{View, EditorView} = require 'atom'
MmCli = require('./mavensmate-cli').mm
Repeat = require 'repeat'

class MavensMateLogFetcher
  
  goFetch: (logId) ->
    params =
      skipPanel: true
      args:
        operation: 'download_log'
      payload:
        log_id: logId
    MmCli.run(params)
    .then (result) ->
      if result.success and result.log?
        fetchedView = new MavensMateLogFetchedView(result)
        fetchedView.show()
    .catch (error) ->
      console.log 'oh no an error'
      console.log error

class MavensMateLogFetchedView extends View
  @content: ->
    @div class: 'mavensmate-log-fetched overlay native-key-bindings', =>
      @i class: 'fa fa-bolt', style: 'padding-right: 10px'
      @span 'New Debug Log', class: 'message'
      @button 'Open Log', class: 'btn btn-success', style: 'float:right;', outlet: 'openLog'

  constructor: (@result) ->
    super
    console.log 'constructing view --->'
    @log = @result.log
    #@openLog.hide()

  initialize: ->
    # when open log button is clicked, log is opened in atom and flash alert is hidden
    thiz = @
    @openLog.click ->
      atom.workspaceView.open(thiz.log.path)
      .then (result) ->
        thiz.destroy()  

  show: ->
    atom.workspaceView.getActivePane().activeView.append(this)
    thiz = @
    # todo: don't hide when mouse is over?
    setTimeout (->
      thiz.destroy()
      return
    ), 5000

  destroy: ->
    @unsubscribe()
    @detach()


exports.fetcher = new MavensMateLogFetcher()