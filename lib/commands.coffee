_       = require 'underscore-plus'
tracker = require('./promise-tracker').tracker
emitter = require('./emitter').pubsub
util    = require './util'

class Command

  mavensmate: null
  requiresConfirm: false
  callback: undefined
  adapterCommandName: null
  uiCommand: false
  payload: {}

  constructor: (@mavensmate) ->

  execute: ->
    self = @
    if @requiresConfirm
      answer = atom.confirm
        message: @confirmMessage
        buttons: @confirmButtons
      if answer == 0
        self.dispatch()
    else
      @dispatch()

  dispatch: ->
    self = @
    params =
      args:
        operation: self.adapterCommandName
        pane: atom.workspace.getActivePane()
    if self.uiCommand
      params.args.ui = true

    params.payload = @payload()

    @mavensmate.adapter.executeCommand(params)
      .then (result) ->
        if self.callback
          self.callback(params, result)
        else
          self.resultHandler(params, result)
      .catch (err) ->
        if self.callback
          self.callback(params, err)
        else
          self.resultHandler(params, err)

  resultHandler: (params, result) ->
    tracker.pop(result.promiseId).result
    emitter.emit 'mavensmate:promise-completed', result.promiseId
    emitter.emit 'mavensmate:panel-notify-finish', params, result, result.promiseId

commands =
  
  # 'clean-project':
  #   requiresConfirm: true
  #   confirmMessage: 'Are you sure you want to revert this project to its server state?'
  #   confirmButtons: [ 'Yes', 'No' ]
  #   adapterCommandName: 'clean-project'
  #   selectors: [
  #     '.tree-view li.project-root', ''
  #   ]

  'refresh-selected-metadata':
    requiresConfirm: true
    confirmMessage: 'Are you sure you want to refresh this metadata from the server?'
    confirmButtons: [ 'Yes', 'No' ]
    adapterCommandName: 'refresh-metadata'
      # '.tree-view li.project-root':
      #   payload: ->
      #     paths: util.getSelectedFiles()
      # '':
      #   payload: ->
      #     paths: [ util.activeFile() ]
  
  # 'delete-selected-metadata':
  #   requiresConfirm: true
  #   confirmMessage: 'Are you sure you want to delete this metadata from the server?'
  #   confirmButtons: [ 'Yes', 'No' ]
  #   adapterCommandName: 'delete-metadata'
  #   payload: ->
  #     paths: util.getSelectedFiles()

  # 'compile-selected-metadata':
  #   requiresConfirm: true
  #   confirmMessage: 'Are you sure you want to compile this metadata to the server?'
  #   confirmButtons: [ 'Yes', 'No' ]
  #   adapterCommandName: 'compile-metadata'
  #   payload: ->
  #     paths: util.getSelectedFiles()

registerCommands = (mavensmate) ->
  action = (evt) ->
    console.log 'runnnning command'
    console.log evt

    commandName = evt.type.split(':').pop()
    commandDefinition = commands[commandName]

    cmd = new Command(mavensmate)
    cmd.requiresConfirm = commandDefinition.requiresConfirm
    cmd.callback = commandDefinition.callback
    cmd.confirmMessage = commandDefinition.confirmMessage
    cmd.confirmButtons = commandDefinition.confirmButtons
    cmd.adapterCommandName = commandDefinition.adapterCommandName
    cmd.payload = commandDefinition.payload
    cmd.execute()

  for cmd of commands
    cmdDef = commands[cmd]
    atom.commands.add 'atom-workspace',
      'mavensmate:'+cmd, action

     

module.exports.registerCommands = registerCommands