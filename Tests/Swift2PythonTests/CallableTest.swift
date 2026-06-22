//
//  CallableTest.swift
//  Swift2Python
//
//  Created by Ben White on 6/21/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Callable Tests", .serialized)
struct CallableTests {

    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }
    
    private func installCallableFixtures() async throws -> PythonObject {
        try await interpreter.runSimpleString(pythonCode: """
        def swift2python_no_args():
            return "ready"

        def swift2python_add(a, b):
            return a + b

        def swift2python_describe(name, punctuation=".", repeat=1):
            return (name + punctuation) * repeat

        def swift2python_raise():
            raise RuntimeError("call failed")

        class Swift2PythonCallableObject:
            def __call__(self, a, b, scale=1):
                return (a + b) * scale

        class Swift2PythonMethodFixture:
            def no_args(self):
                return "method-ready"

            def join(self, left, right, sep="-", repeat=1):
                return ((left + sep + right) * repeat)

            def fail(self):
                raise ValueError("method failed")

        swift2python_callable_object = Swift2PythonCallableObject()
        swift2python_method_fixture = Swift2PythonMethodFixture()
        """)
        return try await interpreter.getGlobals()
    }
    
    @Test("CALL_001: PythonObject direct call supports positional arguments")
    func pythonObjectDirectCallSupportsPositionalArguments() async throws {
        let globals = try await installCallableFixtures()
        let add = try await globals.getItem(key: "swift2python_add")
        
        let explicitResult = try await add.call(2, 3)
        let dynamicResult = try await add(4, 5)
        
        #expect(try await Int(explicitResult) == 5)
        #expect(try await Int(dynamicResult) == 9)
    }
    
    @Test("CALL_002: PythonObject direct call supports no arguments")
    func pythonObjectDirectCallSupportsNoArguments() async throws {
        let globals = try await installCallableFixtures()
        let noArgs = try await globals.getItem(key: "swift2python_no_args")
        
        let explicitResult = try await noArgs.call()
        let dynamicResult = try await noArgs()
        
        #expect(try await String(explicitResult) == "ready")
        #expect(try await String(dynamicResult) == "ready")
    }
    
    @Test("CALL_003: PythonObject direct call supports dictionary kwargs")
    func pythonObjectDirectCallSupportsDictionaryKwargs() async throws {
        let globals = try await installCallableFixtures()
        let describe = try await globals.getItem(key: "swift2python_describe")
        
        let result = try await describe.call(
            "Ada",
            kwargs: [
                "punctuation": "!",
                "repeat": 2
            ]
        )
        
        #expect(try await String(result) == "Ada!Ada!")
    }
    
    @Test("CALL_004: PythonObject direct call supports ordered kwargs")
    func pythonObjectDirectCallSupportsOrderedKwargs() async throws {
        let globals = try await installCallableFixtures()
        let describe = try await globals.getItem(key: "swift2python_describe")
        let kwargs: KeyValuePairs<String, any PendingPythonConvertible> = [
            "punctuation": "?",
            "repeat": 3
        ]
        
        let result = try await describe.call("Ada", kwargs: kwargs)
        
        #expect(try await String(result) == "Ada?Ada?Ada?")
    }
    
    @Test("CALL_005: PythonObject dynamic callable supports keyword syntax")
    func pythonObjectDynamicCallableSupportsKeywordSyntax() async throws {
        let globals = try await installCallableFixtures()
        let describe = try await globals.getItem(key: "swift2python_describe")
        
        let result = try await describe("Ada", punctuation: "?", repeat: 3)
        
        #expect(try await String(result) == "Ada?Ada?Ada?")
    }
    
    @Test("CALL_006: PythonObject dynamic callable supports Python objects with __call__")
    func pythonObjectDynamicCallableSupportsCallableObjects() async throws {
        let globals = try await installCallableFixtures()
        let callableObject = try await globals.getItem(key: "swift2python_callable_object")
        
        let explicitResult = try await callableObject.call(2, 3, kwargs: ["scale": 4])
        let dynamicResult = try await callableObject(2, 3, scale: 5)
        
        #expect(try await Int(explicitResult) == 20)
        #expect(try await Int(dynamicResult) == 25)
    }
    
    @Test("CALL_007: PythonObject dynamic member call supports methods")
    func pythonObjectDynamicMemberCallSupportsMethods() async throws {
        let globals = try await installCallableFixtures()
        let fixture = try await globals.getItem(key: "swift2python_method_fixture")
        
        let noArgResult = try await fixture.no_args()
        let explicitResult = try await fixture.join.call("left", "right", kwargs: ["sep": ":", "repeat": 2])
        let dynamicResult = try await fixture.join("left", "right", sep: "/", repeat: 3)
        
        #expect(try await String(noArgResult) == "method-ready")
        #expect(try await String(explicitResult) == "left:rightleft:right")
        #expect(try await String(dynamicResult) == "left/rightleft/rightleft/right")
    }
    
    @Test("CALL_008: PythonObject direct call propagates Python exceptions")
    func pythonObjectDirectCallPropagatesPythonExceptions() async throws {
        let globals = try await installCallableFixtures()
        let failing = try await globals.getItem(key: "swift2python_raise")
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await failing.call()
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for failing Python callable, got \(String(describing: thrownError))")
        }
    }
    
    @Test("CALL_009: PythonObject dynamic member call propagates Python exceptions")
    func pythonObjectDynamicMemberCallPropagatesPythonExceptions() async throws {
        let globals = try await installCallableFixtures()
        let fixture = try await globals.getItem(key: "swift2python_method_fixture")
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await fixture.fail()
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for failing Python method, got \(String(describing: thrownError))")
        }
    }
    
    @Test("CALL_010: PythonObject dynamic callable rejects duplicate keyword arguments")
    func pythonObjectDynamicCallableRejectsDuplicateKeywordArguments() async throws {
        let globals = try await installCallableFixtures()
        let describe = try await globals.getItem(key: "swift2python_describe")
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await describe.dynamicallyCall(withKeywordArguments: [
                "name": "Ada",
                "punctuation": "!",
                "punctuation": "?"
            ])
        }
        
        if case .valueError = thrownError {
            // expected
        } else {
            Issue.record("Expected .valueError for duplicate keyword arguments, got \(String(describing: thrownError))")
        }
    }
    
    @Test("CALL_011: PythonObject dynamic callable rejects positional after keyword")
    func pythonObjectDynamicCallableRejectsPositionalAfterKeyword() async throws {
        let globals = try await installCallableFixtures()
        let describe = try await globals.getItem(key: "swift2python_describe")
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await describe.dynamicallyCall(withKeywordArguments: [
                "name": "Ada",
                "": "late"
            ])
        }
        
        if case .valueError = thrownError {
            // expected
        } else {
            Issue.record("Expected .valueError for positional-after-keyword arguments, got \(String(describing: thrownError))")
        }
    }
    
    @Test("CALL_012: SafePythonObject call supports positional and no-argument calls")
    func safePythonObjectCallSupportsPositionalAndNoArgumentCalls() async throws {
        _ = try await installCallableFixtures()
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let add = isolatedInterpreter.globals["swift2python_add"]
            let noArgs = isolatedInterpreter.globals["swift2python_no_args"]
            
            let explicitResult = try add.call(2, 3)
            let dynamicResult = try add(4, 5)
            let noArgResult = try noArgs()
            
            #expect(try Int(explicitResult) == 5)
            #expect(try Int(dynamicResult) == 9)
            #expect(try String(noArgResult) == "ready")
        }
    }
    
    @Test("CALL_013: SafePythonObject call supports dictionary and ordered kwargs")
    func safePythonObjectCallSupportsDictionaryAndOrderedKwargs() async throws {
        _ = try await installCallableFixtures()
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let describe = isolatedInterpreter.globals["swift2python_describe"]
            let kwargs: KeyValuePairs<String, any SafePythonConvertible> = [
                "punctuation": "?",
                "repeat": 3
            ]
            
            let dictionaryResult = try describe.call(
                "Ada",
                kwargs: [
                    "punctuation": "!",
                    "repeat": 2
                ]
            )
            let orderedResult = try describe.call("Ada", kwargs: kwargs)
            let dynamicResult = try describe("Ada", punctuation: ".", repeat: 2)
            
            #expect(try String(dictionaryResult) == "Ada!Ada!")
            #expect(try String(orderedResult) == "Ada?Ada?Ada?")
            #expect(try String(dynamicResult) == "Ada.Ada.")
        }
    }
    
    @Test("CALL_014: SafePythonObject dynamic callable supports Python objects with __call__")
    func safePythonObjectDynamicCallableSupportsCallableObjects() async throws {
        _ = try await installCallableFixtures()
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let callableObject = isolatedInterpreter.globals["swift2python_callable_object"]
            
            let explicitResult = try callableObject.call(2, 3, kwargs: ["scale": 4])
            let dynamicResult = try callableObject(2, 3, scale: 5)
            
            #expect(try Int(explicitResult) == 20)
            #expect(try Int(dynamicResult) == 25)
        }
    }
    
    @Test("CALL_015: SafePythonObject dynamic member call supports methods")
    func safePythonObjectDynamicMemberCallSupportsMethods() async throws {
        _ = try await installCallableFixtures()
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let fixture = isolatedInterpreter.globals["swift2python_method_fixture"]
            
            let noArgResult = try fixture.no_args()
            let explicitResult = try fixture.join.call("left", "right", kwargs: ["sep": ":", "repeat": 2])
            let dynamicResult = try fixture.join("left", "right", sep: "/", repeat: 3)
            
            #expect(try String(noArgResult) == "method-ready")
            #expect(try String(explicitResult) == "left:rightleft:right")
            #expect(try String(dynamicResult) == "left/rightleft/rightleft/right")
        }
    }
    
    @Test("CALL_016: SafePythonObject call propagates Python exceptions")
    func safePythonObjectCallPropagatesPythonExceptions() async throws {
        _ = try await installCallableFixtures()
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let failing = isolatedInterpreter.globals["swift2python_raise"]
            let fixture = isolatedInterpreter.globals["swift2python_method_fixture"]
            
            let functionError = #expect(throws: PythonError.self) {
                _ = try failing.call()
            }
            let methodError = #expect(throws: PythonError.self) {
                _ = try fixture.fail()
            }
            
            if case .safePythonException = functionError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for failing safe callable, got \(String(describing: functionError))")
            }
            
            if case .safePythonException = methodError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for failing safe method, got \(String(describing: methodError))")
            }
        }
    }
    
    @Test("CALL_017: SafePythonObject dynamic callable rejects duplicate keyword arguments")
    func safePythonObjectDynamicCallableRejectsDuplicateKeywordArguments() async throws {
        _ = try await installCallableFixtures()
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let describe = isolatedInterpreter.globals["swift2python_describe"]
            
            let thrownError = #expect(throws: PythonError.self) {
                _ = try describe.dynamicallyCall(withKeywordArguments: [
                    "name": "Ada",
                    "punctuation": "!",
                    "punctuation": "?"
                ])
            }
            
            if case .valueError = thrownError {
                // expected
            } else {
                Issue.record("Expected .valueError for duplicate safe keyword arguments, got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("CALL_018: SafePythonObject dynamic callable rejects positional after keyword")
    func safePythonObjectDynamicCallableRejectsPositionalAfterKeyword() async throws {
        _ = try await installCallableFixtures()
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let describe = isolatedInterpreter.globals["swift2python_describe"]
            
            let thrownError = #expect(throws: PythonError.self) {
                _ = try describe.dynamicallyCall(withKeywordArguments: [
                    "name": "Ada",
                    "": "late"
                ])
            }
            
            if case .valueError = thrownError {
                // expected
            } else {
                Issue.record("Expected .valueError for safe positional-after-keyword arguments, got \(String(describing: thrownError))")
            }
        }
    }
}
