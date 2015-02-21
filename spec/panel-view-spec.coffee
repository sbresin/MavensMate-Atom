# helper packages for test
temp    = require 'temp' # npm install temp
path    = require 'path' # npm install path
Q       = require 'q'

# Automatically track and cleanup files at exit
temp.track()

emitter = require('../lib/emitter').pubsub
{panel} = require '../lib/panel/panel-view'

describe 'PanelView', ->
  
  mavensmate = null
  projectPath = null

  beforeEach ->
    atom.project.setPaths([''])

    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    activationPromise = atom.packages.activatePackage('MavensMate-Atom').then ({mainModule}) ->
      mavensmate = mainModule.mavensmate

      spyOn(mavensmate.mavensmateAdapter, 'setProject').andCallFake ->
        deferred = Q.defer()
        deferred.resolve()
        deferred.promise

      spyOn(mavensmate.mavensmateAdapter.client, 'getProject').andCallFake ->
        project =
          path: projectPath
          name: 'bar'
          logService:
            on: ->
        return project
      
    waitsForPromise ->
      activationPromise

    runs ->
      projectPath = path.join(__dirname, 'fixtures', 'testProject')
      atom.project.setPaths([projectPath])

    waitsForPromise ->
      atom.workspace.open('src/package.xml')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)

  afterEach ->
    panel.clear()

  it 'should be instantiated', ->
    expect(panel).toBeDefined()
    expect(panel).toBeDefined()
    expect(panel.find('h3')[0].innerHTML).toBe('MavensMate Salesforce1 IDE for Atom')
    expect(panel.myHeader).toBeDefined()
    expect(panel.myOutput).toBeDefined()

  it 'should add text', ->
    expect(panel.find('.panel-item').length).toBe(2) # package init adds 2 items
    expect(Object.keys(panel.panelDictionary).length).toBe(2)
    panel.addPanelViewItem('unit test', 'danger')
    expect(Object.keys(panel.panelDictionary).length).toBe(3)
    expect(panel.find('.panel-item').length).toBe(3)

  it 'should expand', ->
    panel.expand()
    expect(panel.collapsed).toBe(false)

  it 'should collapse', ->
    panel.collapse()
    expect(panel.collapsed).toBe(true)

  it 'should be cleared', ->
    panel.addPanelViewItem('unit test', 'danger')
    expect(Object.keys(panel.panelDictionary).length).toBeGreaterThan(0)
    panel.clear()
    expect(Object.keys(panel.panelDictionary).length).toBe(0)