//
//  BitwiseOpsTest+ShiftRight.swift
//  Swift2Python
//
//  Created by Ben White on 6/18/26.
//

import Testing
import Logging
@testable import Swift2Python

extension BitwiseOpsTests {
    
    @Test("O>>_001: Bit shift right operator integer")
    func bitShiftRightOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundValue = try 12.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundCount = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundValue: PythonInterpreter.SafePythonObject = -12
            let unboundCount: PythonInterpreter.SafePythonObject = 1
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int >> bound int", boundValue, boundCount, 3),
                ("bound int >> unbound int", boundValue, unboundCount, 6),
                ("unbound int >> bound int", unboundValue, boundCount, -3),
                ("unbound int >> unbound int", unboundValue, unboundCount, -6),
                ("bound int >> bound bool", boundValue, boundTrue, 6),
                ("bound int >> unbound bool", boundValue, unboundFalse, 12),
                ("unbound int >> bound bool", unboundValue, boundTrue, -6),
                ("unbound int >> unbound bool", unboundValue, unboundFalse, -12)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result = lhs >> rhs
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O>>_004: Bit shift right operator bool")
    func bitShiftRightOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            let boundCount = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundCount: PythonInterpreter.SafePythonObject = 2
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool >> bound bool", boundTrue, boundTrue, 0),
                ("bound bool >> unbound bool", boundTrue, unboundFalse, 1),
                ("unbound bool >> bound bool", unboundTrue, boundFalse, 1),
                ("unbound bool >> unbound bool", unboundTrue, unboundTrue, 0),
                ("bound bool >> bound int", boundTrue, boundCount, 0),
                ("unbound bool >> unbound int", unboundTrue, unboundCount, 0),
                ("false >> int", unboundFalse, boundCount, 0)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result = lhs >> rhs
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O>>_005: PythonObject async bit shift right")
    func bitShiftRightPythonObject() async throws {
        let value = try await 12.toPythonObject(interpreter: interpreter)
        let count = try await 2.toPythonObject(interpreter: interpreter)
        let result = try await value.bitShiftRight(count)
        #expect(try await Int(result) == 3)
        
        let convertedResult = try await value.bitShiftRight(1)
        #expect(try await Int(convertedResult) == 6)
        
        let boolValue = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolValue.bitShiftRight(false)
        #expect(try await Int(boolResult) == 1)
    }
    
    @Test("O>>_006: PythonObject async bit shift right error checking")
    func bitShiftRightPythonObjectError() async throws {
        let value = try await 12.toPythonObject(interpreter: interpreter)
        
        let stringError = await #expect(throws: PythonError.self) {
            _ = try await value.bitShiftRight("abc")
        }
        
