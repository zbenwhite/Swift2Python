//
//  PythonError.swift
//  Swift2Python
//
//  Created by Ben White on 2/23/26.
//

import Foundation

/// A stable Swift snapshot of a Python exception.
///
/// Swift2Python captures this information while the Python exception is still
/// available under the GIL. That makes error descriptions useful after an async
/// throw or after a safe exception exits `withIsolatedContext`.
public struct PythonExceptionInfo: Sendable, CustomStringConvertible {
    /// The Python exception type name, such as `TypeError` or `ModuleNotFoundError`.
    public let typeName: String

    /// The Python exception message, usually equivalent to `str(exception)`.
    public let message: String

    /// The formatted Python traceback and exception chain, if Python provided one.
    public let traceback: String?

    /// The full formatted exception text.
    public let formatted: String

    public init(typeName: String, message: String, traceback: String? = nil) {
        self.typeName = typeName
        self.message = message
        self.traceback = traceback?.isEmpty == true ? nil : traceback

        let headline: String
        if message.isEmpty {
            headline = "Python exception: \(typeName)"
        } else {
            headline = "Python exception: \(typeName): \(message)"
        }

        if let traceback = self.traceback, !traceback.isEmpty {
            self.formatted = "\(headline)\n\(traceback)"
        } else {
            self.formatted = headline
        }
    }

    public var description: String { formatted }
}

/// Errors thrown by the Swift2Python package when interacting with the Python runtime.
public enum PythonError: Error, CustomStringConvertible, LocalizedError {
    
    case notInitialized
    case alreadyInitialized
    case libraryNotFound
    case symbolNotFound(String)
    case allocationFailed(String)
    case nullPointer(String)
    case stringConversionFailed(String)
    case unsupportedPythonFeature(feature: String, requiredSymbols: [String])
    case objectUsedWithWrongInterpreter
    
    // ── Finalization-specific case ───────────────────────────────────────────
    /// `Py_FinalizeEx()` returned a non-zero status during shutdown.
    /// - Parameter status: The exact return value from `Py_FinalizeEx()`
    ///   - `0`     = success (should not throw)
    ///   - `> 0`   = unclean shutdown (e.g. unhandled exceptions during atexit)
    ///   - `< 0`   = serious error (rare)
    case finalizationFailed(status: CInt)
    case unknownPythonException
    indirect case pythonException(PythonObject, info: PythonExceptionInfo)
    indirect case safePythonException(PythonInterpreter.SafePythonObject, info: PythonExceptionInfo)
    
    
    /// Thrown when a Swift value cannot be safely converted to/from a Python object
    /// because it is out of range for the target type (e.g. 2000 → UInt8).
    case conversionOverflow(value: String, sourceType: String, targetType: String )
    indirect case conversionType( value: String, sourceType: String, targetType: String, underlying: PythonError? = nil)
    case bytesConversionFailed(expected: String, actual: String?)
    case dictionaryConversionFailed(expected: String, actual: String?)
    case listConversionFailed(expected: String, actual: String?)
    case setConversionFailed(expected: String, actual: String?)
    case tupleConversionFailed(expected: String, actual: String?)
    case tupleArityMismatch(expected: Int, actual: Int)
    case typeError(operation: String, opType1: String, opType2: String )
    case valueError(String)
    case divideByZero
    
    /// Metadata captured from a Python exception, if this error wraps one.
    public var pythonExceptionInfo: PythonExceptionInfo? {
        switch self {
        case .pythonException(_, let info), .safePythonException(_, let info):
            return info
        case .conversionType(_, _, _, let underlying):
            return underlying?.pythonExceptionInfo
        default:
            return nil
        }
    }
    
    // MARK: - CustomStringConvertible
        
