//
//  ItemAccessTests.swift
//  Swift2Python
//

import Testing
@testable import Swift2Python

@Suite("Item Access Tests")
struct ItemAccessTests {
    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask

    let interpreter: PythonInterpreter

    init() async throws {
        interpreter = try await Self.sharedInterpreterTask.value
    }

    @Test("ITM_001: PythonObject getItem and setItem support custom item protocol")
    func asyncCustomItemProtocolAccessAndMutation() async throws {
        try await interpreter.runSimpleString(pythonCode: """
        class Swift2PythonAsyncItemFixture:
            def __init__(self):
                self.values = {}
            def __getitem__(self, key):
                return self.values[key]
            def __setitem__(self, key, value):
                self.values[key] = value
        """)

        let globals = try await interpreter.getGlobals()
        let fixtureType = try await globals.getItem(key: "Swift2PythonAsyncItemFixture")
        let fixture = try await fixtureType()

        try await fixture.setItem(key: "name", newValue: "Ada")
        try await fixture.setItem(key: "count", newValue: 3)

        #expect(try await String(fixture.getItem(key: "name")) == "Ada")
        #expect(try await Int(fixture.getItem(key: "count")) == 3)
    }

    @Test("ITM_002: PythonObject item protocol failures include exception info")
    func asyncCustomItemProtocolFailureIncludesExceptionInfo() async throws {
        try await interpreter.runSimpleString(pythonCode: """
        class Swift2PythonAsyncFailingItemFixture:
            def __getitem__(self, key):
                raise RuntimeError(f"getitem failed for {key}")
            def __setitem__(self, key, value):
                raise RuntimeError(f"setitem failed for {key}")
        """)

        let globals = try await interpreter.getGlobals()
        let fixtureType = try await globals.getItem(key: "Swift2PythonAsyncFailingItemFixture")
        let fixture = try await fixtureType()

        let getError = await #expect(throws: PythonError.self) {
            _ = try await fixture.getItem(key: "bad")
        }
        guard case let .pythonException(_, getInfo)? = getError else {
            Issue.record("Expected .pythonException for failing __getitem__, got \(String(describing: getError))")
            return
        }
        #expect(getInfo.typeName == "RuntimeError")
        #expect(getInfo.message.contains("getitem failed for bad"))
        #expect(getInfo.traceback?.contains("__getitem__") == true)

        let setError = await #expect(throws: PythonError.self) {
            try await fixture.setItem(key: "bad", newValue: 1)
        }
        guard case let .pythonException(_, setInfo)? = setError else {
            Issue.record("Expected .pythonException for failing __setitem__, got \(String(describing: setError))")
            return
        }
        #expect(setInfo.typeName == "RuntimeError")
        #expect(setInfo.message.contains("setitem failed for bad"))
        #expect(setInfo.traceback?.contains("__setitem__") == true)
    }

    @Test("ITM_010: SafePythonObject getItem and setItem support custom item protocol")
    func safeCustomItemProtocolAccessAndMutation() async throws {
        try await interpreter.withIsolatedContext { context in
            try context.runSimpleString(pythonCode: """
            class Swift2PythonSafeItemFixture:
                def __init__(self):
                    self.values = {}
                def __getitem__(self, key):
                    return self.values[key]
                def __setitem__(self, key, value):
                    self.values[key] = value
            """)

            let fixtureType = context.globals["Swift2PythonSafeItemFixture"]
            let fixture = try fixtureType.call()

            try fixture.setItem(key: "name", newValue: "Ada")
            try fixture.setItem(key: "count", newValue: 3)

            #expect(try String(fixture.getItem(key: "name")) == "Ada")
            #expect(try Int(fixture.getItem(key: "count")) == 3)
        }
    }

    @Test("ITM_011: SafePythonObject explicit item failures are catchable inside isolated context")
    func safeCustomItemProtocolFailureIsCatchableInsideContext() async throws {
        try await interpreter.withIsolatedContext { context in
            try context.runSimpleString(pythonCode: """
            class Swift2PythonSafeFailingItemFixture:
                def __getitem__(self, key):
                    raise RuntimeError(f"safe getitem failed for {key}")
            """)

            let fixtureType = context.globals["Swift2PythonSafeFailingItemFixture"]
            let fixture = try fixtureType.call()

            let thrownError = #expect(throws: PythonError.self) {
                _ = try fixture.getItem(key: "bad")
            }

            guard case let .safePythonException(_, info)? = thrownError else {
                Issue.record("Expected .safePythonException inside isolated context, got \(String(describing: thrownError))")
                return
            }
            #expect(info.typeName == "RuntimeError")
            #expect(info.message.contains("safe getitem failed for bad"))
            #expect(info.traceback?.contains("__getitem__") == true)
        }
    }

    @Test("ITM_012: SafePythonObject item failures convert when escaping isolated context")
    func safeCustomItemProtocolFailureConvertsAcrossBoundary() async throws {
        let thrownError = await #expect(throws: PythonError.self) {
            try await interpreter.withIsolatedContext { context in
                try context.runSimpleString(pythonCode: """
                class Swift2PythonEscapingItemFixture:
                    def __getitem__(self, key):
                        raise RuntimeError(f"escaping getitem failed for {key}")
                """)

                let fixtureType = context.globals["Swift2PythonEscapingItemFixture"]
                let fixture = try fixtureType.call()
                _ = try fixture.getItem(key: "bad")
            }
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException after leaving isolated context, got \(String(describing: thrownError))")
            return
        }
        #expect(info.typeName == "RuntimeError")
        #expect(info.message.contains("escaping getitem failed for bad"))
        #expect(info.traceback?.contains("__getitem__") == true)
    }

    @Test("ITM_013: SafePythonObject variadic subscript uses tuple keys")
    func safeVariadicSubscriptUsesTupleKeys() async throws {
        try await interpreter.withIsolatedContext { context in
            try context.runSimpleString(pythonCode: """
            class Swift2PythonTupleKeyFixture:
                def __getitem__(self, key):
                    return key
                def __setitem__(self, key, value):
                    self.last_key = key
                    self.last_value = value
            """)

            let fixtureType = context.globals["Swift2PythonTupleKeyFixture"]
            var fixture = try fixtureType.call()

            let keyFromGet = fixture[1, "two"]
            #expect(try keyFromGet.isTuple)
            #expect(try keyFromGet.tupleCount == 2)
            #expect(try Int(keyFromGet.tupleItem(at: 0)) == 1)
            #expect(try String(keyFromGet.tupleItem(at: 1)) == "two")

            fixture[3, "four"] = "value"
            let keyFromSet = try fixture.get(attr: "last_key")
            let valueFromSet = try fixture.get(attr: "last_value")

            #expect(try keyFromSet.isTuple)
            #expect(try keyFromSet.tupleCount == 2)
            #expect(try Int(keyFromSet.tupleItem(at: 0)) == 3)
            #expect(try String(keyFromSet.tupleItem(at: 1)) == "four")
            #expect(try String(valueFromSet) == "value")
        }
    }
}
