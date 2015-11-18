{spawn}         = require 'child_process'
{View}          = require 'atom-space-pen-views'
$               = require 'jquery'
emitter         = require('./emitter').pubsub
tracker         = require('./promise-tracker').tracker

module.exports =
  # Internal: A status bar view for the test status icon.
  class StatusBarView extends View

    panel: null

    constructor: (panel) ->
      super
      @panel = panel

    # Internal: Initialize mavensmate status bar view DOM contents.
    @content: ->
      @div class: 'inline-block', =>
        @span class: 'icon', outlet: 'mavensMateIconWrapper', tabindex: -1, ''

    # Internal: Initialize the status bar view and event handlers.
    initialize: ->
      # add svg icon via markup explicitly so we can style it with css
      @mavensMateIconWrapper.append('<svg version="1.1" id="mavensmateSvgIcon" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="38.667px" height="12.667px" viewBox="0 0 38.667 12.667" enable-background="new 0 0 38.667 12.667" xml:space="preserve"><g><circle fill="#60BBE2" cx="6.781" cy="6.478" r="4.818" class="circle1"/><circle fill="#5681C2" cx="19.281" cy="6.478" r="4.655" class="circle2"/><circle fill="#7979B9" cx="31.67" cy="6.404" r="4.745" class="circle3"/></g></svg>')

      # attach to atom worksapce
      @attach()

      # event handlers
      self = @

      # when a promise is enqueued, set busy flag to true
      emitter.on 'mavensmate:promise-enqueued', ->
        self.setBusy true
        return

      # when a promise is completed, check the tracker to see whether there are pending promises
      # if there are not, set busy flag to false
      emitter.on 'mavensmate:promise-completed', ->
        # console.log 'mavensmate:promise-completed FROM STATUS BAR ====>'
        if Object.keys(tracker.tracked).length is 0
          self.setBusy false
        return

      # toggle panel view when icon is clickd
      jQuery(this).on 'click', ->
        self.panel.toggle()

    # Internal: Attach the status bar view to the status bar.
    #
    # Returns nothing.
    attach: ->
      # workspaceElement = atom.views.getView(atom.workspace)
      # console.log workspaceElement
      if atom.workspace? and document.querySelector('status-bar')?
        document.querySelector('status-bar').addLeftTile({ item: this })

    # Internal: Detach and destroy the mavensmate status barview.
    destroy: ->
      @detach()

    setBusy: (busy) ->
      if busy
        $('#mavensmateSvgIcon').attr('class', 'busy')
      else
        $('#mavensmateSvgIcon').attr('class', '')
