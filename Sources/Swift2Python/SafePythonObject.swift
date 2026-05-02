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
        
        // MARK: Sequence support
        
        public typealias Element = SafePythonObject
        
        public struct SafePythonIterator: IteratorProtocol {
            private var pyIterator: SafePythonObject
            
            internal init(sequence: SafePythonObject) throws {
                self.pyIterator = try sequence.__iter__()
            }
            
            public mutating func next() -> SafePythonObject? {
                do {
                    return try pyIterator.__next__()
                } catch {
                    // StopIteration or any other error → end of sequence (Swift Iterator contract)
                    return nil
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Sequence conformance is only valid inside withIsolatedContext()")
        public func makeIterator() -> SafePythonIterator {
            do {
                return try SafePythonIterator(sequence: self)
            } catch {
                fatalError("Failed to create iterator for SafePythonObject: \(error)")
            }
        }
        
        // MARK: items() Sequence support
        
        public struct ItemsSequence: Sequence {
            public typealias Element = (key: SafePythonObject, value: SafePythonObject)
            
            private let dictView: SafePythonObject
            
            internal init(dictView: SafePythonObject) {
                self.dictView = dictView
            }
            
            public struct Iterator: IteratorProtocol {
                private var pyIterator: SafePythonObject   // the iterator from items()
                
                internal init(dictView: SafePythonObject) throws {
                    self.pyIterator = try dictView.__iter__()
                }
                
                public mutating func next() -> Element? {
                    do {
                        // Each item from dict.items() is a 2-element tuple in Python
                        let item = try pyIterator.__next__()
                        
                        // Unpack the Python tuple using subscript (already implemented)
                        let key   = item[0]
                        let value = item[1] 
                        
                        return (key: key, value: value)
                    } catch {
                        // StopIteration → end
                        return nil
                    }
                }
            }
            
            public func makeIterator() -> Iterator {
                do {
                    return try Iterator(dictView: dictView)
                } catch {
                    fatalError("Failed to create items() iterator: \(error)")
                }
            }
        }
        
        // The items() function for a dictionary
        @available(*, noasync, message: "items() is only valid inside withIsolatedContext()")
        public func items() -> ItemsSequence {
            ItemsSequence(dictView: self)
        }
        
        // MARK: Bytes support
        
//        public var isBytes: Bool {
//            do {
//                let localInterpreter = interpreter
//                return try localInterpreter.assumeIsolated {
//                    try $0.isBytes(self)
//                }
//            } catch {
//                fatalError("Failed: \(error)")
//            }
//        }
//
//        public var isBytesArray: Bool {
//            do {
//                let localInterpreter = interpreter
//                return try localInterpreter.assumeIsolated {
//                    try $0.isBytesArray(self)
//                }
//            } catch {
//                fatalError("Failed: \(error)")
//            }
//        }
//
//        public var isBytesType: Bool { return isBytes || isBytesArray}
        
        /// Safe copy of Python bytes → Swift Data
        public func asCopiedData() throws -> Data {
            try withUnsafeBytes { Data($0) }
        }
        
        /// Safe copy of Python bytes → Swift `String` (recommended for SVG, JSON, text)
        public func asCopiedString(encoding: String.Encoding = .utf8) throws -> String {
            try withUnsafeBytesString(encoding: encoding) { $0 }
        }
        
        /// Do something with the bytes before the closure ends
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func withUnsafeBytes<R : Sendable>(_ body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) throws -> R {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.withUnsafeBytes(self, body: body)
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        /// Do something with the bytes before the closure ends
        public func withUnsafeBytesString<R : Sendable>( encoding: String.Encoding = .utf8, _ body: @Sendable (String) throws -> R ) throws -> R {
            try withUnsafeBytes { buffer in
                guard let str = String(bytes: buffer, encoding: encoding) else {
                    //throw PythonError.valueError("Cannot decode bytes as \(encoding)")
                    fatalError("placeholder")
                }
                return try body(str)
            }
        }
        
        // MARK: Throwing Comparisons

        
        // A less than that throws.  Operators cause fatalError()
        // so use this whenever anything might go wrong.
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func lessThan(_ other: SafePythonConvertible) throws -> Bool {
            let localInterpreter = interpreter
            let lhs = self
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThanComparable(lhs:lhs, rhs:other.toSafePythonObject(interpreter: $0))
            }
        }
        
        
        // A less than or equal that throws.  Operators cause fatalError()
        // so use this whenever anything might go wrong.
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func lessThanOrEquals(_ other: SafePythonConvertible) throws -> Bool {
            let localInterpreter = interpreter
            let lhs = self
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThanOrEqualComparable(lhs:lhs, rhs:other.toSafePythonObject(interpreter: $0))
            }
        }
        
        
        // A greater than that throws.  Operators cause fatalError()
        // so use this whenever anything might go wrong.
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func greaterThan(_ other: SafePythonConvertible) throws -> Bool {
            let localInterpreter = interpreter
            let lhs = self
            return try localInterpreter.assumeIsolated {
                try $0.syncGreaterThanComparable(lhs:lhs, rhs:other.toSafePythonObject(interpreter: $0))
            }
        }
        
        
        // A greater than or equal that throws.  Operators cause fatalError()
        // so use this whenever anything might go wrong.
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func greaterThanOrEquals(_ other: SafePythonConvertible) throws -> Bool {
            let localInterpreter = interpreter
            let lhs = self
            return try localInterpreter.assumeIsolated {
                try $0.syncGreaterThanOrEqualComparable(lhs:lhs, rhs:other.toSafePythonObject(interpreter: $0))
            }
        }
        
        // MARK: Truth and Logic
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func isTrue() throws -> Bool {
            let localInterpreter = interpreter
            let obj = self
            return try localInterpreter.assumeIsolated {
                try $0.syncIsTrue(obj)
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func isNotTrue() throws -> Bool {
            let localInterpreter = interpreter
            let obj = self
            return try localInterpreter.assumeIsolated {
                try $0.syncIsNotTrue(obj)
            }
        }
        
    }  // end of Safe python object
}
