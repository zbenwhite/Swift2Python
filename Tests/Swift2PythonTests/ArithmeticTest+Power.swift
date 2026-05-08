//
//  ArithmeticTest+Power.swift
//  Swift2Python
//
//  Created by Ben White on 5/7/26.
//

import Testing
import Logging
@testable import Swift2Python

extension ArithmeticTests {
    
    @Test("O**_001: Power Operator Integer")
    func powerOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundIntA = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundIntB = try 4.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundIntA: PythonInterpreter.SafePythonObject = -2
            let unboundIntB: PythonInterpreter.SafePythonObject = 5
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            // Integer-led power should preserve integer results for non-negative integer/bool exponents
            // across bound and unbound combinations.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int ** bound int", boundIntA, boundIntB, 81),
                ("bound int ** unbound int", boundIntA, unboundFalse, 1),
                ("unbound int ** bound int", unboundIntA, boundIntB, 16),
                ("unbound int ** unbound int", unboundIntA, unboundIntB, -32),
                ("bound int ** bound bool", boundIntA, boundTrue, 3),
                ("bound int ** unbound bool", boundIntA, unboundFalse, 1),
                ("unbound int ** bound bool", unboundIntA, boundTrue, -2),
                ("unbound int ** unbound bool", unboundIntA, unboundFalse, 1)
            ]
            
            for (description, base, exponent, expected) in intCases {
                let result = base ** exponent
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // Negative integer exponents should promote the result to double.
            let negativeExponentCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound int ** negative int", boundIntA, try (-2).toSafePythonObject(interpreter: isolatedInterpreter), 1.0 / 9.0),
                ("unbound int ** negative int", unboundIntA, -3, -0.125)
            ]
            
            for (description, base, exponent, expected) in negativeExponentCases {
                let result = try base.power(exponent: exponent)
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
        }
    }
    
    @Test("O**_002: Power Operator Double")
    func powerOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDoubleA = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDoubleB = try 3.0.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDoubleA: PythonInterpreter.SafePythonObject = 9.0
            let unboundDoubleB: PythonInterpreter.SafePythonObject = 0.5
            
            let boundInt = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -2
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            // Double-led power stays in floating-point space for double/double, double/int,
            // and double/bool combinations across bound and unbound states.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound double ** bound double", boundDoubleA, boundDoubleB, 15.625),
                ("bound double ** unbound double", boundDoubleA, unboundDoubleB, 1.5811388300841898),
                ("unbound double ** bound double", unboundDoubleA, boundDoubleB, 729.0),
                ("unbound double ** unbound double", unboundDoubleA, unboundDoubleB, 3.0),
                ("bound double ** bound int", boundDoubleA, boundInt, 6.25),
                ("bound double ** unbound int", boundDoubleA, unboundInt, 0.16),
                ("unbound double ** bound int", unboundDoubleA, boundInt, 81.0),
                ("unbound double ** unbound int", unboundDoubleA, unboundInt, 1.0 / 81.0),
                ("bound double ** bound bool", boundDoubleA, boundTrue, 2.5),
                ("bound double ** unbound bool", boundDoubleA, unboundFalse, 1.0),
                ("unbound double ** bound bool", unboundDoubleA, boundTrue, 9.0),
                ("unbound double ** unbound bool", unboundDoubleA, unboundFalse, 1.0)
            ]
            
            for (description, base, exponent, expected) in doubleCases {
                let result = base ** exponent
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
        }
    }
    
    @Test("O**_004: Power Operator Bool")
    func powerOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundInt = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -2
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = -0.5
            
            // Bool-led power should behave like Python numeric exponentiation where bool participates as 0/1.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool ** bound bool", boundTrue, boundFalse, 1),
                ("bound bool ** unbound bool", boundFalse, unboundTrue, 0),
                ("unbound bool ** bound bool", unboundTrue, boundFalse, 1),
                ("unbound bool ** unbound bool", unboundTrue, unboundTrue, 1),
                ("bound bool ** bound int", boundTrue, boundInt, 1),
                ("bound bool ** unbound int", boundFalse, try 2.toSafePythonObject(interpreter: isolatedInterpreter), 0),
                ("unbound bool ** bound int", unboundFalse, boundInt, 0),
                ("unbound bool ** unbound int", unboundTrue, 4, 1)
            ]
            
            for (description, base, exponent, expected) in intCases {
                let result = base ** exponent
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound bool ** bound double", boundTrue, boundDouble, 1.0),
                ("bound bool ** unbound double", boundFalse, unboundDouble, .infinity),
                ("unbound bool ** bound double", unboundTrue, boundDouble, 1.0),
                ("unbound bool ** unbound double", unboundFalse, 0.5, 0.0)
            ]
            
            for (description, base, exponent, expected) in doubleCases {
                let result = try base.power(exponent: exponent)
                let roundTrip = try Double(result)
                if expected.isInfinite {
                    #expect(roundTrip.isInfinite, Comment(rawValue: description))
                } else {
                    #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
                }
            }
            
            // Negative integer exponents on false should fail like division by zero.
            let thrownError = #expect(throws: PythonError.self, Comment(rawValue: "bool zero base to negative int")) {
                _ = try unboundFalse.power(exponent: unboundInt)
            }
            if case .divideByZero = thrownError {
                // expected
            } else {
                Issue.record("Expected .divideByZero for bool zero base to negative int, but got \(thrownError)")
            }
        }
    }
    
    @Test("O**_005: PythonObject (async) power")
    func powerPythonObject() async throws {
        let baseA = try await 3.toPythonObject(interpreter: interpreter)
        let exponentA = try await 4.toPythonObject(interpreter: interpreter)
        let resultA = try await baseA.power(exponentA)
        let roundTripA = try await Int(resultA)
        #expect(roundTripA == 81)
        
        let baseB = try await 2.5.toPythonObject(interpreter: interpreter)
        let resultB = try await baseB.power(2)
        let roundTripB = try await Double(resultB)
        #expect(roundTripB.isCloseEnough(to: 6.25))
        
        let baseC = try await 3.toPythonObject(interpreter: interpreter)
        let resultC = try await baseC.power(-2)
        let roundTripC = try await Double(resultC)
        #expect(roundTripC.isCloseEnough(to: 1.0 / 9.0))
        
        let baseD = try await true.toPythonObject(interpreter: interpreter)
        let resultD = try await baseD.power(false)
        let roundTripD = try await Int(resultD)
        #expect(roundTripD == 1)
        
        let baseE = try await 0.toPythonObject(interpreter: interpreter)
        let resultE = try await baseE.power(0)
        let roundTripE = try await Int(resultE)
        #expect(roundTripE == 1)
    }
    
    @Test("O**_006: PythonObject (async) power error checking")
    func powerPythonObjectError() async throws {
        let boundDouble = try await 1.5.toPythonObject(interpreter: interpreter)
        let boundInt = try await 2.toPythonObject(interpreter: interpreter)
        let boundString = try await "abc".toPythonObject(interpreter: interpreter)
        let boundBool = try await true.toPythonObject(interpreter: interpreter)
        let boundZeroInt = try await 0.toPythonObject(interpreter: interpreter)
        let boundZeroDouble = try await 0.0.toPythonObject(interpreter: interpreter)
        let boundFalse = try await false.toPythonObject(interpreter: interpreter)
        
        // Async PythonObject power always goes through Python, so invalid string-related powers
        // and zero-to-negative-exponent cases should surface as pythonException.
        let errorCases: [(String, PythonObject, any PendingPythonConvertible)] = [
            ("python double ** string", boundDouble, "abc"),
            ("python int ** string", boundInt, "abc"),
            ("python string ** double", boundString, 1.5),
            ("python string ** int", boundString, 2),
            ("python string ** string", boundString, "def"),
            ("python string ** bool", boundString, true),
            ("python bool ** string", boundBool, "abc"),
            ("python zero int ** negative int", boundZeroInt, -1),
            ("python zero double ** negative double", boundZeroDouble, -0.5),
            ("python false ** negative int", boundFalse, -2)
        ]
        
        for (description, base, exponent) in errorCases {
            let thrownError = await #expect(throws: PythonError.self, Comment(rawValue: description)) {
                _ = try await base.power(exponent)
            }
            
            if case .pythonException = thrownError {
                // expected
            } else {
                Issue.record("Expected .pythonException for \(description), but got \(thrownError)")
            }
        }
    }
    
    @Test("O**_009: Power Special Cases")
    func powerSpecialCases() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundZeroInt = try 0.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundZeroDouble = try 0.0.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundNegativeTwo = try (-2).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundHalf = try 0.5.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundZeroInt: PythonInterpreter.SafePythonObject = 0
            let unboundZeroDouble: PythonInterpreter.SafePythonObject = 0.0
            let unboundNegativeTwo: PythonInterpreter.SafePythonObject = -2
            let unboundHalf: PythonInterpreter.SafePythonObject = 0.5
            let unboundNegativeOne: PythonInterpreter.SafePythonObject = -1
            
            // 0 ** 0 should follow Python and evaluate to 1 for the supported numeric combinations.
            let zeroToZeroIntCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound zero int ** bound zero int", boundZeroInt, boundZeroInt, 1),
                ("unbound zero int ** unbound zero int", unboundZeroInt, unboundZeroInt, 1)
            ]
            
            for (description, base, exponent, expected) in zeroToZeroIntCases {
                let result = try base.power(exponent: exponent)
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            let zeroToZeroDoubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound zero double ** bound zero double", boundZeroDouble, boundZeroDouble, 1.0),
                ("unbound zero double ** unbound zero double", unboundZeroDouble, unboundZeroDouble, 1.0)
            ]
            
            for (description, base, exponent, expected) in zeroToZeroDoubleCases {
                let result = try base.power(exponent: exponent)
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Zero raised to a negative exponent should fail.
            let zeroToNegativeCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound zero int ** unbound negative one", boundZeroInt, unboundNegativeOne),
                ("unbound zero int ** unbound negative one", unboundZeroInt, unboundNegativeOne),
                ("bound zero double ** unbound negative one", boundZeroDouble, unboundNegativeOne),
                ("unbound zero double ** unbound negative one", unboundZeroDouble, unboundNegativeOne)
            ]
            
            for (description, base, exponent) in zeroToNegativeCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try base.power(exponent: exponent)
                }
                
                switch thrownError {
                case .divideByZero, .safePythonException:
                    break
                default:
                    Issue.record("Expected zero-to-negative power failure for \(description), but got \(thrownError)")
                }
            }
            
            // The documented unbound fallback for negative base fractional exponent is NaN.
            let nanResult = try unboundNegativeTwo.power(exponent: unboundHalf)
            let nanRoundTrip = try Double(nanResult)
            #expect(nanRoundTrip.isNaN)
            
            // A bound Python execution of the same case should not come back as a normal Double.
            let boundThrownError = #expect(throws: PythonError.self, Comment(rawValue: "bound negative int ** bound half")) {
                let result = try boundNegativeTwo.power(exponent: boundHalf)
                _ = try Double(result)
            }
            if case .conversionType = boundThrownError {
                // expected: Python returns a complex result that cannot round-trip to Double.
            } else {
                Issue.record("Expected .conversionType for bound negative int ** bound half, but got \(boundThrownError)")
            }
        }
    }
    
    @Test("O**_010: safePythonObject power error checking")
    func safePowerErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundBool = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundZeroInt = try 0.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundBool: PythonInterpreter.SafePythonObject = true
            let unboundNegativeInt: PythonInterpreter.SafePythonObject = -1
            
            // Fully deferred invalid powers should throw the local typeError that matches
            // the operand order encoded in SafePythonObject.power(exponent:).
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double ** unbound string", unboundDouble, unboundString, "Double", "String"),
                ("unbound int ** unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string ** unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound string ** unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound string ** unbound string", unboundString, unboundString, "String", "String"),
                ("unbound string ** unbound bool", unboundString, unboundBool, "String", "Bool"),
                ("unbound bool ** unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, base, exponent, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try base.power(exponent: exponent)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "power", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(thrownError)")
                }
            }
            
            // Fully deferred zero-to-negative powers should be caught locally as divideByZero.
            let unboundDivideByZeroCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("unbound zero int ** negative int", 0, unboundNegativeInt),
                ("unbound zero double ** negative int", 0.0, unboundNegativeInt),
                ("unbound false ** negative int", false, unboundNegativeInt)
            ]
            
            for (description, base, exponent) in unboundDivideByZeroCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try base.power(exponent: exponent)
                }
                
                if case .divideByZero = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .divideByZero for \(description), but got \(thrownError)")
                }
            }
            
            // Once either side is bound, power(exponent:) delegates to Python. The same invalid
            // type pairs and zero-to-negative cases should therefore fail as safePythonException instead.
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double ** unbound string", boundDouble, unboundString),
                ("unbound double ** bound string", unboundDouble, boundString),
                ("bound double ** bound string", boundDouble, boundString),
                ("bound int ** unbound string", boundInt, unboundString),
                ("unbound int ** bound string", unboundInt, boundString),
                ("bound int ** bound string", boundInt, boundString),
                ("bound string ** unbound double", boundString, unboundDouble),
                ("unbound string ** bound double", unboundString, boundDouble),
                ("bound string ** bound double", boundString, boundDouble),
                ("bound string ** unbound int", boundString, unboundInt),
                ("unbound string ** bound int", unboundString, boundInt),
                ("bound string ** bound int", boundString, boundInt),
                ("bound string ** unbound string", boundString, unboundString),
                ("unbound string ** bound string", unboundString, boundString),
                ("bound string ** bound string", boundString, boundString),
                ("bound string ** unbound bool", boundString, unboundBool),
                ("unbound string ** bound bool", unboundString, boundBool),
                ("bound string ** bound bool", boundString, boundBool),
                ("bound bool ** unbound string", boundBool, unboundString),
                ("unbound bool ** bound string", unboundBool, boundString),
                ("bound bool ** bound string", boundBool, boundString),
                ("bound zero int ** unbound negative int", boundZeroInt, unboundNegativeInt),
                ("unbound zero int ** bound negative int", 0, try (-1).toSafePythonObject(interpreter: isolatedInterpreter)),
                ("bound false ** unbound negative int", try false.toSafePythonObject(interpreter: isolatedInterpreter), unboundNegativeInt)
            ]
            
            for (description, base, exponent) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try base.power(exponent: exponent)
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


// Power

// [          ] : O**_001 : Power integer with integer SafePythonObject
// [          ] : O**_002 : Power double with double SafePythonObject
// [          ] : O**_004 : Power bool with bool SafePythonObject
// [          ] : O**_005 : Power PythonObject by PythonObject
// [          ] : O**_005 : Power PythonObject by Int
// [          ] : O**_005 : Power PythonObject by Double
// [          ] : O**_005 : Power PythonObject by Bool
// [          ] : O**_006 : Power PythonObject error handling
// [          ] : O**_009 : Power special cases
// [          ] : O**_010 : Power SafePythonObject error handling
