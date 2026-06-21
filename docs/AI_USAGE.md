# Swift2Python AI Usage Guide

This file is written for coding agents and AI assistants that generate Swift2Python code. Prefer this guide when choosing API patterns, naming, and error handling. The DocC documentation is the human-facing reference; this file is a compact operational guide.

## General Rules

- Prefer public Swift2Python APIs over calling low-level CPython wrappers.
- Use async ``PythonObject`` APIs in normal Swift concurrency code.
- Use ``PythonInterpreter.SafePythonObject`` only inside `withIsolatedContext`.
- Prefer Swift conversion initializers such as `Int(pyObject)`, `String(pyObject)`, and `Double(pyObject)` over direct `convertTo...` calls in examples and user-facing code.
- Do not import `builtins` manually for common builtins access. Use `interpreter.builtins`.

## Operators

Operator support for arithmetic, bitwise, and comparison operations is release-ready. Treat the public operator APIs and their throwing alternatives as the canonical way to express Python operations in Swift2Python.

### Choosing The Right Operator API

Use async ``PythonObject`` methods in normal Swift concurrency code:

```swift
let lhs = try await interpreter.convertToPython(10)
let rhs = try await interpreter.convertToPython(3)
let result = try await lhs.add(rhs)
let isGreater = try await lhs.greaterThan(rhs)
```

Use throwing ``PythonInterpreter.SafePythonObject`` methods inside `withIsolatedContext` when the operation can fail and the caller should handle the error:

```swift
try await interpreter.withIsolatedContext { context in
    let lhs: PythonInterpreter.SafePythonObject = 10
    let rhs: PythonInterpreter.SafePythonObject = 0
    let result = try lhs.divide(divisor: rhs)
    print(try Double(result))
}
```

Use ``PythonInterpreter.SafePythonObject`` operators only for short expressions where failure is a programmer error. Operators are non-throwing and trap with `fatalError` if Python raises, conversion fails, or a fully deferred result cannot be represented:

```swift
try await interpreter.withIsolatedContext { context in
    let lhs: PythonInterpreter.SafePythonObject = 10
    let rhs: PythonInterpreter.SafePythonObject = 3
    let result = lhs + rhs
    let ok = lhs > rhs
}
```

Do not generate operator code for user input, mixed unknown Python values, or examples intended to demonstrate error handling. Generate the throwing method form instead.

### Safe Arithmetic Methods

For ``PythonInterpreter.SafePythonObject`` arithmetic, prefer these throwing methods when failure should be handled:

```swift
try value.positive()
try value.negative()
try value.absolute()
try lhs.add(rhs)
try lhs.subtract(subtrahend: rhs)
try lhs.multiply(rhs)
try lhs.divide(divisor: rhs)
try lhs.modulus(divisor: rhs)
try lhs.power(exponent: rhs)
```

The matching operators are:

```swift
+value
-value
abs(value)
lhs + rhs
lhs - rhs
lhs * rhs
lhs / rhs
lhs % rhs
lhs ** rhs
lhs += rhs
lhs -= rhs
lhs *= rhs
lhs /= rhs
lhs %= rhs
lhs **= rhs
```

### Safe Bitwise Methods

For ``PythonInterpreter.SafePythonObject`` bitwise operations, prefer these throwing methods when failure should be handled:

```swift
try lhs.bitwiseAnd(rhs)
try lhs.bitwiseOr(rhs)
try lhs.bitwiseXor(rhs)
try value.bitwiseInvert()
try lhs.bitShiftLeft(rhs)
try lhs.bitShiftRight(rhs)
```

The matching operators are:

```swift
lhs & rhs
lhs | rhs
lhs ^ rhs
~value
lhs << rhs
lhs >> rhs
lhs &= rhs
lhs |= rhs
lhs ^= rhs
lhs <<= rhs
lhs >>= rhs
```

### Safe Comparison Methods

For normal comparisons, use the Bool-returning methods:

```swift
try lhs.equal(rhs)
try lhs.notEqual(rhs)
try lhs.lessThan(rhs)
try lhs.lessThanOrEqual(rhs)
try lhs.greaterThan(rhs)
try lhs.greaterThanOrEqual(rhs)
```

The matching operators are:

```swift
lhs == rhs
lhs != rhs
lhs < rhs
lhs <= rhs
lhs > rhs
lhs >= rhs
```

