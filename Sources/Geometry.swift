//
//  Geometry.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 02/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import Foundation

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

// An n dimensional vector
// repreented by a double array
typealias Vector = [Double]


class VertexIndex {
    // Vertex index, zero-based
    let vIndex: Int?
    // Normal index, zero-based
    let nIndex: Int?
    // Texture Coord index, zero-based
    let tIndex: Int?

    init(vIndex: Int?, nIndex: Int?, tIndex: Int?) {
        self.vIndex = vIndex
        self.nIndex = nIndex
        self.tIndex = tIndex
    }
}

extension VertexIndex: Equatable {}

func ==(lhs: VertexIndex, rhs: VertexIndex) -> Bool {
    return lhs.vIndex == rhs.vIndex &&
           lhs.nIndex == rhs.nIndex &&
           lhs.tIndex == rhs.tIndex
}

extension VertexIndex: CustomStringConvertible {
    var description: String {
        return "\(vIndex)/\(nIndex)/\(tIndex)"
    }
}

// Consider converting this to a class.
// Since it's already immutable it would
// remain thread safe and needless copying
// would stop. Also applies to Material
public class Shape {
    let name: String?
    let vertices: [Vector]
    let normals: [Vector]
    let textureCoords: [Vector]
    let material: Material?

    // Definition of faces that make up the shape
    // indexes are into the vertices, normals and
    // texture coords of this shape
    //
    // Example:
    //   VertexIndex(vIndex: 4, nIndex: 2, tIndex: 0)
    // Refers to vertices[4], normals[2] and textureCoords[0]
    //
    let faces: [[VertexIndex]]

    init(name: String?,
         vertices: [Vector],
         normals: [Vector],
         textureCoords: [Vector],
         material: Material?,
         faces: [[VertexIndex]]) {
        self.name = name
        self.vertices = vertices
        self.normals = normals
        self.textureCoords = textureCoords
        self.material = material
        self.faces = faces
    }

    func dataForVertexIndex(v: VertexIndex) -> (Vector?, Vector?, Vector?) {
        var data: (Vector?, Vector?, Vector?) = (nil, nil, nil)

        if let vi = v.vIndex {
            data.0 = vertices[vi]
        }

        if let ni = v.nIndex {
            data.1 = normals[ni]
        }

        if let ti = v.tIndex {
            data.2 = textureCoords[ti]
        }

        return data
    }
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

    for i in 0..<lhs.count {
        if false == equal(lhs[i], rhs[i]) {
            return false
        }
    }

    return true
}

public func ==(lhs: Shape, rhs: Shape) -> Bool {
    if lhs.name != rhs.name {
        return false
    }

    let lengthCheck: (Vector, Vector) -> Bool = { a, b in
        a.count == b.count
    }

    if !nestedEquality(lhs.vertices, rhs.vertices, equal: lengthCheck) ||
       !nestedEquality(lhs.normals, rhs.normals, equal: lengthCheck) ||
       !nestedEquality(lhs.textureCoords, rhs.textureCoords, equal: lengthCheck) {
        return false
    }

    let valueCheck: (Vector, Vector) -> Bool = { a, b in
        for i in 0..<a.count {
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

    let vertexIndexCheck: ([VertexIndex], [VertexIndex]) -> Bool = { a, b in
        for i in 0..<a.count {
            if a[i] != b[i] {
                return false
            }
        }
        return true
    }
    if !nestedEquality(lhs.faces, rhs.faces, equal: vertexIndexCheck) {
        return false
    }

    if lhs.material != rhs.material {
        return false
    }


    return true
}

