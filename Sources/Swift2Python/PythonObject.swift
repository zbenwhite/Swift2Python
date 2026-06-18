//
// PythonObject.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

import Foundation

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
    
    // Temporary object result of attribute access.  Methods can be called asynchronously on PythonObject this way.
    public struct CallablePythonObject {
        private let obj: PythonObject
        private let method: String
        
        public init (object: PythonObject, methodName: String) {
            self.obj = object
            self.method = methodName
        }
        
        public func callAsFunction(_ args: any PendingPythonConvertible...) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object:obj, methodName:method, collectedArgs: args)
        }
        
        public func callAsFunction(_ args: any PendingPythonConvertible..., kwargs: [String: PendingPythonConvertible] = [:]) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object:obj, methodName:method, collectedArgs: args, kwargs:kwargs)
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
    
    // a.name
    // (can't do actual a.name because we need try await and they're not available for a.name)
    public func get(attr: String) async throws -> PythonObject {
        return try await interpreter.get(object: self, attribute: attr)
    }
    
    // a.name = value
    // (can't do actual a.name = value because we need try await ...)
    public func set(attr: String, value: PendingPythonConvertible) async throws {
        try await interpreter.set(object: self, attribute: attr, value: value.toPythonObject(interpreter: self.interpreter))
    }
    
    // a.[key]
    // (can't do actual a[key] because we need try await ...)
    public func getItem(key: PendingPythonConvertible) async throws -> PythonObject {
        try await interpreter.getItem(object: self, key: key.toPythonObject(interpreter: self.interpreter))
    }
    
    // a.[key] = value
    // (can't do actual a[key] = value because we need try await ...)
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
    
    public func equals(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.equals(lhs: self, rhs: other)
    }
    
    public func notEquals(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.notEquals(lhs: self, rhs: other)
    }
    
    public func lessThan(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.lessThan(lhs: self, rhs: other)
    }
    
    public func lessThanOrEqual(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.lessThanOrEqual(lhs: self, rhs: other)
    }
    
    public func greaterThan(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.greaterThan(lhs: self, rhs: other)
    }
    
    public func greaterThanOrEqual(_ other: PendingPythonConvertible) async throws -> Bool {
        return try await interpreter.greaterThanOrEqual(lhs: self, rhs: other)
    }
    
    // MARK: Arithmetic functions
    
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
    
    public func modulus(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.modulus(dividend: self, divisor: other.toPythonObject(interpreter: interpreter))
    }
    
    public func modulusInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.modulusInPlace(self, other.toPythonObject(interpreter: interpreter))
    }
    
    public func power(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.power(base: self, exponent: other.toPythonObject(interpreter: interpreter))
    }
    
    public func powerInPlace(_ other: PendingPythonConvertible) async throws -> PythonObject {
        return try await interpreter.powerInPlace(self, other.toPythonObject(interpreter: interpreter))
    }
    
    // MARK: Trueness
    
    public func isTrue() async throws -> Bool {
        return try await interpreter.isTrue(self)
    }
    
    public func isNotTrue() async throws -> Bool {
        return try await interpreter.isNotTrue(self)
    }
}
