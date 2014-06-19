emitter   = require('./mavensmate-emitter').pubsub
tracker   = require('./mavensmate-promise-tracker').tracker

class EventHandler

  constructor: () ->
    # console.log 'initing handlers!!!'
    @initHandlers()

  initHandlers: ->
    emitter.on 'mavensmatePromiseCompleted', (promiseId) ->
      console.log ' ----------------------------> event has occurred!!!'
      # console.log tracker
      # console.log promiseId
      # promise = tracker.pop promiseId
      # console.log promise
      # todo: check tracker, if no pending promises, set status panel to not busy
      return

    emitter.on 'mavensmatePromiseEnqueued', ->
      console.log ' ----------------------------> promise enqueued!!!'
      return

  
handler = new EventHandler()
exports.handler = handler