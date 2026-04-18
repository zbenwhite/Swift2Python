//
//  Operators.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

public extension PythonInterpreter.SafePythonObject {
    
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
        return PythonInterpreter.SafePythonObject.addOperator(lhs:lhs, rhs:rhs)
    }
    
    static func - (minuend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.subtractOperator(minuend:minuend, subtrahend:subtrahend)
    }

    static func * (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.multiplyOperator(lhs:lhs, rhs:rhs)
    }

    static func / (dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.divideOperator(dividend:dividend, divisor:divisor)
    }
    
    static func += (sumend: inout PythonInterpreter.SafePythonObject, addend: PythonInterpreter.SafePythonObject) {
        sumend = PythonInterpreter.SafePythonObject.addOperator(lhs:sumend, rhs:addend)
    }
    
    static func -= (diffend: inout PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) {
        diffend = PythonInterpreter.SafePythonObject.subtractOperator(minuend:diffend, subtrahend:subtrahend)
    }
    
    static func *= (productand: inout PythonInterpreter.SafePythonObject, multiplicand: PythonInterpreter.SafePythonObject) {
        productand = PythonInterpreter.SafePythonObject.multiplyOperator(lhs:productand, rhs:multiplicand)
    }
    
    static func /= (quotientand: inout PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) {
        quotientand = PythonInterpreter.SafePythonObject.divideOperator(dividend:quotientand, divisor:divisor)
    }
    
    static func & (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.bitwiseAndOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.bitwiseAndOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonBitwiseAnd(lhs:lhs, rhs:rhs)
        }
    }

    static func | (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.bitwiseOrOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.bitwiseOrOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonBitwiseOr(lhs:lhs, rhs:rhs)
        }
    }

    static func ^ (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.bitwiseXorOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.bitwiseXorOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonBitwiseXor(lhs:lhs, rhs:rhs)
        }
    }

    // Bitwise and in place
    static func &= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        if lhs.isBoundToPythonInterpreter {
            lhs = lhs.bitwiseAndInPlaceOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            lhs = rhs.bitwiseAndInPlaceOperator(lhs, rhs)
        } else {
            lhs = PythonInterpreter.SafePythonObject.unboundPythonBitwiseAnd(lhs:lhs, rhs:rhs)
        }
    }

    // Bitwise or in place
    static func |= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        if lhs.isBoundToPythonInterpreter {
            lhs = lhs.bitwiseOrInPlaceOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            lhs = rhs.bitwiseOrInPlaceOperator(lhs, rhs)
        } else {
            lhs = PythonInterpreter.SafePythonObject.unboundPythonBitwiseOr(lhs:lhs, rhs:rhs)
        }
    }

    // Bitwise xor in place
    static func ^= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        if lhs.isBoundToPythonInterpreter {
            lhs = lhs.bitwiseXorInPlaceOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            lhs = rhs.bitwiseXorInPlaceOperator(lhs, rhs)
        } else {
            lhs = PythonInterpreter.SafePythonObject.unboundPythonBitwiseXor(lhs:lhs, rhs:rhs)
        }
    }

    static prefix func ~ (_ operand: Self) -> Self {
        if operand.isBoundToPythonInterpreter {
            return operand.bitwiseNotOperator(operand)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonBitwiseNot(operand: operand)
        }
    }

}



extension PythonInterpreter.SafePythonObject : Equatable, Comparable {
    // `Equatable` and `Comparable` are implemented using rich comparison.
    // This is consistent with how Python handles comparisons.

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
    }

    public static func < (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        return PythonInterpreter.SafePythonObject.lessThanComparable(lhs:lhs, rhs:rhs)
    }

    public static func <= (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        return PythonInterpreter.SafePythonObject.lessThanOrEqualsComparable(lhs:lhs, rhs:rhs)
    }

    public static func > (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        return PythonInterpreter.SafePythonObject.greaterThanComparable(lhs:lhs, rhs:rhs)
    }

    public static func >= (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> Bool {
        return PythonInterpreter.SafePythonObject.greaterThanOrEqualsComparable(lhs:lhs, rhs:rhs)
    }
}

public extension PythonInterpreter.SafePythonObject {

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
    }

    static func < (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.lessThanOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.lessThanOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonLessThan(lhs:lhs, rhs:rhs)
        }
    }

    static func <= (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.lessThanOrEqualOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.lessThanOrEqualOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonLessThanOrEquals(lhs:lhs, rhs:rhs)
        }
    }

    static func > (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.greaterThanOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.greaterThanOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonGreaterThan(lhs:lhs, rhs:rhs)
        }
    }

    static func >= (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.greaterThanOrEqualOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.greaterThanOrEqualOperator(lhs, rhs)
        } else {
            return PythonInterpreter.SafePythonObject.unboundPythonGreaterThanOrEquals(lhs:lhs, rhs:rhs)
        }
    }
}
