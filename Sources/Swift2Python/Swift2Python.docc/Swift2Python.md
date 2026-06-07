# ``Swift2Python``

Call Python from Swift with async APIs, synchronous isolated access, and Swift-friendly wrappers around common Python objects.

## Overview

Swift2Python provides a Swift interface for working with Python values through ``PythonInterpreter``, ``PythonObject``, and ``PythonInterpreter/SafePythonObject``.

Use the async APIs for normal Swift concurrency code. Use safe objects inside an isolated context when you need synchronous access while the interpreter owns the Python thread state.

## Topics

### Containers

- <doc:Tuples>
- <doc:Dictionaries>
- <doc:Lists>