        if case .pythonException = stringError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject right shift type error, but got \(String(describing: stringError))")
        }
        
        let negativeError = await #expect(throws: PythonError.self) {
            _ = try await value.bitShiftRight(-1)
        }
        
        if case .pythonException = negativeError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject negative right shift, but got \(String(describing: negativeError))")
        }
    }
    
    @Test("O>>_010: safePythonObject bit shift right error checking")
    func safeBitShiftRightErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundValue = try 12.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 12
            let unboundNegative: PythonInterpreter.SafePythonObject = -12
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let negativeCount: PythonInterpreter.SafePythonObject = -1
            let veryLargeCount = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
            
            let typeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound string >> unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound int >> unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound double >> unbound int", unboundDouble, unboundInt, "Double", "Int")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in typeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.bitShiftRight(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "right shift", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let deferredNegativeError = #expect(throws: PythonError.self) {
                _ = try unboundInt.bitShiftRight(negativeCount)
            }
            
            if case .valueError(let message) = deferredNegativeError {
                #expect(message == "negative shift count")
            } else {
                Issue.record("Expected .valueError for deferred negative right shift, but got \(String(describing: deferredNegativeError))")
            }
            
            #expect(try Int(unboundInt.bitShiftRight(veryLargeCount)) == 0)
            #expect(try Int(unboundNegative.bitShiftRight(veryLargeCount)) == -1)
            
            let boundTypeError = #expect(throws: PythonError.self) {
                _ = try boundValue.bitShiftRight(boundString)
            }
            
            if case .safePythonException = boundTypeError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for bound right shift type error, but got \(String(describing: boundTypeError))")
            }
            
            let convertibleError = #expect(throws: PythonError.self) {
                _ = try unboundInt.bitShiftRight(1)
            }
            
            if case .conversionType = convertibleError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.bitShiftRight(Int), but got \(String(describing: convertibleError))")
            }
        }
    }
    
    @Test("O>>_011: safePythonObject bit shift right accepts SafePythonConvertible values")
    func safeBitShiftRightAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundValue = try 12.toSafePythonObject(interpreter: isolatedInterpreter)
            let intResult = try boundValue.bitShiftRight(2)
            #expect(try Int(intResult) == 3)
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boolResult = try boundTrue.bitShiftRight(false)
            #expect(try Int(boolResult) == 1)
        }
    }
    
    @Test("O>>=_005: PythonObject async in-place bit shift right")
    func bitShiftRightEqualsPythonObject() async throws {
        let value = try await 12.toPythonObject(interpreter: interpreter)
        let result = try await value.bitShiftRightInPlace(2)
        #expect(try await Int(result) == 3)
        
        let boolValue = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolValue.bitShiftRightInPlace(false)
        #expect(try await Int(boolResult) == 1)
    }
    
    @Test("O>>=_006: PythonObject async in-place bit shift right error checking")
    func bitShiftRightEqualsPythonObjectError() async throws {
        let value = try await 12.toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await value.bitShiftRightInPlace("abc")
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject in-place right shift error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O>>=_010: safePythonObject bit shift right equals error checking")
    func safeBitShiftRightEqualsErrors() async throws {
        try await interpreter.withIsolatedContext { _ in
            let unboundInt: PythonInterpreter.SafePythonObject = 12
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let negativeCount: PythonInterpreter.SafePythonObject = -1
            
            var typeTarget = unboundInt
            let typeError = #expect(throws: PythonError.self) {
                try typeTarget.bitShiftRightInPlace(unboundString)
            }
            
            if case let .typeError(operation, opType1, opType2) = typeError {
                #expect(operation == "in place right shift")
                #expect(opType1 == "Int")
                #expect(opType2 == "String")
            } else {
                Issue.record("Expected .typeError for deferred in-place right shift, but got \(String(describing: typeError))")
            }
            
            var negativeTarget = unboundInt
            let negativeError = #expect(throws: PythonError.self) {
                try negativeTarget.bitShiftRightInPlace(negativeCount)
            }
            
            if case .valueError(let message) = negativeError {
                #expect(message == "negative shift count")
            } else {
                Issue.record("Expected .valueError for deferred in-place negative right shift, but got \(String(describing: negativeError))")
            }
        }
    }
    
    @Test("O>>=_011: safePythonObject in-place bit shift right accepts SafePythonConvertible values")
    func safeInPlaceBitShiftRightAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var boundValue = try 12.toSafePythonObject(interpreter: isolatedInterpreter)
            try boundValue.bitShiftRightInPlace(2)
            #expect(try Int(boundValue) == 3)
            
            var deferredValue: PythonInterpreter.SafePythonObject = 12
            let thrownError = #expect(throws: PythonError.self) {
                try deferredValue.bitShiftRightInPlace(2)
            }
            
            if case .conversionType = thrownError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.bitShiftRightInPlace(Int), but got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("O>>=_012: Bit shift right equals operator")
    func bitShiftRightEqualsOperator() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var boundValue = try 12.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundCount = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            boundValue >>= boundCount
            #expect(try Int(boundValue) == 3)
            
            var unboundValue: PythonInterpreter.SafePythonObject = -12
            let unboundCount: PythonInterpreter.SafePythonObject = 1
            unboundValue >>= unboundCount
            #expect(try Int(unboundValue) == -6)
        }
    }
}
