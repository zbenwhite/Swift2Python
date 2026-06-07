//
//  PythonInterpreter+List.swift
//  Swift2Python
//
//  Created by Ben White on 5/13/26.
//

import Foundation

// TODO: The stuff with Python 3.13 and free threading for PyList_GetItem()

extension PythonInterpreter {
    
    // MARK: Convert To Python List
    
    /// Create a PythonObject list from a Swift array.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic.
    ///
    /// ```swift
    /// let list = try await interpreter.convertToPython(array: [1, 2, 3])
    /// ```
    ///
    /// Use this overload for homogeneous arrays and for heterogeneous arrays whose
    /// elements are stored as `any PendingPythonConvertible`.
    ///
    /// - Parameters:
    ///   - array: A Swift array whose elements conform to `PendingPythonConvertible`.
    /// - Returns: A `PythonObject` representing a Python list.
    /// - Throws: `PythonError` if list creation or element conversion fails.
    public func convertToPython(array: [any PendingPythonConvertible]) async throws -> PythonObject {
        let listPtr = try await withGIL {
            try newPythonList(ofSize: array.count, orElse: { try throwPythonError() })
        }
        for (index, element) in array.enumerated() {
            let valuePythonObject = try await element.toPythonObject(interpreter: self)
            let valuePtr = getRegisteredPointer(forPythonObject:valuePythonObject)!
            _ = try await withGIL {
                try setItem(valuePtr, onList: listPtr, atIndex: index, orElse: { try throwPythonError() })
            }
        }
        return newPythonObject(fromReturnedPointer: listPtr)
    }
    
    
    /// Create a SafePythonObject list from a Swift array.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let list = try context.convertToSafePython(array: [1, 2, 3])
    /// }
    /// ```
    ///
    /// Use this overload for homogeneous arrays and for heterogeneous arrays whose
    /// elements are stored as `any SafePythonConvertible`.
    ///
    /// - Parameters:
    ///   - array: A Swift array whose elements conform to `SafePythonConvertible`.
    /// - Returns: A `SafePythonObject` representing a Python list.
    /// - Throws: `PythonError` if list creation or element conversion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(array: [any SafePythonConvertible]) throws -> PythonInterpreter.SafePythonObject {
        let listPtr = try newPythonList(ofSize: array.count, orElse: { try throwSafePythonError() })
        for (index, element) in array.enumerated() {
            let valueSafeObject = try element.toSafePythonObject(interpreter: self)
            let valuePtr = getRegisteredPointer(forSafeObj:valueSafeObject)
            _ = try setItem(valuePtr, onList: listPtr, atIndex: index, orElse: { try throwSafePythonError() })
        }
        return newSafePythonObject(fromReturnedPointer: listPtr)
    }
    
    
    // MARK: Python API Helpers
    
    // This requires the GIL
    private func newPythonList(ofSize: Int, orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try api.pythonList_New(ofSize) ?? {
            try throwError()
        } ()
    }
    
    // This requires the GIL
    private func isList(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Bool  {
        switch api.pythonObject_IsInstance(objPtr, api.PyList_Type) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    // This requires the GIL
    private func getSizeOf(list: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Int {
        let result = api.pythonList_Size(list)
        if result == -1 {
            try throwError()
        }
        return result
    }
    
    // This requires the GIL
    private func normalizeListIndex(_ index: Int, inList list: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws -> Int {
        if index >= 0 {
            return index
        }
        let count = try getSizeOf(list: list, onError: throwError)
        return count + index
    }
    
    // This requires the GIL
    private func setItem(_ item: UnsafeMutableRawPointer, onList: UnsafeMutableRawPointer, atIndex: Int, orElse throwError: () throws -> Never) throws {
        
        // PyList_SetItem is a special case for reference handling.  Python "steals"
        // the reference.  What this means is that Python assumes it is the sole owner
        // of the item after PyList_SetItem.  Since my internal reference count is 1
        // the item will get freed when it is destructed, leading to a double free
        // memory management error.  I need to increment Python's reference count to
        // match my reference count of 1.
        api.Py_IncRef(item)
        
        let result = api.pythonList_SetItem(onList, atIndex, item)
        if result != 0 {
            
            // If it fails, then python doesn't steal the reference, so don't increment.
            // (I'm doing it in this order because it's safer.  I don't want Python
            // to free the object before PyList_SetItem returns -1.)
            api.Py_DecRef(item)
            try throwError()
        }
    }
    
    // This requires the GIL
    private func getItemAt(index: Int, fromList list: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer {
        try api.pythonList_GetItem(list, index) ?? {
            try throwError()
        } ()
    }
    
    // This requires the GIL
    private func appendItem(_ item: UnsafeMutableRawPointer, toList: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws {
        let result = api.pythonList_Append(toList, item)
        if result != 0 {
            try throwError()
        }
    }
    
    // This requires the GIL
    private func insertItem(_ item: UnsafeMutableRawPointer, atIndex: Int, inList: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws {
        let result = api.pythonList_Insert(inList, atIndex, item)
        if result != 0 {
            try throwError()
        }
    }
    
    // This requires the GIL
    private func deleteItem(at index: UnsafeMutableRawPointer, fromList list: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws {
        let result = api.pythonObject_DelItem(list, index)
        if result == -1 {
            try throwError()
        }
    }
    
    // This requires the GIL
    internal func toArray<K>(fromPythonListPointer objPtr: UnsafeMutableRawPointer,
                             onError throwError: () throws -> Never,
                             handleEachItem: (UnsafeMutableRawPointer) throws -> K) throws -> [K] {
        let isList = try isList(objPtr, onError: { try throwError() } )
        guard isList else {
            throw PythonError.listConversionFailed(expected: "list", actual: nil)
        }
        let size = try getSizeOf(list: objPtr, onError: { try throwError() } )
        return try (0..<size).map { index in
            let ptr = try getItemAt(index: index, fromList: objPtr, onError: { try throwError() } )
            return try handleEachItem(ptr)
        }
    }
    
    // This requires the GIL
    internal func toArray<K>(fromPythonListPointer objPtr: UnsafeMutableRawPointer,
                             onError throwError: () throws -> Never,
                             borrowedObject: (UnsafeMutableRawPointer) -> K) throws -> [K] {
        return try toArray(fromPythonListPointer: objPtr, onError: throwError, handleEachItem: borrowedObject)
    }
    
    internal func toArray(_ obj: PythonObject) async throws -> [PythonObject] {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            try toArray(fromPythonListPointer: objPtr,
                        onError: { try throwPythonError() },
                        borrowedObject: { ptr in borrowedPythonObject(fromReturnedPointer: ptr)} )
        }
    }
    
    // MARK: Is Python List ?
    
    internal func isList(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isList(objPtr, onError: { try throwPythonError() } ) }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncIsList(_ obj: PythonInterpreter.SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isList(objPtr, onError: { try throwSafePythonError() } )
    }
    
    // MARK: Python List Count
    
    internal func getListCount(_ obj: PythonObject) async throws -> Int {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isList = try isList(objPtr, onError: { try throwPythonError() } )
            guard isList else {
                throw PythonError.listConversionFailed(expected: "list", actual: nil)
            }
            return try getSizeOf(list: objPtr, onError: { try throwPythonError() } )
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncListCount(_ obj: PythonInterpreter.SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isList = try isList(objPtr, onError: { try throwSafePythonError() } )
        guard isList else {
            throw PythonError.listConversionFailed(expected: "list", actual: nil)
        }
        return try getSizeOf(list: objPtr, onError: { try throwSafePythonError() } )
    }
    
    // MARK: Python List Mutation
    
    internal func appendListItem(_ item: PendingPythonConvertible, to list: PythonObject) async throws {
        let listPtr = getRegisteredPointer(forPythonObject: list)!
        let itemObj = try await item.toPythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forPythonObject: itemObj)!
        return try await withGIL {
            let isList = try isList(listPtr, onError: { try throwPythonError() } )
            guard isList else {
                throw PythonError.listConversionFailed(expected: "list", actual: nil)
            }
            try appendItem(itemPtr, toList: listPtr, onError: { try throwPythonError() })
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncAppendListItem(_ item: SafePythonConvertible, to list: PythonInterpreter.SafePythonObject) throws {
        let listPtr = getRegisteredPointer(forSafeObj: list)
        let itemObj = try item.toSafePythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forSafeObj: itemObj)
        let isList = try isList(listPtr, onError: { try throwSafePythonError() } )
        guard isList else {
            throw PythonError.listConversionFailed(expected: "list", actual: nil)
        }
        try appendItem(itemPtr, toList: listPtr, onError: { try throwSafePythonError() })
    }
    
    internal func insertListItem(_ item: PendingPythonConvertible, at index: Int, to list: PythonObject) async throws {
        let listPtr = getRegisteredPointer(forPythonObject: list)!
        let itemObj = try await item.toPythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forPythonObject: itemObj)!
        return try await withGIL {
            let isList = try isList(listPtr, onError: { try throwPythonError() } )
            guard isList else {
                throw PythonError.listConversionFailed(expected: "list", actual: nil)
            }
            try insertItem(itemPtr, atIndex: index, inList: listPtr, onError: { try throwPythonError() })
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncInsertListItem(_ item: SafePythonConvertible, at index: Int, to list: PythonInterpreter.SafePythonObject) throws {
        let listPtr = getRegisteredPointer(forSafeObj: list)
        let itemObj = try item.toSafePythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forSafeObj: itemObj)
        let isList = try isList(listPtr, onError: { try throwSafePythonError() } )
        guard isList else {
            throw PythonError.listConversionFailed(expected: "list", actual: nil)
        }
        try insertItem(itemPtr, atIndex: index, inList: listPtr, onError: { try throwSafePythonError() })
    }
    
    // MARK: Python List Indexing
    
    internal func listItem(at index: Int, in obj: PythonObject) async throws -> PythonObject {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isList = try isList(objPtr, onError: { try throwPythonError() } )
            guard isList else {
                throw PythonError.listConversionFailed(expected: "list", actual: nil)
            }
            
            let normalizedIndex = try normalizeListIndex(index, inList: objPtr, onError: { try throwPythonError() })
            let ptr = try getItemAt(index: normalizedIndex, fromList: objPtr, onError: { try throwPythonError() } )
            return borrowedPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncListItem(at index: Int, in obj: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isList = try isList(objPtr, onError: { try throwSafePythonError() } )
        guard isList else {
            throw PythonError.listConversionFailed(expected: "list", actual: nil)
        }
        
        let normalizedIndex = try normalizeListIndex(index, inList: objPtr, onError: { try throwSafePythonError() })
        let ptr = try getItemAt(index: normalizedIndex, fromList: objPtr, onError: { try throwSafePythonError() } )
        return borrowedSafePythonObject(fromReturnedPointer: ptr)
    }
    
    internal func setListItem(_ item: PendingPythonConvertible, at index: Int, in list: PythonObject) async throws {
        let listPtr = getRegisteredPointer(forPythonObject: list)!
        let itemObj = try await item.toPythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forPythonObject: itemObj)!
        return try await withGIL {
            let isList = try isList(listPtr, onError: { try throwPythonError() } )
            guard isList else {
                throw PythonError.listConversionFailed(expected: "list", actual: nil)
            }
            let normalizedIndex = try normalizeListIndex(index, inList: listPtr, onError: { try throwPythonError() })
            try setItem(itemPtr, onList: listPtr, atIndex: normalizedIndex, orElse: { try throwPythonError() })
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncSetListItem(_ item: SafePythonConvertible, at index: Int, in list: PythonInterpreter.SafePythonObject) throws {
        let listPtr = getRegisteredPointer(forSafeObj: list)
        let itemObj = try item.toSafePythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forSafeObj: itemObj)
        let isList = try isList(listPtr, onError: { try throwSafePythonError() } )
        guard isList else {
            throw PythonError.listConversionFailed(expected: "list", actual: nil)
        }
        let normalizedIndex = try normalizeListIndex(index, inList: listPtr, onError: { try throwSafePythonError() })
        try setItem(itemPtr, onList: listPtr, atIndex: normalizedIndex, orElse: { try throwSafePythonError() })
    }
    
    internal func delListItem(at index: Int, from list: PythonObject) async throws {
        let listPtr = getRegisteredPointer(forPythonObject: list)!
        let indexObj = try await index.toPythonObject(interpreter: self)
        let indexPtr = getRegisteredPointer(forPythonObject: indexObj)!
        return try await withGIL {
            let isList = try isList(listPtr, onError: { try throwPythonError() } )
            guard isList else {
                throw PythonError.listConversionFailed(expected: "list", actual: nil)
            }
            try deleteItem(at: indexPtr, fromList: listPtr, onError: { try throwPythonError() })
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncDeleteItem(fromList list: PythonInterpreter.SafePythonObject, at index: Int) throws {
        let indexObj = try index.toSafePythonObject(interpreter: self)
        let indexPtr = getRegisteredPointer(forSafeObj: indexObj)
        let listPtr = getRegisteredPointer(forSafeObj: list)
        let isList = try isList(listPtr, onError: { try throwSafePythonError() } )
        guard isList else {
            throw PythonError.listConversionFailed(expected: "list", actual: nil)
        }
        try deleteItem(at: indexPtr, fromList: listPtr, onError: { try throwSafePythonError() })
    }
    
    internal func syncListArray(_ obj: SafePythonObject) throws -> [SafePythonObject] {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try toArray(fromPythonListPointer: objPtr,
                        onError: { try throwSafePythonError() },
                        borrowedObject: { ptr in borrowedSafePythonObject(fromReturnedPointer: ptr)} )
    }
}
