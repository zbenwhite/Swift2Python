//
//  File.swift
//  Swift2Python
//
//  Created by Ben White on 4/26/26.
//

import Foundation

extension PythonInterpreter.SafePythonObject {
    
    public func convertToBool() throws -> Bool {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.convertToBool(self)
            }
        case .deferredDouble(let val):
            return val == 0.0 ? false : true
        case .deferredInt(let val):
            return val == 0 ? false : true
        case .deferredString(let val):
            let trimmed = val.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed == "0" || trimmed.lowercased() == "false" {
                return false
            }
            return true
        case .deferredBool(let val):
            return val
        }
    }
    
    public func convertToDouble() throws -> Double {
        switch state {
        case .bound:
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.convertToDouble(self)
            }
        case .deferredDouble(let val):
            return val
        case .deferredInt(let val):
            return Double(val)
        case .deferredString(let val):
            guard let double = Double(val) else {
                throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "Double", underlying: nil )
            }
            return double
        case .deferredBool(let val):
            return val ? 1.0 : 0.0
        }
    }
    
    public func convertToFloat() throws -> Float {
        do {
            return Float(try convertToDouble())
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, _, let underlying):
                throw PythonError.conversionType( value: value, sourceType: sourceType, targetType: "Float", underlying: underlying )
            default:
                throw error
            }
        }
    }
    
    public func convertToFloat16() throws -> Float16 {
        do {
            return Float16(try convertToDouble())
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, _, let underlying):
                throw PythonError.conversionType( value: value, sourceType: sourceType, targetType: "Float16", underlying: underlying )
            default:
                throw error
            }
        }
    }
    
    public func convertToInt() throws -> Int {
        switch state {
        case .bound:
            // Use Python to convert python object to Int
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.convertToInt(self)
            }
        case .deferredDouble(let val):
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int", underlying: nil)
            }
            if let exact = Int(exactly: val) {
                return exact
            }
            if val > Double(Int.max) || val < Double(Int.min) {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "Int" )
            }
            return Int(val.rounded(.towardZero))
        case .deferredInt(let val):
            return val
        case .deferredString(let val):
            if let intValue = Int(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "Int", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int8", underlying: nil)
            }
            if let exact = Int8(exactly: val) {
                return exact
            }
            if val > Double(Int8.max) || val < Double(Int8.min) {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "Int8" )
            }
            return Int8(val.rounded(.towardZero))
        case .deferredInt(let val):
            if val > Int(Int8.max) || val < Int(Int8.min) {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "Int8" )
            }
            if let intValue = Int8(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int8", underlying: nil)
        case .deferredString(let val):
            if let intValue = Int8(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "Int8", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int16", underlying: nil)
            }
            if let exact = Int16(exactly: val) {
                return exact
            }
            if val > Double(Int16.max) || val < Double(Int16.min) {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "Int16" )
            }
            return Int16(val.rounded(.towardZero))
        case .deferredInt(let val):
            if val > Int(Int16.max) || val < Int(Int16.min) {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "Int16" )
            }
            if let intValue = Int16(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int16", underlying: nil)
        case .deferredString(let val):
            if let intValue = Int16(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "Int16", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int32", underlying: nil)
            }
            if let exact = Int32(exactly: val) {
                return exact
            }
            if val > Double(Int32.max) || val < Double(Int32.min) {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "Int32" )
            }
            return Int32(val.rounded(.towardZero))
        case .deferredInt(let val):
            if val > Int(Int32.max) || val < Int(Int32.min) {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "Int32" )
            }
            if let intValue = Int32(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int32", underlying: nil)
        case .deferredString(let val):
            if let intValue = Int32(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "Int32", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int64", underlying: nil)
            }
            if let exact = Int64(exactly: val) {
                return exact
            }
            if val > Double(Int64.max) || val < Double(Int64.min) {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "Int64" )
            }
            return Int64(val.rounded(.towardZero))
        case .deferredInt(let val):
            if let intValue = Int64(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "Int64", underlying: nil)
        case .deferredString(let val):
            if let intValue = Int64(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "Int64", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt", underlying: nil)
            }
            if let exact = UInt(exactly: val) {
                return exact
            }
            if val > Double(UInt.max) || val < 0.0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt" )
            }
            return UInt(val.rounded(.towardZero))
        case .deferredInt(let val):
            if val < 0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt" )
            }
            if let intValue = UInt(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt", underlying: nil)
        case .deferredString(let val):
            if let intValue = UInt(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "UInt", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt8", underlying: nil)
            }
            if let exact = UInt8(exactly: val) {
                return exact
            }
            if val > Double(UInt8.max) || val < 0.0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt8" )
            }
            return UInt8(val.rounded(.towardZero))
        case .deferredInt(let val):
            if val > Int(UInt8.max) || val < 0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt8" )
            }
            if let intValue = UInt8(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt8", underlying: nil)
        case .deferredString(let val):
            if let intValue = UInt8(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "UInt8", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt16", underlying: nil)
            }
            if let exact = UInt16(exactly: val) {
                return exact
            }
            if val > Double(UInt16.max) || val < 0.0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt16" )
            }
            return UInt16(val.rounded(.towardZero))
        case .deferredInt(let val):
            if val > Int(UInt16.max) || val < 0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt16" )
            }
            if let intValue = UInt16(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt16", underlying: nil)
        case .deferredString(let val):
            if let intValue = UInt16(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "UInt16", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt32", underlying: nil)
            }
            if let exact = UInt32(exactly: val) {
                return exact
            }
            if val > Double(UInt32.max) || val < 0.0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt32" )
            }
            return UInt32(val.rounded(.towardZero))
        case .deferredInt(let val):
            if val > Int(UInt32.max) || val < 0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt32" )
            }
            if let intValue = UInt32(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt32", underlying: nil)
        case .deferredString(let val):
            if let intValue = UInt32(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "UInt32", underlying: nil)
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
            // Double
            //    Fails for Nan or infinity -- conversionType
            //    Fails for overflow -- conversionOverflow
            //    converts for exact match
            //    otherwise rounds toward zero
            guard val.isFinite else {
                throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt64", underlying: nil)
            }
            if let exact = UInt64(exactly: val) {
                return exact
            }
            if val > Double(UInt64.max) || val < 0.0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt64" )
            }
            return UInt64(val.rounded(.towardZero))
        case .deferredInt(let val):
            if val < 0 {
                throw PythonError.conversionOverflow( value: String(val), sourceType: "SafePythonObject", targetType: "UInt64" )
            }
            if let intValue = UInt64(exactly:val) {
                return intValue
            }
            throw PythonError.conversionType( value: String(val), sourceType: "SafePythonObject", targetType: "UInt64", underlying: nil)
        case .deferredString(let val):
            if let intValue = UInt64(val) {
                return intValue
            }
            throw PythonError.conversionType( value: val, sourceType: "SafePythonObject", targetType: "UInt64", underlying: nil)
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
