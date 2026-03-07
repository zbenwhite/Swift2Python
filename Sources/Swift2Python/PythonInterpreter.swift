//
//  PythonInterpreter.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

import Logging
import Foundation

public actor PythonInterpreter {
    
    public struct PythonObjectUniqueID: Sendable, Hashable, CustomStringConvertible {
        // Currently using UUID, but can be changed to Int64 or UInt without
        // changing any public method signatures later.
        private let rawValue: UUID
        
        internal init(_ ptr: UnsafeMutableRawPointer) {
            self.rawValue = UUID()
        }
        
        public var description: String {
            return "PyID(\(rawValue.uuidString.prefix(8)))"
        }
    }
    
    // Because a.name and some other stuff can't be async, they are only avail
    @dynamicMemberLookup
    private struct SafePythonObject {
        private let interpreter: PythonInterpreter
        
        //
        // a.name
        public subscript(dynamicMember name: String) -> SafePythonObject {
            // a.name
            get {
                fatalError("Placeholder to tell xcode to shut up")
            }
            // a.name = value
            nonmutating set {
                fatalError("Placeholder to tell xcode to shut up")
                //try await interpreter.setObjectAttribute(self, name, newValue)
            }
        }
        
        //
        // a[key]
        subscript(key: PendingPythonConvertible...) -> SafePythonObject {
            // a[key]
            get {
                fatalError("Placeholder to tell xcode to shut up")
            }
            // a[key] = value
            nonmutating set {
                fatalError("Placeholder to tell xcode to shut up")
            }
        }
    }
    
    private let runtime = PythonRuntime.shared
    private let logger: Logger = Logger(label: "swift2python.PythonInterpreter")
    
    private var pythonObjectRegistry: [PythonObjectUniqueID: UnsafeMutableRawPointer] = [:]
    private var pythonObjectSwiftRefCount: [PythonObjectUniqueID: Int] = [:]
    
    private func registerPythonObjectPointer(_ ptr: UnsafeMutableRawPointer) -> PythonObjectUniqueID {
        let id = PythonObjectUniqueID(ptr)
        pythonObjectRegistry[id] = ptr
        pythonObjectSwiftRefCount[id] = 1
        return id
    }
    
    /// Decrements the Swift-side reference count.
    /// When it hits zero, it triggers the Python C-API DecRef.
    internal func releaseHandle(_ id: PythonObjectUniqueID) async throws {
        guard let count = pythonObjectSwiftRefCount[id] else { return }
            
        if count <= 1 {
            if let ptr = pythonObjectRegistry[id] {
                // Perform the actual Python cleanup
                try await py_DecRef(ptr)
            }
            pythonObjectRegistry.removeValue(forKey: id)
            pythonObjectSwiftRefCount.removeValue(forKey: id)
        } else {
            pythonObjectSwiftRefCount[id] = count - 1
        }
    }
    
//    // ── CPyton wrappers ───────────────────────────────────────────────
    private func py_DecRef(_ pointer: UnsafeMutableRawPointer) async throws {
        logger.trace("CPyton wrapper called: py_DecRef")
        let decrementRefCount = try await runtime.loadSendableSymbol("Py_DecRef",
                    as: (@convention(c) (UnsafeMutableRawPointer) -> Void).self)
        decrementRefCount.function(pointer)
    }
    
    private func pyBool_FromLong(_ value: Bool) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyBool_FromLong")
        let pyBoolFromLong = try await runtime.loadSendableSymbol("PyBool_FromLong",
                    as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self)
        return pyBoolFromLong.function(value ? 1 : 0)
    }
    
    private func pyDict_New() async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyDict_New")
        // Signature: PyObject *PyDict_New()
        let pyDictNew = try await runtime.loadSendableSymbol( "PyDict_New", as: (@convention(c) () -> UnsafeMutableRawPointer?).self)
        return pyDictNew.function()
    }
    
    private func pyDict_SetItem(_ dictPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer, _ valuePtr: UnsafeMutableRawPointer) async throws -> Int32 {
        logger.trace("CPyton wrapper called: pyDict_SetItem")
        // Signature: int PyDict_SetItem(PyObject *p, PyObject *key, PyObject *val)
        let pyDictSetItem = try await runtime.loadSendableSymbol( "PyDict_SetItem",
                    as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self
        )
        return pyDictSetItem.function(dictPtr, keyPtr, valuePtr)
    }
    
    private func pyFloat_FromDouble(_ value: Double) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyFloat_FromDouble")
        let pyFloatFromDouble = try await runtime.loadSendableSymbol("PyFloat_FromDouble",
                    as: (@convention(c) (Double) -> UnsafeMutableRawPointer?).self)
        return pyFloatFromDouble.function(value)
    }
    
    private func pyImport_AddModule(_ module: String) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyImport_AddModule")
        let pyAdd = try await runtime.loadSendableSymbol("PyImport_AddModule",
                    as: (@convention(c) (UnsafePointer<CChar>) -> UnsafeMutableRawPointer?).self)
        return module.withCString({ pyAdd.function($0) })
    }
    
    private func pyImport_AddModule(pointer: UnsafeMutableRawPointer) async throws {
        logger.trace("CPyton wrapper called: pyImport_AddModule")
        let pyAdd = try await runtime.loadSendableSymbol("PyImport_AddModule",
                    as: (@convention(c) (UnsafeMutableRawPointer) -> Void).self)
        pyAdd.function(pointer)
    }
    
    private func pyImport_ImportModule(_ module: String) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyImport_ImportModule")
        let pyImport = try await runtime.loadSendableSymbol("PyImport_ImportModule",
                    as: (@convention(c) (UnsafePointer<CChar>) -> UnsafeMutableRawPointer?).self)
        return module.withCString({ pyImport.function($0) })
    }
    
    private func pyList_New(_ length: Int) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyList_New")
        let pyListNew = try await runtime.loadSendableSymbol("PyList_New",
                    as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self)
        return pyListNew.function(length)
    }
    
    private func pyList_SetItem(_ listPtr: UnsafeMutableRawPointer, _ index: Int, _ valuePtr: UnsafeMutableRawPointer) async throws -> Int32 {
        logger.trace("CPyton wrapper called: pyList_SetItem")
        let pyListSetItem = try await runtime.loadSendableSymbol("PyList_SetItem",
                    as: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32).self)
        return pyListSetItem.function(listPtr, index, valuePtr)
    }
    
    private func pyLong_FromLong(_ value: Int) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyLong_FromLong")
        let pyLongFromLong = try await runtime.loadSendableSymbol("PyLong_FromLong",
                    as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self)
        return pyLongFromLong.function(value)
    }
    
    private func pyObject_GetAttrString(_ pointer: UnsafeMutableRawPointer, _ name: String) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyObject_GetAttrString")
        let pyGetAttr = try await runtime.loadSendableSymbol("PyObject_GetAttrString",
                    as: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?).self)
        return pyGetAttr.function(pointer, name.withCString({ $0 }))
    }
    
    private func pyObject_GetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyObject_GetItem")
        let pyGetItem = try await runtime.loadSendableSymbol("PyObject_GetItem",
                    as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self)
        return pyGetItem.function(obPtr, keyPtr)
    }
    
    private func pyObject_SetAttrString(_ obPtr: UnsafeMutableRawPointer, _ name: String, _ rvalPtr: UnsafeMutableRawPointer) async throws -> Int32? {
        logger.trace("CPyton wrapper called: pyObject_SetAttrString")
        let pySetAttr = try await runtime.loadSendableSymbol("PyObject_SetAttrString",
                    as: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Int32).self)
        return pySetAttr.function(obPtr, name.withCString({ $0 }), rvalPtr)
    }
    
    private func pyObject_SetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer,
                                  _ rvalPtr: UnsafeMutableRawPointer) async throws -> Int32? {
        logger.trace("CPyton wrapper called: pyObject_SetItem")
        let pySetItem = try await runtime.loadSendableSymbol("PyObject_SetItem",
                    as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self)
        return pySetItem.function(obPtr, keyPtr, rvalPtr)
    }
    
    public func pyRun_SimpleString(_ command: String) async throws -> Int32 {
        logger.trace("CPyton wrapper called: pyRun_SimpleString")
        let pyRun = try await runtime.loadSendableSymbol("PyRun_SimpleString",
                    as: (@convention(c) (UnsafePointer<CChar>) -> Int32).self)
        return command.withCString { pyRun.function($0) }
    }
    
    private func pyUnicode_FromStringAndSize(_ st: String) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyUnicode_FromStringAndSize")
        let pyUnicodeFromStringAndSize = try await runtime.loadSendableSymbol("PyUnicode_FromStringAndSize",
                    as: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?).self)
        let cString = st.utf8CString
        return cString.withUnsafeBufferPointer { bufferPtr in
            pyUnicodeFromStringAndSize.function(bufferPtr.baseAddress, cString.count - 1)
        }
    }
    
    

    /// Asynchronously decrements the reference count of a raw pointer.
    /// Called by PyPointer's deinit.
    func decrementRefCount(_ pointer: UnsafeMutableRawPointer) async throws {
        try await py_DecRef(pointer)
    }
    
    
    
    /// Standard import using PyImport_ImportModule
    private func importStandard(_ name: String) async throws -> PythonObject {
        guard let ptr = try await pyImport_ImportModule(name) else {
            throw PythonError.nullPointer("Failed to import module: \(name)")
        }
            
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(ptr)
        return PythonObject(id: id, interpreter: self)
    }

    /// Aliased import using PyRun_SimpleString and __main__ lookup
    private func importWithAlias(_ name: String, alias: String) async throws -> PythonObject {
            
        // 1. Execute "import name as alias"
        let command = "import \(name) as \(alias)"
        let result = try await pyRun_SimpleString(command)
            
        guard result == 0 else {
            throw PythonError.stringConversionFailed("Python execution failed for: \(command)")
        }

        // 2. Retrieve the alias from the __main__ module namespace
        return try await getFromMain(alias)
    }

    /// Internal helper to fetch an object from the Python __main__ scope
    private func getFromMain(_ attrName: String) async throws -> PythonObject {

        // AddModule returns a 'borrowed' reference to the __main__ module
        guard let mainModulePtr = try await pyImport_AddModule("__main__") else {
            throw PythonError.nullPointer("Could not access Python __main__ module")
        }

        // Get the attribute (the alias) from __main__
        guard let aliasPtr = try await pyObject_GetAttrString(mainModulePtr, attrName) else {
            throw PythonError.nullPointer("Alias '\(attrName)' not found in Python scope")
        }

        let id = registerPythonObjectPointer(aliasPtr)
        return PythonObject(id: id, interpreter: self)
    }
    
    
    /// Imports a Python module, optionally with an alias.
    /// Usage: try await py.`import`("numpy", as: "np")
    public func `import`(_ name: String, as alias: String? = nil) async throws -> PythonObject {
        // Ensure the runtime is initialized before accessing C symbols
        try await runtime.initializeIfNeeded()
            
        if let alias = alias {
            return try await importWithAlias(name, alias: alias)
        } else {
            return try await importStandard(name)
        }
    }
    
    public func convertBoolToPython(_ val: Bool) async throws -> PythonObject {
        guard let ptr = try await pyBool_FromLong(val) else {
            throw PythonError.nullPointer("Failed to convert bool: \(val)")
        }
        
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(ptr)
        return PythonObject(id: id, interpreter: self)
    }
    
    public func convertDoubleToPython(_ val: Double) async throws -> PythonObject {
        guard let ptr = try await pyFloat_FromDouble(val) else {
            throw PythonError.nullPointer("Failed to convert double: \(val)")
        }
        
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(ptr)
        return PythonObject(id: id, interpreter: self)
    }
    
    public func convertIntToPython(_ val: Int) async throws -> PythonObject {
        guard let ptr = try await pyLong_FromLong(val) else {
            throw PythonError.nullPointer("Failed to convert int: \(val)")
        }
        
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(ptr)
        return PythonObject(id: id, interpreter: self)
    }
    
    public func convertStringToPython(_ val: String) async throws -> PythonObject {
        guard let ptr = try await pyUnicode_FromStringAndSize(val) else {
            throw PythonError.nullPointer("Failed to convert string: \(val)")
        }
            
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(ptr)
        return PythonObject(id: id, interpreter: self)
    }
    
    public func convertArrayToPython(_ val: [PendingPythonConvertible]) async throws -> PythonObject {
        guard let listPtr = try await pyList_New(val.count)  else {
            throw PythonError.nullPointer("Failed to convert list: \(val)")
        }
        for (index, element) in val.enumerated() {
            let valuePythonObject = try await element.toPythonObject(interpreter: self)
            let valuePtr = pythonObjectRegistry[valuePythonObject.id]
            _ = try await pyList_SetItem(listPtr, index, valuePtr!)
        }
        
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(listPtr)
        return PythonObject(id: id, interpreter: self)
    }
    
    public func convertDictionaryToPython<K, V>(_ dict: [K: V]) async throws -> PythonObject
            where K: PendingPythonConvertible & Hashable, V: PendingPythonConvertible {
        guard let dictPtr = try await pyDict_New()  else {
            throw PythonError.nullPointer("Failed to convert dictionary")
        }
        
        for (key, value) in dict {
            let keyObj = try await key.toPythonObject(interpreter: self)
            let valueObj = try await value.toPythonObject(interpreter: self)
            let keyPtr = pythonObjectRegistry[keyObj.id]!
            let valuePtr = pythonObjectRegistry[valueObj.id]!
            _ = try await pyDict_SetItem(dictPtr, keyPtr, valuePtr)
        }
        
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(dictPtr)
        return PythonObject(id: id, interpreter: self)
    }
    
    public func getObjectAttribute(_ obj: PythonObject, _ name: String) async throws -> PythonObject {
        let objPtr = pythonObjectRegistry[obj.id]!
        let valuePtr = try await pyObject_GetAttrString(objPtr, name)
        let id = registerPythonObjectPointer(valuePtr!)
        return PythonObject(id: id, interpreter: self)
    }
    
    public func setObjectAttribute(_ obj: PythonObject, _ name: String, _ value: PythonObject) async throws {
        let objPtr = pythonObjectRegistry[obj.id]!
        let valuePtr = pythonObjectRegistry[value.id]!
        _ = try await pyObject_SetAttrString(objPtr, name, valuePtr)
    }
    
    func withIsolatedContext<T>(
        _ body: @Sendable (isolated PythonInterpreter) throws -> T
    ) async rethrows -> T {
        try body(self)
    }
}

