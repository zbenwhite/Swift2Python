//
//  Container.swift
//  Swift2Python
//
//  Created by Ben White on 5/3/26.
//

import Foundation

extension Array : PendingPythonConvertible where Element : PendingPythonConvertible {
    /// Converts this Swift array to a Python list.
    ///
    /// This conformance lets Swift arrays be passed directly to async Swift2Python
    /// APIs that accept `PendingPythonConvertible` values. Each element is converted
    /// with its own `PendingPythonConvertible` conformance.
    ///
    /// ```swift
    /// let list = try await [1, 2, 3].toPythonObject(interpreter: interpreter)
    /// _ = try await pythonFunction([1, 2, 3])
    /// ```
    ///
    /// - Parameters:
    ///   - interpreter: The interpreter that owns the created Python list.
    /// - Returns: A `PythonObject` representing a Python list.
    /// - Throws: `PythonError` if list creation or element conversion fails.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(array: self)
    }
}

extension Array : SafePythonConvertible where Element : SafePythonConvertible {
    /// Converts this Swift array to a safe Python list.
    ///
    /// This conformance lets Swift arrays be passed directly to safe Swift2Python
    /// APIs inside `withIsolatedContext`. Each element is converted with its own
    /// `SafePythonConvertible` conformance.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let list = try [1, 2, 3].toSafePythonObject(interpreter: context)
    ///     _ = try pythonFunction([1, 2, 3])
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - interpreter: The isolated interpreter context that owns the created Python list.
    /// - Returns: A `SafePythonObject` representing a Python list.
    /// - Throws: `PythonError` if list creation or element conversion fails.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(array: self)
        }
    }
}

extension Dictionary : PendingPythonConvertible where Key : PendingPythonConvertible & Hashable, Value : PendingPythonConvertible {
    /// Converts this Swift dictionary to a Python dictionary.
    ///
    /// This conformance lets Swift dictionaries be passed directly to async
    /// Swift2Python APIs that accept `PendingPythonConvertible` values. Each key and
    /// value is converted with its own `PendingPythonConvertible` conformance.
    ///
    /// ```swift
    /// let dict = try await ["name": "Ada", "count": 3].toPythonObject(interpreter: interpreter)
    /// _ = try await pythonFunction(["name": "Ada", "count": 3])
    /// ```
    ///
    /// - Parameters:
    ///   - interpreter: The interpreter that owns the created Python dictionary.
    /// - Returns: A `PythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(dictionary: self)
    }
}

extension Dictionary : SafePythonConvertible where Key : SafePythonConvertible & Hashable, Value : SafePythonConvertible {
    /// Converts this Swift dictionary to a safe Python dictionary.
    ///
    /// This conformance lets Swift dictionaries be passed directly to safe
    /// Swift2Python APIs inside `withIsolatedContext`. Each key and value is
    /// converted with its own `SafePythonConvertible` conformance.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let dict = try ["name": "Ada", "count": 3].toSafePythonObject(interpreter: context)
    ///     _ = try pythonFunction(["name": "Ada", "count": 3])
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - interpreter: The isolated interpreter context that owns the created Python dictionary.
    /// - Returns: A `SafePythonObject` representing a Python dictionary.
    /// - Throws: `PythonError` if dictionary creation, key conversion, value conversion, or item insertion fails.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(dictionary:self)
        }
    }
}

extension Range : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("placeholder")
        //try await interpreter.convertRangeToPython(self)
    }
}

extension PartialRangeFrom : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("placeholder")
        //try await interpreter.convertPartialRangeToPython(self)
    }
}

extension PartialRangeUpTo : PendingPythonConvertible where Bound : PendingPythonConvertible {
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        // TODO: NOT WRITTEN
        fatalError("placeholder")
        //try await interpreter.convertPartialRangeToPython(self)
    }
}
