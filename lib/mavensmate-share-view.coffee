
Crypto = require 'crypto'
{View, EditorView} = require 'atom'

Firebase = require 'firebase'
Firepad = require '../scripts/firepad-lib'
FirepadUserList = require '../scripts/firepad-userlist'

uuid        = require 'node-uuid'

class ShareUserListView extends View

  ref: null
  hash: null

  @content: ->
    @div class: 'mavensmate-share-user-list overlay native-key-bindings', =>
      @i class: 'fa fa-share-alt-square', style: 'padding-right: 7px'
      @span outlet: 'shareMessage', class: 'message'
      @input outlet: 'shareUrl', style: 'width:65%'
      # @div id: 'userlist'

  constructor: (hash, ref) ->
    super
    @ref = ref
    @hash = hash
    
  show: ->
    userList = FirepadUserList.fromDiv(@ref.child('users'), document.body, 'userId', 'displayName');
    atom.workspaceView.getActivePane().activeView.append(this)

  hide: ->
    console.log 'need to hide!'

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

module.exports =
class MavensMateShareView extends View
  
  hash: null

  @activate: -> new MavensMateShareView

  @content: ->
    @div class: 'firepad overlay from-top mini', =>
      @subview 'miniEditor', new EditorView(mini: true)
      @div class: 'message', outlet: 'message'

  detaching: false

  initialize: ->
    atom.workspaceView.command 'mavensmate:share-session', => @share()
    atom.workspaceView.command 'mavensmate:unshare-session', => @unshare()

    @miniEditor.hiddenInput.on 'focusout', => @detach() unless @detaching
    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    @miniEditor.preempt 'textInput', (e) =>
      false unless e.originalEvent.data.match(/[a-zA-Z0-9\-]/)

  detach: ->
    return unless @hasParent()
    @detaching = true
    @miniEditor.setText('')
    super
    @detaching = false

  share: ->
    if editor = atom.workspace.getActiveEditor()
      atom.workspaceView.append(this)
      @message.text('Enter a string to identify this share session')
      @miniEditor.focus()

  confirm: ->
    shareId = @miniEditor.getText()
    # @hash = Crypto.createHash('sha256').update(shareId).digest('base64');
    @hash = uuid.v1()
    console.log 'hash is -->'
    console.log @hash
    @detach()
    @ref = new Firebase('https://mavensmate.firebaseio.com/301818e7db340dc6ba3386899819c4266849baeb').child(@hash);

    editor = atom.workspace.getActiveEditor()
    @ref.once 'value', (snapshot) =>
      console.log 'got a value!'
      console.log snapshot
      options = {sv_: Firebase.ServerValue.TIMESTAMP}
      if !snapshot.val() && editor.getText() != ''
        options.overwrite = true
      else
        editor.setText ''
      @pad = Firepad.fromAtom @ref, editor, options

      @view = new ShareStatusView(@hash, @ref, editor, options)
      @view.show()

      # @userList = new ShareUserListView(@hash, @ref)
      # @userlist.show()

      pane = atom.workspaceView.getActivePane()
      pane.on 'pane:active-item-changed', (something) ->
        console.log 'changed active'
        console.log something
        return

  destroy: ->
    if @pad?
      @pad.dispose()
    @unsubscribe()
    @detach()

  unshare: ->
    @pad.dispose()
    @view.detach()