//
//  ListTest.swift
//  Swift2Python
//
//  Created by Ben White on 6/4/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("List Tests")
struct ListTests {
    
    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        interpreter = try await Self.sharedInterpreterTask.value
    }
    
    private func asyncInts(from list: PythonObject) async throws -> [Int] {
        var values: [Int] = []
        for item in try await list.asArray() {
            values.append(try await Int(item))
        }
        return values
    }
    
    private func safeInts(from list: PythonInterpreter.SafePythonObject) throws -> [Int] {
        try list.listArray.map { try Int($0) }
    }
    
    @Test("LIS_001: PythonObject list creation, inspection, and array conversion")
    func asyncListCreationAndInspection() async throws {
        let list = try await interpreter.convertToPython(array: [1, 2, 3, 4])
        
        #expect(try await list.isList())
        #expect(try await list.listCount() == 4)
        #expect(try await asyncInts(from: list) == [1, 2, 3, 4])
        
        let empty = try await interpreter.convertToPython(array: [] as [Int])
        #expect(try await empty.isList())
        #expect(try await empty.listCount() == 0)
        #expect(try await asyncInts(from: empty).isEmpty)
    }
    
    @Test("LIS_002: PythonObject list item access and mutation")
    func asyncListItemAccessAndMutation() async throws {
        let list = try await interpreter.convertToPython(array: [10, 20, 30])
        
        #expect(try await Int(list.listItem(at: 0)) == 10)
        #expect(try await Int(list.listItem(at: 1)) == 20)
        #expect(try await Int(list.listItem(at: -1)) == 30)
        #expect(try await Int(list.listItem(at: -2)) == 20)
        
        try await list.listSetItem(at: 1, to: 200)
        #expect(try await asyncInts(from: list) == [10, 200, 30])
        
        try await list.listSetItem(at: -1, to: 300)
        #expect(try await asyncInts(from: list) == [10, 200, 300])
    }
    
    @Test("LIS_003: PythonObject list append, insert, and delete")
    func asyncListAppendInsertAndDelete() async throws {
        let list = try await interpreter.convertToPython(array: [1, 3])
        
        try await list.listAppendItem(4)
        #expect(try await asyncInts(from: list) == [1, 3, 4])
        
        try await list.listInsertItem(2, at: 1)
        #expect(try await asyncInts(from: list) == [1, 2, 3, 4])
        
        try await list.listInsertItem(0, at: 0)
        #expect(try await asyncInts(from: list) == [0, 1, 2, 3, 4])
        
        try await list.listDeleteItem(at: 0)
        #expect(try await asyncInts(from: list) == [1, 2, 3, 4])
        
        try await list.listDeleteItem(at: -1)
        #expect(try await asyncInts(from: list) == [1, 2, 3])
    }
    
    @Test("LIS_004: PythonObject generic item access, setItem, and slicing through builtins.slice")
    func asyncGenericItemAccessAndSlicing() async throws {
        let list = try await interpreter.convertToPython(array: [1, 2, 3, 4, 5])
        let builtins = try await interpreter.getBuiltins()
        
        #expect(try await Int(list.getItem(key: 0)) == 1)
        #expect(try await Int(list.getItem(key: -1)) == 5)
        
        try await list.setItem(key: 0, newValue: 10)
        #expect(try await asyncInts(from: list) == [10, 2, 3, 4, 5])
        
        let slice = try await builtins.slice(1, 4)
        let sliced = try await list.getItem(key: slice)
        #expect(try await asyncInts(from: sliced) == [2, 3, 4])
        
        let rangeSliced = try await list.getItem(key: 1..<4)
        #expect(try await asyncInts(from: rangeSliced) == [2, 3, 4])
        
        let closedRangeSliced = try await list.getItem(key: 1...3)
        #expect(try await asyncInts(from: closedRangeSliced) == [2, 3, 4])
        
        let partialFromSliced = try await list.getItem(key: 2...)
        #expect(try await asyncInts(from: partialFromSliced) == [3, 4, 5])
        
        let partialUpToSliced = try await list.getItem(key: ..<3)
        #expect(try await asyncInts(from: partialUpToSliced) == [10, 2, 3])
        
        let partialThroughSliced = try await list.getItem(key: ...2)
        #expect(try await asyncInts(from: partialThroughSliced) == [10, 2, 3])
        
        let replacement = try await interpreter.convertToPython(array: [20, 30])
        try await list.setItem(key: slice, newValue: replacement)
        #expect(try await asyncInts(from: list) == [10, 20, 30, 5])
        
        let rangeReplacement = try await interpreter.convertToPython(array: [200, 300, 400])
        try await list.setItem(key: 1..<3, newValue: rangeReplacement)
        #expect(try await asyncInts(from: list) == [10, 200, 300, 400, 5])
    }
    
    @Test("LIS_005: PythonObject normal Python list methods")
    func asyncPythonListMethods() async throws {
        let list = try await interpreter.convertToPython(array: [3, 1, 2, 2])
        let builtins = try await interpreter.getBuiltins()
        
        #expect(try await Int(list.count(2)) == 2)
        #expect(try await Int(list.index(1)) == 1)
        
        _ = try await list.append(4)
        #expect(try await asyncInts(from: list) == [3, 1, 2, 2, 4])
        
        _ = try await list.extend([5, 6])
        #expect(try await asyncInts(from: list) == [3, 1, 2, 2, 4, 5, 6])
        
        _ = try await list.remove(2)
        #expect(try await asyncInts(from: list) == [3, 1, 2, 4, 5, 6])
        
        let popped = try await list.pop()
        #expect(try await Int(popped) == 6)
        #expect(try await asyncInts(from: list) == [3, 1, 2, 4, 5])
        
        _ = try await list.reverse()
        #expect(try await asyncInts(from: list) == [5, 4, 2, 1, 3])
        
        _ = try await list.sort()
        #expect(try await asyncInts(from: list) == [1, 2, 3, 4, 5])
        
        let tuple = try await builtins.tuple(list)
        #expect(try await tuple.isTuple())
        #expect(try await tuple.tupleCount() == 5)
        #expect(try await Int(tuple.tupleItem(at: 0)) == 1)
        #expect(try await Int(tuple.tupleItem(at: 4)) == 5)
        
        let copied = try await list.copy()
        _ = try await list.clear()
        #expect(try await list.listCount() == 0)
        #expect(try await asyncInts(from: copied) == [1, 2, 3, 4, 5])
    }
    
    @Test("LIS_006: PythonObject list conversions with heterogeneous values")
    func asyncHeterogeneousListConversion() async throws {
        let source: [any PendingPythonConvertible] = ["name", 3, true, 2.5]
        let list = try await interpreter.convertToPython(array: source)
        
        #expect(try await list.isList())
        #expect(try await list.listCount() == 4)
        #expect(try await String(list.listItem(at: 0)) == "name")
        #expect(try await Int(list.listItem(at: 1)) == 3)
        #expect(try await Bool(list.listItem(at: 2)) == true)
        #expect(try await Double(list.listItem(at: 3)) == 2.5)
    }
    
    @Test("LIS_007: PythonObject list error behavior")
    func asyncListErrors() async throws {
        let notList = try await 99.toPythonObject(interpreter: interpreter)
        #expect(try await notList.isList() == false)
        
        let countError = await #expect(throws: PythonError.self) {
            _ = try await notList.listCount()
        }
        if case .listConversionFailed = countError {
        } else {
            Issue.record("Expected .listConversionFailed for listCount on non-list, but got \(countError)")
        }
        
        let arrayError = await #expect(throws: PythonError.self) {
            _ = try await notList.asArray()
        }
        if case .listConversionFailed = arrayError {
        } else {
            Issue.record("Expected .listConversionFailed for asArray on non-list, but got \(arrayError)")
        }
        
        let itemTypeError = await #expect(throws: PythonError.self) {
            _ = try await notList.listItem(at: 0)
        }
        if case .listConversionFailed = itemTypeError {
        } else {
            Issue.record("Expected .listConversionFailed for listItem on non-list, but got \(itemTypeError)")
        }
        
        let setTypeError = await #expect(throws: PythonError.self) {
            try await notList.listSetItem(at: 0, to: 1)
        }
        if case .listConversionFailed = setTypeError {
        } else {
            Issue.record("Expected .listConversionFailed for listSetItem on non-list, but got \(setTypeError)")
        }
        
        let appendTypeError = await #expect(throws: PythonError.self) {
            try await notList.listAppendItem(1)
        }
        if case .listConversionFailed = appendTypeError {
        } else {
            Issue.record("Expected .listConversionFailed for listAppendItem on non-list, but got \(appendTypeError)")
        }
        
        let insertTypeError = await #expect(throws: PythonError.self) {
            try await notList.listInsertItem(1, at: 0)
        }
        if case .listConversionFailed = insertTypeError {
        } else {
            Issue.record("Expected .listConversionFailed for listInsertItem on non-list, but got \(insertTypeError)")
        }
        
        let deleteTypeError = await #expect(throws: PythonError.self) {
            try await notList.listDeleteItem(at: 0)
        }
        if case .listConversionFailed = deleteTypeError {
        } else {
            Issue.record("Expected .listConversionFailed for listDeleteItem on non-list, but got \(deleteTypeError)")
        }
        
        let list = try await interpreter.convertToPython(array: [1, 2, 3])
        let itemBoundsError = await #expect(throws: PythonError.self) {
            _ = try await list.listItem(at: 3)
        }
        if case .pythonException = itemBoundsError {
        } else {
            Issue.record("Expected .pythonException for out-of-bounds listItem, but got \(itemBoundsError)")
        }
        
        let negativeItemBoundsError = await #expect(throws: PythonError.self) {
            _ = try await list.listItem(at: -4)
        }
        if case .pythonException = negativeItemBoundsError {
        } else {
            Issue.record("Expected .pythonException for negative out-of-bounds listItem, but got \(negativeItemBoundsError)")
        }
        
        let setBoundsError = await #expect(throws: PythonError.self) {
            try await list.listSetItem(at: 3, to: 4)
        }
        if case .pythonException = setBoundsError {
        } else {
            Issue.record("Expected .pythonException for out-of-bounds listSetItem, but got \(setBoundsError)")
        }
        
        let deleteBoundsError = await #expect(throws: PythonError.self) {
            try await list.listDeleteItem(at: 3)
        }
        if case .pythonException = deleteBoundsError {
        } else {
            Issue.record("Expected .pythonException for out-of-bounds listDeleteItem, but got \(deleteBoundsError)")
        }
    }
    
    @Test("LIS_010: SafePythonObject list creation, inspection, and array conversion")
    func safeListCreationAndInspection() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let list = try isolatedInterpreter.convertToSafePython(array: [1, 2, 3, 4])
            
            #expect(try list.isList)
            #expect(try list.listCount == 4)
            #expect(try safeInts(from: list) == [1, 2, 3, 4])
            
            let empty = try isolatedInterpreter.convertToSafePython(array: [] as [Int])
            #expect(try empty.isList)
            #expect(try empty.listCount == 0)
            #expect(try safeInts(from: empty).isEmpty)
        }
    }
    
    @Test("LIS_011: SafePythonObject list item access and mutation")
    func safeListItemAccessAndMutation() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let list = try isolatedInterpreter.convertToSafePython(array: [10, 20, 30])
            
            #expect(try Int(list.listItem(at: 0)) == 10)
            #expect(try Int(list.listItem(at: 1)) == 20)
            #expect(try Int(list.listItem(at: -1)) == 30)
            #expect(try Int(list.listItem(at: -2)) == 20)
            
            try list.listSetItem(at: 1, to: 200)
            #expect(try safeInts(from: list) == [10, 200, 30])
            
            try list.listSetItem(at: -1, to: 300)
            #expect(try safeInts(from: list) == [10, 200, 300])
        }
    }
    
    @Test("LIS_012: SafePythonObject list append, insert, and delete")
    func safeListAppendInsertAndDelete() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let list = try isolatedInterpreter.convertToSafePython(array: [1, 3])
            
            try list.listAppendItem(4)
            #expect(try safeInts(from: list) == [1, 3, 4])
            
            try list.listInsertItem(2, at: 1)
            #expect(try safeInts(from: list) == [1, 2, 3, 4])
            
            try list.listInsertItem(0, at: 0)
            #expect(try safeInts(from: list) == [0, 1, 2, 3, 4])
            
            try list.listDeleteItem(at: 0)
            #expect(try safeInts(from: list) == [1, 2, 3, 4])
            
            try list.listDeleteItem(at: -1)
            #expect(try safeInts(from: list) == [1, 2, 3])
        }
    }
    
    @Test("LIS_013: SafePythonObject subscript, negative subscript, slicing, and slice assignment")
    func safeSubscriptAndSlicing() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var list = try isolatedInterpreter.convertToSafePython(array: [1, 2, 3, 4, 5])
            
            #expect(try Int(list[0]) == 1)
            #expect(try Int(list[-1]) == 5)
            
            list[0] = 10
            list[-1] = 50
            #expect(try safeInts(from: list) == [10, 2, 3, 4, 50])
            
            let sliced = list[.slice(1, 4)]
            #expect(try safeInts(from: sliced) == [2, 3, 4])
            
            let firstThree = list[.slice(nil, 3)]
            #expect(try safeInts(from: firstThree) == [10, 2, 3])
            
            let everyOther = list[.slice(nil, nil, step: 2)]
            #expect(try safeInts(from: everyOther) == [10, 3, 50])
            
            let reversed = list[.slice(nil, nil, step: -1)]
            #expect(try safeInts(from: reversed) == [50, 4, 3, 2, 10])
            
            let rangeSliced = list[1..<4]
            #expect(try safeInts(from: rangeSliced) == [2, 3, 4])
            
            let closedRangeSliced = list[1...3]
            #expect(try safeInts(from: closedRangeSliced) == [2, 3, 4])
            
            let partialFromSliced = list[2...]
            #expect(try safeInts(from: partialFromSliced) == [3, 4, 50])
            
            let partialUpToSliced = list[..<3]
            #expect(try safeInts(from: partialUpToSliced) == [10, 2, 3])
            
            let partialThroughSliced = list[...2]
            #expect(try safeInts(from: partialThroughSliced) == [10, 2, 3])
            
            list[.slice(1, 4)] = try isolatedInterpreter.convertToSafePython(array: [20, 30])
            #expect(try safeInts(from: list) == [10, 20, 30, 50])
            
            let replacement = try isolatedInterpreter.convertToSafePython(array: [200, 300, 400])
            try list.setItem(key: 1..<3, newValue: replacement)
            #expect(try safeInts(from: list) == [10, 200, 300, 400, 50])
        }
    }
    
    @Test("LIS_014: SafePythonObject normal Python list methods")
    func safePythonListMethods() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let list = try isolatedInterpreter.convertToSafePython(array: [3, 1, 2, 2])
            
            #expect(try Int(list[dynamicMember: "count"](2)) == 2)
            #expect(try Int(list.index(1)) == 1)
            
            _ = try list.append(4)
            #expect(try safeInts(from: list) == [3, 1, 2, 2, 4])
            
            _ = try list.extend([5, 6])
            #expect(try safeInts(from: list) == [3, 1, 2, 2, 4, 5, 6])
            
            _ = try list.remove(2)
            #expect(try safeInts(from: list) == [3, 1, 2, 4, 5, 6])
            
            let popped = try list.pop()
            #expect(try Int(popped) == 6)
            #expect(try safeInts(from: list) == [3, 1, 2, 4, 5])
            
            _ = try list.reverse()
            #expect(try safeInts(from: list) == [5, 4, 2, 1, 3])
            
            _ = try list.sort()
            #expect(try safeInts(from: list) == [1, 2, 3, 4, 5])
            
            let tuple = try isolatedInterpreter.builtins.tuple(list)
            #expect(try tuple.isTuple)
            #expect(try tuple.tupleCount == 5)
            #expect(try Int(tuple.tupleItem(at: 0)) == 1)
            
            let copied = try list.copy()
            _ = try list.clear()
            #expect(try list.listCount == 0)
            #expect(try safeInts(from: copied) == [1, 2, 3, 4, 5])
        }
    }
    
    @Test("LIS_014A: SafePythonObject list concatenation with +")
    func safeListConcatenationWithPlusOperator() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let left = try isolatedInterpreter.convertToSafePython(array: [1, 2])
            let right = try isolatedInterpreter.convertToSafePython(array: [3])
            
            let combined = left + right
            #expect(try safeInts(from: combined) == [1, 2, 3])
            #expect(try safeInts(from: left) == [1, 2])
            #expect(try safeInts(from: right) == [3])
        }
    }
    
    @Test("LIS_014B: PythonObject list can be bound and mutated as SafePythonObject")
    func asyncListBoundIntoSafeContextKeepsIdentity() async throws {
        let list = try await interpreter.convertToPython(array: [1, 2])
        
        try await list.listAppendItem(3)
        #expect(try await asyncInts(from: list) == [1, 2, 3])
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            var safeList = try isolatedInterpreter.bind(pythonObject: list)
            
            #expect(try safeInts(from: safeList) == [1, 2, 3])
            try safeList.listSetItem(at: 0, to: 10)
            try safeList.listAppendItem(4)
            _ = try safeList.extend(isolatedInterpreter.convertToSafePython(array: [5, 6]))
            safeList[.slice(1, 3)] = try isolatedInterpreter.convertToSafePython(array: [20, 30])
            
            #expect(try safeInts(from: safeList) == [10, 20, 30, 4, 5, 6])
        }
        
        #expect(try await asyncInts(from: list) == [10, 20, 30, 4, 5, 6])
        try await list.listDeleteItem(at: -1)
        #expect(try await asyncInts(from: list) == [10, 20, 30, 4, 5])
    }
    
    @Test("LIS_015: SafePythonObject list conversions with heterogeneous values")
    func safeHeterogeneousListConversion() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let source: [any SafePythonConvertible] = ["name", 3, true, 2.5]
            let list = try isolatedInterpreter.convertToSafePython(array: source)
            
            #expect(try list.isList)
            #expect(try list.listCount == 4)
            #expect(try String(list.listItem(at: 0)) == "name")
            #expect(try Int(list.listItem(at: 1)) == 3)
            #expect(try Bool(list.listItem(at: 2)) == true)
            #expect(try Double(list.listItem(at: 3)) == 2.5)
        }
    }
    
    @Test("LIS_016: SafePythonObject list error behavior")
    func safeListErrors() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let notList = try 99.toSafePythonObject(interpreter: isolatedInterpreter)
            #expect(try notList.isList == false)
            
            let countError = #expect(throws: PythonError.self) {
                _ = try notList.listCount
            }
            if case .listConversionFailed = countError {
            } else {
                Issue.record("Expected .listConversionFailed for listCount on non-list, but got \(countError)")
            }
            
            let arrayError = #expect(throws: PythonError.self) {
                _ = try notList.listArray
            }
            if case .listConversionFailed = arrayError {
            } else {
                Issue.record("Expected .listConversionFailed for listArray on non-list, but got \(arrayError)")
            }
            
            let itemTypeError = #expect(throws: PythonError.self) {
                _ = try notList.listItem(at: 0)
            }
            if case .listConversionFailed = itemTypeError {
            } else {
                Issue.record("Expected .listConversionFailed for listItem on non-list, but got \(itemTypeError)")
            }
            
            let setTypeError = #expect(throws: PythonError.self) {
                try notList.listSetItem(at: 0, to: 1)
            }
            if case .listConversionFailed = setTypeError {
            } else {
                Issue.record("Expected .listConversionFailed for listSetItem on non-list, but got \(setTypeError)")
            }
            
            let appendTypeError = #expect(throws: PythonError.self) {
                try notList.listAppendItem(1)
            }
            if case .listConversionFailed = appendTypeError {
            } else {
                Issue.record("Expected .listConversionFailed for listAppendItem on non-list, but got \(appendTypeError)")
            }
            
            let insertTypeError = #expect(throws: PythonError.self) {
                try notList.listInsertItem(1, at: 0)
            }
            if case .listConversionFailed = insertTypeError {
            } else {
                Issue.record("Expected .listConversionFailed for listInsertItem on non-list, but got \(insertTypeError)")
            }
            
            let deleteTypeError = #expect(throws: PythonError.self) {
                try notList.listDeleteItem(at: 0)
            }
            if case .listConversionFailed = deleteTypeError {
            } else {
                Issue.record("Expected .listConversionFailed for listDeleteItem on non-list, but got \(deleteTypeError)")
            }
            
            let list = try isolatedInterpreter.convertToSafePython(array: [1, 2, 3])
            let itemBoundsError = #expect(throws: PythonError.self) {
                _ = try list.listItem(at: 3)
            }
            if case .safePythonException = itemBoundsError {
            } else {
                Issue.record("Expected .safePythonException for out-of-bounds listItem, but got \(itemBoundsError)")
            }
            
            let negativeItemBoundsError = #expect(throws: PythonError.self) {
                _ = try list.listItem(at: -4)
            }
            if case .safePythonException = negativeItemBoundsError {
            } else {
                Issue.record("Expected .safePythonException for negative out-of-bounds listItem, but got \(negativeItemBoundsError)")
            }
            
            let setBoundsError = #expect(throws: PythonError.self) {
                try list.listSetItem(at: 3, to: 4)
            }
            if case .safePythonException = setBoundsError {
            } else {
                Issue.record("Expected .safePythonException for out-of-bounds listSetItem, but got \(setBoundsError)")
            }
            
            let deleteBoundsError = #expect(throws: PythonError.self) {
                try list.listDeleteItem(at: 3)
            }
            if case .safePythonException = deleteBoundsError {
            } else {
                Issue.record("Expected .safePythonException for out-of-bounds listDeleteItem, but got \(deleteBoundsError)")
            }
            
            let steppedSliceSetError = #expect(throws: PythonError.self) {
                let replacement = try isolatedInterpreter.convertToSafePython(array: [9])
                try list.setItem(key: PythonSlice(nil, nil, step: 2), newValue: replacement)
            }
            if case .safePythonException = steppedSliceSetError {
            } else {
                Issue.record("Expected .safePythonException for invalid stepped slice assignment, but got \(steppedSliceSetError)")
            }
        }
    }
}
