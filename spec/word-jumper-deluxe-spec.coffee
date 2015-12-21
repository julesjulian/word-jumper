WordJumper = require '../lib/word-jumper-deluxe'

describe "LineJumper", ->
    [editor, workspaceElement] = []
    beforeEach ->
        workspaceElement = atom.views.getView(atom.workspace)
        waitsForPromise ->
            Promise.all [
                atom.packages.activatePackage("word-jumper-deluxe")
                atom.workspace.open('sample.js').then (e) ->
                    editor = e
                ]

    describe "moving and selecting right", ->
        it "moves right 2-times", ->
              atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..2]
              pos = editor.getCursorBufferPosition()
              expect(pos).toEqual [0,8]

        it "moves right 3-times", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..3]
            pos = editor.getCursorBufferPosition()
            expect(pos).toEqual [0,13]

        it "moves right 13-times", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..13]
            pos = editor.getCursorBufferPosition()
            expect(pos).toEqual [0,40]

        it "moves right 16-times", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..16]
            pos = editor.getCursorBufferPosition()
            expect(pos).toEqual [1,0]

        it "moves right 20-times and left 3-times", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..20]
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-left') for [1..3]
            pos = editor.getCursorBufferPosition()
            expect(pos).toEqual [1,3]

        it "moves right 15-times and left 3-times", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..15]
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-left') for [1..3]
            pos = editor.getCursorBufferPosition()
            expect(pos).toEqual [0,38]

        it "selects right 2-times", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:select-right') for [1..2]
            selectedText = editor.getLastSelection().getText()
            expect(selectedText).toEqual "var test"

        it "selects right 5-times and left 2-times", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:select-right') for [1..5]
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:select-left') for [1..2]
            selectedText = editor.getLastSelection().getText()
            expect(selectedText).toEqual "var testCamel"

    describe "parentheses", ->
        it "does not select opening parenthesis", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..39]
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:select-left')
            selectedText = editor.getLastSelection().getText()
            expect(selectedText).toEqual "argument"

    describe "indentation space", ->
        it "does not delete indentation space", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..45]
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:remove-left')
            selectedText = editor.lineTextForBufferRow(3)
            expect(selectedText).toEqual "    _indented()"

        it "jumps over indentation space", ->
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-right') for [1..44]
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-left')
            pos = editor.getCursorBufferPosition()
            expect(pos).toEqual [3,0]

    describe "corner cases", ->
        it "can deal with the beginning of a file", ->
            pos = editor.getCursorBufferPosition()
            expect(pos).toEqual [0,0]
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-left')

        it "jumps correctly one line back", ->
            editor.setCursorBufferPosition [5, 0]
            atom.commands.dispatch(workspaceElement, 'word-jumper-deluxe:move-left')
            pos = editor.getCursorBufferPosition()
            expect(pos).toEqual [4, 6]
