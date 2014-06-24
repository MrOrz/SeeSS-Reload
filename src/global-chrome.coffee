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
