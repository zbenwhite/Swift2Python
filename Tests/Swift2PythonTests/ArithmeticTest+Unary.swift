//
//  ArithmeticTest+Unary.swift
//  Swift2Python
//
//  Created by Ben White on 5/7/26.
//

import Testing
import Logging
@testable import Swift2Python

extension ArithmeticTests {
    // MARK: Unary Operators
    
    @Test("O+u_001: Unary Plus Operator")
    func unaryPlusOperator() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDouble = try (-2.5).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -8
            let unboundDouble: PythonInterpreter.SafePythonObject = 3.25
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let intCases: [(String, PythonInterpreter.SafePythonObject, Int)] = [
                ("+bound int", boundInt, 14),
                ("+unbound int", unboundInt, -8),
                ("+bound true", boundTrue, 1),
                ("+unbound false", unboundFalse, 0)
            ]
            
            for (description, operand, expected) in intCases {
                let result = +operand
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
            
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, Double)] = [
                ("+bound double", boundDouble, -2.5),
                ("+unbound double", unboundDouble, 3.25)
            ]
            
            for (description, operand, expected) in doubleCases {
                let result = +operand
                #expect(try Double(result).isCloseEnough(to: expected), Comment(rawValue: description))
            }
        }
    }
    
    @Test("O+u_005: PythonObject async unary plus")
    func unaryPlusPythonObject() async throws {
        let intObject = try await (-14).toPythonObject(interpreter: interpreter)
        let intResult = try await intObject.positive()
        #expect(try await Int(intResult) == -14)
        
        let doubleObject = try await 2.5.toPythonObject(interpreter: interpreter)
        let doubleResult = try await doubleObject.positive()
        #expect(try await Double(doubleResult).isCloseEnough(to: 2.5))
        
        let boolObject = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolObject.positive()
        #expect(try await Int(boolResult) == 1)
    }
    
    @Test("O+u_006: PythonObject async unary plus error checking")
    func unaryPlusPythonObjectError() async throws {
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await stringObject.positive()
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject unary plus error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O+u_010: SafePythonObject unary plus error checking")
    func safeUnaryPlusErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            
            let unboundError = #expect(throws: PythonError.self) {
                _ = try unboundString.positive()
            }
            
            if case let .typeError(operation, opType1, opType2) = unboundError {
                #expect(operation == "unary plus")
                #expect(opType1 == "String")
                #expect(opType2 == "None")
            } else {
                Issue.record("Expected .typeError for unbound string unary plus, but got \(String(describing: unboundError))")
            }
            
            let boundError = #expect(throws: PythonError.self) {
                _ = try boundString.positive()
            }
            
            if case .safePythonException = boundError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for bound string unary plus, but got \(String(describing: boundError))")
            }
        }
    }
    
    @Test("O-u_001: Unary Minus Operator")
    func unaryMinusOperator() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundInt = try 14.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDouble = try (-2.5).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -8
            let unboundDouble: PythonInterpreter.SafePythonObject = 3.25
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let intCases: [(String, PythonInterpreter.SafePythonObject, Int)] = [
                ("-bound int", boundInt, -14),
                ("-unbound int", unboundInt, 8),
                ("-bound true", boundTrue, -1),
                ("-unbound false", unboundFalse, 0)
            ]
            
            for (description, operand, expected) in intCases {
                let result = -operand
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
            
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, Double)] = [
                ("-bound double", boundDouble, 2.5),
                ("-unbound double", unboundDouble, -3.25)
            ]
            
            for (description, operand, expected) in doubleCases {
                let result = -operand
                #expect(try Double(result).isCloseEnough(to: expected), Comment(rawValue: description))
            }
        }
    }
    
    @Test("O-u_005: PythonObject async unary minus")
    func unaryMinusPythonObject() async throws {
        let intObject = try await 14.toPythonObject(interpreter: interpreter)
        let intResult = try await intObject.negative()
        #expect(try await Int(intResult) == -14)
        
        let doubleObject = try await (-2.5).toPythonObject(interpreter: interpreter)
        let doubleResult = try await doubleObject.negative()
        #expect(try await Double(doubleResult).isCloseEnough(to: 2.5))
        
        let boolObject = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolObject.negative()
        #expect(try await Int(boolResult) == -1)
    }
    
    @Test("O-u_006: PythonObject async unary minus error checking")
    func unaryMinusPythonObjectError() async throws {
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await stringObject.negative()
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject unary minus error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O-u_010: SafePythonObject unary minus error checking")
    func safeUnaryMinusErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            
            let unboundError = #expect(throws: PythonError.self) {
                _ = try unboundString.negative()
            }
            
            if case let .typeError(operation, opType1, opType2) = unboundError {
                #expect(operation == "unary minus")
                #expect(opType1 == "String")
                #expect(opType2 == "None")
            } else {
                Issue.record("Expected .typeError for unbound string unary minus, but got \(String(describing: unboundError))")
            }
            
            let boundError = #expect(throws: PythonError.self) {
                _ = try boundString.negative()
            }
            
            if case .safePythonException = boundError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for bound string unary minus, but got \(String(describing: boundError))")
            }
        }
    }
    
    @Test("O-u_012: SafePythonObject deferred integer unary minus overflow")
    func safeUnaryMinusOverflow() throws {
        let minInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.min)
        
        let thrownError = #expect(throws: PythonError.self) {
            _ = try minInt.negative()
        }
        
        if case .conversionOverflow = thrownError {
            // expected
        } else {
            Issue.record("Expected .conversionOverflow for deferred -Int.min, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("Oabs_001: Absolute Value Function")
    func absoluteValueFunction() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundInt = try (-14).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDouble = try (-2.5).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -8
            let unboundDouble: PythonInterpreter.SafePythonObject = 3.25
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let intCases: [(String, PythonInterpreter.SafePythonObject, Int)] = [
                ("abs(bound int)", boundInt, 14),
                ("abs(unbound int)", unboundInt, 8),
                ("abs(bound true)", boundTrue, 1),
                ("abs(unbound false)", unboundFalse, 0)
            ]
            
            for (description, operand, expected) in intCases {
                let result = abs(operand)
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
            
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, Double)] = [
                ("abs(bound double)", boundDouble, 2.5),
                ("abs(unbound double)", unboundDouble, 3.25)
            ]
            
            for (description, operand, expected) in doubleCases {
                let result = abs(operand)
                #expect(try Double(result).isCloseEnough(to: expected), Comment(rawValue: description))
            }
        }
    }
    
    @Test("Oabs_005: PythonObject async absolute value")
    func absoluteValuePythonObject() async throws {
        let intObject = try await (-14).toPythonObject(interpreter: interpreter)
        let intResult = try await intObject.absolute()
        #expect(try await Int(intResult) == 14)
        
        let doubleObject = try await (-2.5).toPythonObject(interpreter: interpreter)
        let doubleResult = try await doubleObject.absolute()
        #expect(try await Double(doubleResult).isCloseEnough(to: 2.5))
        
        let boolObject = try await true.toPythonObject(interpreter: interpreter)
        let boolResult = try await boolObject.absolute()
        #expect(try await Int(boolResult) == 1)
    }
    
    @Test("Oabs_006: PythonObject async absolute value error checking")
    func absoluteValuePythonObjectError() async throws {
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await stringObject.absolute()
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject absolute value error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("Oabs_010: SafePythonObject absolute value error checking")
    func safeAbsoluteValueErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            
            let unboundError = #expect(throws: PythonError.self) {
                _ = try unboundString.absolute()
            }
            
            if case let .typeError(operation, opType1, opType2) = unboundError {
                #expect(operation == "absolute value")
                #expect(opType1 == "String")
                #expect(opType2 == "None")
            } else {
                Issue.record("Expected .typeError for unbound string absolute value, but got \(String(describing: unboundError))")
            }
            
            let boundError = #expect(throws: PythonError.self) {
                _ = try boundString.absolute()
            }
            
            if case .safePythonException = boundError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for bound string absolute value, but got \(String(describing: boundError))")
            }
        }
    }
    
    @Test("Oabs_012: SafePythonObject deferred integer absolute value overflow")
    func safeAbsoluteValueOverflow() throws {
        let minInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.min)
        
        let thrownError = #expect(throws: PythonError.self) {
            _ = try minInt.absolute()
        }
        
        if case .conversionOverflow = thrownError {
            // expected
        } else {
            Issue.record("Expected .conversionOverflow for deferred abs(Int.min), but got \(String(describing: thrownError))")
        }
    }
}
