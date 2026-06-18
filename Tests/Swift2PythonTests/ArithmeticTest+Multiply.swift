//
//  Test.swift
//  Swift2Python
//
//  Created by Ben White on 5/5/26.
//

import Testing
import Logging
@testable import Swift2Python

extension ArithmeticTests {
    
    @Test("O*_001: Multiplication Operator Integer")
    func multiplicationOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundIntA = try 11.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundIntB = try (-4).toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundIntA: PythonInterpreter.SafePythonObject = 6
            let unboundIntB: PythonInterpreter.SafePythonObject = -3
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = -1.25
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundString = try "py".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "go"
            
            // Integer-led multiplication should preserve integer results for int/bool combinations
            // regardless of whether each operand is already bound or still deferred.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int * bound int", boundIntA, boundIntB, -44),
                ("bound int * unbound int", boundIntA, unboundIntB, -33),
                ("unbound int * bound int", unboundIntA, boundIntB, -24),
                ("unbound int * unbound int", unboundIntA, unboundIntB, -18),
                ("bound int * bound bool", boundIntA, boundTrue, 11),
                ("bound int * unbound bool", boundIntA, unboundFalse, 0),
                ("unbound int * bound bool", unboundIntA, boundTrue, 6),
                ("unbound int * unbound bool", unboundIntA, unboundFalse, 0)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs * rhs
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // Integer-led multiplication should promote to double when either side is a double,
            // while still covering bound/unbound combinations.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound int * bound double", boundIntA, boundDouble, 27.5),
                ("bound int * unbound double", boundIntA, unboundDouble, -13.75),
                ("unbound int * bound double", unboundIntA, boundDouble, 15.0),
                ("unbound int * unbound double", unboundIntA, unboundDouble, -7.5)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs * rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Integer * string should follow Python repetition semantics for both bound and deferred values.
            let stringCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String)] = [
                ("bound int * bound string", boundIntB, boundString, ""),
                ("bound int * unbound string", boundIntA, unboundString, "gogogogogogogogogogogo"),
                ("unbound int * bound string", unboundIntA, boundString, "pypypypypypy"),
                ("unbound int * unbound string", unboundIntB, unboundString, "")
            ]
            
            for (description, lhs, rhs, expected) in stringCases {
                let result = lhs * rhs
                let roundTrip = try String(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // Chaining verifies left-to-right multiplication across promotions and bool coercion.
            let chainedResult = boundIntB * unboundIntA * boundDouble * boundTrue
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: -60.0))
        }
    }
    
    @Test("O*_002: Multiplication Operator Double")
    func multiplicationOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDoubleA = try (-3.5).toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDoubleB = try 4.2.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDoubleA: PythonInterpreter.SafePythonObject = 1.25
            let unboundDoubleB: PythonInterpreter.SafePythonObject = -2.0
            
            let boundInt = try 8.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -3
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            // Double-led multiplication should stay in floating-point space for double/double,
            // double/int, and double/bool combinations across bound and unbound states.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound double * bound double", boundDoubleA, boundDoubleB, -14.7),
                ("bound double * unbound double", boundDoubleA, unboundDoubleA, -4.375),
                ("unbound double * bound double", unboundDoubleA, boundDoubleA, -4.375),
                ("unbound double * unbound double", unboundDoubleA, unboundDoubleB, -2.5),
                ("bound double * bound int", boundDoubleA, boundInt, -28.0),
                ("bound double * unbound int", boundDoubleA, unboundInt, 10.5),
                ("unbound double * bound int", unboundDoubleA, boundInt, 10.0),
                ("unbound double * unbound int", unboundDoubleA, unboundInt, -3.75),
                ("bound double * bound bool", boundDoubleA, boundTrue, -3.5),
                ("bound double * unbound bool", boundDoubleA, unboundFalse, -0.0),
                ("unbound double * bound bool", unboundDoubleA, boundTrue, 1.25),
                ("unbound double * unbound bool", unboundDoubleA, unboundFalse, 0.0)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs * rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Chaining keeps the promoted result in floating-point space through repeated multiplication.
            let chainedResult = unboundDoubleA * boundDoubleB * unboundInt * boundTrue
            let chainedRoundTrip = try Double(chainedResult)
            #expect(chainedRoundTrip.isCloseEnough(to: -15.75))
        }
    }
    
    @Test("O*_003: Multiplication Operator String")
    func multiplicationOperatorString() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundStringA = try "ha".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundStringB = try "z".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundStringA: PythonInterpreter.SafePythonObject = "go"
            let unboundStringB: PythonInterpreter.SafePythonObject = "bye"
            
            let boundInt = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 2
            
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            // String-led multiplication should repeat for int operands and collapse to an empty string
            // when multiplied by false, matching Python's repetition rules.
            let stringCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String)] = [
                ("bound string * bound int", boundStringA, boundInt, "hahaha"),
                ("bound string * unbound int", boundStringA, unboundInt, "haha"),
                ("unbound string * bound int", unboundStringA, boundInt, "gogogo"),
                ("unbound string * unbound int", unboundStringA, unboundInt, "gogo"),
                ("bound string * bound bool", boundStringA, boundTrue, "ha"),
                ("bound string * unbound bool", boundStringA, unboundFalse, ""),
                ("unbound string * bound bool", unboundStringA, boundTrue, "go"),
                ("unbound string * unbound bool", unboundStringA, unboundFalse, "")
            ]
            
            for (description, lhs, rhs, expected) in stringCases {
                let result = lhs * rhs
                let roundTrip = try String(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // Bound and deferred string operands that are both strings should fail through the throwing API.
            let invalidCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound string * bound string", boundStringA, boundStringB),
                ("bound string * unbound string", boundStringA, unboundStringB),
                ("unbound string * bound string", unboundStringA, boundStringB),
                ("unbound string * unbound string", unboundStringA, unboundStringB)
            ]
            
            for (description, lhs, rhs) in invalidCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.multiply(rhs)
                }
                
                switch thrownError {
                case .safePythonException, .typeError(operation: "multiplication", opType1: "String", opType2: "String"):
                    break
                default:
                    Issue.record("Expected string/string multiplication failure for \(description), but got \(thrownError)")
                }
            }
        }
    }
    
    @Test("O*_004: Multiplication Operator Bool")
    func multiplicationOperatorBool() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundFalse = try false.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boundInt = try 9.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = -4
            
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = -7.5
            
            let boundString = try "ok".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "hi"
            
            // Bool-led multiplication behaves like Python numeric multiplication where bool participates
            // as 0/1 for bool/bool and bool/int combinations.
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound bool * bound bool", boundTrue, boundFalse, 0),
                ("bound bool * unbound bool", boundTrue, unboundTrue, 1),
                ("unbound bool * bound bool", unboundFalse, boundTrue, 0),
                ("unbound bool * unbound bool", unboundTrue, unboundTrue, 1),
                ("bound bool * bound int", boundTrue, boundInt, 9),
                ("bound bool * unbound int", boundTrue, unboundInt, -4),
                ("unbound bool * bound int", unboundFalse, boundInt, 0),
                ("unbound bool * unbound int", unboundTrue, unboundInt, -4)
            ]
            
            for (description, lhs, rhs, expected) in intCases {
                let result = lhs * rhs
                let roundTrip = try Int(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
            
            // When a bool-led multiplication involves a double, the result should promote to double
            // while still treating the bool as 0/1.
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound bool * bound double", boundTrue, boundDouble, 2.5),
                ("bound bool * unbound double", boundTrue, unboundDouble, -7.5),
                ("unbound bool * bound double", unboundFalse, boundDouble, 0.0),
                ("unbound bool * unbound double", unboundTrue, unboundDouble, -7.5)
            ]
            
            for (description, lhs, rhs, expected) in doubleCases {
                let result = lhs * rhs
                let roundTrip = try Double(result)
                #expect(roundTrip.isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            // Bool * string should mirror Python repetition semantics.
            let stringCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String)] = [
                ("bound bool * bound string", boundTrue, boundString, "ok"),
                ("bound bool * unbound string", boundFalse, unboundString, ""),
                ("unbound bool * bound string", unboundTrue, boundString, "ok"),
                ("unbound bool * unbound string", unboundFalse, unboundString, "")
            ]
            
            for (description, lhs, rhs, expected) in stringCases {
                let result = lhs * rhs
                let roundTrip = try String(result)
                #expect(roundTrip == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O*_005: PythonObject (async) multiply")
    func multiplyPythonObject() async throws {
        let lhsA = try await 17.toPythonObject(interpreter: interpreter)
        let rhsA = try await 6.toPythonObject(interpreter: interpreter)
        let productA = try await lhsA.multiply(rhsA)
        let roundTripA = try await Int(productA)
        #expect(roundTripA == 102)
        
        let lhsB = try await 17.toPythonObject(interpreter: interpreter)
        let productB = try await lhsB.multiply(2)
        let roundTripB = try await Int(productB)
        #expect(roundTripB == 34)
        
        let lhsC = try await 17.toPythonObject(interpreter: interpreter)
        let productC = try await lhsC.multiply(2.5)
        let roundTripC = try await Double(productC)
        #expect(roundTripC.isCloseEnough(to: 42.5))
        
        let lhsD = try await true.toPythonObject(interpreter: interpreter)
        let productD = try await lhsD.multiply(false)
        let roundTripD = try await Int(productD)
        #expect(roundTripD == 0)
        
        let lhsE = try await "ab".toPythonObject(interpreter: interpreter)
        let productE = try await lhsE.multiply(3)
        let roundTripE = try await String(productE)
        #expect(roundTripE == "ababab")
    }
    
    @Test("O*_006: PythonObject (async) multiply error checking")
    func multiplyPythonObjectError() async throws {
        let boundDouble = try await 1.5.toPythonObject(interpreter: interpreter)
        let boundString = try await "abc".toPythonObject(interpreter: interpreter)
        
        // Async PythonObject multiplication always goes through Python, so invalid string-related
        // combinations should surface as pythonException.
        let errorCases: [(String, PythonObject, any PendingPythonConvertible)] = [
            ("python double * string", boundDouble, "abc"),
            ("python string * double", boundString, 1.5),
            ("python string * string", boundString, "def")
        ]
        
        for (description, lhs, rhs) in errorCases {
            let thrownError = await #expect(throws: PythonError.self, Comment(rawValue: description)) {
                _ = try await lhs.multiply(rhs)
            }
            
            if case .pythonException = thrownError {
                // expected
            } else {
                Issue.record("Expected .pythonException for \(description), but got \(thrownError)")
            }
        }
    }
    
    @Test("O*=_005: PythonObject (async) times equals")
    func timesEqualsPythonObject() async throws {
        let lhsA = try await 17.toPythonObject(interpreter: interpreter)
        let productA = try await lhsA.multiplyInPlace(6)
        let roundTripA = try await Int(productA)
        #expect(roundTripA == 102)
        
        let lhsB = try await 17.toPythonObject(interpreter: interpreter)
        let productB = try await lhsB.multiplyInPlace(2.5)
        let roundTripB = try await Double(productB)
        #expect(roundTripB.isCloseEnough(to: 42.5))
        
        let lhsC = try await true.toPythonObject(interpreter: interpreter)
        let productC = try await lhsC.multiplyInPlace(false)
        let roundTripC = try await Int(productC)
        #expect(roundTripC == 0)
        
        let lhsD = try await "ab".toPythonObject(interpreter: interpreter)
        let productD = try await lhsD.multiplyInPlace(3)
        let roundTripD = try await String(productD)
        #expect(roundTripD == "ababab")
    }
    
    @Test("O*=_006: PythonObject (async) times equals error checking")
    func timesEqualsPythonObjectError() async throws {
        let boundDouble = try await 1.5.toPythonObject(interpreter: interpreter)
        let boundString = try await "abc".toPythonObject(interpreter: interpreter)
        
        let errorCases: [(String, PythonObject, any PendingPythonConvertible)] = [
            ("python double *= string", boundDouble, "abc"),
            ("python string *= double", boundString, 1.5),
            ("python string *= string", boundString, "def")
        ]
        
        for (description, lhs, rhs) in errorCases {
            let thrownError = await #expect(throws: PythonError.self, Comment(rawValue: description)) {
                _ = try await lhs.multiplyInPlace(rhs)
            }
            
            if case .pythonException = thrownError {
                // expected
            } else {
                Issue.record("Expected .pythonException for \(description), but got \(thrownError)")
            }
        }
    }
    
    @Test("O*_011: safePythonObject multiplication accepts SafePythonConvertible values")
    func safeMultiplicationAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let typedInt = 32
            let boundInt = try 10.toSafePythonObject(interpreter: isolatedInterpreter)
            let intResult = try boundInt.multiply(typedInt)
            #expect(try Int(intResult) == 320)
            
            let typedDouble = 0.5
            let doubleResult = try boundInt.multiply(typedDouble)
            #expect(try Double(doubleResult) == 5.0)
            
            let repeatCount = 3
            let boundString = try "ha".toSafePythonObject(interpreter: isolatedInterpreter)
            let stringResult = try boundString.multiply(repeatCount)
            #expect(try String(stringResult) == "hahaha")
            
            let literalResult = try boundInt.multiply(2)
            #expect(try Int(literalResult) == 20)
            
            let deferredInt: PythonInterpreter.SafePythonObject = 10
            let thrownError = #expect(throws: PythonError.self) {
                _ = try deferredInt.multiply(typedInt)
            }
            
            if case .conversionType = thrownError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.multiply(Int), but got \(thrownError)")
            }
        }
    }
    
    @Test("O*_012: safePythonObject deferred integer multiplication overflow")
    func safeDeferredIntegerMultiplicationOverflow() throws {
        let maxInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
        let two: PythonInterpreter.SafePythonObject = 2
        let minInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.min)
        let negativeOne: PythonInterpreter.SafePythonObject = -1
        
        let maxOverflow = #expect(throws: PythonError.self) {
            _ = try maxInt.multiply(two)
        }
        
        if case .conversionOverflow = maxOverflow {
            // expected
        } else {
            Issue.record("Expected .conversionOverflow for deferred Int.max * 2, but got \(maxOverflow)")
        }
        
        let minOverflow = #expect(throws: PythonError.self) {
            _ = try minInt.multiply(negativeOne)
        }
        
        if case .conversionOverflow = minOverflow {
            // expected
        } else {
            Issue.record("Expected .conversionOverflow for deferred Int.min * -1, but got \(minOverflow)")
        }
    }
    
    @Test("O*=_001: Times Equals Operator")
    func timesEqualsOperator() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundInt = try 7.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "ha".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundInt: PythonInterpreter.SafePythonObject = 3
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundString: PythonInterpreter.SafePythonObject = "go"
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let intCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Int)] = [
                ("bound int *= unbound int", boundInt, unboundInt, 21),
                ("unbound int *= bound int", unboundInt, boundInt, 21),
                ("bound int *= bound bool", boundInt, boundTrue, 7),
                ("unbound int *= unbound bool", unboundInt, unboundFalse, 0)
            ]
            
            for (description, initialValue, multiplicand, expected) in intCases {
                var result = initialValue
                result *= multiplicand
                #expect(try Int(result) == expected, Comment(rawValue: description))
            }
            
            let doubleCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Double)] = [
                ("bound double *= unbound int", boundDouble, unboundInt, 7.5),
                ("unbound double *= bound int", unboundDouble, boundInt, 10.5),
                ("bound int *= bound double", boundInt, boundDouble, 17.5)
            ]
            
            for (description, initialValue, multiplicand, expected) in doubleCases {
                var result = initialValue
                result *= multiplicand
                #expect(try Double(result).isCloseEnough(to: expected), Comment(rawValue: description))
            }
            
            let stringCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String)] = [
                ("bound string *= unbound int", boundString, unboundInt, "hahaha"),
                ("unbound string *= bound int", unboundString, boundInt, "gogogogogogogo"),
                ("bound string *= unbound false", boundString, unboundFalse, "")
            ]
            
            for (description, initialValue, multiplicand, expected) in stringCases {
                var result = initialValue
                result *= multiplicand
                #expect(try String(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O*=_011: safePythonObject in-place multiplication accepts SafePythonConvertible values")
    func safeInPlaceMultiplicationAcceptsConvertibleValues() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let typedInt = 32
            var boundInt = try 10.toSafePythonObject(interpreter: isolatedInterpreter)
            try boundInt.multiplyInPlace(typedInt)
            #expect(try Int(boundInt) == 320)
            
            let typedDouble = 0.5
            var boundDouble = try 10.toSafePythonObject(interpreter: isolatedInterpreter)
            try boundDouble.multiplyInPlace(typedDouble)
            #expect(try Double(boundDouble) == 5.0)
            
            let repeatCount = 3
            var boundString = try "ha".toSafePythonObject(interpreter: isolatedInterpreter)
            try boundString.multiplyInPlace(repeatCount)
            #expect(try String(boundString) == "hahaha")
            
            var literalResult = try 10.toSafePythonObject(interpreter: isolatedInterpreter)
            try literalResult.multiplyInPlace(2)
            #expect(try Int(literalResult) == 20)
            
            var deferredInt: PythonInterpreter.SafePythonObject = 10
            let thrownError = #expect(throws: PythonError.self) {
                try deferredInt.multiplyInPlace(typedInt)
            }
            
            if case .conversionType = thrownError {
                // expected
            } else {
                Issue.record("Expected .conversionType for deferred SafePythonObject.multiplyInPlace(Int), but got \(thrownError)")
            }
        }
    }
    
    @Test("O*=_012: safePythonObject deferred integer in-place multiplication overflow")
    func safeDeferredIntegerInPlaceMultiplicationOverflow() throws {
        let two: PythonInterpreter.SafePythonObject = 2
        let negativeOne: PythonInterpreter.SafePythonObject = -1
        
        var maxInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
        let maxOverflow = #expect(throws: PythonError.self) {
            try maxInt.multiplyInPlace(two)
        }
        
        if case .conversionOverflow = maxOverflow {
            // expected
        } else {
            Issue.record("Expected .conversionOverflow for deferred Int.max *= 2, but got \(maxOverflow)")
        }
        
        var minInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.min)
        let minOverflow = #expect(throws: PythonError.self) {
            try minInt.multiplyInPlace(negativeOne)
        }
        
        if case .conversionOverflow = minOverflow {
            // expected
        } else {
            Issue.record("Expected .conversionOverflow for deferred Int.min *= -1, but got \(minOverflow)")
        }
    }
    
    @Test("O*=_010: safePythonObject times equals error checking")
    func safeTimesEqualsErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            
            let inPlaceTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double *= unbound string", unboundDouble, unboundString, "Double", "String"),
                ("unbound string *= unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound string *= unbound string", unboundString, unboundString, "String", "String")
            ]
            
            for (description, initialValue, multiplicand, expectedType1, expectedType2) in inPlaceTypeErrorCases {
                var result = initialValue
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    try result.multiplyInPlace(multiplicand)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "in place multiplication", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(thrownError)")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double *= unbound string", boundDouble, unboundString),
                ("unbound double *= bound string", unboundDouble, boundString),
                ("bound string *= unbound double", boundString, unboundDouble),
                ("unbound string *= bound double", unboundString, boundDouble),
                ("bound string *= unbound string", boundString, unboundString),
                ("unbound string *= bound string", unboundString, boundString)
            ]
            
            for (description, initialValue, multiplicand) in boundExceptionCases {
                var result = initialValue
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    try result.multiplyInPlace(multiplicand)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(thrownError)")
                }
            }
        }
    }
    
    @Test("O*_010: safePythonObject multiplication error checking")
    func safeMultiplicationErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 1.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            
            // Fully deferred invalid multiplications should throw the local typeError that matches
            // the operand order encoded in SafePythonObject.multiply(_:).
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound double * unbound string", unboundDouble, unboundString, "Double", "String"),
                ("unbound string * unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound string * unbound string", unboundString, unboundString, "String", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.multiply(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "multiplication", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(thrownError)")
                }
            }
            
            // Once either side is bound, multiply(_:) delegates to Python. The same invalid
            // type pairs should therefore fail as safePythonException instead of the local typeError above.
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound double * unbound string", boundDouble, unboundString),
                ("unbound double * bound string", unboundDouble, boundString),
                ("bound double * bound string", boundDouble, boundString),
                ("bound string * unbound double", boundString, unboundDouble),
                ("unbound string * bound double", unboundString, boundDouble),
                ("bound string * bound double", boundString, boundDouble),
                ("bound string * unbound string", boundString, unboundString),
                ("unbound string * bound string", unboundString, boundString),
                ("bound string * bound string", boundString, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.multiply(rhs)
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


// Multiplication

// [2026-05-07] : O*_001 : Multiply integer by integer SafePythonObject
// [2026-05-07] : O*_002 : Multiply integer by double SafePythonObject
// [2026-05-07] : O*_002 : Multiply double by double SafePythonObject
// [2026-05-07] : O*_002 : Multiply double by integer SafePythonObject
// [2026-05-07] : O*_001 : Multiply bool by integer SafePythonObject
// [2026-05-07] : O*_002 : Multiply bool by double SafePythonObject
// [2026-05-07] : O*_003 : Multiply string by string SafePythonObject
// [2026-05-07] : O*_004 : Multiply bool by bool SafePythonObject

// [2026-05-07] : O*_001 : Multiply integer by integer SafePythonObject unbound
// [2026-05-07] : O*_002 : Multiply integer by double SafePythonObject unbound
// [2026-05-07] : O*_002 : Multiply double by double SafePythonObject unbound
// [2026-05-07] : O*_002 : Multiply double by integer SafePythonObject unbound
// [2026-05-07] : O*_001 : Multiply bool by integer SafePythonObject unbound
// [2026-05-07] : O*_002 : Multiply bool by double SafePythonObject unbound
// [2026-05-07] : O*_003 : Multiply string by string SafePythonObject unbound
// [2026-05-07] : O*_004 : Multiply bool by bool SafePythonObject unbound

// [2026-05-07] : O*_010 : Multiply string by integer SafePythonObject error handling
// [2026-05-07] : O*_010 : Multiply string by double SafePythonObject error handling
// [2026-05-07] : O*_010 : Multiply string by bool SafePythonObject error handling
// [2026-05-07] : O*_010 : Multiply integer by string SafePythonObject error handling
// [2026-05-07] : O*_010 : Multiply double by string SafePythonObject error handling
// [2026-05-07] : O*_010 : Multiply bool by string SafePythonObject error handling

// [2026-05-07] : O*_005 : Multiply PythonObject by PythonObject
// [2026-05-07] : O*_005 : Multiply PythonObject by Int
// [2026-05-07] : O*_005 : Multiply PythonObject by Double
// [2026-05-07] : O*_005 : Multiply PythonObject by Bool
// [2026-05-07] : O*_005 : Multiply PythonObject by String
// [2026-05-07] : O*_006 : Multiply PythonObject error handling
