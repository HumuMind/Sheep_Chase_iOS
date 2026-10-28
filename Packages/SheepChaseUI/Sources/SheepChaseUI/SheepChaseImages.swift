import SwiftUI

public enum SheepChaseImages {
    public static var cover: Image {
        Image("Cover", bundle: .module)
    }

    public static var map: Image {
        Image("Map", bundle: .module)
    }

    public static var sheep: Image {
        Image("Sheep", bundle: .module)
    }

    public static var parchment: Image {
        Image("Parchment", bundle: .module)
    }

    public static func image(forAssetID id: String) -> Image? {
        switch id {
        case "cover": cover
        case "map-treehouse": map
        case "sheep-illustration": sheep
        default: nil
        }
    }
}
