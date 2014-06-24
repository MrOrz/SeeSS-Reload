getCurrentTab = (cb) ->
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    cb tabs[0]

document.getElementById('disable').addEventListener 'click', () ->
  # Disable live reload of current window.
  getCurrentTab (tab) ->
    chrome.extension.sendMessage ['disableFromPopup', tab]
    window.close()

document.getElementById('save').addEventListener 'click', () ->
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    chrome.pageCapture.saveAsMHTML {
      tabId: tabs[0].id
    }, (data) ->
      console.log data
      a = document.createElement 'a'
      a.href = URL.createObjectURL data
      a.download = "data.mhtml"
      a.innerText = "Download!"

      document.querySelector('body').insertBefore a