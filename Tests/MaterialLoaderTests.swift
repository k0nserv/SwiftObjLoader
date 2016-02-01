//
//  MaterialLoaderTests.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 01/02/16.
//  Copyright © 2016 Hugo Tunius. All rights reserved.
//

import XCTest
@testable import SwiftObjLoader

class MaterialLoaderTests: XCTestCase {
    var fixtureHelper: FixtureHelper!

    override func setUp() {
        fixtureHelper = FixtureHelper()
    }

    func testSimple() {
        let source = try? fixtureHelper.loadMtlFixture("simple")
        let loader = MaterialLoader(source: source!, basePath: "/home/user/myuser/path/to/project/")
        do {
            let materials = try loader.read()

            XCTAssertEqual(materials.count, 1)

            let material = materials[0]
            XCTAssertTrue(material.ambientColor.fuzzyEquals(Color.Black))
            XCTAssertTrue(material.diffuseColor.fuzzyEquals(
                Color(r: 0.595140, g:0.074891, b: 0.080111)
            ))
            XCTAssertTrue(material.specularColor.fuzzyEquals(Color(r: 0.5, g: 0.5, b: 0.5)))

            XCTAssertNotNil(material.specularExponent)
            XCTAssertEqualWithAccuracy(material.specularExponent!, 96.078431, accuracy: 0.001)
            XCTAssertEqual(material.illuminationModel, IlluminationModel.DiffuseSpecular)

            XCTAssertEqual(material.ambientTextureMapFilePath, "/home/user/myuser/path/to/project/test.bmp")
            XCTAssertEqual(material.diffuseTextureMapFilePath, "/home/user/myuser/path/to/project/test_diffuse.bmp")
        } catch ObjLoadingError.UnexpectedFileFormat(let errorMessage) {
            XCTFail("Parsing failed with error \(errorMessage)")
        } catch {
            XCTFail("Parsing failed with unknown error")
        }
    }
}
