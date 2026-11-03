import SheepChaseUI
import SwiftUI

struct DiceHelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onUseExample: (String) -> Void

    private let examples = [
        ("d20", "一颗 d20"),
        ("1d20+5", "一颗 d20 加 5"),
        ("2d6+3", "两颗 d6 加 3"),
        ("4d6", "四颗 d6"),
        ("1d20+1d4+2", "多段骰子 + 加值"),
        ("优势 1d20+5", "一次优势检定"),
        ("adv 1d20+5", "一次优势检定"),
        ("优势 2d20+3", "两次独立优势检定"),
        ("劣势 2d20", "两次独立劣势检定"),
        ("dis 1d20+5", "一次劣势检定"),
    ]

    var body: some View {
        BookFormSheet(
            title: "骰子指令帮助",
            primaryTitle: "完成",
            onCancel: { dismiss() },
            onPrimary: { dismiss() }
        ) {
            BookFormSection("基本格式") {
                Text("NdM±K")
                    .bookUI(14, weight: .semibold, monospaced: true)
                    .foregroundStyle(Theme.red)
                Text("N 是骰子数量，M 是骰子面数，K 是加值。N 省略表示 1，K 可以为正、负或省略。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("支持多段骰子用 + 或 - 连接，例如 1d20+1d4+2。空格、大小写都可以。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
            }

            BookFormSection("直接输入") {
                Text("直接在输入框写骰子表达式，不需要 /r、r、roll 等前缀。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("例如输入 1d20+5 或 优势 2d20+3，按回车或点右侧箭头。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
            }

            BookFormSection("优势 / 劣势") {
                Text("优势 / 劣势 / adv / dis")
                    .bookUI(13, weight: .medium, monospaced: true)
                    .foregroundStyle(Theme.red)
                Text("优势 1d20 会掷两颗 d20 取高；劣势取低。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("优势 2d20 表示两次独立检定：掷四颗 d20，两两取高，显示两个结果并分别加值，最后给出合计。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("劣势 2d20 同理，只是每组取低。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("目前优势/劣势只支持单一种 d20 表达式，不能和 d6 等其他骰子混用。")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }

            BookFormSection("全部示例（点击填入指令）") {
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

            BookFormSection("手动投掷") {
                Text("点击骰子按钮会逐个加入骰池；再点一次同一按钮会增加一颗。骰池里可以混合 d6、d8、d20 等不同骰子。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("点骰池标签上的减号可以移除一颗；加值用 +1/+2/+3/+5/-1/-2/-5 累加，旁边可归零。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("手动投掷默认收起；指令输入始终在顶部。")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }

            BookFormSection("投掷者") {
                Text("战斗界面的「投掷」按钮会带入当前对象名字；可以直接修改，也可以留空。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("从右下角骰子按钮打开时，投掷者默认为空。")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }

            BookFormSection("记录") {
                Text("左侧记录会保存每次的完整公式、投掷过程和最终结果；顶部「最近」区域显示最后一次结果。")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
                Text("每个开团保留最近 30 条，并进入快照和 JSON / Markdown 导出。")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }

            BookFormSection("限制") {
                Text("• 单次最多 50 颗骰子\n• 骰子面数 2–100\n• 加值 -999 到 +999\n• 不支持爆炸骰、kh/kl、脚本表达式\n• App 不自动判定命中、成功或大成功/大失败")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
        }
    }
}
