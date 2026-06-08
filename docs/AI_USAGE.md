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

## Dictionaries

Dictionary support has explicit stable-ABI helpers for dictionary creation, inspection, key/value/item extraction, membership, and deletion. Prefer those helpers when the user is working with dictionaries as dictionaries. Use normal Python method calls when the user needs Python-native dict view objects or Python methods such as `get`, `pop`, or `update`.

### What Dictionary APIs Exist

Async ``PythonObject`` dictionary APIs:

```swift
try await object.isDict()
try await dict.dictCount()
try await dict.dictKeys()
try await dict.dictValues()
try await dict.dictItems()
try await dict.containsKey("name")
try await dict.deleteItem(key: "name")
try await dict.getItem(key: "name")
try await dict.setItem(key: "name", newValue: "Ada")
```

Dictionary creation from Swift dictionaries:

```swift
let dict = try await interpreter.convertToPython(dictionary: [
    "name": "Ada",
    "count": 3
])

let heterogeneous: [String: any PendingPythonConvertible] = [
    "name": "Ada",
    "count": 3,
    "active": true
]
let heterogeneousDict = try await interpreter.convertToPython(dictionary: heterogeneous)
```

Safe dictionary APIs inside `withIsolatedContext`:

```swift
try dict.isDict
try dict.dictCount
try dict.dictKeys
try dict.dictValues
try dict.dictItems
try dict.containsKey("name")
try dict.deleteItem(key: "name")
```

Safe dictionary creation:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: [
        "name": "Ada",
        "count": 3
    ])
}
```

### Preferred Async Patterns

Create dictionaries from Swift dictionaries:

```swift
let dict = try await interpreter.convertToPython(dictionary: [
    "one": 1,
    "two": 2
])
```

Read dictionary keys, values, and items as Swift arrays of Python objects:

```swift
let keys = try await dict.dictKeys()
for key in keys {
    print(try await String(key))
}

let items = try await dict.dictItems()
for item in items {
    let key = try await String(item.key)
    let value = try await Int(item.value)
    print(key, value)
}
```

Use generic item APIs for lookup and assignment:

```swift
let name = try await dict.getItem(key: "name")
try await dict.setItem(key: "count", newValue: 4)
```

Use dictionary-specific membership and deletion helpers:

```swift
if try await dict.containsKey("name") {
    try await dict.deleteItem(key: "name")
}
```

### Python-Native Dictionary Methods

Use normal Python method calls when the user wants Python's native dictionary behavior:

```swift
let keysView = try await dict.keys()
let valuesView = try await dict.values()
let itemsView = try await dict.items()
```

Python's `keys()`, `values()`, and `items()` return view objects. Convert them with builtins when a list is needed:

```swift
let keysList = try await interpreter.builtins.list(keysView)
let keys = try await keysList.asArray()
```

Use explicit dynamic-member syntax when a Python method name conflicts with a Swift helper or overload, or when passing multiple arguments is clearer:

```swift
let fallback = try await dict[dynamicMember: "get"]("missing", "fallback")
let popped = try await dict.pop("name")
_ = try await dict.update(["city": "London"])
```

Do not create wrapper APIs for every Python dict method by default. Python-native calls cover methods such as `clear`, `copy`, `fromkeys`, `get`, `items`, `keys`, `pop`, `popitem`, `setdefault`, `update`, and `values`.

### Preferred Safe Patterns

Use safe dictionary APIs only inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: [
        "name": "Ada",
        "count": 3
    ])

    let count = try dict.dictCount
    let name = try String(dict["name"])
    print(count, name)
}
```

Use safe array helpers for keys, values, and items:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: ["one": 1, "two": 2])

    let keys = try dict.dictKeys
    let values = try dict.dictValues
    let items = try dict.dictItems

    print(keys.count, values.count, items.count)
}
```

Use safe Python-native methods when Python view semantics are needed:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: ["name": "Ada"])

    let keysView = try dict.keys()
    let keysList = try context.builtins.list(keysView)
    print(keysList)
}
```

If a Python dictionary method collides with a Swift helper name, call it through explicit dynamic-member syntax:

```swift
let itemsView = try dict[dynamicMember: "items"]()
let fallback = try dict[dynamicMember: "get"]("missing", "fallback")
```

### Error Behavior

Async dictionary helpers throw:

- `PythonError.dictionaryConversionFailed(expected:actual:)` when the object is not a dictionary.
- `PythonError.pythonException` when Python raises while performing dictionary operations, including deleting a missing key.

Safe dictionary helpers throw:

