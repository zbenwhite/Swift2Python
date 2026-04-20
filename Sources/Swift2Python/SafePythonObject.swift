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
        
        public func convertToDouble() throws -> Double {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToDouble(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                return val
            case .deferredInt(let val):
                return Double(val)
            case .deferredString(let val):
                // mimic python string conversion to Double
                guard let double = Double(val) else {
                    fatalError("placeholder")
                }
                return double
            case .deferredBool(let val):
                return val ? 1.0 : 0.0
            }
        }
        
        public func convertToInt() throws -> Int {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredInt(let val):
                return val
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                guard let intValue = Int(val) else {   // Swift Int(String) is close but slightly stricter than Python on some edge cases
                    // Optional improvement: try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let double = Double(val), double.isFinite {
                        return Int(double)             // this would make int("3.14") == 3 (more forgiving)
                    }
                    fatalError("placeholder")
                }
                return intValue
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToInt8() throws -> Int8 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt8(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int8(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = Int8(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                let iVal: Int
                if let intValue = Int(val) {
                    iVal = intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    iVal = Int(double)
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
                if let i = Int8(exactly:iVal) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToInt16() throws -> Int16 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt16(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int16(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = Int16(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                let iVal: Int
                if let intValue = Int(val) {
                    iVal = intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    iVal = Int(double)
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
                if let i = Int16(exactly:iVal) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToInt32() throws -> Int32 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt32(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int32(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = Int32(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                let iVal: Int
                if let intValue = Int(val) {
                    iVal = intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    iVal = Int(double)
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
                if let i = Int32(exactly:iVal) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToInt64() throws -> Int64 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt64(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int64(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = Int64(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = Int64(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = Int64(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt() throws -> UInt {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt(self)
                }
            case .deferredDouble(let val):
                if let i = UInt(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt8() throws -> UInt8 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt8(self)
                }
            case .deferredDouble(let val):
                if let i = UInt8(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt8(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt8(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt8(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt16() throws -> UInt16 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt16(self)
                }
            case .deferredDouble(let val):
                if let i = UInt16(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt16(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt16(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt16(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt32() throws -> UInt32 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt32(self)
                }
            case .deferredDouble(let val):
                if let i = UInt32(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt32(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt32(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt32(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt64() throws -> UInt64 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt64(self)
                }
            case .deferredDouble(let val):
                if let i = UInt64(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt64(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt64(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt64(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToString() throws -> String {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToString(self)
                }
            case .deferredDouble(let val):
                return String(val)
            case .deferredInt(let val):
                return String(val)
            case .deferredString(let val):
                return val
            case .deferredBool(let val):
                return val ? "True" : "False"
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
        public subscript(key: SafePythonConvertible...) -> SafePythonConvertible {
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
                        let key   = item[0] as! SafePythonObject   // or item[SafePythonObject(0)] if needed
                        let value = item[1] as! SafePythonObject
                        
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
        
    }  // end of Safe python object
}
