//
//  SafePythonObject+Bitwise.swift
//  Swift2Python
//
//  Created by Ben White on 6/19/26.
//

extension PythonInterpreter.SafePythonObject {
    
    
    // MARK: -
    // MARK: BITS
    
    
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
    
    // MARK: Bitwise AND

    /// Returns the Python bitwise AND of two safe Python objects.
    ///
    /// This follows Python `&` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_And`. If both
    /// operands are deferred safe values, Swift2Python locally supports the Python-valid
    /// primitive combinations: `Int & Int`, `Int & Bool`, `Bool & Int`, and `Bool & Bool`.
    ///
    /// Fully deferred `Bool & Bool` returns a deferred boolean, matching Python's boolean
    /// bitwise result. Mixed integer/boolean operands return a deferred integer.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to combine with this object.
    /// - Returns: The Python bitwise AND result.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitwiseAnd(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitwiseAnd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseAnd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal & rhsVal)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal & (rhsVal ? 1 : 0))
            case .deferredDouble, .deferredString:
                throw PythonError.typeError(operation: "bitwise AND", opType1: "Int", opType2: Self.deferredTypeName(other))
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseAnd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) & rhsVal)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal && rhsVal)
            case .deferredDouble, .deferredString:
                throw PythonError.typeError(operation: "bitwise AND", opType1: "Bool", opType2: Self.deferredTypeName(other))
            }
            
        case .deferredDouble, .deferredString:
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseAnd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
                throw PythonError.typeError(
                    operation: "bitwise AND",
                    opType1: Self.deferredTypeName(self),
                    opType2: Self.deferredTypeName(other)
                )
            }
        }
    }
    
    /// Returns the Python bitwise AND of this safe Python object and a Python-convertible Swift value.
    ///
    /// This overload adapts typed Swift values such as `Int` and `Bool`. Existing
    /// `SafePythonObject` values are forwarded to `bitwiseAnd(_ other: SafePythonObject)`.
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// safe object, because general conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and combine with this object.
    /// - Returns: The Python bitwise AND result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this
    ///   object is still deferred, or `PythonError` if conversion or Python bitwise AND fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitwiseAnd(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try bitwiseAnd(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try bitwiseAnd(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitwiseAndOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.bitwiseAnd(rhs)
        } catch {
            fatalError("Bitwise AND failed: \(error).  Use `SafePythonObject.bitwiseAnd()` for bitwise AND that might throw.")
        }
    }
    
    /// Replaces this safe Python object with its Python bitwise AND result.
    ///
    /// This follows Python `&=` semantics. If this object is bound, or if the right-hand
    /// operand is bound, the operation is delegated to Python with `PyNumber_InPlaceAnd`.
    /// For fully deferred values, this applies the same valid primitive combinations as
    /// `bitwiseAnd(_:)` and stores the deferred result in this object.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to combine with this object.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitwiseAndInPlace(_ other: PythonInterpreter.SafePythonObject) throws {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceBitwiseAnd(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
            if other.isBoundToPythonInterpreter {
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceBitwiseAnd(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            } else {
                do {
                    self = try bitwiseAnd(other)
                } catch let PythonError.typeError(_, opType1, opType2) {
                    throw PythonError.typeError(operation: "in place bitwise AND", opType1: opType1, opType2: opType2)
                }
            }
        }
    }
    
    /// Replaces this safe Python object with its bitwise AND against a Python-convertible Swift value.
    ///
    /// This overload adapts typed Swift values such as `Int` and `Bool`. Existing
    /// `SafePythonObject` values are forwarded to `bitwiseAndInPlace(_ other: SafePythonObject)`.
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// safe object, because general conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and combine with this object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this
    ///   object is still deferred, or `PythonError` if conversion or Python bitwise AND fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitwiseAndInPlace(_ other: any SafePythonConvertible) throws {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            try bitwiseAndInPlace(safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try bitwiseAndInPlace(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitwiseAndInPlaceOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = lhs
            try result.bitwiseAndInPlace(rhs)
            return result
        } catch {
            fatalError("In place bitwise AND failed: \(error).  Use `SafePythonObject.bitwiseAndInPlace()` for in place bitwise AND that might throw.")
        }
    }
    
    // MARK: Bitwise OR
    
    /// Returns the Python bitwise OR of two safe Python objects.
    ///
    /// This follows Python `|` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_Or`. If both
    /// operands are deferred safe values, Swift2Python locally supports the Python-valid
    /// primitive combinations: `Int | Int`, `Int | Bool`, `Bool | Int`, and `Bool | Bool`.
    ///
    /// Fully deferred `Bool | Bool` returns a deferred boolean, matching Python's boolean
    /// bitwise result. Mixed integer/boolean operands return a deferred integer.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to combine with this object.
    /// - Returns: The Python bitwise OR result.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitwiseOr(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitwiseOr(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseOr(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal | rhsVal)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal | (rhsVal ? 1 : 0))
            case .deferredDouble, .deferredString:
                throw PythonError.typeError(operation: "bitwise OR", opType1: "Int", opType2: Self.deferredTypeName(other))
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseOr(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) | rhsVal)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal || rhsVal)
            case .deferredDouble, .deferredString:
                throw PythonError.typeError(operation: "bitwise OR", opType1: "Bool", opType2: Self.deferredTypeName(other))
            }
            
        case .deferredDouble, .deferredString:
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseOr(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
                throw PythonError.typeError(
                    operation: "bitwise OR",
                    opType1: Self.deferredTypeName(self),
                    opType2: Self.deferredTypeName(other)
                )
            }
        }
    }
    
    /// Returns the Python bitwise OR of this safe Python object and a Python-convertible Swift value.
    ///
    /// This overload adapts typed Swift values such as `Int` and `Bool`. Existing
    /// `SafePythonObject` values are forwarded to `bitwiseOr(_ other: SafePythonObject)`.
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// safe object, because general conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and combine with this object.
    /// - Returns: The Python bitwise OR result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this
    ///   object is still deferred, or `PythonError` if conversion or Python bitwise OR fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitwiseOr(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try bitwiseOr(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try bitwiseOr(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitwiseOrOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.bitwiseOr(rhs)
        } catch {
            fatalError("Bitwise OR failed: \(error).  Use `SafePythonObject.bitwiseOr()` for bitwise OR that might throw.")
        }
    }
    
    /// Replaces this safe Python object with its Python bitwise OR result.
    ///
    /// This follows Python `|=` semantics. If this object is bound, or if the right-hand
    /// operand is bound, the operation is delegated to Python with `PyNumber_InPlaceOr`.
    /// For fully deferred values, this applies the same valid primitive combinations as
    /// `bitwiseOr(_:)` and stores the deferred result in this object.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to combine with this object.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitwiseOrInPlace(_ other: PythonInterpreter.SafePythonObject) throws {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceBitwiseOr(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
            if other.isBoundToPythonInterpreter {
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceBitwiseOr(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            } else {
                do {
                    self = try bitwiseOr(other)
                } catch let PythonError.typeError(_, opType1, opType2) {
                    throw PythonError.typeError(operation: "in place bitwise OR", opType1: opType1, opType2: opType2)
                }
            }
        }
    }
    
    /// Replaces this safe Python object with its bitwise OR against a Python-convertible Swift value.
    ///
    /// This overload adapts typed Swift values such as `Int` and `Bool`. Existing
    /// `SafePythonObject` values are forwarded to `bitwiseOrInPlace(_ other: SafePythonObject)`.
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// safe object, because general conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and combine with this object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this
    ///   object is still deferred, or `PythonError` if conversion or Python bitwise OR fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitwiseOrInPlace(_ other: any SafePythonConvertible) throws {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            try bitwiseOrInPlace(safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try bitwiseOrInPlace(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitwiseOrInPlaceOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = lhs
            try result.bitwiseOrInPlace(rhs)
            return result
        } catch {
            fatalError("In place bitwise OR failed: \(error).  Use `SafePythonObject.bitwiseOrInPlace()` for in place bitwise OR that might throw.")
        }
    }
    
    // MARK: Bitwise XOR
    
    /// Returns the Python bitwise XOR of two safe Python objects.
    ///
    /// This follows Python `^` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_Xor`. If both
    /// operands are deferred safe values, Swift2Python locally supports the Python-valid
    /// primitive combinations: `Int ^ Int`, `Int ^ Bool`, `Bool ^ Int`, and `Bool ^ Bool`.
    ///
    /// Fully deferred `Bool ^ Bool` returns a deferred boolean, matching Python's boolean
    /// bitwise result. Mixed integer/boolean operands return a deferred integer.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to combine with this object.
    /// - Returns: The Python bitwise XOR result.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitwiseXor(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitwiseXor(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseXor(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal ^ rhsVal)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal ^ (rhsVal ? 1 : 0))
            case .deferredDouble, .deferredString:
                throw PythonError.typeError(operation: "bitwise XOR", opType1: "Int", opType2: Self.deferredTypeName(other))
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseXor(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) ^ rhsVal)
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(booleanLiteral: lhsVal != rhsVal)
            case .deferredDouble, .deferredString:
                throw PythonError.typeError(operation: "bitwise XOR", opType1: "Bool", opType2: Self.deferredTypeName(other))
            }
            
        case .deferredDouble, .deferredString:
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseXor(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
                throw PythonError.typeError(
                    operation: "bitwise XOR",
                    opType1: Self.deferredTypeName(self),
                    opType2: Self.deferredTypeName(other)
                )
            }
        }
    }
    
    /// Returns the Python bitwise XOR of this safe Python object and a Python-convertible Swift value.
    ///
    /// This overload adapts typed Swift values such as `Int` and `Bool`. Existing
    /// `SafePythonObject` values are forwarded to `bitwiseXor(_ other: SafePythonObject)`.
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// safe object, because general conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and combine with this object.
    /// - Returns: The Python bitwise XOR result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this
    ///   object is still deferred, or `PythonError` if conversion or Python bitwise XOR fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitwiseXor(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try bitwiseXor(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try bitwiseXor(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitwiseXorOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.bitwiseXor(rhs)
        } catch {
            fatalError("Bitwise XOR failed: \(error).  Use `SafePythonObject.bitwiseXor()` for bitwise XOR that might throw.")
        }
    }
    
    /// Replaces this safe Python object with its Python bitwise XOR result.
    ///
    /// This follows Python `^=` semantics. If this object is bound, or if the right-hand
    /// operand is bound, the operation is delegated to Python with `PyNumber_InPlaceXor`.
    /// For fully deferred values, this applies the same valid primitive combinations as
    /// `bitwiseXor(_:)` and stores the deferred result in this object.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to combine with this object.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitwiseXorInPlace(_ other: PythonInterpreter.SafePythonObject) throws {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceBitwiseXor(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
            if other.isBoundToPythonInterpreter {
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceBitwiseXor(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            } else {
                do {
                    self = try bitwiseXor(other)
                } catch let PythonError.typeError(_, opType1, opType2) {
                    throw PythonError.typeError(operation: "in place bitwise XOR", opType1: opType1, opType2: opType2)
                }
            }
        }
    }
    
    /// Replaces this safe Python object with its bitwise XOR against a Python-convertible Swift value.
    ///
    /// This overload adapts typed Swift values such as `Int` and `Bool`. Existing
    /// `SafePythonObject` values are forwarded to `bitwiseXorInPlace(_ other: SafePythonObject)`.
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// safe object, because general conversion needs an interpreter.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and combine with this object.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but this
    ///   object is still deferred, or `PythonError` if conversion or Python bitwise XOR fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitwiseXorInPlace(_ other: any SafePythonConvertible) throws {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            try bitwiseXorInPlace(safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try bitwiseXorInPlace(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitwiseXorInPlaceOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = lhs
            try result.bitwiseXorInPlace(rhs)
            return result
        } catch {
            fatalError("In place bitwise XOR failed: \(error).  Use `SafePythonObject.bitwiseXorInPlace()` for in place bitwise XOR that might throw.")
        }
    }
    
    // MARK: Bit Shift Left
    
    private static func deferredBitwiseShiftValue(_ object: PythonInterpreter.SafePythonObject) -> Int? {
        switch object.state {
        case .deferredInt(let value):
            return value
        case .deferredBool(let value):
            return value ? 1 : 0
        case .bound, .deferredDouble, .deferredString:
            return nil
        }
    }
    
    private static func checkedDeferredIntegerLeftShift(_ lhs: Int, _ rhs: Int) throws -> PythonInterpreter.SafePythonObject {
        guard rhs >= 0 else {
            throw PythonError.valueError("negative shift count")
        }
        
        guard rhs > 0 else {
            return PythonInterpreter.SafePythonObject(integerLiteral: lhs)
        }
        
        guard rhs < Int.bitWidth else {
            if lhs == 0 {
                return PythonInterpreter.SafePythonObject(integerLiteral: 0)
            }
            throw PythonError.conversionOverflow(
                value: "\(lhs) << \(rhs)",
                sourceType: "deferred Python integer left shift",
                targetType: "Swift Int"
            )
        }
        
        var result = lhs
        for _ in 0..<rhs {
            let doubled = result.multipliedReportingOverflow(by: 2)
            guard !doubled.overflow else {
                throw PythonError.conversionOverflow(
                    value: "\(lhs) << \(rhs)",
                    sourceType: "deferred Python integer left shift",
                    targetType: "Swift Int"
                )
            }
            result = doubled.partialValue
        }
        
        return PythonInterpreter.SafePythonObject(integerLiteral: result)
    }
    
    /// Returns the Python left-shift result of two safe Python objects.
    ///
    /// This follows Python `<<` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_Lshift`. Fully
    /// deferred `Int` and `Bool` values are handled locally; the result is always a
    /// deferred integer. Negative deferred shift counts throw `PythonError.valueError`,
    /// matching Python's `ValueError`. Deferred left shifts that exceed Swift2Python's
    /// local `Int` storage throw `PythonError.conversionOverflow`.
    ///
    /// - Parameters:
    ///   - other: The safe Python object providing the shift count.
    /// - Returns: The Python left-shift result.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, `PythonError.valueError` for
    ///   negative deferred shift counts, or `PythonError.conversionOverflow` if the deferred
    ///   result cannot fit in `Int`.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitShiftLeft(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitShiftLeft(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
            }
        case .deferredInt, .deferredBool:
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitShiftLeft(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredInt, .deferredBool:
                guard let lhsValue = Self.deferredBitwiseShiftValue(self), let rhsValue = Self.deferredBitwiseShiftValue(other) else {
                    throw PythonError.typeError(operation: "left shift", opType1: Self.deferredTypeName(self), opType2: Self.deferredTypeName(other))
                }
                return try Self.checkedDeferredIntegerLeftShift(lhsValue, rhsValue)
            case .deferredDouble, .deferredString:
                throw PythonError.typeError(operation: "left shift", opType1: Self.deferredTypeName(self), opType2: Self.deferredTypeName(other))
            }
        case .deferredDouble, .deferredString:
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitShiftLeft(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
                throw PythonError.typeError(operation: "left shift", opType1: Self.deferredTypeName(self), opType2: Self.deferredTypeName(other))
            }
        }
    }
    
    /// Returns the Python left-shift result of this safe Python object and a Python-convertible Swift value.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitShiftLeft(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try bitShiftLeft(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try bitShiftLeft(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitShiftLeftOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.bitShiftLeft(rhs)
        } catch {
            fatalError("Left shift failed: \(error).  Use `SafePythonObject.bitShiftLeft()` for left shift that might throw.")
        }
    }
    
    /// Replaces this safe Python object with its Python left-shift result.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitShiftLeftInPlace(_ other: PythonInterpreter.SafePythonObject) throws {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceBitShiftLeft(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
        case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
            if other.isBoundToPythonInterpreter {
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceBitShiftLeft(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            } else {
                do {
                    self = try bitShiftLeft(other)
                } catch let PythonError.typeError(_, opType1, opType2) {
                    throw PythonError.typeError(operation: "in place left shift", opType1: opType1, opType2: opType2)
                }
            }
        }
    }
    
    /// Replaces this safe Python object with its left shift against a Python-convertible Swift value.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitShiftLeftInPlace(_ other: any SafePythonConvertible) throws {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            try bitShiftLeftInPlace(safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try bitShiftLeftInPlace(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitShiftLeftInPlaceOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = lhs
            try result.bitShiftLeftInPlace(rhs)
            return result
        } catch {
            fatalError("In place left shift failed: \(error).  Use `SafePythonObject.bitShiftLeftInPlace()` for in place left shift that might throw.")
        }
    }
    
    // MARK: Bit Shift Right
    
    private static func checkedDeferredIntegerRightShift(_ lhs: Int, _ rhs: Int) throws -> PythonInterpreter.SafePythonObject {
        guard rhs >= 0 else {
            throw PythonError.valueError("negative shift count")
        }
        
        if rhs >= Int.bitWidth {
            return PythonInterpreter.SafePythonObject(integerLiteral: lhs < 0 ? -1 : 0)
        }
        
        return PythonInterpreter.SafePythonObject(integerLiteral: lhs >> rhs)
    }
    
    /// Returns the Python right-shift result of two safe Python objects.
    ///
    /// This follows Python `>>` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_Rshift`. Fully
    /// deferred `Int` and `Bool` values are handled locally; the result is always a
    /// deferred integer. Negative deferred shift counts throw `PythonError.valueError`,
    /// matching Python's `ValueError`.
    ///
    /// - Parameters:
    ///   - other: The safe Python object providing the shift count.
    /// - Returns: The Python right-shift result.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.valueError` for
    ///   negative deferred shift counts.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitShiftRight(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitShiftRight(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
            }
        case .deferredInt, .deferredBool:
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitShiftRight(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredInt, .deferredBool:
                guard let lhsValue = Self.deferredBitwiseShiftValue(self), let rhsValue = Self.deferredBitwiseShiftValue(other) else {
                    throw PythonError.typeError(operation: "right shift", opType1: Self.deferredTypeName(self), opType2: Self.deferredTypeName(other))
                }
                return try Self.checkedDeferredIntegerRightShift(lhsValue, rhsValue)
            case .deferredDouble, .deferredString:
                throw PythonError.typeError(operation: "right shift", opType1: Self.deferredTypeName(self), opType2: Self.deferredTypeName(other))
            }
        case .deferredDouble, .deferredString:
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitShiftRight(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
                throw PythonError.typeError(operation: "right shift", opType1: Self.deferredTypeName(self), opType2: Self.deferredTypeName(other))
            }
        }
    }
    
    /// Returns the Python right-shift result of this safe Python object and a Python-convertible Swift value.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitShiftRight(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try bitShiftRight(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try bitShiftRight(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitShiftRightOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.bitShiftRight(rhs)
        } catch {
            fatalError("Right shift failed: \(error).  Use `SafePythonObject.bitShiftRight()` for right shift that might throw.")
        }
    }
    
    /// Replaces this safe Python object with its Python right-shift result.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitShiftRightInPlace(_ other: PythonInterpreter.SafePythonObject) throws {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceBitShiftRight(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
            }
        case .deferredDouble, .deferredInt, .deferredString, .deferredBool:
            if other.isBoundToPythonInterpreter {
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceBitShiftRight(lhs: self.toSafePythonObject(interpreter: $0), rhs: other.toSafePythonObject(interpreter: $0))
                }
            } else {
                do {
                    self = try bitShiftRight(other)
                } catch let PythonError.typeError(_, opType1, opType2) {
                    throw PythonError.typeError(operation: "in place right shift", opType1: opType1, opType2: opType2)
                }
            }
        }
    }
    
    /// Replaces this safe Python object with its right shift against a Python-convertible Swift value.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func bitShiftRightInPlace(_ other: any SafePythonConvertible) throws {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            try bitShiftRightInPlace(safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try bitShiftRightInPlace(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitShiftRightInPlaceOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = lhs
            try result.bitShiftRightInPlace(rhs)
            return result
        } catch {
            fatalError("In place right shift failed: \(error).  Use `SafePythonObject.bitShiftRightInPlace()` for in place right shift that might throw.")
        }
    }
    
    // MARK: Bitwise NOT
    
    /// Returns the Python bitwise inversion of this safe Python object.
    ///
    /// This follows Python `~` semantics. If this object is already bound to an interpreter,
    /// the operation is delegated to Python with `PyNumber_Invert`. Fully deferred `Int`
    /// and `Bool` values are handled locally; deferred `Bool` produces an integer result,
    /// matching Python's `~True == -2` and `~False == -1` behavior.
    ///
    /// - Returns: The Python bitwise inversion result.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive values.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func bitwiseInvert() throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitwiseNot(self.toSafePythonObject(interpreter: $0))
            }
        case .deferredInt(let operandVal):
            return PythonInterpreter.SafePythonObject(integerLiteral: ~operandVal)
        case .deferredBool(let operandVal):
            return PythonInterpreter.SafePythonObject(integerLiteral: ~(operandVal ? 1 : 0))
        case .deferredDouble, .deferredString:
            throw PythonError.typeError(operation: "bitwise NOT", opType1: Self.deferredTypeName(self), opType2: "None")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func bitwiseNotOperator(_ operand: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try operand.bitwiseInvert()
        } catch {
            fatalError("Bitwise NOT failed: \(error).  Use `SafePythonObject.bitwiseInvert()` for bitwise NOT that might throw.")
        }
    }
    
    
}
