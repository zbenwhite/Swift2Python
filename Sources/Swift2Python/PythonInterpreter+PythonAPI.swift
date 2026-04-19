//
//  PythonInterpreter+PythonAPI.swift
//  Swift2Python
//
//  Created by Ben White on 4/16/26.
//
//

import Logging


extension PythonInterpreter {
    
    internal struct PreloadedPythonSymbols {
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
        let PyNumber_InPlacePower: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceRemainder: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceSubtract: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceTrueDivide: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceXor: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Invert: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Multiply: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Or: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Power: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyNumber_Remainder: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
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
        
        // Optional (present on Python >= 3.13 and often backported to older builds)
        let Py_GetConstant: (@convention(c) (Int32) -> UnsafeMutableRawPointer?)?
        
        // Used for Py_None
        let _Py_NoneStruct: UnsafeMutableRawPointer?
        
        let logger: Logger
        
        
        
        
        
        internal func python_DecRef(_ pointer: UnsafeMutableRawPointer) throws {
            logger.trace("CPython API Call: Py_DecRef")
            Py_DecRef(pointer)
        }
        
        internal func pythonBool_FromLong(_ value: Bool) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyBool_FromLong")
            return PyBool_FromLong(value ? 1 : 0)
        }
        
        internal func pythonBytes_Size(_ pointer: UnsafeMutableRawPointer) throws -> Int {
            logger.trace("CPython API Call: PyBytes_Size")
            return Int(PyBytes_Size(pointer))
        }
        
        internal func pythonByteArray_Size(_ pointer: UnsafeMutableRawPointer) throws -> Int {
            logger.trace("CPython API Call: PyByteArray_Size")
            return Int(PyByteArray_Size(pointer))
        }
        
