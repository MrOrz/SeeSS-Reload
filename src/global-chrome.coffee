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

Popup =
  set: () ->
    console.log 'Set popup'
    chrome.browserAction.setPopup
      tabId: ToggleCommand.currentTabId
      popup: 'popup.html'

    # chrome.browserAction.setBadgeText
      # tabId: ToggleCommand.currentTabId
      # text: 'X'
      # text: '…'
      # text: '✓'

    # chrome.browserAction.setBadgeBackgroundColor
      # tabId: ToggleCommand.currentTabId
      # color: '#c00'
      # color: '#cc0'
      # color: '#090'


  unset: () ->
    console.log 'Unset popup'

    chrome.browserAction.setPopup
      tabId: ToggleCommand.currentTabId
      popup: ''

    chrome.browserAction.setBadgeText
      tabId: ToggleCommand.currentTabId
      text: ''

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

      # chrome.debugger.sendCommand @debuggee, 'DOM.resolveNode', {nodeId: nodeId}, (result) ->
      #   @selectedElem = result[0]

  start: (cb) ->

    @selectedElem = null

    @debuggee =
      tabId: ToggleCommand.currentTabId

    chrome.debugger.attach @debuggee, "1.0", () =>

      # Check if the debugger is successfully attached or not.
      # Only initiate inspector mode on when the debugger is attached.
      #
      chrome.debugger.getTargets (targets) =>
        targets = targets.filter (t) => t.tabId == @debuggee.tabId

        if targets.length == 1 and targets[0].attached
          @doStart()
          cb(true) # debugger launched successfully
        else
          cb(false) # DevTools opened, debugger cannot launch

  stop: () ->
    chrome.debugger.sendCommand @debuggee, 'DOM.setInspectModeEnabled', {enabled: false}, () =>
      chrome.debugger.detach @debuggee
      @debuggee = null


window.Drive =
  CLIENT_ID: '302964203115-7octpaksp7lqbo5u7jhlhb9qvlmjinq4.apps.googleusercontent.com'
  SCOPES: 'https://www.googleapis.com/auth/drive'
  FOLDER_NAME: 'SeeSS Collected Data'
  FOLDER_MIME: 'application/vnd.google-apps.folder'
  REDIRECT_URI: 'http://mrorz.github.io/SeeSS-Reload'

  authorize: () ->

    parseToken = (tabId, info, tab) =>
      # https://developers.google.com/accounts/docs/OAuth2UserAgent
      #
      return unless info.url and info.url.indexOf(@REDIRECT_URI) == 0
      tokenObj = {}
      queryString = info.url.slice info.url.indexOf('#')
      regex = /([^&=]+)=([^&]*)/g

      while m = regex.exec queryString
        tokenObj[decodeURIComponent(m[1])] = decodeURIComponent(m[2])

      # Call setToken when tokenObj exists
      # https://developers.google.com/api-client-library/javascript/reference/referencedocs
      #
      gapi.auth.setToken tokenObj
      console.log "Logged in Google Drive", tokenObj

      chrome.tabs.onUpdated.removeListener parseToken

    chrome.tabs.onUpdated.addListener parseToken

    gapi.auth.authorize
      client_id: @CLIENT_ID
      scope: @SCOPES
      immediate: false
      # https://developers.google.com/api-client-library/javascript/start/start-js
      # Setting redirect-uri means using the server-side flow.
      # However we use the extension to capture the access token in URL here.
      #
      redirect_uri: @REDIRECT_URI

  # Get the drive folder named FOLDER_NAME in the user's google drive.
  findFolder: (cb) ->
    gapi.client.drive.files.list {
      q: "title='#{@FOLDER_NAME}' and mimeType = '#{@FOLDER_MIME}'"
      fields: "items/id"
    }, (resp) =>
      console.log 'findFolder resp: ', resp
      @folderId = resp.items.length && resp.items[0].id
      cb(@folderId)

  createFolder: (cb) ->
    gapi.client.request {
      path: '/upload/drive/v2/files'
      method: 'POST'
      params:
        uploadType: 'media'
      body:
        title: @FOLDER_NAME
        mimeType: @FOLDER_MIME
    }, (resp) =>
      console.log 'createFolder resp:', resp
      @folderId = resp.id
      cb(@folderId)

  # Upload the file into FOLDER_NAME folder
  # https://developers.google.com/drive/v2/reference/files/insert
  upload: (fileName, mhtml, cb) ->
    BOUNDRY = "---------#{Math.random()}"
    DELIMITER = "\r\n--#{BOUNDRY}\r\n"
    CLOSE_DELIMITER = "\r\n--#{BOUNDRY}"

    metadata =
      title: fileName
      mimeType: 'application/octet-stream'

    request = gapi.client.drive.files.insert
      path: '/upload/drive/v2/files'
      method: 'POST'
      params:
        uploadType: 'multipart'
      headers:
        'Content-Type': "multipart/mixed; boundary=\"#{BOUNDRY}\""
      body: [
        DELIMITER
        'Content-Type: application/json\r\n\r\n'
        JSON.stringify metadata
        DELIMITER
        'Content-Type: multipart/related\r\n\r\n'
        mhtml
      ].join()

    request.execute cb

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
chrome.tabs.onUpdated.addListener (tabId) ->
  status = LiveReloadGlobal.tabStatus(tabId)
  ToggleCommand.update(tabId) if tabId == ToggleCommand.currentTabId

  # If the status is activated but resetted by refresh, setup the popup.
  Popup.set() if status.activated

chrome.tabs.onSelectionChanged.addListener (tabId, selectInfo) ->
  ToggleCommand.update(tabId)

chrome.tabs.onRemoved.addListener (tabId) ->
  LiveReloadGlobal.killZombieTab tabId


chrome.runtime.onMessage.addListener ([eventName, data], sender, sendResponse) ->
  # console.log "#{eventName}(#{JSON.stringify(data)})"
  switch eventName
    when 'status'
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
      Inspector.start (success)->
        sendResponse success

      return true

    else
      LiveReloadGlobal.received(eventName, data)
