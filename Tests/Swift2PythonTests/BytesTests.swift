//
//  BytesTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/3/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Bytes Tests")
struct BytesTests {
    
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
    
    @Test("Bytes Test 1")
    func bytesTest1() async throws {
    }
}

