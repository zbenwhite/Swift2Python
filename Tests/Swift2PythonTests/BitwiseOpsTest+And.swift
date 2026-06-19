//
//  BitwiseOpsTest+AND.swift
//  Swift2Python
//
//  Created by Ben White on 5/8/26.
//

import Testing
import Logging
@testable import Swift2Python

extension BitwiseOpsTests {
    
    @Test("O&_001: Bitwise AND Operator Integer")
    func bitwiseAndOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundIntA = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundIntB = try 11.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundIntA: PythonInterpreter.SafePythonObject = -6
            let unboundIntB: PythonInterpreter.SafePythonObject = 3
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int & bound int", boundIntA, boundIntB, 10),
                ("bound int & unbound int", boundIntA, unboundIntB, 2),
                ("unbound int & bound int", unboundIntA, boundIntB, 10),
                ("unbound int & unbound int", unboundIntA, unboundIntB, 2),
                ("bound int & bound bool", boundIntA, boundTrue, 0),
                ("bound int & unbound bool", boundIntA, unboundFalse, 0),
                ("unbound int & bound bool", unboundIntA, boundTrue, 0),
                ("unbound int & unbound bool", unboundIntA, unboundFalse, 0)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result = lhs & rhs
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O&_004: Bitwise AND Operator Bool")
    func bitwiseAndOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundInt = try 7.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 6
            
            let boolCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound bool & bound bool", boundTrue, boundFalse, false),
                ("bound bool & unbound bool", boundTrue, unboundTrue, true),
                ("unbound bool & bound bool", unboundTrue, boundFalse, false),
                ("unbound bool & unbound bool", unboundTrue, unboundFalse, false)
            ]
            
            for (description, lhs, rhs, expected) in boolCases {
                let result = lhs & rhs
                #expect(try Bool(result) == expected, Comment(rawValue: description))
            }
            
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool & bound int", boundTrue, boundInt, 1),
                ("bound bool & unbound int", boundTrue, unboundInt, 0),
                ("unbound bool & bound int", unboundTrue, boundInt, 1),
                ("unbound bool & unbound int", unboundTrue, unboundInt, 0)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs & rhs
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O&_005: PythonObject async bitwise AND")
    func bitwiseAndPythonObject() async throws {
        let a = try await 14.toPythonObject(interpreter: interpreter)
        let b = try await 11.toPythonObject(interpreter: interpreter)
        let result = try await a.bitwiseAnd(b)
        #expect(try await Int(result) == 10)
        
        let convertedResult = try await a.bitwiseAnd(3)
        #expect(try await Int(convertedResult) == 2)
        
        let boolA = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolA.bitwiseAnd(false)
        #expect(try await Bool(boolResult) == false)
    }
    
    @Test("O&_006: PythonObject async bitwise AND error checking")
    func bitwiseAndPythonObjectError() async throws {
        let intObject = try await 14.toPythonObject(interpreter: interpreter)
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await intObject.bitwiseAnd(stringObject)
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject bitwise AND error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O&_010: safePythonObject bitwise AND error checking")
    func safeBitwiseAndErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double & unbound int", unboundDouble, unboundInt, "Double", "Int"),
                ("unbound int & unbound double", unboundInt, unboundDouble, "Int", "Double"),
                ("unbound string & unbound bool", unboundString, unboundBool, "String", "Bool"),
                ("unbound bool & unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.bitwiseAnd(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "bitwise AND", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double & unbound int", boundDouble, unboundInt),
                ("unbound int & bound double", unboundInt, boundDouble),
                ("bound string & unbound bool", boundString, unboundBool),
                ("unbound bool & bound string", unboundBool, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.bitwiseAnd(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let convertibleError = #expect(throws: PythonError.self) {
                _ = try unboundInt.bitwiseAnd(1)
            }
            
            if case .conversionType = convertibleError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.bitwiseAnd(Int), but got \(String(describing: convertibleError))")
            }
        }
    }
    
    @Test("O&_011: safePythonObject bitwise AND accepts SafePythonConvertible values")
    func safeBitwiseAndAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let intResult = try boundInt.bitwiseAnd(3)
            #expect(try Int(intResult) == 2)
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boolResult = try boundTrue.bitwiseAnd(false)
            #expect(try Bool(boolResult) == false)
        }
    }
    
    @Test("O&=_005: PythonObject async in-place bitwise AND")
    func bitwiseAndEqualsPythonObject() async throws {
        let a = try await 14.toPythonObject(interpreter: interpreter)
        let result = try await a.bitwiseAndInPlace(11)
        #expect(try await Int(result) == 10)
        
        let boolA = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolA.bitwiseAndInPlace(false)
        #expect(try await Bool(boolResult) == false)
    }
    
    @Test("O&=_006: PythonObject async in-place bitwise AND error checking")
    func bitwiseAndEqualsPythonObjectError() async throws {
        let intObject = try await 14.toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await intObject.bitwiseAndInPlace("abc")
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject in-place bitwise AND error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O&=_010: safePythonObject bitwise AND equals error checking")
    func safeBitwiseAndEqualsErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double &= unbound int", unboundDouble, unboundInt, "Double", "Int"),
                ("unbound int &= unbound double", unboundInt, unboundDouble, "Int", "Double"),
                ("unbound string &= unbound bool", unboundString, unboundBool, "String", "Bool"),
                ("unbound bool &= unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                var target = lhs
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    try target.bitwiseAndInPlace(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "in place bitwise AND", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double &= unbound int", boundDouble, unboundInt),
                ("unbound int &= bound double", unboundInt, boundDouble),
                ("bound string &= unbound bool", boundString, unboundBool),
                ("unbound bool &= bound string", unboundBool, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                var target = lhs
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    try target.bitwiseAndInPlace(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
        }
    }
    
    @Test("O&=_011: safePythonObject in-place bitwise AND accepts SafePythonConvertible values")
    func safeInPlaceBitwiseAndAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            try boundInt.bitwiseAndInPlace(3)
            #expect(try Int(boundInt) == 2)
            
            var boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            try boundTrue.bitwiseAndInPlace(false)
            #expect(try Bool(boundTrue) == false)
            
            var deferredInt: PythonInterpreter.SafePythonObject = 14
            let thrownError = #expect(throws: PythonError.self) {
                try deferredInt.bitwiseAndInPlace(3)
            }
            
            if case .conversionType = thrownError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.bitwiseAndInPlace(Int), but got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("O&=_012: Bitwise AND equals operator")
    func bitwiseAndEqualsOperator() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundMask = try 11.toSafePythonObject(interpreter: isolatedInterpreter)
            boundInt &= boundMask
            #expect(try Int(boundInt) == 10)
            
            var unboundInt: PythonInterpreter.SafePythonObject = -6
            let unboundMask: PythonInterpreter.SafePythonObject = 3
            unboundInt &= unboundMask
            #expect(try Int(unboundInt) == 2)
            
            var boolValue: PythonInterpreter.SafePythonObject = true
            let falseValue: PythonInterpreter.SafePythonObject = false
            boolValue &= falseValue
            #expect(try Bool(boolValue) == false)
        }
    }
    
}
