//
//  Operators.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

public extension PythonInterpreter.SafePythonObject {
    static func + (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.addOperator(rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.addOperator(lhs)
        } else {
            fatalError("Cannot add two non-bound Python objects")
        }
    }
    
    static func - (minuend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if minuend.isBoundToPythonInterpreter {
            return minuend.subtractOperator(minuend: minuend, subtrahend: subtrahend)
        } else if subtrahend.isBoundToPythonInterpreter {
            return subtrahend.subtractOperator(minuend: minuend, subtrahend: subtrahend)
        } else {
            fatalError("Cannot subtract with two non-bound Python objects")
        }
    }

    static func * (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.multiplyOperator(rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.multiplyOperator(lhs)
        } else {
            fatalError("Cannot multiply two non-bound Python objects")
        }
    }

    static func / (dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if dividend.isBoundToPythonInterpreter {
            return dividend.divideOperator(dividend: dividend, divisor: divisor)
        } else if divisor.isBoundToPythonInterpreter {
            return divisor.divideOperator(dividend: dividend, divisor: divisor)
        } else {
            fatalError("Cannot divide with two non-bound Python objects")
        }
    }

//    static func += (lhs: inout PythonObject, rhs: PythonObject) {
//        lhs = performBinaryOp(PyNumber_InPlaceAdd, lhs: lhs, rhs: rhs)
//    }
//
//    static func -= (lhs: inout PythonObject, rhs: PythonObject) {
//        lhs = performBinaryOp(PyNumber_InPlaceSubtract, lhs: lhs, rhs: rhs)
//    }
//
//    static func *= (lhs: inout PythonObject, rhs: PythonObject) {
//        lhs = performBinaryOp(PyNumber_InPlaceMultiply, lhs: lhs, rhs: rhs)
//    }
//
//    static func /= (lhs: inout PythonObject, rhs: PythonObject) {
//        lhs = performBinaryOp(PyNumber_InPlaceTrueDivide, lhs: lhs, rhs: rhs)
//    }
    
    

}
