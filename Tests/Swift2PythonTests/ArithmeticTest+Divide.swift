//
//  ArithmeticTest+Divide.swift
//  Swift2Python
//
//  Created by Ben White on 5/7/26.
//

import Testing
import Logging
@testable import Swift2Python

extension ArithmeticTests {
    
    @Test("O/_001: Division Operator Integer")
    func divisionOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundIntA = try 84.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundIntB = try (-4).toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundIntA: PythonInterpreter.SafePythonObject = 9
            let unboundIntB: PythonInterpreter.SafePythonObject = -3
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = -1.5
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            // Integer-led division should always round-trip as double, including int/int and
            // int/bool combinations across bound and unbound values.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound int / bound int", boundIntA, boundIntB, -21.0),
                ("bound int / unbound int", boundIntA, unboundIntB, -28.0),
                ("unbound int / bound int", unboundIntA, boundIntB, -2.25),
                ("unbound int / unbound int", unboundIntA, unboundIntB, -3.0),
                ("bound int / bound bool", boundIntA, boundTrue, 84.0),
                ("bound int / unbound bool", boundIntA, unboundTrue, 84.0),
                ("unbound int / bound bool", unboundIntA, boundTrue, 9.0),
                ("unbound int / unbound bool", unboundIntA, unboundTrue, 9.0),
                ("bound int / bound double", boundIntA, boundDouble, 33.6),
                ("bound int / unbound double", boundIntA, unboundDouble, -56.0),
                ("unbound int / bound double", unboundIntA, boundDouble, 3.6),
                ("unbound int / unbound double", unboundIntA, unboundDouble, -6.0)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs / rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining verifies left-to-right division and preserves the promoted floating-point result.
            let chainedResult = boundIntA / unboundIntA / boundDouble / boundTrue
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: 3.7333333333333334))
        }
    }
    
    @Test("O/_002: Division Operator Double")
    func divisionOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDoubleA = try (-17.5).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDoubleB = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDoubleA: PythonInterpreter.SafePythonObject = 19.2
            let unboundDoubleB: PythonInterpreter.SafePythonObject = -1.6
            
            let boundInt = try 8.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -4
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            // Double-led division stays in floating-point space for double/double, double/int,
            // and double/bool combinations across bound and unbound states.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound double / bound double", boundDoubleA, boundDoubleB, -7.0),
                ("bound double / unbound double", boundDoubleA, unboundDoubleA, -0.9114583333333334),
                ("unbound double / bound double", unboundDoubleA, boundDoubleA, -1.0971428571428572),
                ("unbound double / unbound double", unboundDoubleA, unboundDoubleB, -12.0),
                ("bound double / bound int", boundDoubleA, boundInt, -2.1875),
                ("bound double / unbound int", boundDoubleA, unboundInt, 4.375),
                ("unbound double / bound int", unboundDoubleA, boundInt, 2.4),
                ("unbound double / unbound int", unboundDoubleA, unboundInt, -4.8),
                ("bound double / bound bool", boundDoubleA, boundTrue, -17.5),
                ("bound double / unbound bool", boundDoubleA, unboundTrue, -17.5),
                ("unbound double / bound bool", unboundDoubleA, boundTrue, 19.2),
                ("unbound double / unbound bool", unboundDoubleA, unboundTrue, 19.2)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs / rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining keeps the promoted result in floating-point space through repeated division.
            let chainedResult = unboundDoubleA / boundDoubleB / unboundInt / boundTrue
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: -1.92))
        }
    }
    
    @Test("O/_004: Division Operator Bool")
    func divisionOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundInt = try 4.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -2
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = -0.5
            
            // Bool-led division behaves like Python numeric division where bool participates as 0/1,
            // and every successful result remains floating-point.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound bool / bound bool", boundTrue, boundTrue, 1.0),
                ("bound bool / unbound bool", boundTrue, unboundTrue, 1.0),
                ("unbound bool / bound bool", unboundFalse, boundTrue, 0.0),
                ("unbound bool / unbound bool", unboundTrue, unboundTrue, 1.0),
                ("bound bool / bound int", boundTrue, boundInt, 0.25),
                ("bound bool / unbound int", boundTrue, unboundInt, -0.5),
                ("unbound bool / bound int", unboundFalse, boundInt, 0.0),
                ("unbound bool / unbound int", unboundTrue, unboundInt, -0.5),
                ("bound bool / bound double", boundTrue, boundDouble, 0.4),
                ("bound bool / unbound double", boundTrue, unboundDouble, -2.0),
                ("unbound bool / bound double", unboundFalse, boundDouble, 0.0),
                ("unbound bool / unbound double", unboundTrue, unboundDouble, -2.0)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs / rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Division by false should surface divide-by-zero semantics for deferred operands.
            let divideByZeroCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound bool / unbound false", boundTrue, unboundFalse),
                ("unbound bool / bound false", unboundTrue, boundFalse),
                ("unbound bool / unbound false", unboundTrue, unboundFalse)
            ]
            
            for (description, lhs, rhs) in divideByZeroCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.divide(divisor: rhs)
                }
                
                switch thrownError {
                case .divideByZero, .safePythonException:
                    break
                default:
                    Issue.record("Expected divide-by-zero failure for \(description), but got \(thrownError)")
                }
            }
        }
    }
    
    @Test("O/_005: PythonObject (async) divide")
    func dividePythonObject() async throws {
        let dividendA = try await 18.toPythonObject(interpreter: interpreter)
        let divisorA = try await 4.toPythonObject(interpreter: interpreter)
        let quotientA = try await dividendA.divide(divisorA)
        let roundTripA = try await Double(quotientA)
        #expect(roundTripA.isCloseEnough(to: 4.5))
        
        let dividendB = try await 21.toPythonObject(interpreter: interpreter)
        let quotientB = try await dividendB.divide(3)
        let roundTripB = try await Double(quotientB)
        #expect(roundTripB.isCloseEnough(to: 7.0))
        
        let dividendC = try await 21.toPythonObject(interpreter: interpreter)
        let quotientC = try await dividendC.divide(2.5)
        let roundTripC = try await Double(quotientC)
        #expect(roundTripC.isCloseEnough(to: 8.4))
        
        let dividendD = try await true.toPythonObject(interpreter: interpreter)
        let quotientD = try await dividendD.divide(true)
        let roundTripD = try await Double(quotientD)
        #expect(roundTripD.isCloseEnough(to: 1.0))
    }
    
    @Test("O/_006: PythonObject (async) divide error checking")
    func dividePythonObjectError() async throws {
        let boundDouble = try await 1.5.toPythonObject(interpreter: interpreter)
        let boundInt = try await 2.toPythonObject(interpreter: interpreter)
        let boundString = try await "abc".toPythonObject(interpreter: interpreter)
        let boundBool = try await true.toPythonObject(interpreter: interpreter)
        
        // Async PythonObject division always goes through Python, so invalid string-related
        // divisions and zero divisors should surface as pythonException.
        let errorCases: [(String, PythonObject, any PendingPythonConvertible)] = [
            ("python double / string", boundDouble, "abc"),
            ("python int / string", boundInt, "abc"),
            ("python string / double", boundString, 1.5),
            ("python string / int", boundString, 2),
            ("python string / string", boundString, "def"),
            ("python string / bool", boundString, true),
            ("python bool / string", boundBool, "abc"),
            ("python double / zero", boundDouble, 0),
            ("python int / false", boundInt, false),
            ("python bool / zero double", boundBool, 0.0)
        ]
        
        for (description, lhs, rhs) in errorCases {
            let thrownError = await #expect(throws: PythonError.self, Comment(rawValue: description)) {
                _ = try await lhs.divide(rhs)
            }
            
            if case .pythonException = thrownError {
                // expected
            } else {
                Issue.record("Expected .pythonException for \(description), but got \(thrownError)")
            }
        }
    }
    
    @Test("O/_010: safePythonObject division error checking")
    func safeDivisionErrors() async throws {
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
            
            // Fully deferred invalid divisions should throw the local typeError that matches
            // the operand order encoded in SafePythonObject.divide(divisor:).
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double / unbound string", unboundDouble, unboundString, "Double", "String"),
                ("unbound int / unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string / unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound string / unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound string / unbound string", unboundString, unboundString, "String", "String"),
                ("unbound string / unbound bool", unboundString, unboundBool, "String", "Bool"),
                ("unbound bool / unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.divide(divisor: rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "division", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(thrownError)")
                }
            }
            
            // Fully deferred numeric zero divisors should be caught locally as divideByZero.
            let unboundDivideByZeroCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("unbound double / unbound zero int", unboundDouble, unboundZeroInt),
                ("unbound int / unbound zero double", unboundInt, unboundZeroDouble),
                ("unbound bool / unbound false", unboundBool, unboundFalse)
            ]
            
            for (description, lhs, rhs) in unboundDivideByZeroCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.divide(divisor: rhs)
                }
                
                if case .divideByZero = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .divideByZero for \(description), but got \(thrownError)")
                }
            }
            
            // Once either side is bound, divide(divisor:) delegates to Python. The same invalid
            // type pairs and zero divisors should therefore fail as safePythonException instead.
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double / unbound string", boundDouble, unboundString),
                ("unbound double / bound string", unboundDouble, boundString),
                ("bound double / bound string", boundDouble, boundString),
                ("bound int / unbound string", boundInt, unboundString),
                ("unbound int / bound string", unboundInt, boundString),
                ("bound int / bound string", boundInt, boundString),
                ("bound string / unbound double", boundString, unboundDouble),
                ("unbound string / bound double", unboundString, boundDouble),
                ("bound string / bound double", boundString, boundDouble),
                ("bound string / unbound int", boundString, unboundInt),
                ("unbound string / bound int", unboundString, boundInt),
                ("bound string / bound int", boundString, boundInt),
                ("bound string / unbound string", boundString, unboundString),
                ("unbound string / bound string", unboundString, boundString),
                ("bound string / bound string", boundString, boundString),
                ("bound string / unbound bool", boundString, unboundBool),
                ("unbound string / bound bool", unboundString, boundBool),
                ("bound string / bound bool", boundString, boundBool),
                ("bound bool / unbound string", boundBool, unboundString),
                ("unbound bool / bound string", unboundBool, boundString),
                ("bound bool / bound string", boundBool, boundString),
                ("bound double / unbound zero int", boundDouble, unboundZeroInt),
                ("unbound double / bound zero double", unboundDouble, boundZeroDouble),
                ("bound int / bound false", boundInt, boundFalse),
                ("unbound bool / bound zero int", unboundBool, boundZeroInt)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.divide(divisor: rhs)
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


