//
//  PythonObjectIdentity.swift
//  Swift2Python
//
//  Created by Ben White on 6/27/26.
//

extension PythonInterpreter {
    /// Actor-bound identity for a Python object managed by Swift2Python.
    ///
    /// `PythonObject` is `Sendable`, but the underlying `PyObject *` is not something
    /// callers should be able to use directly. CPython object pointers only make sense
    /// while the owning `PythonInterpreter` actor is coordinating access, holding the
    /// GIL, and maintaining Swift2Python's bookkeeping reference count. This value is
    /// the compact token a `PythonObject` carries across actor boundaries instead of a
    /// raw pointer.
    ///
    /// The identity has two parts:
    ///
    /// - `interpreterID`: a random per-interpreter value. It lets the actor reject IDs
    ///   created by a different interpreter before attempting to recover a pointer.
    /// - `encodedPointer`: the `PyObject *` address bit pattern XORed with a random
    ///   per-interpreter key.
    ///
    /// The XOR is deliberately reversible. The owning interpreter can recover the exact
    /// pointer with its private key, while other code only sees an opaque integer value
    /// that does not look like a usable CPython pointer. This is not a cryptographic or
    /// sandboxing boundary; it is a fast, mechanical guardrail that keeps the API shape
    /// honest. Swift code can pass identities around, but CPython API calls still funnel
    /// through the interpreter actor.
    ///
    /// This replaces the older "store an ID and look up the pointer" identity scheme for
    /// normal `PythonObject` access. Decoding is constant-time arithmetic with no dictionary
    /// lookup, and the ID itself carries enough information to reject use with the wrong
    /// interpreter. The lifecycle registries still exist, but their job is reference-count
    /// bookkeeping and cleanup rather than being the source of truth for pointer identity.
    public struct PythonObjectUniqueID: Sendable, Hashable, CustomStringConvertible {
        private let interpreterID: UInt64
        private let encodedPointer: UInt
        
        /// Creates an opaque identity from a raw CPython object pointer.
        ///
        /// The caller must be the interpreter that owns `pointer`. Storing the interpreter
        /// ID beside the encoded address makes wrong-interpreter use detectable; encoding
        /// the pointer prevents the public ID from carrying a raw address-shaped value.
        fileprivate init(pointer: UnsafeMutableRawPointer, interpreterID: UInt64, pointerEncodingKey: UInt) {
            self.interpreterID = interpreterID
            self.encodedPointer = UInt(bitPattern: pointer) ^ pointerEncodingKey
        }
        
        /// Decodes the stored pointer only for the interpreter that created this identity.
        ///
        /// Using another interpreter's key would produce a garbage address. The interpreter
        /// ID check happens before XOR decoding so wrong-interpreter use fails cleanly by
        /// returning `nil` instead of manufacturing an invalid pointer.
        fileprivate func decodedPointer(interpreterID: UInt64, pointerEncodingKey: UInt) -> UnsafeMutableRawPointer? {
            guard self.interpreterID == interpreterID else {
                return nil
            }
            return UnsafeMutableRawPointer(bitPattern: encodedPointer ^ pointerEncodingKey)
        }
        
        public var description: String {
            "PyID(\(String(interpreterID, radix: 16)):\(String(encodedPointer, radix: 16)))"
        }
    }
    
    /// Generates a non-zero per-interpreter identity marker.
    ///
    /// Zero is avoided so an all-zero/default-looking identity is never valid for a real
    /// interpreter. Collisions are still theoretically possible, but a random 64-bit value
    /// makes accidental cross-interpreter acceptance vanishingly unlikely.
    internal static func randomNonZeroUInt64() -> UInt64 {
        var value = UInt64.random(in: UInt64.min...UInt64.max)
        while value == 0 {
            value = UInt64.random(in: UInt64.min...UInt64.max)
        }
        return value
    }
    
    /// Generates the per-interpreter key used to reversibly encode object pointers.
    ///
    /// The key is process-local state held by the interpreter actor. Keeping it off the
    /// public identity means callers cannot accidentally treat `encodedPointer` as a
    /// CPython pointer.
    internal static func randomNonZeroUInt() -> UInt {
        var value = UInt.random(in: UInt.min...UInt.max)
        while value == 0 {
            value = UInt.random(in: UInt.min...UInt.max)
        }
        return value
    }
    
    /// Creates the actor-bound identity stored in a `PythonObject` or `SafePythonObject`.
    ///
    /// The returned value is safe to move around as Swift data. It does not grant pointer
    /// access on its own; decoding still requires coming back through this interpreter.
    internal func makePythonObjectID(for pointer: UnsafeMutableRawPointer) -> PythonObjectUniqueID {
        PythonObjectUniqueID(
            pointer: pointer,
            interpreterID: interpreterID,
            pointerEncodingKey: pointerEncodingKey
        )
    }
    
    /// Recovers the raw `PyObject *` for code already running on the owning interpreter.
    ///
    /// A `nil` result means the identity came from another interpreter. Callers should only
    /// use the returned pointer inside interpreter-managed CPython calls where GIL and
    /// lifetime rules are already being enforced.
    internal func decodePythonObjectPointer(from id: PythonObjectUniqueID) -> UnsafeMutableRawPointer? {
        id.decodedPointer(
            interpreterID: interpreterID,
            pointerEncodingKey: pointerEncodingKey
        )
    }
}
