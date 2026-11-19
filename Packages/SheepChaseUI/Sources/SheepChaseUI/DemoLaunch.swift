#if DEBUG
import Foundation

/// Debug 构建下由启动参数触发的演示 / 截图入口。
/// 参数键集中在这里，视图代码只读取命名属性，避免散落的字符串比较。
public enum DemoLaunch {
    private static let arguments = Set(ProcessInfo.processInfo.arguments)

    public static func has(_ flag: String) -> Bool {
        arguments.contains(flag)
    }

    public static var openRun: Bool { has("-demoRun") }
    public static var resetsPinnedReferences: Bool { has("-resetPins") }
    public static var showsSceneMode: Bool { has("-demoScene") }
    public static var showsMapMode: Bool { has("-demoMap") }
    public static var showsNotesTab: Bool { has("-demoNotes") }
    public static var showsBattleSetup: Bool { has("-demoBattle") }
    public static var startsActiveBattle: Bool { has("-demoBattleActive") }

    /// `-demoScene2` / `-demoScene3` / `-demoScene4`，用于截图指定场景。
    public static var sceneOverrideID: String? {
        for index in 2...4 where has("-demoScene\(index)") {
            return "scene-\(index)"
        }
        return nil
    }

    public static var npcID: String? { has("-demoNPC") ? "ahmed-noke" : nil }
    public static var handoutID: String? { has("-demoHandout") ? "scroll-speak-with-animals" : nil }
    public static var itemID: String? { has("-demoItem") ? "staff-of-true-polymorph" : nil }

    public static var showsSafetySheet: Bool { has("-demoSafety") }
    public static var showsSessionsSheet: Bool { has("-demoSessions") }
    public static var showsSearchSheet: Bool { has("-demoSearch") }
    public static var showsImageExport: Bool { has("-demoImageExport") }
    public static var showsSourceSheet: Bool { has("-demoSource") }
    public static var showsSaveTemplateSheet: Bool { has("-demoSaveTemplate") }
    public static var showsCustomNPCSheet: Bool { has("-demoCustomNPC") }
    public static var resetsQuickReference: Bool { has("-resetQuickReference") }
    public static var opensAnnotationEditor: Bool { has("-demoAnnotation") }
}
#endif