        internal func pythonDict_New() throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython wrapper called: PyDict_New")
            return PyDict_New()
        }
        
        internal func pythonDict_SetItem(_ dictPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer, _ valuePtr: UnsafeMutableRawPointer) throws -> Int32 {
            logger.trace("CPython API Call: PyDict_SetItem")
            // Signature: int PyDict_SetItem(PyObject *p, PyObject *key, PyObject *val)
            return PyDict_SetItem(dictPtr, keyPtr, valuePtr)
        }
        
        internal func pythonErr_Clear() throws {
            logger.trace("CPython API Call: PyErr_Clear")
            PyErr_Clear()
        }
        
        internal func pythonErr_Occurred() throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyErr_Occurred")
            return PyErr_Occurred()
        }
        
        internal func pythonFloat_FromDouble(_ value: Double) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyFloat_FromDouble")
            return PyFloat_FromDouble(value)
        }
        
        internal func pythonFloat_AsDouble(_ pointer: UnsafeMutableRawPointer) -> Double {
            logger.trace("CPython API Call: PyFloat_AsDouble")
            return PyFloat_AsDouble(pointer)
        }
        
        internal func pythonGILState_Ensure() -> PyGILState_STATE {
            logger.trace("CPython API Call: PyGILState_Ensure")
            return PyGILState_Ensure()
        }
        
        internal func pythonGILState_Release(_ gstate: PyGILState_STATE) {
            logger.trace("CPython API Call: PyGILState_Release")
            PyGILState_Release(gstate)
        }
        
        internal func pythonImport_AddModule(_ module: String) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyImport_AddModule")
            return module.withCString({ PyImport_AddModule($0) })
        }
        
        internal func pythonImport_ImportModule(_ module: String) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyImport_ImportModule")
            return module.withCString({ PyImport_ImportModule($0) })
        }
        
        internal func pythonList_New(_ length: Int) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyList_New")
            return PyList_New(length)
        }
        
        internal func pythonList_SetItem(_ listPtr: UnsafeMutableRawPointer, _ index: Int, _ valuePtr: UnsafeMutableRawPointer) throws -> Int32 {
            logger.trace("CPython API Call: PyList_SetItem")
            return PyList_SetItem(listPtr, index, valuePtr)
        }
        
        internal func pythonLong_AsLong(_ valuePtr: UnsafeMutableRawPointer) throws -> Int {
            logger.trace("CPython API Call: PyLong_AsLong")
            return PyLong_AsLong(valuePtr)
        }
        
        internal func pythonLong_AsLongLong(_ valuePtr: UnsafeMutableRawPointer) throws -> Int64 {
            logger.trace("CPython API Call: PyLong_AsLongLong")
            return PyLong_AsLongLong(valuePtr)
        }
        
        internal func pythonLong_AsUnsignedLongLong(_ valuePtr: UnsafeMutableRawPointer) throws -> UInt64 {
            logger.trace("CPython API Call: PyLong_AsUnsignedLongLong")
            return PyLong_AsUnsignedLongLong(valuePtr)
        }
        
        internal func pythonLong_FromLong(_ value: Int) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyLong_FromLong")
            return PyLong_FromLong(value)
        }
        
        internal func pythonLong_FromLongLong(_ value: Int64) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyLong_FromLongLong")
            return PyLong_FromLongLong(value)
        }
        
        internal func pythonLong_FromUnsignedLongLong(_ value: UInt64) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyLong_FromUnsignedLongLong")
            return PyLong_FromUnsignedLongLong(value)
        }
        
        internal func pythonNumber_InPlacePower(_ lhs: UnsafeMutableRawPointer, _ rhs: UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: Number_InPlacePower")
            //return PyNumber_InPlacePower(lhs, rhs, Py_None)
            if let pyNone = try pythonNone() {
                logger.trace("CPython API Call: Number_InPlacePower")
                return PyNumber_Power(lhs, rhs, pyNone)
            } else {
                // FIXME: put two args in a tuple and call builtins.pow with it
                logger.error("Py_None is not found so we can't use PyNumber_InPlacePower")
                return nil
            }
        }
        
        internal func pythonNumber_Power(_ lhs: UnsafeMutableRawPointer, _ rhs: UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer? {
            if let pyNone = try pythonNone() {
                logger.trace("CPython API Call: Number_Power")
                return PyNumber_Power(lhs, rhs, pyNone)
            } else {
                // FIXME: put two args in a tuple and call builtins.pow with it
                logger.error("Py_None is not found so we can't use PyNumber_Power")
                return nil
            }
        }
        
        internal func pythonObject_Call(_ callable: UnsafeMutableRawPointer, _ args: UnsafeMutableRawPointer, _ kwargs: UnsafeMutableRawPointer?) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_Call")
            // Signature: PyObject *PyObject_Call(PyObject *callable, PyObject *args, PyObject *kwargs)
            return PyObject_Call(callable, args, kwargs)
        }
        
        internal func pythonObject_CallObject(_ objPtr: UnsafeMutableRawPointer, _ args: UnsafeMutableRawPointer? = nil) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_CallObject")
            // Signature: PyObject* PyObject_CallObject(PyObject *callable_object, PyObject *args)
            return PyObject_CallObject(objPtr, args)
        }
        
        internal func pythonObject_GetAttrString(_ pointer: UnsafeMutableRawPointer, _ name: String) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_GetAttrString")
            return PyObject_GetAttrString(pointer, name.withCString({ $0 }))
        }
        
        internal func pythonObject_GetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_GetItem")
            return PyObject_GetItem(obPtr, keyPtr)
        }
        
        internal func pythonObject_SetAttrString(_ obPtr: UnsafeMutableRawPointer, _ name: String, _ rvalPtr: UnsafeMutableRawPointer) throws -> Int32? {
            logger.trace("CPython API Call: PyObject_SetAttrString")
            return PyObject_SetAttrString(obPtr, name.withCString({ $0 }), rvalPtr)
        }
        
        internal func pythonObject_SetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer, _ rvalPtr: UnsafeMutableRawPointer) throws -> Int32? {
            logger.trace("CPython API Call: PyObject_SetItem")
            return PyObject_SetItem(obPtr, keyPtr, rvalPtr)
        }
        
        internal func pythonObject_Str(_ obPtr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_Str")
            return PyObject_Str(obPtr)
        }
        
        internal func pythonRun_SimpleString(_ command: String) throws -> Int32 {
            logger.trace("CPython API Call: PyRun_SimpleString")
            return command.withCString { PyRun_SimpleString($0) }
        }
        
        internal func pythonTuple_New(_ length: Int) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyTuple_New")
            return PyTuple_New(length)
        }
        
        internal func pythonTuple_SetItem(_ tuple: UnsafeMutableRawPointer, _ index: Int, _ item: UnsafeMutableRawPointer) throws -> Int32 {
            logger.trace("CPython API Call: PyTuple_SetItem")
            return PyTuple_SetItem(tuple, index, item)
        }
        
        internal func pythonUnicode_FromStringAndSize(_ st: String) throws -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyUnicode_FromStringAndSize")
            let cString = st.utf8CString
            return cString.withUnsafeBufferPointer { bufferPtr in
                PyUnicode_FromStringAndSize(bufferPtr.baseAddress, cString.count - 1)
            }
        }
        
        internal func pythonUnicode_AsUTF8AndSize(_ objPtr: UnsafeMutableRawPointer) throws -> (String)? {
            logger.trace("CPython API Call: PyUnicode_AsUTF8AndSize")
            var size: Py_ssize_t = 0
            let utf8 = PyUnicode_AsUTF8AndSize(objPtr, &size)
            
            guard let utf8 else {
                return nil
            }
            return String(cString: utf8)
        }
        
        internal func pythonNone() throws -> UnsafeMutableRawPointer? {
            logger.trace("Obtaining Py_None")

            // Preferred path: Py_GetConstant (Stable ABI, Python 3.13+)
            if let getConstant = Py_GetConstant {
                if let none = getConstant(0) {          // 0 == Py_CONSTANT_NONE
                    return none                         // returns a strong reference (None is immortal)
                }
            }

            // Fallback: classic private symbol (works on vast majority of 3.8–3.12 builds,
            // including most free-threaded installations)
            if let nonePtr = _Py_NoneStruct {
                return nonePtr
            }

            // Last resort – very rare to reach here
            return nil
        }
    }
    
    internal static func loadAllSymbols(using runtime: PythonRuntime, _ logger: Logger) async throws -> PreloadedPythonSymbols {
    //        internal static func loadAllSymbols(using runtime: PythonRuntime) async throws -> PreloadedPythonSymbols {
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
            PyNumber_InPlacePower: try await runtime.loadSendableSymbol(
                "PyNumber_InPlacePower", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self ).function,
            PyNumber_InPlaceRemainder: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceRemainder", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self ).function,
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
            PyNumber_Power: try await runtime.loadSendableSymbol(
                    "PyNumber_Power", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Remainder: try await runtime.loadSendableSymbol(
                    "PyNumber_Remainder", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
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
                "PyErr_GetRaisedException", as: (@convention(c) () -> UnsafeMutableRawPointer?).self).function),
            Py_GetConstant: try? await runtime.loadSendableSymbol(
                "Py_GetConstant", as: (@convention(c) (Int32) -> UnsafeMutableRawPointer?).self).function,
            
            _Py_NoneStruct: try? await runtime.loadSendableSymbol("_Py_NoneStruct", as: UnsafeMutableRawPointer.self).function,
            
            // Other
            logger: logger
        )
    }
}

