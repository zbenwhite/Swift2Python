//
//  PythonInterpreter+Set.swift
//  Swift2Python
//
//  Created by Ben White on 6/8/26.
//

import Foundation

extension PythonInterpreter {
    
    // MARK: Convert To Python Set
    
    /// Create a PythonObject set from a Swift set.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic.
    ///
    /// ```swift
    /// let set = try await interpreter.convertToPython(set: Set([1, 2, 3]))
    /// ```
    ///
    /// - Parameters:
    ///   - set: A Swift set whose elements conform to `PendingPythonConvertible`.
    /// - Returns: A `PythonObject` representing a Python set.
    /// - Throws: `PythonError` if set creation, element conversion, or element insertion fails.
    public func convertToPython<T>(set: Set<T>) async throws -> PythonObject
        where T: PendingPythonConvertible
    {
        let setPtr = try await withGIL {
            try newPythonSet(orElse: { try throwPythonError() })
        }
        
        for element in set {
            let valuePythonObject = try await element.toPythonObject(interpreter: self)
            let valuePtr = getRegisteredPointer(forPythonObject: valuePythonObject)!
            try await withGIL {
                try addItem(valuePtr, toSet: setPtr, orElse: { try throwPythonError() })
            }
        }
        
        return newPythonObject(fromReturnedPointer: setPtr)
    }
    
    /// Create a SafePythonObject set from a Swift set.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let set = try context.convertToSafePython(set: Set([1, 2, 3]))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - set: A Swift set whose elements conform to `SafePythonConvertible`.
    /// - Returns: A `SafePythonObject` representing a Python set.
    /// - Throws: `PythonError` if set creation, element conversion, or element insertion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython<T>(set: Set<T>) throws -> SafePythonObject
        where T: SafePythonConvertible
    {
        let setPtr = try newPythonSet(orElse: { try throwSafePythonError() })
        
        for element in set {
            let valueSafeObject = try element.toSafePythonObject(interpreter: self)
            let valuePtr = getRegisteredPointer(forSafeObj: valueSafeObject)
            try addItem(valuePtr, toSet: setPtr, orElse: { try throwSafePythonError() })
        }
        
        return newSafePythonObject(fromReturnedPointer: setPtr)
    }
    
    // MARK: Async Set Support
    
    internal func isSet(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isSet(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func isFrozenSet(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isFrozenSet(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func isAnySet(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isAnySet(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func getSetCount(_ obj: PythonObject) async throws -> Int {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            guard try isAnySet(objPtr, onError: { try throwPythonError() }) else {
                throw PythonError.setConversionFailed(expected: "set or frozenset", actual: nil)
            }
            return try getSizeOf(set: objPtr, onError: { try throwPythonError() })
        }
    }
    
    // MARK: Safe Set Support
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncIsSet(_ obj: SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isSet(objPtr, onError: { try throwSafePythonError() })
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncIsFrozenSet(_ obj: SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isFrozenSet(objPtr, onError: { try throwSafePythonError() })
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncIsAnySet(_ obj: SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isAnySet(objPtr, onError: { try throwSafePythonError() })
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncSetCount(_ obj: SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        guard try isAnySet(objPtr, onError: { try throwSafePythonError() }) else {
            throw PythonError.setConversionFailed(expected: "set or frozenset", actual: nil)
        }
        return try getSizeOf(set: objPtr, onError: { try throwSafePythonError() })
    }
    
    // MARK: Python API Helpers
    
    // This requires the GIL.
    private func isSet(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws -> Bool {
        switch api.pythonObject_IsInstance(objPtr, api.PySet_Type) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    // This requires the GIL.
    private func isFrozenSet(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws -> Bool {
        switch api.pythonObject_IsInstance(objPtr, api.PyFrozenSet_Type) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    // This requires the GIL.
    private func isAnySet(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws -> Bool {
        try isSet(objPtr, onError: throwError) || isFrozenSet(objPtr, onError: throwError)
    }
    
    // This requires the GIL.
    private func getSizeOf(set: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws -> Int {
        let result = api.pythonSet_Size(set)
        if result == -1 {
            try throwError()
        }
        return result
    }
    
    // This requires the GIL.
    private func newPythonSet(orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try api.pythonSet_New(nil) ?? {
            try throwError()
        }()
    }
    
    // This requires the GIL.
    private func addItem(_ item: UnsafeMutableRawPointer, toSet set: UnsafeMutableRawPointer, orElse throwError: () throws -> Never) throws {
        let result = api.pythonSet_Add(set, item)
        if result != 0 {
            try throwError()
        }
    }
}
