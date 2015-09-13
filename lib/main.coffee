MavensMate             = require './mavensmate'
AutoCompleteProviders  = require './autocomplete/providers'

module.exports =

  mavensmate: null

  # configure MM for Atom SPECIFIC settings (global MavensMate settings handled in mavensmate-app)
  config:
    mm_compile_on_save :
      title: 'Compile files on save'
      description: ''
      type: 'boolean'
      default: true
      order: 30
    mm_panel_height :
      title: 'Panel height'
      description: ''
      type: 'integer'
      default: 200
      order: 100
    mm_close_panel_on_successful_operation:
      title: 'Close panel on successful operation'
      description: ''
      type: 'boolean'
      default: true
      order: 110
    mm_close_panel_delay:
      title: 'Close panel delay'
      description: 'Delay in milliseconds before panel closes on successful operation'
      type: 'integer'
      default: 2000
      order: 120
    mm_apex_file_extensions:
      title: 'Salesforce file extensions'
      description: ''
      type: 'array'
      default: [".page", ".component", ".cls", ".object", ".trigger", ".layout", ".resource", ".remoteSite", ".labels", ".app", ".dashboard", ".permissionset", ".workflow", ".email", ".profile", ".scf", ".queue", ".reportType", ".report", ".weblink", ".tab", ".letter", ".role", ".homePageComponent", ".homePageLayout", ".objectTranslation", ".flow", ".datacategorygroup", ".snapshot", ".site", ".sharingRules", ".settings", ".callCenter", ".community", ".authProvider", ".customApplicationComponent", ".quickAction", ".approvalProcess", ".html" ]
      order: 170
    mm_app_server_port :
      title: 'MavensMate app server port'
      description: ''
      type: 'integer'
      default: 56248
      order: 100

  # todo: should we initiate the app per editorview?
  # right now, this activates MavensMate once per Atom window
  # i think we want to keep each MavensMate() instance tied to a project, but not 100% sure how to approach that
  activate: (state) ->
    console.log '===========> Activating MavensMate-Atom'
    @mavensmate = new MavensMate()

  # instanstiate autocomplete providers
  provide: ->
    # @apexProvider = new AutoCompleteProviders.ApexProvider()
    # @vfProvider = new AutoCompleteProviders.VisualforceTagProvider()
    [AutoCompleteProviders.ApexProvider, AutoCompleteProviders.VisualforceTagProvider]

  deactivate: ->
    console.log '===========> Deactivating MavensMate-Atom'
    @mavensmate?.destroy()
    delete @mavensmate
