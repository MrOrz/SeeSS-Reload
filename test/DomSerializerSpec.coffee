EMPTY_DIV_STYLES = 'background-attachment: ; background-blend-mode: ; background-clip: ; background-color: ; background-image: ; background-origin: ; background-position: ; background-repeat: ; background-size: ; border-bottom-color: ; border-bottom-left-radius: ; border-bottom-right-radius: ; border-bottom-style: ; border-bottom-width: ; border-collapse: ; border-image-outset: ; border-image-repeat: ; border-image-slice: ; border-image-source: ; border-image-width: ; border-left-color: ; border-left-style: ; border-left-width: ; border-right-color: ; border-right-style: ; border-right-width: ; border-top-color: ; border-top-left-radius: ; border-top-right-radius: ; border-top-style: ; border-top-width: ; bottom: ; box-shadow: ; box-sizing: ; caption-side: ; clear: ; clip: ; color: ; cursor: ; direction: ; display: ; empty-cells: ; float: ; font-family: ; font-kerning: ; font-size: ; font-style: ; font-variant: ; font-variant-ligatures: ; font-weight: ; height: ; image-rendering: ; left: ; letter-spacing: ; line-height: ; list-style-image: ; list-style-position: ; list-style-type: ; margin-bottom: ; margin-left: ; margin-right: ; margin-top: ; max-height: ; max-width: ; min-height: ; min-width: ; object-fit: ; object-position: ; opacity: ; orphans: ; outline-color: ; outline-offset: ; outline-style: ; outline-width: ; overflow-wrap: ; overflow-x: ; overflow-y: ; padding-bottom: ; padding-left: ; padding-right: ; padding-top: ; page-break-after: ; page-break-before: ; page-break-inside: ; pointer-events: ; position: ; resize: ; right: ; speak: ; table-layout: ; tab-size: ; text-align: ; text-decoration: ; text-indent: ; text-rendering: ; text-shadow: ; text-overflow: ; text-transform: ; top: ; transition-delay: ; transition-duration: ; transition-property: ; transition-timing-function: ; unicode-bidi: ; vertical-align: ; visibility: ; white-space: ; widows: ; width: ; word-break: ; word-spacing: ; word-wrap: ; z-index: ; zoom: ; -webkit-animation-delay: ; -webkit-animation-direction: ; -webkit-animation-duration: ; -webkit-animation-fill-mode: ; -webkit-animation-iteration-count: ; -webkit-animation-name: ; -webkit-animation-play-state: ; -webkit-animation-timing-function: ; -webkit-appearance: ; -webkit-backface-visibility: ; -webkit-background-clip: ; -webkit-background-composite: ; -webkit-background-origin: ; -webkit-background-size: ; -webkit-border-fit: ; -webkit-border-horizontal-spacing: ; -webkit-border-image: ; -webkit-border-vertical-spacing: ; -webkit-box-align: ; -webkit-box-decoration-break: ; -webkit-box-direction: ; -webkit-box-flex: ; -webkit-box-flex-group: ; -webkit-box-lines: ; -webkit-box-ordinal-group: ; -webkit-box-orient: ; -webkit-box-pack: ; -webkit-box-reflect: ; -webkit-box-shadow: ; -webkit-clip-path: ; -webkit-column-break-after: ; -webkit-column-break-before: ; -webkit-column-break-inside: ; -webkit-column-count: ; -webkit-column-gap: ; -webkit-column-rule-color: ; -webkit-column-rule-style: ; -webkit-column-rule-width: ; -webkit-column-span: ; -webkit-column-width: ; -webkit-filter: ; align-content: ; align-items: ; align-self: ; flex-basis: ; flex-grow: ; flex-shrink: ; flex-direction: ; flex-wrap: ; justify-content: ; -webkit-font-smoothing: ; -webkit-highlight: ; -webkit-hyphenate-character: ; -webkit-line-box-contain: ; -webkit-line-break: ; -webkit-line-clamp: ; -webkit-locale: ; -webkit-margin-before-collapse: ; -webkit-margin-after-collapse: ; -webkit-mask-box-image: ; -webkit-mask-box-image-outset: ; -webkit-mask-box-image-repeat: ; -webkit-mask-box-image-slice: ; -webkit-mask-box-image-source: ; -webkit-mask-box-image-width: ; -webkit-mask-clip: ; -webkit-mask-composite: ; -webkit-mask-image: ; -webkit-mask-origin: ; -webkit-mask-position: ; -webkit-mask-repeat: ; -webkit-mask-size: ; order: ; -webkit-perspective: ; -webkit-perspective-origin: ; -webkit-print-color-adjust: ; -webkit-rtl-ordering: ; -webkit-tap-highlight-color: ; -webkit-text-combine: ; -webkit-text-decorations-in-effect: ; -webkit-text-emphasis-color: ; -webkit-text-emphasis-position: ; -webkit-text-emphasis-style: ; -webkit-text-fill-color: ; -webkit-text-orientation: ; -webkit-text-security: ; -webkit-text-stroke-color: ; -webkit-text-stroke-width: ; -webkit-transform: ; -webkit-transform-origin: ; -webkit-transform-style: ; -webkit-transition-delay: ; -webkit-transition-duration: ; -webkit-transition-property: ; -webkit-transition-timing-function: ; -webkit-user-drag: ; -webkit-user-modify: ; -webkit-user-select: ; -webkit-writing-mode: ; -webkit-app-region: ; buffered-rendering: ; clip-path: ; clip-rule: ; mask: ; filter: ; flood-color: ; flood-opacity: ; lighting-color: ; stop-color: ; stop-opacity: ; color-interpolation: ; color-interpolation-filters: ; color-rendering: ; fill: ; fill-opacity: ; fill-rule: ; marker-end: ; marker-mid: ; marker-start: ; mask-type: ; shape-rendering: ; stroke: ; stroke-dasharray: ; stroke-dashoffset: ; stroke-linecap: ; stroke-linejoin: ; stroke-miterlimit: ; stroke-opacity: ; stroke-width: ; alignment-baseline: ; baseline-shift: ; dominant-baseline: ; kerning: ; text-anchor: ; writing-mode: ; glyph-orientation-horizontal: ; glyph-orientation-vertical: ; vector-effect: ; paint-order: ;'

