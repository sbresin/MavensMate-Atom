{$, View}             = require 'atom-space-pen-views'
{Subscriber,Emitter}  = require 'emissary'
_                     = require 'lodash'
emitter               = require('../emitter').pubsub
util                  = require '../util'
moment                = require 'moment'
parseCommand          = require('./parsers').parse
PanelViewItemResponse = require './panel-view-item-response'
commands              = require '../commands.json'

module.exports =
  # represents a single operation/command within the panel
  class PanelViewItem extends View

    constructor: ->
      super
      # set panel font-size to that of the editor
      fontSize = jQuery('atom-text-editor::shadow div.editor-contents--private').css('font-size')
      try
        if !fontSize
          fontSize = '14px'
        else if 'px' in fontSize and parseInt(fontSize.replace('px', '') < 14)
          fontSize = '14px'
      catch
        # pass

      @terminal.context.style.fontSize = fontSize

    initCommandMessage: (command, params) ->
      @closePanelOnFinish = true
      @closePanelDelay = atom.config.get('MavensMate-Atom.mm_close_panel_delay')
      @command = command
      @params = params
      @running = true

      # scope this panel by the promiseId
      @promiseId = @params.promiseId
      @item.attr 'id', @promiseId

      # write the message to the terminal
      @terminal.html @.getMessage()

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

        if panelOutput.indicator != 'success' and panelOutput.indicator != 'info'
          self.closePanelOnFinish = false

        if panelOutput.indicator == 'info'
          self.closePanelDelay = self.closePanelDelay * 4

        # update progress bar depending on outcome of command
        self.terminal.removeClass 'active'
        self.terminal.addClass panelOutput.indicator

        # update terminal
        itemResponse = new PanelViewItemResponse(id: @promiseId, message: panelOutput.message, result: result)
        self.terminal.append itemResponse
        self.running = false
      return

    # returns the command message to be displayed in the panel
    # todo: refactor to something like parsers.coffee
    getMessage: ->
      console.log('.....')
      console.log(@command)
      console.log(@params)

      cmdDef = @params.commandDefinition

      if cmdDef and cmdDef.panelMessage
        msg = cmdDef.panelMessage
      else
        msg = 'mavensmate ' + @command

      if @params.payload? and @params.payload.paths? and @params.payload.paths.length is 1
        msg += ' '+@params.payload.paths[0].split(/[\\/]/).pop() # extract base name
        
      console.log msg
      header = '['+moment().format('MMMM Do YYYY, h:mm:ss a')+']<br/>'
      return header + '> ' + msg