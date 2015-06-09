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

      self.mavensmateAdapter = CoreAdapter
      self.mavensmateAdapter.initialize()
      atom.mavensmate.adapter = self.mavensmateAdapter

      # opens Salesforce.com URL in an Atom tab
      atom.workspace.addOpener (uri, params) ->
        self.createSalesforceView(params) if uri is 'mavensmate://salesforceView'

      # opens Salesforce.com URL in an Atom browser window
      atom.workspace.addOpener (uri, params) ->
        self.createSalesforceBrowserView(params) if uri is 'mavensmate://salesforceBrowserView'

      atom.workspace.mavensMateProjectInitialized ?= false

      atom.commands.add 'atom-workspace', 'mavensmate:new-project', => @newProject()
      atom.commands.add 'atom-workspace', 'mavensmate:open-project', => @openProject()

      atom.project.onDidChangePaths => @onProjectPathChanged()
      
      self.initializeProject()

    newProject: ->
      params = {}
      params.args = {}
      params.args.operation = 'new-project'
      params.args.url = 'project/new'
      @mavensmateAdapter.openUI(params)

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
      if atom.project? and atom.project.getPaths().length > 0 and util.hasMavensMateProjectStructure()
        self.panel = PanelView
        self.panel.addPanelViewItem('Initializing MavensMate project, please wait...', 'info')
        atom.project.mavensMateErrors = {}
        atom.project.mavensMateCheckpointCount = 0
        # instantiate mavensmate panel, show it
        self.panel.toggle()

        console.log 'initializing project from mavensmate.coffee --> '+atom.project.getPaths()

        self.mavensmateAdapter.setProject(atom.project.getPaths()[0])
          .then (result) ->
            self.panel.addPanelViewItem('MavensMate project initialized successfully. Happy coding!', 'success')
            logFetcher = new LogFetcher(self.mavensmateAdapter.client.getProject())
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

          .catch (err) ->
            console.error 'error activating mavensmate project'
            console.error err.message
            console.error err.stack
            if self.panel?
              self.panel.addPanelViewItem('Could not activate MavensMate project. MavensMate will not function correctly.<br/>'+err.message.replace(/Error:/g, '<br/>Error:'), 'danger')

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
          args:
            operation: 'delete-metadata'
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

    registerProjectCommands: ->
      # attach commands to workspace based on commands.json
      for commandName, command of commands.projectCommands
        resolvedName = 'mavensmate:' + commandName

        atom.commands.add 'atom-workspace', resolvedName, (options) ->
          commandName = options.type.split(':').pop()
          command = commands.projectCommands[commandName]
          if command?
            params =
              args:
                operation: command.operation
                pane: atom.workspace.getActivePane()

            if 'ui' of command
              params.args.ui = command.ui
            if 'view' of command
              params.args.view = command.view
            if 'url' of command
              params.args.url = command.url
            else
              params.args.view = 'modal'

            payload = {}
            if 'payloadFiles' of command
              switch command['payloadFiles']
                when 'active'
                  payload.paths = [util.activeFile()]
                when 'selected'
                  payload.paths = util.getSelectedFiles()
            if 'payloadClasses' of command
              switch command['payloadClasses']
                when 'activeBaseName'
                  if util.activeFile().indexOf('.cls') >= 0
                    payload.classes = [util.activeFileBaseName().split('.')[0]]
            if 'payloadMetadata' of command
              payload.metadata_type = command.payloadMetadata
            if 'payloadPreview' of command
              payload.preview = command.payloadPreview
          
            if Object.keys(payload).length != 0
              params.payload = payload

            if params.args.ui
              self.mavensmateAdapter.openUI(params)
            else
              answer = 0
              if command.confirm?
                answer = atom.confirm
                  message: command.confirm.message
                  detailedMessage: command.confirm.message
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
            args:
              operation: 'compile-metadata'
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