createElement = (str) ->
  div = document.createElement 'div'
  div.innerHTML = str

  div.firstChild

describe 'Printing Jasmine version', () ->
  it 'prints', () ->
    console.log "jasmine version: #{jasmine.getEnv().versionString()}"

describe 'DomSerializer', ->

  describe '#toObject', ->

    it 'processes empty <div>', () ->
      obj = DomSerializer.toObject createElement('<div></div>')
      expect(obj).toEqual
        tag: 'DIV'
        attr: {}
        style: jasmine.any String

    it 'processes attributes', () ->
      obj = DomSerializer.toObject createElement('<div class="a" style="background: cyan;"></div>')
      expect(obj).toEqual
        tag: 'DIV'
        attr:
          'class': 'a'
          style: 'background: cyan;'
        style: jasmine.any String

    it 'reads styles', () ->
      obj = DomSerializer.toObject createElement('<div class="a" style="background: cyan;"></div>')
      expect(obj).toEqual
        tag: 'DIV'
        attr:
          'class': 'a'
          style: 'background: cyan;'
        style: EMPTY_DIV_STYLES

    it 'produces objects that is fully json-serializable', () ->
      obj = DomSerializer.toObject createElement('<div></div>')
      expect(obj).toEqual JSON.parse(JSON.stringify(obj))

    describe 'runs recursively and', ->
      testRoot = null

      beforeEach () ->
        testRoot = createElement """
          <header class="page-header" style="color: green;">
            <h1>Big title</h1>
            <h2 class="subheader">Small title</h2>
            <p style="color: red;">Paragraph</p>
          </header>
        """

      it 'processes DOM correctly'

      it 'processes attributes'

      it 'reads styles'


  describe '#toDom', ->

    it 'recovers DOM from object'

    it 'recovers DOM attributes from object'

    it "appends computed styles to DOM's style attribute"
