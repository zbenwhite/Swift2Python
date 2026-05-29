//
//  SafePythonObject+Container.swift
//  Swift2Python
//
//  Created by Ben White on 5/3/26.
//

import Foundation


extension PythonInterpreter.SafePythonObject {
    
    
    
    // MARK: Sequence support
    
    public typealias Element = PythonInterpreter.SafePythonObject
    
    public struct SafePythonIterator: IteratorProtocol {
        private var pyIterator: PythonInterpreter.SafePythonObject
        
        internal init(sequence: PythonInterpreter.SafePythonObject) throws {
            self.pyIterator = try sequence.__iter__()
        }
        
        public mutating func next() -> PythonInterpreter.SafePythonObject? {
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
    
    // MARK: items() Sequence support
    
    public struct ItemsSequence: Sequence {
        public typealias Element = (key: PythonInterpreter.SafePythonObject, value: PythonInterpreter.SafePythonObject)
        
        private let dictView: PythonInterpreter.SafePythonObject
        
        internal init(dictView: PythonInterpreter.SafePythonObject) {
            self.dictView = dictView
        }
        
        public struct Iterator: IteratorProtocol {
            private var pyIterator: PythonInterpreter.SafePythonObject   // the iterator from items()
            
            internal init(dictView: PythonInterpreter.SafePythonObject) throws {
                self.pyIterator = try dictView.__iter__()
            }
            
            public mutating func next() -> Element? {
                do {
                    // Each item from dict.items() is a 2-element tuple in Python
                    let item = try pyIterator.__next__()
                    
                    // Unpack the Python tuple using subscript (already implemented)
                    let key   = item[0]
                    let value = item[1]
                    
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
