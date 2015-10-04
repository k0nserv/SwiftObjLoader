//
//  Scanner.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 07/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import Foundation

enum ScannerErrors: ErrorType {
    case UnreadableData(error: String)
}

// A general Scanner for .obj and .tml files
class Scanner {
    var dataAvailable: Bool {
        get {
            return false == scanner.atEnd
        }
    }

    private let scanner: NSScanner
    private let source: String

    init(source: String) {
        scanner = NSScanner(string: source)
        self.source = source
        scanner.charactersToBeSkipped = NSCharacterSet.whitespaceCharacterSet()
    }

    func moveToNextLine() {
        scanner.scanUpToCharactersFromSet(NSCharacterSet.newlineCharacterSet(), intoString: nil)
        scanner.scanCharactersFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet(), intoString: nil)
    }

    // Read from current scanner location up to the next
    // whitespace
    func readMarker() -> NSString? {
        var marker: NSString?
        scanner.scanUpToCharactersFromSet(NSCharacterSet.whitespaceCharacterSet(), intoString: &marker)

        return marker
    }

    // Read rom the current scanner location till the end of the line
    func readLine() -> NSString? {
        var string: NSString?
        scanner.scanUpToCharactersFromSet(NSCharacterSet.newlineCharacterSet(), intoString: &string)
        return string
    }

    // Read 3(optionally 4) space separated double values from the scanner
    // The fourth w value defaults to 1.0 if not present
    // Example:
    //  19.2938 1.29019 0.2839
    //  1.29349 -0.93829 1.28392 0.6
    //
    func readVertex() throws -> [Double]? {
        var x = Double.infinity
        var y = Double.infinity
        var z = Double.infinity
        var w = 1.0

        guard scanner.scanDouble(&x) else {
            throw ScannerErrors.UnreadableData(error: "Unexecpted vertex definitions missing x component")
        }

        guard scanner.scanDouble(&y) else {
            throw ScannerErrors.UnreadableData(error: "Unexecpted vertex definitions missing y component")
        }

        guard scanner.scanDouble(&z) else {
            throw ScannerErrors.UnreadableData(error: "Unexecpted vertex definitions missing z component")
        }

        scanner.scanDouble(&w)

        return [x, y, z, w]
    }

    // Read 1, 2 or 3 texture coords from the scanner
    func readTextureCoord() -> [Double]? {
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

    func reset() {
        scanner.scanLocation = 0
    }
}

// A Scanner with specific logic for .obj
// files. Inherits common logic from Scanner
class ObjScanner: Scanner {
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
    func readFace() throws -> [VertexIndex]? {
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

            result.append(VertexIndex(vIndex: v, nIndex: vn, tIndex: vt))
        }

        return result
    }
}