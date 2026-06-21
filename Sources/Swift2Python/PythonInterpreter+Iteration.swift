//
//  PythonInterpreter+Iteration.swift
//  Swift2Python
//
//  Created by Coding Assistant on 6/21/26.
//

extension PythonInterpreter {
    internal func makeIterator(for obj: PythonObject) async throws -> PythonObject {
        guard let objPtr = getRegisteredPointer(forPythonObject: obj) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try await withGIL {
            guard let iteratorPtr = api.pythonObject_GetIter(objPtr) else {
                try throwPythonError()
            }
            return newPythonObject(fromReturnedPointer: iteratorPtr)
        }
    }

    internal func iteratorNext(_ iterator: PythonObject) async throws -> PythonObject? {
        guard let iteratorPtr = getRegisteredPointer(forPythonObject: iterator) else {
            throw PythonError.nullPointer("Iterator pointer not found")
        }
        return try await withGIL {
            if let itemPtr = api.pythonIter_Next(iteratorPtr) {
                return newPythonObject(fromReturnedPointer: itemPtr)
            }
            try throwPythonErrorIfPresent()
            return nil
        }
    }

    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func makeIterator(for obj: SafePythonObject) throws -> SafePythonObject {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        guard let iteratorPtr = api.pythonObject_GetIter(objPtr) else {
            try throwSafePythonError()
        }
        return newSafePythonObject(fromReturnedPointer: iteratorPtr)
    }

    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func iteratorNext(_ iterator: SafePythonObject) throws -> SafePythonObject? {
        let iteratorPtr = getRegisteredPointer(forSafeObj: iterator)
        if let itemPtr = api.pythonIter_Next(iteratorPtr) {
            return newSafePythonObject(fromReturnedPointer: itemPtr)
        }
        try throwSafePythonErrorIfPresent()
        return nil
    }
}
