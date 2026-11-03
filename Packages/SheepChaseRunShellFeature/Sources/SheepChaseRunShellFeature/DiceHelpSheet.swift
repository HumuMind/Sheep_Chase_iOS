import SheepChaseUI
import SwiftUI

struct DiceHelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onUseExample: (String) -> Void

    private let examples = [
        ("d20", "投一颗 d20"),
        ("1d20+5", "一颗 d20，加 5"),
        ("2d6+3", "两颗 d6，加 3"),
        ("4d6", "四颗 d6"),
        ("1d20+1d4+2", "多段骰子 + 加值"),
        ("优势 2d20+3", "两次独立优势检定"),
    ]

    var body: some View {
        BookFormSheet(
            title: "骰子指令帮助",
            primaryTitle: "完成",
            onCancel: { dismiss() },
            onPrimary: { dismiss() }
        ) {
            BookFormSection("基础语法") {
                Text("输入 NdM+K：N 是骰子数量，M 是面数，K 是加值。N 和 K 可以省略。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("也可以加前缀：/r、r、roll、掷、投、骰。例如 /r 1d20+5。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
            }

            BookFormSection("示例（点击填入）") {
                ForEach(examples, id: \.0) { example, description in
                    Button {
                        onUseExample(example)
                        dismiss()
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(example)
                                .bookUI(12, weight: .medium, monospaced: true)
                                .foregroundStyle(Theme.red)
                            Text(description)
                                .bookUI(11)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "arrow.up.left")
                                .bookUI(10)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            BookFormSection("优势 / 劣势") {
                Text("优势 1d20 会掷两颗 d20 取高；劣势取低。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("优势 2d20 表示两次独立的优势检定：掷四颗 d20，两两取高，显示两个结果并求和。")
                    .bookUI(12)
                    .foregroundStyle(Theme.red)
                Text("加值会分别作用于每一次 d20 结果。例如 优势 2d20+3。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("优势/劣势目前只支持单一种 d20 表达式，不能和 d6 等其他骰子混用。")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }

            BookFormSection("限制") {
                Text("• 单次最多 50 颗骰子\n• 骰子面数 2–100\n• 加值 -999 到 +999\n• 不支持爆炸骰、kh/kl、脚本表达式")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
        }
    }
}
