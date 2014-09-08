path    = require 'path' # npm install path

emitter = require('../lib/mavensmate-emitter').pubsub
MavensMateCheckpointHandler = require '../lib/mavensmate-checkpoint-handler'
{Editor, EditorView, WorkspaceView, $} = require 'atom'

describe 'MavensMate Checkpoint Handler', ->

  beforeEach ->
    console.log atom
    atom.project.setPath(path.join(__dirname, 'fixtures', 'testProject'))
    # set up the workspace
    atom.workspaceView = new WorkspaceView()
    atom.workspace = atom.workspaceView.model
    atom.workspaceView.attachToDom()
    # activate the mavensmate package
    waitsForPromise ->
      atom.packages.activatePackage('MavensMate-Atom')

    waitsForPromise ->
      atom.workspace.open('testProject/src/classes/MatchController.cls')

  fit 'should intialize with handlers', ->
    @editor = atom.workspace.getActiveEditor()
    spyOn(@editor.checkpointHandler, 'clearMarkers').andCallThrough()
    spyOn(@editor.checkpointHandler, 'refreshMarkers').andCallThrough()
    spyOn(@editor.checkpointHandler, 'refreshCheckpoints').andCallThrough()

    myParams =  {args: {operation: 'index_apex_overlays'}, promiseId: 'my-fake-promiseId', payload: {files: null}}
    emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
    emitter.emit 'mavensmatePanelNotifyFinish', myParams, null

    myParams.args.operation = 'compile'
    emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
    emitter.emit 'mavensmatePanelNotifyFinish', myParams, { result: null }

    expect(@editor.checkpointHandler.clearMarkers).toHaveBeenCalled()
    expect(@editor.checkpointHandler.refreshMarkers).toHaveBeenCalled()
    expect(@editor.checkpointHandler.refreshCheckpoints).toHaveBeenCalled()
    # clearMarkers will be called for each 'start' emitted as well as when refreshMarkers and refreshCheckpoints is called
    expect(@editor.checkpointHandler.clearMarkers.calls.length).toEqual(4)

  it 'should detect gutter click events', ->
    @editor = atom.workspace.getActiveEditor()
    editorView = new EditorView(mini: false)
    console.log editorView

    console.log $._data(editorView.find('.line-numbers .line-number'), 'events')
    # console.log editorView.find('.line-numbers .line-number').first().click()
    expect(editorView.find('.line-numbers .line-number').first().hasClass('mm-checkpoint-gutter-processing')).toBe(true)
