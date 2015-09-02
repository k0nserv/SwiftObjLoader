//
//  GeometryTests.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 02/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import XCTest
@testable import SwiftObjLoader

class GeometryTests: XCTestCase {
    func testSimpleShapeEquality() {
        var s1 = Shape(name: "Shape", vertices: [[]], normals: [[]], textureCoords: [[]], faces : [[]])
        var s2 = Shape(name: "Shape", vertices: [[]], normals: [[]], textureCoords: [[]], faces : [[]])
        XCTAssertEqual(s1, s2)

        s1 = Shape(name: "Shape1", vertices: [[]], normals: [[]], textureCoords: [[]], faces : [[]])
        s2 = Shape(name: "Shape2", vertices: [[]], normals: [[]], textureCoords: [[]], faces : [[]])
        XCTAssertNotEqual(s1, s2)


        let v1 = [0.1, 0.3, 0.5]
        let v2 = [0.1, 0.2, 0.5]

        s1 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces: [[]])
        s2 = Shape(name: "Shape", vertices: [v2], normals: [v1], textureCoords: [v1], faces : [[]])
        XCTAssertNotEqual(s1, s2)

        s1 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces : [[]])
        s2 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces : [[]])
        XCTAssertEqual(s1, s2)

        s1 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces : [[]])
        s2 = Shape(name: "Shape", vertices: [v1], normals: [v2], textureCoords: [v1], faces : [[]])
        XCTAssertNotEqual(s1, s2)

        s1 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces : [[]])
        s2 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces : [[]])
        XCTAssertEqual(s1, s2)

        s1 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces : [[]])
        s2 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v2], faces : [[]])
        XCTAssertNotEqual(s1, s2)

        s1 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces : [[]])
        s2 = Shape(name: "Shape", vertices: [v1], normals: [v1], textureCoords: [v1], faces : [[]])
        XCTAssertEqual(s1, s2)
    }
}
