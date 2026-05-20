//
//  Container.swift
//  Swift2Python
//
//  Created by Ben White on 5/3/26.
//

import Foundation

extension Array : PendingPythonConvertible where Element : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(array: self)
    }
}

extension Dictionary : PendingPythonConvertible where Key : PendingPythonConvertible & Hashable, Value : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(dictionary: self)
    }
}

extension Dictionary : SafePythonConvertible where Key : SafePythonConvertible & Hashable, Value : SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(dictionary:self)
        }
    }
}

extension Range : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("placeholder")
        //try await interpreter.convertRangeToPython(self)
    }
}

extension PartialRangeFrom : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("placeholder")
        //try await interpreter.convertPartialRangeToPython(self)
    }
}

extension PartialRangeUpTo : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("placeholder")
        //try await interpreter.convertPartialRangeToPython(self)
    }
}
