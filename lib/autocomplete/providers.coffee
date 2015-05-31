fuzzaldrin  = require 'fuzzaldrin'
apex        = require './apex.json'
vf          = require './vf.json'
_           = require 'underscore-plus'

# provides code assist for standard Apex Classes
#
# e.g. when user types "S", String, StringException, Site, Set, System, Sobject, etc. are showing in suggestions
class ApexProvider
  id: 'mavensmate-apexprovider'
  selector: '.source.apex'
  blacklist: '.comment.block.apex'
  apexClasses: null
  modifiers: [ 'public', 'private', 'static', 'final', 'global' ]

  constructor: ->
    apexClasses = []
    apexNamespaces = apex.publicDeclarations
    _.each _.keys(apexNamespaces), (ns) ->
      _.each _.keys(apexNamespaces[ns]), (cls) ->
        apexClasses.push cls
    @apexClasses = apexClasses

  requestHandler: (options) ->
    suggestions = []
    console.log 'ok handling'
    console.log options
    if options.scopeChain.indexOf('.storage.modifier.apex') != -1 or options.scopeChain == '.source.apex .meta.class.apex .meta.class.body.apex'
      for m in @modifiers
        suggestion =
          prefix: options.prefix
          word: m
          label: 'Apex'
        suggestions.push(suggestion)
    else if options.scopeChain.indexOf('.storage.type.apex') != -1 or options.scopeChain == '.source.apex .meta.class.apex .meta.class.body.apex .meta.definition.variable.apex'
      # console.log options.prefix
      # if options.prefix[0] == options.prefix[0].toUpperCase()
      words = fuzzaldrin.filter @apexClasses, options.prefix
      for word in words
        suggestion =
          prefix: options.prefix
          word: word
          label: 'Apex'
        suggestions.push(suggestion)
    return suggestions
  

  # # provides code assist for standard/custom Apex Class methods
  # #
  # # e.g. when user types "s.", if s represents a String, user is shown a list of String instance methods
  # ApexContextProvider: class ApexContextProvider extends Provider
  #   wordRegex: /\b\w*[a-zA-Z_]\w*\b./g
  #   buildSuggestions: ->
  #     selection = @editor.getSelection()
  #     # console.log selection
  #     prefix = @prefixOfSelection selection
  #     prefix = prefix.replace /./, ''
  #     # console.log 'prefix!'
  #     # console.log prefix
  #     #@editor.
      
  #     cursorPosition = @editor.getCursorBufferPosition() #=> returns a point
  #     cachedBufferText = @editor.getBuffer().cachedText #=> returns the CURRENT buffer
  #     # console.log cachedBufferText
  #     if prefix == '.'
  #       params =
  #         args:
  #           operation: 'get_apex_class_completions'
  #           pane: atom.workspace.getActivePane()
  #           offline: true
  #         payload:
  #           point: [cursorPosition.row, cursorPosition.column]
  #           buffer: cachedBufferText
  #           #file_name: util.activeFile()
  #       mm.run(params).then (result) =>
  #         # console.log result
  #         # TODO: waiting on: https://github.com/saschagehlich/autocomplete-plus/pull/99
  #         suggestions = []
  #         for s in result.body
  #           suggestions.push new Suggestion(this, word: s.name, label: "@"+s.name, prefix: prefix)
  #         console.log suggestions
  #         return suggestions


# provides code assist for visualforce tags
#
# e.g. when user types "<", list of vf tags is presented

