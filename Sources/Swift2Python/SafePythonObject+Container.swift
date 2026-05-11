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
    
    
    // MARK: Tuple Support
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var isTuple: Bool {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncIsTuple(self)
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tupleCount: Int {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTupleCount(self)
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tuple2: (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    )? {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTuple2(self)
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tuple3: (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    )? {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTuple3(self)
            }
        }
    }
    
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    public var tuple4: (
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject,
        PythonInterpreter.SafePythonObject
    )? {
        get throws {
            try interpreter.assumeIsolated {
                try $0.syncTuple4(self)
            }
        }
    }
}
