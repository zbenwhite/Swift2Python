//
//  PythonInterpreter+Tuple.swift
//  Swift2Python
//
//  Created by Ben White on 5/9/26.
//

import Foundation


// TODO: tupleArray returns nil but toTupleArray throws.  This should be consistent or the reason should be documented
// TODO: Same for getTupleCount versus tupleCount
// TODO: Python negative indexing -- either support it or document that it's not supported.

// Codex suggestions for error fixes:
//
// case tupleConversionFailed(expected: String, actual: String?)
// case tupleArityMismatch(expected: Int, actual: Int)

extension PythonInterpreter {
    
    // MARK: Convert To Python Tuples
    
    public func convertToPython<T>(tupleContentsOf elements: T) async throws -> PythonObject
        where T: Sequence, T.Element: PendingPythonConvertible
    {
        let tuplePtr = try await createTupleAsync(elements.map { $0 as any PendingPythonConvertible })
        return newPythonObject(fromReturnedPointer: tuplePtr)
    }
    
    public func convertToPython(tupleOf elements: any PendingPythonConvertible...) async throws -> PythonObject {
        let tuplePtr = try await createTupleAsync(elements)
        return newPythonObject(fromReturnedPointer: tuplePtr)
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    public func convertToSafePython<T>(tupleContentsOf elements: T) throws -> PythonInterpreter.SafePythonObject
        where T: Sequence, T.Element: SafePythonConvertible
    {
        let tuplePtr = try syncCreateTuplePtr(from: elements.map { $0 as any SafePythonConvertible })
        return newSafePythonObject(fromReturnedPointer: tuplePtr)
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    public func convertToSafePython(tupleOf elements: any SafePythonConvertible...) throws -> PythonInterpreter.SafePythonObject {
        let tuplePtr = try syncCreateTuplePtr(from: elements)
        return newSafePythonObject(fromReturnedPointer: tuplePtr)
    }
    
    // MARK: Python API Helpers
    
    // This requires the GIL
    private func newPythonTuple(ofSize: Int, orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try api.pythonTuple_New(ofSize) ?? {
            try throwError()
        } ()
    }

    // This requires the GIL
    private func setItem(_ item: UnsafeMutableRawPointer, onTuple: UnsafeMutableRawPointer, atIndex: Int, orElse throwError: () throws -> Never) throws {
        
        // PyTuple_SetItem is a special case for reference handling.  Python "steals"
        // the reference.  What this means is that Python assumes it is the sole owner
        // of the item after PyTuple_SetItem.  Since my internal reference count is 1
        // the item will get freed when it is destructed, leading to a double free
        // memory management error.  I need to increment Python's reference count to
        // match my reference count of 1.
        api.Py_IncRef(item)
        
        let result = api.pythonTuple_SetItem(onTuple, atIndex, item)
        if result != 0 {
            
            // If it fails, then python doesn't steal the reference, so don't increment.
            // (I'm doing it in this order because it's safer.  I don't want Python
            // to free the object before PyTuple_SetItem returns -1.)
            api.Py_DecRef(item)
            try throwError()
        }
    }
    
    // This requires the GIL
    private func isTuple(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Bool  {
        switch api.pythonObject_IsInstance(objPtr, api.PyTuple_Type) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    // This requires the GIL
    private func getSizeOf(tuple: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Int {
        let result = api.pythonTuple_Size(tuple)
        if result == -1 {
            try throwError()
        }
        return result
    }
    
    // This requires the GIL
    private func getItemAt(index: Int, fromTuple: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer {
        try api.pythonTuple_GetItem(fromTuple, index) ?? {
            try throwError()
        } ()
    }
    
    // MARK: Create Python Tuples
    
    internal func createTupleAsync(_ args: [any PendingPythonConvertible]) async throws -> UnsafeMutableRawPointer {
        // TODO: improve performance
        // This acquires the GIL to create the tuple, releases it, potentially re-aquires and releases
        // it to convert each item to a PythonObject, and then re-aquires and releases it to setItem
        // on every item.  All because await while you own the GIL causes deadlocks.
        // It also creates reference-managed PythonObjects for each item, even if they are never used
        // beyond being put in the tuple.  All this machinery makes it safe but somewhat inefficient.
        // But Python is not for speed, performancce improvements are left for the future.
        let tuplePtr = try await withGIL {
            try newPythonTuple(ofSize: args.count, orElse: { try throwPythonError() })
        }
        
        for (index, element) in args.enumerated() {
            let pyObj = try await element.toPythonObject(interpreter: self)
            let itemPtr = getRegisteredPointer(forPythonObject:pyObj)!
            _ = try await withGIL {
                try setItem(itemPtr, onTuple: tuplePtr, atIndex: index, orElse: { try throwPythonError() })
            }
        }
        return tuplePtr
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncCreateTuplePtr(from elements: [any SafePythonConvertible]) throws -> UnsafeMutableRawPointer {
        let tuplePtr = try newPythonTuple(ofSize: elements.count, orElse: { try throwSafePythonError() })
        
        for (index, element) in elements.enumerated() {
            
            // Convert args from SafePythonConvertible to SafePythonObject
            let pyObj = try element.toSafePythonObject(interpreter: self)
            let itemPtr = getRegisteredPointer(forSafeObj:pyObj)
            
            try setItem(itemPtr, onTuple: tuplePtr, atIndex: index, orElse: { try throwSafePythonError() })
        }
        
        return tuplePtr
    }
    
    // MARK: Is Python Tuple ?
    
    internal func isTuple(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isTuple(objPtr, onError: { try throwPythonError() } ) }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncIsTuple(_ obj: PythonInterpreter.SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isTuple(objPtr, onError: { try throwSafePythonError() } )
    }
    
    // MARK: Python Tuple Count
    
    internal func getTupleCount(_ obj: PythonObject) async throws -> Int {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try getSizeOf(tuple: objPtr, onError: { try throwPythonError() } ) }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncTupleCount(_ obj: PythonInterpreter.SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try getSizeOf(tuple: objPtr, onError: { try throwSafePythonError() } )
    }
    
    // MARK: Python Tuple Indexing
    
    internal func tupleItem(at index: Int, in obj: PythonObject) async throws -> PythonObject {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isTuple = try isTuple(objPtr, onError: { try throwPythonError() } )
            guard isTuple else {
                throw PythonError.typeError(operation: "tuple item access", opType1: "", opType2: "")
            }
            
            let ptr = try getItemAt(index: index, fromTuple: objPtr, onError: { try throwPythonError() } )
            return borrowedPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncTupleItem(at index: Int, in obj: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject? {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isTuple = try isTuple(objPtr, onError: { try throwSafePythonError() } )
        guard isTuple else { return nil }
        
        let ptr = try getItemAt(index: index, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        return borrowedSafePythonObject(fromReturnedPointer: ptr)
    }
    
    // MARK: Convert To Swift Array
    
    internal func toTupleArray(_ obj: PythonObject) async throws -> [PythonObject] {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isTuple = try isTuple(objPtr, onError: { try throwPythonError() } )
            guard isTuple else {
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let size = try getSizeOf(tuple: objPtr, onError: { try throwPythonError() } )
            return try (0..<size).map { index in
                let ptr = try getItemAt(index: index, fromTuple: objPtr, onError: { try throwPythonError() } )
                return borrowedPythonObject(fromReturnedPointer: ptr)
            }
        }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncTupleArray(_ obj: PythonInterpreter.SafePythonObject) throws -> [PythonInterpreter.SafePythonObject]? {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isTuple = try isTuple(objPtr, onError: { try throwSafePythonError() } )
        guard isTuple else { return nil }
        
        let size = try getSizeOf(tuple: objPtr, onError: { try throwSafePythonError() } )
        return try (0..<size).map { index in
            let ptr = try getItemAt(index: index, fromTuple: objPtr, onError: { try throwSafePythonError() } )
            return borrowedSafePythonObject(fromReturnedPointer: ptr)
        }
    }
    
    // MARK: Convert To Swift Tuples
    
    internal func toTuple2(_ obj: PythonObject) async throws -> (PythonObject, PythonObject) {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isTuple = try isTuple(objPtr, onError: { try throwPythonError() } )
            guard isTuple else {
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let size = try getSizeOf(tuple: objPtr, onError: { try throwPythonError() } )
            guard size == 2 else {
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let ptr0 = try getItemAt(index: 0, fromTuple: objPtr, onError: { try throwPythonError() } )
            let ptr1 = try getItemAt(index: 1, fromTuple: objPtr, onError: { try throwPythonError() } )
            return (
                borrowedPythonObject(fromReturnedPointer: ptr0),
                borrowedPythonObject(fromReturnedPointer: ptr1)
            )
        }
    }
    
    internal func toTuple3(_ obj: PythonObject) async throws -> (PythonObject, PythonObject, PythonObject) {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isTuple = try isTuple(objPtr, onError: { try throwPythonError() } )
            guard isTuple else {
                // FIXME: These type errors are not setup right.  The setup is too specific to arithmetic operators.
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let size = try getSizeOf(tuple: objPtr, onError: { try throwPythonError() } )
            guard size == 3 else {
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let ptr0 = try getItemAt(index: 0, fromTuple: objPtr, onError: { try throwPythonError() } )
            let ptr1 = try getItemAt(index: 1, fromTuple: objPtr, onError: { try throwPythonError() } )
            let ptr2 = try getItemAt(index: 2, fromTuple: objPtr, onError: { try throwPythonError() } )
            return (
                borrowedPythonObject(fromReturnedPointer: ptr0),
                borrowedPythonObject(fromReturnedPointer: ptr1),
                borrowedPythonObject(fromReturnedPointer: ptr2)
            )
        }
    }
    
    internal func toTuple4(_ obj: PythonObject) async throws -> (PythonObject, PythonObject, PythonObject, PythonObject) {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isTuple = try isTuple(objPtr, onError: { try throwPythonError() } )
            guard isTuple else {
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let size = try getSizeOf(tuple: objPtr, onError: { try throwPythonError() } )
            guard size == 4 else {
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let ptr0 = try getItemAt(index: 0, fromTuple: objPtr, onError: { try throwPythonError() } )
            let ptr1 = try getItemAt(index: 1, fromTuple: objPtr, onError: { try throwPythonError() } )
            let ptr2 = try getItemAt(index: 2, fromTuple: objPtr, onError: { try throwPythonError() } )
            let ptr3 = try getItemAt(index: 3, fromTuple: objPtr, onError: { try throwPythonError() } )
            return (
                borrowedPythonObject(fromReturnedPointer: ptr0),
                borrowedPythonObject(fromReturnedPointer: ptr1),
                borrowedPythonObject(fromReturnedPointer: ptr2),
                borrowedPythonObject(fromReturnedPointer: ptr3)
            )
        }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncTuple2(_ obj: PythonInterpreter.SafePythonObject) throws ->  (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    )? {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isTuple = try isTuple(objPtr, onError: { try throwSafePythonError() } )
        guard isTuple else { return nil }
        
        let size = try getSizeOf(tuple: objPtr, onError: { try throwSafePythonError() } )
        guard size == 2 else { return nil }
        
        let ptr0 = try getItemAt(index: 0, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        let ptr1 = try getItemAt(index: 1, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        return (
            borrowedSafePythonObject(fromReturnedPointer: ptr0),
            borrowedSafePythonObject(fromReturnedPointer: ptr1)
        )
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncTuple3(_ obj: PythonInterpreter.SafePythonObject) throws ->  (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    )? {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isTuple = try isTuple(objPtr, onError: { try throwSafePythonError() } )
        guard isTuple else { return nil }
        
        let size = try getSizeOf(tuple: objPtr, onError: { try throwSafePythonError() } )
        guard size == 3 else { return nil }
        
        let ptr0 = try getItemAt(index: 0, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        let ptr1 = try getItemAt(index: 1, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        let ptr2 = try getItemAt(index: 2, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        return (
            borrowedSafePythonObject(fromReturnedPointer: ptr0),
            borrowedSafePythonObject(fromReturnedPointer: ptr1),
            borrowedSafePythonObject(fromReturnedPointer: ptr2)
        )
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncTuple4(_ obj: PythonInterpreter.SafePythonObject) throws ->  (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    )? {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isTuple = try isTuple(objPtr, onError: { try throwSafePythonError() } )
        guard isTuple else { return nil }
        
        let size = try getSizeOf(tuple: objPtr, onError: { try throwSafePythonError() } )
        guard size == 4 else { return nil }
        
        let ptr0 = try getItemAt(index: 0, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        let ptr1 = try getItemAt(index: 1, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        let ptr2 = try getItemAt(index: 2, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        let ptr3 = try getItemAt(index: 3, fromTuple: objPtr, onError: { try throwSafePythonError() } )
        return (
            borrowedSafePythonObject(fromReturnedPointer: ptr0),
            borrowedSafePythonObject(fromReturnedPointer: ptr1),
            borrowedSafePythonObject(fromReturnedPointer: ptr2),
            borrowedSafePythonObject(fromReturnedPointer: ptr3)
        )
    }
}
