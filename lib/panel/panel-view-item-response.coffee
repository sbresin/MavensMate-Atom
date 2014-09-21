{$, View} = require 'atom'

module.exports =

class PanelViewItemResponse extends View

  @content: (params) ->
    @div style: 'position:relative', =>
      @span '> '+params.message, id: params.id
      @button class: 'btn btn-sm btn-default', style: 'margin-left:5px;height:1.0em;', outlet: 'btnMore', =>
        @i class: 'fa fa-ellipsis-h'
      @div style: 'display:none', outlet: 'moreDiv', =>
        @span JSON.stringify(params.result, undefined, 2)

  initialize: ->
    me = @
    @btnMore.click ->
      me.moreDiv.toggle()

     