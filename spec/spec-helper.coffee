module.exports =
  # Public: Indicates whether an element has a command.
  #
  # * `element` An {HTMLElement} to search.
  # * `name` A {String} containing the command name.
  #
  # Returns a {Boolean} indicating if it has the given command.

  hasCommand: (element, name) ->
    commands = atom.commands.findCommands(target: element)
    exists = false
    for command in commands
      if command.name == name
        exists = true
    exists
