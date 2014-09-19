path = require 'path'
{$, $$$, ScrollView} = require 'atom'

module.exports =
  class MavensMateTabView extends ScrollView

    constructor: (@params) ->
      super
     
      @filePath = @params.result.body
      @promiseId = @params.result.promiseId
      
      @iframe.attr 'src', @filePath
      @iframe.attr 'id', 'iframe-'+@promiseId

      @iframe.focus()

      @addCloseListener()

    @deserialize: (state) ->
      new MavensMateTabView(state)

    serialize: ->
      deserializer: 'MavensMateTabView'

    # Internal: Initialize mavensmate output view DOM contents.
    @content: ->
      @div class: 'mavensmate', =>
        @iframe outlet: 'iframe', width: '100%', height: '100%', class: 'native-key-bindings', sandbox: 'allow-same-origin allow-top-navigation allow-forms allow-scripts', style: 'border:none;'

    serialize: ->
        deserializer: 'MavensMateTabView'
        version: 1
        uri: @uri

    getTitle: ->
      'MavensMate UI'

    getIconName: ->
      'browser'

    getUri: ->
      @uri

    # Tear down any state and detach
    destroy: ->
      console.log 'destroying'
      console.log @
      @detach()
      # console.log atom.workspace

    # close tab when close button is clicked in iframe
    addCloseListener: ->
      thiz = @
      document.addEventListener 'mavensmateCloseIframe', (evt) -> 
        atom.workspaceView.trigger('core:close')



