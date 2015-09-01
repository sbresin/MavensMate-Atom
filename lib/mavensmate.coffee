{$, $$, $$$, View}    = require 'atom-space-pen-views'
window.jQuery         = $
fs                    = require 'fs'
path                  = require 'path'
{exec}                = require 'child_process'
{Subscriber,Emitter}  = require 'emissary'
EventEmitter          = require('./emitter').pubsub
CoreAdapter           = require('./adapter')
ProjectListView       = require './project-list-view'
ErrorMarkers          = require './error-markers'
PanelView             = require('./panel/panel-view').panel
StatusBarView         = require './status-bar-view'
LogFetcher            = require './log-fetcher'
IFrameView            = require('./salesforce-view').IFrameView
BrowserView           = require('./salesforce-view').BrowserView
tracker               = require('./promise-tracker').tracker
util                  = require './util'
emitter               = require('./emitter').pubsub
commands              = require './commands.json'
ErrorsView            = require './errors-view'
atom.mavensmate       = {}
AtomWatcher           = require('./watchers/atom-watcher').watcher

require '../scripts/bootstrap'

module.exports =

  class MavensMate
    self = @
    Subscriber.includeInto this

    editorSubscription: null
    apexAutocompleteRegistration: null
    vfAutocompleteRegistration: null

    panel: null # mavensmate status panel
    mavensmateAdapter: null
    errorsView: null

    tabViewUri: 'mavensmate://tabView'

    errorsDeserializer:
      name: 'ErrorsView'
      version: 1
      deserialize: (state) ->
        self.createErrorsView(state) if state.constructor is Object

    constructor: ->
      console.log 'Creating new instance of MavensMate plugin...'
      
      # temporary hack to workaround cert issues introduced by chrome 39
      # (https://github.com/joeferraro/MavensMate-Atom/issues/129#issuecomment-69847533)
      process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'
      
      # initiate mavensmate for this atom workspace
      @init()

    # Activates the package, instantiates the views, etc.
    #
    # Returns nothing.
    init: ->
      self = @

      if atom.project? and atom.project.getPaths().length > 0 and util.hasMavensMateProjectStructure()
        self.panel = PanelView
        self.panel.addPanelViewItem('Initializing MavensMate, please wait...', 'info')

        self.mavensmateAdapter = CoreAdapter
        self.mavensmateAdapter.initialize()
          .then(() ->
            atom.mavensmate.adapter = self.mavensmateAdapter
            atom.project.mavensmateId = util.fileBodyAsString(path.join(atom.project.getPaths()[0], 'config', '.settings'), true).id
            atom.workspace.mavensMateProjectInitialized ?= false

            self.registerApplicationCommands()
            # atom.commands.add 'atom-workspace', 'mavensmate:open-project', => self.openProject()

            atom.project.onDidChangePaths => @onProjectPathChanged()
            
            self.initializeProject()
          )
          .catch((err) ->
            self.panel.addPanelViewItem(err, 'danger')
            self.panel.toggle()
          )

    openProject: ->
      @selectList = new ProjectListView()
      @selectList.show()

    createErrorsView: (params) ->
      @errorsView = new ErrorsView(params)

    createSalesforceView: (params) ->
      salesforceView = new IFrameView(params)

    createSalesforceBrowserView: (params) ->
      salesforceBrowserView = new BrowserView(params)

    onProjectPathChanged: ->
      if util.hasMavensMateProjectStructure() and not atom.workspace.mavensMateProjectInitialized
        atom.workspace.mavensMateProjectInitialized = true
        @initializeProject()
      else
        console.log('not a mavensmate project or already initialized')

    initializeProject: ->
      self = @
      # TODO: use atom.project.getPaths()
      atom.project.mavensMateErrors = {}
      atom.project.mavensMateCheckpointCount = 0
      # instantiate mavensmate panel, show it
      self.panel.toggle()

      console.log 'initializing project from mavensmate.coffee --> '+atom.project.getPaths()

      self.panel.addPanelViewItem('MavensMate initialized successfully. Happy coding!', 'success')
      # logFetcher = new LogFetcher(self.mavensmateAdapter.client.getProject())
      # attach MavensMate views/handlers to each present and future workspace editor views
      atom.workspace.observeTextEditors (editor) ->
        self.handleBufferEvents editor
        self.registerGrammars editor

      # instantiate client interface
      self.registerProjectCommands()

      # places mavensmate 3 dot icon in the status bar
      @mavensmateStatusBar = new StatusBarView(self.panel)
      
      self.createErrorsView(util.uris.errorsView)
      atom.workspace.addOpener (uri) ->
        self.errorsView if uri is util.uris.errorsView

      atom.deserializers.add(self.errorsDeserializer)

      atom.commands.add 'atom-workspace', 'mavensmate:view-errors', ->
        atom.workspace.open(util.uris.errorsView)

      # attach commands
      atom.commands.add 'atom-workspace', 'mavensmate:toggle-output', ->
        self.panel.toggleView()

      # deletes file(s) from server
      atom.commands.add 'atom-workspace', 'mavensmate:delete-file-from-server', ->
        treeView = util.treeView()
        if treeView.hasFocus() # clicked in sidebar
          filePaths = treeView.selectedPaths()
        else # command palette or right click in editor
          filePaths = [util.activeFile()]
        params =
          command: 'delete-metadata'
          args:
            pane: atom.workspace.getActivePane()
          payload:
            paths: filePaths
        fileString = (filePaths.map (path) -> util.baseName(path)).join(', ')
        answer = atom.confirm
          message: "Are you sure you want to delete #{fileString} from Salesforce?"
          # NB: specs expects the following buton indices, 0: Cancel, 1: Delete
          #     so that we can simulate button clicks properly in the spec
          buttons: ["Cancel", "Delete"]
        if answer == 1 # 1 => Delete
          self.mavensmateAdapter.executeCommand(params)
            .then (result) ->
              self.adapterResponseHandler(params, result)
            .catch (err) ->
              self.adapterResponseHandler(params, err)

    registerApplicationCommands: ->
      for commandName, command of commands.applicationCommands
        resolvedName = 'mavensmate:' + commandName

        atom.commands.add 'atom-workspace', resolvedName, (options) ->
          commandName = options.type.split(':').pop()
          command = commands.applicationCommands[commandName]
          if command?
            params =
              command: command.name
              args:
                pane: atom.workspace.getActivePane()

            payload = {}
            payload.args = {}

            if 'ui' of command
              payload.args.ui = command.ui

            if Object.keys(payload).length != 0
              params.payload = payload

            self.mavensmateAdapter.executeCommand(params)
              .then (result) ->
                self.adapterResponseHandler(params, result)
              .catch (err) ->
                self.adapterResponseHandler(params, err)

    registerProjectCommands: ->
      # attach commands to workspace based on commands.json
      for commandName, command of commands.projectCommands
        resolvedName = 'mavensmate:' + commandName

        atom.commands.add 'atom-workspace', resolvedName, (options) ->
          commandName = options.type.split(':').pop()
          command = commands.projectCommands[commandName]
          if command?
            params =
              command: command.name
              args:
                pane: atom.workspace.getActivePane()

            if 'view' of command
              params.args.view = command.view
            if 'url' of command
              params.args.url = command.url
            else
              params.args.view = 'modal'

            payload = {}
            payload.args = {}
            
            if 'ui' of command
              payload.args.ui = command.ui
            if 'paths' of command
              switch command['paths']
                when 'active'
                  payload.paths = [util.activeFile()]
                when 'selected'
                  payload.paths = util.getSelectedFiles()
            if 'classes' of command
              switch command['classes']
                when 'activeBaseName'
                  if util.activeFile().indexOf('.cls') >= 0
                    payload.classes = [util.activeFileBaseName().split('.')[0]]
            if 'payloadMetadata' of command
              payload.metadata_type = command.payloadMetadata
            if 'payloadPreview' of command
              payload.preview = command.payloadPreview
          
            if Object.keys(payload).length != 0
              params.payload = payload

            answer = 0
            if command.confirm?
              answer = atom.confirm
                message: command.confirm.message
                detailedMessage: command.confirm.detailedMessage
                buttons: command.confirm.buttons
            if answer == 0 # Yes
              self.mavensmateAdapter.executeCommand(params)
                .then (result) ->
                  self.adapterResponseHandler(params, result)
                .catch (err) ->
                  self.adapterResponseHandler(params, err)

    adapterResponseHandler: (params, result) ->
      tracker.pop(result.promiseId).result
      EventEmitter.emit 'mavensmate:promise-completed', result.promiseId
      EventEmitter.emit 'mavensmate:panel-notify-finish', params, result, result.promiseId

    # ensures custom extensions load the correct atom grammar file
    # TODO: refactor
    registerGrammars: (editor) ->
      self = @
      buffer = editor.getBuffer()
      if buffer.file?
        ext = path.extname(buffer.file.path)
        if ext == '.auradoc' || ext == '.app' || ext == '.evt' || ext == '.cmp' || ext == '.object'
          editor.setGrammar atom.syntax.grammarForScopeName('text.xml')

    # watches active editors for events like save
    handleBufferEvents: (editor) ->
      self = @
      buffer = editor.getBuffer()
      if buffer.file? and util.isMetadata(buffer.file.path) and atom.config.get('MavensMate-Atom').mm_compile_on_save
        editor.onDidSave () ->
          params =
            command: 'compile-metadata'
            args:
              pane: atom.workspace.getActivePane()
              textEditor: atom.workspace.getActiveTextEditor()
              buffer: buffer
            payload:
              paths: [buffer.file.path]
          self.mavensmateAdapter.executeCommand(params)
            .then (result) ->
              self.adapterResponseHandler(params, result)
            .catch (err) ->
              self.adapterResponseHandler(params, err)

    # Deactivate the package and destroy the mavensmate views.
    destroy: ->
      # remove MavensMate items from the status bar
      @mavensmateStatusBar?.destroy()
      @mavensmateStatusBar = null

      # remove the MavensMate panel
      if panel?
        @panel.destroy()
        @panel = null

      #unsubscribe from all listeners
      @unsubscribe()