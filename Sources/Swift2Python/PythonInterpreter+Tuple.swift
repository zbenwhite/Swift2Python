//
//  PythonInterpreter+Tuple.swift
//  Swift2Python
//
//  Created by Ben White on 5/9/26.
//

import Foundation


extension PythonInterpreter {
    public func convertToPython<A, B, C>(tuple: (A, B, C)) async throws -> PythonObject
        where A: PendingPythonConvertible,
              B: PendingPythonConvertible,
              C: PendingPythonConvertible
    {
        let elements: [any PendingPythonConvertible] = [tuple.0, tuple.1, tuple.2]
        let tuplePtr = try await createTupleAsync(elements)
        return newPythonObject(fromReturnedPointer: tuplePtr)
    }

    public func convertToSafePython<A, B, C>(tuple: (A, B, C)) throws -> PythonInterpreter.SafePythonObject
        where A: SafePythonConvertible,
              B: SafePythonConvertible,
              C: SafePythonConvertible
    {
        let elements: [any SafePythonConvertible] = [tuple.0, tuple.1, tuple.2]
        let tuplePtr = try syncCreateTuplePtr(from: elements)
        return newSafePythonObject(fromReturnedPointer: tuplePtr)
    }
    
    
    

    
    internal func convertToTuple3(_ obj: PythonObject) async throws -> (PythonObject, PythonObject, PythonObject) {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isTuple = try isTuple(objPtr, onError: { try throwPythonError() } )
            guard isTuple else {
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let size = try getSizeOf(tuple: objPtr, onError: { try throwSafePythonError() } )
            guard size == 3 else {
                throw PythonError.typeError(operation: "tuple conversion", opType1: "", opType2: "")
            }
            
            let ptr0 = try getItemAt(index: 0, fromTuple: objPtr, onError: { try throwSafePythonError() } )
            let ptr1 = try getItemAt(index: 1, fromTuple: objPtr, onError: { try throwSafePythonError() } )
            let ptr2 = try getItemAt(index: 2, fromTuple: objPtr, onError: { try throwSafePythonError() } )
            return (
                borrowedPythonObject(fromReturnedPointer: ptr0),
                borrowedPythonObject(fromReturnedPointer: ptr1),
                borrowedPythonObject(fromReturnedPointer: ptr2)
            )
        }
    }
    
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
    
    private func getSizeOf(tuple: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Int {
        let result = api.pythonTuple_Size(tuple)
        if result == -1 {
            try throwError()
        }
        return result
    }
    
    private func getItemAt(index: Int, fromTuple: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer {
        try api.pythonTuple_GetItem(fromTuple, index) ?? {
            try throwError()
        } ()
    }
    
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
}
