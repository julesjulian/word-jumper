###
# Debug-mode.
# @readonly
# @type {Boolean}
###
DEBUG = false

###
# Direction of the movement.
# @readonly
# @enum {Number}
###
directions = {RIGHT: 1, LEFT: 2}

###
# The string contains 'stop' symbols. In this string searching each letter
# of the caret-line. Can be customized for language needs in plugin setting.
# @readonly
# @type {String}
###
capitalLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
smallLetters = "abcdefghijklmnopqrstuvwxyz"
defaultStopSymbols = capitalLetters + "01234567890 {}()[]?-`~\"'._=:;%|/\\"
enclosingGuys = "[]{}()<>`\"'"

###
# Returns current editor.
# @return {atom#workspaceView#Editor}
###
getEditor = -> atom.workspace.getActiveTextEditor()

###
# Returns stop symbols from the local settings or local scope.
# @return {String}
###
getStopSymbols = -> atom.config.get("word-jumper-deluxe")?.stopSymbols || defaultStopSymbols

###
# Function returns sequence number of the first founded symbol in the
# gived string. Using proprety `stopSymbols` of the plugin settings.
# @param {String} text          - string in which searched substring
# @param {String} stopSymbols   -
# @example
# findBreakSymbol("theCamelCaseString");   // returns 3
# @example
# findBreakSymbol("CaseString");   // returns 4
# @example
# findBreakSymbol("somestring");   // returns 11
# @return {Number}   - position of the first founded 'stop' symbol.
###
findBreakSymbol = (text, symbols, direction) ->
    symbols = symbols || getStopSymbols()
    for letter, i in text
        if capitalLetters.indexOf(text[i]) == -1 or capitalLetters.indexOf(text[i-1]) == -1
            if symbols.indexOf(text[i]) != -1 and i != 0
                if enclosingGuys.indexOf(text[i]) != -1 and direction == directions.LEFT
                    return i - 1
                if direction == directions.LEFT and text[i..i+1] == "  "
                    return i - 1
                return i
        if direction == directions.LEFT and text[i..i+3] == "    "
            return i + 3
    return text.length

###
# Function move cursor to given direction taking into account 'stop' symbols.
# @param {atom#workspaceView#Editor#Cursor} cursor  - editor's cursor object
# @param {Number} direction                         - movement direction
# @param {Boolean} select                           - move cursor with selection
# @param {Boolean} remove                           - remove selection
# @param {Boolean} selection                        - selected range object
###
move = (cursor, direction, select, remove, selection=false) ->
  DEBUG && console.group "Moving cursor #%d", cursor.marker.id

  # Getting cursor's line number
  row = cursor.getScreenRow()
  # Getting cursor's position in the line
  column = cursor.getScreenColumn()

  # Getting line text
  textFull = cursor.getCurrentBufferLine()

  # Left of the cursor
  textLeft = textFull.substr(0, column)

  # Right of the cursor
  textRight = textFull.substr(column)

  # Text which will be searched for special characters
  _text = textRight

  if direction == directions.LEFT
    # Reverse all letters in the text-to-search
    _text = textLeft.split("").reverse().join("")

  # Getting cursor's position offset in the line
  offset = findBreakSymbol _text, getStopSymbols(), direction

  # If direction movement is left reverse offset as reversed a text search
  if direction == directions.LEFT
    offset = offset * (-1) - 1

  if cursor.isAtBeginningOfLine() and direction == directions.LEFT
    if cursor.getScreenRow() - 1 < 0
        row = 0
        column = 0
    else
        row = cursor.getScreenRow() - 1
        column = getEditor().lineTextForBufferRow(row).length + 1

  # If tried to move cursor to the right from beggin of the string
  # Search first symbol and move cursor there
  if cursor.isAtBeginningOfLine() and direction == directions.RIGHT
    if !cursor.isInsideWord()
      offset = findBreakSymbol _text, getStopSymbols().replace(/\s/, '') + smallLetters

  # If cursor at the end of the line, move cursor to the below line
  if cursor.isAtEndOfLine() and direction == directions.RIGHT
    row += 1
    column = 0

  DEBUG && console.debug "Position %dx%d", row, column
  DEBUG && console.debug "Text %c[%s………%s]", "font-weight:900", textLeft, textRight
  DEBUG && console.debug "Offset by", offset

  cursorPoint = [row, column + offset]

  # Selection mode or normal mode
  if select
    # Move selection
    selection.selectToBufferPosition(cursorPoint)
    if remove
      # remove selection
      selection.delete()
  else
    # Just move cursor to new position
    cursor.setBufferPosition(cursorPoint)

  DEBUG && console.groupEnd "Moving cursor #%d", cursor.marker.id

###
# Function iterate the list of cursors and moves each of them in
# required direction considering spec. symbols desribed by
# `stopSymbols` setting variable.
# @param {Number} direction - movement direction
# @param {Boolean} select   - move cursor with selection
# @param {Boolean} remove   - remove cursor with selection
###
moveCursors = (direction, select, remove) ->
  selections = getEditor().getSelections()
  move cursor, direction, select, remove, selections[i] for cursor, i in getEditor()?.getCursors()

module.exports =
  config:
    stopSymbols:
      type: 'string'
      default: defaultStopSymbols

  activate: ->
    atom.commands.add 'atom-workspace',
      'word-jumper-deluxe:move-right': ->
        moveCursors?directions.RIGHT

      'word-jumper-deluxe:move-left': ->
        moveCursors?directions.LEFT

      'word-jumper-deluxe:select-right': ->
        moveCursors?directions.RIGHT, true

      'word-jumper-deluxe:select-left': ->
        moveCursors?directions.LEFT, true

      'word-jumper-deluxe:remove-right': ->
        moveCursors?directions.RIGHT, true, true

      'word-jumper-deluxe:remove-left': ->
        moveCursors?directions.LEFT, true, true
