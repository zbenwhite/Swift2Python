//
//  Conversions.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//


// MARK: Asynchronous Mode Conversions

public protocol PendingPythonConvertible: Sendable {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject
}

extension Bool: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(bool: self)
    }
}

extension Bool {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToBool()
    }
}

extension Double: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(double: self)
    }
}

extension Double {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToDouble()
    }
}

extension Float: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(double: Double(self))
    }
}

extension Float {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToFloat()
    }
}

extension Float16: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(double: Double(self))
    }
}

extension Float16 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToFloat16()
    }
}

extension Int: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(int: Int64(self))
    }
}

extension Int {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToInt()
    }
}

extension Int8: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(int: Int64(self))
    }
}

extension Int8 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToInt8()
    }
}

extension Int16: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(int: Int64(self))
    }
}

extension Int16 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToInt16()
    }
}

extension Int32: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(int: Int64(self))
    }
}

extension Int32 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToInt32()
    }
}

extension Int64: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(int: self)
    }
}

extension Int64 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToInt64()
    }
}

extension UInt: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(uint: UInt64(self))
    }
}

extension UInt {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToUInt()
    }
}

extension UInt8: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(uint: UInt64(self))
    }
}

extension UInt8 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToUInt8()
    }
}

extension UInt16: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(uint: UInt64(self))
    }
}

extension UInt16 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToUInt16()
    }
}

extension UInt32: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(uint: UInt64(self))
    }
}

extension UInt32 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToUInt32()
    }
}

extension UInt64: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(uint: self)
    }
}

extension UInt64 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToUInt64()
    }
}


extension String: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(string: self)
    }
}

extension Optional: PendingPythonConvertible where Wrapped: PendingPythonConvertible {
    /// Converts this Swift optional to Python.
    ///
    /// `nil` becomes Python `None`; `.some(value)` is converted using the wrapped
    /// value's `PendingPythonConvertible` conformance.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        switch self {
        case .some(let value):
            try await value.toPythonObject(interpreter: interpreter)
        case .none:
            try await interpreter.convertToPythonNone()
        }
    }
}

extension String {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToString()
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

extension Bool {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToBool()
    }
}

extension Double: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(double:self)
        }
    }
}

extension Double {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToDouble()
    }
}

extension Float: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(double: Double(self))
        }
    }
}

extension Float {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToFloat()
    }
}

extension Float16: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(double: Double(self))
        }
    }
}

extension Float16 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToFloat16()
    }
}

extension Int: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(int: Int64(self))
        }
    }
}

extension Int {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToInt()
    }
}

extension Int8: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(int: Int64(self))
        }
    }
}

extension Int8 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToInt8()
    }
}

extension Int16: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(int: Int64(self))
        }
    }
}

extension Int16 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToInt16()
    }
}

extension Int32: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(int: Int64(self))
        }
    }
}

extension Int32 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToInt32()
    }
}

extension Int64: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(int:self)
        }
    }
}

extension Int64 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToInt64()
    }
}

extension UInt: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(uint: UInt64(self))
        }
    }
}

extension UInt {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToUInt()
    }
}

extension UInt8: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(uint: UInt64(self))
        }
    }
}

extension UInt8 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToUInt8()
    }
}

extension UInt16: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(uint: UInt64(self))
        }
    }
}

extension UInt16 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToUInt16()
    }
}

extension UInt32: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(uint: UInt64(self))
        }
    }
}

extension UInt32 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToUInt32()
    }
}

extension UInt64: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(uint: self)
        }
    }
}

extension UInt64 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToUInt64()
    }
}

extension String: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(string:self)
        }
    }
}

extension Optional: SafePythonConvertible where Wrapped: SafePythonConvertible {
    /// Converts this Swift optional to Python inside an isolated context.
    ///
    /// `nil` becomes Python `None`; `.some(value)` is converted using the wrapped
    /// value's `SafePythonConvertible` conformance.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            switch self {
            case .some(let value):
                try value.toSafePythonObject(interpreter: $0)
            case .none:
                try $0.convertToSafePythonNone()
            }
        }
    }
}

extension String {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToString()
    }
}
