//
//  SetTest.swift
//  Swift2Python
//
//  Created by Ben White on 6/8/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Set Tests")
struct SetTests {
    
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
    
    private func asyncInts(fromSet set: PythonObject) async throws -> Set<Int> {
        var values = Set<Int>()
        for item in try await set.asSetArray() {
            values.insert(try await Int(item))
        }
        return values
    }
    
    private func asyncStrings(fromSet set: PythonObject) async throws -> Set<String> {
        var values = Set<String>()
        for item in try await set.asSetArray() {
            values.insert(try await String(item))
        }
        return values
    }
    
    private func safeInts(fromSet set: PythonInterpreter.SafePythonObject) throws -> Set<Int> {
        var values = Set<Int>()
        for item in try set.setArray {
            values.insert(try Int(item))
        }
        return values
    }
    
    private func safeStrings(fromSet set: PythonInterpreter.SafePythonObject) throws -> Set<String> {
        var values = Set<String>()
        for item in try set.setArray {
            values.insert(try String(item))
        }
        return values
    }
    
    @Test("SET_001: PythonObject set creation, inspection, and array conversion")
    func asyncSetCreationAndInspection() async throws {
        let set = try await interpreter.convertToPython(set: Set([1, 2, 3]))
        
        #expect(try await set.isSet())
        #expect(try await set.isFrozenSet() == false)
        #expect(try await set.isAnySet())
        #expect(try await set.setCount() == 3)
        #expect(try await asyncInts(fromSet: set) == Set([1, 2, 3]))
        
        let empty = try await interpreter.convertToPython(set: Set<Int>())
        #expect(try await empty.isSet())
        #expect(try await empty.setCount() == 0)
        #expect(try await asyncInts(fromSet: empty).isEmpty)
        
        let direct = try await Set(["red", "green", "blue"]).toPythonObject(interpreter: interpreter)
        #expect(try await direct.isSet())
        #expect(try await asyncStrings(fromSet: direct) == Set(["red", "green", "blue"]))
    }
    
