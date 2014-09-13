{View, EditorView} = require 'atom'
MmCli = require('./mavensmate-cli').mm
Repeat = require 'repeat'

class MavensMateLogFetcher
  
  repeater:null
  fetching:false

  start: ->
    # todo: make interval configurable
    # todo: new_quick_log before starting the fetcher
    #Repeat(@goFetch).every(5000, 'ms').start.now();
    thiz = @
    thiz.fetching = true
    params =
      skipPanel: true
      args:
        operation: 'new_quick_log'
    MmCli.run(params)
      .then (result) ->
        thiz.repeater = Repeat(thiz.goFetch).every(5000, 'ms').until(-> !thiz.fetching).start.now()
      .catch (error) ->
        console.log 'failed to start log fetcher!!!'
        console.log error
    
  stop: ->
    @fetching = false

  goFetch: ->
    params =
      skipPanel: true
      args:
        operation: 'fetch_logs'
    MmCli.run(params)
    .then (result) ->
      if result.logs? and result.logs.length > 0
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
    if @result.logs? and @result.logs.length > 0
      @log = @result.logs[0]
    else
      @openLog.hide()

  initialize: ->
    # when open log button is clicked, log is opened in atom and flash alert is hidden
    thiz = @
    @openLog.click ->
      atom.workspaceView.open(thiz.log)
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