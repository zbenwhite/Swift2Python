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
    
    // MARK: FF_xxx Floating Point Float Conversion Tests
    
    @Test("FF_001: Float → PythonObject (async)")
    func asyncFloatConversion() async throws {
        
        let value: Float = 3.1415927
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Float(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("FF_002: Float → PythonObject (async) for special value -1.0")
    func asyncFloatConversionNegativeOne() async throws {
        
        let value: Float = -1.0
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Float(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("FF_003: Float → SafePythonObject (synchronous)")
    func safeFloatConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Float = 3.1415927
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Float(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("FF_004: Float → SafePythonObject (synchronous) for special value -1.0")
    func safeFloatConversionNegativeOne() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Float = -1.0
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Float(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    // MARK: F16_xxx Floating Point Float16 Conversion Tests
    
    @Test("F16_001: Float16 → PythonObject (async)")
    func asyncFloat16Conversion() async throws {
        
        let value: Float16 = 3.14
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Float16(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("F16_002: Float16 → PythonObject (async) for special value -1.0")
    func asyncFloat16ConversionNegativeOne() async throws {
        
        let value: Float16 = -1.0
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Float16(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("F16_003: Float16 → SafePythonObject (synchronous)")
    func safeFloat16Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Float16 = 3.14
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Float16(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("F16_004: Float16 → SafePythonObject (synchronous) for special value -1.0")
    func safeFloat16ConversionNegativeOne() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Float16 = -1.0
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Float16(safePyObj)
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
    
    // MARK: UI8_xxx UInt8 Conversion Tests
    
    @Test("UI8_001: UInt8 → PythonObject (async)")
    func asyncUInt8Conversion() async throws {
        
        let value: UInt8 = 123
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt8(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI8_002: UInt8 → PythonObject (async) for special value -1 equiv Self.max")
    func asyncUInt8ConversionNegativeValue() async throws {
        
        let value: UInt8 = UInt8.max
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt8(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI8_003: UInt8 → SafePythonObject (synchronous)")
    func safeUInt8Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt8 = 123
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt8(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("UI8_004: UInt8 → SafePythonObject (synchronous) for special value -1 equiv Self.max")
    func safeUInt8ConversionNegativeValue() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt8 = UInt8.max
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt8(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    // MARK: UI16_xxx UInt16 Conversion Tests
    
    @Test("UI16_001: UInt16 → PythonObject (async)")
    func asyncUInt16Conversion() async throws {
        
        let value: UInt16 = 65530
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt16(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI16_002: UInt16 → PythonObject (async) for special value -1 equiv Self.max")
    func asyncUInt16ConversionNegativeValue() async throws {
        
        let value: UInt16 = UInt16.max
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt16(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI16_003: UInt16 → SafePythonObject (synchronous)")
    func safeUInt16Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt16 = 65530
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt16(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("UI16_004: UInt16 → SafePythonObject (synchronous) for special value -1 equiv Self.max")
    func safeUInt16ConversionNegativeValue() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt16 = UInt16.max
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt16(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    // MARK: UI32_xxx UInt32 Conversion Tests
    
    @Test("UI32_001: UInt32 → PythonObject (async)")
    func asyncUInt32Conversion() async throws {
        
        let value: UInt32 = 4_000_000_000
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt32(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI32_002: UInt32 → PythonObject (async) for special value -1 equiv Self.max")
    func asyncUInt32ConversionNegativeValue() async throws {
        
        let value: UInt32 = UInt32.max
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt32(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI32_003: UInt32 → SafePythonObject (synchronous)")
    func safeUInt32Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt32 = 4_000_000_000
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt32(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("UI32_004: UInt32 → SafePythonObject (synchronous) for special value -1 equiv Self.max")
    func safeUInt32ConversionNegativeValue() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt32 = UInt32.max
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt32(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    // MARK: UI64_xxx UInt64 Conversion Tests
    
    @Test("UI64_001: UInt64 → PythonObject (async)")
    func asyncUInt64Conversion() async throws {
        
        let value: UInt64 = 9_876_543_210_987_654_321
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt64(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI64_002: UInt64 → PythonObject (async) for special value -1 equiv Self.max")
    func asyncUInt64ConversionNegativeValue() async throws {
        
        let value: UInt64 = UInt64.max
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await UInt64(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("UI64_003: UInt64 → SafePythonObject (synchronous)")
    func safeUInt64Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt64 = 9_876_543_210_987_654_321
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt64(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("UI64_004: UInt64 → SafePythonObject (synchronous) for special value -1 equiv Self.max")
    func safeUInt64ConversionNegativeValue() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: UInt64 = UInt64.max
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try UInt64(safePyObj)
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

// [2026-04-10] : FF_001 : Test Convert Float to PythonObject
// [2026-04-10] : FF_002 : Test Convert Float to PythonObject special -1.0
// [2026-04-10] : FF_001 : Test Convert PythonObject to Float
// [2026-04-10] : FF_002 : Test Convert PythonObject to Float special -1.0
// [          ] : Test Convert PythonObject to Float error handling when it's not a numeric value
// [2026-04-10] : FF_003 : Test Convert Float to SafePythonObject
// [2026-04-10] : FF_004 : Test Convert Float to SafePythonObject special -1.0
// [2026-04-10] : FF_003 : Test Convert SafePythonObject to Float
// [2026-04-10] : FF_004 : Test Convert SafePythonObject to Float special -1.0
// [          ] : Test Convert SafePythonObject to Float error handling when it's not a numeric value

// [2026-04-10] : F16_001 : Test Convert Float16 to PythonObject
// [2026-04-10] : F16_002 : Test Convert Float16 to PythonObject special -1.0
// [2026-04-10] : F16_001 : Test Convert PythonObject to Float16
// [2026-04-10] : F16_002 : Test Convert PythonObject to Float16 special -1.0
// [          ] : Test Convert PythonObject to Float16 error handling when it's not a numeric value
// [2026-04-10] : F16_003 : Test Convert Float16 to SafePythonObject
// [2026-04-10] : F16_004 : Test Convert Float16 to SafePythonObject special -1.0
// [2026-04-10] : F16_003 : Test Convert SafePythonObject to Float16
// [2026-04-10] : F16_004 : Test Convert SafePythonObject to Float16 special -1.0
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

// [2026-04-10] : UI8_001 : Test Convert UInt8 to PythonObject
// [2026-04-10] : UI8_002 : Convert UInt8 to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt8 to PythonObject negative number error handling
// [2026-04-10] : UI8_001 : Convert PythonObject to UInt8
// [2026-04-10] : UI8_002 : Convert PythonObject to UInt8 special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt8 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt8 error handling when it's a huge number that won't fit in an UInt8
// [          ] : Test Convert PythonObject to UInt8 negative number error handling
// [2026-04-10] : UI8_003 : Convert UInt8 to SafePythonObject
// [2026-04-10] : UI8_004 : Convert UInt8 to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt8 to SafePythonObject negative number error handling
// [2026-04-10] : UI8_003 : Convert SafePythonObject to UInt8
// [2026-04-10] : UI8_004 : Convert SafePythonObject to UInt8 special value -1 equiv Self.max
// [          ] : Test Convert SafePythonObject to UInt8 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt8 error handling when it's a huge number that won't fit in an UInt8
// [          ] : Test Convert SafePythonObject to UInt8 negative number error handling

// [2026-04-10] : UI16_001 : Test Convert UInt16 to PythonObject
// [2026-04-10] : UI16_002 : Test Convert UInt16 to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt16 to PythonObject negative number error handling
// [2026-04-10] : UI16_001 : Test Convert PythonObject to UInt16
// [2026-04-10] : UI16_002 : Test Convert PythonObject to UInt16 special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt16 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt16 error handling when it's a huge number that won't fit in an UInt16
// [          ] : Test Convert PythonObject to UInt16 negative number error handling
// [2026-04-10] : UI16_003 : Test Convert UInt16 to SafePythonObject
// [2026-04-10] : UI16_004 : Test Convert UInt16 to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt16 to SafePythonObject negative number error handling
// [2026-04-10] : UI16_003 : Test Convert SafePythonObject to UInt16
// [2026-04-10] : UI16_004 : Test Convert SafePythonObject to UInt16 special value -1 equiv Self.max
// [          ] : Test Convert SafePythonObject to UInt16 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt16 error handling when it's a huge number that won't fit in an UInt16
// [          ] : Test Convert SafePythonObject to UInt16 negative number error handling

// [2026-04-10] : UI32_001 : Test Convert UInt32 to PythonObject
// [2026-04-10] : UI32_002 : Test Convert UInt32 to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt32 to PythonObject negative number error handling
// [2026-04-10] : UI32_001 : Test Convert PythonObject to UInt32
// [2026-04-10] : UI32_002 : Test Convert PythonObject to UInt32 special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt32 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt32 error handling when it's a huge number that won't fit in an UInt32
// [          ] : Test Convert PythonObject to UInt32negative number error handling
// [2026-04-10] : UI32_003 : Test Convert UInt32 to SafePythonObject
// [2026-04-10] : UI32_004 : Test Convert UInt32 to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt32 to SafePythonObject negative number error handling
// [2026-04-10] : UI32_003 : Test Convert SafePythonObject to UInt32
// [2026-04-10] : UI32_004 : Test Convert SafePythonObject to UInt32 special value -1 equiv Self.max
// [          ] : Test Convert SafePythonObject to UInt32 error handling when it's not a numeric value
// [          ] : Test Convert SafePythonObject to UInt32 error handling when it's a huge number that won't fit in an UInt32
// [          ] : Test Convert SafePythonObject to UInt32 negative number error handling

// [2026-04-10] : UI64_001 : Test Convert UInt64 to PythonObject
// [2026-04-10] : UI64_002 : Test Convert UInt64 to PythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt64 to PythonObject negative number error handling
// [2026-04-10] : UI64_001 : Test Convert PythonObject to UInt64
// [2026-04-10] : UI64_002 : Test Convert PythonObject to UInt64 special value -1 equiv Self.max
// [          ] : Test Convert PythonObject to UInt64 error handling when it's not a numeric value
// [          ] : Test Convert PythonObject to UInt64 error handling when it's a huge number that won't fit in an UInt64
// [          ] : Test Convert PythonObject to UInt64 negative number error handling
// [2026-04-10] : UI64_003 : Test Convert UInt64 to SafePythonObject
// [2026-04-10] : UI64_004 : Test Convert UInt64 to SafePythonObject special value -1 equiv Self.max
// [          ] : Test Convert UInt64 to SafePythonObject negative number error handling
// [2026-04-10] : UI64_003 : Test Convert SafePythonObject to UInt64
// [2026-04-10] : UI64_004 : Test Convert SafePythonObject to UInt64 special value -1 equiv Self.max
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
