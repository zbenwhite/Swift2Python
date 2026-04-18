//
//  PythonInterpreter+Callable.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//


extension PythonInterpreter {
    
    
    // MARK: Callable Support (async mode)
    
    // Private helper that does the actual call (used by both above)
    internal func callPythonCallable(_ callable: PythonObject,
                                    args: [any PendingPythonConvertible],
                                    kwargs: [String: PendingPythonConvertible]) async throws -> PythonObject {
        return try await withGIL {
            // Build args tuple
            let argTuplePtr: UnsafeMutableRawPointer? = try await createArgsTupleAsync(args)
            // Build kwargs dict (if any)
            let kwDictPtr: UnsafeMutableRawPointer? = kwargs.isEmpty
            ? nil
            : try await createKwargsDictAsync(kwargs)
            
            guard let callablePtr = getRegisteredPythonObjectPointer(callable.id) else {
                throw PythonError.nullPointer("Callable pointer not found")
            }
            
            // Use PyObject_Call (most flexible)
            guard let resultPtr = try api.pythonObject_Call(callablePtr, argTuplePtr!, kwDictPtr) else {
                throw PythonError.nullPointer("Python call returned NULL")
            }
            let resultID = registerPythonObjectPointer(resultPtr)
            return PythonObject(id: resultID, interpreter: self)
        }
    }
    
    internal func createArgsTupleAsync(_ args: [any PendingPythonConvertible]) async throws -> UnsafeMutableRawPointer {
        guard let tuplePtr = try api.pythonTuple_New(args.count) else {
            throw PythonError.nullPointer("Failed to create argument tuple")
        }
        
        for (index, element) in args.enumerated() {
            let pyObj = try await element.toPythonObject(interpreter: self)
            guard let itemPtr = getRegisteredPythonObjectPointer(pyObj.id) else {
                throw PythonError.nullPointer("Argument conversion failed")
            }
            _ = try api.pythonTuple_SetItem(tuplePtr, index, itemPtr)
        }
        return tuplePtr
    }
    
    internal func createKwargsDictAsync(_ kwargs: [String: PendingPythonConvertible]) async throws -> UnsafeMutableRawPointer {
        guard let dictPtr = try api.pythonDict_New() else {
            throw PythonError.nullPointer("Failed to create kwargs dict")
        }
        
        for (key, value) in kwargs {
            let keyObj = try await convertToPython(string: key)
            let valueObj = try await value.toPythonObject(interpreter: self)
            
            guard let keyPtr = getRegisteredPythonObjectPointer(keyObj.id),
                  let valuePtr = getRegisteredPythonObjectPointer(valueObj.id) else {
                throw PythonError.nullPointer("Kwargs conversion failed")
            }
            _ = try api.pythonDict_SetItem(dictPtr, keyPtr, valuePtr)
        }
        return dictPtr
    }
    
    public func callPythonMethod(object: PythonObject, methodName: String, collectedArgs: [any PendingPythonConvertible],
                                 kwargs: [String: PendingPythonConvertible]) async throws -> PythonObject {
        
        guard let objPtr = getRegisteredPythonObjectPointer(object.id) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        
        guard let methodPtr = try api.pythonObject_GetAttrString(objPtr, methodName) else {
            throw PythonError.nullPointer("Method '\(methodName)' not found on object")
        }
        
        let methodID = registerPythonObjectPointer(methodPtr)
        let methodObject = PythonObject(id: methodID, interpreter: self)
        
        return try await callPythonCallable(methodObject, args: collectedArgs, kwargs: kwargs)
    }
    
    public func callPythonMethod(object: PythonObject, methodName: String,
                                 collectedArgs: [any PendingPythonConvertible]) async throws -> PythonObject {
        
        guard let objPtr = getRegisteredPythonObjectPointer(object.id) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        
        guard let methodPtr = try api.pythonObject_GetAttrString(objPtr, methodName) else {
            throw PythonError.nullPointer("Method '\(methodName)' not found on object")
        }
        
        let methodID = registerPythonObjectPointer(methodPtr)
        let methodObject = PythonObject(id: methodID, interpreter: self)
        
        return try await callPythonCallable(methodObject, args: collectedArgs, kwargs: [:])
    }
    
    public func callPythonMethod(_ obj: PythonObject, _ name: String, _ args: any PendingPythonConvertible...) async throws -> PythonObject {
        let allArgs = args as [any PendingPythonConvertible]
        return try await callPythonMethod(object: obj, methodName: name, collectedArgs: allArgs)
    }
    
