# Attributes

Read, write, check, and delete Python object attributes from Swift.

## Overview

Swift2Python supports Python attribute access for both async ``PythonObject`` values and synchronous ``PythonInterpreter/SafePythonObject`` values. Attribute access is distinct from callable method syntax: use `get(attr:)` and `set(attr:value:)` for non-callable attribute values, and use dynamic-member call syntax for Python methods.

## Async PythonObject Attributes

Use ``PythonObject`` attribute APIs in normal Swift concurrency code. Reads and writes are `async throws` because they cross the Python interpreter boundary and Python can raise exceptions.

```swift
let globals = try await interpreter.getGlobals()
let object = try await globals.getItem(key: "person")

try await object.set(attr: "name", value: "Ada")
let name = try await object.get(attr: "name")
print(try await String(name))
```

Swift cannot express Python-style `try await object.name` property access for attribute values. Use `get(attr:)` for values and dynamic-member call syntax only for method calls:

```swift
let text = try await object.format("value")
let attribute = try await object.get(attr: "format")
```

## Checking And Deleting Attributes

Use Python's builtins for `hasattr` and `delattr`. Swift2Python automatically exposes builtins through the interpreter, so you do not need to import them manually.

```swift
let builtins = try await interpreter.getBuiltins()
let hasName = try await Bool(builtins.hasattr(object, "name"))

if hasName {
    _ = try await builtins.delattr(object, "name")
}
```

The Python builtin names are lowercase: `hasattr` and `delattr`.

## SafePythonObject Attributes

Use ``PythonInterpreter/SafePythonObject`` only inside `withIsolatedContext`. Safe objects provide synchronous attribute access because the interpreter is already isolated.

For recoverable failures, use the explicit throwing APIs:

```swift
try await interpreter.withIsolatedContext { context in
    let object = context.globals["person"]

    try object.set(attr: "name", value: "Ada")
    let name = try object.get(attr: "name")
    print(try String(name))
}
```

Safe objects also support Python-like dynamic-member syntax for convenience:

```swift
try await interpreter.withIsolatedContext { context in
    var object = context.globals["person"]

    object.name = "Ada"
    print(try String(object.name))
}
```

Dynamic-member attribute access is convenience-oriented. It traps if Python raises or conversion fails. Use `get(attr:)` and `set(attr:value:)` when missing attributes, read-only attributes, or conversion failures are expected.

## Safe Attribute Checks And Deletion

Use safe builtins inside the isolated context:

```swift
try await interpreter.withIsolatedContext { context in
    let object = context.globals["person"]
    let hasName = try Bool(context.builtins.hasattr(object, "name"))

    if hasName {
        _ = try context.builtins.delattr(object, "name")
    }
}
```

## Name Collisions

If a Python attribute name collides with a Swift member name, use explicit attribute APIs instead of dynamic-member syntax:

```swift
let countAttribute = try await object.get(attr: "count")

try await interpreter.withIsolatedContext { context in
    let safeObject = context.globals["item"]
    let countAttribute = try safeObject.get(attr: "count")
}
```

## Errors

Async ``PythonObject`` attribute APIs throw `PythonError.pythonException` when Python raises, including missing attributes and read-only assignment failures. Explicit safe attribute APIs throw `PythonError.safePythonException` inside the isolated context for Python exceptions; if that error escapes `withIsolatedContext`, the isolated context rethrows it as an async Python exception.