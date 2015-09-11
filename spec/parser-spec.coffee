parseCommand = require('../lib/panel/parsers').parse

describe 'clean-project parser', ->

  it 'should parse successful project clean', ->
    commandResult =
      result:
        message: 'Project cleaned successfully'

    parseResult = parseCommand('clean-project', {}, commandResult)
    expect(parseResult.error).toBe(undefined)
    expect(parseResult.stackTrace).toBe(undefined)
    expect(parseResult.indicator).toBe('success')
    expect(parseResult.message).toBe('Project cleaned successfully')

  it 'should parse failed project clean', ->
    commandResult =
      error: 'Failed!'
      result: 'Could not clean project'
      stack: 'A stack trace'

    parseResult = parseCommand('clean-project', {}, commandResult)
    expect(parseResult.isException).toBe(true)
    expect(parseResult.stackTrace).toBe('A stack trace')
    expect(parseResult.indicator).toBe('danger')
    expect(parseResult.message).toBe('Could not clean project')

describe 'logging parser', ->

  it 'should parse start logging', ->
    commandResult =
      result:
        message: 'Started logging'

    parseResult = parseCommand('start-logging', {}, commandResult)
    expect(parseResult.error).toBe(undefined)
    expect(parseResult.indicator).toBe('info')
    expect(parseResult.message).toBe('Started logging')

  it 'should parse start logging failure', ->
    commandResult =
      error: 'Failed!'
      result: 'Could not start logging'
      stack: 'A stack trace'

    parseResult = parseCommand('start-logging', {}, commandResult)
    expect(parseResult.isException).toBe(true)
    expect(parseResult.stackTrace).toBe('A stack trace')
    expect(parseResult.indicator).toBe('danger')
    expect(parseResult.message).toBe('Could not start logging')

