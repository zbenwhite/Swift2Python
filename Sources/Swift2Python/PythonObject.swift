//
// PythonObject.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

import Foundation

@dynamicMemberLookup
public struct PythonObject: Sendable, PendingPythonConvertible {
    
    // This gets de-initialized as soon as the last copy of the PythonObject
    // goes out of scope.  It's a woraround for deinit not working on PythonObject.
    private final class LifetimeTracker: Sendable {
        let id: PythonInterpreter.PythonObjectUniqueID
        let interpreter: PythonInterpreter
        
        init(id: PythonInterpreter.PythonObjectUniqueID, interpreter: PythonInterpreter) {
            self.id = id
            self.interpreter = interpreter
        }
        
        deinit {
            let localID = id
            let localInterpreter = interpreter
            Task {
                try? await localInterpreter.releasePythonObject(forPythonObjectID: localID)
            }
        }
    }
    
    // Temporary object result of attribute access.  Methods can be called asynchronously on PythonObject this way.
    public struct CallablePythonObject {
        private let obj: PythonObject
        private let method: String
        
        public init (object: PythonObject, methodName: String) {
            self.obj = object
            self.method = methodName
        }
        
        public func callAsFunction(_ args: any PendingPythonConvertible...) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object:obj, methodName:method, collectedArgs: args)
        }
        
        public func callAsFunction(_ args: any PendingPythonConvertible..., kwargs: [String: PendingPythonConvertible] = [:]) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object:obj, methodName:method, collectedArgs: args, kwargs:kwargs)
        }
    }
    
    internal let id: PythonInterpreter.PythonObjectUniqueID
    private let interpreter: PythonInterpreter
    private let lifetime: LifetimeTracker
    
    internal init(id: PythonInterpreter.PythonObjectUniqueID, interpreter: PythonInterpreter) {
        self.id = id
        self.interpreter = interpreter
        self.lifetime = LifetimeTracker(id: id, interpreter: interpreter)
    }
    
    // Implement PendingPythonConvertible protocol
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        return self
    }
    
    // a.name
    // (can't do actual a.name because we need try await and they're not available for a.name)
    public func get(attr: String) async throws -> PythonObject {
        return try await interpreter.get(object: self, attribute: attr)
    }
    
    // a.name = value
    // (can't do actual a.name = value because we need try await ...)
    public func set(attr: String, value: PendingPythonConvertible) async throws {
        try await interpreter.set(object: self, attribute: attr, value: value.toPythonObject(interpreter: self.interpreter))
    }
    
    //
    // a.call_a_function() can be implemented.
    public subscript(dynamicMember name: String) -> CallablePythonObject {
        // a.call_a_function()
        get {
            return CallablePythonObject(object: self, methodName: name)
        }
    }
    
    // MARK: Bytes support
    
    /// Returns true if this object is a Python `bytes` instance.
    //    public func isBytes() async throws -> Bool {
    //        try await interpreter.isBytes(self)
    //    }
    //
    //    /// Returns true if this object is a Python `bytes` or an array of `bytes`.
    //    public func isBytesArray() async throws -> Bool {
    //        try await interpreter.isBytesArray(self)
    //    }
    //
    //    /// Returns true if this object is either `bytes` or an array of `bytes`.
    //    public func isBytesType() async throws -> Bool {
    //        if try await self.isBytes() {
    //            return true
    //        } else {
    //            return try await self.isBytesArray()
    //        }
    //    }
    
    /// Safe copy of Python bytes → Swift Data
    public func asCopiedData() async throws -> Data {
        try await withUnsafeBytes { Data($0) }
    }
    
    /// Safe copy of Python bytes → Swift `String` (recommended for SVG, JSON, text)
    public func asCopiedString(encoding: String.Encoding = .utf8) async throws -> String {
        try await withUnsafeBytesString(encoding: encoding) { $0 }
    }
    
    /// Do something with the bytes before the closure ends
    public func withUnsafeBytes<R : Sendable>(_ body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) async throws -> R {
        do {
            return try await interpreter.withUnsafeBytes(self, body: body)
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    /// Do something with the bytes before the closure ends
    public func withUnsafeBytesString<R : Sendable>( encoding: String.Encoding = .utf8, _ body: @Sendable (String) throws -> R ) async throws -> R {
        try await withUnsafeBytes { buffer in
            guard let str = String(bytes: buffer, encoding: encoding) else {
                //throw PythonError.valueError("Cannot decode bytes as \(encoding)")
                fatalError("placeholder")
            }
            return try body(str)
        }
    }
    
    public func convertToDouble() async throws -> Double {
        return try await interpreter.convertToDouble(self)
    }
    
    public func convertToInt() async throws -> Int {
        return try await interpreter.convertToInt(self)
    }
    
    public func convertToInt8() async throws -> Int8 {
        return try await interpreter.convertToInt8(self)
    }
    
    public func convertToInt16() async throws -> Int16 {
        return try await interpreter.convertToInt16(self)
    }
    
    public func convertToInt32() async throws -> Int32 {
        return try await interpreter.convertToInt32(self)
    }
    
    public func convertToInt64() async throws -> Int64 {
        return try await interpreter.convertToInt64(self)
    }
    
    public func convertToUInt() async throws -> UInt {
        return try await interpreter.convertToUInt(self)
    }
    
    public func convertToUInt8() async throws -> UInt8 {
        return try await interpreter.convertToUInt8(self)
    }
    
    public func convertToUInt16() async throws -> UInt16 {
        return try await interpreter.convertToUInt16(self)
    }
    
    public func convertToUInt32() async throws -> UInt32 {
        return try await interpreter.convertToUInt32(self)
    }
    
    public func convertToUInt64() async throws -> UInt64 {
        return try await interpreter.convertToUInt64(self)
    }
    
    public func convertToString() async throws -> String {
        return try await interpreter.convertToString(self)
    }
    
    public func equals(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.equals(lhs: self, rhs: other)
    }
    
    public func notEquals(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.notEquals(lhs: self, rhs: other)
    }
    
    public func lessThan(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.lessThan(lhs: self, rhs: other)
    }
    
    public func lessThanOrEqual(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.lessThanOrEqual(lhs: self, rhs: other)
    }
    
    public func greaterThan(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.greaterThan(lhs: self, rhs: other)
    }
    
    public func greaterThanOrEqual(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.greaterThanOrEqual(lhs: self, rhs: other)
    }
    
    public func add(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.add(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    public func addInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.addInPlace(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    public func subtract(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.subtract(minuend: self, subtrahend: other.toPythonObject(interpreter: interpreter))
    }
    
    public func subtractInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.subtractInPlace(minuend: self, subtrahend: other.toPythonObject(interpreter: interpreter))
    }
    
    public func multiply(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.multiply(self, other.toPythonObject(interpreter: interpreter))
    }
    
    public func multiplyInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.multiplyInPlace(self, other.toPythonObject(interpreter: interpreter))
    }
    
    public func divide(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.divide(dividend: self, divisor: other.toPythonObject(interpreter: interpreter))
    }
    
    public func divideInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.divideInPlace(self, other.toPythonObject(interpreter: interpreter))
    }
    
    public func isTrue() async throws -> Bool {
        return try await interpreter.isTrue(self)
    }
    
    public func isNotTrue() async throws -> Bool {
        return try await interpreter.isNotTrue(self)
    }
}
