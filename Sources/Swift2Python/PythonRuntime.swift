//
//  PythonRuntime.swift
//  Swift2Python
//
//  Created by Ben White on 2/23/26.
//

// PythonRuntime is a singleton because Python needs to be initialized
// once before it can be used.

import Logging
import Darwin
import Foundation

public struct SendableCPythonFunction<T>: @unchecked Sendable {
    public let function: T
    init(_ function: T) { self.function = function }
}

public actor PythonRuntime {
    
    private typealias PythonLibraryHandle = UnsafeMutableRawPointer
    private typealias PythonConfigHandle = OpaquePointer
    
    // ── Singleton access (lazy + thread-safe init)
    public static let shared = PythonRuntime()
    
    // ── Isolated state ───────────────────────────────────────────────
    private var isReady = false
    private var initError: Error? = nil
    
    private var pythonLibraryHandle: PythonLibraryHandle?
    public private(set) var isFreeThreaded: Bool = false
    public private(set) var version: (major: Int, minor: Int, micro: Int)?
    
    private let logger: Logger = Logger(label: "swift2python.PythonRuntime")
    
    private init() {}  // prevent external instantiation
    
    // Cached symbols (lazy-loaded inside actor)
    private var cachedSymbols: [String: Any] = [:]
    
    /// Converts a null-terminated `wchar_t*` from the Python C API to a Swift `String`.
    ///
    /// Handles platform differences:
    /// - Windows: wchar_t = 16-bit (UTF-16)
    /// - macOS/Linux/iOS: wchar_t = 32-bit (UTF-32)
    ///
    /// - Parameter ptr: Pointer to the wide-character string returned by Python
    /// - Returns: The decoded string, or throws if conversion fails
    private func wideCharToString(_ ptr: UnsafePointer<wchar_t>?) -> String? {
        guard let ptr = ptr else { return nil }
        let rawPtr = UnsafeRawPointer(ptr)

        #if os(Windows)
        // Windows: wchar_t is 16-bit (UTF-16)
        let codeUnits = rawPtr.assumingMemoryBound(to: UInt16.self)
        return String(decodingCString: codeUnits, as: UTF16.self)
        #else
        // macOS, Linux, iOS: wchar_t is 32-bit (UTF-32)
        let codeUnits = rawPtr.assumingMemoryBound(to: UInt32.self)
        return String(decodingCString: codeUnits, as: UTF32.self)
        #endif
    }
    
    
    // ── Darwin wrappers ───────────────────────────────────────────────
    private func dlsymWrapper(_ symbol: String) throws -> UnsafeMutableRawPointer? {
        guard let handle = pythonLibraryHandle else {
            throw PythonError.notInitialized
        }
        return symbol.withCString { dlsym(handle, $0) }
    }
    
//    // ── CPyton wrappers ───────────────────────────────────────────────
    
    public func py_DecRef(_ pointer: UnsafeMutableRawPointer) throws {
        logger.trace("CPyton wrapper called: py_DecRef")
        let decrementRefCount = try loadSymbol("Py_DecRef", as: (@convention(c) (UnsafeMutableRawPointer) -> Void).self)
        decrementRefCount(pointer)
    }
    
    private func py_FinalizeEx() throws -> CInt {
        logger.trace("CPyton wrapper called: py_FinalizeEx")
        let pyFinalize = try loadSymbol("Py_FinalizeEx", as: (@convention(c) () -> CInt).self)
        return pyFinalize()
    }
    
    private func py_GetExecPrefix() throws -> String? {
        logger.trace("CPython wrapper called: py_GetExecPrefix")
        // Signature: wchar_t* Py_GetExecPrefix(void);
        let fn = try loadSymbol("Py_GetExecPrefix", as: (@convention(c) () -> UnsafePointer<wchar_t>?).self)
        let ptr = fn()
        return wideCharToString(ptr)
    }
    
    private func py_GetPath() throws -> String? {
        logger.trace("CPython wrapper called: py_GetPath")
        // Signature: wchar_t* Py_GetPath(void);
        let fn = try loadSymbol("Py_GetPath", as: (@convention(c) () -> UnsafePointer<wchar_t>?).self)
        let ptr = fn()
        return wideCharToString(ptr)
    }

    private func py_GetPrefix() throws -> String? {
        logger.trace("CPython wrapper called: py_GetPrefix")
        // Signature: wchar_t* Py_GetPrefix(void);
        let fn = try loadSymbol("Py_GetPrefix", as: (@convention(c) () -> UnsafePointer<wchar_t>?).self)
        let ptr = fn()
        return wideCharToString(ptr)
    }
    
    private func py_GetProgramFullPath() throws -> String? {
        logger.trace("CPython wrapper called: py_GetProgramFullPath")
        // Signature: wchar_t* Py_GetProgramFullPath(void);
        let fn = try loadSymbol("Py_GetProgramFullPath", as: (@convention(c) () -> UnsafePointer<wchar_t>?).self)
        let ptr = fn()
        return wideCharToString(ptr)
    }
    
    private func py_GetProgramFName() throws -> String? {
        logger.trace("CPython wrapper called: py_GetProgramName")
        // Signature: wchar_t* py_GetProgramName(void);
        let fn = try loadSymbol("Py_GetProgramName", as: (@convention(c) () -> UnsafePointer<wchar_t>?).self)
        let ptr = fn()
        return wideCharToString(ptr)
    }
    
    private func py_Initialize() throws {
        logger.trace("CPyton wrapper called: py_Initialize")
        let pyInit = try loadSymbol("Py_Initialize", as: (@convention(c) () -> Void).self)
        pyInit()
    }
    
    private func py_IsInitialized() throws -> Bool {
        logger.trace("CPython wrapper called: py_IsInitialized")
        // The C signature is: int Py_IsInitialized(void);
        // Returns non-zero if initialized, zero otherwise.
        let pyIsInit = try loadSymbol("Py_IsInitialized", as: (@convention(c) () -> CInt).self)
        let result = pyIsInit()
        return result != 0
    }
    
    private func pyRun_SimpleString(_ code: String) throws -> CInt {
        logger.trace("CPyton wrapper called: pyRun_SimpleString")
        let pyExec = try loadSymbol("PyRun_SimpleString", as: (@convention(c) (UnsafePointer<CChar>?) -> CInt).self)
        return code.withCString { cStringPtr in
            pyExec(cStringPtr)
        }
    }
    
 
//    private func pyErr_Occurred() throws {
//        logger.trace("CPyton wrapper called: pyErr_Occurred")
//        let pyErrOccurred = try loadSymbol("PyErr_Occurred", as: (@convention(c) () -> UnsafeMutablePointer<PyObject>?).self)
//        pyErrOccurred()
//    }
//    
//    private func pyErr_Print() throws {
//        logger.trace("CPyton wrapper called: pyErr_Print")
//        let pyErrPrint = try loadSymbol("PyErr_Print", as: (@convention(c) () -> Void).self)
//        pyErrPrint()
//    }
//    
//    private func pyGILState_Ensure() throws -> PyGILState_STATE {
//        logger.trace("CPyton wrapper called: pyGILState_Ensure")
//        let fn = try loadSymbol("PyGILState_Ensure", as: (@convention(c) () -> PyGILState_STATE).self)
//        return fn()
//    }
//
//    private func pyGILState_Release(_ state: PyGILState_STATE) throws {
//        logger.trace("CPyton wrapper called: pyGILState_Release")
//        let fn = try loadSymbol("PyGILState_Release", as: (@convention(c) (PyGILState_STATE) -> Void).self)
//        fn(state)
//    }
//
//    public func pyMem_RawFree(_ ptr: UnsafeMutableRawPointer?) throws {
//        logger.trace("CPyton wrapper called: pyMem_RawFree")
//        guard let ptr else { return }
//        let pyFree = try loadSymbol("PyMem_RawFree", as: (@convention(c) (UnsafeMutableRawPointer?) -> Void).self)
//        pyFree(ptr)
//    }
    
    // ── Symbol loading (replaces PythonKit PythonLibrary.loadSymbol) ───────
    public func loadSymbol<T>(_ name: String, as type: T.Type = T.self) throws -> T {
        if let cached = cachedSymbols[name] as? T {
            return cached
        }
            
        logger.debug("Loading symbol: \(name)")
            
        // Platform-specific dlsym wrapper (implement per macOS/Linux/Windows)
        guard let rawPtr = try dlsymWrapper(name) else {
            throw PythonError.symbolNotFound(name)
        }
            
        let fn = unsafeBitCast(rawPtr, to: T.self)
        cachedSymbols[name] = fn
            
        return fn
    }
    
    public func loadSendableSymbol<T>(_ name: String, as type: T.Type) throws -> SendableCPythonFunction<T> {
        let fn: T = try loadSymbol(name, as: T.self)
        return SendableCPythonFunction(fn)
    }
    
    private static func loadPythonLibrary(path: String?) throws -> PythonLibraryHandle {
        // Implement dlopen logic here (fallback to common locations, env vars, etc.)
        // Example stub:
        let candidatePaths = path.map { [$0] } ?? defaultPythonLibraryPaths()
        for p in candidatePaths {
            if let h = dlopen(p, RTLD_LAZY | RTLD_GLOBAL) {
                return h
            }
        }
        throw PythonError.libraryNotFound
    }
    
    private static func defaultPythonLibraryPaths() -> [String] {
        // macOS: /opt/homebrew/bin/python3.14 → libpython3.14.dylib, etc.
        // Linux: /usr/lib/libpython3.14.so
        // Windows: python314.dll
        []
    }
    
    private func detectFreeThreadedMode() throws -> Bool {
        return false
    }
    
    private func detectPythonVersion() throws -> Bool {
        return false
    }
    
    private func performInitialization(libraryPath: String? = nil) async throws {
        logger.debug("Initializing Python runtime...")
        
        // 1. Load the shared library
        self.pythonLibraryHandle = try Self.loadPythonLibrary(path: libraryPath)
        
        //
        // Calls Py_Initialize() instead of Py_InitializeFromConfig() because Py_InitializeFromConfig()
        // code is python version dependent and Skill2Python is meant to work across different python versions.
        //
        // Output a lot of info to help debugging if Py_Initialize calls exit()
        let env = ProcessInfo.processInfo.environment
        logger.debug("About to call Py_Initialize(). Here's some useful debug info if it calls exit:")
        logger.debug("PYTHONHOME=\(env["PYTHONHOME"] ?? "<not set>")")
        logger.debug("PYTHONPATH=\(env["PYTHONPATH"] ?? "<not set>")")
        logger.debug("PYTHONDEBUG=\(env["PYTHONDEBUG"] ?? "<not set>")")
        logger.debug("PYTHONDONTWRITEBYTECODE=\(env["PYTHONDONTWRITEBYTECODE"] ?? "<not set>")")
        logger.debug("PYTHONNOUSERSITE=\(env["PYTHONNOUSERSITE"] ?? "<not set>")")
        logger.debug("PYTHONUSERBASE=\(env["PYTHONUSERBASE"] ?? "<not set>")")
        logger.debug("PYTHONIOENCODING=\(env["PYTHONIOENCODING"] ?? "<not set>")")
        logger.debug("PYTHONUTF8=\(env["PYTHONUTF8"] ?? "<not set>")")
        logger.debug("PYTHONVERBOSE=\(env["PYTHONVERBOSE"] ?? "<not set>")")
        logger.debug("PYTHONCASEOK=\(env["PYTHONCASEOK"] ?? "<not set>")")
        logger.debug("PYTHONMALLOC=\(env["PYTHONMALLOC"] ?? "<not set>")")
        logger.debug("PYTHONCOERCECLOCALE=\(env["PYTHONCOERCECLOCALE"] ?? "<not set>")")
        logger.debug("PYTHONSAFEPATH=\(env["PYTHONSAFEPATH"] ?? "<not set>")")
        logger.debug("PYTHONGIL=\(env["PYTHONGIL"] ?? "<not set>")")
        logger.debug("PATH=\(env["PATH"] ?? "<not set>")")
        logger.debug("CWD: \(FileManager.default.currentDirectoryPath)")
        logger.debug("Swift process executable: \(CommandLine.arguments.first ?? "unknown")")
        // Add python path here
        try py_Initialize()
        
        // Load the finalize function because we need it for deinit
        _ = try loadSymbol("Py_FinalizeEx", as: (@convention(c) () -> CInt).self)
        
        self.version = try detectPythonVersion()
        
        self.isFreeThreaded = try detectFreeThreadedMode()
        
        isReady = true
        logger.debug("Python \(version!.major).\(version!.minor).\(version!.micro) initialized – free-threaded: \(isFreeThreaded)")
    }
    
    public func initialize(libraryPath: String? = nil) async throws {
        logger.debug("Explicit call to PythonRuntime.initialize()")
        guard !isReady else {
            logger.error("Python initiaztion is only supposed to be performed once.")
            return
        }
        guard initError == nil else { throw initError! }
                
        try await performInitialization(libraryPath: libraryPath)
    }
    
    public func initializeIfNeeded(libraryPath: String? = nil) async throws {
        guard !isReady else { return }
        guard initError == nil else { throw initError! }
        logger.info("Python runtime lazy initialization...")
        
        try await performInitialization(libraryPath: libraryPath)
    }
    
    deinit {
        if isReady {
            logger.warning("Attempting PythonRuntime automatic deinitialization.  Calling finalize() is preferred.")
            if let pyFinalizeFunc = cachedSymbols["Py_FinalizeEx"] as? (@convention(c) () -> CInt) {
                let status = pyFinalizeFunc()
                if status < 0 {
                    logger.error("Py_FinalizeEx returned error status: \(status)")
                } else if status > 0 {
                    logger.warning("Py_FinalizeEx returned non-zero status: \(status) (may indicate unclean shutdown)")
                } else {
                    logger.debug("Py_FinalizeEx succeeded (status 0)")
                }
                
            } else {
                logger.error("Unable to call Py_FinalizeEx in automatic deinitialization.")
            }
        }
        
        cachedSymbols.removeAll()
        
        if let handle = pythonLibraryHandle {
            dlclose(handle)
            pythonLibraryHandle = nil
        }
        isReady = false
    }
    
    public func finalize() throws {
        guard isReady else { return }
        logger.info("Finalizing Python runtime...")
        
        let status = try py_FinalizeEx()
        if status < 0 {
            throw PythonError.finalizationFailed(status: status)
        }
        
        isReady = false
        if let handle = pythonLibraryHandle {
            dlclose(handle)
            pythonLibraryHandle = nil
        }
        cachedSymbols.removeAll()
    }
    
}

