temp      = require 'temp' # npm install temp
path      = require 'path' # npm install path
Q         = require 'q'
ModalView = require '../lib/modal-view'

# Automatically track and cleanup files at exit
temp.track()

describe 'ModalView', ->
  
  projectPath = null
  modal = null

  beforeEach ->
    atom.project.setPaths([''])

    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    activationPromise = atom.packages.activatePackage('MavensMate-Atom').then ({mainModule}) ->
      mavensmate = mainModule.mavensmate

      spyOn(mavensmate.mavensmateAdapter, 'setProject').andCallFake (p) ->
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

  it 'should create a modal view', ->
    modalView = new ModalView('some-url')
    console.log modalView
    expect(modalView.url).toBe('some-url')
    expect(modalView.modal.attr('id')).toBeDefined()
    expect(modalView.iframe).toBeDefined()
    expect(modalView.iframe.attr('src')).toBe('http://localhost:'+atom.mavensmate.adapter.client.getServer().port+'/app/some-url')
    expect(modalView.modal.hasClass('modal fade in')).toBe(true)
    expect(modalView.loading[0].style.display).toBe('none')