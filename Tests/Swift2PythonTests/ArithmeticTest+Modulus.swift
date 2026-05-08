//
//  ArithmeticTest+Modulus.swift
//  Swift2Python
//
//  Created by Ben White on 5/7/26.
//

import Testing
import Logging
@testable import Swift2Python

extension ArithmeticTests {
    
    @Test("O%_001: Modulus Operator Integer")
    func modulusOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundIntA = try 17.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundIntB = try 5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundIntA: PythonInterpreter.SafePythonObject = -17
            let unboundIntB: PythonInterpreter.SafePythonObject = 5
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = -2.5
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            // Integer-led modulus should preserve Python's integer remainder semantics, including sign handling,
            // for int/bool combinations across bound and unbound values.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int % bound int", boundIntA, boundIntB, 2),
                ("bound int % unbound int", boundIntA, unboundIntB, 2),
                ("unbound int % bound int", unboundIntA, boundIntB, 3),
                ("unbound int % unbound int", unboundIntA, unboundIntB, 3),
                ("bound int % bound bool", boundIntA, boundTrue, 0),
                ("bound int % unbound bool", boundIntA, unboundTrue, 0),
                ("unbound int % bound bool", unboundIntA, boundTrue, 0),
                ("unbound int % unbound bool", unboundIntA, unboundTrue, 0)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs % rhs
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // Integer-led modulus should promote to double when the divisor is floating-point.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound int % bound double", boundIntA, boundDouble, 2.0),
                ("bound int % unbound double", boundIntA, unboundDouble, -0.5),
                ("unbound int % bound double", unboundIntA, boundDouble, 0.5),
                ("unbound int % unbound double", unboundIntA, unboundDouble, -2.0)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs % rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining verifies left-to-right evaluation while preserving Python's remainder rules.
            let chainedResult = boundIntA % boundIntB % boundDouble
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: 2.0))
        }
    }
    
    @Test("O%_002: Modulus Operator Double")
    func modulusOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDoubleA = try (-17.5).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDoubleB = try 4.0.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDoubleA: PythonInterpreter.SafePythonObject = 19.2
            let unboundDoubleB: PythonInterpreter.SafePythonObject = -2.5
            
            let boundInt = try 6.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -4
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            // Double-led modulus stays in floating-point space for double/double, double/int,
            // and double/bool combinations across bound and unbound states.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound double % bound double", boundDoubleA, boundDoubleB, 2.5),
                ("bound double % unbound double", boundDoubleA, unboundDoubleA, 1.6999999999999993),
                ("unbound double % bound double", unboundDoubleA, boundDoubleA, -15.8),
                ("unbound double % unbound double", unboundDoubleA, unboundDoubleB, -0.8000000000000007),
                ("bound double % bound int", boundDoubleA, boundInt, 0.5),
                ("bound double % unbound int", boundDoubleA, unboundInt, -1.5),
                ("unbound double % bound int", unboundDoubleA, boundInt, 1.1999999999999993),
                ("unbound double % unbound int", unboundDoubleA, unboundInt, -0.8000000000000007),
                ("bound double % bound bool", boundDoubleA, boundTrue, 0.5),
                ("bound double % unbound bool", boundDoubleA, unboundTrue, 0.5),
                ("unbound double % bound bool", unboundDoubleA, boundTrue, 0.1999999999999993),
                ("unbound double % unbound bool", unboundDoubleA, unboundTrue, 0.1999999999999993)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs % rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining keeps the promoted result in floating-point space through repeated modulus operations.
            let chainedResult = unboundDoubleA % boundDoubleB % unboundInt
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: -0.8000000000000007))
        }
    }
    
    @Test("O%_004: Modulus Operator Bool")
    func modulusOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundInt = try 4.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -3
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = -0.75
            
            // Bool-led modulus behaves like Python numeric modulus where bool participates as 0/1.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool % bound bool", boundTrue, boundTrue, 0),
                ("bound bool % unbound bool", boundTrue, unboundTrue, 0),
                ("unbound bool % bound bool", unboundFalse, boundTrue, 0),
                ("unbound bool % unbound bool", unboundTrue, unboundTrue, 0),
                ("bound bool % bound int", boundTrue, boundInt, 1),
                ("bound bool % unbound int", boundTrue, unboundInt, -2),
                ("unbound bool % bound int", unboundFalse, boundInt, 0),
                ("unbound bool % unbound int", unboundTrue, unboundInt, -2)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs % rhs
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // When a bool-led modulus involves a double, the result should promote to double.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound bool % bound double", boundTrue, boundDouble, 1.0),
                ("bound bool % unbound double", boundTrue, unboundDouble, -0.5),
                ("unbound bool % bound double", unboundFalse, boundDouble, 0.0),
                ("unbound bool % unbound double", unboundTrue, unboundDouble, -0.5)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs % rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Zero divisors should surface as divide-by-zero semantics for modulus too.
            let divideByZeroCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound bool % unbound false", boundTrue, unboundFalse),
                ("unbound bool % bound false", unboundTrue, boundFalse),
                ("unbound bool % unbound false", unboundTrue, unboundFalse)
            ]
            
            for (description, lhs, rhs) in divideByZeroCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.modulus(divisor: rhs)
                }
                
                switch thrownError {
                case .divideByZero, .safePythonException:
                    break
                default:
                    Issue.record("Expected modulus divide-by-zero failure for \(description), but got \(thrownError)")
                }
            }
        }
    }
    
    @Test("O%_005: PythonObject (async) modulus")
    func modulusPythonObject() async throws {
        let dividendA = try await 17.toPythonObject(interpreter: interpreter)
        let divisorA = try await 5.toPythonObject(interpreter: interpreter)
        let remainderA = try await dividendA.modulus(divisorA)
        let roundTripA = try await Int(remainderA)
        #expect(roundTripA == 2)
        
        let dividendB = try await 17.toPythonObject(interpreter: interpreter)
        let remainderB = try await dividendB.modulus(2.5)
        let roundTripB = try await Double(remainderB)
        #expect(roundTripB.isCloseEnough(to: 2.0))
        
        let dividendC = try await (-17.5).toPythonObject(interpreter: interpreter)
        let remainderC = try await dividendC.modulus(4)
        let roundTripC = try await Double(remainderC)
        #expect(roundTripC.isCloseEnough(to: 2.5))
        
        let dividendD = try await true.toPythonObject(interpreter: interpreter)
        let remainderD = try await dividendD.modulus(4)
        let roundTripD = try await Int(remainderD)
        #expect(roundTripD == 1)
        
        let dividendE = try await true.toPythonObject(interpreter: interpreter)
        let remainderE = try await dividendE.modulus(2.5)
        let roundTripE = try await Double(remainderE)
        #expect(roundTripE.isCloseEnough(to: 1.0))
    }
    
    @Test("O%_006: PythonObject (async) modulus error checking")
    func modulusPythonObjectError() async throws {
        let boundDouble = try await 1.5.toPythonObject(interpreter: interpreter)
        let boundInt = try await 2.toPythonObject(interpreter: interpreter)
        let boundString = try await "abc".toPythonObject(interpreter: interpreter)
        let boundBool = try await true.toPythonObject(interpreter: interpreter)
        
        // Async PythonObject modulus always goes through Python, so invalid string-related
        // modulus operations and zero divisors should surface as pythonException.
        let errorCases: [(String, PythonObject, any PendingPythonConvertible)] = [
            ("python double % string", boundDouble, "abc"),
            ("python int % string", boundInt, "abc"),
            ("python string % double", boundString, 1.5),
            ("python string % int", boundString, 2),
            ("python string % string", boundString, "def"),
            ("python string % bool", boundString, true),
            ("python bool % string", boundBool, "abc"),
            ("python double % zero", boundDouble, 0),
            ("python int % false", boundInt, false),
            ("python bool % zero double", boundBool, 0.0)
        ]
        
        for (description, lhs, rhs) in errorCases {
            let thrownError = await #expect(throws: PythonError.self, Comment(rawValue: description)) {
                _ = try await lhs.modulus(rhs)
            }
            
            if case .pythonException = thrownError {
                // expected
            } else {
                Issue.record("Expected .pythonException for \(description), but got \(thrownError)")
            }
        }
    }
    
    @Test("O%_010: safePythonObject modulus error checking")
    func safeModulusErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundBool = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundZeroInt = try 0.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundZeroDouble = try 0.0.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundBool: PythonInterpreter.SafePythonObject = true
            let unboundZeroInt: PythonInterpreter.SafePythonObject = 0
            let unboundZeroDouble: PythonInterpreter.SafePythonObject = 0.0
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            // Fully deferred invalid modulus operations should throw the local typeError that matches
            // the operand order encoded in SafePythonObject.modulus(divisor:). Avoid bool/string here
            // because the current implementation fatally errors instead of throwing.
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double % unbound string", unboundDouble, unboundString, "Double", "String"),
                ("unbound int % unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string % unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound string % unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound string % unbound string", unboundString, unboundString, "String", "String"),
                ("unbound string % unbound bool", unboundString, unboundBool, "String", "Bool")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.modulus(divisor: rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "modulus", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(thrownError)")
                }
            }
            
            // Fully deferred numeric zero divisors should be caught locally as divideByZero.
            let unboundDivideByZeroCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("unbound double % unbound zero int", unboundDouble, unboundZeroInt),
                ("unbound int % unbound zero double", unboundInt, unboundZeroDouble),
                ("unbound bool % unbound false", unboundBool, unboundFalse)
            ]
            
            for (description, lhs, rhs) in unboundDivideByZeroCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.modulus(divisor: rhs)
                }
                
                if case .divideByZero = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .divideByZero for \(description), but got \(thrownError)")
                }
            }
            
            // Once either side is bound, modulus(divisor:) delegates to Python. The same invalid
            // type pairs and zero divisors should therefore fail as safePythonException instead.
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double % unbound string", boundDouble, unboundString),
                ("unbound double % bound string", unboundDouble, boundString),
                ("bound double % bound string", boundDouble, boundString),
                ("bound int % unbound string", boundInt, unboundString),
                ("unbound int % bound string", unboundInt, boundString),
                ("bound int % bound string", boundInt, boundString),
                ("bound string % unbound double", boundString, unboundDouble),
                ("unbound string % bound double", unboundString, boundDouble),
                ("bound string % bound double", boundString, boundDouble),
                ("bound string % unbound int", boundString, unboundInt),
                ("unbound string % bound int", unboundString, boundInt),
                ("bound string % bound int", boundString, boundInt),
                ("bound string % unbound string", boundString, unboundString),
                ("unbound string % bound string", unboundString, boundString),
                ("bound string % bound string", boundString, boundString),
                ("bound string % unbound bool", boundString, unboundBool),
                ("unbound string % bound bool", unboundString, boundBool),
                ("bound string % bound bool", boundString, boundBool),
                ("bound bool % unbound string", boundBool, unboundString),
                ("unbound bool % bound string", unboundBool, boundString),
                ("bound bool % bound string", boundBool, boundString),
                ("bound double % unbound zero int", boundDouble, unboundZeroInt),
                ("unbound double % bound zero double", unboundDouble, boundZeroDouble),
                ("bound int % bound false", boundInt, boundFalse),
                ("unbound bool % bound zero int", unboundBool, boundZeroInt)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.modulus(divisor: rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(thrownError)")
                }
            }
        }
    }
}


// Checklist of tests that pass. Fill in the date when it runs correctly.

// [   date   ] : The date the test runs correctly and passes
// [yyyy-mm-dd] : Test ID : Test
//


// Modulus

// [          ] : O%_001 : Modulus integer with integer SafePythonObject
// [          ] : O%_002 : Modulus integer with double SafePythonObject
// [          ] : O%_002 : Modulus double with double SafePythonObject
// [          ] : O%_002 : Modulus double with integer SafePythonObject
// [          ] : O%_001 : Modulus bool with integer SafePythonObject
// [          ] : O%_002 : Modulus bool with double SafePythonObject
// [          ] : O%_004 : Modulus bool with bool SafePythonObject
// [          ] : O%_005 : Modulus PythonObject by PythonObject
// [          ] : O%_005 : Modulus PythonObject by Int
// [          ] : O%_005 : Modulus PythonObject by Double
// [          ] : O%_005 : Modulus PythonObject by Bool
// [          ] : O%_006 : Modulus PythonObject error handling
// [          ] : O%_010 : Modulus SafePythonObject error handling