# describe 'Run All Tests (Async)', ->
  #   beforeEach ->
  #     # set up spy and ensure that calls are delegated
  #     spyOn(panel, 'getRunAsyncTestsCommandOutput').andCallThrough()
  #     spyOn(mm, 'run').andCallThrough()

  #   fit 'should invoke mavensmate:run-all-tests-async', ->
  #     atom.workspaceView.trigger 'mavensmate:run-all-tests-async'
  #     expect(mm.run).toHaveBeenCalled()
  #     expect(mm.run.mostRecentCall.args[0].args.operation).toBe('run_all_tests')

  #   fit 'should indicate when all tests passed', ->
  #     # create fake params object
  #     myParams =  {args: {operation: 'run_all_tests'}, promiseId: 'my-fake-promiseId'}
  #     successResponse = require('./fixtures/mavensmate-panel-view/test_success.json')

  #     # simulate the emitter firing due to a panel start then finish with a success response from tooling api
  #     emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
  #     emitter.emit 'mavensmatePanelNotifyFinish', myParams, successResponse, 'my-fake-promiseId'

  #     # ensure that getRunAsyncTestsCommandOutput has been called with expected params
  #     expect(panel.getRunAsyncTestsCommandOutput).toHaveBeenCalled()
  #     expect(panel.getRunAsyncTestsCommandOutput).toHaveBeenCalledWith('run_all_tests', myParams, successResponse)

  #     # ensure the correct message was set
  #     expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('Run all tests complete. 3 tests passed.')
  #     expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('')

  #   it 'should indicate when some tests have failed', ->
  #     # create fake params object
  #     myParams =  {args: {operation: 'run_all_tests'}, promiseId: 'my-fake-promiseId'}
  #     failureResponse = require('./fixtures/mavensmate-panel-view/test_failure.json')

  #     # simulate the emitter firing due to a panel start then finish with a success response from tooling api
  #     emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
  #     emitter.emit 'mavensmatePanelNotifyFinish', myParams, failureResponse, 'my-fake-promiseId'

  #     # ensure that getRunAsyncTestsCommandOutput has been called with expected params
  #     expect(panel.getRunAsyncTestsCommandOutput).toHaveBeenCalled()
  #     expect(panel.getRunAsyncTestsCommandOutput).toHaveBeenCalledWith('run_all_tests', myParams, failureResponse)

  #     # ensure the correct message was set
  #     expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('1 failed test method')
  #     expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('SGToolKit_Batch_SendMessage_Test.shouldFail:\nClass.SGToolKit_Batch_SendMessage_Test.shouldFail: line 135, column 1\n\n')

  # # Refresh Selected metadata
  # describe 'Refresh Metadata', ->
  #   filePath = ''
  #   filePaths = []

  #   beforeEach ->
  #     # set up the workspace with a fake apex class
  #     directory = temp.mkdirSync()
  #     atom.project.setPath(directory)
  #     filePath = path.join(directory, 'MyApexClass.cls')
  #     filePaths = [filePath, path.join(directory,'AnotherClass.cls')]
  #     spyOn(mm, 'run').andCallThrough()

  #     waitsForPromise ->
  #       atom.packages.activatePackage 'tree-view'

  #     waitsForPromise ->
  #       atom.workspace.open(filePath)

  #   describe 'confirmations', ->

  #     it 'should prompt the user', ->
  #       spyOn(atom, 'confirm')
  #       atom.workspaceView.trigger 'mavensmate:refresh-selected-metadata'
  #       expect(atom.confirm).toHaveBeenCalled()

  #     it 'should not invoke mavensmate:refresh-selected-metadata if cancelled', ->
  #       spyOn(atom, 'confirm').andReturn(1)
  #       atom.workspaceView.trigger 'mavensmate:refresh-selected-metadata'
  #       expect(mm.run).not.toHaveBeenCalled()

  #     it 'should invoke mavensmate:refresh-selected-metadata and send a refresh call if confirmed', ->
  #       spyOn(atom, 'confirm').andReturn(0)
  #       atom.workspaceView.trigger 'mavensmate:refresh-selected-metadata'
  #       expect(mm.run).toHaveBeenCalled()
  #       expect(mm.run.mostRecentCall.args[0].args.operation).toBe('refresh')

  #   describe 'file selections', ->

  #     it 'should refresh the active file if the sidebar isn\'t focused', ->
  #       spyOn(atom, 'confirm').andReturn(0)
  #       atom.workspaceView.trigger 'mavensmate:refresh-selected-metadata'
  #       expect(mm.run.mostRecentCall.args[0].payload.files).toEqual([filePath])

  #     it 'should refresh the selected files if the sidebar is focused', ->
  #       util = require '../lib/util'
  #       treeView = util.treeView()
  #       spyOn(treeView, 'hasFocus').andReturn(true)
  #       spyOn(treeView, 'selectedPaths').andReturn(filePaths)
  #       spyOn(atom, 'confirm').andReturn(0)
  #       atom.workspaceView.trigger 'mavensmate:refresh-selected-metadata'
  #       expect(mm.run.mostRecentCall.args[0].payload.files).toEqual(filePaths)

  #   describe 'panel messaging', ->

  #     it 'should tell the user what file is being Refreshed and if it was successful', ->
  #       myParams =  {args: {operation: 'refresh', }, promiseId: 'my-fake-promiseId', payload: {files: [filePath]}}
  #       successResponse = require './fixtures/mavensmate-panel-view/generic_success.json'
  #       emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
  #       emitter.emit 'mavensmatePanelNotifyFinish', myParams, successResponse, 'my-fake-promiseId'
  #       console.log panel.myOutput.find('div#command-my-fake-promiseId div').html()
  #       expect(panel.myOutput.find('div#command-my-fake-promiseId div').html()).toBe('Refreshing ' + filePath + '...')
  #       expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('Operation completed successfully')
  #       expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('')

  # # Delete the metadata in the active pane from the server
  # describe 'Delete File from Server', ->
  #   filePath = ''
  #   filePaths = []

  #   beforeEach ->
  #     # set up the workspace with a fake apex class
  #     directory = temp.mkdirSync()
  #     atom.project.setPath(directory)
  #     filePath = path.join(directory, 'MyApexClass.cls')
  #     filePaths = [filePath, path.join(directory,'AnotherClass.cls')]
  #     spyOn(mm, 'run').andCallThrough()

  #     waitsForPromise ->
  #       atom.packages.activatePackage 'tree-view'

  #     waitsForPromise ->
  #       atom.workspace.open(filePath)

  #   describe 'confirmations', ->

  #     it 'should prompt the user', ->
  #       spyOn(atom, 'confirm')
  #       atom.workspaceView.trigger 'mavensmate:delete-file-from-server'
  #       expect(atom.confirm).toHaveBeenCalled()

  #     it 'should not invoke mavensmate:delete-file-from-server if cancelled', ->
  #       spyOn(atom, 'confirm').andReturn(0)
  #       atom.workspaceView.trigger 'mavensmate:delete-file-from-server'
  #       expect(mm.run).not.toHaveBeenCalled()

  #     it 'should invoke mavensmate:delete-file-from-server and send a delete call if confirmed', ->
  #       spyOn(atom, 'confirm').andReturn(1)
  #       atom.workspaceView.trigger 'mavensmate:delete-file-from-server'
  #       expect(mm.run).toHaveBeenCalled()
  #       expect(mm.run.mostRecentCall.args[0].args.operation).toBe('delete')

  #   describe 'file selections', ->

  #     it 'should delete the active file if the sidebar isn\'t focused', ->
  #       spyOn(atom, 'confirm').andReturn(1)
  #       atom.workspaceView.trigger 'mavensmate:delete-file-from-server'
  #       expect(mm.run.mostRecentCall.args[0].payload.files).toEqual([filePath])

  #     it 'should delete the selected files if the sidebar is focused', ->
  #       util = require '../lib/util'
  #       treeView = util.treeView()
  #       spyOn(treeView, 'hasFocus').andReturn(true)
  #       spyOn(treeView, 'selectedPaths').andReturn(filePaths)
  #       spyOn(atom, 'confirm').andReturn(1)
  #       atom.workspaceView.trigger 'mavensmate:delete-file-from-server'
  #       expect(mm.run.mostRecentCall.args[0].payload.files).toBe(filePaths)

  #   describe 'panel messaging', ->

  #     it 'should tell the user what file is being deleted and if it was successful', ->
  #       myParams =  {args: {operation: 'delete', }, promiseId: 'my-fake-promiseId', payload: {files: [filePath]}}
  #       successResponse = require './fixtures/mavensmate-panel-view/delete_success.json'
  #       emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
  #       emitter.emit 'mavensmatePanelNotifyFinish', myParams, successResponse, 'my-fake-promiseId'
  #       console.log panel.myOutput.find('div#command-my-fake-promiseId div').html()
  #       expect(panel.myOutput.find('div#command-my-fake-promiseId div').html()).toBe('Deleting MyApexClass.cls...')
  #       expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('Deleted MyApexClass.cls')
  #       expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('')

  # # Run unit tests for current class
  # describe 'Run Async Unit Tests For This Class', ->
  #   beforeEach ->
  #     # set up the workspace with a fake test class
  #     directory = temp.mkdirSync()
  #     atom.project.setPath(directory)
  #     filePath = path.join(directory, 'MyTest.cls')
  #     spyOn(panel, 'getRunAsyncTestsCommandOutput').andCallThrough()
  #     spyOn(mm, 'run').andCallThrough()

  #     waitsForPromise ->
  #       atom.workspace.open(filePath)

  #   it 'should invoke mavensmate:run-async-unit-tests', ->
  #     atom.workspaceView.trigger 'mavensmate:run-async-unit-tests'
  #     expect(mm.run).toHaveBeenCalled()
  #     expect(mm.run.mostRecentCall.args[0].args.operation).toBe('test_async')
  #     expect(mm.run.mostRecentCall.args[0].payload.classes[0]).toBe('MyTest')

  #   it 'should indicate when all tests passed', ->
  #     myParams = {args: {operation: 'test_async'}, promiseId: 'my-fake-promiseId'}
  #     successResponse = require('./fixtures/mavensmate-panel-view/test_success.json')

  #     # simulate the emitter firing due to a panel start then finish with a success response from tooling api
  #     emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
  #     emitter.emit 'mavensmatePanelNotifyFinish', myParams, successResponse, 'my-fake-promiseId'

  #     # ensure that getRunAsyncTestsCommandOutput has been called with expected params
  #     expect(panel.getRunAsyncTestsCommandOutput).toHaveBeenCalled()
  #     expect(panel.getRunAsyncTestsCommandOutput).toHaveBeenCalledWith('test_async', myParams, successResponse)

  #     # ensure the correct message was set
  #     expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('Run all tests complete. 3 tests passed.')
  #     expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('')

  #   it 'should indicate when some tests have failed', ->
  #     myParams = {args: {operation: 'test_async'}, promiseId: 'my-fake-promiseId'}
  #     failureResponse = require('./fixtures/mavensmate-panel-view/test_failure.json')

  #     # simulate the emitter firing due to a panel start then finish with a success response from tooling api
  #     emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
  #     emitter.emit 'mavensmatePanelNotifyFinish', myParams, failureResponse, 'my-fake-promiseId'

  #     # ensure that getRunAsyncTestsCommandOutput has been called with expected params
  #     expect(panel.getRunAsyncTestsCommandOutput).toHaveBeenCalled()
  #     expect(panel.getRunAsyncTestsCommandOutput).toHaveBeenCalledWith('test_async', myParams, failureResponse)

  #     # ensure the correct message was set
  #     expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('1 failed test method')
  #     expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('SGToolKit_Batch_SendMessage_Test.shouldFail:\nClass.SGToolKit_Batch_SendMessage_Test.shouldFail: line 135, column 1\n\n')

  # # Fetch Logs
  # describe 'Fetch Logs', ->
  #   it 'should indicate how many logs were fetched', ->
  #     myParams = {args: {operation: 'fetch_logs'}, promiseId: 'my-fake-promiseId'}
  #     response = require('./fixtures/mavensmate-panel-view/fetch_logs_4.json')

  #     # simulate the emitter firing due to a panel start then finish with a success response from tooling api
  #     emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
  #     emitter.emit 'mavensmatePanelNotifyFinish', myParams, response, 'my-fake-promiseId'

  #     # ensure the correct message was set
  #     expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('4 Logs successfully downloaded')
  #     expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('')

  # describe 'Compile Project', ->
  #   beforeEach ->
  #     spyOn(panel, 'getCompileProjectCommandOutput').andCallThrough()
  #     spyOn(mm, 'run').andCallThrough()

  #   it 'should invoke mavensmate:compile-project', ->
  #     spyOn(atom, 'confirm').andReturn(1)
  #     atom.workspaceView.trigger 'mavensmate:compile-project'

  #     expect(atom.confirm).toHaveBeenCalled()

  #   it 'should indicate when it is done compiling', ->
  #     myParams = {args: {operation: 'compile_project'}, promiseId: 'my-fake-promiseId'}
  #     successResponse = require('./fixtures/mavensmate-panel-view/compile_project_success.json')

  # describe 'Generic Operations', ->
  #   beforeEach ->
  #     spyOn(panel, 'getGenericOutput').andCallThrough()
  #     spyOn(mm, 'run').andCallThrough()

  #   it 'should indicate when it is done compiling', ->
  #     myParams = {args: {operation: 'generic_command'}, promiseId: 'my-fake-promiseId'}
  #     successResponse = require('./fixtures/mavensmate-panel-view/generic_success.json')

  #     # simulate the emitter firing due to a panel start then finish with a success response from tooling api
  #     emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
  #     emitter.emit 'mavensmatePanelNotifyFinish', myParams, successResponse, 'my-fake-promiseId'

  #     # ensure the correct message was set
  #     expect(panel.getGenericOutput).toHaveBeenCalled()
  #     expect(panel.getGenericOutput).toHaveBeenCalledWith('generic_command', myParams, successResponse)

  #     # ensure the correct message was set
  #     expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('Operation completed successfully')
  #     expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('')