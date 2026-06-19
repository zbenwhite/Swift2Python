//
//  Operators.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

infix operator ** : MultiplicationPrecedence
infix operator **= : AssignmentPrecedence

public extension PythonInterpreter.SafePythonObject {
    
    /// Adds two safe Python objects using Python `+` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or deferred
    /// addition cannot be represented, this traps with `fatalError`. Use
    /// `SafePythonObject.add(_:)` when addition can fail and should be handled.
    static func + (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.addOperator(lhs:lhs, rhs:rhs)
    }
    
    /// Subtracts two safe Python objects using Python `-` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or deferred
    /// subtraction cannot be represented, this traps with `fatalError`. Use
    /// `SafePythonObject.subtract(subtrahend:)` when subtraction can fail and should be handled.
    static func - (minuend: PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.subtractOperator(minuend:minuend, subtrahend:subtrahend)
    }

    /// Multiplies two safe Python objects using Python `*` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or deferred
    /// multiplication cannot be represented, this traps with `fatalError`. Use
    /// `SafePythonObject.multiply(_:)` when multiplication can fail and should be handled.
    static func * (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.multiplyOperator(lhs:lhs, rhs:rhs)
    }

    /// Divides two safe Python objects using Python true-division `/` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or a deferred
    /// divisor is zero, this traps with `fatalError`. Use `SafePythonObject.divide(divisor:)`
    /// when division can fail and should be handled.
    static func / (dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.divideOperator(dividend:dividend, divisor:divisor)
    }

    /// Computes the Python remainder of two safe Python objects using Python `%` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or a deferred
    /// divisor is zero, this traps with `fatalError`. Use `SafePythonObject.modulus(divisor:)`
    /// when modulus can fail and should be handled.
    static func % (dividend: PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.modulusOperator(dividend:dividend, divisor:divisor)
    }

    /// Raises a safe Python object to a safe Python exponent using Python `**` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, a deferred
    /// zero base is raised to a negative exponent, or a deferred result cannot be represented,
    /// this traps with `fatalError`. Use `SafePythonObject.power(exponent:)` when power can fail
    /// and should be handled.
    static func ** (base: PythonInterpreter.SafePythonObject, exponent: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.exponentiationOperator(base:base, exponent:exponent)
    }
    
    /// Adds a safe Python object to another using Python `+=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or deferred
    /// addition cannot be represented, this traps with `fatalError`. Use
    /// `SafePythonObject.addInPlace(_:)` when in-place addition can fail and should be handled.
    static func += (sumend: inout PythonInterpreter.SafePythonObject, addend: PythonInterpreter.SafePythonObject) {
        sumend = PythonInterpreter.SafePythonObject.addInPlaceOperator(sumend:sumend, addend:addend)
    }
    
    /// Subtracts a safe Python object from another using Python `-=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or deferred
    /// subtraction cannot be represented, this traps with `fatalError`. Use
    /// `SafePythonObject.subtractInPlace(subtrahend:)` when in-place subtraction can fail and should be handled.
    static func -= (diffend: inout PythonInterpreter.SafePythonObject, subtrahend: PythonInterpreter.SafePythonObject) {
        diffend = PythonInterpreter.SafePythonObject.subtractInPlaceOperator(diffend: diffend, subtrahend: subtrahend)
    }
    
    /// Multiplies a safe Python object by another using Python `*=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or deferred
    /// multiplication cannot be represented, this traps with `fatalError`. Use
    /// `SafePythonObject.multiplyInPlace(_:)` when in-place multiplication can fail and should be handled.
    static func *= (productand: inout PythonInterpreter.SafePythonObject, multiplicand: PythonInterpreter.SafePythonObject) {
        productand = PythonInterpreter.SafePythonObject.multiplyInPlaceOperator(productand: productand, multiplicand: multiplicand)
    }
    
    /// Divides a safe Python object by another using Python true-division `/=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or a deferred
    /// divisor is zero, this traps with `fatalError`. Use `SafePythonObject.divideInPlace(divisor:)`
    /// when in-place division can fail and should be handled.
    static func /= (quotientand: inout PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) {
        quotientand = PythonInterpreter.SafePythonObject.divideInPlaceOperator(quotientand: quotientand, divisor: divisor)
    }

    /// Replaces a safe Python object with its Python remainder using Python `%=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or a deferred
    /// divisor is zero, this traps with `fatalError`. Use `SafePythonObject.modulusInPlace(divisor:)`
    /// when in-place modulus can fail and should be handled.
    static func %= (quotientand: inout PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) {
        quotientand = PythonInterpreter.SafePythonObject.modulusInPlaceOperator(quotientand: quotientand, divisor: divisor)
    }

    /// Replaces a safe Python object with the result of raising it to an exponent using Python `**=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, a deferred
    /// zero base is raised to a negative exponent, or a deferred result cannot be represented,
    /// this traps with `fatalError`. Use `SafePythonObject.powerInPlace(exponent:)` when in-place
    /// power can fail and should be handled.
    static func **= (base: inout PythonInterpreter.SafePythonObject, exponent: PythonInterpreter.SafePythonObject) {
        base = PythonInterpreter.SafePythonObject.powerInPlaceOperator(base: base, exponent: exponent)
    }
    
