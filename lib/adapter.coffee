{ScrollView}  = require 'atom-space-pen-views'
_             = require 'underscore-plus'
path          = require 'path'
Q             = require 'q'
tracker       = require('./promise-tracker').tracker
emitter       = require('./emitter').pubsub
request       = require 'request'

class CoreAdapter

  checkStatus: () ->
    self = @
    
    deferred = Q.defer()

    request
      .get("http://localhost:#{atom.config.get('MavensMate-Atom').mm_app_server_port}/app/home/index")
      .on('response', (response) ->
        if response.statusCode == 200
          # mavensmate-app is up and running
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
        if response.statusCode > 300
          res = 
            promiseId: promiseId
            error: new Error body
          deferred.resolve res
        else
          statusResponse = JSON.parse body
          requestId = statusResponse.id
          requestDone = false
          requestResponse = null
            
          console.log 'Need to poll local MavensMate server for response ...'

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
                # todo: catch interruption
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
       
    # add to promise tracker,
    tracker.start promiseId, deferred.promise
    # emit an event so the panel knows when to do its thing
    emitter.emit 'mavensmate:panel-notify-start', params, promiseId

    deferred.promise

module.exports = new CoreAdapter()