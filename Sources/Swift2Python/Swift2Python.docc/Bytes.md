# Bytes

Create Python `bytes` and `bytearray` objects from Swift, inspect byte objects, and copy byte buffers back into Swift.

## Overview

Python `bytes` are immutable binary sequences. Python `bytearray` objects are mutable binary sequences. Swift2Python exposes bytes support in two styles:

- Use ``PythonObject`` methods from async Swift code.
- Use ``PythonInterpreter/SafePythonObject`` properties and methods inside `withIsolatedContext` when you need synchronous access.

Use explicit bytes APIs when Swift binary data should become Python binary data. A Swift `[UInt8]` still follows the normal Swift array rule and converts to a Python list unless you call a `bytes:` or `byteArray:` overload.

## Creating Python Bytes

Create immutable Python `bytes` from Swift bytes with ``PythonInterpreter/convertToPython(bytes:)``:

```swift
let bytes = try await interpreter.convertToPython(bytes: [0, 1, 2, 255])
```

Create Python `bytes` from `Data` with the same label:

```swift
let data = Data("hello".utf8)
let bytes = try await interpreter.convertToPython(bytes: data)
```

`Data` conforms to ``PendingPythonConvertible`` and converts to Python `bytes` automatically:

```swift
let data = Data([1, 2, 3])
let bytes = try await data.toPythonObject(interpreter: interpreter)
_ = try await pythonFunction(data)
```

Inside an isolated context, create safe Python `bytes` with ``PythonInterpreter/convertToSafePython(bytes:)``:

```swift
try await interpreter.withIsolatedContext { context in
    let bytes = try context.convertToSafePython(bytes: [1, 2, 3])
    print(try bytes.bytesSize)
}
```

`Data` also conforms to ``SafePythonConvertible``:

```swift
try await interpreter.withIsolatedContext { context in
    let data = Data([1, 2, 3])
    let bytes = try data.toSafePythonObject(interpreter: context)
    print(try bytes.bytesSize)
}
```

## Creating Python Bytearrays

Create mutable Python `bytearray` objects with ``PythonInterpreter/convertToPython(byteArray:)``:

```swift
let byteArray = try await interpreter.convertToPython(byteArray: [10, 20, 30])
```

`Data` can also be copied into a `bytearray`:

```swift
let byteArray = try await interpreter.convertToPython(byteArray: Data([10, 20, 30]))
```

Inside an isolated context, use ``PythonInterpreter/convertToSafePython(byteArray:)``:

```swift
try await interpreter.withIsolatedContext { context in
    let byteArray = try context.convertToSafePython(byteArray: [10, 20, 30])
    print(try byteArray.byteArraySize)
}
```

## Data Versus Byte Arrays

Swift2Python intentionally treats `Data` and `[UInt8]` differently by default:

```swift
let data = Data([1, 2, 3])
let pyBytes = try await data.toPythonObject(interpreter: interpreter) // Python bytes

let array = [UInt8(1), UInt8(2), UInt8(3)]
let pyList = try await array.toPythonObject(interpreter: interpreter) // Python list
```

Use explicit labels when `[UInt8]` represents binary data:

```swift
let pyBytes = try await interpreter.convertToPython(bytes: array)
let pyByteArray = try await interpreter.convertToPython(byteArray: array)
```

This keeps normal Swift arrays predictable while still making binary conversions explicit.

## Checking And Counting

Use ``PythonObject/isBytes()`` and ``PythonObject/isByteArray()`` to check concrete Python byte types:

```swift
if try await object.isBytes() {
    let count = try await object.bytesSize()
    print(count)
}

if try await object.isByteArray() {
    let count = try await object.byteArraySize()
    print(count)
}
```

Use ``PythonObject/isBytesLike()`` when you only need to know whether the object supports Python's readable buffer protocol:

```swift
if try await object.isBytesLike() {
    let data = try await object.asCopiedData()
    print(data.count)
}
```

`isBytesLike()` returns true for `bytes`, `bytearray`, `memoryview`, and other readable buffer-protocol objects.

