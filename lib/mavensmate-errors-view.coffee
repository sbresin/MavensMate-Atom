{$, $$, ScrollView, View}   = require 'atom'
{Subscriber,Emitter}  = require 'emissary'
emitter               = require('./mavensmate-emitter').pubsub
util                  = require './mavensmate-util'
pluralize             = require 'pluralize'


module.exports =
class MavensMateErrorsView extends ScrollView
  constructor: ->
    super
    errorsView = @
    @running = {}
    @running['all'] = {}
    emitter.on 'mavensmatePanelNotifyStart', (params, promiseId) ->
      errorsView.addRunningFiles(params, promiseId)
      errorsView.refreshErrors()

    emitter.on 'mavensMateCompileFinished', (params, promiseId) ->
      errorsView.removeFinishedFiles(params, promiseId)
      errorsView.refreshErrors()

  initialize: ({@uri}={}) ->
    super

  @content: ->
    @div class: 'mavensmate mavensmate-output tool-panel mavensmate-view', =>
      @div class: 'panel-header', =>
        @div class: 'container-fluid', =>
          @div class: 'row', style: 'padding:10px 0px', =>
            @div class: 'col-md-6', =>              
              @h3 'Compile Errors', outlet: 'myHeader', class: 'clearfix'                              
      @div class: 'panel-body', =>
        @div class: 'container-fluid', =>
          @div class: 'row', =>
            @div class: 'mavensmate-notice', outlet: 'viewErrorsStatus', =>
              @i class: 'fa fa-bug', outlet: 'viewErrorsIcon'
              @span '0 errors', outlet: 'viewErrorsLabel', style: 'display:inline-block;padding-left:5px;'
          @div class: 'row', =>
            @div class: 'col-md-12', =>
              @table class: 'table table-striped', =>
                @tbody outlet: 'viewErrorsTableBody'

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
            console.log('deleting promise ' + promiseId + ' for ' + runningFile)
            delete @running[runningFile][promiseId]

  countFilesRunning: ->
    console.log(@running)
    runningFiles = 0
    for runningFile, promises of @running
      if promises?
        runningFiles += Object.keys(promises).length
    return runningFiles          

  refreshErrors: ->
    console.log '-----> refreshErrors'
    filesRunning = @countFilesRunning()
    numberOfErrors = util.numberOfCompileErrors()

    @viewErrorsTableBody.html('')

    if atom.project.errors?
      for fileName, errors of atom.project.errors
        for error in errors
          errorItem = new MavensMateErrorsViewItem(error)
          console.log(error)
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
    @goToErrorLabel.html("#{error.fileName}: Line: #{error.lineNumber}")

  @content: ->
    @tr =>
      @td =>          
        @div 'Sample error information', outlet: 'errorDetails'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnGoToError', =>            
          @span 'Goto the error', outlet: 'goToErrorLabel', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-bug'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnGoogleError', =>            
          @span 'Search Google', outlet: 'viewErrorsLabel', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-search'
      @td =>
        @button class: 'btn btn-sm btn-default btn-errorItem', outlet: 'btnSalesforceError', =>            
          @span 'Search Salesforce', style: 'display:inline-block;padding-left:5px;'
          @i class: 'fa fa-cloud'
