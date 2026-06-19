//
//  SafePythonObject.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

import Foundation

extension PythonInterpreter {
    
    // Because a.name and some other stuff can't be async, they are only available once
    // the object is made inside the actor context
    //
    // SafePythonObject has two forms.
    // Form 1 is like a PythonObject except all the access to PythonInterpreter must be synchronous.
    // Form 2 is a ghost form.  It can't do anything except be turned into Form 1.  It is needed
    // because I want to enable code like safeObject.count = safeObject.count + 1.  This requires
    // a constructor that just takes an int or a float.
    //
    
    @dynamicMemberLookup
    public struct SafePythonObject: SafePythonConvertible, Sequence,
                                    CustomStringConvertible, CustomPlaygroundDisplayConvertible,
                                    CustomReflectable,
                                    ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral,
                                    ExpressibleByStringLiteral, ExpressibleByBooleanLiteral {
        
        
        // MARK: ExpressibleBy
        
        // The state of SafePythonObject.  Is it real or is it just a value to be made real later?
        internal enum State: Sendable {
            case bound(interpreter: PythonInterpreter, id: PythonObjectUniqueID)
            case deferredDouble(Double)
            case deferredInt(Int)
            case deferredString(String)
            case deferredBool(Bool)
        }
        internal let state: State
        
        // Constructors to make arithmetic work
        public init(floatLiteral value: Double) {
            self.state = .deferredDouble(value)
        }
        
        public init(integerLiteral value: Int) {
            self.state = .deferredInt(value)
        }
        
        public init(stringLiteral value: String) {
            self.state = .deferredString(value)
        }
        
        public init(booleanLiteral value: Bool) {
            self.state = .deferredBool(value)
        }
        
        // Materialize the ghost form into a real form
        private func materialize(using context: PythonInterpreter) throws -> SafePythonObject {
            switch state {
            case .bound:
                return self // It's already real
            case .deferredDouble(let val):
                return try context.assumeIsolated {
                    return try $0.convertToSafePython(double:val)
                }
            case .deferredInt(let val):
                return try context.assumeIsolated {
                    return try $0.convertToSafePython(int:Int64(val))
                }
            case .deferredString(let val):
                return try context.assumeIsolated {
                    return try $0.convertToSafePython(string:val)
                }
            case .deferredBool(let val):
                return try context.assumeIsolated {
                    return try $0.convertToSafePython(bool:val)
                }
            }
        }
        
        
            
        public func toSafePythonObject(interpreter: PythonInterpreter) throws -> SafePythonObject {
            return try self.materialize(using: interpreter)
        }
        
        private var error: PythonError?
        
        internal init(interpreter: PythonInterpreter, id: PythonObjectUniqueID) {
            self.state = .bound(interpreter: interpreter, id: id)
            self.error = nil
        }
        
        /// Access the interpreter context. Throws a fatalError if called on a literal before it is bound.
        internal var interpreter: PythonInterpreter {
            guard case let .bound(interp, _) = state else {
                fatalError("SafePythonObject is a ghost: No interpreter found in unbound literal.")
            }
            return interp
        }
        
        /// Access the Python Object ID. Throws a fatalError if called on a literal before it is bound.
        internal var id: PythonInterpreter.PythonObjectUniqueID {
            guard case let .bound(_, id) = state else {
                fatalError("SafePythonObject is a ghost: No ID found in unbound literal.")
            }
            return id
        }
        
        internal var isBoundToPythonInterpreter: Bool {
            switch state {
            case .bound: return true
            default:     return false
            }
        }
        
        public var description: String {
            do {
                return try convertToString()
            } catch {
                return "<unrepresentable Python object: \(error)>"
            }
        }
        
        public var playgroundDescription: Any {
            description
        }
        
        public var customMirror: Mirror {
            Mirror(self, children: [], displayStyle: .struct)
        }
        
        // MARK: Explicit throwing access
        
        // a.name
        public func get(attr: String) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGetObjectAttribute(self, attr)
            }
        }
        
        // a.name = value
        public func set(attr: String, value: any SafePythonConvertible) throws {
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                let realValue = try value.toSafePythonObject(interpreter: $0)
                try $0.syncSetObjectAttribute(self, attr, realValue)
            }
        }
        
        // a[key]
        public func getItem(key: any SafePythonConvertible) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGetObjectItem(obj: self, key: [key])
            }
        }
        
        // a[key] = value
        public func setItem(key: any SafePythonConvertible, newValue: any SafePythonConvertible) throws {
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                try $0.syncSetObjectItem(obj: self, key: [key], newValue: newValue)
            }
        }
        
        // MARK: @dynamicMemberLookup
        
        //
        // a.name
        public subscript(dynamicMember name: String) -> SafePythonObject {
            // a.name
            get {
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.syncGetObjectAttribute(self, name)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            }
            // a.name = value
            set {
                let localInterpreter = interpreter
                localInterpreter.assumeIsolated {
                    do {
                        // newValue might be a literal Double. We make it real here!
                        let realValue = try newValue.materialize(using: $0)
                        try $0.syncSetObjectAttribute(self, name, realValue)
                    } catch {
                        fatalError("Failed to set attribute: \(error)")
                    }
                }
            }
        }
        
        //
        // a[key]
        public subscript(key: SafePythonConvertible...) -> SafePythonObject {
            // a[key]
            get {
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.syncGetObjectItem(obj:self, key:key)
                    } catch {
                        fatalError("Failed to get item: \(error)")
                    }
                }
            }
            // a[key] = value
            set {
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        try $0.syncSetObjectItem(obj:self, key:key, newValue:newValue)
                    } catch {
                        fatalError("Failed to set item: \(error)")
                    }
                }
            }
        }
        
        //
        // a[start:stop:step]
        public subscript(slice: PythonSlice) -> SafePythonObject {
            get {
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        let sliceObject = try $0.convertToSafePython(slice: slice)
                        return try $0.syncGetObjectItem(obj: self, key: [sliceObject])
                    } catch {
                        fatalError("Failed to get slice: \(error)")
                    }
                }
            }
            set {
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        let sliceObject = try $0.convertToSafePython(slice: slice)
                        try $0.syncSetObjectItem(obj: self, key: [sliceObject], newValue: newValue)
                    } catch {
                        fatalError("Failed to set slice: \(error)")
                    }
                }
            }
        }
        
        // MARK: Callable support
        
        public func callAsFunction() throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self)
            }
        }
        
        public func callAsFunction(_ args: any SafePythonConvertible...) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, args:args)
            }
        }
        
        public func callAsFunction(_ args: any SafePythonConvertible...,
                                   kwargs: [String: SafePythonConvertible] = [:]) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, args:args, kwargs:kwargs)
            }
        }
        
        
        // MARK: Bytes support
        
        /// Returns true if this safe Python object is a `bytes` instance.
        ///
        /// Only use this property inside the synchronous, GIL-managed, reference-managed
        /// local `withIsolatedContext` environment.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public var isBytes: Bool {
            get throws {
                try interpreter.assumeIsolated {
                    try $0.isBytes(self)
                }
            }
        }
        
        /// Returns true if this safe Python object is a `bytearray` instance.
        ///
        /// Only use this property inside the synchronous, GIL-managed, reference-managed
        /// local `withIsolatedContext` environment.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public var isByteArray: Bool {
            get throws {
                try interpreter.assumeIsolated {
                    try $0.isByteArray(self)
                }
            }
        }
        
        /// Returns true if this safe Python object supports Python's buffer protocol.
        ///
        /// This includes `bytes`, `bytearray`, `memoryview`, and other objects that can
        /// provide a simple readable buffer.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public var isBytesLike: Bool {
            get throws {
                try interpreter.assumeIsolated {
                    try $0.isBytesLike(self)
                }
            }
        }
        
        /// Returns the number of bytes in this safe Python `bytes` object.
        ///
        /// Only use this property inside the synchronous, GIL-managed, reference-managed
        /// local `withIsolatedContext` environment.
        ///
        /// - Returns: The `bytes` length.
        /// - Throws: `PythonError.bytesConversionFailed` if this object is not `bytes`,
        ///   or `PythonError` if Python raises while reading the size.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public var bytesSize: Int {
            get throws {
                try interpreter.assumeIsolated {
                    try $0.bytesObjectSize(self)
                }
            }
        }
        
        /// Returns the number of bytes in this safe Python `bytearray` object.
        ///
        /// Only use this property inside the synchronous, GIL-managed, reference-managed
        /// local `withIsolatedContext` environment.
        ///
        /// - Returns: The `bytearray` length.
        /// - Throws: `PythonError.bytesConversionFailed` if this object is not `bytearray`,
        ///   or `PythonError` if Python raises while reading the size.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public var byteArraySize: Int {
            get throws {
                try interpreter.assumeIsolated {
                    try $0.byteArrayObjectSize(self)
                }
            }
        }
        
        /// Safe copy of Python bytes → Swift Data
        public func asCopiedData() throws -> Data {
            try withUnsafeBytes { Data($0) }
        }
        
        /// Safe copy of Python bytes → Swift byte array.
        public func asCopiedBytes() throws -> [UInt8] {
            try withUnsafeBytes { Array($0) }
        }
        
        /// Safe copy of Python bytes → Swift byte array.
        ///
        /// This is an alias for `asCopiedBytes()` for callers working with Python `bytearray`.
        public func asCopiedByteArray() throws -> [UInt8] {
            try asCopiedBytes()
        }
        
        /// Safe copy of Python bytes → Swift `String` (recommended for SVG, JSON, text)
        public func asCopiedString(encoding: String.Encoding = .utf8) throws -> String {
            try withUnsafeBytesString(encoding: encoding) { $0 }
        }
        
        /// Do something with the bytes before the closure ends
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func withUnsafeBytes<R : Sendable>(_ body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) throws -> R {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.withUnsafeBytes(self, body: body)
            }
        }
        
        /// Do something with the bytes before the closure ends
        public func withUnsafeBytesString<R : Sendable>( encoding: String.Encoding = .utf8, _ body: @Sendable (String) throws -> R ) throws -> R {
            try withUnsafeBytes { buffer in
                guard let str = String(bytes: buffer, encoding: encoding) else {
                    throw PythonError.bytesConversionFailed(expected: "bytes decodable as \(encoding)", actual: nil)
                }
                return try body(str)
            }
        }
        
        // MARK: Truth and Logic
        
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func isTrue() throws -> Bool {
            let localInterpreter = interpreter
            let obj = self
            return try localInterpreter.assumeIsolated {
                try $0.syncIsTrue(obj)
            }
        }
        
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func isNotTrue() throws -> Bool {
            let localInterpreter = interpreter
            let obj = self
            return try localInterpreter.assumeIsolated {
                try $0.syncIsNotTrue(obj)
            }
        }
        
    }  // end of Safe python object
}
