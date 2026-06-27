//
//  ExceptionHandlingTests.swift
//  Swift2Python
//
//  Created by OpenAI on 6/23/26.
//

import Testing
@testable import Swift2Python

@Suite("Python Exception Handling", .serialized)
struct ExceptionHandlingTests {

    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask

    let interpreter: PythonInterpreter

    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }

    private func installExceptionFixtures() async throws -> PythonObject {
        try await interpreter.runSimpleString(pythonCode: """
        def swift2python_trace_inner():
            raise ValueError("deep failure")

        def swift2python_trace_outer():
            return swift2python_trace_inner()

        def swift2python_raise_from():
            try:
                raise KeyError("root failure")
            except KeyError as error:
                raise RuntimeError("wrapped failure") from error

        def swift2python_raise_with_context():
            try:
                raise LookupError("context root")
            except LookupError:
                raise ValueError("contextual failure")

        def swift2python_raise_with_note():
            error = ValueError("noted failure")
            if hasattr(error, "add_note"):
                error.add_note("first diagnostic note")
            raise error
        """)
        return try await interpreter.getGlobals()
    }

    @Test("PythonObject exceptions include stable type, message, and traceback frames")
    func pythonObjectExceptionIncludesTracebackInfo() async throws {
        let globals = try await installExceptionFixtures()
        let failing = try await globals.getItem(key: "swift2python_trace_outer")

        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await failing.call()
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "ValueError")
        #expect(info.message == "deep failure")
        #expect(info.description.contains("Python exception: ValueError: deep failure"))
        #expect(info.description.contains("Traceback (most recent call last):"))

        guard let traceback = info.traceback else {
            Issue.record("Expected traceback information")
            return
        }

        #expect(traceback.contains("swift2python_trace_outer"))
        #expect(traceback.contains("swift2python_trace_inner"))
        #expect(traceback.contains("line 5"))
        #expect(traceback.contains("line 2"))
        #expect(traceback.contains("ValueError: deep failure"))
    }

    @Test("PythonObject exceptions preserve explicit chained causes")
    func pythonObjectExceptionPreservesExplicitCause() async throws {
        let globals = try await installExceptionFixtures()
        let failing = try await globals.getItem(key: "swift2python_raise_from")

        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await failing.call()
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "RuntimeError")
        #expect(info.message == "wrapped failure")

        guard let traceback = info.traceback else {
            Issue.record("Expected traceback information")
            return
        }

        #expect(traceback.contains("KeyError: 'root failure'"))
        #expect(traceback.contains("The above exception was the direct cause of the following exception:"))
        #expect(traceback.contains("RuntimeError: wrapped failure"))
    }

    @Test("PythonObject exceptions preserve implicit exception context")
    func pythonObjectExceptionPreservesImplicitContext() async throws {
        let globals = try await installExceptionFixtures()
        let failing = try await globals.getItem(key: "swift2python_raise_with_context")

        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await failing.call()
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "ValueError")
        #expect(info.message == "contextual failure")

        guard let traceback = info.traceback else {
            Issue.record("Expected traceback information")
            return
        }

        #expect(traceback.contains("LookupError: context root"))
        #expect(traceback.contains("During handling of the above exception, another exception occurred:"))
        #expect(traceback.contains("ValueError: contextual failure"))
    }

    @Test("PythonObject exceptions preserve Python exception notes when supported")
    func pythonObjectExceptionPreservesNotes() async throws {
        let globals = try await installExceptionFixtures()
        let failing = try await globals.getItem(key: "swift2python_raise_with_note")

        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await failing.call()
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "ValueError")
        #expect(info.message == "noted failure")

        guard let traceback = info.traceback else {
            Issue.record("Expected traceback information")
            return
        }

        #expect(traceback.contains("ValueError: noted failure"))
        #expect(traceback.contains("first diagnostic note"))
    }

    @Test("Import failures include module name and traceback info")
    func importFailureIncludesExceptionInfo() async throws {
        let missingModule = "swift2python_missing_module_for_exception_tests"

        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await interpreter.import(missingModule)
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "ModuleNotFoundError")
        #expect(info.message.contains(missingModule))
        #expect(info.traceback?.contains("ModuleNotFoundError") == true)
    }

    @Test("Attribute lookup failures include attribute name and exception info")
    func attributeFailureIncludesExceptionInfo() async throws {
        let builtins = try await interpreter.getBuiltins()

        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await builtins.get(attr: "swift2python_missing_attribute")
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "AttributeError")
        #expect(info.message.contains("swift2python_missing_attribute"))
        #expect(info.traceback?.contains("AttributeError") == true)
    }

    @Test("Item lookup failures include key details and exception info")
    func itemFailureIncludesExceptionInfo() async throws {
        let dictionary = try await interpreter.convertToPython(dictionary: ["exists": 1])

        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await dictionary.getItem(key: "missing")
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "KeyError")
        #expect(info.message.contains("missing"))
        #expect(info.traceback?.contains("KeyError") == true)
    }

    @Test("Conversion wrappers preserve underlying Python exception info")
    func conversionWrapperPreservesUnderlyingExceptionInfo() async throws {
        let value = try await "not numeric".toPythonObject(interpreter: interpreter)

        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Double(value)
        }

        guard case let .conversionType(_, _, targetType, underlying)? = thrownError else {
            Issue.record("Expected .conversionType, got \(String(describing: thrownError))")
            return
        }

        #expect(targetType == "Double")
        guard let info = underlying?.pythonExceptionInfo else {
            Issue.record("Expected underlying Python exception info")
            return
        }

        #expect(info.typeName == "TypeError")
        #expect(info.traceback?.contains("TypeError") == true)
    }

    @Test("withIsolatedContext converts safe Python exceptions before throwing across the boundary")
    func isolatedContextConvertsSafeExceptionToPythonException() async throws {
        _ = try await installExceptionFixtures()

        let thrownError = await #expect(throws: PythonError.self) {
            try await interpreter.withIsolatedContext { isolatedInterpreter in
                let failing = isolatedInterpreter.globals["swift2python_trace_outer"]
                _ = try failing.call()
            }
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException after leaving isolated context, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "ValueError")
        #expect(info.message == "deep failure")
        #expect(info.traceback?.contains("swift2python_trace_outer") == true)
        #expect(info.traceback?.contains("swift2python_trace_inner") == true)
    }

    @Test("withIsolatedContext preserves chained exceptions when converting across the boundary")
    func isolatedContextPreservesChainedExceptionWhenConvertingBoundaryError() async throws {
        _ = try await installExceptionFixtures()

        let thrownError = await #expect(throws: PythonError.self) {
            try await interpreter.withIsolatedContext { isolatedInterpreter in
                let failing = isolatedInterpreter.globals["swift2python_raise_from"]
                _ = try failing.call()
            }
        }

        guard case let .pythonException(_, info)? = thrownError else {
            Issue.record("Expected .pythonException after leaving isolated context, got \(String(describing: thrownError))")
            return
        }

        #expect(info.typeName == "RuntimeError")
        #expect(info.message == "wrapped failure")
        #expect(info.traceback?.contains("KeyError: 'root failure'") == true)
        #expect(info.traceback?.contains("The above exception was the direct cause of the following exception:") == true)
        #expect(info.traceback?.contains("RuntimeError: wrapped failure") == true)
    }

    @Test("Safe Python exceptions are still catchable inside isolated context")
    func safePythonExceptionIsCatchableInsideIsolatedContext() async throws {
        _ = try await installExceptionFixtures()

        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let failing = isolatedInterpreter.globals["swift2python_trace_outer"]

            let thrownError = #expect(throws: PythonError.self) {
                _ = try failing.call()
            }

            guard case let .safePythonException(_, info)? = thrownError else {
                Issue.record("Expected .safePythonException inside isolated context, got \(String(describing: thrownError))")
                return
            }

            #expect(info.typeName == "ValueError")
            #expect(info.message == "deep failure")
            #expect(info.traceback?.contains("swift2python_trace_outer") == true)
            #expect(info.traceback?.contains("swift2python_trace_inner") == true)
        }
    }

    @Test("Throwing safe attribute lookup exposes catchable safe Python exception info")
    func safeAttributeFailureIncludesExceptionInfoInsideIsolatedContext() async throws {
        let object = try await interpreter.convertToPython(dictionary: ["exists": 1])

        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safeObject = try isolatedInterpreter.bind(pythonObject: object)

            let thrownError = #expect(throws: PythonError.self) {
                _ = try safeObject.get(attr: "swift2python_missing_attribute")
            }

            guard case let .safePythonException(_, info)? = thrownError else {
                Issue.record("Expected .safePythonException inside isolated context, got \(String(describing: thrownError))")
                return
            }

            #expect(info.typeName == "AttributeError")
            #expect(info.message.contains("swift2python_missing_attribute"))
            #expect(info.traceback?.contains("AttributeError") == true)
        }
    }
}