    @Test("SET_002: PythonObject set contains, add, remove, and discard helpers")
    func asyncSetHelpers() async throws {
        let set = try await interpreter.convertToPython(set: Set([1, 2, 3]))
        
        #expect(try await set.setContains(2))
        #expect(try await set.setContains(4) == false)
        
        try await set.setAdd(4)
        #expect(try await set.setContains(4))
        #expect(try await asyncInts(fromSet: set) == Set([1, 2, 3, 4]))
        
        try await set.setDiscard(99)
        #expect(try await asyncInts(fromSet: set) == Set([1, 2, 3, 4]))
        
        try await set.setDiscard(1)
        #expect(try await asyncInts(fromSet: set) == Set([2, 3, 4]))
        
        try await set.setRemove(2)
        #expect(try await asyncInts(fromSet: set) == Set([3, 4]))
        
        let missingRemoveError = await #expect(throws: PythonError.self) {
            try await set.setRemove(2)
        }
        if case .pythonException = missingRemoveError {
        } else {
            Issue.record("Expected .pythonException for removing a missing set item, but got \(missingRemoveError)")
        }
    }
    
    @Test("SET_003: PythonObject normal Python set methods")
    func asyncPythonSetMethods() async throws {
        let set = try await interpreter.convertToPython(set: Set([1, 2, 3]))
        let other = try await interpreter.convertToPython(set: Set([3, 4]))
        
        let union = try await set.union(other)
        #expect(try await asyncInts(fromSet: union) == Set([1, 2, 3, 4]))
        
        let intersection = try await set.intersection(other)
        #expect(try await asyncInts(fromSet: intersection) == Set([3]))
        
        let difference = try await set.difference(other)
        #expect(try await asyncInts(fromSet: difference) == Set([1, 2]))
        
        let symmetricDifference = try await set.symmetric_difference(other)
        #expect(try await asyncInts(fromSet: symmetricDifference) == Set([1, 2, 4]))
        
        #expect(try await Bool(set.issuperset(try await interpreter.convertToPython(set: Set([1, 2])))))
        #expect(try await Bool(other.isdisjoint(try await interpreter.convertToPython(set: Set([1, 2])))))
        #expect(try await Bool((try await interpreter.convertToPython(set: Set([1, 2]))).issubset(set)))
        
        let copy = try await set.copy()
        #expect(try await asyncInts(fromSet: copy) == Set([1, 2, 3]))
        
        let popped = try await set.pop()
        let poppedInt = try await Int(popped)
        #expect(Set([1, 2, 3]).contains(poppedInt))
        #expect(try await set.setCount() == 2)
        
        _ = try await set.update([5, 6])
        #expect(try await set.setContains(5))
        #expect(try await set.setContains(6))
        
        _ = try await set.clear()
        #expect(try await set.setCount() == 0)
        
        let emptyPopError = await #expect(throws: PythonError.self) {
            _ = try await set.pop()
        }
        if case .pythonException = emptyPopError {
        } else {
            Issue.record("Expected .pythonException for pop on an empty set, but got \(emptyPopError)")
        }
    }
    
    @Test("SET_004: PythonObject frozenset creation, inspection, and immutable behavior")
    func asyncFrozenSetCreationAndInspection() async throws {
        let frozenSet = try await interpreter.convertToPython(frozenSet: Set([1, 2, 3]))
        
        #expect(try await frozenSet.isSet() == false)
        #expect(try await frozenSet.isFrozenSet())
        #expect(try await frozenSet.isAnySet())
        #expect(try await frozenSet.setCount() == 3)
        #expect(try await frozenSet.setContains(2))
        #expect(try await asyncInts(fromSet: frozenSet) == Set([1, 2, 3]))
        
        let union = try await frozenSet.union([3, 4])
        #expect(try await asyncInts(fromSet: union) == Set([1, 2, 3, 4]))
        
        let addError = await #expect(throws: PythonError.self) {
            try await frozenSet.setAdd(4)
        }
        if case .setConversionFailed = addError {
        } else {
            Issue.record("Expected .setConversionFailed for setAdd on frozenset, but got \(addError)")
        }
        
        let discardError = await #expect(throws: PythonError.self) {
            try await frozenSet.setDiscard(1)
        }
        if case .setConversionFailed = discardError {
        } else {
            Issue.record("Expected .setConversionFailed for setDiscard on frozenset, but got \(discardError)")
        }
        
        let pythonPopError = await #expect(throws: PythonError.self) {
            _ = try await frozenSet.pop()
        }
        if case .pythonException = pythonPopError {
        } else {
            Issue.record("Expected .pythonException for Python pop on frozenset, but got \(pythonPopError)")
        }
    }
    
    @Test("SET_005: PythonObject set error handling")
    func asyncSetErrors() async throws {
        let notSet = try await 99.toPythonObject(interpreter: interpreter)
        #expect(try await notSet.isSet() == false)
        #expect(try await notSet.isFrozenSet() == false)
        #expect(try await notSet.isAnySet() == false)
        
        let countError = await #expect(throws: PythonError.self) {
            _ = try await notSet.setCount()
        }
        if case .setConversionFailed = countError {
        } else {
            Issue.record("Expected .setConversionFailed for setCount on non-set, but got \(countError)")
        }
        
        let arrayError = await #expect(throws: PythonError.self) {
            _ = try await notSet.asSetArray()
        }
        if case .setConversionFailed = arrayError {
        } else {
            Issue.record("Expected .setConversionFailed for asSetArray on non-set, but got \(arrayError)")
        }
        
        let containsError = await #expect(throws: PythonError.self) {
            _ = try await notSet.setContains(1)
        }
        if case .setConversionFailed = containsError {
        } else {
            Issue.record("Expected .setConversionFailed for setContains on non-set, but got \(containsError)")
        }
        
        let addError = await #expect(throws: PythonError.self) {
            try await notSet.setAdd(1)
        }
        if case .setConversionFailed = addError {
        } else {
            Issue.record("Expected .setConversionFailed for setAdd on non-set, but got \(addError)")
        }
        
        let removeError = await #expect(throws: PythonError.self) {
            try await notSet.setRemove(1)
        }
        if case .setConversionFailed = removeError {
        } else {
            Issue.record("Expected .setConversionFailed for setRemove on non-set, but got \(removeError)")
        }
        
        let discardError = await #expect(throws: PythonError.self) {
            try await notSet.setDiscard(1)
        }
        if case .setConversionFailed = discardError {
        } else {
            Issue.record("Expected .setConversionFailed for setDiscard on non-set, but got \(discardError)")
        }
    }
    
    @Test("SET_010: SafePythonObject set creation, inspection, and array conversion")
    func safeSetCreationAndInspection() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let set = try isolatedInterpreter.convertToSafePython(set: Set([1, 2, 3]))
            
            #expect(try set.isSet)
            #expect(try set.isFrozenSet == false)
            #expect(try set.isAnySet)
            #expect(try set.setCount == 3)
            #expect(try safeInts(fromSet: set) == Set([1, 2, 3]))
            
            let empty = try isolatedInterpreter.convertToSafePython(set: Set<Int>())
            #expect(try empty.isSet)
            #expect(try empty.setCount == 0)
            #expect(try safeInts(fromSet: empty).isEmpty)
            
            let direct = try Set(["red", "green", "blue"]).toSafePythonObject(interpreter: isolatedInterpreter)
            #expect(try direct.isSet)
            #expect(try safeStrings(fromSet: direct) == Set(["red", "green", "blue"]))
        }
    }
    
    @Test("SET_011: SafePythonObject set helpers and normal Python methods")
    func safeSetHelpersAndPythonMethods() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let set = try isolatedInterpreter.convertToSafePython(set: Set([1, 2, 3]))
            let other = try isolatedInterpreter.convertToSafePython(set: Set([3, 4]))
            
            #expect(try set.setContains(2))
            #expect(try set.setContains(4) == false)
            
            try set.setAdd(4)
            #expect(try safeInts(fromSet: set) == Set([1, 2, 3, 4]))
            
            try set.setDiscard(99)
            try set.setDiscard(1)
            #expect(try safeInts(fromSet: set) == Set([2, 3, 4]))
            
            try set.setRemove(2)
            #expect(try safeInts(fromSet: set) == Set([3, 4]))
            
            let union = try set.union(other)
            #expect(try safeInts(fromSet: union) == Set([3, 4]))
            
            let copied = try set.copy()
            #expect(try safeInts(fromSet: copied) == Set([3, 4]))
            
            let popped = try set.pop()
            #expect(Set([3, 4]).contains(try Int(popped)))
            #expect(try set.setCount == 1)
            
            _ = try set.update([5, 6])
            #expect(try set.setContains(5))
            #expect(try set.setContains(6))
            
            _ = try set.clear()
            #expect(try set.setCount == 0)
            
            let emptyPopError = #expect(throws: PythonError.self) {
                _ = try set.pop()
            }
            if case .safePythonException = emptyPopError {
            } else {
                Issue.record("Expected .safePythonException for pop on an empty safe set, but got \(emptyPopError)")
            }
        }
    }
    
    @Test("SET_012: SafePythonObject frozenset creation and immutable behavior")
    func safeFrozenSetCreationAndInspection() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let frozenSet = try isolatedInterpreter.convertToSafePython(frozenSet: Set([1, 2, 3]))
            
            #expect(try frozenSet.isSet == false)
            #expect(try frozenSet.isFrozenSet)
            #expect(try frozenSet.isAnySet)
            #expect(try frozenSet.setCount == 3)
            #expect(try frozenSet.setContains(2))
            #expect(try safeInts(fromSet: frozenSet) == Set([1, 2, 3]))
            
            let union = try frozenSet.union([3, 4])
            #expect(try safeInts(fromSet: union) == Set([1, 2, 3, 4]))
            
            let addError = #expect(throws: PythonError.self) {
                try frozenSet.setAdd(4)
            }
            if case .setConversionFailed = addError {
            } else {
                Issue.record("Expected .setConversionFailed for setAdd on safe frozenset, but got \(addError)")
            }
            
            let removeError = #expect(throws: PythonError.self) {
                try frozenSet.setRemove(1)
            }
            if case .setConversionFailed = removeError {
            } else {
                Issue.record("Expected .setConversionFailed for setRemove on safe frozenset, but got \(removeError)")
            }
            
            let pythonPopError = #expect(throws: PythonError.self) {
                _ = try frozenSet.get(attr: "pop")
            }
            if case .safePythonException = pythonPopError {
            } else {
                Issue.record("Expected .safePythonException for Python pop lookup on safe frozenset, but got \(pythonPopError)")
            }
        }
    }
    
    @Test("SET_013: SafePythonObject set error handling")
    func safeSetErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let notSet = try 99.toSafePythonObject(interpreter: isolatedInterpreter)
            #expect(try notSet.isSet == false)
            #expect(try notSet.isFrozenSet == false)
            #expect(try notSet.isAnySet == false)
            
            let countError = #expect(throws: PythonError.self) {
                _ = try notSet.setCount
            }
            if case .setConversionFailed = countError {
            } else {
                Issue.record("Expected .setConversionFailed for safe setCount on non-set, but got \(countError)")
            }
            
            let arrayError = #expect(throws: PythonError.self) {
                _ = try notSet.setArray
            }
            if case .setConversionFailed = arrayError {
            } else {
                Issue.record("Expected .setConversionFailed for safe setArray on non-set, but got \(arrayError)")
            }
            
            let containsError = #expect(throws: PythonError.self) {
                _ = try notSet.setContains(1)
            }
            if case .setConversionFailed = containsError {
            } else {
                Issue.record("Expected .setConversionFailed for safe setContains on non-set, but got \(containsError)")
            }
            
            let addError = #expect(throws: PythonError.self) {
                try notSet.setAdd(1)
            }
            if case .setConversionFailed = addError {
            } else {
                Issue.record("Expected .setConversionFailed for safe setAdd on non-set, but got \(addError)")
            }
            
            let discardError = #expect(throws: PythonError.self) {
                try notSet.setDiscard(1)
            }
            if case .setConversionFailed = discardError {
            } else {
                Issue.record("Expected .setConversionFailed for safe setDiscard on non-set, but got \(discardError)")
            }
            
            let set = try isolatedInterpreter.convertToSafePython(set: Set([1, 2, 3]))
            let unhashable = try isolatedInterpreter.convertToSafePython(array: [4, 5])
            let unhashableAddError = #expect(throws: PythonError.self) {
                try set.setAdd(unhashable)
            }
            if case .safePythonException = unhashableAddError {
            } else {
                Issue.record("Expected .safePythonException for adding an unhashable list to a safe set, but got \(unhashableAddError)")
            }
        }
    }
}
