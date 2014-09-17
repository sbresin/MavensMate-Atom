{View} = require 'atom'
FirepadUserList = require '../../scripts/firepad-userlist'

module.exports =
class ShareStatusView extends View
  hash: null

  @content: ->
    @div class: 'mavensmate-share firepad overlay from-bottom native-key-bindings', =>
      @i class: 'fa fa-share-alt-square', style: 'padding-right: 7px'
      @span outlet: 'shareMessage', class: 'message'
      @input outlet: 'shareUrl', style: 'width:65%'
      # @div id: 'userlist'

  constructor: (hash, ref, editor, options) ->
    super
    console.log hash
    console.log ref
    console.log editor
    console.log options
    @hash = hash

    @shareUrl.val @hash
    @shareMessage.html 'This file is being shared: '

    # console.log FirepadUserList
    userList = FirepadUserList.fromDiv(ref.child('users'),
              document.body, 'userId', 'displayName');

  show: ->
    atom.workspaceView.getActivePane().activeView.append(this)