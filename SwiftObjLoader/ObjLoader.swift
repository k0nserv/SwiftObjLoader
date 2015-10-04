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

    private let scanner: ObjScanner
    private var running: Bool = false

    private var state = State()
    private var vertexCount = 0
    private var normalCount = 0
    private var textureCoordCount = 0

    // Init an objloader with the
    // source of the .obj file as a string
    //
    init(source: String) {
        scanner = ObjScanner(source: source)
    }

    // Read the specified source.
    // This operation is singled threaded and
    // should not be invoked again before
    // the call has returned
    func read() throws -> [Shape] {
        running = true
        var shapes: [Shape] = []

        resetState()

        do {
            while scanner.dataAvailable {
                let marker = scanner.readMarker()

                guard let m = marker where m.length > 0 else {
                    scanner.moveToNextLine()
                    continue
                }

                if ObjLoader.isComment(m) {
                    scanner.moveToNextLine()
                    continue
                } else if ObjLoader.isVertex(m) {
                    if let v = try readVertex() {
                        state.vertices.append(v)
                    }

                    scanner.moveToNextLine()
                    continue
                } else if ObjLoader.isNormal(m) {
                    if let n = try readVertex() {
                        state.normals.append(n)
                    }

                    scanner.moveToNextLine()
                    continue
                } else if ObjLoader.isTextureCoord(m) {
                    if let vt = scanner.readTextureCoord() {
                        state.textureCoords.append(vt)
                    }

                    scanner.moveToNextLine()
                    continue
                } else if ObjLoader.isObject(m) {
                    if let s = buildShape(state.objectName, vertices: state.vertices, normals: state.normals, textureCoords: state.textureCoords, faces: state.faces) {
                        shapes.append(s)
                    }

                    state = State()
                    state.objectName = scanner.readLine()
                    scanner.moveToNextLine()
                    continue
                } else if ObjLoader.isFace(m) {
                    if let indices = try scanner.readFace() {
                        state.faces.append(normalizeVertexIndices(indices))
                    }

                    scanner.moveToNextLine()
                    continue
                } else {
                    scanner.moveToNextLine()
                    continue
                }
            }

            if let s = buildShape(state.objectName, vertices: state.vertices, normals: state.normals, textureCoords: state.textureCoords, faces: state.faces) {
                shapes.append(s)
            }
            state = State()

            running = false
        } catch let e {
            running = false
            resetState()
            throw e
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

    private static func isTextureCoord(marker: NSString) -> Bool {
        return marker.length == 2 && marker.substringToIndex(2) == textureCoordMarker
    }

    private static func isObject(marker: NSString) -> Bool {
        return marker.length == 1 && marker.characterAtIndex(0) == objectMarker
    }

    private static func isFace(marker: NSString) -> Bool {
        return marker.length == 1 && marker.characterAtIndex(0) == faceMarker
    }

    private func readVertex() throws -> [Double]? {
        do {
            return try scanner.readVertex()
        } catch ScannerErrors.UnreadableData(let error) {
            throw ObjLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    private func resetState() {
        scanner.reset()
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

    private func normalizeVertexIndices(unnormalizedIndices: [VertexIndex]) -> [VertexIndex] {
        return unnormalizedIndices.map {
            return VertexIndex(vIndex: ObjLoader.normalizeIndex($0.vIndex, count: vertexCount),
                nIndex: ObjLoader.normalizeIndex($0.nIndex, count: normalCount),
                tIndex: ObjLoader.normalizeIndex($0.tIndex, count: textureCoordCount))
        }
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