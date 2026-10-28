import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import Foundation

public enum AppVersion {
    public static var short: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.1.0"
    }

    public static var build: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
    }
}
