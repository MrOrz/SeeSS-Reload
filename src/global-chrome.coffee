# Q.longStackSupport = true

TabState::send = (message, data={}) ->
  chrome.tabs.sendMessage @tab, [message, data]

TabState::bundledScriptURI = -> chrome.runtime.getURL('livereload.js')

LiveReloadGlobal.isAvailable = (tab) -> yes

LiveReloadGlobal.initialize()

ToggleCommand =
  currentTabId: null
  invoke: ->
  update: (tabId) ->
    @currentTabId = tabId
    console.log 'Update to tab id: ', tabId
    status = LiveReloadGlobal.tabStatus(tabId)
    chrome.browserAction.setTitle { tabId, title: status.buttonToolTip }
    chrome.browserAction.setIcon { tabId, path: status.buttonIcon }

    unless status.activated
      chrome.browserAction.setBadgeText
        tabId: ToggleCommand.currentTabId
        text: ''

    else

      # update badge if the status is activated.
      # Do not trigger IntegrityState's constructor in ToggleCommand.update()!
      # Because IntegrityState's constructor invokes ToggleCommand.update() internally.
      #

      switch IntegrityState.current(false).get()
        when IntegrityState.CORRECT_STATE  then popupText = '✓'; popupColor = '#090'
        when IntegrityState.EDITING_STATE  then popupText = '…'; popupColor = '#cc0'
        when IntegrityState.GLITCHED_STATE then popupText = 'x'; popupColor = '#c00'

      chrome.browserAction.setBadgeText
        tabId: ToggleCommand.currentTabId
        text: popupText

      chrome.browserAction.setBadgeBackgroundColor
        tabId: ToggleCommand.currentTabId
        color: popupColor

Popup =
  set: () ->
    console.log 'Set popup'
    chrome.browserAction.setPopup
      tabId: ToggleCommand.currentTabId
      popup: 'popup.html'


  unset: () ->
    console.log 'Unset popup'

    chrome.browserAction.setPopup
      tabId: ToggleCommand.currentTabId
      popup: ''


Inspector =
  doStart: () ->
    chrome.debugger.sendCommand @debuggee, 'DOM.setInspectModeEnabled',
      enabled: true
      highlightConfig:
        showInfo: true
        contentColor: {r: 0, g: 0, b: 255, a:0.5}
        borderColor:  {r: 0, g: 0, b: 255, a:0.8}


    # Mark the inspected element with empty attribute __SEESS_GLITCH__
    #
    # https://github.com/cyrus-and/chrome-remote-interface/blob/master/lib/protocol.json
    # Much better than Chrome's documentation...
    #
    chrome.debugger.onEvent.addListener (src, method, params) =>
      return unless method == 'DOM.inspectNodeRequested'
      tabId = src.tabId
      nodeId = params.nodeId
      chrome.debugger.sendCommand @debuggee, 'DOM.setAttributeValue', {
        nodeId: nodeId,
        name: '__SEESS_GLITCH__',
        value: '',
      }, () =>
        @stop()
        chrome.notifications.create 'seess-reload-notification', {
          iconUrl: 'IconActive@2x.png'
          type: 'basic'
          title: 'Glitch Specified'
          message: 'Please open the popup again to complete the glitch report.'
          }, () ->


      # chrome.debugger.sendCommand @debuggee, 'DOM.resolveNode', {nodeId: nodeId}, (result) ->
      #   @selectedElem = result[0]

  start: () ->
    deferred = Q.defer()

    @selectedElem = null

    # Get the current tab,
    # since ToggleCommand.currentTabId is not always correct in
    # this scenario.
    #
    chrome.tabs.query
      active: true,
      currentWindow: true
      (tabs) =>

        @debuggee =
          tabId: tabs[0].id

        chrome.debugger.attach @debuggee, "1.0", () =>

          # Check if the debugger is successfully attached or not.
          # Only initiate inspector mode on when the debugger is attached.
          #
          chrome.debugger.getTargets (targets) =>
            targets = targets.filter (t) => t.tabId == @debuggee.tabId

            if targets.length == 1 and targets[0].attached
              # debugger launched successfully
              @doStart()
              deferred.resolve()

            else
              # DevTools opened, debugger cannot launch
              deferred.reject()

    return deferred.promise

  stop: () ->
    chrome.debugger.sendCommand @debuggee, 'DOM.setInspectModeEnabled', {enabled: false}, () =>
      chrome.debugger.detach @debuggee
      @debuggee = null


