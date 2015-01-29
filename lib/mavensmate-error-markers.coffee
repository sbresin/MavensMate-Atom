{Subscriber,Emitter}  = require 'emissary'
util                  = require './mavensmate-util'
emitter               = require('./mavensmate-emitter').pubsub

module.exports =
class MavensMateErrorMarkers
  Subscriber.includeInto(this)

  constructor: (@textEditor) ->
    @initialize()
    @refreshMarkers()

  initialize: ->
    thisView = @
    emitter.on 'mavensmate:compile-finished', (params) ->
      thisView.refreshMarkers()

  clearMarkers: ->
    return unless @markers?
    marker.destroy() for marker in @markers
    @markers = null

  refreshMarkers: ->
    try
      console.log 'refreshing buffer markers ...'
      if @textEditor.getPath()
        if atom.project.mavensMateErrors[@textEditor.getPath()]?
          errors = atom.project.mavensMateErrors[@textEditor.getPath()]
        else
          currentFileNameWithoutExtension = util.withoutExtension(util.baseName(@textEditor.getPath()))
          errors = atom.project.mavensMateErrors[currentFileNameWithoutExtension] ? []
        
      @clearMarkers()

      if errors?
        lines_to_highlight = (error['lineNumber'] for error in errors when error['lineNumber']?)
        for line in lines_to_highlight
          @markRange(line-1, line-1, 'mm-compile-error-gutter', 'gutter')
          @markRange(line-1, line-1, 'mm-compile-error-line', 'highlight')
    catch error
      console.log 'error refreshing buffer markers'
      console.error error

  markRange: (startRow, endRow, klass, type) ->
    marker = @textEditor.markBufferRange([[startRow, 0], [endRow, Infinity]], invalidate: 'never')
    @textEditor.decorateMarker(marker, type: type, class: klass)
    @markers ?= []
    @markers.push(marker)
