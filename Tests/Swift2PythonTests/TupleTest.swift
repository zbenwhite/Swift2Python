//
//  TupleTest.swift
//  Swift2Python
//
//  Created by Ben White on 5/26/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Tuple Tests")
struct TupleTests {
    
    private static let setupLogging: Void = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
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
        interpreter = try await Self.sharedInterpreterTask.value
    }
    
    @Test("TUP_001: PythonObject tuple creation and inspection")
    func asyncTupleCreationAndInspection() async throws {
        let tuple = try await interpreter.convertToPython(tupleOf: 10, "two", 3.5, true)
        
        #expect(try await tuple.isTuple())
        #expect(try await tuple.tupleCount() == 4)
        
        let first = try await tuple.tupleItem(at: 0)
        let second = try await tuple.tupleItem(at: 1)
        let third = try await tuple.tupleItem(at: 2)
        let fourth = try await tuple.tupleItem(at: 3)
        
        #expect(try await Int(first) == 10)
        #expect(try await String(second) == "two")
        #expect(try await Double(third) == 3.5)
        #expect(try await Bool(fourth) == true)
    }
    
    @Test("TUP_002: PythonObject tupleContentsOf and asTupleArray")
    func asyncTupleContentsOfAndArray() async throws {
        let values = [1, 2, 3, 4]
        let tuple = try await interpreter.convertToPython(tupleContentsOf: values)
        let elements = try await tuple.asTupleArray()
        
        #expect(elements.count == values.count)
        for (index, element) in elements.enumerated() {
            #expect(try await Int(element) == values[index], Comment(rawValue: "Tuple element \(index)"))
        }
    }
    
    @Test("TUP_003: PythonObject fixed-size tuple unpacking")
    func asyncFixedSizeTupleUnpacking() async throws {
        let tuple2 = try await interpreter.convertToPython(tupleOf: "left", 42)
        let pair = try await tuple2.asTuple2()
        #expect(try await String(pair.0) == "left")
        #expect(try await Int(pair.1) == 42)
        
        let tuple3 = try await interpreter.convertToPython(tupleOf: 1.25, 2.5, 5.0)
        let triple = try await tuple3.asTuple3()
        #expect(try await Double(triple.0) == 1.25)
        #expect(try await Double(triple.1) == 2.5)
        #expect(try await Double(triple.2) == 5.0)
        
        let tuple4 = try await interpreter.convertToPython(tupleOf: 1, 2, 3, 4)
        let quad = try await tuple4.asTuple4()
        #expect(try await Int(quad.0) == 1)
        #expect(try await Int(quad.1) == 2)
        #expect(try await Int(quad.2) == 3)
        #expect(try await Int(quad.3) == 4)
    }
    
    @Test("TUP_004: PythonObject tuple error behavior")
    func asyncTupleErrors() async throws {
        let notTuple = try await 99.toPythonObject(interpreter: interpreter)
        #expect(try await notTuple.isTuple() == false)
        
        let countError = await #expect(throws: PythonError.self) {
            _ = try await notTuple.tupleCount()
        }
        if case .tupleConversionFailed = countError {
        } else {
            Issue.record("Expected .tupleConversionFailed for tupleCount on non-tuple, but got \(countError)")
        }
        
        let arrayError = await #expect(throws: PythonError.self) {
            _ = try await notTuple.asTupleArray()
        }
        if case .tupleConversionFailed = arrayError {
        } else {
            Issue.record("Expected .tupleConversionFailed for asTupleArray on non-tuple, but got \(arrayError)")
        }
        
        let tuple3 = try await interpreter.convertToPython(tupleOf: 1, 2, 3)
        let itemError = await #expect(throws: PythonError.self) {
            _ = try await tuple3.tupleItem(at: 3)
        }
        if case .pythonException = itemError {
        } else {
            Issue.record("Expected .pythonException for out-of-bounds tupleItem, but got \(itemError)")
        }
        
        let arityError = await #expect(throws: PythonError.self) {
            _ = try await tuple3.asTuple2()
        }
        if case let .tupleArityMismatch(expected, actual) = arityError {
            #expect(expected == 2)
            #expect(actual == 3)
        } else {
            Issue.record("Expected .tupleArityMismatch for asTuple2 on 3-tuple, but got \(arityError)")
        }
    }
    
    @Test("TUP_010: SafePythonObject tuple creation and inspection")
    func safeTupleCreationAndInspection() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let tuple = try isolatedInterpreter.convertToSafePython(tupleOf: 10, "two", 3.5, true)
            
            #expect(try tuple.isTuple)
            #expect(try tuple.tupleCount == 4)
            
            let first = try tuple.tupleItem(at: 0)
            let second = try tuple.tupleItem(at: 1)
            let third = try tuple.tupleItem(at: 2)
            let fourth = try tuple.tupleItem(at: 3)
            
            #expect(try Int(first) == 10)
            #expect(try String(second) == "two")
            #expect(try Double(third) == 3.5)
            #expect(try Bool(fourth) == true)
        }
    }
    
    @Test("TUP_011: SafePythonObject tuple array and fixed-size unpacking")
    func safeTupleArrayAndFixedSizeUnpacking() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let tuple = try isolatedInterpreter.convertToSafePython(tupleContentsOf: [1, 2, 3, 4])
            let elements = try tuple.tupleArray
            
            #expect(elements.count == 4)
            #expect(try Int(elements[0]) == 1)
            #expect(try Int(elements[1]) == 2)
            #expect(try Int(elements[2]) == 3)
            #expect(try Int(elements[3]) == 4)
            
            let tuple2 = try isolatedInterpreter.convertToSafePython(tupleOf: "left", 42)
            let pair = try tuple2.tuple2
            #expect(try String(pair.0) == "left")
            #expect(try Int(pair.1) == 42)
            
            let tuple3 = try isolatedInterpreter.convertToSafePython(tupleOf: 1.25, 2.5, 5.0)
            let triple = try tuple3.tuple3
            #expect(try Double(triple.0) == 1.25)
            #expect(try Double(triple.1) == 2.5)
            #expect(try Double(triple.2) == 5.0)
            
            let tuple4 = try isolatedInterpreter.convertToSafePython(tupleOf: 1, 2, 3, 4)
            let quad = try tuple4.tuple4
            #expect(try Int(quad.0) == 1)
            #expect(try Int(quad.1) == 2)
            #expect(try Int(quad.2) == 3)
            #expect(try Int(quad.3) == 4)
        }
    }
    
    @Test("TUP_012: SafePythonObject tuple throwing behavior")
    func safeTupleThrowingBehavior() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let notTuple = try 99.toSafePythonObject(interpreter: isolatedInterpreter)
            #expect(try notTuple.isTuple == false)
            
            let countError = #expect(throws: PythonError.self) {
                _ = try notTuple.tupleCount
            }
            if case .tupleConversionFailed = countError {
            } else {
                Issue.record("Expected .tupleConversionFailed for tupleCount on non-tuple, but got \(countError)")
            }
            
            let arrayError = #expect(throws: PythonError.self) {
                _ = try notTuple.tupleArray
            }
            if case .tupleConversionFailed = arrayError {
            } else {
                Issue.record("Expected .tupleConversionFailed for tupleArray on non-tuple, but got \(arrayError)")
            }
            
            let itemError = #expect(throws: PythonError.self) {
                _ = try notTuple.tupleItem(at: 0)
            }
            if case .tupleConversionFailed = itemError {
            } else {
                Issue.record("Expected .tupleConversionFailed for tupleItem on non-tuple, but got \(itemError)")
            }
            
            let tuple2Error = #expect(throws: PythonError.self) {
                _ = try notTuple.tuple2
            }
            if case .tupleConversionFailed = tuple2Error {
            } else {
                Issue.record("Expected .tupleConversionFailed for tuple2 on non-tuple, but got \(tuple2Error)")
            }
            
            let tuple3 = try isolatedInterpreter.convertToSafePython(tupleOf: 1, 2, 3)
            let boundsError = #expect(throws: PythonError.self) {
                _ = try tuple3.tupleItem(at: 3)
            }
            if case .safePythonException = boundsError {
            } else {
                Issue.record("Expected .safePythonException for out-of-bounds tupleItem, but got \(boundsError)")
            }
            
            let arity2Error = #expect(throws: PythonError.self) {
                _ = try tuple3.tuple2
            }
            if case let .tupleArityMismatch(expected, actual) = arity2Error {
                #expect(expected == 2)
                #expect(actual == 3)
            } else {
                Issue.record("Expected .tupleArityMismatch for tuple2 on 3-tuple, but got \(arity2Error)")
            }
            
            let triple = try tuple3.tuple3
            #expect(try Int(triple.0) == 1)
            #expect(try Int(triple.1) == 2)
            #expect(try Int(triple.2) == 3)
            
            let arity4Error = #expect(throws: PythonError.self) {
                _ = try tuple3.tuple4
            }
            if case let .tupleArityMismatch(expected, actual) = arity4Error {
                #expect(expected == 4)
                #expect(actual == 3)
            } else {
                Issue.record("Expected .tupleArityMismatch for tuple4 on 3-tuple, but got \(arity4Error)")
            }
        }
    }
}
