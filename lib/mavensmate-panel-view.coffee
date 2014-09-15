{$, $$$, ScrollView, View} = require 'atom'
Convert = null
{Subscriber,Emitter} = require 'emissary'
emitter             = require('./mavensmate-emitter').pubsub
logFetcher          = require('./mavensmate-log-fetcher').fetcher
util                = require './mavensmate-util'
moment              = require 'moment'
pluralize           = require 'pluralize'
# interact  = require 'interact'

# The status panel that shows the result of command execution, etc.
class MavensMatePanelView extends View
  Subscriber.includeInto this

  fetchingLogs: false
  panelItems: []

  resizeStarted: =>
    $(document).on('mousemove', @resizePanelView)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizePanelView)
    $(document).off('mouseup', @resizeStopped)

  resizePanelView: (evt) =>
    return @resizeStopped() unless evt.which is 1
    # console.log evt
    # console.log evt
    height = jQuery("body").height() - evt.pageY - 10
    @height(height)

  handleEvents: ->
    @on 'mousedown', '.entry', (e) =>
      @onMouseDown(e)

    @on 'mousedown', '.mavensmate-panel-view-resize-handle', (e) => @resizeStarted(e)

  # Internal: Initialize mavensmate output view DOM contents.
  @content: ->
    @div tabIndex: -1, class: 'mavensmate mavensmate-output tool-panel panel-bottom native-key-bindings resize', =>
      @div class: 'mavensmate-panel-view-resize-handle', outlet: 'resizeHandle'
      @div class: 'panel-header', =>
        @div class: 'container-fluid', =>
          @div class: 'row', style: 'padding:10px 0px', =>
            @div class: 'col-md-6', =>
              @h3 'MavensMate Salesforce1 IDE for Atom.io', outlet: 'myHeader', class: 'clearfix', =>
            @div class: 'col-md-6', =>
              @span class: 'config', style: 'float:right', =>
                @button class: 'btn btn-sm btn-default btn-view-errors', outlet: 'btnViewErrors', =>
                  @i class: 'fa fa-bug', outlet: 'viewErrorsIcon'
                  @span '0 errors', outlet: 'viewErrorsLabel', style: 'display:inline-block;padding-left:5px;'
                @button class: 'btn btn-sm btn-default btn-fetch-logs', outlet: 'btnFetchLogs', =>
                  @i class: 'fa fa-refresh', outlet: 'fetchLogsIcon'
                  @span 'Fetch Logs', outlet: 'fetchLogsLabel', style: 'display:inline-block;padding-left:5px;'
      @div class: 'block padded mavensmate-panel', =>
        @div class: 'message', outlet: 'myOutput'

  # Internal: Initialize the mavensmate output view and event handlers.
  initialize: ->
    # @myOutput.html(@output).css('font-size', "#{atom.config.getInt('editor.fontSize')}px")
    me = @ # this

    @btnFetchLogs.click ->
      me.fetchingLogs = !me.fetchingLogs
      if me.fetchingLogs
        me.btnFetchLogs.removeClass 'btn-default'
        me.btnFetchLogs.addClass 'btn-success'
        me.fetchLogsIcon.addClass 'fa-spin'
        me.fetchLogsLabel.html 'Fetching Logs'
        logFetcher.start()
      else
        me.btnFetchLogs.removeClass 'btn-success'
        me.btnFetchLogs.addClass 'btn-default'
        me.fetchLogsIcon.removeClass 'fa-spin'
        me.fetchLogsLabel.html 'Fetch Logs'
        logFetcher.stop()

    # updates panel view font size(s) based on editor font-size updates (see mavensmate-atom-watcher.coffee)
    emitter.on 'mavensmate:font-size-changed', (newFontSize) ->
      jQuery('div.mavensmate pre.terminal').css('font-size', newFontSize)

    # event handler which creates a panelViewItem corresponding to the command promise requested
    emitter.on 'mavensmatePanelNotifyStart', (params, promiseId) ->
      command = util.getCommandName params
      if command not in util.panelExemptCommands() and not params.skipPanel # some commands are not piped to the panel
        params.promiseId = promiseId
        me.update command, params
      me.updateErrorsBtn()
      return

    # handler for finished operations
    # writes status to panel
    # displays colored indicator based on outcome
    emitter.on 'mavensmatePanelNotifyFinish', (params, result, promiseId) ->
      console.log 'finish!'
      console.log params
      console.log result

      promisePanelView = me.panelItems[promiseId]
      console.log promisePanelView
      promisePanelView.update me, params, result

    emitter.on 'mavensMateCompileFinished', (params) ->
      me.updateErrorsBtn()

    @handleEvents()

  # Internal: Update the mavensmate output view contents.
  #
  # output - A string of the test runner results.
  #
  # Returns nothing.
  update: (command, params) ->
    panelItem = new MavensMatePanelViewItem(command, params) # initiate new panel item
    @panelItems[params.promiseId] = panelItem # add panel to dictionary
    @myOutput.prepend panelItem # add panel item to panel

  # Internal: Detach and destroy the mavensmate output view.
  #           clear the existing panel items.
  # Returns nothing.
  destroy: ->
    $('.panel-item').remove()
    @unsubscribe()
    @detach()

  # Internal: Toggle the visibilty of the mavensmate output view.
  #
  # Returns nothing.
  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this) unless @hasParent() #todo: attach to specific workspace view

  countPanels: (commands) ->
    panelCount = 0
    console.log @panelItems
    for promiseId, panelViewItem of @panelItems
      if panelViewItem.command in commands and panelViewItem.running
        panelCount++
    return panelCount

  updateErrorsBtn: ->
    console.log '-----> updateErrorsBtn'
    panelsCompiling = @countPanels(util.compileCommands())

    numberOfErrors = util.numberOfCompileErrors()

    console.log(numberOfErrors)
    @viewErrorsLabel.html(numberOfErrors + ' ' + pluralize('error', numberOfErrors))

    if panelsCompiling == 0
      @viewErrorsIcon.removeClass 'fa-spin'
      if numberOfErrors == 0
        @btnViewErrors.addClass 'btn-default'
        @btnViewErrors.removeClass 'btn-error'
        @btnViewErrors.removeClass 'btn-warning'
      else
        @btnViewErrors.removeClass 'btn-default'
        @btnViewErrors.addClass 'btn-error'
        @btnViewErrors.removeClass 'btn-warning'        
    else
      @viewErrorsIcon.addClass 'fa-spin'
      @btnViewErrors.removeClass 'btn-default'
      @btnViewErrors.removeClass 'btn-error'
      @btnViewErrors.addClass 'btn-warning'

