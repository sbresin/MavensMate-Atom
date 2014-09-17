{$, $$, ScrollView, View}   = require 'atom'
{Subscriber,Emitter}  = require 'emissary'
emitter               = require('./mavensmate-emitter').pubsub
util                  = require './mavensmate-util'
pluralize             = require 'pluralize'
fs                    = require 'fs'


module.exports =
class MavensMateErrorsView extends ScrollView
  constructor: ->
    super
    errorsView = @
    @running = {}
    @running['all'] = {}
    emitter.on 'mavensmatePanelNotifyStart', (params, promiseId) ->
      command = util.getCommandName params
      if command in util.compileCommands()
        errorsView.addRunningFiles(params, promiseId)
        errorsView.refreshErrors()

    emitter.on 'mavensMateCompileFinished', (params, promiseId) ->
      errorsView.removeFinishedFiles(params, promiseId)
      errorsView.refreshErrors()

  initialize: ({@uri}={}) ->
    super

  @content: ->
    @div class: 'mavensmate mavensmate-output tool-panel mavensmate-view native-key-bindings pane-item',  tabindex: -1, =>
      @div class: 'panel-header', =>
        @div class: 'container-fluid', =>
          @div class: 'row', style: 'padding:10px 0px', =>
            @div class: 'col-md-6', =>              
              @h3 'Compile Errors', outlet: 'myHeader', class: 'clearfix'                              
      @div class: 'panel-body', =>
        @div class: 'container-fluid', =>
          @div class: 'row', =>
            @div class: 'col-md-12', =>
              @table class: 'table table-striped table-bordered', =>
                @thead =>
                  @tr =>
                    @td 'Detail'
                    @td 'Go To Error'
                    @td 'Search', colspan: 2
                @tbody outlet: 'viewErrorsTableBody', =>
                @tfoot =>
                  @tr =>
                    @td colspan: 4, =>
                      @i class: 'fa fa-bug', outlet: 'viewErrorsIcon'
                      @span '0 errors', outlet: 'viewErrorsLabel', style: 'display:inline-block;padding-left:5px;'

  focus: ->
    super

  serialize: ->
    deserializer: 'MavensMateErrorsView'
    version: 1
    uri: @uri

  getTitle: ->
    'Errors'

  getIconName: ->
    'bug'

  getUri: ->
    @uri

  isEqual: (other) ->
    other instanceof ErrorsView

  addRunningFiles: (params, promiseId) ->
    command = params.args.operation
    if command in util.compileCommands()
      if command in ['clean_project', 'compile_project']
        @running['all'][promiseId] = params
      else
        filesRunning = (util.baseName(filePath) for filePath in params.payload.files ? [])
        for runningFile in filesRunning
          @running[runningFile] ?= {}
          @running[runningFile][promiseId] = params      

  removeFinishedFiles: (params, promiseId) ->
    command = params.args.operation
    if command in util.compileCommands()
      if command in ['clean_project', 'compile_project'] and @running['all'][promiseId]?
        delete @running['all'][promiseId]
      else
        filesRunning = (util.baseName(filePath) for filePath in params.payload.files ? [])
        for runningFile in filesRunning
          if @running[runningFile][promiseId]?
            delete @running[runningFile][promiseId]

  countFilesRunning: ->
    runningFiles = 0
    for runningFile, promises of @running
      if promises?
        runningFiles += Object.keys(promises).length
    return runningFiles          

  refreshErrors: ->
    filesRunning = @countFilesRunning()
    numberOfErrors = util.numberOfCompileErrors()

    @viewErrorsTableBody.html('')

    if atom.project.errors?
      for fileName, errors of atom.project.errors
        for error in errors
          errorItem = new MavensMateErrorsViewItem(error)
          @viewErrorsTableBody.prepend errorItem

    @viewErrorsLabel.html(numberOfErrors + ' ' + pluralize('error', numberOfErrors))

    if filesRunning == 0
      @viewErrorsIcon.removeClass 'fa-spin'
      # if numberOfErrors == 0
      #   @btnViewErrors.addClass 'btn-default'
      #   @btnViewErrors.removeClass 'btn-error'
      #   @btnViewErrors.removeClass 'btn-warning'
      # else
      #   @btnViewErrors.removeClass 'btn-default'
      #   @btnViewErrors.addClass 'btn-error'
      #   @btnViewErrors.removeClass 'btn-warning'        
    else
      @viewErrorsIcon.addClass 'fa-spin'
      # @btnViewErrors.removeClass 'btn-default'
      # @btnViewErrors.removeClass 'btn-error'
      # @btnViewErrors.addClass 'btn-warning' 

class MavensMateErrorsViewItem extends View
  constructor: (error) ->
    super

    @errorDetails.html(error.problem)
    if error.lineNumber? and error.filePath?
      @goToErrorLabel.html("#{error.fileName}: Line: #{error.lineNumber}")
      if fs.existsSync(error.filePath)
        @btnGoToError.click ->
          atom.workspace?.open(error.filePath).then (errorEditor) ->
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

  @content: ->
    @tr =>
      @td =>          
        @div 'Sample error information', outlet: 'errorDetails'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnGoToError', =>            
          @span 'Goto the error', outlet: 'goToErrorLabel', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-bug', outlet: 'goToIcon'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnGoogleError', =>            
          @span 'Search Google', outlet: 'viewErrorsLabel', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-search'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnSalesforceError', =>            
          @span 'Search Salesforce', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-cloud'