Use safe equivalents inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let bytes = try context.convertToSafePython(bytes: [1, 2, 3])

    if try bytes.isBytes {
        print(try bytes.bytesSize)
    }
}
```


## Copying Bytes To Swift

Use ``PythonObject/asCopiedData()`` when you want `Data`:

```swift
let data = try await bytes.asCopiedData()
```

Use ``PythonObject/asCopiedBytes()`` when you want `[UInt8]`:

```swift
let values = try await bytes.asCopiedBytes()
```

Use ``PythonObject/asCopiedString(encoding:)`` when the bytes contain text:

```swift
let string = try await bytes.asCopiedString()
```

The safe APIs have the same names inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let bytes = try context.convertToSafePython(bytes: Data("hello".utf8))

    let data = try bytes.asCopiedData()
    let values = try bytes.asCopiedBytes()
    let string = try bytes.asCopiedString()

    print(data, values, string)
}
```

Use ``PythonObject/withUnsafeBytes(_:)`` or ``PythonInterpreter/SafePythonObject/withUnsafeBytes(_:)`` when you need temporary zero-copy access to the Python buffer:

```swift
let checksum = try await bytes.withUnsafeBytes { buffer in
    buffer.reduce(0) { $0 + Int($1) }
}
```

The buffer pointer is valid only for the duration of the closure. Copy the bytes out with `asCopiedData()` or `asCopiedBytes()` when you need to keep them.

## Mutating Bytearrays

Swift2Python does not wrap every Python `bytearray` method. Call Python methods directly:

```swift
let byteArray = try await interpreter.convertToPython(byteArray: [1, 2, 3])

try await byteArray.append(4)
try await byteArray.extend([5, 6])
let popped = try await byteArray.pop()
try await byteArray.reverse()
try await byteArray.clear()
```

Python `bytes` are immutable. Mutating methods such as `append` exist on `bytearray`, not on `bytes`.

## Buffer Protocol Objects

Python objects such as `memoryview` can be bytes-like without being concrete `bytes` or `bytearray` objects:

```swift
let bytes = try await interpreter.convertToPython(bytes: [1, 2, 3])
let memoryView = try await interpreter.builtins.memoryview(bytes)

print(try await memoryView.isBytes())      // false
print(try await memoryView.isByteArray())  // false
print(try await memoryView.isBytesLike())  // true

let copied = try await memoryView.asCopiedBytes()
```

Use `isBytesLike()` and copy APIs when accepting any readable buffer. Use `isBytes()` or `isByteArray()` when the exact Python type matters.

## Error Behavior

Bytes helpers throw ``PythonError/bytesConversionFailed(expected:actual:)`` when the target object does not have the expected byte shape:

```swift
let count = try await object.bytesSize()       // requires bytes
let count = try await object.byteArraySize()   // requires bytearray
let data = try await object.asCopiedData()     // requires bytes-like object
```

`withUnsafeBytes` and the copied extraction helpers require a bytes-like object. If the object does not support Python's readable buffer protocol, they throw `bytesConversionFailed`.

String decoding also throws `bytesConversionFailed` when the bytes cannot be decoded with the requested encoding:

```swift
let text = try await bytes.asCopiedString(encoding: .utf8)
```

Python-level failures still throw Python exceptions. Async APIs throw `PythonError.pythonException`; safe APIs throw `PythonError.safePythonException`.

## Choosing An API

- Use ``PythonInterpreter/convertToPython(bytes:)`` for immutable Python `bytes`.
- Use ``PythonInterpreter/convertToPython(byteArray:)`` for mutable Python `bytearray`.
- Use `Data` when binary data should automatically convert to Python `bytes` through Swift2Python conversion protocols.
- Use explicit `bytes:` or `byteArray:` labels for `[UInt8]` binary data.
- Use ``PythonObject/asCopiedData()`` or ``PythonObject/asCopiedBytes()`` to copy Python byte buffers into Swift.
- Use ``PythonObject/withUnsafeBytes(_:)`` only for temporary access during the closure.
- Use safe bytes APIs only inside `withIsolatedContext`.
