{$, View} = require 'atom'
{Subscriber,Emitter} = require 'emissary'
emitter             = require('../mavensmate-emitter').pubsub
util                = require '../mavensmate-util'
moment              = require 'moment'

module.exports =
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
        # console.log 'panel output ---->'
        # console.log panelOutput

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
      # console.log params
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
      console.log msg
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
      # console.log '~~~~~~~~~~~'
      # console.log command
      # console.log params
      # console.log result
      obj = null
      if params.args? and params.args.ui
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
            when 'clean_project'
              obj = @getGenericOutput params, result
              atom.project.errors = {}
            when 'refresh'
              obj = @getGenericOutput params, result
              filesRefreshed = (util.baseName(filePath) for filePath in params.payload.files ? [])
              for refreshedFile in filesRefreshed
                atom.project.errors[refreshedFile] = []
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
        @getErrorOutput  params, result

    getUiCommandOutput: ( params, result) ->
      # console.log 'parsing ui'
      if result.success
        obj =
          message: 'UI generated successfully'
          indicator: 'success'
        return obj
      else
        return @getErrorOutput  params, result

    getErrorOutput: ( params, result) ->
      output =
        message: result.body
        indicator: 'danger'
        stackTrace: result.stackTrace
        isException: result.stackTrace?

    getGenericOutput: ( params, result) ->
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

    getCompileCommandOutput: ( params, result) ->
      console.log 'getCompileCommandOutput'
      console.log JSON.stringify(result)
      obj =
        message: null
        indicator: null
        stackTrace: null
        isException: false

      filesCompiled = {}

      for filePath in params.payload.files
        fileNameBase = util.baseName(filePath)
        fileNameWithoutExtension = util.withoutExtension(fileNameBase)
        compiledFile = {}
        compiledFile.filePath = filePath
        compiledFile.fileNameWithoutExtension = fileNameWithoutExtension
        compiledFile.fileNameBase = fileNameBase
        filesCompiled[fileNameWithoutExtension] = compiledFile

        atom.project.errors[filePath] = []
      for filePath, errors of atom.project.errors
        fileNameBase = util.baseName(filePath)
        fileNameWithoutExtension = util.withoutExtension(fileNameBase)

        if not filesCompiled[fileNameWithoutExtension]?
          compiledFile = {}
          compiledFile.filePath = filePath
          compiledFile.fileNameWithoutExtension = fileNameWithoutExtension
          compiledFile.fileNameBase = fileNameBase
          filesCompiled[fileNameWithoutExtension] = compiledFile

      errorsByFilePath = {}  

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
            if filesCompiled[error.name]?
              error.fileName = filesCompiled[error.name].fileNameBase
              error.filePath = filesCompiled[error.name].filePath
            else            
              error.fileName = error.name
              error.filePath = error.name
            if error.line?
              errorMessage = "#{error.fileName}: #{error.problem[0]} (Line: #{error.line[0]})"
              error.lineNumber = error.line[0]
            else
              errorMessage = "#{error.fileName}: #{error.problem}"
            message += '<br/>' + errorMessage

            errorsByFilePath[error.filePath] ?= []
            errorsByFilePath[error.filePath].push(error)
          obj.message = message
          obj.indicator = 'danger'        
        else if result.State is 'Failed' and result.DeployDetails?
          errors = result.DeployDetails.componentFailures
          message = 'Compile Failed'
          for error in errors
            errorName = error.fileName || error.fullName || error.name
            if filesCompiled[errorName]?
              error.fileName = filesCompiled[errorName].fileNameBase
              error.filePath = filesCompiled[errorName].filePath
            else         
              error.fileName = errorName
              error.filePath = errorName
            if error.lineNumber
              errorMessage = "#{error.fileName}: #{error.problem} (Line: #{error.lineNumber})"
            else
              errorMessage = "#{error.fileName}: #{error.problem}"
            message += '<br/>' + errorMessage
  
            errorsByFilePath[error.filePath] ?= []
            errorsByFilePath[error.filePath].push(error)

          obj.message = message
          obj.indicator = 'danger'
        else if result.State is 'Completed' and not result.ErrorMsg
          obj.indicator = 'success'
          obj.message = 'Success'
        else
          #pass
      else if result.actions?
        # need to diff
        obj.message = result.body
        obj.indicator = 'warning'
      # else # metadata api
      #   #todo
      for filePath, errors of errorsByFilePath
        fileNameBase = util.baseName(filePath)
        fileNameWithoutExtension = util.withoutExtension(fileNameBase)
        if atom.project.errors[fileNameWithoutExtension]?
          delete atom.project.errors[fileNameWithoutExtension]
        atom.project.errors[filePath] = errors
      if !obj.message?
        throw 'unable to parse'

      return obj

    getCompileProjectCommandOutput: ( params, result) ->
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
          emitter.emit 'mavensmateCompileSuccessBufferNotify', params
        else
          if result.Messages?
            errors = result.Messages
            obj.indicator = 'danger'

            message = 'Compile Project Failed'
            for error in errors
              error.returnedPath = error.fileName
              error.fileName = util.baseName(error.returnedPath)
              treePath = './' + error.returnedPath.replace('unpackaged', 'src')
              error.filePath = atom.project.resolve(treePath)
              if error.lineNumber? and error.columnNumber?
                errorMessage = "#{error.fileName}: #{error.problem} (Line: #{error.lineNumber}, Column: #{error.columnNumber})"
              else 
                lineColumnRegEx = /line\s(\d+)\scolumn\s(\d+)/
                match = lineColumnRegEx.exec(error.problem)
                if match? and match.length > 2
                  error.lineNumber = match[1]
                  error.columnNumber = match[2]
                errorMessage = "#{error.fileName}: #{error.problem}"
              message += '<br/>' + errorMessage

              atom.project.errors[error.filePath] ?= []
              atom.project.errors[error.filePath].push(error)
          else
            message = 'Compile Project Failed To Compile'
            message += '<br/>' + result.body
            obj.stackTrace = result.stack_trace
            obj.isException = result.stack_trace?

          obj.message = message
          obj.indicator = 'danger'
      return obj

    getRunAsyncTestsCommandOutput: ( params, result) ->
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

    getNewQuickTraceFlagCommandOutput: ( params, result) ->
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
