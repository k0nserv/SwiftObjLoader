//
//  ObjLoader.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 02/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import Foundation

enum ObjLoadingError: ErrorType {
    case UnexpectedFileFormat(error: String)
}

// Represent the state of parsing
// at any point in time
struct State {
    var objectName: NSString?
    var vertices: [Vector] = []
    var normals: [Vector] = []
    var textureCoords: [Vector] = []
    var faces: [[VertexIndex]] = []
}

class ObjLoader {
    // Source markers
    private static let commentMarker = "#".characterAtIndex(0)
    private static let vertexMarker = "v".characterAtIndex(0)
    private static let normalMarker = "vn"
    private static let textureCoordMarker = "vt"
    private static let objectMarker = "o".characterAtIndex(0)
    private static let faceMarker = "f".characterAtIndex(0)

    private static let whiteSpaceCharacters = NSCharacterSet.whitespaceCharacterSet()
    private static let newLineCharacters = NSCharacterSet.newlineCharacterSet()

    private let source: String
    private let scanner: NSScanner
    private var running: Bool = false

    private var state = State()
    private var vertexCount = 0
    private var normalCount = 0
    private var textureCoordCount = 0

    // Init an objloader with the
    // source of the .obj file as a string
    //
    init(source: String) {
        self.source = source
        scanner = NSScanner(string: source)
        scanner.charactersToBeSkipped = ObjLoader.whiteSpaceCharacters
    }

    // Read the specified source.
    // This operation is singled threaded and
    // should not be invoked again before
    // the call has returned
    func read() throws -> [Shape] {
        running = true
        var shapes: [Shape] = []

        resetState()

        let clear: () -> () = {
            self.state = State()
        }

        while false == scanner.atEnd {
            var marker: NSString?
            scanner.scanUpToCharactersFromSet(ObjLoader.whiteSpaceCharacters, intoString: &marker)

            guard let m = marker where m.length > 0 else {
                moveToNextLine()
                continue
            }

            if ObjLoader.isComment(m) {
                moveToNextLine()
                continue
            } else if ObjLoader.isVertex(m) {
                if let v = readVertex() {
                    state.vertices.append(v)
                }

                moveToNextLine()
                continue
            } else if ObjLoader.isNormal(m) {
                if let n = readVertex() {
                    state.normals.append(n)
                }

                moveToNextLine()
                continue
            } else if ObjLoader.isTextureCoord(m) {
                if let vt = readTextureCoord() {
                    state.textureCoords.append(vt)
                }

                moveToNextLine()
                continue
            } else if ObjLoader.isObject(m) {
                if let s = buildShape(state.objectName, vertices: state.vertices, normals: state.normals, textureCoords: state.textureCoords, faces: state.faces) {
                    shapes.append(s)
                }

                clear()
                scanner.scanUpToCharactersFromSet(ObjLoader.newLineCharacters, intoString: &state.objectName)
                moveToNextLine()
                continue
            } else if ObjLoader.isFace(m) {
                if let indices = try readFace() {
                    state.faces.append(indices)
                }

                moveToNextLine()
                continue
            } else {
                moveToNextLine()
                continue
            }
        }

        if let s = buildShape(state.objectName, vertices: state.vertices, normals: state.normals, textureCoords: state.textureCoords, faces: state.faces) {
            shapes.append(s)
        }
        clear()

        running = false
        return shapes
    }

    private static func isComment(marker: NSString) -> Bool {
        return marker.characterAtIndex(0) == commentMarker
    }

    private static func isVertex(marker: NSString) -> Bool {
        return marker.length == 1 && marker.characterAtIndex(0) == vertexMarker
    }

    private static func isNormal(marker: NSString) -> Bool {
        return marker.length == 2 && marker.substringToIndex(2) == normalMarker
    }

    private static func isTextureCoord(marker: NSString) -> Bool {
        return marker.length == 2 && marker.substringToIndex(2) == textureCoordMarker
    }

