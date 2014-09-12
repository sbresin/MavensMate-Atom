path    = require 'path'
{exec}  = require 'child_process'
daemon  = require 'daemon'
glob    = require 'glob'
Q       = require 'q'
tracker = require('./mavensmate-promise-tracker').tracker
emitter = require('./mavensmate-emitter').pubsub
util    = require './mavensmate-util'

class MavensMateCommandLineInterface

  #promiseTracker: null

  constructor: () ->
    @promiseTracker = tracker

  # Run the specified mm command
  #
  # params =
  #   args:
  #     foo: 'bar'
  #     bat: 'boom'
  #   payload:
  #     something: reallycool
  #   promiseId: 'some promise id'
  #
  # Returns promise.
  run: (params) ->
    deferred = Q.defer()

    args = params.args or {}
    payload = params.payload
    promiseId = params.promiseId

    if not promiseId?
      promiseId = tracker.enqueuePromise()

    # console.log 'executing command'
    # console.log args
    # console.log payload
    # console.log promiseId

    # return unless atom.project.path? TODO: ensure mavensmate project

    cfg = atom.config.getSettings()['MavensMate-Atom']

    #console.log cfg

    cmd = null

    operation = if args.operation then args.operation else payload.command

    if cfg.mm_developer_mode
      if cfg.mm_mm_py_location == 'mm/mm.py'
        mm_location = path.join(atom.packages.resolvePackagePath('MavensMate-Atom'),cfg.mm_mm_py_location)
      else
        mm_location = cfg.mm_mm_py_location
      cmd = cfg.mm_python_location+' "'+mm_location+'" '+operation
    else
      if cfg.mm_path == 'default'
        mm_path = path.join(atom.packages.resolvePackagePath('MavensMate-Atom'),'mm')
      else
        mm_path = cfg.mm_path

      cmd = '"'+mm_path+'" '+operation

    # ui operations
    if 'ui' of args && args['ui']
      if operation in util.modalCommands()
        cmd = cmd + ' --ui -uid='+promiseId
      else
        cmd = cmd + ' --ui -uid='+args.pane.id

    # offline operations
    if 'offline' of args && args['offline']
      cmd = cmd + ' --offline'

    # set client name argument
    cmd = cmd + ' -c=ATOM'

    if payload?
      payload.settings = cfg
    else
      payload = { settings : cfg }

    # payload may include ajax_args from UI ajax requests
    if payload.ajax_args?
      for arg in payload.ajax_args
        cmd = cmd + ' '+arg

    # add piped JSON payload
    cmd = "echo '" + JSON.stringify(payload) + "'| " + cmd

    console.log cmd

    @execute cmd, deferred, promiseId

    tracker.start promiseId, deferred.promise    #todo: ???
    emitter.emit 'mavensmatePanelNotifyStart', params, promiseId

    deferred.promise

  # Execute the command, resolve the promise
  execute: (cmd, deferred, promiseId) ->
    try
      project = atom.project

      cwd = if atom.project? and project.path? then project.path else null
      options = { cwd : cwd }

      exec cmd, options, (exception, stdout) ->
        console.log 'COMMAND RESULT -->'
        console.log exception
        console.log stdout

        jsonSTDOUT = JSON.parse stdout
        if promiseId?
          jsonSTDOUT.promiseId = promiseId
          deferred.resolve jsonSTDOUT
        else
          deferred.resolve jsonSTDOUT
    catch err
      console.error 'MavensMate: ',err
      deferred.reject new Error(err)

mm = new MavensMateCommandLineInterface()
exports.mm = mm
