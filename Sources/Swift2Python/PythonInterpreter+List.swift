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
    
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(array: [any SafePythonConvertible]) throws -> PythonInterpreter.SafePythonObject {
        let listPtr = try newPythonList(ofSize: array.count, orElse: { try throwSafePythonError() })
        for (index, element) in array.enumerated() {
            let valueSafeObject = try element.toSafePythonObject(interpreter: self)
            let valuePtr = getRegisteredPointer(forSafeObj:valueSafeObject)
            _ = try setItem(valuePtr, onList: listPtr, atIndex: index, orElse: { try throwPythonError() })
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
            // to free the object before PyTuple_SetItem returns -1.)
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
    internal func toArray<K>(fromPythonListPointer objPtr: UnsafeMutableRawPointer,
                             onError throwError: () throws -> Never,
                             handleEachItem: (UnsafeMutableRawPointer) throws -> K) throws -> [K] {
        let isList = try isList(objPtr, onError: { try throwError() } )
        guard isList else {
            throw PythonError.listConversionFailed(expected: "list", actual: nil)
        }
        let size = try getSizeOf(list: objPtr, onError: { try throwError() } )
        return try (0..<size).map { index in
            let ptr = try getItemAt(index: index, fromList: objPtr, onError: { try throwPythonError() } )
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
    
    internal func toSafeArray(_ obj: SafePythonObject) throws -> [SafePythonObject] {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try toArray(fromPythonListPointer: objPtr,
                        onError: { try throwSafePythonError() },
                        borrowedObject: { ptr in borrowedSafePythonObject(fromReturnedPointer: ptr)} )
    }
}
