//
//  PythonInterpreter+Operator.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

extension PythonInterpreter {
    
    // MARK: Addition
    
    internal func syncAdd(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Add")
        guard let sumPtr = api.PyNumber_Add(lhsPtr, rhsPtr) else {
            logger.error("PyNumber_Add returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "addition", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: sumPtr)
    }
    
    internal func add(lhs: PythonObject, rhs: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject:lhs)!
        let rhsPtr = getRegisteredPointer(forPythonObject:rhs)!
        
        logger.trace("CPython API call in async mode: PyNumber_Add")
        return try await withGIL {
            guard let sumPtr = api.PyNumber_Add(lhsPtr, rhsPtr) else {
                logger.error("PyNumber_Add returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "addition", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer:sumPtr)
        }
    }
    
    internal func syncInPlaceAdd(sumend: SafePythonObject, addend: SafePythonObject) throws -> SafePythonObject {
        let sumendPtr = getRegisteredPointer(forSafeObj:sumend)
        let addendPtr = getRegisteredPointer(forSafeObj:addend)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceAdd")
        guard let sumPtr = api.PyNumber_InPlaceAdd(sumendPtr, addendPtr) else {
            logger.error("PyNumber_InPlaceAdd returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "in place addition", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: sumPtr)
    }
    
    internal func addInPlace(lhs: PythonObject, rhs: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject:lhs)!
        let rhsPtr = getRegisteredPointer(forPythonObject:rhs)!
        
        logger.trace("CPython API call in async mode: PyNumber_InPlaceAdd")
        return try await withGIL {
            guard let sumPtr = api.PyNumber_InPlaceAdd(lhsPtr, rhsPtr) else {
                logger.error("PyNumber_InPlaceAdd returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "in place addition", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: sumPtr)
        }
    }
    
    // MARK: Subtraction
    
    internal func syncSubtract(minuend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        let minuendPtr = getRegisteredPointer(forSafeObj:minuend)
        let subtrahendPtr = getRegisteredPointer(forSafeObj:subtrahend)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Subtract")
        guard let differencePtr = api.PyNumber_Subtract(minuendPtr, subtrahendPtr) else {
            logger.error("PyNumber_Subtract returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "subtraction", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: differencePtr)
    }
    
    internal func subtract(minuend: PythonObject, subtrahend: PythonObject) async throws -> PythonObject {
        let minuendPtr = getRegisteredPointer(forPythonObject:minuend)!
        let subtrahendPtr = getRegisteredPointer(forPythonObject:subtrahend)!
        
        logger.trace("CPython API call in async mode: PyNumber_Subtract")
        return try await withGIL {
            guard let differencePtr = api.PyNumber_Subtract(minuendPtr, subtrahendPtr) else {
                logger.error("PyNumber_Subtract returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "subtraction", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer:differencePtr)
        }
    }
    
    internal func syncInPlaceSubtract(diffend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        let diffendPtr = getRegisteredPointer(forSafeObj:diffend)
        let subtrahendPtr = getRegisteredPointer(forSafeObj:subtrahend)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceSubtract")
        guard let differencePtr = api.PyNumber_InPlaceSubtract(diffendPtr, subtrahendPtr) else {
            logger.error("PyNumber_InPlaceSubtract returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "in place subtraction", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: differencePtr)
    }
    
    internal func subtractInPlace(minuend: PythonObject, subtrahend: PythonObject) async throws -> PythonObject {
        let minuendPtr = getRegisteredPointer(forPythonObject:minuend)!
        let subtrahendPtr = getRegisteredPointer(forPythonObject:subtrahend)!
        
        logger.trace("CPython API call in async mode: PyNumber_InPlaceSubtract")
        return try await withGIL {
            guard let differencePtr = api.PyNumber_InPlaceSubtract(minuendPtr, subtrahendPtr) else {
                logger.error("PyNumber_InPlaceSubtract returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "in place subtraction", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: differencePtr)
        }
    }
    
    // MARK: Multiplication
    
    internal func syncMultiply(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj: lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj: rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Multiply")
        guard let productPtr = api.PyNumber_Multiply(lhsPtr, rhsPtr) else {
            logger.error("PyNumber_Multiply returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "multiplication", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: productPtr)
    }
    
    internal func multiply(_ lhs: PythonObject, _ rhs: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPtr = getRegisteredPointer(forPythonObject: rhs)!
        
        logger.trace("CPython API call in async mode: PyNumber_Multiply")
        return try await withGIL {
            guard let productPtr = api.PyNumber_Multiply(lhsPtr, rhsPtr) else {
                logger.error("PyNumber_Multiply returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "multiplication", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: productPtr)
        }
    }
    
    internal func syncInPlaceMultiply(productand: SafePythonObject, multiplicand: SafePythonObject) throws -> SafePythonObject {
        let productandPtr = getRegisteredPointer(forSafeObj: productand)
        let multiplicandPtr = getRegisteredPointer(forSafeObj: multiplicand)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceMultiply")
        guard let productPtr = api.PyNumber_InPlaceMultiply(productandPtr, multiplicandPtr) else {
            logger.error("PyNumber_InPlaceMultiply returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "in place multiplication", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: productPtr)
    }
    
    internal func multiplyInPlace(_ lhs: PythonObject, _ rhs: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPtr = getRegisteredPointer(forPythonObject: rhs)!
        
        logger.trace("CPython API call in async mode: PyNumber_InPlaceMultiply")
        return try await withGIL {
            guard let productPtr = api.PyNumber_InPlaceMultiply(lhsPtr, rhsPtr) else {
                logger.error("PyNumber_InPlaceMultiply returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "in place multiplication", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: productPtr)
        }
    }
    
    // MARK: Division
    
    internal func syncDivide(dividend: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let dividendPtr = getRegisteredPointer(forSafeObj: dividend)
        let divisorPtr = getRegisteredPointer(forSafeObj: divisor)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_TrueDivide")
        guard let quotientPtr = api.PyNumber_TrueDivide(dividendPtr, divisorPtr) else {
            logger.error("PyNumber_TrueDivide returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "division", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: quotientPtr)
    }
    
    internal func divide(dividend: PythonObject, divisor: PythonObject) async throws -> PythonObject {
        let dividendPtr = getRegisteredPointer(forPythonObject: dividend)!
        let divisorPtr = getRegisteredPointer(forPythonObject: divisor)!
        
        logger.trace("CPython API call in async mode: PyNumber_TrueDivide")
        return try await withGIL {
            guard let quotientPtr = api.PyNumber_TrueDivide(dividendPtr, divisorPtr) else {
                logger.error("PyNumber_TrueDivide returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "division", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: quotientPtr)
        }
    }
    
    internal func syncInPlaceDivide(quotientand: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let quotientandPtr = getRegisteredPointer(forSafeObj:quotientand)
        let divisorPtr = getRegisteredPointer(forSafeObj:divisor)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceTrueDivide")
        guard let quotientPtr = api.PyNumber_InPlaceTrueDivide(quotientandPtr, divisorPtr) else {
            logger.error("PyNumber_InPlaceTrueDivide returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "in place division", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: quotientPtr)
    }
    
    internal func divideInPlace(_ lhs: PythonObject, _ divisor: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let divisorPtr = getRegisteredPointer(forPythonObject: divisor)!
        
        logger.trace("CPython API call in async mode: PyNumber_InPlaceTrueDivide")
        return try await withGIL {
            guard let quotientPtr = api.PyNumber_InPlaceTrueDivide(lhsPtr, divisorPtr) else {
                logger.error("PyNumber_InPlaceTrueDivide returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "in place division", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: quotientPtr)
        }
    }
    
    // MARK: Modulus
    
    internal func syncModulus(dividend: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let dividendPtr = getRegisteredPointer(forSafeObj:dividend)
        let divisorPtr = getRegisteredPointer(forSafeObj:divisor)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Remainder")
        guard let remainderPtr = api.PyNumber_Remainder(dividendPtr, divisorPtr) else {
            logger.error("PyNumber_Remainder returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "modulus", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: remainderPtr)
    }
    
    internal func modulus(dividend: PythonObject, divisor: PythonObject) async throws -> PythonObject {
        let dividendPtr = getRegisteredPointer(forPythonObject: dividend)!
        let divisorPtr = getRegisteredPointer(forPythonObject: divisor)!
        
        logger.trace("CPython API call in async mode: PyNumber_Remainder")
        return try await withGIL {
            guard let remainderPtr = api.PyNumber_Remainder(dividendPtr, divisorPtr) else {
                logger.error("PyNumber_Remainder returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "modulus", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: remainderPtr)
        }
    }
    
    internal func syncInPlaceRemainder(quotientand: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let quotientandPtr = getRegisteredPointer(forSafeObj:quotientand)
        let divisorPtr = getRegisteredPointer(forSafeObj:divisor)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceRemainder")
        guard let remainderPtr = api.PyNumber_InPlaceRemainder(quotientandPtr, divisorPtr) else {
            logger.error("PyNumber_InPlaceRemainder returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "in place modulus", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: remainderPtr)
    }
    
    internal func modulusInPlace(_ lhs: PythonObject, _ divisor: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let divisorPtr = getRegisteredPointer(forPythonObject: divisor)!
        
        logger.trace("CPython API call in async mode: PyNumber_InPlaceRemainder")
        return try await withGIL {
            guard let quotientPtr = api.PyNumber_InPlaceRemainder(lhsPtr, divisorPtr) else {
                logger.error("PyNumber_InPlaceRemainder returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "in place modulus", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: quotientPtr)
        }
    }
    
    // MARK: Exponentiation
    
    internal func syncPower(base: SafePythonObject, exponent: SafePythonObject) throws -> SafePythonObject {
        let basePtr = getRegisteredPointer(forSafeObj:base)
        let exponentPtr = getRegisteredPointer(forSafeObj:exponent)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Power")
        guard let resultPtr = api.pythonNumber_Power(basePtr, exponentPtr) else {
            logger.error("pythonNumber_Power returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "power", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func power(base: PythonObject, exponent: PythonObject) async throws -> PythonObject {
        let basePtr = getRegisteredPointer(forPythonObject: base)!
        let exponentPtr = getRegisteredPointer(forPythonObject: exponent)!
        
        logger.trace("CPython API call in async mode: PyNumber_Power")
        return try await withGIL {
            guard let resultPtr = api.pythonNumber_Power(basePtr, exponentPtr) else {
                logger.error("pythonNumber_Power returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "power", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: resultPtr)
        }
    }
    
    internal func syncInPlacePower(lhs: SafePythonObject, exponent: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let exponentPtr = getRegisteredPointer(forSafeObj:exponent)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlacePower")
        guard let resultPtr = api.pythonNumber_InPlacePower(lhsPtr, exponentPtr) else {
            logger.error("pythonNumber_InPlacePower returned NULL.  Throwing Python error.")
            try throwSafePythonErrorIfPresent()
            throw PythonError.typeError(operation: "in place power", opType1: "SafePythonObject", opType2: "SafePythonObject")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func powerInPlace(_ lhs: PythonObject, _ exponent: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let exponentPtr = getRegisteredPointer(forPythonObject: exponent)!
        
        logger.trace("CPython API call in async mode: PyNumber_InPlacePower")
        return try await withGIL {
            guard let resultPtr = api.pythonNumber_InPlacePower(lhsPtr, exponentPtr) else {
                logger.error("pythonNumber_InPlacePower returned NULL.  Throwing Python error.")
                try throwPythonErrorIfPresent()
                throw PythonError.typeError(operation: "in place power", opType1: "PythonObject", opType2: "PythonObject")
            }
            return newPythonObject(fromReturnedPointer: resultPtr)
        }
    }
    
    // MARK: Bitwise AND
    
    internal func syncBitwiseAnd(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_And")
        guard let resultPtr = api.PyNumber_And(lhsPtr, rhsPtr) else {
            logger.error("PyNumber_And returned NULL.  Throwing Python error.")
            throw PythonError.nullPointer("Python '&' failed")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func syncInPlaceBitwiseAnd(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceAnd")
        guard let resultPtr = api.PyNumber_InPlaceAnd(lhsPtr, rhsPtr) else {
            logger.error("PyNumber_InPlaceAnd returned NULL.  Throwing Python error.")
            throw PythonError.nullPointer("Python '&=' failed")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    // MARK: Bitwise OR
    
    internal func syncBitwiseOr(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Or")
        guard let resultPtr = api.PyNumber_Or(lhsPtr, rhsPtr) else {
            logger.error("PyNumber_Or returned NULL.  Throwing Python error.")
            throw PythonError.nullPointer("Python '|' failed")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func syncInPlaceBitwiseOr(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceOr")
        guard let resultPtr = api.PyNumber_InPlaceOr(lhsPtr, rhsPtr) else {
            logger.error("PyNumber_InPlaceOr returned NULL.  Throwing Python error.")
            throw PythonError.nullPointer("Python '|=' failed")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    // MARK: Bitwise XOR
    
    internal func syncBitwiseXor(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Xor")
        guard let resultPtr = api.PyNumber_Xor(lhsPtr, rhsPtr) else {
            logger.error("PyNumber_Xor returned NULL.  Throwing Python error.")
            throw PythonError.nullPointer("Python '^' failed")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    internal func syncInPlaceBitwiseXor(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceXor")
        guard let resultPtr = api.PyNumber_InPlaceXor(lhsPtr, rhsPtr) else {
            logger.error("PyNumber_InPlaceXor returned NULL.  Throwing Python error.")
            throw PythonError.nullPointer("Python '^=' failed")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    // MARK: Bitwise NOT
    
    internal func syncBitwiseNot(_ operand: SafePythonObject) throws -> SafePythonObject {
        let operandPtr = getRegisteredPointer(forSafeObj:operand)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Invert")
        guard let resultPtr = api.PyNumber_Invert(operandPtr) else {
            logger.error("PyNumber_Invert returned NULL.  Throwing Python error.")
            throw PythonError.nullPointer("Python '~' failed")
        }
        return newSafePythonObject(fromReturnedPointer: resultPtr)
    }
    
    
}
