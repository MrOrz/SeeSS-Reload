document.querySelector('.disable-livereload').addEventListener 'click', () ->
  # Disable live reload of current window.
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    # console.log(tabs)
    if tabs.length == 1
      chrome.extension.sendMessage ['disableFromPopup', tabs[0]]
      window.close()

document.querySelector('.save').addEventListener 'click', () ->
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