class VisualforceTagProvider
  trailingWhitespace: /\s$/
  attributePattern: /\s+([a-z][-a-z]*)\s*=\s*$/
  tagPattern: /<[a-z]*:[a-z,A-Z]*(?:\s|$)/
  
  id: 'mavensmate-vfprovider'
  selector: '.visualforce'
  # vfTags: null

  constructor: ->
    # @vfTags = vf.tags
    # @loadCompletions()
    @completions = vf

  requestHandler: (request) ->
    console.log 'request ...'
    console.log request.editor
    if @isAttributeValueStartWithNoPrefix(request)
      @getAllAttributeValueCompletions(request)
    else if @isAttributeValueStartWithPrefix(request)
      @getAttributeValueCompletions(request)
    else if @isAttributeStartWithNoPrefix(request)
      @getAllAttributeNameCompletions(request)
    else if @isAttributeStartWithPrefix(request)
      @getAttributeNameCompletions(request)
    else if @isTagStartWithNoPrefix(request)
      @getAllTagNameCompletions()
    else if @isTagStartTagWithPrefix(request)
      @getTagNameCompletions(request)
    else
      []

  isTagStartWithNoPrefix: ({prefix, scope}) ->
    scopes = scope.getScopesArray()
    prefix is '<' and scopes.length is 1 and scopes[0] is 'visualforce.text.html.basic'

  isTagStartTagWithPrefix: ({prefix, scope}) ->
    return false unless prefix
    return false if @trailingWhitespace.test(prefix)
    @hasTagScope(scope.getScopesArray())

  isAttributeStartWithNoPrefix: ({prefix, scope}) ->
    console.log 'isAttributeStartWithNoPrefix'
    console.log prefix
    console.log @trailingWhitespace.test(prefix)
    return false unless @trailingWhitespace.test(prefix)
    @hasTagScope(scope.getScopesArray())

  isAttributeStartWithPrefix: ({prefix, scope, cursor, editor}) ->
    console.log 'isAttributeStartWithPrefix'
    console.log prefix

    return false unless prefix
    # return false if @trailingWhitespace.test(prefix)
    
    scopes = scope.getScopesArray()
    if scopes.indexOf('entity.other.attribute-name.html') is -1
      {row, column} = cursor.getBufferPosition()
      column = column - 1
      column = 0 if column < 0
      scopeDescriptor = editor.scopeDescriptorForBufferPosition([row, column])
      
      scopes = scopeDescriptor.scopes
      console.log scopes

    return true if scopes.indexOf('entity.other.attribute-name.html') isnt -1
    return false unless @hasTagScope(scopes)

    scopes.indexOf('punctuation.definition.tag.html') isnt -1 or
      scopes.indexOf('punctuation.definition.tag.end.html') isnt -1

  isAttributeValueStartWithNoPrefix: ({scope, prefix}) ->
    lastPrefixCharacter = prefix[prefix.length - 1]
    return false unless lastPrefixCharacter in ['"', "'"]
    scopes = scope.getScopesArray()
    @hasStringScope(scopes) and @hasTagScope(scopes)

  isAttributeValueStartWithPrefix: ({scope, prefix}) ->
    lastPrefixCharacter = prefix[prefix.length - 1]
    return false if lastPrefixCharacter in ['"', "'"]
    scopes = scope.getScopesArray()
    @hasStringScope(scopes) and @hasTagScope(scopes)

  hasTagScope: (scopes) ->
    console.log 'hasTagScope'
    console.log scopes
    console.log scopes.indexOf('meta.tag.other.html') isnt -1
    scopes.indexOf('meta.tag.any.html') isnt -1 or
      scopes.indexOf('meta.tag.other.html') isnt -1 or
      scopes.indexOf('meta.tag.block.any.html') isnt -1 or
      scopes.indexOf('meta.tag.inline.any.html') isnt -1 or
      scopes.indexOf('meta.tag.structure.any.html') isnt -1

  hasStringScope: (scopes) ->
    scopes.indexOf('string.quoted.double.html') isnt -1 or
      scopes.indexOf('string.quoted.single.html') isnt -1

  getAllTagNameCompletions: ->
    console.log 'getAllTagNameCompletions'

    completions = []
    for tag in @completions.tags
      completions.push({word: tag, prefix: '', label: 'Visualforce'})
    completions

  getTagNameCompletions: ({prefix}) ->
    console.log 'getTagNameCompletions'
    completions = []
    console.log 'prefix is: '+prefix
    # if prefix.indexOf('apex:') is not -1
    #   prefix = prefix.replace('apex:', '')
    matches = fuzzaldrin.filter @completions.tags, prefix
    for tag in matches
      completions.push({word: tag, prefix: prefix, label: 'Visualforce'})
    completions

  getAllAttributeNameCompletions: ({editor, cursor}) ->
    console.log 'getAllAttributeNameCompletions'

    completions = []

    tagAttributes = @getTagAttributes(editor, cursor)
    for attribute in tagAttributes
      completions.push({word: attribute.name, prefix: '', label: attribute.type})

    completions

  getAttributeNameCompletions: ({editor, cursor, prefix}) ->
    console.log 'getAttributeNameCompletions'

    completions = []

    tagAttributes = @getTagAttributes(editor, cursor)
    console.log 'tagAttributes'
    console.log tagAttributes
    # todo: implement snippets
    for attribute in tagAttributes when attribute.name.indexOf(prefix) is 0
      completions.push({word: attribute.name, prefix: prefix, label: attribute.type})

    completions

  getAllAttributeValueCompletions: ({editor, cursor}) ->
    console.log 'getAllAttributeValueCompletions'
    completions = []
    values = @getAttributeValues(editor, cursor)
    for value in values
      completions.push({word: value, prefix: ''})
    completions

  # not sure we want to provide this
  getAttributeValueCompletions: ({editor, cursor, prefix}) ->
    console.log 'getAttributeValueCompletions'
    completions = []
    values = @getAttributeValues(editor, cursor)
    for value in values when value.indexOf(prefix) is 0
      completions.push({word: value, prefix})
    completions

  # loadCompletions: ->
  #   @completions = {}
  #   fs.readFile path.resolve(__dirname, 'vf.json'), (error, content) =>
  #     console.log content
  #     @completions = JSON.parse(content) unless error?
  #     return

  getPreviousTag: (editor, cursor) ->
    row = cursor.getBufferRow()
    while row >= 0
      tag = @tagPattern.exec(editor.lineTextForBufferRow(row))?[0]
      console.log 'tttt'
      console.log tag
      if tag
        tag = tag.replace('<', '')
        tag = tag.trim()
      return tag if tag
      row--
    return

  getPreviousAttribute: (editor, cursor) ->
    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    line = line.substring(0, cursor.getBufferColumn()).trim()

    # Remove everything until the opening quote
    quoteIndex = line.length - 1
    quoteIndex-- while line[quoteIndex] and not (line[quoteIndex] in ['"', "'"])
    line = line.substring(0, quoteIndex)

    @attributePattern.exec(line)?[1]

  getAttributeValues: (editor, cursor) ->
    # attribute = @completions.attributes[@getPreviousAttribute(editor, cursor)]
    # attribute?.attribOption ? []
    []

  getTagAttributes: (editor, cursor) ->
    tag = @getPreviousTag(editor, cursor)
    console.log 'getting tag attributes for: '+tag
    tagDef = @completions.tagDefs[tag]
    attrs = []
    if tagDef and tagDef.attribs?
      for k, v of tagDef.attribs
        entry =
          name: k
          type: v.type
        attrs.push entry
    # console.log attrs
    return attrs
   
  # requestHandler: (options) ->
  #   suggestions = []
  #   console.log 'vf'
  #   console.log options
  #   if options.scopeChain.indexOf('.visualforce.text.html.basic .meta.tag.other.html') != -1
      
  #     console.log vf['something']
  #   else
  #     words = fuzzaldrin.filter @vfTags, options.prefix
  #     for word in words
  #       suggestion =
  #         prefix: options.prefix
  #         word: word.replace('apex:', '')
  #         label: 'Visualforce'
  #       suggestions.push(suggestion)
  #   return suggestions
      
  # provides code assist for visualforce tags
  #
  # e.g. when user types "<", list of vf tags is presented
