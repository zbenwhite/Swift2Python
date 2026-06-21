//
//  SafePythonObject+Container.swift
//  Swift2Python
//
//  Created by Ben White on 5/3/26.
//

import Foundation


extension PythonInterpreter.SafePythonObject {
    
    
    
    // MARK: Sequence support
    
    /// The element type produced when iterating a safe Python iterable.
    public typealias Element = PythonInterpreter.SafePythonObject
    
    /// A Swift iterator over a Python iterable inside `withIsolatedContext`.
    ///
    /// This iterator is backed by Python's iterator protocol. Use `nextThrowing()`
    /// when the caller must distinguish normal exhaustion from Python errors.
    /// Swift `for`-`in` uses `next()`, which cannot throw and traps on Python errors.
    public struct SafePythonIterator: IteratorProtocol {
        private var pyIterator: PythonInterpreter.SafePythonObject
        
        internal init(sequence: PythonInterpreter.SafePythonObject) throws {
            self.pyIterator = try sequence.interpreter.assumeIsolated {
                try $0.makeIterator(for: sequence)
            }
        }
        
        /// Returns the next Python item, or `nil` when the iterator is exhausted.
        ///
        /// Unlike Swift's non-throwing `next()`, this method preserves Python errors.
        /// Use this when iterating objects whose `__iter__` or `__next__` may raise for
        /// reasons other than normal `StopIteration`.
        ///
        /// - Returns: The next item, or `nil` when Python reports normal iterator exhaustion.
        /// - Throws: `PythonError.safePythonException` if Python raises while advancing the iterator.
        @available(*, noasync, message: "Only safe inside withIsolatedContext()")
        public mutating func nextThrowing() throws -> PythonInterpreter.SafePythonObject? {
            let iterator = pyIterator
            return try iterator.interpreter.assumeIsolated {
                try $0.iteratorNext(iterator)
            }
        }
        
        /// Returns the next Python item for Swift `Sequence` iteration.
        ///
        /// This is the non-throwing `IteratorProtocol` entry point used by Swift
        /// `for`-`in`. It returns `nil` for normal Python `StopIteration` and traps
        /// if Python raises any other error. Use `nextThrowing()` when errors should
        /// be handled by the caller.
        ///
        /// - Returns: The next item, or `nil` when Python reports normal iterator exhaustion.
        public mutating func next() -> PythonInterpreter.SafePythonObject? {
            do {
                return try nextThrowing()
            } catch {
                fatalError("Python iterator raised while advancing: \(error)")
            }
        }
    }
    
