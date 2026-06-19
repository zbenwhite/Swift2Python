//
//  BitwiseOpsTest+ShiftLeft.swift
//  Swift2Python
//
//  Created by Ben White on 6/18/26.
//

import Testing
import Logging
@testable import Swift2Python

extension BitwiseOpsTests {
    
    @Test("O<<_001: Bit shift left operator integer")
    func bitShiftLeftOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundValue = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundCount = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundValue: PythonInterpreter.SafePythonObject = -3
            let unboundCount: PythonInterpreter.SafePythonObject = 1
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int << bound int", boundValue, boundCount, 12),
                ("bound int << unbound int", boundValue, unboundCount, 6),
                ("unbound int << bound int", unboundValue, boundCount, -12),
                ("unbound int << unbound int", unboundValue, unboundCount, -6),
                ("bound int << bound bool", boundValue, boundTrue, 6),
                ("bound int << unbound bool", boundValue, unboundFalse, 3),
                ("unbound int << bound bool", unboundValue, boundTrue, -6),
                ("unbound int << unbound bool", unboundValue, unboundFalse, -3)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result = lhs << rhs
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O<<_004: Bit shift left operator bool")
    func bitShiftLeftOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            let boundCount = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundCount: PythonInterpreter.SafePythonObject = 2
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool << bound bool", boundTrue, boundTrue, 2),
                ("bound bool << unbound bool", boundTrue, unboundFalse, 1),
                ("unbound bool << bound bool", unboundTrue, boundFalse, 1),
                ("unbound bool << unbound bool", unboundTrue, unboundTrue, 2),
                ("bound bool << bound int", boundTrue, boundCount, 8),
                ("unbound bool << unbound int", unboundTrue, unboundCount, 4),
                ("false << int", unboundFalse, boundCount, 0)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result = lhs << rhs
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O<<_005: PythonObject async bit shift left")
    func bitShiftLeftPythonObject() async throws {
        let value = try await 3.toPythonObject(interpreter: interpreter)
        let count = try await 2.toPythonObject(interpreter: interpreter)
        let result = try await value.bitShiftLeft(count)
        #expect(try await Int(result) == 12)
        
        let convertedResult = try await value.bitShiftLeft(1)
        #expect(try await Int(convertedResult) == 6)
        
        let boolValue = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolValue.bitShiftLeft(true)
        #expect(try await Int(boolResult) == 2)
    }
    
    @Test("O<<_006: PythonObject async bit shift left error checking")
    func bitShiftLeftPythonObjectError() async throws {
        let value = try await 3.toPythonObject(interpreter: interpreter)
        
        let stringError = await #expect(throws: PythonError.self) {
            _ = try await value.bitShiftLeft("abc")
        }
        