// Checklist of tests that pass.  Fill in the date when it runs correctly.

// [   date   ] : The date the test runs correctly and passes
// [yyyy-mm-dd] : Test ID : Test
//


// Division

// [2026-05-07] : O/_001 : Divide integer by integer SafePythonObject
// [2026-05-07] : O/_002 : Divide integer by double SafePythonObject
// [2026-05-07] : O/_002 : Divide double by double SafePythonObject
// [2026-05-07] : O/_002 : Divide double by integer SafePythonObject
// [2026-05-07] : O/_001 : Divide bool by integer SafePythonObject
// [2026-05-07] : O/_002 : Divide bool by double SafePythonObject
// [2026-05-07] : O/_003 : Divide string by string SafePythonObject
// [2026-05-07] : O/_004 : Divide bool by bool SafePythonObject

// [2026-05-07] : O/_001 : Divide integer by integer SafePythonObject unbound
// [2026-05-07] : O/_002 : Divide integer by double SafePythonObject unbound
// [2026-05-07] : O/_002 : Divide double by double SafePythonObject unbound
// [2026-05-07] : O/_002 : Divide double by integer SafePythonObject unbound
// [2026-05-07] : O/_001 : Divide bool by integer SafePythonObject unbound
// [2026-05-07] : O/_002 : Divide bool by double SafePythonObject unbound
// [2026-05-07] : O/_003 : Divide string by string SafePythonObject unbound
// [2026-05-07] : O/_004 : Divide bool by bool SafePythonObject unbound

// [2026-05-07] : O/_010 : Divide string by integer SafePythonObject error handling
// [2026-05-07] : O/_010 : Divide string by double SafePythonObject error handling
// [2026-05-07] : O/_010 : Divide string by bool SafePythonObject error handling
// [2026-05-07] : O/_010 : Divide integer by string SafePythonObject error handling
// [2026-05-07] : O/_010 : Divide double by string SafePythonObject error handling
// [2026-05-07] : O/_010 : Divide bool by string SafePythonObject error handling

// [2026-05-07] : O/_005 : Divide PythonObject by PythonObject
// [2026-05-07] : O/_005 : Divide PythonObject by Int
// [2026-05-07] : O/_005 : Divide PythonObject by Double
// [2026-05-07] : O/_005 : Divide PythonObject by Bool
// [2026-05-07] : O/_005 : Divide PythonObject by String
// [2026-05-07] : O/_006 : Divide PythonObject error handling
