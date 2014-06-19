{Provider, Suggestion} = require 'autocomplete-plus'
fuzzaldrin = require 'fuzzaldrin'
apex = require './apex.json'
console.log apex
_ = require 'underscore-plus'

module.exports =
  
  ApexProvider: class ApexProvider extends Provider
    wordRegex: /[A-Z].*/g
    apexClasses: []
    apexNamespaces: apex.publicDeclarations
    console.log 'foo!!!'
    #apexNamespaces: _.keys(apex.publicDeclarations)
    console.log @apexNamespaces
    _.each _.keys(@apexNamespaces), (ns) ->
      console.log ns
      _.each _.keys(@apexNamespaces[ns]), (cls) ->
        #console.log cls
        @apexClasses.push cls

    console.log @apexClasses
    #apexClasses: _.keys(apex.publicDeclarations.System)

    constructor: ->
      super
      #todo

    buildSuggestions: ->
      selection = @editor.getSelection()
      prefix = @prefixOfSelection selection
      return unless prefix.length

      suggestions = @findSuggestionsForPrefix prefix
      return unless suggestions.length
      return suggestions

    findSuggestionsForPrefix: (prefix) ->
        # Filter the words using fuzzaldrin
        words = fuzzaldrin.filter @apexClasses, prefix

        console.log words

        # Builds suggestions for the words
        suggestions = for word in words
          new Suggestion this, word: word, prefix: prefix, label: "@#{word} (Apex)"

        return suggestions

  ApexContextProvider: class ApexContextProvider extends Provider
    wordRegex: /\b\w*[a-zA-Z_]\w*\b./g
    buildSuggestions: ->
      selection = @editor.getSelection()
      prefix = @prefixOfSelection selection
      return unless prefix.length

      suggestions = []
      suggestions.push new Suggestion(this, word: "async", label: "@async", prefix: prefix)
      suggestions.push new Suggestion(this, word: "attributes", label: "@attribute", prefix: prefix)
      suggestions.push new Suggestion(this, word: "author", label: "@author", prefix: prefix)
      suggestions.push new Suggestion(this, word: "beta", label: "@beta", prefix: prefix)
      suggestions.push new Suggestion(this, word: "borrows", label: "@borrows", prefix: prefix)
      suggestions.push new Suggestion(this, word: "bubbles", label: "@bubbles", prefix: prefix)
      return suggestions

  SobjectProvider: class SobjectProvider extends Provider
    wordRegex: /[A-Z].*/g
    sobjects: ["Account", "Contact", "Opportunity"] #todo: populate sobjects

    buildSuggestions: ->
      selection = @editor.getSelection()
      prefix = @prefixOfSelection selection
      return unless prefix.length

      suggestions = @findSuggestionsForPrefix prefix
      return unless suggestions.length
      return suggestions

    findSuggestionsForPrefix: (prefix) ->
        # Filter the words using fuzzaldrin
        words = fuzzaldrin.filter @sobjects, prefix

        console.log words

        # Builds suggestions for the words
        suggestions = for word in words
          new Suggestion this, word: word, prefix: prefix, label: "@#{word} (Sobject)"

        return suggestions