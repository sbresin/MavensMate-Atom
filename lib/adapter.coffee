{ScrollView}  = require 'atom-space-pen-views'
_             = require 'underscore-plus'
path          = require 'path'
Q             = require 'q'
tracker       = require('./promise-tracker').tracker
emitter       = require('./emitter').pubsub
ModalView     = require './modal-view'
request       = require 'request'
io            = require 'socket.io'

globalFunction = global.Function
{allowUnsafeEval, allowUnsafeNewFunction, Function} = require 'loophole'
Function.prototype.call = globalFunction.prototype.call
mavensmate = allowUnsafeNewFunction ->
  allowUnsafeEval ->
    require 'mavensmate'

class CoreView extends ScrollView
  constructor: (params) ->
    super
    @command = params.args.operation
    tabViewUri = 'http://localhost:'+atom.mavensmate.adapter.client.getServer().port+'/app/'+params.args.url
    @iframe.attr 'src', tabViewUri

    @iframe.focus()
   
  @deserialize: (state) ->
    new CoreView(state)

  # Internal: Initialize mavensmate output view DOM contents.
  @content: ->
    @div class: 'mavensmate', =>
      @iframe outlet: 'iframe', width: '100%', height: '100%', class: 'native-key-bindings', sandbox: 'allow-same-origin allow-top-navigation allow-forms allow-scripts', style: 'border:none;'

  serialize: ->
    deserializer: 'CoreView'
    version: 1
    uri: @uri

  getTitle: ->
    _.undasherize(@command)

  getIconName: ->
    'browser'

  getUri: ->
    @uri

  # Tear down any state and detach
  destroy: ->
    @detach()

class CoreAdapter

  client: null

  initialize: () ->
    self = @
    @client = mavensmate.createClient(
      editor: 'atom'
      headless: true
      debugging: false
      settings: atom.config.get('MavensMate-Atom')
    )

    # opens core url in an Atom tab
    atom.workspace.addOpener (uri, params) ->
      self.createUiView(params) if uri is 'mavensmate://core'

    # watch for configuration changes, update client settings
    atom.config.onDidChange 'MavensMate-Atom.mm_workspace', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_compile_check_conflicts', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_api_version', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_default_subscription', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_use_keyring', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_log_location', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_log_level', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_play_sounds', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_atom_exec_path', ({newValue, oldValue}) ->
      self.reloadConfig()

    atom.config.onDidChange 'MavensMate-Atom.mm_ignore_managed_metadata', ({newValue, oldValue}) ->
      self.reloadConfig()

  initSocketListeners: () ->
    setTimeout(->
      console.log('http://localhost:'+atom.mavensmate.adapter.client.getServer().port)
      socket = require('socket.io-client')('http://localhost:'+atom.mavensmate.adapter.client.getServer().port);
      socket.on 'command.finish', (data) -> 
        trackedPromise = tracker.pop(data.jobId);
        emitter.emit 'mavensmate:promise-completed', data.jobId
        emitter.emit 'mavensmate:panel-notify-finish', trackedPromise.params, data.response, data.jobId
    , 500)

  reloadConfig: () ->
    @client.settings = atom.config.get('MavensMate-Atom')
    @client.reloadConfig()

  openUI: (params) ->
    if params.args.view == 'tab'
      atom.workspace.open('mavensmate://core', params)
    else
      modalView = new ModalView params.args.url #attach app view pane
      modalView.appendTo document.body
  
  createUiView: (params) ->
    ui = new CoreView(params)
     
  setProject: (projectPath) ->
    console.log 'setting project from core-adapter ===>'
    
    deferred = Q.defer()
    
    @client.setProject projectPath, (err, response) ->
      # console.log 'project set response -->'
      # console.log err
      # console.log response
      if err
        console.error('could not initiate mavensmate project ...')
        console.error err
        deferred.reject err
      else
        # console.log('mavensmate project initiated ...')
        # console.log response
        deferred.resolve response

    deferred.promise

  executeCommand: (params) ->
    console.log 'executing command via core adapter: '
    console.log params
    
    args = params.args or {}
    payload = params.payload or {}
    promiseId = params.promiseId
    
    command = if args.operation then args.operation else payload.command

    if not promiseId?
      promiseId = tracker.enqueuePromise(command, params)

    deferred = Q.defer()

    payload.jobId = promiseId

    options = {
      uri: 'http://localhost:'+atom.mavensmate.adapter.client.getServer().port+'/api/commands/'+command,
      method: 'POST',
      json: payload
    };

    request options, (err, response, body) ->
      console.log 'REQUEST RESPONSE'
      console.log err
      console.log response
      console.log body
      if err
        err.promiseId = promiseId
        deferred.reject err
      else
        response.promiseId = promiseId
        deferred.resolve response

    # add to promise tracker,
    # emit an event so the panel knows when to do its thing
    
    tracker.start promiseId, deferred.promise
    emitter.emit 'mavensmate:panel-notify-start', params, promiseId

    deferred.promise

module.exports = new CoreAdapter()