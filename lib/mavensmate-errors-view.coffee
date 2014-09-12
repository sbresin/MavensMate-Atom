{$, $$, ScrollView} = 'atom'

module.exports =
class MavensMateErrorsView extends ScrollView
  @content: ->
    @h3 'Hey guyyys'

  focus: ->
    super

  serialize: ->
    deserializer: 'MavensMateErrorsView'
    version: 1
    uri: @uri