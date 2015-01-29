{$, $$, $$$, View}    = require 'atom-space-pen-views'
fs                    = require 'fs'
path                  = require 'path'
{Subscriber,Emitter}  = require 'emissary'

MavensMateConfig                    = require('./mavensmate-config').config
MavensMateEventEmitter              = require('./mavensmate-emitter').pubsub
MavensMateCoreAdapter               = require('./mavensmate-core-adapter')
MavensMateProjectListView           = require './mavensmate-project-list-view'
MavensMateErrorMarkers              = require './mavensmate-error-markers'
MavensMatePanelView                 = require('./panel/panel-view').panel
MavensMateStatusBarView             = require './mavensmate-status-bar-view'
MavensMateLogFetcher                = require './mavensmate-log-fetcher'
MavensMateIFrameView                = require('./mavensmate-salesforce-view').IFrameView
MavensMateBrowserView               = require('./mavensmate-salesforce-view').BrowserView
tracker                             = require('./mavensmate-promise-tracker').tracker
util                                = require './mavensmate-util'
emitter                             = require('./mavensmate-emitter').pubsub
commands                            = require './commands.json'
{exec}                              = require 'child_process'
ErrorsView                          = require './mavensmate-errors-view'
atom.mavensmate = {}
window.jQuery = $

require '../scripts/bootstrap'

MavensMateAtomWatcher = require('./watchers/atom-watcher').watcher

