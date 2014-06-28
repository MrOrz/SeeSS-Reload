
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


# Singleton that observes DOM mutations
#
DebouncedMutationObserver = do ->

  MUTATION_DEBOUNCE_INTERVAL = 500
  _mutationDebounce = null

  _mutationCallback = () ->
    clearTimeout _mutationDebounce
    _mutationDebounce = setTimeout (() -> chrome.extension.sendMessage ['debouncedMutation']), MUTATION_DEBOUNCE_INTERVAL

  _observer = new MutationObserver _mutationCallback

  # Exposed interfaces
  #
  enable: ->

    # Observe the DOM structure change only.
    #
    _observer.observe document.body,
      subtree: true
      childList: true

    # Invoke _mutationCallback once when observer is enabled.
    _mutationCallback()

  disable: ->
    _observer.disconnect()

chrome.runtime.onMessage.addListener ([eventName, data], sender, sendResponse) ->
  # console.log "#{eventName}(#{JSON.stringify(data)})"
  switch eventName
    when 'alert'
      alert data
    when 'enable'
      liveReloadInjected.enable(data)
      DebouncedMutationObserver.enable()
    when 'disable'
      liveReloadInjected.disable()
      DebouncedMutationObserver.disable()

    when 'getGlitches'
      results = document.querySelectorAll('[__SEESS_GLITCH__]')

      glitches = (results.item(i) for i in [0...results.length])

      glitchNames = glitches.map (elem) ->
        "#{elem.localName}##{elem.id}.#{elem.className.split(' ').join('.')}"

      console.log(glitches, glitchNames)
      sendResponse(glitchNames)
      return true