//
//  FixtureHelper.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 02/09/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import Foundation

enum FixtureLoadingErrors: ErrorType {
    case NotFound
}

class FixtureHelper {
    let bundle: NSBundle
    init() {
        bundle = self.dynamicType.loadBundle()
    }

    func loadObjFixture(name: String) throws -> String {
        guard let path = bundle.pathForResource(name, ofType: "obj") else {
            throw FixtureLoadingErrors.NotFound
        }

        let string = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
        
        return string as String
    }

    static private func loadBundle() -> NSBundle {
        return NSBundle(forClass: self)
    }
}

