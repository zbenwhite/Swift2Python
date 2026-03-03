//
//  Conversions.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

protocol PendingPythonConvertible {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject
}

extension Bool: PendingPythonConvertible {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertBoolToPython(self)
    }
}

extension Double: PendingPythonConvertible {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertDoubleToPython(self)
    }
}

extension Int: PendingPythonConvertible {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertIntToPython(self)
    }
}

extension String: PendingPythonConvertible {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertStringToPython(self)
    }
}
