//
//  LogicalTest.swift
//  Swift2Python
//

import Testing
@testable import Swift2Python

@Suite("Logical Operations Tests")
struct LogicalTests {

    private static let sharedInterpreterTask: Task<PythonInterpreter, Error> = Task {
        let runtime = PythonRuntime.shared
        try await runtime.initialize()
        return try await PythonInterpreter()
    }

    let interpreter: PythonInterpreter

    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }

    @Test("LOG_001: Deferred SafePythonObject truthiness")
    func deferredSafePythonObjectTruthiness() async throws {
        try await interpreter.withIsolatedContext { _ in
            let cases: [(PythonInterpreter.SafePythonObject, Bool)] = [
                (true, true),
                (false, false),
                (42, true),
                (0, false),
                (-1.25, true),
                (0.0, false),
                ("python", true),
                ("", false)
            ]

            for (value, expected) in cases {
                let isTrue = try value.isTrue()
                let isNotTrue = try value.isNotTrue()
                #expect(isTrue == expected)
                #expect(isNotTrue == !expected)
            }
        }
    }

    @Test("LOG_002: Bound SafePythonObject truthiness")
    func boundSafePythonObjectTruthiness() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let cases: [(PythonInterpreter.SafePythonObject, Bool)] = [
                (try true.toSafePythonObject(interpreter: isolatedInterpreter), true),
                (try false.toSafePythonObject(interpreter: isolatedInterpreter), false),
                (try 1.toSafePythonObject(interpreter: isolatedInterpreter), true),
                (try 0.toSafePythonObject(interpreter: isolatedInterpreter), false),
                (try "python".toSafePythonObject(interpreter: isolatedInterpreter), true),
                (try "".toSafePythonObject(interpreter: isolatedInterpreter), false)
            ]

            for (value, expected) in cases {
                let isTrue = try value.isTrue()
                let isNotTrue = try value.isNotTrue()
                #expect(isTrue == expected)
                #expect(isNotTrue == !expected)
            }
        }
    }

    @Test("LOG_003: PythonObject truthiness")
    func pythonObjectTruthiness() async throws {
        let cases: [(PythonObject, Bool)] = [
            (try await true.toPythonObject(interpreter: interpreter), true),
            (try await false.toPythonObject(interpreter: interpreter), false),
            (try await 1.toPythonObject(interpreter: interpreter), true),
            (try await 0.toPythonObject(interpreter: interpreter), false),
            (try await "python".toPythonObject(interpreter: interpreter), true),
            (try await "".toPythonObject(interpreter: interpreter), false)
        ]

        for (value, expected) in cases {
            let isTrue = try await value.isTrue()
            let isNotTrue = try await value.isNotTrue()
            #expect(isTrue == expected)
            #expect(isNotTrue == !expected)
        }
    }
    
    @Test("LOG_004: SafePythonObject logicalAnd and logicalOr return Python operands")
    func safePythonObjectLogicalAndOr() async throws {
        try await interpreter.withIsolatedContext { _ in
            let truthy: PythonInterpreter.SafePythonObject = "left"
            let falsey: PythonInterpreter.SafePythonObject = ""
            let rhs: PythonInterpreter.SafePythonObject = "right"
            
            let andTruthy = try truthy.logicalAnd(rhs)
            let andFalsey = try falsey.logicalAnd(rhs)
            let orTruthy = try truthy.logicalOr(rhs)
            let orFalsey = try falsey.logicalOr(rhs)
            
            #expect(try String(andTruthy) == "right")
            #expect(try String(andFalsey) == "")
            #expect(try String(orTruthy) == "left")
            #expect(try String(orFalsey) == "right")
        }
    }
    
    @Test("LOG_005: SafePythonObject logicalAnd and logicalOr short-circuit")
    func safePythonObjectLogicalAndOrShortCircuit() async throws {
        try await interpreter.withIsolatedContext { _ in
            let truthy: PythonInterpreter.SafePythonObject = "left"
            let falsey: PythonInterpreter.SafePythonObject = ""
            var andCalled = false
            var orCalled = false
            
            let andResult = try falsey.logicalAnd {
                andCalled = true
                return "right"
            }
            let orResult = try truthy.logicalOr {
                orCalled = true
                return "right"
            }
            
            #expect(!andCalled)
            #expect(!orCalled)
            #expect(try String(andResult) == "")
            #expect(try String(orResult) == "left")
        }
    }
    
    @Test("LOG_006: PythonObject logicalAnd and logicalOr return Python operands")
    func pythonObjectLogicalAndOr() async throws {
        let truthy = try await "left".toPythonObject(interpreter: interpreter)
        let falsey = try await "".toPythonObject(interpreter: interpreter)
        let rhs = try await "right".toPythonObject(interpreter: interpreter)
        
        let andTruthy = try await truthy.logicalAnd(rhs)
        let andFalsey = try await falsey.logicalAnd(rhs)
        let orTruthy = try await truthy.logicalOr(rhs)
        let orFalsey = try await falsey.logicalOr(rhs)
        
        #expect(try await String(andTruthy) == "right")
        #expect(try await String(andFalsey) == "")
        #expect(try await String(orTruthy) == "left")
        #expect(try await String(orFalsey) == "right")
    }
    
    @Test("LOG_007: PythonObject logicalAnd and logicalOr short-circuit")
    func pythonObjectLogicalAndOrShortCircuit() async throws {
        let truthy = try await "left".toPythonObject(interpreter: interpreter)
        let falsey = try await "".toPythonObject(interpreter: interpreter)
        var andCalled = false
        var orCalled = false
        
        let andResult = try await falsey.logicalAnd {
            andCalled = true
            return try await "right".toPythonObject(interpreter: interpreter)
        }
        let orResult = try await truthy.logicalOr {
            orCalled = true
            return try await "right".toPythonObject(interpreter: interpreter)
        }
        
        #expect(!andCalled)
        #expect(!orCalled)
        #expect(try await String(andResult) == "")
        #expect(try await String(orResult) == "left")
    }
    
    @Test("LOG_008: None truthiness")
    func noneTruthiness() async throws {
        try await interpreter.runSimpleString(pythonCode: "s2p_logical_none = None")
        let globals = try await interpreter.getGlobals()
        let noneObject = try await globals.getItem(key: "s2p_logical_none")
        
        #expect(try await !noneObject.isTrue())
        #expect(try await noneObject.isNotTrue())
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let noneObject = try isolatedInterpreter.globals.getItem(key: "s2p_logical_none")
            #expect(try !noneObject.isTrue())
            #expect(try noneObject.isNotTrue())
        }
    }
    
    @Test("LOG_009: Empty and nonempty Python container truthiness")
    func containerTruthiness() async throws {
        let asyncCases: [(PythonObject, Bool)] = [
            (try await interpreter.convertToPython(array: [Int]()), false),
            (try await interpreter.convertToPython(array: [1]), true),
            (try await interpreter.convertToPython(tupleContentsOf: [Int]()), false),
            (try await interpreter.convertToPython(tupleContentsOf: [1]), true),
            (try await interpreter.convertToPython(dictionary: [String: Int]()), false),
            (try await interpreter.convertToPython(dictionary: ["value": 1]), true),
            (try await interpreter.convertToPython(set: Set<Int>()), false),
            (try await interpreter.convertToPython(set: Set([1])), true)
        ]
        
        for (value, expected) in asyncCases {
            let isTrue = try await value.isTrue()
            let isNotTrue = try await value.isNotTrue()
            #expect(isTrue == expected)
            #expect(isNotTrue == !expected)
        }
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safeCases: [(PythonInterpreter.SafePythonObject, Bool)] = [
                (try isolatedInterpreter.convertToSafePython(array: [Int]()), false),
                (try isolatedInterpreter.convertToSafePython(array: [1]), true),
                (try isolatedInterpreter.convertToSafePython(tupleContentsOf: [Int]()), false),
                (try isolatedInterpreter.convertToSafePython(tupleContentsOf: [1]), true),
                (try isolatedInterpreter.convertToSafePython(dictionary: [String: Int]()), false),
                (try isolatedInterpreter.convertToSafePython(dictionary: ["value": 1]), true),
                (try isolatedInterpreter.convertToSafePython(set: Set<Int>()), false),
                (try isolatedInterpreter.convertToSafePython(set: Set([1])), true)
            ]
            
            for (value, expected) in safeCases {
                let isTrue = try value.isTrue()
                let isNotTrue = try value.isNotTrue()
                #expect(isTrue == expected)
                #expect(isNotTrue == !expected)
            }
        }
    }
    
    @Test("LOG_010: Custom __bool__ truthiness")
    func customBoolTruthiness() async throws {
        try await interpreter.runSimpleString(pythonCode: """
        class S2PLogicalTruthyBool:
            def __bool__(self):
                return True
        class S2PLogicalFalseyBool:
            def __bool__(self):
                return False
        s2p_logical_truthy_bool = S2PLogicalTruthyBool()
        s2p_logical_falsey_bool = S2PLogicalFalseyBool()
        """)
        let globals = try await interpreter.getGlobals()
        let truthy = try await globals.getItem(key: "s2p_logical_truthy_bool")
        let falsey = try await globals.getItem(key: "s2p_logical_falsey_bool")
        
        #expect(try await truthy.isTrue())
        #expect(try await !truthy.isNotTrue())
        #expect(try await !falsey.isTrue())
        #expect(try await falsey.isNotTrue())
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let truthy = try isolatedInterpreter.globals.getItem(key: "s2p_logical_truthy_bool")
            let falsey = try isolatedInterpreter.globals.getItem(key: "s2p_logical_falsey_bool")
            
            #expect(try truthy.isTrue())
            #expect(try !truthy.isNotTrue())
            #expect(try !falsey.isTrue())
            #expect(try falsey.isNotTrue())
        }
    }
    
    @Test("LOG_011: Custom __len__ truthiness")
    func customLenTruthiness() async throws {
        try await interpreter.runSimpleString(pythonCode: """
        class S2PLogicalNonzeroLen:
            def __len__(self):
                return 3
        class S2PLogicalZeroLen:
            def __len__(self):
                return 0
        s2p_logical_nonzero_len = S2PLogicalNonzeroLen()
        s2p_logical_zero_len = S2PLogicalZeroLen()
        """)
        let globals = try await interpreter.getGlobals()
        let truthy = try await globals.getItem(key: "s2p_logical_nonzero_len")
        let falsey = try await globals.getItem(key: "s2p_logical_zero_len")
        
        #expect(try await truthy.isTrue())
        #expect(try await !truthy.isNotTrue())
        #expect(try await !falsey.isTrue())
        #expect(try await falsey.isNotTrue())
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let truthy = try isolatedInterpreter.globals.getItem(key: "s2p_logical_nonzero_len")
            let falsey = try isolatedInterpreter.globals.getItem(key: "s2p_logical_zero_len")
            
            #expect(try truthy.isTrue())
            #expect(try !truthy.isNotTrue())
            #expect(try !falsey.isTrue())
            #expect(try falsey.isNotTrue())
        }
    }
    
    @Test("LOG_012: PythonObject truthiness propagates __bool__ and __len__ exceptions")
    func pythonObjectTruthinessExceptionPropagation() async throws {
        try await interpreter.runSimpleString(pythonCode: """
        class S2PLogicalBoolRaises:
            def __bool__(self):
                raise RuntimeError("bool exploded")
        class S2PLogicalLenRaises:
            def __len__(self):
                raise RuntimeError("len exploded")
        s2p_logical_bool_raises = S2PLogicalBoolRaises()
        s2p_logical_len_raises = S2PLogicalLenRaises()
        """)
        let globals = try await interpreter.getGlobals()
        let boolRaises = try await globals.getItem(key: "s2p_logical_bool_raises")
        let lenRaises = try await globals.getItem(key: "s2p_logical_len_raises")
        
        let boolIsTrueError = await #expect(throws: PythonError.self) {
            _ = try await boolRaises.isTrue()
        }
        let boolIsNotTrueError = await #expect(throws: PythonError.self) {
            _ = try await boolRaises.isNotTrue()
        }
        let lenIsTrueError = await #expect(throws: PythonError.self) {
            _ = try await lenRaises.isTrue()
        }
        let lenIsNotTrueError = await #expect(throws: PythonError.self) {
            _ = try await lenRaises.isNotTrue()
        }
        
        for error in [boolIsTrueError, boolIsNotTrueError, lenIsTrueError, lenIsNotTrueError] {
            if case .pythonException = error {
                // expected
            } else {
                Issue.record("Expected .pythonException, but got \(String(describing: error))")
            }
        }
    }
    
    @Test("LOG_013: SafePythonObject truthiness propagates __bool__ and __len__ exceptions")
    func safePythonObjectTruthinessExceptionPropagation() async throws {
        try await interpreter.runSimpleString(pythonCode: """
        class S2PLogicalSafeBoolRaises:
            def __bool__(self):
                raise RuntimeError("safe bool exploded")
        class S2PLogicalSafeLenRaises:
            def __len__(self):
                raise RuntimeError("safe len exploded")
        s2p_logical_safe_bool_raises = S2PLogicalSafeBoolRaises()
        s2p_logical_safe_len_raises = S2PLogicalSafeLenRaises()
        """)
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let boolRaises = try isolatedInterpreter.globals.getItem(key: "s2p_logical_safe_bool_raises")
            let lenRaises = try isolatedInterpreter.globals.getItem(key: "s2p_logical_safe_len_raises")
            
            let boolIsTrueError = #expect(throws: PythonError.self) {
                _ = try boolRaises.isTrue()
            }
            let boolIsNotTrueError = #expect(throws: PythonError.self) {
                _ = try boolRaises.isNotTrue()
            }
            let lenIsTrueError = #expect(throws: PythonError.self) {
                _ = try lenRaises.isTrue()
            }
            let lenIsNotTrueError = #expect(throws: PythonError.self) {
                _ = try lenRaises.isNotTrue()
            }
            
            for error in [boolIsTrueError, boolIsNotTrueError, lenIsTrueError, lenIsNotTrueError] {
                if case .safePythonException = error {
                    // expected
                } else {
                    Issue.record("Expected .safePythonException, but got \(String(describing: error))")
                }
            }
        }
    }
    
    @Test("LOG_014: Eager logical overloads receive already-created right operands")
    func eagerLogicalOverloadsReceiveAlreadyCreatedRightOperands() async throws {
        try await interpreter.withIsolatedContext { _ in
            let falsey: PythonInterpreter.SafePythonObject = ""
            let truthy: PythonInterpreter.SafePythonObject = "left"
            var safeAndCreated = false
            var safeOrCreated = false
            
            let safeAndRhs: PythonInterpreter.SafePythonObject = {
                safeAndCreated = true
                return "right"
            }()
            let safeOrRhs: PythonInterpreter.SafePythonObject = {
                safeOrCreated = true
                return "right"
            }()
            
            _ = try falsey.logicalAnd(safeAndRhs)
            _ = try truthy.logicalOr(safeOrRhs)
            
            #expect(safeAndCreated)
            #expect(safeOrCreated)
        }
        
        let falsey = try await "".toPythonObject(interpreter: interpreter)
        let truthy = try await "left".toPythonObject(interpreter: interpreter)
        var asyncAndCreated = false
        var asyncOrCreated = false
        
        asyncAndCreated = true
        let asyncAndRhs = try await "right".toPythonObject(interpreter: interpreter)
        asyncOrCreated = true
        let asyncOrRhs = try await "right".toPythonObject(interpreter: interpreter)
        
        _ = try await falsey.logicalAnd(asyncAndRhs)
        _ = try await truthy.logicalOr(asyncOrRhs)
        
        #expect(asyncAndCreated)
        #expect(asyncOrCreated)
    }
}