    public var description: String {
        switch self {
        case .notInitialized:
            return "Python runtime not initialized"
        case .alreadyInitialized:
            return "Python runtime already initialized"
        case .libraryNotFound:
            return "Could not load libpython shared library. Set SWIFT2PYTHON_LIBRARY to the full path of the libpython shared library."
        case .symbolNotFound(let name):
            return "Symbol not found in libpython: \(name)"
        case .allocationFailed(let context):
            return "Memory allocation failed: \(context)"
        case .nullPointer(let context):
            return "Python C API returned NULL pointer: \(context)"
        case .stringConversionFailed(let context):
            return "Failed to convert Python string (wchar_t*) to Swift String: \(context)"
        case .unsupportedPythonFeature(let feature, let requiredSymbols):
            return "Unsupported Python feature: \(feature) requires CPython symbols not available in the loaded libpython: \(requiredSymbols.joined(separator: ", "))"
        case .objectUsedWithWrongInterpreter:
            return "Python object was used with a different PythonInterpreter than the one that created it."
        case .finalizationFailed(let status):
            if status < 0 {
                return "Py_FinalizeEx failed with error status \(status) (serious shutdown error)"
            } else {
                return "Py_FinalizeEx returned warning status \(status) (unclean shutdown - check for unhandled exceptions or resource leaks)"
            }
        case .unknownPythonException:
            return "Python exception with no details."
        case .pythonException(_, let info), .safePythonException(_, let info):
            return info.description
        case .conversionOverflow(let value, let source, let target):
            return "Overflow error: value \(value) of type \(source) cannot be converted to \(target) (out of range)"
        case .conversionType(let value, let sourceType, let targetType, let underlying):
            var text = "Conversion type error: value \(value) of type \(sourceType) cannot be converted to \(targetType)"
            if let underlying {
                text += "\nUnderlying error: \(underlying.description)"
            }
            return text
        case .bytesConversionFailed(let expected, let actual):
            if let actual {
                return "Bytes conversion failed: expected \(expected), got \(actual)"
            } else {
                return "Bytes conversion failed: expected \(expected)"
            }
        case .dictionaryConversionFailed(let expected, let actual):
            if let actual {
                return "Dict conversion failed: expected \(expected), got \(actual)"
            } else {
                return "Dict conversion failed: expected \(expected)"
            }
        case .listConversionFailed(let expected, let actual):
            if let actual {
                return "List conversion failed: expected \(expected), got \(actual)"
            } else {
                return "List conversion failed: expected \(expected)"
            }
        case .setConversionFailed(let expected, let actual):
            if let actual {
                return "Set conversion failed: expected \(expected), got \(actual)"
            } else {
                return "Set conversion failed: expected \(expected)"
            }
        case .tupleConversionFailed(let expected, let actual):
            if let actual {
                return "Tuple conversion failed: expected \(expected), got \(actual)"
            } else {
                return "Tuple conversion failed: expected \(expected)"
            }
        case .tupleArityMismatch(let expected, let actual):
            return "Tuple arity mismatch: expected \(expected) elements, got \(actual)"
        case .typeError(let operation, let opType1, let opType2):
            return "Operation \(operation) is invalid between type \(opType1) and \(opType2)"
        case .valueError(let message):
            return "Value error: \(message)"
        case .divideByZero:
            return "Attempted to divide by zero."
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
        case .pythonException(_, let info), .safePythonException(_, let info):
            return info.message.isEmpty ? info.typeName : "\(info.typeName): \(info.message)"
        default:
            return nil
        }
    }
        
    public var recoverySuggestion: String? {
        switch self {
        case .finalizationFailed:
            return "Call finalize() earlier in a controlled manner (e.g. on app exit). Check Python logs or stderr for details on pending exceptions."
        case .unsupportedPythonFeature:
            return "Use a Python runtime that exports the required Stable ABI symbols, or avoid this feature with the selected runtime."
        case .objectUsedWithWrongInterpreter:
            return "Use PythonObject values only with their owning PythonInterpreter."
        default:
            return nil
        }
    }
}
