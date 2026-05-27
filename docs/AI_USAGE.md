# Swift2Python AI Usage Guide

This file is written for coding agents and AI assistants that generate Swift2Python code. Prefer this guide when choosing API patterns, naming, and error handling. The DocC documentation is the human-facing reference; this file is a compact operational guide.

## General Rules

- Prefer public Swift2Python APIs over calling low-level CPython wrappers.
- Use async ``PythonObject`` APIs in normal Swift concurrency code.
- Use ``PythonInterpreter.SafePythonObject`` only inside `withIsolatedContext`.
- Prefer Swift conversion initializers such as `Int(pyObject)`, `String(pyObject)`, and `Double(pyObject)` over direct `convertTo...` calls in examples and user-facing code.
- Do not import `builtins` manually for common builtins access. Use `interpreter.builtins`.

## Tuples

Tuple support is release-ready and should be treated as complete. Do not invent new tuple helpers unless the user explicitly asks for a new API.

### What Tuple APIs Exist

Async ``PythonObject`` tuple APIs:

```swift
try await object.isTuple()
try await tuple.tupleCount()
try await tuple.tupleItem(at: 0)
try await tuple.asTupleArray()
try await tuple.asTuple2()
try await tuple.asTuple3()
try await tuple.asTuple4()
```

Tuple creation from Swift values:

```swift
let tuple = try await interpreter.convertToPython(tupleOf: 1, "two", 3.0)
let tupleFromSequence = try await interpreter.convertToPython(tupleContentsOf: [1, 2, 3])
```

Safe tuple APIs inside `withIsolatedContext`:

```swift
try tuple.isTuple
try tuple.tupleCount
try tuple.tupleItem(at: 0)
try tuple.tupleArray
try tuple.tuple2
try tuple.tuple3
try tuple.tuple4
```

Safe tuple creation:

```swift
try interpreter.withIsolatedContext { context in
    let tuple = try context.convertToSafePython(tupleOf: 1, "two", 3.0)
    let tupleFromSequence = try context.convertToSafePython(tupleContentsOf: [1, 2, 3])
}
```

### Preferred Async Patterns

Create a heterogeneous tuple with `tupleOf`:

```swift
let tuple = try await interpreter.convertToPython(tupleOf: 42, "answer", true)
```

Create a homogeneous tuple from a Swift sequence with `tupleContentsOf`:

```swift
let values = [1, 2, 3, 4]
let tuple = try await interpreter.convertToPython(tupleContentsOf: values)
```

Read one item by zero-based index:

```swift
let first = try await tuple.tupleItem(at: 0)
let value = try await Int(first)
```

Convert a dynamic-length Python tuple to an array:

```swift
let elements = try await tuple.asTupleArray()
for element in elements {
    print(try await String(element))
}
```

Unpack fixed-size tuples when arity is part of the contract:

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

### Preferred Safe Patterns

Use safe tuple APIs only inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let tuple = try context.convertToSafePython(tupleOf: 1, "two", 3.0)

    let values = try tuple.tuple3
    let first = try Int(values.0)
    let second = try String(values.1)
    let third = try Double(values.2)

    print(first, second, third)
}
```

Use `tupleArray` for dynamic length:

```swift
try await interpreter.withIsolatedContext { context in
    let tuple = try context.convertToSafePython(tupleContentsOf: [1, 2, 3])
    let elements = try tuple.tupleArray
    print(elements.count)
}
```

### Error Behavior

Async tuple helpers throw:

- `PythonError.tupleConversionFailed(expected:actual:)` when the object is not a tuple.
- `PythonError.tupleArityMismatch(expected:actual:)` when `asTuple2`, `asTuple3`, or `asTuple4` receives the wrong tuple length.
- `PythonError.pythonException` when Python raises while reading tuple data, including out-of-bounds `tupleItem(at:)`.

Safe tuple helpers throw:

- `PythonError.tupleConversionFailed(expected:actual:)` when the object is not a tuple.
- `PythonError.tupleArityMismatch(expected:actual:)` when `tuple2`, `tuple3`, or `tuple4` receives the wrong tuple length.
- `PythonError.safePythonException` when Python raises while reading tuple data, including out-of-bounds `tupleItem(at:)`.

Do not write safe tuple code as if tuple helpers return optionals. They throw and return non-optional values:

```swift
let values = try tuple.tuple3
```

Do not write:

```swift
if let values = try tuple.tuple3 { }
```

### Python Iterable to Tuple

Do not add or use a `listAsTuple()` helper. To convert a Python iterable to a tuple, call Python's own `tuple` constructor through preloaded builtins:

```swift
let tuple = try await interpreter.builtins.tuple(listObject)
```

This preserves Python semantics and works for any iterable, not just lists.

### Tuple Indexing Guidance

Swift2Python tuple helpers use zero-based indexes:

```swift
let first = try await tuple.tupleItem(at: 0)
```

Do not assume negative indexes are part of the tuple helper contract. If Python-style negative indexing is required, call Python directly using the generic item access APIs or Python code.

### What Not To Add For Tuples

Do not add these unless the user explicitly requests them:

- Fixed tuple helpers beyond 4 elements.
- Tuple mutation APIs. Python tuples are immutable.
- `listAsTuple()` or `tupleFromList()` wrappers.
- namedtuple-specific APIs. Attribute access and tuple indexing cover normal namedtuple use.
- Duplicate optional safe tuple helpers. The main safe tuple API throws.

### Release Completeness

Tuple support should be considered complete for a 1.0 release. It has async APIs, safe APIs, tuple creation, tuple inspection, fixed-size unpacking, dynamic array conversion, tuple-specific errors, unit tests, and DocC documentation.
