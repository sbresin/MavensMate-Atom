{ScrollView}  = require 'atom-space-pen-views'
_             = require 'underscore-plus'
path          = require 'path'
Q             = require 'q'
tracker       = require('./promise-tracker').tracker
emitter       = require('./emitter').pubsub
ModalView     = require './modal-view'
request       = require 'request'

globalFunction = global.Function
{allowUnsafeEval, allowUnsafeNewFunction, Function} = require 'loophole'
Function.prototype.call = globalFunction.prototype.call
mavensmate = allowUnsafeNewFunction ->
  allowUnsafeEval ->
    require 'mavensmate'

class CoreView extends ScrollView
  constructor: (params) ->
    super
    @command = params.command
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

  getURI: ->
    @uri

  # Tear down any state and detach
  destroy: ->
    @detach()

class CoreAdapter

  client: null
  uiServer: null

  initialize: () ->
    self = @
    
    deferred = Q.defer()

    request
      .get("http://localhost:#{atom.config.get('MavensMate-Atom').mm_app_server_port}/app/home/index")
      .on('response', (response) ->
        if response.statusCode == 200
          # todo: if user wants embedded views, allow it to happen?
          # opens core url in an Atom tab
          atom.workspace.addOpener (uri, params) ->
            self.createUiView(params) if uri is 'mavensmate://core'

          deferred.resolve()
        else
          console.log(response)
          deferred.reject('Could not contact local MavensMate server, please ensure the MavensMate app is installed and running (https://github.com/joeferraro/mavensmate-app/releases). MavensMate will not run properly until resolved.')
      )
      .on('error', (err) ->
        console.log(err)
        deferred.reject('Could not contact local MavensMate server, please ensure the MavensMate app is installed and running (https://github.com/joeferraro/mavensmate-app/releases). MavensMate will not run properly until resolved.')
      )

    deferred.promise

  openUI: (params) ->
    if params.args.view == 'tab'
      atom.workspace.open('mavensmate://core', params)
    else
      modalView = new ModalView params.args.url #attach app view pane
      modalView.appendTo document.body
  
  createUiView: (params) ->
    ui = new CoreView(params)
     
  executeCommand: (params) ->
    console.log 'executing command via core adapter: '
    console.log params
    
    payload = params.payload
    promiseId = params.promiseId
      
    # command = if args.operation then args.operation else payload.command
    command = params.command

    if not promiseId?
      promiseId = tracker.enqueuePromise(command)

    deferred = Q.defer()

    reqUrl = "http://localhost:#{atom.config.get('MavensMate-Atom').mm_app_server_port}/execute?command=#{command}&async=1"
    if atom.project.mavensmateId
      reqUrl += '&pid='+atom.project.mavensmateId

    reqOptions =
      method: 'POST'
      url: reqUrl
      headers:
        'Content-Type': 'application/json'
        'MavensMate-Editor-Agent': 'atom'
      body: JSON.stringify payload

    console.log('executing MavensMate command', reqOptions)

    request(reqOptions, (err, response, body) ->
      console.log('REQUEST CALLBACK')
      console.log err
      console.log response
      console.log body
      if err
        err.promiseId = promiseId
        deferred.reject err
      else
        console.log('response from mavensmate', response, body) 
        statusResponse = JSON.parse body
        requestId = statusResponse.id
        requestDone = false
        requestResponse = null
          
        console.log 'need to poll ...'

        poll = ->
          console.log 'polling for response ...'

          statusOption =
            method: 'GET',
            url: "http://localhost:#{atom.config.get('MavensMate-Atom').mm_app_server_port}/status?id=#{requestId}"
            headers:
              'MavensMate-Editor-Agent': 'atom'
        
          request(statusOption, (err, response, body) ->
            if err
              err.promiseId = promiseId
              deferred.reject err
            else
              res = JSON.parse body
              if res.status and res.status == 'pending'
                setTimeout(->
                  poll()
                , 500)
                # poll()
              else
                # requestResponse = res
                # requestDone = true
                console.log('done!')
                console.log(res)
                res.promiseId = promiseId
                deferred.resolve res
          )  

        poll()      
    )

    # reqOptions
    #   .get(reqUrl)
    #   .on('response', (response) ->
    #     console.log('response from mavensmate', response) 

    #   )
    #   .on('error', (err) ->
    #     console.log(err)
    #     deferred.reject('Could not contact local MavensMate server, please ensure the MavensMate app is installed and running (https://github.com/joeferraro/mavensmate-app/releases). MavensMate will not run properly until resolved.')
    #   )    

    # @client.executeCommand command, payload, (err, response) ->
    #   console.log('executeCommand response: ')
    #   console.log(err)
    #   console.log(response)
    #   if err
    #     err.promiseId = promiseId
    #     deferred.reject err
    #   else
    #     response.promiseId = promiseId
    #     deferred.resolve response

    #     # result = response.result # core always responds like so:
    #     #   { result: { /* the result */ } }
    #     # result.promiseId = promiseId
    #     # deferred.resolve response
          
    # # add to promise tracker,
    # # # emit an event so the panel knows when to do its thing
    tracker.start promiseId, deferred.promise
    emitter.emit 'mavensmate:panel-notify-start', params, promiseId

    deferred.promise

module.exports = new CoreAdapter()