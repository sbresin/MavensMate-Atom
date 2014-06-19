path = require 'path'
{$, $$$, ScrollView} = require 'atom'

module.exports =
  class MavensMateAppView extends ScrollView
    atom.deserializers.add(this)

    @deserialize: (state) ->
      new MavensMateAppView(state)

    @content: ->
      @div class: 'mavensmate native-key-bindings', tabindex: -1

    constructor: (@filePath, @command) ->
      super

      if @filePath?
        if atom.workspace?
          @subscribeToFilePath(@filePath)
        else
          @subscribe atom.packages.once 'activated', =>
            @subscribeToFilePath(@filePath)

    serialize: ->
      deserializer: 'MavensMateAppView'
      filePath: @filePath

    destroy: ->
      @unsubscribe()

    subscribeToFilePath: (filePath) ->
      @trigger 'title-changed'
      @handleEvents()
      @addIframeCloseListener()
      @renderHTML()

    addIframeCloseListener: ->
      document.addEventListener 'mavensmateCloseIframe', (evt) -> 
        console.log 'heard an event!'
        console.log evt
        console.log atom.workspace.getPanes()

        paneId = parseInt evt.detail, 10

        panes = atom.workspace.getPanes()
        for pane in panes
          pane.destroyItems() if paneId == pane.id
        return


    handleEvents: ->

      changeHandler = =>
        @renderHTML()
        pane = atom.workspace.paneForUri(@getUri())
        if pane? and pane isnt atom.workspace.getActivePane()
          pane.activateItem(this)

    getTitle: ->
        'MavensMate | '+@command

    getUri: ->
      'mavensmate://editor/fooooooo'

    renderHTML: ->
      @showLoading()    
      iframe = document.createElement('iframe')
      iframe.src = @filePath
      iframe.width = '100%';
      iframe.height = '100%';
      iframe.sandbox = 'allow-same-origin allow-top-navigation allow-forms allow-scripts';
      iframe.style.border = 'none';
      @html $ iframe

    showLoading: ->
      @html $$$ ->
        @div class: 'atom-html-spinner', 'Loading MavensMate\u2026'
