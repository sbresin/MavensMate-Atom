path                  = require 'path'
Q                     = require 'q'
tracker               = require('./mavensmate-promise-tracker').tracker
emitter               = require('./mavensmate-emitter').pubsub
util                  = require './mavensmate-util'
MavensMateModalView   = require './mavensmate-modal-view'
{ScrollView}          = require 'atom'
_                     = require 'underscore-plus'

globalFunction = global.Function
{allowUnsafeEval, allowUnsafeNewFunction, Function} = require 'loophole'
Function.prototype.call = globalFunction.prototype.call
mavensmate = allowUnsafeNewFunction ->
  allowUnsafeEval ->
    require '../node_modules/mavensmate/lib/mavensmate.js' # todo: for some reason, we cant reference require('mavensmate')

class MavensMateCoreView extends ScrollView
  constructor: (params) ->
    super
    @command = params.args.operation
    tabViewUri = 'http://localhost:'+atom.mavensmate.adapter.client.getServer().port+'/app/'+params.args.url
    @iframe.attr 'src', tabViewUri
    # @iframe.attr 'id', 'iframe-'+@promiseId

    @iframe.focus()
   
  @deserialize: (state) ->
    new MavensMateCoreView(state)

  # Internal: Initialize mavensmate output view DOM contents.
  @content: ->
    @div class: 'mavensmate', =>
      @iframe outlet: 'iframe', width: '100%', height: '100%', class: 'native-key-bindings', sandbox: 'allow-same-origin allow-top-navigation allow-forms allow-scripts', style: 'border:none;'

  serialize: ->
    deserializer: 'MavensMateCoreView'
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

class MavensMateCoreAdapter

  client: null
  uiServer: null

  initialize: () ->
    @client = mavensmate.createClient(
      editor: 'atom'
      headless: true
      debugging: true
      settings: atom.config.getSettings()['MavensMate-Atom']
    )

    # opens core url in an Atom tab
    atom.workspace.registerOpener (uri, params) ->
      createUiView(params) if uri is 'mavensmate://core'

  startUIServer: () ->
    @uiServer = mavensmate.startUIServer(@client)

  openUI: (params) ->
    if params.args.view == 'tab'
      atom.workspaceView.open('mavensmate://core', params)
    else
      modalView = new MavensMateModalView params.args.url #attach app view pane
      modalView.appendTo document.body
  
  createUiView = (params) ->
    ui = new MavensMateCoreView(params)
     
  executeCommand: (params) ->
    console.log 'executing command via core adapter: '
    console.log params
    
    args = params.args or {}
    payload = params.payload
    promiseId = params.promiseId
    
    command = if args.operation then args.operation else payload.command

    if not promiseId?
      promiseId = tracker.enqueuePromise(command)

    deferred = Q.defer()

    @client.executeCommand command, payload, (err, response) ->
      console.log('executeCommand response: ')
      console.log(err)
      console.log(response)
      if err
        err.promiseId = promiseId
        deferred.reject err
      else
        response.promiseId = promiseId
        deferred.resolve response

        # result = response.result # core always responds like so:
        #   { result: { /* the result */ } }
        # result.promiseId = promiseId
        # deferred.resolve response
          
    # add to promise tracker,
    # # emit an event so the panel knows when to do its thing
    tracker.start promiseId, deferred.promise
    emitter.emit 'mavensmate:panel-notify-start', params, promiseId

    deferred.promise

module.exports = new MavensMateCoreAdapter()