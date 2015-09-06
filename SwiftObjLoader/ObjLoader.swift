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

// A n dimensional vector
// repreented by a double array
typealias Vector = [Double]


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
    private let source: String
    private let scanner: NSScanner

    private static let whiteSpaceCharacters = NSCharacterSet.whitespaceCharacterSet()
    private static let newLineCharacters = NSCharacterSet.newlineCharacterSet()
    private static let commentMarker = "#".characterAtIndex(0)
    private static let vertexMarker = "v".characterAtIndex(0)
    private static let normalMarker = "vn"
    private static let textureCoordMarker = "vt"
    private static let objectMarker = "o".characterAtIndex(0)
    private static let faceMarker = "f".characterAtIndex(0)

    // Init an objloader with the
    // source of the .obj file as a string
    //
    init(source: String) {
        self.source = source
        scanner = NSScanner(string: source)
        scanner.charactersToBeSkipped = ObjLoader.whiteSpaceCharacters
    }

    func read() throws -> [Shape] {
        scanner.scanLocation = 0
        var shapes: [Shape] = []
        var state = State()

        let clear: () -> () = {
            state = State()
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
                if let s = ObjLoader.buildShape(state.objectName, vertices: state.vertices, normals: state.normals, textureCoords: state.textureCoords, faces: state.faces) {
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

        if let s = ObjLoader.buildShape(state.objectName, vertices: state.vertices, normals: state.normals, textureCoords: state.textureCoords, faces: state.faces) {
            shapes.append(s)
        }
        clear()

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

            result.append(VertexIndex(vIndex: ObjLoader.normalizeIndex(v), nIndex: ObjLoader.normalizeIndex(vn), tIndex: ObjLoader.normalizeIndex(vt)))
        }

        return result
    }

    private func moveToNextLine() {
        scanner.scanUpToCharactersFromSet(ObjLoader.newLineCharacters, intoString: nil)
        scanner.scanCharactersFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet(), intoString: nil)
    }

    private static func buildShape(name: NSString?, vertices: [[Double]], normals: [[Double]], textureCoords: [[Double]], faces: [[VertexIndex]]) -> Shape? {
        if vertices.count == 0 && normals.count == 0 && textureCoords.count == 0 {
            return nil
        }

        return Shape(name: (name as String?), vertices: vertices, normals: normals, textureCoords: textureCoords, faces: faces)
    }

    private static func normalizeIndex(index: Int?) -> Int? {
        guard let i = index else {
            return nil
        }

        if i == 0 {
            return 0
        }

        return i - 1
    }
}