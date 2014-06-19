uuid        = require 'node-uuid'
_           = require 'cloneextend'
emitter     = require('./mavensmate-emitter').pubsub

class PromiseTracker
  
  # object containing promises we're tracking
  # {
  #   'tracked-promise-uuid' : {
  #     id : 'tracked-promise-uuid',
  #     complete: false,
  #     result: 'some result'
  #   }
  # }
  tracked:{}

  constructor: () ->

  # initiates base promise, assigns id
  #
  # returns promise id  
  enqueuePromise: () ->
    emitter.emit 'mavensmatePromiseEnqueued'

    promiseId = uuid.v1()
    promise = {
      id: promiseId,
      complete: false,
    }
    @tracked[promiseId] = promise
    promiseId  

  start: (promiseId, promise) ->
    emitter.emit 'mavensmatePromiseStarted', promiseId, promise
    @tracked[promiseId].work = promise.then @completePromise

  # utility method for determining whether the promiseId pass is finished
  #
  # returns true/false
  isPromiseComplete: (promiseId) ->
    console.log 'checking whether promise is complete => '+promiseId
    console.log @tracked
    console.log @tracked[promiseId]
    @tracked[promiseId].complete

  # returns the promise requested
  pop: (promiseId, pop=true) ->
    if pop
      p = _.clone(@tracked[promiseId]);
      delete @tracked[promiseId]
      return p
    else
      @tracked[promiseId]
    
  completePromise: (result) ->
    console.log 'completing promise!'
    console.log result
    console.log tracker
    tracker.tracked[result.promiseId].result = result
    tracker.tracked[result.promiseId].complete = true
    #emitter.emit 'mavensmatePromiseCompleted', result.promiseId

tracker = new PromiseTracker()
exports.tracker = tracker