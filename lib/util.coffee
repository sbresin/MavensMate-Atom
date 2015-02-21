_             = require 'underscore-plus'
_.str         = require 'underscore.string'
fs            = require 'fs'
os            = require 'os'
path          = require 'path'
CoreAdapter   = require('./adapter')
BrowserView   = require('./salesforce-view').BrowserView

module.exports =

  class MMUtil

    # returns the active file path
    @activeFile: ->
      editor = atom.workspace.getActivePaneItem()
      file = editor?.buffer.file
      file?.path

    # returns base name for active file
    @activeFileBaseName: ->
      editor = atom.workspace.getActivePaneItem()
      file = editor?.buffer?.file
      file?.getBaseName()

    # returns base name for file path
    # e.g. /workspace/MyApexClass.cls -> MyApexClass.cls
    @baseName: (filePath) ->
      filePath.split(/[\\/]/).pop()

    # takes a url and attempts to return the base salesforce url
    @baseSalesforceUrl: (url) ->
      # e.g., https://na14.salesforce.com/services/Soap/u/30.0/00Dd0000000cRQK
      return _.str.strLeftBack(url, '/services/')

    @extension: (filePath) ->
      '.' + filePath.split(/[.]/).pop()

    # takes a file path and returns it as a string or object (synchronously)
    @fileBodyAsString: (path, parseAsJson = false) ->
      fileBody = fs.readFileSync path
      if parseAsJson
        return JSON.parse fileBody
      else
        return fileBody

    # returns the fully resolved file path given a path relative to the root of the project
    @filePathFromTreePath: (treePath) ->
      atom.project.resolve('./' + treePath)

    # returns the name of the command
    # useful because the command can reside in args or payload
    @getCommandName: (params) ->
      if params.args? and params.args.operation?
        params.args.operation
      else
        params.payload.command

    # filters the selected items against metadata extensions
    @getSelectedFiles: ->
      selectedFilePaths = []
      apex_file_extensions = atom.config.get('MavensMate-Atom').mm_apex_file_extensions
      treeView = this.treeView()
      if treeView.hasFocus() # clicked in sidebar
        filePaths = treeView.selectedPaths()
      else # command palette or right click in editor
        filePaths = [this.activeFile()]
      for filePath in filePaths
        if this.extension(filePath) in apex_file_extensions
          selectedFilePaths.push(filePath)
      return selectedFilePaths

    @openUrlInAtom: (params, split = 'right') ->
      resource = Object.keys(params.result)[0]
      # console.log 'RESOURCE IS: '+resource
      params.textEditor = atom.workspace.getActiveEditor()
      if resource.indexOf('.page') >= 0
        params.split = split
        atom.workspace.open('mavensmate://salesforceView', params)
      # else
      #   # params.split = split
      #   # atom.workspace.open('mavensmate://salesforceBrowserView', params) --> this currently crashes Atom, ostensibly due to an atom-shell issue
      #   # browserView = new BrowserView(params)
      #   # atom.workspace.addRightPanel(item:browserView)

    # whether the given file is a trigger or apex class
    @isClassOrTrigger: (currentFile) ->
      return currentFile? and (currentFile.indexOf('.trigger') >= 0 or currentFile.indexOf('.cls') >= 0)

    # returns true if on linux
    @isLinux: ->
      @platform() == 'linux'

    # returns true if on mac
    @isMac: ->
      @platform() == 'osx'

    @hasMavensMateProjectStructure: (filePath=atom.project.getPath()) ->
      try
        settingsPath = path.join filePath, 'config', '.settings'
        return fs.existsSync(settingsPath)
      catch
        return false
        
    @isMetadata: (filePath) ->
      console.log 'checking whether file is valid sfdc metadata: '+filePath
      apex_file_extensions = atom.config.get('MavensMate-Atom').mm_apex_file_extensions
      return (path.extname(filePath) in apex_file_extensions || path.basename(path.dirname(path.dirname(filePath))) == 'aura') and path.basename(path.dirname(filePath)) != 'config'

    # whether the given command is a request for a ui
    @isUiCommand: (params) ->
      if params.args? and params.args.ui?
        params.args.ui
      else
        false

    # returns true if on windows
    @isWindows: ->
      @platform() == 'windows'

    # returns full path to the mm core api
    # the default value for mm_path is "default" which refers to ~/.atom/storage (on osx)
    # if mm_path is custom (not default), this will return the full path to the executable
    @mmHome: ->
      if atom.config.get('MavensMate-Atom.mm_path') == 'default'
        path.join(atom.getConfigDirPath(), 'storage')
      else
        atom.config.get('MavensMate-Atom.mm_path')

    @isStandardMmConfiguration: ->
      atom.config.get('MavensMate-Atom.mm_path') == 'default'

    # returns full path for atom package home
    @mmPackageHome: ->
      atom.packages.resolvePackagePath('MavensMate-Atom')

    # ui commands that use a modal (others use an atom pane)
    @modalCommands: ->
      [
        'new-project',
        'edit-project',
        'deploy',
        'new-metadata'
      ]

    # compile-related commands
    @compileCommands: ->
      [
        'compile-metadata',
        'compile-project',
        'clean-project',
        'refresh-metadata'
      ]

    @numberOfCompileErrors: (fileName) ->
      numberOfErrors = 0
      if fileName?
        numberOfErrors = atom.project.mavensMateErrors[fileName].length
      else
        for fileName, errors of atom.project.mavensMateErrors
          numberOfErrors += errors.length
      return numberOfErrors

    # list of commands that do not have status displayed in the panel
    @panelExemptCommands: ->
      [
        'get-indexed_metadata',
        'deploy',
        'session',
        'new-apex-overlay',
        'delete-apex-overlay',
        'index-apex-overlays',
        'new-metadata',
        'unit-test',
        'list-metadata',
        'edit-project'
      ]

    # returns platform flag (windows|osx|linux[default])
    @platform: ->
      return 'windows' if process.platform == 'win32'
      return 'osx' if process.platform == 'darwin'
      return 'linux'

    # setting object to configure MavensMate for future SFDC updates
    @sfdcSettings:
      maxCheckpoints: 5

    # returns tree view
    @treeView: ->
      atom.workspaceView.find('.tree-view').view()

    @typeIsArray: (value) ->
      Array.isArray or (value) ->
        {}.toString.call(value) is "[object Array]"

    @withoutExtension: (filePath) ->
      filePath.split(/[.]/).shift()

    @uris:
      errorsView: 'mavensmate://errorsView'