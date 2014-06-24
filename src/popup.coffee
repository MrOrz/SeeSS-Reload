$glitch = document.getElementById('glitch')

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

$glitch.addEventListener 'click', () ->
  getCurrentTab (tab) ->
    chrome.extension.sendMessage ['startInspection'], (success) ->
      if success
        window.close()
      else
        $glitch.value = "Please close devtools or add attribute '__SEESS_GLITCH__' on your own."

# Kick start:
# Read the previously selected glitches from content script
#
getCurrentTab (tab) ->
  chrome.tabs.sendMessage tab.id, ['getGlitches'], (glitchNames) ->
    # console.log 'Get element: ', elements
    $glitch.value = glitchNames.join(', ')