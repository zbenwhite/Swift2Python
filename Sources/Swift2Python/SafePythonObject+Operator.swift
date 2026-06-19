//
//  SafePythonObject+Operator.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

import Foundation

extension PythonInterpreter.SafePythonObject {
    
    // MARK: -
    // MARK: ARITHMETIC
    
    
    
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
    
    
    // MARK: -
    // MARK: BITS
    
    
    
    
    // MARK: Bitwise AND

    private static func deferredBitwiseAndTypeName(_ object: PythonInterpreter.SafePythonObject) -> String {
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
                throw PythonError.typeError(operation: "bitwise AND", opType1: "Int", opType2: Self.deferredBitwiseAndTypeName(other))
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
                throw PythonError.typeError(operation: "bitwise AND", opType1: "Bool", opType2: Self.deferredBitwiseAndTypeName(other))
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
                    opType1: Self.deferredBitwiseAndTypeName(self),
                    opType2: Self.deferredBitwiseAndTypeName(other)
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
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func bitwiseOrOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitwiseOr(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func bitwiseOrInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlaceBitwiseOr(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    // Python bitwise OR results:
    static internal func unboundPythonBitwiseOr(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        switch lhs.state {
        case .bound:
            fatalError("This can never happen.")
        case .deferredDouble:
            fatalError("Python TypeError")
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal | rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal | (rhsVal ? 1 : 0))
            }
        case .deferredString:
            fatalError("Python TypeError")
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) | rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) | (rhsVal ? 1 : 0))
            }
        }
    }
    
    // MARK: Bitwise XOR
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func bitwiseXorOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitwiseXor(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func bitwiseXorInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlaceBitwiseXor(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    // Python bitwise XOR results:
    static internal func unboundPythonBitwiseXor(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        switch lhs.state {
        case .bound:
            fatalError("This can never happen.")
        case .deferredDouble:
            fatalError("Python TypeError")
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal ^ rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal ^ (rhsVal ? 1 : 0))
            }
        case .deferredString:
            fatalError("Python TypeError")
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) ^ rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) ^ (rhsVal ? 1 : 0))
            }
        }
    }
    
    // MARK: Bitwise NOT
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func bitwiseNotOperator(_ operand: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitwiseNot(operand.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    // Python bitwise NOT results:
    static internal func unboundPythonBitwiseNot(operand: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        switch operand.state {
        case .bound:
            fatalError("This can never happen.")
        case .deferredDouble:
            fatalError("Python TypeError")
        case .deferredInt(let operandVal):
            return PythonInterpreter.SafePythonObject(integerLiteral: ~operandVal)
        case .deferredString:
            fatalError("Python TypeError")
        case .deferredBool(let operandVal):
            return PythonInterpreter.SafePythonObject(integerLiteral: ~(operandVal ? 1 : 0))
        }
    }
    
    
    
    
    // MARK: -
    // MARK: COMPARISON
    
    
    
    
    
    
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
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func lessThanOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThan(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    
    static internal func unboundPythonLessThan(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        PythonInterpreter.SafePythonObject(booleanLiteral: lessThanComparable(lhs: lhs, rhs: rhs))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func boundPythonLessThanComparable(interpreter: PythonInterpreter, lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThanComparable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Comparison failed: \(error).  Use `SafePythonObject.lessThan()` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func lessThanComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        switch lhs.state {
        case .bound:
            return boundPythonLessThanComparable(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
            
        case .deferredDouble(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonLessThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return lhsVal < rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal < Double(rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal < (rhsVal ? 1.0 : 0.0)
            }
            
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonLessThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return Double(lhsVal) < rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal < rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal < (rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonLessThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt:
                fatalError("Python TypeError")
            case .deferredString(let rhsVal):
                return lhsVal < rhsVal
            case .deferredBool:
                fatalError("Python TypeError")
            }
            
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonLessThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return (lhsVal ? 1.0 : 0.0) < rhsVal
            case .deferredInt(let rhsVal):
                return (lhsVal ? 1 : 0) < rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return (lhsVal ? 1 : 0) < (rhsVal ? 1 : 0)
            }
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
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func greaterThanOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGreaterThan(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    static internal func unboundPythonGreaterThan(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        PythonInterpreter.SafePythonObject(booleanLiteral: greaterThanComparable(lhs: lhs, rhs: rhs))
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func boundPythonGreaterThanComparable(interpreter: PythonInterpreter, lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncGreaterThanComparable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Comparison failed: \(error).  Use `SafePythonObject.greaterThan()` for comparisons that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func greaterThanComparable(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        switch lhs.state {
        case .bound:
            return boundPythonGreaterThanComparable(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
            
        case .deferredDouble(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonGreaterThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return lhsVal > rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal > Double(rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal > (rhsVal ? 1.0 : 0.0)
            }
            
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonGreaterThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return Double(lhsVal) > rhsVal
            case .deferredInt(let rhsVal):
                return lhsVal > rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return lhsVal > (rhsVal ? 1 : 0)
            }
            
        case .deferredString(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonGreaterThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt:
                fatalError("Python TypeError")
            case .deferredString(let rhsVal):
                return lhsVal > rhsVal
            case .deferredBool:
                fatalError("Python TypeError")
            }
            
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonGreaterThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return (lhsVal ? 1.0 : 0.0) > rhsVal
            case .deferredInt(let rhsVal):
                return (lhsVal ? 1 : 0) > rhsVal
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return (lhsVal ? 1 : 0) > (rhsVal ? 1 : 0)
            }
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
import Foundation
