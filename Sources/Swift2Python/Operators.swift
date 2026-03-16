//
//  Operators.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

public extension PythonInterpreter.SafePythonObject {
    
    
    // TODO: allow operations on unbound objects
    //       if they are both unbound and if the internal types are able to be operated on,
    //       then these operations might still make sense.  Example:
    //           let x: SafePythonObject = 5
    //           x += 10
    //           a.value += x
    //
    //       The x += 10 can be done correctly without erroring out and this code can work.
    //       It's hard to imagine what this user thinks he is doing, but it's also hard to imagine
    //       a downside to just making it work right instead of making it a catastrophic failure mode.
    //       Because swift is compiled, the code it going to look messy.  I also need to implement
    //       the operations as Python would.
    
    static func + (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.addOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.addOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonAdd(lhs:lhs, rhs:rhs)
        }
    }
    
    static func - (minuend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if minuend.isBoundToPythonInterpreter {
            return minuend.subtractOperator(minuend: minuend, subtrahend: subtrahend)
        } else if subtrahend.isBoundToPythonInterpreter {
            return subtrahend.subtractOperator(minuend: minuend, subtrahend: subtrahend)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonSubtract(lhs:minuend, rhs:subtrahend)
        }
    }

    static func * (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.multiplyOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.multiplyOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonMultiply(lhs:lhs, rhs:rhs)
        }
    }

    static func / (dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if dividend.isBoundToPythonInterpreter {
            return dividend.divideOperator(dividend: dividend, divisor: divisor)
        } else if divisor.isBoundToPythonInterpreter {
            return divisor.divideOperator(dividend: dividend, divisor: divisor)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonSubtract(lhs:dividend, rhs:divisor)
        }
    }
    
    static func += (sumend: inout PythonInterpreter.SafePythonObject, addend: PythonInterpreter.SafePythonObject) {
        if sumend.isBoundToPythonInterpreter {
            sumend = sumend.addInPlaceOperator(sumend:sumend, addend:addend)
        } else if addend.isBoundToPythonInterpreter {
            sumend = addend.addInPlaceOperator(sumend:sumend, addend:addend)
        } else {
            sumend = PythonInterpreter.SafePythonObject.unboundPythonAdd(lhs:sumend, rhs:addend)
        }
    }
    
    static func -= (diffend: inout PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) {
        if diffend.isBoundToPythonInterpreter {
            diffend = diffend.subtractInPlaceOperator(diffend:diffend, subtrahend:subtrahend)
        } else if subtrahend.isBoundToPythonInterpreter {
            diffend = subtrahend.subtractInPlaceOperator(diffend:diffend, subtrahend:subtrahend)
        } else {
            diffend = PythonInterpreter.SafePythonObject.unboundPythonSubtract(lhs:diffend, rhs:subtrahend)
        }
    }
    
    static func *= (productand: inout PythonInterpreter.SafePythonObject, multiplicand: PythonInterpreter.SafePythonObject) {
        if productand.isBoundToPythonInterpreter {
            productand = productand.multiplyInPlaceOperator(productand:productand, multiplicand:multiplicand)
        } else if multiplicand.isBoundToPythonInterpreter {
            productand = multiplicand.multiplyInPlaceOperator(productand:productand, multiplicand:multiplicand)
        } else {
            productand = PythonInterpreter.SafePythonObject.unboundPythonMultiply(lhs:productand, rhs:multiplicand)
        }
    }
    
    static func /= (quotientand: inout PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) {
        if quotientand.isBoundToPythonInterpreter {
            quotientand = quotientand.divideInPlaceOperator(quotientand:quotientand, divisor:divisor)
        } else if divisor.isBoundToPythonInterpreter {
            quotientand = divisor.divideInPlaceOperator(quotientand:quotientand, divisor:divisor)
        } else {
            quotientand = PythonInterpreter.SafePythonObject.unboundPythonDivide(lhs:quotientand, rhs:divisor)
        }
    }
    
    static func & (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.andOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.andOperator(lhs, rhs)
        } else {
            fatalError("Placeholder")
        }
        //return performBinaryOp(PyNumber_And, lhs: lhs, rhs: rhs)
    }

    static func | (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.orOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.orOperator(lhs, rhs)
        } else {
            fatalError("Placeholder")
        }
        //return performBinaryOp(PyNumber_Or, lhs: lhs, rhs: rhs)
    }

    static func ^ (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.xorOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.xorOperator(lhs, rhs)
        } else {
            fatalError("Placeholder")
        }
        //return performBinaryOp(PyNumber_Xor, lhs: lhs, rhs: rhs)
    }

    static func &= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        if lhs.isBoundToPythonInterpreter {
            lhs = lhs.andInPlaceOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            lhs = rhs.andInPlaceOperator(lhs, rhs)
        } else {
            fatalError("Placeholder")
        }
        //lhs = performBinaryOp(PyNumber_InPlaceAnd, lhs: lhs, rhs: rhs)
    }

    static func |= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        if lhs.isBoundToPythonInterpreter {
            lhs = lhs.orInPlaceOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            lhs = rhs.orInPlaceOperator(lhs, rhs)
        } else {
            fatalError("Placeholder")
        }
        //lhs = performBinaryOp(PyNumber_InPlaceOr, lhs: lhs, rhs: rhs)
    }

    static func ^= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        if lhs.isBoundToPythonInterpreter {
            lhs = lhs.xorInPlaceOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            lhs = rhs.xorInPlaceOperator(lhs, rhs)
        } else {
            fatalError("Placeholder")
        }
        //lhs = performBinaryOp(PyNumber_InPlaceXor, lhs: lhs, rhs: rhs)
    }

    static prefix func ~ (_ operand: Self) -> Self {
        if operand.isBoundToPythonInterpreter {
            fatalError("Placeholder")
        } else {
            fatalError("Placeholder")
        }
        //return performUnaryOp(PyNumber_Invert, operand: operand)
    }

}



