{$, $$, View, ScrollView} = require 'atom-space-pen-views'
emitter                   = require('./emitter').pubsub
util                      = require './util'
pluralize                 = require 'pluralize'
fs                        = require 'fs'
shell                     = require 'shell'


module.exports =
class ErrorsView extends ScrollView
  constructor: ->
    super
    errorsView = @
    @running = {}
    @running['all'] = {}
    emitter.on 'mavensmate:panel-notify-start', (params, promiseId) ->
      command = util.getCommandName params
      if command in util.compileCommands()
        errorsView.addRunningFiles(params, promiseId)
        errorsView.refreshErrors()

    emitter.on 'mavensmate:compile-finished', (params, promiseId) ->
      errorsView.removeFinishedFiles(params, promiseId)
      errorsView.refreshErrors()

  initialize: ({@uri}={}) ->
    super

  @content: ->
    @div class: 'mavensmate mavensmate-output tool-panel mavensmate-view native-key-bindings pane-item errors-view',  tabindex: -1, =>
      @div class: 'panel-header', =>
        @div class: 'container-fluid', =>
          @div class: 'row', style: 'padding:10px 0px', =>
            @div class: 'col-md-6', =>
              @h3 'Compile Errors', outlet: 'myHeader', class: 'clearfix'
      @div class: 'panel-body', =>
        @div class: 'container-fluid', =>
          @div class: 'row', =>
            @div class: 'col-md-12', =>
              @table class: 'table table-striped table-bordered', style: 'margin-top:20px', =>
                @thead =>
                  @tr =>
                    @td 'Detail'
                    @td 'Go To Error'
                    @td 'Search', colspan: 3
                @tbody outlet: 'viewErrorsTableBody', ->
                @tfoot =>
                  @tr =>
                    @td colspan: 5, =>
                      @i class: 'fa fa-bug', outlet: 'viewErrorsIcon'
                      @span '0 errors', outlet: 'viewErrorsLabel', style: 'display:inline-block;padding-left:5px;'

  focus: ->
    super

  serialize: ->
    deserializer: 'ErrorsView'
    version: 1
    uri: @uri

  getTitle: ->
    'Errors'

  getIconName: ->
    'bug'

  getURI: ->
    @uri

  isEqual: (other) ->
    other instanceof ErrorsView

  addRunningFiles: (params, promiseId) ->
    command = params.command
    if command in util.compileCommands()
      if command in ['clean-project', 'compile-project']
        @running['all'][promiseId] = params
      else
        if params.payload? and params.payload.paths?
          for runningFile in params.payload.paths
            @running[runningFile] ?= {}
            @running[runningFile][promiseId] = params

  removeFinishedFiles: (params, promiseId) ->
    command = params.command
    if command in util.compileCommands()
      if command in ['clean-project', 'compile-project'] and @running['all'][promiseId]?
        delete @running['all'][promiseId]
      else
        if params.payload.paths?
          for runningFile in params.payload.paths
            if @running[runningFile][promiseId]?
              delete @running[runningFile][promiseId]

  areFilesRunning: ->
    for runningFile, promises of @running
      if promises?
        if Object.keys(promises).length > 0
          return true
    return false

  isFileRunning: (filePath)->
    filePromises = @running['all']
    if filePromises? and Object.keys(filePromises).length > 0
      return true
    filePromises = @running[filePath]
    if filePromises?

      return Object.keys(filePromises).length > 0
    return false
    

  refreshErrors: ->
    filesRunning = @areFilesRunning()
    numberOfErrors = util.numberOfCompileErrors()
    
    @viewErrorsTableBody.html('')
    if atom.project.mavensMateErrors?
      for filePath, errors of atom.project.mavensMateErrors
        
        fileRunning = @isFileRunning(filePath)
        for error in errors
          errorItem = new MavensMateErrorsViewItem(error)
          if fileRunning == true
            errorItem.addClass('warning')
          else
            errorItem.addClass('danger')
          @viewErrorsTableBody.prepend errorItem
    @viewErrorsLabel.html(numberOfErrors + ' ' + pluralize('error', numberOfErrors))

    if filesRunning == false
      @viewErrorsIcon.removeClass 'fa-spin'
    else
      @viewErrorsIcon.addClass 'fa-spin'

class MavensMateErrorsViewItem extends View
  constructor: (error) ->
    super

    @errorDetails.html(error.problem)
    @subscribeGoToButtonToError(error)

    endsWithSymbolRegex = /([^:]*):\s[^\s]*$/
    match = endsWithSymbolRegex.exec(error.problem)
    if match? and match.length > 1
      error.query = match[1]
    else
      error.query = error.problem

    @btnGoogleError.click ->
      shell.openExternal "https://www.google.com/search?q=salesforce #{error.query}"

    @btnSalesforceError.click ->
      shell.openExternal "https://developer.salesforce.com/search?q=#{error.query}"

    @btnSalesforceStackStack.click ->
      shell.openExternal "http://salesforce.stackexchange.com/search?q=#{error.query}"

  @content: ->
    @tr =>
      @td =>
        @div 'Sample error information', outlet: 'errorDetails'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnGoToError', =>
          @span 'Goto the error', outlet: 'goToErrorLabel', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-bug', outlet: 'goToIcon'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnSalesforceError', =>
          @span 'Search Salesforce', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-cloud'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnSalesforceStackStack', =>
          @span 'Search Salesforce Stack Exchange', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-group'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnGoogleError', =>
          @span 'Search Google', outlet: 'viewErrorsLabel', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-search'

  subscribeGoToButtonToError: (error) ->
    if error.lineNumber? and error.filePath?
      @goToErrorLabel.html("#{error.fileName}: Line: #{error.lineNumber}")
      if fs.existsSync(error.filePath)
        @btnGoToError.click ->
          atom.workspace?.open(error.filePath).then (errorEditor) ->
            if error.columnNumber == -1
              error.columnNumber = 1
            errorEditor.setCursorBufferPosition([error.lineNumber-1, error.columnNumber-1], autoscroll: true)
      else
        @goToErrorLabel.html("Can't GoTo #{error.fileName}: Line: #{error.lineNumber}")
        @goToIcon.removeClass('fa-bug')
        @goToIcon.addClass('fa-frown-o')
        @btnGoToError.attr('disabled','disabled')
    else
      @goToErrorLabel.html("MavensMate not sure what happened")
      @goToIcon.removeClass('fa-bug')
      @goToIcon.addClass('fa-meh-o')
      @btnGoToError.attr('disabled','disabled')
