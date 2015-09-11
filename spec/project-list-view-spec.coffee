# path    = require 'path' # npm install path

# ProjectListView = require '../lib/project-list-view'

# describe 'ProjectListView', ->
  
#   projectListView = null

#   beforeEach ->
#     workspaceElement = atom.views.getView(atom.workspace)
#     jasmine.attachToDOM(workspaceElement)

#     activationPromise = atom.packages.activatePackage('MavensMate-Atom')
      
#     waitsForPromise ->
#       activationPromise

#     runs ->
#       editor = atom.workspace.getActiveTextEditor()
#       projectListView = new ProjectListView()
#       projectListView.initialize()
    
#   describe 'init', ->

#     it 'should have the appropriate atom classes', ->
#       expect(projectListView.hasClass('select-list')).toBe(true)
#       expect(projectListView.hasClass('command-palette')).toBe(true)

#     it 'should use a "name" filter', ->
#       expect(projectListView.getFilterKey()).toBe('name')

#   describe 'show', ->

#     it 'should contain a list of projects', ->
#       spyOn(projectListView, 'getDirs').andCallFake ->
#         [
#           {
#             name: 'a project'
#             path: '/some/fake/path'
#           }
#           {
#             name: 'another project'
#             path: '/another/fake/path'
#           }
#         ]

#       projectListView.show()
#       expect(projectListView.items.length).toBe(2)
#       expect(projectListView.isVisible()).toBe(true)

#     describe 'item', ->

#       it 'should be an html list item', ->
#         item =
#           name: 'foo'
#           path: 'bar'

#         expect(projectListView.viewForItem(item)).toBe('<li>foo<br/>bar</li>')

#   describe 'toggle', ->

#     it 'should show the list view when it is hidden', ->
#       projectListView.toggle()
#       expect(projectListView.isVisible()).toBe(true)