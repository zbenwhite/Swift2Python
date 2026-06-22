# Callables

Call Python functions, classes, methods, and callable objects from Swift.

## Overview

Swift2Python supports Python's call protocol for both async ``PythonObject`` values and synchronous ``PythonInterpreter/SafePythonObject`` values. Use normal Swift call syntax for most calls, and use explicit `call(...)` methods when arguments are already stored in Swift collections.

## Async PythonObject Calls

Use ``PythonObject`` in normal Swift concurrency code. Calls are `async throws` because argument conversion, Python execution, and exception handling cross the Python interpreter boundary.

```swift
let globals = try await interpreter.getGlobals()
let function = try await globals.getItem(key: "make_message")

let message = try await function("Ada", punctuation: "!", repeat: 2)
print(try await String(message))
```

The same syntax works for Python classes, callable instances, bound methods, and any object that implements Python's call protocol:

```swift
let instance = try await pythonClass("name")
let value = try await callableObject(1, 2, scale: 4)
let result = try await instance.method("left", "right", sep: ":")
```

## Explicit Calls

Use `call(...)` when you want the call to be explicit or when arguments are already collected in Swift values.

```swift
let result = try await function.call(1, 2)
```

Use dictionary keyword arguments when the keywords are already in a Swift dictionary:

```swift
let result = try await function.call(
    "Ada",
    kwargs: [
        "punctuation": "!",
        "repeat": 2
    ]
)
```

Use `KeyValuePairs` when keyword order matters or when you want Swift2Python to reject duplicate keyword names before Python receives the call:

```swift
let kwargs: KeyValuePairs<String, any PendingPythonConvertible> = [
    "punctuation": "?",
    "repeat": 3
]

let result = try await function.call("Ada", kwargs: kwargs)
```

## Dynamic Member Methods

Python method calls work through dynamic member lookup plus dynamic callable support:

```swift
let text = try await object.format("value", width: 12)
```

When the method name is not known until runtime, use `callPythonMethod` or `get(attr:)` plus `call(...)`:

```swift
let value = try await interpreter.callPythonMethod(
    object: object,
    methodName: methodName,
    collectedArgs: [argument]
)
```

Prefer dynamic-member syntax when the method name is static. Prefer `callPythonMethod` only when the method name is data.

## SafePythonObject Calls

Use ``PythonInterpreter/SafePythonObject`` calls only inside `withIsolatedContext`. The calls are synchronous because the interpreter is already isolated and holding the correct Python execution context.

```swift
try await interpreter.withIsolatedContext { context in
    let globals = context.globals
    let function = globals["make_message"]

    let message = try function("Ada", punctuation: "!", repeat: 2)
    print(try String(message))
}
```

The explicit `call(...)` APIs are also available for safe objects:

```swift
try await interpreter.withIsolatedContext { context in
    let function = context.globals["make_message"]

    let message = try function.call(
        "Ada",
        kwargs: [
            "punctuation": "!",
            "repeat": 2
        ]
    )

    print(try String(message))
}
```

## Errors And Keyword Validation

Callable APIs throw `PythonError` when conversion fails, an object is not callable, attribute lookup fails, or Python raises an exception. Async `PythonObject` calls report Python exceptions as `PythonError.pythonException`. Synchronous safe calls report Python exceptions as `PythonError.safePythonException`.

Swift2Python validates dynamic keyword calls before invoking Python:

- duplicate keyword labels throw `PythonError.valueError`
- positional arguments after keyword arguments throw `PythonError.valueError`

Dictionary kwargs cannot contain duplicate keys because Swift dictionaries cannot represent them. Use `KeyValuePairs` when duplicate detection matters.

## Choosing A Callable API

Use direct call syntax for normal calls:

```swift
try await function(1, 2, name: "Ada")
try function(1, 2, name: "Ada")
```

Use `call(...)` for explicit or collected arguments:

```swift
try await function.call(1, 2, kwargs: keywordDictionary)
try function.call(1, 2, kwargs: keywordDictionary)
```

Do not call `dynamicallyCall(...)` directly in normal user code. It is the Swift compiler hook that powers `@dynamicCallable` syntax.
