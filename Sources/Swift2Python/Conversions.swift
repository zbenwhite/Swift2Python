//
//  Conversions.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

// TODO: More
//
// TODO: numpy conversions?
// DONE: UInt
// DONE: Int8
// DONE: Int16
// DONE: Int32
// DONE: Int64
// DONE: UInt8
// DONE: UInt16
// DONE: UInt32
// DONE: UInt64
// DONE: Float  (but improvement possible)
// DONE: Float16   (but improvement possible)
// TODO: Optional?
// TODO: Complex number
// TODO: Set?
// TODO: Dates and Times


// MARK: Asynchronous Mode Conversions

public protocol PendingPythonConvertible: Sendable {
    func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject
}

extension Bool: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(bool: self)
    }
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Bool(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Double(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Float(Double(pythonObject))
    }
}

extension Float {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await Float(pythonObject.convertToDouble())
    }
}

extension Float16: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(double: Double(self))
    }
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Float16(Double(pythonObject))
    }
}

extension Float16 {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await Float16(pythonObject.convertToDouble())
    }
}

extension Int: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(int: Int64(self))
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

extension Int8: PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(int: Int64(self))
    }
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Int8(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Int16(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Int32(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await Int64(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await UInt(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await UInt8(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await UInt16(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await UInt32(pythonObject)
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
    
    public func from(pythonObject: PythonObject) async throws -> Self? {
        return try await UInt64(pythonObject)
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

extension String {
    public init(_ pythonObject: PythonObject) async throws {
        self = try await pythonObject.convertToString()
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
    
    public func from(safePythonObject: PythonInterpreter.SafePythonObject) throws -> Self? {
        return try Bool(safePythonObject)
    }
}

extension Bool {
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    public func from(safePythonObject: PythonInterpreter.SafePythonObject) throws -> Self? {
        return try Double(safePythonObject)
    }
}

extension Double {
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    public func from(safePythonObject: PythonInterpreter.SafePythonObject) throws -> Self? {
        return try Float(Double(safePythonObject))
    }
}

extension Float {
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    public func from(safePythonObject: PythonInterpreter.SafePythonObject) throws -> Self? {
        return try Float16(Double(safePythonObject))
    }
}

extension Float16 {
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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

extension String {
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public init(_ safePythonObject: PythonInterpreter.SafePythonObject) throws {
        self = try safePythonObject.convertToString()
    }
}
