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

public typealias PyThreadState = OpaquePointer

public actor PythonRuntime {
    
    // ── Singleton access
    public static let shared = PythonRuntime()
    private init() {}  // prevent external instantiation
    
    private let logger: Logger = Logger(label: "swift2python.PythonRuntime")
    

    // MARK: Loading Symbols
    
    // Cached symbols (lazy-loaded inside actor)
    private var cachedSymbols: [String: Any] = [:]
    
    // ── Darwin wrappers ───────────────────────────────────────────────
    private func dlsymWrapper(_ symbol: String) throws -> UnsafeMutableRawPointer? {
        guard let handle = pythonLibraryHandle else {
            throw PythonError.notInitialized
        }
        return symbol.withCString { dlsym(handle, $0) }
    }
    
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
    
    public struct SendableCPythonFunction<T>: @unchecked Sendable {
        public let function: T
        init(_ function: T) { self.function = function }
    }
    
    public func loadSendableSymbol<T>(_ name: String, as type: T.Type) throws -> SendableCPythonFunction<T> {
        let fn: T = try loadSymbol(name, as: T.self)
        return SendableCPythonFunction(fn)
    }
    
    
    private typealias PythonLibraryHandle = UnsafeMutableRawPointer
    private var pythonLibraryHandle: PythonLibraryHandle?
    
    
    private struct SendablePythonLibHandle: @unchecked Sendable {
        public let handle: PythonLibraryHandle
        init(_ handle: PythonLibraryHandle) { self.handle = handle }
    }
    
    private var _sendablePythonLibraryHandle: SendablePythonLibHandle? = nil
    
    private static func loadPythonLibrary(path: String?, logger: Logger) throws -> PythonLibraryHandle {
        // Implement dlopen logic here (fallback to common locations, env vars, etc.)
        // Example stub:
        let candidatePaths = path.map { [$0] } ?? defaultPythonLibraryPaths()
        for p in candidatePaths {
            logger.trace("Checking path \(p) ...")
            if let h = dlopen(p, RTLD_LAZY | RTLD_GLOBAL) {
                logger.trace("... found.")
                return h
            } else {
                logger.trace("... not found.")
            }
        }
        throw PythonError.libraryNotFound
    }
    
    // MARK: Finding Python library
    
    private static func currentUVArchitecture() -> String {
        var uts = utsname()
        uname(&uts)
        
        let machine = withUnsafePointer(to: &uts.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
        
        // Convert to what uv expects
        return machine == "arm64" ? "aarch64" : "x86_64"
    }
    
    private static func currentUVPlatformOS() -> String {
        #if os(macOS)
            return "macos"
        #else
            return "linux"   // adjust as needed
        #endif
    }
    
    private static func defaultPythonLibraryPaths() -> [String] {
        var paths: [String] = []

        // Common Homebrew locations (Apple Silicon & Intel)
        let brewPrefixes = [
            "/opt/homebrew",
            "/usr/local"
        ]

        let versions = ["3.13", "3.14", "3.12", "3.11"]  // newest first

        for prefix in brewPrefixes {
            for ver in versions {
                let dotted = ver.replacingOccurrences(of: ".", with: "")
                paths.append("\(prefix)/opt/python@\(ver)/Frameworks/Python.framework/Versions/\(ver)/lib/libpython\(ver).dylib")
                paths.append("\(prefix)/opt/python@\(ver)/lib/libpython\(ver).dylib")
                paths.append("\(prefix)/Cellar/python@\(ver)/\(ver).*/Frameworks/Python.framework/Versions/\(ver)/lib/libpython\(ver).dylib")
                paths.append("\(prefix)/lib/libpython\(dotted).dylib")
                paths.append("\(prefix)/lib/libpython\(ver).dylib")
            }
        }
        
        // UV pythons
        let uvRoot = FileManager.default.homeDirectoryForCurrentUser.path
        let uvPrefix = "\(uvRoot)/.local/share/uv/python"
        
        let arch = currentUVArchitecture()
        let os = currentUVPlatformOS()
        
        for ver in versions {
            paths.append("\(uvPrefix)/cpython-\(ver)-\(os)-\(arch)-none/lib/libpython\(ver).dylib")
        }

        // System Python (macOS) – usually not full-featured, but sometimes useful
        paths.append("/Library/Frameworks/Python.framework/Versions/3.13/lib/libpython3.13.dylib")

        // Last resort: assume python3-config --ldflags gives us clues
        return paths
    }
    
//    private func detectFreeThreadedMode() throws -> Bool {
//        let sys = try PythonRuntime.import("sys")
//
//        if let isGilEnabled = sys._is_gil_enabled {
//            // Callable → free-threaded capable build
//            let gilEnabled = Bool(isGilEnabled()) ?? true
//            return !gilEnabled  // true = free-threaded mode active (GIL off)
//        }
//
//        // Fallback for detection of capability
//        let versionStr = String(sys.version)
//        return versionStr.lowercased().contains("free-threading")
//    }
//
    
    // MARK: Python Version stuff
    
    public private(set) var version: (major: Int, minor: Int, micro: Int)?
    
    private func py_GetVersion() throws -> String? {
        logger.trace("CPython wrapper called: py_GetVersion")
        // The C signature is: const char *Py_GetVersion(void);
        let getVersion = try loadSymbol("Py_GetVersion", as: (@convention(c) () -> UnsafePointer<CChar>?).self)
        if let cString = getVersion() {
            return String(cString: cString)
        }
        else {
            return nil
        }
    }
    
    private func detectPythonVersion() throws {
        logger.trace("detectPythonVersion() called.")
        guard let versionString = try py_GetVersion() else {
            logger.error("Python version string not returned by py_GetVersion() ")
            return
        }
        
        logger.trace("py_GetVersion() raw string: \(versionString)")
        
        // Take only the first token (up to first space)
        guard let versionPart = versionString.split(separator: " ").first else {
            logger.error("Python version string expected to start with version: \(versionString)")
            return
        }
            
        // Split on dots: "3.13.1" → ["3", "13", "1"]
        let components = versionPart.split(separator: ".").map { String($0) }
            
        guard components.count >= 2,
              let major = Int(components[0]),
              let minor = Int(components[1])
        else {
            logger.error("Python version string expected to start with version in the form major.minor.micro: \(versionString)")
            return
        }
            
        // Micro is optional in some dev builds (e.g. "3.14.0a5+"), treat as 0 if missing
        let micro: Int
        if components.count >= 3 {
            // Strip any trailing non-digits (like "0a5+" → try "0")
            let microStr = components[2].prefix(while: { $0.isNumber })
            micro = Int(microStr) ?? 0
        } else {
            micro = 0
        }
        
        self.version = (major, minor, micro)
        logger.debug("Detected Python version from C API: \(major).\(minor).\(micro)")
    }
    
    /// The major, minor, micro version tuple of the loaded Python interpreter,
    /// or `nil` if initialization has not yet succeeded or failed.
    public var pythonVersion: (major: Int, minor: Int, micro: Int)? {
        version
    }

    /// A convenience string in the form "3.13.0" (or similar).
    /// Returns `nil` if version has not been detected.
    public var pythonVersionString: String? {
        guard let v = version else { return nil }
        return "\(v.major).\(v.minor).\(v.micro)"
    }
    
    // MARK: Initialize and Finalize
    
    private var isReady = false
    
    private var initTask: Task<Void, Swift.Error>? = nil
    
    // Special stuff only initialization and deinitialization.
    // A bunch of stuff needs to be sendable because it needs to be run on specific threads
    
    
    // Store this because deinit calls it and it must be sendable
    private var _sendablePyEval_RestoreThread: SendableCPythonFunction<@convention(c) (PyThreadState?) -> Void>? = nil
    private var _sendablePyFinalizeEx: SendableCPythonFunction<@convention(c) () -> CInt>? = nil
    
    
    private struct SendableThreadState: @unchecked Sendable {
        public let state: PyThreadState
        init(_ state: PyThreadState) { self.state = state }
    }
    
    private var _sendablePythonThreadState: SendableThreadState? = nil
    
    public func initialize(libraryPath: String? = nil) async throws {
        logger.debug("Explicit call to PythonRuntime.initialize()")
        
        // 1. Fast path: already successfully initialized
        if isReady {
            logger.error("Python initiaztion is only supposed to be performed once.")
            return
        }
        
        // 2. Prevent re-entrancy: If initialization is already running, just wait for it.
        if let existingTask = initTask {
            try await existingTask.value
            return
        }
        
        // 3. Create the initialization task
        let task = Task {
            try await self._performInitialization(libraryPath: libraryPath)
        }
        
        // 4. Store it so other concurrent callers will await it
        self.initTask = task
        
        // 5. Wait for the task to finish, then clean up
        do {
            try await task.value
            self.initTask = nil
            self.isReady = true
        } catch {
            self.initTask = nil
            throw error
        }
    }
    
    
    private func _performInitialization(libraryPath: String?) async throws {
        // Load the shared library
        self.pythonLibraryHandle = try Self.loadPythonLibrary(path: libraryPath, logger: logger)
        // Save it for running on deinit thread
        if let pythonLibraryHandle = self.pythonLibraryHandle {
            self._sendablePythonLibraryHandle = SendablePythonLibHandle(pythonLibraryHandle)
        }
        
        // Save these for deinitialization/finalize
        self._sendablePyFinalizeEx = try loadSendableSymbol("Py_FinalizeEx", as: (@convention(c) () -> CInt).self)
        self._sendablePyEval_RestoreThread = try loadSendableSymbol("PyEval_RestoreThread", as: (@convention(c) (PyThreadState?) -> Void).self)
        
        
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
        
        
        // Initialization + SaveThread must be on main thread
        let pyInitSendable = try loadSendableSymbol("Py_Initialize", as: (@convention(c) () -> Void).self)
        let pyEvalSaveThreadSendable = try loadSendableSymbol("PyEval_SaveThread", as: (@convention(c) () -> PyThreadState?).self)
        self._sendablePythonThreadState = await MainActor.run {
            
            logger.debug("Calling Py_Initialize on main thread...")
            pyInitSendable.function()
            
            logger.debug("Calling PyEval_SaveThread on main thread...")
            let threadState = pyEvalSaveThreadSendable.function()
            
            // Return the thread state for deinitialization/finalize
            return SendableThreadState(threadState!)
        }

        try detectPythonVersion()
        isReady = true
    }
    
    /// Whether the Python runtime has been successfully initialized.
    public var isInitialized: Bool {
        isReady
    }
    
    deinit {
        if isReady {
            logger.warning("Attempting PythonRuntime automatic deinitialization.  Calling finalize() is preferred.")
            
            if let ts = self._sendablePythonThreadState?.state , let pyRestoreThread = _sendablePyEval_RestoreThread?.function {
                pyRestoreThread(ts)
                logger.debug("Restored main thread state in deinit")
            }
            
            if let pyFinalizeFunc = _sendablePyFinalizeEx?.function {
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
        
        if let handle = self._sendablePythonLibraryHandle?.handle {
            dlclose(handle)
        }
        isReady = false
    }
    
    public func finalize() async throws {
        guard isReady else { return }
        logger.info("Finalizing Python runtime...")
        
        if let ts = self._sendablePythonThreadState?.state , let pyRestoreThread = _sendablePyEval_RestoreThread?.function {
            await MainActor.run {
                logger.debug("Call PyEval_RestoreThread on main thread")
                pyRestoreThread(ts)
            }
        }
        
        if let pyFinalizeFunc = _sendablePyFinalizeEx?.function {
            let status = pyFinalizeFunc()
            if status < 0 {
                logger.error("Py_FinalizeEx returned error status: \(status)")
            } else if status > 0 {
                logger.warning("Py_FinalizeEx returned non-zero status: \(status) (may indicate unclean shutdown)")
            } else {
                logger.debug("Py_FinalizeEx succeeded (status 0)")
            }
        }
        
        isReady = false
        if let handle = pythonLibraryHandle {
            dlclose(handle)
            pythonLibraryHandle = nil
        }
        cachedSymbols.removeAll()
    }
    
}
