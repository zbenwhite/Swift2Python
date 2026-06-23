# Sets

Create Python sets and frozensets from Swift sets, inspect Python set objects, check membership, mutate Python sets, and convert Python set values to Swift arrays.

## Overview

Python `set` is a mutable unordered collection of unique hashable values. Python `frozenset` is the immutable equivalent. Swift2Python exposes set support in two styles:

- Use ``PythonObject`` methods from async Swift code.
- Use ``PythonInterpreter/SafePythonObject`` properties and methods inside `withIsolatedContext` when you need synchronous access.

Set-specific helpers validate Python object types before reading or mutating. Helpers that work for either `set` or `frozenset` use `isAnySet`, `setCount`, `setContains`, and array conversion. Mutation helpers require a mutable Python `set`.

## Creating Python Sets

Use ``PythonInterpreter/convertToPython(set:)`` to create a mutable Python set from a Swift `Set`:

```swift
let set = try await interpreter.convertToPython(set: Set([1, 2, 3]))
```

Swift sets also conform to ``PendingPythonConvertible`` when their elements are convertible:

```swift
let set = try await Set(["red", "green", "blue"])
    .toPythonObject(interpreter: interpreter)
```

Inside an isolated context, use ``PythonInterpreter/convertToSafePython(set:)``:

```swift
try await interpreter.withIsolatedContext { context in
    let set = try context.convertToSafePython(set: Set([1, 2, 3]))
    print(try set.setCount)
}
```

Swift set membership guarantees Swift hashability. Python may still reject an element if the converted Python object is not hashable.

## Creating Python Frozensets

Use ``PythonInterpreter/convertToPython(frozenSet:)`` when Python code expects an immutable `frozenset`:

```swift
let frozenSet = try await interpreter.convertToPython(frozenSet: Set([1, 2, 3]))
```

Inside an isolated context, use ``PythonInterpreter/convertToSafePython(frozenSet:)``:

```swift
try await interpreter.withIsolatedContext { context in
    let frozenSet = try context.convertToSafePython(frozenSet: Set([1, 2, 3]))
    print(try frozenSet.isFrozenSet)
}
```

Swift `Set` conversion through `toPythonObject` creates a mutable Python `set`. Use the explicit `frozenSet:` conversion when you need `frozenset`.

## Checking And Counting

Use ``PythonObject/isSet()``, ``PythonObject/isFrozenSet()``, and ``PythonObject/isAnySet()`` to inspect Python objects:

```swift
if try await object.isAnySet() {
    let count = try await object.setCount()
    print(count)
}
```

`isSet()` is true only for mutable Python sets. `isFrozenSet()` is true only for Python frozensets. `isAnySet()` is true for either type.

Use the safe equivalents inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let set = try context.convertToSafePython(set: Set([1, 2, 3]))
    if try set.isAnySet {
        print(try set.setCount)
    }
}
```

## Reading Sets As Swift Arrays

Use ``PythonObject/asSetArray()`` when you want an eager Swift array of ``PythonObject`` values:

```swift
let elements = try await set.asSetArray()
for element in elements {
    print(try await Int(element))
}
```

Use ``PythonInterpreter/SafePythonObject/setArray`` inside an isolated context:

```swift
try await interpreter.withIsolatedContext { context in
    let set = try context.convertToSafePython(set: Set([1, 2, 3]))
    let elements = try set.setArray
    print(elements.count)
}
```

Python sets are unordered. The returned Swift array uses Python's current set iteration order. Do not rely on the order unless the Python object itself provides stable ordering through some other contract.

## Membership And Mutation

Use ``PythonObject/setContains(_:)`` for membership checks on either `set` or `frozenset`:

```swift
if try await set.setContains("name") {
    print("present")
}
```

Use ``PythonObject/setAdd(_:)``, ``PythonObject/setRemove(_:)``, and ``PythonObject/setDiscard(_:)`` for mutable Python sets:

```swift
try await set.setAdd(4)
try await set.setDiscard(99)   // no error if absent
try await set.setRemove(4)     // Python raises if absent
```

The same helpers are available on `SafePythonObject` inside an isolated context:

```swift
try await interpreter.withIsolatedContext { context in
    let set = try context.convertToSafePython(set: Set([1, 2, 3]))

    if try set.setContains(2) {
        try set.setRemove(2)
    }
    try set.setAdd(4)
}
```

Mutation helpers validate that the object is a mutable Python `set`. They throw ``PythonError/setConversionFailed(expected:actual:)`` for `frozenset`.

## Calling Python Set Methods

Swift2Python does not wrap every Python set method. Call Python methods directly when you need Python-native behavior:

```swift
let union = try await set.union(other)
let intersection = try await set.intersection(other)
let difference = try await set.difference(other)
let symmetricDifference = try await set.symmetric_difference(other)

