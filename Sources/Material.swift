//
//  Material.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 04/10/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import Foundation

// From http://floating-point-gui.de/errors/comparison/
private func doubleEquality(a: Double, _ b: Double) -> Bool {
    let diff = abs(a - b)

    if a == b { // shortcut for infinities
        return true
    } else if (a == 0 || b == 0 || diff < DBL_MIN) {
        return diff < (1e-5 * DBL_MIN)
    } else {
        let absA = abs(a)
        let absB = abs(b)
        return diff / min((absA + absB), DBL_MAX) < 1e-5
    }
}

public struct Color {
    public static let Black = Color(r: 0.0, g: 0.0, b: 0.0)

    let r: Double
    let g: Double
    let b: Double

    func fuzzyEquals(other: Color) -> Bool {
        return doubleEquality(self.r, other.r) &&
               doubleEquality(self.g, other.g) &&
               doubleEquality(self.b, other.b)
    }
}

class MaterialBuilder {
    var name: NSString = ""
    var ambientColor: Color?
    var diffuseColor: Color?
    var specularColor: Color?
    var illuminationModel: IlluminationModel?
    var specularExponent: Double?
    var ambientTextureMapFilePath: NSString?
    var diffuseTextureMapFilePath: NSString?
}

public struct Material {
    let name: NSString
    let ambientColor: Color
    let diffuseColor: Color
    let specularColor: Color
    let illuminationModel: IlluminationModel
    let specularExponent: Double?
    let ambientTextureMapFilePath: NSString?
    let diffuseTextureMapFilePath: NSString?

    init(builderBlock: (MaterialBuilder) -> MaterialBuilder) {
        let builder = builderBlock(MaterialBuilder())

        if builder.name != nil {
            self.name = builder.name
        } else {
            self.name = nil
        }

        if let a = builder.ambientColor {
            self.ambientColor = a
        } else {
            self.ambientColor = Color.Black
        }

        if let d = builder.diffuseColor {
            self.diffuseColor = d
        } else {
            self.diffuseColor = Color.Black
        }

        if let s = builder.specularColor {
            self.specularColor = s
        } else {
            self.specularColor = Color.Black
        }

        if let i = builder.illuminationModel {
            self.illuminationModel = i
        } else {
            self.illuminationModel = .Constant
        }

        if let s = builder.specularExponent {
            self.specularExponent = s
        } else {
            self.specularExponent = nil
        }

        if let a = builder.ambientTextureMapFilePath {
            self.ambientTextureMapFilePath = a
        } else {
            self.ambientTextureMapFilePath = nil
        }

        if let d = builder.diffuseTextureMapFilePath {
            self.diffuseTextureMapFilePath = d
        } else {
            self.diffuseTextureMapFilePath = nil
        }
    }
}

public enum IlluminationModel: Int {
    // This is a constant color illumination model. The color is the specified Kd for the material. The formula is:
    // color = Kd
    case Constant = 0

    // This is a diffuse illumination model using Lambertian shading.
    // The color includes an ambient and diffuse shading terms for each light source. The formula is
    // color = KaIa + Kd { SUM j=1..ls, (N * Lj)Ij }
    case Diffuse = 1

    // This is a diffuse and specular illumination model using Lambertian shading
    // and Blinn's interpretation of Phong's specular illumination model (BLIN77).
    // The color includes an ambient constant term, and a diffuse and specular shading term for each light source. The formula is:
    // color = KaIa + Kd { SUM j=1..ls, (N*Lj)Ij } + Ks { SUM j=1..ls, ((H*Hj)^Ns)Ij }
    case DiffuseSpecular = 2

    // Term definitions are: Ia ambient light, Ij light j's intensity, Ka ambient reflectance, Kd diffuse reflectance,
    // Ks specular reflectance, H unit vector bisector between L and V, L unit light vector, N unit surface normal, V unit view vector
}
