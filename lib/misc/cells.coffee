scopes = require './scopes'
{values} = require 'underscore-plus'

module.exports =

  getCurrentCell: (ed) ->
    buffer = ed.getBuffer()
    start = buffer.getFirstPosition()
    end = buffer.getEndPosition()
    regexString = atom.config.get 'julia-client.cellDelimiter'

    unless regexString?
      return [start, end]

    regex = new RegExp regexString
    cursor = ed.getCursorBufferPosition()

    if cursor.row > 0
      buffer.backwardsScanInRange regex, [start, cursor], ({range}) ->
          start = range.start

    buffer.scanInRange regex, [cursor, end], ({range}) ->
      end = range.start

    celltext = ed.getTextInBufferRange([start, end])
    res =
      range: [values(start), values(end)]
      selection: ed.getSelections()[0]
      line: end.row + 1
      text: celltext

    [res]
