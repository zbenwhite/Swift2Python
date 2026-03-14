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
            fatalError("Cannot subtract with two non-bound Python objects")
        }
    }

    static func * (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        if lhs.isBoundToPythonInterpreter {
            return lhs.multiplyOperator(lhs, rhs)
        } else if rhs.isBoundToPythonInterpreter {
            return rhs.multiplyOperator(lhs, rhs)
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
            fatalError("Cannot subtract in place two non-bound Python objects")
        }
    }
    
    static func *= (productand: inout PythonInterpreter.SafePythonObject, multiplicand: PythonInterpreter.SafePythonObject) {
        if productand.isBoundToPythonInterpreter {
            productand = productand.multiplyInPlaceOperator(productand:productand, multiplicand:multiplicand)
        } else if multiplicand.isBoundToPythonInterpreter {
            productand = multiplicand.multiplyInPlaceOperator(productand:productand, multiplicand:multiplicand)
        } else {
            fatalError("Cannot multiply in place two non-bound Python objects")
        }
    }
    
    static func /= (quotientand: inout PythonInterpreter.SafePythonObject, divisor: PythonInterpreter.SafePythonObject) {
        if quotientand.isBoundToPythonInterpreter {
            quotientand = quotientand.divideInPlaceOperator(quotientand:quotientand, divisor:divisor)
        } else if divisor.isBoundToPythonInterpreter {
            quotientand = divisor.divideInPlaceOperator(quotientand:quotientand, divisor:divisor)
        } else {
            fatalError("Cannot divide in place two non-bound Python objects")
        }
    }

}