    /// Combines two safe Python objects using Python bitwise `&` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or the fully
    /// deferred operand types do not support bitwise AND, this traps with `fatalError`.
    /// Use `SafePythonObject.bitwiseAnd(_:)` when bitwise AND can fail and should be handled.
    static func & (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.bitwiseAndOperator(lhs: lhs, rhs: rhs)
    }

    /// Combines two safe Python objects using Python bitwise `|` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or the fully
    /// deferred operand types do not support bitwise OR, this traps with `fatalError`.
    /// Use `SafePythonObject.bitwiseOr(_:)` when bitwise OR can fail and should be handled.
    static func | (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.bitwiseOrOperator(lhs: lhs, rhs: rhs)
    }

    /// Combines two safe Python objects using Python bitwise `^` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or the fully
    /// deferred operand types do not support bitwise XOR, this traps with `fatalError`.
    /// Use `SafePythonObject.bitwiseXor(_:)` when bitwise XOR can fail and should be handled.
    static func ^ (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.bitwiseXorOperator(lhs: lhs, rhs: rhs)
    }

    /// Shifts a safe Python object left using Python `<<` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, the fully
    /// deferred operand types do not support left shift, a deferred shift count is negative,
    /// or a deferred result cannot be represented, this traps with `fatalError`. Use
    /// `SafePythonObject.bitShiftLeft(_:)` when left shift can fail and should be handled.
    static func << (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.bitShiftLeftOperator(lhs: lhs, rhs: rhs)
    }

    /// Shifts a safe Python object right using Python `>>` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, the fully
    /// deferred operand types do not support right shift, or a deferred shift count is negative,
    /// this traps with `fatalError`. Use `SafePythonObject.bitShiftRight(_:)` when right shift
    /// can fail and should be handled.
    static func >> (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return PythonInterpreter.SafePythonObject.bitShiftRightOperator(lhs: lhs, rhs: rhs)
    }

    /// Replaces a safe Python object with its Python bitwise AND result using `&=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or the fully
    /// deferred operand types do not support bitwise AND, this traps with `fatalError`.
    /// Use `SafePythonObject.bitwiseAndInPlace(_:)` when in-place bitwise AND can fail and should be handled.
    static func &= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        lhs = PythonInterpreter.SafePythonObject.bitwiseAndInPlaceOperator(lhs: lhs, rhs: rhs)
    }

    /// Replaces a safe Python object with its Python bitwise OR result using `|=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or the fully
    /// deferred operand types do not support bitwise OR, this traps with `fatalError`.
    /// Use `SafePythonObject.bitwiseOrInPlace(_:)` when in-place bitwise OR can fail and should be handled.
    static func |= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        lhs = PythonInterpreter.SafePythonObject.bitwiseOrInPlaceOperator(lhs: lhs, rhs: rhs)
    }

    /// Replaces a safe Python object with its Python bitwise XOR result using `^=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or the fully
    /// deferred operand types do not support bitwise XOR, this traps with `fatalError`.
    /// Use `SafePythonObject.bitwiseXorInPlace(_:)` when in-place bitwise XOR can fail and should be handled.
    static func ^= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        lhs = PythonInterpreter.SafePythonObject.bitwiseXorInPlaceOperator(lhs: lhs, rhs: rhs)
    }

    /// Replaces a safe Python object with its Python left-shift result using `<<=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, the fully
    /// deferred operand types do not support left shift, a deferred shift count is negative,
    /// or a deferred result cannot be represented, this traps with `fatalError`. Use
    /// `SafePythonObject.bitShiftLeftInPlace(_:)` when in-place left shift can fail and should be handled.
    static func <<= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        lhs = PythonInterpreter.SafePythonObject.bitShiftLeftInPlaceOperator(lhs: lhs, rhs: rhs)
    }

    /// Replaces a safe Python object with its Python right-shift result using `>>=` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, the fully
    /// deferred operand types do not support right shift, or a deferred shift count is negative,
    /// this traps with `fatalError`. Use `SafePythonObject.bitShiftRightInPlace(_:)` when in-place
    /// right shift can fail and should be handled.
    static func >>= (lhs: inout PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) {
        lhs = PythonInterpreter.SafePythonObject.bitShiftRightInPlaceOperator(lhs: lhs, rhs: rhs)
    }

    /// Returns the Python bitwise inversion of a safe Python object using `~` semantics.
    ///
    /// This operator is non-throwing. If Python raises, conversion fails, or the fully
    /// deferred operand type does not support bitwise inversion, this traps with `fatalError`.
    /// Use `SafePythonObject.bitwiseInvert()` when bitwise inversion can fail and should be handled.
    static prefix func ~ (_ operand: Self) -> Self {
        return PythonInterpreter.SafePythonObject.bitwiseNotOperator(operand)
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
