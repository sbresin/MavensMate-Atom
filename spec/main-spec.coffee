helper                    = require './spec-helper'
path                      = require 'path' # npm install path
Q                         = require 'q'

describe 'main.coffee', ->

  describe 'package pre activation', ->
    
    packageMain = null

    beforeEach ->
      runs ->
        workspaceElement = atom.views.getView(atom.workspace)
        jasmine.attachToDOM(workspaceElement)

        pkg = atom.packages.loadPackage('MavensMate-Atom')
        packageMain = pkg.mainModule
        spyOn(packageMain, 'provide').andCallThrough()
        pkg = atom.packages.loadPackage('autocomplete-plus')
      
    it 'should not have settings', ->
      expect(atom.config.get('MavensMate-Atom')).toBeUndefined()

    it 'should not be activated', ->
      expect(atom.packages.activePackages['MavensMate-Atom']).toBeUndefined()

    it 'should have apex and vf autocomplete providers', ->
      packageMain.provide()
      expect(packageMain.apexProvider).toBeDefined()
      expect(packageMain.apexProvider.apexClasses.length).toEqual(447)
      expect(packageMain.vfProvider).toBeDefined()
      expect(packageMain.vfProvider.vfTags.length).toEqual(131)

  describe 'package activation with mavensmate project already loaded', ->
    [buffer, directory, editor, editorView, filePath, workspaceElement] = []
    
    mavensmate = null
    projectPath = null

    beforeEach ->
      atom.project.setPaths([''])

      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)

      runs ->
        projectPath = path.join(__dirname, 'fixtures', 'testProject')
        atom.project.setPaths([projectPath])

      activationPromise = atom.packages.activatePackage('MavensMate-Atom').then ({mainModule}) ->
        console.log 'spec: MavensMate-Atom activated ...'
        mavensmate = mainModule.mavensmate
        console.log mavensmate

      waitsForPromise ->
        activationPromise

      waitsForPromise ->
        atom.workspace.open('src/package.xml')

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editorView = atom.views.getView(editor)

    it 'should activate package in Atom', ->
      expect(atom.packages.isPackageActive('MavensMate-Atom')).toBe true

    it 'should have default settings defined', ->
      expect(atom.config.get('MavensMate-Atom')).toBeDefined()
      config = atom.config.get('MavensMate-Atom')
      expect(config.mm_compile_on_save).toBeDefined()
      expect(config.mm_panel_height).toBeDefined()
      expect(config.mm_close_panel_on_successful_operation).toBeDefined()
      expect(config.mm_close_panel_delay).toBeDefined()
      expect(config.mm_apex_file_extensions).toBeDefined()
      expect(config.mm_app_server_port).toBeDefined()

    it 'should attach commands', ->
      expect(helper.hasCommand(workspaceElement, 'mavensmate:new-project')).toBeTruthy()
      # expect(helper.hasCommand(workspaceElement, 'mavensmate:open-project')).toBeTruthy()
      expect(helper.hasCommand(workspaceElement, 'mavensmate:compile-project')).toBeTruthy()
    
    # it 'calls openProject() method for mavensmate:open-project event', ->
    #   spyOn mavensmate, 'openProject'
    #   atom.commands.dispatch(editorView, 'mavensmate:open-project')
    #   expect(mavensmate.openProject).toHaveBeenCalled()
    #   jasmine.unspy mavensmate, 'openProject'

    it 'calls newProject() method for mavensmate:new-project event', ->
      deferred = Q.defer()
      deferred.resolve()
      spyOn(mavensmate.mavensmateAdapter,'executeCommand').andCallFake -> deferred.promise
      atom.commands.dispatch(editorView, 'mavensmate:new-project')
      expect(mavensmate.mavensmateAdapter.executeCommand).toHaveBeenCalled()
      jasmine.unspy mavensmate.mavensmateAdapter, 'executeCommand'

  describe 'package activation without mavensmate project loaded', ->
    workspaceElement = []
    mavensmate = null
    projectPath = null

    beforeEach ->
      atom.project.setPaths([''])

      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)

      activationPromise = atom.packages.activatePackage('MavensMate-Atom').then ({mainModule}) ->
        mavensmate = mainModule.mavensmate

      waitsForPromise ->
        activationPromise

    it 'should activate package in Atom', ->
      expect(atom.packages.isPackageActive('MavensMate-Atom')).toBe true

    it 'should attach project commands when project is loaded', ->
      projectPath = path.join(__dirname, 'fixtures', 'testProject')
      expect(helper.hasCommand(workspaceElement, 'mavensmate:compile-project')).toBeFalsy()
      expect(helper.hasCommand(workspaceElement, 'mavensmate:new-project')).toBeTruthy()
      atom.project.setPaths([projectPath])
      expect(helper.hasCommand(workspaceElement, 'mavensmate:compile-project')).toBeTruthy()

  describe 'package deactivation', ->

    beforeEach ->
      atom.packages.deactivatePackage 'MavensMate-Atom'

    it 'should deactivate package in Atom', ->
      expect(atom.packages.activePackages['MavensMate-Atom']).toBeUndefined()


     