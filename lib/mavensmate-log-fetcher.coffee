{View}              = require 'atom-space-pen-views'
Repeat              = require 'repeat'
mavensMateAdapter   = require('./mavensmate-core-adapter')

class MavensMateLogFetcher
  
  constructor: (project) ->
    console.log 'init log fetcher'
    console.log project
    project.logService.on 'mavensmate-log-downloaded', (location) ->
      console.log 'LOG DOWNLOADED!!!'
      fetchedView = new MavensMateLogFetchedView(location)
      fetchedView.show()

class MavensMateLogFetchedView extends View
  @content: ->
    @div class: 'mavensmate-log-fetched overlay native-key-bindings', =>
      @i class: 'fa fa-bolt', style: 'padding-right: 10px'
      @span 'New Debug Log', class: 'message'
      @button 'Open Log', class: 'btn btn-success', style: 'float:right;', outlet: 'openLog'

  constructor: (path) ->
    super
    console.log 'constructing view --->'
    console.log path
    @path = path

  initialize: ->
    # when open log button is clicked, log is opened in atom and flash alert is hidden
    self = @
    @openLog.click ->
      atom.workspaceView.open(self.path)
      .then (result) ->
        self.destroy()

  show: ->
    self = @
    atom.workspaceView.append(this) # TODO: deprecated
 
    # ensures log notification stays open if mouse is over it
    # otherwise disappears after 5 seconds
    hideTimer = setTimeout(->
      self.destroy()
      return
    , 5000)
    
    self.bind "mouseleave", ->
      hideTimer = setTimeout(->
        self.destroy()
        return
      , 5000)
      return

    self.bind "mouseenter", ->
      clearTimeout hideTimer  if hideTimer isnt null
      return

  destroy: ->
    @detach()

module.exports = MavensMateLogFetcher