`SafePythonObject` comparison operators return Swift `Bool` in normal comparison contexts. They can also return a Python bool object when assigned to `SafePythonObject`:

```swift
let swiftBool: Bool = lhs < rhs
let pythonBool: PythonInterpreter.SafePythonObject = lhs < rhs
```

Use raw Python comparison result methods only when you intentionally need Python's `PyObject_RichCompare` result as a ``PythonInterpreter.SafePythonObject``:

```swift
try lhs.equalPython(rhs)
try lhs.notEqualPython(rhs)
try lhs.lessThanPython(rhs)
try lhs.lessThanOrEqualPython(rhs)
try lhs.greaterThanPython(rhs)
try lhs.greaterThanOrEqualPython(rhs)
```

Do not use `*Python` comparison methods for ordinary boolean decisions. Use them only for custom Python classes whose rich comparison may return a non-`bool` object that must be preserved.

### Async PythonObject Methods

For ``PythonObject``, use async throwing methods. There are no Swift operator overloads for async `PythonObject` operations.

Arithmetic:

```swift
try await value.absolute()
try await value.positive()
try await value.negative()
try await lhs.add(rhs)
try await lhs.addInPlace(rhs)
try await lhs.subtract(rhs)
try await lhs.subtractInPlace(rhs)
try await lhs.multiply(rhs)
try await lhs.multiplyInPlace(rhs)
try await lhs.divide(rhs)
try await lhs.divideInPlace(rhs)
try await lhs.modulus(rhs)
try await lhs.modulusInPlace(rhs)
try await lhs.power(rhs)
try await lhs.powerInPlace(rhs)
```

Bitwise:

```swift
try await lhs.bitwiseAnd(rhs)
try await lhs.bitwiseAndInPlace(rhs)
try await lhs.bitwiseOr(rhs)
try await lhs.bitwiseOrInPlace(rhs)
try await lhs.bitwiseXor(rhs)
try await lhs.bitwiseXorInPlace(rhs)
try await value.bitwiseInvert()
try await lhs.bitShiftLeft(rhs)
try await lhs.bitShiftLeftInPlace(rhs)
try await lhs.bitShiftRight(rhs)
try await lhs.bitShiftRightInPlace(rhs)
```

Comparisons return Swift `Bool`:

```swift
try await lhs.equal(rhs)
try await lhs.notEqual(rhs)
try await lhs.lessThan(rhs)
try await lhs.lessThanOrEqual(rhs)
try await lhs.greaterThan(rhs)
try await lhs.greaterThanOrEqual(rhs)
```

### Logical Operations

Use logical methods for Python truthiness and Python-style `and` / `or`. Do not generate Swift `&&` or `||` for `PythonObject` or ``PythonInterpreter.SafePythonObject`` values.

Use `isTrue()` when the caller needs a Swift `Bool` condition:

```swift
if try await value.isTrue() {
    print("truthy")
}
```

Use `isNotTrue()` for Python logical NOT as a Swift `Bool`:

```swift
if try await value.isNotTrue() {
    print("falsey")
}
```

Safe truthiness works inside `withIsolatedContext` and supports deferred literals:

```swift
try await interpreter.withIsolatedContext { context in
    let value: PythonInterpreter.SafePythonObject = ""
    let falsey = try value.isNotTrue()
}
```

Use `logicalAnd` and `logicalOr` when Python operand-returning behavior matters. These methods return a Python object, not a Swift `Bool`:

```swift
let selected = try await preferred.logicalOr(fallback)
let required = try await condition.logicalAnd(value)
```

Use the closure overloads when preserving Python short-circuiting matters. The closure should create the right operand only when Python would evaluate it:

```swift
let selected = try await preferred.logicalOr {
    try await computeFallback()
}

let required = try await condition.logicalAnd {
    try await computeValue()
}
```

