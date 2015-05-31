{SelectListView}  = require 'atom-space-pen-views'
fs                = require 'fs'
path              = require 'path'
util              = require '../util'

module.exports =
class ApexScriptsListView extends SelectListView

  initialize: (@callback) ->
    super

  confirmed: (item) ->
    @cancel()
    @callback(item)
    
  viewForItem: (item) ->
    "<li>#{item.name}<br/>#{item.path}</li>"

  # returns list of project directories based on workspace setting
  getScripts: ->
    projectPath = fs.readdirSync atom.project.getPaths()[0]
    files = fs.readdirSync projectPath
    scripts = []
    for file in files
      if file[0] != '.'
        filePath = path.join workspace, file
        stat = fs.statSync filePath
        if stat.isFile() and path.extname(filePath) == '.cls'
          scripts.push { name : file, path: filePath }

    return scripts

  # when user types, list is filtered based on name property
  getFilterKey: ()->
    'name'

  # shows list view
  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @storeFocusedElement()
    
    @setItems(@getScripts())

    @focusFilterEditor()