Promise         = require('bluebird')
tracker         = require('../lib/promise-tracker').tracker
emitter         = require('../lib/emitter').pubsub

describe 'PromiseTracker', ->

  afterEach ->
    tracker = require('../lib/promise-tracker').tracker

  describe 'enqueuePromise', ->

    it 'should add a promise to tracked', ->
      promiseId = tracker.enqueuePromise('some-operation')
      expect(Object.keys(tracker.tracked).length).toBe(1)
      expect(tracker.tracked[promiseId].complete).toBe(false)
      expect(tracker.tracked[promiseId].operation).toBe('some-operation')

  describe 'hasPendingOperation', ->

    it 'should return whether there is a pending operation being tracked', ->
      tracker.enqueuePromise('some-operation')
      expect(tracker.hasPendingOperation('some-operation')).toBe(true)

  describe 'start', ->

    it 'should add promise', ->
      spyOn(emitter, 'emit').andCallThrough()
      promiseId = tracker.enqueuePromise('some-operation')
      expect(emitter.emit.mostRecentCall.args[0]).toEqual('mavensmate:promise-enqueued')

      p = new Promise((resolve, reject) ->
        res =
          promiseId: promiseId
          foo: 'bar'
        resolve(res)
      )
      tracker.start(promiseId, p)
      expect(emitter.emit.mostRecentCall.args[0]).toEqual('mavensmate:promise-started')
      expect(tracker.tracked[promiseId].work = p)

  describe 'isPromiseComplete', ->

    it 'should return completion status', ->
      promiseId = tracker.enqueuePromise('some-operation')
      expect(tracker.isPromiseComplete(promiseId)).toEqual(false)

  describe 'pop', ->

    it 'should return tracked promise', ->
      promiseId = tracker.enqueuePromise('some-operation')
      expect(tracker.pop(promiseId).id).toEqual(promiseId)

  describe 'completePromise', ->

    it 'should complete the promise and set the result', ->
      promiseId = tracker.enqueuePromise('some-operation')
      result =
        promiseId : promiseId
        result : 'ok!'
      tracker.completePromise(result)
      expect(tracker.tracked[promiseId].complete).toBe(true)
      expect(tracker.tracked[promiseId].result).toBe(result)