Safe short-circuiting is synchronous inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let preferred: PythonInterpreter.SafePythonObject = ""
    let selected = try preferred.logicalOr {
        try context.convertToSafePython("fallback")
    }
}
```

Remember Python semantics:

- `lhs.logicalAnd(rhs)` returns `lhs` when `lhs` is falsey; otherwise it returns `rhs`.
- `lhs.logicalOr(rhs)` returns `lhs` when `lhs` is truthy; otherwise it returns `rhs`.
- These methods are not replacements for comparison methods. For comparisons, use `equal`, `lessThan`, and related APIs.

### Error Behavior

Async ``PythonObject`` methods throw `PythonError.pythonException` when Python raises and may also throw conversion errors.

Throwing ``PythonInterpreter.SafePythonObject`` methods throw `PythonError.safePythonException` for Python failures, `PythonError.typeError` for invalid fully deferred primitive combinations, `PythonError.divisionByZero` for fully deferred zero division or modulus, and `PythonError.overflowError` when a fully deferred integer result cannot fit in Swift2Python's deferred storage.

Logical closure overloads can also throw errors from the right-hand closure. Deferred safe truthiness for bool, int, double, and string literals is evaluated locally and does not raise Python exceptions.

Safe operators use the same underlying behavior, but they cannot throw. Do not write generated code that catches around an operator; use the throwing method instead.

### Do Not Add Duplicate Operator APIs

Do not add alternate names for existing operations unless the user explicitly requests a new API. In particular:

- Do not add `equals` or `notEquals`; use `equal` and `notEqual`.
- Do not add plural comparison names such as `lessThanOrEquals`; use `lessThanOrEqual` and `greaterThanOrEqual`.
- Do not add custom async operators for ``PythonObject``. Swift operators cannot be async or throwing in the way these APIs need.
- Do not bypass the public methods by calling low-level CPython wrappers directly.

## Iteration

Iteration support is release-ready and should be treated as complete. Do not add synchronous `Sequence` conformance to ``PythonObject``; async Python objects must use `AsyncSequence` because creating and advancing Python iterators can require async interpreter work.

### Choosing The Right Iteration API

Use `for try await` for normal async ``PythonObject`` values:

```swift
let iterable = try await interpreter.convertToPython(array: [1, 2, 3])

for try await item in iterable {
    print(try await Int(item))
}
```

This is the preferred generated-code pattern for Python lists, tuples, sets, dictionaries, dictionary views, ranges, generators, existing iterators, and custom iterable classes.

Use ``PythonInterpreter.SafePythonObject`` iteration only inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let iterable = try context.convertToSafePython(array: [1, 2, 3])

    for item in iterable {
        print(try Int(item))
    }
}
```

Use safe `for`-`in` only when iteration failure is a programmer error. Swift `Sequence` cannot throw from `makeIterator()` or `next()`, so this path traps if Python refuses to create an iterator or raises while advancing it.

Use the throwing safe iterator when errors should be handled:

```swift
try await interpreter.withIsolatedContext { context in
    let iterable = try context.convertToSafePython(array: [1, 2, 3])
    var iterator = try iterable.pythonIterator()

    while let item = try iterator.nextThrowing() {
        print(try Int(item))
    }
}
```

### Dictionary Items

For async ``PythonObject`` dictionary views, call Python's `items()` and iterate the Python tuples when lazy view iteration is desired:

```swift
let items = try await dict.items()
for try await item in items {
    let key = try await String(item.getItem(key: 0))
    let value = try await Int(item.getItem(key: 1))
    print(key, value)
}
```

Use `dictItems()` when the caller wants an eager Swift array of `(key, value)` pairs:

```swift
let pairs = try await dict.dictItems()
for pair in pairs {
    print(try await String(pair.key), try await Int(pair.value))
}
```