- `PythonError.dictionaryConversionFailed(expected:actual:)` when the object is not a dictionary.
- `PythonError.safePythonException` when Python raises while performing dictionary operations, including deleting a missing key.

Safe dictionary helpers throw and return non-optional values. Do not write safe dictionary code as if keys, values, or items return optionals:

```swift
let items = try dict.dictItems
```

Do not write:

```swift
if let items = try dict.dictItems { }
```

### Dictionary View Guidance

Use Swift2Python's dictionary helpers when the intended result is a Swift array:

```swift
let keys = try await dict.dictKeys()
```

Use Python's dictionary methods when the intended result is a Python view object:

```swift
let keysView = try await dict.keys()
```

Do not treat these as interchangeable. The helper eagerly returns Swift arrays of Swift2Python objects; Python methods return live Python view objects.

### What Not To Add For Dictionaries

Do not add these unless the user explicitly requests them:

- Wrapper APIs for every Python dict method.
- A `clear()` wrapper. Users can call Python's `dict.clear()` directly, and `PyDict_Clear` is not needed for the core API.
- A `pop()` wrapper. Users can call `try await dict.pop("key")` or `try dict.pop("key")` in safe context.
- Dedicated wrappers for `keys()`, `values()`, or `items()` view objects. Existing Python method calls cover this.
- Optional safe dictionary helpers. The main safe dictionary API throws.

### Release Completeness

Dictionary support should be considered close to release-ready when it has async APIs, safe APIs, dictionary creation, dictionary inspection, key/value/item extraction, membership, deletion, Python-native method examples, unit tests, and DocC documentation.

## Lists

List support has explicit helpers for list creation, inspection, length, array conversion, item access, and item mutation. Prefer those helpers when the user is treating an object as a list. Use normal Python method calls for Python-native list behavior such as `pop`, `reverse`, `sort`, `copy`, `clear`, `count`, `index`, `remove`, and `extend`.

### What List APIs Exist

Async ``PythonObject`` list APIs:

```swift
try await object.isList()
try await list.listCount()
try await list.asArray()
try await list.listItem(at: 0)
try await list.listItem(at: -1)
try await list.listSetItem(at: -1, to: "value")
try await list.listAppendItem("value")
try await list.listInsertItem("value", at: 1)
try await list.listDeleteItem(at: -1)
try await list.getItem(key: 0)
try await list.setItem(key: 0, newValue: "value")
```

List creation from Swift arrays:

```swift
let list = try await interpreter.convertToPython(array: [1, 2, 3])

let heterogeneous: [any PendingPythonConvertible] = ["name", 3, true]
let heterogeneousList = try await interpreter.convertToPython(array: heterogeneous)
```

Safe list APIs inside `withIsolatedContext`:

```swift
try list.isList
try list.listCount
try list.listArray
try list.listItem(at: 0)
try list.listItem(at: -1)
try list.listSetItem(at: -1, to: "value")
try list.listAppendItem("value")
try list.listInsertItem("value", at: 1)
try list.listDeleteItem(at: -1)
try list.getItem(key: 0)
try list.setItem(key: 0, newValue: "value")
```

Safe list creation:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [1, 2, 3])
}
```

Safe convenience subscripts:

```swift
let first = list[0]
let last = list[-1]
list[1] = "value"

let middle = list[1..<3]
let tail = list[2...]
list[1...2] = replacement
let reversed = list[.slice(nil, nil, step: -1)]
```

### Preferred Async Patterns

Create lists from Swift arrays:

```swift
let list = try await interpreter.convertToPython(array: [1, 2, 3])
```

Read and mutate items with list helpers when the object is expected to be a Python list:

```swift
let last = try await list.listItem(at: -1)
try await list.listSetItem(at: -1, to: "replacement")
try await list.listAppendItem("tail")
try await list.listDeleteItem(at: -1)
```

Convert a Python list to a Swift array when eager Swift iteration is wanted:

```swift
let elements = try await list.asArray()
for element in elements {
    print(try await Int(element))
}
```

Use Swift ranges plus generic item access for ordinary async slicing. Swift cannot use `await` in subscript access for `PythonObject`:

```swift
let middle = try await list.getItem(key: 1..<3)
let inclusiveMiddle = try await list.getItem(key: 1...2)
let tail = try await list.getItem(key: 2...)
try await list.setItem(key: 1..<3, newValue: replacement)
```

Use `PythonSlice` or `builtins.slice` when a Swift range cannot express the slice, such as a stepped or reversed slice:

```swift
let reversed = try await list.getItem(key: PythonSlice(nil, nil, step: -1))
let slice = try await interpreter.builtins.slice(1, 3)
let sameMiddle = try await list.getItem(key: slice)
```

Convert a Python list to a tuple with Python's own constructor:

```swift
let tuple = try await interpreter.builtins.tuple(list)
```

Do not add a `listAsTuple()` helper. Python's `tuple` constructor works for any iterable.

### Python-Native List Methods

Use direct Python method calls for normal list methods:

```swift
try await list.append(4)
let popped = try await list.pop()
try await list.reverse()
try await list.sort()
let copy = try await list.copy()
try await list.clear()
try await list.extend([1, 2, 3])
try await list.remove(2)
let index = try await list.index(3)
```

If a Python method name conflicts with a Swift helper or property, call it through explicit dynamic-member syntax:

```swift
let occurrences = try await list[dynamicMember: "count"](2)
```

Do not create wrapper APIs for every Python list method by default. Python-native calls cover methods such as `append`, `clear`, `copy`, `count`, `extend`, `index`, `insert`, `pop`, `remove`, `reverse`, and `sort`.

### Preferred Safe Patterns

Use safe list APIs only inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [1, 2, 3])

    let count = try list.listCount
    let last = try list.listItem(at: -1)
    try list.listSetItem(at: 0, to: 10)

    print(count, last)
}
```

