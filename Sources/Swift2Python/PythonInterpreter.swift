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
    
    //
    // ── CPyton wrappers ───────────────────────────────────────────────
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
    
    
    // MARK: -
    // MARK: SYNCHRONOUS MODE
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
        
        /// Access the interpreter context. Throws a fatalError if called on a literal before it is bound.
        internal var interpreter: PythonInterpreter {
            guard case let .bound(interp, _) = state else {
                fatalError("SafePythonObject is a ghost: No interpreter found in unbound literal.")
            }
            return interp
        }
        
        /// Access the Python Object ID. Throws a fatalError if called on a literal before it is bound.
        internal var id: PythonInterpreter.PythonObjectUniqueID {
            guard case let .bound(_, id) = state else {
                fatalError("SafePythonObject is a ghost: No ID found in unbound literal.")
            }
            return id
        }
        
        internal var isBoundToPythonInterpreter: Bool {
            switch state {
            case .bound: return true
            default:     return false
            }
        }
        
        //
        // a.name
        public subscript(dynamicMember name: String) -> SafePythonObject {
            // a.name
            get {
                let localInterpreter = interpreter
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
                let localInterpreter = interpreter
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
        
        internal func addOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncAdd(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        internal func addInPlaceOperator(sumend: SafePythonConvertible, addend: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncInPlaceAdd(sumend: sumend.toSafePythonObject(interpreter: $0), addend: addend.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        // This is implemented because writing it is better than erroring out.
        // But seriously, what are you doing here?  Why does your code use this?
        // Python addition results:
        static internal func unboundPythonAdd(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal + rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal + Double(rhsVal))
                case .deferredString(let rhsVal):
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal + (rhsVal ? 1.0 : 0.0))
                }
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: Double(lhsVal) + rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal + rhsVal)
                case .deferredString(let rhsVal):
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal + (rhsVal ? 1 : 0))
                }
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    fatalError("Python TypeError")
                case .deferredInt(let rhsVal):
                    fatalError("Python TypeError")
                case .deferredString(let rhsVal):
                    return SafePythonObject(stringLiteral: lhsVal + rhsVal)
                case .deferredBool(let rhsVal):
                    fatalError("Python TypeError")
                }
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) + rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) + rhsVal)
                case .deferredString(let rhsVal):
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) + (rhsVal ? 1 : 0))
                }
            }
        }
        
        
        internal func multiplyOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncMultiply(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        internal func subtractOperator(minuend: SafePythonConvertible, subtrahend: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncSubtract(minuend: minuend.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        internal func divideOperator(dividend: SafePythonConvertible, divisor: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncDivide(dividend: dividend.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        internal func subtractInPlaceOperator(diffend: SafePythonConvertible, subtrahend: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncInPlaceSubtract(diffend: diffend.toSafePythonObject(interpreter: $0), subtrahend: subtrahend.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        internal func multiplyInPlaceOperator(productand: SafePythonConvertible, multiplicand: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncInPlaceMultiply(productand: productand.toSafePythonObject(interpreter: $0), multiplicand: multiplicand.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        internal func divideInPlaceOperator(quotientand: SafePythonConvertible, divisor: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncInPlaceDivide(quotientand: quotientand.toSafePythonObject(interpreter: $0), divisor: divisor.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
    }  // end of Safe python object
    
    // MARK: Prepare for synchronous mode
    // No asynchronous loading of symbols, so they all need to be preloaded
    // at the beginning of synchronous mode.  They only load the first time
    // and are cached after that.
    
    struct SafePythonCSymbols {
        var PyBool_FromLong: (@convention(c) (Int) -> UnsafeMutableRawPointer?)?
        var PyFloat_FromDouble: (@convention(c) (Double) -> UnsafeMutableRawPointer?)?
        var PyLong_FromLong: (@convention(c) (Int) -> UnsafeMutableRawPointer?)?
        var PyNumber_Add: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        var PyNumber_InPlaceAdd: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        var PyNumber_InPlaceMultiply: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        var PyNumber_InPlaceSubtract: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        var PyNumber_InPlaceTrueDivide: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        var PyNumber_Multiply: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        var PyNumber_Subtract: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        var PyNumber_TrueDivide: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
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
        safeSymbolsCache.PyNumber_Add = try await runtime.loadSendableSymbol("PyNumber_Add",
                                                                             as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyNumber_InPlaceAdd = try await runtime.loadSendableSymbol("PyNumber_InPlaceAdd",
                                                                                    as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyNumber_InPlaceMultiply = try await runtime.loadSendableSymbol("PyNumber_InPlaceMultiply",
                                                                                         as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyNumber_InPlaceSubtract = try await runtime.loadSendableSymbol("PyNumber_InPlaceSubtract",
                                                                                         as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyNumber_InPlaceTrueDivide = try await runtime.loadSendableSymbol("PyNumber_InPlaceTrueDivide",
                                                                                           as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyNumber_Multiply = try await runtime.loadSendableSymbol("PyNumber_Multiply",
                                                                                  as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyNumber_Subtract = try await runtime.loadSendableSymbol("PyNumber_Subtract",
                                                                                  as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function
        safeSymbolsCache.PyNumber_TrueDivide = try await runtime.loadSendableSymbol("PyNumber_TrueDivide",
                                                                                    as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function
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
    
    // MARK: Conversions from primitives (synchronous mode)
    // Primitive type conversions in synchronous mode ----------
    
    internal func convertToSafePython(bool val: Bool) throws -> SafePythonObject {
        let id = try convertToSafePythonID(bool: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(bool val: Bool) throws -> PythonObjectUniqueID {
        logger.trace("CPyton API call in synchronous mode: PyBool_FromLong")
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
        logger.trace("CPyton API call in synchronous mode: PyFloat_FromDouble")
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
        logger.trace("CPyton API call in synchronous mode: PyLong_FromLong")
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
        logger.trace("CPyton API call in synchronous mode: PyUnicode_FromStringAndSize")
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
    
    // MARK: Subscript support (synchronous mode)
    // Subscript attribute operations in synchronous mode ----------
    
    fileprivate func syncGetObjectAttribute(_ obj: SafePythonObject, _ name: String) throws -> SafePythonObject {
        logger.trace("CPyton API call in synchronous mode: PyObject_GetAttrString")
        guard let getAttr = safeSymbolsCache.PyObject_GetAttrString else {
            throw PythonError.nullPointer("Failed ")
        }
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        guard let attrPtr = getAttr(objPtr, name) else {
            throw PythonError.nullPointer("Failed ")
        }
        let attrId = registerPythonObjectPointer(attrPtr)
        return SafePythonObject(interpreter: self, id: attrId)
    }
    
    fileprivate func syncSetObjectAttribute(_ obj: SafePythonObject, _ name: String, _ value: SafePythonObject) throws {
        logger.trace("CPyton API call in synchronous mode: PyObject_SetAttrString")
        guard let setAttr = safeSymbolsCache.PyObject_SetAttrString else {
            throw PythonError.nullPointer("Failed ")
        }
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        let valuePtr = getRegisteredPythonObjectPointer(value.id)!
        _ = setAttr(objPtr, name, valuePtr)
    }
    
    // MARK: Operator support (synchronous mode)
    // Operators for synchronous mode ----------
    
    internal func syncAdd(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        guard let pyAdd = safeSymbolsCache.PyNumber_Add else {
            throw PythonError.nullPointer("Failed ")
        }
        
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Add")
        guard let sumPtr = pyAdd(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '+' failed")
        }
        
        let sumId = registerPythonObjectPointer(sumPtr)
        return SafePythonObject(interpreter: self, id: sumId)
    }
    
    internal func syncSubtract(minuend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        guard let pyNumber_Subtract = safeSymbolsCache.PyNumber_Subtract else {
            throw PythonError.nullPointer("Failed ")
        }
        
        let minuendPtr = getRegisteredPythonObjectPointer(minuend.id)!
        let subtrahendPtr = getRegisteredPythonObjectPointer(subtrahend.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Subtract")
        guard let differencePtr = pyNumber_Subtract(minuendPtr, subtrahendPtr) else {
            throw PythonError.nullPointer("Python '-' failed")
        }
        
        let differenceId = registerPythonObjectPointer(differencePtr)
        return SafePythonObject(interpreter: self, id: differenceId)
    }
    
    internal func syncMultiply(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        guard let pyMultiply = safeSymbolsCache.PyNumber_Multiply else {
            throw PythonError.nullPointer("Failed ")
        }
        
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Multiply")
        guard let productPtr = pyMultiply(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '*' failed")
        }
        
        let productId = registerPythonObjectPointer(productPtr)
        return SafePythonObject(interpreter: self, id: productId)
    }
    
    internal func syncDivide(dividend: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        guard let pyNumber_TrueDivide = safeSymbolsCache.PyNumber_TrueDivide else {
            throw PythonError.nullPointer("Failed ")
        }
        
        let dividendPtr = getRegisteredPythonObjectPointer(dividend.id)!
        let divisorPtr = getRegisteredPythonObjectPointer(divisor.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_TrueDivide")
        guard let quotientPtr = pyNumber_TrueDivide(dividendPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '/' failed")
        }
        
        let quotientId = registerPythonObjectPointer(quotientPtr)
        return SafePythonObject(interpreter: self, id: quotientId)
    }
    
    internal func syncInPlaceAdd(sumend: SafePythonObject, addend: SafePythonObject) throws -> SafePythonObject {
        guard let pyInPlaceAdd = safeSymbolsCache.PyNumber_InPlaceAdd else {
            throw PythonError.nullPointer("PyNumber_InPlaceAdd not loaded")
        }
        
        let sumendPtr = getRegisteredPythonObjectPointer(sumend.id)!
        let addendPtr = getRegisteredPythonObjectPointer(addend.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceAdd")
        guard let sumPtr = pyInPlaceAdd(sumendPtr, addendPtr) else {
            throw PythonError.nullPointer("Python '+=' failed")
        }
        
        let sumId = registerPythonObjectPointer(sumPtr)
        return SafePythonObject(interpreter: self, id: sumId)
    }
    
    internal func syncInPlaceSubtract(diffend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        guard let pyInPlaceSubtract = safeSymbolsCache.PyNumber_InPlaceSubtract else {
            throw PythonError.nullPointer("PyNumber_InPlaceSubtract not loaded")
        }
        
        let diffendPtr = getRegisteredPythonObjectPointer(diffend.id)!
        let subtrahendPtr = getRegisteredPythonObjectPointer(subtrahend.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceSubtract")
        guard let differencePtr = pyInPlaceSubtract(diffendPtr, subtrahendPtr) else {
            throw PythonError.nullPointer("Python '-=' failed")
        }
        
        let differenceId = registerPythonObjectPointer(differencePtr)
        return SafePythonObject(interpreter: self, id: differenceId)
    }
    
    internal func syncInPlaceMultiply(productand: SafePythonObject, multiplicand: SafePythonObject) throws -> SafePythonObject {
        guard let pyInPlaceMultiply = safeSymbolsCache.PyNumber_InPlaceMultiply else {
            throw PythonError.nullPointer("PyNumber_InPlaceMultiply not loaded")
        }
        
        let productandPtr = getRegisteredPythonObjectPointer(productand.id)!
        let multiplicandPtr = getRegisteredPythonObjectPointer(multiplicand.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceMultiply")
        guard let productPtr = pyInPlaceMultiply(productandPtr, multiplicandPtr) else {
            throw PythonError.nullPointer("Python '*=' failed")
        }
        
        let productId = registerPythonObjectPointer(productPtr)
        return SafePythonObject(interpreter: self, id: productId)
    }
    
    internal func syncInPlaceDivide(quotientand: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        guard let pyInPlaceDivide = safeSymbolsCache.PyNumber_InPlaceTrueDivide else {
            throw PythonError.nullPointer("PyNumber_InPlaceTrueDivide not loaded")
        }
        
        let quotientandPtr = getRegisteredPythonObjectPointer(quotientand.id)!
        let divisorPtr = getRegisteredPythonObjectPointer(divisor.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceTrueDivide")
        guard let quotientPtr = pyInPlaceDivide(quotientandPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '/=' failed")
        }
        
        let quotientId = registerPythonObjectPointer(quotientPtr)
        return SafePythonObject(interpreter: self, id: quotientId)
    }
}

