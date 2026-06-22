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
    
    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask
    
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
    
    @Test("RefCount: PythonException from unhashable set insertion remains recoverable")
    func asyncUnhashableSetInsertionExceptionReferenceCounting() async throws {
        let set = try await interpreter.convertToPython(set: Set([1, 2, 3]))
        let unhashable = try await interpreter.convertToPython(array: [4, 5])
        
        let unhashableAddError = await #expect(throws: PythonError.self) {
            try await set.setAdd(unhashable)
        }
        if case .pythonException = unhashableAddError {
        } else {
            Issue.record("Expected .pythonException for adding an unhashable list to a set, but got \(unhashableAddError)")
        }
    }
    
    @Test("RefCount: SafePythonObject exception escapes isolated context before cleanup")
    func safePythonExceptionEscapesIsolatedContextBeforeCleanup() async throws {
        let thrownError = await #expect(throws: PythonError.self) {
            try await interpreter.withIsolatedContext { isolatedInterpreter in
                let dividend = try 1.toSafePythonObject(interpreter: isolatedInterpreter)
                let divisor = try 0.toSafePythonObject(interpreter: isolatedInterpreter)
                _ = try dividend.divide(divisor: divisor)
            }
        }
        
        if case .pythonException = thrownError {
            // expected
        } else {
            Issue.record("Expected .pythonException for SafePythonObject division by zero escaping isolated context, but got \(thrownError)")
        }
    }
    
}
