{SelectListView}  = require 'atom-space-pen-views'
fs                = require 'fs'
path              = require 'path'
util              = require './util'

module.exports =
class ProjectListView extends SelectListView

  initialize: () ->
    super
    @addClass('command-palette')

  cancelled: ->
    @hide()

  confirmed: (item) ->
    @cancel()
    console.log ('opening project: ' + item.path)
    atom.open options =
      pathsToOpen: [item.path]

  toggle: ->
    if @panel?.isVisible()
      console.log 'togglign closed'
      @cancel()
    else
      console.log 'toggling open'
      @show()

  viewForItem: (item) ->
    "<li>#{item.name}<br/>#{item.path}</li>"

  hide: ->
    @panel?.hide()

  # returns list of project directories based on workspace setting
  getDirs: ->
    dirs = []
    
    try
      home = util.getHomeDirectory()
      cfg = util.fileBodyAsString(path.join(home, '.mavensmate-config.json'), true)
      workspaces = cfg.mm_workspace
      for workspace in workspaces
        if fs.existsSync workspace
          files = fs.readdirSync workspace
          for file in files
            if file[0] != '.'
              filePath = path.join workspace, file
              stat = fs.statSync filePath
              if stat.isDirectory() and util.hasMavensMateProjectStructure(filePath)
                dirs.push { name : file, path: filePath }
    catch error
      console.log('error getting project list ...', error)

    return dirs

  # when user types, list is filtered based on name property
  getFilterKey: ()->
    'name'

  # shows list view
  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @storeFocusedElement()
    
    @setItems(@getDirs())

    @focusFilterEditor()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()