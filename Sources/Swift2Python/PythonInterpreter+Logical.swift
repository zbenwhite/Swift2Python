//
//  PythonInterpreter+Logical.swift
//  Swift2Python
//
//  Created by Ben White on 4/26/26.
//

import Foundation


extension PythonInterpreter {
    
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncIsTrue(_ safeObj: SafePythonObject) throws -> Bool {
        let safePtr = getRegisteredPointer(forSafeObj:safeObj)
        return try api.pythonObject_IsTrue(safePtr)
    }
    
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func syncIsNotTrue(_ safeObj: SafePythonObject) throws -> Bool {
        let safePtr = getRegisteredPointer(forSafeObj:safeObj)
        return try api.pythonObject_Not(safePtr)
    }
    
    internal func isTrue(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try withGIL {
            try api.pythonObject_IsTrue(objPtr)
        }
    }
    
    internal func isNotTrue(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try withGIL {
            try api.pythonObject_Not(objPtr)
        }
    }
}
