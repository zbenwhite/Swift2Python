//
//  BitwiseOpsTest+XOR.swift
//  Swift2Python
//
//  Created by Ben White on 5/8/26.
//

import Testing
import Logging
@testable import Swift2Python

extension BitwiseOpsTests {
    
    @Test("O^_001: Bitwise XOR Operator Integer")
    func bitwiseXorOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundIntA = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundIntB = try 11.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundIntA: PythonInterpreter.SafePythonObject = -6
            let unboundIntB: PythonInterpreter.SafePythonObject = 3
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int ^ bound int", boundIntA, boundIntB, 5),
                ("bound int ^ unbound int", boundIntA, unboundIntB, 13),
                ("unbound int ^ bound int", unboundIntA, boundIntB, -15),
                ("unbound int ^ unbound int", unboundIntA, unboundIntB, -7),
                ("bound int ^ bound bool", boundIntA, boundTrue, 15),
                ("bound int ^ unbound bool", boundIntA, unboundFalse, 14),
                ("unbound int ^ bound bool", unboundIntA, boundTrue, -5),
                ("unbound int ^ unbound bool", unboundIntA, unboundFalse, -6)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result = lhs ^ rhs
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O^_004: Bitwise XOR Operator Bool")
    func bitwiseXorOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundInt = try 7.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 6
            
            let boolCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound bool ^ bound bool", boundTrue, boundFalse, true),
                ("bound bool ^ unbound bool", boundTrue, unboundTrue, false),
                ("unbound bool ^ bound bool", unboundTrue, boundFalse, true),
                ("unbound bool ^ unbound bool", unboundTrue, unboundFalse, true)
            ]
            
            for (description, lhs, rhs, expected) in boolCases {
                let result = lhs ^ rhs
                #expect(try Bool(result) == expected, Comment(rawValue: description))
            }
            
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool ^ bound int", boundTrue, boundInt, 6),
                ("bound bool ^ unbound int", boundTrue, unboundInt, 7),
                ("unbound bool ^ bound int", unboundTrue, boundInt, 6),
                ("unbound bool ^ unbound int", unboundTrue, unboundInt, 7)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs ^ rhs
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O^_005: PythonObject async bitwise XOR")
    func bitwiseXorPythonObject() async throws {
        let a = try await 14.toPythonObject(interpreter: interpreter)
        let b = try await 11.toPythonObject(interpreter: interpreter)
        let result = try await a.bitwiseXor(b)
        #expect(try await Int(result) == 5)
        
        let convertedResult = try await a.bitwiseXor(3)
        #expect(try await Int(convertedResult) == 13)
        
        let boolA = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolA.bitwiseXor(false)
        #expect(try await Bool(boolResult) == true)
    }
    
    @Test("O^_006: PythonObject async bitwise XOR error checking")
    func bitwiseXorPythonObjectError() async throws {
        let intObject = try await 14.toPythonObject(interpreter: interpreter)
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await intObject.bitwiseXor(stringObject)
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject bitwise XOR error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O^_010: safePythonObject bitwise XOR error checking")
    func safeBitwiseXorErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double ^ unbound int", unboundDouble, unboundInt, "Double", "Int"),
                ("unbound int ^ unbound double", unboundInt, unboundDouble, "Int", "Double"),
                ("unbound string ^ unbound bool", unboundString, unboundBool, "String", "Bool"),
                ("unbound bool ^ unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.bitwiseXor(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "bitwise XOR", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double ^ unbound int", boundDouble, unboundInt),
                ("unbound int ^ bound double", unboundInt, boundDouble),
                ("bound string ^ unbound bool", boundString, unboundBool),
                ("unbound bool ^ bound string", unboundBool, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.bitwiseXor(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let convertibleError = #expect(throws: PythonError.self) {
                _ = try unboundInt.bitwiseXor(1)
            }
            
            if case .conversionType = convertibleError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.bitwiseXor(Int), but got \(String(describing: convertibleError))")
            }
        }
    }
    
    @Test("O^_011: safePythonObject bitwise XOR accepts SafePythonConvertible values")
    func safeBitwiseXorAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let intResult = try boundInt.bitwiseXor(3)
            #expect(try Int(intResult) == 13)
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boolResult = try boundTrue.bitwiseXor(false)
            #expect(try Bool(boolResult) == true)
        }
    }
    
    @Test("O^=_005: PythonObject async in-place bitwise XOR")
    func bitwiseXorEqualsPythonObject() async throws {
        let a = try await 14.toPythonObject(interpreter: interpreter)
        let result = try await a.bitwiseXorInPlace(11)
        #expect(try await Int(result) == 5)
        
        let boolA = try await false.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolA.bitwiseXorInPlace(true)
        #expect(try await Bool(boolResult) == true)
    }
    
    @Test("O^=_006: PythonObject async in-place bitwise XOR error checking")
    func bitwiseXorEqualsPythonObjectError() async throws {
        let intObject = try await 14.toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await intObject.bitwiseXorInPlace("abc")
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject in-place bitwise XOR error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O^=_010: safePythonObject bitwise XOR equals error checking")
    func safeBitwiseXorEqualsErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double ^= unbound int", unboundDouble, unboundInt, "Double", "Int"),
                ("unbound int ^= unbound double", unboundInt, unboundDouble, "Int", "Double"),
                ("unbound string ^= unbound bool", unboundString, unboundBool, "String", "Bool"),
                ("unbound bool ^= unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                var target = lhs
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    try target.bitwiseXorInPlace(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "in place bitwise XOR", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double ^= unbound int", boundDouble, unboundInt),
                ("unbound int ^= bound double", unboundInt, boundDouble),
                ("bound string ^= unbound bool", boundString, unboundBool),
                ("unbound bool ^= bound string", unboundBool, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                var target = lhs
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    try target.bitwiseXorInPlace(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
        }
    }
    
    @Test("O^=_011: safePythonObject in-place bitwise XOR accepts SafePythonConvertible values")
    func safeInPlaceBitwiseXorAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            try boundInt.bitwiseXorInPlace(3)
            #expect(try Int(boundInt) == 13)
            
            var boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            try boundFalse.bitwiseXorInPlace(true)
            #expect(try Bool(boundFalse) == true)
            
            var deferredInt: PythonInterpreter.SafePythonObject = 14
            let thrownError = #expect(throws: PythonError.self) {
                try deferredInt.bitwiseXorInPlace(3)
            }
            
            if case .conversionType = thrownError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.bitwiseXorInPlace(Int), but got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("O^=_012: Bitwise XOR equals operator")
    func bitwiseXorEqualsOperator() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundMask = try 11.toSafePythonObject(interpreter: isolatedInterpreter)
            boundInt ^= boundMask
            #expect(try Int(boundInt) == 5)
            
            var unboundInt: PythonInterpreter.SafePythonObject = -6
            let unboundMask: PythonInterpreter.SafePythonObject = 3
            unboundInt ^= unboundMask
            #expect(try Int(unboundInt) == -7)
            
            var boolValue: PythonInterpreter.SafePythonObject = false
            let trueValue: PythonInterpreter.SafePythonObject = true
            boolValue ^= trueValue
            #expect(try Bool(boolValue) == true)
        }
    }
    
    // MARK: O^_xxx Bitwise XOR Tests
}
