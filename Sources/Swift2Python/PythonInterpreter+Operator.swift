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
            throw PythonError.nullPointer("Python '+' failed")
        }
        
        let sumId = registerSafePythonObject(sumPtr)
        let sumObj = SafePythonObject(interpreter: self, id: sumId)
        self.incrementHousekeepingRefCount(forSafeObj: sumObj)
        return sumObj
    }
    
    internal func add(lhs: PythonObject, rhs: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject:lhs)!
        let rhsPtr = getRegisteredPointer(forPythonObject:rhs)!
        
        logger.trace("CPython API call in async mode: PyNumber_Add")
        return try withGIL {
            guard let sumPtr = api.PyNumber_Add(lhsPtr, rhsPtr) else {
                throw PythonError.nullPointer("Python '+' failed")
            }
            
            let sumId = registerPythonObjectPointer(sumPtr)
            return PythonObject(id: sumId, interpreter: self)
        }
    }
    
    internal func syncInPlaceAdd(sumend: SafePythonObject, addend: SafePythonObject) throws -> SafePythonObject {
        let sumendPtr = getRegisteredPointer(forSafeObj:sumend)
        let addendPtr = getRegisteredPointer(forSafeObj:addend)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceAdd")
        guard let sumPtr = api.PyNumber_InPlaceAdd(sumendPtr, addendPtr) else {
            throw PythonError.nullPointer("Python '+=' failed")
        }
        
        let sumId = registerSafePythonObject(sumPtr)
        let sumObj = SafePythonObject(interpreter: self, id: sumId)
        self.incrementHousekeepingRefCount(forSafeObj: sumObj)
        return sumObj
    }
    
    internal func addInPlace(lhs: PythonObject, rhs: PythonObject) async throws -> PythonObject {
        let lhsPtr = getRegisteredPointer(forPythonObject:lhs)!
        let rhsPtr = getRegisteredPointer(forPythonObject:rhs)!
        
        logger.trace("CPython API call in async mode: PyNumber_InPlaceAdd")
        return try withGIL {
            guard let sumPtr = api.PyNumber_InPlaceAdd(lhsPtr, rhsPtr) else {
                throw PythonError.nullPointer("Python '+=' failed")
            }
            
            let sumId = registerPythonObjectPointer(sumPtr)
            return PythonObject(id: sumId, interpreter: self)
        }
    }
    
    // MARK: Subtraction
    
    internal func syncSubtract(minuend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        let minuendPtr = getRegisteredPointer(forSafeObj:minuend)
        let subtrahendPtr = getRegisteredPointer(forSafeObj:subtrahend)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Subtract")
        guard let differencePtr = api.PyNumber_Subtract(minuendPtr, subtrahendPtr) else {
            throw PythonError.nullPointer("Python '-' failed")
        }
        
        let differenceId = registerSafePythonObject(differencePtr)
        let differenceObj = SafePythonObject(interpreter: self, id: differenceId)
        self.incrementHousekeepingRefCount(forSafeObj: differenceObj)
        return differenceObj
    }
    
    internal func subtract(minuend: PythonObject, subtrahend: PythonObject) async throws -> PythonObject {
        let minuendPtr = getRegisteredPointer(forPythonObject:minuend)!
        let subtrahendPtr = getRegisteredPointer(forPythonObject:subtrahend)!
        
        logger.trace("CPython API call in async mode: PyNumber_Subtract")
        return try withGIL {
            guard let differencePtr = api.PyNumber_Subtract(minuendPtr, subtrahendPtr) else {
                throw PythonError.nullPointer("Python '-' failed")
            }
            
            let differenceId = registerPythonObjectPointer(differencePtr)
            return PythonObject(id: differenceId, interpreter: self)
        }
    }
    
    internal func syncInPlaceSubtract(diffend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        let diffendPtr = getRegisteredPointer(forSafeObj:diffend)
        let subtrahendPtr = getRegisteredPointer(forSafeObj:subtrahend)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceSubtract")
        guard let differencePtr = api.PyNumber_InPlaceSubtract(diffendPtr, subtrahendPtr) else {
            throw PythonError.nullPointer("Python '-=' failed")
        }
        
        let differenceId = registerSafePythonObject(differencePtr)
        let differenceObj = SafePythonObject(interpreter: self, id: differenceId)
        self.incrementHousekeepingRefCount(forSafeObj: differenceObj)
        return differenceObj
    }
    
    internal func subtractInPlace(minuend: PythonObject, subtrahend: PythonObject) async throws -> PythonObject {
        let minuendPtr = getRegisteredPointer(forPythonObject:minuend)!
        let subtrahendPtr = getRegisteredPointer(forPythonObject:subtrahend)!
        
        logger.trace("CPython API call in async mode: PyNumber_InPlaceAddSubtract")
        return try withGIL {
            guard let differencePtr = api.PyNumber_InPlaceAdd(minuendPtr, subtrahendPtr) else {
                throw PythonError.nullPointer("Python '-=' failed")
            }
            
            let differenceId = registerPythonObjectPointer(differencePtr)
            return PythonObject(id: differenceId, interpreter: self)
        }
    }
    
    // MARK: Multiplication
    
    internal func syncMultiply(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Multiply")
        guard let productPtr = api.PyNumber_Multiply(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '*' failed")
        }
        
        let productId = registerSafePythonObject(productPtr)
        let productObj = SafePythonObject(interpreter: self, id: productId)
        self.incrementHousekeepingRefCount(forSafeObj: productObj)
        return productObj
    }
    
    internal func syncInPlaceMultiply(productand: SafePythonObject, multiplicand: SafePythonObject) throws -> SafePythonObject {
        let productandPtr = getRegisteredPointer(forSafeObj:productand)
        let multiplicandPtr = getRegisteredPointer(forSafeObj:multiplicand)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceMultiply")
        guard let productPtr = api.PyNumber_InPlaceMultiply(productandPtr, multiplicandPtr) else {
            throw PythonError.nullPointer("Python '*=' failed")
        }
        
        let productId = registerSafePythonObject(productPtr)
        let productObj = SafePythonObject(interpreter: self, id: productId)
        self.incrementHousekeepingRefCount(forSafeObj: productObj)
        return productObj
    }
    
    // MARK: Division
    
    internal func syncDivide(dividend: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let dividendPtr = getRegisteredPointer(forSafeObj:dividend)
        let divisorPtr = getRegisteredPointer(forSafeObj:divisor)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_TrueDivide")
        guard let quotientPtr = api.PyNumber_TrueDivide(dividendPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '/' failed")
        }
        
        let quotientId = registerSafePythonObject(quotientPtr)
        let quotientObj = SafePythonObject(interpreter: self, id: quotientId)
        self.incrementHousekeepingRefCount(forSafeObj: quotientObj)
        return quotientObj
    }
    
    internal func syncInPlaceDivide(quotientand: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let quotientandPtr = getRegisteredPointer(forSafeObj:quotientand)
        let divisorPtr = getRegisteredPointer(forSafeObj:divisor)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceTrueDivide")
        guard let quotientPtr = api.PyNumber_InPlaceTrueDivide(quotientandPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '/=' failed")
        }
        
        let quotientId = registerSafePythonObject(quotientPtr)
        let quotientObj = SafePythonObject(interpreter: self, id: quotientId)
        self.incrementHousekeepingRefCount(forSafeObj: quotientObj)
        return quotientObj
    }
    
    // MARK: Modulus
    
    internal func syncModulus(dividend: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let dividendPtr = getRegisteredPointer(forSafeObj:dividend)
        let divisorPtr = getRegisteredPointer(forSafeObj:divisor)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_TrueDivide")
        guard let remainderPtr = api.PyNumber_Remainder(dividendPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '%' failed")
        }
        
        let remainderId = registerSafePythonObject(remainderPtr)
        let remainderObj = SafePythonObject(interpreter: self, id: remainderId)
        self.incrementHousekeepingRefCount(forSafeObj: remainderObj)
        return remainderObj
    }
    
    internal func syncInPlaceRemainder(quotientand: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let quotientandPtr = getRegisteredPointer(forSafeObj:quotientand)
        let divisorPtr = getRegisteredPointer(forSafeObj:divisor)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceRemainder")
        guard let remainderPtr = api.PyNumber_InPlaceRemainder(quotientandPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '%=' failed")
        }
        
        let reminderId = registerSafePythonObject(remainderPtr)
        let reminderObj = SafePythonObject(interpreter: self, id: reminderId)
        self.incrementHousekeepingRefCount(forSafeObj: reminderObj)
        return reminderObj
    }
    
    // MARK: Exponentiation
    
    internal func syncPower(base: SafePythonObject, exponent: SafePythonObject) throws -> SafePythonObject {
        let basePtr = getRegisteredPointer(forSafeObj:base)
        let exponentPtr = getRegisteredPointer(forSafeObj:exponent)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Power")
        guard let resultPtr = try api.pythonNumber_Power(basePtr, exponentPtr) else {
            throw PythonError.nullPointer("Python '**' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncInPlacePower(lhs: SafePythonObject, exponent: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let exponentPtr = getRegisteredPointer(forSafeObj:exponent)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlacePower")
        guard let resultPtr = try api.pythonNumber_InPlacePower(lhsPtr, exponentPtr) else {
            throw PythonError.nullPointer("Python '**=' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    // MARK: Bitwise AND
    
    internal func syncBitwiseAnd(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_And")
        guard let resultPtr = api.PyNumber_And(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '&' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncInPlaceBitwiseAnd(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceAnd")
        guard let resultPtr = api.PyNumber_InPlaceAnd(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '&=' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    // MARK: Bitwise OR
    
    internal func syncBitwiseOr(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Or")
        guard let resultPtr = api.PyNumber_Or(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '|' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncInPlaceBitwiseOr(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceOr")
        guard let resultPtr = api.PyNumber_InPlaceOr(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '|=' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    // MARK: Bitwise XOR
    
    internal func syncBitwiseXor(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Xor")
        guard let resultPtr = api.PyNumber_Xor(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '^' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncInPlaceBitwiseXor(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_InPlaceXor")
        guard let resultPtr = api.PyNumber_InPlaceXor(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '^=' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    // MARK: Bitwise NOT
    
    internal func syncBitwiseNot(_ operand: SafePythonObject) throws -> SafePythonObject {
        let operandPtr = getRegisteredPointer(forSafeObj:operand)
        
        logger.trace("CPython API call in synchronous mode: PyNumber_Invert")
        guard let resultPtr = api.PyNumber_Invert(operandPtr) else {
            throw PythonError.nullPointer("Python '~' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    // MARK: Equals Operator
    
    internal func syncDoubleEquals(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.equal.rawValue) else {
            throw PythonError.nullPointer("Python '==' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncDoubleEqualsEquatable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.equal.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    // MARK: Not Equals Operator
    
    internal func syncNotEquals(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.notEqual.rawValue) else {
            throw PythonError.nullPointer("Python '!=' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncNotEqualsEquatable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.notEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    // MARK: Greater than
    
    internal func syncGreaterThan(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThan.rawValue) else {
            throw PythonError.nullPointer("Python '>' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncGreaterThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThan.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    // MARK: Greater than or equal
    
    internal func syncGreaterThanOrEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThanOrEqual.rawValue) else {
            throw PythonError.nullPointer("Python '>=' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncGreaterThanOrEqualComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThanOrEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    // MARK: Less than
    
    internal func syncLessThan(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.lessThan.rawValue) else {
            throw PythonError.nullPointer("Python '<' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncLessThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.lessThan.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    // MARK: Less than or equal
    
    internal func syncLessThanOrEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.lessThanOrEqual.rawValue) else {
            throw PythonError.nullPointer("Python '<=' failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncLessThanOrEqualComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.lessThanOrEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
}
