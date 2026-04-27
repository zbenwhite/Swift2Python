//
//  PythonInterpreter+Convert.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

import Foundation


extension PythonInterpreter {
    
    
    
    // MARK: Conversion of primative types (async mode)
    
    public func convertToPython(bool: Bool) async throws -> PythonObject {
        return try withGIL {
            guard let ptr = api.pythonBool_FromLong(bool) else {
                throw PythonError.nullPointer("Failed to convert bool: \(bool)")
            }
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    public func convertToBool(_ obj: PythonObject) async throws -> Bool {
        //let objPtr = getRegisteredPointer(forPythonObject:obj)!
        fatalError("placeholder")
    }
    
    public func convertToPython(double: Double) async throws -> PythonObject {
        return try withGIL {
            guard let ptr =  try api.pythonFloat_FromDouble(double) else {
                throw PythonError.nullPointer("Failed to convert double: \(double)")
            }
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    public func convertToDouble(_ obj: PythonObject) async throws -> Double {
        let objPtr = getRegisteredPointer(forPythonObject:obj)!
        return try await withGIL {
            let value = api.pythonFloat_AsDouble(objPtr)
            if value == -1.0 {
                if let _ = try api.pythonErr_Occurred() {
                    try await throwPythonError()
                }
            }
            return Double(exactly: value)!
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToDouble(_ obj: SafePythonObject) throws -> Double {
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        let value = api.pythonFloat_AsDouble(objPtr)
        if value == -1.0 {
            if let _ = try api.pythonErr_Occurred() {
                try throwPythonError()
            }
        }
        return Double(exactly: value)!
    }
    
    // MARK: Int Conversions
    
    public func convertToPython(int val: Int64) async throws -> PythonObject {
        logger.trace("convertToPython: Convert Int64 to PythonObject.")
        return try withGIL {
            guard let ptr = api.pythonLong_FromLongLong(val) else {
                throw PythonError.nullPointer("Failed to convert int: \(val)")
            }
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
        guard let ptr = api.pythonLong_FromLongLong(val) else {
            throw PythonError.nullPointer("Failed to convert int: \(val)")
        }
        
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
                let value = try api.pythonLong_AsLongLong(objPtr)
                if value == -1 {
                    if let _ = try api.pythonErr_Occurred() {
                        try await throwPythonError()
                    }
                }
                return value
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
        let value = try api.pythonLong_AsLongLong(objPtr)
        if value == -1 {
            if let _ = try api.pythonErr_Occurred() {
                do {
                    try throwPythonError()
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
            }
        }
        return value
    }
    
    // MARK: UInt Conversions
    
    public func convertToPython(uint val: UInt64) async throws -> PythonObject {
        return try withGIL {
            guard let ptr = try api.pythonLong_FromUnsignedLongLong(UInt64(val)) else {
                throw PythonError.nullPointer("Failed to convert int: \(val)")
            }
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
        guard let ptr = try api.pythonLong_FromUnsignedLongLong(val) else {
            throw PythonError.nullPointer("Failed to convert int: \(val)")
        }
        
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
                let value = try api.pythonLong_AsUnsignedLongLong(objPtr)
                if value == UInt64.max {              // (unsigned long long)-1 on error
                    if let _ = try api.pythonErr_Occurred() {
                        try await throwPythonError()
                    }
                }
                return value
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
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "UInt64", underlying: error )
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
        let value = try api.pythonLong_AsUnsignedLongLong(objPtr)
        if value == UInt64.max {              // (unsigned long long)-1 on error
            if let _ = try api.pythonErr_Occurred() {
                do {
                    try throwPythonError()
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
            }
        }
        return value
    }
    
    // MARK: String Conversions
    
    public func convertToPython(string: String) async throws -> PythonObject {
        return try withGIL {
            guard let ptr = try api.pythonUnicode_FromStringAndSize(string) else {
                throw PythonError.nullPointer("Failed to convert string: \(string)")
            }
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    public func convertToString(_ obj: PythonObject) async throws -> String {
        let objPtr = getRegisteredPointer(forPythonObject:obj)!
        
        return try withGIL {
            if let pyStr = api.pythonObject_Str(objPtr) {
                // FIXME: New object is created.  It needs to disappear.
                // defer { Py_DECREF(pyStr) }
                if let s = try api.pythonUnicode_AsUTF8AndSize(pyStr) {
                    return s
                } else {
                    try throwPythonError()
                }
            }
            else {
                try throwPythonError()
            }
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToString(_ obj: SafePythonObject) throws -> String {
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        
        guard let pyStr = api.pythonObject_Str(objPtr) else {
            try throwPythonError()
        }
        // FIXME: New object is created.  It needs to disappear.
        // defer { Py_DECREF(pyStr) }
        if let s = try api.pythonUnicode_AsUTF8AndSize(pyStr) {
            return s
        } else {
            try throwPythonError()
        }
    }
    
    public func convertToPython(array: [PendingPythonConvertible]) async throws -> PythonObject {
        return try await withGIL {
            guard let listPtr = try api.pythonList_New(array.count)  else {
                throw PythonError.nullPointer("Failed to convert list: \(array)")
            }
            for (index, element) in array.enumerated() {
                let valuePythonObject = try await element.toPythonObject(interpreter: self)
                let valuePtr = getRegisteredPointer(forPythonObject:valuePythonObject)
                _ = try api.pythonList_SetItem(listPtr, index, valuePtr!)
            }
            return newPythonObject(fromReturnedPointer: listPtr)
        }
    }
    
    public func convertToPython<K, V>(dictionary: [K: V]) async throws -> PythonObject
            where K: PendingPythonConvertible & Hashable, V: PendingPythonConvertible {
        return try await withGIL {
            guard let dictPtr = try api.pythonDict_New()  else {
                throw PythonError.nullPointer("Failed to convert dictionary")
            }
            
            for (key, value) in dictionary {
                let keyObj = try await key.toPythonObject(interpreter: self)
                let valueObj = try await value.toPythonObject(interpreter: self)
                let keyPtr = getRegisteredPointer(forPythonObject:keyObj)!
                let valuePtr = getRegisteredPointer(forPythonObject:valueObj)!
                _ = try api.pythonDict_SetItem(dictPtr, keyPtr, valuePtr)
            }
            return newPythonObject(fromReturnedPointer: dictPtr)
        }
    }
    
    
    // MARK: Conversions from primitives (synchronous mode)
    // Primitive type conversions in synchronous mode ----------
    
    internal func convertToSafePython(bool val: Bool) throws -> SafePythonObject {
        let id = try convertToSafePythonID(bool: val)
        let safeObj = SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: safeObj)
        return safeObj
    }
    
    internal func convertToSafePythonID(bool: Bool) throws -> PythonObjectUniqueID {
        guard let ptr = api.pythonBool_FromLong(((bool ? 1 : 0) != 0)) else {
            throw PythonError.nullPointer("Failed to convert bool: \(bool)")
        }
        
        let id = registerSafePythonObject(ptr)
        return id
    }
    
    internal func convertToSafePython(double val: Double) throws -> SafePythonObject {
        let id = try convertToSafePythonID(double: val)
        let safeObj = SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: safeObj)
        return safeObj
    }
    
    internal func convertToSafePythonID(double val: Double) throws -> PythonObjectUniqueID {
        logger.trace("CPython API call in synchronous mode: PyFloat_FromDouble")
        guard let ptr = api.PyFloat_FromDouble(val) else {
            throw PythonError.nullPointer("Failed to convert double: \(val)")
        }
        
        let id = registerSafePythonObject(ptr)
        return id
    }
    
    internal func convertToSafePython(string val: String) throws -> SafePythonObject {
        let id = try convertToSafePythonID(string: val)
        let safeObj = SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: safeObj)
        return safeObj
    }
    
    internal func convertToSafePythonID(string val: String) throws -> PythonObjectUniqueID {
        guard let ptr = try api.pythonUnicode_FromStringAndSize(val) else {
            throw PythonError.nullPointer("Failed to convert string: \(val)")
        }
        let id = registerSafePythonObject(ptr)
        return id
    }
    
    
}
