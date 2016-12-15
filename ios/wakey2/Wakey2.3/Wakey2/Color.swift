//
//  Color.swift
//  Wakey2
//
//  Created by Eric Czech on 12/14/16.
//  Copyright © 2016 Eric Czech. All rights reserved.
//

import Foundation

public struct Color: Equatable, CustomStringConvertible {
    static let maxHue: Double = 360.0
    static let defaultKelvin: Int = 3500
    
    public let hue: Double
    public let saturation: Double
    public let kelvin: Int
    
    public init(hue: Double, saturation: Double, kelvin: Int) {
        self.hue = hue
        self.saturation = saturation
        self.kelvin = kelvin
    }
    
    public static func color(hue: Double, saturation: Double) -> Color {
        return Color(hue: hue, saturation: saturation, kelvin: Color.defaultKelvin)
    }
    
    public static func white(kelvin: Int) -> Color {
        return Color(hue: 0.0, saturation: 0.0, kelvin: kelvin)
    }
    
    public var isColor: Bool {
        return !isWhite
    }
    
    public var isWhite: Bool {
        return saturation == 0.0
    }
    
    func toQueryStringValue() -> String {
        if isWhite {
            return "kelvin:\(kelvin)"
        } else {
            return "hue:\(hue) saturation:\(saturation)"
        }
    }
    
    // MARK: Printable
    public var description: String {
        return "<Color hue: \(hue), saturation: \(saturation), kelvin: \(kelvin)>"
    }
}

public func ==(lhs: Color, rhs: Color) -> Bool {
    return lhs.hue == rhs.hue &&
        lhs.saturation == rhs.saturation &&
        lhs.kelvin == rhs.kelvin
}
