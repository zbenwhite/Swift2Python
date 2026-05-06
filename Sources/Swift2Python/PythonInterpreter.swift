//
//  PythonInterpreter.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

// TODO: PythonKit Python.swift line 119: CustomStringConvertible -- printing python objects
// TODO: PythonKit Python.swift line 131: CustomPlaygroundDisplayConvertible -- swift playground display
// TODO: PythonKit Python.swift line 139: CustomReflectable -- mirror api
// TODO: PythonKit Python.swift line 1386: hashing support
// TODO: PythonKit Python.swift line 1470: ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral

// [2026-04-05]: DONE: Make C API lookups happen at initialize and stop checking for validity all the time
// TODO: Reference handling
// TODO: handle exceptions from python in a nice swift way
// [2026-04-26]: DONE: true/false checking in python objects
// TODO: tuples
// TODO: builtins
// TODO: python dict and sequence APIs
// TODO: PythonBytes -- create python bytes objects from swift
// [2026-04-18]: DONE: exponent operator
// [2026-04-18]: DONE: modulus operator
// TODO: custom ENV variables to find python
// TODO: change the id <--> pointer stuff to a typecast of the pointer?
// TODO: All conversions should work in both PythonObject and SafePythonObject mode
// [2026-04-25]: DONE: unbind or something to let SafePythonObject become a PythonObject at the end of the isolated closure
// TODO: api for arithmetic on PythonObject since operators can't be async
// TODO: understand free threaded python
// TODO: SafePythonObject comparisons that throw -- they should also handle unbound
// TODO: Combine Unbound and bound comparisons and operators
// TODO: choose "Equal" or "Equals" for comparison function naming and only use one
// [2026-04-25]: DONE: Use the InPlace Python APIs for InPlace just in case the operators are overloaded in python.
// TODO: bit shift operators?

