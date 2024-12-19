//
//  UndoRedoManager.swift
//  XKit
//
//  Created by 🌊 薛 on 2022/10/26.
//

import Foundation

public enum UndoRedoManagerError: Error {
    case cannotUndo, cannotRedo
}

public class UndoRedoManager<T> {
    private enum ActionType: Hashable {
        case undo, redo
    }

    public var canUndo: Bool {
        !undoStack.isEmpty
    }

    public var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// The undo redo stack, which is an array of dictionaries of the format [undo/redo : function]
    private var undoStack: [[ActionType: () -> T?]]

    /// The separate redo stack to keep track of what can and should be redone next.
    private var redoStack: [[ActionType: () -> T?]]

    public init() {
        undoStack = []
        redoStack = []
    }

    /// Adds a new action to undos
    public func add(undo: @escaping () -> T?, redo: @escaping () -> T?) {
        // Add two entries to the dictionary, an undo and a redo with the respective indexes.
        undoStack.append([.undo: undo, .redo: redo])

        // Clear redos
        clearRedos()
    }

    /// Undo the last event.
    @discardableResult
    public func undo() throws -> T? {
        if !canUndo { throw UndoRedoManagerError.cannotUndo }

        // Get the last item in the stack.
        let last = undoStack.popLast()!

        // That last item is a function that says how something should be undone. Run the function.
        let val = last[.undo]?()

        // Now take the redo of that function and add it to the redo stack.
        redoStack.insert(last, at: 0)

        return val
    }

    /// Redo the last event.
    @discardableResult
    public func redo() throws -> T? {
        if !canRedo { throw UndoRedoManagerError.cannotRedo }

        // Get the last item in the redos.
        let last = redoStack.removeFirst()

        // Run that function to perform the redo.
        let val = last[.redo]?()

        // Make sure you add back the redo to the undo stack.
        undoStack.append(last)

        return val
    }

    public func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    /// Clears the redos.
    private func clearRedos() {
        redoStack.removeAll()
    }
}
