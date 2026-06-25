# Conversions

Convert Swift values to Python objects, and convert Python objects back to Swift scalar values.

## Overview

Swift2Python uses two conversion styles:

- Use ``PendingPythonConvertible`` and ``PythonObject`` from normal async Swift code.
- Use ``SafePythonConvertible`` and ``PythonInterpreter/SafePythonObject`` inside `withIsolatedContext`.

Most code should use the async API first. The safe API is for synchronous work inside an isolated interpreter context.

## Convert Swift Values To Python

Swift scalar values such as `Bool`, `Int`, `Double`, and `String` conform to ``PendingPythonConvertible``. Convert them explicitly with `toPythonObject(interpreter:)`:

```swift
let count = try await 3.toPythonObject(interpreter: interpreter)
let name = try await "Ada".toPythonObject(interpreter: interpreter)
```

Most Swift2Python APIs also accept convertible Swift values directly:

```swift
let math = try await interpreter.import("math")
let result = try await math.pow(2, 8)
```

Container types such as arrays, dictionaries, sets, `KeyValuePairs`, and `Data` also conform when their elements are convertible. See <doc:Lists>, <doc:Dictionaries>, <doc:Sets>, and <doc:Bytes> for container-specific details.

## Convert Python Values To Swift

Use Swift initializers to convert a ``PythonObject`` back to a Swift scalar:

```swift
let value = try await Int(result)
let text = try await String(name)
let enabled = try await Bool(flag)
```

If conversion fails because the Python value has the wrong type, Swift2Python throws ``PythonError/conversionType(value:sourceType:targetType:underlying:)``. If a Python integer does not fit in the requested Swift integer type, Swift2Python throws ``PythonError/conversionOverflow(value:sourceType:targetType:)``.

`String(pyObject)` follows Python's `str(obj)` behavior. For example, converting Python `None` to `String` produces `"None"`; it does not fail as a non-string value.

## Optional Values

Swift optionals convert naturally to Python:

- `nil` becomes Python `None`.
- `.some(value)` converts the wrapped value.

```swift
let missing: Int? = nil
let present: Int? = 42

let pyMissing = try await missing.toPythonObject(interpreter: interpreter)
let pyPresent = try await present.toPythonObject(interpreter: interpreter)
```

This is useful when passing optional arguments to Python functions or building heterogeneous dictionaries:

```swift
let values: [String: any PendingPythonConvertible] = [
    "name": "Ada",
    "nickname": Optional<String>.none,
    "count": 3
]

let dict = try await values.toPythonObject(interpreter: interpreter)
```

Swift2Python does not automatically convert Python `None` back to `nil` for arbitrary optional target types. Read the Python object and decide the intended Swift type in your own code.

## Safe Conversions

Inside `withIsolatedContext`, use ``SafePythonConvertible`` and safe initializers:

```swift
try await interpreter.withIsolatedContext { context in
    let pyValue = try 42.toSafePythonObject(interpreter: context)
    let swiftValue = try Int(pyValue)
    print(swiftValue)
}
```

Safe conversion APIs are synchronous because the isolated context already owns the interpreter access needed to work with ``PythonInterpreter/SafePythonObject``. Do not store safe objects for use after the isolated closure returns.

## Choosing An API

Use this pattern for normal async code:

```swift
let pyValue = try await swiftValue.toPythonObject(interpreter: interpreter)
let swiftValue = try await Int(pyValue)
```

Use this pattern inside an isolated context:

```swift
try await interpreter.withIsolatedContext { context in
    let pyValue = try swiftValue.toSafePythonObject(interpreter: context)
    let swiftValue = try Int(pyValue)
}
```

Prefer the Swift initializer spelling for Python-to-Swift conversion.
