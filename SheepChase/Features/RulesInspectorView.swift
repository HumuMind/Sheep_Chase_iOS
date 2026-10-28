import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct RulesInspector: View {
    @Environment(RunStore.self) private var store
    @State private var query = ""

    private var rules: [ContentPack.RuleCard] {
        guard !query.isEmpty else { return store.content.rules }
        return store.content.rules.filter { rule in
            rule.term.localizedCaseInsensitiveContains(query)
                || rule.summary.localizedCaseInsensitiveContains(query)
                || rule.category.localizedCaseInsensitiveContains(query)
                || rule.aliases.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    private var spells: [ContentPack.SpellCard] {
        guard !query.isEmpty else { return store.content.spells }
        return store.content.spells.filter { spell in
            spell.name.localizedCaseInsensitiveContains(query)
                || spell.summary.localizedCaseInsensitiveContains(query)
                || spell.aliases.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("速查")
                .font(.headline)
            Text("本冒险精选；不是完整 SRD。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索规则、法术或别名", text: $query)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1)
            )

            if query.isEmpty {
                Text("共 \(rules.count) 条规则 · \(spells.count) 个法术")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("找到 \(rules.count) 条规则 · \(spells.count) 个法术")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !rules.isEmpty {
                Text("规则")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.red)
                ForEach(rules) { rule in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.term)
                            .font(.body.weight(.medium))
                        Text(rule.category + " · " + rule.pageRef)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(rule.summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    Divider()
                }
            }

            if !spells.isEmpty {
                Text("法术")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.red)
                ForEach(spells) { spell in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spell.name)
                            .font(.body.weight(.medium))
                        Text("\(spell.level) 环 · \(spell.castingTime) · \(spell.duration)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(spell.summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    Divider()
                }
            }

            if rules.isEmpty && spells.isEmpty {
                Text("没有匹配项。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
        }
    }
}
