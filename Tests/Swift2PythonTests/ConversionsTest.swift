//
//  ConversionsTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/3/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Conversions Tests")
struct ConversionsTests {
    
    private static let setupLogging: Void = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return handler
        }
    }()
    
    let interpreter: PythonInterpreter
    
    init() async {
        _ = Self.setupLogging
        let runtime = PythonRuntime.shared
        do {
            try await runtime.initialize()
        } catch {
            #expect(Bool(false), "Failed to initialize Python runtime: \(error)")
        }
        interpreter = try! await PythonInterpreter()
    }
    
    @Test("Double → PythonObject (async)")
    func asyncDoubleConversion() async throws {
        
        let value: Double = 3.141592653589793
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Double(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("Double → PythonObject (async) for special value -1.0")
    func asyncDoubleConversionNegOne() async throws {
        
        // Must test -1.0 because there's code associated with -1.0
        let value: Double = -1.0
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Double(pyObj)
        #expect(roundTrip == value)
    }

//    @Test("Int → SafePythonObject (sync)")
//    func syncIntConversion() throws {
//        
//        let value: Int = -987654321
//        let safeObj = try value.toSafePythonObject(interpreter: interpreter)
//        
//        let roundTrip = try await Int.fromSafePythonObject(safeObj, interpreter: interpreter)
//        #expect(roundTrip == value)
//    }

}
