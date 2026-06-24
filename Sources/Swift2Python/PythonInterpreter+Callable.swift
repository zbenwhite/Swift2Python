//
//  PythonInterpreter+Callable.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

extension PythonInterpreter {
    
    // MARK: Python API Helpers
    
    // This requires the GIL
    private func getAttr(_ name: String, onObject objPtr: UnsafeMutableRawPointer, orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        guard let attrPtr = api.pythonObject_GetAttrString(objPtr, name) else {
            try throwError()
        }
        return attrPtr
    }
    
    // This requires the GIL
    private func callCallable(_ callable: UnsafeMutableRawPointer, args: UnsafeMutableRawPointer? = nil, kwargs: UnsafeMutableRawPointer? = nil,
                              onError throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        let resultPtr: UnsafeMutableRawPointer?
        let useSimpleCall: Bool
        
        // No args and no kwargs and simple call available: use simple call
        if let _ = api.PyObject_CallNoArgs {
            useSimpleCall = args == nil && kwargs == nil
        }
        else {
            useSimpleCall = false
        }
        if useSimpleCall {
            resultPtr = api.PyObject_CallNoArgs!(callable)
        } else {
            if args == nil {
                guard let emptyTuple = api.PyTuple_New(0) else { try throwError() }
                defer { api.Py_DecRef(emptyTuple) }
                resultPtr = api.PyObject_Call(callable, emptyTuple, kwargs)
            } else {
                resultPtr = api.PyObject_Call(callable, args!, kwargs)
            }
        }
        if resultPtr == nil {
            try throwError()
        }
        return resultPtr!
    }
    
    
    // MARK: Callable Support (async mode)
    
    // Private helper that does the actual call (used by both above)
    internal func callPythonCallable(_ callable: PythonObject,
                                    args: [any PendingPythonConvertible],
                                    kwargs: [String: any PendingPythonConvertible]) async throws -> PythonObject {

        // Build args tuple
        let argTuplePtr: UnsafeMutableRawPointer? = try await createTupleAsync(args)
        // Build kwargs dict (if any)
        let kwDictPtr: UnsafeMutableRawPointer? = try await createKwargsDictAsync(kwargs)
        
        guard let callablePtr = getRegisteredPointer(forPythonObject:callable) else {
            throw PythonError.nullPointer("Callable pointer not found")
        }
        return try await withGIL {
            // Use PyObject_Call (most flexible)
            let resultPtr = try callCallable(callablePtr, args: argTuplePtr!, kwargs: kwDictPtr, onError: { try throwPythonError() } )
            return newPythonObject(fromReturnedPointer: resultPtr)
        }
    }
    
