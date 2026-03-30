//
// PythonObject.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

import Foundation

@dynamicMemberLookup
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
    
    public struct CallablePythonObject {
        private let obj: PythonObject
        private let method: String
        
        public init (object: PythonObject, methodName: String) {
            self.obj = object
            self.method = methodName
        }
                
        public func callAsFunction(_ args: any PendingPythonConvertible...) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object:obj, methodName:method, collectedArgs: args)
        }
        
        public func callAsFunction(_ args: any PendingPythonConvertible..., kwargs: [String: PendingPythonConvertible] = [:]) async throws -> PythonObject {
            return try await obj.interpreter.callPythonMethod(object:obj, methodName:method, collectedArgs: args, kwargs:kwargs)
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
    
    //
    // a.call_a_function() can be implemented.
    public subscript(dynamicMember name: String) -> CallablePythonObject {
        // a.call_a_function()
        get {
            return CallablePythonObject(object: self, methodName: name)
        }
    }
}

