# Iteration

Iterate Python containers, views, ranges, generators, and custom iterables from Swift.

## Overview

Swift2Python exposes Python's iterator protocol in two forms:

- Use ``PythonObject`` as an `AsyncSequence` in normal Swift concurrency code.
- Use ``PythonInterpreter/SafePythonObject`` as a synchronous `Sequence` inside ``PythonInterpreter/withIsolatedContext(_:)``.

`PythonObject` does not conform to Swift `Sequence` because creating and advancing a Python iterator can require async interpreter work. Use `for try await` for async Python objects. Use safe synchronous iteration only while the interpreter is isolated.

Iteration follows Python semantics: normal `StopIteration` becomes `nil` and ends the Swift loop. Other Python exceptions are thrown from async iteration or from the throwing safe iterator APIs.

## Async PythonObject Iteration

Use `for try await` with any Python iterable:

```swift
let list = try await interpreter.convertToPython(array: [1, 2, 3])

for try await item in list {
    print(try await Int(item))
}
```

This works for Python lists, tuples, sets, dictionaries, dictionary views, ranges, generators, existing Python iterators, and custom iterable classes.

```swift
let range = try await interpreter.builtins.range(4)

var values: [Int] = []
for try await item in range {
    values.append(try await Int(item))
}

print(values) // [0, 1, 2, 3]
```

Use direct async iteration when you do not need to materialize every item up front. Use helpers such as ``PythonObject/asArray()``, ``PythonObject/dictKeys()``, ``PythonObject/dictValues()``, or ``PythonObject/dictItems()`` when you intentionally want eager Swift arrays.

## Dictionary Views

Python dictionary methods such as `keys()`, `values()`, and `items()` return Python view objects. Those views are iterable:

```swift
let dict = try await interpreter.convertToPython(dictionary: [
    "one": 1,
    "two": 2
])

let keys = try await dict.keys()
for try await key in keys {
    print(try await String(key))
}

let items = try await dict.items()
for try await item in items {
    let key = try await String(item.getItem(key: 0))
    let value = try await Int(item.getItem(key: 1))
    print(key, value)
}
```

For async dictionary items, Python yields 2-item Python tuples. Use tuple item access or `dictItems()` depending on whether you want lazy iteration or an eager Swift array of `(key, value)` pairs.

## Async Error Handling

Async iteration throws if Python refuses to create an iterator or if `__next__` raises an exception other than normal `StopIteration`:

```swift
do {
    for try await item in object {
        print(item)
    }
} catch {
    print("Python iteration failed: \(error)")
}
```

You can also work with the async iterator directly:

```swift
var iterator = object.makeAsyncIterator()
while let item = try await iterator.next() {
    print(item)
}
```

The first call to `next()` creates the underlying Python iterator. That call can throw if the source object is not iterable.

## SafePythonObject Iteration

Inside `withIsolatedContext`, `SafePythonObject` supports Swift `for`-`in`:

```swift
try await interpreter.withIsolatedContext { context in
    let list = try context.convertToSafePython(array: [1, 2, 3])

    for item in list {
        print(try Int(item))
    }
}
```

Use this only inside the isolated context. Safe iteration is synchronous because the interpreter already owns the Python thread state in that scope.

## Throwing Safe Iterators

Swift `Sequence` and `IteratorProtocol` cannot throw from `makeIterator()` or `next()`. For recoverable Python errors, use ``PythonInterpreter/SafePythonObject/pythonIterator()`` and `nextThrowing()` instead of plain `for`-`in`:

```swift
try await interpreter.withIsolatedContext { context in
    let iterable = try context.convertToSafePython(array: [1, 2, 3])
    var iterator = try iterable.pythonIterator()

    while let item = try iterator.nextThrowing() {
        print(try Int(item))
    }
}
```

Use plain `for`-`in` only when iteration failure is a programmer error. If Python raises while creating or advancing the iterator, the non-throwing `Sequence` path traps.

## Safe Dictionary Items

Inside an isolated context, ``PythonInterpreter/SafePythonObject/items()`` returns a Swift sequence over Python `dict.items()` and unwraps each item into a labeled Swift tuple:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: [
        "one": 1,
        "two": 2
    ])

    for pair in dict.items() {
        let key = try String(pair.key)
        let value = try Int(pair.value)
        print(key, value)
    }
}
```

For recoverable errors while advancing the `items()` iterator, use its throwing iterator method:

```swift
try await interpreter.withIsolatedContext { context in
    let dict = try context.convertToSafePython(dictionary: ["one": 1])
    var iterator = dict.items().makeIterator()

    while let pair = try iterator.nextThrowing() {
        print(try String(pair.key), try Int(pair.value))
    }
}
```

Use ``PythonInterpreter/SafePythonObject/dictItems`` when you want an eager Swift array of dictionary items instead of an iterator over Python's `items()` view.

## Choosing An API

Use this rule of thumb:

```swift
// Normal async code
for try await item in pythonObject { }

// Isolated synchronous code, failure is a programmer error
for item in safePythonObject { }

// Isolated synchronous code, failure should be handled
var iterator = try safePythonObject.pythonIterator()
while let item = try iterator.nextThrowing() { }
```

Prefer iteration for ranges, generators, large containers, and dictionary views when you do not need all elements at once. Prefer eager array helpers when the caller needs random access, repeated traversal, or a stable Swift snapshot.