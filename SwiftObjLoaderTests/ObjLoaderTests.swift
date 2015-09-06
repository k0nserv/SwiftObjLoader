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
        do {
            let shapes = try loader.read()
            XCTAssertEqual(shapes.count, 1)
            let vertices = [
                // v 1.000905 -0.903713 -1.120729
                [1.000905, -0.903713, -1.120729, 1.0],
                // v 1.000905 -0.903713 0.879271
                [1.000905, -0.903713, 0.879271, 1.0],
                // v -0.999095 -0.903713 0.879271
                [-0.999095, -0.903713, 0.879271, 1.0],
                // v -0.999095 -0.903713 -1.120729
                [-0.999095, -0.903713, -1.120729, 1.0],
                // v 1.000905 1.096287 -1.120728
                [1.000905, 1.096287, -1.120728, 1.0],
                // v 1.000904 1.096287 0.879272
                [1.000904, 1.096287, 0.879272, 1.0],
                // v -0.999095 1.096287 0.879271
                [-0.999095, 1.096287, 0.879271, 1.0],
                // v -0.999095 1.096287 -1.120729
                [-0.999095, 1.096287, -1.120729, 1.0]
            ]
            let normals = [
                // vn 0.000000 -1.000000 0.000000
                [0.000000, -1.000000, 0.000000, 1.0],
                // vn 0.000000 1.000000 0.000000
                [0.000000, 1.000000, 0.000000, 1.0],
                // vn 1.000000 0.000000 0.000000
                [1.000000, 0.000000, 0.000000, 1.0],
                // vn 1.000000 0.000000 0.000000
                [-0.000000, -0.000000, 1.000000, 1.0],
                // vn -1.000000 -0.000000 -0.000000
                [-1.000000, -0.000000, -0.000000, 1.0],
                // vn 0.000000 0.000000 -1.000000
                [0.000000, 0.000000, -1.000000, 1.0]
            ]

            let textureCoords = [
                // vt 0.000000 1.000000
                [0.000000, 1.000000, 0.0],
                // vt 1.000000 0.000000
                [1.000000, 0.000000, 0.0],
                // vt 0.000000 1.000000
                [0.000000, 1.000000, 0.0],
                // vt 1.000000 1.000000
                [1.000000, 1.000000, 0.0]
            ]
            let faces = [
                // f 1//1 2//1 3//1 4//1
                [
                    VertexIndex(vIndex: 0, nIndex: 0, tIndex: 0),
                    VertexIndex(vIndex: 1, nIndex: 0, tIndex: 1),
                    VertexIndex(vIndex: 2, nIndex: 0, tIndex: 2),
                    VertexIndex(vIndex: 3, nIndex: 0, tIndex: 3)
                ],
                // f 5//2 8//2 7//2 6//2
                [
                    VertexIndex(vIndex: 4, nIndex: 1, tIndex: nil),
                    VertexIndex(vIndex: 7, nIndex: 1, tIndex: nil),
                    VertexIndex(vIndex: 6, nIndex: 1, tIndex: nil),
                    VertexIndex(vIndex: 5, nIndex: 1, tIndex: nil)
                ],
                // f 1//3 5//3 6//3 2//3
                [
                    VertexIndex(vIndex: 0, nIndex: 2, tIndex: nil),
                    VertexIndex(vIndex: 4, nIndex: 2, tIndex: nil),
                    VertexIndex(vIndex: 5, nIndex: 2, tIndex: nil),
                    VertexIndex(vIndex: 1, nIndex: 2, tIndex: nil)
                ],
                // f 2//4 6//4 7//4 3//4
                [
                    VertexIndex(vIndex: 1, nIndex: 3, tIndex: nil),
                    VertexIndex(vIndex: 5, nIndex: 3, tIndex: nil),
                    VertexIndex(vIndex: 6, nIndex: 3, tIndex: nil),
                    VertexIndex(vIndex: 2, nIndex: 3, tIndex: nil)
                ],
                // f 3//5 7//5 8//5 4//5
                [
                    VertexIndex(vIndex: 2, nIndex: 4, tIndex: nil),
                    VertexIndex(vIndex: 6, nIndex: 4, tIndex: nil),
                    VertexIndex(vIndex: 7, nIndex: 4, tIndex: nil),
                    VertexIndex(vIndex: 3, nIndex: 4, tIndex: nil)
                ],
                // f 5//6 1//6 4//6 8//6
                [
                    VertexIndex(vIndex: 4, nIndex: 5, tIndex: nil),
                    VertexIndex(vIndex: 0, nIndex: 5, tIndex: nil),
                    VertexIndex(vIndex: 3, nIndex: 5, tIndex: nil),
                    VertexIndex(vIndex: 7, nIndex: 5, tIndex: nil)
                ]

            ]
            let expectedShape = Shape(name: "Cube", vertices: vertices, normals: normals, textureCoords: textureCoords, faces: faces)
            XCTAssertEqual(expectedShape, shapes[0])
            verifyLocalFaceIndexes(shapes[0])
        } catch ObjLoadingError.UnexpectedFileFormat(let errorMessage) {
            XCTFail("Parsing failed with error \(errorMessage)")
        } catch {
            XCTFail("Parsing failed with unknown error")
        }
    }

    func testMultiple() {
        let source = try? fixtureHelper.loadObjFixture("triangle_and_box")
        let loader = ObjLoader(source: source!)
        do {
            let shapes = try loader.read()
            XCTAssertEqual(shapes.count, 2)

            let triangle = shapes[0]
            let vertices = [
                // v 1.407288 0.638664 -1.179823
                [1.407288, 0.638664, -1.179823, 1],
                // v 1.407288 0.638664 -3.179823
                [1.407288, 0.638664, -3.179823, 1],
                // v 3.407288 0.638664 -3.179823
                [3.407288, 0.638664, -3.179823, 1]
            ]
            let normals = [
                // vn 0.000000 -1.000000 0.000000
                [0.000000, -1.000000, 0.000000, 1]
            ]
            let faces: [[VertexIndex]] = [
                [
                    // f 2//1 3//1 1//1
                    VertexIndex(vIndex: 1, nIndex: 0, tIndex: nil),
                    VertexIndex(vIndex: 2, nIndex: 0, tIndex: nil),
                    VertexIndex(vIndex: 0, nIndex: 0, tIndex: nil)
                ]
            ]
            let expectedTriangle = Shape(name: "Triangle", vertices: vertices, normals: normals, textureCoords: [], faces: faces)
            XCTAssertEqual(expectedTriangle, triangle)
            verifyLocalFaceIndexes(triangle)

            let box = shapes[1]
            let boxVertices = [
                //v 1.000905 0.018270 -1.120729
                [1.000905, 0.018270, -1.120729, 1],
                //v 1.000905 0.018270 0.879271
                [1.000905, 0.018270, 0.879271, 1],
                //v -0.999095 0.018270 0.879271
                [-0.999095, 0.018270, 0.879271, 1],
                //v -0.999095 0.018270 -1.120729
                [-0.999095, 0.018270, -1.120729, 1],
                //v 1.000905 2.018270 -1.120728
                [1.000905, 2.018270, -1.120728, 1],
                //v 1.000904 2.018270 0.879272
                [1.000904, 2.018270, 0.879272, 1],
                //v -0.999095 2.018270 0.879271
                [-0.999095, 2.018270, 0.879271, 1],
                //v -0.999095 2.018270 -1.120729
                [-0.999095, 2.018270, -1.120729, 1]
            ]
            let boxNormals = [
                //vn 0.000000 -1.000000 -0.000000
                [0.000000, -1.000000, -0.000000, 1],
                //vn 0.000000 1.000000 0.000000
                [0.000000, 1.000000, 0.000000, 1],
                //vn 1.000000 0.000000 0.000000
                [1.000000, 0.000000, 0.000000, 1],
                //vn -0.000000 -0.000000 1.000000
                [-0.000000, -0.000000, 1.000000, 1],
                //vn -1.000000 -0.000000 -0.000000
                [-1.000000, -0.000000, -0.000000, 1],
                //vn 0.000000 0.000000 -1.000000
                [0.000000, 0.000000, -1.000000, 1]
            ]

            let boxFaces = [
                //f 4//2 5//2 6//2 7//2
                [
                    VertexIndex(vIndex: 0, nIndex: 0, tIndex: nil),
                    VertexIndex(vIndex: 1, nIndex: 0, tIndex: nil),
                    VertexIndex(vIndex: 2, nIndex: 0, tIndex: nil),
                    VertexIndex(vIndex: 3, nIndex: 0, tIndex: nil)
                ],
                //f 8//3 11//3 10//3 9//3
                [
                    VertexIndex(vIndex: 4, nIndex: 1, tIndex: nil),
                    VertexIndex(vIndex: 7, nIndex: 1, tIndex: nil),
                    VertexIndex(vIndex: 6, nIndex: 1, tIndex: nil),
                    VertexIndex(vIndex: 5, nIndex: 1, tIndex: nil)
                ],
                //f 4//4 8//4 9//4 5//4
                [
                    VertexIndex(vIndex: 0, nIndex: 2, tIndex: nil),
                    VertexIndex(vIndex: 4, nIndex: 2, tIndex: nil),
                    VertexIndex(vIndex: 5, nIndex: 2, tIndex: nil),
                    VertexIndex(vIndex: 1, nIndex: 2, tIndex: nil)
                ],
                //f 5//5 9//5 10//5 6//5
                [
                    VertexIndex(vIndex: 1, nIndex: 3, tIndex: nil),
                    VertexIndex(vIndex: 5, nIndex: 3, tIndex: nil),
                    VertexIndex(vIndex: 6, nIndex: 3, tIndex: nil),
                    VertexIndex(vIndex: 2, nIndex: 3, tIndex: nil)
                ],
                //f 6//6 10//6 11//6 7//6
                [
                    VertexIndex(vIndex: 2, nIndex: 4, tIndex: nil),
                    VertexIndex(vIndex: 6, nIndex: 4, tIndex: nil),
                    VertexIndex(vIndex: 7, nIndex: 4, tIndex: nil),
                    VertexIndex(vIndex: 3, nIndex: 4, tIndex: nil)
                ],
                //f 8//7 4//7 7//7 11//7
                [
                    VertexIndex(vIndex: 4, nIndex: 5, tIndex: nil),
                    VertexIndex(vIndex: 0, nIndex: 5, tIndex: nil),
                    VertexIndex(vIndex: 3, nIndex: 5, tIndex: nil),
                    VertexIndex(vIndex: 7, nIndex: 5, tIndex: nil)
                ]
            ]

            let expectedBox = Shape(name: "Cube", vertices: boxVertices, normals: boxNormals, textureCoords: [], faces: boxFaces)
            XCTAssertEqual(box, expectedBox)
            verifyLocalFaceIndexes(box)

        } catch ObjLoadingError.UnexpectedFileFormat(let errorMessage) {
            XCTFail("Parsing failed with error \(errorMessage)")
        } catch {
            XCTFail("Parsing failed with unknown error")
        }
    }

    // Verify that indexes for shape definitions into
    // vertices, normals and texture coords have been correctly
    // normalized to index into the data of the shape and
    // not into the global data of the file definition
    //
    // will cause the test suite to fail due to an
    // index out of bounds error on failure
    private func verifyLocalFaceIndexes(shape: Shape) {
        for vertexIndexes in shape.faces {
            for vertexIndex in vertexIndexes {
                // Will cause an out of bounds error
                // if vIndex, nIndex or tIndex is not normalized
                // to be local to the internal data of the shape
                // instead of global to the file as per the
                // .obj specification
                shape.dataForVertexIndex(vertexIndex)
            }
        }
    }
}
