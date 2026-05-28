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
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var isDict: Bool {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncIsDict(self)
            }
            
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var dictCount: Int {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncDictCount(self)
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var dictKeys: [PythonInterpreter.SafePythonObject] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncDictKeys(self)
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var dictValues: [PythonInterpreter.SafePythonObject] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncDictValues(self)
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var dictItems: [(key: PythonInterpreter.SafePythonObject, value: PythonInterpreter.SafePythonObject)] {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncDictItems(self)
            }
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
