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
        let Py_IncRef: (@convention(c) (UnsafeMutableRawPointer) -> Void)
        let PyBool_FromLong: (@convention(c) (Int) -> UnsafeMutableRawPointer?)
        let PyBuffer_Release: (@convention(c) (UnsafeMutableRawPointer) -> Void)
        let PyBytes_Size: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyByteArray_Size: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyDict_New: (@convention(c) () -> UnsafeMutableRawPointer?)
        let PyDict_SetItem: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyDict_Size: (@convention(c) (UnsafeMutableRawPointer?) -> Int)
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
        let PyList_Append: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyList_GetItem: (@convention(c) (UnsafeMutableRawPointer?, Int) -> UnsafeMutableRawPointer?)
        let PyList_Insert: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32)
        let PyList_New: (@convention(c) (Int) -> UnsafeMutableRawPointer?)
        let PyList_SetItem: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32)
        let PyList_Size: (@convention(c) (UnsafeMutableRawPointer?) -> Int)
        let PyLong_AsLongLong: (@convention(c) (UnsafeMutableRawPointer) -> Int64)
        let PyLong_AsUnsignedLongLong: (@convention(c) (UnsafeMutableRawPointer) -> UInt64)
        let PyLong_FromLongLong: (@convention(c) (Int64) -> UnsafeMutableRawPointer?)
        let PyLong_FromUnsignedLongLong: (@convention(c) (UInt64) -> UnsafeMutableRawPointer?)
        let PyMapping_Items: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyMapping_Keys: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyMapping_Values: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
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
        let PyObject_IsInstance: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Int32)
        let PyObject_IsTrue: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyObject_Not: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyObject_RichCompare: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32) -> UnsafeMutableRawPointer?)
        let PyObject_RichCompareBool: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32) -> Int32)
        let PyObject_SetAttrString: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Int32)
        let PyObject_SetItem: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyObject_Str: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyRun_SimpleString: (@convention(c) (UnsafePointer<CChar>) -> Int32)
        let PyTuple_GetItem: (@convention(c) (UnsafeMutableRawPointer?, Int) -> UnsafeMutableRawPointer?)
        let PyTuple_New: (@convention(c) (Int) -> UnsafeMutableRawPointer?)
        let PyTuple_SetItem: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32)
        let PyTuple_Size: (@convention(c) (UnsafeMutableRawPointer?) -> Int)
        let PyUnicode_AsUTF8AndSize: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutablePointer<Py_ssize_t>?) -> UnsafePointer<CChar>?)
        let PyUnicode_FromStringAndSize: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?)

        // Optional (only present on Python >= 3.9)
        let PyObject_CallNoArgs: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        
        // Optional (only present on Python >= 3.12)
        let PyErr_GetRaisedException: (@convention(c) () -> UnsafeMutableRawPointer?)?
        
        // Optional (present on Python >= 3.13 and often backported to older builds)
        let Py_GetConstant: (@convention(c) (Int32) -> UnsafeMutableRawPointer?)?
        
        // Optional (only present on Python >= 3.14)
        let Py_REFCNT: (@convention(c) (UnsafeMutableRawPointer) -> Int32)?
        
        // Optional (only present on Python >= 3.9)
