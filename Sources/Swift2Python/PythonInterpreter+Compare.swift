//
//  PythonInterpreter+Compare.swift
//  Swift2Python
//
//  Created by Ben White on 5/10/26.
//


extension PythonInterpreter {
    
    public enum PythonRichCompareOp: CInt {
        case lessThan           = 0     // Py_LT   →  <
        case lessThanOrEqual    = 1     // Py_LE   →  <=
        case equal              = 2     // Py_EQ   →  ==
        case notEqual           = 3     // Py_NE   →  !=
        case greaterThan        = 4     // Py_GT   →  >
        case greaterThanOrEqual = 5     // Py_GE   →  >=
        
        /// The integer value expected by the Python C API.
        public var rawValue: CInt {
            switch self {
            case .lessThan:           return 0
            case .lessThanOrEqual:    return 1
            case .equal:              return 2
            case .notEqual:           return 3
            case .greaterThan:        return 4
            case .greaterThanOrEqual: return 5
            }
        }
    }
    
    // This requires the GIL
    private func richCompareBool(_ lhsPtr: UnsafeMutableRawPointer, _ rhsPtr: UnsafeMutableRawPointer, _ op: PythonRichCompareOp,
                             orElse throwError: () throws -> Never) throws -> Bool {
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompareBool")
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, op.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    
    // This requires the GIL
    private func richCompare(_ lhsPtr: UnsafeMutableRawPointer, _ rhsPtr: UnsafeMutableRawPointer, _ op: PythonRichCompareOp,
                             orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        logger.trace("CPython API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, op.rawValue) else {
            try throwError()
        }
        return resultPtr
    }
    
    // MARK: Comparion Support (async mode)
    
    public func equal(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Equal comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            try richCompareBool(lhsPtr, rhsPtr, .equal, orElse: { try throwPythonError() } )
        }
    }
    
    public func notEqual(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Not equal comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            try richCompareBool(lhsPtr, rhsPtr, .notEqual, orElse: { try throwPythonError() } )
        }
    }
    
    public func lessThan(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Less than comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            try richCompareBool(lhsPtr, rhsPtr, .lessThan, orElse: { try throwPythonError() } )
        }
    }
    
    public func lessThanOrEqual(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Less than or equal comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            try richCompareBool(lhsPtr, rhsPtr, .lessThanOrEqual, orElse: { try throwPythonError() } )
        }
    }
    public func greaterThan(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Greater than comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            try richCompareBool(lhsPtr, rhsPtr, .greaterThan, orElse: { try throwPythonError() } )
        }
    }
    
    public func greaterThanOrEqual(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Greater than or equal comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            try richCompareBool(lhsPtr, rhsPtr, .greaterThanOrEqual, orElse: { try throwPythonError() } )
        }
    }
    
    
    
    // MARK: Equal Operator
    
    internal func syncEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        let resultPtr = try richCompare(lhsPtr, rhsPtr, .equal, orElse: { try throwSafePythonError() } )
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncEqualEquatable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        return try richCompareBool(lhsPtr, rhsPtr, .equal, orElse: { try throwSafePythonError() } )
    }
    
    // MARK: Not Equal Operator
    
    internal func syncNotEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        let resultPtr = try richCompare(lhsPtr, rhsPtr, .notEqual, orElse: { try throwSafePythonError() } )
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncNotEqualEquatable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        return try richCompareBool(lhsPtr, rhsPtr, .notEqual, orElse: { try throwSafePythonError() } )
    }
    
    // MARK: Greater than
    
    internal func syncGreaterThan(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        let resultPtr = try richCompare(lhsPtr, rhsPtr, .greaterThan, orElse: { try throwSafePythonError() } )
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncGreaterThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        return try richCompareBool(lhsPtr, rhsPtr, .greaterThan, orElse: { try throwSafePythonError() } )
    }
    
    // MARK: Greater than or equal
    
    internal func syncGreaterThanOrEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        let resultPtr = try richCompare(lhsPtr, rhsPtr, .greaterThanOrEqual, orElse: { try throwSafePythonError() } )
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncGreaterThanOrEqualComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        return try richCompareBool(lhsPtr, rhsPtr, .greaterThanOrEqual, orElse: { try throwSafePythonError() } )
    }
    
    // MARK: Less than
    
    internal func syncLessThan(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        let resultPtr = try richCompare(lhsPtr, rhsPtr, .lessThan, orElse: { try throwSafePythonError() } )
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncLessThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        return try richCompareBool(lhsPtr, rhsPtr, .lessThan, orElse: { try throwSafePythonError() } )
    }
    
    // MARK: Less than or equal
    
    internal func syncLessThanOrEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        
        let resultPtr = try richCompare(lhsPtr, rhsPtr, .lessThanOrEqual, orElse: { try throwSafePythonError() } )
        
        let resultId = registerSafePythonObject(resultPtr)
        let resultObj = SafePythonObject(interpreter: self, id: resultId)
        self.incrementHousekeepingRefCount(forSafeObj: resultObj)
        return resultObj
    }
    
    internal func syncLessThanOrEqualComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPointer(forSafeObj:lhs)
        let rhsPtr = getRegisteredPointer(forSafeObj:rhs)
        return try richCompareBool(lhsPtr, rhsPtr, .lessThanOrEqual, orElse: { try throwSafePythonError() } )
    }
    
}