module.exports =

  class MavensMate
    self = @
    Subscriber.includeInto this

    editorSubscription: null
    autocomplete: null
    providers: []

    panel: null # mavensmate status panel
    mavensmateAdapter: null
    errorsView: null

    tabViewUri: 'mavensmate://tabView'

    errorsDeserializer:
      name: 'MavensMateErrorsView'
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

      # instantiate mavensmate panel, show it
      self.panel = MavensMatePanelView
      self.panel.toggle()

      # opens Salesforce.com URL in an Atom tab
      atom.workspace.addOpener (uri, params) ->
        self.createSalesforceView(params) if uri is 'mavensmate://salesforceView'

      # opens Salesforce.com URL in an Atom browser window
      atom.workspace.addOpener (uri, params) ->
        self.createSalesforceBrowserView(params) if uri is 'mavensmate://salesforceBrowserView'

      atom.workspace.mavensMateProjectInitialized ?= false

      # instantiate client interface
      self.mavensmateAdapter = MavensMateCoreAdapter
      self.mavensmateAdapter.initialize()
      atom.mavensmate.adapter = self.mavensmateAdapter
      self.projectCommands = commands.projectCommands

      atom.commands.add 'atom-workspace', 'mavensmate:new-project', => @newProject()
      atom.commands.add 'atom-workspace', 'mavensmate:open-project', => @openProject()

      atom.project.onDidChangePaths => @onProjectPathChanged()

      self.initializeProject()

      self.createErrorsView(util.uris.errorsView)
      atom.workspace.addOpener (uri) ->
        self.errorsView if uri is util.uris.errorsView

      atom.deserializers.add(@errorsDeserializer)

      atom.commands.add 'atom-workspace', 'mavensmate:view-errors', ->
        atom.workspaceView.open(util.uris.errorsView)

    newProject: ->
      params = {}
      params.args = {}
      params.args.operation = 'new-project'
      params.args.url = 'project/new'
      @mavensmateAdapter.openUI(params)

    openProject: ->
      @selectList = new MavensMateProjectListView()
      @selectList.toggle()

    createErrorsView: (params) ->
      @errorsView = new ErrorsView(params)

    createSalesforceView: (params) ->
      salesforceView = new MavensMateIFrameView(params)

    createSalesforceBrowserView: (params) ->
      salesforceBrowserView = new MavensMateBrowserView(params)

    onProjectPathChanged: ->
      if util.hasMavensMateProjectStructure() and not atom.workspace.mavensMateProjectInitialized
        atom.workspace.mavensMateProjectInitialized = true
        @initializeProject()
      else
        console.log('not a mavensmate project or already initialized')

    initializeProject: ->
      self = @
      atom.project.mavensMateErrors = {}
      atom.project.mavensMateCheckpointCount = 0
      if atom.project.path
        console.log 'initializing project from mavensmate.coffee --> '+atom.project.path

        self.mavensmateAdapter.setProject(atom.project.path)
          .then (result) ->
            logFetcher = new MavensMateLogFetcher(self.mavensmateAdapter.client.getProject())
            # attach MavensMate views/handlers to each present and future workspace editor views
            atom.workspace.eachEditor (editor) ->
              self.handleBufferEvents editor
          .catch (err) ->
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
              self.mmResponseHandler(params, result)
            .catch (err) ->
              self.mmResponseHandler(params, err)


      # attach commands to workspace based on commands.json
      for commandName, command of @projectCommands
        resolvedName = 'mavensmate:' + commandName

        atom.commands.add 'atom-workspace', resolvedName, (options) =>
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
            # console.log 'command payload: '
            # console.log payload
            if Object.keys(payload).length != 0
              params.payload = payload
            # console.log(params.payload)

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
                    self.mmResponseHandler(params, result)
                  .catch (err) ->
                    self.mmResponseHandler(params, err)

      # places mavensmate 3 dot icon in the status bar
      createStatusEntry = =>
        @mavensmateStatusBar = new MavensMateStatusBarView(@panel)

      if atom.workspace.statusBar
        createStatusEntry()
      else
        atom.packages.once 'activated', ->
          createStatusEntry()

      # we rely upon autocomplete plus right now
      if !util.isAutocompletePlusInstalled()
        @installAutocompletePlus()
      else
        @enableAutocomplete()

    installAutocompletePlus: ->
      # cmd = "#{atom.packages.getApmPath()} install autocomplete-plus"
      # exec cmd, @enableAutocomplete

    enableAutocomplete: ->
      atom.packages.activatePackage("autocomplete-plus")
        .then (pkg) =>
          @autocomplete = pkg.mainModule
          @registerProviders()

    registerProviders: ->
      MavensMateCodeAssistProviders = require './mavensmate-code-assist-providers'

      @editorSubscription = atom.workspace.eachEditor (editor) ->
        if editor.attached and not editor.mini
          apexProvider = new MavensMateCodeAssistProviders.ApexProvider(editor.editor)
          @autocomplete.registerProviderForEditor apexProvider, editor.editor
          @providers.push apexProvider

          vfTagProvider = new MavensMateCodeAssistProviders.VisualforceTagProvider(editor.editor)
          @autocomplete.registerProviderForEditor vfTagProvider, editor.editor
          @providers.push vfTagProvider

          # vfTagContextProvider = new MavensMateCodeAssistProviders.VisualforceTagContextProvider(editor)
          # @autocomplete.registerProviderForEditorView vfTagContextProvider, editor
          # @providers.push vfTagContextProvider

          # apexContextProvider = new MavensMateCodeAssistProviders.ApexContextProvider(editor)
          # @autocomplete.registerProviderForEditorView apexContextProvider, editor
          # @providers.push apexContextProvider

          # sobjectProvider = new MavensMateCodeAssistProviders.SobjectProvider(editor)
          # @autocomplete.registerProviderForEditorView sobjectProvider, editor
          # @providers.push sobjectProvider

    # Public: Deactivate the package and destroy the mavensmate views.
    #
    # Returns nothing.
    destroy: ->
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
      MavensMateEventEmitter.emit 'mavensmate:promise-completed', result.promiseId
      MavensMateEventEmitter.emit 'mavensmate:panel-notify-finish', params, result, result.promiseId

    handleBufferEvents: (editor) ->
      console.log 'subscribing to buffer events for editor: '
      console.log editor
      self = @
      buffer = editor.getBuffer()
      # console.log buffer.file
      # console.log buffer.file.path
      if buffer.file? and util.isMetadata(buffer.file.path)
        @subscribe buffer.on 'saved', ->
          console.log('SAVED')
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
              self.mmResponseHandler(params, result)
            .catch (err) ->
              self.mmResponseHandler(params, err)