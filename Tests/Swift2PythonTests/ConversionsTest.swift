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
    
    // MARK: FD_xxx Floating Point Double
    
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
    
    @Test("FD_009: PythonObject (async) → Double throws on wrong type")
    func asyncDoubleConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Double(pyObj)
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Double")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("FD_010: SafePythonObject (synchronous) → Double throws wrong type")
    func safeDoubleConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Double(safePyObj)
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Double")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("FD_011: SafePythonObject to Double for unbound cases (synchronous)")
    func safeDoubleUnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_int = try Double(a)
            #expect(a_int == 1.0)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_int = try Double(b)
            #expect(b_int == 0.0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_int = try Double(c)
            #expect(c_int == 5.0)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_int = try Double(d)
            #expect(d_int == 0.0)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_int = try Double(e)
            #expect(e_int == -74.6)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_int = try Double(f)
            #expect(f_int == 0.0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_int = try Double(g)
            #expect(g_int == 17.0)
            
            let h: PythonInterpreter.SafePythonObject = "-817"
            let h_int = try Double(h)
            #expect(h_int == -817.0)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try Double(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Double")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try Double(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Double")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
        }
    }
    
    // MARK: FF_xxx Floating Point Float
    
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
    
    @Test("FF_009: PythonObject (async) → Double throws on wrong type")
    func asyncFloatConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Float(pyObj)
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Float")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("FF_010: SafePythonObject (synchronous) → Double throws wrong type")
    func safeFloatConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Float(safePyObj)
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Float")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("FF_011: SafePythonObject to Double for unbound cases (synchronous)")
    func safeFloatUnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_int = try Float(a)
            #expect(a_int == 1.0)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_int = try Float(b)
            #expect(b_int == 0.0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_int = try Float(c)
            #expect(c_int == 5.0)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_int = try Float(d)
            #expect(d_int == 0.0)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_int = try Float(e)
            #expect(e_int == -74.6)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_int = try Float(f)
            #expect(f_int == 0.0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_int = try Float(g)
            #expect(g_int == 17.0)
            
            let h: PythonInterpreter.SafePythonObject = "-817"
            let h_int = try Float(h)
            #expect(h_int == -817.0)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try Float(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Float")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try Float(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Float")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
        }
    }
    
    // MARK: F16_xxx Floating Point Float16
    
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
    
    @Test("F16_009: PythonObject (async) → Double throws on wrong type")
    func asyncFloat16ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Float16(pyObj)
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Float16")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("F16_010: SafePythonObject (synchronous) → Double throws wrong type")
    func safeFloat16ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Float16(safePyObj)
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Float16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("F16_011: SafePythonObject to Double for unbound cases (synchronous)")
    func safeFloat16UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_int = try Float16(a)
            #expect(a_int == 1.0)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_int = try Float16(b)
            #expect(b_int == 0.0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_int = try Float16(c)
            #expect(c_int == 5.0)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_int = try Float16(d)
            #expect(d_int == 0.0)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_int = try Float16(e)
            #expect(e_int == -74.6)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_int = try Float16(f)
            #expect(f_int == 0.0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_int = try Float16(g)
            #expect(g_int == 17.0)
            
            let h: PythonInterpreter.SafePythonObject = "-817"
            let h_int = try Float16(h)
            #expect(h_int == -817.0)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try Float16(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Float16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try Float16(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Float16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
        }
    }
    
    // MARK: I_xxx Simple Int
    
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
    
    @Test("I_005: PythonObject (async) → Int throws on overflow")
    func asyncIntConversionOverflow() async throws {
        
        let tooBigForInt64: UInt64 = UInt64(Int64.max) + 25
        
        let pyObj = try await tooBigForInt64.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int(pyObj) as Int
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooBigForInt64))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I_006: PythonObject (async) → Int throws on underflow")
    func asyncIntConversionUnderflow() async throws {
        
        let smallInt64 = Int64.min + 5
        let pyObj_a = try await smallInt64.toPythonObject(interpreter: interpreter)
        let pyObj = try await pyObj_a.subtract(25)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int(pyObj) as Int
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == "-9223372036854775828")
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I_007: SafePythonObject (synchronous) → Int throws on overflow")
    func safeIntConversionOverflow() async throws {
        let tooBigForInt64: UInt64 = UInt64(Int64.max) + 25  // use UInt64 for big number
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj = try tooBigForInt64.toSafePythonObject(interpreter: interpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int(pyObj) as Int
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooBigForInt64))
                #expect(sourceType.contains("PythonObject"))
                #expect(targetType == "Int")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I_008: SafePythonObject (synchronous) → Int throws on negative value")
    func safeIntConversionUnderflow() async throws {
        
        let smallInt64 = Int64.min + 5

        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj_a = try smallInt64.toSafePythonObject(interpreter: interpreter)
            let pyObj = pyObj_a - 25
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int(pyObj) as Int
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == "-9223372036854775828")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I_009: PythonObject (async) → Int throws on wrong type")
    func asyncIntConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int(pyObj) as Int
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("I_010: SafePythonObject (synchronous) → Int throws wrong type")
    func safeIntConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int(safePyObj) as Int
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("I_011: SafePythonObject to Int for unbound cases (synchronous)")
    func safeIntUnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_int = try Int(a)
            #expect(a_int == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_int = try Int(b)
            #expect(b_int == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_int = try Int(c)
            #expect(c_int == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_int = try Int(d)
            #expect(d_int == 0)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_int = try Int(e)
            #expect(e_int == -74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_int = try Int(f)
            #expect(f_int == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_int = try Int(g)
            #expect(g_int == 17)
            
            let h: PythonInterpreter.SafePythonObject = "-817"
            let h_int = try Int(h)
            #expect(h_int == -817)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try Int(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try Int(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k1 = Double(Int.max) * 4.0
                let k: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: k1 + 4.0)
                _ = try Int(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == String(Double(Int.max) * 4.0 + 4.0))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try Int(l)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError4 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
        }
    }
    
    // MARK: I8_xxx Int8
    
    @Test("I8_001: Int8 → PythonObject (async)")
    func asyncInt8Conversion() async throws {
        
        let value: Int8 = 123
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int8(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I8_002: Int8 → PythonObject (async) for special value -1")
    func asyncInt8ConversionNegativeOne() async throws {
        
        let value: Int8 = -1
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int8(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I8_003: Int8 → SafePythonObject (synchronous)")
    func safeInt8Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int8 = 123
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int8(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I8_004: Int8 → SafePythonObject (synchronous) for special value -1")
    func safeInt8ConversionNegativeOne() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int8 = -1
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int8(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I8_005: PythonObject (async) → Int8 throws on overflow")
    func asyncInt8ConversionOverflow() async throws {
        
        let big_Int8: Int8 = Int8.max - 5
        let tooBigForInt8: Int = Int(big_Int8) + 25
        
        let pyObj = try await tooBigForInt8.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int8(pyObj) as Int8
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooBigForInt8))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int8")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I8_006: PythonObject (async) → Int8 throws on underflow")
    func asyncInt8ConversionUnderflow() async throws {
        
        let small_Int8: Int8 = Int8.min + 5
        let tooSmallForInt8: Int = Int(small_Int8) - 25
        
        let pyObj = try await tooSmallForInt8.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int8(pyObj) as Int8
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooSmallForInt8))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int8")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I8_007: SafePythonObject (synchronous) → Int8 throws on overflow")
    func safeInt8ConversionOverflow() async throws {
        let big_Int8: Int8 = Int8.max - 5
        let tooBigForInt8: Int = Int(big_Int8) + 25
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj = try tooBigForInt8.toSafePythonObject(interpreter: interpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int8(pyObj) as Int8
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooBigForInt8))
                #expect(sourceType.contains("PythonObject"))
                #expect(targetType == "Int8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I8_008: SafePythonObject (synchronous) → Int8 throws on negative value")
    func safeInt8ConversionUnderflow() async throws {
        
        let small_Int8: Int8 = Int8.min + 5
        let tooSmallForInt8: Int = Int(small_Int8) - 25
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj = try tooSmallForInt8.toSafePythonObject(interpreter: interpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int8(pyObj) as Int8
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooSmallForInt8))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I8_009: PythonObject (async) → UInt throws on wrong type")
    func asyncInt8ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int8(pyObj) as Int8
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int8")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("I8_010: SafePythonObject (synchronous) → UInt throws wrong type")
    func safeInt8ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int8(safePyObj) as Int8
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int8")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    
    @Test("I8_011: SafePythonObject to Int8 for unbound cases (synchronous)")
    func safeInt8UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_int = try Int8(a)
            #expect(a_int == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_int = try Int8(b)
            #expect(b_int == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_int = try Int8(c)
            #expect(c_int == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_int = try Int8(d)
            #expect(d_int == 0)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_int = try Int8(e)
            #expect(e_int == -74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_int = try Int8(f)
            #expect(f_int == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_int = try Int8(g)
            #expect(g_int == 17)
            
            let h: PythonInterpreter.SafePythonObject = "-117"
            let h_int = try Int8(h)
            #expect(h_int == -117)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try Int8(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int8")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try Int8(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int8")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(integerLiteral: Int(Int8.max) + 4)
                _ = try Int8(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == String(Int(Int8.max) + 4))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int8.min) - 4.0)
                _ = try Int8(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == String(Double(Int8.min) - 4.0))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try Int8(m)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError5 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int8")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError5)")
            }
        }
    }
    
    // MARK: I16_xxx Int16
    
    @Test("I16_001: Int16 → PythonObject (async)")
    func asyncInt16Conversion() async throws {
        
        let value: Int16 = 32_000
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int16(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I16_002: Int16 → PythonObject (async) for special value -1")
    func asyncInt16ConversionNegativeOne() async throws {
        
        let value: Int16 = -1
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int16(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I16_003: Int16 → SafePythonObject (synchronous)")
    func safeInt16Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int16 = 32_000
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int16(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I16_004: Int16 → SafePythonObject (synchronous) for special value -1")
    func safeInt16ConversionNegativeOne() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int16 = -1
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int16(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I16_005: PythonObject (async) → Int16 throws on overflow")
    func asyncInt16ConversionOverflow() async throws {
        
        let big_Int16: Int16 = Int16.max - 5
        let tooBigForInt16: Int = Int(big_Int16) + 25
        
        let pyObj = try await tooBigForInt16.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int16(pyObj) as Int16
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooBigForInt16))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int16")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I16_006: PythonObject (async) → Int16 throws on underflow")
    func asyncInt16ConversionUnderflow() async throws {
        
        let small_Int16: Int16 = Int16.min + 5
        let tooSmallForInt16: Int = Int(small_Int16) - 25
        
        let pyObj = try await tooSmallForInt16.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int16(pyObj) as Int16
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooSmallForInt16))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int16")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I16_007: SafePythonObject (synchronous) → Int16 throws on overflow")
    func safeInt16ConversionOverflow() async throws {
        let big_Int16: Int16 = Int16.max - 5
        let tooBigForInt16: Int = Int(big_Int16) + 25
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj = try tooBigForInt16.toSafePythonObject(interpreter: interpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int16(pyObj) as Int16
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooBigForInt16))
                #expect(sourceType.contains("PythonObject"))
                #expect(targetType == "Int16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I16_008: SafePythonObject (synchronous) → Int16 throws on negative value")
    func safeInt16ConversionUnderflow() async throws {
        
        let small_Int16: Int16 = Int16.min + 5
        let tooSmallForInt16: Int = Int(small_Int16) - 25
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj = try tooSmallForInt16.toSafePythonObject(interpreter: interpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int16(pyObj) as Int16
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooSmallForInt16))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I16_009: PythonObject (async) → UInt throws on wrong type")
    func asyncInt16ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int16(pyObj) as Int16
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int16")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("I16_010: SafePythonObject (synchronous) → UInt throws wrong type")
    func safeInt16ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int16(safePyObj) as Int16
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("I16_011: SafePythonObject to Int16 for unbound cases (synchronous)")
    func safeInt16UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_int = try Int16(a)
            #expect(a_int == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_int = try Int16(b)
            #expect(b_int == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_int = try Int16(c)
            #expect(c_int == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_int = try Int16(d)
            #expect(d_int == 0)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_int = try Int16(e)
            #expect(e_int == -74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_int = try Int16(f)
            #expect(f_int == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_int = try Int16(g)
            #expect(g_int == 17)
            
            let h: PythonInterpreter.SafePythonObject = "-817"
            let h_int = try Int16(h)
            #expect(h_int == -817)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try Int16(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try Int16(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(integerLiteral: Int(Int16.max) + 4)
                _ = try Int16(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == String(Int(Int16.max) + 4))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int16.min) - 4.0)
                _ = try Int16(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == String(Double(Int16.min) - 4.0))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try Int16(m)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError5 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError5)")
            }
        }
    }
    
    // MARK: I32_xxx Int32
    
    @Test("I32_001: Int32 → PythonObject (async)")
    func asyncInt32Conversion() async throws {
        
        let value: Int32 = 2_147_483_000
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int32(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I32_002: Int32 → PythonObject (async) for special value -1")
    func asyncInt32ConversionNegativeOne() async throws {
        
        let value: Int32 = -1
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int32(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I32_003: Int32 → SafePythonObject (synchronous)")
    func safeInt32Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int32 = 2_147_483_000
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int32(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I32_004: Int32 → SafePythonObject (synchronous) for special value -1")
    func safeInt32ConversionNegativeOne() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int32 = -1
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int32(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I32_005: PythonObject (async) → Int32 throws on overflow")
    func asyncInt32ConversionOverflow() async throws {
        
        let big_Int32: Int32 = Int32.max - 5
        let tooBigForInt32: Int64 = Int64(big_Int32) + 25
        
        let pyObj = try await tooBigForInt32.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int32(pyObj) as Int32
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooBigForInt32))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int32")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I32_006: PythonObject (async) → Int32 throws on underflow")
    func asyncInt32ConversionUnderflow() async throws {
        
        let small_Int32: Int32 = Int32.min + 5
        let tooSmallForInt32: Int64 = Int64(small_Int32) - 25
        
        let pyObj = try await tooSmallForInt32.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int32(pyObj) as Int32
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooSmallForInt32))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int32")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I32_007: SafePythonObject (synchronous) → Int32 throws on overflow")
    func safeInt32ConversionOverflow() async throws {
        let big_Int32: Int32 = Int32.max - 5
        let tooBigForInt32: Int64 = Int64(big_Int32) + 25
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj = try tooBigForInt32.toSafePythonObject(interpreter: interpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int32(pyObj) as Int32
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooBigForInt32))
                #expect(sourceType.contains("PythonObject"))
                #expect(targetType == "Int32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I32_008: SafePythonObject (synchronous) → Int32 throws on negative value")
    func safeInt32ConversionUnderflow() async throws {
        
        let small_Int32: Int32 = Int32.min + 5
        let tooSmallForInt32: Int64 = Int64(small_Int32) - 25
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj = try tooSmallForInt32.toSafePythonObject(interpreter: interpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int32(pyObj) as Int32
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooSmallForInt32))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I32_009: PythonObject (async) → UInt throws on wrong type")
    func asyncInt32ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int32(pyObj) as Int32
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int32")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("I32_010: SafePythonObject (synchronous) → UInt throws wrong type")
    func safeInt32ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int32(safePyObj) as Int32
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int32")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("I32_011: SafePythonObject to Int32 for unbound cases (synchronous)")
    func safeInt32UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_int = try Int32(a)
            #expect(a_int == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_int = try Int32(b)
            #expect(b_int == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_int = try Int32(c)
            #expect(c_int == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_int = try Int32(d)
            #expect(d_int == 0)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_int = try Int32(e)
            #expect(e_int == -74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_int = try Int32(f)
            #expect(f_int == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_int = try Int32(g)
            #expect(g_int == 17)
            
            let h: PythonInterpreter.SafePythonObject = "-817"
            let h_int = try Int32(h)
            #expect(h_int == -817)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try Int32(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int32")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try Int32(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int32")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(integerLiteral: Int(Int32.max) + 4)
                _ = try Int32(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == String(Int(Int32.max) + 4))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double(Int32.min) - 4.0)
                _ = try Int32(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == String(Double(Int32.min) - 4.0))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try Int32(m)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError5 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int32")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError5)")
            }
        }
    }
    
    // MARK: I64_xxx Int64
    
    @Test("I64_001: Int64 → PythonObject (async)")
    func asyncInt64Conversion() async throws {
        
        let value: Int64 = 9_223_372_036_854_775_807
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int64(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I64_002: Int64 → PythonObject (async) for special value -1")
    func asyncInt64ConversionNegativeOne() async throws {
        
        let value: Int64 = -1
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Int64(pyObj)
        #expect(roundTrip == value)
    }
    
    @Test("I64_003: Int64 → SafePythonObject (synchronous)")
    func safeInt64Conversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int64 = 9_223_372_036_854_775_807
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int64(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I64_004: Int64 → SafePythonObject (synchronous) for special value -1")
    func safeInt64ConversionNegativeOne() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value: Int64 = -1
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Int64(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("I64_005: PythonObject (async) → Int64 throws on overflow")
    func asyncInt64ConversionOverflow() async throws {
        
        let tooBigForInt64: UInt64 = UInt64(Int64.max) + 25
        
        let pyObj = try await tooBigForInt64.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int64(pyObj) as Int64
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooBigForInt64))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int64")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I64_006: PythonObject (async) → Int64 throws on underflow")
    func asyncInt64ConversionUnderflow() async throws {
        
        let smallInt64 = Int64.min + 5
        let pyObj_a = try await smallInt64.toPythonObject(interpreter: interpreter)
        let pyObj = try await pyObj_a.subtract(25)  // lowest + 5 - 25 is too small
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int64(pyObj) as Int64
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == "-9223372036854775828")
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int64")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("I64_007: SafePythonObject (synchronous) → Int64 throws on overflow")
    func safeInt64ConversionOverflow() async throws {
        let tooBigForInt64: UInt64 = UInt64(Int64.max) + 25
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj = try tooBigForInt64.toSafePythonObject(interpreter: interpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int64(pyObj) as Int64
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooBigForInt64))
                #expect(sourceType.contains("PythonObject"))
                #expect(targetType == "Int64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I64_008: SafePythonObject (synchronous) → Int64 throws on negative value")
    func safeInt64ConversionUnderflow() async throws {
        
        let smallInt64 = Int64.min + 5

        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let pyObj_a = try smallInt64.toSafePythonObject(interpreter: interpreter)
            let pyObj = pyObj_a - 25
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int64(pyObj) as Int64
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == "-9223372036854775828")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("I64_009: PythonObject (async) → UInt throws on wrong type")
    func asyncInt64ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Int64(pyObj) as Int64
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Int64")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("I64_010: SafePythonObject (synchronous) → UInt throws wrong type")
    func safeInt64ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Int64(safePyObj) as Int64
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int64")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("I64_011: SafePythonObject to Int64 for unbound cases (synchronous)")
    func safeInt64UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_int = try Int64(a)
            #expect(a_int == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_int = try Int64(b)
            #expect(b_int == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_int = try Int64(c)
            #expect(c_int == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_int = try Int64(d)
            #expect(d_int == 0)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_int = try Int64(e)
            #expect(e_int == -74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_int = try Int64(f)
            #expect(f_int == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_int = try Int64(g)
            #expect(g_int == 17)
            
            let h: PythonInterpreter.SafePythonObject = "-817"
            let h_int = try Int64(h)
            #expect(h_int == -817)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try Int64(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int64")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try Int64(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int64")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k1 = Double(Int64.max) * 4.0
                let k: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: k1 + 4.0)
                _ = try Int64(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == String(Double(Int64.max) * 4.0 + 4.0))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l1 = Double(Int64.min) * 4.0
                let l: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: l1 - 4.0)
                _ = try Int64(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == String(Double(Int64.min) * 4.0 - 4.0))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try Int64(m)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError5 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Int64")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError5)")
            }
        }
    }
    
    // MARK: UI_xxx Simple UInt
    
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
    
    @Test("UI_005: PythonObject (async) → UInt throws on overflow")
    func asyncUIntConversionOverflow() async throws {
        
        let tooBigForUInt64: UInt64 = 18446744073709551610
        
        let pyObj_a = try await tooBigForUInt64.toPythonObject(interpreter: interpreter)
        let pyObj = try await pyObj_a.add(77)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt(pyObj) as UInt
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == "18446744073709551687")
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI_006: PythonObject (async) → UInt throws on negative value")
    func asyncUIntConversionNegative() async throws {
        
        let regular_UInt: UInt = 40
        let negative: Int = Int(regular_UInt) - Int(regular_UInt) - 7
        
        let pyObj = try await negative.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt(pyObj) as UInt
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(negative))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI_007: SafePythonObject (synchronous) → UInt throws on overflow")
    func safeUIntConversionOverflow() async throws {
        
        let tooBigForUInt64: UInt64 = 18446744073709551610
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj_a = try tooBigForUInt64.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj = safePyObj_a + 77
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt(safePyObj) as UInt
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == "18446744073709551687")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI_008: SafePythonObject (synchronous) → UInt throws on negative value")
    func safeUIntConversionNegative() async throws {
        
        let regular_UInt: UInt = 40
        let negative: Int = Int(regular_UInt) - Int(regular_UInt) - 7
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try negative.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt(safePyObj) as UInt
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(negative))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI_009: PythonObject (async) → UInt throws on wrong type")
    func asyncUIntConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt(pyObj) as UInt
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("UI_010: SafePythonObject (synchronous) → UInt throws wrong type")
    func safeUIntConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt(safePyObj) as UInt
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI_011: SafePythonObject to UInt for unbound cases (synchronous)")
    func safeUIntUnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_uint = try UInt(a)
            #expect(a_uint == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_uint = try UInt(b)
            #expect(b_uint == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_uint = try UInt(c)
            #expect(c_uint == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_uint = try UInt(d)
            #expect(d_uint == 0)
            
            let e: PythonInterpreter.SafePythonObject = 74.6
            let e_uint = try UInt(e)
            #expect(e_uint == 74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_uint = try UInt(f)
            #expect(f_uint == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_uint = try UInt(g)
            #expect(g_uint == 17)
            
            let h: PythonInterpreter.SafePythonObject = "817"
            let h_uint = try UInt(h)
            #expect(h_uint == 817)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try UInt(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try UInt(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k: PythonInterpreter.SafePythonObject = -7
                _ = try UInt(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == "-7")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = -74.6
                _ = try UInt(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == "-74.6")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m1 = Double(UInt.max) * 4.0
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: m1 + 4.0)
                _ = try UInt(m)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError5 {
                #expect(value == String(Double(UInt.max) * 4.0 + 4.0))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError5)")
            }
            
            let thrownError6 = #expect(throws: PythonError.self) {
                let n: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try UInt(n)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError6 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError6)")
            }
        }
    }
    
    // MARK: UI8_xxx UInt8
    
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
    
    @Test("UI8_005: PythonObject (async) → UInt8 throws on overflow")
    func asyncUInt8ConversionOverflow() async throws {
        
        let big_UInt8: UInt8 = UInt8.max - 5
        let tooBigForUInt8: UInt = UInt(big_UInt8) + 25
        
        let pyObj = try await tooBigForUInt8.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt8(pyObj) as UInt8
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooBigForUInt8))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt8")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI8_006: PythonObject (async) → UInt8 throws on negative value")
    func asyncUInt8ConversionNegative() async throws {
        
        let regular_UInt8: UInt8 = 40
        let negative: Int = Int(regular_UInt8) - Int(regular_UInt8) - 7
        
        let pyObj = try await negative.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt8(pyObj) as UInt8
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(negative))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt8")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI8_007: SafePythonObject (synchronous) → UInt8 throws on overflow")
    func safeUInt8ConversionOverflow() async throws {
        
        let big_UInt8: UInt8 = UInt8.max - 5
        let tooBigForUInt8: UInt = UInt(big_UInt8) + 25
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try tooBigForUInt8.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt8(safePyObj) as UInt8
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooBigForUInt8))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI8_008: SafePythonObject (synchronous) → UInt8 throws on negative value")
    func safeUInt8ConversionNegative() async throws {
        
        let regular_UInt8: UInt8 = 40
        let negative: Int = Int(regular_UInt8) - Int(regular_UInt8) - 7
        
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try negative.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt8(safePyObj) as UInt8
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(negative))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI8_009: PythonObject (async) → UInt8 throws on wrong type")
    func asyncUInt8ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt8(pyObj) as UInt8
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt8")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("UI8_010: SafePythonObject (synchronous) → UInt8 throws wrong type")
    func safeUInt8ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt8(safePyObj) as UInt8
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI8_011: SafePythonObject to UInt8 for unbound cases (synchronous)")
    func safeUInt8UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_uint = try UInt8(a)
            #expect(a_uint == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_uint = try UInt8(b)
            #expect(b_uint == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_uint = try UInt8(c)
            #expect(c_uint == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_uint = try UInt8(d)
            #expect(d_uint == 0)
            
            let e: PythonInterpreter.SafePythonObject = 74.6
            let e_uint = try UInt8(e)
            #expect(e_uint == 74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_uint = try UInt8(f)
            #expect(f_uint == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_uint = try UInt8(g)
            #expect(g_uint == 17)
            
            let h: PythonInterpreter.SafePythonObject = "117"
            let h_uint = try UInt8(h)
            #expect(h_uint == 117)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try UInt8(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try UInt8(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k: PythonInterpreter.SafePythonObject = -7
                _ = try UInt8(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == "-7")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = -74.6
                _ = try UInt8(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == "-74.6")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(integerLiteral: Int(UInt8.max) + 4)
                _ = try UInt8(m)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError5 {
                #expect(value == String(Int(UInt8.max) + 4))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError5)")
            }
            
            let thrownError6 = #expect(throws: PythonError.self) {
                let n: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try UInt8(n)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError6 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt8")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError6)")
            }
        }
    }
    
    // MARK: UI16_xxx UInt16
    
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
    
    @Test("UI16_005: PythonObject (async) → UInt16 throws on overflow")
    func asyncUInt16ConversionOverflow() async throws {
        
        let big_UInt16: UInt16 = UInt16.max - 5
        let tooBigForUInt16: UInt = UInt(big_UInt16) + 25
        
        let pyObj = try await tooBigForUInt16.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt16(pyObj) as UInt16
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooBigForUInt16))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt16")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI16_006: PythonObject (async) → UInt16 throws on negative value")
    func asyncUInt16ConversionNegative() async throws {
        
        let regular_UInt16: UInt16 = 40
        let negative: Int = Int(regular_UInt16) - Int(regular_UInt16) - 7
        
        let pyObj = try await negative.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt16(pyObj) as UInt16
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(negative))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt16")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI16_007: SafePythonObject (synchronous) → UInt16 throws on overflow")
    func safeUInt16ConversionOverflow() async throws {
        
        let big_UInt16: UInt16 = UInt16.max - 5
        let tooBigForUInt16: UInt = UInt(big_UInt16) + 25
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try tooBigForUInt16.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt16(safePyObj) as UInt16
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooBigForUInt16))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI16_008: SafePythonObject (synchronous) → UInt16 throws on negative value")
    func safeUInt16ConversionNegative() async throws {
        
        let regular_UInt16: UInt16 = 40
        let negative: Int = Int(regular_UInt16) - Int(regular_UInt16) - 7
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try negative.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt16(safePyObj) as UInt16
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(negative))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI16_009: PythonObject (async) → UInt16 throws on wrong type")
    func asyncUInt16ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt16(pyObj) as UInt16
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt16")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("UI16_010: SafePythonObject (synchronous) → UInt16 throws wrong type")
    func safeUInt16ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt16(safePyObj) as UInt16
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI16_011: SafePythonObject to UInt16 for unbound cases (synchronous)")
    func safeUInt16UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_uint = try UInt16(a)
            #expect(a_uint == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_uint = try UInt16(b)
            #expect(b_uint == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_uint = try UInt16(c)
            #expect(c_uint == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_uint = try UInt16(d)
            #expect(d_uint == 0)
            
            let e: PythonInterpreter.SafePythonObject = 74.6
            let e_uint = try UInt16(e)
            #expect(e_uint == 74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_uint = try UInt16(f)
            #expect(f_uint == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_uint = try UInt16(g)
            #expect(g_uint == 17)
            
            let h: PythonInterpreter.SafePythonObject = "817"
            let h_uint = try UInt16(h)
            #expect(h_uint == 817)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try UInt16(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try UInt16(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k: PythonInterpreter.SafePythonObject = -7
                _ = try UInt16(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == "-7")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = -74.6
                _ = try UInt16(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == "-74.6")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(integerLiteral: Int(UInt16.max) + 4)
                _ = try UInt16(m)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError5 {
                #expect(value == String(Int(UInt16.max) + 4))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError5)")
            }
            
            let thrownError6 = #expect(throws: PythonError.self) {
                let n: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try UInt16(n)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError6 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt16")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError6)")
            }
        }
    }
    
    // MARK: UI32_xxx UInt32
    
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
    
    @Test("UI32_005: PythonObject (async) → UInt32 throws on overflow")
    func asyncUInt32ConversionOverflow() async throws {
        
        let big_UInt32: UInt32 = UInt32.max - 5
        let tooBigForUInt32: UInt64 = UInt64(big_UInt32) + 25
        
        let pyObj = try await tooBigForUInt32.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt32(pyObj) as UInt32
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(tooBigForUInt32))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt32")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI32_006: PythonObject (async) → UInt32 throws on negative value")
    func asyncUInt32ConversionNegative() async throws {
        
        let regular_UInt32: UInt32 = 40
        let negative: Int = Int(regular_UInt32) - Int(regular_UInt32) - 7
        
        let pyObj = try await negative.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt32(pyObj) as UInt32
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(negative))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt32")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI32_007: SafePythonObject (synchronous) → UInt32 throws on overflow")
    func safeUInt32ConversionOverflow() async throws {
        
        let big_UInt32: UInt32 = UInt32.max - 5
        let tooBigForUInt32: UInt64 = UInt64(big_UInt32) + 25
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try tooBigForUInt32.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt32(safePyObj) as UInt32
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(tooBigForUInt32))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI32_008: SafePythonObject (synchronous) → UInt32 throws on negative value")
    func safeUInt32ConversionNegative() async throws {
        
        let regular_UInt32: UInt32 = 40
        let negative: Int = Int(regular_UInt32) - Int(regular_UInt32) - 7
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try negative.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt32(safePyObj) as UInt32
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(negative))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI32_009: PythonObject (async) → UInt32 throws on wrong type")
    func asyncUInt32ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt32(pyObj) as UInt32
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt32")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("UI32_010: SafePythonObject (synchronous) → UInt32 throws wrong type")
    func safeUInt32ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt32(safePyObj) as UInt32
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI32_011: SafePythonObject to UInt32 for unbound cases (synchronous)")
    func safeUInt32UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_uint = try UInt32(a)
            #expect(a_uint == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_uint = try UInt32(b)
            #expect(b_uint == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_uint = try UInt32(c)
            #expect(c_uint == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_uint = try UInt32(d)
            #expect(d_uint == 0)
            
            let e: PythonInterpreter.SafePythonObject = 74.6
            let e_uint = try UInt32(e)
            #expect(e_uint == 74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_uint = try UInt32(f)
            #expect(f_uint == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_uint = try UInt32(g)
            #expect(g_uint == 17)
            
            let h: PythonInterpreter.SafePythonObject = "817"
            let h_uint = try UInt32(h)
            #expect(h_uint == 817)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try UInt32(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try UInt32(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k: PythonInterpreter.SafePythonObject = -7
                _ = try UInt32(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == "-7")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = -74.6
                _ = try UInt32(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == "-74.6")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(integerLiteral: Int(UInt32.max) + 4)
                _ = try UInt32(m)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError5 {
                #expect(value == String(Int(UInt32.max) + 4))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError5)")
            }
            
            let thrownError6 = #expect(throws: PythonError.self) {
                let n: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try UInt32(n)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError6 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt32")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError6)")
            }
        }
    }
    
    // MARK: UI64_xxx UInt64
    
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
    
    @Test("UI64_005: PythonObject (async) → UInt64 throws on overflow")
    func asyncUInt64ConversionOverflow() async throws {
        
        let tooBigForUInt64: UInt64 = 18446744073709551610
        
        let pyObj_a = try await tooBigForUInt64.toPythonObject(interpreter: interpreter)
        let pyObj = try await pyObj_a.add(77)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt64(pyObj) as UInt64
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == "18446744073709551687")
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt64")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI64_006: PythonObject (async) → UInt64 throws on negative value")
    func asyncUInt64ConversionNegative() async throws {
        
        let regular_UInt64: UInt64 = 40
        let negative: Int = Int(regular_UInt64) - Int(regular_UInt64) - 7
        
        let pyObj = try await negative.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt64(pyObj) as UInt64
        }
        
        if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
            #expect(value == String(negative))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt64")
        } else {
            Issue.record("Expected .conversionOverflow, but got \(thrownError)")
        }
    }
    
    @Test("UI64_007: SafePythonObject (synchronous) → UInt64 throws on overflow")
    func safeUInt64ConversionOverflow() async throws {
        
        let tooBigForUInt64: UInt64 = 18446744073709551610
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj_a = try tooBigForUInt64.toSafePythonObject(interpreter: isolatedInterpreter)
            let safePyObj = safePyObj_a + 77
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt64(safePyObj) as UInt64
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == "18446744073709551687")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI64_008: SafePythonObject (synchronous) → UInt64 throws on negative value")
    func safeUInt64ConversionNegative() async throws {
        
        let regular_UInt64: UInt64 = 40
        let negative: Int = Int(regular_UInt64) - Int(regular_UInt64) - 7
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try negative.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt64(safePyObj) as UInt64
            }
            
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError {
                #expect(value == String(negative))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI64_009: PythonObject (async) → UInt64 throws on wrong type")
    func asyncUInt64ConversionWrongType() async throws {
        
        let s = "not an integer"
        
        let pyObj = try await s.toPythonObject(interpreter: interpreter)
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await UInt64(pyObj) as UInt64
        }
        
        if case let .conversionType(value, sourceType, targetType, _) = thrownError {
            #expect(value == String(s))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "UInt64")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("UI64_010: SafePythonObject (synchronous) → UInt64 throws wrong type")
    func safeUInt64ConversionWrongType() async throws {
        
        let s = "not an integer"
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let safePyObj = try s.toSafePythonObject(interpreter: isolatedInterpreter)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try UInt64(safePyObj) as UInt64
            }
            
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == String(s))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    @Test("UI64_011: SafePythonObject to UInt64 for unbound cases (synchronous)")
    func safeUInt64UnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_uint = try UInt64(a)
            #expect(a_uint == 1)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_uint = try UInt64(b)
            #expect(b_uint == 0)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_uint = try UInt64(c)
            #expect(c_uint == 5)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_uint = try UInt64(d)
            #expect(d_uint == 0)
            
            let e: PythonInterpreter.SafePythonObject = 74.6
            let e_uint = try UInt64(e)
            #expect(e_uint == 74)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_uint = try UInt64(f)
            #expect(f_uint == 0)
            
            let g: PythonInterpreter.SafePythonObject = "17"
            let g_uint = try UInt64(g)
            #expect(g_uint == 17)
            
            let h: PythonInterpreter.SafePythonObject = "817"
            let h_uint = try UInt64(h)
            #expect(h_uint == 817)
            
            let thrownError = #expect(throws: PythonError.self) {
                let i: PythonInterpreter.SafePythonObject = "i like turnips"
                _ = try UInt64(i)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError {
                #expect(value == "i like turnips")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
            
            let thrownError2 = #expect(throws: PythonError.self) {
                let j: PythonInterpreter.SafePythonObject = ""
                _ = try UInt64(j)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError2 {
                #expect(value == "")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError2)")
            }
            
            let thrownError3 = #expect(throws: PythonError.self) {
                let k: PythonInterpreter.SafePythonObject = -7
                _ = try UInt64(k)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError3 {
                #expect(value == "-7")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError3)")
            }
            
            let thrownError4 = #expect(throws: PythonError.self) {
                let l: PythonInterpreter.SafePythonObject = -74.6
                _ = try UInt64(l)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError4 {
                #expect(value == "-74.6")
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError4)")
            }
            
            let thrownError5 = #expect(throws: PythonError.self) {
                let m1 = Double(UInt64.max) * 4.0
                let m: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: m1 + 4.0)
                _ = try UInt64(m)
            }
            if case let .conversionOverflow(value, sourceType, targetType) = thrownError5 {
                #expect(value == String(Double(UInt64.max) * 4.0 + 4.0))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionOverflow, but got \(thrownError5)")
            }
            
            let thrownError6 = #expect(throws: PythonError.self) {
                let n: PythonInterpreter.SafePythonObject = PythonInterpreter.SafePythonObject(floatLiteral: Double.infinity)
                _ = try UInt64(n)
            }
            if case let .conversionType(value, sourceType, targetType, _) = thrownError6 {
                #expect(value == String(Double.infinity))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "UInt64")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError6)")
            }
        }
    }
    
    // MARK: ST_xxx String
    
    @Test("ST_001: String → PythonObject (async)")
    func asyncStringConversion() async throws {
        
        let value = "this is a string ?"
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await String(pyObj)
        #expect(roundTrip == value)
    }

    @Test("ST_002: String → SafePythonObject (synchronous)")
    func safeStringConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let value = "this is a string ?"
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try String(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("ST_003: PythonObject to string error handling (async)")
    func asyncStringError() async throws {
        
        // \ud800 is a lone surrogate, legal in Python str but illegal in UTF-8
        let pythonCode = "poisonST_003 = '\\ud800'"
        
        try await interpreter.runSimpleString(pythonCode: pythonCode)
        let poisonObj = try await interpreter.getGlobals().getItem(key: "poisonST_003")  // __main__.__dict__["poison"]
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await String(poisonObj)
        }
        
        if case let .conversionType(_, sourceType, targetType, _) = thrownError {
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "String")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("ST_004: SafePythonObject to string error handling (synchronous)")
    func safeStringError() async throws {
        
        // \ud800 is a lone surrogate, legal in Python str but illegal in UTF-8
        let pythonCode = "poisonST_004 = '\\ud800'"
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            try isolatedInterpreter.runSimpleString(pythonCode: pythonCode)
            
            let thrownError = #expect(throws: PythonError.self) {
                // This should trigger PyUnicode_AsUTF8AndSize to return NULL
                _ = try String(isolatedInterpreter.globals["poisonST_004"])
            }
            
            if case let .conversionType(_, sourceType, targetType, _) = thrownError {
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "String")
            } else {
                Issue.record("Expected .conversionType error")
            }
        }
    }
    
    // Real Swift string to python can only really fail with an error if out of RAM.  No testing.
    // @Test("ST_005: String to PythonObject error handling (async)")
    // @Test("ST_006: String to SafePythonObject error handling (synchronous)")
    
    @Test("ST_007: SafePythonObject to String for unbound cases (synchronous)")
    func safeStringUnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_str = try String(a)
            #expect(a_str == "True")
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_str = try String(b)
            #expect(b_str == "False")
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_str = try String(c)
            #expect(c_str == "5")
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_str = try String(d)
            #expect(d_str == "0")
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_str = try String(e)
            #expect(e_str == "-74.6")
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_str = try String(f)
            #expect(f_str == "0.0")
            
            let g: PythonInterpreter.SafePythonObject = "i like turnips"
            let g_str = try String(g)
            #expect(g_str == "i like turnips")
            
            let h: PythonInterpreter.SafePythonObject = ""
            let h_str = try String(h)
            #expect(h_str == "")
        }
    }
    
    @Test("ST_008: SafePythonObject CustomStringConvertible description")
    func safeStringDescription() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let literalString: PythonInterpreter.SafePythonObject = "i like turnips"
            #expect(literalString.description == "i like turnips")
            #expect(literalString.playgroundDescription as? String == "i like turnips")
            #expect("\(literalString)" == "i like turnips")
            
            let literalBool: PythonInterpreter.SafePythonObject = true
            #expect(literalBool.description == "True")
            #expect(literalBool.playgroundDescription as? String == "True")
            
            let pythonCode = """
            class DescribedST008:
                def __str__(self):
                    return "from __str__"

            describedST008 = DescribedST008()
            listST008 = [1, 2, 3]
            """
            try isolatedInterpreter.runSimpleString(pythonCode: pythonCode)
            
            let described = isolatedInterpreter.globals["describedST008"]
            #expect(described.description == "from __str__")
            #expect(described.playgroundDescription as? String == "from __str__")
            
            let list = isolatedInterpreter.globals["listST008"]
            #expect(list.description == "[1, 2, 3]")
            #expect(list.playgroundDescription as? String == "[1, 2, 3]")
        }
    }
    
    // MARK: B_xxx Bool
    
    @Test("B_001: Bool → PythonObject (async)")
    func asyncBoolConversion() async throws {
        
        let a = 5
        let b = "3"
        let value = a > Int(b)!
        let pyObj = try await value.toPythonObject(interpreter: interpreter)
        
        let roundTrip = try await Bool(pyObj)
        #expect(roundTrip == value)
    }

    @Test("B_002: Bool → SafePythonObject (synchronous)")
    func safeBoolConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a = 5
            let b = "3"
            let value = a > Int(b)!
            let safePyObj = try value.toSafePythonObject(interpreter: isolatedInterpreter)
            
            let roundTrip = try Bool(safePyObj)
            #expect(roundTrip == value)
        }
    }
    
    @Test("B_003: PythonObject to bool error handling (async)")
    func asyncBoolError() async throws {
        // It's actually a little difficult to cause an error.
        
        let pythonCode = """
        class Breakable:
            def __bool__(self):
                raise ValueError("Intentional Interop Error")

        poisonB_003 = Breakable()
        """
        
        try await interpreter.runSimpleString(pythonCode: pythonCode)
        let poisonObj = try await interpreter.getGlobals().getItem(key: "poisonB_003")  // __main__.__dict__["poison"]
        
        let thrownError = await #expect(throws: PythonError.self) {
            _ = try await Bool(poisonObj)
        }
        
        if case let .conversionType(_, sourceType, targetType, _) = thrownError {
            //#expect(value == String("poison"))
            #expect(sourceType.contains("PythonObject"))
            #expect(targetType == "Bool")
        } else {
            Issue.record("Expected .conversionType, but got \(thrownError)")
        }
    }
    
    @Test("B_004: SafePythonObject to bool error handling (synchronous)")
    func safeBoolError() async throws {
        // It's actually a little difficult to cause an error.
        
        let pythonCode = """
        class Breakable:
            def __bool__(self):
                raise ValueError("Intentional Interop Error")

        poisonB_004 = Breakable()
        """
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            try isolatedInterpreter.runSimpleString(pythonCode: pythonCode)
            let thrownError = #expect(throws: PythonError.self) {
                _ = try Bool(isolatedInterpreter.globals["poisonB_004"])
            }
            
            if case let .conversionType(_, sourceType, targetType, _) = thrownError {
                //#expect(value == String("poison"))
                #expect(sourceType.contains("SafePythonObject"))
                #expect(targetType == "Bool")
            } else {
                Issue.record("Expected .conversionType, but got \(thrownError)")
            }
        }
    }
    
    // PyBool_FromLong never fails.  Errors don't happen.  No testing is possible.
    // @Test("B_005: Bool to PythonObject error handling (async)")
    // @Test("B_006: Bool to SafePythonObject error handling (synchronous)")
    
    @Test("B_007: SafePythonObject to Bool for unbound cases (synchronous)")
    func safeBoolUnboundConversion() async throws {
        
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let a: PythonInterpreter.SafePythonObject = true
            let a_bool = try Bool(a)
            #expect(a_bool == true)
            
            let b: PythonInterpreter.SafePythonObject = false
            let b_bool = try Bool(b)
            #expect(b_bool == false)
            
            let c: PythonInterpreter.SafePythonObject = 5
            let c_bool = try Bool(c)
            #expect(c_bool == true)
            
            let d: PythonInterpreter.SafePythonObject = 0
            let d_bool = try Bool(d)
            #expect(d_bool == false)
            
            let e: PythonInterpreter.SafePythonObject = -74.6
            let e_bool = try Bool(e)
            #expect(e_bool == true)
            
            let f: PythonInterpreter.SafePythonObject = 0.0
            let f_bool = try Bool(f)
            #expect(f_bool == false)
            
            let g: PythonInterpreter.SafePythonObject = "i like turnips"
            let g_bool = try Bool(g)
            #expect(g_bool == true)
            
            let h: PythonInterpreter.SafePythonObject = ""
            let h_bool = try Bool(h)
            #expect(h_bool == false)
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
// [2026-05-03] : FD_009 : Test Convert PythonObject to Double error handling when it's not a numeric value
// [2026-04-09] : FD_003 : Test Convert Double to SafePythonObject
// [2026-04-09] : FD_004 : Test Convert Double to SafePythonObject special -1.0
// [2026-04-09] : FD_003 : Test Convert SafePythonObject to Double
// [2026-04-09] : FD_004 : Test Convert SafePythonObject to Double special -1.0
// [2026-05-03] : FD_010 : Test Convert SafePythonObject to Double error handling when it's not a numeric value
// [2026-05-03] : FD_011 : Test Convert SafePythonObject to Double for unbound cases

// [2026-04-10] : FF_001 : Test Convert Float to PythonObject
// [2026-04-10] : FF_002 : Test Convert Float to PythonObject special -1.0
// [2026-04-10] : FF_001 : Test Convert PythonObject to Float
// [2026-04-10] : FF_002 : Test Convert PythonObject to Float special -1.0
// [2026-05-03] : FF_009 : Test Convert PythonObject to Float error handling when it's not a numeric value
// [2026-04-10] : FF_003 : Test Convert Float to SafePythonObject
// [2026-04-10] : FF_004 : Test Convert Float to SafePythonObject special -1.0
// [2026-04-10] : FF_003 : Test Convert SafePythonObject to Float
// [2026-04-10] : FF_004 : Test Convert SafePythonObject to Float special -1.0
// [2026-05-03] : FF_010 : Test Convert SafePythonObject to Float error handling when it's not a numeric value
// [2026-05-03] : FF_011 : Test Convert SafePythonObject to Float for unbound cases

// [2026-04-10] : F16_001 : Test Convert Float16 to PythonObject
// [2026-04-10] : F16_002 : Test Convert Float16 to PythonObject special -1.0
// [2026-04-10] : F16_001 : Test Convert PythonObject to Float16
// [2026-04-10] : F16_002 : Test Convert PythonObject to Float16 special -1.0
// [2026-05-03] : F16_009 : Test Convert PythonObject to Float16 error handling when it's not a numeric value
// [2026-04-10] : F16_003 : Test Convert Float16 to SafePythonObject
// [2026-04-10] : F16_004 : Test Convert Float16 to SafePythonObject special -1.0
// [2026-04-10] : F16_003 : Test Convert SafePythonObject to Float16
// [2026-04-10] : F16_004 : Test Convert SafePythonObject to Float16 special -1.0
// [2026-05-03] : F16_010 : Test Convert SafePythonObject to Float16 error handling when it's not a numeric value
// [2026-05-03] : F16_011 : Test Convert SafePythonObject to Float16 for unbound cases

// Signed Integers

// [2026-04-09] : I_001 : Test Convert Int to PythonObject
// [2026-04-09] : I_002 : Test Convert Int to PythonObject special value -1
// [2026-04-09] : I_001 : Test Convert PythonObject to Int
// [2026-04-09] : I_002 : Test Convert PythonObject to Int special value  -1
// [2026-04-21] : I_009 : Test Convert PythonObject to Int error handling when it's not a numeric value
// [2026-04-21] : I_005 : Test Convert PythonObject to Int error handling when it's a huge number that won't fit in an Int
// [2026-04-21] : I_006 : Test Convert PythonObject to Int error handling when it's a huge negative number that won't fit in an Int
// [2026-04-09] : I_003 : Test Convert Int to SafePythonObject
// [2026-04-09] : I_004 : Test Convert Int to SafePythonObject special value -1
// [2026-04-09] : I_003 : Test Convert SafePythonObject to Int
// [2026-04-09] : I_004 : Test Convert SafePythonObject to Int special value -1
// [2026-04-21] : I_010 : Test Convert SafePythonObject to Int error handling when it's not a numeric value
// [2026-04-21] : I_007 : Test Convert SafePythonObject to Int error handling when it's a huge number that won't fit in an Int
// [2026-04-21] : I_008 : Test Convert SafePythonObject to Int error handling when it's a huge negative number that won't fit in an Int
// [2026-05-02] : I_011 : Test Convert unbound SafePythonObject to Int

// [2026-04-11] : I8_001 : Test Convert Int8 to PythonObject
// [2026-04-11] : I8_002 : Test Convert Int8 to PythonObject special value -1
// [2026-04-11] : I8_001 : Test Convert PythonObject to Int8
// [2026-04-11] : I8_002 : Test Convert PythonObject to Int8 special value -1
// [2026-04-21] : I8_009 : Test Convert PythonObject to Int8 error handling when it's not a numeric value
// [2026-04-21] : I8_005 : Test Convert PythonObject to Int8 error handling overflow
// [2026-04-21] : I8_006 : Test Convert PythonObject to Int8 error handling underflow
// [2026-04-11] : I8_003 : Test Convert Int8 to SafePythonObject
// [2026-04-11] : I8_004 : Test Convert Int8 to SafePythonObject special value -1
// [2026-04-11] : I8_003 : Test Convert SafePythonObject to Int8
// [2026-04-11] : I8_004 : Test Convert SafePythonObject to Int8 special value -1
// [2026-04-21] : I8_010 : Test Convert SafePythonObject to Int8 error handling when it's not a numeric value
// [2026-04-21] : I8_007 : Test Convert SafePythonObject to Int8 error handling overflow
// [2026-04-21] : I8_008 : Test Convert SafePythonObject to Int8 error handling underflow
// [2026-05-02] : I8_011 : Test Convert unbound SafePythonObject to Int8

// [2026-04-11] : I16_001 : Test Convert Int16 to PythonObject
// [2026-04-11] : I16_002 : Test Convert Int16 to PythonObject special value -1
// [2026-04-11] : I16_001 : Test Convert PythonObject to Int16
// [2026-04-11] : I16_002 : Test Convert PythonObject to Int16 special value -1
// [2026-04-21] : I16_009 : Test Convert PythonObject to Int16 error handling when it's not a numeric value
// [2026-04-21] : I16_005 : Test Convert PythonObject to Int16 error handling overflow
// [2026-04-21] : I16_006 : Test Convert PythonObject to Int16 error handling underflow
// [2026-04-11] : I16_003 : Test Convert Int16 to SafePythonObject
// [2026-04-11] : I16_004 : Test Convert Int16 to SafePythonObject special value -1
// [2026-04-11] : I16_003 : Test Convert SafePythonObject to Int16
// [2026-04-11] : I16_004 : Test Convert SafePythonObject to Int16 special value -1
// [2026-04-21] : I16_010 : Test Convert SafePythonObject to Int16 error handling when it's not a numeric value
// [2026-04-21] : I16_007 : Test Convert SafePythonObject to Int16 error handling overflow
// [2026-04-21] : I16_008 : Test Convert SafePythonObject to Int16 error handling underflow
// [2026-05-02] : I16_011 : Test Convert unbound SafePythonObject to Int16

// [2026-04-11] : I32_001 : Test Convert Int32 to PythonObject
// [2026-04-11] : I32_002 : Test Convert Int32 to PythonObject special value -1
// [2026-04-11] : I32_001 : Test Convert PythonObject to Int32
// [2026-04-11] : I32_002 : Test Convert PythonObject to Int32 special value -1
// [2026-04-21] : I32_009 : Test Convert PythonObject to Int32 error handling when it's not a numeric value
// [2026-04-21] : I32_005 : Test Convert PythonObject to Int32 error handling overflow
// [2026-04-21] : I32_006 : Test Convert PythonObject to Int32 error handling underflow
// [2026-04-11] : I32_003 : Test Convert Int32 to SafePythonObject
// [2026-04-11] : I32_004 : Test Convert Int32 to SafePythonObject special value -1
// [2026-04-11] : I32_003 : Test Convert SafePythonObject to Int32
// [2026-04-11] : I32_004 : Test Convert SafePythonObject to Int32 special value -1
// [2026-04-21] : I32_010 : Test Convert SafePythonObject to Int32 error handling when it's not a numeric value
// [2026-04-21] : I32_007 : Test Convert SafePythonObject to Int32 error handling overflow
// [2026-04-21] : I32_008 : Test Convert SafePythonObject to Int32 error handling underflow
// [2026-05-02] : I32_011 : Test Convert unbound SafePythonObject to Int32

// [2026-04-11] : I64_001 : Test Convert Int64 to PythonObject
// [2026-04-11] : I64_002 : Test Convert Int64 to PythonObject special value -1
// [2026-04-11] : I64_001 : Test Convert PythonObject to Int64
// [2026-04-11] : I64_002 : Test Convert PythonObject to Int64 special value -1
// [2026-04-21] : I64_009 : Test Convert PythonObject to Int64 error handling when it's not a numeric value
// [2026-04-21] : I64_005 : Test Convert PythonObject to Int64 error handling overflow
// [2026-04-21] : I64_006 : Test Convert PythonObject to Int64 error handling underflow
// [2026-04-11] : I64_003 : Test Convert Int64 to SafePythonObject
// [2026-04-11] : I64_004 : Test Convert Int64 to SafePythonObject special value -1
// [2026-04-11] : I64_003 : Test Convert SafePythonObject to Int64
// [2026-04-11] : I64_004 : Test Convert SafePythonObject to Int64 special value -1
// [2026-04-21] : I64_010 : Test Convert SafePythonObject to Int64 error handling when it's not a numeric value
// [2026-04-21] : I64_007 : Test Convert SafePythonObject to Int64 error handling overflow
// [2026-04-21] : I64_008 : Test Convert SafePythonObject to Int64 error handling underflow
// [2026-05-02] : I64_011 : Test Convert unbound SafePythonObject to Int64

// Unsigned Integers

// [2026-04-10] : UI_001 : Test Convert UInt to PythonObject
// [2026-04-10] : UI_002 : Test Convert UInt to PythonObject special value -1 equiv Self.max
// [2026-04-10] : UI_001 : Test Convert PythonObject to UInt
// [2026-04-10] : UI_002 : Test Convert PythonObject to UInt special value -1 equiv Self.max
// [2026-04-20] : UI_009 : Test Convert PythonObject to UInt error handling when it's not a numeric value
// [2026-04-20] : UI_005 : Test Convert PythonObject to UInt error handling on overflow
// [2026-04-20] : UI_006 : Test Convert PythonObject to UInt negative number error handling
// [2026-04-10] : UI_003 : Test Convert UInt to SafePythonObject
// [2026-04-10] : UI_004 : Test Convert UInt to SafePythonObject special value -1 equiv Self.max
// [2026-04-10] : UI_003 : Test Convert SafePythonObject to UInt
// [2026-04-10] : UI_004 : Test Convert SafePythonObject to UInt special value -1 equiv Self.max
// [2026-04-20] : UI_010 : Test Convert SafePythonObject to UInt error handling when it's not a numeric value
// [2026-04-20] : UI_007 : Test Convert SafePythonObject to UInt error handling on overflow
// [2026-04-20] : UI_008 : Test Convert SafePythonObject to UInt negative number error handling
// [2026-05-02] : UI_011 : Test Convert SafePythonObject to UInt for unbound cases

// [2026-04-10] : UI8_001 : Test Convert UInt8 to PythonObject
// [2026-04-10] : UI8_002 : Test Convert UInt8 to PythonObject special value -1 equiv Self.max
// [2026-04-10] : UI8_001 : Test Convert PythonObject to UInt8
// [2026-04-10] : UI8_002 : Test Convert PythonObject to UInt8 special value -1 equiv Self.max
// [2026-04-12] : UI8_009 : Test Convert PythonObject to UInt8 error handling when it's not a numeric value
// [2026-04-12] : UI8_005 : Test Convert PythonObject to UInt8 error handling on overflow
// [2026-04-19] : UI8_006 : Test Convert PythonObject to UInt8 negative number error handling
// [2026-04-10] : UI8_003 : Test Convert UInt8 to SafePythonObject
// [2026-04-10] : UI8_004 : Test Convert UInt8 to SafePythonObject special value -1 equiv Self.max
// [2026-04-10] : UI8_003 : Test Convert SafePythonObject to UInt8
// [2026-04-10] : UI8_004 : Test Convert SafePythonObject to UInt8 special value -1 equiv Self.max
// [2026-04-12] : UI8_010 : Test Convert SafePythonObject to UInt8 error handling when it's not a numeric value
// [2026-04-12] : UI8_007 : Test Convert SafePythonObject to UInt8 error handling on overflow
// [2026-04-19] : UI8_008 : Test Convert SafePythonObject to UInt8 negative number error handling
// [2026-05-02] : UI8_011 : Test Convert SafePythonObject to UInt8 for unbound cases


// [2026-04-10] : UI16_001 : Test Convert UInt16 to PythonObject
// [2026-04-10] : UI16_002 : Test Convert UInt16 to PythonObject special value -1 equiv Self.max
// [2026-04-10] : UI16_001 : Test Convert PythonObject to UInt16
// [2026-04-10] : UI16_002 : Test Convert PythonObject to UInt16 special value -1 equiv Self.max
// [2026-04-19] : UI16_009 : Test Convert PythonObject to UInt16 error handling when it's not a numeric value
// [2026-04-19] : UI16_005 : Test Convert PythonObject to UInt16 error handling on overflow
// [2026-04-19] : UI16_006 : Test Convert PythonObject to UInt16 negative number error handling
// [2026-04-10] : UI16_003 : Test Convert UInt16 to SafePythonObject
// [2026-04-10] : UI16_004 : Test Convert UInt16 to SafePythonObject special value -1 equiv Self.max
// [2026-04-10] : UI16_003 : Test Convert SafePythonObject to UInt16
// [2026-04-10] : UI16_004 : Test Convert SafePythonObject to UInt16 special value -1 equiv Self.max
// [2026-04-19] : UI16_010 : Test Convert SafePythonObject to UInt16 error handling when it's not a numeric value
// [2026-04-19] : UI16_007 : Test Convert SafePythonObject to UInt16 error handling on overflow
// [2026-04-19] : UI16_008 : Test Convert SafePythonObject to UInt16 negative number error handling
// [2026-05-02] : UI16_011 : Test Convert SafePythonObject to UInt16 for unbound cases

// [2026-04-10] : UI32_001 : Test Convert UInt32 to PythonObject
// [2026-04-10] : UI32_002 : Test Convert UInt32 to PythonObject special value -1 equiv Self.max
// [2026-04-10] : UI32_001 : Test Convert PythonObject to UInt32
// [2026-04-10] : UI32_002 : Test Convert PythonObject to UInt32 special value -1 equiv Self.max
// [2026-04-19] : UI32_009 : Test Convert PythonObject to UInt32 error handling when it's not a numeric value
// [2026-04-19] : UI32_005 : Test Convert PythonObject to UInt32 error handling on overflow
// [2026-04-19] : UI32_006 : Test Convert PythonObject to UInt32negative number error handling
// [2026-04-10] : UI32_003 : Test Convert UInt32 to SafePythonObject
// [2026-04-10] : UI32_004 : Test Convert UInt32 to SafePythonObject special value -1 equiv Self.max
// [2026-04-10] : UI32_003 : Test Convert SafePythonObject to UInt32
// [2026-04-10] : UI32_004 : Test Convert SafePythonObject to UInt32 special value -1 equiv Self.max
// [2026-04-19] : UI32_010 : Test Convert SafePythonObject to UInt32 error handling when it's not a numeric value
// [2026-04-19] : UI32_007 : Test Convert SafePythonObject to UInt32 error handling on overflow
// [2026-04-19] : UI32_008 : Test Convert SafePythonObject to UInt32 negative number error handling
// [2026-05-02] : UI32_011 : Test Convert SafePythonObject to UInt32 for unbound cases

// [2026-04-10] : UI64_001 : Test Convert UInt64 to PythonObject
// [2026-04-10] : UI64_002 : Test Convert UInt64 to PythonObject special value -1 equiv Self.max
// [2026-04-10] : UI64_001 : Test Convert PythonObject to UInt64
// [2026-04-10] : UI64_002 : Test Convert PythonObject to UInt64 special value -1 equiv Self.max
// [2026-04-19] : UI64_009 : Test Convert PythonObject to UInt64 error handling when it's not a numeric value
// [2026-04-19] : UI64_005 : Test Convert PythonObject to UInt64 error handling on overflow
// [2026-04-19] : UI64_006 : Test Convert PythonObject to UInt64 negative number error handling
// [2026-04-10] : UI64_003 : Test Convert UInt64 to SafePythonObject
// [2026-04-10] : UI64_004 : Test Convert UInt64 to SafePythonObject special value -1 equiv Self.max
// [2026-04-10] : UI64_003 : Test Convert SafePythonObject to UInt64
// [2026-04-10] : UI64_004 : Test Convert SafePythonObject to UInt64 special value -1 equiv Self.max
// [2026-04-19] : UI64_010 : Test Convert SafePythonObject to UInt64 error handling when it's not a numeric value
// [2026-04-19] : UI64_007 : Test Convert SafePythonObject to UInt64 error handling on overflow
// [2026-04-19] : UI64_008 : Test Convert SafePythonObject to UInt64 negative number error handling
// [2026-05-02] : UI64_011 : Test Convert SafePythonObject to UInt64 for unbound cases

// Bool

// [2026-05-01] : B_001 : Test Convert Bool to PythonObject
// [2026-05-02] : B_005 : *** Test Convert Bool to PythonObject error handling
// [2026-05-01] : B_001 : Test Convert PythonObject to Bool
// [2026-05-01] : B_003 : Test Convert PythonObject to Bool error handling
// [2026-05-01] : B_002 : Test Convert Bool to SafePythonObject
// [2026-05-02] : B_006 : *** Test Convert Bool to SafePythonObject error handling
// [2026-05-01] : B_002 : Test Convert SafePythonObject to Bool
// [2026-05-01] : B_004 : Test Convert SafePythonObject to Bool error handling
// [2026-05-02] : B_007 : Test Convert SafePythonObject to Bool for unbound cases

// Strings

// [2026-05-02] : ST_001 : Test Convert String to PythonObject
// [2026-05-02] : ST_005 : *** Test Convert Bool to PythonObject error handling
// [2026-05-02] : ST_001 : Test Convert PythonObject to String
// [2026-05-02] : ST_003 : Test Convert PythonObject to String error handling
// [2026-05-02] : ST_002 : Test Convert String to SafePythonObject
// [2026-05-02] : ST_006 : *** Test Convert String to SafePythonObject error handling
// [2026-05-02] : ST_002 : Test Convert SafePythonObject to String
// [2026-05-02] : ST_003 : Test Convert SafePythonObject to String error handling
// [2026-05-02] : ST_007 : Test Convert SafePythonObject to String for unbound cases
