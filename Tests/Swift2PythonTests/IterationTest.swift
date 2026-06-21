//
//  IterationTest.swift
//  Swift2Python
//
//  Created by Ben White on 6/21/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Iteration Tests", .serialized)
struct IterationTests {

    private static let setupLogging: Void = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
    }()
    
    private static let sharedInterpreterTask: Task<PythonInterpreter, Error> = Task {
        _ = setupLogging
        
        let runtime = PythonRuntime.shared
        try await runtime.initialize()
        return try await PythonInterpreter()
    }
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }
    
    private func asyncInts(from iterable: PythonObject) async throws -> [Int] {
        var values: [Int] = []
        for try await item in iterable {
            values.append(try await Int(item))
        }
        return values
    }
    
    private func asyncStrings(from iterable: PythonObject) async throws -> [String] {
        var values: [String] = []
        for try await item in iterable {
            values.append(try await String(item))
        }
        return values
    }
    
    private func safeInts(from iterable: PythonInterpreter.SafePythonObject) throws -> [Int] {
        var values: [Int] = []
        var iterator = try iterable.pythonIterator()
        while let item = try iterator.nextThrowing() {
            values.append(try Int(item))
        }
        return values
    }
    
    @Test("ITER_001: PythonObject AsyncSequence iterates common iterables")
    func pythonObjectAsyncSequenceCommonIterables() async throws {
        let builtins = try await interpreter.getBuiltins()
        let list = try await interpreter.convertToPython(array: [1, 2, 3])
        let tuple = try await builtins.tuple(list)
        let range = try await builtins.range(4)
        
        let iterator = try await builtins.iter(list)
        
        #expect(try await asyncInts(from: list) == [1, 2, 3])
        #expect(try await asyncInts(from: tuple) == [1, 2, 3])
        #expect(try await asyncInts(from: range) == [0, 1, 2, 3])
        #expect(try await asyncInts(from: iterator) == [1, 2, 3])
    }
    
    @Test("ITER_002: PythonObject AsyncSequence iterates dictionary views")
    func pythonObjectAsyncSequenceDictionaryViews() async throws {
        let dict = try await interpreter.convertToPython(dictionary: [
            "one": 1,
            "two": 2,
            "three": 3
        ])
        
        let keys = try await dict.keys()
        let values = try await dict.values()
        let items = try await dict.items()
        
        #expect(try await asyncStrings(from: keys).sorted() == ["one", "three", "two"])
        #expect(try await asyncInts(from: values).sorted() == [1, 2, 3])
        
        var itemPairs: [String: Int] = [:]
        for try await item in items {
            let key = try await String(item.getItem(key: 0))
            let value = try await Int(item.getItem(key: 1))
            itemPairs[key] = value
        }
        #expect(itemPairs == ["one": 1, "two": 2, "three": 3])
    }
    
    @Test("ITER_003: PythonObject AsyncIterator reports exhaustion")
    func pythonObjectAsyncIteratorReportsExhaustion() async throws {
        let list = try await interpreter.convertToPython(array: [10, 20])
        var iterator = list.makeAsyncIterator()
        
        #expect(try await Int(iterator.next()!) == 10)
        #expect(try await Int(iterator.next()!) == 20)
        #expect(try await iterator.next() == nil)
        #expect(try await iterator.next() == nil)
    }
    
    @Test("ITER_004: PythonObject AsyncSequence rejects non-iterables")
    func pythonObjectAsyncSequenceRejectsNonIterables() async throws {
        let number = try await interpreter.convertToPython(int: 42)
        
        let thrownError = await #expect(throws: PythonError.self) {
            for try await _ in number {
                Issue.record("Non-iterable unexpectedly produced an item")
            }
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for async non-iterable iteration, got \(String(describing: thrownError))")
        }
    }
    
    @Test("ITER_005: PythonObject AsyncIterator propagates iterator creation errors")
    func pythonObjectAsyncIteratorPropagatesCreationErrors() async throws {
        let number = try await interpreter.convertToPython(int: 42)
        var iterator = number.makeAsyncIterator()
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await iterator.next()
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for async iterator creation error, got \(String(describing: thrownError))")
        }
    }
    
    @Test("ITER_006: SafePythonObject Sequence iterates common containers")
    func safePythonObjectSequenceCommonContainers() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let list = try isolatedInterpreter.convertToSafePython(array: [1, 2, 3])
            let tuple = try isolatedInterpreter.builtins.tuple(list)
            let set = try isolatedInterpreter.convertToSafePython(set: Set([3, 1, 2]))
            
            var listValues: [Int] = []
            for item in list {
                listValues.append(try Int(item))
            }
            
            #expect(listValues == [1, 2, 3])
            #expect(try safeInts(from: tuple) == [1, 2, 3])
            #expect(try safeInts(from: set).sorted() == [1, 2, 3])
        }
    }
    
    @Test("ITER_007: SafePythonObject throwing iterator reports exhaustion")
    func safePythonObjectThrowingIteratorReportsExhaustion() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let list = try isolatedInterpreter.convertToSafePython(array: [10, 20])
            var iterator = try list.pythonIterator()
            
            #expect(try Int(iterator.nextThrowing()!) == 10)
            #expect(try Int(iterator.nextThrowing()!) == 20)
            #expect(try iterator.nextThrowing() == nil)
            #expect(try iterator.nextThrowing() == nil)
        }
    }
    
    @Test("ITER_008: SafePythonObject items sequence yields key-value pairs")
    func safePythonObjectItemsSequenceYieldsPairs() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let dict = try isolatedInterpreter.convertToSafePython(dictionary: [
                "one": 1,
                "two": 2,
                "three": 3
            ])
            
            var pairs: [String: Int] = [:]
            var iterator = dict.items().makeIterator()
            while let item = try iterator.nextThrowing() {
                pairs[try String(item.key)] = try Int(item.value)
            }
            
            #expect(pairs == ["one": 1, "two": 2, "three": 3])
        }
    }
    
    @Test("ITER_009: SafePythonObject throwing iterator rejects non-iterables")
    func safePythonObjectThrowingIteratorRejectsNonIterables() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let number = try isolatedInterpreter.convertToSafePython(int: 42)
            
            let thrownError = #expect(throws: PythonError.self) {
                _ = try number.pythonIterator()
            }
            
            if case .safePythonException = thrownError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for safe non-iterable iteration, got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("ITER_010: SafePythonObject throwing iterator propagates mid-iteration errors")
    func safePythonObjectThrowingIteratorPropagatesMidIterationErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            try isolatedInterpreter.runSimpleString(pythonCode: """
            class Swift2PythonSafeExplodingIterator:
                def __iter__(self):
                    return self
                def __next__(self):
                    raise RuntimeError("safe iteration exploded")
            """)
            let explodingType = isolatedInterpreter.globals["Swift2PythonSafeExplodingIterator"]
            let exploding = try explodingType()
            var iterator = try exploding.pythonIterator()
            
            let thrownError = #expect(throws: PythonError.self) {
                _ = try iterator.nextThrowing()
            }
            
            if case .safePythonException = thrownError {
                // expected
            } else {
                Issue.record("Expected .safePythonException for safe iterator error, got \(String(describing: thrownError))")
            }
        }
    }
    
    @Test("ITER_011: PythonObject AsyncIterator propagates mid-iteration errors")
    func pythonObjectAsyncIteratorPropagatesMidIterationErrors() async throws {
        try await interpreter.runSimpleString(pythonCode: """
        class Swift2PythonAsyncExplodingIterator:
            def __iter__(self):
                return self
            def __next__(self):
                raise RuntimeError("async iteration exploded")
        """)
        let globals = try await interpreter.getGlobals()
        let explodingType = try await globals.getItem(key: "Swift2PythonAsyncExplodingIterator")
        let exploding = try await interpreter.callPythonCallable(explodingType, args: [], kwargs: [:])
        var iterator = exploding.makeAsyncIterator()
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await iterator.next()
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for async iterator error, got \(String(describing: thrownError))")
        }
    }
}
