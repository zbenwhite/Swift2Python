//
//  CompareOpsTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/18/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Comparison Operations Tests")
struct CompareOpsTests {

    private static let setupLogging: Void = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
    }()
    
    private static let sharedInterpreterTask: Task<PythonInterpreter, Error> = Task {
        _ = setupLogging
        
        // Initialize the runtime
        let runtime = PythonRuntime.shared
        try await runtime.initialize()
        
        // Create and return the single shared interpreter
        return try await PythonInterpreter()
    }
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }
    
    // MARK: O<_xxx Less Than Tests
    
    @Test("O<_001: Less Than Operator Integer")
    func lessThanOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundSmall = try 4.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundLarge = try 9.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundSmall: PythonInterpreter.SafePythonObject = 4
            let unboundLarge: PythonInterpreter.SafePythonObject = 9
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boolCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound small < bound large", boundSmall, boundLarge, true),
                ("bound large < bound small", boundLarge, boundSmall, false),
                ("bound small < unbound large", boundSmall, unboundLarge, true),
                ("unbound small < bound large", unboundSmall, boundLarge, true),
                ("unbound large < unbound small", unboundLarge, unboundSmall, false),
                ("unbound false < bound true", unboundFalse, boundTrue, true),
                ("bound true < unbound small", boundTrue, unboundSmall, true)
            ]
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: Bool = lhs < rhs
                #expect(result == expected, Comment(rawValue: description))
            }
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: PythonInterpreter.SafePythonObject = lhs < rhs
                #expect(try Bool(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O<_002: Less Than Operator Double")
    func lessThanOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 4.5
            let unboundInt: PythonInterpreter.SafePythonObject = 5
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound double < bound int", boundDouble, boundInt, true),
                ("bound int < bound double", boundInt, boundDouble, false),
                ("unbound double < unbound int", unboundDouble, unboundInt, true),
                ("unbound int < unbound double", unboundInt, unboundDouble, false),
                ("unbound true < bound double", unboundTrue, boundDouble, true),
                ("bound double < unbound true", boundDouble, unboundTrue, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs < rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O<_003: Less Than Operator String")
    func lessThanOperatorString() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundA = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundB = try "abd".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundA: PythonInterpreter.SafePythonObject = "abc"
            let unboundB: PythonInterpreter.SafePythonObject = "abd"
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound string < bound string", boundA, boundB, true),
                ("bound string reverse", boundB, boundA, false),
                ("bound string < unbound string", boundA, unboundB, true),
                ("unbound string < bound string", unboundA, boundB, true),
                ("unbound string reverse", unboundB, unboundA, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs < rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O<_005: PythonObject async less than")
    func lessThanPythonObject() async throws {
        let smallInt = try await 4.toPythonObject(interpreter: interpreter)
        #expect(try await smallInt.lessThan(9))
        #expect(try await smallInt.lessThan(4) == false)
        
        let doubleObject = try await 2.5.toPythonObject(interpreter: interpreter)
        #expect(try await doubleObject.lessThan(3))
        
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        #expect(try await stringObject.lessThan("abd"))
        
        let boolObject = try await false.toPythonObject(interpreter: interpreter)
        #expect(try await boolObject.lessThan(true))
    }
    
    @Test("O<_006: PythonObject async less than error checking")
    func lessThanPythonObjectError() async throws {
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await stringObject.lessThan(1)
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject less-than error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O<_009: Less Than deferred Int and Double exactness")
    func lessThanDeferredIntDoubleExactness() throws {
        let maxInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
        let maxIntRoundedToDouble = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int.max))
        let doublePastExactIntegerPrecision = PythonInterpreter.SafePythonObject(floatLiteral: 9_007_199_254_740_992.0)
        let intPastExactIntegerPrecision = PythonInterpreter.SafePythonObject(integerLiteral: 9_007_199_254_740_993)
        let nanValue = PythonInterpreter.SafePythonObject(floatLiteral: Double.nan)
        
        #expect(try Bool(maxInt.lessThan(maxIntRoundedToDouble)) == true)
        #expect(try Bool(maxIntRoundedToDouble.lessThan(maxInt)) == false)
        #expect(try Bool(doublePastExactIntegerPrecision.lessThan(intPastExactIntegerPrecision)) == true)
        #expect(try Bool(intPastExactIntegerPrecision.lessThan(doublePastExactIntegerPrecision)) == false)
        let one = PythonInterpreter.SafePythonObject(integerLiteral: 1)
        #expect(try Bool(nanValue.lessThan(one)) == false)
        #expect(try Bool(maxInt.lessThan(nanValue)) == false)
    }
    
    @Test("O<_010: SafePythonObject less than error checking")
    func safeLessThanErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundInt: PythonInterpreter.SafePythonObject = 1
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound string < unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound int < unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string < unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound bool < unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.lessThan(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "less than", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound string < bound int", boundString, boundInt),
                ("bound string < unbound int", boundString, unboundInt),
                ("unbound string < bound int", unboundString, boundInt),
                ("bound int < bound string", boundInt, boundString),
                ("bound int < unbound string", boundInt, unboundString),
                ("unbound int < bound string", unboundInt, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.lessThan(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
        }
    }
    
    // MARK: O<=_xxx Less Than or Equal Tests
    
    @Test("O<=_001: Less Than Or Equal Operator Integer")
    func lessThanOrEqualOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundSmall = try 4.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundLarge = try 9.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundSmall: PythonInterpreter.SafePythonObject = 4
            let unboundLarge: PythonInterpreter.SafePythonObject = 9
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boolCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound small <= bound large", boundSmall, boundLarge, true),
                ("bound small <= bound small", boundSmall, boundSmall, true),
                ("bound large <= bound small", boundLarge, boundSmall, false),
                ("bound small <= unbound large", boundSmall, unboundLarge, true),
                ("unbound small <= bound large", unboundSmall, boundLarge, true),
                ("unbound large <= unbound small", unboundLarge, unboundSmall, false),
                ("unbound false <= bound true", unboundFalse, boundTrue, true),
                ("bound true <= unbound false", boundTrue, unboundFalse, false)
            ]
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: Bool = lhs <= rhs
                #expect(result == expected, Comment(rawValue: description))
            }
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: PythonInterpreter.SafePythonObject = lhs <= rhs
                #expect(try Bool(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O<=_002: Less Than Or Equal Operator Double")
    func lessThanOrEqualOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 2.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 5.0
            let unboundInt: PythonInterpreter.SafePythonObject = 5
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound double <= bound int", boundDouble, boundInt, true),
                ("bound int <= bound double", boundInt, boundDouble, false),
                ("unbound double <= unbound int", unboundDouble, unboundInt, true),
                ("unbound int <= unbound double", unboundInt, unboundDouble, true),
                ("unbound true <= bound double", unboundTrue, boundDouble, true),
                ("bound double <= unbound true", boundDouble, unboundTrue, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs <= rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O<=_003: Less Than Or Equal Operator String")
    func lessThanOrEqualOperatorString() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundA = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundB = try "abd".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundA: PythonInterpreter.SafePythonObject = "abc"
            let unboundB: PythonInterpreter.SafePythonObject = "abd"
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound string <= bound string", boundA, boundB, true),
                ("bound string equal", boundA, boundA, true),
                ("bound string reverse", boundB, boundA, false),
                ("bound string <= unbound string", boundA, unboundB, true),
                ("unbound string <= bound string", unboundA, boundB, true),
                ("unbound string reverse", unboundB, unboundA, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs <= rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O<=_005: PythonObject async less than or equal")
    func lessThanOrEqualPythonObject() async throws {
        let smallInt = try await 4.toPythonObject(interpreter: interpreter)
        #expect(try await smallInt.lessThanOrEqual(9))
        #expect(try await smallInt.lessThanOrEqual(4))
        #expect(try await smallInt.lessThanOrEqual(3) == false)
        
        let doubleObject = try await 2.5.toPythonObject(interpreter: interpreter)
        #expect(try await doubleObject.lessThanOrEqual(3))
        
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        #expect(try await stringObject.lessThanOrEqual("abd"))
        #expect(try await stringObject.lessThanOrEqual("abc"))
        
        let boolObject = try await false.toPythonObject(interpreter: interpreter)
        #expect(try await boolObject.lessThanOrEqual(false))
        #expect(try await boolObject.lessThanOrEqual(true))
    }
    
    @Test("O<=_006: PythonObject async less than or equal error checking")
    func lessThanOrEqualPythonObjectError() async throws {
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await stringObject.lessThanOrEqual(1)
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject less-than-or-equal error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O<=_009: Less Than Or Equal deferred Int and Double exactness")
    func lessThanOrEqualDeferredIntDoubleExactness() throws {
        let maxInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
        let maxIntRoundedToDouble = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int.max))
        let doublePastExactIntegerPrecision = PythonInterpreter.SafePythonObject(floatLiteral: 9_007_199_254_740_992.0)
        let intPastExactIntegerPrecision = PythonInterpreter.SafePythonObject(integerLiteral: 9_007_199_254_740_993)
        let nanValue = PythonInterpreter.SafePythonObject(floatLiteral: Double.nan)
        
        #expect(try Bool(maxInt.lessThanOrEqual(maxIntRoundedToDouble)) == true)
        #expect(try Bool(maxIntRoundedToDouble.lessThanOrEqual(maxInt)) == false)
        #expect(try Bool(doublePastExactIntegerPrecision.lessThanOrEqual(intPastExactIntegerPrecision)) == true)
        #expect(try Bool(intPastExactIntegerPrecision.lessThanOrEqual(doublePastExactIntegerPrecision)) == false)
        let one = PythonInterpreter.SafePythonObject(integerLiteral: 1)
        #expect(try Bool(nanValue.lessThanOrEqual(one)) == false)
        #expect(try Bool(maxInt.lessThanOrEqual(nanValue)) == false)
    }
    
    @Test("O<=_010: SafePythonObject less than or equal error checking")
    func safeLessThanOrEqualErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundInt: PythonInterpreter.SafePythonObject = 1
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound string <= unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound int <= unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string <= unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound bool <= unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.lessThanOrEqual(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "less than or equal", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound string <= bound int", boundString, boundInt),
                ("bound string <= unbound int", boundString, unboundInt),
                ("unbound string <= bound int", unboundString, boundInt),
                ("bound int <= bound string", boundInt, boundString),
                ("bound int <= unbound string", boundInt, unboundString),
                ("unbound int <= bound string", unboundInt, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.lessThanOrEqual(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
        }
    }
    
    // MARK: O>_xxx Greater Than Tests
    
    @Test("O>_001: Greater Than Operator Integer")
    func greaterThanOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundSmall = try 4.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundLarge = try 9.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundSmall: PythonInterpreter.SafePythonObject = 4
            let unboundLarge: PythonInterpreter.SafePythonObject = 9
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boolCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound large > bound small", boundLarge, boundSmall, true),
                ("bound small > bound large", boundSmall, boundLarge, false),
                ("bound large > unbound small", boundLarge, unboundSmall, true),
                ("unbound large > bound small", unboundLarge, boundSmall, true),
                ("unbound small > unbound large", unboundSmall, unboundLarge, false),
                ("bound true > unbound false", boundTrue, unboundFalse, true),
                ("unbound false > bound true", unboundFalse, boundTrue, false)
            ]
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: Bool = lhs > rhs
                #expect(result == expected, Comment(rawValue: description))
            }
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: PythonInterpreter.SafePythonObject = lhs > rhs
                #expect(try Bool(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O>_002: Greater Than Operator Double")
    func greaterThanOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 3.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 5.5
            let unboundInt: PythonInterpreter.SafePythonObject = 5
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound double > bound int", boundDouble, boundInt, true),
                ("bound int > bound double", boundInt, boundDouble, false),
                ("unbound double > unbound int", unboundDouble, unboundInt, true),
                ("unbound int > unbound double", unboundInt, unboundDouble, false),
                ("bound double > unbound true", boundDouble, unboundTrue, true),
                ("unbound true > bound double", unboundTrue, boundDouble, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs > rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O>_003: Greater Than Operator String")
    func greaterThanOperatorString() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundA = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundB = try "abd".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundA: PythonInterpreter.SafePythonObject = "abc"
            let unboundB: PythonInterpreter.SafePythonObject = "abd"
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound string > bound string", boundB, boundA, true),
                ("bound string reverse", boundA, boundB, false),
                ("bound string > unbound string", boundB, unboundA, true),
                ("unbound string > bound string", unboundB, boundA, true),
                ("unbound string reverse", unboundA, unboundB, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs > rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O>_005: PythonObject async greater than")
    func greaterThanPythonObject() async throws {
        let largeInt = try await 9.toPythonObject(interpreter: interpreter)
        #expect(try await largeInt.greaterThan(4))
        #expect(try await largeInt.greaterThan(9) == false)
        
        let doubleObject = try await 3.5.toPythonObject(interpreter: interpreter)
        #expect(try await doubleObject.greaterThan(3))
        
        let stringObject = try await "abd".toPythonObject(interpreter: interpreter)
        #expect(try await stringObject.greaterThan("abc"))
        
        let boolObject = try await true.toPythonObject(interpreter: interpreter)
        #expect(try await boolObject.greaterThan(false))
    }
    
    @Test("O>_006: PythonObject async greater than error checking")
    func greaterThanPythonObjectError() async throws {
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await stringObject.greaterThan(1)
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject greater-than error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O>_009: Greater Than deferred Int and Double exactness")
    func greaterThanDeferredIntDoubleExactness() throws {
        let maxInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
        let maxIntRoundedToDouble = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int.max))
        let doublePastExactIntegerPrecision = PythonInterpreter.SafePythonObject(floatLiteral: 9_007_199_254_740_992.0)
        let intPastExactIntegerPrecision = PythonInterpreter.SafePythonObject(integerLiteral: 9_007_199_254_740_993)
        let nanValue = PythonInterpreter.SafePythonObject(floatLiteral: Double.nan)
        
        #expect(try Bool(maxInt.greaterThan(maxIntRoundedToDouble)) == false)
        #expect(try Bool(maxIntRoundedToDouble.greaterThan(maxInt)) == true)
        #expect(try Bool(doublePastExactIntegerPrecision.greaterThan(intPastExactIntegerPrecision)) == false)
        #expect(try Bool(intPastExactIntegerPrecision.greaterThan(doublePastExactIntegerPrecision)) == true)
        let one = PythonInterpreter.SafePythonObject(integerLiteral: 1)
        #expect(try Bool(nanValue.greaterThan(one)) == false)
        #expect(try Bool(maxInt.greaterThan(nanValue)) == false)
    }
    
    @Test("O>_010: SafePythonObject greater than error checking")
    func safeGreaterThanErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundInt: PythonInterpreter.SafePythonObject = 1
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound string > unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound int > unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string > unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound bool > unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.greaterThan(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "greater than", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound string > bound int", boundString, boundInt),
                ("bound string > unbound int", boundString, unboundInt),
                ("unbound string > bound int", unboundString, boundInt),
                ("bound int > bound string", boundInt, boundString),
                ("bound int > unbound string", boundInt, unboundString),
                ("unbound int > bound string", unboundInt, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.greaterThan(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
        }
    }
    
    // MARK: O>=_xxx Greater Than or Equal Tests
    
    @Test("O>=_001: Greater Than Or Equal Operator Integer")
    func greaterThanOrEqualOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundSmall = try 4.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundLarge = try 9.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundSmall: PythonInterpreter.SafePythonObject = 4
            let unboundLarge: PythonInterpreter.SafePythonObject = 9
            let boundTrue = try true.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundFalse: PythonInterpreter.SafePythonObject = false
            
            let boolCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound large >= bound small", boundLarge, boundSmall, true),
                ("bound small >= bound small", boundSmall, boundSmall, true),
                ("bound small >= bound large", boundSmall, boundLarge, false),
                ("bound large >= unbound small", boundLarge, unboundSmall, true),
                ("unbound large >= bound small", unboundLarge, boundSmall, true),
                ("unbound small >= unbound large", unboundSmall, unboundLarge, false),
                ("bound true >= unbound false", boundTrue, unboundFalse, true),
                ("unbound false >= bound true", unboundFalse, boundTrue, false)
            ]
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: Bool = lhs >= rhs
                #expect(result == expected, Comment(rawValue: description))
            }
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: PythonInterpreter.SafePythonObject = lhs >= rhs
                #expect(try Bool(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O>=_002: Greater Than Or Equal Operator Double")
    func greaterThanOrEqualOperatorDouble() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundDouble = try 3.5.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 3.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundDouble: PythonInterpreter.SafePythonObject = 5.0
            let unboundInt: PythonInterpreter.SafePythonObject = 5
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound double >= bound int", boundDouble, boundInt, true),
                ("bound int >= bound double", boundInt, boundDouble, false),
                ("unbound double >= unbound int", unboundDouble, unboundInt, true),
                ("unbound int >= unbound double", unboundInt, unboundDouble, true),
                ("bound double >= unbound true", boundDouble, unboundTrue, true),
                ("unbound true >= bound double", unboundTrue, boundDouble, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs >= rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O>=_003: Greater Than Or Equal Operator String")
    func greaterThanOrEqualOperatorString() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundA = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundB = try "abd".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundA: PythonInterpreter.SafePythonObject = "abc"
            let unboundB: PythonInterpreter.SafePythonObject = "abd"
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound string >= bound string", boundB, boundA, true),
                ("bound string equal", boundA, boundA, true),
                ("bound string reverse", boundA, boundB, false),
                ("bound string >= unbound string", boundB, unboundA, true),
                ("unbound string >= bound string", unboundB, boundA, true),
                ("unbound string reverse", unboundA, unboundB, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs >= rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O>=_005: PythonObject async greater than or equal")
    func greaterThanOrEqualPythonObject() async throws {
        let largeInt = try await 9.toPythonObject(interpreter: interpreter)
        #expect(try await largeInt.greaterThanOrEqual(4))
        #expect(try await largeInt.greaterThanOrEqual(9))
        #expect(try await largeInt.greaterThanOrEqual(10) == false)
        
        let doubleObject = try await 3.5.toPythonObject(interpreter: interpreter)
        #expect(try await doubleObject.greaterThanOrEqual(3))
        
        let stringObject = try await "abd".toPythonObject(interpreter: interpreter)
        #expect(try await stringObject.greaterThanOrEqual("abc"))
        #expect(try await stringObject.greaterThanOrEqual("abd"))
        
        let boolObject = try await true.toPythonObject(interpreter: interpreter)
        #expect(try await boolObject.greaterThanOrEqual(true))
        #expect(try await boolObject.greaterThanOrEqual(false))
    }
    
    @Test("O>=_006: PythonObject async greater than or equal error checking")
    func greaterThanOrEqualPythonObjectError() async throws {
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await stringObject.greaterThanOrEqual(1)
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for PythonObject greater-than-or-equal error, but got \(String(describing: thrownError))")
        }
    }
    
    @Test("O>=_009: Greater Than Or Equal deferred Int and Double exactness")
    func greaterThanOrEqualDeferredIntDoubleExactness() throws {
        let maxInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
        let maxIntRoundedToDouble = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int.max))
        let doublePastExactIntegerPrecision = PythonInterpreter.SafePythonObject(floatLiteral: 9_007_199_254_740_992.0)
        let intPastExactIntegerPrecision = PythonInterpreter.SafePythonObject(integerLiteral: 9_007_199_254_740_993)
        let nanValue = PythonInterpreter.SafePythonObject(floatLiteral: Double.nan)
        
        #expect(try Bool(maxInt.greaterThanOrEqual(maxIntRoundedToDouble)) == false)
        #expect(try Bool(maxIntRoundedToDouble.greaterThanOrEqual(maxInt)) == true)
        #expect(try Bool(doublePastExactIntegerPrecision.greaterThanOrEqual(intPastExactIntegerPrecision)) == false)
        #expect(try Bool(intPastExactIntegerPrecision.greaterThanOrEqual(doublePastExactIntegerPrecision)) == true)
        let one = PythonInterpreter.SafePythonObject(integerLiteral: 1)
        #expect(try Bool(nanValue.greaterThanOrEqual(one)) == false)
        #expect(try Bool(maxInt.greaterThanOrEqual(nanValue)) == false)
    }
    
    @Test("O>=_010: SafePythonObject greater than or equal error checking")
    func safeGreaterThanOrEqualErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundString = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundInt = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundString: PythonInterpreter.SafePythonObject = "abc"
            let unboundInt: PythonInterpreter.SafePythonObject = 1
            let unboundDouble: PythonInterpreter.SafePythonObject = 1.5
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let unboundTypeErrorCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, String, String)] = [
                ("unbound string >= unbound int", unboundString, unboundInt, "String", "Int"),
                ("unbound int >= unbound string", unboundInt, unboundString, "Int", "String"),
                ("unbound string >= unbound double", unboundString, unboundDouble, "String", "Double"),
                ("unbound bool >= unbound string", unboundBool, unboundString, "Bool", "String")
            ]
            
            for (description, lhs, rhs, expectedType1, expectedType2) in unboundTypeErrorCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.greaterThanOrEqual(rhs)
                }
                
                if case let .typeError(operation, opType1, opType2) = thrownError {
                    #expect(operation == "greater than or equal", Comment(rawValue: description))
                    #expect(opType1 == expectedType1, Comment(rawValue: description))
                    #expect(opType2 == expectedType2, Comment(rawValue: description))
                } else {
                    Issue.record("Expected .typeError for \(description), but got \(String(describing: thrownError))")
                }
            }
            
            let boundExceptionCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject)] = [
                ("bound string >= bound int", boundString, boundInt),
                ("bound string >= unbound int", boundString, unboundInt),
                ("unbound string >= bound int", unboundString, boundInt),
                ("bound int >= bound string", boundInt, boundString),
                ("bound int >= unbound string", boundInt, unboundString),
                ("unbound int >= bound string", unboundInt, boundString)
            ]
            
            for (description, lhs, rhs) in boundExceptionCases {
                let thrownError = #expect(throws: PythonError.self, Comment(rawValue: description)) {
                    _ = try lhs.greaterThanOrEqual(rhs)
                }
                
                if case .safePythonException = thrownError {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException for \(description), but got \(String(describing: thrownError))")
                }
            }
        }
    }
    
    // MARK: O==_xxx Equality Tests
    
    @Test("O==_001: Equality Operator Integer")
    func equalityOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundOne = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundOtherOne = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundTwo = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundOne: PythonInterpreter.SafePythonObject = 1
            let unboundTwo: PythonInterpreter.SafePythonObject = 2
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            let boolCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound one == bound one", boundOne, boundOtherOne, true),
                ("bound one == bound two", boundOne, boundTwo, false),
                ("bound one == unbound one", boundOne, unboundOne, true),
                ("unbound one == bound one", unboundOne, boundOne, true),
                ("unbound one == unbound two", unboundOne, unboundTwo, false),
                ("unbound true == bound one", unboundTrue, boundOne, true)
            ]
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: Bool = lhs == rhs
                #expect(result == expected, Comment(rawValue: description))
            }
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: PythonInterpreter.SafePythonObject = lhs == rhs
                #expect(try Bool(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O==_002: Equality Operator String and mixed types")
    func equalityOperatorStringAndMixedTypes() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundA = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundOtherA = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundB = try "abd".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundA: PythonInterpreter.SafePythonObject = "abc"
            let unboundInt: PythonInterpreter.SafePythonObject = 1
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound string == bound same string", boundA, boundOtherA, true),
                ("bound string == bound different string", boundA, boundB, false),
                ("bound string == unbound same string", boundA, unboundA, true),
                ("unbound string == bound same string", unboundA, boundA, true),
                ("unbound string == unbound int", unboundA, unboundInt, false),
                ("unbound bool == unbound int", unboundBool, unboundInt, true)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs == rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O==_005: PythonObject async equality")
    func equalityPythonObject() async throws {
        let intObject = try await 1.toPythonObject(interpreter: interpreter)
        #expect(try await intObject.equal(1))
        #expect(try await intObject.equal(2) == false)
        #expect(try await intObject.equal(true))
        
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        #expect(try await stringObject.equal("abc"))
        #expect(try await stringObject.equal(1) == false)
    }
    
    @Test("O==_009: Equality deferred Int and Double exactness")
    func equalityDeferredIntDoubleExactness() throws {
        let maxInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
        let maxIntRoundedToDouble = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int.max))
        let doublePastExactIntegerPrecision = PythonInterpreter.SafePythonObject(floatLiteral: 9_007_199_254_740_992.0)
        let intPastExactIntegerPrecision = PythonInterpreter.SafePythonObject(integerLiteral: 9_007_199_254_740_993)
        let nanValue = PythonInterpreter.SafePythonObject(floatLiteral: Double.nan)
        let one = PythonInterpreter.SafePythonObject(integerLiteral: 1)
        
        #expect((maxInt == maxIntRoundedToDouble) == false)
        #expect((maxIntRoundedToDouble == maxInt) == false)
        #expect((doublePastExactIntegerPrecision == intPastExactIntegerPrecision) == false)
        #expect((intPastExactIntegerPrecision == doublePastExactIntegerPrecision) == false)
        #expect((nanValue == one) == false)
        #expect((nanValue == nanValue) == false)
    }
    
    // MARK: O!=_xxx Not Equal Tests
    
    @Test("O!=_001: Not Equal Operator Integer")
    func notEqualOperatorInteger() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundOne = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundOtherOne = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
            let boundTwo = try 2.toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundOne: PythonInterpreter.SafePythonObject = 1
            let unboundTwo: PythonInterpreter.SafePythonObject = 2
            let unboundTrue: PythonInterpreter.SafePythonObject = true
            
            let boolCases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound one != bound one", boundOne, boundOtherOne, false),
                ("bound one != bound two", boundOne, boundTwo, true),
                ("bound one != unbound one", boundOne, unboundOne, false),
                ("unbound one != bound one", unboundOne, boundOne, false),
                ("unbound one != unbound two", unboundOne, unboundTwo, true),
                ("unbound true != bound one", unboundTrue, boundOne, false)
            ]
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: Bool = lhs != rhs
                #expect(result == expected, Comment(rawValue: description))
            }
            
            for (description, lhs, rhs, expected) in boolCases {
                let result: PythonInterpreter.SafePythonObject = lhs != rhs
                #expect(try Bool(result) == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O!=_002: Not Equal Operator String and mixed types")
    func notEqualOperatorStringAndMixedTypes() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boundA = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundOtherA = try "abc".toSafePythonObject(interpreter: isolatedInterpreter)
            let boundB = try "abd".toSafePythonObject(interpreter: isolatedInterpreter)
            let unboundA: PythonInterpreter.SafePythonObject = "abc"
            let unboundInt: PythonInterpreter.SafePythonObject = 1
            let unboundBool: PythonInterpreter.SafePythonObject = true
            
            let cases: [(String, PythonInterpreter.SafePythonObject, PythonInterpreter.SafePythonObject, Bool)] = [
                ("bound string != bound same string", boundA, boundOtherA, false),
                ("bound string != bound different string", boundA, boundB, true),
                ("bound string != unbound same string", boundA, unboundA, false),
                ("unbound string != bound same string", unboundA, boundA, false),
                ("unbound string != unbound int", unboundA, unboundInt, true),
                ("unbound bool != unbound int", unboundBool, unboundInt, false)
            ]
            
            for (description, lhs, rhs, expected) in cases {
                let result: Bool = lhs != rhs
                #expect(result == expected, Comment(rawValue: description))
            }
        }
    }
    
    @Test("O!=_005: PythonObject async not equal")
    func notEqualPythonObject() async throws {
        let intObject = try await 1.toPythonObject(interpreter: interpreter)
        #expect(try await intObject.notEqual(1) == false)
        #expect(try await intObject.notEqual(2))
        #expect(try await intObject.notEqual(true) == false)
        
        let stringObject = try await "abc".toPythonObject(interpreter: interpreter)
        #expect(try await stringObject.notEqual("abc") == false)
        #expect(try await stringObject.notEqual(1))
    }
    
    @Test("O!=_009: Not Equal deferred Int and Double exactness")
    func notEqualDeferredIntDoubleExactness() throws {
        let maxInt = PythonInterpreter.SafePythonObject(integerLiteral: Int.max)
        let maxIntRoundedToDouble = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int.max))
        let doublePastExactIntegerPrecision = PythonInterpreter.SafePythonObject(floatLiteral: 9_007_199_254_740_992.0)
        let intPastExactIntegerPrecision = PythonInterpreter.SafePythonObject(integerLiteral: 9_007_199_254_740_993)
        let nanValue = PythonInterpreter.SafePythonObject(floatLiteral: Double.nan)
        let one = PythonInterpreter.SafePythonObject(integerLiteral: 1)
        
        #expect(maxInt != maxIntRoundedToDouble)
        #expect(maxIntRoundedToDouble != maxInt)
        #expect(doublePastExactIntegerPrecision != intPastExactIntegerPrecision)
        #expect(intPastExactIntegerPrecision != doublePastExactIntegerPrecision)
        #expect(nanValue != one)
        #expect(nanValue != nanValue)
    }
}
