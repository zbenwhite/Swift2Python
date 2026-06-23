//
//  PythonInterpreter+PythonAPI.swift
//  Swift2Python
//
//  Created by Ben White on 4/16/26.
//
//

import Logging

public typealias Py_ssize_t = Int64

public typealias PyGILState_STATE = Int32

extension PythonInterpreter {
    
    internal struct PreloadedPythonSymbols {
        let Py_DecRef: (@convention(c) (UnsafeMutableRawPointer) -> Void)
        let Py_IncRef: (@convention(c) (UnsafeMutableRawPointer) -> Void)
        let PyBool_FromLong: (@convention(c) (Int) -> UnsafeMutableRawPointer?)
        let PyBuffer_Release: (@convention(c) (UnsafeMutableRawPointer) -> Void)
        let PyBytes_FromStringAndSize: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?)
        let PyBytes_Size: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyByteArray_FromStringAndSize: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?)
        let PyByteArray_Size: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyDict_New: (@convention(c) () -> UnsafeMutableRawPointer?)
        let PyDict_SetItem: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyDict_Size: (@convention(c) (UnsafeMutableRawPointer?) -> Int)
        let PyErr_Clear:  (@convention(c) () -> Void)
        let PyErr_Fetch: (@convention(c) (UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> Void)
        let PyErr_NormalizeException: (@convention(c) (UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?, UnsafeMutablePointer<UnsafeMutableRawPointer?>?) -> Void)
        let PyErr_Occurred: (@convention(c) () -> UnsafeMutableRawPointer?)
        let PyIter_Next: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
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
        let PyMapping_HasKey: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyMapping_Items: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyMapping_Keys: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyMapping_Values: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyNumber_Absolute: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Add: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_And: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceAdd: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceAnd: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceLshift: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceMultiply: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceOr: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlacePower: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceRemainder: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceRshift: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceSubtract: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceTrueDivide: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_InPlaceXor: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Invert: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Lshift: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Multiply: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Negative: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Or: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Positive: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Power: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyNumber_Remainder: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Rshift: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Subtract: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_TrueDivide: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyNumber_Xor: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyObject_Call: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyObject_CallObject: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PyObject_DelItem: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyObject_GetAttrString: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?)
        let PyObject_GetBuffer: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer, Int32) -> Int32)
        let PyObject_GetItem: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyObject_GetIter: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyObject_IsInstance: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> Int32)
        let PyObject_IsTrue: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyObject_Not: (@convention(c) (UnsafeMutableRawPointer) -> Int32)
        let PyObject_RichCompare: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32) -> UnsafeMutableRawPointer?)
        let PyObject_RichCompareBool: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32) -> Int32)
        let PyObject_SetAttrString: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Int32)
        let PyObject_SetItem: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PyObject_Str: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)
        let PyRun_SimpleString: (@convention(c) (UnsafePointer<CChar>) -> Int32)
        let PyFrozenSet_New: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PySet_Add: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PySet_Contains: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PySet_Discard: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32)
        let PySet_New: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?)
        let PySet_Size: (@convention(c) (UnsafeMutableRawPointer?) -> Int)
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
        
        let PyByteArray_Type: UnsafeMutableRawPointer
        let PyBytes_Type: UnsafeMutableRawPointer
        let PyDict_Type: UnsafeMutableRawPointer
        let PyFrozenSet_Type: UnsafeMutableRawPointer
        let PyList_Type: UnsafeMutableRawPointer
        let PySet_Type: UnsafeMutableRawPointer
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
        
        internal func pythonBytes_FromStringAndSize(_ bytes: UnsafePointer<CChar>?, _ size: Int) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyBytes_FromStringAndSize")
            return PyBytes_FromStringAndSize(bytes, size)
        }
        
        internal func pythonBytes_Size(_ pointer: UnsafeMutableRawPointer) -> Int {
            logger.trace("CPython API Call: PyBytes_Size")
            return Int(PyBytes_Size(pointer))
        }
        
        internal func pythonByteArray_FromStringAndSize(_ bytes: UnsafePointer<CChar>?, _ size: Int) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyByteArray_FromStringAndSize")
            return PyByteArray_FromStringAndSize(bytes, size)
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
        
        internal func pythonMapping_HasKey(_ object: UnsafeMutableRawPointer, _ key: UnsafeMutableRawPointer) -> Bool {
            logger.trace("CPython API Call: PyMapping_HasKey")
            return PyMapping_HasKey(object, key) == 1
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
        
        internal func pythonIter_Next(_ iterator: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyIter_Next")
            return PyIter_Next(iterator)
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
        
        internal func pythonObject_DelItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PyObject_DelItem")
            return PyObject_DelItem(obPtr, keyPtr)
        }
        
        internal func pythonObject_GetAttrString(_ pointer: UnsafeMutableRawPointer, _ name: String) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_GetAttrString")
            return name.withCString { namePtr in
                PyObject_GetAttrString(pointer, namePtr)
            }
        }
        
        internal func pythonObject_GetItem(_ obPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_GetItem")
            return PyObject_GetItem(obPtr, keyPtr)
        }
        
        internal func pythonObject_GetIter(_ obPtr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyObject_GetIter")
            return PyObject_GetIter(obPtr)
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
            return name.withCString { namePtr in
                PyObject_SetAttrString(obPtr, namePtr, rvalPtr)
            }
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
        
        internal func pythonSet_Add(_ setPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PySet_Add")
            return PySet_Add(setPtr, keyPtr)
        }
        
        internal func pythonSet_Contains(_ setPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PySet_Contains")
            return PySet_Contains(setPtr, keyPtr)
        }
        
        internal func pythonSet_Discard(_ setPtr: UnsafeMutableRawPointer, _ keyPtr: UnsafeMutableRawPointer) -> Int32 {
            logger.trace("CPython API Call: PySet_Discard")
            return PySet_Discard(setPtr, keyPtr)
        }
        
        internal func pythonFrozenSet_New(_ iterablePtr: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PyFrozenSet_New")
            return PyFrozenSet_New(iterablePtr)
        }
        
        internal func pythonSet_New(_ iterablePtr: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
            logger.trace("CPython API Call: PySet_New")
            return PySet_New(iterablePtr)
        }
        
        internal func pythonSet_Size(_ setPtr: UnsafeMutableRawPointer) -> Int {
            logger.trace("CPython API Call: PySet_Size")
            return PySet_Size(setPtr)
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
                return try pythonReferenceCountUsingSysGetRefCount(obj)
            }
        }

        private func pythonReferenceCountUsingSysGetRefCount(_ obj: UnsafeMutableRawPointer) throws -> Int32 {
            guard let sys = "sys".withCString({ PyImport_ImportModule($0) }) else {
                throw PythonError.symbolNotFound("sys")
            }
            defer { Py_DecRef(sys) }

            guard let getRefCount = PyObject_GetAttrString(sys, "getrefcount") else {
                throw PythonError.symbolNotFound("sys.getrefcount")
            }
            defer { Py_DecRef(getRefCount) }

            guard let args = PyTuple_New(1) else {
                throw PythonError.allocationFailed("Could not allocate sys.getrefcount argument tuple")
            }
            defer { Py_DecRef(args) }

            // PyTuple_SetItem steals a reference on success. The caller's pointer
            // is borrowed, so increment first and let the tuple own that increment.
            Py_IncRef(obj)
            if PyTuple_SetItem(args, 0, obj) != 0 {
                Py_DecRef(obj)
                throw PythonError.allocationFailed("Could not set sys.getrefcount argument")
            }

            guard let result = PyObject_Call(getRefCount, args, nil) else {
                throw PythonError.symbolNotFound("sys.getrefcount result")
            }
            defer { Py_DecRef(result) }

            let count = PyLong_AsLongLong(result)
            if PyErr_Occurred() != nil {
                throw PythonError.stringConversionFailed("Could not convert sys.getrefcount result")
            }

            // sys.getrefcount includes the temporary argument reference. In this
            // fallback path, that reference is the one held by the args tuple.
            return Int32(count - 1)
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
            PyBytes_FromStringAndSize: try await runtime.loadSendableSymbol(
                "PyBytes_FromStringAndSize", as: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?).self).function,
            PyBytes_Size: try await runtime.loadSendableSymbol(
                "PyBytes_Size", as: (@convention(c) (UnsafeMutableRawPointer) -> Int32).self).function,
            PyByteArray_FromStringAndSize: try await runtime.loadSendableSymbol(
                "PyByteArray_FromStringAndSize", as: (@convention(c) (UnsafePointer<CChar>?, Int) -> UnsafeMutableRawPointer?).self).function,
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
            PyIter_Next: try await runtime.loadSendableSymbol(
                "PyIter_Next", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
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
            PyMapping_HasKey: try await runtime.loadSendableSymbol(
                "PyMapping_HasKey", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyMapping_Items: try await runtime.loadSendableSymbol(
                "PyMapping_Items", as: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyMapping_Keys: try await runtime.loadSendableSymbol(
                "PyMapping_Keys", as: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyMapping_Values: try await runtime.loadSendableSymbol(
                "PyMapping_Values", as: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Absolute: try await runtime.loadSendableSymbol(
                "PyNumber_Absolute", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Add: try await runtime.loadSendableSymbol(
                "PyNumber_Add", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_And: try await runtime.loadSendableSymbol(
                "PyNumber_And", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceAdd: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceAdd", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceAnd: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceAnd", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceLshift: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceLshift", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceMultiply: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceMultiply", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceOr: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceOr", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlacePower: try await runtime.loadSendableSymbol(
                "PyNumber_InPlacePower", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self ).function,
            PyNumber_InPlaceRemainder: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceRemainder", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self ).function,
            PyNumber_InPlaceRshift: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceRshift", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceSubtract: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceSubtract", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceTrueDivide: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceTrueDivide", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_InPlaceXor: try await runtime.loadSendableSymbol(
                "PyNumber_InPlaceXor", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Invert: try await runtime.loadSendableSymbol(
                "PyNumber_Invert", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Lshift: try await runtime.loadSendableSymbol(
                "PyNumber_Lshift", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Multiply: try await runtime.loadSendableSymbol(
                "PyNumber_Multiply", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Negative: try await runtime.loadSendableSymbol(
                "PyNumber_Negative", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Or: try await runtime.loadSendableSymbol(
                "PyNumber_Or", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Positive: try await runtime.loadSendableSymbol(
                "PyNumber_Positive", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Power: try await runtime.loadSendableSymbol(
                    "PyNumber_Power", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Remainder: try await runtime.loadSendableSymbol(
                    "PyNumber_Remainder", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyNumber_Rshift: try await runtime.loadSendableSymbol(
                "PyNumber_Rshift", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
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
            PyObject_DelItem: try await runtime.loadSendableSymbol(
                "PyObject_DelItem", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PyObject_GetAttrString: try await runtime.loadSendableSymbol(
                "PyObject_GetAttrString", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?).self).function,
            PyObject_GetBuffer: try await runtime.loadSendableSymbol(
                "PyObject_GetBuffer", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer, Int32) -> Int32).self).function,
            PyObject_GetItem: try await runtime.loadSendableSymbol(
                "PyObject_GetItem", as: (@convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
            PyObject_GetIter: try await runtime.loadSendableSymbol(
                "PyObject_GetIter", as: (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?).self).function,
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
            PyFrozenSet_New: try await runtime.loadSendableSymbol(
                "PyFrozenSet_New", as: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PySet_Add: try await runtime.loadSendableSymbol(
                "PySet_Add", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PySet_Contains: try await runtime.loadSendableSymbol(
                "PySet_Contains", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PySet_Discard: try await runtime.loadSendableSymbol(
                "PySet_Discard", as: (@convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Int32).self).function,
            PySet_New: try await runtime.loadSendableSymbol(
                "PySet_New", as: (@convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer?).self).function,
            PySet_Size: try await runtime.loadSendableSymbol(
                "PySet_Size", as: (@convention(c) (UnsafeMutableRawPointer?) -> Int).self).function,
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
            
            PyByteArray_Type: try await runtime.loadSendableSymbol("PyByteArray_Type", as: UnsafeMutableRawPointer.self).function,
            PyBytes_Type: try await runtime.loadSendableSymbol("PyBytes_Type", as: UnsafeMutableRawPointer.self).function,
            PyDict_Type: try await runtime.loadSendableSymbol("PyDict_Type", as: UnsafeMutableRawPointer.self).function,
            PyFrozenSet_Type: try await runtime.loadSendableSymbol("PyFrozenSet_Type", as: UnsafeMutableRawPointer.self).function,
            PyList_Type: try await runtime.loadSendableSymbol("PyList_Type", as: UnsafeMutableRawPointer.self).function,
            PySet_Type: try await runtime.loadSendableSymbol("PySet_Type", as: UnsafeMutableRawPointer.self).function,
            PyTuple_Type: try await runtime.loadSendableSymbol("PyTuple_Type", as: UnsafeMutableRawPointer.self).function,
            
            _Py_NoneStruct: try? await runtime.loadSendableSymbol("_Py_NoneStruct", as: UnsafeMutableRawPointer.self).function,
            
            // Other
            logger: logger
        )
    }
}
