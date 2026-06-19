//
//  PythonInterpreter+Bytes.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//

import Foundation

public let PyBUF_SIMPLE: Int32 = 0
public let PyBUF_WRITABLE: Int32 = 1 << 0
public let PyBUF_FORMAT: Int32 = 1 << 1
public let PyBUF_ND: Int32 = 1 << 2
public let PyBUF_STRIDES: Int32 = 1 << 3
public let PyBUF_C_CONTIGUOUS: Int32 = 1 << 4

public struct Py_buffer {
    public var buf: UnsafeMutableRawPointer?
    public var obj: UnsafeMutableRawPointer?
    public var len: Int
    public var itemsize: Int
    public var readonly: Int32
    public var ndim: Int32
    public var format: UnsafeMutablePointer<CChar>?
    public var shape: UnsafeMutablePointer<Int>?
    public var strides: UnsafeMutablePointer<Int>?
    public var suboffsets: UnsafeMutablePointer<Int>?
    public var `internal`: UnsafeMutableRawPointer?
    
    public init() {
        self.buf = nil
        self.obj = nil
        self.len = 0
        self.itemsize = 0
        self.readonly = 0
        self.ndim = 0
        self.format = nil
        self.shape = nil
        self.strides = nil
        self.suboffsets = nil
        self.internal = nil
    }
}

extension PythonInterpreter {
    
    // MARK: Python API Helpers
    
