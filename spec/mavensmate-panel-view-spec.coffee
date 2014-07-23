emitter   = require('../lib/mavensmate-emitter').pubsub
panel = require('../lib/mavensmate-panel-view').panel

# Top level describe is for the overall file
describe 'MavensMate Panel View', ->

  it 'should be defined', ->
    expect(panel).toBeDefined()
    expect(panel).toBeDefined()
    expect(panel[0].outerText).toBe('MavensMate for Atom.io')
    expect(panel.myHeader).toBeDefined()
    expect(panel.myOutput).toBeDefined()

  # nest descibes by functionality. e.g. Run All Tests, Compile, etc.
  describe 'Run All Tests (Async)', ->
    beforeEach ->
      # set up spy and ensure that calls are delegated
      spyOn(panel, 'getRunAllTestsCommandOutput').andCallThrough()

    it 'should indicate when all tests passed', ->
      # create fake params object
      myParams =  {args: {operation: 'run_all_tests'}, promiseId: 'my-fake-promiseId'}
      successResponse = require('./fixtures/mavensmate-panel-view/test_success.json')

      # simulate the emitter firing due to a panel start then finish with a success response from tooling api
      emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
      emitter.emit 'mavensmatePanelNotifyFinish', myParams, successResponse, 'my-fake-promiseId'

      # ensure that getRunAllTestsCommandOutput has been called with expected params
      expect(panel.getRunAllTestsCommandOutput).toHaveBeenCalled()
      expect(panel.getRunAllTestsCommandOutput).toHaveBeenCalledWith('run_all_tests', myParams, successResponse)

      # ensure the correct message was set
      expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('Run all tests complete. 3 tests passed.')
      expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('')

    it 'should indicate when some tests have failed', ->
      # create fake params object
      myParams =  {args: {operation: 'run_all_tests'}, promiseId: 'my-fake-promiseId'}
      failureResponse = require('./fixtures/mavensmate-panel-view/test_failure.json')

      # simulate the emitter firing due to a panel start then finish with a success response from tooling api
      emitter.emit 'mavensmatePanelNotifyStart', myParams, 'my-fake-promiseId'
      emitter.emit 'mavensmatePanelNotifyFinish', myParams, failureResponse, 'my-fake-promiseId'

      # ensure that getRunAllTestsCommandOutput has been called with expected params
      expect(panel.getRunAllTestsCommandOutput).toHaveBeenCalled()
      expect(panel.getRunAllTestsCommandOutput).toHaveBeenCalledWith('run_all_tests', myParams, failureResponse)

      # ensure the correct message was set
      expect(panel.myOutput.find('div#message-my-fake-promiseId').html()).toBe('1 failed test method')
      expect(panel.myOutput.find('div#stackTrace-my-fake-promiseId div pre').html()).toBe('SGToolKit_Batch_SendMessage_Test.shouldFail:\nClass.SGToolKit_Batch_SendMessage_Test.shouldFail: line 135, column 1\n\n')
