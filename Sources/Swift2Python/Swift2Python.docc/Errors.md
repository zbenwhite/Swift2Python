# Error Handling

Understand Python exceptions, Swift conversion errors, and isolated-context error boundaries.

## Overview

Swift2Python reports failures through ``PythonError``. Errors that come from Python itself are preserved as Python exceptions, including the Python exception type, message, traceback, chained exceptions, implicit exception context, and Python exception notes when the running Python version supports them.

Use ``PythonError/pythonException(_:info:)`` in normal async ``PythonObject`` code. Use ``PythonError/safePythonException(_:info:)`` only inside `withIsolatedContext`, where ``PythonInterpreter/SafePythonObject`` values are valid.

## Reading Python Exception Details

Every Python exception wrapper includes ``PythonExceptionInfo``. The `info` value is a stable Swift snapshot captured while Swift2Python still has access to the Python exception under the GIL.

```swift
do {
    let globals = try await interpreter.getGlobals()
    let function = try await globals.getItem(key: "load_config")
    _ = try await function("missing.toml")
} catch let error as PythonError {
    if let info = error.pythonExceptionInfo {
        print(info.typeName)
        print(info.message)
        print(info.formatted)
    } else {
        print(error.localizedDescription)
    }
}
```

`info.formatted` is also used by `PythonError.description` and `localizedDescription`, so printing the error is usually enough for diagnostics:

```swift
do {
    _ = try await object.read()
} catch {
    print(error.localizedDescription)
}
```

## Tracebacks

Swift2Python formats tracebacks with Python's own `traceback.format_exception` behavior. That means the formatted text follows Python's standard output, including the original stack frames and final exception line:

```text
Python exception: ValueError: deep failure
Traceback (most recent call last):
  File "<string>", line 5, in outer
  File "<string>", line 2, in inner
ValueError: deep failure
```

The leading `Python exception:` line is Swift2Python's compact headline. The traceback text below it is Python-formatted text.

## Chained Exceptions

Python can attach another exception as the direct cause or implicit context of the current exception. Swift2Python preserves that chain in ``PythonExceptionInfo/traceback`` and ``PythonExceptionInfo/formatted``.

For explicit causes, Python code such as this:

```python
try:
    raise KeyError("root failure")
except KeyError as error:
    raise RuntimeError("wrapped failure") from error
```

formats with Python's standard cause text:

```text
KeyError: 'root failure'

The above exception was the direct cause of the following exception:

RuntimeError: wrapped failure
```

Implicit context is preserved too, including Python's `During handling of the above exception, another exception occurred:` text. Exception notes added with `BaseException.add_note` are included when supported by the running Python version.

## SafePythonObject Exceptions

``PythonInterpreter/SafePythonObject`` exists for synchronous work inside `withIsolatedContext`. Inside that closure, Python exceptions are thrown as ``PythonError/safePythonException(_:info:)`` so you can catch and handle them before leaving the isolated context:

```swift
try await interpreter.withIsolatedContext { context in
    do {
        let config = context.globals["config"]
        _ = try config.get(attr: "missing")
    } catch let PythonError.safePythonException(_, info) {
        print(info.formatted)
    }
}
```

If a safe Python exception escapes the closure, Swift2Python converts it to ``PythonError/pythonException(_:info:)`` automatically. This keeps the thrown error usable outside the isolated context while preserving the same ``PythonExceptionInfo``:

```swift
do {
    try await interpreter.withIsolatedContext { context in
        let config = context.globals["config"]
        _ = try config.get(attr: "missing")
    }
} catch let PythonError.pythonException(_, info) {
    print(info.formatted)
}
```

Do not store or return ``PythonInterpreter/SafePythonObject`` values for use outside `withIsolatedContext`. Convert values to ``PythonObject`` or Swift values before leaving the closure.

## Swift2Python Validation Errors

Not every ``PythonError`` is a Python exception. Swift2Python also throws validation and conversion errors before or after calling Python, such as ``PythonError/valueError(_:)``, ``PythonError/typeError(operation:opType1:opType2:)``, ``PythonError/tupleArityMismatch(expected:actual:)``, and collection conversion failures.

These errors do not have ``PythonExceptionInfo`` because they are Swift2Python diagnostics, not Python-raised exceptions. Use `pythonExceptionInfo` when you specifically need Python traceback details, and use `localizedDescription` for general error reporting.

## Choosing An Error API

- Use `catch let error as PythonError` when you need Swift2Python-specific handling.
- Use `error.pythonExceptionInfo` when Python traceback details matter.
- Use ``PythonError/pythonException(_:info:)`` for exceptions caught outside isolated contexts.
- Use ``PythonError/safePythonException(_:info:)`` only inside `withIsolatedContext`.
- Use explicit throwing safe APIs, such as ``PythonInterpreter/SafePythonObject/get(attr:)``, when a safe operation may fail recoverably.
- Avoid non-throwing safe dynamic-member properties and operators in examples that demonstrate error handling; those APIs trap when failure is treated as a programmer error.
