# Item Access

Read and write Python items from Swift using Python's item protocol.

## Overview

Swift2Python exposes Python `object[key]` and `object[key] = value` through explicit throwing APIs. These APIs work for dictionaries, lists, tuples, custom Python objects that implement `__getitem__` or `__setitem__`, and other Python objects that support the item protocol.

Use ``PythonObject/getItem(key:)`` and ``PythonObject/setItem(key:newValue:)`` in normal async Swift code. Use ``PythonInterpreter/SafePythonObject/getItem(key:)`` and ``PythonInterpreter/SafePythonObject/setItem(key:newValue:)`` inside `withIsolatedContext` when item failures should be recoverable.

## Async PythonObject Items

Swift cannot express `try await object[key]`, so async item access uses named methods:

```swift
let dict = try await interpreter.convertToPython(dictionary: [
    "name": "Ada",
    "count": 3
])

let name = try await dict.getItem(key: "name")
try await dict.setItem(key: "count", newValue: 4)

print(try await String(name))
```

The same APIs work for Python lists and tuples:

```swift
let list = try await interpreter.convertToPython(array: [10, 20, 30])

let first = try await list.getItem(key: 0)
try await list.setItem(key: 1, newValue: 200)
```

List-specific helpers such as ``PythonObject/listItem(at:)`` and ``PythonObject/listSetItem(at:to:)`` are still useful when code is intentionally list-shaped. Use generic item access when the object may be any Python item container or when you want normal Python item protocol behavior.

## Custom Python Item Protocols

Generic item access calls Python's `__getitem__` and `__setitem__` implementations:

```swift
try await interpreter.runSimpleString(pythonCode: """
class Store:
    def __init__(self):
        self.values = {}
    def __getitem__(self, key):
        return self.values[key]
    def __setitem__(self, key, value):
        self.values[key] = value
""")

let globals = try await interpreter.getGlobals()
let storeType = try await globals.getItem(key: "Store")
let store = try await storeType()

try await store.setItem(key: "name", newValue: "Ada")
let name = try await store.getItem(key: "name")
```

If Python raises from `__getitem__` or `__setitem__`, Swift2Python throws ``PythonError/pythonException(_:info:)`` with ``PythonExceptionInfo`` containing the Python traceback.

## Slicing

Swift ranges convert to Python `slice` objects for generic item access:

```swift
let middle = try await list.getItem(key: 1..<4)
let inclusiveMiddle = try await list.getItem(key: 1...3)
let tail = try await list.getItem(key: 2...)
let prefix = try await list.getItem(key: ..<3)

try await list.setItem(key: 1..<3, newValue: replacement)
```

Use ``PythonSlice`` when you need a stepped or reversed slice:

```swift
let reversed = try await list.getItem(key: PythonSlice(nil, nil, step: -1))
let everyOther = try await list.getItem(key: PythonSlice(nil, nil, step: 2))
```

Inside `withIsolatedContext`, safe subscript syntax supports the same slice descriptor:

```swift
try await interpreter.withIsolatedContext { context in
    var list = try context.convertToSafePython(array: [1, 2, 3, 4, 5])

    let middle = list[.slice(1, 4)]
    let reversed = list[.slice(nil, nil, step: -1)]

    list[.slice(1, 3)] = try context.convertToSafePython(array: [20, 30])
}
```

`nil` slice bounds map to Python `None`, so `.slice(nil, nil, step: -1)` is the Swift2Python spelling of Python `[::-1]`. Safe slice subscript syntax cannot throw and traps if Python rejects the slice, such as a zero step or invalid stepped slice assignment. Use explicit ``PythonInterpreter/SafePythonObject/getItem(key:)`` and ``PythonInterpreter/SafePythonObject/setItem(key:newValue:)`` with ``PythonSlice`` when slice errors should be handled.

## Safe Item Access

Inside `withIsolatedContext`, use explicit throwing methods when item failures should be handled:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])

    let name = try dict.getItem(key: "name")
    try dict.setItem(key: "count", newValue: 3)

    print(try String(name))
}
```

Safe objects also support concise subscript syntax:

```swift
try await interpreter.withIsolatedContext { context in
    var dict = try context.convertToSafePython(dictionary: ["name": "Ada"])

    let name = dict["name"]
    dict["count"] = 3

    print(try String(name))
}
```

Safe subscript access and assignment cannot throw. They trap if Python raises or conversion fails. Use ``PythonInterpreter/SafePythonObject/getItem(key:)`` and ``PythonInterpreter/SafePythonObject/setItem(key:newValue:)`` when missing keys, invalid indexes, read-only items, or custom Python exceptions are expected.

## Tuple Keys

Safe subscript syntax accepts more than one key. When multiple keys are supplied, Swift2Python builds a Python tuple and passes that tuple as the single Python key. This matches Python syntax such as `object[x, y]`:

```swift
try await interpreter.withIsolatedContext { context in
    let arrayLike = context.globals["array_like"]
    let value = arrayLike[1, 2]
    print(value)
}
```

Use this for Python objects that expect tuple keys, such as multidimensional indexing APIs. For recoverable errors or dynamically collected keys, create the Python tuple explicitly and call ``PythonInterpreter/SafePythonObject/getItem(key:)``.

## Error Behavior

Async item APIs throw ``PythonError/pythonException(_:info:)`` when Python raises. The exception info preserves the Python type, message, traceback, chained exceptions, and notes.

Safe explicit item APIs throw ``PythonError/safePythonException(_:info:)`` inside the isolated context. If that error escapes `withIsolatedContext`, Swift2Python converts it to ``PythonError/pythonException(_:info:)`` and preserves the same exception info.

Safe subscript syntax traps on failures because Swift subscripts in this design are non-throwing.

## Choosing An API

- Use ``PythonObject/getItem(key:)`` and ``PythonObject/setItem(key:newValue:)`` for async item access.
- Use list-specific helpers when the object is known to be a list and you want list validation.
- Use dictionary-specific helpers such as ``PythonObject/containsKey(_:)`` and ``PythonObject/deleteItem(key:)`` for dictionary membership and deletion.
- Use ``PythonInterpreter/SafePythonObject/getItem(key:)`` and ``PythonInterpreter/SafePythonObject/setItem(key:newValue:)`` for recoverable safe item access.
- Use safe subscript syntax for concise isolated-context code where item failure is a programmer error.
- Use multi-key safe subscript syntax when the Python API expects a tuple key.
- Use ``PythonSlice`` or `.slice(...)` for stepped and reversed slices; use explicit item APIs when slice failures are recoverable.
