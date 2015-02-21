emitter = require('../emitter').pubsub

Repeat = require 'repeat'

# use this class to register watchers for atom-specific attributes (font size, settings, etc)
# emit events for subscription by other plugin classes
class AtomWatcher

  constructor: () ->
    atom.mavensmate.currentFontSize = jQuery("atom-text-editor::shadow div.editor-contents--private").css("font-size")
    @startWatching()

  startWatching: ->
    Repeat(@watchFontSize).every(100, 'ms').start.now()

  # watches editor font size, emits event when it changes so that mavensmate views can update accordingly
  watchFontSize: ->
    newFontSize = jQuery("atom-text-editor::shadow div.editor-contents--private").css("font-size")
    if newFontSize != atom.mavensmate.currentFontSize
      atom.mavensmate.currentFontSize = newFontSize
      emitter.emit 'mavensmate:font-size-changed', atom.mavensmate.currentFontSize
    return

watcher = new AtomWatcher()
exports.mm = watcher
