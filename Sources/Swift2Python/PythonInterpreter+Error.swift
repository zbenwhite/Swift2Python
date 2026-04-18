//
//  PythonInterpreter+Error.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

extension PythonInterpreter {
    
    // This function assumes you already have the GIL.
    internal func throwPythonErrorIfPresent() async throws {
        guard try api.pythonErr_Occurred() != nil else { return }
        try await throwPythonError()
    }
    
    // This function assumes you already have the GIL.
    internal func throwPythonError() async throws -> Never {
        if let pyGetRaisedException = api.PyErr_GetRaisedException {
            // Do it the new Python 3.12 way
            logger.trace("CPython API Call: PyErr_GetRaisedException")
            if let exceptionPtr = pyGetRaisedException() {
                //defer { Py_DECREF(exc) }
                let id = registerPythonObjectPointer(exceptionPtr)
                let exception = PythonObject(id: id, interpreter: self)
                throw PythonError.pythonException(exception)            }
        } else {
            // Do it the old Python 3.11 or earlier way
            var excType: UnsafeMutableRawPointer? = nil
            var excValue: UnsafeMutableRawPointer? = nil
            var excTraceback: UnsafeMutableRawPointer? = nil
            
            logger.trace("CPython API Call: PyErr_Fetch")
            api.PyErr_Fetch(&excType, &excValue, &excTraceback)
            if excType != nil || excValue != nil {
                
                logger.trace("CPython API Call: PyErr_NormalizeException")
                api.PyErr_NormalizeException(&excType, &excValue, &excTraceback)
                if let valuePtr = excValue {
                    let id = registerPythonObjectPointer(valuePtr)
                    let exception = PythonObject(id: id, interpreter: self)
                    throw PythonError.pythonException(exception)
                } else if let typePtr = excType {
                    let id = registerPythonObjectPointer(typePtr)
                    let exception = PythonObject(id: id, interpreter: self)
                    throw PythonError.pythonException(exception)
                } else {
                    throw PythonError.unknownPythonException
                }
            }
        }
        throw PythonError.unknownPythonException
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func throwPythonErrorIfPresent() throws {
        guard try api.pythonErr_Occurred() != nil else { return }
        try throwPythonError()
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func throwPythonError() throws -> Never {
        logger.trace("throwPythonError (synchronous)")
        if let pyGetRaisedException = api.PyErr_GetRaisedException {
            // Do it the new Python 3.12 way
            logger.trace("CPython API Call: PyErr_GetRaisedException")
            if let exceptionPtr = pyGetRaisedException() {
                //defer { Py_DECREF(exc) }
                
                let id = registerPythonObjectPointer(exceptionPtr)
                let exception = SafePythonObject(interpreter: self, id: id)
                logger.warning("Python error: \(exception)")
                throw PythonError.safePythonException(exception)
            }
        } else {
            // Do it the old Python 3.11 or earlier way
            var excType: UnsafeMutableRawPointer? = nil
            var excValue: UnsafeMutableRawPointer? = nil
            var excTraceback: UnsafeMutableRawPointer? = nil
            
            logger.trace("CPython API Call: PyErr_Fetch")
            api.PyErr_Fetch(&excType, &excValue, &excTraceback)
            if excType != nil || excValue != nil {
                
                logger.trace("CPython API Call: PyErr_NormalizeException")
                api.PyErr_NormalizeException(&excType, &excValue, &excTraceback)
                if let valuePtr = excValue {
                    let id = registerPythonObjectPointer(valuePtr)
                    let exception = SafePythonObject(interpreter: self, id: id)
                    logger.warning("Python error: \(exception)")
                    throw PythonError.safePythonException(exception)
                } else if let typePtr = excType {
                    let id = registerPythonObjectPointer(typePtr)
                    let exception = SafePythonObject(interpreter: self, id: id)
                    logger.warning("Python error: \(exception)")
                    throw PythonError.safePythonException(exception)
                } else {
                    throw PythonError.unknownPythonException
                }
            }
        }
        throw PythonError.unknownPythonException
    }
    
}
