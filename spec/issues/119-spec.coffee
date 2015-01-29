# describe 'Workspace setting fix', ->

#   beforeEach ->
#     waitsForPromise ->
#       atom.packages.activatePackage 'MavensMate-Atom'

#   it 'should have a default', ->
#     expect(atom.config.getSettings()['MavensMate-Atom']).toBeDefined()
#     config = atom.config.getSettings()['MavensMate-Atom']
#     expect(config.mm_workspace).toEqual(['/one/cool/workspace', '/one/not-so-cool/workspace'])

#   it 'should support configuration', ->
#     atom.config.set('MavensMate-Atom.mm_workspace', ['/some/other/workspace'])
#     updatedConfig = atom.config.get('MavensMate-Atom')
#     expect(updatedConfig.mm_workspace).toEqual(['/some/other/workspace'])

#     atom.config.set('MavensMate-Atom.mm_workspace', ['/some/other/workspace', '/another'])
#     updatedConfig = atom.config.get('MavensMate-Atom')
#     expect(updatedConfig.mm_workspace).toEqual(['/some/other/workspace', '/another'])

#       