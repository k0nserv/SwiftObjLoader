//
//  MaterialLoader.swift
//  SwiftObjLoader
//
//  Created by Hugo Tunius on 04/10/15.
//  Copyright © 2015 Hugo Tunius. All rights reserved.
//

import Foundation

public enum MaterialLoadingError: ErrorType {
    case UnexpectedFileFormat(error: String)
}

public class MaterialLoader {

    // Represent the state of parsing
    // at any point in time
    struct State {
        var materialName: NSString?
        var ambientColor: Color?
        var diffuseColor: Color?
        var specularColor: Color?
        var specularExponent: Double?
        var illuminationModel: IlluminationModel?
        var ambientTextureMapFilePath: NSString?
        var diffuseTextureMapFilePath: NSString?

        func isDirty() -> Bool {
            if materialName != nil {
                return true
            }

            if ambientColor != nil {
                return true
            }

            if diffuseColor != nil {
                return true
            }

            if specularColor != nil {
                return true
            }

            if specularExponent != nil {
                return true
            }

            if illuminationModel != nil {
                return true
            }

            if ambientTextureMapFilePath != nil {
                return true
            }

            if diffuseTextureMapFilePath != nil {
                return true
            }

            return false
        }
    }

    // Source markers
    private static let newMaterialMarker       = "newmtl"
    private static let ambientColorMarker      = "Ka"
    private static let diffuseColorMarker      = "Kd"
    private static let specularColorMarker     = "Ks"
    private static let specularExponentMarker  = "Ns"
    private static let illuminationModeMarker  = "illum"
    private static let ambientTextureMapMarker = "map_Ka"
    private static let diffuseTextureMapMarker = "map_Kd"

    private let scanner: MaterialScanner
    private let basePath: NSString
    private var state: State

    // Init an MaterialLoader with the
    // source of the .mtl file as a string
    //
    public init(source: String, basePath: NSString) {
        self.basePath = basePath
        scanner = MaterialScanner(source: source)
        state = State()
    }

    // Read the specified source.
    // This operation is singled threaded and
    // should not be invoked again before
    // the call has returned
    func read() throws -> [Material] {
        resetState()
        var materials: [Material] = []

        do {
            while scanner.dataAvailable {
                let marker = scanner.readMarker()

                guard let m = marker where m.length > 0 else {
                    scanner.moveToNextLine()
                    continue
                }

                if MaterialLoader.isAmbientColor(m) {
                    let color = try readColor()
                    state.ambientColor = color

                    scanner.moveToNextLine()
                    continue
                } else if MaterialLoader.isDiffuseColor(m) {
                    let color = try readColor()
                    state.diffuseColor = color

                    scanner.moveToNextLine()
                    continue
                } else if MaterialLoader.isSpecularColor(m) {
                    let color = try readColor()
                    state.specularColor = color

                    scanner.moveToNextLine()
                    continue
                } else if MaterialLoader.isSpecularExponent(m) {
                    let specularExponent = try readSpecularExponent()

                    state.specularExponent = specularExponent

                    scanner.moveToNextLine()
                    continue
                } else if MaterialLoader.isIlluminationMode(m) {
                    let model = try readIlluminationModel()
                    state.illuminationModel = model

                    scanner.moveToNextLine()
                    continue
                } else if MaterialLoader.isAmbientTextureMap(m) {
                    let mapFilename = try readFilename()
                    state.ambientTextureMapFilePath = basePath.stringByAppendingPathComponent(mapFilename as String)

                    scanner.moveToNextLine()
                    continue
                } else if MaterialLoader.isDiffuseTextureMap(m) {
                    let mapFilename = try readFilename()
                    state.diffuseTextureMapFilePath = basePath.stringByAppendingPathComponent(mapFilename as String)

                    scanner.moveToNextLine()
                    continue
                } else if MaterialLoader.isNewMaterial(m) {
                    if let material = buildMaterial() {
                        materials.append(material)
                    }

                    state = State()
                    state.materialName = scanner.readLine()
                    scanner.moveToNextLine()
                    continue
                } else {
                    scanner.readLine()
                    scanner.moveToNextLine()
                    continue
                }
            }
            if let material = buildMaterial() {
                materials.append(material)
            }

            state = State()
        }

        return materials
    }

    private func resetState() {
        scanner.reset()
        state = State()
    }

    private static func isNewMaterial(marker: NSString) -> Bool {
        return marker == newMaterialMarker
    }

    private static func isAmbientColor(marker: NSString) -> Bool {
        return marker == ambientColorMarker
    }

    private static func isDiffuseColor(marker: NSString) -> Bool {
        return marker == diffuseColorMarker
    }

    private static func isSpecularColor(marker: NSString) -> Bool {
        return marker == specularColorMarker
    }

    private static func isSpecularExponent(marker: NSString) -> Bool {
        return marker == specularExponentMarker
    }

    private static func isIlluminationMode(marker: NSString) -> Bool {
        return marker == illuminationModeMarker
    }

    private static func isAmbientTextureMap(marker: NSString) -> Bool {
        return marker == ambientTextureMapMarker
    }

    private static func isDiffuseTextureMap(marker: NSString) -> Bool {
        return marker == diffuseTextureMapMarker
    }

    private func readColor() throws -> Color {
        do {
            return try scanner.readColor()
        } catch ScannerErrors.InvalidData(let error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        } catch ScannerErrors.UnreadableData(let error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    private func readIlluminationModel() throws -> IlluminationModel {
        do {
            let value = try scanner.readInt()
            if let model = IlluminationModel(rawValue: Int(value)) {
                return model
            }

            throw MaterialLoadingError.UnexpectedFileFormat(error: "Invalid illumination model: \(value)")
        } catch ScannerErrors.InvalidData(let error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    private func readSpecularExponent() throws -> Double {
        do {
            let value = try scanner.readDouble()

            guard value >= 0.0 && value <= 1000.0 else {
                throw MaterialLoadingError.UnexpectedFileFormat(error: "Invalid Ns value: !(value)")
            }

            return value
        } catch ScannerErrors.InvalidData(let error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    private func readFilename() throws -> NSString {
        do {
            return try scanner.readString()
        } catch ScannerErrors.InvalidData(let error) {
            throw MaterialLoadingError.UnexpectedFileFormat(error: error)
        }
    }

    private func buildMaterial() -> Material? {
        guard state.isDirty() else {
            return nil
        }

        return Material() {
            $0.name              = self.state.materialName
            $0.ambientColor      = self.state.ambientColor
            $0.diffuseColor      = self.state.diffuseColor
            $0.specularColor     = self.state.specularColor
            $0.specularExponent  = self.state.specularExponent
            $0.illuminationModel = self.state.illuminationModel
            $0.ambientTextureMapFilePath = self.state.ambientTextureMapFilePath
            $0.diffuseTextureMapFilePath = self.state.diffuseTextureMapFilePath

            return $0
        }
    }
}