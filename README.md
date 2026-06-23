#  Swift2Python

Swift2Python is meant to be a modern Swift replacement for PythonKit.  

It works with Swift Concurrency so you can just interact with Python using await.  It uses only the stable ABI 
so it should be forward compatible with future Python and should be backward compatible to Python 3.9 or earlier.
It also manages the GIL internally so you don't have to worry about the GIL at all.  The idea is that it should 
work with free threaded Python, but that's not tested at all yet.

## Narrative

I was doing some projects, partly to learn Swift.  I tried to use Swift together with Python.  It was suggested to
me to use PythonKit.  But PythonKit doesn't "just work".  PythonKit was written before Swift Concurrency.  And 
PythonKit uses a couple old Python APIs that were removed from more recent Python.  PythonKit needed an update.

So I asked AIs about updating PythonKit to work with Swift Concurrency.  They said it would be too hard.  Then
I asked about designing a replacement for PythonKit created with concurrent access in mind.  They said it would be 
a good project and wouldn't even take very long.  So I did it.  It took a lot longer than they said.  Here it is.

This is my first Swift project and my first public software release.  Codex wrote a lot of the code and almost all 
of the documentation.  If something looks like I don't know what I'm doing, that intuition may be correct.

## Documentation

- Operators, throwing alternatives, and async alternatives are documented in the DocC page `Operators`.
- AI/code-generation guidance is documented in `docs/AI_USAGE.md`.

