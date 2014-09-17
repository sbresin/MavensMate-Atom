path    = require 'path'
{exec, spawn}  = require 'child_process'
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

    opts = [] # any command line options
    cmd = null # command to run

    operation = if args.operation then args.operation else payload.command

    if cfg.mm_developer_mode
      if cfg.mm_mm_py_location == 'mm/mm.py'
        mm_location = path.join(atom.packages.resolvePackagePath('MavensMate-Atom'),cfg.mm_mm_py_location)
      else
        mm_location = cfg.mm_mm_py_location
      cmd = cfg.mm_python_location
      opts.push mm_location
    else
      if cfg.mm_path == 'default'
        mm_path = path.join(atom.packages.resolvePackagePath('MavensMate-Atom'),'mm')
      else
        mm_path = cfg.mm_path

      cmd = mm_path

    opts.push operation

    # ui operations
    if 'ui' of args && args['ui']
      opts.push '--ui'

      if operation in util.modalCommands()
        opts.push '-uid='+promiseId
      else
        opts.push '-uid='+args.pane.id

    # offline operations
    if 'offline' of args && args['offline']
      opts.push '--offline'

    opts.push '-c=ATOM'

    if payload?
      payload.settings = cfg
    else
      payload = { settings : cfg }

    # payload may include ajax_args from UI ajax requests
    if payload.ajax_args?
      for arg in payload.ajax_args
        opts.push arg

    stdin = JSON.stringify payload

    @execute cmd, opts, stdin, deferred, promiseId

    # add to promise tracker, emit an event so the panel knows when to do its thing
    tracker.start promiseId, deferred.promise
    emitter.emit 'mavensmatePanelNotifyStart', params, promiseId

    deferred.promise

  # Execute the command, resolve the promise
  execute: (cmd, opts, stdin, deferred, promiseId) ->
    try
      console.log cmd
      console.log opts
      console.log stdin

      project = atom.project

      cwd = if atom.project? and project.path? then project.path else null
      options = { cwd : cwd }

      childMmProcess = spawn(cmd, opts, cwd: cwd)

      childMmProcess.stdin.write(stdin)
      childMmProcess.stdin.end()

      stdout = ''
      stderr = ''

      childMmProcess.stdout.on "data", (data) ->
        # data.setEncoding 'utf8' ?
        # console.log "spawnSTDOUT:", data
        stdout += data

      childMmProcess.stderr.on "data", (data) ->
        # console.log "spawnSTDERR:", data
        stderr += data
      
      childMmProcess.on "close", (code) ->
        # console.log "Child process closed"
        return

      childMmProcess.on "disconnect", (code) ->
        # console.log "Child process disconnected"
        return

      childMmProcess.on "exit", (code) ->
        # console.log "Child exited with code " + code       
        jsonToParse = if stdout == '' then stderr else stdout
        jsonOutput = JSON.parse jsonToParse
        if promiseId?
          jsonOutput.promiseId = promiseId
          deferred.resolve jsonOutput
        else
          deferred.resolve jsonOutput
        return

    catch err
      console.error 'MavensMate: ',err
      deferred.reject new Error(err)

mm = new MavensMateCommandLineInterface()
exports.mm = mm