Inside `withIsolatedContext`, use `dict.items()` for a Swift sequence that yields labeled `(key, value)` safe-object pairs:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: ["one": 1])

    for pair in dict.items() {
        print(try String(pair.key), try Int(pair.value))
    }
}
```

Use `dictItems` when an eager safe Swift array is better than iterating Python's `items()` view.

### Iteration Error Behavior

Async ``PythonObject`` iteration throws `PythonError.pythonException` when Python raises while creating or advancing the iterator. Normal Python `StopIteration` ends the loop and is not an error.

Throwing safe iteration throws `PythonError.safePythonException` for Python-raised failures. Normal `StopIteration` returns `nil` from `nextThrowing()`.

Non-throwing safe `for`-`in` iteration traps on Python errors. Do not generate safe `for`-`in` loops for user input, non-iterable candidates, or custom Python iterators expected to raise. Generate `pythonIterator()` plus `nextThrowing()` instead.

### Iteration Versus Eager Arrays

Prefer iteration for generators, ranges, dictionary views, large containers, and one-pass processing:

```swift
for try await item in pythonRange {
    // process one item at a time
}
```

Prefer eager helpers when the caller needs random access, repeated traversal, count before traversal, or a stable Swift snapshot:

```swift
let elements = try await list.asArray()
let keys = try await dict.dictKeys()
let pairs = try await dict.dictItems()
```

Do not add separate wrapper APIs for every Python iterable type. Python's iterator protocol covers the general case.

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

## Sets

Set support covers Python `set` and `frozenset`. Prefer explicit Swift2Python helpers for creation, type checks, counts, membership, mutable add/remove/discard, and eager array conversion. Use normal Python method calls for set algebra and less-common Python set operations.

### What Set APIs Exist

Async ``PythonObject`` set APIs:

```swift
try await object.isSet()
try await object.isFrozenSet()
try await object.isAnySet()
try await set.setCount()
try await set.asSetArray()
try await set.setContains("value")
try await set.setAdd("value")
try await set.setRemove("value")
try await set.setDiscard("value")
```

Set and frozenset creation from Swift sets:

```swift
let set = try await interpreter.convertToPython(set: Set([1, 2, 3]))
let frozenSet = try await interpreter.convertToPython(frozenSet: Set([1, 2, 3]))
```

Swift `Set` conforms to `PendingPythonConvertible` and converts to a mutable Python `set`:

```swift
let set = try await Set(["red", "green"]).toPythonObject(interpreter: interpreter)
```

Safe set APIs inside `withIsolatedContext`:

```swift
try object.isSet
try object.isFrozenSet
try object.isAnySet
try set.setCount
try set.setArray
try set.setContains("value")
try set.setAdd("value")
try set.setRemove("value")
try set.setDiscard("value")
```

Safe set and frozenset creation:

```swift
try await interpreter.withIsolatedContext { context in
    let set = try context.convertToSafePython(set: Set([1, 2, 3]))
    let frozenSet = try context.convertToSafePython(frozenSet: Set([1, 2, 3]))
}
```

### Preferred Async Patterns

Create a mutable Python set from a Swift set:

```swift
let set = try await interpreter.convertToPython(set: Set([1, 2, 3]))
```

Create a Python frozenset only with the explicit `frozenSet:` label:

```swift
let frozenSet = try await interpreter.convertToPython(frozenSet: Set([1, 2, 3]))
```

Check type and count:

```swift
if try await object.isAnySet() {
    let count = try await object.setCount()
    print(count)
}
```

Convert to an eager Swift array of Python objects when needed. Treat the order as arbitrary because Python sets are unordered:

```swift
let elements = try await set.asSetArray()
for element in elements {
    print(try await Int(element))
}
```

Use membership and mutation helpers when the object is expected to be a set:

```swift
if try await set.setContains(2) {
    try await set.setRemove(2)
}
try await set.setAdd(4)
try await set.setDiscard(99)
```

### Python-Native Set Methods

Use direct Python method calls for normal set algebra and Python-native behavior:

```swift
let union = try await set.union(other)
let intersection = try await set.intersection(other)
let difference = try await set.difference(other)
let symmetricDifference = try await set.symmetric_difference(other)

let subset = try await smaller.issubset(set)
let superset = try await set.issuperset(smaller)
let disjoint = try await set.isdisjoint(other)

let popped = try await set.pop()
try await set.update([4, 5])
try await set.clear()
let copy = try await set.copy()
```

Do not create wrapper APIs for every Python set method by default. Python-native calls cover methods such as `clear`, `copy`, `difference`, `difference_update`, `intersection`, `intersection_update`, `isdisjoint`, `issubset`, `issuperset`, `pop`, `symmetric_difference`, `symmetric_difference_update`, `union`, and `update`.

### Preferred Safe Patterns

Use safe set APIs only inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let set = try context.convertToSafePython(set: Set([1, 2, 3]))

    let count = try set.setCount
    let elements = try set.setArray
    try set.setAdd(4)

    print(count, elements)
}
```

Call Python-native methods directly in the safe context:

```swift
try await interpreter.withIsolatedContext { context in
    let set = try context.convertToSafePython(set: Set([1, 2, 3]))
    let other = try context.convertToSafePython(set: Set([3, 4]))

    let union = try set.union(other)
    let popped = try set.pop()
    print(union, popped)
}
```

