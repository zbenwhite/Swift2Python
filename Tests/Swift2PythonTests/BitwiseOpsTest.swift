//
//  BitwiseOpsTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/18/26.
//

import Testing
import Logging
@testable import Swift2Python

@Suite("Bitwise Operations Tests")
struct BitwiseOpsTests {

    private static let sharedInterpreterTask = TestSupport.sharedInterpreterTask
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        self.interpreter = try await Self.sharedInterpreterTask.value
    }
    
    
}
