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

class ObjLoader {
    private let source: String
    private let scanner: NSScanner

    private static let whiteSpaceCharacters = NSCharacterSet.whitespaceCharacterSet()
    private static let newLineCharacters = NSCharacterSet.newlineCharacterSet()
    private static let commentMarker = "#".characterAtIndex(0)
    private static let vertexMarker = "v".characterAtIndex(0)
    private static let normalMarker = "vn"
    private static let objectMarker = "o".characterAtIndex(0)
    private static let faceMarker = "f".characterAtIndex(0)

    // Init an objloader with the
    // source of the .obj file as a string
    //
    init(source: String) {
        self.source = source
        scanner = NSScanner(string: source)
        scanner.charactersToBeSkipped = self.dynamicType.whiteSpaceCharacters
    }

    func read() throws -> [Shape] {
        scanner.scanLocation = 0
        var shapes: [Shape] = []

        var currentName: NSString?
        var currentVertices: [[Double]] = []
        var currentNormals: [[Double]] = []
        var currentTextureCoords: [[Double]] = []
        var currentFaces: [[VertexIndex]] = []

        let clear: () -> () = {
            currentName = nil
            currentVertices.removeAll()
            currentNormals.removeAll()
            currentTextureCoords.removeAll()
            currentFaces.removeAll()
        }

        while false == scanner.atEnd {
            var marker: NSString?
            scanner.scanUpToCharactersFromSet(self.dynamicType.whiteSpaceCharacters, intoString: &marker)

            guard let m = marker where m.length > 0 else {
                moveToNextLine()
                continue
            }

            if self.dynamicType.isComment(m) {
                moveToNextLine()
                continue
            } else if self.dynamicType.isVertex(m) {
                if let v = readVertex() {
                    currentVertices.append(v)
                }

                moveToNextLine()
                continue
            } else if self.dynamicType.isNormal(m) {
                if let n = readVertex() {
                    currentNormals.append(n)
                }

                moveToNextLine()
                continue
            } else if self.dynamicType.isObject(m) {
                if let s = self.dynamicType.buildShape(currentName, vertices: currentVertices, normals: currentNormals, textureCoords: currentTextureCoords, faces: currentFaces) {
                    shapes.append(s)
                }

                clear()
                scanner.scanUpToCharactersFromSet(self.dynamicType.newLineCharacters, intoString: &currentName)
                moveToNextLine()
                continue
            } else if self.dynamicType.isFace(m) {
                if let indices = try readFace() {
                    currentFaces.append(indices)
                }

                moveToNextLine()
                continue
            } else {
                moveToNextLine()
                continue
            }
        }

        if let s = self.dynamicType.buildShape(currentName, vertices: currentVertices, normals: currentNormals, textureCoords: currentTextureCoords, faces: currentFaces) {
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

            result.append(VertexIndex(vIndex: self.dynamicType.normalizeIndex(v), nIndex: self.dynamicType.normalizeIndex(vn), tIndex: self.dynamicType.normalizeIndex(vt)))
        }

        return result
    }

    private func moveToNextLine() {
        scanner.scanUpToCharactersFromSet(self.dynamicType.newLineCharacters, intoString: nil)
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