For safe code that might access a missing Python method or attribute, prefer the explicit throwing `get(attr:)` API over dynamic-member syntax. Dynamic-member lookup can trap when the attribute does not exist:

```swift
let pop = try set.get(attr: "pop")
```

### Frozenset Guidance

`frozenset` is immutable. Use `isFrozenSet`, `isAnySet`, `setCount`, `setContains`, and `asSetArray` / `setArray` with frozensets.

Do not call mutation helpers on frozensets:

```swift
try await frozenSet.setContains(2)  // OK
try await frozenSet.setAdd(4)       // throws setConversionFailed
```

Use Python-native non-mutating methods on frozensets when needed:

```swift
let union = try await frozenSet.union(other)
let disjoint = try await frozenSet.isdisjoint(other)
```

### Error Behavior

Async set helpers throw:

- `PythonError.setConversionFailed(expected:actual:)` when the object is not a set or frozenset, or when a mutation helper is used on a frozenset.
- `PythonError.pythonException` when Python raises while performing set operations, including `setRemove` for a missing item or Python `pop()` on an empty set.

Safe set helpers throw:

- `PythonError.setConversionFailed(expected:actual:)` when the object is not a set or frozenset, or when a mutation helper is used on a frozenset.
- `PythonError.safePythonException` when Python raises while performing set operations.

`setRemove` follows Python `remove` semantics and throws for missing items. `setDiscard` follows Python `discard` semantics and does not throw for missing items.

Avoid using deliberately unhashable values, such as a Python list inserted into a Python set, as ordinary set-support tests. That path is useful for reference-counting/error-bridge regression tests, but it can expose lower-level exception wrapping issues unrelated to set API behavior.

### What Not To Add For Sets

Do not add these unless the user explicitly requests them:

- Wrapper APIs for every Python set method.
- Separate Swift wrapper methods for set algebra operations such as `union`, `intersection`, and `difference`; direct Python calls cover them.
- A `pop()` wrapper. Users can call `set.pop()` directly.
- A `clear()` wrapper. Users can call `set.clear()` directly.
- Mutation helpers for frozenset. Python frozensets are immutable.
- Optional safe set helpers. The main safe set API throws.

### Release Completeness

Set support should be considered complete for a 1.0 release when it has async APIs, safe APIs, mutable set creation, frozenset creation, type inspection, count, membership, mutation helpers for mutable sets, array conversion, Python-native method examples, unit tests, and DocC documentation.

## Bytes And Bytearray

Bytes support has explicit helpers for Python `bytes`, Python `bytearray`, and readable buffer-protocol objects. Prefer these helpers when the user is working with binary data. Do not rely on generic array conversion for binary data.

### What Bytes APIs Exist

Async ``PythonObject`` bytes APIs:

```swift
try await object.isBytes()
try await object.isByteArray()
try await object.isBytesLike()
try await bytes.bytesSize()
try await byteArray.byteArraySize()
try await object.asCopiedData()
try await object.asCopiedBytes()
try await object.asCopiedByteArray()
try await object.asCopiedString()
try await object.withUnsafeBytes { buffer in ... }
```

Bytes and bytearray creation:

```swift
let bytes = try await interpreter.convertToPython(bytes: [0, 1, 2, 255])
let bytesFromData = try await interpreter.convertToPython(bytes: Data([0, 1, 2]))

let byteArray = try await interpreter.convertToPython(byteArray: [0, 1, 2])
let byteArrayFromData = try await interpreter.convertToPython(byteArray: Data([0, 1, 2]))
```

Safe bytes APIs inside `withIsolatedContext`:

```swift
try object.isBytes
try object.isByteArray
try object.isBytesLike
try bytes.bytesSize
try byteArray.byteArraySize
try object.asCopiedData()
try object.asCopiedBytes()
try object.asCopiedByteArray()
try object.asCopiedString()
try object.withUnsafeBytes { buffer in ... }
```

Safe bytes and bytearray creation:

```swift
try await interpreter.withIsolatedContext { context in
    let bytes = try context.convertToSafePython(bytes: [1, 2, 3])
    let byteArray = try context.convertToSafePython(byteArray: [1, 2, 3])
}
```

