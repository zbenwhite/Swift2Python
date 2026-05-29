//
//  DictionaryTest.swift
//  Swift2Python
//
//  Created by Ben White on 5/27/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Dictionary Tests")
struct DictionaryTests {
    
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
    
    @Test("DIC_001: PythonObject dictionary creation and inspection")
    func asyncDictionaryCreationAndInspection() async throws {
        let dict = try await interpreter.convertToPython(dictionary: [
            "one": 1,
            "two": 2,
            "three": 3
        ])
        
        #expect(try await dict.isDict())
        #expect(try await dict.dictCount() == 3)
        
        let keys = try await dict.dictKeys()
        var swiftKeys: [String] = []
        for key in keys {
            swiftKeys.append(try await String(key))
        }
        #expect(Set(swiftKeys) == Set(["one", "two", "three"]))
        
        let values = try await dict.dictValues()
        var swiftValues: [Int] = []
        for value in values {
            swiftValues.append(try await Int(value))
        }
        #expect(swiftValues.sorted() == [1, 2, 3])
        
        let items = try await dict.dictItems()
        var swiftItems: [String: Int] = [:]
        for item in items {
            swiftItems[try await String(item.key)] = try await Int(item.value)
        }
        #expect(swiftItems == ["one": 1, "two": 2, "three": 3])
    }
    
    @Test("DIC_002: PythonObject heterogeneous dictionary conversion and item access")
    func asyncHeterogeneousDictionaryAndItemAccess() async throws {
        let source: [String: any PendingPythonConvertible] = [
            "name": "Ada",
            "count": 3,
            "active": true
        ]
        let dict = try await interpreter.convertToPython(dictionary: source)
        
        #expect(try await String(dict.getItem(key: "name")) == "Ada")
        #expect(try await Int(dict.getItem(key: "count")) == 3)
        #expect(try await Bool(dict.getItem(key: "active")) == true)
    }
    
