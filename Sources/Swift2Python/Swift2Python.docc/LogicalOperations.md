# Logical Operations

Use logical operations when you need Python truthiness, logical NOT, or Python-style `and` / `or` behavior.

## Overview

Python truthiness is broader than Swift `Bool`. `None`, `False`, numeric zero, empty strings, and empty containers are falsey. Most other values are truthy. Custom Python objects can define truthiness with `__bool__` or `__len__`.

Swift2Python exposes Python truthiness with `isTrue()` and `isNotTrue()`:

```swift
let value = try await interpreter.convertToPython("hello")

if try await value.isTrue() {
    print("Python considers this object truthy")
}
```

Inside `withIsolatedContext`, use the synchronous `SafePythonObject` methods:

```swift
try await interpreter.withIsolatedContext { context in
    let value: PythonInterpreter.SafePythonObject = "hello"

    if try value.isTrue() {
        print("Python considers this object truthy")
    }
}
```

## Truthiness

`isTrue()` returns Swift `Bool` using Python truthiness rules.

`isNotTrue()` returns Swift `Bool` using Python logical NOT rules. It is equivalent to Python `not value`, but it returns a Swift `Bool` rather than a Python `bool` object.

For `PythonObject`, these methods delegate to CPython's `PyObject_IsTrue` and `PyObject_Not`, so Python controls built-in truthiness and custom `__bool__` or `__len__` behavior.

For `SafePythonObject`, bound Python objects also delegate to CPython. Deferred Swift literals use Python-compatible local rules before they are materialized:

- `Bool`: uses the bool value.
- `Int`: `0` is falsey; nonzero values are truthy.
- `Double`: `0.0` is falsey; nonzero values are truthy.
- `String`: `""` is falsey; nonempty strings are truthy.

Async truthiness:

```swift
let object = try await interpreter.convertToPython([1, 2, 3])
let truthy = try await object.isTrue()
let falsey = try await object.isNotTrue()
```

Safe truthiness:

```swift
try await interpreter.withIsolatedContext { context in
    let object: PythonInterpreter.SafePythonObject = 0
    let truthy = try object.isTrue()
    let falsey = try object.isNotTrue()
}
```

## Python `and` And `or`

Python `and` and `or` return one of their operands. They do not return `Bool` unless one of the operands is already a Python bool.

Python `and` behaves like this:

```python
lhs and rhs
```

- If `lhs` is falsey, the result is `lhs`.
- If `lhs` is truthy, the result is `rhs`.

Python `or` behaves like this:

```python
lhs or rhs
```

- If `lhs` is truthy, the result is `lhs`.
- If `lhs` is falsey, the result is `rhs`.

Swift2Python provides explicit `logicalAnd` and `logicalOr` methods instead of overloading Swift `&&` and `||`, because Swift developers expect those operators to return `Bool`.

## Eager Logical Methods

Use the eager overloads when both operands already exist:

```swift
let lhs = try await interpreter.convertToPython("")
let rhs = try await interpreter.convertToPython("fallback")

let andResult = try await lhs.logicalAnd(rhs) // returns lhs, because lhs is falsey
let orResult = try await lhs.logicalOr(rhs)   // returns rhs, because lhs is falsey
```

Safe eager methods work the same way inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let lhs: PythonInterpreter.SafePythonObject = ""
    let rhs: PythonInterpreter.SafePythonObject = "fallback"

    let andResult = try lhs.logicalAnd(rhs)
    let orResult = try lhs.logicalOr(rhs)

    print(try String(andResult), try String(orResult))
}
```

## Short-Circuit Logical Methods

Use the closure overloads when the right operand should only be created if Python would evaluate it.

For Python `and`, the closure runs only when the left operand is truthy:

```swift
let result = try await lhs.logicalAnd {
    try await expensivePythonCall()
}
```

For Python `or`, the closure runs only when the left operand is falsey:

```swift
let result = try await lhs.logicalOr {
    try await fallbackPythonValue()
}
```

Safe short-circuit methods are synchronous and throwing:

```swift
try await interpreter.withIsolatedContext { context in
    let lhs: PythonInterpreter.SafePythonObject = ""

    let result = try lhs.logicalOr {
        try context.convertToSafePython("fallback")
    }

    print(try String(result))
}
```

## Choosing The Right Method

Use `isTrue()` when you need a Swift `Bool` condition:

```swift
if try await value.isTrue() {
    print("truthy")
}
```

Use `isNotTrue()` when you need Python logical NOT as a Swift `Bool`:

```swift
if try await value.isNotTrue() {
    print("falsey")
}
```

Use `logicalAnd` and `logicalOr` when you need Python's operand-returning semantics:

```swift
let selected = try await preferred.logicalOr(fallback)
```

Use the closure overloads when preserving Python short-circuiting matters:

```swift
let selected = try await preferred.logicalOr {
    try await computeFallback()
}
```

## Error Behavior

`PythonObject` logical methods throw `PythonError.pythonException` if Python raises while evaluating truthiness. The closure overloads can also throw errors from the right-hand closure.

`SafePythonObject` logical methods throw `PythonError.safePythonException` if a bound Python object raises while evaluating truthiness. Deferred literals are evaluated locally and do not raise. The closure overloads can also throw errors from the right-hand closure.