    /// Creates a throwing Python iterator for this object.
    ///
    /// Use this when you need recoverable error handling. `makeIterator()` is required
    /// by Swift's `Sequence` protocol and traps if Python refuses to create an iterator.
    ///
    /// - Returns: A safe Python iterator.
    /// - Throws: `PythonError.safePythonException` if this object is not iterable or Python raises.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func pythonIterator() throws -> SafePythonIterator {
        try SafePythonIterator(sequence: self)
    }
    
    /// Creates a Python iterator for Swift `Sequence` iteration.
    ///
    /// This is the non-throwing `Sequence` conformance entry point used by Swift
    /// `for`-`in`. It traps if Python refuses to create an iterator. Use
    /// `pythonIterator()` when iterator creation errors should be handled by the caller.
    ///
    /// - Returns: A safe Python iterator.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func makeIterator() -> SafePythonIterator {
        do {
            return try pythonIterator()
        } catch {
            fatalError("Failed to create iterator for SafePythonObject: \(error)")
        }
    }
    
    // MARK: items() Sequence support
    
    /// A Swift sequence over the key/value pairs produced by Python `dict.items()`.
    ///
    /// Each element is returned as a labeled Swift tuple containing safe Python
    /// objects for the key and value. Iteration must happen inside `withIsolatedContext`.
    public struct ItemsSequence: Sequence {
        /// The key/value pair type produced while iterating Python `dict.items()`.
        public typealias Element = (key: PythonInterpreter.SafePythonObject, value: PythonInterpreter.SafePythonObject)
        
        private let dictView: PythonInterpreter.SafePythonObject
        
        internal init(dictView: PythonInterpreter.SafePythonObject) {
            self.dictView = dictView
        }
        
        /// An iterator over Python `dict.items()` pairs.
        ///
        /// The underlying Python iterator yields 2-item Python tuples. This iterator
        /// unwraps each tuple into a Swift `(key: value:)` pair of safe Python objects.
        public struct Iterator: IteratorProtocol {
            private var pyIterator: PythonInterpreter.SafePythonObject   // the iterator from items()
            
            internal init(dictView: PythonInterpreter.SafePythonObject) throws {
                self.pyIterator = try dictView.interpreter.assumeIsolated {
                    let itemsMethod = try $0.syncGetObjectAttribute(dictView, "items")
                    let itemsView = try $0.syncCall(callable: itemsMethod)
                    return try $0.makeIterator(for: itemsView)
                }
            }
            
            /// Returns the next key/value pair from Python `dict.items()`.
            ///
            /// Python's normal `StopIteration` is returned as `nil`. Other Python
            /// exceptions are preserved so the caller can handle them.
            ///
            /// - Returns: The next key/value pair, or `nil` when iteration is exhausted.
            /// - Throws: `PythonError.safePythonException` if Python raises while advancing the iterator.
            @available(*, noasync, message: "Only safe inside withIsolatedContext()")
            public mutating func nextThrowing() throws -> Element? {
                let iterator = pyIterator
                guard let item = try iterator.interpreter.assumeIsolated({ try $0.iteratorNext(iterator) }) else {
                    return nil
                }
                let key = item[0]
                let value = item[1]
                return (key: key, value: value)
            }
            
            /// Returns the next key/value pair for Swift `Sequence` iteration.
            ///
            /// This is the non-throwing `IteratorProtocol` entry point used by Swift
            /// `for`-`in`. It returns `nil` for normal Python `StopIteration` and traps
            /// if Python raises any other error. Use `nextThrowing()` when errors should
            /// be handled by the caller.
            ///
            /// - Returns: The next key/value pair, or `nil` when iteration is exhausted.
            public mutating func next() -> Element? {
                do {
                    return try nextThrowing()
                } catch {
                    fatalError("Python items() iterator raised while advancing: \(error)")
                }
            }
        }
        
        /// Creates an iterator over this dictionary's `items()` view.
        ///
        /// This is the non-throwing `Sequence` conformance entry point used by Swift
        /// `for`-`in`. It traps if Python raises while calling `items()` or creating
        /// the Python iterator.
        ///
        /// - Returns: An iterator over key/value pairs.
        public func makeIterator() -> Iterator {
            do {
                return try Iterator(dictView: dictView)
            } catch {
                fatalError("Failed to create items() iterator: \(error)")
            }
        }
    }
    
    /// Returns a Swift sequence over this Python dictionary's key/value pairs.
    ///
    /// This calls Python `dict.items()` when iteration starts and exposes each
    /// returned pair as `(key: SafePythonObject, value: SafePythonObject)`. Use this
    /// for `for`-`in` iteration inside `withIsolatedContext`; use `dictItems` when you
    /// want an eager Swift array of pairs instead.
    ///
    /// - Returns: A sequence over this dictionary's `items()` view.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func items() -> ItemsSequence {
        ItemsSequence(dictView: self)
    }
    
    // MARK: Set Support
    
    /// Returns true if this safe Python object is a set.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// - Returns: `true` when this object is a Python `set`; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var isSet: Bool {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncIsSet(self)
            }
        }
    }
    
    /// Returns true if this safe Python object is a frozenset.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// - Returns: `true` when this object is a Python `frozenset`; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var isFrozenSet: Bool {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncIsFrozenSet(self)
            }
        }
    }
    
    /// Returns true if this safe Python object is a set or frozenset.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// - Returns: `true` when this object is a Python `set` or `frozenset`; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var isAnySet: Bool {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncIsAnySet(self)
            }
        }
    }
    
    /// Returns the number of elements in this safe Python set or frozenset.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// - Returns: The set length.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a set or frozenset,
    ///   or `PythonError` if Python raises while reading the set length.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var setCount: Int {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncSetCount(self)
            }
        }
    }
    
    /// Returns this safe Python set or frozenset's elements as a Swift array.
    ///
    /// Python sets are unordered, so the returned array uses Python's current set
    /// iteration order. Only use this property inside `withIsolatedContext`.
    ///
    /// - Returns: A Swift array containing this Python set or frozenset's elements.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a set or frozenset,
    ///   or `PythonError` if Python raises while iterating the set.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var setArray: [PythonInterpreter.SafePythonObject] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncSetArray(self)
            }
        }
    }
    
    /// Returns true if this safe Python set or frozenset contains an item.
    ///
    /// - Parameters:
    ///   - item: The item to check. It is converted to Python before checking membership.
    /// - Returns: `true` if the item is present; otherwise `false`.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a set or frozenset,
    ///   or `PythonError` if conversion or membership checking fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func setContains(_ item: any SafePythonConvertible) throws -> Bool {
        try interpreter.assumeIsolated {
            try $0.syncSetContains(item, in: self)
        }
    }
    
    /// Adds an item to this safe Python set.
    ///
    /// - Parameters:
    ///   - item: The item to add. It is converted to Python before insertion.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a mutable set,
    ///   or `PythonError` if conversion or insertion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func setAdd(_ item: any SafePythonConvertible) throws {
        try interpreter.assumeIsolated {
            try $0.syncAddSetItem(item, to: self)
        }
    }
    
    /// Removes an item from this safe Python set, raising if the item is absent.
    ///
    /// This follows Python `set.remove` semantics.
    ///
    /// - Parameters:
    ///   - item: The item to remove. It is converted to Python before removal.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a mutable set,
    ///   or `PythonError.safePythonException` if Python raises, including missing items.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func setRemove(_ item: any SafePythonConvertible) throws {
        try interpreter.assumeIsolated {
            try $0.syncRemoveSetItem(item, from: self)
        }
    }
    
    /// Discards an item from this safe Python set without raising if the item is absent.
    ///
    /// This follows Python `set.discard` semantics.
    ///
    /// - Parameters:
    ///   - item: The item to discard. It is converted to Python before removal.
    /// - Throws: `PythonError.setConversionFailed` if this object is not a mutable set,
    ///   or `PythonError` if conversion or discard fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func setDiscard(_ item: any SafePythonConvertible) throws {
        try interpreter.assumeIsolated {
            try $0.syncDiscardSetItem(item, from: self)
        }
    }
    
    // MARK: Dictionary Support
    
    /// Returns true if this safe Python object is a dictionary.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let object = try context.convertToSafePython(dictionary: ["name": "Ada"])
    ///     if try object.isDict {
    ///         let count = try object.dictCount
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: `true` when this object is a Python dictionary; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var isDict: Bool {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncIsDict(self)
            }
            
        }
    }
    
    /// Returns the number of entries in this safe Python dictionary.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])
    ///     let count = try dict.dictCount
    /// }
    /// ```
    ///
    /// - Returns: The number of key-value pairs in the dictionary.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while reading the dictionary size.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var dictCount: Int {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncDictCount(self)
            }
        }
    }
    
    /// Returns this safe Python dictionary's keys as a Swift array of safe Python objects.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. Use this when you want an eager Swift array.
    /// To preserve Python's view semantics, call Python's `keys()` method directly instead.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])
    ///     let keys = try dict.dictKeys
    /// }
    /// ```
    ///
    /// - Returns: A Swift array containing the dictionary keys as `SafePythonObject` values.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while reading the keys.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var dictKeys: [PythonInterpreter.SafePythonObject] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncDictKeys(self)
            }
        }
    }
    
    /// Returns this safe Python dictionary's values as a Swift array of safe Python objects.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. Use this when you want an eager Swift array.
    /// To preserve Python's view semantics, call Python's `values()` method directly instead.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])
    ///     let values = try dict.dictValues
    /// }
    /// ```
    ///
    /// - Returns: A Swift array containing the dictionary values as `SafePythonObject` values.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while reading the values.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var dictValues: [PythonInterpreter.SafePythonObject] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncDictValues(self)
            }
        }
    }
    
    /// Returns this safe Python dictionary's key-value pairs as a Swift array.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. Use this when you want an eager Swift array.
    /// To preserve Python's view semantics, call Python's `items()` method directly instead.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])
    ///     let items = try dict.dictItems
    /// }
    /// ```
    ///
    /// - Returns: A Swift array of `(key: SafePythonObject, value: SafePythonObject)` pairs.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while reading the items.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var dictItems: [(key: PythonInterpreter.SafePythonObject, value: PythonInterpreter.SafePythonObject)] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncDictItems(self)
            }
        }
    }
    
    /// Deletes a key from this safe Python dictionary.
    ///
    /// Only use this method inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. This helper validates that this
    /// object is a Python dictionary before deleting the item.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])
    ///     try dict.deleteItem(key: "name")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The dictionary key to delete.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while deleting the key.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func deleteItem(key: SafePythonConvertible) throws {
        try interpreter.assumeIsolated {
            let keyObj = try key.toSafePythonObject(interpreter: $0)
            try $0.syncDeleteItem(fromDict: self, key: keyObj)
        }
    }
    
    /// Returns true if this safe Python dictionary contains the given key.
    ///
    /// Only use this method inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. This helper validates that this
    /// object is a Python dictionary before checking key membership.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])
    ///     if try dict.containsKey("name") {
    ///         print("name is present")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The dictionary key to check.
    /// - Returns: `true` when the key is present; otherwise `false`.
    /// - Throws: `PythonError.dictionaryConversionFailed` if this object is not a dictionary,
    ///   or `PythonError` if Python raises while checking key membership.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func containsKey(_ key: SafePythonConvertible) throws -> Bool {
        try interpreter.assumeIsolated {
            let keyObj = try key.toSafePythonObject(interpreter: $0)
            return try $0.syncContainsKey(keyObj, inDict: self)
        }
    }
    
    // MARK: List Support
    
    /// Returns true if this safe Python object is a list.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let object = try context.convertToSafePython(array: [1, 2, 3])
    ///     if try object.isList {
    ///         let count = try object.listCount
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: `true` when this object is a Python list; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var isList: Bool {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncIsList(self)
            }
        }
    }
    
    /// Returns the number of elements in this safe Python list.
    ///
    /// Only use this property inside `withIsolatedContext`.
    ///
    /// - Returns: The list length.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError` if Python raises while reading the list length.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var listCount: Int {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncListCount(self)
            }
        }
    }
    
    /// Returns this safe Python list's elements as a Swift array.
    ///
    /// Use this when you want an eager Swift array of `SafePythonObject` values.
    /// Only use this property inside `withIsolatedContext`.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let list = try context.convertToSafePython(array: [1, 2, 3])
    ///     let elements = try list.listArray
    ///     print(elements.count)
    /// }
    /// ```
    ///
    /// - Returns: A Swift array containing this Python list's elements.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError` if Python raises while reading the list.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var listArray: [PythonInterpreter.SafePythonObject] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncListArray(self)
            }
        }
    }
    
    /// Returns the list element at the specified index.
    ///
    /// Indexes are zero-based. Negative indexes use Python list semantics, so `-1`
    /// returns the last element. Only use this method inside `withIsolatedContext`.
    ///
    /// - Parameters:
    ///   - index: The Python list index to read.
    /// - Returns: The element at `index`.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError.safePythonException` if Python raises, including out-of-bounds indexes.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func listItem(at index: Int) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.syncListItem(at: index, in: self)
        }
    }
    
    /// Appends an item to this safe Python list.
    ///
    /// Only use this method inside `withIsolatedContext`.
    ///
    /// - Parameters:
    ///   - item: The value to append. It is converted to a Python object before insertion.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError` if conversion or append fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func listAppendItem(_ item: any SafePythonConvertible) throws {
        try interpreter.assumeIsolated {
            try $0.syncAppendListItem(item, to: self)
        }
    }

    /// Inserts an item into this safe Python list at the specified index.
    ///
    /// This follows Python's `list.insert` behavior for indexes outside the list bounds.
    /// Only use this method inside `withIsolatedContext`.
    ///
    /// - Parameters:
    ///   - item: The value to insert. It is converted to a Python object before insertion.
    ///   - index: The index where the value should be inserted.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError` if conversion or insertion fails.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func listInsertItem(_ item: any SafePythonConvertible, at index: Int) throws {
        try interpreter.assumeIsolated {
            try $0.syncInsertListItem(item, at: index, to: self)
        }
    }
    
    /// Replaces the list element at the specified index.
    ///
    /// Indexes are zero-based. Negative indexes use Python list semantics, so `-1`
    /// replaces the last element. Only use this method inside `withIsolatedContext`.
    ///
    /// - Parameters:
    ///   - index: The Python list index to replace.
    ///   - value: The new value. It is converted to a Python object before assignment.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError.safePythonException` if Python raises, including out-of-bounds indexes.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func listSetItem(at index: Int, to value: any SafePythonConvertible) throws {
        try interpreter.assumeIsolated {
            try $0.syncSetListItem(value, at: index , in: self)
        }
    }
    
    /// Deletes the list element at the specified index.
    ///
    /// Indexes are interpreted by Python, including negative indexes such as `-1`.
    /// Only use this method inside `withIsolatedContext`.
    ///
    /// - Parameters:
    ///   - index: The Python list index to delete.
    /// - Throws: `PythonError.listConversionFailed` if this object is not a list,
    ///   or `PythonError.safePythonException` if Python raises, including out-of-bounds indexes.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func listDeleteItem(at index: Int) throws {
        try interpreter.assumeIsolated {
            try $0.syncDeleteItem(fromList: self, at: index)
        }
    }
    
    // MARK: Tuple Support
    
    /// Returns true if this safe Python object is a tuple.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try interpreter.withIsolatedContext { context in
    ///     let object = try context.convertToSafePython(tupleOf: 1, 2, 3)
    ///     if try object.isTuple {
    ///         let count = try object.tupleCount
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: `true` when this object is a Python tuple; otherwise `false`.
    /// - Throws: `PythonError` if Python raises while checking the object type.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var isTuple: Bool {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncIsTuple(self)
            }
        }
    }
    
    /// Returns the number of elements in this safe Python tuple.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment.
    ///
    /// ```swift
    /// try interpreter.withIsolatedContext { context in
    ///     let tuple = try context.convertToSafePython(tupleOf: 1, 2, 3)
    ///     let count = try tuple.tupleCount
    /// }
    /// ```
    ///
    /// - Returns: The number of elements in the tuple.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   or `PythonError` if Python raises while reading the tuple size.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tupleCount: Int {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTupleCount(self)
            }
        }
    }
    
    /// Converts this safe Python tuple to a Swift array of safe Python object elements.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. Use this when the tuple length is dynamic.
    ///
    /// ```swift
    /// try interpreter.withIsolatedContext { context in
    ///     let tuple = try context.convertToSafePython(tupleContentsOf: [1, 2, 3])
    ///     let elements = try tuple.tupleArray
    /// }
    /// ```
    ///
    /// - Returns: A Swift array containing the tuple elements as `SafePythonObject` values.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   or `PythonError` if Python raises while reading an element.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tupleArray: [PythonInterpreter.SafePythonObject] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTupleArray(self)
            }
        }
    }
    
    /// Returns the tuple element at the specified index.
    ///
    /// Only use this method inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. Tuple indexing is zero-based. Negative
    /// indexing is not currently documented as supported by this helper; call Python
    /// directly if you need full Python indexing behavior.
    ///
    /// ```swift
    /// try interpreter.withIsolatedContext { context in
    ///     let tuple = try context.convertToSafePython(tupleOf: "first", "second")
    ///     let first = try tuple.tupleItem(at: 0)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - index: The zero-based tuple index to read.
    /// - Returns: The tuple element at `index` as a `SafePythonObject`.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   or `PythonError` if Python raises while reading the element.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public func tupleItem(at index: Int) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.syncTupleItem(at: index, in: self)
        }
    }
    
    /// Converts this safe Python tuple to a fixed-size Swift 2-tuple.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. Use this when exactly two tuple
    /// elements are part of the API contract.
    ///
    /// ```swift
    /// try interpreter.withIsolatedContext { context in
    ///     let tuple = try context.convertToSafePython(tupleOf: "left", 42)
    ///     let pair = try tuple.tuple2
    /// }
    /// ```
    ///
    /// - Returns: A Swift tuple containing the two Python tuple elements.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   `PythonError.tupleArityMismatch` if the tuple does not contain exactly two
    ///   elements, or `PythonError` if Python raises while reading an element.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tuple2: (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    ) {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTuple2(self)
            }
        }
    }
    
    /// Converts this safe Python tuple to a fixed-size Swift 3-tuple.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. Use this when exactly three tuple
    /// elements are part of the API contract.
    ///
    /// ```swift
    /// try interpreter.withIsolatedContext { context in
    ///     let tuple = try context.convertToSafePython(tupleOf: 1.25, 2.5, 5.0)
    ///     let point = try tuple.tuple3
    /// }
    /// ```
    ///
    /// - Returns: A Swift tuple containing the three Python tuple elements.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   `PythonError.tupleArityMismatch` if the tuple does not contain exactly three
    ///   elements, or `PythonError` if Python raises while reading an element.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tuple3: (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    ) {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTuple3(self)
            }
        }
    }
    
    /// Converts this safe Python tuple to a fixed-size Swift 4-tuple.
    ///
    /// Only use this property inside the synchronous, GIL-managed, reference-managed
    /// local `withIsolatedContext` environment. Use this when exactly four tuple
    /// elements are part of the API contract.
    ///
    /// ```swift
    /// try interpreter.withIsolatedContext { context in
    ///     let tuple = try context.convertToSafePython(tupleOf: 1, 2, 3, 4)
    ///     let values = try tuple.tuple4
    /// }
    /// ```
    ///
    /// - Returns: A Swift tuple containing the four Python tuple elements.
    /// - Throws: `PythonError.tupleConversionFailed` if this object is not a tuple,
    ///   `PythonError.tupleArityMismatch` if the tuple does not contain exactly four
    ///   elements, or `PythonError` if Python raises while reading an element.
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tuple4: (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    ) {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTuple4(self)
            }
        }
    }
}
