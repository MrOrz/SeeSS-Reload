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


chrome.browserAction.onClicked.addListener (tab) ->
  status = LiveReloadGlobal.tabStatus(tab.id)
  console.log "Listener Clickd", status
  if !status.activated
    LiveReloadGlobal.toggle(tab.id)
    ToggleCommand.update(tab.id)

    # Setup popup for future activation of the button.
    Popup.set()

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

    else
      LiveReloadGlobal.received(eventName, data)
