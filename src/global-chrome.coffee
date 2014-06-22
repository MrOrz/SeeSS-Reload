TabState::send = (message, data={}) ->
  chrome.tabs.sendMessage @tab, [message, data]

TabState::bundledScriptURI = -> chrome.runtime.getURL('livereload.js')

LiveReloadGlobal.isAvailable = (tab) -> yes

LiveReloadGlobal.initialize()

ToggleCommand =
  invoke: ->
  update: (tabId) ->
    status = LiveReloadGlobal.tabStatus(tabId)
    chrome.browserAction.setTitle { tabId, title: status.buttonToolTip }
    chrome.browserAction.setIcon { tabId, path: status.buttonIcon }

Popup =
  set: (tabId) ->
    chrome.browserAction.setPopup
      tabId: tabId
      popup: 'popup.html'

  unset: (tabId) ->
    chrome.browserAction.setPopup
      tabId: tabId
      popup: ''

chrome.browserAction.onClicked.addListener (tab) ->
  status = LiveReloadGlobal.tabStatus(tab.id)
  console.log "Listener Clickd", status
  if !status.activated
    LiveReloadGlobal.toggle(tab.id)
    ToggleCommand.update(tab.id)

    # Setup popup for future activation of the button.
    Popup.set(tab.id)


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
      Popup.unset(tab.id)

    else
      LiveReloadGlobal.received(eventName, data)