# class VisualforceAttributeProvider
#   id: 'mavensmate-vf-attribute-provider'
#   selector: '.visualforce .meta.tag.html'
#   vfTags: []

#   constructor: ->
#     @vfTags = vf.tags

#   requestHandler: (options) ->
#     suggestions = []
#     words = fuzzaldrin.filter @vfTags, options.prefix

#     console.log 'building suggestions for vf tag context ...'
#     selection = @editor.getSelection()
#     console.log selection
#     prefix = @prefixOfSelection selection
#     console.log '----'
#     console.log prefix
#     return unless prefix.length

#     suggestions = @findSuggestionsForPrefix prefix
#     return unless suggestions.length
#     return suggestions

#   findSuggestionsForPrefix: (prefix) ->
#     # Filter the words using fuzzaldrin
#     prefix = prefix.replace '<', ''
#     words = fuzzaldrin.filter @vfTags, prefix

#     # Builds suggestions for the words
#     suggestions = for word in words
#       new Suggestion this, word: word, prefix: prefix, label: "@#{word} (Visualforce)"
#     return suggestions

  # # provides list of Sobjects available in the source org
  # #
  # # e.g. when user types "O" list of options may include Opportunity, OpportunityLineItem, OpportunityContactRole, etc.
  # SobjectProvider: class SobjectProvider extends Provider
  #   wordRegex: /[A-Z].*/g
  #   sobjects: ["Account", "Contact", "Opportunity"] #todo: populate sobjects

  #   buildSuggestions: ->
  #     selection = @editor.getSelection()
  #     prefix = @prefixOfSelection selection
  #     return unless prefix.length

  #     suggestions = @findSuggestionsForPrefix prefix
  #     return unless suggestions.length
  #     return suggestions

  #   findSuggestionsForPrefix: (prefix) ->
  #       # Filter the words using fuzzaldrin
  #       words = fuzzaldrin.filter @sobjects, prefix

  #       # console.log words

  #       # Builds suggestions for the words
  #       suggestions = for word in words
  #         new Suggestion this, word: word, prefix: prefix, label: "@#{word} (Sobject)"

  #       return suggestions

module.exports.ApexProvider = ApexProvider
module.exports.VisualforceTagProvider = VisualforceTagProvider