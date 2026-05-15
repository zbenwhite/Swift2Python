//
//  PythonInterpreter+Convert.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

import Foundation


extension PythonInterpreter {
    
    
    // MARK: Python API Helpers
    
    // This requires the GIL
    private func pythonErrorOccurred() -> Bool {
        // pythonErr_Occurred returns a borrowed error pointer.  No need to py_DecRef it
        // because it is not used.  Python owns it.  Only checking if it's NULL (no error)
        // or has a value (error).
        if let _ = api.pythonErr_Occurred() {
            return true
        }
        return false
    }
    
    // This requires the GIL
    private func asDouble(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Double  {
        let value = api.pythonFloat_AsDouble(objPtr)
        if value == -1.0 {
            if pythonErrorOccurred() {
                try throwError()
            }
        }
        return value
    }
    
    // This requires the GIL
    private func asLongLong(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> Int64  {
        let value = api.pythonLong_AsLongLong(objPtr)
        if value == -1 {
            if pythonErrorOccurred() {
                try throwError()
            }
        }
        return value
    }
    
    // This requires the GIL
    private func asUnsignedLongLong(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> UInt64  {
        let value = api.pythonLong_AsUnsignedLongLong(objPtr)
        if value == UInt64.max {              // (unsigned long long)-1 on error
            if pythonErrorOccurred() {
                try throwError()
            }
        }
        return value
    }
    
    private func asUTF8String(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never ) throws -> String  {
        if let s = api.pythonUnicode_AsUTF8AndSize(objPtr) {
            return s
        } else {
            try throwError()
        }
    }
    
    // This requires the GIL
    private func toPythonBoolFromBool(_ value: Bool, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer  {
        // PyBool_FromLong never fails.
        guard let ptr = api.pythonBool_FromLong(value) else {
            try throwError()
        }
        return ptr
    }
    
    // This requires the GIL
    private func toPythonFloatFromDouble(_ value: Double, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer  {
        guard let ptr = api.pythonFloat_FromDouble(value) else {
            try throwError()
        }
        return ptr
    }
    
    // This requires the GIL
    private func toPythonIntFromLongLong(_ value: Int64, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer  {
        guard let ptr = api.pythonLong_FromLongLong(value) else {
            try throwError()
        }
        return ptr
    }
    
    // This requires the GIL
    private func toPythonIntFromUnsignedLongLong(_ value: UInt64, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer  {
        guard let ptr = api.pythonLong_FromUnsignedLongLong(value) else {
            try throwError()
        }
        return ptr
    }
    
    // This requires the GIL
    private func toPythonUnicodeFromString(_ value: String, onError throwError: () throws -> Never ) throws -> UnsafeMutableRawPointer  {
        guard let ptr = api.pythonUnicode_FromStringAndSize(value) else {
            try throwError()
        }
        return ptr
    }
    
    // MARK: Bool Conversions
    
    public func convertToPython(bool: Bool) async throws -> PythonObject {
        return try await withGIL {
            // PyBool_FromLong never fails.  Unknown error is fine.
            let ptr = try toPythonBoolFromBool(bool, onError: { throw PythonError.unknownPythonException } )
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    public func convertToBool(_ obj: PythonObject) async throws -> Bool {
        logger.trace("convertToBool: Convert PythonObject to Bool.")
        let boolValue: Bool
        do {
            boolValue = try await obj.isTrue()
        } catch let error as PythonError {
            let objStr = (try? await String(obj)) ?? "<unrepresentable>"
            throw PythonError.conversionType(value: objStr, sourceType: "PythonObject", targetType: "Bool", underlying: error)
        }
        return boolValue
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToBool(_ obj: SafePythonObject) throws -> Bool {
        let boolValue: Bool
        do {
            boolValue = try obj.isTrue()
        } catch let error as PythonError {
            let objStr = (try? String(obj)) ?? "<unrepresentable>"
            throw PythonError.conversionType(value: objStr, sourceType: "SafePythonObject", targetType: "Bool", underlying: error)
        }
        return boolValue
    }
    
    // MARK: Double Conversions
    
    public func convertToPython(double: Double) async throws -> PythonObject {
        return try await withGIL {
            let ptr = try toPythonFloatFromDouble(double, onError: { try throwPythonError() })
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    public func convertToDouble(_ obj: PythonObject) async throws -> Double {
        let objPtr = getRegisteredPointer(forPythonObject:obj)!
        do {
            return try await withGIL {
                return try asDouble(objPtr, onError: { try throwPythonError() } )
            }
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "Double", underlying: error )
            default: throw error
            }
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToDouble(_ obj: SafePythonObject) throws -> Double {
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        do {
            return try asDouble(objPtr, onError: { try throwSafePythonError() } )
        } catch let error as PythonError {
            switch error {
            case .safePythonException:
                let objStr = (try? String(obj)) ?? "<unrepresentable>"
                throw PythonError.conversionType( value: objStr, sourceType: "SafePythonObject", targetType: "Double", underlying: nil )
            default: throw error
            }
        }
    }
    
    // MARK: Int Conversions
    
    public func convertToPython(int val: Int64) async throws -> PythonObject {
        logger.trace("convertToPython: Convert Int64 to PythonObject.")
        return try await withGIL {
            let ptr = try toPythonIntFromLongLong(val, onError: { try throwPythonError() } )
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    internal func convertToSafePython(int val: Int64) throws -> SafePythonObject {
        let id = try convertToSafePythonID(int: val)
        let safeObj = SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: safeObj)
        return safeObj
    }
    
    internal func convertToSafePythonID(int val: Int64) throws -> PythonObjectUniqueID {
        let ptr = try toPythonIntFromLongLong(val, onError: { try throwSafePythonError() } )
        let id = registerSafePythonObject(ptr)
        return id
    }
    
    public func convertToInt(_ obj: PythonObject) async throws -> Int {
        logger.trace("convertToInt: Convert PythonObject to Int.")
        let int64Value: Int64
        do {
            int64Value = try await convertToInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to Int.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "Int", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to Int.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "Int")
            default: throw error
            }
        }
        if let intValue = Int(exactly: int64Value) {
            return intValue
        } else {
            throw PythonError.conversionOverflow(value: String(int64Value), sourceType: "PythonObject", targetType: "Int")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt(_ obj: SafePythonObject) throws -> Int {
        logger.trace("convertToInt: Convert SafePythonObject to Int.")
        let int64Value: Int64
        do {
            int64Value = try convertToInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to Int.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "Int", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to Int.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "Int")
            default: throw error
            }
        }
        if let intValue = Int(exactly: int64Value) {
            return intValue
        } else {
            throw PythonError.conversionOverflow(value: String(int64Value), sourceType: "SafePythonObject", targetType: "Int")
        }
    }
    
    public func convertToInt8(_ obj: PythonObject) async throws -> Int8 {
        logger.trace("convertToInt8: Convert PythonObject to Int8.")
        let int64Value: Int64
        do {
            int64Value = try await convertToInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to Int8.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "Int8", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to Int8.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "Int8")
            default: throw error
            }
        }
        if let intValue = Int8(exactly: int64Value) {
            return intValue
        } else {
            throw PythonError.conversionOverflow(value: String(int64Value), sourceType: "PythonObject", targetType: "Int8")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt8(_ obj: SafePythonObject) throws -> Int8 {
        logger.trace("convertToInt: Convert SafePythonObject to Int8.")
        let int64Value: Int64
        do {
            int64Value = try convertToInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to Int8.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "Int8", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to Int8.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "Int8")
            default: throw error
            }
        }
        if let intValue = Int8(exactly: int64Value) {
            return intValue
        } else {
            throw PythonError.conversionOverflow(value: String(int64Value), sourceType: "SafePythonObject", targetType: "Int8")
        }
    }
    
    public func convertToInt16(_ obj: PythonObject) async throws -> Int16 {
        logger.trace("convertToInt16: Convert PythonObject to Int16.")
        let int64Value: Int64
        do {
            int64Value = try await convertToInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to Int16.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "Int16", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to Int16.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "Int16")
            default: throw error
            }
        }
        if let intValue = Int16(exactly: int64Value) {
            return intValue
        } else {
            throw PythonError.conversionOverflow(value: String(int64Value), sourceType: "PythonObject", targetType: "Int16")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt16(_ obj: SafePythonObject) throws -> Int16 {
        logger.trace("convertToInt16: Convert SafePythonObject to Int16.")
        let int64Value: Int64
        do {
            int64Value = try convertToInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to Int16.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "Int16", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to Int16.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "Int16")
            default: throw error
            }
        }
        if let int16Value = Int16(exactly: int64Value) {
            return int16Value
        } else {
            throw PythonError.conversionOverflow(value: String(int64Value), sourceType: "SafePythonObject", targetType: "Int16")
        }
    }
    
    public func convertToInt32(_ obj: PythonObject) async throws -> Int32 {
        logger.trace("convertToInt32: Convert PythonObject to Int32.")
        let int64Value: Int64
        do {
            int64Value = try await convertToInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to Int32.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "Int32", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to Int32.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "Int32")
            default: throw error
            }
        }
        if let intValue = Int32(exactly: int64Value) {
            return intValue
        } else {
            throw PythonError.conversionOverflow(value: String(int64Value), sourceType: "PythonObject", targetType: "Int32")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt32(_ obj: SafePythonObject) throws -> Int32 {
        logger.trace("convertToInt32: Convert SafePythonObject to Int32.")
        let int64Value: Int64
        do {
            int64Value = try convertToInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to Int32.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "Int32", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to Int32.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "Int32")
            default: throw error
            }
        }
        if let int32Value = Int32(exactly: int64Value) {
            return int32Value
        } else {
            throw PythonError.conversionOverflow(value: String(int64Value), sourceType: "SafePythonObject", targetType: "Int32")
        }
    }
    
    public func convertToInt64(_ obj: PythonObject) async throws -> Int64 {
        logger.trace("convertToInt64: Convert PythonObject to UInt64.")
        
        // Check for huge number < -1 * 2^32 and throw conversion overflow error
        let isHugeNegative: Bool
        do {
            isHugeNegative = try await obj.lessThan(Int64.min)
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "Int64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isHugeNegative {
            logger.error("convertToInt64: Called for HUGE NEGATIVE number PythonObject.")
            let objStr = try await String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "PythonObject", targetType: "Int64")
        }
        
        // Check for huge number > 2^64 and throw conversion overflow error
        let isHuge: Bool
        do {
            isHuge = try await obj.greaterThan(Int64.max)
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "Int64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isHuge {
            logger.error("convertToUInt64: Called for HUGE number PythonObject > \(Int64.max).")
            let objStr = try await String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "PythonObject", targetType: "Int64")
        }
        
        let objPtr = getRegisteredPointer(forPythonObject:obj)!
        
        do {
            return try await withGIL {
                return try asLongLong(objPtr, onError: { try throwPythonError() } )
            }
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "Int64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
    }
    
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt64(_ obj: SafePythonObject) throws -> Int64 {
        logger.trace("convertToInt64: Convert SafePythonObject to Int64.")
        
        // Check for huge number < -1 * 2^32 and throw conversion overflow error
        let isHugeNegative: Bool
        do {
            isHugeNegative = try obj.lessThan(Int64.min)
        } catch let error as PythonError {
            switch error {
            case .safePythonException:
                let objStr = (try? String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "SafePythonObject", targetType: "Int64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isHugeNegative {
            logger.error("convertToUInt64: Called for HUGE NEGATIVE number SafePythonObject.")
            let objStr = try String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "SafePythonObject", targetType: "Int64")
        }
        
        // Check for huge number > 2^32 and throw conversion overflow error
        let isHuge: Bool
        do {
            isHuge = try obj.greaterThan(Int64.max)
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "Int64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isHuge {
            logger.error("convertToInt64: Called for HUGE number SafePythonObject > \(Int64.max).")
            let objStr = try String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "SafePythonObject", targetType: "Int64")
        }
        
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        do {
            return try asLongLong(objPtr, onError: { try throwSafePythonError() } )
        } catch let error as PythonError {
            switch error {
            case .safePythonException:
                let objStr = (try? String(obj)) ?? "<unrepresentable>"
                throw PythonError.conversionType( value: objStr, sourceType: "SafePythonObject", targetType: "Int64", underlying: error )
            default:
                throw error
            }
        }
    }
    
    // MARK: UInt Conversions
    
    public func convertToPython(uint val: UInt64) async throws -> PythonObject {
        return try await withGIL {
            let ptr = try toPythonIntFromUnsignedLongLong(val, onError: { try throwPythonError() } )
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    internal func convertToSafePython(uint val: UInt64) throws -> SafePythonObject {
        let id = try convertToSafePythonID(uint: val)
        let safeObj = SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: safeObj)
        return safeObj
    }
    
    internal func convertToSafePythonID(uint val: UInt64) throws -> PythonObjectUniqueID {
        let ptr = try toPythonIntFromUnsignedLongLong(val, onError: { try throwSafePythonError() } )
        let id = registerSafePythonObject(ptr)
        return id
    }
    
    public func convertToUInt(_ obj: PythonObject) async throws -> UInt {
        logger.trace("convertToUInt: Convert PythonObject to UInt.")
        
        let uint64Value: UInt64
        do {
            uint64Value = try await convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to UInt.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to UInt.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "UInt")
            default: throw error
            }
        }
        if let uintValue = UInt(exactly: uint64Value) {
            return uintValue
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "PythonObject", targetType: "UInt8")
        }
    }
    
    public func convertToUInt(_ obj: SafePythonObject) throws -> UInt {
        logger.trace("convertToUInt: Convert SafePythonObject to UInt.")
        let uint64Value: UInt64
        do {
            uint64Value = try convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to UInt.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to UInt.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "UInt")
            default: throw error
            }
        }
        if let uintValue = UInt(exactly: uint64Value) {
            return uintValue
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "SafePythonObject", targetType: "UInt")
        }
    }
    
    // MARK: UInt8
    
    public func convertToUInt8(_ obj: PythonObject) async throws -> UInt8 {
        logger.trace("convertToUInt8: Convert PythonObject to UInt8.")
        let uint64Value: UInt64
        do {
            uint64Value = try await convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to UInt8.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt8", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to UInt8.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "UInt8")
            default: throw error
            }
        }
        if let uint8Value = UInt8(exactly: uint64Value) {
            return uint8Value
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "PythonObject", targetType: "UInt8")
        }
    }
    
    public func convertToUInt8(_ obj: SafePythonObject) throws -> UInt8 {
        logger.trace("convertToUInt8: Convert SafePythonObject to UInt8.")
        let uint64Value: UInt64
        do {
            uint64Value = try convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to UInt8.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt8", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to UInt8.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "UInt8")
            default: throw error
            }
        }
        if let uint8Value = UInt8(exactly: uint64Value) {
            return uint8Value
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "SafePythonObject", targetType: "UInt8")
        }
    }
    
    // MARK: UInt16
    
    public func convertToUInt16(_ obj: PythonObject) async throws -> UInt16 {
        logger.trace("convertToUInt8: Convert PythonObject to UInt16.")
        let uint64Value: UInt64
        do {
            uint64Value = try await convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to UInt16.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt16", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to UInt16.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "UInt16")
            default: throw error
            }
        }
        if let uint16Value = UInt16(exactly: uint64Value) {
            return uint16Value
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "PythonObject", targetType: "UInt16")
        }
    }
    
    public func convertToUInt16(_ obj: SafePythonObject) throws -> UInt16 {
        logger.trace("convertToUInt16: Convert PythonObject to UInt16.")
        let uint64Value: UInt64
        do {
            uint64Value = try convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to UInt16.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt16", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to UInt16.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "UInt16")
            default: throw error
            }
        }
        if let uint16Value = UInt16(exactly: uint64Value) {
            return uint16Value
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "SafePythonObject", targetType: "UInt16")
        }
    }
    
    // MARK: UInt32
    
    public func convertToUInt32(_ obj: PythonObject) async throws -> UInt32 {
        logger.trace("convertToUInt32: Convert PythonObject to UInt32.")
        let uint64Value: UInt64
        do {
            uint64Value = try await convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to UInt32.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt32", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to UInt32.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "UInt32")
            default: throw error
            }
        }
        if let uint32Value = UInt32(exactly: uint64Value) {
            return uint32Value
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "PythonObject", targetType: "UInt32")
        }
    }
    
    public func convertToUInt32(_ obj: SafePythonObject) throws -> UInt32 {
        logger.trace("convertToUInt32: Convert SafePythonObject to UInt32.")
        let uint64Value: UInt64
        do {
            uint64Value = try convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, let targetType, let underlying):
                logger.trace("Conversion type error.  Swapping target from \(targetType) to UInt32.")
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt32", underlying: underlying)
            case .conversionOverflow(let value, let sourceType, let targetType):
                logger.trace("Conversion overflow error.  Swapping target from \(targetType) to UInt32.")
                throw PythonError.conversionOverflow(value: value, sourceType: sourceType, targetType: "UInt32")
            default: throw error
            }
        }
        if let uint32Value = UInt32(exactly: uint64Value) {
            return uint32Value
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "SafePythonObject", targetType: "UInt32")
        }
    }
    
    // MARK: UInt64
    
    public func convertToUInt64(_ obj: PythonObject) async throws -> UInt64 {
        logger.trace("convertToUInt64: Convert PythonObject to UInt64.")
        
        // Check for negative number and throw conversion overflow error
        let isNegative: Bool
        do {
            isNegative = try await obj.lessThan(0)
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isNegative {
            logger.error("convertToUInt64: Called for NEGATIVE number PythonObject.")
            let objStr = try await String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "PythonObject", targetType: "UInt64")
        }
        
        // Check for huge number > 2^64 and throw conversion overflow error
        let isHuge: Bool
        do {
            isHuge = try await obj.greaterThan(UInt64.max)
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isHuge {
            logger.error("convertToUInt64: Called for HUGE number PythonObject > \(UInt64.max).")
            let objStr = try await String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "PythonObject", targetType: "UInt64")
        }
        
        let objPtr = getRegisteredPointer(forPythonObject:obj)!
        
        do {
            return try await withGIL {
                return try asUnsignedLongLong(objPtr, onError: { try throwPythonError() } )
            }
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToUInt64(_ obj: SafePythonObject) throws -> UInt64 {
        logger.trace("convertToUInt64: Convert SafePythonObject to UInt64.")
        let isNegative: Bool
        do {
            isNegative = try obj.lessThan(0)
        } catch let error as PythonError {
            switch error {
            case .safePythonException:
                let objStr = (try? String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "SafePythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isNegative {
            logger.error("convertToUInt64: Called for NEGATIVE number SafePythonObject.")
            let objStr = try String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "SafePythonObject", targetType: "UInt64")
        }
        
        // Check for huge number > 2^64 and throw conversion overflow error
        let isHuge: Bool
        do {
            isHuge = try obj.greaterThan(UInt64.max)
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "SafePythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isHuge {
            logger.error("convertToUInt64: Called for HUGE number SafePythonObject > \(UInt64.max).")
            let objStr = try String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "SafePythonObject", targetType: "UInt64")
        }
        
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        do {
            return try asUnsignedLongLong(objPtr, onError: { try throwSafePythonError() } )
        } catch let error as PythonError {
            switch error {
            case .safePythonException:
                let objStr = (try? String(obj)) ?? "<unrepresentable>"
                throw PythonError.conversionType( value: objStr, sourceType: "SafePythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        }
    }
    
    // MARK: String Conversions
    
    public func convertToPython(string: String) async throws -> PythonObject {
        return try await withGIL {
            let ptr = try toPythonUnicodeFromString(string, onError: { try throwPythonError() } )
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    public func convertToString(_ obj: PythonObject) async throws -> String {
        let objPtr = getRegisteredPointer(forPythonObject:obj)!
        
        return try await withGIL {
            do {
                if let pyStr = api.pythonObject_Str(objPtr) {
                    // pythonObject_Str creates an object.  The easiest way to deal with
                    // reference counting is to register it and set it up for normal collection later,
                    // even though it's only temporary.
                    _ = newPythonObject(fromReturnedPointer: pyStr)
                    
                    return try asUTF8String(pyStr, onError: { try throwPythonError() } )
                }
                else {
                    try throwPythonError()
                }
            } catch let error as PythonError {
                throw PythonError.conversionType( value: "<unrepresentable>", sourceType: "PythonObject", targetType: "String", underlying: error )
            }
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToString(_ obj: SafePythonObject) throws -> String {
        do {
            let objPtr = getRegisteredPointer(forSafeObj:obj)
            // Call __string__ so this works on more-or-less any object
            guard let pyStr = api.pythonObject_Str(objPtr) else {
                try throwSafePythonError()
            }
            // pythonObject_Str creates an object.  The easiest way to deal with
            // reference counting is to register it and set it up for normal collection later,
            // even though it's only temporary.
            let id = registerSafePythonObject(pyStr)
            let safeObj = SafePythonObject(interpreter: self, id: id)
            self.incrementHousekeepingRefCount(forSafeObj: safeObj)
            
            // Turn the python string into a Swift string.
            return try asUTF8String(pyStr, onError: { try throwSafePythonError() } )
        } catch let error as PythonError {
            throw PythonError.conversionType( value: "<unrepresentable>", sourceType: "SafePythonObject", targetType: "String", underlying: error )
        }
    }
    
    
    // MARK: Conversions from primitives (synchronous mode)
    // Primitive type conversions in synchronous mode ----------
    
    internal func convertToSafePython(bool: Bool) throws -> SafePythonObject {
        let id = try convertToSafePythonID(bool: bool)
        let safeObj = SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: safeObj)
        return safeObj
    }
    
    internal func convertToSafePythonID(bool: Bool) throws -> PythonObjectUniqueID {
        // PyBool_FromLong never fails.  Unknown error is fine.
        let ptr = try toPythonBoolFromBool(bool, onError: { throw PythonError.unknownPythonException } )
        let id = registerSafePythonObject(ptr)
        return id
    }
    
    internal func convertToSafePython(double: Double) throws -> SafePythonObject {
        let id = try convertToSafePythonID(double: double)
        let safeObj = SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: safeObj)
        return safeObj
    }
    
    internal func convertToSafePythonID(double: Double) throws -> PythonObjectUniqueID {
        logger.trace("CPython API call in synchronous mode: PyFloat_FromDouble")
        guard let ptr = api.PyFloat_FromDouble(double) else {
            throw PythonError.nullPointer("Failed to convert double: \(double)")
        }
        
        let id = registerSafePythonObject(ptr)
        return id
    }
    
    internal func convertToSafePython(string: String) throws -> SafePythonObject {
        let id = try convertToSafePythonID(string: string)
        let safeObj = SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: safeObj)
        return safeObj
    }
    
    internal func convertToSafePythonID(string: String) throws -> PythonObjectUniqueID {
        let ptr = try toPythonUnicodeFromString(string, onError: { try throwSafePythonError() } )
        let id = registerSafePythonObject(ptr)
        return id
    }
    
    
}
