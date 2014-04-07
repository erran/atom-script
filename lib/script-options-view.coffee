{View} = require 'atom'

module.exports =
class ScriptOptionsView extends View

  @content: ->
    @div =>
      @div class: 'overlay from-top panel', outlet: 'scriptOptionsView', =>
        @div class: 'panel-heading', 'Configure Run Options'
        @div class: 'panel-body padded native-key-bindings', =>
          @div class: 'block', =>
            @label 'Current Working Directory:'
            @input
              type: 'text'
              class: 'editor mini editor-colors'
              outlet: 'inputCwd'
          @div class: 'block', =>
            @label 'Command'
            @input
              type: 'text'
              class: 'editor mini editor-colors'
              outlet: 'inputCommand'
          @div class: 'block', =>
            @label 'Command Arguments:'
            @input
              type: 'text'
              class: 'editor mini editor-colors'
              outlet: 'inputCommandArgs'
          @div class: 'block', =>
            @label 'Program Arguments:'
            @input
              type: 'text'
              class: 'editor mini editor-colors'
              outlet: 'inputScriptArgs'
          @div class: 'block', =>
            css = 'btn inline-block-tight'
            @button class: "btn #{css}", click: 'close', 'Close'
            @button class: "btn #{css}", click: 'run', 'Run'

  initialize: (run_options) ->
    atom.workspaceView.command 'script:run-options', => @runOptions()
    atom.workspaceView.command 'script:close-options',
      => @toggleScriptOptions 'hide'
    atom.workspaceView.command 'script:save-options', => @saveOptions()
    atom.workspaceView.prependToTop(this)
    @toggleScriptOptions 'hide'
    @run_options = run_options

  runOptions: ->
    @toggleScriptOptions()

  toggleScriptOptions: (command) ->
    if command?
      if command == 'show'
        @scriptOptionsView.show()
      if command == 'hide'
        @scriptOptionsView.hide()
    else
      @scriptOptionsView.toggle()

  saveOptions: =>
    splitArgs = (element) ->
      item for item in element.val().split(' ') when item isnt ''

    @run_options.cmd_cwd = @inputCwd.val()
    @run_options.cmd = @inputCommand.val()
    @run_options.cmd_args = splitArgs @inputCommandArgs
    @run_options.script_args = splitArgs @inputScriptArgs

  close: ->
    atom.workspaceView.trigger 'script:close-options'

  run: ->
    atom.workspaceView.trigger 'script:save-options'
    atom.workspaceView.trigger 'script:close-options'
    atom.workspaceView.trigger 'script:run'
