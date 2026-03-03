//
// PythonObject.swift
//  Swift2Python
//
//  Created by Ben White on 2/28/26.
//

import Foundation

@dynamicMemberLookup
public struct PythonObject: Sendable {
    
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
    
    
    //
    // a.name
    public subscript(dynamicMember name: String) -> PythonObject {
        // a.name
        get {
            fatalError("Placeholder to tell xcode to shut up")
        }
        // a.name = value
        nonmutating set {
            fatalError("Placeholder to tell xcode to shut up")
        }
    }
    
    
    //
    // a[key]
    subscript(key: PendingPythonConvertible...) -> PythonObject {
        // a[key]
        get {
            fatalError("Placeholder to tell xcode to shut up")
        }
        // a[key] = value
        nonmutating set {
            fatalError("Placeholder to tell xcode to shut up")
        }
    }
}
