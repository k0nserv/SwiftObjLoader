//
//  ObjLoaderTests.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 02/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import XCTest
@testable import SwiftObjLoader

class ObjLoaderTests: XCTestCase {
    var fixtureHelper: FixtureHelper!

    override func setUp() {
        fixtureHelper = FixtureHelper()
    }

    func testSimple() {
        let source = try? fixtureHelper.loadObjFixture("simple")
        let loader = ObjLoader(source: source!)
        let shapes = loader.read()

        XCTAssertEqual(shapes.count, 1)
        let vertices = [[1.000905, -0.903713, -1.120729, 1.0], [1.000905, -0.903713, 0.879271, 1.0], [-0.999095, -0.903713, 0.879271, 1.0],
                        [-0.999095, -0.903713, -1.120729, 1.0], [1.000905, 1.096287, -1.120728, 1.0], [1.000904, 1.096287, 0.879272, 1.0],
                        [-0.999095, 1.096287, 0.879271, 1.0], [-0.999095, 1.096287, -1.120729, 1.0]]
        let normals = [[0.000000, -1.000000, 0.000000, 1.0], [0.000000, 1.000000, 0.000000, 1.0], [1.000000, 0.000000, 0.000000, 1.0],
                       [-0.000000, -0.000000, 1.000000, 1.0], [-1.000000, -0.000000, -0.000000, 1.0], [0.000000, 0.000000, -1.000000, 1.0]]
        let expectedShape = Shape(name: "Cube", vertices: vertices, normals: normals, textureCoords: [])
        XCTAssertEqual(expectedShape, shapes[0])
    }
}
