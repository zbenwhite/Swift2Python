# Swift2Python

Swift2Python is meant to be a modern Swift replacement for PythonKit.

It works with Swift Concurrency so you can interact with Python using `await`. It uses only the stable ABI, so the intention is that it should be forward compatible with future Python and backward compatible to Python 3.9 or earlier. It also manages the GIL internally so you do not have to worry about the GIL in normal use.

The current release is developed and tested on macOS with current GIL-enabled Python. The intention is that Swift2Python should be capable of running on Linux and iOS, with free-threaded Python, and with older supported Python versions, but those combinations are not tested yet. For untested platforms or Python installs, use environment variable `SWIFT2PYTHON_LIBRARY` to point Swift2Python at the libpython shared library explicitly.

## Getting Started

Add Swift2Python to your package, import it, and ask the shared runtime for its default interpreter:

```swift
import Swift2Python

let python = try await PythonRuntime.shared.interpreter()
let math = try await python.import("math")
let value = try await math.sqrt(9)
```

If Swift2Python cannot find Python, set environment variable `SWIFT2PYTHON_LIBRARY` to the full path of `libpython`. If you need local Python modules, set environment variable `SWIFT2PYTHON_PYTHONPATH` before startup.

See the DocC page `Getting Started` (`Sources/Swift2Python/Swift2Python.docc/GettingStarted.md`) for the full setup guide.

## Narrative

I was doing some projects, partly to learn Swift. I tried to use Swift together with Python. It was suggested to me to use PythonKit. But PythonKit doesn't "just work". PythonKit was written before Swift Concurrency. And PythonKit uses a couple old Python APIs that were removed from more recent Python. PythonKit needed an update.

So I asked AIs about updating PythonKit to work with Swift Concurrency. They said it would be too hard. Then I asked about designing a replacement for PythonKit created with concurrent access in mind. They said it would be a good project and wouldn't even take very long. So I did it. It took a lot longer than they said. Here it is.

This is my first Swift project and my first public software release. Codex wrote a lot of the code and almost all of the documentation. If something looks like I don't know what I'm doing, that intuition may be correct.

## Documentation

- Runtime configuration is documented in the DocC page `Runtime Configuration`. Set environment variable `SWIFT2PYTHON_LIBRARY` to choose a specific libpython shared library, and set environment variable `SWIFT2PYTHON_PYTHONPATH` to provide Python module search paths before initialization.
- Operators, throwing alternatives, and async alternatives are documented in the DocC page `Operators`.
- AI/code-generation guidance is documented in `docs/AI_USAGE.md`.
