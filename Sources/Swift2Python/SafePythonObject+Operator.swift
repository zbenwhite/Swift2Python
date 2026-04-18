//
//  SafePythonObject+Operator.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//


extension PythonInterpreter.SafePythonObject {
    
    
    
    // MARK: -
    // MARK: ARITHMETIC
    
    
    
    
    // MARK: Addition
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func boundPythonAdd(interpreter: PythonInterpreter, lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncAdd(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Addition failed: \(error).  Use `SafePythonObject.add()` for addition that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func addOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        switch lhs.state {
        case .bound:
            return boundPythonAdd(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
            
        case .deferredDouble(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonAdd(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + Double(rhsVal))
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal + (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonAdd(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) + rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal + rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal + (rhsVal ? 1 : 0))
            }
            
        case .deferredString(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonAdd(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt:
                fatalError("Python TypeError")
            case .deferredString(let rhsVal):
                return PythonInterpreter.SafePythonObject(stringLiteral: lhsVal + rhsVal)
            case .deferredBool:
                fatalError("Python TypeError")
            }
            
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonAdd(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) + rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) + rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) + (rhsVal ? 1 : 0))
            }
        }
    }
    
    // MARK: Subtraction
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func boundPythonSubtract(interpreter: PythonInterpreter, minuend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncSubtract(minuend: minuend.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Subtraction failed: \(error).  Use `SafePythonObject.subtract()` for subtraction that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func subtractOperator(minuend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        switch minuend.state {
        case .bound:
            return boundPythonSubtract(interpreter: minuend.interpreter, minuend: minuend, subtrahend: subtrahend)
            
        case .deferredDouble(let lhsVal):
            switch subtrahend.state {
            case .bound:
                return boundPythonSubtract(interpreter: subtrahend.interpreter, minuend: minuend, subtrahend: subtrahend)
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - Double(rhsVal))
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal - (rhsVal ? 1.0 : 0.0))
            }
            
        case .deferredInt(let lhsVal):
            switch subtrahend.state {
            case .bound:
                return boundPythonSubtract(interpreter: subtrahend.interpreter, minuend: minuend, subtrahend: subtrahend)
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) - rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal - rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: lhsVal - (rhsVal ? 1 : 0))
            }
            
        case .deferredString:
            switch subtrahend.state {
            case .bound:
                return boundPythonSubtract(interpreter: subtrahend.interpreter, minuend: minuend, subtrahend: subtrahend)
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
            switch subtrahend.state {
            case .bound:
                return boundPythonSubtract(interpreter: subtrahend.interpreter, minuend: minuend, subtrahend: subtrahend)
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) - rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) - rhsVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) - (rhsVal ? 1 : 0))
            }
        }
    }
    
    // MARK: Multiplication
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func boundPythonMultiply(interpreter: PythonInterpreter, lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncMultiply(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Multiplication failed: \(error).  Use `SafePythonObject.multiply()` for multiplication that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func multiplyOperator(lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        switch lhs.state {
        case .bound:
            return boundPythonMultiply(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
            
        case .deferredDouble(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonMultiply(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * rhsVal)
            case .deferredInt(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * Double(rhsVal))
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal * (rhsVal ? 1.0 : 0.0))
            }
        case .deferredInt(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonMultiply(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
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
            switch rhs.state {
            case .bound:
                return boundPythonMultiply(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let rhsVal):
                return (rhsVal < 1) ? PythonInterpreter.SafePythonObject(stringLiteral: "") : PythonInterpreter.SafePythonObject(stringLiteral: String(repeating: lhsVal, count: rhsVal))
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                return rhsVal ? PythonInterpreter.SafePythonObject(stringLiteral: lhsVal) : PythonInterpreter.SafePythonObject(stringLiteral: "")
            }
        case .deferredBool(let lhsVal):
            switch rhs.state {
            case .bound:
                return boundPythonMultiply(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
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
    
    // MARK: Division
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func boundPythonDivide(interpreter: PythonInterpreter, dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        do {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.syncDivide(dividend: dividend.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
            }
        } catch {
            fatalError("Subtraction failed: \(error).  Use `SafePythonObject.subtract()` for subtraction that might throw.")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    static internal func divideOperator(dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        switch dividend.state {
        case .bound:
            return boundPythonDivide(interpreter: dividend.interpreter, dividend: dividend, divisor: divisor)
            
        case .deferredDouble(let lhsVal):
            switch divisor.state {
            case .bound:
                return boundPythonDivide(interpreter: divisor.interpreter, dividend: dividend, divisor: divisor)
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal / Double(rhsVal))
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                guard rhsVal else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal) // n / 1 == n
            }
            
        case .deferredInt(let lhsVal):
            switch divisor.state {
            case .bound:
                return boundPythonDivide(interpreter: divisor.interpreter, dividend: dividend, divisor: divisor)
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal) / Double(rhsVal))   // Python division always return floating point
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                guard rhsVal else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: Double(lhsVal)) // n / 1 == n
            }
            
        case .deferredString:
            switch divisor.state {
            case .bound:
                return boundPythonDivide(interpreter: divisor.interpreter, dividend: dividend, divisor: divisor)
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
            switch divisor.state {
            case .bound:
                return boundPythonDivide(interpreter: divisor.interpreter, dividend: dividend, divisor: divisor)
            case .deferredDouble(let rhsVal):
                guard rhsVal != 0.0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / rhsVal)
            case .deferredInt(let rhsVal):
                guard rhsVal != 0 else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / Double(rhsVal))    // Python division always return floating point
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let rhsVal):
                guard rhsVal else { fatalError("Python Divide By Zero") }
                return PythonInterpreter.SafePythonObject(floatLiteral: lhsVal ? 1.0 : 0.0) // n / 1 == n
            }
        }
    }
    
    // MARK: Exponentiation

    
    
    
    
    
    
    
    
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
