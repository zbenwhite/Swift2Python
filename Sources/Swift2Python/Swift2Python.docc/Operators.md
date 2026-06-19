# Operators

Use Swift2Python operators when you want Python-style arithmetic, bitwise, or comparison behavior in Swift.

## Overview

Swift2Python provides three ways to perform Python operations:

- Use `SafePythonObject` operators inside `withIsolatedContext` when the operation is expected to succeed and trapping on failure is acceptable.
- Use throwing `SafePythonObject` methods inside `withIsolatedContext` when type errors, Python exceptions, overflow, or conversion failures should be handled.
- Use async `PythonObject` methods in normal Swift concurrency code.

The operators are convenient, but they are intentionally non-throwing. If Python raises or Swift2Python cannot represent a fully deferred result, an operator traps with `fatalError`. Prefer the throwing method form whenever failure is part of normal control flow.

## Safe Operators

`SafePythonObject` operators are available inside `withIsolatedContext`:

```swift
try await interpreter.withIsolatedContext { context in
    let a = try context.convertToSafePython(10)
    let b = try context.convertToSafePython(3)

    let sum = a + b
    let difference = a - b
    let product = a * b
    let quotient = a / b
    let remainder = a % b
    let power = a ** b

    let isGreater = a > b
    let isEqual = a == b

    print(try Int(sum), isGreater, try Int(power))
}
```

Arithmetic operators:

- `+`, `+=`
- `-`, `-=`
- `*`, `*=`
- `/`, `/=`
- `%`, `%=`
- `**`, `**=`
- unary `+`
- unary `-`
- `abs(_:)`

Bitwise operators:

- `&`, `&=`
- `|`, `|=`
- `^`, `^=`
- `~`
- `<<`, `<<=`
- `>>`, `>>=`

Comparison operators:

- `==`
- `!=`
- `<`
- `<=`
- `>`
- `>=`

Comparison operators return Swift `Bool` in normal Swift comparison contexts. They can also produce Python bool objects when the result is assigned as `SafePythonObject`:

```swift
try await interpreter.withIsolatedContext { context in
    let lhs: PythonInterpreter.SafePythonObject = 4
    let rhs: PythonInterpreter.SafePythonObject = 9

    let swiftBool: Bool = lhs < rhs
    let pythonBool: PythonInterpreter.SafePythonObject = lhs < rhs

    print(swiftBool, try Bool(pythonBool))
}
```

## Throwing Safe Methods

Use throwing methods when the operation can fail and the caller should handle that failure. These methods preserve Python semantics for bound Python objects and provide Swift errors for fully deferred values that cannot be evaluated locally.

```swift
try await interpreter.withIsolatedContext { context in
    let a: PythonInterpreter.SafePythonObject = 10
    let b: PythonInterpreter.SafePythonObject = 0

    do {
        let result = try a.divide(divisor: b)
        print(try Double(result))
    } catch {
        print("Python division failed: \(error)")
    }
}
```

Throwing arithmetic methods:

- `positive()` for unary `+`
- `negative()` for unary `-`
- `absolute()` for `abs(_:)`
- `add(_:)`
- `subtract(subtrahend:)`
- `multiply(_:)`
- `divide(divisor:)`
- `modulus(divisor:)`
- `power(exponent:)`

Throwing bitwise methods:

- `bitwiseAnd(_:)`
- `bitwiseOr(_:)`
- `bitwiseXor(_:)`
- `bitwiseInvert()`
- `bitShiftLeft(_:)`
- `bitShiftRight(_:)`

Throwing comparison methods that return Swift `Bool`:

- `equal(_:)`
- `notEqual(_:)`
- `lessThan(_:)`
- `lessThanOrEqual(_:)`
- `greaterThan(_:)`
- `greaterThanOrEqual(_:)`

Raw Python comparison result methods:

- `equalPython(_:)`
- `notEqualPython(_:)`
- `lessThanPython(_:)`
- `lessThanOrEqualPython(_:)`
- `greaterThanPython(_:)`
- `greaterThanOrEqualPython(_:)`

Prefer the `Bool` methods for normal comparisons. Use the `*Python` methods only when you intentionally need Python's raw rich-comparison result as a `SafePythonObject`, such as when a custom Python `__lt__`, `__eq__`, or related method may return a non-`bool` object.

## Async PythonObject Methods

Use `PythonObject` methods in normal async Swift code. These methods are throwing and do not require `withIsolatedContext`.

```swift
let a = try await interpreter.convertToPython(10)
let b = try await interpreter.convertToPython(3)

let sum = try await a.add(b)
let quotient = try await a.divide(b)
let isGreater = try await a.greaterThan(b)

print(try await Int(sum), try await Double(quotient), isGreater)
```

Async arithmetic methods:

- `absolute()`
- `positive()`
- `negative()`
- `add(_:)`, `addInPlace(_:)`
- `subtract(_:)`, `subtractInPlace(_:)`
- `multiply(_:)`, `multiplyInPlace(_:)`
- `divide(_:)`, `divideInPlace(_:)`
- `modulus(_:)`, `modulusInPlace(_:)`
- `power(_:)`, `powerInPlace(_:)`

Async bitwise methods:

- `bitwiseAnd(_:)`, `bitwiseAndInPlace(_:)`
- `bitwiseOr(_:)`, `bitwiseOrInPlace(_:)`
- `bitwiseXor(_:)`, `bitwiseXorInPlace(_:)`
- `bitwiseInvert()`
- `bitShiftLeft(_:)`, `bitShiftLeftInPlace(_:)`
- `bitShiftRight(_:)`, `bitShiftRightInPlace(_:)`

Async comparison methods return Swift `Bool`:

- `equal(_:)`
- `notEqual(_:)`
- `lessThan(_:)`
- `lessThanOrEqual(_:)`
- `greaterThan(_:)`
- `greaterThanOrEqual(_:)`

## Choosing An API

Use this rule of thumb:

```swift
// Normal async code
let result = try await pythonObject.add(3)

// Synchronous isolated code, failure handled
let safeResult = try safeObject.add(3)

// Synchronous isolated code, failure is programmer error
let convenient = safeObject + 3
```

Operators are best for short, local expressions where the operand types are known. Throwing methods are best for library code, user input, mixed Python values, and any place where Python exceptions should be reported instead of trapping. Async `PythonObject` methods are best outside `withIsolatedContext`.

## Deferred Safe Values

`SafePythonObject` can hold fully deferred Swift-backed primitive values such as integers, doubles, strings, and bools before they are bound to a Python interpreter. Operators and throwing safe methods support these values when Swift2Python can preserve Python-compatible behavior locally.

Some Python behaviors cannot be represented as deferred Swift values. For example, integer overflow, negative shift counts, invalid bitwise operands, division by zero, and invalid ordering comparisons throw from the method APIs. The matching operators trap because Swift operators cannot throw.

When in doubt, use the throwing method first. Convert to operators after the valid operand types are clear.
