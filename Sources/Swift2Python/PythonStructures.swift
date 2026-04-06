//
//  PythonStructures.swift
//  Swift2Python
//
//  Created by Ben White on 4/5/26.
//

public struct Py_buffer {
    public var buf: UnsafeMutableRawPointer?
    public var obj: UnsafeMutableRawPointer?
    public var len: Int
    public var itemsize: Int
    public var readonly: Int32
    public var ndim: Int32
    public var format: UnsafeMutablePointer<CChar>?
    public var shape: UnsafeMutablePointer<Int>?
    public var strides: UnsafeMutablePointer<Int>?
    public var suboffsets: UnsafeMutablePointer<Int>?
    public var `internal`: UnsafeMutableRawPointer?
    
    public init() {
        self.buf = nil
        self.obj = nil
        self.len = 0
        self.itemsize = 0
        self.readonly = 0
        self.ndim = 0
        self.format = nil
        self.shape = nil
        self.strides = nil
        self.suboffsets = nil
        self.internal = nil
    }
}
