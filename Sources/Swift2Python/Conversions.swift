//
//  Conversions.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

// TODO: More
//
// - numpy conversions?
// - UInt
// - Int8
// - Int16
// - Int32
// - Int64
// - UInt8
// - UInt16
// - UInt32
// - UInt64
// - Float
// - Optional?
// - 


// MARK: Asynchronous Mode Conversions

public protocol PendingPythonConvertible: Sendable {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject
}

extension Bool: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(bool: self)
    }
}

extension Double: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(double: self)
    }
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Double(pythonObject)
    }
}

extension Double {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToDouble()
    }
}

extension Int: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(int: self)
    }
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Int(pythonObject)
    }
}

extension Int {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToInt()
    }
}


extension String: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(string: self)
    }
}

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

extension Range : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("shut up xcode")
        //try await interpreter.convertRangeToPython(self)
    }
}

extension PartialRangeFrom : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("shut up xcode")
        //try await interpreter.convertPartialRangeToPython(self)
    }
}

extension PartialRangeUpTo : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("shut up xcode")
        //try await interpreter.convertPartialRangeToPython(self)
    }
}

// MARK: -
// MARK: Synchronous Mode Conversions


public protocol SafePythonConvertible: Sendable {
    func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject
}

extension Bool: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(bool:self)
        }
    }
}

extension Double: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(double:self)
        }
    }
}

extension Int: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(int:self)
        }
    }
}

extension String: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(string:self)
        }
    }
}
