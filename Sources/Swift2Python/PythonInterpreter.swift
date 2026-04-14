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
        self.api = try await Self.loadAllSymbols(using: runtime)
    }
    
    
    // MARK: Pre-load API pointers
    
    private struct PreloadedPythonSymbols {
        let Py_DecRef: (@convention(c) (UnsafeMutableRawPointer) -> Void)
        let PyBool_FromLong: (@convention(c) (Int) -> UnsafeMutableRawPointer?)
        let PyBuffer_Release: (@convention(c) (UnsafeMutableRawPointer) -> Void)
        let PyBytes_Size: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyByteArray_Size: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyDict_New: (@convention(c) () -> UnsafeMutableRawPointer?)
        let PyDict_SetItem: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyErr_Clear:  (@convention(c) () -> Void)
        let PyErr_Fetch: (@convention(c) (UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> Void)
        let PyErr_NormalizeException: (@convention(c) (UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> Void)
        let PyErr_Occurred: (@convention(c) () -> UnsafeMutableRawPointer?)
        let PyFloat_AsDouble: (@convention(c) (UnsafeMutableRawPointer) -> Double)
        let PyFloat_FromDouble: (@convention(c) (Double) -> UnsafeMutableRawPointer?)
        let PyGILState_Ensure: (@convention(c) () -> PyGILState_STATE)
        let PyGILState_Release: (@convention(c) (PyGILState_STATE) -> Void)
        let PyImport_AddModule: (@convention(c) (UnsafePointer<CChar>) -> UnsafeMutableRawPointer?)
        let PyImport_ImportModule: (@convention(c) (UnsafePointer<CChar>) -> UnsafeMutableRawPointer?)
        let PyList_New: (@convention(c) (Int) -> UnsafeMutableRawPointer?)
        let PyList_SetItem: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32)
        let PyLong_AsLong: (@convention(c) (UnsafeMutableRawPointer) -> Int)
        let PyLong_AsLongLong: (@convention(c) (UnsafeMutableRawPointer) -> Int64)
        let PyLong_AsUnsignedLongLong: (@convention(c) (UnsafeMutableRawPointer) -> UInt64)
        let PyLong_FromLong: (@convention(c) (Int) -> UnsafeMutableRawPointer?)
        let PyLong_FromLongLong: (@convention(c) (Int64) -> UnsafeMutableRawPointer?)
        let PyLong_FromUnsignedLongLong: (@convention(c) (UInt64) -> UnsafeMutableRawPointer?)
        let PyNumber_Add: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_And: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceAdd: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceAnd: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceMultiply: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceOr: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceSubtract: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceTrueDivide: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceXor: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Invert: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Multiply: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Or: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Subtract: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_TrueDivide: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Xor: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyObject_Call: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyObject_CallObject: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyObject_GetAttrString: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?)
        let PyObject_GetBuffer: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer, Int32) -> Int32)
        let PyObject_GetItem: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyObject_RichCompare: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32) -> UnsafeMutableRawPointer?)
        let PyObject_RichCompareBool: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32) -> Int32)
        let PyObject_SetAttrString: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Int32)
        let PyObject_SetItem: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyObject_Str: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyRun_SimpleString: (@convention(c) (UnsafePointer<CChar>) -> Int32)
        let PyTuple_New: (@convention(c) (Int) -> UnsafeMutableRawPointer?)
        let PyTuple_SetItem: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32)
        let PyUnicode_AsUTF8AndSize: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<Py_ssize_t>?) -> UnsafePointer<CChar>?)
        let PyUnicode_FromStringAndSize: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?)

        // Optional (only present on Python >= 3.9)
        let PyObject_CallNoArgs: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        
        // Optional (only present on Python >= 3.12)
        let PyErr_GetRaisedException: (@convention(c) () -> UnsafeMutableRawPointer?)?
    }

    private var api: PreloadedPythonSymbols!  // Loaded in init
    
    private static func loadAllSymbols(using runtime: PythonRuntime) async throws -> PreloadedPythonSymbols {
        return PreloadedPythonSymbols(
            Py_DecRef: try await runtime.loadSendableSymbol(
                "Py_DecRef", as: (@convention(c) (UnsafeMutableRawPointer) -> Void).self).function,
            PyBool_FromLong: try await runtime.loadSendableSymbol(
                "PyBool_FromLong", as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self).function,
            PyBuffer_Release: try await runtime.loadSendableSymbol(
                "PyBuffer_Release", as: (@convention(c) (UnsafeMutableRawPointer) -> Void).self).function,
            PyBytes_Size: try await runtime.loadSendableSymbol(
                "PyBytes_Size", as: (@convention(c) (UnsafeMutableRawPointer) -> Int32).self).function,
            PyByteArray_Size: try await runtime.loadSendableSymbol(
                "PyByteArray_Size", as: (@convention(c) (UnsafeMutableRawPointer) -> Int32).self).function,
            PyDict_New: try await runtime.loadSendableSymbol(
                "PyDict_New", as: (@convention(c) () -> UnsafeMutableRawPointer?).self).function,
            PyDict_SetItem: try await runtime.loadSendableSymbol(
                "PyDict_SetItem", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyErr_Clear: try await runtime.loadSendableSymbol(
                "PyErr_Clear", as: (@convention(c) () -> Void).self).function,
            PyErr_Fetch: try await runtime.loadSendableSymbol(
                "PyErr_Fetch", as: (@convention(c) (UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> Void).self).function,
            PyErr_NormalizeException: try await runtime.loadSendableSymbol(
                "PyErr_NormalizeException", as: (@convention(c) (UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> Void).self).function,
            PyErr_Occurred: try await runtime.loadSendableSymbol(
                "PyErr_Occurred", as: (@convention(c) () -> UnsafeMutableRawPointer?).self).function,
            PyFloat_AsDouble: try await runtime.loadSendableSymbol(
                "PyFloat_AsDouble", as: (@convention(c) (UnsafeMutableRawPointer) -> Double).self).function,
            PyFloat_FromDouble: try await runtime.loadSendableSymbol(
                "PyFloat_FromDouble", as: (@convention(c) (Double) -> UnsafeMutableRawPointer?).self).function,
            PyGILState_Ensure: try await runtime.loadSendableSymbol(
                "PyGILState_Ensure", as: (@convention(c) () -> PyGILState_STATE).self).function,
            PyGILState_Release: try await runtime.loadSendableSymbol(
                "PyGILState_Release", as: (@convention(c) (PyGILState_STATE) -> Void).self).function,
            PyImport_AddModule: try await runtime.loadSendableSymbol(
                "PyImport_AddModule", as: (@convention(c) (UnsafePointer<CChar>) -> UnsafeMutableRawPointer?).self).function,
            PyImport_ImportModule: try await runtime.loadSendableSymbol(
                "PyImport_ImportModule", as: (@convention(c) (UnsafePointer<CChar>) -> UnsafeMutableRawPointer?).self).function,
            PyList_New: try await runtime.loadSendableSymbol(
                "PyList_New", as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self).function,
            PyList_SetItem: try await runtime.loadSendableSymbol(
                "PyList_SetItem", as: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyLong_AsLong: try await runtime.loadSendableSymbol(
                "PyLong_AsLong", as: (@convention(c) (UnsafeMutableRawPointer) -> Int).self).function,
            PyLong_AsLongLong: try await runtime.loadSendableSymbol(
                "PyLong_AsLongLong", as: (@convention(c) (UnsafeMutableRawPointer) -> Int64).self).function,
            PyLong_AsUnsignedLongLong: try await runtime.loadSendableSymbol(
                "PyLong_AsUnsignedLongLong", as: (@convention(c) (UnsafeMutableRawPointer) -> UInt64).self).function,
            PyLong_FromLong: try await runtime.loadSendableSymbol(
                "PyLong_FromLong", as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self).function,
            PyLong_FromLongLong: try await runtime.loadSendableSymbol(
                "PyLong_FromLongLong", as: (@convention(c) (Int64) -> UnsafeMutableRawPointer?).self).function,
            PyLong_FromUnsignedLongLong: try await runtime.loadSendableSymbol(
                "PyLong_FromUnsignedLongLong", as: (@convention(c) (UInt64) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Add: try await runtime.loadSendableSymbol(
                "PyNumber_Add", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_And: try await runtime.loadSendableSymbol(
                "PyNumber_And", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceAdd: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceAdd", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceAnd: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceAnd", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceMultiply: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceMultiply", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceOr: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceOr", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceSubtract: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceSubtract", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceTrueDivide: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceTrueDivide", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceXor: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceXor", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Invert: try await runtime.loadSendableSymbol(
                "PyNumber_Invert", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Multiply: try await runtime.loadSendableSymbol(
                "PyNumber_Multiply", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Or: try await runtime.loadSendableSymbol(
                "PyNumber_Or", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Subtract: try await runtime.loadSendableSymbol(
                "PyNumber_Subtract", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_TrueDivide: try await runtime.loadSendableSymbol(
                "PyNumber_TrueDivide", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Xor: try await runtime.loadSendableSymbol(
                "PyNumber_Xor", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyObject_Call: try await runtime.loadSendableSymbol(
                "PyObject_Call", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyObject_CallObject: try await runtime.loadSendableSymbol(
                "PyObject_CallObject", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyObject_GetAttrString: try await runtime.loadSendableSymbol(
                "PyObject_GetAttrString", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?).self).function,
            PyObject_GetBuffer: try await runtime.loadSendableSymbol(
                "PyObject_GetBuffer", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer, Int32) -> Int32).self).function,
            PyObject_GetItem: try await runtime.loadSendableSymbol(
                "PyObject_GetItem", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyObject_RichCompare: try await runtime.loadSendableSymbol(
                "PyObject_RichCompare", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32) -> UnsafeMutableRawPointer?).self).function,
            PyObject_RichCompareBool: try await runtime.loadSendableSymbol(
                "PyObject_RichCompareBool", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32) -> Int32).self).function,
            PyObject_SetAttrString: try await runtime.loadSendableSymbol(
                "PyObject_SetAttrString", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyObject_SetItem: try await runtime.loadSendableSymbol(
                "PyObject_SetItem", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyObject_Str: try await runtime.loadSendableSymbol(
                "PyObject_Str", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyRun_SimpleString: try await runtime.loadSendableSymbol(
                "PyRun_SimpleString", as: (@convention(c) (UnsafePointer<CChar>) -> Int32).self).function,
            PyTuple_New: try await runtime.loadSendableSymbol(
                "PyTuple_New", as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self).function,
            PyTuple_SetItem: try await runtime.loadSendableSymbol(
                "PyTuple_SetItem", as: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyUnicode_AsUTF8AndSize: try await runtime.loadSendableSymbol(
                "PyUnicode_AsUTF8AndSize", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<Py_ssize_t>?) -> UnsafePointer<CChar>?).self).function,
            PyUnicode_FromStringAndSize: try await runtime.loadSendableSymbol(
                "PyUnicode_FromStringAndSize", as: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?).self).function,

            // The ones below may be missing
            PyObject_CallNoArgs: (try? await runtime.loadSendableSymbol(
                "PyObject_CallNoArgs", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function),
            PyErr_GetRaisedException: (try? await runtime.loadSendableSymbol(
                "PyErr_GetRaisedException", as: (@convention(c) () -> UnsafeMutableRawPointer?).self).function)
        )
    }
    
    // MARK: Python C API wrappers
    
    private func py_DecRef(_ pointer: UnsafeMutableRawPointer) throws {
        logger.trace("CPyton API Call: Py_DecRef")
        api.Py_DecRef(pointer)
    }
    
    private func pyBool_FromLong(_ value: Bool) -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyBool_FromLong")
        return api.PyBool_FromLong(value ? 1 : 0)
    }
    
    private func pyBytes_Size(_ pointer: UnsafeMutableRawPointer) throws -> Int {
        logger.trace("CPyton API Call: PyBytes_Size")
        return Int(api.PyBytes_Size(pointer))
    }
    
    private func pyByteArray_Size(_ pointer: UnsafeMutableRawPointer) throws -> Int {
        logger.trace("CPyton API Call: PyByteArray_Size")
        return Int(api.PyByteArray_Size(pointer))
    }
    
    private func pyDict_New() throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton wrapper called: PyDict_New")
        return api.PyDict_New()
    }
    
    private func pyDict_SetItem(_ dictPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer, _ valuePtr: UnsafeMutableRawPointer) throws -> Int32 {
        logger.trace("CPyton API Call: PyDict_SetItem")
        // Signature: int PyDict_SetItem(PyObject *p, PyObject *key, PyObject *val)
        return api.PyDict_SetItem(dictPtr, keyPtr, valuePtr)
    }
    
    private func pyErr_Clear() throws {
        logger.trace("CPyton API Call: PyErr_Clear")
        api.PyErr_Clear()
    }
    
    private func pyErr_Occurred() throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyErr_Occurred")
        return api.PyErr_Occurred()
    }
    
    private func pyFloat_FromDouble(_ value: Double) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyFloat_FromDouble")
        return api.PyFloat_FromDouble(value)
    }
    
    private func pyFloat_AsDouble(_ pointer: UnsafeMutableRawPointer) -> Double {
        logger.trace("CPyton API Call: PyFloat_AsDouble")
        return api.PyFloat_AsDouble(pointer)
    }
    
    private func pyGILState_Ensure() -> PyGILState_STATE {
        logger.trace("CPyton API Call: PyGILState_Ensure")
        return api.PyGILState_Ensure()
    }
    
    private func pyGILState_Release(_ gstate: PyGILState_STATE) {
        logger.trace("CPyton API Call: PyGILState_Release")
        api.PyGILState_Release(gstate)
    }
    
    private func pyImport_AddModule(_ module: String) async throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyImport_AddModule")
        return module.withCString({ api.PyImport_AddModule($0) })
    }
    
    private func pyImport_ImportModule(_ module: String) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyImport_ImportModule")
        return module.withCString({ api.PyImport_ImportModule($0) })
    }
    
    private func pyList_New(_ length: Int) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyList_New")
        return api.PyList_New(length)
    }
    
    private func pyList_SetItem(_ listPtr: UnsafeMutableRawPointer, _ index: Int, _ valuePtr: UnsafeMutableRawPointer) throws -> Int32 {
        logger.trace("CPyton API Call: PyList_SetItem")
        return api.PyList_SetItem(listPtr, index, valuePtr)
    }
    
    private func pyLong_AsLong(_ valuePtr: UnsafeMutableRawPointer) throws -> Int {
        logger.trace("CPyton API Call: PyLong_AsLong")
        return api.PyLong_AsLong(valuePtr)
    }
    
    private func pyLong_AsLongLong(_ valuePtr: UnsafeMutableRawPointer) throws -> Int64 {
        logger.trace("CPyton API Call: PyLong_AsLongLong")
        return api.PyLong_AsLongLong(valuePtr)
    }
    
    private func pyLong_AsUnsignedLongLong(_ valuePtr: UnsafeMutableRawPointer) throws -> UInt64 {
        logger.trace("CPyton API Call: PyLong_AsUnsignedLongLong")
        return api.PyLong_AsUnsignedLongLong(valuePtr)
    }
    
    private func pyLong_FromLong(_ value: Int) -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyLong_FromLong")
        return api.PyLong_FromLong(value)
    }
    
    private func pyLong_FromLongLong(_ value: Int64) -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyLong_FromLongLong")
        return api.PyLong_FromLongLong(value)
    }
    
    private func pyLong_FromUnsignedLongLong(_ value: UInt64) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyLong_FromUnsignedLongLong")
        return api.PyLong_FromUnsignedLongLong(value)
    }
    
    private func pyObject_Call(_ callable: UnsafeMutableRawPointer, _ args: UnsafeMutableRawPointer, _ kwargs: UnsafeMutableRawPointer?) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyObject_Call")
        // Signature: PyObject *PyObject_Call(PyObject *callable, PyObject *args, PyObject *kwargs)
        return api.PyObject_Call(callable, args, kwargs)
    }
    
    private func pyObject_CallObject(_ objPtr: UnsafeMutableRawPointer, _ args: UnsafeMutableRawPointer? = nil) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyObject_CallObject")
        // Signature: PyObject* PyObject_CallObject(PyObject *callable_object, PyObject *args)
        return api.PyObject_CallObject(objPtr, args)
    }
    
    private func pyObject_GetAttrString(_ pointer: UnsafeMutableRawPointer, _ name: String) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyObject_GetAttrString")
        return api.PyObject_GetAttrString(pointer, name.withCString({ $0 }))
    }
    
    private func pyObject_GetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyObject_GetItem")
        return api.PyObject_GetItem(obPtr, keyPtr)
    }
    
    private func pyObject_SetAttrString(_ obPtr: UnsafeMutableRawPointer, _ name: String, _ rvalPtr: UnsafeMutableRawPointer) throws -> Int32? {
        logger.trace("CPyton API Call: PyObject_SetAttrString")
        return api.PyObject_SetAttrString(obPtr, name.withCString({ $0 }), rvalPtr)
    }
    
    private func pyObject_SetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer,
                                  _ rvalPtr: UnsafeMutableRawPointer) throws -> Int32? {
        logger.trace("CPyton API Call: PyObject_SetItem")
        return api.PyObject_SetItem(obPtr, keyPtr, rvalPtr)
    }
    
    private func pyObject_Str(_ obPtr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyObject_Str")
        return api.PyObject_Str(obPtr)
    }
    
    public func pyRun_SimpleString(_ command: String) throws -> Int32 {
        logger.trace("CPyton API Call: PyRun_SimpleString")
        return command.withCString { api.PyRun_SimpleString($0) }
    }
    
    private func pyTuple_New(_ length: Int) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyTuple_New")
        return api.PyTuple_New(length)
    }
    
    private func pyTuple_SetItem(_ tuple: UnsafeMutableRawPointer, _ index: Int, _ item: UnsafeMutableRawPointer) throws -> Int32 {
        logger.trace("CPyton API Call: PyTuple_SetItem")
        return api.PyTuple_SetItem(tuple, index, item)
    }
    
    private func pyUnicode_FromStringAndSize(_ st: String) throws -> UnsafeMutableRawPointer? {
        logger.trace("CPyton API Call: PyUnicode_FromStringAndSize")
        let cString = st.utf8CString
        return cString.withUnsafeBufferPointer { bufferPtr in
            api.PyUnicode_FromStringAndSize(bufferPtr.baseAddress, cString.count - 1)
        }
    }
    
    private func pyUnicode_AsUTF8AndSize(_ objPtr: UnsafeMutableRawPointer) throws -> (String)? {
        logger.trace("CPyton API Call: PyUnicode_AsUTF8AndSize")
        var size: Py_ssize_t = 0
        let utf8 = api.PyUnicode_AsUTF8AndSize(objPtr, &size)
        
        guard let utf8 else {
            return nil
        }
        return String(cString: utf8)
    }
    
    // MARK: Python Errors
    
    // This function assumes you already have the GIL.
    private func throwPythonErrorIfPresent() async throws {
        guard try pyErr_Occurred() != nil else { return }
        try await throwPythonError()
    }
    
    // This function assumes you already have the GIL.
    private func throwPythonError() async throws -> Never {
        if let pyGetRaisedException = api.PyErr_GetRaisedException {
            // Do it the new Python 3.12 way
            logger.trace("CPyton API Call: PyErr_GetRaisedException")
            if let exceptionPtr = pyGetRaisedException() {
                //defer { Py_DECREF(exc) }
                let id = registerPythonObjectPointer(exceptionPtr)
                let exception = PythonObject(id: id, interpreter: self)
                throw PythonError.pythonException(exception)            }
        } else {
            // Do it the old Python 3.11 or earlier way
            var excType: UnsafeMutableRawPointer? = nil
            var excValue: UnsafeMutableRawPointer? = nil
            var excTraceback: UnsafeMutableRawPointer? = nil
            
            logger.trace("CPyton API Call: PyErr_Fetch")
            api.PyErr_Fetch(&excType, &excValue, &excTraceback)
            if excType != nil || excValue != nil {
                
                logger.trace("CPyton API Call: PyErr_NormalizeException")
                api.PyErr_NormalizeException(&excType, &excValue, &excTraceback)
                if let valuePtr = excValue {
                    let id = registerPythonObjectPointer(valuePtr)
                    let exception = PythonObject(id: id, interpreter: self)
                    throw PythonError.pythonException(exception)
                } else if let typePtr = excType {
                    let id = registerPythonObjectPointer(typePtr)
                    let exception = PythonObject(id: id, interpreter: self)
                    throw PythonError.pythonException(exception)
                } else {
                    throw PythonError.unknownPythonException
                }
            }
        }
        throw PythonError.unknownPythonException
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    private func throwPythonErrorIfPresent() throws {
        guard try pyErr_Occurred() != nil else { return }
        try throwPythonError()
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    private func throwPythonError() throws -> Never {
        logger.trace("throwPythonError (synchronous)")
        if let pyGetRaisedException = api.PyErr_GetRaisedException {
            // Do it the new Python 3.12 way
            logger.trace("CPyton API Call: PyErr_GetRaisedException")
            if let exceptionPtr = pyGetRaisedException() {
                //defer { Py_DECREF(exc) }
                
                let id = registerPythonObjectPointer(exceptionPtr)
                let exception = SafePythonObject(interpreter: self, id: id)
                logger.warning("Python error: \(exception)")
                throw PythonError.safePythonException(exception)
            }
        } else {
            // Do it the old Python 3.11 or earlier way
            var excType: UnsafeMutableRawPointer? = nil
            var excValue: UnsafeMutableRawPointer? = nil
            var excTraceback: UnsafeMutableRawPointer? = nil
            
            logger.trace("CPyton API Call: PyErr_Fetch")
            api.PyErr_Fetch(&excType, &excValue, &excTraceback)
            if excType != nil || excValue != nil {
                
                logger.trace("CPyton API Call: PyErr_NormalizeException")
                api.PyErr_NormalizeException(&excType, &excValue, &excTraceback)
                if let valuePtr = excValue {
                    let id = registerPythonObjectPointer(valuePtr)
                    let exception = SafePythonObject(interpreter: self, id: id)
                    logger.warning("Python error: \(exception)")
                    throw PythonError.safePythonException(exception)
                } else if let typePtr = excType {
                    let id = registerPythonObjectPointer(typePtr)
                    let exception = SafePythonObject(interpreter: self, id: id)
                    logger.warning("Python error: \(exception)")
                    throw PythonError.safePythonException(exception)
                } else {
                    throw PythonError.unknownPythonException
                }
            }
        }
        throw PythonError.unknownPythonException
    }
    
    // MARK: GIL handling (async mode)
    
    // A GIL handler for async mode
    public func withGIL<Result>(_ body: () async throws -> Result) async throws -> Result {
        
        // Manage the GIL
        let gstate = pyGILState_Ensure()
        defer { pyGILState_Release(gstate) }
        
        // All Python C API usage is now safe here.
        return try await body()
    }
    
    
    /// Asynchronously decrements the reference count of a raw pointer.
    /// Called by PyPointer's deinit.
    func decrementRefCount(_ pointer: UnsafeMutableRawPointer) async throws {
        try py_DecRef(pointer)
    }
    
    // MARK: Import support (async mode)
    
    /// Standard import using PyImport_ImportModule
    private func importStandard(_ name: String) async throws -> PythonObject {
        guard let ptr = try pyImport_ImportModule(name) else {
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
        let result = try pyRun_SimpleString(command)
        
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
        guard let aliasPtr = try pyObject_GetAttrString(mainModulePtr, attrName) else {
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
    
    
    // MARK: Conversion of primative types (async mode)
    
    public func convertToPython(bool: Bool) async throws -> PythonObject {
        return try withGIL {
            guard let ptr = pyBool_FromLong(bool) else {
                throw PythonError.nullPointer("Failed to convert bool: \(bool)")
            }
            
            // Register the pointer in our actor's internal hashtable
            let id = registerPythonObjectPointer(ptr)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    public func convertToBool(_ obj: PythonObject) async throws -> Bool {
        let objPtr = pythonObjectRegistry[obj.id]!
        fatalError("placeholder")
    }
    
    public func convertToPython(double: Double) async throws -> PythonObject {
        return try await withGIL {
            guard let ptr =  try await pyFloat_FromDouble(double) else {
                throw PythonError.nullPointer("Failed to convert double: \(double)")
            }
            
            // Register the pointer in our actor's internal hashtable
            let id = registerPythonObjectPointer(ptr)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    public func convertToDouble(_ obj: PythonObject) async throws -> Double {
        let objPtr = pythonObjectRegistry[obj.id]!
        return try await withGIL {
            let value = pyFloat_AsDouble(objPtr)
            if value == -1.0 {
                if let _ = try pyErr_Occurred() {
                    try await throwPythonError()
                }
            }
            return Double(exactly: value)!
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToDouble(_ obj: SafePythonObject) throws -> Double {
        let objPtr = pythonObjectRegistry[obj.id]!
        let value = pyFloat_AsDouble(objPtr)
        if value == -1.0 {
            if let _ = try pyErr_Occurred() {
                try throwPythonError()
            }
        }
        return Double(exactly: value)!
    }
    
    public func convertToPython(int val: Int64) async throws -> PythonObject {
        logger.trace("convertToPython: Convert Int64 to PythonObject.")
        return try withGIL {
            guard let ptr = pyLong_FromLongLong(val) else {
                throw PythonError.nullPointer("Failed to convert int: \(val)")
            }
            
            let id = registerPythonObjectPointer(ptr)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    public func convertToInt(_ obj: PythonObject) async throws -> Int {
        logger.trace("convertToInt: Convert PythonObject to Int.")
        if let value = try await Int(exactly: convertToInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt(_ obj: SafePythonObject) throws -> Int {
        logger.trace("convertToInt: Convert SafePythonObject to Int.")
        if let value = try Int(exactly: convertToInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToInt8(_ obj: PythonObject) async throws -> Int8 {
        logger.trace("convertToInt8: Convert PythonObject to Int8.")
        if let value = try await Int8(exactly: convertToInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt8(_ obj: SafePythonObject) throws -> Int8 {
        logger.trace("convertToInt: Convert SafePythonObject to Int8.")
        if let value = try Int8(exactly: convertToInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToInt16(_ obj: PythonObject) async throws -> Int16 {
        logger.trace("convertToInt16: Convert PythonObject to Int16.")
        if let value = try await Int16(exactly: convertToInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt16(_ obj: SafePythonObject) throws -> Int16 {
        logger.trace("convertToInt16: Convert SafePythonObject to Int16.")
        if let value = try Int16(exactly: convertToInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToInt32(_ obj: PythonObject) async throws -> Int32 {
        logger.trace("convertToInt32: Convert PythonObject to Int32.")
        if let value = try await Int32(exactly: convertToInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt32(_ obj: SafePythonObject) throws -> Int32 {
        if let value = try Int32(exactly: convertToInt64(obj)) {
            logger.trace("convertToInt32: Convert SafePythonObject to Int32.")
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToInt64(_ obj: PythonObject) async throws -> Int64 {
        logger.trace("convertToInt64: Convert PythonObject to Int64.")
        let objPtr = pythonObjectRegistry[obj.id]!
        return try await withGIL {
            let value = try pyLong_AsLongLong(objPtr)
            if value == -1 {
                if let _ = try pyErr_Occurred() {
                    try await throwPythonError()
                }
            }
            return value
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToInt64(_ obj: SafePythonObject) throws -> Int64 {
        logger.trace("convertToInt64: Convert SafePythonObject to Int64.")
        let objPtr = pythonObjectRegistry[obj.id]!
        let value = try pyLong_AsLongLong(objPtr)
        if value == -1 {
            if let _ = try pyErr_Occurred() {
                try throwPythonError()
            }
        }
        return value
    }
    
    public func convertToPython(uint val: UInt64) async throws -> PythonObject {
        return try withGIL {
            guard let ptr = try pyLong_FromUnsignedLongLong(UInt64(val)) else {
                throw PythonError.nullPointer("Failed to convert int: \(val)")
            }
            
            let id = registerPythonObjectPointer(ptr)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    public func convertToUInt(_ obj: PythonObject) async throws -> UInt {
        logger.trace("convertToUInt: Convert PythonObject to UInt.")
        if let value = try await UInt(exactly: convertToUInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToUInt(_ obj: SafePythonObject) throws -> UInt {
        logger.trace("convertToUInt: Convert SafePythonObject to UInt.")
        if let value = try UInt(exactly: convertToUInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToUInt8(_ obj: PythonObject) async throws -> UInt8 {
        logger.trace("convertToUInt8: Convert PythonObject to UInt8.")
        let uint64Value: UInt64
        do {
            uint64Value = try await convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, _, let underlying):
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt8", underlying: underlying)
            default: throw error
            }
        }
        if let uint8Value = UInt8(exactly: uint64Value) {
            return uint8Value
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "PythonObject", targetType: "UInt8")
        }
    }
    
    public func convertToUInt8(_ obj: SafePythonObject) throws -> UInt8 {
        logger.trace("convertToUInt8: Convert SafePythonObject to UInt8.")
        let uint64Value: UInt64
        do {
            uint64Value = try convertToUInt64(obj)
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, _, let underlying):
                throw PythonError.conversionType(value: value, sourceType: sourceType, targetType: "UInt8", underlying: underlying)
            default: throw error
            }
        }
        if let uint8Value = UInt8(exactly: uint64Value) {
            return uint8Value
        } else {
            throw PythonError.conversionOverflow(value: String(uint64Value), sourceType: "SafePythonObject", targetType: "UInt8")
        }
    }
    
    public func convertToUInt16(_ obj: PythonObject) async throws -> UInt16 {
        logger.trace("convertToUInt16: Convert PythonObject to UInt16.")
        if let value = try await UInt16(exactly: convertToUInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToUInt16(_ obj: SafePythonObject) throws -> UInt16 {
        logger.trace("convertToUInt16: Convert SafePythonObject to UInt16.")
        if let value = try UInt16(exactly: convertToUInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToUInt32(_ obj: PythonObject) async throws -> UInt32 {
        logger.trace("convertToUInt32: Convert PythonObject to UInt32.")
        if let value = try await UInt32(exactly:convertToUInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToUInt32(_ obj: SafePythonObject) throws -> UInt32 {
        logger.trace("convertToUInt32: Convert SafePythonObject to UInt32.")
        if let value = try UInt32(exactly:convertToUInt64(obj)) {
            return value
        } else {
            fatalError("placeholder")
        }
    }
    
    public func convertToUInt64(_ obj: PythonObject) async throws -> UInt64 {
        logger.trace("convertToUInt64: Convert PythonObject to UInt64.")
        let isNegative: Bool
        do {
            isNegative = try await obj.lessThan(0)
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isNegative {
            logger.error("convertToUInt64: Called for NEGATIVE number PythonObject.")
            let objStr = try await String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "PythonObject", targetType: "UInt64")
        }
        let objPtr = pythonObjectRegistry[obj.id]!
        
        
        do {
            return try await withGIL {
                let value = try pyLong_AsUnsignedLongLong(objPtr)
                if value == UInt64.max {              // (unsigned long long)-1 on error
                    if let _ = try pyErr_Occurred() {
                        try await throwPythonError()
                    }
                }
                return value
            }
        } catch let error as PythonError {
            switch error {
            case .pythonException:
                let objStr = (try? await String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "PythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToUInt64(_ obj: SafePythonObject) throws -> UInt64 {
        logger.trace("convertToUInt64: Convert SafePythonObject to UInt64.")
        let isNegative: Bool
        do {
            isNegative = try obj.lessThan(0)
        } catch let error as PythonError {
            switch error {
            case .safePythonException:
                let objStr = (try? String(obj)) ?? "<unrepresentable>"
                
                throw PythonError.conversionType( value: objStr, sourceType: "SafePythonObject", targetType: "UInt64", underlying: error )
            default:
                throw error
            }
        } catch {
            throw error
        }
        if isNegative {
            logger.error("convertToUInt64: Called for NEGATIVE number SafePythonObject.")
            let objStr = try String(obj)
            throw PythonError.conversionOverflow(value: objStr, sourceType: "SafePythonObject", targetType: "UInt64")
        }
        let objPtr = pythonObjectRegistry[obj.id]!
        let value = try pyLong_AsUnsignedLongLong(objPtr)
        if value == UInt64.max {              // (unsigned long long)-1 on error
            if let _ = try pyErr_Occurred() {
                do {
                    try throwPythonError()
                } catch let error as PythonError {
                    switch error {
                    case .safePythonException:
                        let objStr = (try? String(obj)) ?? "<unrepresentable>"
                        
                        throw PythonError.conversionType( value: objStr, sourceType: "SafePythonObject", targetType: "UInt64", underlying: error )
                    default:
                        throw error
                    }
                } catch {
                    throw error
                }
            }
        }
        return value
    }
    
    
    public func convertToPython(string: String) async throws -> PythonObject {
        return try withGIL {
            guard let ptr = try pyUnicode_FromStringAndSize(string) else {
                throw PythonError.nullPointer("Failed to convert string: \(string)")
            }
            
            // Register the pointer in our actor's internal hashtable
            let id = registerPythonObjectPointer(ptr)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    public func convertToString(_ obj: PythonObject) async throws -> String {
        let objPtr = pythonObjectRegistry[obj.id]!
        
        return try withGIL {
            if let pyStr = pyObject_Str(objPtr) {
                // FIXME: New object is created.  It needs to disappear.
                // defer { Py_DECREF(pyStr) }
                if let s = try pyUnicode_AsUTF8AndSize(pyStr) {
                    return s
                } else {
                    try throwPythonError()
                }
            }
            else {
                try throwPythonError()
            }
        }
    }
    
    @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    public func convertToString(_ obj: SafePythonObject) throws -> String {
        let objPtr = pythonObjectRegistry[obj.id]!
        
        guard let pyStr = pyObject_Str(objPtr) else {
            try throwPythonError()
        }
        // FIXME: New object is created.  It needs to disappear.
        // defer { Py_DECREF(pyStr) }
        if let s = try pyUnicode_AsUTF8AndSize(pyStr) {
            return s
        } else {
            try throwPythonError()
        }
    }
    
    public func convertToPython(array: [PendingPythonConvertible]) async throws -> PythonObject {
        return try await withGIL {
            guard let listPtr = try pyList_New(array.count)  else {
                throw PythonError.nullPointer("Failed to convert list: \(array)")
            }
            for (index, element) in array.enumerated() {
                let valuePythonObject = try await element.toPythonObject(interpreter: self)
                let valuePtr = pythonObjectRegistry[valuePythonObject.id]
                _ = try pyList_SetItem(listPtr, index, valuePtr!)
            }
            
            // Register the pointer in our actor's internal hashtable
            let id = registerPythonObjectPointer(listPtr)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    public func convertToPython<K, V>(dictionary: [K: V]) async throws -> PythonObject
            where K: PendingPythonConvertible & Hashable, V: PendingPythonConvertible {
        return try await withGIL {
            guard let dictPtr = try pyDict_New()  else {
                throw PythonError.nullPointer("Failed to convert dictionary")
            }
            
            for (key, value) in dictionary {
                let keyObj = try await key.toPythonObject(interpreter: self)
                let valueObj = try await value.toPythonObject(interpreter: self)
                let keyPtr = pythonObjectRegistry[keyObj.id]!
                let valuePtr = pythonObjectRegistry[valueObj.id]!
                _ = try pyDict_SetItem(dictPtr, keyPtr, valuePtr)
            }
            
            // Register the pointer in our actor's internal hashtable
            let id = registerPythonObjectPointer(dictPtr)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    // MARK: Attribute access (async mode)
    
    public func get(object: PythonObject, attribute: String) async throws -> PythonObject {
        let objPtr = pythonObjectRegistry[object.id]!
        
        return try withGIL {
            let valuePtr = try pyObject_GetAttrString(objPtr, attribute)
            let id = registerPythonObjectPointer(valuePtr!)
            return PythonObject(id: id, interpreter: self)
        }
    }
    
    public func set(object: PythonObject, attribute: String, value: PythonObject) async throws {
        let objPtr = pythonObjectRegistry[object.id]!
        let valuePtr = pythonObjectRegistry[value.id]!
        
        try withGIL {
            _ = try pyObject_SetAttrString(objPtr, attribute, valuePtr)
        }
    }
    
    // MARK: Comparion Support (async mode)
    
    
    public func equals(lhs: PythonObject, rhs: PendingPythonConvertible) async throws -> Bool {
        logger.trace("Equals comparison for PythonObject (async)")
        let lhsPtr = pythonObjectRegistry[lhs.id]!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = pythonObjectRegistry[rhsPyObj.id]!
        
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
        let lhsPtr = pythonObjectRegistry[lhs.id]!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = pythonObjectRegistry[rhsPyObj.id]!
        
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
        let lhsPtr = pythonObjectRegistry[lhs.id]!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = pythonObjectRegistry[rhsPyObj.id]!
        
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
        let lhsPtr = pythonObjectRegistry[lhs.id]!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = pythonObjectRegistry[rhsPyObj.id]!
        
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
        let lhsPtr = pythonObjectRegistry[lhs.id]!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = pythonObjectRegistry[rhsPyObj.id]!
        
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
        let lhsPtr = pythonObjectRegistry[lhs.id]!
        let rhsPyObj = try await rhs.toPythonObject(interpreter: self)
        let rhsPtr = pythonObjectRegistry[rhsPyObj.id]!
        
        return try await withGIL {
            switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThanOrEqual.rawValue) {
            case 0: return false
            case 1: return true
            default: try await throwPythonError()
            }
        }
    }
    
    // MARK: Callable Support (async mode)
    
    // Private helper that does the actual call (used by both above)
    private func callPythonCallable(_ callable: PythonObject,
                                    args: [any PendingPythonConvertible],
                                    kwargs: [String: PendingPythonConvertible]) async throws -> PythonObject {
        return try await withGIL {
            // Build args tuple
            let argTuplePtr: UnsafeMutableRawPointer? = try await createArgsTupleAsync(args)
            // Build kwargs dict (if any)
            let kwDictPtr: UnsafeMutableRawPointer? = kwargs.isEmpty
            ? nil
            : try await createKwargsDictAsync(kwargs)
            
            guard let callablePtr = pythonObjectRegistry[callable.id] else {
                throw PythonError.nullPointer("Callable pointer not found")
            }
            
            // Use PyObject_Call (most flexible)
            guard let resultPtr = try pyObject_Call(callablePtr, argTuplePtr!, kwDictPtr) else {
                throw PythonError.nullPointer("Python call returned NULL")
            }
            let resultID = registerPythonObjectPointer(resultPtr)
            return PythonObject(id: resultID, interpreter: self)
        }
    }
    
    private func createArgsTupleAsync(_ args: [any PendingPythonConvertible]) async throws -> UnsafeMutableRawPointer {
        guard let tuplePtr = try pyTuple_New(args.count) else {
            throw PythonError.nullPointer("Failed to create argument tuple")
        }
        
        for (index, element) in args.enumerated() {
            let pyObj = try await element.toPythonObject(interpreter: self)
            guard let itemPtr = pythonObjectRegistry[pyObj.id] else {
                throw PythonError.nullPointer("Argument conversion failed")
            }
            _ = try pyTuple_SetItem(tuplePtr, index, itemPtr)
        }
        return tuplePtr
    }
    
    private func createKwargsDictAsync(_ kwargs: [String: PendingPythonConvertible]) async throws -> UnsafeMutableRawPointer {
        guard let dictPtr = try pyDict_New() else {
            throw PythonError.nullPointer("Failed to create kwargs dict")
        }
        
        for (key, value) in kwargs {
            let keyObj = try await convertToPython(string: key)
            let valueObj = try await value.toPythonObject(interpreter: self)
            
            guard let keyPtr = pythonObjectRegistry[keyObj.id],
                  let valuePtr = pythonObjectRegistry[valueObj.id] else {
                throw PythonError.nullPointer("Kwargs conversion failed")
            }
            _ = try pyDict_SetItem(dictPtr, keyPtr, valuePtr)
        }
        return dictPtr
    }
    
    public func callPythonMethod(object: PythonObject, methodName: String, collectedArgs: [any PendingPythonConvertible],
                                 kwargs: [String: PendingPythonConvertible]) async throws -> PythonObject {
        
        guard let objPtr = pythonObjectRegistry[object.id] else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        
        guard let methodPtr = try pyObject_GetAttrString(objPtr, methodName) else {
            throw PythonError.nullPointer("Method '\(methodName)' not found on object")
        }
        
        let methodID = registerPythonObjectPointer(methodPtr)
        let methodObject = PythonObject(id: methodID, interpreter: self)
        
        return try await callPythonCallable(methodObject, args: collectedArgs, kwargs: kwargs)
    }
    
    public func callPythonMethod(object: PythonObject, methodName: String,
                                 collectedArgs: [any PendingPythonConvertible]) async throws -> PythonObject {
        
        guard let objPtr = pythonObjectRegistry[object.id] else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        
        guard let methodPtr = try pyObject_GetAttrString(objPtr, methodName) else {
            throw PythonError.nullPointer("Method '\(methodName)' not found on object")
        }
        
        let methodID = registerPythonObjectPointer(methodPtr)
        let methodObject = PythonObject(id: methodID, interpreter: self)
        
        return try await callPythonCallable(methodObject, args: collectedArgs, kwargs: [:])
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
    
    // MARK: Bytes Support (async mode)
    
    public let PyBUF_SIMPLE      = Int32(0)
    public let PyBUF_WRITABLE    = Int32(1 << 0)
    public let PyBUF_FORMAT      = Int32(1 << 1)
    public let PyBUF_ND          = Int32(1 << 2)
    public let PyBUF_STRIDES     = Int32(1 << 3)
    public let PyBUF_C_CONTIGUOUS = Int32(1 << 4)
    
//    public func isBytes(_ obj: PythonObject) async throws -> Bool {
//        guard let objPtr = pythonObjectRegistry[obj.id] else {
//            throw PythonError.nullPointer("Object pointer not found")
//        }
//        return try withGIL { pyBytes_Check(objPtr) }
//    }
//    
//    public func isBytesArray(_ obj: PythonObject) async throws -> Bool {
//        guard let objPtr = pythonObjectRegistry[obj.id] else {
//            throw PythonError.nullPointer("Object pointer not found")
//        }
//        return try withGIL { pyByteArray_Check(objPtr) }
//    }
    
    public func bytesObjectSize(_ obj: PythonObject) async throws -> Int {
        guard let objPtr = pythonObjectRegistry[obj.id] else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try withGIL { try Int(pyBytes_Size(objPtr)) }
    }
    
    public func bytesArrayObjectSize(_ obj: PythonObject) async throws -> Int {
        guard let objPtr = pythonObjectRegistry[obj.id] else {
            throw PythonError.nullPointer("Object pointer not found")
        }
        return try withGIL { try pyByteArray_Size(objPtr) }
    }
    
    // REMOVED DUPLICATE async withUnsafeBytes that manually handled bytes and bytearray here
    
    public func withUnsafeBytes<R>(_ obj: PythonObject, body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) async throws -> R {
        try withGIL {
            let objPtr = getRegisteredPythonObjectPointer(obj.id)!
            
            var view = Py_buffer()
            
            guard api.PyObject_GetBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
                fatalError()
            }
            defer {
                api.PyBuffer_Release(&view)
            }
            
            guard let base = view.buf else {
                throw PythonError.nullPointer("Buffer pointer is null")
            }
            
            let ptr = base.assumingMemoryBound(to: UInt8.self)
            let buffer = UnsafeBufferPointer(start: ptr, count: Int(view.len))
            
            return try body(buffer)
        }
    }
    
    // MARK: -
    // MARK: SYNCHRONOUS MODE
    //
    
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
                try body(self)
            }
        } catch let error as PythonError {
            // Transform safePythonException → pythonException so the caller gets
            // a normal async-friendly PythonError.
            if case .safePythonException(let safeObj) = error {
                
                // FIXME: make sure SafePythonObject destruction doesn't mess up reference counts or something.
                let id = safeObj.id
                let pythonObj = PythonObject(id : id, interpreter: self)
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
        let gstate = pyGILState_Ensure()
        defer { pyGILState_Release(gstate) }
        
        // All Python C API usage is now safe here.
        return try body()
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
    
    // TODO: This was/is Sendable.  That's probably not needed, right?
    @dynamicMemberLookup
    public struct SafePythonObject: SafePythonConvertible, Sequence,
                                    ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral,
                                    ExpressibleByStringLiteral, ExpressibleByBooleanLiteral {
        
        
        // MARK: ExpressibleBy stuff, so operators can work
        
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
                    return try $0.convertToSafePython(int:Int64(val))
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
        
        public func convertToDouble() throws -> Double {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToDouble(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                return val
            case .deferredInt(let val):
                return Double(val)
            case .deferredString(let val):
                // mimic python string conversion to Double
                guard let double = Double(val) else {
                    fatalError("placeholder")
                }
                return double
            case .deferredBool(let val):
                return val ? 1.0 : 0.0
            }
        }
        
        public func convertToInt() throws -> Int {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredInt(let val):
                return val
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                guard let intValue = Int(val) else {   // Swift Int(String) is close but slightly stricter than Python on some edge cases
                    // Optional improvement: try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let double = Double(val), double.isFinite {
                        return Int(double)             // this would make int("3.14") == 3 (more forgiving)
                    }
                    fatalError("placeholder")
                }
                return intValue
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToInt8() throws -> Int8 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt8(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int8(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = Int8(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                let iVal: Int
                if let intValue = Int(val) {
                    iVal = intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    iVal = Int(double)
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
                if let i = Int8(exactly:iVal) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToInt16() throws -> Int16 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt16(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int16(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = Int16(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                let iVal: Int
                if let intValue = Int(val) {
                    iVal = intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    iVal = Int(double)
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
                if let i = Int16(exactly:iVal) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToInt32() throws -> Int32 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt32(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int32(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = Int32(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                let iVal: Int
                if let intValue = Int(val) {
                    iVal = intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    iVal = Int(double)
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
                if let i = Int32(exactly:iVal) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToInt64() throws -> Int64 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.convertToInt64(self)
                    } catch {
                        fatalError("Failed to get attribute: \(error)")
                    }
                }
            case .deferredDouble(let val):
                if let i = Int64(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = Int64(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = Int64(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = Int64(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt() throws -> UInt {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt(self)
                }
            case .deferredDouble(let val):
                if let i = UInt(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt8() throws -> UInt8 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt8(self)
                }
            case .deferredDouble(let val):
                if let i = UInt8(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt8(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt8(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt8(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt16() throws -> UInt16 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt16(self)
                }
            case .deferredDouble(let val):
                if let i = UInt16(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt16(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt16(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt16(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt32() throws -> UInt32 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt32(self)
                }
            case .deferredDouble(let val):
                if let i = UInt32(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt32(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt32(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt32(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToUInt64() throws -> UInt64 {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToUInt64(self)
                }
            case .deferredDouble(let val):
                if let i = UInt64(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")  // overflow
                }
            case .deferredInt(let val):
                if let i = UInt64(exactly:val) {
                    return i
                }
                else {
                    fatalError("placeholder")
                }
            case .deferredString(let val):
                // Mimic Python's int("...")
                // Python accepts decimal strings, but does NOT accept floats like "3.14"
                // It also supports base prefixes (0x, 0o, 0b) but we can start simple.
                // For full fidelity you can later add radix support.
                if let intValue = UInt64(val) {
                   return intValue
                } else if let double = Double(val), double.isFinite {
                    // try via Double first then truncate (Python allows int("3.14") to fail, but some users expect leniency)
                    if let intValue = UInt64(exactly:double) {
                        return intValue
                    }
                    else {
                        fatalError("placeholder")  // out of range
                    }
                } else {
                    fatalError("placeholder")  // can't convert to a number
                }
            case .deferredBool(let val):
                return val ? 1 : 0
            }
        }
        
        public func convertToString() throws -> String {
            switch state {
            case .bound:
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.convertToString(self)
                }
            case .deferredDouble(let val):
                return String(val)
            case .deferredInt(let val):
                return String(val)
            case .deferredString(let val):
                return val
            case .deferredBool(let val):
                return val ? "True" : "False"
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
        
        // MARK: SafePythonObject @dynamicMemberLookup support
        
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
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        return try $0.syncGetObjectItem(obj:self, key:key)
                    } catch {
                        fatalError("Failed to get item: \(error)")
                    }
                }
            }
            // a[key] = value
            set {
                let localInterpreter = interpreter
                return localInterpreter.assumeIsolated {
                    do {
                        try $0.syncSetObjectItem(obj:self, key:key, newValue:newValue)
                    } catch {
                        fatalError("Failed to set item: \(error)")
                    }
                }
            }
        }
        
        // MARK: SafePythonObject Callable support
        
        public func callAsFunction() throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self)
            }
        }
        
        public func callAsFunction(_ args: any SafePythonConvertible...) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, args:args)
            }
        }
        
        public func callAsFunction(_ args: any SafePythonConvertible...,
                                   kwargs: [String: SafePythonConvertible] = [:]) throws -> SafePythonObject {
            let localInterpreter = interpreter
            return try localInterpreter.assumeIsolated {
                return try $0.syncCall(callable:self, args:args, kwargs:kwargs)
            }
        }
        
        // MARK: SafePythonObject Sequence support
        
        public typealias Element = SafePythonObject
        
        public struct SafePythonIterator: IteratorProtocol {
            private var pyIterator: SafePythonObject
            
            fileprivate init(sequence: SafePythonObject) throws {
                self.pyIterator = try sequence.__iter__()
            }
            
            public mutating func next() -> SafePythonObject? {
                do {
                    return try pyIterator.__next__()
                } catch {
                    // StopIteration or any other error → end of sequence (Swift Iterator contract)
                    return nil
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Sequence conformance is only valid inside withIsolatedContext()")
        public func makeIterator() -> SafePythonIterator {
            do {
                return try SafePythonIterator(sequence: self)
            } catch {
                fatalError("Failed to create iterator for SafePythonObject: \(error)")
            }
        }
        
        // MARK: SafePythonObject items() Sequence support
        
        public struct ItemsSequence: Sequence {
            public typealias Element = (key: SafePythonObject, value: SafePythonObject)
            
            private let dictView: SafePythonObject
            
            fileprivate init(dictView: SafePythonObject) {
                self.dictView = dictView
            }
            
            public struct Iterator: IteratorProtocol {
                private var pyIterator: SafePythonObject   // the iterator from items()
                
                fileprivate init(dictView: SafePythonObject) throws {
                    self.pyIterator = try dictView.__iter__()
                }
                
                public mutating func next() -> Element? {
                    do {
                        // Each item from dict.items() is a 2-element tuple in Python
                        let item = try pyIterator.__next__()
                        
                        // Unpack the Python tuple using subscript (already implemented)
                        let key   = item[0] as! SafePythonObject   // or item[SafePythonObject(0)] if needed
                        let value = item[1] as! SafePythonObject
                        
                        return (key: key, value: value)
                    } catch {
                        // StopIteration → end
                        return nil
                    }
                }
            }
            
            public func makeIterator() -> Iterator {
                do {
                    return try Iterator(dictView: dictView)
                } catch {
                    fatalError("Failed to create items() iterator: \(error)")
                }
            }
        }
        
        // The items() function for a dictionary
        @available(*, noasync, message: "items() is only valid inside withIsolatedContext()")
        public func items() -> ItemsSequence {
            ItemsSequence(dictView: self)
        }
        
        // MARK: SafePythonObject Bytes support
        
//        public var isBytes: Bool {
//            do {
//                let localInterpreter = interpreter
//                return try localInterpreter.assumeIsolated {
//                    try $0.isBytes(self)
//                }
//            } catch {
//                fatalError("Failed: \(error)")
//            }
//        }
//        
//        public var isBytesArray: Bool {
//            do {
//                let localInterpreter = interpreter
//                return try localInterpreter.assumeIsolated {
//                    try $0.isBytesArray(self)
//                }
//            } catch {
//                fatalError("Failed: \(error)")
//            }
//        }
//        
//        public var isBytesType: Bool { return isBytes || isBytesArray}
        
        /// Safe copy of Python bytes → Swift Data
        public func asCopiedData() throws -> Data {
            try withUnsafeBytes { Data($0) }
        }
        
        /// Safe copy of Python bytes → Swift `String` (recommended for SVG, JSON, text)
        public func asCopiedString(encoding: String.Encoding = .utf8) throws -> String {
            try withUnsafeBytesString(encoding: encoding) { $0 }
        }
        
        /// Do something with the bytes before the closure ends
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func withUnsafeBytes<R : Sendable>(_ body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) throws -> R {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.withUnsafeBytes(self, body: body)
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        /// Do something with the bytes before the closure ends
        public func withUnsafeBytesString<R : Sendable>( encoding: String.Encoding = .utf8, _ body: @Sendable (String) throws -> R ) throws -> R {
            try withUnsafeBytes { buffer in
                guard let str = String(bytes: buffer, encoding: encoding) else {
                    //throw PythonError.valueError("Cannot decode bytes as \(encoding)")
                    fatalError("placeholder")
                }
                return try body(str)
            }
        }
        
        // MARK: SafePythonObject Operator support
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
                case .deferredString:
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
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal + (rhsVal ? 1 : 0))
                }
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt:
                    fatalError("Python TypeError")
                case .deferredString(let rhsVal):
                    return SafePythonObject(stringLiteral: lhsVal + rhsVal)
                case .deferredBool:
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
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) + (rhsVal ? 1 : 0))
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
        
        // Python multiplication results:
        static internal func unboundPythonMultiply(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal * rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal * Double(rhsVal))
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal * (rhsVal ? 1.0 : 0.0))
                }
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: Double(lhsVal) * rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal * rhsVal)
                case .deferredString(let rhsVal):
                    return (lhsVal < 1) ? SafePythonObject(stringLiteral: "") : SafePythonObject(stringLiteral: String(repeating: rhsVal, count: lhsVal))
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal * (rhsVal ? 1 : 0))
                }
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt(let rhsVal):
                    return (rhsVal < 1) ? SafePythonObject(stringLiteral: "") : SafePythonObject(stringLiteral: String(repeating: lhsVal, count: rhsVal))
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return rhsVal ? SafePythonObject(stringLiteral: lhsVal) : SafePythonObject(stringLiteral: "")
                }
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) * rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) * rhsVal)
                case .deferredString(let rhsVal):
                    return lhsVal ? SafePythonObject(stringLiteral: rhsVal) : SafePythonObject(stringLiteral: "")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) * (rhsVal ? 1 : 0))
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
        
        // Python subtraction results:
        static internal func unboundPythonSubtract(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal - rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal - Double(rhsVal))
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(floatLiteral: lhsVal - (rhsVal ? 1.0 : 0.0))
                }
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: Double(lhsVal) - rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal - rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal - (rhsVal ? 1 : 0))
                }
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) - rhsVal)
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) - rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) - (rhsVal ? 1 : 0))
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
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
        
        // Python division results:
        static internal func unboundPythonDivide(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    guard rhsVal != 0.0 else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: lhsVal / rhsVal)
                case .deferredInt(let rhsVal):
                    guard rhsVal != 0 else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: lhsVal / Double(rhsVal))
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    guard rhsVal else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: lhsVal) // n / 1 == n
                }
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    guard rhsVal != 0.0 else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: Double(lhsVal) / rhsVal)
                case .deferredInt(let rhsVal):
                    guard rhsVal != 0 else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: Double(lhsVal) / Double(rhsVal))   // Python division always return floating point
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    guard rhsVal else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: Double(lhsVal)) // n / 1 == n
                }
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    guard rhsVal != 0.0 else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / rhsVal)
                case .deferredInt(let rhsVal):
                    guard rhsVal != 0 else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: (lhsVal ? 1.0 : 0.0) / Double(rhsVal))    // Python division always return floating point
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    guard rhsVal else { fatalError("Python Divide By Zero") }
                    return SafePythonObject(floatLiteral: lhsVal ? 1.0 : 0.0) // n / 1 == n
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func bitwiseAndOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseAnd(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func bitwiseAndInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncInPlaceBitwiseAnd(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        // Python bitwise AND results:
        static internal func unboundPythonBitwiseAnd(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal & rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal & (rhsVal ? 1 : 0))
                }
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) & rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) & (rhsVal ? 1 : 0))
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func bitwiseOrOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseOr(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func bitwiseOrInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncInPlaceBitwiseOr(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        // Python bitwise OR results:
        static internal func unboundPythonBitwiseOr(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal | rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal | (rhsVal ? 1 : 0))
                }
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) | rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) | (rhsVal ? 1 : 0))
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func bitwiseXorOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseXor(lhs.toSafePythonObject(interpreter: $0), rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func bitwiseXorInPlaceOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncInPlaceBitwiseXor(lhs: lhs.toSafePythonObject(interpreter: $0), rhs: rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        // Python bitwise XOR results:
        static internal func unboundPythonBitwiseXor(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal ^ rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: lhsVal ^ (rhsVal ? 1 : 0))
                }
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) ^ rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return SafePythonObject(integerLiteral: (lhsVal ? 1 : 0) ^ (rhsVal ? 1 : 0))
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func bitwiseNotOperator(_ operand: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncBitwiseNot(operand.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        // Python bitwise NOT results:
        static internal func unboundPythonBitwiseNot(operand: SafePythonObject) -> SafePythonObject {
            switch operand.state {
            case .bound:
                fatalError("This can never happen.")
            case .deferredDouble:
                fatalError("Python TypeError")
            case .deferredInt(let operandVal):
                return SafePythonObject(integerLiteral: ~operandVal)
            case .deferredString:
                fatalError("Python TypeError")
            case .deferredBool(let operandVal):
                return SafePythonObject(integerLiteral: ~(operandVal ? 1 : 0))
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func doubleEqualsEquatableOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> Bool {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncDoubleEqualsEquatable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func doubleEqualsOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncDoubleEquals(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func unboundPythonDoubleEquals(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            SafePythonObject(booleanLiteral: unboundPythonDoubleEqualsEquatable(lhs: lhs, rhs: rhs))
        }
        
        static internal func unboundPythonDoubleEqualsEquatable(lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return lhsVal == rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal == Double(rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal == (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return Double(lhsVal) == rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal == rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal == (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt:
                    fatalError("Python TypeError")
                case .deferredString(let rhsVal):
                    return lhsVal == rhsVal
                case .deferredBool:
                    fatalError("Python TypeError")
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) == rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) == rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal == rhsVal
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func notEqualsEquatableOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> Bool {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncNotEqualsEquatable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func notEqualsOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncNotEquals(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        static internal func unboundPythonNotEquals(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            SafePythonObject(booleanLiteral: unboundPythonNotEqualsEquatable(lhs: lhs, rhs: rhs))
        }
        
        static internal func unboundPythonNotEqualsEquatable(lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            switch lhs.state {
            case .bound:
                fatalError("This can never happen.")
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return lhsVal != rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal != Double(rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal != (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return Double(lhsVal) != rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal != rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal != (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt:
                    fatalError("Python TypeError")
                case .deferredString(let rhsVal):
                    return lhsVal != rhsVal
                case .deferredBool:
                    fatalError("Python TypeError")
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    fatalError("This can never happen.")
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) != rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) != rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal != rhsVal
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func lessThanOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThan(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        // A less than that throws.  Operators cause fatalError()
        // so use this whenever anything might go wrong.
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func lessThan(_ other: SafePythonConvertible) throws -> Bool {
            let localInterpreter = interpreter
            let lhs = self
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThanComparable(lhs:lhs, rhs:other.toSafePythonObject(interpreter: $0))
            }
        }
        
        static internal func unboundPythonLessThan(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            SafePythonObject(booleanLiteral: lessThanComparable(lhs: lhs, rhs: rhs))
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func boundPythonLessThanComparable(interpreter: PythonInterpreter, lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanComparable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Comparison failed: \(error).  Use `SafePythonObject.lessThan()` for comparisons that might throw.")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func lessThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            switch lhs.state {
            case .bound:
                return boundPythonLessThanComparable(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonLessThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return lhsVal < rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal < Double(rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal < (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonLessThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return Double(lhsVal) < rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal < rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal < (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonLessThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt:
                    fatalError("Python TypeError")
                case .deferredString(let rhsVal):
                    return lhsVal < rhsVal
                case .deferredBool:
                    fatalError("Python TypeError")
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonLessThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) < rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) < rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return (lhsVal ? 1 : 0) < (rhsVal ? 1 : 0)
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func lessThanOrEqualOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanOrEqual(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        // A less than that throws.  Operators cause fatalError()
        // so use this whenever anything might go wrong.
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        public func lessThanOrEquals(_ other: SafePythonConvertible) throws -> Bool {
            let localInterpreter = interpreter
            let lhs = self
            return try localInterpreter.assumeIsolated {
                try $0.syncLessThanOrEqualComparable(lhs:lhs, rhs:other.toSafePythonObject(interpreter: $0))
            }
        }
        
        static internal func unboundPythonLessThanOrEquals(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            SafePythonObject(booleanLiteral: lessThanOrEqualsComparable(lhs: lhs, rhs: rhs))
        }
        
        
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func boundPythonLessThanOrEqualsComparable(interpreter: PythonInterpreter, lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncLessThanOrEqualComparable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Comparison failed: \(error).  Use `SafePythonObject.lessThanOrEqual()` for comparisons that might throw.")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func lessThanOrEqualsComparable(lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            switch lhs.state {
            case .bound:
                return boundPythonLessThanOrEqualsComparable(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonLessThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return lhsVal <= rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal <= Double(rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal <= (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonLessThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return Double(lhsVal) <= rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal <= rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal <= (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonLessThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt:
                    fatalError("Python TypeError")
                case .deferredString(let rhsVal):
                    return lhsVal <= rhsVal
                case .deferredBool:
                    fatalError("Python TypeError")
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonLessThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) <= rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) <= rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return (lhsVal ? 1 : 0) <= (rhsVal ? 1 : 0)
                }
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func greaterThanOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThan(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        static internal func unboundPythonGreaterThan(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            SafePythonObject(booleanLiteral: greaterThanComparable(lhs: lhs, rhs: rhs))
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func boundPythonGreaterThanComparable(interpreter: PythonInterpreter, lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanComparable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Comparison failed: \(error).  Use `SafePythonObject.greaterThan()` for comparisons that might throw.")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func greaterThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            switch lhs.state {
            case .bound:
                return boundPythonGreaterThanComparable(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonGreaterThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return lhsVal > rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal > Double(rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal > (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonGreaterThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return Double(lhsVal) > rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal > rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal > (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonGreaterThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt:
                    fatalError("Python TypeError")
                case .deferredString(let rhsVal):
                    return lhsVal > rhsVal
                case .deferredBool:
                    fatalError("Python TypeError")
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonGreaterThanComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) > rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) > rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return (lhsVal ? 1 : 0) > (rhsVal ? 1 : 0)
                }
            }
        }
               
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        internal func greaterThanOrEqualOperator(_ lhs: SafePythonConvertible, _ rhs: SafePythonConvertible) -> SafePythonObject {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanOrEqual(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Failed: \(error)")
            }
        }
        
        static internal func unboundPythonGreaterThanOrEquals(lhs: SafePythonObject, rhs: SafePythonObject) -> SafePythonObject {
            SafePythonObject(booleanLiteral: greaterThanOrEqualsComparable(lhs: lhs, rhs: rhs))
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func boundPythonGreaterThanOrEqualsComparable(interpreter: PythonInterpreter, lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            do {
                let localInterpreter = interpreter
                return try localInterpreter.assumeIsolated {
                    try $0.syncGreaterThanOrEqualComparable(lhs:lhs.toSafePythonObject(interpreter: $0), rhs:rhs.toSafePythonObject(interpreter: $0))
                }
            } catch {
                fatalError("Comparison failed: \(error).  Use `SafePythonObject.greaterThanOrEqual()` for comparisons that might throw.")
            }
        }
        
        @available(*, noasync, message: "SafePythonObject Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
        static internal func greaterThanOrEqualsComparable(lhs: SafePythonObject, rhs: SafePythonObject) -> Bool {
            switch lhs.state {
            case .bound:
                return boundPythonGreaterThanOrEqualsComparable(interpreter: lhs.interpreter, lhs: lhs, rhs: rhs)
                
            case .deferredDouble(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonGreaterThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return lhsVal >= rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal >= Double(rhsVal)
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal >= (rhsVal ? 1.0 : 0.0)
                }
                
            case .deferredInt(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonGreaterThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return Double(lhsVal) >= rhsVal
                case .deferredInt(let rhsVal):
                    return lhsVal >= rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return lhsVal >= (rhsVal ? 1 : 0)
                }
                
            case .deferredString(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonGreaterThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble:
                    fatalError("Python TypeError")
                case .deferredInt:
                    fatalError("Python TypeError")
                case .deferredString(let rhsVal):
                    return lhsVal >= rhsVal
                case .deferredBool:
                    fatalError("Python TypeError")
                }
                
            case .deferredBool(let lhsVal):
                switch rhs.state {
                case .bound:
                    return boundPythonGreaterThanOrEqualsComparable(interpreter: rhs.interpreter, lhs: lhs, rhs: rhs)
                case .deferredDouble(let rhsVal):
                    return (lhsVal ? 1.0 : 0.0) >= rhsVal
                case .deferredInt(let rhsVal):
                    return (lhsVal ? 1 : 0) >= rhsVal
                case .deferredString:
                    fatalError("Python TypeError")
                case .deferredBool(let rhsVal):
                    return (lhsVal ? 1 : 0) >= (rhsVal ? 1 : 0)
                }
            }
        }
        
    }  // end of Safe python object
    
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
        logger.trace("CPyton API call in synchronous mode: PyImport_ImportModule")
        guard let ptr = name.withCString({ api.PyImport_ImportModule($0) }) else {
            throw PythonError.nullPointer("Failed to import module: \(name)")
        }
        
        let id = registerPythonObjectPointer(ptr)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    private func syncGetFromMain(_ attrName: String) throws -> SafePythonObject {
        logger.trace("Synchronous getFromMain")
        
        logger.trace("CPyton API call in synchronous mode: PyImport_AddModule")
        guard let mainModulePtr = "__main__".withCString({ api.PyImport_AddModule($0) }) else {
            throw PythonError.nullPointer("Could not access Python __main__ module")
        }
        
        logger.trace("CPyton API call in synchronous mode: PyObject_GetAttrString")
        guard let aliasPtr = attrName.withCString({ api.PyObject_GetAttrString(mainModulePtr, $0) }) else {
            throw PythonError.nullPointer("Alias '\(attrName)' not found in Python scope")
        }
        
        let id = registerPythonObjectPointer(aliasPtr)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    private func syncImportWithAlias(_ name: String, alias: String) throws -> SafePythonObject {
        logger.trace("Synchronous importWithAlias")
        
        // 1. Execute "import name as alias"
        let command = "import \(name) as \(alias)"
        logger.trace("CPyton API call in synchronous mode: PyRun_SimpleString")
        let result = command.withCString { api.PyRun_SimpleString($0) }
        
        guard result == 0 else {
            throw PythonError.stringConversionFailed("Python execution failed for: \(command)")
        }
        
        // 2. Retrieve the alias from __main__
        return try syncGetFromMain(alias)
    }
    
    // MARK: Conversions from primitives (synchronous mode)
    // Primitive type conversions in synchronous mode ----------
    
    internal func convertToSafePython(bool val: Bool) throws -> SafePythonObject {
        let id = try convertToSafePythonID(bool: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(bool: Bool) throws -> PythonObjectUniqueID {
        guard let ptr = pyBool_FromLong(((bool ? 1 : 0) != 0)) else {
            throw PythonError.nullPointer("Failed to convert bool: \(bool)")
        }
        
        let id = registerPythonObjectPointer(ptr)
        return id
    }
    
    internal func convertToSafePython(double val: Double) throws -> SafePythonObject {
        let id = try convertToSafePythonID(double: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(double val: Double) throws -> PythonObjectUniqueID {
        logger.trace("CPyton API call in synchronous mode: PyFloat_FromDouble")
        guard let ptr = api.PyFloat_FromDouble(val) else {
            throw PythonError.nullPointer("Failed to convert double: \(val)")
        }
        
        // Register the pointer in our actor's internal hashtable
        let id = registerPythonObjectPointer(ptr)
        return id
    }
    
    internal func convertToSafePython(int val: Int64) throws -> SafePythonObject {
        let id = try convertToSafePythonID(int: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(int val: Int64) throws -> PythonObjectUniqueID {
        guard let ptr = pyLong_FromLongLong(val) else {
            throw PythonError.nullPointer("Failed to convert int: \(val)")
        }
        
        let id = registerPythonObjectPointer(ptr)
        return id
    }
    
    internal func convertToSafePython(uint val: UInt64) throws -> SafePythonObject {
        let id = try convertToSafePythonID(uint: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(uint val: UInt64) throws -> PythonObjectUniqueID {
        guard let ptr = try pyLong_FromUnsignedLongLong(val) else {
            throw PythonError.nullPointer("Failed to convert int: \(val)")
        }
        
        let id = registerPythonObjectPointer(ptr)
        return id
    }
    
    internal func convertToSafePython(string val: String) throws -> SafePythonObject {
        let id = try convertToSafePythonID(string: val)
        return SafePythonObject(interpreter: self, id: id)
    }
    
    internal func convertToSafePythonID(string val: String) throws -> PythonObjectUniqueID {
        logger.trace("CPyton API call in synchronous mode: PyUnicode_FromStringAndSize")
        let cString = val.utf8CString
        return try cString.withUnsafeBufferPointer { bufferPtr in
            guard let ptr = api.PyUnicode_FromStringAndSize(bufferPtr.baseAddress, cString.count - 1) else {
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
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        guard let attrPtr = api.PyObject_GetAttrString(objPtr, name) else {
            throw PythonError.nullPointer("Failed ")
        }
        let attrId = registerPythonObjectPointer(attrPtr)
        return SafePythonObject(interpreter: self, id: attrId)
    }
    
    fileprivate func syncSetObjectAttribute(_ obj: SafePythonObject, _ name: String, _ value: SafePythonObject) throws {
        logger.trace("CPyton API call in synchronous mode: PyObject_SetAttrString")
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        let valuePtr = getRegisteredPythonObjectPointer(value.id)!
        _ = api.PyObject_SetAttrString(objPtr, name, valuePtr)
    }
    
    fileprivate func syncGetObjectItem(obj: SafePythonObject, key: [any SafePythonConvertible]) throws -> SafePythonObject {
        let pyKeyPtr: UnsafeMutableRawPointer
        
        switch key.count {
        case 0:
            fatalError("Subscript with zero keys is not valid")
        case 1:
            let pyKey = try! key[0].toSafePythonObject(interpreter: self)
            pyKeyPtr = getRegisteredPythonObjectPointer(pyKey.id)!
        default:
            pyKeyPtr = try! syncCallCreateTuplePtr(from: key)
        }
        
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_GetItem")
        guard let resultPtr = api.PyObject_GetItem(objPtr, pyKeyPtr) else {
            throw PythonError.nullPointer("Python subscript get failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    fileprivate func syncSetObjectItem(obj: SafePythonObject, key: [any SafePythonConvertible], newValue:SafePythonConvertible) throws {
        let pyKeyPtr: UnsafeMutableRawPointer
        
        switch key.count {
        case 0:
            fatalError("Subscript with zero keys is not valid")
        case 1:
            let pyKey = try! key[0].toSafePythonObject(interpreter: self)
            pyKeyPtr = getRegisteredPythonObjectPointer(pyKey.id)!
        default:
            pyKeyPtr = try! syncCallCreateTuplePtr(from: key)
        }
        
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        
        let newValuePyObj = try! newValue.toSafePythonObject(interpreter: self)
        let newValuePtr = getRegisteredPythonObjectPointer(newValuePyObj.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_SetItem")
        _ = api.PyObject_SetItem(objPtr, pyKeyPtr, newValuePtr)
    }
    
    // MARK: Callable support (synchronous mode)
    
    private func syncCallCreateTuplePtr(from elements: [any SafePythonConvertible]) throws -> UnsafeMutableRawPointer {
        let count = elements.count
        logger.trace("CPyton API call in synchronous mode: PyTuple_New")
        guard let tuplePtr = api.PyTuple_New(count) else {
            throw PythonError.nullPointer("Failed to create Python tuple")
        }
        
        logger.trace("CPyton API call in synchronous mode: PyTuple_SetItem in a loop.")
        for (index, element) in elements.enumerated() {
            
            // Convert args from SafePythonConvertible to SafePythonObject
            let pyObj = try element.toSafePythonObject(interpreter: self)
            guard let itemPtr = getRegisteredPythonObjectPointer(pyObj.id) else {
                throw PythonError.nullPointer("Argument conversion failed")
            }
            
            let res = api.PyTuple_SetItem(tuplePtr, index, itemPtr)
            if res != 0 {
                throw PythonError.stringConversionFailed("PyTuple_SetItem failed at index \(index)")
            }
        }
        
        return tuplePtr
    }
    
    private func syncCallCreateDictPtr(from dict: [String: any SafePythonConvertible]) throws -> UnsafeMutableRawPointer {
        logger.trace("CPyton API call in synchronous mode: PyDict_New")
        guard let dictPtr = api.PyDict_New() else {
            throw PythonError.nullPointer("Failed to create Python dict")
        }
        
        for (key, value) in dict {
            let keyObj = try convertToSafePython(string: key)           // or use your existing string converter
            let valueObj = try value.toSafePythonObject(interpreter: self)
            
            let keyPtr = getRegisteredPythonObjectPointer(keyObj.id)!
            let valuePtr = getRegisteredPythonObjectPointer(valueObj.id)!
            
            let res = api.PyDict_SetItem(dictPtr, keyPtr, valuePtr)
            if res != 0 {
                throw PythonError.stringConversionFailed("PyDict_SetItem failed for key: \(key)")
            }
        }
        
        return dictPtr
    }
    
    fileprivate func syncCall(callable: SafePythonObject) throws -> SafePythonObject {
        if let pyCall = api.PyObject_CallNoArgs {
            let callablePtr = getRegisteredPythonObjectPointer(callable.id)!
            
            logger.trace("CPyton API call in synchronous mode: PyObject_CallNoArgs")
            guard let resultPtr = pyCall(callablePtr) else {
                throw PythonError.nullPointer("Python call failed")
            }
            let resultId = registerPythonObjectPointer(resultPtr)
            return SafePythonObject(interpreter: self, id: resultId)
        } else {
            logger.debug("PyObject_CallNoArgs not available → falling back to syncCall with empty args")
            return try syncCall(callable: callable, args: [])
        }
    }
    
    fileprivate func syncCall(callable: SafePythonObject, args: [any SafePythonConvertible]) throws -> SafePythonObject {
        
        // Put args in a tuple
        let argTuplePtr = try syncCallCreateTuplePtr(from: args)
        
        let callablePtr = getRegisteredPythonObjectPointer(callable.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_CallObject")
        guard let resultPtr = api.PyObject_CallObject(callablePtr, argTuplePtr) else {
            throw PythonError.nullPointer("Python call failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    fileprivate func syncCall(callable: SafePythonObject,
                             args: [any SafePythonConvertible],
                             kwargs: [String: any SafePythonConvertible]) throws -> SafePythonObject {
        
        // Put args in a tuple
        let argTuplePtr = try syncCallCreateTuplePtr(from: args)
        
        // Create kwargs dictionary (can be NULL if no keyword args)
        let kwDictPtr: UnsafeMutableRawPointer? = kwargs.isEmpty ? nil : try syncCallCreateDictPtr(from: kwargs)
        
        let callablePtr = getRegisteredPythonObjectPointer(callable.id)!
        
        logger.trace("CPython API call (sync): PyObject_Call")
        
        logger.trace("CPyton API call in synchronous mode: PyObject_Call")
        guard let resultPtr = api.PyObject_Call(callablePtr, argTuplePtr, kwDictPtr) else {
            throw PythonError.nullPointer("Python call failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    // MARK: Operator support (synchronous mode)
    // Operators for synchronous mode ----------
    
    internal func syncAdd(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Add")
        guard let sumPtr = api.PyNumber_Add(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '+' failed")
        }
        
        let sumId = registerPythonObjectPointer(sumPtr)
        return SafePythonObject(interpreter: self, id: sumId)
    }
    
    internal func syncBitwiseAnd(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_And")
        guard let resultPtr = api.PyNumber_And(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '&' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncBitwiseNot(_ operand: SafePythonObject) throws -> SafePythonObject {
        let operandPtr = getRegisteredPythonObjectPointer(operand.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Invert")
        guard let resultPtr = api.PyNumber_Invert(operandPtr) else {
            throw PythonError.nullPointer("Python '~' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncBitwiseOr(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Or")
        guard let resultPtr = api.PyNumber_Or(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '|' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncBitwiseXor(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Xor")
        guard let resultPtr = api.PyNumber_Xor(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '^' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncDivide(dividend: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let dividendPtr = getRegisteredPythonObjectPointer(dividend.id)!
        let divisorPtr = getRegisteredPythonObjectPointer(divisor.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_TrueDivide")
        guard let quotientPtr = api.PyNumber_TrueDivide(dividendPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '/' failed")
        }
        
        let quotientId = registerPythonObjectPointer(quotientPtr)
        return SafePythonObject(interpreter: self, id: quotientId)
    }
    
    internal func syncDoubleEquals(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.equal.rawValue) else {
            throw PythonError.nullPointer("Python '==' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncDoubleEqualsEquatable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.equal.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncGreaterThan(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThan.rawValue) else {
            throw PythonError.nullPointer("Python '>' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncGreaterThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThan.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncGreaterThanOrEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThanOrEqual.rawValue) else {
            throw PythonError.nullPointer("Python '>=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncGreaterThanOrEqualComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.greaterThanOrEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncInPlaceAdd(sumend: SafePythonObject, addend: SafePythonObject) throws -> SafePythonObject {
        let sumendPtr = getRegisteredPythonObjectPointer(sumend.id)!
        let addendPtr = getRegisteredPythonObjectPointer(addend.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceAdd")
        guard let sumPtr = api.PyNumber_InPlaceAdd(sumendPtr, addendPtr) else {
            throw PythonError.nullPointer("Python '+=' failed")
        }
        
        let sumId = registerPythonObjectPointer(sumPtr)
        return SafePythonObject(interpreter: self, id: sumId)
    }
    
    internal func syncInPlaceBitwiseAnd(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceAnd")
        guard let resultPtr = api.PyNumber_InPlaceAnd(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '&=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncInPlaceBitwiseOr(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceOr")
        guard let resultPtr = api.PyNumber_InPlaceOr(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '|=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncInPlaceBitwiseXor(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceXor")
        guard let resultPtr = api.PyNumber_InPlaceXor(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '^=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncInPlaceDivide(quotientand: SafePythonObject, divisor: SafePythonObject) throws -> SafePythonObject {
        let quotientandPtr = getRegisteredPythonObjectPointer(quotientand.id)!
        let divisorPtr = getRegisteredPythonObjectPointer(divisor.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceTrueDivide")
        guard let quotientPtr = api.PyNumber_InPlaceTrueDivide(quotientandPtr, divisorPtr) else {
            throw PythonError.nullPointer("Python '/=' failed")
        }
        
        let quotientId = registerPythonObjectPointer(quotientPtr)
        return SafePythonObject(interpreter: self, id: quotientId)
    }
    
    internal func syncInPlaceMultiply(productand: SafePythonObject, multiplicand: SafePythonObject) throws -> SafePythonObject {
        let productandPtr = getRegisteredPythonObjectPointer(productand.id)!
        let multiplicandPtr = getRegisteredPythonObjectPointer(multiplicand.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceMultiply")
        guard let productPtr = api.PyNumber_InPlaceMultiply(productandPtr, multiplicandPtr) else {
            throw PythonError.nullPointer("Python '*=' failed")
        }
        
        let productId = registerPythonObjectPointer(productPtr)
        return SafePythonObject(interpreter: self, id: productId)
    }
    
    internal func syncInPlaceSubtract(diffend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        let diffendPtr = getRegisteredPythonObjectPointer(diffend.id)!
        let subtrahendPtr = getRegisteredPythonObjectPointer(subtrahend.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_InPlaceSubtract")
        guard let differencePtr = api.PyNumber_InPlaceSubtract(diffendPtr, subtrahendPtr) else {
            throw PythonError.nullPointer("Python '-=' failed")
        }
        
        let differenceId = registerPythonObjectPointer(differencePtr)
        return SafePythonObject(interpreter: self, id: differenceId)
    }
    
    internal func syncLessThan(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.lessThan.rawValue) else {
            throw PythonError.nullPointer("Python '<' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncLessThanComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.lessThan.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncLessThanOrEqual(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.lessThanOrEqual.rawValue) else {
            throw PythonError.nullPointer("Python '<=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncLessThanOrEqualComparable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.lessThanOrEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncMultiply(_ lhs: SafePythonObject, _ rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Multiply")
        guard let productPtr = api.PyNumber_Multiply(lhsPtr, rhsPtr) else {
            throw PythonError.nullPointer("Python '*' failed")
        }
        
        let productId = registerPythonObjectPointer(productPtr)
        return SafePythonObject(interpreter: self, id: productId)
    }
    
    internal func syncNotEquals(lhs: SafePythonObject, rhs: SafePythonObject) throws -> SafePythonObject {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompare")
        guard let resultPtr = api.PyObject_RichCompare(lhsPtr, rhsPtr, PythonRichCompareOp.notEqual.rawValue) else {
            throw PythonError.nullPointer("Python '!=' failed")
        }
        
        let resultId = registerPythonObjectPointer(resultPtr)
        return SafePythonObject(interpreter: self, id: resultId)
    }
    
    internal func syncNotEqualsEquatable(lhs: SafePythonObject, rhs: SafePythonObject) throws -> Bool {
        let lhsPtr = getRegisteredPythonObjectPointer(lhs.id)!
        let rhsPtr = getRegisteredPythonObjectPointer(rhs.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyObject_RichCompareBool")
        
        switch api.PyObject_RichCompareBool(lhsPtr, rhsPtr, PythonRichCompareOp.notEqual.rawValue) {
        case 0: return false
        case 1: return true
        default: try throwPythonError()
        }
    }
    
    internal func syncSubtract(minuend: SafePythonObject, subtrahend: SafePythonObject) throws -> SafePythonObject {
        let minuendPtr = getRegisteredPythonObjectPointer(minuend.id)!
        let subtrahendPtr = getRegisteredPythonObjectPointer(subtrahend.id)!
        
        logger.trace("CPyton API call in synchronous mode: PyNumber_Subtract")
        guard let differencePtr = api.PyNumber_Subtract(minuendPtr, subtrahendPtr) else {
            throw PythonError.nullPointer("Python '-' failed")
        }
        
        let differenceId = registerPythonObjectPointer(differencePtr)
        return SafePythonObject(interpreter: self, id: differenceId)
    }
    
    // MARK: Bytes support (synchronous mode)
    
//    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
//    internal func isBytes(_ obj: SafePythonObject) throws -> Bool {
//        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
//        return pyBytes_Check(objPtr)
//    }
//    
//    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
//    internal func isBytesArray(_ obj: SafePythonObject) throws -> Bool {
//        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
//        return pyByteArray_Check(objPtr)
//    }
    
    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func bytesObjectSize(_ obj: SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        return try pyBytes_Size(objPtr)
    }
    
    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func byteArrayObjectSize(_ obj: SafePythonObject) throws -> Int {
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        return try pyByteArray_Size(objPtr)
    }
    
    @available(*, noasync, message: "Synchronous Python operations must be performed inside withIsolatedContext(). Direct calls from async contexts are unsafe.")
    internal func withUnsafeBytes<R>(_ obj: SafePythonObject, body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) throws -> R {
        let objPtr = getRegisteredPythonObjectPointer(obj.id)!
        
        var view = Py_buffer()
        
        guard api.PyObject_GetBuffer(objPtr, &view, PyBUF_SIMPLE) == 0 else {
            fatalError()
        }
        defer {
            api.PyBuffer_Release(&view)
        }
        
        guard let base = view.buf else {
            throw PythonError.nullPointer("Buffer pointer is null")
        }
        
        let ptr = base.assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: ptr, count: Int(view.len))
        
        return try body(buffer)
    }
}