    private static func isObject(marker: NSString) -> Bool {
        return marker.length == 1 && marker.characterAtIndex(0) == objectMarker
    }

    private static func isFace(marker: NSString) -> Bool {
        return marker.length == 1 && marker.characterAtIndex(0) == faceMarker
    }

    // Read 3(optionally 4) space separated double values from the scanner
    // The fourth w value defaults to 1.0 if not present
    // Example:
    //  19.2938 1.29019 0.2839
    //  1.29349 -0.93829 1.28392 0.6
    //
    private func readVertex() -> [Double]? {
        var x = Double.infinity
        var y = Double.infinity
        var z = Double.infinity
        var w = 1.0

        guard scanner.scanDouble(&x) else {
            return nil
        }

        guard scanner.scanDouble(&y) else {
            return nil
        }

        guard scanner.scanDouble(&z) else {
            return nil
        }

        scanner.scanDouble(&w)

        return [x, y, z, w]
    }

    // Read 1, 2 or 3 texture coords from the scanner
    private func readTextureCoord() -> [Double]? {
        var u = Double.infinity
        var v = 0.0
        var w = 0.0

        guard scanner.scanDouble(&u) else {
            return nil
        }

        if scanner.scanDouble(&v) {
            scanner.scanDouble(&w)
        }

        return [u, v, w]
    }

    // Parses face declarations
    //
    // Example:
    //
    //     f v1/vt1/vn1 v2/vt2/vn2 ....
    //
    // Possible cases
    // v1//
    // v1//vn1
    // v1/vt1/
    // v1/vt1/vn1
    private func readFace() throws -> [VertexIndex]? {
        var result: [VertexIndex] = []
        while true {
            var v, vn, vt: Int?
            var tmp: Int32 = -1

            guard scanner.scanInt(&tmp) else {
                break
            }
            v = Int(tmp)

            guard scanner.scanString("/", intoString: nil) else {
                throw ObjLoadingError.UnexpectedFileFormat(error: "Lack of '/' when parsing face definition, each vertex index should contain 2 '/'")
            }

            if scanner.scanInt(&tmp) { // v1/vt1/
                vt = Int(tmp)
            }
            guard scanner.scanString("/", intoString: nil) else {
                throw ObjLoadingError.UnexpectedFileFormat(error: "Lack of '/' when parsing face definition, each vertex index should contain 2 '/'")
            }

            if scanner.scanInt(&tmp) {
                vn = Int(tmp)
            }

            result.append(VertexIndex(vIndex: ObjLoader.normalizeIndex(v, count: vertexCount), nIndex: ObjLoader.normalizeIndex(vn, count: normalCount), tIndex: ObjLoader.normalizeIndex(vt, count: textureCoordCount)))
        }

        return result
    }

    private func moveToNextLine() {
        scanner.scanUpToCharactersFromSet(ObjLoader.newLineCharacters, intoString: nil)
        scanner.scanCharactersFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet(), intoString: nil)
    }

    private func resetState() {
        scanner.scanLocation = 0
        state = State()
        vertexCount = 0
        normalCount = 0
        textureCoordCount = 0
    }

    private func buildShape(name: NSString?, vertices: [[Double]], normals: [[Double]], textureCoords: [[Double]], faces: [[VertexIndex]]) -> Shape? {
        if vertices.count == 0 && normals.count == 0 && textureCoords.count == 0 {
            return nil
        }


        let result =  Shape(name: (name as String?), vertices: vertices, normals: normals, textureCoords: textureCoords, faces: faces)
        vertexCount += vertices.count
        normalCount += normals.count
        textureCoordCount += textureCoords.count

        return result
    }

    private static func normalizeIndex(index: Int?, count: Int) -> Int? {
        guard let i = index else {
            return nil
        }

        if i == 0 {
            return 0
        }

        return i - count - 1
    }
}