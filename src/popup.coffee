$glitch = document.getElementById('glitch')
$desc = document.getElementById('glitch-desc')

getCurrentTab = (cb) ->
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    cb tabs[0]

document.getElementById('disable').addEventListener 'click', () ->
  # Disable live reload of current window.
  getCurrentTab (tab) ->
    chrome.extension.sendMessage ['disableFromPopup', tab]
    window.close()

document.getElementById('save').addEventListener 'click', () ->
  getCurrentTab (tab) ->
    data =
      tab: tab
      glitch: $glitch.value
      desc: $desc.value

    chrome.extension.sendMessage ['reportGlitch', data], (success) ->
      window.close() if success

      # console.log blob
      # a = document.createElement 'a'
      # a.href = URL.createObjectURL blob
      # a.download = "data.mhtml"
      # a.innerText = "Download!"

      # document.querySelector('body').insertBefore a

inspectClickHandler = () ->
  getCurrentTab (tab) ->
    chrome.extension.sendMessage ['startInspection'], (success) ->
      if success
        window.close()
      else
        $glitch.value = "Please close devtools or add attribute '__SEESS_GLITCH__' on your own."

$glitch.addEventListener 'click', inspectClickHandler
document.getElementById('glitch-button').addEventListener 'click', inspectClickHandler

# Kick start:
# Read the previously selected glitches from content script
#
getCurrentTab (tab) ->
  chrome.tabs.sendMessage tab.id, ['getGlitches'], (glitchNames) ->
    # console.log 'Get element: ', elements
    $glitch.value = glitchNames.join(', ')