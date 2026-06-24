//
// PythonObject.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

import Foundation

@dynamicCallable
@dynamicMemberLookup
public struct PythonObject: Sendable, PendingPythonConvertible, CustomReflectable {
    
    // This gets de-initialized as soon as the last copy of the PythonObject
    // goes out of scope.  It's a woraround for deinit not working on PythonObject.
    private final class LifetimeTracker: Sendable {
        let id: PythonInterpreter.PythonObjectUniqueID
        let interpreter: PythonInterpreter
        
        init(id: PythonInterpreter.PythonObjectUniqueID, interpreter: PythonInterpreter) {
            self.id = id
            self.interpreter = interpreter
        }
        
        deinit {
            let localID = id
            let localInterpreter = interpreter
            Task {
                try? await localInterpreter.releasePythonObject(forPythonObjectID: localID)
            }
        }
    }
    
    // Temporary object result of attribute access. Methods can be called asynchronously on PythonObject this way.
    @dynamicCallable
    public struct CallablePythonObject {
        private let obj: PythonObject
        private let method: String
        
        public init (object: PythonObject, methodName: String) {
            self.obj = object
            self.method = methodName
        }
        
        /// Calls this Python method with positional arguments.
        ///
        /// This is the explicit form of dynamic-member method calling. For normal use,
        /// prefer Swift call syntax through `@dynamicCallable`, for example
        /// `try await object.method(1, 2)`. Use `call` when you need to pass an
        /// argument collection explicitly or when the call site should make the Python
        /// method invocation obvious.
        ///
        /// - Parameter args: Positional arguments converted to Python objects before the call.
        /// - Returns: The Python object returned by the method.
        /// - Throws: `PythonError` if attribute lookup, argument conversion, or the Python call fails.
        public func call(_ args: any PendingPythonConvertible...) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object: obj, methodName: method, collectedArgs: args)
        }
        
        /// Calls this Python method with positional and dictionary keyword arguments.
        ///
        /// Use this explicit form when keyword arguments are already stored in a Swift
        /// dictionary. For inline keyword syntax, prefer `try await object.method(arg, name: value)`.
        /// Dictionary keys must be valid Python keyword names for the target callable.
        ///
        /// - Parameters:
        ///   - args: Positional arguments converted to Python objects before the call.
        ///   - kwargs: Keyword arguments converted into a Python `dict`.
        /// - Returns: The Python object returned by the method.
        /// - Throws: `PythonError` if attribute lookup, argument conversion, keyword conversion,
        ///   or the Python call fails.
        public func call(_ args: any PendingPythonConvertible..., kwargs: [String: any PendingPythonConvertible]) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object: obj, methodName: method, collectedArgs: args, kwargs: kwargs)
        }
        
        /// Calls this Python method with positional and ordered keyword arguments.
        ///
        /// Use this overload when preserving keyword order matters or when duplicate
        /// keyword detection should happen before Python receives the call. Empty keyword
        /// names are not valid in this explicit kwargs form.
        ///
        /// - Parameters:
        ///   - args: Positional arguments converted to Python objects before the call.
        ///   - kwargs: Ordered keyword arguments converted into a Python `dict`.
        /// - Returns: The Python object returned by the method.
        /// - Throws: `PythonError.valueError` for invalid keyword pairs, or `PythonError`
        ///   if attribute lookup, conversion, or the Python call fails.
        public func call(_ args: any PendingPythonConvertible..., kwargs: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object: obj, methodName: method, collectedArgs: args, kwargs: kwargs)
        }
        
        /// Implements `@dynamicCallable` positional method calls.
        ///
        /// This powers syntax such as `try await object.method(1, 2)`. Call this method
        /// directly only when manually forwarding dynamic-call arguments.
        ///
        /// - Parameter args: Positional arguments supplied by Swift's dynamic-call lowering.
        /// - Returns: The Python object returned by the method.
        /// - Throws: `PythonError` if attribute lookup, argument conversion, or the Python call fails.
        public func dynamicallyCall(withArguments args: [any PendingPythonConvertible]) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object: obj, methodName: method, collectedArgs: args)
        }
        
        /// Implements `@dynamicCallable` positional and keyword method calls.
        ///
        /// This powers syntax such as `try await object.method(1, name: value)`. Swift
        /// represents positional arguments with an empty keyword label, so this method
        /// validates that positional arguments do not appear after keyword arguments and
        /// that keyword labels are not duplicated.
        ///
        /// - Parameter args: Dynamic-call arguments supplied by Swift.
        /// - Returns: The Python object returned by the method.
        /// - Throws: `PythonError.valueError` for invalid argument ordering or duplicate
        ///   keywords, or `PythonError` if lookup, conversion, or the Python call fails.
        public func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {
            let methodObject = try await obj.get(attr: method)
            return try await obj.interpreter.callPythonCallable(methodObject, dynamicArguments: args)
        }
    }
    
    internal let id: PythonInterpreter.PythonObjectUniqueID
    private let interpreter: PythonInterpreter
    private let lifetime: LifetimeTracker
    
    internal init(id: PythonInterpreter.PythonObjectUniqueID, interpreter: PythonInterpreter) {
        self.id = id
        self.interpreter = interpreter
        self.lifetime = LifetimeTracker(id: id, interpreter: interpreter)
    }
    
    public var customMirror: Mirror {
        Mirror(self, children: [], displayStyle: .struct)
    }
    
    // Implement PendingPythonConvertible protocol
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        return self
    }
    
    /// Calls this Python object as a callable with positional arguments.
    ///
    /// Use this for Python functions, classes, bound methods, callable instances,
    /// and any other Python object that implements Python's call protocol. For inline
    /// calls, prefer `try await object(1, 2)`. Use `call` when forwarding argument
    /// collections or when an explicit throwing API is clearer at the call site.
    ///
    /// - Parameter args: Positional arguments converted to Python objects before the call.
    /// - Returns: The Python object returned by the callable.
    /// - Throws: `PythonError` if argument conversion fails, the object is not callable,
    ///   or Python raises during the call.
    public func call(_ args: any PendingPythonConvertible...) async throws -> PythonObject {
        try await interpreter.callPythonCallable(self, args: args, kwargs: [:])
    }
    
    /// Calls this Python object as a callable with positional and dictionary keyword arguments.
    ///
    /// Use this explicit form when keyword arguments are already stored in a Swift
    /// dictionary. For inline keyword calls, prefer `try await object(arg, name: value)`.
    /// Dictionary keys must be valid Python keyword names for the target callable.
    ///
    /// - Parameters:
    ///   - args: Positional arguments converted to Python objects before the call.
    ///   - kwargs: Keyword arguments converted into a Python `dict`.
    /// - Returns: The Python object returned by the callable.
    /// - Throws: `PythonError` if argument conversion, keyword conversion, or the Python call fails.
    public func call(_ args: any PendingPythonConvertible..., kwargs: [String: any PendingPythonConvertible]) async throws -> PythonObject {
        try await interpreter.callPythonCallable(self, args: args, kwargs: kwargs)
    }
    
    /// Calls this Python object as a callable with positional and ordered keyword arguments.
    ///
    /// Use this overload when preserving keyword order matters or when duplicate
    /// keyword detection should happen before Python receives the call. Empty keyword
    /// names are not valid in this explicit kwargs form.
    ///
    /// - Parameters:
    ///   - args: Positional arguments converted to Python objects before the call.
    ///   - kwargs: Ordered keyword arguments converted into a Python `dict`.
    /// - Returns: The Python object returned by the callable.
    /// - Throws: `PythonError.valueError` for invalid keyword pairs, or `PythonError`
    ///   if conversion or the Python call fails.
    public func call(_ args: any PendingPythonConvertible..., kwargs: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {
        try await interpreter.callPythonCallable(self, args: args, kwargs: kwargs)
    }
    
    /// Implements `@dynamicCallable` positional calls.
    ///
    /// This powers syntax such as `try await function(1, 2)`. Call this method
    /// directly only when manually forwarding dynamic-call arguments.
    ///
    /// - Parameter args: Positional arguments supplied by Swift's dynamic-call lowering.
    /// - Returns: The Python object returned by the callable.
    /// - Throws: `PythonError` if conversion or the Python call fails.
    public func dynamicallyCall(withArguments args: [any PendingPythonConvertible]) async throws -> PythonObject {
        try await interpreter.callPythonCallable(self, args: args, kwargs: [:])
    }
    
    /// Implements `@dynamicCallable` positional and keyword calls.
    ///
    /// This powers syntax such as `try await function(1, name: value)`. Swift
    /// represents positional arguments with an empty keyword label, so this method
    /// validates that positional arguments do not appear after keyword arguments and
    /// that keyword labels are not duplicated.
    ///
    /// - Parameter args: Dynamic-call arguments supplied by Swift.
    /// - Returns: The Python object returned by the callable.
    /// - Throws: `PythonError.valueError` for invalid argument ordering or duplicate
    ///   keywords, or `PythonError` if conversion or the Python call fails.
    public func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, any PendingPythonConvertible>) async throws -> PythonObject {
        try await interpreter.callPythonCallable(self, dynamicArguments: args)
    }
    
    /// Gets a Python attribute by name.
    ///
    /// Use this async throwing API for recoverable attribute access on `PythonObject`.
    /// Swift cannot express Python-style `try await object.name` property access, so
    /// `get(attr:)` is the canonical async form for reading non-callable attributes.
    /// For method calls where the name is known at compile time, use dynamic-member
    /// call syntax such as `try await object.method()`.
    ///
    /// - Parameter attr: The Python attribute name to read.
    /// - Returns: The Python object stored in the named attribute.
    /// - Throws: `PythonError.pythonException` if Python raises, including when the
    ///   attribute is missing, or another `PythonError` if the object pointer is unavailable.
    public func get(attr: String) async throws -> PythonObject {
        return try await interpreter.get(object: self, attribute: attr)
    }
    
    /// Sets a Python attribute by name.
    ///
    /// Use this async throwing API for recoverable attribute mutation on `PythonObject`.
    /// The value is converted to a Python object before assignment.
    ///
    /// - Parameters:
    ///   - attr: The Python attribute name to set.
    ///   - value: The Swift or Python value to convert and assign.
    /// - Throws: `PythonError.pythonException` if Python raises, including read-only
    ///   attribute errors, or another `PythonError` if conversion fails.
    public func set(attr: String, value: PendingPythonConvertible) async throws {
        let pyValue = try await value.toPythonObject(interpreter: self.interpreter)
        try await interpreter.set(object: self, attribute: attr, value: pyValue)
    }
    
    /// Gets an item through Python's item protocol.
    ///
    /// This is the async throwing form of Python `object[key]`. Use it for
    /// dictionaries, lists, tuples, custom Python objects that implement
    /// `__getitem__`, and any other object that supports `PyObject_GetItem`.
    /// Swift subscript syntax cannot express the required `try await`, so
    /// ``getItem(key:)`` is the canonical async item-access API.
    ///
    /// Swift ranges and ``PythonSlice`` values can be used as keys when Python
    /// slicing is desired:
    ///
    /// ```swift
    /// let value = try await object.getItem(key: "name")
    /// let middle = try await list.getItem(key: 1..<4)
    /// ```
    ///
    /// - Parameter key: The Swift or Python key to convert and pass to Python.
    /// - Returns: The Python object returned by `object[key]`.
    /// - Throws: `PythonError.pythonException` if Python raises, including
    ///   `KeyError`, `IndexError`, or exceptions from custom `__getitem__`
    ///   implementations, or another `PythonError` if key conversion fails.
    public func getItem(key: PendingPythonConvertible) async throws -> PythonObject {
        try await interpreter.getItem(object: self, key: key.toPythonObject(interpreter: self.interpreter))
    }
    
    /// Sets an item through Python's item protocol.
    ///
    /// This is the async throwing form of Python `object[key] = value`. Use it for
    /// mappings, mutable sequences, custom Python objects that implement
    /// `__setitem__`, and slice assignment. Swift assignment subscripts cannot
    /// express `try await`, so ``setItem(key:newValue:)`` is the canonical async
    /// item-mutation API.
    ///
    /// ```swift
    /// try await dict.setItem(key: "name", newValue: "Ada")
    /// try await list.setItem(key: 1..<3, newValue: replacement)
    /// ```
    ///
    /// - Parameters:
    ///   - key: The Swift or Python key to convert and pass to Python.
    ///   - newValue: The Swift or Python value to convert and assign.
    /// - Throws: `PythonError.pythonException` if Python raises, including
    ///   `KeyError`, `IndexError`, read-only item failures, or exceptions from
    ///   custom `__setitem__` implementations, or another `PythonError` if
    ///   conversion fails.
    public func setItem(key: PendingPythonConvertible, newValue: PendingPythonConvertible) async throws {
        try await interpreter.setItem(object: self, key: key.toPythonObject(interpreter: self.interpreter), newValue: newValue.toPythonObject(interpreter: self.interpreter))
    }
    
    /// Deletes a key from this Python dictionary.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic. This helper validates that this
    /// object is a Python dictionary before deleting the item.
    ///
    /// ```swift
    /// try await dict.deleteItem(key: "name")
    /// ```
    ///
    /// - Parameters:
    ///   - key: The dictionary key to delete.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while deleting the key.
    public func deleteItem(key: PendingPythonConvertible) async throws {
        try await interpreter.deleteItem(fromDict: self, key: key.toPythonObject(interpreter: self.interpreter))
    }
    
    /// Returns true if this Python dictionary contains the given key.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic. This helper validates that this
    /// object is a Python dictionary before checking key membership.
    ///
    /// ```swift
    /// if try await dict.containsKey("name") {
    ///     print("name is present")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The dictionary key to check.
    /// - Returns: `true` when the key is present; otherwise `false`.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while checking key membership.
    public func containsKey(_ key: PendingPythonConvertible) async throws -> Bool {
        try await interpreter.containsKey(key.toPythonObject(interpreter: self.interpreter), inDict: self)
    }
    
    //
    // a.call_a_function() can be implemented.
    public subscript(dynamicMember name: String) -> CallablePythonObject {
        // a.call_a_function()
        get {
            return CallablePythonObject(object: self, methodName: name)
        }
    }
    
    // MARK: Bytes support
    
    /// Returns true if this object is a Python `bytes` instance.
    ///
    /// - Returns: `true` when this object is a Python `bytes`; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    public func isBytes() async throws -> Bool {
        try await interpreter.isBytes(self)
    }
    
    /// Returns true if this object is a Python `bytearray` instance.
    ///
    /// - Returns: `true` when this object is a Python `bytearray`; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    public func isByteArray() async throws -> Bool {
        try await interpreter.isByteArray(self)
    }
    
    /// Returns true if this object supports Python's buffer protocol.
    ///
    /// This includes `bytes`, `bytearray`, `memoryview`, and other objects that can
    /// provide a simple readable buffer.
    ///
    /// - Returns: `true` when this object can be read as bytes; otherwise `false`.
    /// - Throws: `PythonError` if the object pointer is unavailable.
    public func isBytesLike() async throws -> Bool {
        try await interpreter.isBytesLike(self)
    }
    
    /// Returns the number of bytes in this Python `bytes` object.
    ///
    /// - Returns: The `bytes` length.
    /// - Throws: `PythonError.bytesConversionFailed` if this object is not `bytes`,
    ///   or `PythonError` if Python raises while reading the size.
    public func bytesSize() async throws -> Int {
        try await interpreter.bytesObjectSize(self)
    }
    
    /// Returns the number of bytes in this Python `bytearray` object.
    ///
    /// - Returns: The `bytearray` length.
    /// - Throws: `PythonError.bytesConversionFailed` if this object is not `bytearray`,
    ///   or `PythonError` if Python raises while reading the size.
    public func byteArraySize() async throws -> Int {
        try await interpreter.byteArrayObjectSize(self)
    }
    
    /// Safe copy of Python bytes → Swift Data
    public func asCopiedData() async throws -> Data {
        try await withUnsafeBytes { Data($0) }
    }
    
    /// Safe copy of Python bytes → Swift byte array.
    public func asCopiedBytes() async throws -> [UInt8] {
        try await withUnsafeBytes { Array($0) }
    }
    
    /// Safe copy of Python bytes → Swift byte array.
    ///
    /// This is an alias for `asCopiedBytes()` for callers working with Python `bytearray`.
    public func asCopiedByteArray() async throws -> [UInt8] {
        try await asCopiedBytes()
    }
    
    /// Safe copy of Python bytes → Swift `String` (recommended for SVG, JSON, text)
    public func asCopiedString(encoding: String.Encoding = .utf8) async throws -> String {
        try await withUnsafeBytesString(encoding: encoding) { $0 }
    }
    
    /// Do something with the bytes before the closure ends
    public func withUnsafeBytes<R : Sendable>(_ body: @Sendable (UnsafeBufferPointer<UInt8>) throws -> R) async throws -> R {
        try await interpreter.withUnsafeBytes(self, body: body)
    }
    
    /// Do something with the bytes before the closure ends
    public func withUnsafeBytesString<R : Sendable>( encoding: String.Encoding = .utf8, _ body: @Sendable (String) throws -> R ) async throws -> R {
        try await withUnsafeBytes { buffer in
            guard let str = String(bytes: buffer, encoding: encoding) else {
                throw PythonError.bytesConversionFailed(expected: "bytes decodable as \(encoding)", actual: nil)
            }
            return try body(str)
        }
    }
    
    // MARK: Dict support
    
    /// Returns true if this Python object is a dictionary.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic.
    ///
    /// ```swift
    /// if try await object.isDict() {
    ///     let count = try await object.dictCount()
    /// }
    /// ```
    ///
    /// - Returns: `true` when this object is a Python dictionary; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    public func isDict() async throws -> Bool {
        return try await interpreter.isDict(self)
    }
    
    /// Returns the number of entries in this Python dictionary.
    ///
    /// Use this when you expect the object to be a dictionary and want an error if it is not one.
    ///
    /// ```swift
    /// let count = try await dict.dictCount()
    /// ```
    ///
    /// - Returns: The number of key-value pairs in the dictionary.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while reading the dictionary size.
    public func dictCount() async throws -> Int {
        return try await interpreter.getDictCount(self)
    }
    
    /// Returns this Python dictionary's keys as a Swift array of Python objects.
    ///
    /// Use this when you want an eager Swift array. To preserve Python's view semantics,
    /// call Python's `keys()` method directly instead.
    ///
    /// ```swift
    /// let keys = try await dict.dictKeys()
    /// for key in keys {
    ///     print(try await String(key))
    /// }
    /// ```
    ///
    /// - Returns: A Swift array containing the dictionary keys as `PythonObject` values.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while reading the keys.
    public func dictKeys() async throws -> [PythonObject] {
        return try await interpreter.dictKeys(self)
    }
    
    /// Returns this Python dictionary's values as a Swift array of Python objects.
    ///
    /// Use this when you want an eager Swift array. To preserve Python's view semantics,
    /// call Python's `values()` method directly instead.
    ///
    /// ```swift
    /// let values = try await dict.dictValues()
    /// for value in values {
    ///     print(try await String(value))
    /// }
    /// ```
    ///
    /// - Returns: A Swift array containing the dictionary values as `PythonObject` values.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while reading the values.
    public func dictValues() async throws -> [PythonObject] {
        return try await interpreter.dictValues(self)
    }
    
    /// Returns this Python dictionary's key-value pairs as a Swift array.
    ///
    /// Use this when you want an eager Swift array. To preserve Python's view semantics,
    /// call Python's `items()` method directly instead.
    ///
    /// ```swift
    /// let items = try await dict.dictItems()
    /// for item in items {
    ///     let key = try await String(item.key)
    ///     let value = try await Int(item.value)
    ///     print(key, value)
    /// }
    /// ```
    ///
    /// - Returns: A Swift array of `(key: PythonObject, value: PythonObject)` pairs.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while reading the items.
    public func dictItems() async throws -> [(key: PythonObject, value: PythonObject)] {
        return try await interpreter.dictItems(self)
    }
    
    // MARK: List support
    
    /// Returns this Python list's elements as a Swift array.
    ///
    /// Use this when you want an eager Swift array of `PythonObject` values. To keep
    /// working with the original Python list, use list item helpers or Python list
    /// methods directly instead.
    ///
    /// ```swift
    /// let elements = try await list.asArray()
    /// for element in elements {
    ///     print(try await Int(element))
    /// }
    /// ```
    ///
    /// - Returns: A Swift array containing this Python list's elements.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError` if Python raises while reading the list.
    public func asArray() async throws -> [PythonObject] {
        return try await interpreter.toArray(self)
    }
    
    /// Returns true if this Python object is a list.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic.
    ///
    /// ```swift
    /// if try await object.isList() {
    ///     let count = try await object.listCount()
    /// }
    /// ```
    ///
    /// - Returns: `true` when this object is a Python list; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    public func isList() async throws -> Bool {
        return try await interpreter.isList(self)
    }
    
    /// Returns the number of elements in this Python list.
    ///
    /// ```swift
    /// let count = try await list.listCount()
    /// ```
    ///
    /// - Returns: The list length.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError` if Python raises while reading the list length.
    public func listCount() async throws -> Int {
        return try await interpreter.getListCount(self)
    }
    
    /// Returns the list element at the specified index.
    ///
    /// Indexes are zero-based. Negative indexes use Python list semantics, so `-1`
    /// returns the last element.
    ///
    /// ```swift
    /// let first = try await list.listItem(at: 0)
    /// let last = try await list.listItem(at: -1)
    /// ```
    ///
    /// - Parameters:
    ///   - index: The Python list index to read.
    /// - Returns: The element at `index`.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError.pythonException` if Python raises, including out-of-bounds indexes.
    public func listItem(at index: Int) async throws -> PythonObject {
        return try await interpreter.listItem(at: index, in: self)
    }
    
    /// Appends an item to this Python list.
    ///
    /// ```swift
    /// try await list.listAppendItem("new value")
    /// ```
    ///
    /// - Parameters:
    ///   - item: The value to append. It is converted to a Python object before insertion.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError` if conversion or append fails.
    public func listAppendItem(_ item: any PendingPythonConvertible) async throws {
        return try await interpreter.appendListItem(item, to: self)
    }

    /// Inserts an item into this Python list at the specified index.
    ///
    /// This follows Python's `list.insert` behavior for indexes outside the list bounds.
    ///
    /// ```swift
    /// try await list.listInsertItem("new value", at: 1)
    /// ```
    ///
    /// - Parameters:
    ///   - item: The value to insert. It is converted to a Python object before insertion.
    ///   - index: The index where the value should be inserted.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError` if conversion or insertion fails.
    public func listInsertItem(_ item: any PendingPythonConvertible, at index: Int) async throws {
        return try await interpreter.insertListItem(item, at: index, to: self)
    }

    /// Replaces the list element at the specified index.
    ///
    /// Indexes are zero-based. Negative indexes use Python list semantics, so `-1`
    /// replaces the last element.
    ///
    /// ```swift
    /// try await list.listSetItem(at: -1, to: "replacement")
    /// ```
    ///
    /// - Parameters:
    ///   - index: The Python list index to replace.
    ///   - value: The new value. It is converted to a Python object before assignment.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError.pythonException` if Python raises, including out-of-bounds indexes.
    public func listSetItem(at index: Int, to value: any PendingPythonConvertible) async throws {
        return try await interpreter.setListItem(value, at: index , in: self)
    }
    
    /// Deletes the list element at the specified index.
    ///
    /// Indexes are interpreted by Python, including negative indexes such as `-1`.
    ///
    /// ```swift
    /// try await list.listDeleteItem(at: -1)
    /// ```
    ///
    /// - Parameters:
    ///   - index: The Python list index to delete.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError.pythonException` if Python raises, including out-of-bounds indexes.
    public func listDeleteItem(at index: Int) async throws {
        try await interpreter.delListItem(at: index, from: self)
    }

    // MARK: Set support
    
    /// Returns true if this Python object is a set.
    ///
    /// - Returns: `true` when this object is a Python `set`; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    public func isSet() async throws -> Bool {
        try await interpreter.isSet(self)
    }
    
    /// Returns true if this Python object is a frozenset.
    ///
    /// - Returns: `true` when this object is a Python `frozenset`; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    public func isFrozenSet() async throws -> Bool {
        try await interpreter.isFrozenSet(self)
    }
    
    /// Returns true if this Python object is a set or frozenset.
    ///
    /// - Returns: `true` when this object is a Python `set` or `frozenset`; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    public func isAnySet() async throws -> Bool {
        try await interpreter.isAnySet(self)
    }
    
    /// Returns the number of elements in this Python set or frozenset.
    ///
    /// - Returns: The set length.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a set or frozenset,
    ///   or `PythonError` if Python raises while reading the set length.
    public func setCount() async throws -> Int {
        try await interpreter.getSetCount(self)
    }
    
    /// Returns this Python set or frozenset's elements as a Swift array.
    ///
    /// Python sets are unordered, so the returned array uses Python's current set
    /// iteration order. Use this for eager access to the elements as `PythonObject` values.
    ///
    /// - Returns: A Swift array containing this Python set or frozenset's elements.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a set or frozenset,
    ///   or `PythonError` if Python raises while iterating the set.
    public func asSetArray() async throws -> [PythonObject] {
        try await interpreter.toSetArray(self)
    }
    
    /// Returns true if this Python set or frozenset contains an item.
    ///
    /// - Parameters:
    ///   - item: The item to check. It is converted to Python before checking membership.
    /// - Returns: `true` if the item is present; otherwise `false`.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a set or frozenset,
    ///   or `PythonError` if conversion or membership checking fails.
    public func setContains(_ item: any PendingPythonConvertible) async throws -> Bool {
        try await interpreter.setContains(item, in: self)
    }
    
    /// Adds an item to this Python set.
    ///
    /// - Parameters:
    ///   - item: The item to add. It is converted to Python before insertion.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a mutable set,
    ///   or `PythonError` if conversion or insertion fails.
    public func setAdd(_ item: any PendingPythonConvertible) async throws {
        try await interpreter.addSetItem(item, to: self)
    }
    
    /// Removes an item from this Python set, raising if the item is absent.
    ///
    /// This follows Python `set.remove` semantics.
    ///
    /// - Parameters:
    ///   - item: The item to remove. It is converted to Python before removal.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a mutable set,
    ///   or `PythonError.pythonException` if Python raises, including missing items.
    public func setRemove(_ item: any PendingPythonConvertible) async throws {
        try await interpreter.removeSetItem(item, from: self)
    }
    
    /// Discards an item from this Python set without raising if the item is absent.
    ///
    /// This follows Python `set.discard` semantics.
    ///
    /// - Parameters:
    ///   - item: The item to discard. It is converted to Python before removal.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a mutable set,
    ///   or `PythonError` if conversion or discard fails.
    public func setDiscard(_ item: any PendingPythonConvertible) async throws {
        try await interpreter.discardSetItem(item, from: self)
    }
    
    // MARK: Tuple support
    
    /// Returns true if this Python object is a tuple.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic.
    ///
    /// ```swift
    /// if try await object.isTuple() {
    ///     let count = try await object.tupleCount()
    /// }
    /// ```
    ///
    /// - Returns: `true` when this object is a Python tuple; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    public func isTuple() async throws -> Bool {
        return try await interpreter.isTuple(self)
    }
    
    /// Returns the number of elements in this Python tuple.
    ///
    /// Use `await` for correctly managed Swift and Python concurrency. Reference
    /// counting and GIL-handling are automatic.
    ///
    /// ```swift
    /// let count = try await tuple.tupleCount()
    /// ```
    ///
    /// - Returns: The number of elements in the tuple.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   or `PythonError` if Python raises while reading the tuple size.
    public func tupleCount() async throws -> Int {
        return try await interpreter.getTupleCount(self)
    }
    
    /// Converts this Python tuple to a Swift array of PythonObject elements.
    ///
    /// Use this when the tuple length is dynamic. The returned array contains
    /// reference-managed `PythonObject` values for each tuple element.
    ///
    /// ```swift
    /// let elements = try await tuple.asTupleArray()
    /// for element in elements {
    ///     print(try await String(element))
    /// }
    /// ```
    ///
    /// - Returns: A Swift array containing the tuple elements as `PythonObject` values.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   or `PythonError` if Python raises while reading an element.
    public func asTupleArray() async throws -> [PythonObject] {
        return try await interpreter.toTupleArray(self)
    }
    
    /// Returns the tuple element at the specified index.
    ///
    /// Tuple indexing is zero-based. Negative indexing is not currently documented as
    /// supported by this helper; call Python directly if you need full Python indexing
    /// behavior.
    ///
    /// ```swift
    /// let first = try await tuple.tupleItem(at: 0)
    /// ```
    ///
    /// - Parameters:
    ///   - index: The zero-based tuple index to read.
    /// - Returns: The tuple element at `index` as a `PythonObject`.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   or `PythonError` if Python raises while reading the element.
    public func tupleItem(at index: Int) async throws -> PythonObject {
        return try await interpreter.tupleItem(at: index, in: self)
    }
    
    /// Converts this Python tuple to a fixed-size Swift 2-tuple.
    ///
    /// Use this when exactly two tuple elements are part of the API contract.
    ///
    /// ```swift
    /// let pair = try await tuple.asTuple2()
    /// let key = try await String(pair.0)
    /// let value = try await Int(pair.1)
    /// ```
    ///
    /// - Returns: A Swift tuple containing the two Python tuple elements.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   `PythonError.tupleArityMismatch` if the tuple does not contain exactly two
    ///   elements, or `PythonError` if Python raises while reading an element.
    public func asTuple2() async throws -> (PythonObject, PythonObject) {
        return try await interpreter.toTuple2(self)
    }
    
    /// Converts this Python tuple to a fixed-size Swift 3-tuple.
    ///
    /// Use this when exactly three tuple elements are part of the API contract.
    ///
    /// ```swift
    /// let point = try await tuple.asTuple3()
    /// let x = try await Double(point.0)
    /// let y = try await Double(point.1)
    /// let z = try await Double(point.2)
    /// ```
    ///
    /// - Returns: A Swift tuple containing the three Python tuple elements.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   `PythonError.tupleArityMismatch` if the tuple does not contain exactly three
    ///   elements, or `PythonError` if Python raises while reading an element.
    public func asTuple3() async throws -> (PythonObject, PythonObject, PythonObject) {
        return try await interpreter.toTuple3(self)
    }
    
    /// Converts this Python tuple to a fixed-size Swift 4-tuple.
    ///
    /// Use this when exactly four tuple elements are part of the API contract.
    ///
    /// ```swift
    /// let values = try await tuple.asTuple4()
    /// let first = try await Int(values.0)
    /// let second = try await Int(values.1)
    /// let third = try await Int(values.2)
    /// let fourth = try await Int(values.3)
    /// ```
    ///
    /// - Returns: A Swift tuple containing the four Python tuple elements.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   `PythonError.tupleArityMismatch` if the tuple does not contain exactly four
    ///   elements, or `PythonError` if Python raises while reading an element.
    public func asTuple4() async throws -> (PythonObject, PythonObject, PythonObject, PythonObject) {
        return try await interpreter.toTuple4(self)
    }
    
    // MARK: Bool conversion
    
    public func convertToBool() async throws -> Bool {
        return try await interpreter.convertToBool(self)
    }
    
    
    // MARK: Floating Point conversion
    
    public func convertToDouble() async throws -> Double {
        return try await interpreter.convertToDouble(self)
    }
    
    public func convertToFloat() async throws -> Float {
        do {
            return Float(try await convertToDouble())
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, _, let underlying):
                throw PythonError.conversionType( value: value, sourceType: sourceType, targetType: "Float", underlying: underlying )
            default:
                throw error
            }
        }
    }
    
    public func convertToFloat16() async throws -> Float16 {
        do {
            return Float16(try await convertToDouble())
        } catch let error as PythonError {
            switch error {
            case .conversionType(let value, let sourceType, _, let underlying):
                throw PythonError.conversionType( value: value, sourceType: sourceType, targetType: "Float16", underlying: underlying )
            default:
                throw error
            }
        }
    }
    
    // MARK: Int conversion
    
    public func convertToInt() async throws -> Int {
        return try await interpreter.convertToInt(self)
    }
    
    public func convertToInt8() async throws -> Int8 {
        return try await interpreter.convertToInt8(self)
    }
    
    public func convertToInt16() async throws -> Int16 {
        return try await interpreter.convertToInt16(self)
    }
    
    public func convertToInt32() async throws -> Int32 {
        return try await interpreter.convertToInt32(self)
    }
    
    public func convertToInt64() async throws -> Int64 {
        return try await interpreter.convertToInt64(self)
    }
    
    // MARK: UInt conversion
    
    public func convertToUInt() async throws -> UInt {
        return try await interpreter.convertToUInt(self)
    }
    
    public func convertToUInt8() async throws -> UInt8 {
        return try await interpreter.convertToUInt8(self)
    }
    
    public func convertToUInt16() async throws -> UInt16 {
        return try await interpreter.convertToUInt16(self)
    }
    
    public func convertToUInt32() async throws -> UInt32 {
        return try await interpreter.convertToUInt32(self)
    }
    
    public func convertToUInt64() async throws -> UInt64 {
        return try await interpreter.convertToUInt64(self)
    }
    
    public func convertToString() async throws -> String {
        return try await interpreter.convertToString(self)
    }
    
    // MARK: Comparison functions
    
    /// Returns true when this Python object compares equal to another value using Python `==` semantics.
    ///
    /// This delegates to CPython's rich comparison machinery, so Python controls custom comparison
    /// methods, numeric coercion, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to compare against.
    /// - Returns: `true` when `self == other`; otherwise `false`.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func equal(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.equal(lhs: self, rhs: other)
    }
    
    /// Returns true when this Python object compares not equal to another value using Python `!=` semantics.
    ///
    /// This delegates to CPython's rich comparison machinery, so Python controls custom comparison
    /// methods, numeric coercion, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to compare against.
    /// - Returns: `true` when `self != other`; otherwise `false`.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func notEqual(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.notEqual(lhs: self, rhs: other)
    }
    
    /// Returns true when this Python object compares less than another value using Python `<` semantics.
    ///
    /// This delegates to CPython's rich comparison machinery, so Python controls custom comparison
    /// methods, numeric coercion, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to compare against.
    /// - Returns: `true` when `self < other`; otherwise `false`.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func lessThan(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.lessThan(lhs: self, rhs: other)
    }
    
    /// Returns true when this Python object compares less than or equal to another value using Python `<=` semantics.
    ///
    /// This delegates to CPython's rich comparison machinery, so Python controls custom comparison
    /// methods, numeric coercion, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to compare against.
    /// - Returns: `true` when `self <= other`; otherwise `false`.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func lessThanOrEqual(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.lessThanOrEqual(lhs: self, rhs: other)
    }
    
    /// Returns true when this Python object compares greater than another value using Python `>` semantics.
    ///
    /// This delegates to CPython's rich comparison machinery, so Python controls custom comparison
    /// methods, numeric coercion, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to compare against.
    /// - Returns: `true` when `self > other`; otherwise `false`.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func greaterThan(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.greaterThan(lhs: self, rhs: other)
    }
    
    /// Returns true when this Python object compares greater than or equal to another value using Python `>=` semantics.
    ///
    /// This delegates to CPython's rich comparison machinery, so Python controls custom comparison
    /// methods, numeric coercion, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to compare against.
    /// - Returns: `true` when `self >= other`; otherwise `false`.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func greaterThanOrEqual(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.greaterThanOrEqual(lhs: self, rhs: other)
    }
    
    // MARK: Arithmetic functions
    
    /// Applies Python unary plus to this Python object using Python `+x` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Positive`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, and error reporting.
    ///
    /// - Returns: The Python unary plus result.
    /// - Throws: `PythonError.pythonException` if Python raises.
    public func positive() async throws -> PythonObject {
        return try await interpreter.positive(self)
    }
    
    /// Applies Python unary minus to this Python object using Python `-x` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Negative`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, and error reporting.
    ///
    /// - Returns: The Python unary minus result.
    /// - Throws: `PythonError.pythonException` if Python raises.
    public func negative() async throws -> PythonObject {
        return try await interpreter.negative(self)
    }
    
    /// Returns the Python absolute value of this Python object using Python `abs(x)` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Absolute`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, and error reporting.
    ///
    /// - Returns: The Python absolute value result.
    /// - Throws: `PythonError.pythonException` if Python raises.
    public func absolute() async throws -> PythonObject {
        return try await interpreter.absolute(self)
    }
    
    /// Adds a Python-convertible value to this Python object using Python `+` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Add`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to add.
    /// - Returns: The Python addition result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func add(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.add(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Adds a Python-convertible value to this Python object using Python `+=` semantics.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceAdd`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to add.
    /// - Returns: The Python in-place addition result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func addInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.addInPlace(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Subtracts a Python-convertible value from this Python object using Python `-` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Subtract`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to subtract.
    /// - Returns: The Python subtraction result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func subtract(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.subtract(minuend: self, subtrahend: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Subtracts a Python-convertible value from this Python object using Python `-=` semantics.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceSubtract`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to subtract.
    /// - Returns: The Python in-place subtraction result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func subtractInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.subtractInPlace(minuend: self, subtrahend: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Multiplies this Python object by a Python-convertible value using Python `*` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Multiply`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, sequence repetition, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to multiply by.
    /// - Returns: The Python multiplication result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func multiply(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.multiply(self, other.toPythonObject(interpreter: interpreter))
    }
    
    /// Multiplies this Python object by a Python-convertible value using Python `*=` semantics.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceMultiply`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to multiply by.
    /// - Returns: The Python in-place multiplication result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func multiplyInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.multiplyInPlace(self, other.toPythonObject(interpreter: interpreter))
    }
    
    /// Divides this Python object by a Python-convertible value using Python true-division `/` semantics.
    ///
    /// This delegates to CPython's `PyNumber_TrueDivide`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, zero-division behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible divisor.
    /// - Returns: The Python true-division result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func divide(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.divide(dividend: self, divisor: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Divides this Python object by a Python-convertible value using Python `/=` semantics.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceTrueDivide`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible divisor.
    /// - Returns: The Python in-place true-division result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func divideInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.divideInPlace(self, other.toPythonObject(interpreter: interpreter))
    }
    
    /// Returns the Python remainder of this Python object divided by a Python-convertible value.
    ///
    /// This delegates to CPython's `PyNumber_Remainder`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, zero-division behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible divisor.
    /// - Returns: The Python remainder result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func modulus(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.modulus(dividend: self, divisor: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Replaces this Python object with its Python remainder divided by a Python-convertible value.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceRemainder`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible divisor.
    /// - Returns: The Python in-place remainder result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func modulusInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.modulusInPlace(self, other.toPythonObject(interpreter: interpreter))
    }
    
    /// Raises this Python object to a Python-convertible exponent using Python `**` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Power`, so Python controls type coercion,
    /// arbitrary-precision integer behavior, complex results, zero-division behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible exponent.
    /// - Returns: The Python power result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func power(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.power(base: self, exponent: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Replaces this Python object with the result of raising it to a Python-convertible exponent.
    ///
    /// This delegates to CPython's `PyNumber_InPlacePower`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible exponent.
    /// - Returns: The Python in-place power result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func powerInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.powerInPlace(self, other.toPythonObject(interpreter: interpreter))
    }
    
    // MARK: Bitwise functions
    
    /// Combines this Python object with a Python-convertible value using Python bitwise `&` semantics.
    ///
    /// This delegates to CPython's `PyNumber_And`, so Python controls integer behavior,
    /// boolean behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to combine with this object.
    /// - Returns: The Python bitwise AND result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitwiseAnd(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitwiseAnd(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Replaces this Python object with its bitwise AND against a Python-convertible value.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceAnd`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to combine with this object.
    /// - Returns: The Python in-place bitwise AND result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitwiseAndInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitwiseAndInPlace(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Combines this Python object with a Python-convertible value using Python bitwise `|` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Or`, so Python controls integer behavior,
    /// boolean behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to combine with this object.
    /// - Returns: The Python bitwise OR result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitwiseOr(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitwiseOr(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Replaces this Python object with its bitwise OR against a Python-convertible value.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceOr`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to combine with this object.
    /// - Returns: The Python in-place bitwise OR result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitwiseOrInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitwiseOrInPlace(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Combines this Python object with a Python-convertible value using Python bitwise `^` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Xor`, so Python controls integer behavior,
    /// boolean behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to combine with this object.
    /// - Returns: The Python bitwise XOR result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitwiseXor(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitwiseXor(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Replaces this Python object with its bitwise XOR against a Python-convertible value.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceXor`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible value to combine with this object.
    /// - Returns: The Python in-place bitwise XOR result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitwiseXorInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitwiseXorInPlace(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Shifts this Python object left by a Python-convertible count using Python `<<` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Lshift`, so Python controls integer behavior,
    /// boolean behavior, overflow behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible shift count.
    /// - Returns: The Python left-shift result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitShiftLeft(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitShiftLeft(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Replaces this Python object with its left shift by a Python-convertible count.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceLshift`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible shift count.
    /// - Returns: The Python in-place left-shift result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitShiftLeftInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitShiftLeftInPlace(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Shifts this Python object right by a Python-convertible count using Python `>>` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Rshift`, so Python controls integer behavior,
    /// boolean behavior, and error reporting.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible shift count.
    /// - Returns: The Python right-shift result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitShiftRight(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitShiftRight(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Replaces this Python object with its right shift by a Python-convertible count.
    ///
    /// This delegates to CPython's `PyNumber_InPlaceRshift`. Python may mutate mutable
    /// objects in place or return a new object for immutable values.
    ///
    /// - Parameters:
    ///   - other: The Python-convertible shift count.
    /// - Returns: The Python in-place right-shift result.
    /// - Throws: `PythonError.pythonException` if Python raises, or `PythonError` if conversion fails.
    public func bitShiftRightInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.bitShiftRightInPlace(lhs: self, rhs: other.toPythonObject(interpreter: interpreter))
    }
    
    /// Returns the Python bitwise inversion of this Python object using Python `~` semantics.
    ///
    /// This delegates to CPython's `PyNumber_Invert`, so Python controls integer behavior,
    /// boolean behavior, and error reporting.
    ///
    /// - Returns: The Python bitwise inversion result.
    /// - Throws: `PythonError.pythonException` if Python raises.
    public func bitwiseInvert() async throws -> PythonObject {
        return try await interpreter.bitwiseInvert(self)
    }
    
    // MARK: Trueness
    
    /// Returns this object's Python truth value.
    ///
    /// This delegates to CPython's `PyObject_IsTrue`, so Python controls truthiness for
    /// built-in values and custom `__bool__` or `__len__` implementations.
    ///
    /// - Returns: `true` when Python considers this object truthy; otherwise `false`.
    /// - Throws: `PythonError.pythonException` if Python raises while evaluating truthiness.
    public func isTrue() async throws -> Bool {
        return try await interpreter.isTrue(self)
    }
    
    /// Returns whether this object is falsey under Python truthiness rules.
    ///
    /// This delegates to CPython's `PyObject_Not`, so Python controls truthiness for
    /// built-in values and custom `__bool__` or `__len__` implementations.
    ///
    /// - Returns: `true` when Python considers this object falsey; otherwise `false`.
    /// - Throws: `PythonError.pythonException` if Python raises while evaluating truthiness.
    public func isNotTrue() async throws -> Bool {
        return try await interpreter.isNotTrue(self)
    }
    
    /// Returns the Python `and` result for this object and an already-created right operand.
    ///
    /// Python `and` returns one of its operands, not a `Bool`: it returns `self` when
    /// `self` is falsey, otherwise it returns `rhs`. Use the closure overload when the
    /// right operand should not be created unless needed.
    ///
    /// - Parameter rhs: The right operand.
    /// - Returns: `self` if `self` is falsey; otherwise `rhs`.
    /// - Throws: `PythonError.pythonException` if Python raises while evaluating truthiness.
    public func logicalAnd(_ rhs: PythonObject) async throws -> PythonObject {
        if try await isTrue() {
            return rhs
        }
        return self
    }
    
    /// Returns the Python `and` result for this object and a lazily-created right operand.
    ///
    /// Python `and` short-circuits. The `rhs` closure is only evaluated when `self` is
    /// truthy, and the result is one of the operands rather than a Swift `Bool`.
    ///
    /// - Parameter rhs: A closure that creates the right operand only when needed.
    /// - Returns: `self` if `self` is falsey; otherwise the result of `rhs`.
    /// - Throws: `PythonError.pythonException` if Python raises while evaluating truthiness,
    ///   or any error thrown by `rhs`.
    public func logicalAnd(_ rhs: () async throws -> PythonObject) async throws -> PythonObject {
        if try await isTrue() {
            return try await rhs()
        }
        return self
    }
    
    /// Returns the Python `or` result for this object and an already-created right operand.
    ///
    /// Python `or` returns one of its operands, not a `Bool`: it returns `self` when
    /// `self` is truthy, otherwise it returns `rhs`. Use the closure overload when the
    /// right operand should not be created unless needed.
    ///
    /// - Parameter rhs: The right operand.
    /// - Returns: `self` if `self` is truthy; otherwise `rhs`.
    /// - Throws: `PythonError.pythonException` if Python raises while evaluating truthiness.
    public func logicalOr(_ rhs: PythonObject) async throws -> PythonObject {
        if try await isTrue() {
            return self
        }
        return rhs
    }
    
    /// Returns the Python `or` result for this object and a lazily-created right operand.
    ///
    /// Python `or` short-circuits. The `rhs` closure is only evaluated when `self` is
    /// falsey, and the result is one of the operands rather than a Swift `Bool`.
    ///
    /// - Parameter rhs: A closure that creates the right operand only when needed.
    /// - Returns: `self` if `self` is truthy; otherwise the result of `rhs`.
    /// - Throws: `PythonError.pythonException` if Python raises while evaluating truthiness,
    ///   or any error thrown by `rhs`.
    public func logicalOr(_ rhs: () async throws -> PythonObject) async throws -> PythonObject {
        if try await isTrue() {
            return self
        }
        return try await rhs()
    }
}


