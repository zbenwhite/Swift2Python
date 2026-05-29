# Dictionaries

Create Python dictionaries from Swift dictionaries, inspect dictionary objects, read dictionary views, and mutate Python dictionaries from Swift.

## Overview

Python dictionaries are mutable mappings from hashable keys to values. Swift2Python exposes dictionary support in two styles:

- Use ``PythonObject`` methods from async Swift code.
- Use ``PythonInterpreter/SafePythonObject`` properties and methods inside `withIsolatedContext` when you need synchronous access.

Dictionary-specific helpers validate that the Python object is a dictionary before reading or mutating it. Async and safe helpers throw ``PythonError/dictionaryConversionFailed(expected:actual:)`` when the object is not a dictionary.

## Creating a Python Dictionary

Use ``PythonInterpreter/convertToPython(dictionary:)`` to create a Python dictionary from a Swift dictionary:

```swift
let dict = try await interpreter.convertToPython(dictionary: [
    "name": "Ada",
    "count": 3
])
```

Swift dictionaries also conform to ``PendingPythonConvertible`` when their keys and values are convertible:

```swift
let dict = try await ["name": "Ada", "count": 3]
    .toPythonObject(interpreter: interpreter)
```

For heterogeneous string-keyed dictionaries, use an existential value type:

```swift
let values: [String: any PendingPythonConvertible] = [
    "name": "Ada",
    "count": 3,
    "active": true
]
let dict = try await interpreter.convertToPython(dictionary: values)
```

## Checking and Counting

Use ``PythonObject/isDict()`` to test whether an object is a Python dictionary:

```swift
if try await object.isDict() {
    let count = try await object.dictCount()
    print("Dictionary has \(count) entries")
}
```

Use ``PythonObject/dictCount()`` when you expect a dictionary and want an error if the object is not one:

```swift
let count = try await dict.dictCount()
```

## Reading Keys, Values, and Items

Use ``PythonObject/dictKeys()``, ``PythonObject/dictValues()``, and ``PythonObject/dictItems()`` when you want Swift arrays:

```swift
let keys = try await dict.dictKeys()
for key in keys {
    print(try await String(key))
}
```

```swift
let items = try await dict.dictItems()
for item in items {
    let key = try await String(item.key)
    let value = try await Int(item.value)
    print(key, value)
}
```

The returned arrays contain ``PythonObject`` values. Convert each key or value to a Swift type when you need Swift values.

## Getting, Setting, and Deleting Items

Use the generic item APIs for normal dictionary lookup and assignment:

```swift
let name = try await dict.getItem(key: "name")
try await dict.setItem(key: "count", newValue: 4)
```

Use ``PythonObject/containsKey(_:)`` to test key membership:

```swift
if try await dict.containsKey("name") {
    print("name is present")
}
```

Use ``PythonObject/deleteItem(key:)`` to delete a key:

```swift
try await dict.deleteItem(key: "name")
```

Deleting a missing key follows Python semantics and throws a Python exception.

## Calling Python Dictionary Methods

Dictionary-specific helpers cover common stable-ABI operations. You can also call normal Python dictionary methods directly:

```swift
let keysView = try await dict.keys()
let valuesView = try await dict.values()
let itemsView = try await dict.items()
```

Python's `keys()`, `values()`, and `items()` return Python view objects. Convert them with Python's `list` constructor when you want a list:

```swift
let keysList = try await interpreter.builtins.list(keysView)
let keys = try await keysList.asArray()
```

Call methods such as `get`, `pop`, and `update` through dynamic member syntax:

```swift
let fallback = try await dict[dynamicMember: "get"]("missing", "fallback")
let popped = try await dict.pop("name")
_ = try await dict.update(["city": "London"])
```

Use explicit `dynamicMember` syntax when a Python method name conflicts with a Swift helper or overload.

## Safe Dictionary Access

Inside `withIsolatedContext`, use ``PythonInterpreter/SafePythonObject`` for synchronous dictionary access:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: [
        "name": "Ada",
        "count": 3
    ])

    if try dict.isDict {
        let count = try dict.dictCount
        print(count)
    }

    let name = dict["name"]
    let swiftName = try String(name)
    print(swiftName)
}
```

Use safe key, value, and item helpers when you want Swift arrays inside the isolated context:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: ["one": 1, "two": 2])

    let keys = try dict.dictKeys
    let values = try dict.dictValues
    let items = try dict.dictItems

    print(keys.count, values.count, items.count)
}
```

Safe helpers throw instead of returning optionals. For example, ``PythonInterpreter/SafePythonObject/dictItems`` throws ``PythonError/dictionaryConversionFailed(expected:actual:)`` when the object is not a dictionary.

Use safe mutation helpers for membership and deletion:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])

    if try dict.containsKey("name") {
        try dict.deleteItem(key: "name")
    }
}
```

You can also call Python dictionary methods in the safe context:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])

    let keysView = try dict.keys()
    let keysList = try context.builtins.list(keysView)

    let fallback = try dict[dynamicMember: "get"]("missing", "fallback")
    print(try String(fallback), keysList)
}
```

## Choosing an API

- Use ``PythonInterpreter/convertToPython(dictionary:)`` to create Python dictionaries from Swift dictionaries.
- Use ``PythonObject/dictKeys()``, ``PythonObject/dictValues()``, and ``PythonObject/dictItems()`` when you want Swift arrays.
- Use Python's `keys()`, `values()`, and `items()` when you want Python view objects.
- Use ``PythonObject/getItem(key:)`` and ``PythonObject/setItem(key:newValue:)`` for generic mapping access.
- Use ``PythonObject/containsKey(_:)`` and ``PythonObject/deleteItem(key:)`` for dictionary-specific membership and deletion.
- Use safe dictionary properties and methods only inside `withIsolatedContext`.
