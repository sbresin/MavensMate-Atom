helper                    = require './spec-helper'
temp                      = require 'temp' # npm install temp
path                      = require 'path' # npm install path
Q                         = require 'q'
adapter                   = require '../lib/adapter'

describe 'main.coffee', ->

  describe 'package pre activation', ->
    
    mmMain = null

    beforeEach ->
      runs ->
        workspaceElement = atom.views.getView(atom.workspace)
        jasmine.attachToDOM(workspaceElement)

        pack = atom.packages.loadPackage('MavensMate-Atom')
        mmMain = pack.mainModule
        spyOn(mmMain, 'provide').andCallThrough()
        pack = atom.packages.loadPackage('autocomplete-plus')
      
    it 'should not have settings', ->
      expect(atom.config.get('MavensMate-Atom')).toBeUndefined()

    it 'is not be activated', ->
      expect(atom.packages.activePackages['MavensMate-Atom']).toBeUndefined()

    it 'should have autocomplete providers', ->
      mmMain.provide()
      expect(mmMain.apexProvider).toBeDefined()
      expect(mmMain.apexProvider.apexClasses.length).toEqual(447)
      expect(mmMain.vfProvider).toBeDefined()
      expect(mmMain.vfProvider.vfTags.length).toEqual(131)

  describe 'package activation', ->
    [buffer, directory, editor, editorView, filePath, workspaceElement] = []
    mavensmate = null
    projectPath = null

    beforeEach ->
      atom.project.setPaths([''])

      workspaceElement = atom.views.getView(atom.workspace)
      jasmine.attachToDOM(workspaceElement)

      runs ->
        console.log 'setting project'
        projectPath = path.join(__dirname, 'fixtures', 'testProject')
        console.log(projectPath)
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
      spyOn mavensmate.mavensmateAdapter, 'executeCommand'
      atom.commands.dispatch(editorView, 'mavensmate:new-project')
      expect(mavensmate.mavensmateAdapter.executeCommand).toHaveBeenCalled()
      jasmine.unspy mavensmate.mavensmateAdapter, 'executeCommand'

  describe 'package deactivation', ->

    beforeEach ->
      atom.packages.deactivatePackage 'MavensMate-Atom'

    it 'should deactivate package in Atom', ->
      expect(atom.packages.activePackages['MavensMate-Atom']).toBeUndefined()


     