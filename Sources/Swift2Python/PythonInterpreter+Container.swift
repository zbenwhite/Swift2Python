//
//  PythonInterpreter+Container.swift
//  Swift2Python
//
//  Created by Ben White on 5/3/26.
//

import Foundation


extension PythonInterpreter {
    
    
    
    
    
    public func convertToPython(array: [PendingPythonConvertible]) async throws -> PythonObject {
        return try await withGIL {
            guard let listPtr = try api.pythonList_New(array.count)  else {
                throw PythonError.nullPointer("Failed to convert list: \(array)")
            }
            for (index, element) in array.enumerated() {
                let valuePythonObject = try await element.toPythonObject(interpreter: self)
                let valuePtr = getRegisteredPointer(forPythonObject:valuePythonObject)
                _ = try api.pythonList_SetItem(listPtr, index, valuePtr!)
            }
            return newPythonObject(fromReturnedPointer: listPtr)
        }
    }
    
    public func convertToPython<K, V>(dictionary: [K: V]) async throws -> PythonObject
            where K: PendingPythonConvertible & Hashable, V: PendingPythonConvertible {
        return try await withGIL {
            guard let dictPtr = try api.pythonDict_New()  else {
                throw PythonError.nullPointer("Failed to convert dictionary")
            }
            
            for (key, value) in dictionary {
                let keyObj = try await key.toPythonObject(interpreter: self)
                let valueObj = try await value.toPythonObject(interpreter: self)
                let keyPtr = getRegisteredPointer(forPythonObject:keyObj)!
                let valuePtr = getRegisteredPointer(forPythonObject:valueObj)!
                _ = try api.pythonDict_SetItem(dictPtr, keyPtr, valuePtr)
            }
            return newPythonObject(fromReturnedPointer: dictPtr)
        }
    }
    
    
}
