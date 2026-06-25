# Roadmap

Swift2Python 1.0 focuses on a stable core bridge for Python objects, conversions, containers, operators, error handling, item access, slicing, and runtime configuration.

This document is for intentionally deferred work and validation targets. It is not a complete issue tracker and should not collect every local implementation note.

## Deferred From 1.0

### Date and Time Conversions

Swift `Date` and Python `datetime` do not map cleanly without choosing policies for time zones, naive datetimes, calendar-only dates, time-only values, and precision. A future release may add explicit UTC `Date` <-> timezone-aware `datetime.datetime` conversion after those policies are documented and tested.

### Complex Numbers

Python has a native complex number type. Swift does not provide a standard-library complex type, so support should wait until Swift2Python has a clear target Swift representation and conversion policy.

### NumPy Conversions

NumPy conversion support is useful, but it is outside the core CPython bridge. A future release may add opt-in support for arrays and scalar values after the base package API is stable.

### Broader Platform Validation

Swift2Python is intended to be capable of running anywhere Swift and CPython are available, including Linux and iOS, but 1.0 validation is focused on macOS. Linux and iOS should be tested before claiming full platform support.

### Python Version Validation

Swift2Python uses the CPython stable ABI where practical and is intended to work across supported Python versions. Older Python versions and free-threaded Python still need explicit validation before they are described as tested configurations.

### Multiple Interpreter Strategy

`PythonRuntime.shared.interpreter()` provides the default interpreter for normal use. Future free-threaded Python support may need a documented strategy for multiple interpreters, interpreter ownership, and object isolation between interpreters.
