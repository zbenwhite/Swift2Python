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
    
    @Test("Double → PythonObject (async)")
    func asyncDoubleConversion() async throws {
        
        let value: Double = 3.141592653589793
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Double(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("Double → PythonObject (async) for special value -1.0")
    func asyncDoubleConversionNegativeOne() async throws {
        
        // Must test -1.0 because there's code associated with -1.0
        let value: Double = -1.0
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Double(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("Double → SafePythonObject (synchronous)")
    func safeDoubleConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Double = 3.141592653589793
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Double(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("Double → SafePythonObject (synchronous) for special value -1.0")
    func safeDoubleConversionNegativeOne() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Double = -1.0
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Double(safePyObj)
            #expect(roundTrip == value)
        }
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


// [xxxx-xx-xx] : Test
//
// Floating Point

// [2026-04-06] : Test Convert Double to PythonObject
// [2026-04-06] : Test Convert Double to PythonObject special -1.0
// [2026-04-06] : Test Convert PythonObject to Double
// [2026-04-06] : Test Convert PythonObject to Double special -1.0
// [          ] : Test Convert PythonObject to Double error handling when it's not a numeric value
// [          ] : Test Convert Double to SafePythonObject
// [          ] : Test Convert Double to SafePythonObject special -1.0
// [          ] : Test Convert SafePythonObject to Double
// [          ] : Test Convert SafePythonObject to Double special -1.0
// [          ] : Test Convert SafePythonObject to Double error handling when it's not a numeric value

// Signed Integers

// [          ] : Test Convert Int to PythonObject
// [          ] : Test Convert Int to PythonObject special value
// [          ] : Test Convert PythonObject to Int
// [          ] : Test Convert PythonObject to Int special value
// [          ] : Test Convert PythonObject to Int error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int error handling when it's a huge number that won't fit in an Int
// [          ] : Test Convert Int to SafePythonObject
// [          ] : Test Convert Int to SafePythonObject special value
// [          ] : Test Convert SafePythonObject to Int
// [          ] : Test Convert SafePythonObject to Int special value
// [          ] : Test Convert SafePythonObject to Int error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int error handling when it's a huge number that won't fit in an Int

// [          ] : Test Convert Int8 to PythonObject
// [          ] : Test Convert Int8 to PythonObject special value
// [          ] : Test Convert PythonObject to Int8
// [          ] : Test Convert PythonObject to Int8 special value
// [          ] : Test Convert PythonObject to Int8 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int8 error handling when it's a huge number that won't fit in an Int8
// [          ] : Test Convert Int8 to SafePythonObject
// [          ] : Test Convert Int8 to SafePythonObject special value
// [          ] : Test Convert SafePythonObject to Int8
// [          ] : Test Convert SafePythonObject to Int8 special value
// [          ] : Test Convert SafePythonObject to Int8 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int8 error handling when it's a huge number that won't fit in an Int8

// [          ] : Test Convert Int16 to PythonObject
// [          ] : Test Convert Int16 to PythonObject special value
// [          ] : Test Convert PythonObject to Int16
// [          ] : Test Convert PythonObject to Int16 special value
// [          ] : Test Convert PythonObject to Int16 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int16 error handling when it's a huge number that won't fit in an Int16
// [          ] : Test Convert Int16 to SafePythonObject
// [          ] : Test Convert Int16 to SafePythonObject special value
// [          ] : Test Convert SafePythonObject to Int16
// [          ] : Test Convert SafePythonObject to Int16 special value
// [          ] : Test Convert SafePythonObject to Int16 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int16 error handling when it's a huge number that won't fit in an Int16

// [          ] : Test Convert Int32 to PythonObject
// [          ] : Test Convert Int32 to PythonObject special value
// [          ] : Test Convert PythonObject to Int32
// [          ] : Test Convert PythonObject to Int32 special value
// [          ] : Test Convert PythonObject to Int32 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int32 error handling when it's a huge number that won't fit in an Int32
// [          ] : Test Convert Int32 to SafePythonObject
// [          ] : Test Convert Int32 to SafePythonObject special value
// [          ] : Test Convert SafePythonObject to Int32
// [          ] : Test Convert SafePythonObject to Int32 special value
// [          ] : Test Convert SafePythonObject to Int32 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int32 error handling when it's a huge number that won't fit in an Int32

// [          ] : Test Convert Int64 to PythonObject
// [          ] : Test Convert Int64 to PythonObject special value
// [          ] : Test Convert PythonObject to Int64
// [          ] : Test Convert PythonObject to Int64 special value
// [          ] : Test Convert PythonObject to Int64 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to Int64 error handling when it's a huge number that won't fit in an Int64
// [          ] : Test Convert Int64 to SafePythonObject
// [          ] : Test Convert Int64 to SafePythonObject special value
// [          ] : Test Convert SafePythonObject to Int64
// [          ] : Test Convert SafePythonObject to Int64 special value
// [          ] : Test Convert SafePythonObject to Int64 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to Int64 error handling when it's a huge number that won't fit in an Int64

// Unsigned Integers

// [          ] : Test Convert UInt to PythonObject
// [          ] : Test Convert UInt to PythonObject special value
// [          ] : Test Convert UInt to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt
// [          ] : Test Convert PythonObject to UInt special value
// [          ] : Test Convert PythonObject to UInt error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt error handling when it's a huge number that won't fit in an UInt
// [          ] : Test Convert PythonObject to UInt negative number error handling
// [          ] : Test Convert UInt to SafePythonObject
// [          ] : Test Convert UInt to SafePythonObject special value
// [          ] : Test Convert UInt to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt
// [          ] : Test Convert SafePythonObject to UInt special value
// [          ] : Test Convert SafePythonObject to UInt error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt error handling when it's a huge number that won't fit in an UInt
// [          ] : Test Convert SafePythonObject to UInt negative number error handling

// [          ] : Test Convert UInt8 to PythonObject
// [          ] : Test Convert UInt8 to PythonObject special value
// [          ] : Test Convert UInt8 to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt8
// [          ] : Test Convert PythonObject to UInt8 special value
// [          ] : Test Convert PythonObject to UInt8 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt8 error handling when it's a huge number that won't fit in an UInt8
// [          ] : Test Convert PythonObject to UInt8 negative number error handling
// [          ] : Test Convert UInt8 to SafePythonObject
// [          ] : Test Convert UInt8 to SafePythonObject special value
// [          ] : Test Convert UInt8 to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt8
// [          ] : Test Convert SafePythonObject to UInt8 special value
// [          ] : Test Convert SafePythonObject to UInt8 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt8 error handling when it's a huge number that won't fit in an UInt8
// [          ] : Test Convert SafePythonObject to UInt8 negative number error handling

// [          ] : Test Convert UInt16 to PythonObject
// [          ] : Test Convert UInt16 to PythonObject special value
// [          ] : Test Convert UInt16 to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt16
// [          ] : Test Convert PythonObject to UInt16 special value
// [          ] : Test Convert PythonObject to UInt16 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt16 error handling when it's a huge number that won't fit in an UInt16
// [          ] : Test Convert PythonObject to UInt16 negative number error handling
// [          ] : Test Convert UInt16 to SafePythonObject
// [          ] : Test Convert UInt16 to SafePythonObject special value
// [          ] : Test Convert UInt16 to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt16
// [          ] : Test Convert SafePythonObject to UInt16 special value
// [          ] : Test Convert SafePythonObject to UInt16 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt16 error handling when it's a huge number that won't fit in an UInt16
// [          ] : Test Convert SafePythonObject to UInt16 negative number error handling

// [          ] : Test Convert UInt32 to PythonObject
// [          ] : Test Convert UInt32 to PythonObject special value
// [          ] : Test Convert UInt32 to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt32
// [          ] : Test Convert PythonObject to UInt32 special value
// [          ] : Test Convert PythonObject to UInt32 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt32 error handling when it's a huge number that won't fit in an UInt32
// [          ] : Test Convert PythonObject to UInt32negative number error handling
// [          ] : Test Convert UInt32 to SafePythonObject
// [          ] : Test Convert UInt32 to SafePythonObject special value
// [          ] : Test Convert UInt32 to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt32
// [          ] : Test Convert SafePythonObject to UInt32 special value
// [          ] : Test Convert SafePythonObject to UInt32 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt32 error handling when it's a huge number that won't fit in an UInt32
// [          ] : Test Convert SafePythonObject to UInt32 negative number error handling

// [          ] : Test Convert UInt64 to PythonObject
// [          ] : Test Convert UInt64 to PythonObject special value
// [          ] : Test Convert UInt64 to PythonObject negative number error handling
// [          ] : Test Convert PythonObject to UInt64
// [          ] : Test Convert PythonObject to UInt64 special value
// [          ] : Test Convert PythonObject to UInt64 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt64 error handling when it's a huge number that won't fit in an UInt64
// [          ] : Test Convert PythonObject to UInt64 negative number error handling
// [          ] : Test Convert UInt64 to SafePythonObject
// [          ] : Test Convert UInt64 to SafePythonObject special value
// [          ] : Test Convert UInt64 to SafePythonObject negative number error handling
// [          ] : Test Convert SafePythonObject to UInt64
// [          ] : Test Convert SafePythonObject to UInt64 special value
// [          ] : Test Convert SafePythonObject to UInt64 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt64 error handling when it's a huge number that won't fit in an UInt64
// [          ] : Test Convert SafePythonObject to UInt64 negative number error handling
