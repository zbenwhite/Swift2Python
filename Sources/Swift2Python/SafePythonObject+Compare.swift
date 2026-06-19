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
    
    // MARK: Compare Equals
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func doubleEqualsEquatableOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> Bool {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncDoubleEqualsEquatable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func doubleEqualsOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncDoubleEquals(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func unboundPythonDoubleEquals(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        PythonInterpreter.SafePythonObject(booleanLiteral: unboundPythonDoubleEqualsEquatable(lhs: lhs, rhs: rhs))
    }
    
    static internal func unboundPythonDoubleEqualsEquatable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        switch lhs.state {
        case .bound:
            fatalError("This can never happen.")
            
        case .deferredDouble(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let rhsVal):
                return lhsVal == rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal == Double(rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal == (rhsVal ? 1.0 : 0.0)
            }
            
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let rhsVal):
                return Double(lhsVal) == rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal == rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal == (rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt:
                fatalError("Python TypeError")
            case .deferredString(let rhsVal):
                return lhsVal == rhsVal
            case .deferredBool:
                fatalError("Python TypeError")
            }
            
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let rhsVal):
                return (lhsVal ? 1.0 : 0.0) == rhsVal
            case .deferredInt(let rhsVal):
                return (lhsVal ? 1 : 0) == rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal == rhsVal
            }
        }
    }
    
    
    // MARK: Compare Not Equals
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func notEqualsEquatableOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> Bool {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncNotEqualsEquatable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func notEqualsOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncNotEquals(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    static internal func unboundPythonNotEquals(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        PythonInterpreter.SafePythonObject(booleanLiteral: unboundPythonNotEqualsEquatable(lhs: lhs, rhs: rhs))
    }
    
    static internal func unboundPythonNotEqualsEquatable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        switch lhs.state {
        case .bound:
            fatalError("This can never happen.")
            
        case .deferredDouble(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let rhsVal):
                return lhsVal != rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal != Double(rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal != (rhsVal ? 1.0 : 0.0)
            }
            
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let rhsVal):
                return Double(lhsVal) != rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal != rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal != (rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt:
                fatalError("Python TypeError")
            case .deferredString(let rhsVal):
                return lhsVal != rhsVal
            case .deferredBool:
                fatalError("Python TypeError")
            }
            
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let rhsVal):
                return (lhsVal ? 1.0 : 0.0) != rhsVal
            case .deferredInt(let rhsVal):
                return (lhsVal ? 1 : 0) != rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal != rhsVal
            }
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
    
    /// Compares this safe Python object with another using Python `<` semantics.
    ///
    /// If either operand is bound to an interpreter, this delegates to Python's rich comparison
    /// machinery so custom Python objects and Python's exception behavior are preserved. Fully
    /// deferred numeric and string values are compared locally with Python-compatible bool/int
    /// behavior. Invalid fully deferred primitive combinations throw `PythonError.typeError`.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to compare against.
    /// - Returns: A safe Python bool object containing the comparison result.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func lessThan(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
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
    
    /// Compares this safe Python object with a Swift value using Python `<` semantics.
    ///
    /// Fully deferred objects can only compare directly against another `SafePythonObject`, because
    /// general `SafePythonConvertible` conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and compare against.
    /// - Returns: A safe Python bool object containing the comparison result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError` if conversion or Python comparison fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func lessThan(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try lessThan(safeObject)
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
            return try lhs.lessThan(rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.lessThan(_:)` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func lessThanComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            return try Bool(lhs.lessThan(rhs))
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.lessThan(_:)` for comparisons that might throw.")
        }
    }
    
    
    // MARK: Less Than Or Equal To
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func lessThanOrEqualOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThanOrEqual(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    
    static internal func unboundPythonLessThanOrEquals(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        PythonInterpreter.SafePythonObject(booleanLiteral: lessThanOrEqualsComparable(lhs: lhs, rhs: rhs))
    }
    
    
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func boundPythonLessThanOrEqualsComparable(interpreter: PythonInterpreter, lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThanOrEqualComparable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Comparison failed: \(error).  Use `SafePythonObject.lessThanOrEqual()` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func lessThanOrEqualsComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        switch lhs.state {
        case .bound:
            return boundPythonLessThanOrEqualsComparable(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
            
        case .deferredDouble(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonLessThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return lhsVal <= rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal <= Double(rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal <= (rhsVal ? 1.0 : 0.0)
            }
            
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonLessThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return Double(lhsVal) <= rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal <= rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal <= (rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonLessThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt:
                fatalError("Python TypeError")
            case .deferredString(let rhsVal):
                return lhsVal <= rhsVal
            case .deferredBool:
                fatalError("Python TypeError")
            }
            
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonLessThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return (lhsVal ? 1.0 : 0.0) <= rhsVal
            case .deferredInt(let rhsVal):
                return (lhsVal ? 1 : 0) <= rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return (lhsVal ? 1 : 0) <= (rhsVal ? 1 : 0)
            }
        }
    }
    
    
    // MARK: Greater Than
    
    private static func greaterThanTypeError(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonError {
        PythonError.typeError(operation: "greater than", opType1: Self.deferredTypeName(lhs), opType2: Self.deferredTypeName(rhs))
    }
    
    /// Compares this safe Python object with another using Python `>` semantics.
    ///
    /// If either operand is bound to an interpreter, this delegates to Python's rich comparison
    /// machinery so custom Python objects and Python's exception behavior are preserved. Fully
    /// deferred numeric and string values are compared locally with Python-compatible bool/int
    /// behavior. Invalid fully deferred primitive combinations throw `PythonError.typeError`.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to compare against.
    /// - Returns: A safe Python bool object containing the comparison result.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func greaterThan(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
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
    
    /// Compares this safe Python object with a Swift value using Python `>` semantics.
    ///
    /// Fully deferred objects can only compare directly against another `SafePythonObject`, because
    /// general `SafePythonConvertible` conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and compare against.
    /// - Returns: A safe Python bool object containing the comparison result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this object
    ///   is still deferred, or `PythonError` if conversion or Python comparison fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func greaterThan(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try greaterThan(safeObject)
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
            return try lhs.greaterThan(rhs)
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.greaterThan(_:)` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func greaterThanComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            return try Bool(lhs.greaterThan(rhs))
        } catch {
            fatalError("Comparison failed: \(error). Use `SafePythonObject.greaterThan(_:)` for comparisons that might throw.")
        }
    }
    
    // MARK: Greater Than Or Equal To
    
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func greaterThanOrEqualOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGreaterThanOrEqual(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    static internal func unboundPythonGreaterThanOrEquals(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        PythonInterpreter.SafePythonObject(booleanLiteral: greaterThanOrEqualsComparable(lhs: lhs, rhs: rhs))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func boundPythonGreaterThanOrEqualsComparable(interpreter: PythonInterpreter, lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGreaterThanOrEqualComparable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Comparison failed: \(error).  Use `SafePythonObject.greaterThanOrEqual()` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func greaterThanOrEqualsComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        switch lhs.state {
        case .bound:
            return boundPythonGreaterThanOrEqualsComparable(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
            
        case .deferredDouble(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonGreaterThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return lhsVal >= rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal >= Double(rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal >= (rhsVal ? 1.0 : 0.0)
            }
            
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonGreaterThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return Double(lhsVal) >= rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal >= rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal >= (rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonGreaterThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt:
                fatalError("Python TypeError")
            case .deferredString(let rhsVal):
                return lhsVal >= rhsVal
            case .deferredBool:
                fatalError("Python TypeError")
            }
            
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonGreaterThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return (lhsVal ? 1.0 : 0.0) >= rhsVal
            case .deferredInt(let rhsVal):
                return (lhsVal ? 1 : 0) >= rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return (lhsVal ? 1 : 0) >= (rhsVal ? 1 : 0)
            }
        }
    }
}