    public func callPythonMethod(_ obj: PythonObject, _ name: String, _ args: any PendingPythonConvertible...,
                                 kwargs: [String: PendingPythonConvertible] = [:]) async throws -> PythonObject {
        let allArgs = args as [any PendingPythonConvertible]
        return try await callPythonMethod(object: obj, methodName: name, collectedArgs: allArgs, kwargs:kwargs)
    }
    
    // MARK: Callable support (synchronous mode)
    
    internal func syncCallCreateTuplePtr(from elements: [any SafePythonConvertible]) throws -> UnsafeMutableRawPointer {
        let count = elements.count
        logger.trace("CPython API call in synchronous mode: PyTuple_New")
        guard let tuplePtr = api.PyTuple_New(count) else {
            throw PythonError.nullPointer("Failed to create Python tuple")
        }
        
        logger.trace("CPython API call in synchronous mode: PyTuple_SetItem in a loop.")
        for (index, element) in elements.enumerated() {
            
            // Convert args from SafePythonConvertible to SafePythonObject
            let pyObj = try element.toSafePythonObject(interpreter: self)
            guard let itemPtr = getRegisteredPythonObjectPointer(pyObj.id) else {
                throw PythonError.nullPointer("Argument conversion failed")
            }
            
            let res = api.PyTuple_SetItem(tuplePtr, index, itemPtr)
            if res != 0 {
                throw PythonError.stringConversionFailed("PyTuple_SetItem failed at index \(index)")
            }
        }
        
        return tuplePtr
    }
    
    internal func syncCallCreateDictPtr(from dict: [String: any SafePythonConvertible]) throws -> UnsafeMutableRawPointer {
        logger.trace("CPython API call in synchronous mode: PyDict_New")
        guard let dictPtr = api.PyDict_New() else {
            throw PythonError.nullPointer("Failed to create Python dict")
        }
        
        for (key, value) in dict {
            let keyObj = try convertToSafePython(string: key)           // or use your existing string converter
            let valueObj = try value.toSafePythonObject(interpreter: self)
            
            let keyPtr = getRegisteredPythonObjectPointer(keyObj.id)!
            let valuePtr = getRegisteredPythonObjectPointer(valueObj.id)!
            
            let res = api.PyDict_SetItem(dictPtr, keyPtr, valuePtr)
            if res != 0 {
                throw PythonError.stringConversionFailed("PyDict_SetItem failed for key: \(key)")
            }
        }
        
        return dictPtr
    }
    
    internal func syncCall(callable: SafePythonObject) throws -> SafePythonObject {
        if let pyCall = api.PyObject_CallNoArgs {
            let callablePtr = getRegisteredPythonObjectPointer(callable.id)!
            
            logger.trace("CPython API call in synchronous mode: PyObject_CallNoArgs")
            guard let resultPtr = pyCall(callablePtr) else {
                throw PythonError.nullPointer("Python call failed")
            }
            let resultId = registerPythonObjectPointer(resultPtr)
            return SafePythonObject(interpreter: self, id: resultId)
        } else {
            logger.debug("PyObject_CallNoArgs not available → falling back to syncCall with empty args")
            return try syncCall(callable: callable, args: [])
        }
    }
    
    internal func syncCall(callable: SafePythonObject, args: [any SafePythonConvertible]) throws -> SafePythonObject {
        
        // Put args in a tuple
        let argTuplePtr = try syncCallCreateTuplePtr(from: args)
        
        let callablePtr = getRegisteredPythonObjectPointer(callable.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_CallObject")
        guard let resultPtr = api.PyObject_CallObject(callablePtr, argTuplePtr) else {
            throw PythonError.nullPointer("Python call failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncCall(callable: SafePythonObject,
                             args: [any SafePythonConvertible],
                             kwargs: [String: any SafePythonConvertible]) throws -> SafePythonObject {
        
        // Put args in a tuple
        let argTuplePtr = try syncCallCreateTuplePtr(from: args)
        
        // Create kwargs dictionary (can be NULL if no keyword args)
        let kwDictPtr: UnsafeMutableRawPointer? = kwargs.isEmpty ? nil : try syncCallCreateDictPtr(from: kwargs)
        
        let callablePtr = getRegisteredPythonObjectPointer(callable.id)!
        
        logger.trace("CPython API call (sync): PyObject_Call")
        
        logger.trace("CPython API call in synchronous mode: PyObject_Call")
        guard let resultPtr = api.PyObject_Call(callablePtr, argTuplePtr, kwDictPtr) else {
            throw PythonError.nullPointer("Python call failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
}
