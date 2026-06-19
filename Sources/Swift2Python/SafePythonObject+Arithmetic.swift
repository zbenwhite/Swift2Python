//
//  SafePythonObject+Operator.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

import Foundation

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
    
    // MARK: Unary Positive
    
    /// Returns the Python unary-plus result of this safe Python object.
    ///
    /// This follows Python `+x` semantics. If this object is bound to an interpreter,
    /// the operation is delegated to Python with `PyNumber_Positive`, allowing custom
    /// Python objects to implement `__pos__`. Fully deferred `Int` and `Double` values
    /// return their numeric value unchanged; fully deferred `Bool` produces a deferred
    /// integer, matching Python's `+True == 1` and `+False == 0` behavior.
    ///
    /// - Returns: The Python unary-plus result.
    /// - Throws: `PythonError.safePythonException` if Python raises, or `PythonError.typeError`
    ///   for invalid fully deferred primitive values.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func positive() throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncPositive(self.toSafePythonObject(interpreter: $0))
            }
        case .deferredDouble(let value):
            return PythonInterpreter.SafePythonObject(floatLiteral: value)
        case .deferredInt(let value):
            return PythonInterpreter.SafePythonObject(integerLiteral: value)
        case .deferredBool(let value):
            return PythonInterpreter.SafePythonObject(integerLiteral: value ? 1 : 0)
        case .deferredString:
            throw PythonError.typeError(operation: "unary plus", opType1: Self.deferredTypeName(self), opType2: "None")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func positiveOperator(_ operand: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try operand.positive()
        } catch {
            fatalError("Unary plus failed: \(error).  Use `SafePythonObject.positive()` for unary plus that might throw.")
        }
    }
    
    // MARK: Unary Negative
    
    private static func checkedDeferredIntegerNegation(_ value: Int) throws -> PythonInterpreter.SafePythonObject {
        let result = value.multipliedReportingOverflow(by: -1)
        guard !result.overflow else {
            throw PythonError.conversionOverflow(
                value: "-\(value)",
                sourceType: "deferred Python integer negation",
                targetType: "Swift Int"
            )
        }
        
        return PythonInterpreter.SafePythonObject(integerLiteral: result.partialValue)
    }
    
    /// Returns the Python unary-minus result of this safe Python object.
    ///
    /// This follows Python `-x` semantics. If this object is bound to an interpreter,
    /// the operation is delegated to Python with `PyNumber_Negative`, allowing custom
    /// Python objects to implement `__neg__`. Fully deferred numeric and boolean values
    /// are handled locally. Deferred `Int.min` throws `PythonError.conversionOverflow`
    /// because Python would produce an arbitrary-precision integer that cannot fit in
    /// Swift2Python's deferred `Int` storage.
    ///
    /// - Returns: The Python unary-minus result.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive values, or `PythonError.conversionOverflow`
    ///   if fully deferred integer negation exceeds Swift2Python's deferred `Int` storage.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func negative() throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncNegative(self.toSafePythonObject(interpreter: $0))
            }
        case .deferredDouble(let value):
            return PythonInterpreter.SafePythonObject(floatLiteral: -value)
        case .deferredInt(let value):
            return try Self.checkedDeferredIntegerNegation(value)
        case .deferredBool(let value):
            return PythonInterpreter.SafePythonObject(integerLiteral: value ? -1 : 0)
        case .deferredString:
            throw PythonError.typeError(operation: "unary minus", opType1: Self.deferredTypeName(self), opType2: "None")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func negativeOperator(_ operand: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try operand.negative()
        } catch {
            fatalError("Unary minus failed: \(error).  Use `SafePythonObject.negative()` for unary minus that might throw.")
        }
    }
    
    // MARK: Absolute Value
    
    private static func checkedDeferredIntegerAbsolute(_ value: Int) throws -> PythonInterpreter.SafePythonObject {
        guard value != Int.min else {
            throw PythonError.conversionOverflow(
                value: "abs(\(value))",
                sourceType: "deferred Python integer absolute value",
                targetType: "Swift Int"
            )
        }
        
        return PythonInterpreter.SafePythonObject(integerLiteral: Swift.abs(value))
    }
    
    /// Returns the Python absolute value of this safe Python object.
    ///
    /// This follows Python `abs(x)` semantics. If this object is bound to an interpreter,
    /// the operation is delegated to Python with `PyNumber_Absolute`, allowing custom
    /// Python objects to implement `__abs__`. Fully deferred numeric and boolean values
    /// are handled locally. Deferred `Int.min` throws `PythonError.conversionOverflow`
    /// because Python would produce an arbitrary-precision integer that cannot fit in
    /// Swift2Python's deferred `Int` storage.
    ///
    /// - Returns: The Python absolute value result.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive values, or `PythonError.conversionOverflow`
    ///   if fully deferred integer absolute value exceeds Swift2Python's deferred `Int` storage.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func absolute() throws -> PythonInterpreter.SafePythonObject {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncAbsolute(self.toSafePythonObject(interpreter: $0))
            }
        case .deferredDouble(let value):
            return PythonInterpreter.SafePythonObject(floatLiteral: Swift.abs(value))
        case .deferredInt(let value):
            return try Self.checkedDeferredIntegerAbsolute(value)
        case .deferredBool(let value):
            return PythonInterpreter.SafePythonObject(integerLiteral: value ? 1 : 0)
        case .deferredString:
            throw PythonError.typeError(operation: "absolute value", opType1: Self.deferredTypeName(self), opType2: "None")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func absoluteOperator(_ operand: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try operand.absolute()
        } catch {
            fatalError("Absolute value failed: \(error).  Use `SafePythonObject.absolute()` for absolute value that might throw.")
        }
    }
    
    // MARK: Addition
    
    /// Adds two fully deferred integer values without allowing Swift integer overflow.
    ///
    /// Python integers are arbitrary precision, but deferred safe integers are stored as
    /// Swift `Int` until an interpreter is available. If the result does not fit in that
    /// storage, throw instead of letting Swift trap on overflow.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand deferred integer value.
    ///   - rhs: The right-hand deferred integer value.
    /// - Returns: A deferred safe Python integer containing the checked sum.
    /// - Throws: `PythonError.conversionOverflow` when the checked sum cannot fit in `Int`.
    private static func checkedDeferredIntegerAddition(_ lhs: Int, _ rhs: Int) throws -> PythonInterpreter.SafePythonObject {
        let result = lhs.addingReportingOverflow(rhs)
        guard !result.overflow else {
            throw PythonError.conversionOverflow(
                value: "\(lhs) + \(rhs)",
                sourceType: "deferred Python integer addition",
                targetType: "Swift Int"
            )
        }
        
        return PythonInterpreter.SafePythonObject(integerLiteral: result.partialValue)
    }
    
    /// Adds another safe Python object to this safe Python object.
    ///
    /// This follows Python `+` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_Add`. If both
    /// operands are deferred safe values, Swift2Python performs the same primitive
    /// numeric, boolean, and string combinations locally until the result is bound.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to add.
    /// - Returns: The Python addition result.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.conversionOverflow`
    ///   if fully deferred integer addition exceeds Swift2Python's deferred `Int` storage.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func add(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        
        // The throwing addition function.  For materialized python objects, this calls PyNumber_Add
        // using the interpreter. If only one is materialized, materialize the other and do the same.
        // If neither are materialized (why?) then add them the way Python would add them:
        // LHS     RHS      ACTION / Type
        // -----   ------   ---------
        // bound   any      PyNumber_Add -- preserve term order
        // any     bound    PyNumber_Add -- preserve term order
        // double  double   double
        // double  int      double
        // double  string   ERR: typeError
        // double  bool     double
        // int     int      int, or ERR: conversionOverflow if outside deferred Int storage
        // int     double   double
        // int     string   ERR: typeError
        // int     bool     int, or ERR: conversionOverflow if outside deferred Int storage
        // string  double   ERR: typeError
        // string  int      ERR: typeError
        // string  string   string concatenation
        // string  bool     ERR: typeError
        // bool    double   double
        // bool    int      int, or ERR: conversionOverflow if outside deferred Int storage
        // bool    string   ERR: typeError
        // bool    bool     int
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncAdd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncAdd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "addition", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncAdd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) + rhsVal)
            case .deferredInt(let rhsVal):
                return try Self.checkedDeferredIntegerAddition(lhsVal, rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "addition", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                return try Self.checkedDeferredIntegerAddition(lhsVal, rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncAdd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "addition", opType1: "String", opType2: "Double")
            case .deferredInt:
                throw PythonError.typeError(operation: "addition", opType1: "String", opType2: "Int")
            case .deferredString(let rhsVal):
                return PythonInterpreter.SafePythonObject(stringLiteral: lhsVal + rhsVal)
            case .deferredBool:
                throw PythonError.typeError(operation: "addition", opType1: "String", opType2: "Bool")
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncAdd(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) + rhsVal)
            case .deferredInt(let rhsVal):
                return try Self.checkedDeferredIntegerAddition(lhsVal ? 1 : 0, rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "addition", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                return try Self.checkedDeferredIntegerAddition(lhsVal ? 1 : 0, rhsVal ? 1 : 0)
            }
        }
    }
    
    /// Adds a Python-convertible Swift value to this safe Python object.
    ///
    /// This overload is an adapter for typed Swift values such as `Int`, `Double`,
    /// `Bool`, `String`, and container conformers. Existing `SafePythonObject` values
    /// are forwarded to `add(_ other: SafePythonObject)` so deferred-safe behavior stays
    /// centralized in the primary overload.
    ///
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// `SafePythonObject`. Without a bound receiver, there is no interpreter available to
    /// perform general `SafePythonConvertible` conversion.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and add.
    /// - Returns: The Python addition result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but
    ///   this object is still deferred, or `PythonError` if conversion or Python addition fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func add(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try add(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try add(other.toSafePythonObject(interpreter: interpreter))
    }
    
    // A static function to be used for the + operator.  The + operator does not throw, so this causes
    // a fatal error if the types are incompatible.  Use SafePythonObject.add() for a throwing add.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func addOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.add(rhs)
        } catch {
            fatalError("Addition failed: \(error).  Use `SafePythonObject.add()` for addition that might throw.")
        }
    }
    
    /// Adds another safe Python object to this safe Python object in place.
    ///
    /// This follows Python `+=` semantics. If this object is bound, or if the addend is
    /// bound, the operation is delegated to Python with `PyNumber_InPlaceAdd`. Python may
    /// mutate mutable objects in place or return a new object for immutable values; this
    /// safe object is updated to reference the result either way.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to add.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.conversionOverflow`
    ///   if fully deferred integer addition exceeds Swift2Python's deferred `Int` storage.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func addInPlace(_ other: PythonInterpreter.SafePythonObject) throws  {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceAdd(sumend: self.toSafePythonObject(interpreter: $0), addend: other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceAdd(sumend: self.toSafePythonObject(interpreter: $0), addend: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + rhsVal)
            case .deferredInt(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "in place addition", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceAdd(sumend: self.toSafePythonObject(interpreter: $0), addend: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) + rhsVal)
            case .deferredInt(let rhsVal):
                self = try Self.checkedDeferredIntegerAddition(lhsVal, rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "in place addition", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                self = try Self.checkedDeferredIntegerAddition(lhsVal, rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceAdd(sumend: self.toSafePythonObject(interpreter: $0), addend: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "in place addition", opType1: "String", opType2: "Double")
            case .deferredInt:
                throw PythonError.typeError(operation: "in place addition", opType1: "String", opType2: "Int")
            case .deferredString(let rhsVal):
                self = PythonInterpreter.SafePythonObject(stringLiteral: lhsVal + rhsVal)
            case .deferredBool:
                throw PythonError.typeError(operation: "in place addition", opType1: "String", opType2: "Bool")
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceAdd(sumend: self.toSafePythonObject(interpreter: $0), addend: other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) + rhsVal)
            case .deferredInt(let rhsVal):
                self = try Self.checkedDeferredIntegerAddition(lhsVal ? 1 : 0, rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "in place addition", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                self = try Self.checkedDeferredIntegerAddition(lhsVal ? 1 : 0, rhsVal ? 1 : 0)
            }
        }
    }
    
    /// Adds a Python-convertible Swift value to this safe Python object in place.
    ///
    /// This overload is an adapter for typed Swift values such as `Int`, `Double`,
    /// `Bool`, `String`, and container conformers. Existing `SafePythonObject` values
    /// are forwarded to `addInPlace(_ other: SafePythonObject)` so deferred-safe behavior
    /// stays centralized in the primary overload.
    ///
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// `SafePythonObject`. Without a bound receiver, there is no interpreter available to
    /// perform general `SafePythonConvertible` conversion.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and add.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but
    ///   this object is still deferred, or `PythonError` if conversion or Python addition fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func addInPlace(_ other: any SafePythonConvertible) throws {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            try addInPlace(safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try addInPlace(other.toSafePythonObject(interpreter: interpreter))
    }
    
    // A static function to be used for the += operator.  The += operator does not throw, so this causes
    // a fatal error if the types are incompatible.  Use SafePythonObject.addInPlace() for a throwing
    // in place add.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func addInPlaceOperator(sumend: PythonInterpreter.SafePythonObject, addend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = sumend
            try result.addInPlace(addend)
            return result
        } catch {
            fatalError("In place addition failed: \(error).  Use `SafePythonObject.addInPlace()` for in place addition that might throw.")
        }
    }
    
    // MARK: Subtraction
    
    /// Subtracts two fully deferred integer values without allowing Swift integer overflow.
    ///
    /// Python integers are arbitrary precision, but deferred safe integers are stored as
    /// Swift `Int` until an interpreter is available. If the result does not fit in that
    /// storage, throw instead of letting Swift trap on overflow.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand deferred integer value.
    ///   - rhs: The right-hand deferred integer value.
    /// - Returns: A deferred safe Python integer containing the checked difference.
    /// - Throws: `PythonError.conversionOverflow` when the checked difference cannot fit in `Int`.
    private static func checkedDeferredIntegerSubtraction(_ lhs: Int, _ rhs: Int) throws -> PythonInterpreter.SafePythonObject {
        let result = lhs.subtractingReportingOverflow(rhs)
        guard !result.overflow else {
            throw PythonError.conversionOverflow(
                value: "\(lhs) - \(rhs)",
                sourceType: "deferred Python integer subtraction",
                targetType: "Swift Int"
            )
        }
        
        return PythonInterpreter.SafePythonObject(integerLiteral: result.partialValue)
    }
    
    /// Subtracts another safe Python object from this safe Python object.
    ///
    /// This follows Python `-` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_Subtract`. If both
    /// operands are deferred safe values, Swift2Python performs the same primitive
    /// numeric and boolean combinations locally until the result is bound.
    ///
    /// - Parameters:
    ///   - subtrahend: The safe Python object to subtract.
    /// - Returns: The Python subtraction result.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.conversionOverflow`
    ///   if fully deferred integer subtraction exceeds Swift2Python's deferred `Int` storage.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func subtract(subtrahend: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        
        // The throwing subtraction function.  For materialized python objects, this calls PyNumber_Subtract
        // using the interpreter. If only one is materialized, materialize the other and do the same.
        // If neither are materialized (why?) then subtract them the way Python would subtract them:
        // LHS     RHS      ACTION / Type
        // -----   ------   ---------
        // bound   any      PyNumber_Subtract -- preserve term order
        // any     bound    PyNumber_Subtract -- preserve term order
        // double  double   double
        // double  int      double
        // double  string   ERR: typeError
        // double  bool     double
        // int     int      int, or ERR: conversionOverflow if outside deferred Int storage
        // int     double   double
        // int     string   ERR: typeError
        // int     bool     int, or ERR: conversionOverflow if outside deferred Int storage
        // string  double   ERR: typeError
        // string  int      ERR: typeError
        // string  string   ERR: typeError
        // string  bool     ERR: typeError
        // bool    double   double
        // bool    int      int, or ERR: conversionOverflow if outside deferred Int storage
        // bool    string   ERR: typeError
        // bool    bool     int
        switch state {
            
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncSubtract(minuend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch subtrahend.state {
            case .bound:
                let localInterpreter = subtrahend.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncSubtract(minuend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "subtraction", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch subtrahend.state {
            case .bound:
                let localInterpreter = subtrahend.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncSubtract(minuend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) - rhsVal)
            case .deferredInt(let rhsVal):
                return try Self.checkedDeferredIntegerSubtraction(lhsVal, rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "subtraction", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                return try Self.checkedDeferredIntegerSubtraction(lhsVal, rhsVal ? 1 : 0)
            }
        
        case .deferredString:
            switch subtrahend.state {
            case .bound:
                let localInterpreter = subtrahend.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncSubtract(minuend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "subtraction", opType1: "String", opType2: "Double")
            case .deferredInt:
                throw PythonError.typeError(operation: "subtraction", opType1: "String", opType2: "Int")
            case .deferredString:
                throw PythonError.typeError(operation: "subtraction", opType1: "String", opType2: "String")
            case .deferredBool:
                throw PythonError.typeError(operation: "subtraction", opType1: "String", opType2: "Bool")
            }
            
        case .deferredBool(let lhsVal):
            switch subtrahend.state {
            case .bound:
                let localInterpreter = subtrahend.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncSubtract(minuend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) - rhsVal)
            case .deferredInt(let rhsVal):
                return try Self.checkedDeferredIntegerSubtraction(lhsVal ? 1 : 0, rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "subtraction", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                return try Self.checkedDeferredIntegerSubtraction(lhsVal ? 1 : 0, rhsVal ? 1 : 0)
            }
        }
    }
    
    /// Subtracts a Python-convertible Swift value from this safe Python object.
    ///
    /// This overload is an adapter for typed Swift values such as `Int`, `Double`,
    /// `Bool`, `String`, and container conformers. Existing `SafePythonObject` values
    /// are forwarded to `subtract(subtrahend:)` so deferred-safe behavior stays centralized
    /// in the primary overload.
    ///
    /// The receiver must already be bound to an interpreter unless `subtrahend` is already
    /// a `SafePythonObject`. Without a bound receiver, there is no interpreter available to
    /// perform general `SafePythonConvertible` conversion.
    ///
    /// - Parameters:
    ///   - subtrahend: The Swift value to convert and subtract.
    /// - Returns: The Python subtraction result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but
    ///   this object is still deferred, or `PythonError` if conversion or Python subtraction fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func subtract(subtrahend: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = subtrahend as? PythonInterpreter.SafePythonObject {
            return try subtract(subtrahend: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: subtrahend),
                sourceType: String(describing: type(of: subtrahend)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try subtract(subtrahend: subtrahend.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func subtractOperator(minuend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try minuend.subtract(subtrahend:subtrahend)
        } catch {
            fatalError("Subtraction failed: \(error).  Use `SafePythonObject.subtract()` for subtraction that might throw.")
        }
    }
    
    /// Subtracts another safe Python object from this safe Python object in place.
    ///
    /// This follows Python `-=` semantics. If this object is bound, or if the subtrahend is
    /// bound, the operation is delegated to Python with `PyNumber_InPlaceSubtract`. Python may
    /// mutate mutable objects in place or return a new object for immutable values; this
    /// safe object is updated to reference the result either way.
    ///
    /// - Parameters:
    ///   - subtrahend: The safe Python object to subtract.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.conversionOverflow`
    ///   if fully deferred integer subtraction exceeds Swift2Python's deferred `Int` storage.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func subtractInPlace(subtrahend: PythonInterpreter.SafePythonObject) throws {
        switch state {
            
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceSubtract(diffend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch subtrahend.state {
            case .bound:
                let localInterpreter = subtrahend.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceSubtract(diffend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - rhsVal)
            case .deferredInt(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "in place subtraction", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch subtrahend.state {
            case .bound:
                let localInterpreter = subtrahend.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceSubtract(diffend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) - rhsVal)
            case .deferredInt(let rhsVal):
                self = try Self.checkedDeferredIntegerSubtraction(lhsVal, rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "in place subtraction", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                self = try Self.checkedDeferredIntegerSubtraction(lhsVal, rhsVal ? 1 : 0)
            }
        
        case .deferredString:
            switch subtrahend.state {
            case .bound:
                let localInterpreter = subtrahend.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceSubtract(diffend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "in place subtraction", opType1: "String", opType2: "Double")
            case .deferredInt:
                throw PythonError.typeError(operation: "in place subtraction", opType1: "String", opType2: "Int")
            case .deferredString:
                throw PythonError.typeError(operation: "in place subtraction", opType1: "String", opType2: "String")
            case .deferredBool:
                throw PythonError.typeError(operation: "in place subtraction", opType1: "String", opType2: "Bool")
            }
            
        case .deferredBool(let lhsVal):
            switch subtrahend.state {
            case .bound:
                let localInterpreter = subtrahend.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceSubtract(diffend: self.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) - rhsVal)
            case .deferredInt(let rhsVal):
                self = try Self.checkedDeferredIntegerSubtraction(lhsVal ? 1 : 0, rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "in place subtraction", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                self = try Self.checkedDeferredIntegerSubtraction(lhsVal ? 1 : 0, rhsVal ? 1 : 0)
            }
        }
    }
    
    /// Subtracts a Python-convertible Swift value from this safe Python object in place.
    ///
    /// This overload is an adapter for typed Swift values such as `Int`, `Double`,
    /// `Bool`, `String`, and container conformers. Existing `SafePythonObject` values
    /// are forwarded to `subtractInPlace(subtrahend:)` so deferred-safe behavior stays
    /// centralized in the primary overload.
    ///
    /// The receiver must already be bound to an interpreter unless `subtrahend` is already
    /// a `SafePythonObject`. Without a bound receiver, there is no interpreter available to
    /// perform general `SafePythonConvertible` conversion.
    ///
    /// - Parameters:
    ///   - subtrahend: The Swift value to convert and subtract.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but
    ///   this object is still deferred, or `PythonError` if conversion or Python subtraction fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func subtractInPlace(subtrahend: any SafePythonConvertible) throws {
        if let safeObject = subtrahend as? PythonInterpreter.SafePythonObject {
            try subtractInPlace(subtrahend: safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: subtrahend),
                sourceType: String(describing: type(of: subtrahend)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try subtractInPlace(subtrahend: subtrahend.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func subtractInPlaceOperator(diffend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = diffend
            try result.subtractInPlace(subtrahend: subtrahend)
            return result
        } catch {
            fatalError("In place subtraction failed: \(error).  Use `SafePythonObject.subtractInPlace()` for in place subtraction that might throw.")
        }
    }
    
    // MARK: Multiplication
    
    /// Multiplies two fully deferred integer values without allowing Swift integer overflow.
    ///
    /// Python integers are arbitrary precision, but deferred safe integers are stored as
    /// Swift `Int` until an interpreter is available. If the result does not fit in that
    /// storage, throw instead of letting Swift trap on overflow.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand deferred integer value.
    ///   - rhs: The right-hand deferred integer value.
    /// - Returns: A deferred safe Python integer containing the checked product.
    /// - Throws: `PythonError.conversionOverflow` when the checked product cannot fit in `Int`.
    private static func checkedDeferredIntegerMultiplication(_ lhs: Int, _ rhs: Int) throws -> PythonInterpreter.SafePythonObject {
        let result = lhs.multipliedReportingOverflow(by: rhs)
        guard !result.overflow else {
            throw PythonError.conversionOverflow(
                value: "\(lhs) * \(rhs)",
                sourceType: "deferred Python integer multiplication",
                targetType: "Swift Int"
            )
        }
        
        return PythonInterpreter.SafePythonObject(integerLiteral: result.partialValue)
    }
    
    /// Multiplies this safe Python object by another safe Python object.
    ///
    /// This follows Python `*` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_Multiply`. If both
    /// operands are deferred safe values, Swift2Python performs the same primitive numeric,
    /// boolean, and string repetition combinations locally until the result is bound.
    ///
    /// - Parameters:
    ///   - other: The safe Python object to multiply by.
    /// - Returns: The Python multiplication result.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.conversionOverflow`
    ///   if fully deferred integer multiplication exceeds Swift2Python's deferred `Int` storage.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func multiply(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        
        // The throwing multiplication function.  For materialized python objects, this calls PyNumber_Multiply
        // using the interpreter. If only one is materialized, materialize the other and do the same.
        // If neither are materialized (why?) then multiply them the way Python would multiply them:
        // LHS     RHS      ACTION / Type
        // -----   ------   ---------
        // bound   any      PyNumber_Multiply -- preserve factor order
        // any     bound    PyNumber_Multiply -- preserve factor order
        // double  double   double
        // double  int      double
        // double  string   ERR: typeError
        // double  bool     double
        // int     int      int, or ERR: conversionOverflow if outside deferred Int storage
        // int     double   double
        // int     string   string repetition
        // int     bool     int
        // string  double   ERR: typeError
        // string  int      string repetition
        // string  string   ERR: typeError
        // string  bool     string repetition
        // bool    double   double
        // bool    int      int
        // bool    string   string repetition
        // bool    bool     int
        switch state {
            
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncMultiply(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncMultiply(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "multiplication", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncMultiply(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) * rhsVal)
            case .deferredInt(let rhsVal):
                return try Self.checkedDeferredIntegerMultiplication(lhsVal, rhsVal)
            case .deferredString(let rhsVal):
                return (lhsVal < 1) ? PythonInterpreter.SafePythonObject(stringLiteral: "") : PythonInterpreter.SafePythonObject(stringLiteral: String(repeating: rhsVal, count: lhsVal))
            case .deferredBool(let rhsVal):
                return try Self.checkedDeferredIntegerMultiplication(lhsVal, rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncMultiply(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "multiplication", opType1: "String", opType2: "Double")
            case .deferredInt(let rhsVal):
                return (rhsVal < 1) ? PythonInterpreter.SafePythonObject(stringLiteral: "") : PythonInterpreter.SafePythonObject(stringLiteral: String(repeating: lhsVal, count: rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "multiplication", opType1: "String", opType2: "String")
            case .deferredBool(let rhsVal):
                return rhsVal ? PythonInterpreter.SafePythonObject(stringLiteral: lhsVal) : PythonInterpreter.SafePythonObject(stringLiteral: "")
            }
            
        case .deferredBool(let lhsVal):
            switch other.state {
            case .bound:
                let localInterpreter = other.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncMultiply(self.toSafePythonObject(interpreter: $0), other.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) * rhsVal)
            case .deferredInt(let rhsVal):
                return try Self.checkedDeferredIntegerMultiplication(lhsVal ? 1 : 0, rhsVal)
            case .deferredString(let rhsVal):
                return lhsVal ? PythonInterpreter.SafePythonObject(stringLiteral: rhsVal) : PythonInterpreter.SafePythonObject(stringLiteral: "")
            case .deferredBool(let rhsVal):
                return try Self.checkedDeferredIntegerMultiplication(lhsVal ? 1 : 0, rhsVal ? 1 : 0)
            }
        }
    }
    
    /// Multiplies this safe Python object by a Python-convertible Swift value.
    ///
    /// This overload is an adapter for typed Swift values such as `Int`, `Double`,
    /// `Bool`, `String`, and container conformers. Existing `SafePythonObject` values
    /// are forwarded to `multiply(_:)` so deferred-safe behavior stays centralized in
    /// the primary overload.
    ///
    /// The receiver must already be bound to an interpreter unless `other` is already a
    /// `SafePythonObject`. Without a bound receiver, there is no interpreter available to
    /// perform general `SafePythonConvertible` conversion.
    ///
    /// - Parameters:
    ///   - other: The Swift value to convert and multiply by.
    /// - Returns: The Python multiplication result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but
    ///   this object is still deferred, or `PythonError` if conversion or Python multiplication fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func multiply(_ other: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = other as? PythonInterpreter.SafePythonObject {
            return try multiply(safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: other),
                sourceType: String(describing: type(of: other)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try multiply(other.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func multiplyOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.multiply(rhs)
        } catch {
            fatalError("Multiplication failed: \(error).  Use `SafePythonObject.multiply()` for multiplication that might throw.")
        }
    }
    
    /// Multiplies this safe Python object by another safe Python object in place.
    ///
    /// This follows Python `*=` semantics. If this object is bound, or if the multiplicand is
    /// bound, the operation is delegated to Python with `PyNumber_InPlaceMultiply`. Python may
    /// mutate mutable objects in place or return a new object for immutable values; this
    /// safe object is updated to reference the result either way.
    ///
    /// - Parameters:
    ///   - multiplicand: The safe Python object to multiply by.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.conversionOverflow`
    ///   if fully deferred integer multiplication exceeds Swift2Python's deferred `Int` storage.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func multiplyInPlace(_ multiplicand: PythonInterpreter.SafePythonObject) throws {
        switch state {
            
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceMultiply(productand: self.toSafePythonObject(interpreter: $0), multiplicand: multiplicand.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch multiplicand.state {
            case .bound:
                let localInterpreter = multiplicand.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceMultiply(productand: self.toSafePythonObject(interpreter: $0), multiplicand: multiplicand.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * rhsVal)
            case .deferredInt(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "in place multiplication", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch multiplicand.state {
            case .bound:
                let localInterpreter = multiplicand.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceMultiply(productand: self.toSafePythonObject(interpreter: $0), multiplicand: multiplicand.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) * rhsVal)
            case .deferredInt(let rhsVal):
                self = try Self.checkedDeferredIntegerMultiplication(lhsVal, rhsVal)
            case .deferredString(let rhsVal):
                self = (lhsVal < 1) ? PythonInterpreter.SafePythonObject(stringLiteral: "") : PythonInterpreter.SafePythonObject(stringLiteral: String(repeating: rhsVal, count: lhsVal))
            case .deferredBool(let rhsVal):
                self = try Self.checkedDeferredIntegerMultiplication(lhsVal, rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch multiplicand.state {
            case .bound:
                let localInterpreter = multiplicand.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceMultiply(productand: self.toSafePythonObject(interpreter: $0), multiplicand: multiplicand.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "in place multiplication", opType1: "String", opType2: "Double")
            case .deferredInt(let rhsVal):
                self = (rhsVal < 1) ? PythonInterpreter.SafePythonObject(stringLiteral: "") : PythonInterpreter.SafePythonObject(stringLiteral: String(repeating: lhsVal, count: rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "in place multiplication", opType1: "String", opType2: "String")
            case .deferredBool(let rhsVal):
                self = rhsVal ? PythonInterpreter.SafePythonObject(stringLiteral: lhsVal) : PythonInterpreter.SafePythonObject(stringLiteral: "")
            }
            
        case .deferredBool(let lhsVal):
            switch multiplicand.state {
            case .bound:
                let localInterpreter = multiplicand.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceMultiply(productand: self.toSafePythonObject(interpreter: $0), multiplicand: multiplicand.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                self = PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) * rhsVal)
            case .deferredInt(let rhsVal):
                self = try Self.checkedDeferredIntegerMultiplication(lhsVal ? 1 : 0, rhsVal)
            case .deferredString(let rhsVal):
                self = lhsVal ? PythonInterpreter.SafePythonObject(stringLiteral: rhsVal) : PythonInterpreter.SafePythonObject(stringLiteral: "")
            case .deferredBool(let rhsVal):
                self = try Self.checkedDeferredIntegerMultiplication(lhsVal ? 1 : 0, rhsVal ? 1 : 0)
            }
        }
    }
    
    /// Multiplies this safe Python object by a Python-convertible Swift value in place.
    ///
    /// This overload is an adapter for typed Swift values such as `Int`, `Double`,
    /// `Bool`, `String`, and container conformers. Existing `SafePythonObject` values
    /// are forwarded to `multiplyInPlace(_:)` so deferred-safe behavior stays centralized
    /// in the primary overload.
    ///
    /// The receiver must already be bound to an interpreter unless `multiplicand` is already
    /// a `SafePythonObject`. Without a bound receiver, there is no interpreter available to
    /// perform general `SafePythonConvertible` conversion.
    ///
    /// - Parameters:
    ///   - multiplicand: The Swift value to convert and multiply by.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but
    ///   this object is still deferred, or `PythonError` if conversion or Python multiplication fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func multiplyInPlace(_ multiplicand: any SafePythonConvertible) throws {
        if let safeObject = multiplicand as? PythonInterpreter.SafePythonObject {
            try multiplyInPlace(safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: multiplicand),
                sourceType: String(describing: type(of: multiplicand)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try multiplyInPlace(multiplicand.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func multiplyInPlaceOperator(productand: PythonInterpreter.SafePythonObject, multiplicand: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = productand
            try result.multiplyInPlace(multiplicand)
            return result
        } catch {
            fatalError("In place multiplication failed: \(error).  Use `SafePythonObject.multiplyInPlace()` for in place multiplication that might throw.")
        }
    }
    
    // MARK: Division
    
    /// Divides this safe Python object by another safe Python object.
    ///
    /// This follows Python true-division `/` semantics. If either operand is already bound to an
    /// interpreter, the operation is delegated to Python with `PyNumber_TrueDivide`. If both
    /// operands are deferred safe values, Swift2Python performs the same primitive numeric and
    /// boolean combinations locally until the result is bound. Successful numeric division always
    /// returns a deferred double.
    ///
    /// - Parameters:
    ///   - divisor: The safe Python object to divide by.
    /// - Returns: The Python true-division result.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.divideByZero` for
    ///   fully deferred zero divisors.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func divide(divisor: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        
        // The throwing division function.  For materialized python objects, this calls PyNumber_TrueDivide
        // using the interpreter. If only one is materialized, materialize the other and do the same.
        // If neither are materialized (why?) then divide them the way Python would divide them.
        // Division by zero results in PythonError.divideByZero
        // LHS     RHS      ACTION / Type
        // -----   ------   ---------
        // bound   any      PyNumber_TrueDivide -- preserve operand order
        // any     bound    PyNumber_TrueDivide -- preserve operand order
        // double  double   double
        // double  int      double
        // double  string   ERR: typeError
        // double  bool     double, or ERR: divideByZero when rhs is false
        // int     int      double
        // int     double   double
        // int     string   ERR: typeError
        // int     bool     double, or ERR: divideByZero when rhs is false
        // string  double   ERR: typeError
        // string  int      ERR: typeError
        // string  string   ERR: typeError
        // string  bool     ERR: typeError
        // bool    double   double
        // bool    int      double
        // bool    string   ERR: typeError
        // bool    bool     double, or ERR: divideByZero when rhs is false
        switch self.state {
            
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncDivide(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncDivide(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal / Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "division", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal)
            }
            
        case .deferredInt(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncDivide(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) / Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "division", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal))
            }
            
        case .deferredString:
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncDivide(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "division", opType1: "String", opType2: "Double")
            case .deferredInt:
                throw PythonError.typeError(operation: "division", opType1: "String", opType2: "Int")
            case .deferredString:
                throw PythonError.typeError(operation: "division", opType1: "String", opType2: "String")
            case .deferredBool:
                throw PythonError.typeError(operation: "division", opType1: "String", opType2: "Bool")
            }
            
        case .deferredBool(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncDivide(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "division", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal ? 1.0 : 0.0)
            }
        }
    }
    
    /// Divides this safe Python object by a Python-convertible Swift value.
    ///
    /// This overload is an adapter for typed Swift values such as `Int`, `Double`,
    /// `Bool`, `String`, and container conformers. Existing `SafePythonObject` values
    /// are forwarded to `divide(divisor:)` so deferred-safe behavior stays centralized
    /// in the primary overload.
    ///
    /// The receiver must already be bound to an interpreter unless `divisor` is already a
    /// `SafePythonObject`. Without a bound receiver, there is no interpreter available to
    /// perform general `SafePythonConvertible` conversion.
    ///
    /// - Parameters:
    ///   - divisor: The Swift value to convert and divide by.
    /// - Returns: The Python true-division result.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but
    ///   this object is still deferred, or `PythonError` if conversion or Python division fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func divide(divisor: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = divisor as? PythonInterpreter.SafePythonObject {
            return try divide(divisor: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: divisor),
                sourceType: String(describing: type(of: divisor)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try divide(divisor: divisor.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func divideOperator(dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try dividend.divide(divisor: divisor)
        } catch {
            fatalError("Division failed: \(error).  Use `SafePythonObject.divide()` for division that might throw.")
        }
    }
    
    /// Divides this safe Python object by another safe Python object in place.
    ///
    /// This follows Python `/=` semantics. If this object is bound, or if the divisor is
    /// bound, the operation is delegated to Python with `PyNumber_InPlaceTrueDivide`. Python may
    /// mutate mutable objects in place or return a new object for immutable values; this
    /// safe object is updated to reference the result either way.
    ///
    /// - Parameters:
    ///   - divisor: The safe Python object to divide by.
    /// - Throws: `PythonError.safePythonException` if Python raises, `PythonError.typeError`
    ///   for invalid fully deferred primitive combinations, or `PythonError.divideByZero` for
    ///   fully deferred zero divisors.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func divideInPlace(divisor: PythonInterpreter.SafePythonObject) throws {
        switch state {
            
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceDivide(quotientand: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceDivide(quotientand: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal / Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "in place division", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal)
            }
            
        case .deferredInt(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceDivide(quotientand: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) / Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "in place division", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal))
            }
            
        case .deferredString:
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceDivide(quotientand: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "in place division", opType1: "String", opType2: "Double")
            case .deferredInt:
                throw PythonError.typeError(operation: "in place division", opType1: "String", opType2: "Int")
            case .deferredString:
                throw PythonError.typeError(operation: "in place division", opType1: "String", opType2: "String")
            case .deferredBool:
                throw PythonError.typeError(operation: "in place division", opType1: "String", opType2: "Bool")
            }
            
        case .deferredBool(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceDivide(quotientand: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / Double(rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "in place division", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                self = PythonInterpreter.SafePythonObject(floatLiteral: lhsVal ? 1.0 : 0.0)
            }
        }
    }
    
    /// Divides this safe Python object by a Python-convertible Swift value in place.
    ///
    /// This overload is an adapter for typed Swift values such as `Int`, `Double`,
    /// `Bool`, `String`, and container conformers. Existing `SafePythonObject` values
    /// are forwarded to `divideInPlace(divisor:)` so deferred-safe behavior stays centralized
    /// in the primary overload.
    ///
    /// The receiver must already be bound to an interpreter unless `divisor` is already
    /// a `SafePythonObject`. Without a bound receiver, there is no interpreter available to
    /// perform general `SafePythonConvertible` conversion.
    ///
    /// - Parameters:
    ///   - divisor: The Swift value to convert and divide by.
    /// - Throws: `PythonError.conversionType` if conversion requires an interpreter but
    ///   this object is still deferred, or `PythonError` if conversion or Python division fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func divideInPlace(divisor: any SafePythonConvertible) throws {
        if let safeObject = divisor as? PythonInterpreter.SafePythonObject {
            try divideInPlace(divisor: safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: divisor),
                sourceType: String(describing: type(of: divisor)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try divideInPlace(divisor: divisor.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func divideInPlaceOperator(quotientand: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = quotientand
            try result.divideInPlace(divisor: divisor)
            return result
        } catch {
            fatalError("In place division failed: \(error).  Use `SafePythonObject.divideInPlace()` for in place division that might throw.")
        }
    }
    
    // MARK: Modulus
    
    private static func pythonModulus(lhs: Double, rhs: Double) -> Double {
        lhs - rhs * floor(lhs / rhs)
    }
    
    private static func pythonIntegerModulus(lhs: Int, rhs: Int) throws -> Int {
        if lhs == Int.min && rhs == -1 {
            return 0
        }
        
        let remainder = lhs % rhs
        if remainder != 0 && ((rhs > 0 && remainder < 0) || (rhs < 0 && remainder > 0)) {
            return remainder + rhs
        }
        return remainder
    }
    
    /// Returns the Python remainder of this safe Python object divided by another safe Python object.
    ///
    /// If either operand is already bound to an interpreter, this delegates to CPython's
    /// `PyNumber_Remainder`. If both operands are still deferred Swift literals, this applies
    /// Python-compatible `%` behavior locally, including Python's sign rule for integer remainders.
    ///
    /// - Parameters:
    ///   - divisor: The divisor used for the Python `%` operation.
    /// - Returns: The Python remainder result.
    /// - Throws: `PythonError.divideByZero` for fully deferred zero divisors,
    ///   `PythonError.typeError` for unsupported fully deferred operand pairs, or `PythonError`
    ///   if Python raises or conversion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func modulus(divisor: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        
        // The throwing modulus function. For materialized Python objects, this calls PyNumber_Remainder
        // using the interpreter. If only one side is materialized, materialize the other and do the same.
        // If neither side is materialized, do the operation Python would do.
        // Division by zero results in PythonError.divideByZero.
        // LHS     RHS      ACTION / Type
        // -----   ------   ---------
        // bound   any      PyNumber_Remainder
        // any     bound    PyNumber_Remainder
        // double  double   double
        // double  int      double
        // double  string   ERR: typeError
        // double  bool     double
        // int     int      int
        // int     double   double
        // int     string   ERR: typeError
        // int     bool     int
        // string  double   ERR: typeError
        // string  int      ERR: typeError
        // string  string   ERR: typeError
        // string  bool     ERR: typeError
        // bool    double   double
        // bool    int      int
        // bool    string   ERR: typeError
        // bool    bool     int
        
        switch self.state {
            
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncModulus(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncModulus(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Self.pythonModulus(lhs: lhsVal, rhs: rhsVal))
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Self.pythonModulus(lhs: lhsVal, rhs: Double(rhsVal)))
            case .deferredString:
                throw PythonError.typeError(operation: "modulus", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Self.pythonModulus(lhs: lhsVal, rhs: 1.0))
            }
            
        case .deferredInt(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncModulus(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Self.pythonModulus(lhs: Double(lhsVal), rhs: rhsVal))
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(integerLiteral: try Self.pythonIntegerModulus(lhs: lhsVal, rhs: rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "modulus", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(integerLiteral: try Self.pythonIntegerModulus(lhs: lhsVal, rhs: 1))
            }
            
        case .deferredString:
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncModulus(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "modulus", opType1: "String", opType2: "Double")
            case .deferredInt:
                throw PythonError.typeError(operation: "modulus", opType1: "String", opType2: "Int")
            case .deferredString:
                throw PythonError.typeError(operation: "modulus", opType1: "String", opType2: "String")
            case .deferredBool:
                throw PythonError.typeError(operation: "modulus", opType1: "String", opType2: "Bool")
            }
            
        case .deferredBool(let lhsVal):
            switch divisor.state {
            case .bound:
                let localInterpreter = divisor.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncModulus(dividend: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Self.pythonModulus(lhs: lhsVal ? 1.0 : 0.0, rhs: rhsVal))
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(integerLiteral: try Self.pythonIntegerModulus(lhs: lhsVal ? 1 : 0, rhs: rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "modulus", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(integerLiteral: try Self.pythonIntegerModulus(lhs: lhsVal ? 1 : 0, rhs: rhsVal ? 1 : 0))
            }
        }
    }
    
    /// Returns the Python remainder of this safe Python object divided by a Swift value.
    ///
    /// This overload is for values such as `Int`, `Double`, `Bool`, and `String` that can be
    /// converted to Python through the receiver's interpreter. The receiver must already be bound
    /// unless `divisor` is itself a `SafePythonObject`.
    ///
    /// - Parameters:
    ///   - divisor: The Python-convertible divisor.
    /// - Returns: The Python remainder result.
    /// - Throws: `PythonError.conversionType` if the receiver is deferred and `divisor` needs an
    ///   interpreter for conversion, or `PythonError` if conversion or Python modulus fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func modulus(divisor: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = divisor as? PythonInterpreter.SafePythonObject {
            return try modulus(divisor: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: divisor),
                sourceType: String(describing: type(of: divisor)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try modulus(divisor: divisor.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func modulusOperator(dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try dividend.modulus(divisor: divisor)
        } catch {
            fatalError("Modulus failed: \(error).  Use `SafePythonObject.modulus()` for modulus that might throw.")
        }
    }
    
    /// Replaces this safe Python object with its Python remainder divided by another safe Python object.
    ///
    /// If either operand is already bound to an interpreter, this delegates to CPython's
    /// `PyNumber_InPlaceRemainder`. If both operands are deferred Swift literals, this applies
    /// Python-compatible `%=` behavior locally.
    ///
    /// - Parameters:
    ///   - divisor: The divisor used for the Python `%=` operation.
    /// - Throws: `PythonError.divideByZero` for fully deferred zero divisors,
    ///   `PythonError.typeError` for unsupported fully deferred operand pairs, or `PythonError`
    ///   if Python raises or conversion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func modulusInPlace(divisor: PythonInterpreter.SafePythonObject) throws {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlaceRemainder(quotientand: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
            }
        default:
            if divisor.isBoundToPythonInterpreter {
                let localInterpreter = divisor.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlaceRemainder(quotientand: self.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            } else {
                do {
                    self = try modulus(divisor: divisor)
                } catch let PythonError.typeError(_, opType1, opType2) {
                    throw PythonError.typeError(operation: "in place modulus", opType1: opType1, opType2: opType2)
                }
            }
        }
    }
    
    /// Replaces this safe Python object with its Python remainder divided by a Swift value.
    ///
    /// This overload is for values such as `Int`, `Double`, `Bool`, and `String` that can be
    /// converted to Python through the receiver's interpreter. The receiver must already be bound
    /// unless `divisor` is itself a `SafePythonObject`.
    ///
    /// - Parameters:
    ///   - divisor: The Python-convertible divisor.
    /// - Throws: `PythonError.conversionType` if the receiver is deferred and `divisor` needs an
    ///   interpreter for conversion, or `PythonError` if conversion or Python modulus fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func modulusInPlace(divisor: any SafePythonConvertible) throws {
        if let safeObject = divisor as? PythonInterpreter.SafePythonObject {
            try modulusInPlace(divisor: safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: divisor),
                sourceType: String(describing: type(of: divisor)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try modulusInPlace(divisor: divisor.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func modulusInPlaceOperator(quotientand: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = quotientand
            try result.modulusInPlace(divisor: divisor)
            return result
        } catch {
            fatalError("In place modulus failed: \(error).  Use `SafePythonObject.modulusInPlace()` for in place modulus that might throw.")
        }
    }
    
    // MARK: Exponentiation
    
    private static func fractionalExponentProducesComplex(base: Double, exponent: Double) -> Bool {
        base < 0.0 && exponent.isFinite && exponent.rounded(.towardZero) != exponent
    }
    
    private static func complexPowerConversionError(base: String, exponent: String) -> PythonError {
        PythonError.conversionType(
            value: "\(base) ** \(exponent)",
            sourceType: "deferred Python power result",
            targetType: "SafePythonObject without complex support"
        )
    }
    
    private static func checkedDeferredIntegerPower(base: Int, exponent: Int) throws -> PythonInterpreter.SafePythonObject {
        if exponent == 0 { return PythonInterpreter.SafePythonObject(integerLiteral: 1) }
        
        var result = 1
        var currentBase = base
        var currentExponent = exponent
        
        while currentExponent > 0 {
            if currentExponent % 2 != 0 {
                let product = result.multipliedReportingOverflow(by: currentBase)
                guard !product.overflow else {
                    throw PythonError.conversionOverflow(
                        value: "\(base) ** \(exponent)",
                        sourceType: "deferred Python integer power",
                        targetType: "Swift Int"
                    )
                }
                result = product.partialValue
            }
            
            currentExponent /= 2
            if currentExponent > 0 {
                let square = currentBase.multipliedReportingOverflow(by: currentBase)
                guard !square.overflow else {
                    throw PythonError.conversionOverflow(
                        value: "\(base) ** \(exponent)",
                        sourceType: "deferred Python integer power",
                        targetType: "Swift Int"
                    )
                }
                currentBase = square.partialValue
            }
        }
        
        return PythonInterpreter.SafePythonObject(integerLiteral: result)
    }
    
    /// Raises this safe Python object to a safe Python exponent using Python `**` semantics.
    ///
    /// If either operand is already bound to an interpreter, this delegates to CPython's
    /// `PyNumber_Power`. If both operands are still deferred Swift literals, this applies
    /// Python-compatible power behavior locally where the result is representable.
    ///
    /// - Parameters:
    ///   - exponent: The exponent used for the Python `**` operation.
    /// - Returns: The Python power result.
    /// - Throws: `PythonError.divideByZero` for fully deferred zero-to-negative powers,
    ///   `PythonError.typeError` for unsupported fully deferred operand pairs,
    ///   `PythonError.conversionType` for fully deferred complex results, `PythonError.conversionOverflow`
    ///   for fully deferred integer powers outside Swift2Python's deferred `Int` storage,
    ///   or `PythonError` if Python raises or conversion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func power(exponent: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        
        
        // The throwing power function. For materialized Python objects, this calls PyNumber_Power
        // using the interpreter. If only one side is materialized, materialize the other and do the same.
        // If neither side is materialized, do the operation Python would do when Swift2Python can
        // represent the result locally.
        //
        // LHS     RHS      ACTION / Type                Error or special case
        // -----   ------   ---------                    -------------------------------
        // bound   any      PyNumber_Power
        // any     bound    PyNumber_Power
        // double  double   double                       0 ** negative -> divideByZero; negative ** fractional -> conversionType
        // double  int      double                       0 ** negative -> divideByZero
        // double  string   ERR: typeError
        // double  bool     double
        // int     int      int (double if rhs < 0)      0 ** negative -> divideByZero; checked overflow for non-negative rhs
        // int     double   double                       0 ** negative -> divideByZero; negative ** fractional -> conversionType
        // int     string   ERR: typeError
        // int     bool     int
        // string  double   ERR: typeError
        // string  int      ERR: typeError
        // string  string   ERR: typeError
        // string  bool     ERR: typeError
        // bool    double   double                       false ** negative -> divideByZero
        // bool    int      int                          false ** negative -> divideByZero
        // bool    string   ERR: typeError
        // bool    bool     int
        
        switch self.state {
            
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncPower(base: self.toSafePythonObject(interpreter: $0), exponent: exponent.toSafePythonObject(interpreter: $0))
            }
            
        case .deferredDouble(let lhsVal):
            switch exponent.state {
            case .bound:
                let localInterpreter = exponent.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncPower(base: self.toSafePythonObject(interpreter: $0), exponent: exponent.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                if lhsVal == 0.0 {
                    if rhsVal == 0.0 {
                        return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)
                    } else if rhsVal < 0.0 {
                        throw PythonError.divideByZero
                    }
                }
                if Self.fractionalExponentProducesComplex(base: lhsVal, exponent: rhsVal) {
                    throw Self.complexPowerConversionError(base: String(lhsVal), exponent: String(rhsVal))
                }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(lhsVal, rhsVal))
            case .deferredInt(let rhsVal):
                if lhsVal == 0.0 {
                    if rhsVal == 0 {
                        return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)
                    } else if rhsVal < 0 {
                        throw PythonError.divideByZero
                    }
                }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(lhsVal, Double(rhsVal)))
            case .deferredString:
                throw PythonError.typeError(operation: "power", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(lhsVal, rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch exponent.state {
            case .bound:
                let localInterpreter = exponent.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncPower(base: self.toSafePythonObject(interpreter: $0), exponent: exponent.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                if lhsVal == 0 {
                    if rhsVal == 0.0 {
                        return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)
                    } else if rhsVal < 0.0 {
                        throw PythonError.divideByZero
                    }
                }
                if Self.fractionalExponentProducesComplex(base: Double(lhsVal), exponent: rhsVal) {
                    throw Self.complexPowerConversionError(base: String(lhsVal), exponent: String(rhsVal))
                }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(Double(lhsVal), rhsVal))
            case .deferredInt(let rhsVal):
                if lhsVal == 0 {
                    if rhsVal == 0 {
                        return PythonInterpreter.SafePythonObject(integerLiteral: 1)
                    } else if rhsVal < 0 {
                        throw PythonError.divideByZero
                    }
                }
                if rhsVal < 0 {
                    return PythonInterpreter.SafePythonObject(floatLiteral: pow(Double(lhsVal), Double(rhsVal)))
                }
                return try Self.checkedDeferredIntegerPower(base: lhsVal, exponent: rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "power", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                return rhsVal ? PythonInterpreter.SafePythonObject(integerLiteral: lhsVal) : PythonInterpreter.SafePythonObject(integerLiteral: 1)
            }
            
        case .deferredString:
            switch exponent.state {
            case .bound:
                let localInterpreter = exponent.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncPower(base: self.toSafePythonObject(interpreter: $0), exponent: exponent.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble:
                throw PythonError.typeError(operation: "power", opType1: "String", opType2: "Double")
            case .deferredInt:
                throw PythonError.typeError(operation: "power", opType1: "String", opType2: "Int")
            case .deferredString:
                throw PythonError.typeError(operation: "power", opType1: "String", opType2: "String")
            case .deferredBool:
                throw PythonError.typeError(operation: "power", opType1: "String", opType2: "Bool")
            }
            
        case .deferredBool(let lhsVal):
            switch exponent.state {
            case .bound:
                let localInterpreter = exponent.interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncPower(base: self.toSafePythonObject(interpreter: $0), exponent: exponent.toSafePythonObject(interpreter: $0))
                }
            case .deferredDouble(let rhsVal):
                if lhsVal == false {
                    if rhsVal == 0.0 {
                        return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)
                    } else if rhsVal < 0.0 {
                        throw PythonError.divideByZero
                    } else {
                        return PythonInterpreter.SafePythonObject(floatLiteral: 0.0)
                    }
                } else {
                    return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)
                }
            case .deferredInt(let rhsVal):
                if lhsVal == false {
                    if rhsVal == 0 {
                        return PythonInterpreter.SafePythonObject(integerLiteral: 1)
                    } else if rhsVal < 0 {
                        throw PythonError.divideByZero
                    } else {
                        return PythonInterpreter.SafePythonObject(integerLiteral: 0)
                    }
                } else {
                    return PythonInterpreter.SafePythonObject(integerLiteral: 1)
                }
            case .deferredString:
                throw PythonError.typeError(operation: "power", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                return rhsVal ? PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0)) : PythonInterpreter.SafePythonObject(integerLiteral: 1)
            }
        }
    }
    
    /// Raises this safe Python object to a Python-convertible exponent.
    ///
    /// This overload is for values such as `Int`, `Double`, `Bool`, and `String` that can be
    /// converted to Python through the receiver's interpreter. The receiver must already be bound
    /// unless `exponent` is itself a `SafePythonObject`.
    ///
    /// - Parameters:
    ///   - exponent: The Python-convertible exponent.
    /// - Returns: The Python power result.
    /// - Throws: `PythonError.conversionType` if the receiver is deferred and `exponent` needs an
    ///   interpreter for conversion, or `PythonError` if conversion or Python power fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func power(exponent: any SafePythonConvertible) throws -> PythonInterpreter.SafePythonObject {
        if let safeObject = exponent as? PythonInterpreter.SafePythonObject {
            return try power(exponent: safeObject)
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: exponent),
                sourceType: String(describing: type(of: exponent)),
                targetType: "bound SafePythonObject"
            )
        }
        
        return try power(exponent: exponent.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func exponentiationOperator(base: PythonInterpreter.SafePythonObject, exponent: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try base.power(exponent: exponent)
        } catch {
            fatalError("Power failed: \(error).  Use `SafePythonObject.power()` for power that might throw.")
        }
    }
    
    /// Replaces this safe Python object with the result of raising it to another safe Python object.
    ///
    /// If either operand is already bound to an interpreter, this delegates to CPython's
    /// `PyNumber_InPlacePower`. If both operands are deferred Swift literals, this applies
    /// Python-compatible `**=` behavior locally where the result is representable.
    ///
    /// - Parameters:
    ///   - exponent: The exponent used for the Python `**=` operation.
    /// - Throws: `PythonError.divideByZero` for fully deferred zero-to-negative powers,
    ///   `PythonError.typeError` for unsupported fully deferred operand pairs,
    ///   `PythonError.conversionType` for fully deferred complex results, `PythonError.conversionOverflow`
    ///   for fully deferred integer powers outside Swift2Python's deferred `Int` storage,
    ///   or `PythonError` if Python raises or conversion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func powerInPlace(exponent: PythonInterpreter.SafePythonObject) throws {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            try localInterpreter.assumeIsolated {
                self = try $0.syncInPlacePower(lhs: self.toSafePythonObject(interpreter: $0), exponent: exponent.toSafePythonObject(interpreter: $0))
            }
        default:
            if exponent.isBoundToPythonInterpreter {
                let localInterpreter = exponent.interpreter
                try localInterpreter.assumeIsolated {
                    self = try $0.syncInPlacePower(lhs: self.toSafePythonObject(interpreter: $0), exponent: exponent.toSafePythonObject(interpreter: $0))
                }
            } else {
                do {
                    self = try power(exponent: exponent)
                } catch let PythonError.typeError(_, opType1, opType2) {
                    throw PythonError.typeError(operation: "in place power", opType1: opType1, opType2: opType2)
                }
            }
        }
    }
    
    /// Replaces this safe Python object with the result of raising it to a Swift value.
    ///
    /// This overload is for values such as `Int`, `Double`, `Bool`, and `String` that can be
    /// converted to Python through the receiver's interpreter. The receiver must already be bound
    /// unless `exponent` is itself a `SafePythonObject`.
    ///
    /// - Parameters:
    ///   - exponent: The Python-convertible exponent.
    /// - Throws: `PythonError.conversionType` if the receiver is deferred and `exponent` needs an
    ///   interpreter for conversion, or `PythonError` if conversion or Python power fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public mutating func powerInPlace(exponent: any SafePythonConvertible) throws {
        if let safeObject = exponent as? PythonInterpreter.SafePythonObject {
            try powerInPlace(exponent: safeObject)
            return
        }
        
        guard isBoundToPythonInterpreter else {
            throw PythonError.conversionType(
                value: String(describing: exponent),
                sourceType: String(describing: type(of: exponent)),
                targetType: "bound SafePythonObject"
            )
        }
        
        try powerInPlace(exponent: exponent.toSafePythonObject(interpreter: interpreter))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func powerInPlaceOperator(base: PythonInterpreter.SafePythonObject, exponent: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            var result = base
            try result.powerInPlace(exponent: exponent)
            return result
        } catch {
            fatalError("In place power failed: \(error).  Use `SafePythonObject.powerInPlace()` for in place power that might throw.")
        }
    }
    
}
