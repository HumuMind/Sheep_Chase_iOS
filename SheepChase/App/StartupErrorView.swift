import SheepChaseUI
import SwiftUI

/// 启动失败时的兜底界面，替代 fatalError，避免用户只看到崩溃。
struct StartupErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 34))
                .foregroundStyle(Theme.red)
            Text("《荒野逐羊》无法启动")
                .bookSerif(18, weight: .semibold)
                .foregroundStyle(Theme.ink)
            Text(message)
                .bookUI(12)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Text("数据仍保存在本机；修复后重新打开 App 即可继续。")
                .bookUI(11)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BookPaperBackground())
    }
}