extension PythonInterpreter.SafePythonObject : Equatable, Comparable {
    // `Equatable` and `Comparable` are implemented using rich comparison.
    // This is consistent with how Python handles comparisons.
//    private func compared(to other: PythonObject, byOp: Int32) -> Bool {
//        let lhsObject = ownedPyObject
//        let rhsObject = other.ownedPyObject
//        defer {
//            Py_DecRef(lhsObject)
//            Py_DecRef(rhsObject)
//        }
//        assert(PyErr_Occurred() == nil,
//               "Python error occurred somewhere but wasn't handled")
//        switch PyObject_RichCompareBool(lhsObject, rhsObject, byOp) {
//        case 0: return false
//        case 1: return true
//        default:
//            try! throwPythonErrorIfPresent()
//            fatalError("No result or error returned when comparing \(self) to \(other)")
//        }
//    }

    public static func == (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        if lhs.isBoundToPythonInterpreter {
            return lhs.doubleEqualsEquatableOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.doubleEqualsEquatableOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonDoubleEqualsEquatable(lhs:lhs, rhs:rhs)
        }
    }

    public static func != (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        if lhs.isBoundToPythonInterpreter {
            return lhs.notEqualsEquatableOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.notEqualsEquatableOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonNotEqualsEquatable(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_NE)
    }

    public static func < (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        if lhs.isBoundToPythonInterpreter {
            return lhs.lessThanComparableOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.lessThanComparableOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonLessThanComparable(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_LT)
    }

    public static func <= (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        if lhs.isBoundToPythonInterpreter {
            return lhs.lessThanOrEqualComparableOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.lessThanOrEqualComparableOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonLessThanOrEqualsComparable(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_LE)
    }

    public static func > (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        if lhs.isBoundToPythonInterpreter {
            return lhs.greaterThanComparableOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.greaterThanComparableOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonGreaterThanComparable(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_GT)
    }

    public static func >= (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        if lhs.isBoundToPythonInterpreter {
            return lhs.greaterThanOrEqualComparableOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.greaterThanOrEqualComparableOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonGreaterThanOrEqualsComparable(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_GE)
    }
}

public extension PythonInterpreter.SafePythonObject {
//    private func compared(to other: PythonObject, byOp: Int32) -> PythonObject {
//        let lhsObject = ownedPyObject
//        let rhsObject = other.ownedPyObject
//        defer {
//            Py_DecRef(lhsObject)
//            Py_DecRef(rhsObject)
//        }
//        assert(PyErr_Occurred() == nil,
//               "Python error occurred somewhere but wasn't handled")
//        guard let result = PyObject_RichCompare(lhsObject, rhsObject, byOp) else {
//            // If a Python exception was thrown, throw a corresponding Swift error.
//            try! throwPythonErrorIfPresent()
//            fatalError("No result or error returned when comparing \(self) to \(other)")
//        }
//        return PythonObject(consuming: result)
//    }

    static func == (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.doubleEqualsOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.doubleEqualsOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonDoubleEquals(lhs:lhs, rhs:rhs)
        }
    }

    static func != (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.notEqualsOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.notEqualsOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonNotEquals(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_NE)
    }

    static func < (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.lessThanOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.lessThanOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonLessThan(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_LT)
    }

    static func <= (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.lessThanOrEqualOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.lessThanOrEqualOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonLessThanOrEquals(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_LE)
    }

    static func > (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.greaterThanOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.greaterThanOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonGreaterThan(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_GT)
    }

    static func >= (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.greaterThanOrEqualOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.greaterThanOrEqualOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonGreaterThanOrEquals(lhs:lhs, rhs:rhs)
        }
        //return lhs.compared(to: rhs, byOp: Py_GE)
    }
}
