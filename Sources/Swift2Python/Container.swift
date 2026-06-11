//
//  Container.swift
//  Swift2Python
//
//  Created by Ben White on 5/3/26.
//

import Foundation

extension Data: PendingPythonConvertible {
    /// Converts this Swift data value to Python `bytes`.
    ///
    /// This conformance lets `Data` be passed directly to async Swift2Python APIs
    /// that accept `PendingPythonConvertible` values. The bytes are copied into an
    /// immutable Python `bytes` object.
    ///
    /// ```swift
    /// let pyBytes = try await data.toPythonObject(interpreter: interpreter)
    /// _ = try await pythonFunction(data)
    /// ```
    ///
    /// - Parameters:
    ///   - interpreter: The interpreter that owns the created Python bytes object.
    /// - Returns: A `PythonObject` representing Python `bytes`.
    /// - Throws: `PythonError` if bytes creation fails.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(bytes: self)
    }
}

extension Data: SafePythonConvertible {
    /// Converts this Swift data value to safe Python `bytes`.
    ///
    /// This conformance lets `Data` be passed directly to safe Swift2Python APIs
    /// inside `withIsolatedContext`. The bytes are copied into an immutable Python
    /// `bytes` object.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let pyBytes = try data.toSafePythonObject(interpreter: context)
    ///     _ = try pythonFunction(data)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - interpreter: The isolated interpreter context that owns the created Python bytes object.
    /// - Returns: A `SafePythonObject` representing Python `bytes`.
    /// - Throws: `PythonError` if bytes creation fails.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(bytes: self)
        }
    }
}

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
            try $0.convertToSafePython(dictionary: self)
        }
    }
}

extension Set: PendingPythonConvertible where Element: PendingPythonConvertible {
    /// Converts this Swift set to a Python set.
    ///
    /// This conformance lets Swift sets be passed directly to async Swift2Python
    /// APIs that accept `PendingPythonConvertible` values. Each element is converted
    /// with its own `PendingPythonConvertible` conformance.
    ///
    /// ```swift
    /// let set = try await Set([1, 2, 3]).toPythonObject(interpreter: interpreter)
    /// _ = try await pythonFunction(Set([1, 2, 3]))
    /// ```
    ///
    /// Swift set membership guarantees Swift hashability. Python may still reject
    /// an element if the converted Python object is not hashable.
    ///
    /// - Parameters:
    ///   - interpreter: The interpreter that owns the created Python set.
    /// - Returns: A `PythonObject` representing a Python set.
    /// - Throws: `PythonError` if set creation, element conversion, or element insertion fails.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await interpreter.convertToPython(set: self)
    }
}

extension Set: SafePythonConvertible where Element: SafePythonConvertible {
    /// Converts this Swift set to a safe Python set.
    ///
    /// This conformance lets Swift sets be passed directly to safe Swift2Python
    /// APIs inside `withIsolatedContext`. Each element is converted with its own
    /// `SafePythonConvertible` conformance.
    ///
    /// ```swift
    /// try await interpreter.withIsolatedContext { context in
    ///     let set = try Set([1, 2, 3]).toSafePythonObject(interpreter: context)
    ///     _ = try pythonFunction(Set([1, 2, 3]))
    /// }
    /// ```
    ///
    /// Swift set membership guarantees Swift hashability. Python may still reject
    /// an element if the converted Python object is not hashable.
    ///
    /// - Parameters:
    ///   - interpreter: The isolated interpreter context that owns the created Python set.
    /// - Returns: A `SafePythonObject` representing a Python set.
    /// - Throws: `PythonError` if set creation, element conversion, or element insertion fails.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated {
            try $0.convertToSafePython(set: self)
        }
    }
}

extension Range : PendingPythonConvertible where Bound == Int {
    /// Converts this Swift range to a Python `slice` object.
    ///
    /// The range's `lowerBound` becomes the slice start, and its exclusive
    /// `upperBound` becomes the slice stop.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await PythonSlice(lowerBound, upperBound).toPythonObject(interpreter: interpreter)
    }
}

extension Range : SafePythonConvertible where Bound == Int {
    /// Converts this Swift range to a safe Python `slice` object.
    ///
    /// This lets ranges be used directly with `SafePythonObject` item access.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try PythonSlice(lowerBound, upperBound).toSafePythonObject(interpreter: interpreter)
    }
}

extension ClosedRange : PendingPythonConvertible where Bound == Int {
    /// Converts this Swift closed range to a Python `slice` object.
    ///
    /// Python slices use an exclusive stop value, so `1...3` becomes
    /// `slice(1, 4)`.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await PythonSlice(lowerBound, exclusiveStop(after: upperBound, sourceType: "ClosedRange<Int>")).toPythonObject(interpreter: interpreter)
    }
}

extension ClosedRange : SafePythonConvertible where Bound == Int {
    /// Converts this Swift closed range to a safe Python `slice` object.
    ///
    /// Python slices use an exclusive stop value, so `1...3` becomes
    /// `slice(1, 4)`.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try PythonSlice(lowerBound, exclusiveStop(after: upperBound, sourceType: "ClosedRange<Int>")).toSafePythonObject(interpreter: interpreter)
    }
}

extension PartialRangeFrom : PendingPythonConvertible where Bound == Int {
    /// Converts this Swift partial range to a Python `slice` object.
    ///
    /// `2...` becomes `slice(2, None)`.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await PythonSlice(lowerBound, nil).toPythonObject(interpreter: interpreter)
    }
}

extension PartialRangeFrom : SafePythonConvertible where Bound == Int {
    /// Converts this Swift partial range to a safe Python `slice` object.
    ///
    /// `2...` becomes `slice(2, None)`.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try PythonSlice(lowerBound, nil).toSafePythonObject(interpreter: interpreter)
    }
}

extension PartialRangeUpTo : PendingPythonConvertible where Bound == Int {
    /// Converts this Swift partial range to a Python `slice` object.
    ///
    /// `..<3` becomes `slice(None, 3)`.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await PythonSlice(nil, upperBound).toPythonObject(interpreter: interpreter)
    }
}

extension PartialRangeUpTo : SafePythonConvertible where Bound == Int {
    /// Converts this Swift partial range to a safe Python `slice` object.
    ///
    /// `..<3` becomes `slice(None, 3)`.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try PythonSlice(nil, upperBound).toSafePythonObject(interpreter: interpreter)
    }
}

extension PartialRangeThrough : PendingPythonConvertible where Bound == Int {
    /// Converts this Swift partial closed range to a Python `slice` object.
    ///
    /// Python slices use an exclusive stop value, so `...2` becomes
    /// `slice(None, 3)`.
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        try await PythonSlice(nil, exclusiveStop(after: upperBound, sourceType: "PartialRangeThrough<Int>")).toPythonObject(interpreter: interpreter)
    }
}

extension PartialRangeThrough : SafePythonConvertible where Bound == Int {
    /// Converts this Swift partial closed range to a safe Python `slice` object.
    ///
    /// Python slices use an exclusive stop value, so `...2` becomes
    /// `slice(None, 3)`.
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try PythonSlice(nil, exclusiveStop(after: upperBound, sourceType: "PartialRangeThrough<Int>")).toSafePythonObject(interpreter: interpreter)
    }
}

private func exclusiveStop(after value: Int, sourceType: String) throws -> Int {
    guard value < Int.max else {
        throw PythonError.conversionOverflow(value: String(value), sourceType: sourceType, targetType: "Python slice stop")
    }
    return value + 1
}