# represents a single operation/command within the panel
class MavensMatePanelViewItem extends View

  promiseId = null
  

  constructor: (command, params) ->
    super
    
    @command = command
    @running = true
    # set panel font-size to that of the editor
    fontSize = jQuery("div.editor-contents").css('font-size')
    @terminal.context.style.fontSize = fontSize
    
    # get the message
    message = @.panelCommandMessage params, util.isUiCommand params

    # scope this panel by the promiseId
    @promiseId = params.promiseId
    @item.attr 'id', @promiseId
    
    # write the message to the terminal
    @terminal.html message
    
  # Internal: Initialize mavensmate output view DOM contents.
  @content: ->
    @div class: 'panel-item',  =>
      @div outlet: 'item', =>
        @div class: 'container-fluid', =>
          @div class: 'row', =>
            @div class: 'col-md-12', =>
              @div =>
                @pre class: 'terminal active', outlet: 'terminal'

  initialize: ->

  update: (panel, params, result) ->
    me = @    
    if @command not in util.panelExemptCommands()
      panelOutput = @getPanelOutput params, result
      console.log 'panel output ---->'
      console.log panelOutput

      # update progress bar depending on outcome of command
      # me.progress.attr 'class', 'progress'
      # me.progressBar.attr 'class', 'progress-bar progress-bar-'+panelOutput.indicator
      me.terminal.removeClass 'active'
      me.terminal.addClass panelOutput.indicator

      # update terminal
      me.terminal.append '<br/>> '+ '<span id="message-'+@promiseId+'">'+panelOutput.message+'</span>'
      me.running = false
    return

  # returns the command message to be displayed in the panel
  panelCommandMessage: (params, isUi=false) ->
    console.log params
    
    if isUi
      switch @command
        when 'new_project'
          msg = 'Opening new project panel'
        when 'edit_project'
          msg = 'Opening edit project panel'
        else 
          msg = 'mm ' + @command
    else
      switch @command
        when 'new_project'
          msg =  'Creating new project'
        when 'compile_project'
          msg = 'Compiling project'
        when 'index_metadata'
          msg = 'Indexing metadata'
        when 'compile'
          if params.payload.files? and params.payload.files.length is 1
            msg = 'Compiling '+params.payload.files[0].split(/[\\/]/).pop() # extract base name
          else
            msg = 'Compiling selected metadata'
        when 'delete'
          if params.payload.files? and params.payload.files.length is 1
            msg = 'Deleting ' + params.payload.files[0].split(/[\\/]/).pop() # extract base name
          else
            msg = 'Deleting selected metadata'
        when 'refresh'
          if params.payload.files? and params.payload.files.length is 1
            msg = 'Refreshing ' + params.payload.files[0].split(/[\\/]/).pop() # extract base name
          else
            msg = 'Refreshing selected metadata'
        else
          msg = 'mm ' + @command

    header = '['+moment().format('MMMM Do YYYY, h:mm:ss a')+']<br/>'
    return header + '> ' + msg

  # transforms the JSON returned by the cli into an object with properties that conform to the panel
  #
  # output =
  #   message: '(Line 17) Unexpected token, yada yada yada'
  #   indicator: 'success' #warning, danger, etc. (bootstrap label class names)
  #   stackTrace: 'foo bar bat'
  #   isException: true
  #
  getPanelOutput: (params, result) ->
    console.log '~~~~~~~~~~~'
    console.log @command
    console.log params
    console.log result
    obj = null
    if params.args? and params.args.ui
      console.log 'cool!'
      obj = @getUiCommandOutput params, result
    else
      try
        switch @command
          when 'delete'
            obj = @getDeleteCommandOutput params, result
          when 'compile'
            obj = @getCompileCommandOutput params, result
          when 'compile_project'
            obj = @getCompileProjectCommandOutput params, result
          when 'run_all_tests', 'test_async'
            obj = @getRunAsyncTestsCommandOutput params, result
          when 'new_quick_trace_flag'
            obj = @getNewQuickTraceFlagCommandOutput params, result
          else
            obj = @getGenericOutput params, result
      catch
        obj = @getGenericOutput params, result

    return obj

  getDeleteCommandOutput: (params, result) ->
    if result.success
      obj = indicator: "success"
      if params.payload.files? and params.payload.files.length is 1
        obj.message = 'Deleted ' + util.baseName(params.payload.files[0])
      else
        obj.message = "Deleted selected metadata"
      return obj
    else
      @getErrorOutput params, result

  getUiCommandOutput: (params, result) ->
    console.log 'parsing ui'
    if result.success
      obj =
        message: 'UI generated successfully'
        indicator: 'success'
      return obj
    else
      return @getErrorOutput params, result

  getErrorOutput: (params, result) ->
    output =
      message: result.body
      indicator: 'danger'
      stackTrace: result.stackTrace
      isException: result.stackTrace?

  getGenericOutput: (params, result) ->
    if result.body? and result.success?
      output =
        message: result.body
        indicator: if result.success then 'success' else 'danger'
        stackTrace: result.stackTrace
        isException: result.stackTrace?
    else
      output =
        message: 'No result message could be determined'
        indicator: 'warning'
        stackTrace: result.stackTrace
        isException: result.stackTrace?

  getCompileCommandOutput: (params, result) ->
    console.log 'getCompileCommandOutput'
    obj =
      message: null
      indicator: null
      stackTrace: null
      isException: false

    filesCompiled = (util.baseName(filePath) for filePath in params.payload.files ? [])
    console.log filesCompiled
    for compiledFile in filesCompiled
      atom.project.errors[compiledFile] = []

    if result.State? # tooling
      if result.state is 'Error' and result.ErrorMsg?
        obj.message = result.ErrorMsg
        obj.success = false
      else if result.State is 'Failed' and result.CompilerErrors?
        if Object.prototype.toString.call result.CompilerErrors is '[object String]'
          result.CompilerErrors = JSON.parse result.CompilerErrors

        errors = result.CompilerErrors
        message = 'Compile Failed'
        for error in errors
          errorFileName = error.name + ".cls"
          if error.line?
            errorMessage = "#{errorFileName}: #{error.problem[0]} (Line: #{error.line[0]})"
            error.lineNumber = error.line[0]
          else
            errorMessage = "#{errorFileName}: #{error.problem}"
          message += '<br/>' + errorMessage

          atom.project.errors[errorFileName] ?= []
          atom.project.errors[errorFileName].push(error)
        obj.message = message
        obj.indicator = 'danger'
        emitter.emit 'mavensMateCompileFinished', params
      else if result.State is 'Failed' and result.DeployDetails?
        errors = result.DeployDetails.componentFailures
        message = 'Compile Failed'
        for error in errors
          errorFileName = error.fileName + ".cls"
          if error.lineNumber
            errorMessage = "#{errorFileName}: #{error.problem} (Line: #{error.lineNumber})"
          else
            errorMessage = "#{errorFileName}: #{error.problem}"
          message += '<br/>' + errorMessage

          atom.project.errors[errorFileName] ?= []
          atom.project.errors[errorFileName].push(error)
        obj.message = message
        obj.indicator = 'danger'
        emitter.emit 'mavensMateCompileFinished', params 
      else if result.State is 'Completed' and not result.ErrorMsg
        obj.indicator = 'success'
        obj.message = 'Success'
        emitter.emit 'mavensMateCompileFinished', params
      else
        #pass
    else if result.actions?
      # need to diff
      obj.message = result.body
      obj.indicator = 'warning'
    # else # metadata api
    #   #todo

    if !obj.message?
      throw 'unable to parse'

    return obj

  getCompileProjectCommandOutput: (params, result) ->
    obj =
      message: null
      indicator: null
      stackTrace: null
      isException: false

    if result.success?
      atom.project.errors = {}
      obj.success = result.success;
      if result.success
        obj.message = "Success"
        obj.indicator = 'success'
        emitter.emit 'mavensMateCompileFinished', params
      else
        errors = result.Messages
        obj.indicator = 'danger'

        message = 'Compile Project Failed'
        for error in errors
          errorFileName = util.baseName(error.fileName)
          errorMessage = "#{errorFileName}: #{error.problem} (Line: #{error.lineNumber}, Column: #{error.columnNumber})"
          message += '<br/>' + errorMessage

          atom.project.errors[errorFileName] ?= []
          atom.project.errors[errorFileName].push(error)
        console.log("Emitting mavensMateCompileFinished")
        console.log(atom.project.errors)
        emitter.emit 'mavensMateCompileFinished', params

        obj.message = message
        obj.indicator = 'danger'
    return obj

  getRunAsyncTestsCommandOutput: (params, result) ->
    obj =
      message: null
      indicator: 'warning'
      stackTrace: ''
      isException: false

    passCounter = 0
    failedCounter = 0

    for apexClass in result
      for test in apexClass.detailed_results
        if test.Outcome == "Fail"
          failedCounter++
          obj.message = "#{failedCounter} failed test method"
          obj.message += 's' if failedCounter > 1
          obj.stackTrace += "#{test.ApexClass.Name}.#{test.MethodName}:\n#{test.StackTrace}\n\n"
        else
          passCounter++


    if failedCounter == 0
      obj.message = "Run all tests complete. #{passCounter} test" + (if passCounter > 1 then "s " else " ") + "passed."
      obj.indicator = 'success'
    else
      obj.indicator = 'danger'
      obj.isException = true

    return obj

  getNewQuickTraceFlagCommandOutput: (params, result) ->
    obj =
      message: null
      indicator: 'warning'
      stackTrace: ''
      isException: false

    if result.success is false
      obj.indicator = 'danger'
      obj.isException = true
      obj.stackTrace = result.stack_trace
    else
      obj.indicator = 'success'

    obj.message = result.body
    return obj

panel = new MavensMatePanelView()
exports.panel = panel