extension PythonObject: AsyncSequence {
    /// The element type produced when asynchronously iterating a Python iterable.
    public typealias Element = PythonObject
    
    /// An async iterator backed by Python's iterator protocol.
    ///
    /// The Python iterator is created lazily on the first call to `next()`. Use this
    /// through Swift's `for try await` syntax to consume Python iterables without
    /// materializing every item into a Swift collection first.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var pyIterator: PythonObject?
        private let source: PythonObject
        
        internal init(source: PythonObject) {
            self.source = source
        }
        
        /// Returns the next item from this Python iterator.
        ///
        /// Python's normal `StopIteration` is returned as `nil`. Other Python exceptions
        /// are preserved as thrown `PythonError.pythonException` values. The first call
        /// creates the underlying Python iterator and can throw if the source object is
        /// not iterable.
        ///
        /// - Returns: The next Python item, or `nil` when iteration is exhausted.
        /// - Throws: `PythonError.pythonException` if Python raises while creating or advancing the iterator.
        public mutating func next() async throws -> PythonObject? {
            let iterator: PythonObject
            if let existingIterator = pyIterator {
                iterator = existingIterator
            } else {
                iterator = try await source.interpreter.makeIterator(for: source)
                pyIterator = iterator
            }
            return try await source.interpreter.iteratorNext(iterator)
        }
    }
    
    /// Creates an async iterator over this Python iterable.
    ///
    /// This is the `AsyncSequence` conformance entry point used by Swift
    /// `for try await`. It does not call Python immediately; the underlying Python
    /// iterator is created on the first call to `AsyncIterator.next()`.
    ///
    /// Use this when consuming Python lists, tuples, sets, dictionaries, views,
    /// generators, ranges, or custom iterables without eagerly materializing them
    /// into Swift arrays.
    ///
    /// - Returns: An async iterator over this Python iterable.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(source: self)
    }
}
