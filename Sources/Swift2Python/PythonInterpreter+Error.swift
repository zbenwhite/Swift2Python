//
//  PythonInterpreter+Error.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

extension PythonInterpreter {
    
    // This function assumes you already have the GIL.
    internal func throwPythonErrorIfPresent() throws {
        guard api.pythonErr_Occurred() != nil else { return }
        try throwPythonError()
    }
    
    // This function assumes you already have the GIL.
    internal func throwPythonError() throws -> Never {
        if let pyGetRaisedException = api.PyErr_GetRaisedException {
            // Python 3.12+ returns the raised exception object with its traceback attached.
            logger.trace("CPython API Call: PyErr_GetRaisedException")
            if let exceptionPtr = pyGetRaisedException() {
                let info = capturePythonExceptionInfo(exceptionPtr: exceptionPtr)
                let exception = newPythonObject(fromReturnedPointer: exceptionPtr)
                throw PythonError.pythonException(exception, info: info)
            }
        } else {
            // Python 3.11 and earlier expose type, value, traceback through PyErr_Fetch.
            var excType: UnsafeMutableRawPointer? = nil
            var excValue: UnsafeMutableRawPointer? = nil
            var excTraceback: UnsafeMutableRawPointer? = nil
            
            logger.trace("CPython API Call: PyErr_Fetch")
            api.PyErr_Fetch(&excType, &excValue, &excTraceback)
            if excType != nil || excValue != nil {
                logger.trace("CPython API Call: PyErr_NormalizeException")
                api.PyErr_NormalizeException(&excType, &excValue, &excTraceback)

                let exceptionPtr = excValue ?? excType
                guard let exceptionPtr else {
                    if let tracebackPtr = excTraceback { api.Py_DecRef(tracebackPtr) }
                    throw PythonError.unknownPythonException
                }

                let info = capturePythonExceptionInfo(
                    exceptionPtr: exceptionPtr,
                    typePtr: excType,
                    tracebackPtr: excTraceback
                )

                if exceptionPtr != excType, let typePtr = excType {
                    api.Py_DecRef(typePtr)
                }
                if let tracebackPtr = excTraceback {
                    api.Py_DecRef(tracebackPtr)
                }

                let exception = newPythonObject(fromReturnedPointer: exceptionPtr)
                throw PythonError.pythonException(exception, info: info)
            }
        }
        throw PythonError.unknownPythonException
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func throwSafePythonErrorIfPresent() throws {
        guard api.pythonErr_Occurred() != nil else { return }
        try throwSafePythonError()
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func throwSafePythonError() throws -> Never {
        logger.trace("throwPythonError (synchronous)")
        if let pyGetRaisedException = api.PyErr_GetRaisedException {
            // Python 3.12+ returns the raised exception object with its traceback attached.
            logger.trace("CPython API Call: PyErr_GetRaisedException")
            if let exceptionPtr = pyGetRaisedException() {
                let info = capturePythonExceptionInfo(exceptionPtr: exceptionPtr)
                let exception = newSafePythonObject(fromReturnedPointer: exceptionPtr)
                logger.warning("Python error: \(info.formatted)")
                throw PythonError.safePythonException(exception, info: info)
            }
        } else {
            // Python 3.11 and earlier expose type, value, traceback through PyErr_Fetch.
            var excType: UnsafeMutableRawPointer? = nil
            var excValue: UnsafeMutableRawPointer? = nil
            var excTraceback: UnsafeMutableRawPointer? = nil
            
            logger.trace("CPython API Call: PyErr_Fetch")
            api.PyErr_Fetch(&excType, &excValue, &excTraceback)
            if excType != nil || excValue != nil {
                logger.trace("CPython API Call: PyErr_NormalizeException")
                api.PyErr_NormalizeException(&excType, &excValue, &excTraceback)

                let exceptionPtr = excValue ?? excType
                guard let exceptionPtr else {
                    if let tracebackPtr = excTraceback { api.Py_DecRef(tracebackPtr) }
                    throw PythonError.unknownPythonException
                }

                let info = capturePythonExceptionInfo(
                    exceptionPtr: exceptionPtr,
                    typePtr: excType,
                    tracebackPtr: excTraceback
                )

                if exceptionPtr != excType, let typePtr = excType {
                    api.Py_DecRef(typePtr)
                }
                if let tracebackPtr = excTraceback {
                    api.Py_DecRef(tracebackPtr)
                }

                let exception = newSafePythonObject(fromReturnedPointer: exceptionPtr)
                logger.warning("Python error: \(info.formatted)")
                throw PythonError.safePythonException(exception, info: info)
            }
        }
        throw PythonError.unknownPythonException
    }

    // MARK: Exception Formatting

    // Python exceptions cross two boundaries in this package: the C API boundary,
    // where CPython reports errors as borrowed/owned PyObject pointers, and the
    // Swift concurrency boundary, where SafePythonObject values may not be usable
    // after withIsolatedContext exits. The helpers in this section take a snapshot
    // of the active Python exception while the GIL is held, producing plain Swift
    // strings that remain safe and useful after the Python objects move across
    // those boundaries.
    //
    // The snapshot keeps both a compact Swift headline and Python's own traceback
    // formatting. A simple exception should read like:
    //
    //     Python exception: ValueError: deep failure
    //     Traceback (most recent call last):
    //       File "<string>", line 3, in outer
    //       File "<string>", line 2, in inner
    //     ValueError: deep failure
    //
    // Chained exceptions should keep Python's standard cause/context text, for
    // example:
    //
    //     KeyError: 'root failure'
    //
    //     The above exception was the direct cause of the following exception:
    //
    //     RuntimeError: wrapped failure
    //
    // Python 3.12+ stores the currently raised exception as one object, with its
    // traceback attached. Python 3.11 and earlier expose type, value, and traceback
    // separately through PyErr_Fetch. The rest of this section normalizes both
    // shapes into the same PythonExceptionInfo value before Swift throws.
    
    // This function assumes you already have the GIL.
    private func capturePythonExceptionInfo(
        exceptionPtr: UnsafeMutableRawPointer,
        typePtr: UnsafeMutableRawPointer? = nil,
        tracebackPtr: UnsafeMutableRawPointer? = nil
    ) -> PythonExceptionInfo {
        // PyErr_Fetch gives us the exception type separately on Python 3.11 and
        // earlier. PyErr_GetRaisedException on Python 3.12+ only gives the value,
        // so derive the type from value.__class__ in that path.
        let resolvedTypePtr = typePtr ?? getAttributePointer("__class__", from: exceptionPtr)
        defer {
            // Attribute lookup returns a new reference. A type pointer supplied by
            // PyErr_Fetch is owned and released by the caller after this snapshot.
            if typePtr == nil, let resolvedTypePtr {
                api.Py_DecRef(resolvedTypePtr)
            }
        }

        // Keep the type name as plain Swift data so descriptions remain useful
        // after the Python exception object leaves the GIL-protected section.
        let typeName = resolvedTypePtr.flatMap { typePointer in
            getAttributePointer("__name__", from: typePointer).flatMap { namePtr in
                defer { api.Py_DecRef(namePtr) }
                return stringFromPythonObject(namePtr)
            }
        } ?? "PythonException"

        let message = stringFromPythonObject(exceptionPtr) ?? "<unrepresentable Python exception>"

        let resolvedTracebackPtr: UnsafeMutableRawPointer?
        var ownsResolvedTraceback = false
        if let tracebackPtr {
            // PyErr_Fetch passed ownership to the caller, so borrow it here and
            // let throwPythonError / throwSafePythonError release it.
            resolvedTracebackPtr = tracebackPtr
        } else {
            // Python 3.12+ keeps the traceback attached to the exception value.
            // Attribute lookup returns a new reference that this function owns.
            resolvedTracebackPtr = getAttributePointer("__traceback__", from: exceptionPtr)
            ownsResolvedTraceback = resolvedTracebackPtr != nil
        }
        defer {
            if ownsResolvedTraceback, let resolvedTracebackPtr {
                api.Py_DecRef(resolvedTracebackPtr)
            }
        }

        let traceback = formatTraceback(
            exceptionPtr: exceptionPtr,
            typePtr: resolvedTypePtr,
            tracebackPtr: resolvedTracebackPtr
        )

        return PythonExceptionInfo(typeName: typeName, message: message, traceback: traceback)
    }

    // This function assumes you already have the GIL.
    private func getAttributePointer(_ name: String, from objectPtr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
        guard let attrPtr = api.pythonObject_GetAttrString(objectPtr, name) else {
            // These lookups are best-effort formatting helpers. If they fail,
            // clear the formatting error so it does not replace the real Python error.
            try? api.pythonErr_Clear()
            return nil
        }
        return attrPtr
    }

    // This function assumes you already have the GIL.
    private func stringFromPythonObject(_ objectPtr: UnsafeMutableRawPointer) -> String? {
        guard let stringPtr = api.pythonObject_Str(objectPtr) else {
            // String conversion is diagnostic only. Preserve the original error
            // by clearing any secondary formatting failure.
            try? api.pythonErr_Clear()
            return nil
        }
        defer { api.Py_DecRef(stringPtr) }
        guard let string = api.pythonUnicode_AsUTF8AndSize(stringPtr) else {
            try? api.pythonErr_Clear()
            return nil
        }
        return string
    }

    // This function assumes you already have the GIL.
    private func formatTraceback(
        exceptionPtr: UnsafeMutableRawPointer,
        typePtr: UnsafeMutableRawPointer?,
        tracebackPtr: UnsafeMutableRawPointer?
    ) -> String? {
        // Delegate formatting to Python's traceback module so exception causes,
        // implicit contexts, notes, and Python-version-specific formatting match
        // what a Python user would see.
        guard let tracebackModule = api.pythonImport_ImportModule("traceback") else {
            try? api.pythonErr_Clear()
            return nil
        }
        defer { api.Py_DecRef(tracebackModule) }

        guard let formatException = api.pythonObject_GetAttrString(tracebackModule, "format_exception") else {
            try? api.pythonErr_Clear()
            return nil
        }
        defer { api.Py_DecRef(formatException) }

        guard let typePtr, let tracebackPtr else { return nil }

        // traceback.format_exception expects (type, value, traceback) and
        // returns an array of strings. makeBorrowingTuple balances the stolen
        // references required by PyTuple_SetItem.
        guard let args = makeBorrowingTuple([typePtr, exceptionPtr, tracebackPtr]) else { return nil }
        defer { api.Py_DecRef(args) }

        guard let lines = api.pythonObject_Call(formatException, args, nil) else {
            try? api.pythonErr_Clear()
            return nil
        }
        defer { api.Py_DecRef(lines) }

        return joinPythonStringSequence(lines)
    }

    // This function assumes you already have the GIL.
    private func joinPythonStringSequence(_ sequencePtr: UnsafeMutableRawPointer) -> String? {
        // Python's traceback helpers return [String]. Use Python's own "".join
        // so the sequence protocol and Unicode handling stay on the Python side.
        guard let separator = api.pythonUnicode_FromStringAndSize("") else {
            try? api.pythonErr_Clear()
            return nil
        }
        defer { api.Py_DecRef(separator) }

        guard let join = api.pythonObject_GetAttrString(separator, "join") else {
            try? api.pythonErr_Clear()
            return nil
        }
        defer { api.Py_DecRef(join) }

        guard let args = makeBorrowingTuple([sequencePtr]) else { return nil }
        defer { api.Py_DecRef(args) }

        guard let joined = api.pythonObject_Call(join, args, nil) else {
            try? api.pythonErr_Clear()
            return nil
        }
        defer { api.Py_DecRef(joined) }

        return api.pythonUnicode_AsUTF8AndSize(joined)
    }

    // This function assumes you already have the GIL.
    private func makeBorrowingTuple(_ objects: [UnsafeMutableRawPointer]) -> UnsafeMutableRawPointer? {
        // PyTuple_SetItem steals a reference. Callers pass borrowed pointers, so
        // increment first and let the tuple own the incremented reference.
        guard let tuple = api.pythonTuple_New(objects.count) else {
            try? api.pythonErr_Clear()
            return nil
        }

        for (index, object) in objects.enumerated() {
            api.Py_IncRef(object)
            if api.pythonTuple_SetItem(tuple, index, object) != 0 {
                // On failure PyTuple_SetItem did not steal the reference, so
                // release the increment before discarding the partial tuple.
                api.Py_DecRef(object)
                api.Py_DecRef(tuple)
                try? api.pythonErr_Clear()
                return nil
            }
        }

        return tuple
    }
}