### Data And `[UInt8]` Rules

`Data` conforms to `PendingPythonConvertible` and `SafePythonConvertible`. It converts to immutable Python `bytes`:

```swift
let data = Data([1, 2, 3])
let bytes = try await data.toPythonObject(interpreter: interpreter)
```

`[UInt8]` is still a Swift array. Generic conversion turns it into a Python list:

```swift
let values: [UInt8] = [1, 2, 3]
let list = try await values.toPythonObject(interpreter: interpreter) // Python list
```

When `[UInt8]` means binary data, use explicit labels:

```swift
let bytes = try await interpreter.convertToPython(bytes: values)
let byteArray = try await interpreter.convertToPython(byteArray: values)
```

Do not change `[UInt8]` generic array conversion to Python `bytes`; that would break the consistent Array-to-list rule.

### Preferred Async Patterns

Create immutable bytes from `Data` when possible:

```swift
let payload = Data([0, 1, 2, 255])
let bytes = try await interpreter.convertToPython(bytes: payload)
```

Create mutable bytearrays only when Python-side mutation is needed:

```swift
let byteArray = try await interpreter.convertToPython(byteArray: [1, 2, 3])
try await byteArray.append(4)
try await byteArray.extend([5, 6])
```

Copy bytes back into Swift with `Data` or `[UInt8]` helpers:

```swift
let data = try await object.asCopiedData()
let values = try await object.asCopiedBytes()
```

Use `asCopiedString(encoding:)` only when the bytes are text:

```swift
let text = try await object.asCopiedString(encoding: .utf8)
```

Use `withUnsafeBytes` only for temporary access during the closure. Do not store the buffer pointer:

```swift
let checksum = try await object.withUnsafeBytes { buffer in
    buffer.reduce(0) { $0 + Int($1) }
}
```

### Preferred Safe Patterns

Use safe bytes APIs only inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let bytes = try context.convertToSafePython(bytes: Data([1, 2, 3]))

    let count = try bytes.bytesSize
    let data = try bytes.asCopiedData()
    let values = try bytes.asCopiedBytes()

    print(count, data, values)
}
```

Call Python-native bytearray methods directly in the safe context:

```swift
try await interpreter.withIsolatedContext { context in
    let byteArray = try context.convertToSafePython(byteArray: [1, 2, 3])
    _ = try byteArray.append(4)
    _ = try byteArray.reverse()
}
```

### Buffer Protocol Guidance

Use `isBytesLike` when accepting any readable Python buffer, including `bytes`, `bytearray`, and `memoryview`:

```swift
if try await object.isBytesLike() {
    let bytes = try await object.asCopiedBytes()
}
```

Use `isBytes` or `isByteArray` only when exact concrete Python type matters.


### Error Behavior

Async bytes helpers throw:

- `PythonError.bytesConversionFailed(expected:actual:)` when the object is not the expected bytes shape, such as calling `bytesSize()` on a non-`bytes` object or `byteArraySize()` on a non-`bytearray` object.
- `PythonError.bytesConversionFailed(expected:actual:)` when `withUnsafeBytes`, `asCopiedData`, or `asCopiedBytes` is used on a non-buffer object.
- `PythonError.bytesConversionFailed(expected:actual:)` when `asCopiedString(encoding:)` cannot decode the bytes.
- `PythonError.pythonException` when Python raises during Python-native method calls.

Safe bytes helpers throw the same Swift conversion error for Swift2Python validation failures and `PythonError.safePythonException` for Python-raised failures.

### What Not To Add For Bytes

Do not add these unless the user explicitly requests them:

- A generic `[UInt8]` conversion that produces Python `bytes`; use explicit `bytes:` labels instead.
- Wrapper APIs for every Python `bytearray` method. Direct Python calls cover `append`, `extend`, `pop`, `reverse`, `clear`, and related methods.
- Persistent storage of pointers from `withUnsafeBytes`; copy to `Data` or `[UInt8]` when data must outlive the closure.
- Mutation helpers for Python `bytes`. Python `bytes` are immutable.

### Release Completeness

Bytes support should be considered complete for a 1.0 release when it has async APIs, safe APIs, `bytes` creation, `bytearray` creation, `Data` conversion, type inspection, size helpers, buffer-protocol copying, string decoding, unit tests, and DocC documentation.
