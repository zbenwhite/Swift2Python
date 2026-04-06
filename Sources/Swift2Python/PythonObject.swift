//
// PythonObject.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

import Foundation

@dynamicMemberLookup
public struct PythonObject: Sendable, PendingPythonConvertible {
    
    /// Helper to bridge Swift ARC to the Actor's registry
    private final class LifetimeTracker: Sendable {
        let id: PythonInterpreter.PythonObjectUniqueID
        let interpreter: PythonInterpreter

        init(id: PythonInterpreter.PythonObjectUniqueID, interpreter: PythonInterpreter) {
            self.id = id
            self.interpreter = interpreter
        }

        deinit {
            let capturedID = id
            let capturedInterpreter = interpreter
            Task {
                try? await capturedInterpreter.releaseHandle(capturedID)
            }
        }
    }
    
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

    init(id: PythonInterpreter.PythonObjectUniqueID, interpreter: PythonInterpreter) {
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
    
    public func convertToUInt() async throws -> UInt {
        return try await interpreter.convertToUInt(self)
    }
}

