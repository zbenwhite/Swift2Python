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
    
    private typealias PyObjectGetBuffer = @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer, Int32) -> Int32
    private typealias PyBufferRelease = @convention(c) (UnsafeMutableRawPointer) -> Void
    
    private func requireBufferProtocolSymbols() throws -> (getBuffer: PyObjectGetBuffer, release: PyBufferRelease) {
        guard let getBuffer = api.PyObject_GetBuffer,
              let release = api.PyBuffer_Release
        else {
            throw PythonError.unsupportedPythonFeature(
                feature: "Python buffer protocol access",
                requiredSymbols: ["PyObject_GetBuffer", "PyBuffer_Release"]
            )
        }
        return (getBuffer, release)
    }
    
    private func bufferProtocolSymbols() -> (getBuffer: PyObjectGetBuffer, release: PyBufferRelease)? {
        guard let getBuffer = api.PyObject_GetBuffer,
              let release = api.PyBuffer_Release
        else {
            return nil
        }
        return (getBuffer, release)
    }
    
    // This requires the GIL
    private func isBytesLike(_ objPtr: UnsafeMutableRawPointer) throws -> Bool {
        if let bufferAPI = bufferProtocolSymbols() {
            var view = Py_buffer()
            guard bufferAPI.getBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
                try api.pythonErr_Clear()
                return false
            }
            bufferAPI.release(&view)
            return true
        }
        
        return try isBytesLikeUsingMemoryView(objPtr)
    }
    
    // This requires the GIL
    private func callPythonObject(_ callable: UnsafeMutableRawPointer, withSingleArgument argument: UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer? {
        guard let args = api.PyTuple_New(1) else {
            try api.pythonErr_Clear()
            throw PythonError.allocationFailed("Could not allocate single-argument tuple")
        }
        defer { api.Py_DecRef(args) }
        
        api.Py_IncRef(argument)
        if api.PyTuple_SetItem(args, 0, argument) != 0 {
            api.Py_DecRef(argument)
            try api.pythonErr_Clear()
            throw PythonError.allocationFailed("Could not set single-argument tuple item")
        }
        
        return api.PyObject_Call(callable, args, nil)
    }
    
    // This requires the GIL
    private func newMemoryView(from objPtr: UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer? {
        guard let builtins = api.pythonImport_ImportModule("builtins") else {
            try api.pythonErr_Clear()
            throw PythonError.symbolNotFound("builtins")
        }
        defer { api.Py_DecRef(builtins) }
        
        guard let memoryView = api.pythonObject_GetAttrString(builtins, "memoryview") else {
            try api.pythonErr_Clear()
            return nil
        }
        defer { api.Py_DecRef(memoryView) }
        
        guard let view = try callPythonObject(memoryView, withSingleArgument: objPtr) else {
            try api.pythonErr_Clear()
            return nil
        }
        return view
    }
    
    // This requires the GIL
    internal func isBytesLikeUsingMemoryView(_ objPtr: UnsafeMutableRawPointer) throws -> Bool {
        guard let view = try newMemoryView(from: objPtr) else {
            return false
        }
        api.Py_DecRef(view)
        return true
    }
    
    // This requires the GIL
    private func copiedBytes(from objPtr: UnsafeMutableRawPointer) throws -> [UInt8] {
        if let bufferAPI = bufferProtocolSymbols() {
            return try copiedBytesUsingBufferProtocol(objPtr, bufferAPI: bufferAPI)
        }
        
        return try copiedBytesUsingMemoryView(objPtr)
    }
    
    // This requires the GIL
    private func copiedBytesUsingBufferProtocol(
        _ objPtr: UnsafeMutableRawPointer,
        bufferAPI: (getBuffer: PyObjectGetBuffer, release: PyBufferRelease)
    ) throws -> [UInt8] {
        var view = Py_buffer()
        
        guard bufferAPI.getBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
            try api.pythonErr_Clear()
            throw PythonError.bytesConversionFailed(expected: "bytes-like object", actual: nil)
        }
        defer { bufferAPI.release(&view) }
        
        guard view.len >= 0 else {
            throw PythonError.bytesConversionFailed(expected: "non-negative buffer length", actual: nil)
        }
        guard view.len > 0 else {
            return []
        }
        guard let base = view.buf else {
            throw PythonError.nullPointer("Buffer pointer is null")
        }
        
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: ptr, count: view.len)
        return Array(buffer)
    }
    
    // This requires the GIL
    internal func copiedBytesUsingMemoryView(_ objPtr: UnsafeMutableRawPointer) throws -> [UInt8] {
        guard let view = try newMemoryView(from: objPtr) else {
            throw PythonError.bytesConversionFailed(expected: "bytes-like object", actual: nil)
        }
        defer { api.Py_DecRef(view) }
        
        guard let toBytes = api.pythonObject_GetAttrString(view, "tobytes") else {
            try api.pythonErr_Clear()
            throw PythonError.bytesConversionFailed(expected: "memoryview.tobytes", actual: nil)
        }
        defer { api.Py_DecRef(toBytes) }
        
        let pythonBytes: UnsafeMutableRawPointer?
        if let callNoArgs = api.PyObject_CallNoArgs {
            pythonBytes = callNoArgs(toBytes)
        } else {
            pythonBytes = api.pythonObject_CallObject(toBytes)
        }
        guard let pythonBytes else {
            try api.pythonErr_Clear()
            throw PythonError.bytesConversionFailed(expected: "memoryview bytes", actual: nil)
        }
        defer { api.Py_DecRef(pythonBytes) }
        
        return try copiedBytesFromExactPythonBytes(pythonBytes)
    }
    
    // This requires the GIL
    private func copiedBytesFromExactPythonBytes(_ bytesPtr: UnsafeMutableRawPointer) throws -> [UInt8] {
        var bytePointer: UnsafeMutablePointer<CChar>?
        var length: Py_ssize_t = 0
        
        guard api.pythonBytes_AsStringAndSize(bytesPtr, &bytePointer, &length) == 0 else {
            try api.pythonErr_Clear()
            throw PythonError.bytesConversionFailed(expected: "bytes", actual: nil)
        }
        
        guard length >= 0 else {
            throw PythonError.bytesConversionFailed(expected: "non-negative bytes length", actual: nil)
        }
        guard length > 0 else {
            return []
        }
        guard let bytePointer else {
            throw PythonError.nullPointer("Bytes pointer is null")
        }
        
        let count = Int(length)
        let ptr = UnsafeRawPointer(bytePointer).assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: ptr, count: count)
        return Array(buffer)
    }
    
    // MARK: Synchronous bytes
    
    /// Creates a safe Python `bytes` object by copying Swift bytes.
    ///
    /// Use this explicit API when `[UInt8]` represents binary data and should become
    /// Python `bytes` instead of a Python list. Only call this method inside
    /// `withIsolatedContext`.
    ///
    /// - Parameter bytes: The Swift bytes to copy into the new Python `bytes` object.
    /// - Returns: A safe Python object representing immutable Python `bytes`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(bytes: [UInt8]) throws -> SafePythonObject {
        let bytesPtr = try newPythonBytes(from: bytes, orElse: { try throwSafePythonError() })
        return newSafePythonObject(fromReturnedPointer: bytesPtr)
    }
    
    /// Creates a safe Python `bytes` object by copying Swift `Data`.
    ///
    /// Only call this method inside `withIsolatedContext`.
    ///
    /// - Parameter bytes: The Swift data to copy into the new Python `bytes` object.
    /// - Returns: A safe Python object representing immutable Python `bytes`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(bytes: Data) throws -> SafePythonObject {
        let bytesPtr = try newPythonBytes(from: bytes, orElse: { try throwSafePythonError() })
        return newSafePythonObject(fromReturnedPointer: bytesPtr)
    }
    
    /// Creates a safe Python `bytearray` object by copying Swift bytes.
    ///
    /// Use this explicit API when `[UInt8]` represents mutable binary data and should
    /// become Python `bytearray` instead of a Python list. Only call this method inside
    /// `withIsolatedContext`.
    ///
    /// - Parameter byteArray: The Swift bytes to copy into the new Python `bytearray` object.
    /// - Returns: A safe Python object representing mutable Python `bytearray`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func convertToSafePython(byteArray: [UInt8]) throws -> SafePythonObject {
        let byteArrayPtr = try newPythonByteArray(from: byteArray, orElse: { try throwSafePythonError() })
        return newSafePythonObject(fromReturnedPointer: byteArrayPtr)
    }
    
    /// Creates a safe Python `bytearray` object by copying Swift `Data`.
    ///
    /// Only call this method inside `withIsolatedContext`.
    ///
    /// - Parameter byteArray: The Swift data to copy into the new Python `bytearray` object.
    /// - Returns: A safe Python object representing mutable Python `bytearray`.
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
    internal func copiedBytes(_ obj: SafePythonObject) throws -> [UInt8] {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try copiedBytes(from: objPtr)
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
        let bufferAPI = try requireBufferProtocolSymbols()
        
        var view = Py_buffer()
        
        guard bufferAPI.getBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
            try api.pythonErr_Clear()
            throw PythonError.bytesConversionFailed(expected: "bytes-like object", actual: nil)
        }
        defer {
            bufferAPI.release(&view)
        }
        
        guard let base = view.buf else {
            throw PythonError.nullPointer("Buffer pointer is null")
        }
        
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: ptr, count: Int(view.len))
        
        return try body(buffer)
    }
    
    
    // MARK: Asynchronous bytes
    
    /// Creates a Python `bytes` object by copying Swift bytes.
    ///
    /// Use this explicit API when `[UInt8]` represents binary data and should become
    /// Python `bytes` instead of a Python list.
    ///
    /// - Parameter bytes: The Swift bytes to copy into the new Python `bytes` object.
    /// - Returns: A Python object representing immutable Python `bytes`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    public func convertToPython(bytes: [UInt8]) async throws -> PythonObject {
        let bytesPtr = try await withGIL {
            try newPythonBytes(from: bytes, orElse: { try throwPythonError() })
        }
        return newPythonObject(fromReturnedPointer: bytesPtr)
    }
    
    /// Creates a Python `bytes` object by copying Swift `Data`.
    ///
    /// - Parameter bytes: The Swift data to copy into the new Python `bytes` object.
    /// - Returns: A Python object representing immutable Python `bytes`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    public func convertToPython(bytes: Data) async throws -> PythonObject {
        let bytesPtr = try await withGIL {
            try newPythonBytes(from: bytes, orElse: { try throwPythonError() })
        }
        return newPythonObject(fromReturnedPointer: bytesPtr)
    }
    
    /// Creates a Python `bytearray` object by copying Swift bytes.
    ///
    /// Use this explicit API when `[UInt8]` represents mutable binary data and should
    /// become Python `bytearray` instead of a Python list.
    ///
    /// - Parameter byteArray: The Swift bytes to copy into the new Python `bytearray` object.
    /// - Returns: A Python object representing mutable Python `bytearray`.
    /// - Throws: `PythonError` if Python cannot allocate the object.
    public func convertToPython(byteArray: [UInt8]) async throws -> PythonObject {
        let byteArrayPtr = try await withGIL {
            try newPythonByteArray(from: byteArray, orElse: { try throwPythonError() })
        }
        return newPythonObject(fromReturnedPointer: byteArrayPtr)
    }
    
    /// Creates a Python `bytearray` object by copying Swift `Data`.
    ///
    /// - Parameter byteArray: The Swift data to copy into the new Python `bytearray` object.
    /// - Returns: A Python object representing mutable Python `bytearray`.
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
    
    internal func copiedBytes(_ obj: PythonObject) async throws -> [UInt8] {
        let objPtr = getRegisteredPointer(forPythonObject: obj)!
        return try await withGIL { try copiedBytes(from: objPtr) }
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
    
    /// Provides temporary zero-copy access to a Python object's readable buffer.
    ///
    /// The buffer pointer is valid only for the duration of `body`. This API requires
    /// the loaded libpython to export `PyObject_GetBuffer` and `PyBuffer_Release`; use
    /// `PythonObject.asCopiedData()` or `PythonObject.asCopiedBytes()` when a copied
    /// Python 3.9-compatible extraction is sufficient.
    ///
    /// - Parameters:
    ///   - obj: The Python object that must support the readable buffer protocol.
    ///   - body: A closure that receives the temporary readable byte buffer.
    /// - Returns: The value returned by `body`.
    /// - Throws: `PythonError.bytesConversionFailed` if `obj` is not bytes-like,
    ///   or `PythonError.unsupportedPythonFeature` if direct buffer symbols are missing.
    public func withUnsafeBytes<R>(_ obj: PythonObject, body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) async throws -> R {
        try await withGIL {
            let objPtr = getRegisteredPointer(forPythonObject: obj)!
            let bufferAPI = try requireBufferProtocolSymbols()
            
            var view = Py_buffer()
            
            guard bufferAPI.getBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
                try api.pythonErr_Clear()
                throw PythonError.bytesConversionFailed(expected: "bytes-like object", actual: nil)
            }
            defer {
                bufferAPI.release(&view)
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
