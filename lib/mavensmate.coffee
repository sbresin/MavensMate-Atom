{$, $$, $$$, EditorView, View} = require 'atom'
fs    = require 'fs'
path  = require 'path'
{Subscriber,Emitter}                = require 'emissary'
MavensMateEventEmitter              = require('./mavensmate-emitter').pubsub
MavensMateLocalServer               = require './mavensmate-local-server'
MavensMateCommandLineInterface      = require('./mavensmate-cli').mm
MavensMateProjectListView           = require './mavensmate-project-list-view'
MavensMateErrorView                 = require './mavensmate-error-view'
MavensMateCheckpointHandler         = require './mavensmate-checkpoint-handler'
MavensMatePanelView                 = require('./mavensmate-panel-view').panel
MavensMateStatusBarView             = require './mavensmate-status-bar-view'
# MavensMateShareView                 = require './mavensmate-share-view'
MavensMateAppView                   = require './mavensmate-app-view'
MavensMateModalView                 = require './mavensmate-modal-view'
CodeHelperMetadata                  = require './code-helper/metadata'
CodeHelperBufferView                = require './code-helper/buffer-view'
tracker                             = require('./mavensmate-promise-tracker').tracker
util                                = require './mavensmate-util'
emitter                             = require('./mavensmate-emitter').pubsub
MavensMateCodeAssistProviders       = require './mavensmate-code-assist-providers'
commands                            = require './commands.json'
{exec}                              = require 'child_process'
atom.mavensmate = {}
window.jQuery = $

require '../scripts/bootstrap'

MavensMateAtomWatcher = require('./mavensmate-atom-watcher').watcher
MavensMateTabView = null

tabViewUri = 'mavensmate://tabView'
createTabView = (params) ->
  MavensMateTabView ?= require './mavensmate-tab-view'
  tabView = new MavensMateTabView(params)