window.Drive = do () ->

  # Private variables
  #
  CLIENT_ID = '302964203115-7octpaksp7lqbo5u7jhlhb9qvlmjinq4.apps.googleusercontent.com'
  SCOPES = 'https://www.googleapis.com/auth/drive'
  FOLDER_NAME = 'SeeSS Collected Data'
  FOLDER_MIME = 'application/vnd.google-apps.folder'
  REDIRECT_URI = 'http://mrorz.github.io/SeeSS-Reload'

  _initialized = false
  _fileReader = new FileReader
  _uploadParams = null
  _folderId = null # ID of the Google drive folder containing SeeSS mht files.

  # Upload the file into FOLDER_NAME folder
  # https://developers.google.com/drive/v2/reference/files/insert
  _fileReader.onload = () ->
    return unless _uploadParams

    BOUNDRY = "---------#{("" + Math.random()).slice(2)}"
    DELIMITER = "\r\n--#{BOUNDRY}\r\n"
    CLOSE_DELIMITER = "\r\n--#{BOUNDRY}--"

    thumbnailData = null

    if _uploadParams.thumb
      thumbData = _uploadParams.thumb.slice _uploadParams.thumb.indexOf('base64,')+7

      # thumbnail.image must be "URL-safe Base64 encoded bytes".
      #
      # https://developers.google.com/drive/v2/reference/files
      # http://stackoverflow.com/questions/17377103/google-drive-update-keeps-throwing-an-error-when-i-try-to-save-a-thumbnail
      #
      thumbnailData =
        image: thumbData.replace(/\+/g, '-').replace(/\//g, '_') # Convert base64 to base64url
        mimeType: _uploadParams.thumb.match(/data:(.+?);/)[1]

    request = gapi.client.request
      path: '/upload/drive/v2/files'
      method: 'POST'
      params:
        uploadType: 'multipart'
      headers:
        'Content-Type': "multipart/mixed; boundary=\"#{BOUNDRY}\""
      body: [
        DELIMITER
        'Content-Type: application/json\r\n\r\n'
        JSON.stringify
          title: _uploadParams.fileName
          mimeType: 'message/rfc822'
          description: _uploadParams.desc
          parents: [{kind: 'drive#fileLink', id: _folderId}]
          thumbnail: thumbnailData
        DELIMITER
        'Content-Type: message/rfc822\r\n'
        'Content-Transfer-Encoding: 8bit\r\n\r\n'
        _fileReader.result
        CLOSE_DELIMITER
      ].join('')

    request.execute (resp) ->
      console.log 'Drive upload response', resp
      if resp.error
        _uploadParams.deferred.reject resp.error
      else
        _uploadParams.deferred.resolve resp

      # Reset the entire _uploadParams
      _uploadParams = null


  initialize: () ->
    apiLoadDeferred = Q.defer()
    gapi.client.load 'drive', 'v2', () ->
      apiLoadDeferred.resolve()

    # Return the promise of this procedure:
    #
    # Authorize & Load API --> find folder --> optionally create folder
    #
    return Q.all([apiLoadDeferred.promise, @authorize()])
      .then(@findFolder)
      .then(
        () -> # Successfully found folder, directly resolve.
          return Q(_folderId)
        () => # Folder not found, return the createFolder's promise.
          return @createFolder()
      ).then(
        () ->
          console.log 'Drive initailized!'
          _initialized = true
      ).thenResolve _folderId

  #
  # Returns exposed object interfaces
  #

  authorize: () ->
    deferred = Q.defer()

    parseToken = (tabId, info, tab) ->
      # https://developers.google.com/accounts/docs/OAuth2UserAgent
      #
      return unless info.url and info.url.indexOf(REDIRECT_URI) == 0
      tokenObj = {}
      queryString = info.url.slice( info.url.indexOf('#')+1 )
      regex = /([^&=]+)=([^&]*)/g

      while m = regex.exec queryString
        tokenObj[decodeURIComponent(m[1])] = decodeURIComponent(m[2])

      # Call setToken when tokenObj exists
      # https://developers.google.com/api-client-library/javascript/reference/referencedocs
      #
      gapi.auth.setToken tokenObj

      console.log "Logged in Google Drive", tokenObj

      chrome.tabs.onUpdated.removeListener parseToken

      deferred.resolve()

    chrome.tabs.onUpdated.addListener parseToken

    gapi.auth.authorize
      client_id: CLIENT_ID
      scope: SCOPES
      immediate: false
      # https://developers.google.com/api-client-library/javascript/start/start-js
      # Setting redirect-uri means using the server-side flow.
      # However we use the extension to capture the access token in URL here.
      #
      redirect_uri: REDIRECT_URI

    return deferred.promise

  # Get the drive folder named FOLDER_NAME in the user's google drive.
  findFolder: () ->
    throw new Error('Drive unauthorized yet') unless gapi.auth.getToken()
    deferred = Q.defer()

    request = gapi.client.drive.files.list
      q: "title='#{FOLDER_NAME}' and mimeType = '#{FOLDER_MIME}'"
      fields: "items/id"

    request.execute (resp) ->
      console.log 'findFolder resp: ', resp
      _folderId = resp.items?.length && resp.items[0].id
      if _folderId
        deferred.resolve _folderId
      else
        deferred.reject 'Not Found'

    return deferred.promise

  createFolder: () ->
    throw new Error('Drive unauthorized yet') unless gapi.auth.getToken()

    deferred = Q.defer()

    gapi.client.request {
      path: '/upload/drive/v2/files'
      method: 'POST'
      params:
        uploadType: 'media'
      body:
        title: FOLDER_NAME
        mimeType: FOLDER_MIME
    }, (resp) ->
      console.log 'createFolder resp:', resp
      _folderId = resp.id
      deferred.resolve _folderId

    return deferred.promise

  # Reads mhtml blob and sets the upload parameters
  upload: (fileName, mhtmlBlob, thumb, desc) ->
    throw new Error('Drive uninitialized yet') unless _initialized

    deferred = Q.defer()

    if _fileReader.readyState == _fileReader.LOADING || _uploadParams != null
      throw new Error('Upload pending.')

    # Setup upload parameters
    _uploadParams =
      fileName: fileName
      desc: desc
      thumb: thumb
      deferred: deferred

    _fileReader.readAsText(mhtmlBlob)

    return deferred.promise


# Integrity state for each tasbs
class IntegrityState

  # tab --> state instance
  _tabs = {}


  # Prototype methods

  constructor: (@tabId) ->
    # Pseudo-private variables
    @_state = null
    @_storedDesc = null
    @_storedBlob = null
    @_storedTitle = null
    @_storedThumbUrl = null

    @_changeState(@CORRECT_STATE)  # Set initial state to correct.

    # Register the current integrity state instance into the _tabs hash.
    _tabs[@tabId] = @

  CORRECT_STATE: 0
  EDITING_STATE: 1
  GLITCHED_STATE: 2

  # Change state and update icon
  _changeState: (newState) ->
    @_state = newState
    ToggleCommand.update(ToggleCommand.currentTabId)

  # Exposed interface
  #

  # Getters
  get: () -> @_state
  blob: () -> @_storedBlob
  desc: () -> @_storedDesc
  thumb: () -> @_storedThumbUrl
  title: () -> @_storedTitle

  readyToUpload: () ->
    @_storedBlob && @_storedTitle

  # Store the page blob & page title
  store: (title, blb, thumb) ->
    console.log "Update stored blob to", title, blb, thumb.slice(0, 20)+'...'
    @_storedTitle = title
    @_storedBlob = blb
    @_storedThumbUrl = thumb

  # The only way to return to CORRECT_STATE
  cleanup: () ->
    console.log "Stored blob information cleared for tab #{@tabId}"
    @_storedTitle = @_storedBlob = @_storedDesc = @_storedThumbUrl = null
    @_changeState(@CORRECT_STATE)

  # Set state to any state other than CORRECT
  # and stores description
  set: (state, desc) ->
    switch state
      when @EDITING_STATE then @_changeState(state)
      when @GLITCHED_STATE
        @_storedDesc = desc
        @_changeState state
      else
        console.error 'Invalid state transition for IntegrityState'

  # Class method that returns the integrity state of the current tab.
  IntegrityState.current = (createNew = true) ->
    _tabs[ToggleCommand.currentTabId] || (createNew && new IntegrityState(ToggleCommand.currentTabId))

  # Transparent state constants from prototype
  IntegrityState.CORRECT_STATE = IntegrityState.prototype.CORRECT_STATE
  IntegrityState.EDITING_STATE = IntegrityState.prototype.EDITING_STATE
  IntegrityState.GLITCHED_STATE = IntegrityState.prototype.GLITCHED_STATE

  # Cleanup _tabs when tab closed
  chrome.tabs.onRemoved.addListener (tabId) ->
    delete _tabs[tabId]
    return

# Given a data-url of a image,
# Shrink the image into 0.3 * width and 0.3* height and output new data-url
#
ImageDataUrlResizer = do () ->

  SCALE = 0.3

  _imageElem = new Image
  _imageElem.onload = () ->

    # Resizing
    width = _canvasElem.width = _imageElem.width * SCALE
    height = _canvasElem.height = _imageElem.height * SCALE

    _ctx.drawImage _imageElem, 0, 0, width, height
    _deferred.resolve _canvasElem.toDataURL('image/jpeg', 0.5)

  _canvasElem = document.createElement('canvas')
  _ctx = _canvasElem.getContext('2d')

  _deferred = null

  return (dataUrl) ->
    # Cancel previous resize request.
    if _deferred && _deferred.promise.isPending()
      _deferred.reject 'Canceled by next image'

    # Create new deferred object
    _deferred = Q.defer()

    # Kick-start the _imageElem.onload
    _imageElem.src = dataUrl

    return _deferred.promise



# Wrapper for Drive.upload that reads information from current IntegrityState
# and generates an uniformed snapshot filename
#
sendSnapshot = () ->
  deferred = Q.defer()

  # Generate a local time string YYYY-MM-DD HH:mm:SS in local time zone
  localeTimestamp = Date.now() - (new Date).getTimezoneOffset()*60000
  dateString = (new Date(localeTimestamp)).toISOString().replace('T',' ').replace(/\.\d{3}Z/, '')

  # Prefix every file with [v] or [x]
  label = if IntegrityState.current().get() == IntegrityState.CORRECT_STATE then 'v' else 'x'

  # Return Drive.upload promise
  #
  fileTitle = "#{dateString}[#{label}]#{IntegrityState.current().title()}.mht"

  # Resize thumbnail before actual upload
  #
  ImageDataUrlResizer(IntegrityState.current().thumb()).then (smallThumb) ->
    console.log "Uploading to Google Drive: #{fileTitle}, #{IntegrityState.current().desc()}"
    Drive.upload(
      fileTitle,
      IntegrityState.current().blob(),
      smallThumb,
      IntegrityState.current().desc()
    ).then(
      (resp) ->
        IntegrityState.current().cleanup()
        return resp
      (error) ->
        Drive.authorize() if error.code == 401
    )


chrome.browserAction.onClicked.addListener (tab) ->
  status = LiveReloadGlobal.tabStatus(tab.id)
  console.log "Listener Clickd", status
  if !status.activated
    LiveReloadGlobal.toggle(tab.id)
    ToggleCommand.update(tab.id)

    # Setup popup for future activation of the button.
    Popup.set()

    # Debugger
    # chrome.debugger.attach {tabId: tab.id}, "1.0"
    # chrome.debugger.onEvent.addListener (debuggee, method, params) ->
    #   console.log 'debugger onEvent', arguments

# http://stackoverflow.com/questions/14069948/how-to-stop-chrome-tabs-reload-from-resetting-the-extension-icon
# Chrome refresh / pushstate resets icon to default. Get it back.
#
chrome.tabs.onUpdated.addListener (tabId, info, tab) ->
  return unless info.status == "complete"
  status = LiveReloadGlobal.tabStatus(tabId)
  ToggleCommand.update(tabId) if tabId == ToggleCommand.currentTabId

  # If the status is activated but resetted by refresh, setup the popup.
  Popup.set() if status.activated

# Sends previously stored snapshots on refresh / pushstate
chrome.tabs.onUpdated.addListener (tabId, info, tab) ->
  return unless info.status == "loading"

  # Only interested in updates of current tab
  return unless tabId == ToggleCommand.currentTabId

  # Send the stored blob file now.
  sendSnapshot() if IntegrityState.current().readyToUpload()

chrome.tabs.onSelectionChanged.addListener (tabId, selectInfo) ->
  ToggleCommand.update(tabId)

chrome.tabs.onRemoved.addListener (tabId) ->
  LiveReloadGlobal.killZombieTab tabId


getMHTML = (tabId) ->
  console.log 'Getting mhtml'
  deferred = Q.defer()
  chrome.pageCapture.saveAsMHTML
    tabId: tabId
    (blob) ->
      console.log 'got mhtml'
      deferred.resolve blob

  return deferred.promise

getThumbnailDataUrl = () ->
  console.log 'Getting thumbnail'
  deferred = Q.defer()
  chrome.tabs.captureVisibleTab (dataUrl) ->
    console.log 'got thumbnail dataUrl'
    deferred.resolve dataUrl

  return deferred.promise

chrome.runtime.onMessage.addListener ([eventName, data], sender, sendResponse) ->
  # console.log "#{eventName}(#{JSON.stringify(data)})"
  switch eventName
    when 'status'
      # Trigger the instantiation of integrity state of current tab
      IntegrityState.current()

      LiveReloadGlobal.updateStatus(sender.tab.id, data)
      ToggleCommand.update(sender.tab.id)

    when 'disableFromPopup'
      tab = data
      LiveReloadGlobal.toggle(tab.id)
      ToggleCommand.update(tab.id)

      # Unset popup
      Popup.unset()

    # Starts inspection and returns whether starting is successful.
    #
    when 'startInspection'
      Inspector.start().then(
        () ->
          sendResponse true
        () ->
          sendResponse false
      )

      return true # Make the extension channel open for sendResponse() calls.

    when 'debouncedMutation'

      Q.all([getMHTML(sender.tab.id), getThumbnailDataUrl()]).spread (blob, thumbDataUrl) ->
        # Put in required data into the state.
        IntegrityState.current().store "<#{sender.tab.width}x#{sender.tab.height}>#{sender.tab.url}", blob, thumbDataUrl
        # IntegrityState.current().set IntegrityState.current().CORRECT_STATE

    when 'reportGlitch'

      Q.all([getMHTML(data.tab.id), getThumbnailDataUrl()]).spread (blob, thumbDataUrl) ->
        # Put in the required data into the state
        IntegrityState.current().store "<#{data.tab.width}x#{data.tab.height}>#{data.tab.url}", blob, thumbDataUrl
        IntegrityState.current().set IntegrityState.current().GLITCHED_STATE, "{{#{data.glitch.trim()}}} #{data.desc.trim()}"

        # Send mhtml snapshot
        sendSnapshot().then (resp) ->
          sendResponse resp

      return true # Make the extension channel open for sendResponse() calls.

    else
      LiveReloadGlobal.received(eventName, data)

# Initalize Google drive on startup
window.gapi_onload = () ->
  console.log 'GAPI Onload invoked!', gapi.auth, gapi.client
  setTimeout ()->
    Drive.initialize()
