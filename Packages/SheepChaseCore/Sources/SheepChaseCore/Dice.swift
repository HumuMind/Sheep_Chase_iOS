import Foundation

public enum DiceMode: String, Codable, CaseIterable, Hashable {
    case normal
    case advantage
    case disadvantage

    public var title: String {
        switch self {
        case .normal: "普通"
        case .advantage: "优势"
        case .disadvantage: "劣势"
        }
    }
}

public struct DiceTerm: Codable, Hashable {
    public var count: Int
    public var sides: Int

    public init(count: Int = 1, sides: Int) {
        self.count = count
        self.sides = sides
    }
}

public struct DiceExpression: Codable, Hashable {
    public var terms: [DiceTerm]
    public var modifier: Int
    public var mode: DiceMode

    public init(terms: [DiceTerm], modifier: Int = 0, mode: DiceMode = .normal) {
        self.terms = terms
        self.modifier = modifier
        self.mode = mode
    }
}

public struct DiceCheck: Codable, Hashable {
    public var rawRolls: [Int]
    public var kept: Int
    public var total: Int

    public init(rawRolls: [Int], kept: Int, total: Int) {
        self.rawRolls = rawRolls
        self.kept = kept
        self.total = total
    }
}

public struct DiceRoll: Identifiable, Codable, Hashable {
    public var id: UUID
    public var command: String
    public var mode: DiceMode
    public var checks: [DiceCheck]
    public var total: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        command: String,
        mode: DiceMode,
        checks: [DiceCheck],
        total: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.command = command
        self.mode = mode
        self.checks = checks
        self.total = total
        self.createdAt = createdAt
    }

    public var detail: String {
        if mode == .normal {
            guard let check = checks.first else { return command }
            return "\(check.rawRolls.map(String.init).joined(separator: " + ")) = \(check.total)"
        }
        return checks.map { check in
            let modifier = check.total - check.kept
            let modifierText = modifier >= 0 ? "+ \(modifier)" : "- \(abs(modifier))"
            return "[\(check.rawRolls.map(String.init).joined(separator: " | "))] 取 \(check.kept) \(modifierText) = \(check.total)"
        }.joined(separator: "\n")
    }
}

public enum DiceParseError: LocalizedError, Equatable {
    case empty
    case invalidCharacter
    case missingDice
    case invalidCount
    case invalidSides
    case tooManyDice
    case invalidModifier
    case advantageNeedsD20

    public var errorDescription: String? {
        switch self {
        case .empty: "请输入骰子指令。"
        case .invalidCharacter: "指令里有无法识别的字符。"
        case .missingDice: "至少需要一颗骰子，例如 1d20。"
        case .invalidCount: "骰子数量需要在 1–50 之间。"
        case .invalidSides: "骰子面数需要在 2–100 之间。"
        case .tooManyDice: "单次最多投 50 颗骰子。"
        case .invalidModifier: "加值需要在 -999 到 +999 之间。"
        case .advantageNeedsD20: "优势/劣势只支持单一种 d20 表达式，例如 优势 2d20+3。"
        }
    }
}

public enum DiceParser {
    public static func parse(_ input: String) -> Result<DiceExpression, DiceParseError> {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .failure(.empty) }

        let lower = text.lowercased()
        for prefix in ["/r", "roll", "r", "掷", "投", "骰"] where lower.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            break
        }

        var mode: DiceMode = .normal
        let modeLower = text.lowercased()
        for (prefix, value) in [("优势", DiceMode.advantage), ("劣势", DiceMode.disadvantage), ("adv", .advantage), ("dis", .disadvantage)]
        where modeLower.hasPrefix(prefix) {
            mode = value
            text = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            break
        }

        text = text.replacingOccurrences(of: " ", with: "")
        guard !text.isEmpty else { return .failure(.empty) }

        var terms: [DiceTerm] = []
        var modifier = 0
        var index = text.startIndex
        var sign = 1
        var totalDice = 0

        while index < text.endIndex {
            let character = text[index]
            if character == "+" {
                sign = 1
                index = text.index(after: index)
                continue
            }
            if character == "-" {
                sign = -1
                index = text.index(after: index)
                continue
            }

            var countText = ""
            while index < text.endIndex, text[index].isNumber {
                countText.append(text[index])
                index = text.index(after: index)
            }

            if index < text.endIndex, text[index] == "d" || text[index] == "D" {
                index = text.index(after: index)
                var sidesText = ""
                while index < text.endIndex, text[index].isNumber {
                    sidesText.append(text[index])
                    index = text.index(after: index)
                }
                guard !sidesText.isEmpty, let sides = Int(sidesText) else {
                    return .failure(.invalidSides)
                }
                let count = countText.isEmpty ? 1 : Int(countText) ?? 0
                guard count >= 1 else { return .failure(.invalidCount) }
                guard (2...100).contains(sides) else { return .failure(.invalidSides) }
                totalDice += count
                guard totalDice <= 50 else { return .failure(.tooManyDice) }
                terms.append(DiceTerm(count: count, sides: sides))
                sign = 1
            } else {
                guard !countText.isEmpty, let value = Int(countText) else {
                    return .failure(.missingDice)
                }
                modifier += sign * value
                guard abs(modifier) <= 999 else { return .failure(.invalidModifier) }
                sign = 1
            }

            if index < text.endIndex, text[index] != "+", text[index] != "-" {
                return .failure(.invalidCharacter)
            }
        }

        guard !terms.isEmpty else { return .failure(.missingDice) }
        if mode != .normal {
            guard terms.count == 1, terms[0].sides == 20 else {
                return .failure(.advantageNeedsD20)
            }
        }
        return .success(DiceExpression(terms: terms, modifier: modifier, mode: mode))
    }
}

public enum DiceRoller {
    public static func roll(
        _ expression: DiceExpression,
        command: String,
        die: (Int) -> Int = { sides in Int.random(in: 1...sides) }
    ) -> DiceRoll {
        if expression.mode == .normal {
            var raw: [Int] = []
            for term in expression.terms {
                for _ in 0..<term.count {
                    raw.append(die(term.sides))
                }
            }
            let total = raw.reduce(0, +) + expression.modifier
            return DiceRoll(
                command: command,
                mode: .normal,
                checks: [DiceCheck(rawRolls: raw, kept: raw.reduce(0, +), total: total)],
                total: total
            )
        }

        let term = expression.terms[0]
        var checks: [DiceCheck] = []
        for _ in 0..<term.count {
            let pair = [die(20), die(20)]
            let kept = expression.mode == .advantage ? pair.max()! : pair.min()!
            checks.append(
                DiceCheck(
                    rawRolls: pair,
                    kept: kept,
                    total: kept + expression.modifier
                )
            )
        }
        return DiceRoll(
            command: command,
            mode: expression.mode,
            checks: checks,
            total: checks.reduce(0) { $0 + $1.total }
        )
    }
}
