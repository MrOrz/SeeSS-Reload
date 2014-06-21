# ToggleCommand =
#   invoke: ->
#   update: (tabId) ->
#     status = LiveReloadGlobal.tabStatus(tabId)
#     chrome.browserAction.setTitle { tabId, title: status.buttonToolTip }
#     chrome.browserAction.setIcon { tabId, path: status.buttonIcon }


document.querySelector('.disable-livereload').addEventListener 'click', () ->
  # LiveReloadGlobal.toggle(tab.id)
  # ToggleCommand.update(tab.id)

  chrome.extension.sendMessage ['status', enabled: no, active: no]
  chrome.browserAction.setPopup # Disable the popup
    popup: ""