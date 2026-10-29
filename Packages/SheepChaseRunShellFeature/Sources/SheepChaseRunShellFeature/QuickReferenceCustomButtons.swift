import SwiftUI
import SheepChaseUI

extension QuickReferencePanel {
    var customNPCButton: some View {
        Button {
            showAddNPC = true
        } label: {
            Label("＋ 自定义人物", systemImage: "person.badge.plus")
                .font(.caption)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Theme.red)
        .padding(.top, 2)
    }

    var customMonsterButton: some View {
        Button {
            showAddMonster = true
        } label: {
            Label("＋ 自定义怪物", systemImage: "pawprint.fill")
                .font(.caption)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Theme.red)
        .padding(.top, 2)
    }
}
