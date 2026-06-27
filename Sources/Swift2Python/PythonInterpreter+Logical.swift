//
//  PythonInterpreter+Logical.swift
//  Swift2Python
//
//  Created by Ben White on 4/26/26.
//


extension PythonInterpreter {
    
    // MARK: Python API Helpers
    
    
    // This requires the GIL
    private func isTrue(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Bool  {
        let result = api.pythonObject_IsTrue(objPtr)
        if result == -1 {
            if let _ = api.pythonErr_Occurred() {
                try throwError()
            }
        }
        return result == 1
    }
    
    // This requires the GIL
    private func isNotTrue(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Bool  {
        let result = api.pythonObject_Not(objPtr)
        if result == -1 {
            if let _ = api.pythonErr_Occurred() {
                try throwError()
            }
        }
        return result == 1
    }
    
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncIsTrue(_ safeObj: SafePythonObject) throws -> Bool {
        let safePtr = getRegisteredPointer(forSafeObj:safeObj)
        return try isTrue(safePtr, onError: { try throwSafePythonError() } )
    }
    
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncIsNotTrue(_ safeObj: SafePythonObject) throws -> Bool {
        let safePtr = getRegisteredPointer(forSafeObj:safeObj)
        return try isNotTrue(safePtr, onError: { try throwSafePythonError() } )
    }
    
    internal func isTrue(_ obj: PythonObject) async throws -> Bool {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL {
            return try isTrue(objPtr, onError: { try throwPythonError() } )
        }
    }
    
    internal func isNotTrue(_ obj: PythonObject) async throws -> Bool {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL {
            return try isNotTrue(objPtr, onError: { try throwPythonError() } )
        }
    }
}
