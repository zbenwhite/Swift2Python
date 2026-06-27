//
//  PythonInterpreter+Set.swift
//  Swift2Python
//
//  Created by Ben White on 6/8/26.
//


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
            let valuePtr = try requirePythonPointer(forObject: valuePythonObject)
            try await withGIL {
                try addItem(valuePtr, toSet: setPtr, orElse: { try throwPythonError() })
            }
        }
        
        return newPythonObject(fromReturnedPointer: setPtr)
    }
    
    /// Create a PythonObject frozenset from a Swift set.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic.
    ///
    /// ```swift
    /// let frozenSet = try await interpreter.convertToPython(frozenSet: Set([1, 2, 3]))
    /// ```
    ///
    /// - Parameters:
    ///   - frozenSet: A Swift set whose elements conform to `PendingPythonConvertible`.
    /// - Returns: A `PythonObject` representing a Python frozenset.
    /// - Throws: `PythonError` if frozenset creation, element conversion, or element insertion fails.
    public func convertToPython<T>(frozenSet: Set<T>) async throws -> PythonObject
        where T: PendingPythonConvertible
    {
        let frozenSetPtr = try await withGIL {
            try newPythonFrozenSet(orElse: { try throwPythonError() })
        }
        
        for element in frozenSet {
            let valuePythonObject = try await element.toPythonObject(interpreter: self)
            let valuePtr = try requirePythonPointer(forObject: valuePythonObject)
            try await withGIL {
                try addItem(valuePtr, toSet: frozenSetPtr, orElse: { try throwPythonError() })
            }
        }
        
        return newPythonObject(fromReturnedPointer: frozenSetPtr)
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
    
    /// Create a SafePythonObject frozenset from a Swift set.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let frozenSet = try context.convertToSafePython(frozenSet: Set([1, 2, 3]))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - frozenSet: A Swift set whose elements conform to `SafePythonConvertible`.
    /// - Returns: A `SafePythonObject` representing a Python frozenset.
    /// - Throws: `PythonError` if frozenset creation, element conversion, or element insertion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython<T>(frozenSet: Set<T>) throws -> SafePythonObject
        where T: SafePythonConvertible
    {
        let frozenSetPtr = try newPythonFrozenSet(orElse: { try throwSafePythonError() })
        
        for element in frozenSet {
            let valueSafeObject = try element.toSafePythonObject(interpreter: self)
            let valuePtr = getRegisteredPointer(forSafeObj: valueSafeObject)
            try addItem(valuePtr, toSet: frozenSetPtr, orElse: { try throwSafePythonError() })
        }
        
        return newSafePythonObject(fromReturnedPointer: frozenSetPtr)
    }
    
    // MARK: Async Set Support
    
    internal func isSet(_ obj: PythonObject) async throws -> Bool {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL { try isSet(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func isFrozenSet(_ obj: PythonObject) async throws -> Bool {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL { try isFrozenSet(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func isAnySet(_ obj: PythonObject) async throws -> Bool {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL { try isAnySet(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func getSetCount(_ obj: PythonObject) async throws -> Int {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL {
            guard try isAnySet(objPtr, onError: { try throwPythonError() }) else {
                throw PythonError.setConversionFailed(expected: "set or frozenset", actual: nil)
            }
            return try getSizeOf(set: objPtr, onError: { try throwPythonError() })
        }
    }
    
    internal func toSetArray(_ obj: PythonObject) async throws -> [PythonObject] {
        guard try await isAnySet(obj) else {
            throw PythonError.setConversionFailed(expected: "set or frozenset", actual: nil)
        }
        let builtins = try await getBuiltins()
        let list = try await builtins.list(obj)
        return try await list.asArray()
    }
    
    internal func setContains(_ item: any PendingPythonConvertible, in obj: PythonObject) async throws -> Bool {
        let objPtr = try requirePythonPointer(forObject: obj)
        let itemObj = try await item.toPythonObject(interpreter: self)
        let itemPtr = try requirePythonPointer(forObject: itemObj)
        return try await withGIL {
            guard try isAnySet(objPtr, onError: { try throwPythonError() }) else {
                throw PythonError.setConversionFailed(expected: "set or frozenset", actual: nil)
            }
            return try containsItem(itemPtr, inSet: objPtr, onError: { try throwPythonError() })
        }
    }
    
    internal func addSetItem(_ item: any PendingPythonConvertible, to obj: PythonObject) async throws {
        let objPtr = try requirePythonPointer(forObject: obj)
        let itemObj = try await item.toPythonObject(interpreter: self)
        let itemPtr = try requirePythonPointer(forObject: itemObj)
        try await withGIL {
            guard try isSet(objPtr, onError: { try throwPythonError() }) else {
                throw PythonError.setConversionFailed(expected: "set", actual: nil)
            }
            try addItem(itemPtr, toSet: objPtr, orElse: { try throwPythonError() })
        }
    }
    
    internal func discardSetItem(_ item: any PendingPythonConvertible, from obj: PythonObject) async throws {
        let objPtr = try requirePythonPointer(forObject: obj)
        let itemObj = try await item.toPythonObject(interpreter: self)
        let itemPtr = try requirePythonPointer(forObject: itemObj)
        try await withGIL {
            guard try isSet(objPtr, onError: { try throwPythonError() }) else {
                throw PythonError.setConversionFailed(expected: "set", actual: nil)
            }
            try discardItem(itemPtr, fromSet: objPtr, orElse: { try throwPythonError() })
        }
    }
    
    internal func removeSetItem(_ item: any PendingPythonConvertible, from obj: PythonObject) async throws {
        guard try await isSet(obj) else {
            throw PythonError.setConversionFailed(expected: "set", actual: nil)
        }
        _ = try await callPythonMethod(obj, "remove", item)
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
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncSetArray(_ obj: SafePythonObject) throws -> [SafePythonObject] {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        guard try isAnySet(objPtr, onError: { try throwSafePythonError() }) else {
            throw PythonError.setConversionFailed(expected: "set or frozenset", actual: nil)
        }
        let list = try syncCall(callable: builtins.list, args: [obj])
        return try list.listArray
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncSetContains(_ item: any SafePythonConvertible, in obj: SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let itemObj = try item.toSafePythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forSafeObj: itemObj)
        guard try isAnySet(objPtr, onError: { try throwSafePythonError() }) else {
            throw PythonError.setConversionFailed(expected: "set or frozenset", actual: nil)
        }
        return try containsItem(itemPtr, inSet: objPtr, onError: { try throwSafePythonError() })
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncAddSetItem(_ item: any SafePythonConvertible, to obj: SafePythonObject) throws {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let itemObj = try item.toSafePythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forSafeObj: itemObj)
        guard try isSet(objPtr, onError: { try throwSafePythonError() }) else {
            throw PythonError.setConversionFailed(expected: "set", actual: nil)
        }
        try addItem(itemPtr, toSet: objPtr, orElse: { try throwSafePythonError() })
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncDiscardSetItem(_ item: any SafePythonConvertible, from obj: SafePythonObject) throws {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let itemObj = try item.toSafePythonObject(interpreter: self)
        let itemPtr = getRegisteredPointer(forSafeObj: itemObj)
        guard try isSet(objPtr, onError: { try throwSafePythonError() }) else {
            throw PythonError.setConversionFailed(expected: "set", actual: nil)
        }
        try discardItem(itemPtr, fromSet: objPtr, orElse: { try throwSafePythonError() })
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncRemoveSetItem(_ item: any SafePythonConvertible, from obj: SafePythonObject) throws {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        guard try isSet(objPtr, onError: { try throwSafePythonError() }) else {
            throw PythonError.setConversionFailed(expected: "set", actual: nil)
        }
        let remove = try syncGetObjectAttribute(obj, "remove")
        _ = try syncCall(callable: remove, args: [item])
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
    private func newPythonFrozenSet(orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try api.pythonFrozenSet_New(nil) ?? {
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
    
    // This requires the GIL.
    private func containsItem(_ item: UnsafeMutableRawPointer, inSet set: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws -> Bool {
        switch api.pythonSet_Contains(set, item) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    // This requires the GIL.
    private func discardItem(_ item: UnsafeMutableRawPointer, fromSet set: UnsafeMutableRawPointer, orElse throwError: () throws -> Never) throws {
        let result = api.pythonSet_Discard(set, item)
        if result == -1 {
            try throwError()
        }
    }
}
