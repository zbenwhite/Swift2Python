//
//  PythonInterpreter+Bytes.swift
//  Swift2Python
//
//  Created by Ben White on 4/17/26.
//


public let PyBUF_SIMPLE      = Int32(0)
public let PyBUF_WRITABLE    = Int32(1 << 0)
public let PyBUF_FORMAT      = Int32(1 << 1)
public let PyBUF_ND          = Int32(1 << 2)
public let PyBUF_STRIDES     = Int32(1 << 3)
public let PyBUF_C_CONTIGUOUS = Int32(1 << 4)

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
    internal func isBytesArray(_ obj: SafePythonObject) throws -> Bool {
        try isByteArray(obj)
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
    
    internal func isBytes(_ obj: PythonObject) async throws -> Bool {
        guard let objPtr = getRegisteredPointer(forPythonObject: obj) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try await withGIL { try isBytes(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func isByteArray(_ obj: PythonObject) async throws -> Bool {
        guard let objPtr = getRegisteredPointer(forPythonObject: obj) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try await withGIL { try isByteArray(objPtr, onError: { try throwPythonError() }) }
    }
    
    internal func isBytesArray(_ obj: PythonObject) async throws -> Bool {
        try await isByteArray(obj)
    }
    
    internal func isBytesLike(_ obj: PythonObject) async throws -> Bool {
        guard let objPtr = getRegisteredPointer(forPythonObject: obj) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try await withGIL { try isBytesLike(objPtr) }
    }
    
    public func bytesObjectSize(_ obj: PythonObject) async throws -> Int {
        guard let objPtr = getRegisteredPointer(forPythonObject: obj) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try await withGIL {
            guard try isBytes(objPtr, onError: { try throwPythonError() }) else {
                throw PythonError.bytesConversionFailed(expected: "bytes", actual: nil)
            }
            return Int(api.pythonBytes_Size(objPtr))
        }
    }
    
    public func byteArrayObjectSize(_ obj: PythonObject) async throws -> Int {
        guard let objPtr = getRegisteredPointer(forPythonObject: obj) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
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