    internal func callPythonCallable(_ callable: PythonObject,
                                    args: [any PendingPythonConvertible],
                                    kwargs: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {

        // Build args tuple
        let argTuplePtr: UnsafeMutableRawPointer? = try await createTupleAsync(args)
        // Build kwargs dict (if any)
        let kwDictPtr: UnsafeMutableRawPointer? = try await createKwargsDictAsync(kwargs)
        
        guard let callablePtr = getRegisteredPointer(forPythonObject:callable) else {
            throw PythonError.nullPointer("Callable pointer not found")
        }
        return try await withGIL {
            // Use PyObject_Call (most flexible)
            let resultPtr = try callCallable(callablePtr, args: argTuplePtr!, kwargs: kwDictPtr, onError: { try throwPythonError() } )
            return newPythonObject(fromReturnedPointer: resultPtr)
        }
    }
    
    internal func callPythonCallable(_ callable: PythonObject,
                                    dynamicArguments: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {
        var positionalArgs: [any PendingPythonConvertible] = []
        var keywordPairs: [(String, any PendingPythonConvertible)] = []
        var foundKeyword = false
        var seenKeys = Set<String>()
        
        for (key, value) in dynamicArguments {
            if key.isEmpty {
                guard !foundKeyword else {
                    throw PythonError.valueError("Positional argument cannot follow keyword argument")
                }
                positionalArgs.append(value)
            } else {
                foundKeyword = true
                guard seenKeys.insert(key).inserted else {
                    throw PythonError.valueError("Duplicate keyword argument '\(key)'")
                }
                keywordPairs.append((key, value))
            }
        }
        
        return try await callPythonCallable(callable, args: positionalArgs, keywordPairs: keywordPairs)
    }
    
    private func callPythonCallable(_ callable: PythonObject,
                                    args: [any PendingPythonConvertible],
                                    keywordPairs: [(String, any PendingPythonConvertible)]) async throws -> PythonObject {
        let argTuplePtr: UnsafeMutableRawPointer? = try await createTupleAsync(args)
        let kwDictPtr: UnsafeMutableRawPointer? = try await createKwargsDictAsync(keywordPairs)
        
        guard let callablePtr = getRegisteredPointer(forPythonObject:callable) else {
            throw PythonError.nullPointer("Callable pointer not found")
        }
        return try await withGIL {
            let resultPtr = try callCallable(callablePtr, args: argTuplePtr!, kwargs: kwDictPtr, onError: { try throwPythonError() } )
            return newPythonObject(fromReturnedPointer: resultPtr)
        }
    }
    
    internal func createKwargsDictAsync(_ kwargs: [String: any PendingPythonConvertible]) async throws -> UnsafeMutableRawPointer? {
        if kwargs.isEmpty {
            return nil
        } else {
            let dict = try await convertToPython(dictionary:kwargs)
            return getRegisteredPointer(forPythonObject:dict)
        }
    }
    
    internal func createKwargsDictAsync(_ kwargs: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> UnsafeMutableRawPointer? {
        if kwargs.isEmpty {
            return nil
        } else {
            let dict = try await convertKeywordArgumentsToPython(kwargs)
            return getRegisteredPointer(forPythonObject:dict)
        }
    }
    
    private func createKwargsDictAsync(_ kwargs: [(String, any PendingPythonConvertible)]) async throws -> UnsafeMutableRawPointer? {
        if kwargs.isEmpty {
            return nil
        }
        var dictionary: [String: any PendingPythonConvertible] = [:]
        for (key, value) in kwargs {
            dictionary[key] = value
        }
        let dict = try await convertToPython(dictionary: dictionary)
        return getRegisteredPointer(forPythonObject:dict)
    }
    
    /// Looks up and calls a Python method with positional and dictionary keyword arguments.
    ///
    /// This is the interpreter-level form of `try await object.method.call(...)`. Most
    /// callers should prefer the `PythonObject` dynamic-member API, but this helper is
    /// useful when the method name is only known at runtime or arguments are already
    /// collected in arrays and dictionaries.
    ///
    /// - Parameters:
    ///   - object: The Python object whose attribute should be called.
    ///   - methodName: The Python attribute name to look up and call.
    ///   - collectedArgs: Positional arguments converted to Python objects before the call.
    ///   - kwargs: Keyword arguments converted into a Python `dict`.
    /// - Returns: The Python object returned by the method.
    /// - Throws: `PythonError` if the object pointer is unavailable, attribute lookup fails,
    ///   conversion fails, the attribute is not callable, or Python raises during the call.
    public func callPythonMethod(object: PythonObject, methodName: String, collectedArgs: [any PendingPythonConvertible],
                                 kwargs: [String: any PendingPythonConvertible]) async throws -> PythonObject {
        guard let objPtr = getRegisteredPointer(forPythonObject:object) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        let methodPtr = try await withGIL {
            try getAttr(methodName, onObject: objPtr, orElse: { try throwPythonError() })
        }
        let methodObject = newPythonObject(fromReturnedPointer: methodPtr)
        return try await callPythonCallable(methodObject, args: collectedArgs, kwargs: kwargs)
    }
    
    /// Looks up and calls a Python method with positional and ordered keyword arguments.
    ///
    /// Use this overload when keyword order should be preserved or duplicate keyword
    /// detection should happen before Python receives the call. Most callers should
    /// prefer `try await object.method(arg, name: value)` or `object.method.call(...)`.
    ///
    /// - Parameters:
    ///   - object: The Python object whose attribute should be called.
    ///   - methodName: The Python attribute name to look up and call.
    ///   - collectedArgs: Positional arguments converted to Python objects before the call.
    ///   - kwargs: Ordered keyword arguments converted into a Python `dict`.
    /// - Returns: The Python object returned by the method.
    /// - Throws: `PythonError.valueError` for invalid keyword pairs, or `PythonError`
    ///   if lookup, conversion, or the Python call fails.
    public func callPythonMethod(object: PythonObject, methodName: String, collectedArgs: [any PendingPythonConvertible],
                                 kwargs: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {
        guard let objPtr = getRegisteredPointer(forPythonObject:object) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        let methodPtr = try await withGIL {
            try getAttr(methodName, onObject: objPtr, orElse: { try throwPythonError() })
        }
        let methodObject = newPythonObject(fromReturnedPointer: methodPtr)
        return try await callPythonCallable(methodObject, args: collectedArgs, kwargs: kwargs)
    }
    
    /// Looks up and calls a Python method with positional arguments.
    ///
    /// This is the collected-argument form for method names known only at runtime.
    /// Prefer `try await object.method(1, 2)` when the method name is static.
    ///
    /// - Parameters:
    ///   - object: The Python object whose attribute should be called.
    ///   - methodName: The Python attribute name to look up and call.
    ///   - collectedArgs: Positional arguments converted to Python objects before the call.
    /// - Returns: The Python object returned by the method.
    /// - Throws: `PythonError` if lookup, conversion, or the Python call fails.
    public func callPythonMethod(object: PythonObject, methodName: String,
                                 collectedArgs: [any PendingPythonConvertible]) async throws -> PythonObject {
        
        guard let objPtr = getRegisteredPointer(forPythonObject:object) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        let methodPtr = try await withGIL {
            try getAttr(methodName, onObject: objPtr, orElse: { try throwPythonError() })
        }
        let methodObject = newPythonObject(fromReturnedPointer: methodPtr)
        return try await callPythonCallable(methodObject, args: collectedArgs, kwargs: [:])
    }
    
    /// Looks up and calls a Python method with positional arguments.
    ///
    /// This convenience overload accepts Swift variadic arguments instead of an array.
    /// Prefer dynamic-member syntax when the method name is static.
    ///
    /// - Parameters:
    ///   - obj: The Python object whose attribute should be called.
    ///   - name: The Python attribute name to look up and call.
    ///   - args: Positional arguments converted to Python objects before the call.
    /// - Returns: The Python object returned by the method.
    /// - Throws: `PythonError` if lookup, conversion, or the Python call fails.
    public func callPythonMethod(_ obj: PythonObject, _ name: String, _ args: any PendingPythonConvertible...) async throws -> PythonObject {
        let allArgs = args as [any PendingPythonConvertible]
        return try await callPythonMethod(object: obj, methodName: name, collectedArgs: allArgs)
    }
    
    /// Looks up and calls a Python method with positional and dictionary keyword arguments.
    ///
    /// This convenience overload accepts Swift variadic positional arguments and a
    /// keyword dictionary. Prefer dynamic-member syntax when the method name is static.
    ///
    /// - Parameters:
    ///   - obj: The Python object whose attribute should be called.
    ///   - name: The Python attribute name to look up and call.
    ///   - args: Positional arguments converted to Python objects before the call.
    ///   - kwargs: Keyword arguments converted into a Python `dict`.
    /// - Returns: The Python object returned by the method.
    /// - Throws: `PythonError` if lookup, conversion, keyword conversion, or the Python call fails.
    public func callPythonMethod(_ obj: PythonObject, _ name: String, _ args: any PendingPythonConvertible...,
                                 kwargs: [String: any PendingPythonConvertible] = [:]) async throws -> PythonObject {
        let allArgs = args as [any PendingPythonConvertible]
        return try await callPythonMethod(object: obj, methodName: name, collectedArgs: allArgs, kwargs:kwargs)
    }
    
    // MARK: Callable support (synchronous mode)
    
    internal func syncCall(callable: SafePythonObject) throws -> SafePythonObject {
        let callablePtr = getRegisteredPointer(forSafeObj: callable)
        let resultPtr = try callCallable(callablePtr, onError: { try throwSafePythonError() } )
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func syncCall(callable: SafePythonObject, args: [any SafePythonConvertible]) throws -> SafePythonObject {
        // args in a tuple
        let argTuplePtr: UnsafeMutableRawPointer?
        if args.isEmpty {
            argTuplePtr = nil
        } else {
            argTuplePtr = try syncCreateTuplePtr(from: args)
        }
        defer {
            if let argTuplePtr {
                api.Py_DecRef(argTuplePtr)
            }
        }
        let callablePtr = getRegisteredPointer(forSafeObj: callable)
        let resultPtr = try callCallable(callablePtr, args: argTuplePtr, onError: { try throwSafePythonError() } )
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func syncCall(callable: SafePythonObject,
                             args: [any SafePythonConvertible],
                             kwargs: [String: any SafePythonConvertible]) throws -> SafePythonObject {
        // args in a tuple
        let argTuplePtr: UnsafeMutableRawPointer?
        if args.isEmpty {
            argTuplePtr = nil
        } else {
            argTuplePtr = try syncCreateTuplePtr(from: args)
        }
        defer {
            if let argTuplePtr {
                api.Py_DecRef(argTuplePtr)
            }
        }
        
        // kwargs in a dict
        let kwDictPtr: UnsafeMutableRawPointer?
        if kwargs.isEmpty {
            kwDictPtr = nil
        } else {
            let kwargsDictObj = try convertToSafePython(dictionary: kwargs)
            kwDictPtr = getRegisteredPointer(forSafeObj: kwargsDictObj)
        }
        
        let callablePtr = getRegisteredPointer(forSafeObj: callable)
        let resultPtr = try callCallable(callablePtr, args: argTuplePtr, kwargs: kwDictPtr, onError: { try throwSafePythonError() } )
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func syncCall(callable: SafePythonObject,
                          args: [any SafePythonConvertible],
                          kwargs: KeyValuePairs<String, any SafePythonConvertible>) throws -> SafePythonObject {
        // args in a tuple
        let argTuplePtr: UnsafeMutableRawPointer?
        if args.isEmpty {
            argTuplePtr = nil
        } else {
            argTuplePtr = try syncCreateTuplePtr(from: args)
        }
        defer {
            if let argTuplePtr {
                api.Py_DecRef(argTuplePtr)
            }
        }
        
        // kwargs in a dict
        let kwDictPtr: UnsafeMutableRawPointer?
        if kwargs.isEmpty {
            kwDictPtr = nil
        } else {
            let kwargsDictObj = try convertKeywordArgumentsToSafePython(kwargs)
            kwDictPtr = getRegisteredPointer(forSafeObj: kwargsDictObj)
        }
        
        let callablePtr = getRegisteredPointer(forSafeObj: callable)
        let resultPtr = try callCallable(callablePtr, args: argTuplePtr, kwargs: kwDictPtr, onError: { try throwSafePythonError() } )
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func syncCall(callable: SafePythonObject,
                          dynamicArguments: KeyValuePairs<String, any SafePythonConvertible>) throws -> SafePythonObject {
        var positionalArgs: [any SafePythonConvertible] = []
        var keywordPairs: [(String, any SafePythonConvertible)] = []
        var foundKeyword = false
        var seenKeys = Set<String>()
        
        for (key, value) in dynamicArguments {
            if key.isEmpty {
                guard !foundKeyword else {
                    throw PythonError.valueError("Positional argument cannot follow keyword argument")
                }
                positionalArgs.append(value)
            } else {
                foundKeyword = true
                guard seenKeys.insert(key).inserted else {
                    throw PythonError.valueError("Duplicate keyword argument '\(key)'")
                }
                keywordPairs.append((key, value))
            }
        }
        
        return try syncCall(callable: callable, args: positionalArgs, keywordPairs: keywordPairs)
    }
    
    private func syncCall(callable: SafePythonObject,
                          args: [any SafePythonConvertible],
                          keywordPairs: [(String, any SafePythonConvertible)]) throws -> SafePythonObject {
        let argTuplePtr: UnsafeMutableRawPointer?
        if args.isEmpty {
            argTuplePtr = nil
        } else {
            argTuplePtr = try syncCreateTuplePtr(from: args)
        }
        defer {
            if let argTuplePtr {
                api.Py_DecRef(argTuplePtr)
            }
        }
        
        let kwDictPtr: UnsafeMutableRawPointer?
        if keywordPairs.isEmpty {
            kwDictPtr = nil
        } else {
            var dictionary: [String: any SafePythonConvertible] = [:]
            for (key, value) in keywordPairs {
                dictionary[key] = value
            }
            let kwargsDictObj = try convertToSafePython(dictionary: dictionary)
            kwDictPtr = getRegisteredPointer(forSafeObj: kwargsDictObj)
        }
        
        let callablePtr = getRegisteredPointer(forSafeObj: callable)
        let resultPtr = try callCallable(callablePtr, args: argTuplePtr, kwargs: kwDictPtr, onError: { try throwSafePythonError() } )
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
}
