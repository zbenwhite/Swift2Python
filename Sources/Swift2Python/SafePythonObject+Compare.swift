//
//  SafePythonObject+Compare.swift
//  Swift2Python
//
//  Created by Ben White on 6/19/26.
//


extension PythonInterpreter.SafePythonObject {
    
    private static func deferredTypeName(_ object: PythonInterpreter.SafePythonObject) -> String {
        switch object.state {
        case .bound:
            return "SafePythonObject"
        case .deferredDouble:
            return "Double"
        case .deferredInt:
            return "Int"
        case .deferredString:
            return "String"
        case .deferredBool:
            return "Bool"
        }
    }
    
    // MARK: Compare Equal
    
    private static func deferredDouble(_ lhs: Double, isEqualTo rhs: Int) -> Bool {
        guard !lhs.isNaN else { return false }
        return !Self.deferredDouble(lhs, isLessThan: rhs) && !Self.deferredInt(rhs, isLessThan: lhs)
    }
    
    private static func deferredInt(_ lhs: Int, isEqualTo rhs: Double) -> Bool {
        guard !rhs.isNaN else { return false }
        return !Self.deferredInt(lhs, isLessThan: rhs) && !Self.deferredDouble(rhs, isLessThan: lhs)
    }
    
    /// Compares this safe Python object with a Swift value using Python `==` semantics and returns a Swift `Bool`.
    ///
    /// Prefer this method for almost all throwing equality checks. It uses Python's boolean rich
    /// comparison path for bound operands and supports fully unbound `SafePythonObject` values.
    ///
    /// Use `equalPython(_:)` instead only when you intentionally need Python's raw rich-comparison
    /// result as a `SafePythonObject`, such as when a custom Python `__eq__` may return a non-`bool`
    /// object that you want to keep instead of converting to Swift `Bool`.
    ///
    /// If `other` is already a `SafePythonObject`, this supports fully unbound operands. If `other`
    /// is another `SafePythonConvertible`, this object must already be bound so the value can be
    /// converted through the active interpreter before Python performs the comparison.
    ///
    /// - Parameters:
    ///   - other: The Swift value to compare against.
    /// - Returns: `true` when this object compares equal to `other`; otherwise `false`.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError.safePythonException` if Python raises.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func equal(_ other: SafePythonConvertible) throws -> Bool {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try Self.equalBool(lhs: self, rhs: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncEqualEquatable(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    /// Compares this safe Python object with another using Python `==` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. In normal Swift control flow, prefer `equal(_:)`, which returns `Bool`
    /// and is the intended throwing API for almost all equality checks.
    ///
    /// If either operand is bound to an interpreter, this delegates to Python's `PyObject_RichCompare`,
    /// preserving custom comparison results, including non-`bool` objects returned by Python
    /// `__eq__` methods. Fully deferred values are compared locally with Python-compatible bool/int
    /// behavior and return a deferred Python bool.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.safePythonException` if Python raises.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func equalPython(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal == rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: Self.deferredDouble(lhsVal, isEqualTo: rhsVal))
            case .deferredString:
                return PythonInterpreter.SafePythonObject(booleanLiteral: false)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal == (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: Self.deferredInt(lhsVal, isEqualTo: rhsVal))
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal == rhsVal)
            case .deferredString:
                return PythonInterpreter.SafePythonObject(booleanLiteral: false)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal == (rhsVal ? 1 : 0))
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredBool:
                return PythonInterpreter.SafePythonObject(booleanLiteral: false)
            case .deferredString(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal == rhsVal)
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1.0 : 0.0) == rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) == rhsVal)
            case .deferredString:
                return PythonInterpreter.SafePythonObject(booleanLiteral: false)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal == rhsVal)
            }
        }
    }
    
    /// Compares this safe Python object with a Swift value using Python `==` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. Prefer `equal(_:)` for normal throwing comparisons that should produce
    /// a Swift `Bool`.
    ///
    /// Fully deferred objects can only compare directly against another `SafePythonObject`, because
    /// general `SafePythonConvertible` conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError` if conversion or Python comparison fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func equalPython(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try equalPython(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    static internal func equalOp(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.equalPython(rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.equal(_:)` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    private static func equalBool(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) throws -> Bool {
        switch lhs.state {
            case .bound:
                let localInterpreter = lhs.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return lhsVal == rhsVal
                case .deferredInt(let rhsVal):
                    return Self.deferredDouble(lhsVal, isEqualTo: rhsVal)
                case .deferredString:
                    return false
                case .deferredBool(let rhsVal):
                    return lhsVal == (rhsVal ? 1.0 : 0.0)
                }
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return Self.deferredInt(lhsVal, isEqualTo: rhsVal)
                case .deferredInt(let rhsVal):
                    return lhsVal == rhsVal
                case .deferredString:
                    return false
                case .deferredBool(let rhsVal):
                    return lhsVal == (rhsVal ? 1 : 0)
                }
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble, .deferredInt, .deferredBool:
                    return false
                case .deferredString(let rhsVal):
                    return lhsVal == rhsVal
                }
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) == rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) == rhsVal
                case .deferredString:
                    return false
                case .deferredBool(let rhsVal):
                    return lhsVal == rhsVal
                }
            }
        }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func equalEquatable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            return try equalBool(lhs: lhs, rhs: rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.equal(_:)` for comparisons that might throw.")
        }
    }
    
    
    // MARK: Compare Not Equal
    
    /// Compares this safe Python object with a Swift value using Python `!=` semantics and returns a Swift `Bool`.
    ///
    /// Prefer this method for almost all throwing inequality checks. It uses Python's boolean rich
    /// comparison path for bound operands and supports fully unbound `SafePythonObject` values.
    ///
    /// Use `notEqualPython(_:)` instead only when you intentionally need Python's raw rich-comparison
    /// result as a `SafePythonObject`, such as when a custom Python `__ne__` may return a non-`bool`
    /// object that you want to keep instead of converting to Swift `Bool`.
    ///
    /// If `other` is already a `SafePythonObject`, this supports fully unbound operands. If `other`
    /// is another `SafePythonConvertible`, this object must already be bound so the value can be
    /// converted through the active interpreter before Python performs the comparison.
    ///
    /// - Parameters:
    ///   - other: The Swift value to compare against.
    /// - Returns: `true` when this object compares not equal to `other`; otherwise `false`.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError.safePythonException` if Python raises.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func notEqual(_ other: SafePythonConvertible) throws -> Bool {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try Self.notEqualBool(lhs: self, rhs: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncNotEqualEquatable(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    /// Compares this safe Python object with another using Python `!=` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. In normal Swift control flow, prefer `notEqual(_:)`, which returns `Bool`
    /// and is the intended throwing API for almost all inequality checks.
    ///
    /// If either operand is bound to an interpreter, this delegates to Python's `PyObject_RichCompare`,
    /// preserving custom comparison results, including non-`bool` objects returned by Python
    /// `__ne__` methods. Fully deferred values are compared locally with Python-compatible bool/int
    /// behavior and return a deferred Python bool.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.safePythonException` if Python raises.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func notEqualPython(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncNotEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncNotEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal != rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: !Self.deferredDouble(lhsVal, isEqualTo: rhsVal))
            case .deferredString:
                return PythonInterpreter.SafePythonObject(booleanLiteral: true)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal != (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncNotEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: !Self.deferredInt(lhsVal, isEqualTo: rhsVal))
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal != rhsVal)
            case .deferredString:
                return PythonInterpreter.SafePythonObject(booleanLiteral: true)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal != (rhsVal ? 1 : 0))
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncNotEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredBool:
                return PythonInterpreter.SafePythonObject(booleanLiteral: true)
            case .deferredString(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal != rhsVal)
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncNotEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1.0 : 0.0) != rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) != rhsVal)
            case .deferredString:
                return PythonInterpreter.SafePythonObject(booleanLiteral: true)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal != rhsVal)
            }
        }
    }
    
    /// Compares this safe Python object with a Swift value using Python `!=` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. Prefer `notEqual(_:)` for normal throwing comparisons that should produce
    /// a Swift `Bool`.
    ///
    /// Fully deferred objects can only compare directly against another `SafePythonObject`, because
    /// general `SafePythonConvertible` conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError` if conversion or Python comparison fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func notEqualPython(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try notEqualPython(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncNotEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    static internal func notEqualOp(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.notEqualPython(rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.notEqual(_:)` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    private static func notEqualBool(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) throws -> Bool {
        switch lhs.state {
            case .bound:
                let localInterpreter = lhs.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncNotEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncNotEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return lhsVal != rhsVal
                case .deferredInt(let rhsVal):
                    return !Self.deferredDouble(lhsVal, isEqualTo: rhsVal)
                case .deferredString:
                    return true
                case .deferredBool(let rhsVal):
                    return lhsVal != (rhsVal ? 1.0 : 0.0)
                }
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncNotEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return !Self.deferredInt(lhsVal, isEqualTo: rhsVal)
                case .deferredInt(let rhsVal):
                    return lhsVal != rhsVal
                case .deferredString:
                    return true
                case .deferredBool(let rhsVal):
                    return lhsVal != (rhsVal ? 1 : 0)
                }
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncNotEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble, .deferredInt, .deferredBool:
                    return true
                case .deferredString(let rhsVal):
                    return lhsVal != rhsVal
                }
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncNotEqualEquatable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) != rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) != rhsVal
                case .deferredString:
                    return true
                case .deferredBool(let rhsVal):
                    return lhsVal != rhsVal
                }
            }
        }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func notEqualEquatable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            return try notEqualBool(lhs: lhs, rhs: rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.notEqual(_:)` for comparisons that might throw.")
        }
    }
    
    
    // MARK: Less Than
    
    private static func deferredInt(_ lhs: Int, isLessThan rhs: Double) -> Bool {
        guard !rhs.isNaN else { return false }
        if rhs == .infinity { return true }
        if rhs == -.infinity { return false }
        if rhs <= Double(Int.min) { return false }
        if rhs >= -Double(Int.min) { return true }
        
        let roundedDown = rhs.rounded(.down)
        let roundedDownInt = Int(roundedDown)
        if lhs < roundedDownInt { return true }
        if lhs > roundedDownInt { return false }
        return rhs != roundedDown
    }
    
    private static func deferredDouble(_ lhs: Double, isLessThan rhs: Int) -> Bool {
        guard !lhs.isNaN else { return false }
        if lhs == -.infinity { return true }
        if lhs == .infinity { return false }
        if lhs < Double(Int.min) { return true }
        if lhs >= -Double(Int.min) { return false }
        
        let roundedUp = lhs.rounded(.up)
        let roundedUpInt = Int(roundedUp)
        if roundedUpInt < rhs { return true }
        if roundedUpInt > rhs { return false }
        return lhs != roundedUp
    }
    
    private static func lessThanTypeError(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonError {
        PythonError.typeError(operation: "less than", opType1: Self.deferredTypeName(lhs), opType2: Self.deferredTypeName(rhs))
    }
    
    /// Compares this safe Python object with a Swift value using Python `<` semantics and returns a Swift `Bool`.
    ///
    /// Prefer this method for almost all throwing less-than checks. It uses Python's boolean rich
    /// comparison path for bound operands and preserves the same deferred-aware behavior as
    /// `Comparable` for unbound `SafePythonObject` values.
    ///
    /// Use `lessThanPython(_:)` instead only when you intentionally need Python's raw rich-comparison
    /// result as a `SafePythonObject`, such as when a custom Python `__lt__` may return a non-`bool`
    /// object that you want to keep instead of converting to Swift `Bool`.
    ///
    /// If `other` is already a `SafePythonObject`, this supports fully unbound operands. If `other`
    /// is another `SafePythonConvertible`, this object must already be bound so the value can be
    /// converted through the active interpreter before Python performs the comparison.
    ///
    /// - Parameters:
    ///   - other: The Swift value to compare against.
    /// - Returns: `true` when this object compares less than `other`; otherwise `false`.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, `PythonError.safePythonException` if Python raises, or
    ///   `PythonError.typeError` for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func lessThan(_ other: SafePythonConvertible) throws -> Bool {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try Self.lessThanBool(lhs: self, rhs: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncLessThanComparable(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    /// Compares this safe Python object with another using Python `<` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. In normal Swift control flow, prefer `lessThan(_:)`, which returns `Bool`
    /// and is the intended throwing API for almost all less-than checks.
    ///
    /// If either operand is bound to an interpreter, this delegates to Python's `PyObject_RichCompare`,
    /// preserving custom comparison results, including non-`bool` objects returned by Python
    /// `__lt__` methods. Fully deferred numeric and string values are compared locally with
    /// Python-compatible bool/int behavior and return a deferred Python bool.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func lessThanPython(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal < rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: Self.deferredDouble(lhsVal, isLessThan: rhsVal))
            case .deferredString:
                throw Self.lessThanTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal < (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: Self.deferredInt(lhsVal, isLessThan: rhsVal))
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal < rhsVal)
            case .deferredString:
                throw Self.lessThanTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal < (rhsVal ? 1 : 0))
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredBool:
                throw Self.lessThanTypeError(lhs: self, rhs: other)
            case .deferredString(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal < rhsVal)
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1.0 : 0.0) < rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) < rhsVal)
            case .deferredString:
                throw Self.lessThanTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) < (rhsVal ? 1 : 0))
            }
        }
    }
    
    /// Compares this safe Python object with a Swift value using Python `<` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. Prefer `lessThan(_:)` for normal throwing comparisons that should produce
    /// a Swift `Bool`.
    ///
    /// Fully deferred objects can only compare directly against another `SafePythonObject`, because
    /// general `SafePythonConvertible` conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError` if conversion or Python comparison fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func lessThanPython(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try lessThanPython(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncLessThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    static internal func lessThanOp(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.lessThanPython(rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.lessThan(_:)` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    private static func lessThanBool(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) throws -> Bool {
        switch lhs.state {
            case .bound:
                let localInterpreter = lhs.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncLessThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return lhsVal < rhsVal
                case .deferredInt(let rhsVal):
                    return Self.deferredDouble(lhsVal, isLessThan: rhsVal)
                case .deferredString:
                    throw Self.lessThanTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return lhsVal < (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncLessThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return Self.deferredInt(lhsVal, isLessThan: rhsVal)
                case .deferredInt(let rhsVal):
                    return lhsVal < rhsVal
                case .deferredString:
                    throw Self.lessThanTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return lhsVal < (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncLessThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble, .deferredInt, .deferredBool:
                    throw Self.lessThanTypeError(lhs: lhs, rhs: rhs)
                case .deferredString(let rhsVal):
                    return lhsVal < rhsVal
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncLessThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) < rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) < rhsVal
                case .deferredString:
                    throw Self.lessThanTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return (lhsVal ? 1 : 0) < (rhsVal ? 1 : 0)
                }
            }
        }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func lessThanComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            return try lessThanBool(lhs: lhs, rhs: rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.lessThan(_:)` for comparisons that might throw.")
        }
    }
    
    
    // MARK: Less Than Or Equal To
    
    private static func lessThanOrEqualTypeError(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonError {
        PythonError.typeError(operation: "less than or equal", opType1: Self.deferredTypeName(lhs), opType2: Self.deferredTypeName(rhs))
    }
    
    /// Compares this safe Python object with a Swift value using Python `<=` semantics and returns a Swift `Bool`.
    ///
    /// Prefer this method for almost all throwing less-than-or-equal checks. It uses Python's
    /// boolean rich comparison path for bound operands and supports fully unbound `SafePythonObject`
    /// values.
    ///
    /// Use `lessThanOrEqualPython(_:)` instead only when you intentionally need Python's raw
    /// rich-comparison result as a `SafePythonObject`, such as when a custom Python `__le__` may
    /// return a non-`bool` object that you want to keep instead of converting to Swift `Bool`.
    ///
    /// If `other` is already a `SafePythonObject`, this supports fully unbound operands. If `other`
    /// is another `SafePythonConvertible`, this object must already be bound so the value can be
    /// converted through the active interpreter before Python performs the comparison.
    ///
    /// - Parameters:
    ///   - other: The Swift value to compare against.
    /// - Returns: `true` when this object compares less than or equal to `other`; otherwise `false`.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, `PythonError.safePythonException` if Python raises, or
    ///   `PythonError.typeError` for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func lessThanOrEqual(_ other: SafePythonConvertible) throws -> Bool {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try Self.lessThanOrEqualBool(lhs: self, rhs: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncLessThanOrEqualComparable(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    /// Compares this safe Python object with another using Python `<=` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. In normal Swift control flow, prefer `lessThanOrEqual(_:)`, which returns
    /// `Bool` and is the intended throwing API for almost all less-than-or-equal checks.
    ///
    /// If either operand is bound to an interpreter, this delegates to Python's `PyObject_RichCompare`,
    /// preserving custom comparison results, including non-`bool` objects returned by Python
    /// `__le__` methods. Fully deferred numeric and string values are compared locally with
    /// Python-compatible bool/int behavior and return a deferred Python bool.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func lessThanOrEqualPython(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal <= rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: !lhsVal.isNaN && !Self.deferredInt(rhsVal, isLessThan: lhsVal))
            case .deferredString:
                throw Self.lessThanOrEqualTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal <= (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: !rhsVal.isNaN && !Self.deferredDouble(rhsVal, isLessThan: lhsVal))
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal <= rhsVal)
            case .deferredString:
                throw Self.lessThanOrEqualTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal <= (rhsVal ? 1 : 0))
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredBool:
                throw Self.lessThanOrEqualTypeError(lhs: self, rhs: other)
            case .deferredString(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal <= rhsVal)
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1.0 : 0.0) <= rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) <= rhsVal)
            case .deferredString:
                throw Self.lessThanOrEqualTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) <= (rhsVal ? 1 : 0))
            }
        }
    }
    
    /// Compares this safe Python object with a Swift value using Python `<=` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. Prefer `lessThanOrEqual(_:)` for normal throwing comparisons that should
    /// produce a Swift `Bool`.
    ///
    /// Fully deferred objects can only compare directly against another `SafePythonObject`, because
    /// general `SafePythonConvertible` conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError` if conversion or Python comparison fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func lessThanOrEqualPython(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try lessThanOrEqualPython(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncLessThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    static internal func lessThanOrEqualOp(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.lessThanOrEqualPython(rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.lessThanOrEqual(_:)` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    private static func lessThanOrEqualBool(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) throws -> Bool {
        switch lhs.state {
            case .bound:
                let localInterpreter = lhs.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncLessThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return lhsVal <= rhsVal
                case .deferredInt(let rhsVal):
                    return !lhsVal.isNaN && !Self.deferredInt(rhsVal, isLessThan: lhsVal)
                case .deferredString:
                    throw Self.lessThanOrEqualTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return lhsVal <= (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncLessThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return !rhsVal.isNaN && !Self.deferredDouble(rhsVal, isLessThan: lhsVal)
                case .deferredInt(let rhsVal):
                    return lhsVal <= rhsVal
                case .deferredString:
                    throw Self.lessThanOrEqualTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return lhsVal <= (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncLessThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble, .deferredInt, .deferredBool:
                    throw Self.lessThanOrEqualTypeError(lhs: lhs, rhs: rhs)
                case .deferredString(let rhsVal):
                    return lhsVal <= rhsVal
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncLessThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) <= rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) <= rhsVal
                case .deferredString:
                    throw Self.lessThanOrEqualTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return (lhsVal ? 1 : 0) <= (rhsVal ? 1 : 0)
                }
            }
        }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func lessThanOrEqualComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            return try lessThanOrEqualBool(lhs: lhs, rhs: rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.lessThanOrEqual(_:)` for comparisons that might throw.")
        }
    }
    
    
    // MARK: Greater Than
    
    private static func greaterThanTypeError(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonError {
        PythonError.typeError(operation: "greater than", opType1: Self.deferredTypeName(lhs), opType2: Self.deferredTypeName(rhs))
    }
    
    /// Compares this safe Python object with a Swift value using Python `>` semantics and returns a Swift `Bool`.
    ///
    /// Prefer this method for almost all throwing greater-than checks. It uses Python's boolean rich
    /// comparison path for bound operands and supports fully unbound `SafePythonObject` values.
    ///
    /// Use `greaterThanPython(_:)` instead only when you intentionally need Python's raw
    /// rich-comparison result as a `SafePythonObject`, such as when a custom Python `__gt__` may
    /// return a non-`bool` object that you want to keep instead of converting to Swift `Bool`.
    ///
    /// If `other` is already a `SafePythonObject`, this supports fully unbound operands. If `other`
    /// is another `SafePythonConvertible`, this object must already be bound so the value can be
    /// converted through the active interpreter before Python performs the comparison.
    ///
    /// - Parameters:
    ///   - other: The Swift value to compare against.
    /// - Returns: `true` when this object compares greater than `other`; otherwise `false`.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, `PythonError.safePythonException` if Python raises, or
    ///   `PythonError.typeError` for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func greaterThan(_ other: SafePythonConvertible) throws -> Bool {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try Self.greaterThanBool(lhs: self, rhs: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncGreaterThanComparable(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    /// Compares this safe Python object with another using Python `>` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. In normal Swift control flow, prefer `greaterThan(_:)`, which returns
    /// `Bool` and is the intended throwing API for almost all greater-than checks.
    ///
    /// If either operand is bound to an interpreter, this delegates to Python's `PyObject_RichCompare`,
    /// preserving custom comparison results, including non-`bool` objects returned by Python
    /// `__gt__` methods. Fully deferred numeric and string values are compared locally with
    /// Python-compatible bool/int behavior and return a deferred Python bool.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func greaterThanPython(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGreaterThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal > rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: Self.deferredInt(rhsVal, isLessThan: lhsVal))
            case .deferredString:
                throw Self.greaterThanTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal > (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: Self.deferredDouble(rhsVal, isLessThan: lhsVal))
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal > rhsVal)
            case .deferredString:
                throw Self.greaterThanTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal > (rhsVal ? 1 : 0))
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredBool:
                throw Self.greaterThanTypeError(lhs: self, rhs: other)
            case .deferredString(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal > rhsVal)
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1.0 : 0.0) > rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) > rhsVal)
            case .deferredString:
                throw Self.greaterThanTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) > (rhsVal ? 1 : 0))
            }
        }
    }
    
    /// Compares this safe Python object with a Swift value using Python `>` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. Prefer `greaterThan(_:)` for normal throwing comparisons that should
    /// produce a Swift `Bool`.
    ///
    /// Fully deferred objects can only compare directly against another `SafePythonObject`, because
    /// general `SafePythonConvertible` conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError` if conversion or Python comparison fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func greaterThanPython(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try greaterThanPython(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncGreaterThan(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    static internal func greaterThanOp(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.greaterThanPython(rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.greaterThan(_:)` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    private static func greaterThanBool(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) throws -> Bool {
        switch lhs.state {
            case .bound:
                let localInterpreter = lhs.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncGreaterThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return lhsVal > rhsVal
                case .deferredInt(let rhsVal):
                    return Self.deferredInt(rhsVal, isLessThan: lhsVal)
                case .deferredString:
                    throw Self.greaterThanTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return lhsVal > (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncGreaterThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return Self.deferredDouble(rhsVal, isLessThan: lhsVal)
                case .deferredInt(let rhsVal):
                    return lhsVal > rhsVal
                case .deferredString:
                    throw Self.greaterThanTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return lhsVal > (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncGreaterThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble, .deferredInt, .deferredBool:
                    throw Self.greaterThanTypeError(lhs: lhs, rhs: rhs)
                case .deferredString(let rhsVal):
                    return lhsVal > rhsVal
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncGreaterThanComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) > rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) > rhsVal
                case .deferredString:
                    throw Self.greaterThanTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return (lhsVal ? 1 : 0) > (rhsVal ? 1 : 0)
                }
            }
        }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func greaterThanComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            return try greaterThanBool(lhs: lhs, rhs: rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.greaterThan(_:)` for comparisons that might throw.")
        }
    }
    
    // MARK: Greater Than Or Equal To
    
    private static func greaterThanOrEqualTypeError(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonError {
        PythonError.typeError(operation: "greater than or equal", opType1: Self.deferredTypeName(lhs), opType2: Self.deferredTypeName(rhs))
    }
    
    /// Compares this safe Python object with a Swift value using Python `>=` semantics and returns a Swift `Bool`.
    ///
    /// Prefer this method for almost all throwing greater-than-or-equal checks. It uses Python's
    /// boolean rich comparison path for bound operands and supports fully unbound `SafePythonObject`
    /// values.
    ///
    /// Use `greaterThanOrEqualPython(_:)` instead only when you intentionally need Python's raw
    /// rich-comparison result as a `SafePythonObject`, such as when a custom Python `__ge__` may
    /// return a non-`bool` object that you want to keep instead of converting to Swift `Bool`.
    ///
    /// If `other` is already a `SafePythonObject`, this supports fully unbound operands. If `other`
    /// is another `SafePythonConvertible`, this object must already be bound so the value can be
    /// converted through the active interpreter before Python performs the comparison.
    ///
    /// - Parameters:
    ///   - other: The Swift value to compare against.
    /// - Returns: `true` when this object compares greater than or equal to `other`; otherwise `false`.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, `PythonError.safePythonException` if Python raises, or
    ///   `PythonError.typeError` for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func greaterThanOrEqual(_ other: SafePythonConvertible) throws -> Bool {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try Self.greaterThanOrEqualBool(lhs: self, rhs: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncGreaterThanOrEqualComparable(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    /// Compares this safe Python object with another using Python `>=` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. In normal Swift control flow, prefer `greaterThanOrEqual(_:)`, which
    /// returns `Bool` and is the intended throwing API for almost all greater-than-or-equal checks.
    ///
    /// If either operand is bound to an interpreter, this delegates to Python's `PyObject_RichCompare`,
    /// preserving custom comparison results, including non-`bool` objects returned by Python
    /// `__ge__` methods. Fully deferred numeric and string values are compared locally with
    /// Python-compatible bool/int behavior and return a deferred Python bool.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func greaterThanOrEqualPython(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGreaterThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal >= rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: !lhsVal.isNaN && !Self.deferredDouble(lhsVal, isLessThan: rhsVal))
            case .deferredString:
                throw Self.greaterThanOrEqualTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal >= (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: !rhsVal.isNaN && !Self.deferredInt(lhsVal, isLessThan: rhsVal))
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal >= rhsVal)
            case .deferredString:
                throw Self.greaterThanOrEqualTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal >= (rhsVal ? 1 : 0))
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredBool:
                throw Self.greaterThanOrEqualTypeError(lhs: self, rhs: other)
            case .deferredString(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal >= rhsVal)
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1.0 : 0.0) >= rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) >= rhsVal)
            case .deferredString:
                throw Self.greaterThanOrEqualTypeError(lhs: self, rhs: other)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: (lhsVal ? 1 : 0) >= (rhsVal ? 1 : 0))
            }
        }
    }
    
    /// Compares this safe Python object with a Swift value using Python `>=` semantics and returns Python's result object.
    ///
    /// Use this method only when you need the raw Python rich-comparison result as a
    /// `SafePythonObject`. Prefer `greaterThanOrEqual(_:)` for normal throwing comparisons that
    /// should produce a Swift `Bool`.
    ///
    /// Fully deferred objects can only compare directly against another `SafePythonObject`, because
    /// general `SafePythonConvertible` conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and compare against.
    /// - Returns: Python's rich-comparison result as a safe Python object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError` if conversion or Python comparison fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func greaterThanOrEqualPython(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try greaterThanOrEqualPython(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "SafePythonObject"
            )
        }
        
        let localInterpreter = interpreter
        return try localInterpreter.assumeIsolated {
            try $0.syncGreaterThanOrEqual(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
        }
    }
    
    static internal func greaterThanOrEqualOp(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.greaterThanOrEqualPython(rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.greaterThanOrEqual(_:)` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    private static func greaterThanOrEqualBool(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) throws -> Bool {
        switch lhs.state {
            case .bound:
                let localInterpreter = lhs.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncGreaterThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return lhsVal >= rhsVal
                case .deferredInt(let rhsVal):
                    return !lhsVal.isNaN && !Self.deferredDouble(lhsVal, isLessThan: rhsVal)
                case .deferredString:
                    throw Self.greaterThanOrEqualTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return lhsVal >= (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncGreaterThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return !rhsVal.isNaN && !Self.deferredInt(lhsVal, isLessThan: rhsVal)
                case .deferredInt(let rhsVal):
                    return lhsVal >= rhsVal
                case .deferredString:
                    throw Self.greaterThanOrEqualTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return lhsVal >= (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncGreaterThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble, .deferredInt, .deferredBool:
                    throw Self.greaterThanOrEqualTypeError(lhs: lhs, rhs: rhs)
                case .deferredString(let rhsVal):
                    return lhsVal >= rhsVal
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    let localInterpreter = rhs.interpreter
                    return try localInterpreter.assumeIsolated {
                        try $0.syncGreaterThanOrEqualComparable(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                    }
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) >= rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) >= rhsVal
                case .deferredString:
                    throw Self.greaterThanOrEqualTypeError(lhs: lhs, rhs: rhs)
                case .deferredBool(let rhsVal):
                    return (lhsVal ? 1 : 0) >= (rhsVal ? 1 : 0)
                }
            }
        }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func greaterThanOrEqualComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            return try greaterThanOrEqualBool(lhs: lhs, rhs: rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.greaterThanOrEqual(_:)` for comparisons that might throw.")
        }
    }
}
