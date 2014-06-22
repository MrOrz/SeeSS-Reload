document.querySelector('.disable-livereload').addEventListener 'click', () ->
  # Disable live reload of current window.
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    # console.log(tabs)
    if tabs.length == 1
      chrome.extension.sendMessage ['disableFromPopup', tabs[0]]
      window.close()