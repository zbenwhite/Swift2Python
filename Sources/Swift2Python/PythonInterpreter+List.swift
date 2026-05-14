//
//  PythonInterpreter+List.swift
//  Swift2Python
//
//  Created by Ben White on 5/13/26.
//

import Foundation



extension PythonInterpreter {
    
    
    public func convertToPython(array: [PendingPythonConvertible]) async throws -> PythonObject {
        let listPtr = try await withGIL {
            try newPythonList(ofSize: array.count, orElse: { try throwPythonError() })
        }
        for (index, element) in array.enumerated() {
            let valuePythonObject = try await element.toPythonObject(interpreter: self)
            let valuePtr = getRegisteredPointer(forPythonObject:valuePythonObject)
            _ = try await withGIL { try api.pythonList_SetItem(listPtr, index, valuePtr!) }
        }
        return newPythonObject(fromReturnedPointer: listPtr)
    }
    
    
    // MARK: Python API Helpers
    
    // This requires the GIL
    private func newPythonList(ofSize: Int, orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try api.pythonList_New(ofSize) ?? {
            try throwError()
        } ()
    }
    
    // This requires the GIL
    private func getSizeOf(list: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Int {
        let result = api.pythonList_Size(list)
        if result == -1 {
            try throwError()
        }
        return result
    }
    
    
}
