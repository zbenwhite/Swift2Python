//
//  PythonInterpreter+Slice.swift
//  Swift2Python
//
//  Created by Ben White on 6/7/26.
//

import Foundation

/// A Swift representation of a Python `slice` object.
///
/// Use this with `SafePythonObject` subscript syntax when working inside
/// `withIsolatedContext`.
///
/// ```swift
/// let values = try interpreter.withIsolatedContext { interpreter in
///     let list = try interpreter.convertToSafePython(array: [1, 2, 3, 4])
///     return list[.slice(1, 3)]
/// }
/// ```
public struct PythonSlice: Sendable {
    public let start: Int?
    public let stop: Int?
    public let step: Int?

    /// Creates a Python slice descriptor.
    ///
    /// `nil` represents Python's omitted slice bound, equivalent to `None` in
    /// `slice(start, stop, step)`.
    ///
    /// ```swift
    /// let middle = PythonSlice(1, 3)
    /// let everyOther = PythonSlice(nil, nil, step: 2)
    /// ```
    ///
    /// - Parameters:
    ///   - start: The optional start index.
    ///   - stop: The optional stop index.
    ///   - step: The optional step value.
    public init(_ start: Int? = nil, _ stop: Int? = nil, step: Int? = nil) {
        self.start = start
        self.stop = stop
        self.step = step
    }

    /// Creates a Python slice descriptor for use with `SafePythonObject` subscript syntax.
    ///
    /// ```swift
    /// let middle = list[.slice(1, 3)]
    /// list[.slice(1, 3)] = replacement
    /// ```
    ///
    /// - Parameters:
    ///   - start: The optional start index.
    ///   - stop: The optional stop index.
    ///   - step: The optional step value.
    /// - Returns: A `PythonSlice` value.
    public static func slice(_ start: Int? = nil, _ stop: Int? = nil, step: Int? = nil) -> PythonSlice {
        PythonSlice(start, stop, step: step)
    }
}

extension PythonSlice: SafePythonConvertible {
    public func toSafePythonObject(interpreter: PythonInterpreter) throws -> PythonInterpreter.SafePythonObject {
        try interpreter.assumeIsolated { context in
            try context.convertToSafePython(slice: self)
        }
    }
}

extension PythonInterpreter {
    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    internal func convertToSafePython(slice: PythonSlice) throws -> SafePythonObject {
        let start = try safePythonObjectOrNone(slice.start)
        let stop = try safePythonObjectOrNone(slice.stop)
        let step = try safePythonObjectOrNone(slice.step)
        return try syncCall(callable: builtins.slice, args: [start, stop, step])
    }

    @available(*, noasync, message: "Only safe inside withIsolatedContext()")
    private func safePythonObjectOrNone(_ value: Int?) throws -> SafePythonObject {
        if let value {
            return try convertToSafePython(int: Int64(value))
        }

        guard let nonePtr = api._Py_NoneStruct else {
            throw PythonError.nullPointer("Could not resolve Py_None")
        }
        return borrowedSafePythonObject(fromReturnedPointer: nonePtr)
    }
}
