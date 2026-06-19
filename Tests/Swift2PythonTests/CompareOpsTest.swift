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
    // MARK: O<_xxx Greater Than Tests
    // MARK: O<=_xxx Greater Than or Equal Tests
    // MARK: O==_xxx Equality Tests
    // MARK: O!=_xxx Not Equals Tests
}
