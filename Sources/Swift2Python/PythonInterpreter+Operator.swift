//
//  PythonInterpreter+Operator.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//


extension PythonInterpreter {
    
    // MARK: Operator support (synchronous mode)
    // Operators for synchronous mode ----------
    
    internal func syncAdd(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Add")
        guard let sumPtr = api.PyNumber_Add(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '+' failed")
        }
        
        let sumId = registerPythonObjectPointer(sumPtr)
        return SafePythonObject(interpreter: self, id: sumId)
    }
    
    internal func syncBitwiseAnd(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_And")
        guard let resultPtr = api.PyNumber_And(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '&' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncBitwiseNot(_ operand: SafePythonObject) throws -> SafePythonObject {
        let operandPtr = getRegisteredPythonObjectPointer(operand.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Invert")
        guard let resultPtr = api.PyNumber_Invert(operandPtr) else {
            throw PythonError.nullPointer("Python '~' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncBitwiseOr(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Or")
        guard let resultPtr = api.PyNumber_Or(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '|' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncBitwiseXor(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Xor")
        guard let resultPtr = api.PyNumber_Xor(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '^' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncDivide(dividend: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let dividendPtr = getRegisteredPythonObjectPointer(dividend.id)!
        let divisorPtr = getRegisteredPythonObjectPointer(divisor.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_TrueDivide")
        guard let quotientPtr = api.PyNumber_TrueDivide(dividendPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '/' failed")
        }
        
        let quotientId = registerPythonObjectPointer(quotientPtr)
        return SafePythonObject(interpreter: self, id: quotientId)
    }
    
    internal func syncDoubleEquals(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.equal.rawValue) else {
            throw PythonError.nullPointer("Python '==' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncDoubleEqualsEquatable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.equal.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncGreaterThan(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThan.rawValue) else {
            throw PythonError.nullPointer("Python '>' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncGreaterThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThan.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncGreaterThanOrEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThanOrEqual.rawValue) else {
            throw PythonError.nullPointer("Python '>=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncGreaterThanOrEqualComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThanOrEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncInPlaceAdd(sumend: SafePythonObject, addend: SafePythonObject) throws -> SafePythonObject {
        let sumendPtr = getRegisteredPythonObjectPointer(sumend.id)!
        let addendPtr = getRegisteredPythonObjectPointer(addend.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceAdd")
        guard let sumPtr = api.PyNumber_InPlaceAdd(sumendPtr, addendPtr) else {
            throw PythonError.nullPointer("Python '+=' failed")
        }
        
        let sumId = registerPythonObjectPointer(sumPtr)
        return SafePythonObject(interpreter: self, id: sumId)
    }
    
    internal func syncInPlaceBitwiseAnd(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceAnd")
        guard let resultPtr = api.PyNumber_InPlaceAnd(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '&=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncInPlaceBitwiseOr(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceOr")
        guard let resultPtr = api.PyNumber_InPlaceOr(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '|=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncInPlaceBitwiseXor(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceXor")
        guard let resultPtr = api.PyNumber_InPlaceXor(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '^=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncInPlaceDivide(quotientand: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let quotientandPtr = getRegisteredPythonObjectPointer(quotientand.id)!
        let divisorPtr = getRegisteredPythonObjectPointer(divisor.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceTrueDivide")
        guard let quotientPtr = api.PyNumber_InPlaceTrueDivide(quotientandPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '/=' failed")
        }
        
        let quotientId = registerPythonObjectPointer(quotientPtr)
        return SafePythonObject(interpreter: self, id: quotientId)
    }
    
    internal func syncInPlaceMultiply(productand: SafePythonObject, multiplicand: SafePythonObject) throws -> SafePythonObject {
        let productandPtr = getRegisteredPythonObjectPointer(productand.id)!
        let multiplicandPtr = getRegisteredPythonObjectPointer(multiplicand.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceMultiply")
        guard let productPtr = api.PyNumber_InPlaceMultiply(productandPtr, multiplicandPtr) else {
            throw PythonError.nullPointer("Python '*=' failed")
        }
        
        let productId = registerPythonObjectPointer(productPtr)
        return SafePythonObject(interpreter: self, id: productId)
    }
    
    internal func syncInPlaceSubtract(diffend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        let diffendPtr = getRegisteredPythonObjectPointer(diffend.id)!
        let subtrahendPtr = getRegisteredPythonObjectPointer(subtrahend.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceSubtract")
        guard let differencePtr = api.PyNumber_InPlaceSubtract(diffendPtr, subtrahendPtr) else {
            throw PythonError.nullPointer("Python '-=' failed")
        }
        
        let differenceId = registerPythonObjectPointer(differencePtr)
        return SafePythonObject(interpreter: self, id: differenceId)
    }
    
    internal func syncLessThan(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.lessThan.rawValue) else {
            throw PythonError.nullPointer("Python '<' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncLessThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.lessThan.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncLessThanOrEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.lessThanOrEqual.rawValue) else {
            throw PythonError.nullPointer("Python '<=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncLessThanOrEqualComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.lessThanOrEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncMultiply(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Multiply")
        guard let productPtr = api.PyNumber_Multiply(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '*' failed")
        }
        
        let productId = registerPythonObjectPointer(productPtr)
        return SafePythonObject(interpreter: self, id: productId)
    }
    
    internal func syncNotEquals(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.notEqual.rawValue) else {
            throw PythonError.nullPointer("Python '!=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncNotEqualsEquatable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.notEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncSubtract(minuend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        let minuendPtr = getRegisteredPythonObjectPointer(minuend.id)!
        let subtrahendPtr = getRegisteredPythonObjectPointer(subtrahend.id)!
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Subtract")
        guard let differencePtr = api.PyNumber_Subtract(minuendPtr, subtrahendPtr) else {
            throw PythonError.nullPointer("Python '-' failed")
        }
        
        let differenceId = registerPythonObjectPointer(differencePtr)
        return SafePythonObject(interpreter: self, id: differenceId)
    }
    
    
}
