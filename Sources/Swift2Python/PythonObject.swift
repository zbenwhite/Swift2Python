//
// PythonObject.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

import Foundation

public struct PythonObject: Sendable, PendingPythonConvertible {
    
    /// Helper to bridge Swift ARC to the Actor's registry
    private final class LifetimeTracker: Sendable {
        let id: PythonInterpreter.PythonObjectUniqueID
        let interpreter: PythonInterpreter

        init(id: PythonInterpreter.PythonObjectUniqueID, interpreter: PythonInterpreter) {
            self.id = id
            self.interpreter = interpreter
        }

        deinit {
            let capturedID = id
            let capturedInterpreter = interpreter
            Task {
                try? await capturedInterpreter.releaseHandle(capturedID)
            }
        }
    }
    
    internal let id: PythonInterpreter.PythonObjectUniqueID
    private let interpreter: PythonInterpreter
    private let lifetime: LifetimeTracker

    init(id: PythonInterpreter.PythonObjectUniqueID, interpreter: PythonInterpreter) {
        self.id = id
        self.interpreter = interpreter
        self.lifetime = LifetimeTracker(id: id, interpreter: interpreter)
    }
    
    // Implement PendingPythonConvertible protocol
    public func toPythonObject(interpreter: PythonInterpreter) async throws -> PythonObject {
        return self
    }
    
    // a.name
    // (can't do actual a.name because we need try await and they're not available for a.name)
    public func get(attrName: String) async throws -> PythonObject {
        return try await interpreter.getObjectAttribute(self, attrName)
    }
    
    // a.name = value
    // (can't do actual a.name = value because we need try await ...)
    public func set(attrName: String, value: PendingPythonConvertible) async throws {
        try await interpreter.setObjectAttribute(self, attrName, value.toPythonObject(interpreter: self.interpreter))
    }
}
