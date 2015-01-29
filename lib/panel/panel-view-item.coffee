{$, View}             = require 'atom-space-pen-views'
{Subscriber,Emitter}  = require 'emissary'
emitter               = require('../mavensmate-emitter').pubsub
util                  = require '../mavensmate-util'
moment                = require 'moment'
parseCommand          = require('./parsers').parse
PanelViewItemResponse = require './panel-view-item-response'

module.exports =
  # represents a single operation/command within the panel
  class MavensMatePanelViewItem extends View

    constructor: ->
      super
      # set panel font-size to that of the editor
      fontSize = jQuery("atom-text-editor::shadow div.editor-contents--private").css('font-size')
      @terminal.context.style.fontSize = fontSize

    initCommandMessage: (command, params) ->
      @closePanelOnFinish = true
      @command = command
      @running = true

      # get the message
      message = @.panelCommandMessage params, util.isUiCommand params

      # scope this panel by the promiseId
      @promiseId = params.promiseId
      @item.attr 'id', @promiseId

      # write the message to the terminal
      @terminal.html message

    initGenericMessage: (message, status) ->
      # write the message to the terminal
      @terminal.html message
      if status?
        @terminal.addClass status

    # Internal: Initialize mavensmate output view DOM contents.
    @content: ->
      @div class: 'panel-item',  =>
        @div outlet: 'item', =>
          @div class: 'container-fluid', =>
            @div class: 'row', =>
              @div class: 'col-md-12', =>
                @div =>
                  @pre class: 'terminal active', outlet: 'terminal'

    initialize: ->

    # updates terminal view with result of command
    update: (panel, params, result) ->
      console.log 'updating panel item as a result of command ====>'
      console.log params
      console.log result
      self = @
      if @command not in util.panelExemptCommands() and not params.skipPanel
        panelOutput = parseCommand(@command, params, result)

        if panelOutput.indicator != 'success'
          self.closePanelOnFinish = false

        # update progress bar depending on outcome of command
        self.terminal.removeClass 'active'
        self.terminal.addClass panelOutput.indicator

        # update terminal
        itemResponse = new PanelViewItemResponse(id: @promiseId, message: panelOutput.message, result: result)
        self.terminal.append itemResponse
        # self.terminal.append '<br/>> '+ '<span id="message-'+@promiseId+'">'+panelOutput.message+'</span>'
        self.running = false
      return

    # returns the command message to be displayed in the panel
    # todo: refactor to something like parsers.coffee
    panelCommandMessage: (params, isUi=false) ->
      # console.log params
      
      switch @command
        when 'new-project'
          msg =  'Creating new project'
        when 'compile-project'
          msg = 'Compiling project'
        when 'index-metadata'
          msg = 'Indexing metadata'
        when 'compile-metadata'
          if params.payload.paths? and params.payload.paths.length is 1
            msg = 'Compiling '+params.payload.paths[0].split(/[\\/]/).pop() # extract base name
          else
            msg = 'Compiling selected metadata'
        when 'delete-metadata'
          if params.payload.paths? and params.payload.paths.length is 1
            msg = 'Deleting ' + params.payload.paths[0].split(/[\\/]/).pop() # extract base name
          else
            msg = 'Deleting selected metadata'
        when 'refresh-metadata'
          if params.payload.paths? and params.payload.paths.length is 1
            msg = 'Refreshing ' + params.payload.paths[0].split(/[\\/]/).pop() # extract base name
          else
            msg = 'Refreshing selected metadata'
        when 'clean-project'
          msg = 'Cleaning project'
        when 'run-tests'
          msg = 'Running Apex unit test(s)'
        when 'start-logging'
          msg = 'Creating trace flags for user ids in config/.debug'
        when 'stop-logging'
          msg = 'Deleting trace flags you have created for user ids in config/.debug'
        when 'index-apex'
          msg = 'Indexing Apex symbols for this project'
        else
          msg = 'mavensmate ' + @command
      console.log msg
      header = '['+moment().format('MMMM Do YYYY, h:mm:ss a')+']<br/>'
      return header + '> ' + msg