    private func withUnsafeCStringPointer<R>(for bytes: [UInt8], _ body: (UnsafePointer<CChar>?) throws -> R) rethrows -> R {
        try bytes.withUnsafeBufferPointer { buffer in
            let pointer = buffer.baseAddress.map { UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self) }
            return try body(pointer)
        }
    }
    
    private func withUnsafeCStringPointer<R>(for data: Data, _ body: (UnsafePointer<CChar>?) throws -> R) rethrows -> R {
        try data.withUnsafeBytes { buffer in
            let pointer = buffer.baseAddress.map { $0.assumingMemoryBound(to: CChar.self) }
            return try body(pointer)
        }
    }
    
    // This requires the GIL
    private func newPythonBytes(from bytes: [UInt8], orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try withUnsafeCStringPointer(for: bytes) { pointer in
            try api.pythonBytes_FromStringAndSize(pointer, bytes.count) ?? {
                try throwError()
            } ()
        }
    }
    
    // This requires the GIL
    private func newPythonBytes(from data: Data, orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try withUnsafeCStringPointer(for: data) { pointer in
            try api.pythonBytes_FromStringAndSize(pointer, data.count) ?? {
                try throwError()
            } ()
        }
    }
    
    // This requires the GIL
    private func newPythonByteArray(from bytes: [UInt8], orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try withUnsafeCStringPointer(for: bytes) { pointer in
            try api.pythonByteArray_FromStringAndSize(pointer, bytes.count) ?? {
                try throwError()
            } ()
        }
    }
    
    // This requires the GIL
    private func newPythonByteArray(from data: Data, orElse throwError: () throws -> Never) throws -> UnsafeMutableRawPointer {
        try withUnsafeCStringPointer(for: data) { pointer in
            try api.pythonByteArray_FromStringAndSize(pointer, data.count) ?? {
                try throwError()
            } ()
        }
    }
    
    // This requires the GIL
    private func isBytes(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws -> Bool {
        switch api.pythonObject_IsInstance(objPtr, api.PyBytes_Type) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    // This requires the GIL
    private func isByteArray(_ objPtr: UnsafeMutableRawPointer, onError throwError: () throws -> Never) throws -> Bool {
        switch api.pythonObject_IsInstance(objPtr, api.PyByteArray_Type) {
        case 0: return false
        case 1: return true
        default: try throwError()
        }
    }
    
    // This requires the GIL
    private func isBytesLike(_ objPtr: UnsafeMutableRawPointer) throws -> Bool {
        var view = Py_buffer()
        guard api.PyObject_GetBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
            try api.pythonErr_Clear()
            return false
        }
        api.PyBuffer_Release(&view)
        return true
    }
    
    // MARK: Synchronous bytes
    
    /// Create a safe Python `bytes` object from Swift bytes.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment.
    ///
    /// - Parameter bytes: The Swift bytes to copy into a Python `bytes` object.
    /// - Returns: A `SafePythonObject` representing Python `bytes`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(bytes: [UInt8]) throws -> SafePythonObject {
        let bytesPtr = try newPythonBytes(from: bytes, orElse: { try throwSafePythonError() })
        return newSafePythonObject(fromReturnedPointer: bytesPtr)
    }
    
    /// Create a safe Python `bytes` object from Swift `Data`.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment.
    ///
    /// - Parameter bytes: The Swift data to copy into a Python `bytes` object.
    /// - Returns: A `SafePythonObject` representing Python `bytes`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(bytes: Data) throws -> SafePythonObject {
        let bytesPtr = try newPythonBytes(from: bytes, orElse: { try throwSafePythonError() })
        return newSafePythonObject(fromReturnedPointer: bytesPtr)
    }
    
    /// Create a safe Python `bytearray` object from Swift bytes.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment.
    ///
    /// - Parameter byteArray: The Swift bytes to copy into a Python `bytearray` object.
    /// - Returns: A `SafePythonObject` representing Python `bytearray`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(byteArray: [UInt8]) throws -> SafePythonObject {
        let byteArrayPtr = try newPythonByteArray(from: byteArray, orElse: { try throwSafePythonError() })
        return newSafePythonObject(fromReturnedPointer: byteArrayPtr)
    }
    
    /// Create a safe Python `bytearray` object from Swift `Data`.
    ///
    /// Only for use inside the synchronous, GIL-managed, reference-managed local
    /// `withIsolatedContext` environment.
    ///
    /// - Parameter byteArray: The Swift data to copy into a Python `bytearray` object.
    /// - Returns: A `SafePythonObject` representing Python `bytearray`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(byteArray: Data) throws -> SafePythonObject {
        let byteArrayPtr = try newPythonByteArray(from: byteArray, orElse: { try throwSafePythonError() })
        return newSafePythonObject(fromReturnedPointer: byteArrayPtr)
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func isBytes(_ obj: SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isBytes(objPtr, onError: { try throwSafePythonError() })
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func isByteArray(_ obj: SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isByteArray(objPtr, onError: { try throwSafePythonError() })
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func isBytesLike(_ obj: SafePythonObject) throws -> Bool {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try isBytesLike(objPtr)
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func bytesObjectSize(_ obj: SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        guard try isBytes(objPtr, onError: { try throwSafePythonError() }) else {
            throw PythonError.bytesConversionFailed(expected: "bytes", actual: nil)
        }
        return api.pythonBytes_Size(objPtr)
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func byteArrayObjectSize(_ obj: SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        guard try isByteArray(objPtr, onError: { try throwSafePythonError() }) else {
            throw PythonError.bytesConversionFailed(expected: "bytearray", actual: nil)
        }
        return api.pythonByteArray_Size(objPtr)
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func withUnsafeBytes<R>(_ obj: SafePythonObject, body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) throws -> R {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        
        var view = Py_buffer()
        
        guard api.PyObject_GetBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
            try api.pythonErr_Clear()
            throw PythonError.bytesConversionFailed(expected: "bytes-like object", actual: nil)
        }
        defer {
            api.PyBuffer_Release(&view)
        }
        
        guard let base = view.buf else {
            throw PythonError.nullPointer("Buffer pointer is null")
        }
        
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: ptr, count: Int(view.len))
        
        return try body(buffer)
    }
    
    
    // MARK: Asynchronous bytes
    
    /// Create a Python `bytes` object from Swift bytes.
    ///
    /// Use this explicit API when `[UInt8]` should become binary `bytes` instead of
    /// a Python list.
    ///
    /// - Parameter bytes: The Swift bytes to copy into a Python `bytes` object.
    /// - Returns: A `PythonObject` representing Python `bytes`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    public func convertToPython(bytes: [UInt8]) async throws -> PythonObject {
        let bytesPtr = try await withGIL {
            try newPythonBytes(from: bytes, orElse: { try throwPythonError() })
        }
        return newPythonObject(fromReturnedPointer: bytesPtr)
    }
    
    /// Create a Python `bytes` object from Swift `Data`.
    ///
    /// - Parameter bytes: The Swift data to copy into a Python `bytes` object.
    /// - Returns: A `PythonObject` representing Python `bytes`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    public func convertToPython(bytes: Data) async throws -> PythonObject {
        let bytesPtr = try await withGIL {
            try newPythonBytes(from: bytes, orElse: { try throwPythonError() })
        }
        return newPythonObject(fromReturnedPointer: bytesPtr)
    }
    
    /// Create a Python `bytearray` object from Swift bytes.
    ///
    /// Use this explicit API when `[UInt8]` should become mutable binary data instead
    /// of a Python list.
    ///
    /// - Parameter byteArray: The Swift bytes to copy into a Python `bytearray` object.
    /// - Returns: A `PythonObject` representing Python `bytearray`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    public func convertToPython(byteArray: [UInt8]) async throws -> PythonObject {
        let byteArrayPtr = try await withGIL {
            try newPythonByteArray(from: byteArray, orElse: { try throwPythonError() })
        }
        return newPythonObject(fromReturnedPointer: byteArrayPtr)
    }
    
    /// Create a Python `bytearray` object from Swift `Data`.
    ///
    /// - Parameter byteArray: The Swift data to copy into a Python `bytearray` object.
    /// - Returns: A `PythonObject` representing Python `bytearray`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    public func convertToPython(byteArray: Data) async throws -> PythonObject {
        let byteArrayPtr = try await withGIL {
            try newPythonByteArray(from: byteArray, orElse: { try throwPythonError() })
        }
        return newPythonObject(fromReturnedPointer: byteArrayPtr)
    }
    
    internal func isBytes(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isBytes(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func isByteArray(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isByteArray(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func isBytesLike(_ obj: PythonObject) async throws -> Bool {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try isBytesLike(objPtr) }
    }
    
    internal func bytesObjectSize(_ obj: PythonObject) async throws -> Int {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            guard try isBytes(objPtr, onError: { try throwPythonError() }) else {
                throw PythonError.bytesConversionFailed(expected: "bytes", actual: nil)
            }
            return Int(api.pythonBytes_Size(objPtr))
        }
    }
    
    internal func byteArrayObjectSize(_ obj: PythonObject) async throws -> Int {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL {
            guard try isByteArray(objPtr, onError: { try throwPythonError() }) else {
                throw PythonError.bytesConversionFailed(expected: "bytearray", actual: nil)
            }
            return api.pythonByteArray_Size(objPtr)
        }
    }
    
    // REMOVED DUPLICATE async withUnsafeBytes that manually handled bytes and bytearray here
    
    public func withUnsafeBytes<R>(_ obj: PythonObject, body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) async throws -> R {
        try await withGIL {
            let objPtr = getRegisteredPointer(forPythonObject: obj)!
            
            var view = Py_buffer()
            
            guard api.PyObject_GetBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
                try api.pythonErr_Clear()
                throw PythonError.bytesConversionFailed(expected: "bytes-like object", actual: nil)
            }
            defer {
                api.PyBuffer_Release(&view)
            }
            
            guard let base = view.buf else {
                throw PythonError.nullPointer("Buffer pointer is null")
            }
            
            let ptr = base.assumingMemoryBound(to: UInt8.self)
            let buffer = UnsafeBufferPointer(start: ptr, count: Int(view.len))
            
            return try body(buffer)
        }
    }
}
