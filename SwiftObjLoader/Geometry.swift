//
//  Geometry.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 02/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import Foundation
import Darwin

struct VertexIndex {
    // Vertex index, zero-based
    let vIndex: Int?
    // Normal index, zero-based
    let nIndex: Int?
    // Texture Coord index, zero-based
    let tIndex: Int?
}

extension VertexIndex: Equatable {}

func ==(lhs: VertexIndex, rhs: VertexIndex) -> Bool {
    return lhs.vIndex == rhs.vIndex &&
           lhs.nIndex == rhs.nIndex &&
           lhs.tIndex == rhs.tIndex
}

struct Shape {
    let name: String?
    let vertices: [[Double]]
    let normals: [[Double]]
    let textureCoords: [[Double]]
    let faces: [[VertexIndex]]
}

extension Shape: Equatable {}

// From http://floating-point-gui.de/errors/comparison/
private func doubleEquality(a: Double, _ b: Double) -> Bool {
    let diff = abs(a - b)

    if a == b { // shortcut for infinities
        return true
    } else if (a == 0 || b == 0 || diff < DBL_MIN) {
        return diff < (1e-5 * DBL_MIN)
    } else {
        let absA = abs(a)
        let absB = abs(b)
        return diff / min((absA + absB), DBL_MAX) < 1e-5
    }
}


private func nestedEquality<T>(lhs: [[T]], _ rhs: [[T]], equal: ([T], [T]) -> Bool) -> Bool {
    if lhs.count != rhs.count {
        return false
    }

    for var i = 0; i < lhs.count; i++ {
        if false == equal(lhs[i], rhs[i]) {
            return false
        }
    }

    return true
}

func ==(lhs: Shape, rhs: Shape) -> Bool {
    if lhs.name != rhs.name {
        return false
    }

    let lengthCheck: ([Double], [Double]) -> Bool = { a, b in
        a.count == b.count
    }

    if !nestedEquality(lhs.vertices, rhs.vertices, equal: lengthCheck) ||
       !nestedEquality(lhs.normals, rhs.normals, equal: lengthCheck) ||
       !nestedEquality(lhs.textureCoords, rhs.textureCoords, equal: lengthCheck) {
        return false
    }

    let valueCheck: ([Double], [Double]) -> Bool = { a, b in
        for var i = 0; i < a.count; i++ {
            if !doubleEquality(a[i], b[i]) {
                return false
            }
        }
        return true
    }

    if !nestedEquality(lhs.vertices, rhs.vertices, equal: valueCheck) ||
       !nestedEquality(lhs.normals, rhs.normals, equal: valueCheck) ||
        !nestedEquality(lhs.textureCoords, rhs.textureCoords, equal: valueCheck) {
            return false
    }

    if !nestedEquality(lhs.faces, rhs.faces, equal: { $0.count == $1.count }) {
        return false
    }

    if !nestedEquality(lhs.faces, rhs.faces, equal: { $0 == $1 }) {
        return false
    }


    return true
}

