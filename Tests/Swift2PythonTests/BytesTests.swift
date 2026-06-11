//
//  BytesTest.swift
//  Swift2Python
//
//  Created by Ben White on 4/3/26.
//

import Foundation
import Testing
import Logging
@testable import Swift2Python

@Suite("Bytes Tests")
struct BytesTests {
    
    private static let setupLogging: Void = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .debug
            return handler
        }
    }()
    
    private static let sharedInterpreterTask: Task<PythonInterpreter, Error> = Task {
        _ = setupLogging
        let runtime = PythonRuntime.shared
        try await runtime.initialize()
        return try await PythonInterpreter()
    }
    
    let interpreter: PythonInterpreter
    
    init() async throws {
        interpreter = try await Self.sharedInterpreterTask.value
    }
    
    @Test("BYT_001: PythonObject bytes creation, inspection, and Swift extraction")
    func asyncBytesCreationAndExtraction() async throws {
        let source: [UInt8] = [0, 1, 2, 3, 255]
        let bytes = try await interpreter.convertToPython(bytes: source)
        
        #expect(try await bytes.isBytes())
        #expect(try await bytes.isByteArray() == false)
        #expect(try await bytes.isBytesLike())
        #expect(try await bytes.bytesSize() == source.count)
        #expect(try await bytes.asCopiedBytes() == source)
        #expect(try await bytes.asCopiedByteArray() == source)
        #expect(Array(try await bytes.asCopiedData()) == source)
        
        let text = try await interpreter.convertToPython(bytes: Data("hello".utf8))
        #expect(try await text.asCopiedString() == "hello")
    }
    
    @Test("BYT_002: PythonObject bytearray creation, inspection, extraction, and Python mutation")
    func asyncByteArrayCreationAndMutation() async throws {
        let source: [UInt8] = [10, 20, 30]
        let byteArray = try await interpreter.convertToPython(byteArray: source)
        
        #expect(try await byteArray.isBytes() == false)
        #expect(try await byteArray.isByteArray())
        #expect(try await byteArray.isBytesLike())
        #expect(try await byteArray.byteArraySize() == source.count)
        #expect(try await byteArray.asCopiedBytes() == source)
        
        _ = try await byteArray.append(40)
        #expect(try await byteArray.asCopiedBytes() == [10, 20, 30, 40])
        
        _ = try await byteArray.extend([50, 60])
        #expect(try await byteArray.asCopiedBytes() == [10, 20, 30, 40, 50, 60])
        
        let popped = try await byteArray.pop()
        #expect(try await Int(popped) == 60)
        #expect(try await byteArray.asCopiedBytes() == [10, 20, 30, 40, 50])
        
        _ = try await byteArray.reverse()
        #expect(try await byteArray.asCopiedBytes() == [50, 40, 30, 20, 10])
        
        _ = try await byteArray.clear()
        #expect(try await byteArray.byteArraySize() == 0)
        #expect(try await byteArray.asCopiedBytes().isEmpty)
    }
    
    @Test("BYT_003: Data conforms to PendingPythonConvertible as Python bytes")
    func asyncDataConvertsToBytes() async throws {
        let data = Data([65, 66, 67, 0, 255])
        let bytes = try await data.toPythonObject(interpreter: interpreter)
        
        #expect(try await bytes.isBytes())
        #expect(try await bytes.isBytesLike())
        #expect(try await bytes.bytesSize() == data.count)
        #expect(try await bytes.asCopiedData() == data)
        #expect(try await bytes.asCopiedBytes() == Array(data))
    }
    
    @Test("BYT_004: Python buffer protocol objects are bytes-like")
    func asyncBytesLikeObjects() async throws {
        let builtins = try await interpreter.getBuiltins()
        let bytes = try await interpreter.convertToPython(bytes: [1, 2, 3])
        let memoryView = try await builtins.memoryview(bytes)
        let list = try await interpreter.convertToPython(array: [1, 2, 3])
        
        #expect(try await memoryView.isBytes() == false)
        #expect(try await memoryView.isByteArray() == false)
        #expect(try await memoryView.isBytesLike())
        #expect(try await memoryView.asCopiedBytes() == [1, 2, 3])
        
        #expect(try await list.isBytesLike() == false)
    }
    
    @Test("BYT_005: PythonObject bytes error handling")
    func asyncBytesErrorHandling() async throws {
        let notBytes = try await 123.toPythonObject(interpreter: interpreter)
        let bytes = try await interpreter.convertToPython(bytes: [0xFF])
        let byteArray = try await interpreter.convertToPython(byteArray: [1, 2, 3])
        
        #expect(try await notBytes.isBytes() == false)
        #expect(try await notBytes.isByteArray() == false)
        #expect(try await notBytes.isBytesLike() == false)
        
        let bytesSizeError = await #expect(throws: PythonError.self) {
            _ = try await notBytes.bytesSize()
        }
        if case .bytesConversionFailed = bytesSizeError {
        } else {
            Issue.record("Expected .bytesConversionFailed for bytesSize on non-bytes, but got \(bytesSizeError)")
        }
        
        let byteArraySizeError = await #expect(throws: PythonError.self) {
            _ = try await notBytes.byteArraySize()
        }
        if case .bytesConversionFailed = byteArraySizeError {
        } else {
            Issue.record("Expected .bytesConversionFailed for byteArraySize on non-bytearray, but got \(byteArraySizeError)")
        }
        
        let byteArrayAsBytesError = await #expect(throws: PythonError.self) {
            _ = try await byteArray.bytesSize()
        }
        if case .bytesConversionFailed = byteArrayAsBytesError {
        } else {
            Issue.record("Expected .bytesConversionFailed for bytesSize on bytearray, but got \(byteArrayAsBytesError)")
        }
        
        let unsafeBytesError = await #expect(throws: PythonError.self) {
            _ = try await notBytes.withUnsafeBytes { Array($0) }
        }
        if case .bytesConversionFailed = unsafeBytesError {
        } else {
            Issue.record("Expected .bytesConversionFailed for withUnsafeBytes on non-buffer object, but got \(unsafeBytesError)")
        }
        
        let decodingError = await #expect(throws: PythonError.self) {
            _ = try await bytes.asCopiedString()
        }
        if case .bytesConversionFailed = decodingError {
        } else {
            Issue.record("Expected .bytesConversionFailed for invalid UTF-8 bytes, but got \(decodingError)")
        }
        
        let immutableAppendError = await #expect(throws: PythonError.self) {
            _ = try await bytes.append(1)
        }
        if case .pythonException = immutableAppendError {
        } else {
            Issue.record("Expected .pythonException for calling append on bytes, but got \(immutableAppendError)")
        }
    }
    
    @Test("BYT_006: SafePythonObject bytes and bytearray support")
    func safeBytesAndByteArraySupport() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let bytes = try isolatedInterpreter.convertToSafePython(bytes: [1, 2, 3, 4])
            
            #expect(try bytes.isBytes)
            #expect(try bytes.isByteArray == false)
            #expect(try bytes.isBytesArray == false)
            #expect(try bytes.isBytesLike)
            #expect(try bytes.bytesSize == 4)
            #expect(try bytes.asCopiedBytes() == [1, 2, 3, 4])
            #expect(Array(try bytes.asCopiedData()) == [1, 2, 3, 4])
            
            let text = try isolatedInterpreter.convertToSafePython(bytes: Data("safe".utf8))
            #expect(try text.asCopiedString() == "safe")
            
            let byteArray = try isolatedInterpreter.convertToSafePython(byteArray: Data([5, 6, 7]))
            #expect(try byteArray.isBytes == false)
            #expect(try byteArray.isByteArray)
            #expect(try byteArray.isBytesArray)
            #expect(try byteArray.isBytesLike)
            #expect(try byteArray.byteArraySize == 3)
            #expect(try byteArray.asCopiedByteArray() == [5, 6, 7])
            
            _ = try byteArray.append(8)
            #expect(try byteArray.asCopiedBytes() == [5, 6, 7, 8])
        }
    }
    
    @Test("BYT_007: Data conforms to SafePythonConvertible as safe Python bytes")
    func safeDataConvertsToBytes() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let data = Data([9, 8, 7, 6])
            let bytes = try data.toSafePythonObject(interpreter: isolatedInterpreter)
            
            #expect(try bytes.isBytes)
            #expect(try bytes.bytesSize == data.count)
            #expect(try bytes.asCopiedData() == data)
            #expect(try bytes.asCopiedBytes() == Array(data))
        }
    }
    
    @Test("BYT_008: SafePythonObject bytes error handling")
    func safeBytesErrorHandling() async throws {
        try await interpreter.withIsolatedContext { isolatedInterpreter in
            let notBytes = try 123.toSafePythonObject(interpreter: isolatedInterpreter)
            let bytes = try isolatedInterpreter.convertToSafePython(bytes: [0xFF])
            let byteArray = try isolatedInterpreter.convertToSafePython(byteArray: [1, 2])
            
            #expect(try notBytes.isBytes == false)
            #expect(try notBytes.isByteArray == false)
            #expect(try notBytes.isBytesLike == false)
            
            let bytesSizeError = #expect(throws: PythonError.self) {
                _ = try notBytes.bytesSize
            }
            if case .bytesConversionFailed = bytesSizeError {
            } else {
                Issue.record("Expected .bytesConversionFailed for safe bytesSize on non-bytes, but got \(bytesSizeError)")
            }
            
            let byteArraySizeError = #expect(throws: PythonError.self) {
                _ = try notBytes.byteArraySize
            }
            if case .bytesConversionFailed = byteArraySizeError {
            } else {
                Issue.record("Expected .bytesConversionFailed for safe byteArraySize on non-bytearray, but got \(byteArraySizeError)")
            }
            
            let byteArrayAsBytesError = #expect(throws: PythonError.self) {
                _ = try byteArray.bytesSize
            }
            if case .bytesConversionFailed = byteArrayAsBytesError {
            } else {
                Issue.record("Expected .bytesConversionFailed for safe bytesSize on bytearray, but got \(byteArrayAsBytesError)")
            }
            
            let unsafeBytesError = #expect(throws: PythonError.self) {
                _ = try notBytes.withUnsafeBytes { Array($0) }
            }
            if case .bytesConversionFailed = unsafeBytesError {
            } else {
                Issue.record("Expected .bytesConversionFailed for safe withUnsafeBytes on non-buffer object, but got \(unsafeBytesError)")
            }
            
            let decodingError = #expect(throws: PythonError.self) {
                _ = try bytes.asCopiedString()
            }
            if case .bytesConversionFailed = decodingError {
            } else {
                Issue.record("Expected .bytesConversionFailed for safe invalid UTF-8 bytes, but got \(decodingError)")
            }
        }
    }
}
