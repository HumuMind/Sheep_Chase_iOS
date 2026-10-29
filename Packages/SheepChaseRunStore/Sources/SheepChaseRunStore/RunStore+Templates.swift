import Foundation
import SheepChaseCore
import SheepChasePersistence

public enum TemplateStoreError: LocalizedError {
    case emptyName
    case emptyPatch
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyName: "请填写模组名称。"
        case .emptyPatch: "当前没有可保存的模组改动。"
        case .saveFailed(let message): "保存模组失败：\(message)"
        }
    }
}

@MainActor
extension RunStore {
    public var orderedTemplates: [AdventureTemplate] {
        templates.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func template(id: UUID?) -> AdventureTemplate? {
        guard let id else { return nil }
        return templates.first { $0.id == id }
    }

    @discardableResult
    public func saveRunAsTemplate(
        from run: RunRecord,
        name: String,
        summary: String,
        options: TemplateSaveOptions = TemplateSaveOptions()
    ) throws -> AdventureTemplate {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TemplateStoreError.emptyName }

        let patch = AdventureTemplatePatch(
            annotations: options.includeAnnotations ? run.annotations : [],
            customBeats: options.includeCustomContent ? run.customBeats : [],
            customNPCs: options.includeCustomContent ? run.customNPCs : [],
            customMonsters: options.includeCustomContent ? run.customMonsters : [],
            customMapPins: options.includeMapPins ? run.customMapPins : [],
            encounterAdjustments: options.includeEncounterAdjustments ? run.encounterAdjustments : [],
            monsterOverrides: options.includeEncounterAdjustments ? run.monsterOverrides : []
        )
        guard !patch.isEmpty else { throw TemplateStoreError.emptyPatch }

        let template = AdventureTemplate(
            name: trimmed,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            baseModuleID: content.manifest.id,
            baseModuleTitle: content.manifest.title,
            baseContentVersion: content.manifest.version,
            patch: patch
        )
        templates.insert(template, at: 0)
        do {
            try templateRepository.save(templates)
        } catch {
            templates.removeAll { $0.id == template.id }
            throw TemplateStoreError.saveFailed(error.localizedDescription)
        }
        notify("已保存我的模组：\(template.name)")
        return template
    }

    public func renameTemplate(_ template: AdventureTemplate, to name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TemplateStoreError.emptyName }
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[index].name = trimmed
        templates[index].updatedAt = .now
        do {
            try templateRepository.save(templates)
        } catch {
            throw TemplateStoreError.saveFailed(error.localizedDescription)
        }
        notify("模组已重命名")
    }

    public func deleteTemplate(_ template: AdventureTemplate) {
        templates.removeAll { $0.id == template.id }
        try? templateRepository.save(templates)
        notify("已删除我的模组：\(template.name)")
    }

    public func createRun(name: String, from template: AdventureTemplate?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let run = RunRecord(
            name: trimmedName.isEmpty ? "未命名开团" : trimmedName,
            sceneID: scenes.first?.id ?? "scene-1",
            beatID: scenes.first?.beats.first?.id ?? "",
            contentVersion: content.manifest.version
        )

        if let template {
            let patch = template.patch
            run.annotations = patch.annotations
            run.customBeats = patch.customBeats
            run.customNPCs = patch.customNPCs
            run.customMonsters = patch.customMonsters
            run.customMapPins = patch.customMapPins
            run.encounterAdjustments = patch.encounterAdjustments
            run.monsterOverrides = patch.monsterOverrides
            run.sourceTemplateID = template.id
            run.sourceTemplateName = template.name
            run.sourceTemplateBaseVersion = template.baseContentVersion
        }

        repository.insert(run)
        runs.append(run)
        selectedRunID = run.id
        selectedTab = .party
        persist()

        if let template, template.baseContentVersion != content.manifest.version {
            notify("已使用「\(template.name)」创建开团；模板基于 \(template.baseContentVersion)，当前内容包为 \(content.manifest.version)")
        } else if let template {
            notify("已从「\(template.name)」创建开团")
        } else {
            notify("已创建空白开团")
        }
    }
}
