//
//  File.swift
//  Swift2Python
//
//  Created by Ben White on 4/26/26.
//

import Foundation

extension PythonInterpreter.SafePythonObject {
    
    public func convertToDouble() throws -> Double {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return localInterpreter.assumeIsolated {
                do {
                    return try $0.convertToDouble(self)
                } catch {
                    fatalError("Failed to get attribute: \(error)")
                }
            }
        case .deferredDouble(let val):
            return val
        case .deferredInt(let val):
            return Double(val)
        case .deferredString(let val):
            // mimic python string conversion to Double
            guard let double = Double(val) else {
                fatalError("placeholder")
            }
            return double
        case .deferredBool(let val):
            return val ? 1.0 : 0.0
        }
    }
    
    public func convertToInt() throws -> Int {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.convertToInt(self)
            }
        case .deferredDouble(let val):
            if let i = Int(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredInt(let val):
            return val
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            guard let intValue = Int(val) else {   // Swift Int(String) is close but slightly stricter than Python on some edge cases
                // Optional improvement: try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                if let double = Double(val), double.isFinite {
                    return Int(double)             // this would make int("3.14") == 3 (more forgiving)
                }
                fatalError("placeholder")
            }
            return intValue
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToInt8() throws -> Int8 {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.convertToInt8(self)
            }
        case .deferredDouble(let val):
            if let i = Int8(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = Int8(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            let iVal: Int
            if let intValue = Int(val) {
                iVal = intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                iVal = Int(double)
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
            if let i = Int8(exactly:iVal) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToInt16() throws -> Int16 {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.convertToInt16(self)
            }
        case .deferredDouble(let val):
            if let i = Int16(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = Int16(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            let iVal: Int
            if let intValue = Int(val) {
                iVal = intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                iVal = Int(double)
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
            if let i = Int16(exactly:iVal) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToInt32() throws -> Int32 {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.convertToInt32(self)
            }
        case .deferredDouble(let val):
            if let i = Int32(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = Int32(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            let iVal: Int
            if let intValue = Int(val) {
                iVal = intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                iVal = Int(double)
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
            if let i = Int32(exactly:iVal) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToInt64() throws -> Int64 {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.convertToInt64(self)
            }
        case .deferredDouble(let val):
            if let i = Int64(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = Int64(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            if let intValue = Int64(val) {
               return intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                if let intValue = Int64(exactly:double) {
                    return intValue
                }
                else {
                    fatalError("placeholder")  // out of range
                }
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToUInt() throws -> UInt {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.convertToUInt(self)
            }
        case .deferredDouble(let val):
            if let i = UInt(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = UInt(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            if let intValue = UInt(val) {
               return intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                if let intValue = UInt(exactly:double) {
                    return intValue
                }
                else {
                    fatalError("placeholder")  // out of range
                }
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToUInt8() throws -> UInt8 {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.convertToUInt8(self)
            }
        case .deferredDouble(let val):
            if let i = UInt8(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = UInt8(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            if let intValue = UInt8(val) {
               return intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                if let intValue = UInt8(exactly:double) {
                    return intValue
                }
                else {
                    fatalError("placeholder")  // out of range
                }
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToUInt16() throws -> UInt16 {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.convertToUInt16(self)
            }
        case .deferredDouble(let val):
            if let i = UInt16(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = UInt16(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            if let intValue = UInt16(val) {
               return intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                if let intValue = UInt16(exactly:double) {
                    return intValue
                }
                else {
                    fatalError("placeholder")  // out of range
                }
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToUInt32() throws -> UInt32 {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.convertToUInt32(self)
            }
        case .deferredDouble(let val):
            if let i = UInt32(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = UInt32(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            if let intValue = UInt32(val) {
               return intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                if let intValue = UInt32(exactly:double) {
                    return intValue
                }
                else {
                    fatalError("placeholder")  // out of range
                }
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToUInt64() throws -> UInt64 {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.convertToUInt64(self)
            }
        case .deferredDouble(let val):
            if let i = UInt64(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")  // overflow
            }
        case .deferredInt(let val):
            if let i = UInt64(exactly:val) {
                return i
            }
            else {
                fatalError("placeholder")
            }
        case .deferredString(let val):
            // Mimic Python's int("...")
            // Python accepts decimal strings, but does NOT accept floats like "3.14"
            // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
            // For full fidelity you can later add radix support.
            if let intValue = UInt64(val) {
               return intValue
            } else if let double = Double(val), double.isFinite {
                // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                if let intValue = UInt64(exactly:double) {
                    return intValue
                }
                else {
                    fatalError("placeholder")  // out of range
                }
            } else {
                fatalError("placeholder")  // can't convert to a number
            }
        case .deferredBool(let val):
            return val ? 1 : 0
        }
    }
    
    public func convertToString() throws -> String {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                try $0.convertToString(self)
            }
        case .deferredDouble(let val):
            return String(val)
        case .deferredInt(let val):
            return String(val)
        case .deferredString(let val):
            return val
        case .deferredBool(let val):
            return val ? "True" : "False"
        }
    }
    
}
