# Tuples

Create Python tuples from Swift values, inspect Python tuple objects, and unpack fixed-size tuples into Swift values.

## Overview

Python tuples are immutable, ordered containers. Swift2Python exposes tuple support in two styles:

- Use ``PythonObject`` methods from async Swift code.
- Use ``PythonInterpreter/SafePythonObject`` properties inside `withIsolatedContext` when you need synchronous access.

Tuple APIs validate that the Python object is a tuple before reading from it. Async APIs throw ``PythonError/tupleConversionFailed(expected:actual:)`` when the object is not a tuple. Fixed-size unpacking throws ``PythonError/tupleArityMismatch(expected:actual:)`` when the tuple has the wrong number of elements.

## Creating a Python Tuple

Use ``PythonInterpreter/convertToPython(tupleOf:)`` when you have a small number of values:

```swift
let tuple = try await interpreter.convertToPython(tupleOf: 42, "hello", true)
```

Use ``PythonInterpreter/convertToPython(tupleContentsOf:)`` when you already have a Swift sequence:

```swift
let values = [1, 2, 3, 4]
let tuple = try await interpreter.convertToPython(tupleContentsOf: values)
```

The sequence elements must conform to ``PendingPythonConvertible``. Common Swift values such as integers, floating-point values, strings, booleans, arrays, dictionaries, and existing ``PythonObject`` values are intended to flow through the conversion APIs.

## Checking and Counting

Use ``PythonObject/isTuple()`` to test whether an object is a Python tuple:

```swift
if try await object.isTuple() {
    let count = try await object.tupleCount()
    print("Tuple has \(count) elements")
}
```

Use ``PythonObject/tupleCount()`` when you expect a tuple and want an error if the object is not one:

```swift
let count = try await tuple.tupleCount()
```

## Reading Items

Use ``PythonObject/tupleItem(at:)`` to read one element:

```swift
let first = try await tuple.tupleItem(at: 0)
let second = try await tuple.tupleItem(at: 1)
let last = try await tuple.tupleItem(at: -1)
```

Tuple indexing uses zero-based Python indexes and supports Python-style negative indexes. Use `-1` for the last element, `-2` for the next-to-last element, and so on. Out-of-range positive or negative indexes throw the Python indexing error.

## Converting to a Swift Array

Use ``PythonObject/asTupleArray()`` when the tuple length is dynamic:

```swift
let elements = try await tuple.asTupleArray()
for element in elements {
    print(try await String(element))
}
```

The returned array contains ``PythonObject`` references to the tuple elements. Convert each element to a Swift type when you need Swift values.

## Unpacking Fixed-Size Tuples

Use ``PythonObject/asTuple2()``, ``PythonObject/asTuple3()``, or ``PythonObject/asTuple4()`` when the arity is part of the contract:

```swift
let pair = try await tuple.asTuple2()
let key = try await String(pair.0)
let value = try await Int(pair.1)
```

```swift
let point = try await tuple.asTuple3()
let x = try await Double(point.0)
let y = try await Double(point.1)
let z = try await Double(point.2)
```

Fixed-size tuple helpers check the exact tuple length. If a tuple has the wrong number of elements, Swift2Python throws ``PythonError/tupleArityMismatch(expected:actual:)``.

## Safe Tuple Access

Inside `withIsolatedContext`, use ``PythonInterpreter/SafePythonObject`` for synchronous tuple access:

```swift
try interpreter.withIsolatedContext { context in
    let tuple = try context.convertToSafePython(tupleOf: 1, "two", 3.0)

    if try tuple.isTuple {
        let count = try tuple.tupleCount
        print(count)
    }

    let values = try tuple.tuple3
    let first = try Int(values.0)
    let second = try String(values.1)
    let third = try Double(values.2)
    let last = try tuple.tupleItem(at: -1)
    print(first, second, third, try Double(last))
}
```

Safe tuple helpers throw for tuple-shaped conversions. For example, ``PythonInterpreter/SafePythonObject/tuple3`` throws ``PythonError/tupleConversionFailed(expected:actual:)`` when the object is not a tuple and ``PythonError/tupleArityMismatch(expected:actual:)`` when the tuple does not have exactly three elements.

Use ``PythonInterpreter/SafePythonObject/tupleArray`` when the tuple length is dynamic:

```swift
try interpreter.withIsolatedContext { context in
    let tuple = try context.convertToSafePython(tupleContentsOf: [1, 2, 3])
    let elements = try tuple.tupleArray
    print(elements.count)
}
```

## Calling Python's `tuple()`

Swift2Python's tuple creation APIs create tuples from Swift values. To convert an arbitrary Python iterable to a tuple, call Python's own `tuple` constructor:

```swift
let tuple = try await interpreter.builtins.tuple(listObject)
```

This is the preferred approach for Python-native conversions such as list-to-tuple because it preserves Python semantics for any iterable.

## Choosing an API

- Use ``PythonInterpreter/convertToPython(tupleOf:)`` for small, heterogeneous tuples.
- Use ``PythonInterpreter/convertToPython(tupleContentsOf:)`` for Swift sequences.
- Use ``PythonObject/asTupleArray()`` for dynamic-length Python tuples.
- Use ``PythonObject/asTuple2()``, ``PythonObject/asTuple3()``, or ``PythonObject/asTuple4()`` when arity is fixed.
- Use Python's `tuple()` constructor for converting existing Python iterables.
