//
//  ScannerTests.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 12/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import XCTest
@testable import SwiftObjLoader

class ScannerTests: XCTestCase {
    var scanner: Scanner!

    func testReadLine() {
        scanner = Scanner(source: "Test\nMore Test")
        XCTAssertEqual(scanner.readLine(), "Test")
        XCTAssertEqual(scanner.readLine(), nil)

        scanner = Scanner(source: "Test with spaces")
        XCTAssertEqual(scanner.readLine(), "Test with spaces")
    }

    func testMoveToNextLine() {
        scanner = Scanner(source: "\nTest")
        scanner.moveToNextLine()
        XCTAssertEqual(scanner.readLine(), "Test")
    }

    func testReadMarker() {
        scanner = Scanner(source: "v 0.21882 0.28391 1.0283")
        XCTAssertEqual(scanner.readMarker(), "v")

        scanner = Scanner(source: "vt 0.28192 0.782192")
        XCTAssertEqual(scanner.readMarker(), "vt")

        scanner = Scanner(source: "    v")
        XCTAssertEqual(scanner.readMarker(), "v")
    }

/*    func testReadVertex() {
        scanner = Scanner(source: "  1.0238 0.28382 1.023784\n")

        do {
            assertDoubleArrayEqual(try scanner.readVertex(), rhs: [1.0238, 0.28382, 1.023784, 1.0])
        } catch {
            XCTFail("Throw not expected")
        }

        scanner = Scanner(source: "1.02839")
        do {
            try scanner.readVertex()
            XCTFail("Throw was expected")
        } catch ScannerErrors.UnreadableData(let error) {
            let a = error as NSString
            let match = a.rangeOfString("missing y component")
            XCTAssertTrue(match.location != NSNotFound)
        } catch {
            XCTFail("ScannerErrors.UnreadableData was not thrown")
        }
    }
*/

    private func assertDoubleArrayEqual(lhs: [Double]?, rhs: [Double]?) {
        if lhs == nil && rhs == nil {
            return
        }

        XCTAssertNotNil(lhs)
        XCTAssertNotNil(rhs)
        XCTAssertEqual(lhs!.count, rhs!.count, "assertDoubleArrayEqual: Lengths not equal")

        for var i = 0; i < lhs!.count; i++ {
            XCTAssertEqualWithAccuracy(lhs![i], rhs![i], accuracy: 0.001,
                "Doubles lhs[\(i)] = \(lhs![i]) and rhs[\(i)] = \(rhs![i]) were not equal with accuracy")
        }
    }

}
