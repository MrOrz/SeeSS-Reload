describe 'Printing Jasmine version', () ->
  it 'prints', () ->
    console.log "jasmine version: #{jasmine.getEnv().versionString()}"

describe 'DomSerializer', ->

  describe '#toObject', ->

    it 'processes empty <div>'

    it 'processes attributes'

    it 'reads styles'

    it 'produces JSON-serializable objects'

    describe 'runs recursively and', ->
      testRoot = null

      beforeEach () ->
        testRoot = document.createElement 'div'
        testRoot.innerHTML = """
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
