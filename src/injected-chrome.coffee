
LiveReloadInjected::send = (message, data) ->
  chrome.runtime.sendMessage [message, data]

liveReloadInjected = new LiveReloadInjected(document, window, 'Chrome')

# Inspector =
#   div: document.createElement '<div style="background: rgba(0,0,255,.3); border: 1px solid #00f; position: absolute; z-index: 1000000; display: none;"></div>'

#   start: () ->
#     document.body.insertBefore div
#     div.style.display = 'block'
#     document.body.addEventListener 'mouseover', (e) ->
#       # elementFromPoint uses coordinate based on screen.
#       el = document.elementFromPoint e.x, e.y
#       console.log(el, el.getBoundingClientRect)
#       div.

#   stop: () ->

chrome.runtime.onMessage.addListener ([eventName, data], sender, sendResponse) ->
  # console.log "#{eventName}(#{JSON.stringify(data)})"
  switch eventName
    when 'alert'
      alert data
    when 'enable'
      liveReloadInjected.enable(data)
    when 'disable'
      liveReloadInjected.disable()

    when 'getGlitches'
      results = document.querySelectorAll('[__SEESS_GLITCH__]')

      glitches = (results.item(i) for i in [0...results.length])

      glitchNames = glitches.map (elem) ->
        "#{elem.localName}.#{elem.className.split(' ').join('.')}"

      console.log(glitches, glitchNames)
      sendResponse(glitchNames)
      return true