        if case .pythonException = stringError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject left shift type error, but got \(String(describing: stringError))")
        }
        
        let negativeError = await #expect(throws: PythonError.self) {
            _ = try await value.bitShiftLeft(-1)
        }
        
        if case .pythonException = negativeError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject negative left shift, but got \(String(describing: negativeError))")
        }
    }
    
    @Test("O<<_010: safePythonObject bit shift left error checking")
    func safeBitShiftLeftErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundValue = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 3
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let negativeCount: PythonInterpreter.SafePythonObject = -1
            let hugeCount: PythonInterpreter.SafePythonObject = 1
            let hugeValue = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
            
            let typeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound string << unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound int << unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound double << unbound int", unboundDouble, unboundInt, "Double", "Int")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in typeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.bitShiftLeft(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "left shift", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let deferredNegativeError = #expect(throws: PythonError.self) {
                _ = try unboundInt.bitShiftLeft(negativeCount)
            }
            
            if case .valueError(let message) = deferredNegativeError {
                #expect(message == "negative shift count")
            } else {
                Issue.record("Expected .valueError for deferred negative left shift, but got \(String(describing: deferredNegativeError))")
            }
            
            let overflowError = #expect(throws: PythonError.self) {
                _ = try hugeValue.bitShiftLeft(hugeCount)
            }
            
            if case .conversionOverflow = overflowError {
                // expected
            } else {
                Issue.record("Expected .conversionOverflow for deferred overflowing left shift, but got \(String(describing: overflowError))")
            }
            
            let boundTypeError = #expect(throws: PythonError.self) {
                _ = try boundValue.bitShiftLeft(boundString)
            }
            
            if case .safePythonException = boundTypeError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for bound left shift type error, but got \(String(describing: boundTypeError))")
            }
            
            let convertibleError = #expect(throws: PythonError.self) {
                _ = try unboundInt.bitShiftLeft(1)
            }
            
            if case .conversionType = convertibleError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.bitShiftLeft(Int), but got \(String(describing: convertibleError))")
            }
        }
    }
    
    @Test("O<<_011: safePythonObject bit shift left accepts SafePythonConvertible values")
    func safeBitShiftLeftAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundValue = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let intResult = try boundValue.bitShiftLeft(2)
            #expect(try Int(intResult) == 12)
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boolResult = try boundTrue.bitShiftLeft(true)
            #expect(try Int(boolResult) == 2)
        }
    }
    
    @Test("O<<=_005: PythonObject async in-place bit shift left")
    func bitShiftLeftEqualsPythonObject() async throws {
        let value = try await 3.toPythonObject(interpreter: interpreter)
        let result = try await value.bitShiftLeftInPlace(2)
        #expect(try await Int(result) == 12)
        
        let boolValue = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolValue.bitShiftLeftInPlace(true)
        #expect(try await Int(boolResult) == 2)
    }
    
    @Test("O<<=_006: PythonObject async in-place bit shift left error checking")
    func bitShiftLeftEqualsPythonObjectError() async throws {
        let value = try await 3.toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await value.bitShiftLeftInPlace("abc")
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject in-place left shift error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O<<=_010: safePythonObject bit shift left equals error checking")
    func safeBitShiftLeftEqualsErrors() async throws {
        try await interpreter.withIsolatedContext { _ in
            let unboundInt: PythonInterpreter.SafePythonObject = 3
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let negativeCount: PythonInterpreter.SafePythonObject = -1
            
            var typeTarget = unboundInt
            let typeError = #expect(throws: PythonError.self) {
                try typeTarget.bitShiftLeftInPlace(unboundString)
            }
            
            if case let .typeError(operation, opType1, opType2) = typeError {
                #expect(operation == "in place left shift")
                #expect(opType1 == "Int")
                #expect(opType2 == "String")
            } else {
                Issue.record("Expected .typeError for deferred in-place left shift, but got \(String(describing: typeError))")
            }
            
            var negativeTarget = unboundInt
            let negativeError = #expect(throws: PythonError.self) {
                try negativeTarget.bitShiftLeftInPlace(negativeCount)
            }
            
            if case .valueError(let message) = negativeError {
                #expect(message == "negative shift count")
            } else {
                Issue.record("Expected .valueError for deferred in-place negative left shift, but got \(String(describing: negativeError))")
            }
        }
    }
    
    @Test("O<<=_011: safePythonObject in-place bit shift left accepts SafePythonConvertible values")
    func safeInPlaceBitShiftLeftAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var boundValue = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            try boundValue.bitShiftLeftInPlace(2)
            #expect(try Int(boundValue) == 12)
            
            var deferredValue: PythonInterpreter.SafePythonObject = 3
            let thrownError = #expect(throws: PythonError.self) {
                try deferredValue.bitShiftLeftInPlace(2)
            }
            
            if case .conversionType = thrownError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.bitShiftLeftInPlace(Int), but got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("O<<=_012: Bit shift left equals operator")
    func bitShiftLeftEqualsOperator() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var boundValue = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundCount = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            boundValue <<= boundCount
            #expect(try Int(boundValue) == 12)
            
            var unboundValue: PythonInterpreter.SafePythonObject = -3
            let unboundCount: PythonInterpreter.SafePythonObject = 1
            unboundValue <<= unboundCount
            #expect(try Int(unboundValue) == -6)
        }
    }
}
