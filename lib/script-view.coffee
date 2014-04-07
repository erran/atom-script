grammarMap = require './grammars'
{View, BufferedProcess} = require 'atom'
HeaderView = require './header-view'
ScriptOptionsView = require './script-options-view'
AnsiFilter = require 'ansi-to-html'
_ = require 'underscore'

# Runs a portion of a script through an interpreter and displays it line by line
module.exports =
class ScriptView extends View
  @bufferedProcess: null

  @content: ->
    @div =>
      @subview 'headerView', new HeaderView()

      # Display layout and outlets
      css = 'tool-panel panel panel-bottom padding script-view
        native-key-bindings'
      @div class: css, outlet: 'script', tabindex: -1, =>
        @div class: 'panel-body padded output', outlet: 'output'

  initialize: (serializeState, run_options) ->
    # Bind commands
    atom.workspaceView.command 'script:run', => @start()
    atom.workspaceView.command 'script:close-view', => @close()
    atom.workspaceView.command 'script:kill-process', => @stop()

    @ansiFilter = new AnsiFilter
    @run_options = run_options

  serialize: ->

  updateOptions: (event) =>
    console.log(event)
    @run_options = event.run_options

  start: ->
    # Get current editor
    editor = atom.workspace.getActiveEditor()

    # No editor available, do nothing
    return unless editor?

    @resetView()
    commandContext = @setup editor
    @run commandContext.command, commandContext.args if commandContext

  resetView: (title = 'Loading...') ->
    # Display window and load message

    # First run, create view
    atom.workspaceView.prependToBottom(@) unless @hasParent()

    # Close any existing process and start a new one
    @stop()

    @headerView.title.text title
    @headerView.setStatus 'start'

    # Get script view ready
    @output.empty()

  close: ->
    # Stop any running process and dismiss window
    @stop()
    @detach() if @hasParent()

  getlang: (editor) -> editor.getGrammar().name

  setup: (editor) ->
    # Store information about the run, including language
    commandContext = {}

    # Get language
    lang = @getlang(editor)

    err = null

    # Determine if no language is selected.
    if lang == 'Null Grammar' or lang == 'Plain Text'
      err = "You must select a language in the lower left, or save the file
        with an appropriate extension."

    # Provide them a dialog to submit an issue on GH, prepopulated with their
    # language of choice.
    else if not lang of grammarMap
      err = "Command not configured for #{lang}!
        \n\nAdd an <a href='https://github.com/rgbkrk/atom-script/issues/\
        new?title=Add%20support%20for%20#{lang}'>issue on GitHub</a>
        or send your own Pull Request."

    if err?
      @handleError(err)
      return false

    if not @run_options.cmd? or @run_options.cmd is ''
      # Precondition: lang? and lang of grammarMap
      commandContext.command = grammarMap[lang].command
    else
      commandContext.command = @run_options.cmd

    filename = editor.getTitle()

    # Get selected text
    selectedText = editor.getSelectedText()
    filepath = editor.getPath()

    # If no text was selected, either use the file
    # or select ALL the code in the editor

    # Brand new file, text not selected, "select" ALL the text
    if (not selectedText? or not selectedText) and not filepath?
      selectedText = editor.getText()

    # No selected text on a file that does exist, use filepath
    if (not selectedText? or not selectedText) and filepath?
      argType = 'File Based'
      arg = filepath
    else
      argType = 'Selection Based'
      arg = selectedText

    makeargs = grammarMap[lang][argType]

    try
      args = makeargs(arg)
      commandContext.args = args
    catch error
      err = "#{argType} runner not available for #{lang}.
        \n\nIf it should exist, add an
        <a href='https://github.com/rgbkrk/atom-script/issues/\
        new?title=Add%20support%20for%20#{lang}'>issue on GitHub</a>, or send
        your own pull request."

      @handleError(err)
      return false

    # Update header
    @headerView.title.text "#{lang} - #{filename}"

    # Return setup information
    return commandContext

  handleError: (err) ->
    # Display error and kill process
    @headerView.title.text 'Error'
    @headerView.setStatus 'err'
    @display 'error', err
    @stop()

  run: (command, args) ->
    atom.emit 'achievement:unlock', msg: 'Homestar Runner'

    # Default to where the user opened atom
    options =
      cwd: @getCwd()
      env: process.env
    args = (@run_options.cmd_args.concat args).concat @run_options.script_args

    stdout = (output) => @display 'stdout', output
    stderr = (output) => @display 'stderr', output
    exit = (return_code) =>
      if return_code is 0
        @headerView.setStatus 'stop'
      else
        @headerView.setStatus 'err'
      console.log "Exited with #{return_code}"

    # Run process
    @bufferedProcess = new BufferedProcess({command, args, options,
                                            stdout, stderr, exit})
    @bufferedProcess.process.on('error', (node_error) =>
      @output.append "<h1>Unable to run</h1>
        <pre>#{_.escape command}</pre>
        <h2>Is it on your path?</h2>
        <pre>PATH: #{_.escape process.env.PATH}</pre>"
    )

  getCwd: ->
    if not @run_options.cmd_cwd? or @run_options.cmd_cwd is ''
      atom.project.getPath()
    else
      @run_options.cmd_cwd

  stop: ->
    # Kill existing process if available
    if @bufferedProcess? and @bufferedProcess.process?
      @display 'stdout', '^C'
      @headerView.setStatus 'kill'
      @bufferedProcess.kill()

  display: (css, line) ->

    line = _.escape(line)
    line = @ansiFilter.toHtml(line)

    @output.append "<pre class='line #{css}'>#{line}</pre>"
