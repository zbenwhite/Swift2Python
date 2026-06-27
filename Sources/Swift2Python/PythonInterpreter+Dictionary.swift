//
//  PythonInterpreter+Dictionary.swift
//  Swift2Python
//
//  Created by Ben White on 5/3/26.
//

import Foundation


extension PythonInterpreter {
    
    
    // MARK: Swift Dict to Python
    
    /// Create a PythonObject dictionary from a Swift dictionary.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic.
    ///
    /// ```swift
    /// let dict = try await interpreter.convertToPython(dictionary: [
    ///     "name": "Ada",
    ///     "count": 3
    /// ])
    /// ```
    ///
    /// - Parameters:
    ///   - dictionary: A Swift dictionary whose keys and values conform to `PendingPythonConvertible`.
    /// - Returns: A `PythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    public func convertToPython<K, V>(dictionary: [K: V]) async throws -> PythonObject
            where K: PendingPythonConvertible & Hashable, V: PendingPythonConvertible {
        let dictPtr = try await withGIL { try newPythonDict(orElse: { try throwPythonError() }) }
        for (key, value) in dictionary {
            let keyObj = try await key.toPythonObject(interpreter: self)
            let valueObj = try await value.toPythonObject(interpreter: self)
            let keyPtr = try requirePythonPointer(forObject: keyObj)
            let valuePtr = try requirePythonPointer(forObject: valueObj)
            _ = try await withGIL { try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwPythonError() }) }
        }
        return newPythonObject(fromReturnedPointer: dictPtr)
    }
    
    /// Create a PythonObject dictionary from a heterogeneous Swift dictionary with string keys.
    ///
    /// Use this overload when dictionary values have different Swift types but all values
    /// conform to `PendingPythonConvertible`.
    ///
    /// ```swift
    /// let values: [String: any PendingPythonConvertible] = [
    ///     "name": "Ada",
    ///     "count": 3,
    ///     "active": true
    /// ]
    /// let dict = try await interpreter.convertToPython(dictionary: values)
    /// ```
    ///
    /// - Parameters:
    ///   - dictionary: A string-keyed Swift dictionary whose values conform to `PendingPythonConvertible`.
    /// - Returns: A `PythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    public func convertToPython(dictionary: [String: any PendingPythonConvertible]) async throws -> PythonObject {
        let dictPtr = try await withGIL { try newPythonDict(orElse: { try throwPythonError() }) }
        for (key, value) in dictionary {
            let keyObj = try await key.toPythonObject(interpreter: self)
            let valueObj = try await value.toPythonObject(interpreter: self)
            let keyPtr = try requirePythonPointer(forObject: keyObj)
            let valuePtr = try requirePythonPointer(forObject: valueObj)
            _ = try await withGIL { try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwPythonError() }) }
        }
        return newPythonObject(fromReturnedPointer: dictPtr)
    }
    
    /// Create a PythonObject dictionary from Swift key-value pairs.
    ///
    /// Use this overload when insertion order matters or when duplicate Swift keys
    /// are intentional. Python dictionary semantics apply: setting the same key
    /// again replaces the value for that key.
    ///
    /// ```swift
    /// let values: KeyValuePairs<String, Int> = [
    ///     "one": 1,
    ///     "one": 2
    /// ]
    /// let dict = try await interpreter.convertToPython(keyValuePairs: values)
    /// ```
    ///
    /// - Parameters:
    ///   - keyValuePairs: Swift key-value pairs whose keys and values conform to `PendingPythonConvertible`.
    /// - Returns: A `PythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    public func convertToPython<K, V>(keyValuePairs: KeyValuePairs<K, V>) async throws -> PythonObject
            where K: PendingPythonConvertible, V: PendingPythonConvertible {
        let dictPtr = try await withGIL { try newPythonDict(orElse: { try throwPythonError() }) }
        for (key, value) in keyValuePairs {
            let keyObj = try await key.toPythonObject(interpreter: self)
            let valueObj = try await value.toPythonObject(interpreter: self)
            let keyPtr = try requirePythonPointer(forObject: keyObj)
            let valuePtr = try requirePythonPointer(forObject: valueObj)
            _ = try await withGIL { try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwPythonError() }) }
        }
        return newPythonObject(fromReturnedPointer: dictPtr)
    }
    
    /// Create a PythonObject dictionary from heterogeneous string-keyed Swift key-value pairs.
    ///
    /// Use this overload when values have different Swift types and insertion order
    /// or duplicate-key overwrite semantics matter.
    ///
    /// ```swift
    /// let values: KeyValuePairs<String, any PendingPythonConvertible> = [
    ///     "name": "Ada",
    ///     "count": 3
    /// ]
    /// let dict = try await interpreter.convertToPython(keyValuePairs: values)
    /// ```
    ///
    /// - Parameters:
    ///   - keyValuePairs: String-keyed Swift key-value pairs whose values conform to `PendingPythonConvertible`.
    /// - Returns: A `PythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    public func convertToPython(keyValuePairs: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {
        let dictPtr = try await withGIL { try newPythonDict(orElse: { try throwPythonError() }) }
        for (key, value) in keyValuePairs {
            let keyObj = try await key.toPythonObject(interpreter: self)
            let valueObj = try await value.toPythonObject(interpreter: self)
            let keyPtr = try requirePythonPointer(forObject: keyObj)
            let valuePtr = try requirePythonPointer(forObject: valueObj)
            _ = try await withGIL { try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwPythonError() }) }
        }
        return newPythonObject(fromReturnedPointer: dictPtr)
    }
    
    internal func convertKeywordArgumentsToPython(_ keywordArguments: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {
        var seenKeys = Set<String>()
        let dictPtr = try await withGIL { try newPythonDict(orElse: { try throwPythonError() }) }
        for (key, value) in keywordArguments {
            guard !key.isEmpty else {
                throw PythonError.valueError("Keyword argument labels cannot be empty")
            }
            guard seenKeys.insert(key).inserted else {
                throw PythonError.valueError("Duplicate keyword argument '\(key)'")
            }
            let keyObj = try await key.toPythonObject(interpreter: self)
            let valueObj = try await value.toPythonObject(interpreter: self)
            let keyPtr = try requirePythonPointer(forObject: keyObj)
            let valuePtr = try requirePythonPointer(forObject: valueObj)
            _ = try await withGIL { try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwPythonError() }) }
        }
        return newPythonObject(fromReturnedPointer: dictPtr)
    }
    
    
    /// Create a SafePythonObject dictionary from a Swift dictionary.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let dict = try context.convertToSafePython(dictionary: [
    ///         "name": "Ada",
    ///         "count": 3
    ///     ])
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - dictionary: A Swift dictionary whose keys and values conform to `SafePythonConvertible`.
    /// - Returns: A `SafePythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
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
    
    /// Create a SafePythonObject dictionary from a heterogeneous Swift dictionary with string keys.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment. Use this overload when dictionary values
    /// have different Swift types but all values conform to `SafePythonConvertible`.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let values: [String: any SafePythonConvertible] = [
    ///         "name": "Ada",
    ///         "count": 3,
    ///         "active": true
    ///     ]
    ///     let dict = try context.convertToSafePython(dictionary: values)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - dictionary: A string-keyed Swift dictionary whose values conform to `SafePythonConvertible`.
    /// - Returns: A `SafePythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(dictionary: [String: any SafePythonConvertible]) throws -> SafePythonObject {
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
    
    /// Create a SafePythonObject dictionary from Swift key-value pairs.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment. Python dictionary semantics apply:
    /// setting the same key again replaces the value for that key.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let values: KeyValuePairs<String, Int> = [
    ///         "one": 1,
    ///         "one": 2
    ///     ]
    ///     let dict = try context.convertToSafePython(keyValuePairs: values)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyValuePairs: Swift key-value pairs whose keys and values conform to `SafePythonConvertible`.
    /// - Returns: A `SafePythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython<K, V>(keyValuePairs: KeyValuePairs<K, V>) throws -> SafePythonObject
    where K: SafePythonConvertible, V: SafePythonConvertible {
        let dictPtr = try newPythonDict(orElse: { try throwSafePythonError() })
        for (key, value) in keyValuePairs {
            let keyObj = try key.toSafePythonObject(interpreter: self)
            let valueObj = try value.toSafePythonObject(interpreter: self)
            let keyPtr = getRegisteredPointer(forSafeObj:keyObj)
            let valuePtr = getRegisteredPointer(forSafeObj:valueObj)
            try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwSafePythonError() })
        }
        return newSafePythonObject(fromReturnedPointer: dictPtr)
    }
    
    /// Create a SafePythonObject dictionary from heterogeneous string-keyed Swift key-value pairs.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment. Use this overload when values have
    /// different Swift types and insertion order or duplicate-key overwrite
    /// semantics matter.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let values: KeyValuePairs<String, any SafePythonConvertible> = [
    ///         "name": "Ada",
    ///         "count": 3
    ///     ]
    ///     let dict = try context.convertToSafePython(keyValuePairs: values)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - keyValuePairs: String-keyed Swift key-value pairs whose values conform to `SafePythonConvertible`.
    /// - Returns: A `SafePythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(keyValuePairs: KeyValuePairs<String, any SafePythonConvertible>) throws -> SafePythonObject {
        let dictPtr = try newPythonDict(orElse: { try throwSafePythonError() })
        for (key, value) in keyValuePairs {
            let keyObj = try key.toSafePythonObject(interpreter: self)
            let valueObj = try value.toSafePythonObject(interpreter: self)
            let keyPtr = getRegisteredPointer(forSafeObj:keyObj)
            let valuePtr = getRegisteredPointer(forSafeObj:valueObj)
            try setValue(valuePtr, onDict: dictPtr, atKey: keyPtr, orElse: { try throwSafePythonError() })
        }
        return newSafePythonObject(fromReturnedPointer: dictPtr)
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func convertKeywordArgumentsToSafePython(_ keywordArguments: KeyValuePairs<String, any SafePythonConvertible>) throws -> SafePythonObject {
        var seenKeys = Set<String>()
        let dictPtr = try newPythonDict(orElse: { try throwSafePythonError() })
        for (key, value) in keywordArguments {
            guard !key.isEmpty else {
                throw PythonError.valueError("Keyword argument labels cannot be empty")
            }
            guard seenKeys.insert(key).inserted else {
                throw PythonError.valueError("Duplicate keyword argument '\(key)'")
            }
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
    private func deleteItem(atKey key: UnsafeMutableRawPointer, fromDict dict: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws {
        let result = api.pythonObject_DelItem(dict, key)
        if result == -1 {
            try throwError()
        }
    }
    
    // This requires the GIL
    // PyMapping_HasKey always succeeds.  Errors are trapped by Python itself so no throws
    private func hasKey(_ key: UnsafeMutableRawPointer, inDict dict: UnsafeMutableRawPointer) -> Bool {
        api.pythonMapping_HasKey(dict, key)
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
    
    // This requires the GIL
    private func getSizeOf(list: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Int {
        let result = api.pythonList_Size(list)
        if result == -1 {
            try throwError()
        }
        return result
    }
    
    // This requires the GIL
    private func getItemAt(index: Int, fromList list: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer {
        guard let resultPtr = api.pythonList_GetItem(list, index) else {
            try throwError()
        }
        return resultPtr
    }
    
    // This requires the GIL
    private func getItemAt(index: Int, fromTuple tuple: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer {
        guard let resultPtr = api.pythonTuple_GetItem(tuple, index) else {
            try throwError()
        }
        return resultPtr
    }
    
    // This requires the GIL
    private func getKeysList(from object: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer {
        try api.pythonMapping_Keys(object) ?? {
            try throwError()
        } ()
    }
    
    // This requires the GIL
    private func getValuesList(from object: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer {
        try api.pythonMapping_Values(object) ?? {
            try throwError()
        } ()
    }
    
    // This requires the GIL
    private func getItemsList(from object: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer {
        try api.pythonMapping_Items(object) ?? {
            try throwError()
        } ()
    }
    
    // MARK: Is Python Dict ?
    
    internal func isDict(_ obj: PythonObject) async throws -> Bool {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL { try isDict(objPtr, onError: { try throwPythonError() } ) }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncIsDict(_ obj: PythonInterpreter.SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isDict(objPtr, onError: { try throwSafePythonError() } )
    }
    
    // MARK: Python Dict Count
    
    internal func getDictCount(_ obj: PythonObject) async throws -> Int {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL {
            let isDict = try isDict(objPtr, onError: { try throwPythonError() } )
            guard isDict else {
                throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
            }
            return try getSizeOf(dictionary: objPtr, onError: { try throwPythonError() } )
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncDictCount(_ obj: PythonInterpreter.SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isDict = try isDict(objPtr, onError: { try throwSafePythonError() } )
        guard isDict else {
            throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
        }
        return try getSizeOf(dictionary: objPtr, onError: { try throwSafePythonError() } )
    }
    
    internal func containsKey(_ key: PythonObject, inDict obj: PythonObject) async throws -> Bool {
        let objPtr = try requirePythonPointer(forObject: obj)
        let keyPtr = try requirePythonPointer(forObject: key)
        return try await withGIL {
            let isDict = try isDict(objPtr, onError: { try throwPythonError() } )
            guard isDict else {
                throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
            }
            return hasKey(keyPtr, inDict: objPtr)
        }
    }
    
    internal func deleteItem(fromDict obj: PythonObject, key: PythonObject) async throws {
        let objPtr = try requirePythonPointer(forObject: obj)
        let keyPtr = try requirePythonPointer(forObject: key)
        try await withGIL {
            let isDict = try isDict(objPtr, onError: { try throwPythonError() } )
            guard isDict else {
                throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
            }
            try deleteItem(atKey: keyPtr, fromDict: objPtr, onError: { try throwPythonError() })
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncContainsKey(_ key: PythonInterpreter.SafePythonObject, inDict obj: PythonInterpreter.SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let keyPtr = getRegisteredPointer(forSafeObj: key)
        let isDict = try isDict(objPtr, onError: { try throwSafePythonError() } )
        guard isDict else {
            throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
        }
        return hasKey(keyPtr, inDict: objPtr)
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncDeleteItem(fromDict obj: PythonInterpreter.SafePythonObject, key: PythonInterpreter.SafePythonObject) throws {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let keyPtr = getRegisteredPointer(forSafeObj: key)
        let isDict = try isDict(objPtr, onError: { try throwSafePythonError() } )
        guard isDict else {
            throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
        }
        try deleteItem(atKey: keyPtr, fromDict: objPtr, onError: { try throwSafePythonError() })
    }
    
    // MARK: Convert Dict Views To Swift Arrays
    
    internal func dictKeys(_ obj: PythonObject) async throws -> [PythonObject] {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL {
            let isDict = try isDict(objPtr, onError: { try throwPythonError() } )
            guard isDict else {
                throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
            }
            
            let listPtr = try getKeysList(from: objPtr, onError: { try throwPythonError() } )
            defer { api.Py_DecRef(listPtr) }  // List is only used here and not kept
            return try toArray(fromPythonListPointer: listPtr,
                               onError: { try throwPythonError() },
                               borrowedObject: { ptr in borrowedPythonObject(fromReturnedPointer: ptr)} )
        }
    }
    
    internal func dictValues(_ obj: PythonObject) async throws -> [PythonObject] {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL {
            let isDict = try isDict(objPtr, onError: { try throwPythonError() } )
            guard isDict else {
                throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
            }
            
            let listPtr = try getValuesList(from: objPtr, onError: { try throwPythonError() } )
            defer { api.Py_DecRef(listPtr) }  // List is only used here and not kept
            return try toArray(fromPythonListPointer: listPtr,
                               onError: { try throwPythonError() },
                               borrowedObject: { ptr in borrowedPythonObject(fromReturnedPointer: ptr)} )
        }
    }
    
    internal func dictItems(_ obj: PythonObject) async throws -> [(key: PythonObject, value: PythonObject)] {
        let objPtr = try requirePythonPointer(forObject: obj)
        return try await withGIL {
            let isDict = try isDict(objPtr, onError: { try throwPythonError() } )
            guard isDict else {
                throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
            }
            
            let listPtr = try getItemsList(from: objPtr, onError: { try throwPythonError() } )
            defer { api.Py_DecRef(listPtr) }  // List is only used here and not kept
            
            
            return try toArray(fromPythonListPointer: listPtr, onError: { try throwPythonError() },
                        handleEachItem: { tuplePtr in
                    // no need to reference count the tuple pointer.  It's owned by python and not stored in swift.
                    let keyPtr = try getItemAt(index: 0, fromTuple: tuplePtr, onError: { try throwPythonError() } )
                    let valuePtr = try getItemAt(index: 1, fromTuple: tuplePtr, onError: { try throwPythonError() } )
                    return ( key: borrowedPythonObject(fromReturnedPointer: keyPtr),
                        value: borrowedPythonObject(fromReturnedPointer: valuePtr)  )
                } )
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncDictKeys(_ obj: PythonInterpreter.SafePythonObject) throws -> [PythonInterpreter.SafePythonObject] {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isDict = try isDict(objPtr, onError: { try throwSafePythonError() } )
        guard isDict else {
            throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
        }
        
        let listPtr = try getKeysList(from: objPtr, onError: { try throwSafePythonError() } )
        defer { api.Py_DecRef(listPtr) }   // List is only used here and not kept
        return try toArray(fromPythonListPointer: listPtr,
                           onError: { try throwSafePythonError() },
                           borrowedObject: { ptr in borrowedSafePythonObject(fromReturnedPointer: ptr)} )
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncDictValues(_ obj: PythonInterpreter.SafePythonObject) throws -> [PythonInterpreter.SafePythonObject] {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isDict = try isDict(objPtr, onError: { try throwSafePythonError() } )
        guard isDict else {
            throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
        }
        
        let listPtr = try getValuesList(from: objPtr, onError: { try throwSafePythonError() } )
        defer { api.Py_DecRef(listPtr) }    // List is only used here and not kept
        return try toArray(fromPythonListPointer: listPtr,
                           onError: { try throwSafePythonError() },
                           borrowedObject: { ptr in borrowedSafePythonObject(fromReturnedPointer: ptr)} )
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func syncDictItems(_ obj: PythonInterpreter.SafePythonObject) throws -> [(key: PythonInterpreter.SafePythonObject, value: PythonInterpreter.SafePythonObject)] {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let isDict = try isDict(objPtr, onError: { try throwSafePythonError() } )
        guard isDict else {
            throw PythonError.dictionaryConversionFailed(expected: "dict", actual: nil)
        }
        
        let listPtr = try getItemsList(from: objPtr, onError: { try throwSafePythonError() } )
        defer { api.Py_DecRef(listPtr) }    // List is only used here and not kept
        
        return try toArray(fromPythonListPointer: listPtr, onError: { try throwSafePythonError() },
                    handleEachItem: { tuplePtr in
                // no need to reference count the tuple pointer.  It's owned by python and not stored in swift.
                let keyPtr = try getItemAt(index: 0, fromTuple: tuplePtr, onError: { try throwSafePythonError() } )
                let valuePtr = try getItemAt(index: 1, fromTuple: tuplePtr, onError: { try throwSafePythonError() } )
                return ( key: borrowedSafePythonObject(fromReturnedPointer: keyPtr),
                    value: borrowedSafePythonObject(fromReturnedPointer: valuePtr)  )
            } )
    }
        
}
