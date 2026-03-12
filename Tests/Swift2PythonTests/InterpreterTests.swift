//
//  InterpreterTests.swift
//  Swift2Python
//
//  Created by Ben White on 3/7/26.
//

import Testing
import Logging
@testable import Swift2Python


// This runs once when the test process starts
private let setupLogging: Void = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
}()

@Suite("PythonInterpreter", .serialized)  // global state → serialize
struct InterpreterTests {
    
    init() async {
        _ = setupLogging
        let runtime = PythonRuntime.shared
        do {
            try await runtime.initialize()
        } catch {
            #expect(Bool(false), "Failed to initialize Python runtime: \(error)")
        }
    }
    
    let py = PythonInterpreter()

    @Test("Imports sys and reads version")
    func importSysVersion() async throws {
        let sys = try await py.import("sys")

        let versionInfo = try await sys.get(attrName: "version_info")

        let majorObj = try await versionInfo.get(attrName: "major")
        let minorObj = try await versionInfo.get(attrName: "minor")

        // Need a way to extract Swift Int — add a helper later
        // For now: just confirm we got objects back
        #expect(majorObj.id.description.starts(with: "PyID"))
        #expect(minorObj.id.description.starts(with: "PyID"))

        // Bonus: print version via run simple string
        let code = """
        import sys
        print(sys.version)
        """
        _ = try await py.pyRun_SimpleString(code)
    }

    @Test("Converts Swift values and calls len()")
    func convertAndCallLen() async throws {
        let lst = try await py.convertArrayToPython([1, 42, -7])

        let builtins = try await py.import("builtins")
        let lenFunc = try await builtins.get(attrName: "len")

        // Call len(lst)
        _ = try await lenFunc.callAsFunction(lst)

        // TODO: extract Int from result (add .asInt or similar)
        print("Length should be 3")
    }

    @Test("Method call syntax sugar")
    func methodCallSugar() async throws {
        let math = try await py.import("math")
        _ = try await math.sqrt(16.0)  // → should be ~4.0

        // Once you add extraction: #expect(try await result.asDouble() == 4.0)
    }
    
    
    @Test("Async Real World example.")
    func asyncRealWorld() async throws {
        
        let np = try await py.import("numpy")
        let plt = try await py.import("matplotlib.pyplot")

        let x = try await np.linspace(0, 10, 100)
        let y = try await np.sin(x)

        let _ = try await plt.plot(x, y)
        let _ = try await plt.show()
    }
    
    
    @Test("Isolated test.")
    func isolatedPython() async throws {
        
        // 1. Get the standard types module
        let types = try await py.import("types")

        // 2. Create a blank Python object (SimpleNamespace)
        let myObject = try await types.SimpleNamespace()
        
        py.withIsolatedContext { interpreter in
            var safeObj = interpreter.bind(myObject)
            
            // --- TEST 1: SETTING & GETTING ATTRIBUTES (Dynamic Member Lookup) ---
            //safeObj.name = "Swift-Python-Bridge"
            safeObj.version = 2.0
            safeObj.numVal = 3.0
            safeObj.numVal = safeObj.numVal + 1.0
            safeObj.numVal = safeObj.numVal + safeObj.numVal
            safeObj.is_active = true

            print("Name from Python: \(safeObj.name)")       // Swift gets the attribute
            print("Version from Python: \(safeObj.version)") // Swift gets the attribute

            // --- TEST 2: SUBSCRIPT ACCESS (Dictionary Mapping) ---
            // In Python, you can view an object's attributes as a dictionary using __dict__
            let dictView = safeObj.__dict__

            // Set a new value via subscript (Bracket notation)
            dictView["location"] = "Cupertino"

            // Verify the attribute was set via the subscript
            print("Location (via attribute): \(safeObj.location)")
            print("Location (via subscript): \(dictView["location"])")

            // --- TEST 3: ITERATING OVER SUBSCRIPTS ---
            print("\nIterating over all set attributes:")
            for (key, value) in dictView.items() {
                print(" - \(key): \(value)")
            }
        }
    }
}

