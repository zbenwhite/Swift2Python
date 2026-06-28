# Getting Started

Add Swift2Python to a Swift package, choose a Python runtime, and call Python from Swift.

## Add Swift2Python To Your Package

Add Swift2Python as a package dependency:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyPackage",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/your-org/Swift2Python.git", from: "v0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "MyTool",
            dependencies: [
                .product(name: "Swift2Python", package: "Swift2Python")
            ]
        )
    ]
)
```

Replace the repository URL and version with the release you are using.

## Choose A Python Runtime

Swift2Python loads CPython dynamically. On common macOS Python installs, automatic discovery is usually enough.

If Swift2Python cannot find libpython, set environment variable `SWIFT2PYTHON_LIBRARY` before running your Swift program:

```sh
export SWIFT2PYTHON_LIBRARY=/opt/homebrew/opt/python@3.13/lib/libpython3.13.dylib
```

The value must point to the libpython shared library, not the `python` executable. See <doc:RuntimeConfiguration> for detailed runtime configuration.

## Create An Interpreter

Use the shared runtime to get the default interpreter:

```swift
import Swift2Python

let python = try await PythonRuntime.shared.interpreter()
```

This initializes Python if needed and returns the cached default ``PythonInterpreter`` actor.

## Import And Call Python

Use async APIs for normal Swift concurrency code:

```swift
import Swift2Python

@main
struct MyTool {
    static func main() async throws {
        let python = try await PythonRuntime.shared.interpreter()

        let math = try await python.import("math")
        let value = try await math.sqrt(9)

        print(try await Double(value))
    }
}
```

Python values are represented as ``PythonObject``. Convert them back to Swift with Swift initializers:

```swift
let builtins = try await python.getBuiltins()
let text = try await builtins.str(value)
print(try await String(text))
```

## Use Local Python Modules

If your project imports local Python files, add their directory to `SWIFT2PYTHON_PYTHONPATH` before the runtime initializes:

```sh
export SWIFT2PYTHON_PYTHONPATH=/path/to/my/python/modules
```

Then import them normally:

```swift
let module = try await python.import("my_module")
let result = try await module.some_function("input")
```

Third-party packages must be installed into the Python environment selected by Swift2Python.

## Handle Python Errors

Python exceptions are thrown as ``PythonError``. The error preserves Python traceback text:

```swift
do {
    let json = try await python.import("json")
    _ = try await json.loads("{")
} catch let error as PythonError {
    print(error.localizedDescription)
}
```

For Python-raised errors, ``PythonError/pythonExceptionInfo`` contains structured exception details and formatted traceback text.

## Use An Isolated Context For Synchronous Code

Use `withIsolatedContext` when you want concise synchronous access to Python values inside one interpreter-owned closure:

```swift
try await python.withIsolatedContext { context in
    let math = try context.import("math")
    let value = try math.sqrt(16)
    print(try Double(value))
}
```

Inside the isolated context, values are ``PythonInterpreter/SafePythonObject``. Prefer explicit throwing methods when failures should be recoverable. Convenience syntax such as dynamic members, operators, and subscripts can trap if Python raises.

If you already have an async ``PythonObject`` and need to use it inside an isolated context, bind it to the context first:

```swift
let types = try await python.import("types")
let object = try await types.SimpleNamespace()

try await python.withIsolatedContext { context in
    let safeObject = try context.bind(pythonObject: object)
    safeObject.name = "Ada"
    print(try String(safeObject.name))
}
```

``PythonInterpreter/bind(pythonObject:)`` throws if the object belongs to a different ``PythonInterpreter``. Do not store ``PythonInterpreter/SafePythonObject`` values after the isolated closure returns.

When an isolated-context result needs to remain a Python value after the closure exits, use ``PythonInterpreter/escapeFromIsolation(forSafeObj:)`` to copy the safe object into an async ``PythonObject``:

```swift
let names = try await python.withIsolatedContext { context in
    let builtins = context.builtins
    let safeNames = try builtins.list(["Ada", "Grace", "Katherine"])
    return context.escapeFromIsolation(forSafeObj: safeNames)
}

print(try await names.listCount())
```

The returned ``PythonObject`` owns its own Python reference. The original ``PythonInterpreter/SafePythonObject`` remains usable until the isolated closure exits, and is cleaned up with the rest of the isolated context.

## Platform And Version Status

The current release is developed and tested on macOS with current GIL-enabled Python. Swift2Python is intended to be capable of running on Linux and iOS, with free-threaded Python, and with older supported Python versions, but those combinations are not tested yet.
