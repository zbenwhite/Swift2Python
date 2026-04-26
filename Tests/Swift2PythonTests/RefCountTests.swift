//
//  RefCountTests.swift
//  Swift2Python
//
//  Created by Ben White on 4/23/26.
//


import Testing
import Logging
@testable import Swift2Python


@Suite("Reference Counting Tests")
struct RefCountTests {
    
    private static let setupLogging: Void = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
    }()
    
    private static let sharedInterpreterTask: Task<PythonInterpreter, Error> = Task {
        _ = setupLogging
        
        // Initialize the runtime
        let runtime = PythonRuntime.shared
        try await runtime.initialize()
        
        // Create and return the single shared interpreter
        return try await PythonInterpreter()
    }
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }
    
    
    //
    @Test("SafePythonObject deinit reference count -> 0")
    func safeObjectDeinit() async throws {
        
        let testHandle: PythonInterpreter.ReferenceCountTestHandle = try await interpreter.withIsolatedContext { isolatedInterpreter in
            
            let value: String = "test"
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let refCount = try isolatedInterpreter.getRefCount(forSafeObj:safePyObj)
            // Test that the reference count is 1
            #expect(refCount == 1)
            
            // extra increment that my housekeeping code doesn't know about
            let p = isolatedInterpreter.getRegisteredPointer(forSafeObj: safePyObj)
            isolatedInterpreter.api.Py_IncRef(p)
            
            
            let refCount2 = try isolatedInterpreter.getRefCount(forSafeObj:safePyObj)
            // Test that the reference count is 2 now
            #expect(refCount2 == 2)
            
            // Save a handle to get reference count after deinit
            return try isolatedInterpreter.getReferenceCountHandle(forSafeObj: safePyObj)
            
        }
        
        // Auto-cleanup decrements reference count from 2 to 1
        // (Because it's not safe to test for reference count == 0.  It might crash.)
        
        let refCountAfterCleanup = try await interpreter.getRefCount(forHandle: testHandle)
        
        // Test that the reference count after deinit is 1
        #expect(refCountAfterCleanup == 1)
        
        // Don't leak memory from test code
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            isolatedInterpreter.api.Py_DecRef(testHandle.handle)
        }
    }
    
    
    
    
}
