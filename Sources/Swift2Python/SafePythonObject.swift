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
    
    @dynamicCallable
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
        
        /// Gets a Python attribute by name inside an isolated interpreter context.
        ///
        /// Use this throwing API inside `PythonInterpreter.withIsolatedContext` when
        /// missing attributes or Python exceptions should be handled by the caller. For
        /// convenience-only code where failure is a programmer error, safe dynamic-member
        /// syntax such as `object.name` is also available.
        ///
        /// - Parameter attr: The Python attribute name to read.
        /// - Returns: The safe Python object stored in the named attribute.
        /// - Throws: `PythonError.safePythonException` inside the isolated context when
        ///   Python raises, including missing attributes.
        public func get(attr: String) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGetObjectAttribute(self, attr)
            }
        }
        
        /// Sets a Python attribute by name inside an isolated interpreter context.
        ///
        /// Use this throwing API inside `PythonInterpreter.withIsolatedContext` when
        /// assignment failure should be recoverable. The value is materialized into a
        /// Python object before assignment, so Swift literals can be used directly.
        ///
        /// - Parameters:
        ///   - attr: The Python attribute name to set.
        ///   - value: The Swift or safe Python value to convert and assign.
        /// - Throws: `PythonError.safePythonException` inside the isolated context when
        ///   Python raises, including read-only attribute errors, or another `PythonError`
        ///   if conversion fails.
        public func set(attr: String, value: any SafePythonConvertible) throws {
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                let realValue = try value.toSafePythonObject(interpreter: $0)
                try $0.syncSetObjectAttribute(self, attr, realValue)
            }
        }
        
        /// Gets an item through Python's item protocol inside an isolated context.
        ///
        /// This is the recoverable throwing form of Python `object[key]` for
        /// ``SafePythonObject``. Use it inside `PythonInterpreter.withIsolatedContext`
        /// when missing keys, out-of-range indexes, or exceptions from custom
        /// `__getitem__` implementations should be handled by the caller. For
        /// concise code where failure is a programmer error, safe subscript syntax
        /// such as `object[key]` is also available.
        ///
        /// - Parameter key: The Swift or safe Python key to convert and pass to Python.
        /// - Returns: The safe Python object returned by `object[key]`.
        /// - Throws: `PythonError.safePythonException` inside the isolated context
        ///   when Python raises, or another `PythonError` if key conversion fails.
        public func getItem(key: any SafePythonConvertible) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGetObjectItem(obj: self, key: [key])
            }
        }
        
        /// Sets an item through Python's item protocol inside an isolated context.
        ///
        /// This is the recoverable throwing form of Python `object[key] = value`
        /// for ``SafePythonObject``. Use it for mappings, mutable sequences, custom
        /// Python objects that implement `__setitem__`, and recoverable slice
        /// assignment. The key and value are materialized into Python objects before
        /// assignment, so Swift literals can be used directly.
        ///
        /// - Parameters:
        ///   - key: The Swift or safe Python key to convert and pass to Python.
        ///   - newValue: The Swift or safe Python value to convert and assign.
        /// - Throws: `PythonError.safePythonException` inside the isolated context
        ///   when Python raises, or another `PythonError` if conversion fails.
        public func setItem(key: any SafePythonConvertible, newValue: any SafePythonConvertible) throws {
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                try $0.syncSetObjectItem(obj: self, key: [key], newValue: newValue)
            }
        }
        
        // MARK: @dynamicMemberLookup
        
        /// Gets or sets a Python attribute using Swift dynamic-member syntax.
        ///
        /// This powers Python-like safe syntax inside `withIsolatedContext`, such as
        /// `object.name` and `object.name = "Ada"`. This subscript is intentionally
        /// convenience-oriented: it traps with `fatalError` if Python raises or conversion
        /// fails. Use the explicit throwing `get(attr:)` and `set(attr:value:)` methods
        /// when missing attributes, read-only attributes, or conversion failures are part
        /// of normal control flow.
        ///
        /// - Parameter name: The Python attribute name supplied by Swift's dynamic-member lookup.
        /// - Returns: The safe Python object stored in the named attribute.
        public subscript(dynamicMember name: String) -> SafePythonObject {
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
        
        /// Gets or sets an item using Python-like subscript syntax.
        ///
        /// This powers convenient syntax inside `withIsolatedContext`, such as
        /// `object[key]`, `object[key] = value`, and `object[x, y]` for Python
        /// tuple-key indexing. When more than one key is supplied, Swift2Python
        /// builds a Python tuple and passes that tuple as the single Python key,
        /// matching Python's `object[x, y]` behavior.
        ///
        /// This subscript is convenience-oriented and cannot throw. It traps with
        /// `fatalError` if Python raises or conversion fails. Use the explicit
        /// throwing ``getItem(key:)`` and ``setItem(key:newValue:)`` methods when
        /// item failures are part of normal control flow.
        ///
        /// - Parameter key: One or more keys supplied by Swift subscript syntax.
        /// - Returns: The safe Python object returned by Python item lookup.
        public subscript(key: SafePythonConvertible...) -> SafePythonObject {
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
        
        /// Gets or sets an item using a Python slice descriptor.
        ///
        /// This powers `object[.slice(start, stop, step:)]` inside
        /// `withIsolatedContext`. It is the safe-object convenience form for
        /// Python `object[start:stop:step]`. `nil` slice bounds map to Python
        /// `None`, so `.slice(nil, nil, step: -1)` represents `[::-1]`.
        ///
        /// This subscript is convenience-oriented and cannot throw. It traps with
        /// `fatalError` if Python raises or conversion fails, including invalid
        /// slice assignments. Use the explicit throwing ``getItem(key:)`` and
        /// ``setItem(key:newValue:)`` methods with ``PythonSlice`` when slice
        /// failures should be recoverable.
        ///
        /// - Parameter slice: The Python slice descriptor.
        /// - Returns: The safe Python object returned by Python slice lookup.
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
        
        /// Calls this Python object as a callable with no arguments.
        ///
        /// Use this inside `PythonInterpreter.withIsolatedContext` for synchronous,
        /// GIL-managed calls to Python functions, classes, bound methods, callable
        /// instances, and other callable objects. For inline syntax, prefer `try object()`.
        ///
        /// - Returns: The safe Python object returned by the callable.
        /// - Throws: `PythonError` if the object is not callable or Python raises during the call.
        public func call() throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self)
            }
        }
        
        /// Calls this Python object as a callable with positional arguments.
        ///
        /// Use this explicit form inside `withIsolatedContext` when forwarding arguments
        /// or when a named throwing API is clearer than dynamic call syntax. For normal
        /// inline calls, prefer `try object(1, 2)`.
        ///
        /// - Parameter args: Positional arguments converted to Python objects before the call.
        /// - Returns: The safe Python object returned by the callable.
        /// - Throws: `PythonError` if conversion fails, the object is not callable, or Python raises.
        public func call(_ args: any SafePythonConvertible...) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, args:args)
            }
        }
        
        /// Calls this Python object as a callable with positional and dictionary keyword arguments.
        ///
        /// Use this explicit form when keyword arguments are already stored in a Swift
        /// dictionary. For inline keyword calls inside `withIsolatedContext`, prefer
        /// `try object(arg, name: value)`.
        ///
        /// - Parameters:
        ///   - args: Positional arguments converted to Python objects before the call.
        ///   - kwargs: Keyword arguments converted into a Python `dict`.
        /// - Returns: The safe Python object returned by the callable.
        /// - Throws: `PythonError` if conversion, keyword conversion, or the Python call fails.
        public func call(_ args: any SafePythonConvertible...,
                         kwargs: [String: any SafePythonConvertible]) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, args:args, kwargs:kwargs)
            }
        }
        
        /// Calls this Python object as a callable with positional and ordered keyword arguments.
        ///
        /// Use this overload when preserving keyword order matters or when duplicate
        /// keyword detection should happen before Python receives the call. Empty keyword
        /// names are not valid in this explicit kwargs form.
        ///
        /// - Parameters:
        ///   - args: Positional arguments converted to Python objects before the call.
        ///   - kwargs: Ordered keyword arguments converted into a Python `dict`.
        /// - Returns: The safe Python object returned by the callable.
        /// - Throws: `PythonError.valueError` for invalid keyword pairs, or `PythonError`
        ///   if conversion or the Python call fails.
        public func call(_ args: any SafePythonConvertible...,
                         kwargs: KeyValuePairs<String, any SafePythonConvertible>) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, args:args, kwargs:kwargs)
            }
        }
        
        /// Implements `@dynamicCallable` positional calls for safe Python objects.
        ///
        /// This powers syntax such as `try function(1, 2)` inside `withIsolatedContext`.
        /// Call this method directly only when manually forwarding dynamic-call arguments.
        ///
        /// - Parameter args: Positional arguments supplied by Swift's dynamic-call lowering.
        /// - Returns: The safe Python object returned by the callable.
        /// - Throws: `PythonError` if conversion or the Python call fails.
        public func dynamicallyCall(withArguments args: [any SafePythonConvertible]) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, args:args)
            }
        }
        
        /// Implements `@dynamicCallable` positional and keyword calls for safe Python objects.
        ///
        /// This powers syntax such as `try function(1, name: value)` inside
        /// `withIsolatedContext`. Swift represents positional arguments with an empty
        /// keyword label, so this method validates that positional arguments do not
        /// appear after keyword arguments and that keyword labels are not duplicated.
        ///
        /// - Parameter args: Dynamic-call arguments supplied by Swift.
        /// - Returns: The safe Python object returned by the callable.
        /// - Throws: `PythonError.valueError` for invalid argument ordering or duplicate
        ///   keywords, or `PythonError` if conversion or the Python call fails.
        public func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, any SafePythonConvertible>) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, dynamicArguments:args)
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
        
        /// Returns this object's Python truth value.
        ///
        /// Deferred Swift literals use Python's built-in truthiness rules without first
        /// materializing a Python object. Bound objects delegate to CPython's
        /// `PyObject_IsTrue`, so custom Python `__bool__` and `__len__` behavior is preserved.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func isTrue() throws -> Bool {
            switch state {
            case .deferredDouble(let value):
                return value != 0.0
            case .deferredInt(let value):
                return value != 0
            case .deferredString(let value):
                return !value.isEmpty
            case .deferredBool(let value):
                return value
            case .bound:
                let localInterpreter = interpreter
                let obj = self
                return try localInterpreter.assumeIsolated {
                    try $0.syncIsTrue(obj)
                }
            }
        }
        
        /// Returns whether this object is falsey under Python truthiness rules.
        ///
        /// Deferred Swift literals use Python's built-in truthiness rules without first
        /// materializing a Python object. Bound objects delegate to CPython's `PyObject_Not`,
        /// so custom Python `__bool__` and `__len__` behavior is preserved.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func isNotTrue() throws -> Bool {
            switch state {
            case .deferredDouble(let value):
                return value == 0.0
            case .deferredInt(let value):
                return value == 0
            case .deferredString(let value):
                return value.isEmpty
            case .deferredBool(let value):
                return !value
            case .bound:
                let localInterpreter = interpreter
                let obj = self
                return try localInterpreter.assumeIsolated {
                    try $0.syncIsNotTrue(obj)
                }
            }
        }
        
        /// Returns the Python `and` result for this object and an already-created right operand.
        ///
        /// Python `and` returns one of its operands, not a `Bool`: it returns `self` when
        /// `self` is falsey, otherwise it returns `rhs`. Use the closure overload when the
        /// right operand should not be created unless needed.
        ///
        /// - Parameter rhs: The right operand.
        /// - Returns: `self` if `self` is falsey; otherwise `rhs`.
        /// - Throws: `PythonError.safePythonException` if Python raises while evaluating truthiness.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func logicalAnd(_ rhs: SafePythonObject) throws -> SafePythonObject {
            if try isTrue() {
                return rhs
            }
            return self
        }
        
        /// Returns the Python `and` result for this object and a lazily-created right operand.
        ///
        /// Python `and` short-circuits. The `rhs` closure is only evaluated when `self` is
        /// truthy, and the result is one of the operands rather than a Swift `Bool`.
        ///
        /// - Parameter rhs: A closure that creates the right operand only when needed.
        /// - Returns: `self` if `self` is falsey; otherwise the result of `rhs`.
        /// - Throws: `PythonError.safePythonException` if Python raises while evaluating truthiness,
        ///   or any error thrown by `rhs`.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func logicalAnd(_ rhs: () throws -> SafePythonObject) throws -> SafePythonObject {
            if try isTrue() {
                return try rhs()
            }
            return self
        }
        
        /// Returns the Python `or` result for this object and an already-created right operand.
        ///
        /// Python `or` returns one of its operands, not a `Bool`: it returns `self` when
        /// `self` is truthy, otherwise it returns `rhs`. Use the closure overload when the
        /// right operand should not be created unless needed.
        ///
        /// - Parameter rhs: The right operand.
        /// - Returns: `self` if `self` is truthy; otherwise `rhs`.
        /// - Throws: `PythonError.safePythonException` if Python raises while evaluating truthiness.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func logicalOr(_ rhs: SafePythonObject) throws -> SafePythonObject {
            if try isTrue() {
                return self
            }
            return rhs
        }
        
        /// Returns the Python `or` result for this object and a lazily-created right operand.
        ///
        /// Python `or` short-circuits. The `rhs` closure is only evaluated when `self` is
        /// falsey, and the result is one of the operands rather than a Swift `Bool`.
        ///
        /// - Parameter rhs: A closure that creates the right operand only when needed.
        /// - Returns: `self` if `self` is truthy; otherwise the result of `rhs`.
        /// - Throws: `PythonError.safePythonException` if Python raises while evaluating truthiness,
        ///   or any error thrown by `rhs`.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public func logicalOr(_ rhs: () throws -> SafePythonObject) throws -> SafePythonObject {
            if try isTrue() {
                return self
            }
            return try rhs()
        }
        
    }  // end of Safe python object
}
