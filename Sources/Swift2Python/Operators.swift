//
//  Operators.swift
//  Swift2Python
//
//  Created by Ben White on 3/2/26.
//

public extension PythonInterpreter.SafePythonObject {
    static func + (lhs: PythonInterpreter.SafePythonObject, rhs: PythonInterpreter.SafePythonObject) -> PythonInterpreter.SafePythonObject {
        return lhs.addOperator(rhs)
    }
}
