//
//  PythonInterpreter+RefCount.swift
//  Swift2Python
//
//  Created by Ben White on 4/23/26.
//

extension PythonInterpreter {
    
    
    struct IsolatedLifecycleRecord {
        var referenceCount: Int
        let objectPtr: UnsafeMutableRawPointer
    }
    
    struct ReferenceCountTestHandle: @unchecked Sendable {
        let handle: UnsafeMutableRawPointer
    }
    
    class IsolatedContextRegistry {
        var registry: [PythonObjectUniqueID: IsolatedLifecycleRecord] = [:]
    }
    
    internal func getRefCount(forHandle: ReferenceCountTestHandle) async throws -> Int {
        return try self.withGIL {
            return try Int(api.pythonReferenceCount(forHandle.handle))
        }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func getRefCount(forSafeObj: SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPointer(forSafeObj: forSafeObj)
        return try Int(api.pythonReferenceCount(objPtr))
    }
    
    internal func getRefCount(forPythonObj: PythonObject) async throws -> Int {
        return try self.withGIL {
            let objPtr = getRegisteredPointer(forPythonObject:forPythonObj)!
            return try Int(api.pythonReferenceCount(objPtr))
        }
    }
    
    internal func getReferenceCountHandle(forSafeObj: SafePythonObject) throws -> ReferenceCountTestHandle {
        let objPtr = getRegisteredPointer(forSafeObj: forSafeObj)
        return ReferenceCountTestHandle(handle: objPtr)
        
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func incrementHousekeepingRefCount(forSafeObj: SafePythonObject, andAlsoPythonsRefCount: Bool = false) {
        guard let currentContext = isolatedContextStack.last, var record = currentContext.registry[forSafeObj.id] else {
            fatalError("Attempted to reference count a SafePythonObject that was not in the registry!")
        }
        record.referenceCount += 1                           // update the housekeeping reference count
        currentContext.registry[forSafeObj.id] = record      // write it back because it's a struct
        if andAlsoPythonsRefCount {
            api.Py_IncRef(record.objectPtr)
        }
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func decrementHousekeepingRefCount(forSafeObj: SafePythonObject, andAlsoPythonsRefCount: Bool = false) {
        guard let currentContext = isolatedContextStack.last, var record = currentContext.registry[forSafeObj.id] else {
            fatalError("Attempted to reference count a SafePythonObject that was not in the registry!")
        }
        record.referenceCount -= 1                           // update the housekeeping rreference count
        currentContext.registry[forSafeObj.id] = record      // write it back because it's a struct
        if andAlsoPythonsRefCount {
            api.Py_DecRef(record.objectPtr)
        }
    }
    
    public func escapeFromIsolation(forSafeObj: SafePythonObject) -> PythonObject {
        // Code is duplicated here because this is a special case
        guard let currentContext = isolatedContextStack.last, var record = currentContext.registry[forSafeObj.id] else {
            fatalError("Attempted to reference count a SafePythonObject that was not in the registry!")
        }
        record.referenceCount -= 1                           // update the reference count
        currentContext.registry[forSafeObj.id] = record      // write it back because it's a struct
        let ptr = record.objectPtr
        let newId = registerPythonObjectPointer(ptr)
        return PythonObject(id: newId, interpreter: self)
    }
    
    internal func setupSafePythonObjectRegistry() {
        isolatedContextStack.append(IsolatedContextRegistry())
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func registerSafePythonObject(_ ptr: UnsafeMutableRawPointer) -> PythonObjectUniqueID {
        guard let currentContext = isolatedContextStack.last else {
            fatalError("Attempted to register a SafePythonPython but the isolatedContextStack was empty!")
        }
        let id = PythonObjectUniqueID(ptr)
        let record = IsolatedLifecycleRecord(referenceCount: 0, objectPtr: ptr)
        currentContext.registry[id] = record
        return id
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func getRegisteredSafeObjectPtr(id: PythonObjectUniqueID) -> UnsafeMutableRawPointer {
        guard let currentContext = isolatedContextStack.last, let record = currentContext.registry[id] else {
            fatalError("Attempted to reference count a SafePythonObject that was not in the registry!")
        }
        return record.objectPtr
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    internal func getRegisteredPointer(forSafeObj: SafePythonObject) -> UnsafeMutableRawPointer {
        return getRegisteredSafeObjectPtr(id: forSafeObj.id)
    }
                                           
    internal func cleanupSafePythonObjects() {
        guard let contextToCleanup = isolatedContextStack.popLast() else {
            logger.error("Attempted to cleanupSafePythonObjects but the isolatedContextStack was empty!")
            return
        }
                
        for (_, record) in contextToCleanup.registry {
            let count = record.referenceCount
            let objPtr = record.objectPtr
            if count > 0 {
                // Call Py_DecRef to free up the object
                for _ in 0..<count {
                    api.Py_DecRef(objPtr)
                }
            }
        }
    }
}
