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
    
    // MARK: FD_xxx Floating Point Double Conversion Tests
    
    @Test("FD_001: Double → PythonObject (async)")
    func asyncDoubleConversion() async throws {
        
        let value: Double = 3.141592653589793
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Double(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("FD_002: Double → PythonObject (async) for special value -1.0")
    func asyncDoubleConversionNegativeOne() async throws {
        
        // Must test -1.0 because there's code associated with -1.0
        let value: Double = -1.0
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Double(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("FD_003: Double → SafePythonObject (synchronous)")
    func safeDoubleConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Double = 3.141592653589793
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Double(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("FD_004: Double → SafePythonObject (synchronous) for special value -1.0")
    func safeDoubleConversionNegativeOne() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Double = -1.0
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Double(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    // MARK: I_xxx Simple Int Conversion Tests
    
    @Test("I_001: Int → PythonObject (async)")
    func asyncIntConversion() async throws {
        
        let value: Int = 987654321
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I_002: Int → PythonObject (async) for special value -1")
    func asyncIntConversionNegativeValue() async throws {
        
        let value: Int = -1
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I_003: Int → SafePythonObject (synchronous)")
    func safeIntConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int = 987654321
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I_004: Int → SafePythonObject (synchronous) for special value -1")
    func safeIntConversionNegativeValue() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int = -1
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    // MARK: UI_xxx Simple UInt Conversion Tests
    
    @Test("UI_001: UInt → PythonObject (async)")
    func asyncUIntConversion() async throws {
        
        let value: UInt = 987654321
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI_002: UInt → PythonObject (async) for special value -1")
    func asyncUIntConversionNegativeValue() async throws {
        
        let value: UInt = UInt.max
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI_003: UInt → SafePythonObject (synchronous)")
    func safeUIntConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt = 987654321
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("UI_004: UInt → SafePythonObject (synchronous) for special value -1")
    func safeUIntConversionNegativeValue() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt = UInt.max
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt(safePyObj)
            #expect(roundTrip == value)
        }
    }

}


// Checklist of tests that pass.  Fill in the date when it runs correctly.

// [   date   ] : The date the test runs correctly and passes
// [yyyy-mm-dd] : Test ID : Test
//
// Floating Point

// [2026-04-06] : FD_001 : Test Convert Double to PythonObject
// [2026-04-06] : FD_002 : Test Convert Double to PythonObject special -1.0
// [2026-04-06] : FD_001 : Test Convert PythonObject to Double
// [2026-04-06] : FD_002 : Test Convert PythonObject to Double special -1.0
// [          ] : Test Convert PythonObject to Double error handling when it's not a numeric value
// [2026-04-09] : FD_003 : Test Convert Double to SafePythonObject
// [2026-04-09] : FD_004 : Test Convert Double to SafePythonObject special -1.0
// [2026-04-09] : FD_003 : Test Convert SafePythonObject to Double
// [2026-04-09] : FD_004 : Test Convert SafePythonObject to Double special -1.0
// [          ] : Test Convert SafePythonObject to Double error handling when it's not a numeric value

// [          ] : Test Convert Float to PythonObject
// [          ] : Test Convert Float to PythonObject special -1.0
// [          ] : Test Convert PythonObject to Float
// [          ] : Test Convert PythonObject to Float special -1.0
// [          ] : Test Convert PythonObject to Float error handling when it's not a numeric value
// [          ] : Test Convert Float to SafePythonObject
// [          ] : Test Convert Float to SafePythonObject special -1.0
// [          ] : Test Convert SafePythonObject to Float
// [          ] : Test Convert SafePythonObject to Float special -1.0
// [          ] : Test Convert SafePythonObject to Float error handling when it's not a numeric value

// [          ] : Test Convert Float16 to PythonObject
// [          ] : Test Convert Float16 to PythonObject special -1.0
// [          ] : Test Convert PythonObject to Float16
// [          ] : Test Convert PythonObject to Float16 special -1.0
// [          ] : Test Convert PythonObject to Float16 error handling when it's not a numeric value
// [          ] : Test Convert Float16 to SafePythonObject
// [          ] : Test Convert Float16 to SafePythonObject special -1.0
// [          ] : Test Convert SafePythonObject to Float16
// [          ] : Test Convert SafePythonObject to Float16 special -1.0
// [          ] : Test Convert SafePythonObject to Float16 error handling when it's not a numeric value

// Signed Integers

// [2026-04-09] : I_001 : Test Convert Int to PythonObject
// [2026-04-09] : I_002 : Test Convert Int to PythonObject special value -1
// [2026-04-09] : I_001 : Test Convert PythonObject to Int
// [2026-04-09] : I_002 : Test Convert PythonObject to Int special value  -1
// [          ] : Test Convert PythonObject to Int error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int error handling when it's a huge number that won't fit in an Int
// [2026-04-09] : I_003 : Test Convert Int to SafePythonObject
// [2026-04-09] : I_004 : Test Convert Int to SafePythonObject special value -1
// [2026-04-09] : I_003 : Test Convert SafePythonObject to Int
// [2026-04-09] : I_004 : Test Convert SafePythonObject to Int special value -1
// [          ] : Test Convert SafePythonObject to Int error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int error handling when it's a huge number that won't fit in an Int

// [          ] : Test Convert Int8 to PythonObject
// [          ] : Test Convert Int8 to PythonObject special value -1
// [          ] : Test Convert PythonObject to Int8
// [          ] : Test Convert PythonObject to Int8 special value -1
// [          ] : Test Convert PythonObject to Int8 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int8 error handling when it's a huge number that won't fit in an Int8
// [          ] : Test Convert Int8 to SafePythonObject
// [          ] : Test Convert Int8 to SafePythonObject special value -1
// [          ] : Test Convert SafePythonObject to Int8
// [          ] : Test Convert SafePythonObject to Int8 special value -1
// [          ] : Test Convert SafePythonObject to Int8 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int8 error handling when it's a huge number that won't fit in an Int8

// [          ] : Test Convert Int16 to PythonObject
// [          ] : Test Convert Int16 to PythonObject special value -1
// [          ] : Test Convert PythonObject to Int16
// [          ] : Test Convert PythonObject to Int16 special value -1
// [          ] : Test Convert PythonObject to Int16 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int16 error handling when it's a huge number that won't fit in an Int16
// [          ] : Test Convert Int16 to SafePythonObject
// [          ] : Test Convert Int16 to SafePythonObject special value -1
// [          ] : Test Convert SafePythonObject to Int16
// [          ] : Test Convert SafePythonObject to Int16 special value -1
// [          ] : Test Convert SafePythonObject to Int16 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int16 error handling when it's a huge number that won't fit in an Int16

// [          ] : Test Convert Int32 to PythonObject
// [          ] : Test Convert Int32 to PythonObject special value -1
// [          ] : Test Convert PythonObject to Int32
// [          ] : Test Convert PythonObject to Int32 special value -1
// [          ] : Test Convert PythonObject to Int32 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int32 error handling when it's a huge number that won't fit in an Int32
// [          ] : Test Convert Int32 to SafePythonObject
// [          ] : Test Convert Int32 to SafePythonObject special value -1
// [          ] : Test Convert SafePythonObject to Int32
// [          ] : Test Convert SafePythonObject to Int32 special value -1
// [          ] : Test Convert SafePythonObject to Int32 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int32 error handling when it's a huge number that won't fit in an Int32

// [          ] : Test Convert Int64 to PythonObject
// [          ] : Test Convert Int64 to PythonObject special value -1
// [          ] : Test Convert PythonObject to Int64
// [          ] : Test Convert PythonObject to Int64 special value -1
// [          ] : Test Convert PythonObject to Int64 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int64 error handling when it's a huge number that won't fit in an Int64
// [          ] : Test Convert Int64 to SafePythonObject
// [          ] : Test Convert Int64 to SafePythonObject special value -1
// [          ] : Test Convert SafePythonObject to Int64
// [          ] : Test Convert SafePythonObject to Int64 special value -1
// [          ] : Test Convert SafePythonObject to Int64 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int64 error handling when it's a huge number that won't fit in an Int64

// Unsigned Integers

// [2026-04-10] : UI_001 : Test Convert UInt to PythonObject
// [2026-04-10] : UI_002 : Test Convert UInt to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt to PythonObject negative number error handling
// [2026-04-10] : UI_001 : Test Convert PythonObject to UInt
// [2026-04-10] : UI_002 : Test Convert PythonObject to UInt special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt error handling when it's a huge number that won't fit in an UInt
// [          ] : Test Convert PythonObject to UInt negative number error handling
// [2026-04-10] : UI_003 : Test Convert UInt to SafePythonObject
// [2026-04-10] : UI_004 : Test Convert UInt to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt to SafePythonObject negative number error handling
// [2026-04-10] : UI_003 : Test Convert SafePythonObject to UInt
// [2026-04-10] : UI_004 : Test Convert SafePythonObject to UInt special value
// [          ] : Test Convert SafePythonObject to UInt error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt error handling when it's a huge number that won't fit in an UInt
// [          ] : Test Convert SafePythonObject to UInt negative number error handling

// [          ] : Test Convert UInt8 to PythonObject
// [          ] : Test Convert UInt8 to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt8 to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt8
// [          ] : Test Convert PythonObject to UInt8 special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt8 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt8 error handling when it's a huge number that won't fit in an UInt8
// [          ] : Test Convert PythonObject to UInt8 negative number error handling
// [          ] : Test Convert UInt8 to SafePythonObject
// [          ] : Test Convert UInt8 to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt8 to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt8
// [          ] : Test Convert SafePythonObject to UInt8 special value -1 equiv Self.max
// [          ] : Test Convert SafePythonObject to UInt8 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt8 error handling when it's a huge number that won't fit in an UInt8
// [          ] : Test Convert SafePythonObject to UInt8 negative number error handling

// [          ] : Test Convert UInt16 to PythonObject
// [          ] : Test Convert UInt16 to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt16 to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt16
// [          ] : Test Convert PythonObject to UInt16 special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt16 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt16 error handling when it's a huge number that won't fit in an UInt16
// [          ] : Test Convert PythonObject to UInt16 negative number error handling
// [          ] : Test Convert UInt16 to SafePythonObject
// [          ] : Test Convert UInt16 to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt16 to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt16
// [          ] : Test Convert SafePythonObject to UInt16 special value -1 equiv Self.max
// [          ] : Test Convert SafePythonObject to UInt16 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt16 error handling when it's a huge number that won't fit in an UInt16
// [          ] : Test Convert SafePythonObject to UInt16 negative number error handling

// [          ] : Test Convert UInt32 to PythonObject
// [          ] : Test Convert UInt32 to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt32 to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt32
// [          ] : Test Convert PythonObject to UInt32 special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt32 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt32 error handling when it's a huge number that won't fit in an UInt32
// [          ] : Test Convert PythonObject to UInt32negative number error handling
// [          ] : Test Convert UInt32 to SafePythonObject
// [          ] : Test Convert UInt32 to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt32 to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt32
// [          ] : Test Convert SafePythonObject to UInt32 special value -1 equiv Self.max
// [          ] : Test Convert SafePythonObject to UInt32 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt32 error handling when it's a huge number that won't fit in an UInt32
// [          ] : Test Convert SafePythonObject to UInt32 negative number error handling

// [          ] : Test Convert UInt64 to PythonObject
// [          ] : Test Convert UInt64 to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt64 to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt64
// [          ] : Test Convert PythonObject to UInt64 special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt64 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt64 error handling when it's a huge number that won't fit in an UInt64
// [          ] : Test Convert PythonObject to UInt64 negative number error handling
// [          ] : Test Convert UInt64 to SafePythonObject
// [          ] : Test Convert UInt64 to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt64 to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt64
// [          ] : Test Convert SafePythonObject to UInt64 special value -1 equiv Self.max
// [          ] : Test Convert SafePythonObject to UInt64 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt64 error handling when it's a huge number that won't fit in an UInt64
// [          ] : Test Convert SafePythonObject to UInt64 negative number error handling

// Strings

// [          ] : Test Convert String to PythonObject
// [          ] : Test Convert PythonObject to String
// [          ] : Test Convert String to SafePythonObject
// [          ] : Test Convert SafePythonObject to String

// Arrays

// [          ] : Test Convert Array to PythonObject
// [          ] : Test Convert PythonObject to Array
// [          ] : Test Convert Array to SafePythonObject
// [          ] : Test Convert SafePythonObject to Array

// Dictionaries

// [          ] : Test Convert Dictionary to PythonObject
// [          ] : Test Convert PythonObject to Dictionary
// [          ] : Test Convert Dictionary to SafePythonObject
// [          ] : Test Convert SafePythonObject to Dictionary

// Tuples

// [          ] : Test Convert Tuple to PythonObject
// [          ] : Test Convert PythonObject to Tuple
// [          ] : Test Convert Tuple to SafePythonObject
// [          ] : Test Convert SafePythonObject to Tuple
