//
//  InterpreterTests.swift
//  Swift2Python
//
//  Created by Ben White on 3/7/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("PythonInterpreter", .serialized)  // global state → serialize
struct InterpreterTests {
    
    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }

    @Test("Imports sys and reads version")
    func importSysVersion() async throws {
        let sys = try await interpreter.import("sys")

        let versionInfo = try await sys.get(attr: "version_info")

        let majorObj = try await versionInfo.get(attr: "major")
        let minorObj = try await versionInfo.get(attr: "minor")

        // Need a way to extract Swift Int — add a helper later
        // For now: just confirm we got objects back
        #expect(majorObj.id.description.starts(with: "PyID"))
        #expect(minorObj.id.description.starts(with: "PyID"))
        
        let majorMirror = Mirror(reflecting: majorObj)
        #expect(majorMirror.displayStyle == .struct)
        #expect(majorMirror.children.isEmpty)

        // Bonus: print version via run simple string
        let code = """
        import sys
        print(sys.version)
        """
        //_ = try await py.api.pythonRun_SimpleString(code)
    }

    @Test("Converts Swift values and calls len()")
    func convertAndCallLen() async throws {
        let lst = try await interpreter.convertToPython(array: [1, 42, -7])

        let builtins = try await interpreter.import("builtins")
        let lenFunc = try await builtins.get(attr: "len")

        // Call len(lst)
        _ = try await lenFunc.callAsFunction(lst)

        // TODO: extract Int from result (add .asInt or similar)
        print("Length should be 3")
    }

    @Test("Method call syntax sugar")
    func methodCallSugar() async throws {
        let math = try await interpreter.import("math")
        _ = try await math.sqrt(16.0)  // → should be ~4.0

        // Once you add extraction: #expect(try await result.asDouble() == 4.0)
    }
    
    
    @Test("Async Real World example.")
    func asyncRealWorld() async throws {
        
        let np = try await interpreter.import("numpy")
        let plt = try await interpreter.import("matplotlib.pyplot")

        let x = try await np.linspace(0, 10, 100)
        let y = try await np.sin(x)

        let _ = try await plt.plot(x, y)
        let _ = try await plt.show()
    }
    
    
    @Test("Isolated test.")
    func isolatedPython() async throws {
        
        // 1. Get the standard types module
        let types = try await interpreter.import("types")

        // 2. Create a blank Python object (SimpleNamespace)
        let myObject = try await types.SimpleNamespace()
        
        try await interpreter.withIsolatedContext { interpreter in
            var safeObj = interpreter.bind(pythonObject: myObject)
            
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
            var dictView = safeObj.__dict__

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

