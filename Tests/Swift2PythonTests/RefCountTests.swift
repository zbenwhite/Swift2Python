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
    
    @Test("RefCount: safe variadic subscript get releases synthesized tuple key")
    func safeVariadicSubscriptGetReleasesSynthesizedTupleKey() async throws {
        let tupleKeyHandle: PythonInterpreter.ReferenceCountTestHandle = try await interpreter.withIsolatedContext { isolatedInterpreter in
            try isolatedInterpreter.runSimpleString(pythonCode: """
            class Swift2PythonTupleKeyEcho:
                def __getitem__(self, key):
                    return key
            """)
            
            let echoType = isolatedInterpreter.globals["Swift2PythonTupleKeyEcho"]
            let echo = try echoType.call()
            let tupleKey = echo[1, 2]
            
            #expect(try tupleKey.isTuple)
            #expect(try tupleKey.tupleCount == 2)
            
            let tupleKeyPtr = isolatedInterpreter.getRegisteredPointer(forSafeObj: tupleKey)
            isolatedInterpreter.api.Py_IncRef(tupleKeyPtr)
            
            return try isolatedInterpreter.getReferenceCountHandle(forSafeObj: tupleKey)
        }
        
        let refCountAfterCleanup = try await interpreter.getRefCount(forHandle: tupleKeyHandle)
        #expect(refCountAfterCleanup == 1)
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            isolatedInterpreter.api.Py_DecRef(tupleKeyHandle.handle)
        }
    }
    
    @Test("RefCount: safe variadic subscript set releases synthesized tuple key")
    func safeVariadicSubscriptSetReleasesSynthesizedTupleKey() async throws {
        let tupleKeyHandle: PythonInterpreter.ReferenceCountTestHandle = try await interpreter.withIsolatedContext { isolatedInterpreter in
            try isolatedInterpreter.runSimpleString(pythonCode: """
            class Swift2PythonTupleKeyRecorder:
                def __setitem__(self, key, value):
                    self.last_key = key
                    self.last_value = value
            """)
            
            let recorderType = isolatedInterpreter.globals["Swift2PythonTupleKeyRecorder"]
            var recorder = try recorderType.call()
            recorder[1, 2] = "value"
            
            let tupleKey = try recorder.get(attr: "last_key")
            #expect(try tupleKey.isTuple)
            #expect(try tupleKey.tupleCount == 2)
            
            let tupleKeyPtr = isolatedInterpreter.getRegisteredPointer(forSafeObj: tupleKey)
            isolatedInterpreter.api.Py_IncRef(tupleKeyPtr)
            
            let handle = try isolatedInterpreter.getReferenceCountHandle(forSafeObj: tupleKey)
            _ = try isolatedInterpreter.builtins.delattr(recorder, "last_key")
            return handle
        }
        
        let refCountAfterCleanup = try await interpreter.getRefCount(forHandle: tupleKeyHandle)
        #expect(refCountAfterCleanup == 1)
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            isolatedInterpreter.api.Py_DecRef(tupleKeyHandle.handle)
        }
    }
    
    @Test("RefCount: safe callable releases temporary argument tuple")
    func safeCallableReleasesTemporaryArgumentTuple() async throws {
        let argumentHandle: PythonInterpreter.ReferenceCountTestHandle = try await interpreter.withIsolatedContext { isolatedInterpreter in
            let argument = try isolatedInterpreter.convertToSafePython(array: [1, 2, 3])
            
            let argumentPtr = isolatedInterpreter.getRegisteredPointer(forSafeObj: argument)
            isolatedInterpreter.api.Py_IncRef(argumentPtr)
            
            let length = try isolatedInterpreter.builtins.len(argument)
            #expect(try Int(length) == 3)
            
            return try isolatedInterpreter.getReferenceCountHandle(forSafeObj: argument)
        }
        
        let refCountAfterCleanup = try await interpreter.getRefCount(forHandle: argumentHandle)
        #expect(refCountAfterCleanup == 1)
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            isolatedInterpreter.api.Py_DecRef(argumentHandle.handle)
        }
    }
    
    @Test("RefCount: safe slice subscript releases returned slice key")
    func safeSliceSubscriptReleasesReturnedSliceKey() async throws {
        let sliceKeyHandle: PythonInterpreter.ReferenceCountTestHandle = try await interpreter.withIsolatedContext { isolatedInterpreter in
            try isolatedInterpreter.runSimpleString(pythonCode: """
            class Swift2PythonSliceKeyEcho:
                def __getitem__(self, key):
                    return key
            """)
            
            let echoType = isolatedInterpreter.globals["Swift2PythonSliceKeyEcho"]
            let echo = try echoType.call()
            let sliceKey = echo[.slice(1, 4, step: 2)]
            
            #expect(try Int(sliceKey.get(attr: "start")) == 1)
            #expect(try Int(sliceKey.get(attr: "stop")) == 4)
            #expect(try Int(sliceKey.get(attr: "step")) == 2)
            
            let sliceKeyPtr = isolatedInterpreter.getRegisteredPointer(forSafeObj: sliceKey)
            isolatedInterpreter.api.Py_IncRef(sliceKeyPtr)
            
            return try isolatedInterpreter.getReferenceCountHandle(forSafeObj: sliceKey)
        }
        
        let refCountAfterCleanup = try await interpreter.getRefCount(forHandle: sliceKeyHandle)
        #expect(refCountAfterCleanup == 1)
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            isolatedInterpreter.api.Py_DecRef(sliceKeyHandle.handle)
        }
    }
    
}
