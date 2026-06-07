# Lists

Create, inspect, mutate, slice, and convert Python lists from Swift.

## Overview

Python lists are mutable ordered sequences. Swift2Python supports lists through async ``PythonObject`` APIs and synchronous ``PythonInterpreter/SafePythonObject`` APIs inside ``PythonInterpreter/withIsolatedContext(_:)``.

Use the list-specific helpers when you want list creation, list validation, length, element access, or element mutation. Use normal Python method calls when you want Python's native list behavior, such as `pop()`, `reverse()`, `sort()`, or `copy()`.

## Creating Lists

Create a Python list from a Swift array with ``PythonInterpreter/convertToPython(array:)``:

```swift
let list = try await interpreter.convertToPython(array: [1, 2, 3])
```

For heterogeneous values, store the array elements as `any PendingPythonConvertible`:

```swift
let values: [any PendingPythonConvertible] = ["name", 3, true]
let list = try await interpreter.convertToPython(array: values)
```

Inside an isolated context, create a safe Python list with ``PythonInterpreter/convertToSafePython(array:)``:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [1, 2, 3])
    print(try list.listCount)
}
```

## Checking And Counting

Use ``PythonObject/isList()`` to check whether a Python object is a list, and ``PythonObject/listCount()`` to read its length:

```swift
if try await object.isList() {
    let count = try await object.listCount()
    print(count)
}
```

Use the safe equivalents inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [1, 2, 3])
    if try list.isList {
        print(try list.listCount)
    }
}
```

## Reading Lists As Swift Arrays

Use ``PythonObject/asArray()`` when you want an eager Swift array of ``PythonObject`` values:

```swift
let elements = try await list.asArray()
for element in elements {
    print(try await Int(element))
}
```

Use ``PythonInterpreter/SafePythonObject/listArray`` inside an isolated context:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [1, 2, 3])
    let elements = try list.listArray
    print(elements.count)
}
```

## Accessing And Mutating Items

Use zero-based indexes with ``PythonObject/listItem(at:)`` and ``PythonObject/listSetItem(at:to:)``. Negative indexes follow Python list semantics, so `-1` means the last element.

```swift
let first = try await list.listItem(at: 0)
let last = try await list.listItem(at: -1)

try await list.listSetItem(at: -1, to: "replacement")
```

Append, insert, and delete values with the list mutation helpers:

```swift
try await list.listAppendItem("tail")
try await list.listInsertItem("middle", at: 1)
try await list.listDeleteItem(at: -1)
```

The same helpers are available on `SafePythonObject` inside an isolated context:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [1, 2, 3])

    let last = try list.listItem(at: -1)
    try list.listSetItem(at: 0, to: 10)
    try list.listAppendItem(4)
    try list.listDeleteItem(at: -1)

    print(last)
}
```

## Subscripting Safe Lists

`SafePythonObject` supports convenient subscript syntax inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [1, 2, 3])

    let first = list[0]
    let last = list[-1]
    list[1] = 20

    print(first, last)
}
```

Subscript access and assignment use Swift's non-throwing subscript model. If Python raises, the convenience subscript traps. For recoverable error handling, use the explicit throwing methods instead:

```swift
let first = try list.getItem(key: 0)
try list.setItem(key: 1, newValue: 20)
```

## Slicing Lists

For async `PythonObject` values, create a Python `slice` object with `interpreter.builtins.slice` and use generic item access:

```swift
let slice = try await interpreter.builtins.slice(1, 3)
let middle = try await list.getItem(key: slice)

let replacement = try await interpreter.convertToPython(array: [20, 30])
try await list.setItem(key: slice, newValue: replacement)
```

For `SafePythonObject`, use ``PythonSlice`` with subscript syntax:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [0, 1, 2, 3, 4])

    let middle = list[.slice(1, 4)]
    list[.slice(1, 3)] = try context.convertToSafePython(array: [10, 20])

    print(middle)
}
```

Use `nil` for omitted Python slice bounds:

```swift
let tail = list[.slice(2, nil)]
let reversed = list[.slice(nil, nil, step: -1)]
```

For recoverable slice assignment errors, use ``PythonInterpreter/SafePythonObject/setItem(key:newValue:)``:

```swift
try list.setItem(
    key: PythonSlice(1, 3),
    newValue: try context.convertToSafePython(array: [10, 20])
)
```

## Calling Python List Methods

Swift2Python does not wrap every Python list method. Call Python methods directly:

```swift
try await list.append(4)
let popped = try await list.pop()
try await list.reverse()
try await list.sort()
let copy = try await list.copy()
try await list.clear()
```

Use `extend`, `remove`, `index`, and other list methods the same way:

```swift
try await list.extend([4, 5])
try await list.remove(2)
let index = try await list.index(4)
```

If a Python method name conflicts with a Swift helper or property, call it through explicit dynamic-member syntax:

```swift
let occurrences = try await list[dynamicMember: "count"](2)
```

## Converting Lists To Tuples

Use Python's `tuple` constructor through `interpreter.builtins`:

```swift
let tuple = try await interpreter.builtins.tuple(list)
```

This works for any Python iterable, not just lists.

## Error Behavior

List helpers throw `PythonError.listConversionFailed(expected:actual:)` when the target object is not a Python list.

List item helpers throw Python exceptions for Python-level failures, including out-of-bounds indexes and invalid assignments. Async APIs throw `PythonError.pythonException`; safe APIs throw `PythonError.safePythonException`.

Safe subscript syntax is a convenience API and cannot throw. Use `getItem(key:)` and `setItem(key:newValue:)` when robust error handling matters.

## Choosing An API

Use list-specific helpers when the code is treating a Python object as a list:

```swift
let count = try await list.listCount()
let last = try await list.listItem(at: -1)
try await list.listAppendItem("value")
```

Use Python methods when you want normal Python list behavior:

```swift
let value = try await list.pop()
try await list.reverse()
```

Use `SafePythonObject` APIs only inside `withIsolatedContext` when synchronous access is required.
