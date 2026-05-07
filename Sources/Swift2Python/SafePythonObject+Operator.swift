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
    
    // The throwing addition function.  For materialized python objects, this calls PyNumber_Add
    // using the interpreter. If only one is materialized, materialize the other and do the same.
    // If neither are materialized (why?) then add them the way Pythong would add them:
    // LHS     RHS      ACTION / Type
    // -----   ------   ---------
    // bound   any      PyNumber_Add -- preserve term order
    // any     bound    PyNumber_Add -- preserve term order
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
    // string  string   string concatenation
    // string  bool     ERR: typeError
    // bool    double   double
    // bool    int      int
    // bool    string   ERR: typeError
    // bool    bool     int
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func add(_ other: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
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
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal + rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "addition", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal + (rhsVal ? 1 : 0))
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
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) + rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "addition", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) + (rhsVal ? 1 : 0))
            }
        }
    }
    
    // A static function to be used for the + operator.  The + operator does not throw, so this causes
    // a fatal error if the types of the addition are incompatible.  Use SafePythonObject.add() for a throwing
    // add.
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func addOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.add(rhs)
        } catch {
            fatalError("Addition failed: \(error).  Use `SafePythonObject.add()` for addition that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func addInPlaceOperator(sumend: SafePythonConvertible, addend: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlaceAdd(sumend: sumend.toSafePythonObject(interpreter: $0), addend: addend.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
        }
    }
    
    // MARK: Subtraction
    
    // The throwing subtraction function.  For materialized python objects, this calls PyNumber_Subtract
    // using the interpreter. If only one is materialized, materialize the other and do the same.
    // If neither are materialized (why?) then subtract them the way Python would subtract them:
    // LHS     RHS      ACTION / Type
    // -----   ------   ---------
    // bound   any      PyNumber_Subtract
    // any     bound    PyNumber_Subtract
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func subtract(subtrahend: PythonInterpreter.SafePythonObject) throws -> PythonInterpreter.SafePythonObject {
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
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal - rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "subtraction", opType1: "Int", opType2: "String")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal - (rhsVal ? 1 : 0))
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
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) - rhsVal)
            case .deferredString:
                throw PythonError.typeError(operation: "subtraction", opType1: "Bool", opType2: "String")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) - (rhsVal ? 1 : 0))
            }
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func subtractOperator(minuend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try minuend.subtract(subtrahend:subtrahend)
        } catch {
            fatalError("Subtraction failed: \(error).  Use `SafePythonObject.subtract()` for subtraction that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func subtractInPlaceOperator(diffend: SafePythonConvertible, subtrahend: SafePythonConvertible) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncInPlaceSubtract(diffend: diffend.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Failed: \(error)")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func multiplyOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try lhs.multiply(rhs)
        } catch {
            fatalError("Multiplication failed: \(error).  Use `SafePythonObject.multiply()` for subtraction that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
            
        case .deferredString(let lhsVal):
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func divideOperator(dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try dividend.divide(divisor: divisor)
        } catch {
            fatalError("Division failed: \(error).  Use `SafePythonObject.divide()` for division that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func modulusOperator(dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            return try dividend.modulus(divisor: divisor)
        } catch {
            fatalError("Modulus failed: \(error).  Use `SafePythonObject.modulus()` for modulus that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func boundPythonExponentiation(interpreter: PythonInterpreter, base: PythonInterpreter.SafePythonObject, exponent: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncPower(base: base.toSafePythonObject(interpreter: $0), exponent: exponent.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Exponentiation failed: \(error).  Use `SafePythonObject.power()` for exponentiation that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func exponentiationOperator(base: PythonInterpreter.SafePythonObject, exponent: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        switch base.state {
        case .bound:
            return boundPythonExponentiation(interpreter: base.interpreter, base: base, exponent: exponent)
            
        case .deferredDouble(let lhsVal):
            switch exponent.state {
            case .bound:
                return boundPythonExponentiation(interpreter: exponent.interpreter, base: base, exponent: exponent)
            case .deferredDouble(let rhsVal):
                guard lhsVal != 0.0 || rhsVal >= 0.0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(lhsVal, rhsVal))
            case .deferredInt(let rhsVal):
                guard lhsVal != 0.0 || rhsVal >= 0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(lhsVal, Double(rhsVal)))
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(lhsVal, rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch exponent.state {
            case .bound:
                return boundPythonExponentiation(interpreter: exponent.interpreter, base: base, exponent: exponent)
            case .deferredDouble(let rhsVal):
                guard lhsVal != 0 || rhsVal >= 0.0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(Double(lhsVal), rhsVal))
            case .deferredInt(let rhsVal):
                if rhsVal >= 0 {
                    return PythonInterpreter.SafePythonObject(integerLiteral: integerPower(base: lhsVal, exponent: rhsVal))
                } else {
                    guard lhsVal != 0 else { fatalError("Python Divide By Zero") }
                    return PythonInterpreter.SafePythonObject(floatLiteral: pow(Double(lhsVal), Double(rhsVal)))
                }
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return rhsVal ? PythonInterpreter.SafePythonObject(integerLiteral: lhsVal) : PythonInterpreter.SafePythonObject(integerLiteral: 1)
            }
            
        case .deferredString:
            switch exponent.state {
            case .bound:
                return boundPythonExponentiation(interpreter: exponent.interpreter, base: base, exponent: exponent)
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt:
                fatalError("Python TypeError")
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool:
                fatalError("Python TypeError")
            }
            
        case .deferredBool(let lhsVal):
            switch exponent.state {
            case .bound:
                return boundPythonExponentiation(interpreter: exponent.interpreter, base: base, exponent: exponent)
            case .deferredDouble(let rhsVal):
                let baseValue = lhsVal ? 1.0 : 0.0
                guard baseValue != 0.0 || rhsVal >= 0.0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: pow(baseValue, rhsVal))
            case .deferredInt(let rhsVal):
                let baseValue = lhsVal ? 1 : 0
                if rhsVal >= 0 {
                    return PythonInterpreter.SafePythonObject(integerLiteral: integerPower(base: baseValue, exponent: rhsVal))
                } else {
                    guard baseValue != 0 else { fatalError("Python Divide By Zero") }
                    return PythonInterpreter.SafePythonObject(floatLiteral: pow(Double(baseValue), Double(rhsVal)))
                }
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return rhsVal ? PythonInterpreter.SafePythonObject(integerLiteral: lhsVal ? 1 : 0) : PythonInterpreter.SafePythonObject(integerLiteral: 1)
            }
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

    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
           
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
