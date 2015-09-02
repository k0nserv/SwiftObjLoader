//
//  ObjLoader.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 02/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import Foundation

class ObjLoader {
    private let source: String
    private let scanner: NSScanner

    private static let whiteSpaceCharacters = NSCharacterSet.whitespaceCharacterSet()
    private static let newLineCharacters = NSCharacterSet.newlineCharacterSet()
    private static let commentMarker = "#".characterAtIndex(0)
    private static let vertexMarker = "v".characterAtIndex(0)
    private static let normalMarker = "vn"
    private static let objectMarker = "o".characterAtIndex(0)
    // Init an objloader with the
    // source of the .obj file as a string
    //
    init(source: String) {
        self.source = source
        scanner = NSScanner(string: source)
        scanner.charactersToBeSkipped = self.dynamicType.whiteSpaceCharacters
    }

    func read() -> [Shape] {
        scanner.scanLocation = 0
        var shapes: [Shape] = []

        var currentName: NSString?
        var currentVertices: [[Double]] = []
        var currentNormals: [[Double]] = []
        var currentTextureCoords: [[Double]] = []

        while false == scanner.atEnd {
            var marker: NSString?
            scanner.scanUpToCharactersFromSet(self.dynamicType.whiteSpaceCharacters, intoString: &marker)
//            scanner.scanCharactersFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet(), intoString: nil)

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
                if let s = self.dynamicType.buildShape(currentName, vertices: currentVertices, normals: currentNormals, textureCoords: currentTextureCoords) {
                    shapes.append(s)
                }

                scanner.scanUpToCharactersFromSet(self.dynamicType.newLineCharacters, intoString: &currentName)
                moveToNextLine()
                continue
            }
        }

        if let s = self.dynamicType.buildShape(currentName, vertices: currentVertices, normals: currentNormals, textureCoords: currentTextureCoords) {
            shapes.append(s)
        }

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

    private static func buildShape(name: NSString?, vertices: [[Double]], normals: [[Double]], textureCoords: [[Double]]) -> Shape? {
        if vertices.count == 0 && normals.count == 0 && textureCoords.count == 0 {
            return nil
        }

        return Shape(name: (name as String?), vertices: vertices, normals: normals, textureCoords: textureCoords)
    }

    private func moveToNextLine() {
        scanner.scanUpToCharactersFromSet(self.dynamicType.newLineCharacters, intoString: nil)
        scanner.scanCharactersFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet(), intoString: nil)
    }
}