let popped = try await set.pop()
try await set.update([4, 5])
try await set.clear()
let copy = try await set.copy()
```

Use Python predicate methods directly as well:

```swift
let subset = try await smaller.issubset(set)
let superset = try await set.issuperset(smaller)
let disjoint = try await set.isdisjoint(other)
```

Inside an isolated context, call the same Python methods on `SafePythonObject`:

```swift
try await interpreter.withIsolatedContext { context in
    let set = try context.convertToSafePython(set: Set([1, 2, 3]))
    let other = try context.convertToSafePython(set: Set([3, 4]))

    let union = try set.union(other)
    let popped = try set.pop()
    print(union, popped)
}
```

If a Python method name is missing or Python raises, async calls throw ``PythonError/pythonException(_:info:)`` and safe calls throw ``PythonError/safePythonException(_:info:)``. For safe code that may access a missing attribute, prefer the explicit throwing ``PythonInterpreter/SafePythonObject/get(attr:)`` API over dynamic-member syntax so the error is recoverable.

## Frozenset Behavior

`frozenset` supports membership, count, array conversion, and non-mutating Python methods such as `union`, `intersection`, `difference`, `symmetric_difference`, `issubset`, `issuperset`, and `isdisjoint`.

It does not support mutation:

```swift
let frozenSet = try await interpreter.convertToPython(frozenSet: Set([1, 2, 3]))

try await frozenSet.setContains(2)   // OK
try await frozenSet.setAdd(4)        // throws setConversionFailed
```

Python methods that do not exist on `frozenset`, such as `pop`, raise Python exceptions if you call or access them.

## Error Behavior

Set helpers throw ``PythonError/setConversionFailed(expected:actual:)`` when the target object is not a Python `set` or `frozenset`, or when a mutation helper is used on a `frozenset`.

`setRemove` follows Python `set.remove` semantics and throws a Python exception when the item is missing. `setDiscard` follows Python `set.discard` semantics and does not throw for missing items.

Python-level failures, such as popping from an empty set, are surfaced as Python exceptions. Async APIs throw ``PythonError/pythonException(_:info:)``. Safe APIs throw ``PythonError/safePythonException(_:info:)``.

## Choosing An API

- Use ``PythonInterpreter/convertToPython(set:)`` to create mutable Python sets from Swift sets.
- Use ``PythonInterpreter/convertToPython(frozenSet:)`` to create Python frozensets from Swift sets.
- Use ``PythonObject/isAnySet()`` and ``PythonObject/setCount()`` when either `set` or `frozenset` is acceptable.
- Use ``PythonObject/asSetArray()`` when you want an eager Swift array of Python objects.
- Use ``PythonObject/setContains(_:)`` for membership checks.
- Use ``PythonObject/setAdd(_:)``, ``PythonObject/setRemove(_:)``, and ``PythonObject/setDiscard(_:)`` only for mutable sets.
- Use Python methods directly for set algebra and less-common set operations.
- Use safe set APIs only inside `withIsolatedContext`.
