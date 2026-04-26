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
// TODO: logic operators and true/false checking in python objects
// TODO: tuples
// TODO: builtins
// TODO: python dict and sequence APIs
// TODO: PythonBytes -- create python bytes objects from swift
// TODO: exponent operator?
// TODO: modulus operator?
// TODO: custom ENV variables to find python
// TODO: dict support
// TODO: change the id <--> pointer stuff to a typecast of the pointer?
// TODO: All conversions should work in both PythonObject and SafePythonObject mode
// TODO: unbind or something to let SafePythonObject become a PythonObject at the end of the isolated closure?
// TODO: api for arithmetic on PythonObject since operators can't be async
// TODO: understand free threaded python
// TODO: SafePythonObject comparisons that throw -- they should also handle unbound
// TODO: Combine Unbound and bound comparisons and operators
// TODO: choose "Equal" or "Equals" for comparison function naming and only use one
// TODO: Use the InPlace Python APIs for InPlace just in case the operators are overloaded in python.
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
    
    private var pythonObjectRegistry: [PythonObjectUniqueID: UnsafeMutableRawPointer] = [:]
    private var pythonObjectSwiftRefCount: [PythonObjectUniqueID: Int] = [:]
    
    internal func registerPythonObjectPointer(_ ptr: UnsafeMutableRawPointer) -> PythonObjectUniqueID {
        let id = PythonObjectUniqueID(ptr)
        pythonObjectRegistry[id] = ptr
        pythonObjectSwiftRefCount[id] = 1
        return id
    }
    
    private func getRegisteredPythonObjectPointer(_ id: PythonObjectUniqueID) -> UnsafeMutableRawPointer? {
        return pythonObjectRegistry[id]
    }
    
    internal func getRegisteredPointer(forPythonObject: PythonObject) -> UnsafeMutableRawPointer? {
        return getRegisteredPythonObjectPointer(forPythonObject.id)
    }
    
    /// Decrements the Swift-side reference count.
    /// When it hits zero, it triggers the Python C-API DecRef.
    internal func releaseHandle(_ id: PythonObjectUniqueID) async throws {
        guard let count = pythonObjectSwiftRefCount[id] else { return }
        
        if count <= 1 {
//            if let ptr = pythonObjectRegistry[id] {
//                // Perform the actual Python cleanup
//                //try py_DecRef(ptr)
//            }
            pythonObjectRegistry.removeValue(forKey: id)
            pythonObjectSwiftRefCount.removeValue(forKey: id)
        } else {
            pythonObjectSwiftRefCount[id] = count - 1
        }
    }
    
    
    init() async throws {
        logger.trace("Preload all Python C API symbols.")
        self.api = try await Self.loadAllSymbols(using: runtime, logger)
    }
    
    internal var api: PreloadedPythonSymbols!  // Loaded in init
        
    // MARK: Python Errors
    
    
    // MARK: GIL handling (async mode)
    
    // A GIL handler for async mode
    public func withGIL<Result>(_ body: () async throws -> Result) async throws -> Result {
        
        // Manage the GIL
        let gstate = api.pythonGILState_Ensure()
        defer { api.pythonGILState_Release(gstate) }
        
        // All Python C API usage is now safe here.
        return try await body()
    }
    
    // MARK: Import support (async mode)
    
    /// Standard import using PyImport_ImportModule
    private func importStandard(_ name: String) async throws -> PythonObject {
        guard let ptr = try api.pythonImport_ImportModule(name) else {
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
        let result = try api.pythonRun_SimpleString(command)
        
        guard result == 0 else {
            throw PythonError.stringConversionFailed("Python execution failed for: \(command)")
        }
        
        // 2. Retrieve the alias from the __main__ module namespace
        return try await getFromMain(alias)
    }
    
    /// Internal helper to fetch an object from the Python __main__ scope
    private func getFromMain(_ attrName: String) async throws -> PythonObject {
        
        // AddModule returns a 'borrowed' reference to the __main__ module
        guard let mainModulePtr = try api.pythonImport_AddModule("__main__") else {
            throw PythonError.nullPointer("Could not access Python __main__ module")
        }
        
        // Get the attribute (the alias) from __main__
        guard let aliasPtr = try api.pythonObject_GetAttrString(mainModulePtr, attrName) else {
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
    
    
    
    // MARK: Attribute access (async mode)
    
    public func get(object: PythonObject, attribute: String) async throws -> PythonObject {
        let objPtr = getRegisteredPointer(forPythonObject: object)!
        
        return try withGIL {
            let valuePtr = try api.pythonObject_GetAttrString(objPtr, attribute)
            let id = registerPythonObjectPointer(valuePtr!)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    public func set(object: PythonObject, attribute: String, value: PythonObject) async throws {
        let objPtr = getRegisteredPointer(forPythonObject: object)!
        let valuePtr = getRegisteredPointer(forPythonObject: value)!
        
        try withGIL {
            _ = try api.pythonObject_SetAttrString(objPtr, attribute, valuePtr)
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
            default: try await throwPythonError()
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
            default: try await throwPythonError()
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
            default: try await throwPythonError()
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
            default: try await throwPythonError()
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
            default: try await throwPythonError()
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
            default: try await throwPythonError()
            }
        }
    }

    
    // MARK: -
    // MARK: SYNCHRONOUS MODE
    //
    
    
    // Isolated registry
    //internal var isolatedContextStack: Deque<[PythonObjectUniqueID: IsolatedLifecycleRecord]> = []
    internal var isolatedContextStack: Deque<IsolatedContextRegistry> = []
    
    
    
    
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
        do {
            return try withGIL {
                setupSafePythonObjectRegistry()
                defer {
                    cleanupSafePythonObjects()
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
    public func withGIL<Result>(_ body: () throws -> Result) throws -> Result {
        
        // Manage the GIL
        let gstate = api.pythonGILState_Ensure()
        defer { api.pythonGILState_Release(gstate) }
        
        // All Python C API usage is now safe here.
        return try body()
    }
    
    
    // MARK: Prepare for synchronous mode
    // No asynchronous loading of symbols, so they all need to be preloaded
    // at the beginning of synchronous mode.  They only load the first time
    // and are cached after that.
    
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
    
    @available(*, noasync, message: "Do not call in async context.  This is only safe to call inside withIsolatedContext.")
    public func bind(_ obj: PythonObject) -> PythonInterpreter.SafePythonObject {
        return SafePythonObject(interpreter: self, id: obj.id)
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
        logger.trace("CPython API call in synchronous mode: PyImport_ImportModule")
        guard let ptr = name.withCString({ api.PyImport_ImportModule($0) }) else {
            throw PythonError.nullPointer("Failed to import module: \(name)")
        }
        
        let id = registerSafePythonObject(ptr)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    private func syncGetFromMain(_ attrName: String) throws -> SafePythonObject {
        logger.trace("Synchronous getFromMain")
        
        logger.trace("CPython API call in synchronous mode: PyImport_AddModule")
        guard let mainModulePtr = "__main__".withCString({ api.PyImport_AddModule($0) }) else {
            throw PythonError.nullPointer("Could not access Python __main__ module")
        }
        
        guard let aliasPtr = try api.pythonObject_GetAttrString(mainModulePtr, attrName) else {
            throw PythonError.nullPointer("Alias '\(attrName)' not found in Python scope")
        }
        
        let id = registerSafePythonObject(aliasPtr)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    private func syncImportWithAlias(_ name: String, alias: String) throws -> SafePythonObject {
        logger.trace("Synchronous importWithAlias")
        
        // 1. Execute "import name as alias"
        let command = "import \(name) as \(alias)"
        let result = try api.pythonRun_SimpleString(command)
        
        guard result == 0 else {
            throw PythonError.stringConversionFailed("Python execution failed for: \(command)")
        }
        
        // 2. Retrieve the alias from __main__
        return try syncGetFromMain(alias)
    }
    
    // MARK: Subscript support (synchronous mode)
    // Subscript attribute operations in synchronous mode ----------
    
    internal func syncGetObjectAttribute(_ obj: SafePythonObject, _ name: String) throws -> SafePythonObject {
        let objPtr = getRegisteredPointer(forSafeObj:obj)
        guard let attrPtr = try api.pythonObject_GetAttrString(objPtr, name) else {
            throw PythonError.nullPointer("Failed ")
        }
        let attrId = registerSafePythonObject(attrPtr)
        return SafePythonObject(interpreter: self, id: attrId)
    }
    
    internal func syncSetObjectAttribute(_ obj: SafePythonObject, _ name: String, _ value: SafePythonObject) throws {
        let objPtr = getRegisteredPointer(forSafeObj: obj)
        let valuePtr = getRegisteredPointer(forSafeObj: value)
        _ = try api.pythonObject_SetAttrString(objPtr, name, valuePtr)
    }
    
    internal func syncGetObjectItem(obj: SafePythonObject, key: [any SafePythonConvertible]) throws -> SafePythonObject {
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