//        let PyObject_CallOneArg: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)?
        
        let PyDict_Type: UnsafeMutableRawPointer
        let PyList_Type: UnsafeMutableRawPointer
        let PyTuple_Type: UnsafeMutableRawPointer
        
        // Used for Py_None
        let _Py_NoneStruct: UnsafeMutableRawPointer?
        
        let logger: Logger
        
        
        
        internal func python_DecRef(_ pointer: UnsafeMutableRawPointer) {
            logger.trace("CPython API Call: Py_DecRef")
            Py_DecRef(pointer)
        }
        
        internal func pythonBool_FromLong(_ value: Bool) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyBool_FromLong")
            return PyBool_FromLong(value ? 1 : 0)
        }
        
        internal func pythonBytes_Size(_ pointer: UnsafeMutableRawPointer) -> Int {
            logger.trace("CPython API Call: PyBytes_Size")
            return Int(PyBytes_Size(pointer))
        }
        
        internal func pythonByteArray_Size(_ pointer: UnsafeMutableRawPointer) -> Int {
            logger.trace("CPython API Call: PyByteArray_Size")
            return Int(PyByteArray_Size(pointer))
        }
        
        internal func pythonDict_New() -> UnsafeMutableRawPointer? {
            logger.trace("CPython wrapper called: PyDict_New")
            return PyDict_New()
        }
        
        internal func pythonDict_SetItem(_ dictPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer, _ valuePtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyDict_SetItem")
            return PyDict_SetItem(dictPtr, keyPtr, valuePtr)
        }
        
        internal func pythonDict_Size(_ dict: UnsafeMutableRawPointer) -> Int {
            logger.trace("CPython API Call: PyDict_Size")
            return PyDict_Size(dict)
        }
        
        internal func pythonErr_Clear() throws {
            logger.trace("CPython API Call: PyErr_Clear")
            PyErr_Clear()
        }
        
        internal func pythonErr_Occurred() -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyErr_Occurred")
            return PyErr_Occurred()
        }
        
        internal func pythonFloat_FromDouble(_ value: Double) -> UnsafeMutableRawPointer? {
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
        
        internal func pythonImport_AddModule(_ module: String) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyImport_AddModule")
            return module.withCString({ PyImport_AddModule($0) })
        }
        
        internal func pythonImport_ImportModule(_ module: String) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyImport_ImportModule")
            return module.withCString({ PyImport_ImportModule($0) })
        }
        
        internal func pythonList_Append(_ listPtr: UnsafeMutableRawPointer, _ itemPtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyList_Append")
            return PyList_Append(listPtr, itemPtr)
        }
        
        internal func pythonList_GetItem(_ listPtr: UnsafeMutableRawPointer, _ index: Int) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyList_GetItem")
            return PyList_GetItem(listPtr, index)
        }
        
        internal func pythonList_Insert(_ listPtr: UnsafeMutableRawPointer, _ index: Int, _ itemPtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyList_Insert")
            return PyList_Insert(listPtr, index, itemPtr)
        }
        
        internal func pythonList_New(_ length: Int) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyList_New")
            return PyList_New(length)
        }
        
        internal func pythonList_SetItem(_ listPtr: UnsafeMutableRawPointer, _ index: Int, _ valuePtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyList_SetItem")
            return PyList_SetItem(listPtr, index, valuePtr)
        }
        
        internal func pythonList_Size(_ list: UnsafeMutableRawPointer) -> Int {
            logger.trace("CPython API Call: PyList_Size")
            return PyList_Size(list)
        }
        
        internal func pythonLong_AsLongLong(_ valuePtr: UnsafeMutableRawPointer) -> Int64 {
            logger.trace("CPython API Call: PyLong_AsLongLong")
            return PyLong_AsLongLong(valuePtr)
        }
        
        internal func pythonLong_AsUnsignedLongLong(_ valuePtr: UnsafeMutableRawPointer) -> UInt64 {
            logger.trace("CPython API Call: PyLong_AsUnsignedLongLong")
            return PyLong_AsUnsignedLongLong(valuePtr)
        }
        
        internal func pythonLong_FromLongLong(_ value: Int64) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyLong_FromLongLong")
            return PyLong_FromLongLong(value)
        }
        
        internal func pythonLong_FromUnsignedLongLong(_ value: UInt64) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyLong_FromUnsignedLongLong")
            return PyLong_FromUnsignedLongLong(value)
        }
        
        internal func pythonMapping_Items(_ object: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyMapping_Items")
            return PyMapping_Items(object)
        }
        
        internal func pythonMapping_Keys(_ object: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyMapping_Keys")
            return PyMapping_Keys(object)
        }
        
        internal func pythonMapping_Values(_ object: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyMapping_Values")
            return PyMapping_Values(object)
        }
        
        internal func pythonNumber_InPlacePower(_ lhs: UnsafeMutableRawPointer, _ rhs: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: Number_InPlacePower")
            if let pyNone = pythonNone() {
                logger.trace("CPython API Call: Number_InPlacePower")
                return PyNumber_Power(lhs, rhs, pyNone)
            } else {
                // FIXME: put two args in a tuple and call builtins.pow with it
                logger.error("Py_None is not found so we can't use PyNumber_InPlacePower")
                return nil
            }
        }
        
        internal func pythonNumber_Power(_ lhs: UnsafeMutableRawPointer, _ rhs: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            if let pyNone = pythonNone() {
                logger.trace("CPython API Call: Number_Power")
                return PyNumber_Power(lhs, rhs, pyNone)
            } else {
                // FIXME: put two args in a tuple and call builtins.pow with it
                logger.error("Py_None is not found so we can't use PyNumber_Power")
                return nil
            }
        }
        
        internal func pythonObject_Call(_ callable: UnsafeMutableRawPointer, _ args: UnsafeMutableRawPointer, _ kwargs: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_Call")
            return PyObject_Call(callable, args, kwargs)
        }
        
        internal func pythonObject_CallObject(_ objPtr: UnsafeMutableRawPointer, _ args: UnsafeMutableRawPointer? = nil) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_CallObject")
            return PyObject_CallObject(objPtr, args)
        }
        
        internal func pythonObject_GetAttrString(_ pointer: UnsafeMutableRawPointer, _ name: String) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_GetAttrString")
            return PyObject_GetAttrString(pointer, name.withCString({ $0 }))
        }
        
        internal func pythonObject_GetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_GetItem")
            return PyObject_GetItem(obPtr, keyPtr)
        }
        
        internal func pythonObject_IsTrue(_ obPtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyObject_IsTrue")
            return PyObject_IsTrue(obPtr)
        }
            
        internal func pythonObject_Not(_ obPtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyObject_Not")
            return PyObject_Not(obPtr)
        }
        
        internal func pythonObject_SetAttrString(_ obPtr: UnsafeMutableRawPointer, _ name: String, _ rvalPtr: UnsafeMutableRawPointer) -> Int32? {
            logger.trace("CPython API Call: PyObject_SetAttrString")
            return PyObject_SetAttrString(obPtr, name.withCString({ $0 }), rvalPtr)
        }
        
        internal func pythonObject_SetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer, _ rvalPtr: UnsafeMutableRawPointer) -> Int32? {
            logger.trace("CPython API Call: PyObject_SetItem")
            return PyObject_SetItem(obPtr, keyPtr, rvalPtr)
        }
        
        internal func pythonObject_Str(_ obPtr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_Str")
            return PyObject_Str(obPtr)
        }
        
        internal func pythonRun_SimpleString(_ command: String) -> Int32 {
            logger.trace("CPython API Call: PyRun_SimpleString")
            return command.withCString { PyRun_SimpleString($0) }
        }
        
        internal func pythonObject_IsInstance(_ object: UnsafeMutableRawPointer, _ classInfo: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyObject_IsInstance")
            return PyObject_IsInstance(object, classInfo)
        }
        
        internal func pythonTuple_GetItem(_ tuple: UnsafeMutableRawPointer, _ index: Int) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyTuple_GetItem")
            return PyTuple_GetItem(tuple, index)
        }
        
        internal func pythonTuple_New(_ length: Int) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyTuple_New")
            return PyTuple_New(length)
        }
        
        internal func pythonTuple_SetItem(_ tuple: UnsafeMutableRawPointer, _ index: Int, _ item: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyTuple_SetItem")
            return PyTuple_SetItem(tuple, index, item)
        }
        
        internal func pythonTuple_Size(_ tuple: UnsafeMutableRawPointer) -> Int {
            logger.trace("CPython API Call: PyTuple_Size")
            return PyTuple_Size(tuple)
        }
        
        internal func pythonUnicode_FromStringAndSize(_ st: String) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyUnicode_FromStringAndSize")
            let cString = st.utf8CString
            return cString.withUnsafeBufferPointer { bufferPtr in
                PyUnicode_FromStringAndSize(bufferPtr.baseAddress, cString.count - 1)
            }
        }
        
        internal func pythonUnicode_AsUTF8AndSize(_ objPtr: UnsafeMutableRawPointer) -> (String)? {
            logger.trace("CPython API Call: PyUnicode_AsUTF8AndSize")
            var size: Py_ssize_t = 0
            let utf8 = PyUnicode_AsUTF8AndSize(objPtr, &size)
            
            guard let utf8 else {
                return nil
            }
            return String(cString: utf8)
        }
        
        internal func pythonNone() -> UnsafeMutableRawPointer? {
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
        
        internal func pythonReferenceCount(_ obj: UnsafeMutableRawPointer) throws -> Int32 {
            if let refCountFunction = Py_REFCNT {
                return refCountFunction(obj)
            } else {
                throw PythonError.symbolNotFound("Py_REFCNT")
//                let sys = PyImport_ImportModule("sys")
//                guard let callable = PyObject_GetAttrString(sys, "getrefcount") else {
//                    throw PythonError.symbolNotFound("sys.getrefcount()")
//                }
//                if let call_OneArgFunc = PyObject_CallOneArg {
//                    let intObj = call_OneArgFunc(callable, obj)
//                    return Int(intObj)
//                } else {
//                    var tuplePtr = PyTuple_New(1)
//                    let _ = PyTuple_SetItem(tuplePtr, 0, obj)
//                    let intObj = pythonObject_Call(callable, tuplePtr, nil)
//                    return Int(intObj)
//                }
            }
        }
    }
    
    internal static func loadAllSymbols(using runtime: PythonRuntime, _ logger: Logger) async throws -> PreloadedPythonSymbols {
    //        internal static func loadAllSymbols(using runtime: PythonRuntime) async throws -> PreloadedPythonSymbols {
        return PreloadedPythonSymbols(
            Py_DecRef: try await runtime.loadSendableSymbol(
                "Py_DecRef", as: (@convention(c) (UnsafeMutableRawPointer) -> Void).self).function,
            Py_IncRef: try await runtime.loadSendableSymbol(
                "Py_IncRef", as: (@convention(c) (UnsafeMutableRawPointer) -> Void).self).function,
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
            PyDict_Size: try await runtime.loadSendableSymbol(
                "PyDict_Size", as: (@convention(c) (UnsafeMutableRawPointer?) -> Int).self).function,
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
            PyList_Append: try await runtime.loadSendableSymbol(
                "PyList_Append", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyList_GetItem: try await runtime.loadSendableSymbol(
                "PyList_GetItem", as: (@convention(c) (UnsafeMutableRawPointer?, Int) -> UnsafeMutableRawPointer?).self).function,
            PyList_Insert: try await runtime.loadSendableSymbol(
                "PyList_Insert", as: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyList_New: try await runtime.loadSendableSymbol(
                "PyList_New", as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self).function,
            PyList_SetItem: try await runtime.loadSendableSymbol(
                "PyList_SetItem", as: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyList_Size: try await runtime.loadSendableSymbol(
                "PyList_Size", as: (@convention(c) (UnsafeMutableRawPointer?) -> Int).self).function,
            PyLong_AsLongLong: try await runtime.loadSendableSymbol(
                "PyLong_AsLongLong", as: (@convention(c) (UnsafeMutableRawPointer) -> Int64).self).function,
            PyLong_AsUnsignedLongLong: try await runtime.loadSendableSymbol(
                "PyLong_AsUnsignedLongLong", as: (@convention(c) (UnsafeMutableRawPointer) -> UInt64).self).function,
            PyLong_FromLongLong: try await runtime.loadSendableSymbol(
                "PyLong_FromLongLong", as: (@convention(c) (Int64) -> UnsafeMutableRawPointer?).self).function,
            PyLong_FromUnsignedLongLong: try await runtime.loadSendableSymbol(
                "PyLong_FromUnsignedLongLong", as: (@convention(c) (UInt64) -> UnsafeMutableRawPointer?).self).function,
            PyMapping_Items: try await runtime.loadSendableSymbol(
                "PyMapping_Items", as: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyMapping_Keys: try await runtime.loadSendableSymbol(
                "PyMapping_Keys", as: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyMapping_Values: try await runtime.loadSendableSymbol(
                "PyMapping_Values", as: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
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
            PyObject_IsInstance: try await runtime.loadSendableSymbol(
                "PyObject_IsInstance", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Int32).self).function,
            PyObject_IsTrue: try await runtime.loadSendableSymbol(
                "PyObject_IsTrue", as: (@convention(c) (UnsafeMutableRawPointer) -> Int32).self).function,
            PyObject_Not: try await runtime.loadSendableSymbol(
                "PyObject_Not", as: (@convention(c) (UnsafeMutableRawPointer) -> Int32).self).function,
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
            PyTuple_GetItem: try await runtime.loadSendableSymbol(
                "PyTuple_GetItem", as: (@convention(c) (UnsafeMutableRawPointer?, Int) -> UnsafeMutableRawPointer?).self).function,
            PyTuple_New: try await runtime.loadSendableSymbol(
                "PyTuple_New", as: (@convention(c) (Int) -> UnsafeMutableRawPointer?).self).function,
            PyTuple_SetItem: try await runtime.loadSendableSymbol(
                "PyTuple_SetItem", as: (@convention(c) (UnsafeMutableRawPointer?, Int, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyTuple_Size: try await runtime.loadSendableSymbol(
                "PyTuple_Size", as: (@convention(c) (UnsafeMutableRawPointer?) -> Int).self).function,
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
            Py_REFCNT: try? await runtime.loadSendableSymbol(
                "Py_REFCNT", as: (@convention(c) (UnsafeMutableRawPointer) -> Int32).self).function,
//            PyObject_CallOneArg: try await runtime.loadSendableSymbol(
//                "PyObject_CallOneArg", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            
            PyDict_Type: try await runtime.loadSendableSymbol("PyDict_Type", as: UnsafeMutableRawPointer.self).function,
            PyList_Type: try await runtime.loadSendableSymbol("PyList_Type", as: UnsafeMutableRawPointer.self).function,
            PyTuple_Type: try await runtime.loadSendableSymbol("PyTuple_Type", as: UnsafeMutableRawPointer.self).function,
            
            _Py_NoneStruct: try? await runtime.loadSendableSymbol("_Py_NoneStruct", as: UnsafeMutableRawPointer.self).function,
            
            // Other
            logger: logger
        )
    }
}


// MARK: -
// MARK: API Reference


// MARK: API Py_DecRef

/// ### `Py_DecRef`  (https://docs.python.org/3/c-api/refcounting.html)
/// `void Py_DecRef(PyObject *o)`
///
/// Decrements the reference count of `o`.
///
/// **Thread Safety:**
///     - Requires an attached thread state in normal CPython usage.
///     - In free-threaded Python, the refcount update itself is thread-safe, but object destruction may run finalizers or other arbitrary code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Releases one owned reference.
/// **Errors:** Does not return an error code.
///
/// - Parameter `o`: The object whose reference count will be decremented.
///
/// - Important:
///      If this drops the last reference, the object may be deallocated immediately.

// MARK: API Py_IncRef

/// ### `Py_IncRef`  (https://docs.python.org/3/c-api/refcounting.html)
/// `void Py_IncRef(PyObject *o)`
///
/// Increments the reference count of `o`.
///
/// **Thread Safety:**
///     - Requires an attached thread state in normal CPython usage.
///     - In free-threaded Python, the refcount update itself is thread-safe, but object lifetime effects still matter to surrounding code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Acquires one owned reference.
/// **Errors:** Does not return an error code.
///
/// - Parameter `o`: The object whose reference count will be incremented.
///
/// - Important:
///      Balance this with a later `Py_DecRef()` when the additional ownership is no longer needed.

// MARK: API Py_REFCNT

/// ### `Py_REFCNT`  (https://docs.python.org/3/c-api/refcounting.html)
/// `Py_ssize_t Py_REFCNT(PyObject *o)`
///
/// Returns the current reference count of `o`.
///
/// **Thread Safety:**
///     - Requires an attached thread state in normal CPython usage.
///     - In free-threaded Python, the observed value is only a snapshot and must not be treated as a synchronization guarantee.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.14 onward.
/// **Reference counting:** Does not change ownership.
/// **Errors:** Does not return an error code.
///
/// - Parameter `o`: The object whose reference count will be inspected.
/// - Returns: The current reference count value.
///
/// - Important:
///      CPython documentation warns against using the exact refcount value for program logic except in narrow debugging or implementation-specific cases.

// MARK: API PyBool_FromLong

/// ### `PyBool_FromLong`  (https://docs.python.org/3/c-api/bool.html)
/// `PyObject *PyBool_FromLong(long v)`
///
/// Returns `Py_True` for a nonzero value and `Py_False` for zero.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - Returns one of the process-wide bool singletons; no caller-visible mutation is involved.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Does not report an error.
///
/// - Parameter `v`: The integer value to convert.
/// - Returns: A new reference to `Py_True` or `Py_False`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyBuffer_Release

/// ### `PyBuffer_Release`  (https://docs.python.org/3/c-api/buffer.html)
/// `void PyBuffer_Release(Py_buffer *view)`
///
/// Releases a buffer previously acquired through the buffer protocol.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - The release callback is defined by the exporting object, so do not assume this is atomic for shared mutable exporters.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Releases any owned references held by the `Py_buffer`.
/// **Errors:** Does not return an error code.
///
/// - Parameter `view`: The buffer view to release.

// MARK: API PyBytes_Size

/// ### `PyBytes_Size`  (https://docs.python.org/3/c-api/bytes.html)
/// `Py_ssize_t PyBytes_Size(PyObject *o)`
///
/// Returns the length of a Python `bytes` object.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Reading the size of a shared immutable `bytes` object does not mutate it.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not change reference ownership.
/// **Errors:** Returns `-1` and sets an exception if `o` is not a `bytes` object.
///
/// - Parameter `o`: The object expected to be a `bytes` instance.
/// - Returns: The number of bytes in `o`, or `-1` on failure.

// MARK: API PyByteArray_Size

/// ### `PyByteArray_Size`  (https://docs.python.org/3/c-api/bytearray.html)
/// `Py_ssize_t PyByteArray_Size(PyObject *o)`
///
/// Returns the length of a Python `bytearray` object.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `bytearray` without external synchronization.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not change reference ownership.
/// **Errors:** Returns `-1` and sets an exception if `o` is not a `bytearray` object.
///
/// - Parameter `o`: The object expected to be a `bytearray` instance.
/// - Returns: The number of bytes in `o`, or `-1` on failure.

// MARK: API PyDict_New

/// ### `PyDict_New` (https://docs.python.org/3/c-api/dict.html)
/// `PyObject *PyDict_New(void)`
///
/// Returns a new empty dictionary.  Creates a Python `dict`.
///
/// **Thread Safety:** Atomic
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure.
///
/// - Returns: A new reference representing an empty dictionary, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyDict_SetItem

/// ### `PyDict_SetItem`  (https://docs.python.org/3/c-api/dict.html)
/// `int PyDict_SetItem(PyObject *p, PyObject *key, PyObject *val)`
///
/// Sets `p[key] = val`.  Inserts or replaces a dictionary entry.
///
/// **Thread Safety:**
///     - safe for concurrent use on the same object (https://docs.python.org/3/library/threadsafety.html#threadsafety-level-shared)
///     - Atomic on free threading when key is str, int, float, bool or bytes.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:**
///      Unlike functions like PyList_SetItem, PyDict_SetItem does not steal references. It increments
///      the reference counts (Py_INCREF) of both the `key` and the `val` internally.
/// **Errors:** Returns `-1` and sets an exception on failure.
///
/// - Parameters:
///   - `p`: The destination dictionary.
///   - `key`: The key object.
///   - `val`: The value object.
/// - Returns: `0` on success, or `-1` on failure.
///
/// - Important:
///      Because references are not stolen, `Py_DECREF` must be called on `key` and `val`
///      like any other object.

// MARK: API PyGILState_Ensure

/// ### `PyGILState_Ensure`  (https://docs.python.org/3/c-api/init.html)
/// `PyGILState_STATE PyGILState_Ensure(void)`
///
/// Ensures the current thread is ready to call the Python C API.  Acquires the GIL if needed.
///
/// **Thread Safety:**
///     - Safe to call from a non-Python-created native thread.
///     - Each call must be matched by `PyGILState_Release()` on the same thread.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not create or destroy Python object references directly.
/// **Errors:** Does not return an error code.
///
/// - Returns: An opaque `PyGILState_STATE` handle that must be passed to `PyGILState_Release()`.
///
/// - Important:
///      The returned state token is specific to this call and must not be reused
///      for a different `PyGILState_Ensure()` call.

// MARK: API PyGILState_Release

/// ### `PyGILState_Release`  (https://docs.python.org/3/c-api/init.html)
/// `void PyGILState_Release(PyGILState_STATE state)`
///
/// Restores the thread state saved by `PyGILState_Ensure()`.  Releases the GIL if appropriate.
///
/// **Thread Safety:**
///     - Must be called on the same thread that called the matching `PyGILState_Ensure()`.
///     - Must receive the exact `PyGILState_STATE` handle returned by that call.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not create or destroy Python object references directly.
/// **Errors:** Does not return an error code.
///
/// - Parameter `state`: The opaque handle returned by `PyGILState_Ensure()`.
///
/// - Important:
///      Every `PyGILState_Ensure()` call must be paired with exactly one
///      `PyGILState_Release()` call.

// MARK: API PyErr_Clear

/// ### `PyErr_Clear`  (https://docs.python.org/3/c-api/exceptions.html)
/// `void PyErr_Clear(void)`
///
/// Clears the current thread's exception indicator.  Discards any active raised exception.
///
/// **Thread Safety:**
///     - Operates on the current thread's exception state.
///     - The caller must have an attached thread state.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Releases ownership of the current exception state.
/// **Errors:** Does not return an error code.

// MARK: API PyErr_Fetch

/// ### `PyErr_Fetch`  (https://docs.python.org/3/c-api/exceptions.html)
/// `void PyErr_Fetch(PyObject **ptype, PyObject **pvalue, PyObject **ptraceback)`
///
/// Fetches the current exception indicator into three pointers.  Clears the current raised exception.
///
/// **Thread Safety:**
///     - Operates on the current thread's exception state.
///     - The caller must have an attached thread state.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Transfers ownership of the fetched objects to the caller.
/// **Errors:** Does not return an error code.
///
/// - Parameters:
///   - `ptype`: Receives the exception type, or `NULL`.
///   - `pvalue`: Receives the exception value, or `NULL`.
///   - `ptraceback`: Receives the traceback object, or `NULL`.
///
/// - Important:
///      Deprecated since Python 3.12 in favor of `PyErr_GetRaisedException()`.
///      Any non-`NULL` objects returned here are owned references and must be released
///      or restored explicitly.

// MARK: API PyErr_NormalizeException

/// ### `PyErr_NormalizeException`  (https://docs.python.org/3/c-api/exceptions.html)
/// `void PyErr_NormalizeException(PyObject **exc, PyObject **val, PyObject **tb)`
///
/// Normalizes an exception triplet so the value becomes an instance of the exception type.
///
/// **Thread Safety:**
///     - Operates on exception objects associated with the current thread.
///     - The caller must have an attached thread state.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** May replace the referenced objects while preserving owned references.
/// **Errors:** Does not return an error code.
///
/// - Parameters:
///   - `exc`: The exception type pointer.
///   - `val`: The exception value pointer.
///   - `tb`: The traceback pointer.
///
/// - Important:
///      Deprecated since Python 3.12 in favor of `PyErr_GetRaisedException()`.
///      This function does not automatically set `__traceback__` on the exception value.

// MARK: API PyErr_Occurred

/// ### `PyErr_Occurred`  (https://docs.python.org/3/c-api/exceptions.html)
/// `PyObject *PyErr_Occurred(void)`
///
/// Tests whether the current thread has an active exception indicator set.
///
/// **Thread Safety:**
///     - Operates on the current thread's exception state.
///     - The caller must hold the GIL or otherwise have an attached thread state.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a borrowed reference.
/// **Errors:** Returns `NULL` when no exception is set.
///
/// - Returns: The current exception type as a borrowed reference, or `NULL`.
///
/// - Important:
///      Do not compare the returned object directly to a specific exception type;
///      use `PyErr_ExceptionMatches()`-style APIs when testing exception classes.

// MARK: API PyErr_GetRaisedException

/// ### `PyErr_GetRaisedException`  (https://docs.python.org/3/c-api/exceptions.html)
/// `PyObject *PyErr_GetRaisedException(void)`
///
/// Retrieves the current raised exception instance and clears it from the current thread state.
///
/// **Thread Safety:**
///     - Operates on the current thread's exception state.
///     - The caller must have an attached thread state.
/// **ABI:** Stable ABI
/// **Versions:** Python 3.12 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` if no exception is set.
///
/// - Returns: A new reference to the raised exception instance, or `NULL`.
///
/// - Important:
///      This is the modern replacement for the legacy `PyErr_Fetch()` /
///      `PyErr_NormalizeException()` flow.

// MARK: API PyFloat_AsDouble

/// ### `PyFloat_AsDouble`  (https://docs.python.org/3/c-api/float.html)
/// `double PyFloat_AsDouble(PyObject *pyfloat)`
///
/// Converts a Python object to a C `double`.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - For non-float objects this may invoke Python conversion logic, so it is not guaranteed atomic for arbitrary objects in free-threaded Python.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not change reference ownership.
/// **Errors:** Returns `-1.0` and sets an exception on failure.
///
/// - Parameter `pyfloat`: The Python object to convert.
/// - Returns: The converted `double` value.

// MARK: API PyFloat_FromDouble

/// ### `PyFloat_FromDouble`  (https://docs.python.org/3/c-api/float.html)
/// `PyObject *PyFloat_FromDouble(double v)`
///
/// Creates a Python float from a C `double`.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - Creates a new immutable float object.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure.
///
/// - Parameter `v`: The C floating-point value.
/// - Returns: A new reference to the Python float object, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyImport_AddModule

/// ### `PyImport_AddModule`  (https://docs.python.org/3/c-api/import.html)
/// `PyObject *PyImport_AddModule(const char *name)`
///
/// Returns the module object for `name`, creating an empty module entry if needed.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Operates on interpreter module state; do not assume this is atomic with respect to other import-side effects.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a borrowed reference.
/// **Errors:** Returns `NULL` on failure.
///
/// - Parameter `name`: The fully qualified module name.
/// - Returns: A borrowed reference to the module object, or `NULL`.

// MARK: API PyImport_ImportModule

/// ### `PyImport_ImportModule`  (https://docs.python.org/3/c-api/import.html)
/// `PyObject *PyImport_ImportModule(const char *name)`
///
/// Imports a module by name.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Importing may execute arbitrary Python code and module initialization logic.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameter `name`: The fully qualified module name.
/// - Returns: A new reference to the imported module, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyList_New

/// ### `PyList_New`  (https://docs.python.org/3/c-api/list.html)
/// `PyObject *PyList_New(Py_ssize_t len)`
///
/// Creates a new Python list with `len` slots.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Creates a new list object that is safe to populate before sharing it with other threads.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure.
///
/// - Parameter `len`: The initial list length.
/// - Returns: A new reference to the list object, or `NULL`.
///
/// - Important: Newly allocated slots are initialized to `NULL`, not to Python objects.

// MARK: API PyList_SetItem

/// ### `PyList_SetItem`  (https://docs.python.org/3/c-api/list.html)
/// `int PyList_SetItem(PyObject *list, Py_ssize_t index, PyObject *item)`
///
/// Stores `item` into a list slot.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Mutates the list; do not assume this is safe on a shared mutable list without external synchronization.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Steals a reference to `item`.
/// **Errors:** Returns `-1` and sets an exception on failure.
///
/// - Parameters:
///   - `list`: The destination list.
///   - `index`: The target element index.
///   - `item`: The item to store.
/// - Returns: `0` on success, or `-1` on failure.
///
/// - Important:
///      Because the reference to `item` is stolen, do not `Py_DECREF` it again after a successful call.

// MARK: API PyLong_AsLongLong

/// ### `PyLong_AsLongLong`  (https://docs.python.org/3/c-api/long.html)
/// `long long PyLong_AsLongLong(PyObject *obj)`
///
/// Converts a Python integer-like object to a C `long long`.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - For non-`int` objects this may invoke Python conversion logic, so it is not guaranteed atomic for arbitrary objects in free-threaded Python.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not change reference ownership.
/// **Errors:** Returns `-1` and sets an exception on failure or overflow.
///
/// - Parameter `obj`: The Python object to convert.
/// - Returns: The converted `long long` value.

// MARK: API PyLong_AsUnsignedLongLong

/// ### `PyLong_AsUnsignedLongLong`  (https://docs.python.org/3/c-api/long.html)
/// `unsigned long long PyLong_AsUnsignedLongLong(PyObject *obj)`
///
/// Converts a Python integer-like object to a C `unsigned long long`.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - For non-`int` objects this may invoke Python conversion logic, so it is not guaranteed atomic for arbitrary objects in free-threaded Python.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not change reference ownership.
/// **Errors:** Returns `(unsigned long long)-1` and sets an exception on failure or overflow.
///
/// - Parameter `obj`: The Python object to convert.
/// - Returns: The converted unsigned value.

// MARK: API PyLong_FromLongLong

/// ### `PyLong_FromLongLong`  (https://docs.python.org/3/c-api/long.html)
/// `PyObject *PyLong_FromLongLong(long long v)`
///
/// Creates a Python integer from a C `long long`.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Creates a new immutable integer object.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure.
///
/// - Parameter `v`: The integer value to convert.
/// - Returns: A new reference to the Python integer, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyLong_FromUnsignedLongLong

/// ### `PyLong_FromUnsignedLongLong`  (https://docs.python.org/3/c-api/long.html)
/// `PyObject *PyLong_FromUnsignedLongLong(unsigned long long v)`
///
/// Creates a Python integer from a C `unsigned long long`.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Creates a new immutable integer object.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure.
///
/// - Parameter `v`: The unsigned integer value to convert.
/// - Returns: A new reference to the Python integer, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_Add

/// ### `PyNumber_Add`  (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_Add(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 + o2`.  Arithmetic addition.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the sum, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.


// MARK: API PyNumber_And

/// ### `PyNumber_And`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_And(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 & o2`. Bitwise AND.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the bitwise AND, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlaceAdd

/// ### `PyNumber_InPlaceAdd`  (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlaceAdd(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 += o2`.  Arithmetic addition in place.
///
/// The operation is performed in place when `o1` supports it.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the in-place sum, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlaceAnd

/// ### `PyNumber_InPlaceAnd`  (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlaceAnd(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 &= o2`.   Bitwise AND in place.
///
/// The operation is performed in place when `o1` supports it.  Bitwise AND in place.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the in-place bitwise AND result, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlaceMultiply

/// ### `PyNumber_InPlaceMultiply`  (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlaceMultiply(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 *= o2`.  Arithmetic multiplication in place.
///
/// The operation is performed in place when `o1` supports it.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the in-place product, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlaceOr

/// ### `PyNumber_InPlaceOr`   (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlaceOr(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 |= o2`.  Bitwise OR in place.
///
/// The operation is performed in place when `o1` supports it.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the in-place bitwise OR result, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlacePower

/// ### `PyNumber_InPlacePower`  (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlacePower(PyObject *o1, PyObject *o2, PyObject *o3)`
///
/// Returns the result of `o1 **= o2` when `o3` is `Py_None`.  Arithmetic exponentiation in place.
///
/// The operation is performed in place when `o1` supports it.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
///   - `o3`: The optional modulus operand. Pass `Py_None` to ignore it.
/// - Returns: A new reference representing the in-place power result, or `NULL` on failure.
///
/// - Important: Pass `Py_None`, not `NULL`, when the third argument is unused.
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlaceRemainder

/// ### `PyNumber_InPlaceRemainder`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlaceRemainder(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 %= o2`.  Arithmetic remainder in place.
///
/// The operation is performed in place when `o1` supports it.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the in-place remainder, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlaceSubtract

/// ### `PyNumber_InPlaceSubtract`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlaceSubtract(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 -= o2`.  Arithmetic subtraction in place.
///
/// The operation is performed in place when `o1` supports it.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the in-place difference, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlaceTrueDivide

/// ### `PyNumber_InPlaceTrueDivide`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlaceTrueDivide(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 /= o2`.  True division in place.
///
/// The operation is performed in place when `o1` supports it.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the in-place quotient, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_InPlaceXor

/// ### `PyNumber_InPlaceXor`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_InPlaceXor(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 ^= o2`.  Bitwise exclusive OR in place.
///
/// The operation is performed in place when `o1` supports it.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, do not assume this is safe on a shared mutable `o1` without external synchronization; the in-place numeric method may mutate `o1` and may execute arbitrary Python code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the in-place bitwise XOR result, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_Invert

/// ### `PyNumber_Invert`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_Invert(PyObject *o)`
///
/// Returns the result of `~o`.  Bitwise unary NOT.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand type and any Python code its numeric method executes.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameter `o`: The Python object operand.
/// - Returns: A new reference representing the bitwise negation, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_Multiply

/// ### `PyNumber_Multiply`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_Multiply(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 * o2`.  Arithmetic multiplication.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the product, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_Or

/// ### `PyNumber_Or`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_Or(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 | o2`.  Bitwise OR.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the bitwise OR, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_Power

/// ### `PyNumber_Power`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_Power(PyObject *o1, PyObject *o2, PyObject *o3)`
///
/// Returns the result of `pow(o1, o2, o3)`.  Arithmetic exponentiation.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The base Python object.
///   - `o2`: The exponent Python object.
///   - `o3`: The optional modulus operand. Pass `Py_None` to ignore it.
/// - Returns: A new reference representing the power result, or `NULL` on failure.
///
/// - Important: Pass `Py_None`, not `NULL`, when the third argument is unused.
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_Remainder

/// ### `PyNumber_Remainder`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_Remainder(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 % o2`.  Arithmetic remainder (modulus).
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the remainder, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_Subtract

/// ### `PyNumber_Subtract`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_Subtract(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 - o2`.  Arithmetic subtraction.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the difference, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_TrueDivide

/// ### `PyNumber_TrueDivide`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_TrueDivide(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 / o2`.  True division.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the quotient, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyNumber_Xor

/// ### `PyNumber_Xor`    (https://docs.python.org/3/c-api/number.html)
/// `PyObject *PyNumber_Xor(PyObject *o1, PyObject *o2)`
///
/// Returns the result of `o1 ^ o2`.  Bitwise exclusive OR.
///
/// **Thread Safety:**
///     - Requires an attached thread state. On the regular build, the GIL serializes the call.
///     - In free-threaded Python, this API is not guaranteed atomic for arbitrary objects; safety depends on the operand types and any Python code their numeric methods execute.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure and sets an exception.
///
/// - Parameters:
///   - `o1`: The left-hand Python object.
///   - `o2`: The right-hand Python object.
/// - Returns: A new reference representing the bitwise XOR, or `NULL` on failure.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.
// MARK: API PyObject_Call

/// ### `PyObject_Call`  (https://docs.python.org/3/c-api/call.html)
/// `PyObject *PyObject_Call(PyObject *callable, PyObject *args, PyObject *kwargs)`
///
/// Calls a Python callable with positional and keyword arguments.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Executes arbitrary Python code and is not atomic with respect to user code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameters:
///   - `callable`: The callable object to invoke.
///   - `args`: A tuple of positional arguments.
///   - `kwargs`: A dictionary of keyword arguments, or `NULL`.
/// - Returns: A new reference to the call result, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyObject_CallObject

/// ### `PyObject_CallObject`  (https://docs.python.org/3/c-api/call.html)
/// `PyObject *PyObject_CallObject(PyObject *callable, PyObject *args)`
///
/// Calls a Python callable with positional arguments only.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Executes arbitrary Python code and is not atomic with respect to user code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameters:
///   - `callable`: The callable object to invoke.
///   - `args`: A tuple of positional arguments, or `NULL`.
/// - Returns: A new reference to the call result, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyObject_GetAttrString

/// ### `PyObject_GetAttrString`  (https://docs.python.org/3/c-api/object.html)
/// `PyObject *PyObject_GetAttrString(PyObject *o, const char *attr_name)`
///
/// Looks up an attribute on a Python object by UTF-8 name.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Attribute access may execute arbitrary Python code through descriptors or `__getattribute__`.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameters:
///   - `o`: The Python object whose attribute will be read.
///   - `attr_name`: The attribute name as a null-terminated C string.
/// - Returns: A new reference to the attribute value, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyObject_GetBuffer

/// ### `PyObject_GetBuffer`  (https://docs.python.org/3/c-api/buffer.html)
/// `int PyObject_GetBuffer(PyObject *exporter, Py_buffer *view, int flags)`
///
/// Requests a buffer view from an exporter object.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - The exporter controls the implementation, so do not assume this is atomic for shared mutable objects.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Fills `view` and may store owned references there.
/// **Errors:** Returns `-1` and sets an exception on failure.
///
/// - Parameters:
///   - `exporter`: The object exporting a buffer.
///   - `view`: The output `Py_buffer` structure.
///   - `flags`: Buffer request flags.
/// - Returns: `0` on success, or `-1` on failure.
///
/// - Important: Balance a successful call with `PyBuffer_Release()`.

// MARK: API PyObject_GetItem

/// ### `PyObject_GetItem`  (https://docs.python.org/3/c-api/object.html)
/// `PyObject *PyObject_GetItem(PyObject *o, PyObject *key)`
///
/// Returns `o[key]`.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Item lookup may execute arbitrary Python code and is not guaranteed atomic for arbitrary objects.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameters:
///   - `o`: The container object.
///   - `key`: The lookup key or index.
/// - Returns: A new reference to the fetched item, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyObject_RichCompare

/// ### `PyObject_RichCompare`  (https://docs.python.org/3/c-api/object.html)
/// `PyObject *PyObject_RichCompare(PyObject *o1, PyObject *o2, int opid)`
///
/// Performs a rich comparison such as `==`, `<`, or `>=`.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - May execute arbitrary Python comparison logic and is not guaranteed atomic for arbitrary objects.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameters:
///   - `o1`: The left-hand object.
///   - `o2`: The right-hand object.
///   - `opid`: The rich-comparison opcode.
/// - Returns: A new reference to the comparison result, or `NULL`.
///
/// - Important: The result is usually a Python boolean, but custom types may return other objects.

// MARK: API PyObject_RichCompareBool

/// ### `PyObject_RichCompareBool`  (https://docs.python.org/3/c-api/object.html)
/// `int PyObject_RichCompareBool(PyObject *o1, PyObject *o2, int opid)`
///
/// Performs a rich comparison and returns the truth value as a C integer.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - May execute arbitrary Python comparison logic and is not guaranteed atomic for arbitrary objects.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not return an owned Python object reference.
/// **Errors:** Returns `-1` and sets an exception on failure.
///
/// - Parameters:
///   - `o1`: The left-hand object.
///   - `o2`: The right-hand object.
///   - `opid`: The rich-comparison opcode.
/// - Returns: `1` for true, `0` for false, or `-1` on failure.

// MARK: API PyObject_SetAttrString

/// ### `PyObject_SetAttrString`  (https://docs.python.org/3/c-api/object.html)
/// `int PyObject_SetAttrString(PyObject *o, const char *attr_name, PyObject *v)`
///
/// Sets an attribute on a Python object by UTF-8 name.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Mutates object state and may execute arbitrary Python code; do not assume this is safe on shared mutable objects without synchronization.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not steal a reference to `v`.
/// **Errors:** Returns `-1` and sets an exception on failure.
///
/// - Parameters:
///   - `o`: The destination object.
///   - `attr_name`: The attribute name.
///   - `v`: The value to assign.
/// - Returns: `0` on success, or `-1` on failure.

// MARK: API PyObject_SetItem

/// ### `PyObject_SetItem`  (https://docs.python.org/3/c-api/object.html)
/// `int PyObject_SetItem(PyObject *o, PyObject *key, PyObject *v)`
///
/// Assigns `o[key] = v`.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Mutates object state and may execute arbitrary Python code; do not assume this is safe on shared mutable objects without synchronization.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not steal references to `key` or `v`.
/// **Errors:** Returns `-1` and sets an exception on failure.
///
/// - Parameters:
///   - `o`: The destination container.
///   - `key`: The key or index.
///   - `v`: The value to assign.
/// - Returns: `0` on success, or `-1` on failure.

// MARK: API PyObject_Str

/// ### `PyObject_Str`  (https://docs.python.org/3/c-api/object.html)
/// `PyObject *PyObject_Str(PyObject *o)`
///
/// Returns the string representation of a Python object.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - May execute arbitrary Python code through `__str__` or fallback formatting logic.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameter `o`: The object to format.
/// - Returns: A new reference to the Python string result, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyRun_SimpleString

/// ### `PyRun_SimpleString`  (https://docs.python.org/3/c-api/veryhigh.html)
/// `int PyRun_SimpleString(const char *command)`
///
/// Executes Python source code from a null-terminated C string.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Executes arbitrary Python code and is not atomic with respect to user code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Does not return a Python object reference.
/// **Errors:** Returns `-1` on failure.
///
/// - Parameter `command`: The Python source code to execute.
/// - Returns: `0` on success, or `-1` on failure.

// MARK: API PyTuple_New

/// ### `PyTuple_New`  (https://docs.python.org/3/c-api/tuple.html)
/// `PyObject *PyTuple_New(Py_ssize_t len)`
///
/// Creates a new Python tuple with `len` slots.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Creates a new tuple object that is safe to populate before sharing it with other threads.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure.
///
/// - Parameter `len`: The tuple length.
/// - Returns: A new reference to the tuple object, or `NULL`.
///
/// - Important: Newly allocated slots are initialized to `NULL`, not to Python objects.

// MARK: API PyTuple_SetItem

/// ### `PyTuple_SetItem`  (https://docs.python.org/3/c-api/tuple.html)
/// `int PyTuple_SetItem(PyObject *tuple, Py_ssize_t pos, PyObject *o)`
///
/// Stores an item into a tuple slot during tuple construction.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Mutates the tuple in place; use this only before the tuple becomes visible to other code.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Steals a reference to `o`.
/// **Errors:** Returns `-1` and sets an exception on failure.
///
/// - Parameters:
///   - `tuple`: The tuple being initialized.
///   - `pos`: The destination slot index.
///   - `o`: The item to store.
/// - Returns: `0` on success, or `-1` on failure.
///
/// - Important:
///      Because the reference to `o` is stolen, do not `Py_DECREF` it again after a successful call.

// MARK: API PyUnicode_AsUTF8AndSize

/// ### `PyUnicode_AsUTF8AndSize`  (https://docs.python.org/3/c-api/unicode.html)
/// `const char *PyUnicode_AsUTF8AndSize(PyObject *unicode, Py_ssize_t *size)`
///
/// Returns a UTF-8 view of a Python Unicode object.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Reads from an immutable Unicode object, but the returned pointer is borrowed storage owned by that object.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a borrowed pointer; does not create a new Python object reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameters:
///   - `unicode`: The Python string object.
///   - `size`: Receives the UTF-8 byte count.
/// - Returns: A pointer to UTF-8 data, or `NULL`.
///
/// - Important:
///      The returned pointer remains valid only while the Unicode object stays alive.

// MARK: API PyUnicode_FromStringAndSize

/// ### `PyUnicode_FromStringAndSize`  (https://docs.python.org/3/c-api/unicode.html)
/// `PyObject *PyUnicode_FromStringAndSize(const char *u, Py_ssize_t size)`
///
/// Creates a Python Unicode object from UTF-8 data.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Creates a new immutable Unicode object.
/// **ABI:** Stable ABI
/// **Versions:** Stable Python 3.2 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` on failure.
///
/// - Parameters:
///   - `u`: The UTF-8 input buffer.
///   - `size`: The number of bytes to read from `u`.
/// - Returns: A new reference to the Python string object, or `NULL`.
///
/// - Important: Call `Py_DECREF` on the returned object when you are done with it.

// MARK: API PyObject_CallNoArgs

/// ### `PyObject_CallNoArgs`  (https://docs.python.org/3/c-api/call.html)
/// `PyObject *PyObject_CallNoArgs(PyObject *callable)`
///
/// Calls a Python callable with no positional or keyword arguments.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Executes arbitrary Python code and is not atomic with respect to user code.
/// **ABI:** Stable ABI
/// **Versions:** Python 3.9 onward.
/// **Reference counting:** Returns a new reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameter `callable`: The callable object to invoke.
/// - Returns: A new reference to the call result, or `NULL`.
///
/// - Important: This symbol may be unavailable on older Python runtimes.

// MARK: API Py_GetConstant

/// ### `Py_GetConstant`  (https://docs.python.org/3/c-api/object.html)
/// `PyObject *Py_GetConstant(unsigned int constant_id)`
///
/// Returns a strong reference to a well-known CPython constant.
///
/// **Thread Safety:**
///     - Requires an attached thread state.
///     - Returns immutable or singleton interpreter constants; no caller-visible mutation is involved.
/// **ABI:** Stable ABI
/// **Versions:** Python 3.13 onward, with some backports.
/// **Reference counting:** Returns a strong reference.
/// **Errors:** Returns `NULL` and sets an exception on failure.
///
/// - Parameter `constant_id`: The constant identifier to fetch.
/// - Returns: A new reference to the requested constant, or `NULL`.
///
/// - Important: `0` refers to `None` in current CPython.

// MARK: API _Py_NoneStruct

/// ### `_Py_NoneStruct`
/// `PyObject _Py_NoneStruct`
///
/// Private CPython symbol backing the singleton `None` object.
///
/// **Thread Safety:**
///     - Access is read-only from Swift, but this is a private CPython implementation detail.
///     - The symbol is used as a singleton object reference and must not be mutated.
/// **ABI:** Private CPython symbol
/// **Versions:** Present on many CPython builds, but not guaranteed by the Stable ABI.
/// **Reference counting:** Accessed as a borrowed singleton reference.
/// **Errors:** Not applicable.
///
/// - Important: Prefer `Py_GetConstant` when available.
