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
    
    internal func createKwargsDictAsync(_ kwargs: [String: any PendingPythonConvertible]) async throws -> UnsafeMutableRawPointer? {
        if kwargs.isEmpty {
            return nil
        } else {
            let dict = try await convertToPython(dictionary:kwargs)
            return getRegisteredPointer(forPythonObject:dict)
        }
    }
    
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
    
    public func callPythonMethod(_ obj: PythonObject, _ name: String, _ args: any PendingPythonConvertible...) async throws -> PythonObject {
        let allArgs = args as [any PendingPythonConvertible]
        return try await callPythonMethod(object: obj, methodName: name, collectedArgs: allArgs)
    }
    
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
    
}