import Logging
import Foundation
import Collections

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
    internal let logger: Logger = Logger(label: "swift2python.PythonInterpreter")
    
    internal var pythonObjectRegistry: [PythonObjectUniqueID: PyObjectLifecycleRecord] = [:]
    

    
    
    init() async throws {
        logger.trace("Preload all Python C API symbols.")
        self.api = try await Self.loadAllSymbols(using: runtime, logger)
        
        // Defaults for some global helpers.  Setting them to false works because
        // of the ExpressibleByBooleanLiteral.  This is just temporary until the first
        // withIsolatedContest call.
        self.main = false
        self.builtins = false
        self.sys = false
        self.globals = false
    }
    
    internal var api: PreloadedPythonSymbols!  // Loaded in init
        
    // MARK: GIL handling (async mode)
    
    // A GIL handler for async mode
    public func withGIL<Result>(_ body: () throws -> Result) async throws -> Result {
        
        // Manage the GIL
        let gstate = api.pythonGILState_Ensure()
        defer { api.pythonGILState_Release(gstate) }
        
        // All Python C API usage is now safe here.
        return try body()
    }
    
    // MARK: Import support (async mode)
    
    /// Standard import using PyImport_ImportModule
    private func importStandard(_ name: String) async throws -> PythonObject {
        logger.trace("import \(name) called for PythonObject (async)")
        return try await withGIL {
            guard let ptr = try api.pythonImport_ImportModule(name) else {
                throw PythonError.nullPointer("Failed to import module: \(name)")
            }
            return newPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    /// Aliased import using PyRun_SimpleString and __main__ lookup
    private func importWithAlias(_ name: String, alias: String) async throws -> PythonObject {
        logger.trace("import \(name) as \(alias) called for PythonObject (async)")
        let command = "import \(name) as \(alias)"
        try await runSimpleString(pythonCode: command)
        let main = try await getMain()
        return try await main.getItem(key: alias)
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
    
    public func addModule(_ name: String) async throws -> PythonObject {
        logger.trace("addModule(\(name)) called for PythonObject (async)")
        return try await withGIL {
            guard let ptr = try api.pythonImport_AddModule(name) else {
                throw PythonError.nullPointer("Could not access __main__")
            }
            return borrowedPythonObject(fromReturnedPointer: ptr)
        }
    }
    
    // Async version of .main
    public func getMain() async throws -> PythonObject {
        if _main == nil {
            _main = try await addModule("__main__")
        }
        return _main!
    }
    // Async version of .builtins
    public func getBuiltins() async throws -> PythonObject {
        if _builtins == nil {
            _builtins = try await importStandard("builtins")
        }
        return _builtins!
    }
    // Async version of .sys
    public func getSys() async throws -> PythonObject {
        if _sys == nil {
            _sys = try await importStandard("sys")
        }
        return _sys!
    }
    // Async version of .globals
    public func getGlobals() async throws -> PythonObject {
        if _globals == nil {
            let main = try await getMain()
            _globals = try await main.get(attr: "__dict__")
        }
        return _globals!
    }
    
    public func runSimpleString(pythonCode: String) async throws {
        logger.trace("runSimpleString called (async)")
        try await withGIL {
            let result = try api.pythonRun_SimpleString(pythonCode)
            guard result == 0 else {
                throw PythonError.stringConversionFailed("Python execution failed for: \(pythonCode)")
            }
        }
    }
    
    // MARK: Attribute access (async mode)
    
    public func get(object: PythonObject, attribute: String) async throws -> PythonObject {
        logger.trace("get: 'object.attribute' called for PythonObject (async)")
        let objPtr = getRegisteredPointer(forPythonObject: object)!
        
        return try await withGIL {
            let valuePtr = try api.pythonObject_GetAttrString(objPtr, attribute)!
            return newPythonObject(fromReturnedPointer: valuePtr)
        }
    }
    
    public func set(object: PythonObject, attribute: String, value: PythonObject) async throws {
        logger.trace("set: 'object.attribute = value' called for PythonObject (async)")
        let objPtr = getRegisteredPointer(forPythonObject: object)!
        let valuePtr = getRegisteredPointer(forPythonObject: value)!
        
        try await withGIL {
            _ = try api.pythonObject_SetAttrString(objPtr, attribute, valuePtr)
        }
    }
    
    // MARK: Subscripting (async mode)
    
    public func getItem(object: PythonObject, key: PythonObject) async throws -> PythonObject {
        logger.trace("getItem: 'object[key]' called for PythonObject (async)")
        let keyPtr = getRegisteredPointer(forPythonObject: key)!
        let objPtr = getRegisteredPointer(forPythonObject: object)!
        
        return try await withGIL {
            guard let resultPtr = try api.pythonObject_GetItem(objPtr, keyPtr) else {
                throw PythonError.nullPointer("Python subscript get failed")
            }
            return newPythonObject(fromReturnedPointer: resultPtr)
        }
    }
    
    public func setItem(object: PythonObject, key: PythonObject, newValue: PythonObject) async throws {
        logger.trace("setItem: 'object[key] = newValue' called for PythonObject (async)")
        let keyPtr = getRegisteredPointer(forPythonObject: key)!
        let newValuePtr = getRegisteredPointer(forPythonObject: newValue)!
        let objPtr = getRegisteredPointer(forPythonObject: object)!
        
        try await withGIL {
            _ = try api.pythonObject_SetItem(objPtr, keyPtr, newValuePtr)
        }
    }
    
    // MARK: Comparion Support (async mode)
    
    public func equals(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Equals comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.equal.rawValue) {
            case 0: return false
            case 1: return true
            default: try throwPythonError()
            }
        }
    }
    
    public func notEquals(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Not equals comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.notEqual.rawValue) {
            case 0: return false
            case 1: return true
            default: try throwPythonError()
            }
        }
    }
    
    public func lessThan(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Less than comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.lessThan.rawValue) {
            case 0: return false
            case 1: return true
            default: try throwPythonError()
            }
        }
    }
    
    public func lessThanOrEqual(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Less than or equal comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.lessThanOrEqual.rawValue) {
            case 0: return false
            case 1: return true
            default: try throwPythonError()
            }
        }
    }
    public func greaterThan(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Greater than comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThan.rawValue) {
            case 0: return false
            case 1: return true
            default: try throwPythonError()
            }
        }
    }
    
    public func greaterThanOrEqual(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Greater than or equal comparison for PythonObject (async)")
        let lhsPtr = getRegisteredPointer(forPythonObject: lhs)!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = getRegisteredPointer(forPythonObject: rhsPyObj)!
        
        return try await withGIL {
            switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThanOrEqual.rawValue) {
            case 0: return false
            case 1: return true
            default: try throwPythonError()
            }
        }
    }

    
    // MARK: -
    // MARK: SYNCHRONOUS MODE
    //
    
    
    // Isolated registry
    //internal var isolatedContextStack: Deque<[PythonObjectUniqueID: IsolatedLifecycleRecord]> = []
    internal var isolatedContextStack: Deque<IsolatedContextRegistry> = []
    
    
    // MARK: Globals
    
    // These are useful globals.  They are stored as PythonObject so they clean themselves up.
    // bind them at the beginning of withIsolatedContext to make them easy to use.
    
    /// The `__main__` module — primary namespace for user code
    private var _main: PythonObject?
    public private(set) var main: SafePythonObject
        
    /// Builtins module — direct access to `len`, `list`, `dict`, `print`, etc.
    private var _builtins: PythonObject?
    public private(set) var builtins: SafePythonObject
        
    /// `sys` module — very commonly used (`sys.path`, `sys.modules`, `sys.version_info`, ...)
    private var _sys: PythonObject?
    public private(set) var sys: SafePythonObject
        
    /// Globals dictionary of the `__main__` module (equivalent to `__main__.__dict__`)
    /// This is very useful for `exec()` / `eval()` with shared namespace
    private var _globals: PythonObject?
    public private(set) var globals: SafePythonObject
    
    
    private func readyGlobalSetups() async throws {
        _ = try await getMain()
        _ = try await getBuiltins()
        _ = try await getSys()
        _ = try await getGlobals()
    }
    
    private func setupGlobals() throws {
        self.main = _bind(pythonObject: _main!)
        self.builtins = _bind(pythonObject: _builtins!)
        self.sys = _bind(pythonObject: _sys!)
        self.globals = _bind(pythonObject: _globals!)
    }
    
    private func clearGlobals() {
        self.main = false
        self.builtins = false
        self.sys = false
        self.globals = false
    }
    
    // Synchronous mode lives inside this function.  There are many Python-esque things that users might
    // like to do, but they don't really work when you need to await.  You can't await:
    //    - setting an attribute like a.name = "Ted"
    //    - anything with operators, like x = a.qty + 7
    //
    // So this function with closure exists to create a synchronous bit of code running isolated
    // with the PythonInterpreter actor.  Everythin is prepared at the beginning.  All the sysmbols are
    // ensured loaded.  For GIL Python, the GIL is setup correctly.  Every operation inside this closure
    // happens on SafePythonObject, and all the SafePythonObject methods use assumeIsolated.  So they'll
    // definitely fail outside this closure.  But inside the closure, do Python stuff.  Don't use await.
    public func withIsolatedContext<T>(
        _ body: @Sendable (isolated PythonInterpreter) throws -> T
    ) async throws -> T {
        logger.trace("withIsolatedContext called")
        do {
            try await readyGlobalSetups()
            return try withGILSynchronous {
                setupSafePythonObjectRegistry()
                try setupGlobals()
                defer {
                    cleanupSafePythonObjects()
                    clearGlobals()
                }
                return try body(self)
            }
        } catch let error as PythonError {
            // Transform safePythonException → pythonException so the caller gets
            // a normal async-friendly PythonError.
            if case .safePythonException(let safeObj) = error {
                let pythonObj = escapeFromIsolation(forSafeObj: safeObj)
                throw PythonError.pythonException(pythonObj)
            }
            
            // Re-throw any other PythonError unchanged
            throw error
        } catch {
            throw error
        }
    }
    
    // A GIL handler for synchronous mode
    public func withGILSynchronous<Result>(_ body: () throws -> Result) throws -> Result {
        
        // Manage the GIL
        let gstate = api.pythonGILState_Ensure()
        defer { api.pythonGILState_Release(gstate) }
        
        // All Python C API usage is now safe here.
        return try body()
    }
    
    
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
    
    // MARK: Module Import (synchronous mode)
    
    /// Synchronous overload of `import` — **only** call this inside `withIsolatedContext`.
    /// It returns a `SafePythonObject` that supports the full synchronous operator / subscript / attribute API.
    ///
    /// Example:
    /// ```swift
    /// try await interpreter.withIsolatedContext { iso in
    ///     let np = try iso.`import`("numpy", as: "np")
    ///     let arr = try np.array([1, 2, 3])   // synchronous call
    ///     np.pi = 3.14                        // synchronous attribute set
    /// }
    /// ```
    @available(*, noasync,
                message: "Use the async version `try await interpreter.import(...)` outside of withIsolatedContext. This synchronous version is only safe inside withIsolatedContext.")
    public func `import`(_ name: String, as alias: String? = nil) throws -> SafePythonObject {
        if let alias = alias {
            return try syncImportWithAlias(name, alias: alias)
        } else {
            return try syncImportStandard(name)
        }
    }
    
    private func syncImportStandard(_ name: String) throws -> SafePythonObject {
        logger.trace("import \(name) called for SafePythonObject (synchronous)")
        guard let ptr = try api.pythonImport_ImportModule(name) else {
            throw PythonError.nullPointer("Failed to import module: \(name)")
        }
        
        let id = registerSafePythonObject(ptr)
        let moduleObj =  SafePythonObject(interpreter: self, id: id)
        self.incrementHousekeepingRefCount(forSafeObj: moduleObj)
        return moduleObj
    }
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    private func syncAddModule(_ name: String) throws -> SafePythonObject {
        logger.trace("add module \(name) called for SafePythonObject (synchronous)")
        let modulePtr = try api.pythonImport_AddModule(name)!
        let moduleId = registerSafePythonObject(modulePtr)
        let moduleObj = SafePythonObject(interpreter: self, id: moduleId)
        self.incrementHousekeepingRefCount(forSafeObj: moduleObj, andAlsoPythonsRefCount: true)
        return moduleObj
    }
    
    private func syncImportWithAlias(_ name: String, alias: String) throws -> SafePythonObject {
        logger.trace("import \(name) as \(alias) called for SafePythonObject (synchronous)")
        let command = "import \(name) as \(alias)"
        try runSimpleString(pythonCode: command)
        return try syncGetObjectAttribute(main, alias)

    }
    
    public func runSimpleString(pythonCode: String) throws {
        logger.trace("runSimpleString called (synchronous)")
        let result = try api.pythonRun_SimpleString(pythonCode)
        guard result == 0 else {
            throw PythonError.stringConversionFailed("Python execution failed for: \(pythonCode)")
        }
    }
    
    // MARK: Subscript support (synchronous mode)
    // Subscript attribute operations in synchronous mode ----------
    
    internal func syncGetObjectAttribute(_ obj: SafePythonObject, _ name: String) throws -> SafePythonObject {
        logger.trace("get: 'object.attribute' called for SafePythonObject (synchronous)")
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        guard let attrPtr = try api.pythonObject_GetAttrString(objPtr, name) else {
            throw PythonError.nullPointer("Failed ")
        }
        let attrId = registerSafePythonObject(attrPtr)
        return SafePythonObject(interpreter: self, id: attrId)
    }
    
    internal func syncSetObjectAttribute(_ obj: SafePythonObject, _ name: String, _ value: SafePythonObject) throws {
        logger.trace("set: 'object.attribute = value' called for SafePythonObject (synchronous)")
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let valuePtr = getRegisteredPointer(forSafeObj: value)
        _ = try api.pythonObject_SetAttrString(objPtr, name, valuePtr)
    }
    
    internal func syncGetObjectItem(obj: SafePythonObject, key: [any SafePythonConvertible]) throws -> SafePythonObject {
        logger.trace("getItem: 'object[key]' called for SafePythonObject (synchronous)")
        let pyKeyPtr: UnsafeMutableRawPointer
        
        switch key.count {
        case 0:
            fatalError("Subscript with zero keys is not valid")
        case 1:
            let pyKey = try! key[0].toSafePythonObject(interpreter: self)
            pyKeyPtr = getRegisteredPointer(forSafeObj: pyKey)
        default:
            pyKeyPtr = try! syncCallCreateTuplePtr(from: key)
        }
        
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        
        guard let resultPtr = try api.pythonObject_GetItem(objPtr, pyKeyPtr) else {
            throw PythonError.nullPointer("Python subscript get failed")
        }
        
        let resultId = registerSafePythonObject(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncSetObjectItem(obj: SafePythonObject, key: [any SafePythonConvertible], newValue:SafePythonConvertible) throws {
        logger.trace("setItem: 'object[key] = newValue' called for SafePythonObject (synchronous)")
        let pyKeyPtr: UnsafeMutableRawPointer
        
        switch key.count {
        case 0:
            fatalError("Subscript with zero keys is not valid")
        case 1:
            let pyKey = try! key[0].toSafePythonObject(interpreter: self)
            pyKeyPtr = getRegisteredPointer(forSafeObj: pyKey)
        default:
            pyKeyPtr = try! syncCallCreateTuplePtr(from: key)
        }
        
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        
        let newValuePyObj = try! newValue.toSafePythonObject(interpreter: self)
        let newValuePtr = getRegisteredPointer(forSafeObj: newValuePyObj)
        
        _ = try api.pythonObject_SetItem(objPtr, pyKeyPtr, newValuePtr)
    }
    
}
