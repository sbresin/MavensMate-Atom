{$, $$$, ScrollView, View} = require 'atom'
Convert = null
{Subscriber,Emitter} = require 'emissary'
emitter             = require('../mavensmate-emitter').pubsub
logFetcher          = require('../mavensmate-log-fetcher').fetcher
util                = require '../mavensmate-util'
moment              = require 'moment'
MavensMatePanelViewItem = require './panel-view-item'

# The status panel that shows the result of command execution, etc.
class MavensMatePanelView extends View
  Subscriber.includeInto this

  fetchingLogs: false
  panelItems: []
  collapsed: true

  resizeStarted: =>
    $(document).on('mousemove', @resizePanelHandler)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizePanelHandler)
    $(document).off('mouseup', @resizeStopped)

  resizePanelHandler: (evt) =>
    return @resizeStopped() unless evt.which is 1
    height = jQuery("body").height() - evt.pageY - 10
    @setPanelViewHeight(height)

  setPanelViewHeight: (height) =>
    @height(height)
    jQuery('.mavensmate-output .message').css('max-height',height-54+'px')  

  handleEvents: ->
    @on 'mousedown', '.entry', (e) =>
      @onMouseDown(e)

    @on 'mousedown', '.mavensmate-panel-view-resize-handle', (e) => @resizeStarted(e)

  # Internal: Initialize mavensmate output view DOM contents.
  @content: ->
    @div tabIndex: -1, class: 'mavensmate mavensmate-output tool-panel panel-bottom native-key-bindings resize', =>
      @div class: 'mavensmate-panel-view-resize-handle', outlet: 'resizeHandle'
      @div class: 'panel-header', =>
        @div class: 'container-fluid', =>
          @div class: 'row', style: 'padding:10px 0px', =>
            @div class: 'col-md-6', =>
              @h3 'MavensMate Salesforce1 IDE for Atom.io', outlet: 'myHeader', class: 'clearfix', =>
            @div class: 'col-md-6', =>
              @span class: 'config', style: 'float:right', =>
                @button class: 'btn btn-sm btn-default btn-fetch-logs', outlet: 'btnFetchLogs', =>
                  @i class: 'fa fa-refresh', outlet: 'fetchLogsIcon'
                  @span 'Fetch Logs', outlet: 'fetchLogsLabel', style: 'display:inline-block;padding-left:5px;'
                @button class: 'btn btn-sm btn-default btn-toggle-panel', outlet: 'btnTogglePanel', style: 'margin-left:5px', =>
                  @i class: 'fa fa-toggle-up', outlet: 'btnToggleIcon'
      @div class: 'block padded mavensmate-panel', =>
        @div class: 'message', outlet: 'myOutput'

  # Internal: Initialize the mavensmate output view and event handlers.
  initialize: ->
    me = @ # this

    # toggle log fetcher
    @btnFetchLogs.click ->
      me.fetchingLogs = !me.fetchingLogs
      if me.fetchingLogs
        me.btnFetchLogs.removeClass 'btn-default'
        me.btnFetchLogs.addClass 'btn-success'
        me.fetchLogsIcon.addClass 'fa-spin'
        me.fetchLogsLabel.html 'Fetching Logs'
        logFetcher.start()
      else
        me.btnFetchLogs.removeClass 'btn-success'
        me.btnFetchLogs.addClass 'btn-default'
        me.fetchLogsIcon.removeClass 'fa-spin'
        me.fetchLogsLabel.html 'Fetch Logs'
        logFetcher.stop()

    # toggle log fetcher
    @btnTogglePanel.click ->
      if me.collapsed
        me.expand()
      else
        me.collapse() 
 
    # updates panel view font size(s) based on editor font-size updates (see mavensmate-atom-watcher.coffee)
    emitter.on 'mavensmate:font-size-changed', (newFontSize) ->
      jQuery('div.mavensmate pre.terminal').css('font-size', newFontSize)

    # event handler which creates a panelViewItem corresponding to the command promise requested
    emitter.on 'mavensmatePanelNotifyStart', (params, promiseId) ->
      command = util.getCommandName params
      if command not in util.panelExemptCommands() and not params.skipPanel # some commands are not piped to the panel
        params.promiseId = promiseId
        me.update command, params
      return

    # handler for finished operations
    # writes status to panel item
    # displays colored indicator based on outcome
    emitter.on 'mavensmatePanelNotifyFinish', (params, result, promiseId) ->
      promisePanelViewItem = me.panelItems[promiseId]
      promisePanelViewItem.update me, params, result

    @handleEvents()
  
  collapse: () ->
    @setPanelViewHeight(40)
    @btnToggleIcon.removeClass 'fa-toggle-down'
    @btnToggleIcon.addClass 'fa-toggle-up'
    @collapsed = true

  expand: () ->
    @setPanelViewHeight(200)  
    @btnToggleIcon.removeClass 'fa-toggle-up'
    @btnToggleIcon.addClass 'fa-toggle-down'
    @collapsed = false

  afterAttach: (onDom) ->
    # @setPanelViewHeight(200)
    # @setPanelViewHeight(40)
    @collapse()

  # Update the mavensmate output view contents.
  #
  # output - A string of the test runner results.
  #
  # Returns nothing.
  update: (command, params) ->
    if @collapsed
      @expand()

    panelItem = new MavensMatePanelViewItem(command, params) # initiate new panel item
    @panelItems[params.promiseId] = panelItem # add panel to dictionary
    @myOutput.prepend panelItem # add panel item to panel

  # Detach and destroy the mavensmate output view.
  #           clear the existing panel items.
  # Returns nothing.
  destroy: ->
    $('.panel-item').remove()
    @unsubscribe()
    @detach()

  # Toggle the visibilty of the mavensmate output view.
  #
  # Returns nothing.
  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this) unless @hasParent() #todo: attach to specific workspace view



panel = new MavensMatePanelView()
exports.panel = panel
