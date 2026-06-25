# Runtime Configuration

Choose which Python runtime Swift2Python loads and which Python module paths are visible during initialization.

## Overview

Swift2Python loads CPython dynamically. By default, it searches common libpython locations such as Homebrew Python framework and library paths, uv-managed Python installations, framework installs, and common Linux distribution and source-install library directories.

For normal use, ask the shared runtime for its default interpreter:

```swift
let python = try await PythonRuntime.shared.interpreter()
```

That call initializes the runtime if needed and returns the cached default ``PythonInterpreter`` actor. For repeatable applications and CI, configure the runtime explicitly before the first call to ``PythonRuntime/interpreter(libraryPath:)`` or ``PythonRuntime/initialize(libraryPath:)``.

## Selecting libpython

The most explicit option is to pass the shared library path when requesting the default interpreter:

```swift
let python = try await PythonRuntime.shared.interpreter(
    libraryPath: "/opt/homebrew/opt/python@3.13/lib/libpython3.13.dylib"
)
```

You can also pass the shared library path to initialization:

```swift
try await PythonRuntime.shared.initialize(
    libraryPath: "/opt/homebrew/opt/python@3.13/lib/libpython3.13.dylib"
)
```

The path must point to the libpython shared library, not the `python` executable.

You can also set environmet variable `SWIFT2PYTHON_LIBRARY` before launching the Swift process:

```sh
export SWIFT2PYTHON_LIBRARY=/opt/homebrew/opt/python@3.13/lib/libpython3.13.dylib
```

Library selection uses this precedence:

1. The explicit `libraryPath` argument.
2. environmet variable `SWIFT2PYTHON_LIBRARY`.
3. Swift2Python's built-in search paths.

Swift2Python expands wildcard path components before attempting to load a library. This lets built-in candidates find versioned Homebrew Cellar installs and Linux multi-architecture library directories such as `/usr/lib/x86_64-linux-gnu`.

## Setting Python Module Paths

Set environmet variable `SWIFT2PYTHON_PYTHONPATH` when your embedded Python code needs project-local modules or vendored packages:

```sh
export SWIFT2PYTHON_PYTHONPATH=/path/to/project/python:/path/to/project/vendor
```

Swift2Python copies this value to environmet variable `PYTHONPATH` immediately before `Py_Initialize()`. Use the same path separator Python expects on the target platform.

## Initialization Timing

Python runtime configuration must be set before the first successful initialization. After CPython is initialized, changing environmet variables `SWIFT2PYTHON_LIBRARY`, `SWIFT2PYTHON_PYTHONPATH`, or `PYTHONPATH` does not reload the runtime.

For tests and command-line tools, configure the environment before requesting the default interpreter or calling `PythonRuntime.shared.initialize()`.
