MavensMate = require './mavensmate'

module.exports =
  
  # todo: should we initiate the app per editorview?
  # right now, this activates MavensMate once per Atom window
  # i think we want to keep each MavensMate() instance tied to a project, but not 100% sure how to approach that
  activate: =>
    console.log 'activating mavensmate'
    console.log atom.workspaceView
    @mavensmate = new MavensMate() 

  deactivate: =>
    console.log 'deactivating mavensmate'
    @mavensmate.destroy()