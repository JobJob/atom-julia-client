{CompositeDisposable} = require 'atom'
{views} = require '../ui'
{client} = require '../connection'

workspace = require './workspace'
cons = require './console'

{nextline, stepin, finish, stepexpr, togglebp} =
  client.import ['nextline', 'stepin', 'finish', 'stepexpr', 'togglebp']

breakpoints = null

module.exports =
  activate: ->
    @subs = new CompositeDisposable

    client.handle
      debugmode: (state) => @debugmode state
      stepto: (file, line, text) => @stepto file, line, text

    @subs.add client.onDetached => @debugmode false

  deactivate: ->
    @subs.dispose()

  activeError: ->
    if not @active
      atom.notifications.addError "You need to be debugging to do that.",
        detail: """
          You can enter debugging by setting a breakpoint, or
          by calling `@step f(args...)`.
          """
        dismissable: true
      return true

  require: (f) -> @activeError() or f()

  debugmode: (@active) ->
    if !@active
      @stepper.destroy()
      workspace.update()
    else
      cons.c.input()

  stepto: (file, line, text) ->
    @stepper.goto file, line-1
    @stepper.setText views.render text
    workspace.update()

  nextline: -> @require -> nextline()
  stepin: -> @require -> stepin()
  finish: -> @require -> finish()
  stepexpr: -> @require -> stepexpr()

  breakpoints: []

  bp: (file, line) ->
    togglebp file, line
    if (existing = breakpoints.get(file, line, @breakpoints)[0])?
      @breakpoints = @breakpoints.filter (x) -> x != existing
      return existing.destroy()
    thebp = breakpoints.add file, line
    @breakpoints.push thebp


  togglebp: (ed = atom.workspace.getActiveTextEditor()) ->
    return unless ed
    for cursor in ed.getCursors()
      @bp ed.getPath(), cursor.getBufferPosition().row

  consumeInk: (ink) ->
    @stepper = new ink.Stepper
      buttons: [
        {icon: 'arrow-down', command: 'julia-debug:step-to-next-line'}
        {icon: 'link-external', command: 'julia-debug:finish-function'}
        {icon: 'move-right', command: 'julia-debug:step-into-function'}
        {icon: 'chevron-right', command: 'julia-debug:step-to-next-expression'}
      ]
    breakpoints = ink.breakpoints
    @subs.add breakpoints.addScope 'source.julia'
