//
//  PythonInterpreter+Container.swift
//  Swift2Python
//
//  Created by Ben White on 5/3/26.
//

import Foundation


extension PythonInterpreter {
    
    public func convertToPython<K, V>(dictionary: [K: V]) async throws -> PythonObject
            where K: PendingPythonConvertible & Hashable, V: PendingPythonConvertible {
                
        let dictPtr = try newPythonDict(orElse: { try throwPythonError() })
        for (key, value) in dictionary {
            let keyObj = try await key.toPythonObject(interpreter: self)
            let valueObj = try await value.toPythonObject(interpreter: self)
            let keyPtr = getRegisteredPointer(forPythonObject:keyObj)!
            let valuePtr = getRegisteredPointer(forPythonObject:valueObj)!
            _ = try await withGIL { try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwPythonError() }) }
        }
        return newPythonObject(fromReturnedPointer: dictPtr)
    }
    
    public func convertToPython(dictionary: [String: any PendingPythonConvertible]) async throws -> PythonObject {
        let dictPtr = try newPythonDict(orElse: { try throwPythonError() })
        for (key, value) in dictionary {
            let keyObj = try await key.toPythonObject(interpreter: self)
            let valueObj = try await value.toPythonObject(interpreter: self)
            let keyPtr = getRegisteredPointer(forPythonObject:keyObj)!
            let valuePtr = getRegisteredPointer(forPythonObject:valueObj)!
            _ = try await withGIL { try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwPythonError() }) }
        }
        return newPythonObject(fromReturnedPointer: dictPtr)
    }
    
    public func convertToSafePython<K, V>(dictionary: [K: V]) throws -> SafePythonObject
    where K: SafePythonConvertible & Hashable, V: SafePythonConvertible {
        let dictPtr = try newPythonDict(orElse: { try throwSafePythonError() })
        for (key, value) in dictionary {
            let keyObj = try key.toSafePythonObject(interpreter: self)
            let valueObj = try value.toSafePythonObject(interpreter: self)
            let keyPtr = getRegisteredPointer(forSafeObj:keyObj)
            let valuePtr = getRegisteredPointer(forSafeObj:valueObj)
            try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwSafePythonError() })
        }
        return newSafePythonObject(fromReturnedPointer: dictPtr)
    }
                
                
                
    
    
    // MARK: Python API Helpers
    
    // This requires the GIL
    private func newPythonDict(orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try api.pythonDict_New() ?? {
            try throwError()
        } ()
    }

    // This requires the GIL
    private func setValue(_ value: UnsafeMutableRawPointer, onDict: UnsafeMutableRawPointer, atKey: UnsafeMutableRawPointer, orElse throwError: () throws -> Never) throws {
        let result = api.pythonDict_SetItem(onDict, atKey, value)
        if result != 0 {
            try throwError()
        }
    }
    
    // This requires the GIL
    private func isDict(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Bool  {
        switch api.pythonObject_IsInstance(objPtr, api.PyDict_Type) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    // This requires the GIL
    private func getSizeOf(dictionary: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Int {
        let result = api.pythonDict_Size(dictionary)
        if result == -1 {
            try throwError()
        }
        return result
    }
    
    
    
    
    // MARK: Is Python Dict ?
    
    internal func isDict(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isDict(objPtr, onError: { try throwPythonError() } ) }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncIsDict(_ obj: PythonInterpreter.SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isDict(objPtr, onError: { try throwSafePythonError() } )
    }
    
    // MARK: Python Dict Count
    
    internal func getDictCount(_ obj: PythonObject) async throws -> Int {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            let isDict = try isDict(objPtr, onError: { try throwPythonError() } )
            guard isDict else {
                throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
            }
            return try getSizeOf(dictionary: objPtr, onError: { try throwPythonError() } )
        }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncDictCount(_ obj: PythonInterpreter.SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isDict = try isDict(objPtr, onError: { try throwSafePythonError() } )
        guard isDict else {
            throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
        }
        return try getSizeOf(dictionary: objPtr, onError: { try throwSafePythonError() } )
    }
        
}
