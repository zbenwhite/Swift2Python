//
//  AttributesTest.swift
//  Swift2Python
//

import Testing
@testable import Swift2Python

@Suite("Attribute Tests", .serialized)
struct AttributesTests {

    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask

    let interpreter: PythonInterpreter

    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }
    
    private func makeNamespace() async throws -> PythonObject {
        try await interpreter.runSimpleString(pythonCode: """
        class Swift2PythonAttributeFixture:
            pass
        """)
        let globals = try await interpreter.getGlobals()
        let fixtureType = try await globals.getItem(key: "Swift2PythonAttributeFixture")
        return try await fixtureType()
    }
    
    @Test("ATTR_001: PythonObject get and set attribute")
    func pythonObjectGetAndSetAttribute() async throws {
        let object = try await makeNamespace()
        
        try await object.set(attr: "name", value: "Ada")
        try await object.set(attr: "count", value: 3)
        
        let name = try await object.get(attr: "name")
        let count = try await object.get(attr: "count")
        
        #expect(try await String(name) == "Ada")
        #expect(try await Int(count) == 3)
    }
    
    @Test("ATTR_002: PythonObject set replaces existing attribute")
    func pythonObjectSetReplacesExistingAttribute() async throws {
        let object = try await makeNamespace()
        
        try await object.set(attr: "value", value: "first")
        try await object.set(attr: "value", value: "second")
        
        let value = try await object.get(attr: "value")
        
        #expect(try await String(value) == "second")
    }
    
    @Test("ATTR_003: PythonObject get missing attribute throws")
    func pythonObjectGetMissingAttributeThrows() async throws {
        let object = try await makeNamespace()
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await object.get(attr: "missing")
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for missing async attribute, got \(String(describing: thrownError))")
        }
    }
    
    @Test("ATTR_004: PythonObject set read-only attribute throws")
    func pythonObjectSetReadOnlyAttributeThrows() async throws {
        let value = try await interpreter.convertToPython(int: 42)
        
        let thrownError = await #expect(throws: PythonError.self) {
            try await value.set(attr: "real", value: 10)
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for read-only async attribute set, got \(String(describing: thrownError))")
        }
    }
    
    @Test("ATTR_005: PythonObject builtins hasattr checks attributes")
    func pythonObjectBuiltinsHasattrChecksAttributes() async throws {
        let object = try await makeNamespace()
        let builtins = try await interpreter.getBuiltins()
        
        try await object.set(attr: "name", value: "Ada")
        
        let hasName = try await builtins.hasattr(object, "name")
        let hasMissing = try await builtins.hasattr(object, "missing")
        
        #expect(try await Bool(hasName))
        #expect(try await Bool(hasMissing) == false)
    }
    
    @Test("ATTR_006: PythonObject builtins delattr deletes attributes")
    func pythonObjectBuiltinsDelattrDeletesAttributes() async throws {
        let object = try await makeNamespace()
        let builtins = try await interpreter.getBuiltins()
        
        try await object.set(attr: "name", value: "Ada")
        #expect(try await Bool(try await builtins.hasattr(object, "name")))
        
        _ = try await builtins.delattr(object, "name")
        
        #expect(try await Bool(try await builtins.hasattr(object, "name")) == false)
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await object.get(attr: "name")
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException after async delattr, got \(String(describing: thrownError))")
        }
    }
    
    @Test("ATTR_007: PythonObject builtins delattr missing attribute throws")
    func pythonObjectBuiltinsDelattrMissingAttributeThrows() async throws {
        let object = try await makeNamespace()
        let builtins = try await interpreter.getBuiltins()
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await builtins.delattr(object, "missing")
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for missing async delattr, got \(String(describing: thrownError))")
        }
    }
    
    @Test("ATTR_008: PythonObject dynamic member supports method calls")
    func pythonObjectDynamicMemberSupportsMethodCalls() async throws {
        let object = try await makeNamespace()
        
        try await object.set(attr: "name", value: "Ada")
        let dict = try await object.get(attr: "__dict__")
        let value = try await dict[dynamicMember: "get"]("name", "fallback")
        
        #expect(try await String(value) == "Ada")
    }
    
    @Test("ATTR_009: SafePythonObject explicit get and set attribute")
    func safePythonObjectExplicitGetAndSetAttribute() async throws {
        let object = try await makeNamespace()
        
        try await interpreter.withIsolatedContext { context in
            let safeObject = context.bind(pythonObject: object)
            
            try safeObject.set(attr: "name", value: "Ada")
            try safeObject.set(attr: "count", value: 3)
            
            let name = try safeObject.get(attr: "name")
            let count = try safeObject.get(attr: "count")
            
            #expect(try String(name) == "Ada")
            #expect(try Int(count) == 3)
        }
    }
    
    @Test("ATTR_010: SafePythonObject dynamic member gets and sets attributes")
    func safePythonObjectDynamicMemberGetsAndSetsAttributes() async throws {
        let object = try await makeNamespace()
        
        try await interpreter.withIsolatedContext { context in
            var safeObject = context.bind(pythonObject: object)
            
            safeObject.name = "Ada"
            safeObject.numVal = 3
            safeObject.numVal = safeObject.numVal + 4
            
            let name = try String(safeObject.name)
            let numVal = try Int(safeObject.numVal)
            
            #expect(name == "Ada")
            #expect(numVal == 7)
        }
    }
    
    @Test("ATTR_011: SafePythonObject explicit get missing attribute throws")
    func safePythonObjectExplicitGetMissingAttributeThrows() async throws {
        let object = try await makeNamespace()
        
        try await interpreter.withIsolatedContext { context in
            let safeObject = context.bind(pythonObject: object)
            
            let thrownError = #expect(throws: PythonError.self) {
                _ = try safeObject.get(attr: "missing")
            }
            
            if case .safePythonException = thrownError {
                // expected inside isolated context
            } else {
                Issue.record("Expected .safePythonException for missing safe attribute, got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("ATTR_012: SafePythonObject explicit set read-only attribute throws")
    func safePythonObjectExplicitSetReadOnlyAttributeThrows() async throws {
        let value = try await interpreter.convertToPython(int: 42)
        
        try await interpreter.withIsolatedContext { context in
            let safeValue = context.bind(pythonObject: value)
            
            let thrownError = #expect(throws: PythonError.self) {
                try safeValue.set(attr: "real", value: 10)
            }
            
            if case .safePythonException = thrownError {
                // expected inside isolated context
            } else {
                Issue.record("Expected .safePythonException for read-only safe attribute set, got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("ATTR_013: SafePythonObject builtins hasattr checks attributes")
    func safePythonObjectBuiltinsHasattrChecksAttributes() async throws {
        let object = try await makeNamespace()
        
        try await interpreter.withIsolatedContext { context in
            let safeObject = context.bind(pythonObject: object)
            
            try safeObject.set(attr: "name", value: "Ada")
            
            let hasName = try context.builtins.hasattr(safeObject, "name")
            let hasMissing = try context.builtins.hasattr(safeObject, "missing")
            
            #expect(try Bool(hasName))
            #expect(try Bool(hasMissing) == false)
        }
    }
    
    @Test("ATTR_014: SafePythonObject builtins delattr deletes attributes")
    func safePythonObjectBuiltinsDelattrDeletesAttributes() async throws {
        let object = try await makeNamespace()
        
        try await interpreter.withIsolatedContext { context in
            let safeObject = context.bind(pythonObject: object)
            
            try safeObject.set(attr: "name", value: "Ada")
            #expect(try Bool(context.builtins.hasattr(safeObject, "name")))
            
            _ = try context.builtins.delattr(safeObject, "name")
            
            #expect(try Bool(context.builtins.hasattr(safeObject, "name")) == false)
            
            let thrownError = #expect(throws: PythonError.self) {
                _ = try safeObject.get(attr: "name")
            }
            
            if case .safePythonException = thrownError {
                // expected inside isolated context
            } else {
                Issue.record("Expected .safePythonException after safe delattr, got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("ATTR_015: SafePythonObject builtins delattr missing attribute throws")
    func safePythonObjectBuiltinsDelattrMissingAttributeThrows() async throws {
        let object = try await makeNamespace()
        
        try await interpreter.withIsolatedContext { context in
            let safeObject = context.bind(pythonObject: object)
            
            let thrownError = #expect(throws: PythonError.self) {
                _ = try context.builtins.delattr(safeObject, "missing")
            }
            
            if case .safePythonException = thrownError {
                // expected inside isolated context
            } else {
                Issue.record("Expected .safePythonException for missing safe delattr, got \(String(describing: thrownError))")
            }
        }
    }
}
