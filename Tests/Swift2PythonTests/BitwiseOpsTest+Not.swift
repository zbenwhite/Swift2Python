//
//  BitwiseOpsTest+NOT.swift
//  Swift2Python
//
//  Created by Ben White on 5/8/26.
//

import Testing
import Logging
@testable import Swift2Python

extension BitwiseOpsTests {
    
    @Test("O~_001: Bitwise NOT Operator Integer")
    func bitwiseNotOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundPositive = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundNegative = try (-6).toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundPositive: PythonInterpreter.SafePythonObject = 14
            let unboundNegative: PythonInterpreter.SafePythonObject = -6
            
            let cases: [(String, PythonInterpreter.SafePythonObject, Int)] = [
                ("~bound positive int", boundPositive, -15),
                ("~bound negative int", boundNegative, 5),
                ("~unbound positive int", unboundPositive, -15),
                ("~unbound negative int", unboundNegative, 5)
            ]
            
            for (description, operand, expected) in cases {
                let result = ~operand
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O~_004: Bitwise NOT Operator Bool")
    func bitwiseNotOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let cases: [(String, PythonInterpreter.SafePythonObject, Int)] = [
                ("~bound true", boundTrue, -2),
                ("~bound false", boundFalse, -1),
                ("~unbound true", unboundTrue, -2),
                ("~unbound false", unboundFalse, -1)
            ]
            
            for (description, operand, expected) in cases {
                let result = ~operand
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O~_005: PythonObject async bitwise NOT")
    func bitwiseNotPythonObject() async throws {
        let intObject = try await 14.toPythonObject(interpreter: interpreter)
        let intResult = try await intObject.bitwiseInvert()
        #expect(try await Int(intResult) == -15)
        
        let boolObject = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolObject.bitwiseInvert()
        #expect(try await Int(boolResult) == -2)
    }
    
    @Test("O~_006: PythonObject async bitwise NOT error checking")
    func bitwiseNotPythonObjectError() async throws {
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await stringObject.bitwiseInvert()
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject bitwise NOT error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O~_010: safePythonObject bitwise NOT error checking")
    func safeBitwiseNotErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, String)] = [
                ("~unbound double", unboundDouble, "Double"),
                ("~unbound string", unboundString, "String")
            ]
            
            for (description, operand, expectedType) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try operand.bitwiseInvert()
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "bitwise NOT", Comment(rawValue: description))
                    #expect(opType1 == expectedType, Comment(rawValue: description))
                    #expect(opType2 == "None", Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject)] = [
                ("~bound double", boundDouble),
                ("~bound string", boundString)
            ]
            
            for (description, operand) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try operand.bitwiseInvert()
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
        }
    }
    
    @Test("O~_011: safePythonObject bitwise NOT throwing API")
    func safeBitwiseNotThrowingAPI() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundResult = try boundInt.bitwiseInvert()
            #expect(try Int(boundResult) == -15)
            
            let unboundBool: PythonInterpreter.SafePythonObject = true
            let unboundResult = try unboundBool.bitwiseInvert()
            #expect(try Int(unboundResult) == -2)
        }
    }
    
    // MARK: O~_xxx Bitwise NOT Tests
}