    @Test("DIC_003: PythonObject containsKey and deleteItem")
    func asyncContainsKeyAndDeleteItem() async throws {
        let dict = try await interpreter.convertToPython(dictionary: [
            "name": "Ada",
            "count": "3"
        ])
        
        #expect(try await dict.containsKey("name"))
        #expect(try await dict.containsKey("missing") == false)
        
        try await dict.deleteItem(key: "name")
        #expect(try await dict.containsKey("name") == false)
        #expect(try await dict.dictCount() == 1)
        
        let missingKeyError = await #expect(throws: PythonError.self) {
            try await dict.deleteItem(key: "name")
        }
        if case .pythonException = missingKeyError {
        } else {
            Issue.record("Expected .pythonException for deleting a missing key, but got \(missingKeyError)")
        }
    }
    
    @Test("DIC_004: PythonObject normal Python dictionary methods")
    func asyncPythonDictionaryMethods() async throws {
        let dict = try await interpreter.convertToPython(dictionary: [
            "name": "Ada",
            "count": "3"
        ])
        let builtins = try await interpreter.getBuiltins()
        
        let keysView = try await dict.keys()
        let keysList = try await builtins.list(keysView)
        let keys = try await keysList.asArray()
        var swiftKeys: [String] = []
        for key in keys {
            swiftKeys.append(try await String(key))
        }
        #expect(Set(swiftKeys) == Set(["name", "count"]))
        
        let valuesView = try await dict.values()
        let valuesList = try await builtins.list(valuesView)
        let values = try await valuesList.asArray()
        var swiftValues: [String] = []
        for value in values {
            swiftValues.append(try await String(value))
        }
        #expect(Set(swiftValues) == Set(["Ada", "3"]))
        
        let itemsView = try await dict.items()
        let itemsList = try await builtins.list(itemsView)
        let items = try await itemsList.asArray()
        var swiftItems: [String: String] = [:]
        for item in items {
            let pair = try await item.asTuple2()
            swiftItems[try await String(pair.0)] = try await String(pair.1)
        }
        #expect(swiftItems == ["name": "Ada", "count": "3"])
        
        #expect(try await String(dict[dynamicMember: "get"]("missing", "fallback")) == "fallback")
        
        _ = try await dict.update(["city": "London"])
        #expect(try await String(dict.getItem(key: "city")) == "London")
        
        let popped = try await dict.pop("name")
        #expect(try await String(popped) == "Ada")
        #expect(try await dict.containsKey("name") == false)
    }
    
    @Test("DIC_005: PythonObject dictionary error behavior")
    func asyncDictionaryErrors() async throws {
        let notDict = try await 99.toPythonObject(interpreter: interpreter)
        #expect(try await notDict.isDict() == false)
        
        let countError = await #expect(throws: PythonError.self) {
            _ = try await notDict.dictCount()
        }
        if case .dictionaryConversionFailed = countError {
        } else {
            Issue.record("Expected .dictionaryConversionFailed for dictCount on non-dict, but got \(countError)")
        }
        
        let keysError = await #expect(throws: PythonError.self) {
            _ = try await notDict.dictKeys()
        }
        if case .dictionaryConversionFailed = keysError {
        } else {
            Issue.record("Expected .dictionaryConversionFailed for dictKeys on non-dict, but got \(keysError)")
        }
        
        let valuesError = await #expect(throws: PythonError.self) {
            _ = try await notDict.dictValues()
        }
        if case .dictionaryConversionFailed = valuesError {
        } else {
            Issue.record("Expected .dictionaryConversionFailed for dictValues on non-dict, but got \(valuesError)")
        }
        
        let itemsError = await #expect(throws: PythonError.self) {
            _ = try await notDict.dictItems()
        }
        if case .dictionaryConversionFailed = itemsError {
        } else {
            Issue.record("Expected .dictionaryConversionFailed for dictItems on non-dict, but got \(itemsError)")
        }
        
        let containsError = await #expect(throws: PythonError.self) {
            _ = try await notDict.containsKey("name")
        }
        if case .dictionaryConversionFailed = containsError {
        } else {
            Issue.record("Expected .dictionaryConversionFailed for containsKey on non-dict, but got \(containsError)")
        }
        
        let deleteError = await #expect(throws: PythonError.self) {
            try await notDict.deleteItem(key: "name")
        }
        if case .dictionaryConversionFailed = deleteError {
        } else {
            Issue.record("Expected .dictionaryConversionFailed for deleteItem on non-dict, but got \(deleteError)")
        }
    }
    
    @Test("DIC_010: SafePythonObject dictionary creation and inspection")
    func safeDictionaryCreationAndInspection() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let dict = try isolatedInterpreter.convertToSafePython(dictionary: [
                "one": 1,
                "two": 2,
                "three": 3
            ])
            
            #expect(try dict.isDict)
            #expect(try dict.dictCount == 3)
            
            let keys = try dict.dictKeys
            var swiftKeys: [String] = []
            for key in keys {
                swiftKeys.append(try String(key))
            }
            #expect(Set(swiftKeys) == Set(["one", "two", "three"]))
            
            let values = try dict.dictValues
            var swiftValues: [Int] = []
            for value in values {
                swiftValues.append(try Int(value))
            }
            #expect(swiftValues.sorted() == [1, 2, 3])
            
            let items = try dict.dictItems
            var swiftItems: [String: Int] = [:]
            for item in items {
                swiftItems[try String(item.key)] = try Int(item.value)
            }
            #expect(swiftItems == ["one": 1, "two": 2, "three": 3])
        }
    }
    
    @Test("DIC_011: SafePythonObject heterogeneous dictionary and mutation")
    func safeHeterogeneousDictionaryAndMutation() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let source: [String: any SafePythonConvertible] = [
                "name": "Ada",
                "count": 3,
                "active": true
            ]
            let dict = try isolatedInterpreter.convertToSafePython(dictionary: source)
            
            #expect(try String(dict["name"]) == "Ada")
            #expect(try Int(dict["count"]) == 3)
            #expect(try Bool(dict["active"]) == true)
            
            #expect(try dict.containsKey("name"))
            #expect(try dict.containsKey("missing") == false)
            
            try dict.deleteItem(key: "active")
            #expect(try dict.containsKey("active") == false)
            #expect(try dict.dictCount == 2)
        }
    }
    
    @Test("DIC_012: SafePythonObject normal Python dictionary methods")
    func safePythonDictionaryMethods() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let dict = try isolatedInterpreter.convertToSafePython(dictionary: [
                "name": "Ada",
                "count": "3"
            ])
            
            let keysView = try dict.keys()
            let keysList = try isolatedInterpreter.builtins.list(keysView)
            var swiftKeys: [String] = []
            for key in keysList {
                swiftKeys.append(try String(key))
            }
            #expect(Set(swiftKeys) == Set(["name", "count"]))
            
            let valuesView = try dict.values()
            let valuesList = try isolatedInterpreter.builtins.list(valuesView)
            var swiftValues: [String] = []
            for value in valuesList {
                swiftValues.append(try String(value))
            }
            #expect(Set(swiftValues) == Set(["Ada", "3"]))
            
            let itemsView = try dict[dynamicMember: "items"]()
            let itemsList = try isolatedInterpreter.builtins.list(itemsView)
            var swiftItems: [String: String] = [:]
            for item in itemsList {
                let pair = try item.tuple2
                swiftItems[try String(pair.0)] = try String(pair.1)
            }
            #expect(swiftItems == ["name": "Ada", "count": "3"])
            
            #expect(try String(dict[dynamicMember: "get"]("missing", "fallback")) == "fallback")
            
            _ = try dict.update(["city": "London"])
            #expect(try String(dict["city"]) == "London")
            
            let popped = try dict.pop("name")
            #expect(try String(popped) == "Ada")
            #expect(try dict.containsKey("name") == false)
        }
    }
    
    @Test("DIC_013: SafePythonObject dictionary throwing behavior")
    func safeDictionaryThrowingBehavior() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let notDict = try 99.toSafePythonObject(interpreter: isolatedInterpreter)
            #expect(try notDict.isDict == false)
            
            let countError = #expect(throws: PythonError.self) {
                _ = try notDict.dictCount
            }
            if case .dictionaryConversionFailed = countError {
            } else {
                Issue.record("Expected .dictionaryConversionFailed for dictCount on non-dict, but got \(countError)")
            }
            
            let keysError = #expect(throws: PythonError.self) {
                _ = try notDict.dictKeys
            }
            if case .dictionaryConversionFailed = keysError {
            } else {
                Issue.record("Expected .dictionaryConversionFailed for dictKeys on non-dict, but got \(keysError)")
            }
            
            let valuesError = #expect(throws: PythonError.self) {
                _ = try notDict.dictValues
            }
            if case .dictionaryConversionFailed = valuesError {
            } else {
                Issue.record("Expected .dictionaryConversionFailed for dictValues on non-dict, but got \(valuesError)")
            }
            
            let itemsError = #expect(throws: PythonError.self) {
                _ = try notDict.dictItems
            }
            if case .dictionaryConversionFailed = itemsError {
            } else {
                Issue.record("Expected .dictionaryConversionFailed for dictItems on non-dict, but got \(itemsError)")
            }
            
            let containsError = #expect(throws: PythonError.self) {
                _ = try notDict.containsKey("name")
            }
            if case .dictionaryConversionFailed = containsError {
            } else {
                Issue.record("Expected .dictionaryConversionFailed for containsKey on non-dict, but got \(containsError)")
            }
            
            let deleteError = #expect(throws: PythonError.self) {
                try notDict.deleteItem(key: "name")
            }
            if case .dictionaryConversionFailed = deleteError {
            } else {
                Issue.record("Expected .dictionaryConversionFailed for deleteItem on non-dict, but got \(deleteError)")
            }
            
            let dict = try isolatedInterpreter.convertToSafePython(dictionary: ["name": "Ada"])
            let missingKeyError = #expect(throws: PythonError.self) {
                try dict.deleteItem(key: "missing")
            }
            if case .safePythonException = missingKeyError {
            } else {
                Issue.record("Expected .safePythonException for deleting a missing key, but got \(missingKeyError)")
            }
        }
    }
}
