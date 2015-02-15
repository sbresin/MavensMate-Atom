helper                    = require './spec-helper'
temp                      = require 'temp' # npm install temp
path                      = require 'path' # npm install path
Q                         = require 'q'

describe 'main.coffee', ->

  describe 'package pre activation', ->
    
    it 'should not have settings', ->
      expect(atom.config.get('MavensMate-Atom')).toBeUndefined()

    it 'is not be activated', ->
      expect(atom.packages.activePackages['MavensMate-Atom']).toBeUndefined()

  describe 'package activation', ->

    [buffer, directory, editor, editorView, filePath, workspaceElement] = []
    mavensmate = null
    projectPath = null

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
      expect(config.mm_timeout).toBeDefined()
      expect(config.mm_compile_check_conflicts).toBeDefined()
      expect(config.mm_community_api_token).toBeDefined()
      expect(config.mm_use_keyring).toBeDefined()
      expect(config.mm_api_version).toBeDefined()
      expect(config.mm_log_location).toBeDefined()
      expect(config.mm_log_level).toBeDefined()
      expect(config.mm_workspace).toBeDefined()
      expect(config.mm_http_proxy).toBeDefined()
      expect(config.mm_https_proxy).toBeDefined()
      expect(config.mm_play_sounds).toBeDefined()
      expect(config.mm_panel_height).toBeDefined()
      expect(config.mm_close_panel_on_successful_operation).toBeDefined()
      expect(config.mm_close_panel_delay).toBeDefined()
      expect(config.mm_template_location).toBeDefined()
      expect(config.mm_template_source).toBeDefined()
      expect(config.mm_default_subscription).toBeDefined()
      expect(config.mm_atom_exec_path).toBeDefined()
      expect(config.mm_ignore_managed_metadata).toBeDefined()
      expect(config.mm_apex_file_extensions).toBeDefined()

    it 'should attach commands', ->
      expect(helper.hasCommand(workspaceElement, 'mavensmate:new-project')).toBeTruthy()
      expect(helper.hasCommand(workspaceElement, 'mavensmate:open-project')).toBeTruthy()
      expect(helper.hasCommand(workspaceElement, 'mavensmate:compile-project')).toBeTruthy()
    
    it 'calls openProject() method for mavensmate:open-project event', ->
      spyOn mavensmate, 'openProject'
      atom.commands.dispatch(editorView, 'mavensmate:open-project')
      expect(mavensmate.openProject).toHaveBeenCalled()
      jasmine.unspy mavensmate, 'openProject'

    it 'calls newProject() method for mavensmate:new-project event', ->
      spyOn mavensmate, 'newProject'
      atom.commands.dispatch(editorView, 'mavensmate:new-project')
      expect(mavensmate.newProject).toHaveBeenCalled()
      jasmine.unspy mavensmate, 'newProject'

  describe 'package deactivation', ->

    beforeEach ->
      atom.packages.deactivatePackage 'MavensMate-Atom'

    it 'should deactivate package in Atom', ->
      expect(atom.packages.activePackages['MavensMate-Atom']).toBeUndefined()


     