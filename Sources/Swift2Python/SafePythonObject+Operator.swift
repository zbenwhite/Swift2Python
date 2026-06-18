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
    
    // The throwing multiplication function.  For materialized python objects, this calls PyNumber_Multiply
    // using the interpreter. If only one is materialized, materialize the other and do the same.
    // If neither are materialized (why?) then multiply them the way Python would multiply them:
    // LHS     RHS      ACTION / Type
    // -----   ------   ---------
    // bound   any      PyNumber_Multiply -- preserve term order
    // any     bound    PyNumber_Multiply -- preserve term order
    // double  double   double
    // double  int      double
    // double  string   ERR: typeError
    // double  bool     double
    // int     int      int
    // int     double   double
    // int     string   string
    // int     bool     int
    // string  double   ERR: typeError
    // string  int      string
    // string  string   ERR: typeError
    // string  bool     string
    // bool    double   double
    // bool    int      int
    // bool    string   string
    // bool    bool     int
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func multiply(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
        switch self.state {
            
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
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal * rhsVal)
            case .deferredString(let rhsVal):
                return (lhsVal < 1) ? PythonInterpreter.SafePythonObject(stringLiteral: "") : PythonInterpreter.SafePythonObject(stringLiteral: String(repeating: rhsVal, count: lhsVal))
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal * (rhsVal ? 1 : 0))
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
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) * rhsVal)
            case .deferredString(let rhsVal):
                return lhsVal ? PythonInterpreter.SafePythonObject(stringLiteral: rhsVal) : PythonInterpreter.SafePythonObject(stringLiteral: "")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) * (rhsVal ? 1 : 0))
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func multiplyOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.multiply(rhs)
        } catch {
            fatalError("Multiplication failed: \(error).  Use `SafePythonObject.multiply()` for subtraction that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func multiplyInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlaceMultiply(productand: lhs.toSafePythonObject(interpreter: $0), multiplicand: rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    // MARK: Division
    
    // The throwing division function.  For materialized python objects, this calls PyNumber_TrueDivide
    // using the interpreter. If only one is materialized, materialize the other and do the same.
    // If neither are materialized (why?) then divide them the way Python would divide them.
    // Dizision by zero results in PythonError.divideByZero
    // LHS     RHS      ACTION / Type
    // -----   ------   ---------
    // bound   any      PyNumber_TrueDivide
    // any     bound    PyNumber_TrueDivide
    // double  double   double
    // double  int      double
    // double  string   ERR: typeError
    // double  bool     double
    // int     int      double
    // int     double   double
    // int     string   string
    // int     bool     double
    // string  double   ERR: typeError
    // string  int      ERR: typeError
    // string  string   ERR: typeError
    // string  bool     ERR: typeError
    // bool    double   double
    // bool    int      double
    // bool    string   ERR: typeError
    // bool    bool     double
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func divide(divisor: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
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
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal) // n / 1 == n
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
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) / Double(rhsVal))   // Python division always return floating point
            case .deferredString:
                throw PythonError.typeError(operation: "division", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal)) // n / 1 == n
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
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / Double(rhsVal))    // Python division always return floating point
            case .deferredString:
                throw PythonError.typeError(operation: "division", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal ? 1.0 : 0.0) // n / 1 == n
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func divideOperator(dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try dividend.divide(divisor: divisor)
        } catch {
            fatalError("Division failed: \(error).  Use `SafePythonObject.divide()` for division that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func divideInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlaceDivide(quotientand: lhs.toSafePythonObject(interpreter: $0), divisor: rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    // MARK: Modulus
    
    
    private static func pythonModulus(lhs: Double, rhs: Double) -> Double {
        lhs - rhs * floor(lhs / rhs)
    }
    
    private static func pythonIntegerModulus(lhs: Int, rhs: Int) -> Int {
        let remainder = lhs % rhs
        if remainder != 0 && ((rhs > 0 && remainder < 0) || (rhs < 0 && remainder > 0)) {
            return remainder + rhs
        }
        return remainder
    }
    
    // The throwing modulus function.  For materialized python objects, this calls PyNumber_Remainder
    // using the interpreter. If only one is materialized, materialize the other and do the same.
    // If neither are materialized (why?) then do the operation python would do.
    // Dizision by zero results in PythonError.divideByZero
    // LHS     RHS      ACTION / Type
    // -----   ------   ---------
    // bound   any      PyNumber_TrueDivide
    // any     bound    PyNumber_TrueDivide
    // double  double   double
    // double  int      double
    // double  string   ERR: typeError
    // double  bool     double
    // int     int      double
    // int     double   double
    // int     string   string
    // int     bool     double
    // string  double   ERR: typeError
    // string  int      ERR: typeError
    // string  string   ERR: typeError
    // string  bool     ERR: typeError
    // bool    double   double
    // bool    int      double
    // bool    string   ERR: typeError
    // bool    bool     double
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func modulus(divisor: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
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
                return PythonInterpreter.SafePythonObject(integerLiteral: Self.pythonIntegerModulus(lhs: lhsVal, rhs: rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "modulus", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(integerLiteral: Self.pythonIntegerModulus(lhs: lhsVal, rhs: 1))
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
                return PythonInterpreter.SafePythonObject(integerLiteral: Self.pythonIntegerModulus(lhs: lhsVal ? 1 : 0, rhs: rhsVal))
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                guard rhsVal else { throw PythonError.divideByZero }
                return PythonInterpreter.SafePythonObject(integerLiteral: Self.pythonIntegerModulus(lhs: lhsVal ? 1 : 0, rhs: rhsVal ? 1 : 0))
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func modulusOperator(dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try dividend.modulus(divisor: divisor)
        } catch {
            fatalError("Modulus failed: \(error).  Use `SafePythonObject.modulus()` for modulus that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func modulusInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlaceRemainder(quotientand: lhs.toSafePythonObject(interpreter: $0), divisor: rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    // MARK: Exponentiation
    
    private static func integerPower(base: Int, exponent: Int) -> Int {
        if exponent == 0 { return 1 }
        
        var result = 1
        var currentBase = base
        var currentExponent = exponent
        
        while currentExponent > 0 {
            if currentExponent % 2 != 0 {
                result *= currentBase
            }
            currentExponent /= 2
            if currentExponent > 0 {
                currentBase *= currentBase
            }
        }
        
        return result
    }
    
    
    // The throwing power function.  For materialized python objects, this calls PyNumber_Power
    // using the interpreter. If only one is materialized, materialize the other and do the same.
    // If neither are materialized (why?) then do the operation python would do.
    //
    // Exceptions: Python returns complex numbers for something like (-2) ** 0​.5.  This gives NaN.
    //             Also this code can overflow an int.  This code is only for convenience because
    //             returning good answers is better than erroring out on unbound values.  Materialize
    //             your SafePythonObjects and stop messing around if you want better behavior.
    //
    // LHS     RHS      ACTION / Type                Error or special case
    // -----   ------   ---------                    -------------------------------
    // bound   any      PyNumber_Power
    // any     bound    PyNumber_Power
    // double  double   double                       lhs == 0.0 && rhs < 0.0  .... can't raise zero to negative power.  Divide by zero.
    // double  int      double                       lhs == 0.0 && rhs < 0.0  .... can't raise zero to negative power.  Divide by zero.
    // double  string   ERR: typeError
    // double  bool     double
    // int     int      int (double if rhs < 0)      lhs == 0 && rhs < 0      .... can't raise zero to negative power.  Divide by zero.
    // int     double   double                       lhs == 0.0 && rhs < 0.0  .... can't raise zero to negative power.  Divide by zero.
    // int     string   ERR: typeError
    // int     bool     int
    // string  double   ERR: typeError
    // string  int      ERR: typeError
    // string  string   ERR: typeError
    // string  bool     ERR: typeError
    // bool    double   double                       lhs == False && rhs < 0.0  .... can't raise zero to negative power.  Divide by zero.
    // bool    int      int (double if rhs < 0)      lhs == False && rhs < 0.0  .... can't raise zero to negative power.  Divide by zero.
    // bool    string   ERR: typeError
    // bool    bool     int
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func power(exponent: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
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
                        return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)      // 0 ** 0 = 1
                    } else if rhsVal < 0.0 {
                        throw PythonError.divideByZero                                    // 0 ** n is divide by zero for negative n
                    }
                }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(lhsVal, rhsVal))
            case .deferredInt(let rhsVal):
                if lhsVal == 0.0 {
                    if rhsVal == 0 {
                        return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)      // 0 ** 0 = 1
                    } else if rhsVal < 0 {
                        throw PythonError.divideByZero                                    // 0 ** n is divide by zero for negative n
                    }
                }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(lhsVal, Double(rhsVal)))
            case .deferredString:
                throw PythonError.typeError(operation: "power", opType1: "Double", opType2: "String")
            case .deferredBool(let rhsVal):
                if lhsVal == 0.0 && rhsVal {
                    return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)      // 0 ** 0 = 1
                }
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
                        return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)      // 0 ** 0 = 1
                    } else if rhsVal < 0.0 {
                        throw PythonError.divideByZero                                    // 0 ** n is divide by zero for negative n
                    }
                }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(Double(lhsVal), rhsVal))
            case .deferredInt(let rhsVal):
                if lhsVal == 0 {
                    if rhsVal == 0 {
                        return PythonInterpreter.SafePythonObject(integerLiteral: 1)      // 0 ** 0 = 1
                    } else if rhsVal < 0 {
                        throw PythonError.divideByZero                                    // 0 ** n is divide by zero for negative n
                    }
                }
                if rhsVal < 0 {
                    return PythonInterpreter.SafePythonObject(floatLiteral: pow(Double(lhsVal), Double(rhsVal)))
                }
                return PythonInterpreter.SafePythonObject(integerLiteral: Self.integerPower(base: lhsVal, exponent: rhsVal))
            case .deferredString:
                throw PythonError.typeError(operation: "power", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                // n ** 0 == 1
                // n ** 1 == n
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
                        return PythonInterpreter.SafePythonObject(floatLiteral: 1.0)      // 0 ** 0 = 1
                    } else if rhsVal < 0.0 {
                        throw PythonError.divideByZero                                    // 0 ** n is divide by zero for negative n
                    } else {
                        return PythonInterpreter.SafePythonObject(floatLiteral: 0.0)      // 0 ** n = 0 for positive n
                    }
                } else {
                    return PythonInterpreter.SafePythonObject(floatLiteral: pow(1.0, rhsVal))
                }
            case .deferredInt(let rhsVal):
                
                if lhsVal == false {
                    if rhsVal == 0 {
                        return PythonInterpreter.SafePythonObject(integerLiteral: 1)      // 0 ** 0 = 1
                    } else if rhsVal < 0 {
                        throw PythonError.divideByZero                                    // 0 ** n is divide by zero for negative n
                    } else {
                        return PythonInterpreter.SafePythonObject(integerLiteral: 0)      // 0 ** n = 0 for positive n
                    }
                } else {
                    return PythonInterpreter.SafePythonObject(integerLiteral: 1)
                }
            case .deferredString:
                throw PythonError.typeError(operation: "power", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                // 0 ** 0 == 1
                // 0 ** 1 == 0
                // 1 ** 0 == 1
                // 1 ** 1 == 1
                return rhsVal ? PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0)) : PythonInterpreter.SafePythonObject(integerLiteral: 1)
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    static internal func exponentiationOperator(base: PythonInterpreter.SafePythonObject, exponent: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try base.power(exponent: exponent)
        } catch {
            fatalError("Power failed: \(error).  Use `SafePythonObject.power()` for power that might throw.")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func exponentiationInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlacePower(lhs: lhs.toSafePythonObject(interpreter: $0), exponent: rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    
    // MARK: -
    // MARK: BITS
    
    
    
    
    // MARK: Bitwise AND

    // Python bitwise AND results:
    static internal func unboundPythonBitwiseAnd(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
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
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal & rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal & (rhsVal ? 1 : 0))
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
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) & rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) & (rhsVal ? 1 : 0))
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func bitwiseAndOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncBitwiseAnd(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func bitwiseAndInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlaceBitwiseAnd(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
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
