//
//  PythonError.swift
//  Swift2Python
//
//  Created by Ben White on 2/23/26.
//

import Foundation

/// Errors thrown by the Swift2Python package when interacting with the Python runtime.
public enum PythonError: Error, CustomStringConvertible, LocalizedError {
    
    case notInitialized
    case alreadyInitialized
    case libraryNotFound
    case symbolNotFound(String)
    case allocationFailed(String)
    case nullPointer(String)
    case stringConversionFailed(String)
    
    // ── Finalization-specific case ───────────────────────────────────────────
    /// `Py_FinalizeEx()` returned a non-zero status during shutdown.
    /// - Parameter status: The exact return value from `Py_FinalizeEx()`
    ///   - `0`     = success (should not throw)
    ///   - `> 0`   = unclean shutdown (e.g. unhandled exceptions during atexit)
    ///   - `< 0`   = serious error (rare)
    case finalizationFailed(status: CInt)
    case unknownPythonException
    indirect case pythonException(PythonObject)
    indirect case safePythonException(PythonInterpreter.SafePythonObject)
    
    
    /// Thrown when a Swift value cannot be safely converted to/from a Python object
    /// because it is out of range for the target type (e.g. 2000 → UInt8).
    case conversionOverflow(value: String, sourceType: String, targetType: String )
    indirect case conversionType( value: String, sourceType: String, targetType: String, underlying: PythonError? = nil)
    case typeError(operation: String, opType1: String, opType2: String )
    
    
    // MARK: - CustomStringConvertible
        
    public var description: String {
        switch self {
        case .notInitialized:
            return "Python runtime not initialized"
        case .alreadyInitialized:
            return "Python runtime already initialized"
        case .libraryNotFound:
            return "Could not load libpython shared library"
        case .symbolNotFound(let name):
            return "Symbol not found in libpython: \(name)"
        case .allocationFailed(let context):
            return "Memory allocation failed: \(context)"
        case .nullPointer(let context):
            return "Python C API returned NULL pointer: \(context)"
        case .stringConversionFailed(let context):
            return "Failed to convert Python string (wchar_t*) to Swift String: \(context)"
        case .finalizationFailed(let status):
            if status < 0 {
                return "Py_FinalizeEx failed with error status \(status) (serious shutdown error)"
            } else {
                return "Py_FinalizeEx returned warning status \(status) (unclean shutdown – check for unhandled exceptions or resource leaks)"
            }
        case .unknownPythonException:
            return "Python exception with no details."
        case .pythonException:
            return "Python exception (async)."  // FIXME: do better
        case .safePythonException:
            return "Python exception (synchronous)."  // FIXME: do better
        case .conversionOverflow(let value, let source, let target):
            return "Overflow error: value \(value) of type \(source) cannot be converted to \(target) (out of range)"
        case .conversionType(let value, let sourceType, let targetType, _ ):
            return "Conversion type error: value \(value) of type \(sourceType) cannot be converted to \(targetType)"
        case .typeError(let opType1, let opType2, let operation):
            return "Operation \(operation) is invalid between type \(opType1) and \(opType2)"
        }
    }
        
    // MARK: - LocalizedError
        
    public var errorDescription: String? {
        description
    }
        
    public var failureReason: String? {
        switch self {
        case .finalizationFailed(let status):
            if status < 0 {
                return "Python interpreter shutdown encountered a critical error."
            } else {
                return "Python interpreter did not shut down cleanly."
            }
        default:
            return nil
        }
    }
        
    // Optional: help provide recovery suggestion
    public var recoverySuggestion: String? {
        switch self {
        case .finalizationFailed:
            return "Call finalize() earlier in a controlled manner (e.g. on app exit). Check Python logs or stderr for details on pending exceptions."
        default:
            return nil
        }
    }
}