Use safe subscript syntax for concise code when trapping on Python errors is acceptable. Prefer Swift ranges for ordinary slicing:

```swift
try await interpreter.withIsolatedContext { context in
    var list = try context.convertToSafePython(array: [0, 1, 2, 3])

    let last = list[-1]
    list[1] = 20

    let middle = list[1..<3]
    let tail = list[2...]
    list[1...2] = try context.convertToSafePython(array: [10, 20])

    print(last, middle, tail)
}
```

Use explicit throwing item methods for robust safe code:

```swift
let value = try list.getItem(key: -1)
let middle = try list.getItem(key: 1..<3)
try list.setItem(key: 1..<3, newValue: replacement)
```

### Error Behavior

Async list helpers throw:

- `PythonError.listConversionFailed(expected:actual:)` when the object is not a list.
- `PythonError.pythonException` when Python raises while performing list operations, including out-of-bounds item access or invalid slice assignment.

Safe list helpers throw:

- `PythonError.listConversionFailed(expected:actual:)` when the object is not a list.
- `PythonError.safePythonException` when Python raises while performing list operations, including out-of-bounds item access or invalid slice assignment.

Safe subscript access and assignment cannot throw because Swift subscripts are not `throws` in this design. They trap on Python errors. Tell users to call `getItem(key:)` and `setItem(key:newValue:)` when they need recoverable error handling.

### Slice Guidance

For async ``PythonObject`` slicing, prefer Swift ranges with generic item access:

```swift
let result = try await list.getItem(key: 1..<3)
let tail = try await list.getItem(key: 2...)
let prefix = try await list.getItem(key: ..<3)
try await list.setItem(key: 1...2, newValue: replacement)
```

For safe slicing, prefer Swift ranges with subscript syntax:

```swift
let result = list[1..<3]
let tail = list[2...]
let prefix = list[..<3]
list[1...2] = replacement
```

Supported Swift range keys are `Range<Int>`, `ClosedRange<Int>`, `PartialRangeFrom<Int>`, `PartialRangeUpTo<Int>`, and `PartialRangeThrough<Int>`. Closed ranges are converted to Python's exclusive stop convention, so `1...2` becomes `slice(1, 3)`.

Use ``PythonSlice`` when a Swift range cannot express the slice:

```swift
let reversed = list[.slice(nil, nil, step: -1)]
try list.setItem(key: PythonSlice(1, 3), newValue: replacement)
```

### What Not To Add For Lists

Do not add these unless the user explicitly requests them:

- Wrapper APIs for every Python list method.
- `listAsTuple()` or `tupleFromList()` wrappers.
- A `reverse()` wrapper. Users can call `list.reverse()` directly.
- A `pop()` wrapper. Users can call `list.pop()` directly.
- A `sort()` wrapper. Users can call `list.sort()` directly.
- Separate async subscript slicing for `PythonObject`; use Swift range keys or `PythonSlice` with `getItem`/`setItem` because Swift cannot use `await` with subscript syntax.
- Optional safe list helpers. The main safe list API throws.

### Release Completeness

List support should be considered complete for a 1.0 release when it has async APIs, safe APIs, list creation, list inspection, array conversion, item access and mutation, negative indexing, Swift range slicing, `PythonSlice` support for stepped slices, Python-native method examples, unit tests, and DocC documentation.