module.exports =

  class MavensMate
    Subscriber.includeInto this

    editorSubscription: null
    autocomplete: null
    providers: []

    panel: null # mavensmate status panel
    localHttpServer: null # express.js server that handles UI interaction
    mm: null # mm cli singleton

    constructor: ->
      console.log 'New instance of MavensMate plugin...'
      @init()

    # Activates the package, starts the local server, instantiates the views, etc.
    #
    # Returns nothing.
    init: -> 
      atom.workspace.registerOpener (uri, params) ->
        createTabView(params) if uri is tabViewUri

      atom.workspaceView.mavensMateProjectInitialized ?= false
      console.log 'initing mavensmate.coffee'
      #@promiseTracker = new MavensMatePromiseTracker()

      # instantiate mm tool
      @mm = MavensMateCommandLineInterface

      @projectCommands = commands.projectCommands

      # start the local express.js server, returns a promise, set the server port that was randomly selected
      console.log 'initing express.js'
      @localHttpServer = new MavensMateLocalServer()
      @localHttpServer.start().then (result) =>
        atom.config.set('MavensMate-Atom.mm_server_port', result)

      # instantiate mavensmate panel, show it
      @panel = MavensMatePanelView    

      atom.workspaceView.command "mavensmate:new-project", =>
        params =
          args:
            operation: 'new_project'
            ui: true
            #pane: atom.workspace.getActivePane().splitLeft()
            pane: atom.workspace.getActivePane()
        @mm.run(params).then (result) =>
          @mmResponseHandler(params, result)

      # presents a list of projects in a select list
      atom.workspaceView.command "mavensmate:open-project", =>
        # instantiate a mavensmate project list view instance
        @selectList = new MavensMateProjectListView()
        @selectList.toggle()

      atom.project.on 'path-changed', => @onProjectPathChanged()

      @onProjectPathChanged()

    onProjectPathChanged: ->
      if util.isMavensMateProject() and not atom.workspaceView.mavensMateProjectInitialized
        atom.workspaceView.mavensMateProjectInitialized = true
        @initializeProject()
      else
        console.log('not a mavensmate project or already initialized')


    initializeProject: ->
      @panel.toggle()

      # @subscribe atom.workspace.eachEditor (editor) =>
      #   @handleEvents(editor)

      atom.project.errors = {}
      atom.project.checkpointCount = 0
      if atom.project.path
        try
          data = fs.readFileSync atom.project.path + '/config/.overlays'
          overlays = JSON.parse data
          atom.project.checkpointCount = overlays.length
        catch error
          console.log error

      ##COMMANDS TODO: move


      atom.workspaceView.command "mavensmate:toggle-output", =>
        @panel.toggle()

      # deletes file(s) from server
      atom.workspaceView.command "mavensmate:delete-file-from-server", =>
        treeView = util.treeView()
        if treeView.hasFocus() # clicked in sidebar
          filePaths = treeView.selectedPaths()
        else # command palette or right click in editor
          filePaths = [util.activeFile()]
        params =
          args:
            operation: 'delete'
            pane: atom.workspace.getActivePane()
          payload:
            files: filePaths
        fileString = (filePaths.map (path) -> util.baseName(path)).join(', ')
        answer = atom.confirm
          message: "Are you sure you want to delete #{fileString} from Salesforce?"
          # NB: specs expects the following buton indices, 0: Cancel, 1: Delete
          #     so that we can simulate button clicks properly in the spec
          buttons: ["Cancel", "Delete"]
        if answer == 1 # 1 => Delete
          @mm.run(params).then (result) =>
            @mmResponseHandler(params, result)


      # attach commands to workspace based on commands.json
      for commandName, command of @projectCommands
        resolvedName = 'mavensmate:' + commandName

        atom.workspaceView.command resolvedName, (options) =>          
          commandName = options.type.split(':').pop()
          command = @projectCommands[commandName]
          if command?
            params =
              args:
                operation: command.operation
                pane: atom.workspace.getActivePane()

            if 'ui' of command
              params.args.ui = command.ui
            if 'view' of command
              params.args.view = command.view
            else
              params.args.view = 'modal'

            payload = {}
            if 'payloadFiles' of command
              switch command['payloadFiles']
                when 'active'
                  payload.files = [util.activeFile()]
                when 'selected'
                  payload.files = util.getSelectedFiles()
            if 'payloadClasses' of command
              switch command['payloadClasses']
                when 'activeBaseName'
                  if util.activeFile().indexOf('.cls') >= 0
                    payload.classes = [util.activeFileBaseName().split('.')[0]]
            if 'payloadMetadata' of command
              payload.metadata_type = command.payloadMetadata
            console.log(payload)
            if Object.keys(payload).length != 0
              params.payload = payload
            console.log(params.payload)

            answer = 0
            if command.confirm?
              answer = atom.confirm
                message: command.confirm.message
                detailedMessage: command.confirm.message
                buttons: command.confirm.buttons
            if answer == 0 # Yes
              @mm.run(params).then (result) =>
                @mmResponseHandler(params, result)


      # places mavensmate 3 dot icon in the status bar
      createStatusEntry = =>
        @mavensmateStatusBar = new MavensMateStatusBarView(@panel)

      if atom.workspaceView.statusBar
        createStatusEntry()
      else
        atom.packages.once 'activated', ->
          createStatusEntry()

      # we rely upon autocomplete plus right now
      if !util.isAutocompletePlusInstalled()
        @installAutocompletePlus()
      else
        @enableAutocomplete()

      # attach MavensMate views/handlers to each present and future editor views
      atom.workspaceView.eachEditorView (editorView) =>        
        @handleBufferEvents editorView
        # TODO: shouldn't we scope this to MavensMate projects only?
        editorView.errorView = new MavensMateErrorView(editorView) # displays gutter marks, etc. on compile errors
        editorView.checkpointHandler = new MavensMateCheckpointHandler(editorView, @mm, @mmResponseHandler) # creates/deletes/displays checkpoints in gutter
        # editorView.shareView = new MavensMateShareView() contextify npm package is incompatible right now
        
      # retrieve code helper metadata, set up code helper buffers
      m = new CodeHelperMetadata()
      m.retrieve().then (metadata) ->
        console.log 'ok!!!! yahhhhhh'
        atom.mavensmate.codeHelperMetadata = metadata
        console.log atom.mavensmate.codeHelperMetadata

        # attach MavensMate views/handlers to each present and future editor views
        atom.workspaceView.eachEditorView (editorView) =>        
          editorView.codeHelperBufferView = new CodeHelperBufferView(editorView)
          console.log editorView.codeHelperBufferView

    installAutocompletePlus: ->
      cmd = "#{atom.packages.getApmPath()} install autocomplete-plus"
      exec cmd, @enableAutocomplete

    enableAutocomplete: ->
      atom.packages.activatePackage("autocomplete-plus")
        .then (pkg) =>
          @autocomplete = pkg.mainModule
          @registerProviders()

    registerProviders: ->
      @editorSubscription = atom.workspaceView.eachEditorView (editorView) =>
        if editorView.attached and not editorView.mini
          apexProvider = new MavensMateCodeAssistProviders.ApexProvider(editorView)
          @autocomplete.registerProviderForEditorView apexProvider, editorView
          @providers.push apexProvider

          apexContextProvider = new MavensMateCodeAssistProviders.ApexContextProvider(editorView)
          @autocomplete.registerProviderForEditorView apexContextProvider, editorView
          @providers.push apexContextProvider

          # sobjectProvider = new MavensMateCodeAssistProviders.SobjectProvider(editorView)
          # @autocomplete.registerProviderForEditorView sobjectProvider, editorView
          # @providers.push sobjectProvider

    # Public: Deactivate the package and destroy the mavensmate views.
    #
    # Returns nothing.
    destroy: ->
      if @localHttpServer?
        @localHttpServer.destroy()
        delete @localHttpServer
    
      # remove MavensMate items from the status bar
      @mavensmateStatusBar?.destroy()
      @mavensmateStatusBar = null

      # remove the MavensMate panel
      @panel.destroy()
      @panel = null

      #unsubscribe from all listeners
      @unsubscribe()

    mmResponseHandler: (params, result) ->
      tracker.pop(result.promiseId).result
      if params.args.ui
        if result.success
          if params.args.view == 'tab'
            params.result = result
            atom.workspaceView.open tabViewUri, params
          else
            modalView = new MavensMateModalView result.promiseId, result.body, params.args.operation #attach app view pane
            modalView.appendTo document.body

      MavensMateEventEmitter.emit 'mavensmatePromiseCompleted', result.promiseId
      MavensMateEventEmitter.emit 'mavensmatePanelNotifyFinish', params, result, result.promiseId

    handleBufferEvents: (editorView) ->
      buffer = editorView.editor.getBuffer()

      if buffer.file? and util.isMetadata(buffer.file.getBaseName())
        @subscribe buffer.on 'saved', =>
          params =
            args:
              operation: 'compile'
              pane: atom.workspace.getActivePane()
              editor: atom.workspace.getActiveEditor()
              editorView: atom.workspaceView.getActiveView()
              buffer: buffer
            payload:
              files: [buffer.file.path]
          @mm.run(params).then (result) =>
            @mmResponseHandler(params, result)
