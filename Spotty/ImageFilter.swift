//
//  ImageFilter.swift
//  Spotty
//
//  Created by Cameron Eubank on 9/20/16.
//  Copyright © 2016 Cameron Eubank. All rights reserved.
//

import Foundation

class ImageFilter: NSObject{
    var name: String?
    var intensity: Float?
    
    init(name: String, intensity: Float) {
        self.name = name
        self.intensity = intensity
    }

    struct filters{
        static let none = ImageFilter(name: "CISepiaTone", intensity: 0.0)
        static let sepia = ImageFilter(name: "CISepiaTone", intensity: 0.5)
        static let xRay = ImageFilter(name: "CIXRay", intensity: 0.1)
        static let circularScreen = ImageFilter(name: "CICircularScreen", intensity: 0.2)
        static let halfTone = ImageFilter(name: "CICMYKHalftone", intensity: 0.2)
        static let dotScreen = ImageFilter(name: "CIDotScreen", intensity: 0.3)
        static let edges = ImageFilter(name: "CIEdges", intensity: 0.3)
        static let edgeWork = ImageFilter(name: "CIEdgeWork", intensity: 0.2)
        static let falseColor = ImageFilter(name: "CIFalseColor", intensity: 0.3)
        static let hatchedScreen = ImageFilter(name: "CIHatchedScreen", intensity: 0.2)
        static let heightField = ImageFilter(name: "CIHeightFieldFromMask", intensity: 0.3)
        static let pixels = ImageFilter(name: "CIHexagonalPixellate", intensity: 0.3)
        static let toneCurve = ImageFilter(name: "CILinearToSRGBToneCurve", intensity: 0.2)
        static let lineOverlay = ImageFilter(name: "CILineOverlay", intensity: 0.3)
        static let lineScreen = ImageFilter(name: "CILineScreen", intensity: 0.2)
        static let maskToAlpha = ImageFilter(name: "CIMaskToAlpha", intensity: 0.3)
        static let maxComponent = ImageFilter(name: "CIMaximumComponent", intensity: 0.3)
        static let minComponent = ImageFilter(name: "CIMinimumComponent", intensity: 0.2)
        static let chrome = ImageFilter(name: "CIPhotoEffectChrome", intensity: 0.3)
        static let fade = ImageFilter(name: "CIPhotoEffectFade", intensity: 0.2)
        static let instant = ImageFilter(name: "CIPhotoEffectInstant", intensity: 0.3)
        static let mono = ImageFilter(name: "CIPhotoEffectMono", intensity: 0.3)
        static let noir = ImageFilter(name: "CIPhotoEffectNoir", intensity: 0.2)
        static let process = ImageFilter(name: "CIPhotoEffectProcess", intensity: 0.3)
        static let tonal = ImageFilter(name: "CIPhotoEffectTonal", intensity: 0.2)
        static let transfer = ImageFilter(name: "CIPhotoEffectTransfer", intensity: 0.3)
        static let spotColor = ImageFilter(name: "CISpotColor", intensity: 0.2)
        static let linearCurve = ImageFilter(name: "CISRGBToneCurveToLinear", intensity: 0.3)
        static let thermal = ImageFilter(name: "CIThermal", intensity: 0.2)
    }
}
