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

extension PythonInterpreter {
    
    
    
    // MARK: Synchronous bytes
    
    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func bytesObjectSize(_ obj: SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try api.pythonBytes_Size(objPtr)
    }
    
    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func byteArrayObjectSize(_ obj: SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        return try api.pythonByteArray_Size(objPtr)
    }
    
    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func withUnsafeBytes<R>(_ obj: SafePythonObject, body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) throws -> R {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        
        var view = Py_buffer()
        
        guard api.PyObject_GetBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
            fatalError()
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
    
    
    public func bytesObjectSize(_ obj: PythonObject) async throws -> Int {
        guard let objPtr = getRegisteredPointer(forPythonObject: obj) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try await withGIL { try Int(api.pythonBytes_Size(objPtr)) }
    }
    
    public func bytesArrayObjectSize(_ obj: PythonObject) async throws -> Int {
        guard let objPtr = getRegisteredPointer(forPythonObject: obj) else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try await withGIL { try api.pythonByteArray_Size(objPtr) }
    }
    
    // REMOVED DUPLICATE async withUnsafeBytes that manually handled bytes and bytearray here
    
    public func withUnsafeBytes<R>(_ obj: PythonObject, body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) async throws -> R {
        try await withGIL {
            let objPtr = getRegisteredPointer(forPythonObject: obj)!
            
            var view = Py_buffer()
            
            guard api.PyObject_GetBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
                fatalError()
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


//    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
//    internal func isBytes(_ obj: SafePythonObject) throws -> Bool {
//        let objPtr = getRegisteredPointer(forSafeObj:obj)
//        return pyBytes_Check(objPtr)
//    }
//
//    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
//    internal func isBytesArray(_ obj: SafePythonObject) throws -> Bool {
//        let objPtr = getRegisteredPointer(forSafeObj:obj)
//        return pyByteArray_Check(objPtr)
//    }
