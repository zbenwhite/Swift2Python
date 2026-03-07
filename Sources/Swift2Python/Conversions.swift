//
//  Conversions.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

public protocol PendingPythonConvertible: Sendable {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject
}

extension Bool: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertBoolToPython(self)
    }
}

extension Double: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertDoubleToPython(self)
    }
}

extension Int: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertIntToPython(self)
    }
}

extension String: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertStringToPython(self)
    }
}

extension Array : PendingPythonConvertible where Element : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertArrayToPython(self)
    }
}

extension Dictionary : PendingPythonConvertible where Key : PendingPythonConvertible & Hashable, Value : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertDictionaryToPython(self)
    }
}

extension Range : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        fatalError("shut up xcode")
        //try await interpreter.convertRangeToPython(self)
    }
}

extension PartialRangeFrom : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        fatalError("shut up xcode")
        //try await interpreter.convertPartialRangeToPython(self)
    }
}

extension PartialRangeUpTo : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        fatalError("shut up xcode")
        //try await interpreter.convertPartialRangeToPython(self)
    }
}
