//
//  Conversions.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

// This file defines the public Swift-to-Python conversion protocols and the
// scalar Python-to-Swift initializer conveniences. Container conformances live
// in Container.swift, while the interpreter implementations that call CPython
// conversion APIs live in PythonInterpreter+Convert.swift.
//
// The intended public spelling is:
//
//     let pyValue = try await swiftValue.toPythonObject(interpreter: python)
//     let swiftValue = try await Int(pyValue)
//
// Use SafePythonConvertible and the synchronous initializers only inside an
// isolated interpreter context.

// MARK: Asynchronous Mode Conversions

/// A Swift value that can be converted to a managed Python object asynchronously.
///
/// Use this protocol for values passed into `PythonObject` APIs from normal async
/// Swift code. Conforming types create a `PythonObject` owned by the supplied
/// interpreter. Swift2Python provides conformances for common scalar and
/// container types.
public protocol PendingPythonConvertible: Sendable {
    /// Converts this value to a managed Python object using the supplied interpreter.
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject
}

extension Bool: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(bool: self)
    }
}

extension Bool {
    /// Creates a Swift Boolean from a Python truth value.
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
    /// Creates a Swift double from a Python numeric value.
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
    /// Creates a Swift single-precision float from a Python numeric value.
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
    /// Creates a Swift half-precision float from a Python numeric value.
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
    /// Creates a Swift integer from a Python integer.
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
    /// Creates an 8-bit Swift integer from a Python integer.
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
    /// Creates a 16-bit Swift integer from a Python integer.
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
    /// Creates a 32-bit Swift integer from a Python integer.
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
    /// Creates a 64-bit Swift integer from a Python integer.
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
    /// Creates an unsigned Swift integer from a Python integer.
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
    /// Creates an unsigned 8-bit Swift integer from a Python integer.
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
    /// Creates an unsigned 16-bit Swift integer from a Python integer.
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
    /// Creates an unsigned 32-bit Swift integer from a Python integer.
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
    /// Creates an unsigned 64-bit Swift integer from a Python integer.
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
    /// Creates a Swift string from a Python string.
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToString()
    }
}

// MARK: -
// MARK: Synchronous Mode Conversions

/// A Swift value that can be converted to a Python object inside an isolated context.
///
/// Use this protocol from `PythonInterpreter.withIsolatedContext(_:)` and other
/// synchronous APIs that already hold the interpreter isolation needed to work
/// with `SafePythonObject`. Conforming types create a `SafePythonObject` owned by
/// the supplied interpreter.
public protocol SafePythonConvertible: Sendable {
    /// Converts this value to a safe Python object using the supplied interpreter.
    func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject
}

extension Bool: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(bool: self)
        }
    }
}

extension Bool {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    /// Creates a Swift Boolean from a safe Python truth value.
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToBool()
    }
}

extension Double: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(double: self)
        }
    }
}

extension Double {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    /// Creates a Swift double from a safe Python numeric value.
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
    /// Creates a Swift single-precision float from a safe Python numeric value.
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
    /// Creates a Swift half-precision float from a safe Python numeric value.
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
    /// Creates a Swift integer from a safe Python integer.
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
    /// Creates an 8-bit Swift integer from a safe Python integer.
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
    /// Creates a 16-bit Swift integer from a safe Python integer.
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
    /// Creates a 32-bit Swift integer from a safe Python integer.
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToInt32()
    }
}

extension Int64: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(int: self)
        }
    }
}

extension Int64 {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    /// Creates a 64-bit Swift integer from a safe Python integer.
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
    /// Creates an unsigned Swift integer from a safe Python integer.
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
    /// Creates an unsigned 8-bit Swift integer from a safe Python integer.
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
    /// Creates an unsigned 16-bit Swift integer from a safe Python integer.
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
    /// Creates an unsigned 32-bit Swift integer from a safe Python integer.
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
    /// Creates an unsigned 64-bit Swift integer from a safe Python integer.
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToUInt64()
    }
}

extension String: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(string: self)
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
    /// Creates a Swift string from a safe Python string.
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToString()
    }
}
