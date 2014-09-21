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
    emitter.emit 'mavensmate:promise-enqueued'

    promiseId = uuid.v1()
    promise = {
      id: promiseId,
      complete: false,
    }
    @tracked[promiseId] = promise
    promiseId  

  start: (promiseId, promise) ->
    emitter.emit 'mavensmate:promise-started', promiseId, promise
    @tracked[promiseId].work = promise.then @completePromise

  # utility method for determining whether the promiseId pass is finished
  #
  # returns true/false
  isPromiseComplete: (promiseId) ->
    @tracked[promiseId].complete

  # returns the promise requested
  pop: (promiseId, pop=true) ->
    if pop
      p = _.clone(@tracked[promiseId]);
      delete @tracked[promiseId]
      # if Object.keys(@tracked).length is 0
      #   emitter.emit 'mavensmate:promise-queue-empty'
      return p
    else
      @tracked[promiseId]
    
  completePromise: (result) ->
    tracker.tracked[result.promiseId].result = result
    tracker.tracked[result.promiseId].complete = true

tracker = new PromiseTracker()
exports.tracker = tracker