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
    
    private func getRegisteredPythonObjectPointer(_ id: PythonObjectUniqueID) -> UnsafeMutableRawPointer? {
        return pythonObjectRegistry[id]
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
    
    private func pyObject_CallObject(_ objPtr: UnsafeMutableRawPointer, _ args: UnsafeMutableRawPointer? = nil) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: pyObject_CallObject")
        // Signature: PyObject* PyObject_CallObject(PyObject *callable_object, PyObject *args)
        let pyObjectCallObject = try await runtime.loadSendableSymbol("PyObject_CallObject",
                    as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self)
        return pyObjectCallObject.function(objPtr, args)
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
        //try await runtime.initializeIfNeeded()
            
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
    
    public func callPythonMethod(object: PythonObject, methodName: String, collectedArgs: [any PendingPythonConvertible]) async throws -> PythonObject {
        fatalError("shut up xcode")
    }
    
    public func callPythonMethod(object: PythonObject, methodName: String, collectedArgs: [any PendingPythonConvertible],
                                 kwargs: [String: PendingPythonConvertible] = [:]) async throws -> PythonObject {
        fatalError("shut up xcode")
    }
    
    public func callPythonMethod(_ obj: PythonObject, _ name: String, _ args: any PendingPythonConvertible...) async throws -> PythonObject {
        let allArgs = args as [any PendingPythonConvertible]
        return try await callPythonMethod(object: obj, methodName: name, collectedArgs: allArgs)
    }
    
    public func callPythonMethod(_ obj: PythonObject, _ name: String, _ args: any PendingPythonConvertible...,
                                   kwargs: [String: PendingPythonConvertible] = [:]) async throws -> PythonObject {
        let allArgs = args as [any PendingPythonConvertible]
        return try await callPythonMethod(object: obj, methodName: name, collectedArgs: allArgs, kwargs:kwargs)
    }
    
    // -------- Synchronous Python interop section  --------------------------
    //
    
    public func withIsolatedContext<T>(
        _ body: @Sendable (isolated PythonInterpreter) throws -> T
    ) async throws -> T {
        try await ensureSymbolsLoaded()
        return try body(self)
    }
    
    
    // Because a.name and some other stuff can't be async, they are only available once
    // the object is made inside the actor context
    //
    // SafePythonObject has two forms.
    // Form 1 is like a PythonObject except all the access to PythonInterpreter must be synchronous.
    // Form 2 is a ghost form.  It can't do anything except be turned into Form 1.  It is needed
    // because I want to enable code like safeObject.count = safeObject.count + 1.  This requires
    // a constructor that just takes an int or a float.
    //
    @dynamicMemberLookup
    public struct SafePythonObject: Sendable, SafePythonConvertible,
                            ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral,
                            ExpressibleByStringLiteral, ExpressibleByBooleanLiteral {
        
        
        // The state of SafePythonObject.  Is it real or is it just a value to be made real later?
        private enum State: Sendable {
            case bound(interpreter: PythonInterpreter, id: PythonObjectUniqueID)
            case deferredDouble(Double)
            case deferredInt(Int)
            case deferredString(String)
            case deferredBool(Bool)
        }
        private let state: State
        
        // Constructors to make arithmetic work
        public init(floatLiteral value: Double) {
            self.state = .deferredDouble(value)
        }
        
        public init(integerLiteral value: Int) {
            self.state = .deferredInt(value)
        }
        
        public init(stringLiteral value: String) {
            self.state = .deferredString(value)
        }
        
        public init(booleanLiteral value: Bool) {
            self.state = .deferredBool(value)
        }
        
        // Materialize the ghost form into a real form
        private func materialize(using context: PythonInterpreter) throws -> SafePythonObject {
            switch state {
            case .bound:
                return self // It's already real
            case .deferredDouble(let val):
                return try context.assumeIsolated {
                    return try $0.convertToSafePython(double:val)
                }
            case .deferredInt(let val):
                return try context.assumeIsolated {
                    return try $0.convertToSafePython(int:val)
                }
            case .deferredString(let val):
                return try context.assumeIsolated {
                    return try $0.convertToSafePython(string:val)
                }
            case .deferredBool(let val):
                return try context.assumeIsolated {
                    return try $0.convertToSafePython(bool:val)
                }
            }
        }
        
        public func toSafePythonObject(interpreter: PythonInterpreter) throws -> SafePythonObject {
            return try self.materialize(using: interpreter)
        }
        
        private var error: PythonError?
        
        fileprivate init(interpreter: PythonInterpreter, id: PythonObjectUniqueID) {
            self.state = .bound(interpreter: interpreter, id: id)
            self.error = nil
        }
        
        public func getInterpreter() -> PythonInterpreter {
            if case .bound(let interpreter, _) = state { return interpreter }
            fatalError("Cannot get interpreter from an unbound literal.  SafePythonObject is a ghost.")
        }
        
        public func getID() -> PythonObjectUniqueID {
            if case .bound(_, let id) = state { return id }
            fatalError("Cannot get ID from an unbound literal.  SafePythonObject is a ghost.")
        }
        
        //
        // a.name
        public subscript(dynamicMember name: String) -> SafePythonObject {
            // a.name
            get {
                let localInterpreter = getInterpreter()
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.syncGetObjectAttribute(self, name)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            }
            // a.name = value
            set {
                let localInterpreter = self.getInterpreter()
                localInterpreter.assumeIsolated {
                    do {
                        // newValue might be a literal Double. We make it real here!
                        let realValue = try newValue.materialize(using: $0)
                        try $0.syncSetObjectAttribute(self, name, realValue)
                    } catch {
                        fatalError("Failed to set attribute: \(error)")
                    }
                }
            }
        }
        
        //
        // a[key]
        public subscript(key: SafePythonConvertible...) -> SafePythonConvertible {
            // a[key]
            get {
                fatalError("Placeholder")
            }
            // a[key] = value
            set {
                fatalError("Placeholder")
            }
        }
        
        public func addOperator(_ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = getInterpreter()
                return try localInterpreter.assumeIsolated {
                    try $0.addOperator(self, rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed to convert value or set attribute: \(error)")
            }
        }
    }
    
    private struct SafePythonCSymbols {
        var PyBool_FromLong: (@convention(c) (Int) -> UnsafeMutableRawPointer?)?
        var PyFloat_FromDouble: (@convention(c) (Double) -> UnsafeMutableRawPointer?)?
        var PyLong_FromLong: (@convention(c) (Int) -> UnsafeMutableRawPointer?)?
        var PyObject_GetAttrString: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?)?
        var PyObject_SetAttrString: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Int32)?
        var PyRun_SimpleString: (@convention(c) (UnsafePointer<CChar>) -> Int32)?
        var PyUnicode_FromStringAndSize: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?)?
    }
    
    private var safeSymbolsCache = SafePythonCSymbols()
    
    private func ensureSymbolsLoaded() async throws {
        // Return if the cache is already setup
        guard safeSymbolsCache.PyRun_SimpleString == nil else { return }
        safeSymbolsCache.PyBool_FromLong = try await runtime.loadSendableSymbol("PyBool_FromLong",
                    as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyFloat_FromDouble = try await runtime.loadSendableSymbol("PyFloat_FromDouble",
                    as: (@convention(c) (Double) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyLong_FromLong = try await runtime.loadSendableSymbol("PyLong_FromLong",
                    as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyRun_SimpleString = try await runtime.loadSendableSymbol("PyRun_SimpleString",
                    as: (@convention(c) (UnsafePointer<CChar>) -> Int32).self).function
        safeSymbolsCache.PyObject_GetAttrString = try await runtime.loadSendableSymbol("PyObject_GetAttrString",
                    as: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyObject_SetAttrString = try await runtime.loadSendableSymbol("PyObject_SetAttrString",
                    as: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Int32).self).function
        safeSymbolsCache.PyUnicode_FromStringAndSize = try await runtime.loadSendableSymbol("PyUnicode_FromStringAndSize",
                    as: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?).self).function
    }
    
    public func bind(_ obj: PythonObject) -> PythonInterpreter.SafePythonObject {
        return SafePythonObject(interpreter: self, id: obj.id)
    }
    
    internal func convertToSafePython(bool val: Bool) throws -> SafePythonObject {
        let id = try convertToSafePythonID(bool: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(bool val: Bool) throws -> PythonObjectUniqueID {
        guard let convert = safeSymbolsCache.PyBool_FromLong else {
            throw PythonError.nullPointer("Failed to convert bool: \(val)")
        }
        guard let ptr = convert(val ? 1 : 0) else {
            throw PythonError.nullPointer("Failed to convert bool: \(val)")
        }
        
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(ptr)
        return id
    }
    
    internal func convertToSafePython(double val: Double) throws -> SafePythonObject {
        let id = try convertToSafePythonID(double: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(double val: Double) throws -> PythonObjectUniqueID {
        guard let convert = safeSymbolsCache.PyFloat_FromDouble else {
            throw PythonError.nullPointer("Failed to convert double: \(val)")
        }
        guard let ptr = convert(val) else {
            throw PythonError.nullPointer("Failed to convert double: \(val)")
        }
            
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(ptr)
        return id
    }
    
    internal func convertToSafePython(int val: Int) throws -> SafePythonObject {
        let id = try convertToSafePythonID(int: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(int val: Int) throws -> PythonObjectUniqueID {
        guard let convert = safeSymbolsCache.PyLong_FromLong else {
            throw PythonError.nullPointer("Failed to convert int: \(val)")
        }
        guard let ptr = convert(val) else {
            throw PythonError.nullPointer("Failed to convert int: \(val)")
        }
        
        // Register the pointer in our actor's internal hash
        let id = registerPythonObjectPointer(ptr)
        return id
    }
    
    internal func convertToSafePython(string val: String) throws -> SafePythonObject {
        let id = try convertToSafePythonID(string: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(string val: String) throws -> PythonObjectUniqueID {
        guard let convert = safeSymbolsCache.PyUnicode_FromStringAndSize else {
            throw PythonError.nullPointer("Failed to convert string: \(val)")
        }
        
        let cString = val.utf8CString
        return try cString.withUnsafeBufferPointer { bufferPtr in
            guard let ptr = convert(bufferPtr.baseAddress, cString.count - 1) else {
                throw PythonError.nullPointer("Failed to convert string: \(val)")
            }
            
            // Register the pointer in our actor's internal hashtable
            let id = registerPythonObjectPointer(ptr)
            return id
        }
    }
    
    
    
    fileprivate func syncGetObjectAttribute(_ obj: SafePythonObject, _ name: String) throws -> SafePythonObject {
        guard let getAttr = safeSymbolsCache.PyObject_GetAttrString else {
            throw PythonError.nullPointer("Failed ")
        }
        let objPtr = getRegisteredPythonObjectPointer(obj.getID())!
        guard let attrPtr = getAttr(objPtr, name) else {
            throw PythonError.nullPointer("Failed ")
        }
        let attrId = registerPythonObjectPointer(attrPtr)
        return SafePythonObject(interpreter: self, id: attrId)
    }
    
    fileprivate func syncSetObjectAttribute(_ obj: SafePythonObject, _ name: String, _ value: SafePythonObject) throws {
        guard let setAttr = safeSymbolsCache.PyObject_SetAttrString else {
            throw PythonError.nullPointer("Failed ")
        }
        let objPtr = getRegisteredPythonObjectPointer(obj.getID())!
        let valuePtr = getRegisteredPythonObjectPointer(value.getID())!
        _ = setAttr(objPtr, name, valuePtr)
    }
    
    // Operators
    
    internal func addOperator(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        fatalError("Placeholder to tell xcode to shut up")
    }
}

