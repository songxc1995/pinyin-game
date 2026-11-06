import Foundation

public struct CaughtButterfly: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(t)_\(lv)_\(s)_\(d)_\(uid)" }
    public var t: String
    public var lv: Int
    public var s: Int
    public var d: String
    public var uid: String

    enum CodingKeys: String, CodingKey {
        case t, lv, s, d, uid
    }

    public init(t: String, lv: Int, s: Int, d: String, uid: String = UUID().uuidString) {
        self.t = t
        self.lv = lv
        self.s = s
        self.d = d
        self.uid = uid
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.t = (try? c.decode(String.self, forKey: .t)) ?? "r"
        self.lv = (try? c.decode(Int.self, forKey: .lv)) ?? 1
        self.s = (try? c.decode(Int.self, forKey: .s)) ?? 1
        self.d = (try? c.decode(String.self, forKey: .d)) ?? GameProgress.todayString()
        self.uid = (try? c.decode(String.self, forKey: .uid)) ?? UUID().uuidString
    }
}

public struct HistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(d)|\(subj ?? "pinyin")|\(lv)|\(r)|\(t)|\(f ?? "mid")" }
    public var d: String
    public var subj: String?
    public var lv: Int
    public var s: Int
    public var r: Int
    public var t: Int
    public var f: String?
}

public struct StreakState: Codable, Equatable, Sendable {
    public var last: String
    public var n: Int
}

public struct TTSPreference: Codable, Equatable, Sendable {
    public var slow: Bool
}

public struct DailyProgress: Codable, Equatable, Sendable {
    public var d: String
    public var rounds: Int
    public var maxCombo: Int
    public var words: Int
    public var claimed: [String: Int]
}

public struct GameProgress: Codable, Equatable, Sendable {
    // 语文拼音进度
    public var unlocked: Int = 1
    public var stars: [String: Int] = [:]
    public var food: [String: Int] = [:]

    // 沪教版数学进度
    public var mathUnlocked: Int = 2
    public var mathStars: [String: Int] = [:]
    public var desserts: [String: Int] = [:]

    // 沪教牛津英语进度
    public var englishUnlocked: Int = 2
    public var englishStars: [String: Int] = [:]
    public var englishCards: [String: Int] = [:]

    // 是否开启自由选关（家长/小朋友可随时跳关练习教材对应单元）
    public var freeUnlockAll: Bool = true

    // 共享错题本、战绩、打卡、蝴蝶花园
    public var wrong: [String: Int] = [:]
    public var wrongMastered: [String: Int] = [:]
    public var history: [HistoryEntry] = []
    public var streak: StreakState = StreakState(last: "", n: 0)
    public var bestCombo: Int = 0
    public var bf: [CaughtButterfly] = []
    public var cleared: [String: Int] = [:]
    public var tts: TTSPreference = TTSPreference(slow: false)
    public var potSkin: String = "classic"
    public var blind: Bool = false
    public var seasoningMode: Bool = true
    public var daily: DailyProgress = DailyProgress(d: Self.todayString(), rounds: 0, maxCombo: 0, words: 0, claimed: [:])

    public init() {}

    enum CodingKeys: String, CodingKey {
        case unlocked, stars, food
        case mathUnlocked, mathStars, desserts
        case englishUnlocked, englishStars, englishCards
        case freeUnlockAll
        case wrong, wrongMastered, history, streak, bestCombo, bf, cleared, tts, potSkin, blind, seasoningMode, daily
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.unlocked = (try? c.decode(Int.self, forKey: .unlocked)) ?? 1
        self.stars = (try? c.decode([String: Int].self, forKey: .stars)) ?? [:]
        self.food = (try? c.decode([String: Int].self, forKey: .food)) ?? [:]
        self.mathUnlocked = (try? c.decode(Int.self, forKey: .mathUnlocked)) ?? 2
        self.mathStars = (try? c.decode([String: Int].self, forKey: .mathStars)) ?? [:]
        self.desserts = (try? c.decode([String: Int].self, forKey: .desserts)) ?? [:]
        self.englishUnlocked = (try? c.decode(Int.self, forKey: .englishUnlocked)) ?? 2
        self.englishStars = (try? c.decode([String: Int].self, forKey: .englishStars)) ?? [:]
        self.englishCards = (try? c.decode([String: Int].self, forKey: .englishCards)) ?? [:]
        self.freeUnlockAll = (try? c.decode(Bool.self, forKey: .freeUnlockAll)) ?? true
        self.wrong = (try? c.decode([String: Int].self, forKey: .wrong)) ?? [:]
        self.wrongMastered = (try? c.decode([String: Int].self, forKey: .wrongMastered)) ?? [:]
        self.history = (try? c.decode([HistoryEntry].self, forKey: .history)) ?? []
        self.streak = (try? c.decode(StreakState.self, forKey: .streak)) ?? StreakState(last: "", n: 0)
        self.bestCombo = (try? c.decode(Int.self, forKey: .bestCombo)) ?? 0
        self.bf = (try? c.decode([CaughtButterfly].self, forKey: .bf)) ?? []
        self.cleared = (try? c.decode([String: Int].self, forKey: .cleared)) ?? [:]
        self.tts = (try? c.decode(TTSPreference.self, forKey: .tts)) ?? TTSPreference(slow: false)
        self.potSkin = (try? c.decode(String.self, forKey: .potSkin)) ?? "classic"
        self.blind = (try? c.decode(Bool.self, forKey: .blind)) ?? false
        self.seasoningMode = (try? c.decode(Bool.self, forKey: .seasoningMode)) ?? true
        self.daily = (try? c.decode(DailyProgress.self, forKey: .daily))
            ?? DailyProgress(d: Self.todayString(), rounds: 0, maxCombo: 0, words: 0, claimed: [:])
    }

    public static func todayString(date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    /// 语、数、英三科总星星数共享
    public var totalStars: Int {
        stars.values.reduce(0, +) + mathStars.values.reduce(0, +) + englishStars.values.reduce(0, +)
    }

    public var foodCount: Int {
        food.keys.count
    }

    public var dessertCount: Int {
        desserts.keys.count
    }

    public var englishCardCount: Int {
        englishCards.keys.count
    }

    public var totalCollectionCount: Int {
        foodCount + dessertCount + englishCardCount
    }

    public func starsForLevel(_ n: Int, subject: SubjectKind = .pinyin) -> Int {
        switch subject {
        case .pinyin:  return stars[String(n)] ?? 0
        case .math:    return mathStars[String(n)] ?? 0
        case .english: return englishStars[String(n)] ?? 0
        }
    }

    public func isStageLocked(_ n: Int, subject: SubjectKind) -> Bool {
        if freeUnlockAll { return false }
        switch subject {
        case .pinyin:  return n > unlocked
        case .math:    return n > mathUnlocked
        case .english: return n > englishUnlocked
        }
    }

    public func butterflyCount(for speciesId: String) -> Int {
        bf.filter { $0.t == speciesId }.count
    }

    public func butterflyStage(for speciesId: String) -> Int {
        let count = butterflyCount(for: speciesId)
        if count >= ButterflySpecies.evolutionThresholds[3] { return 3 }
        if count >= ButterflySpecies.evolutionThresholds[2] { return 2 }
        return count >= 1 ? 1 : 0
    }

    public func nextStageNeed(for speciesId: String) -> Int? {
        let stage = butterflyStage(for: speciesId)
        return stage >= 3 ? nil : ButterflySpecies.evolutionThresholds[stage + 1]
    }

    public mutating func ensureDaily() {
        let t = Self.todayString()
        if daily.d != t {
            daily = DailyProgress(d: t, rounds: 0, maxCombo: 0, words: 0, claimed: [:])
        }
    }

    public mutating func touchStreak() {
        let t = Self.todayString()
        ensureDaily()
        if streak.last == t { return }
        let yesterday = Self.todayString(date: Date(timeIntervalSinceNow: -86400))
        if streak.last == yesterday {
            streak.n += 1
        } else {
            streak.n = 1
        }
        streak.last = t
    }

    public mutating func merge(from other: GameProgress) -> Int {
        var added = 0
        if other.unlocked > unlocked { unlocked = other.unlocked; added += 1 }
        if other.mathUnlocked > mathUnlocked { mathUnlocked = other.mathUnlocked; added += 1 }
        if other.englishUnlocked > englishUnlocked { englishUnlocked = other.englishUnlocked; added += 1 }

        for (k, v) in other.stars where v > (stars[k] ?? 0) { stars[k] = v; added += 1 }
        for (k, v) in other.mathStars where v > (mathStars[k] ?? 0) { mathStars[k] = v; added += 1 }
        for (k, v) in other.englishStars where v > (englishStars[k] ?? 0) { englishStars[k] = v; added += 1 }

        for (k, v) in other.food where v > 0 && food[k] == nil { food[k] = 1; added += 1 }
        for (k, v) in other.desserts where v > 0 && desserts[k] == nil { desserts[k] = 1; added += 1 }
        for (k, v) in other.englishCards where v > 0 && englishCards[k] == nil { englishCards[k] = 1; added += 1 }
        for (k, v) in other.cleared where v > 0 && cleared[k] == nil { cleared[k] = 1; added += 1 }
        for (k, v) in other.wrong where v > 0 { wrong[k] = (wrong[k] ?? 0) + v; added += 1 }
        for (k, v) in other.wrongMastered where wrongMastered[k] == nil { wrongMastered[k] = v; added += 1 }

        let existingHist = Set(history.map(\.id))
        for h in other.history where !existingHist.contains(h.id) {
            history.append(h)
            added += 1
        }
        if history.count > 60 { history = Array(history.suffix(60)) }
        if other.streak.last > streak.last {
            streak = other.streak; added += 1
        } else if other.streak.last == streak.last && other.streak.n > streak.n {
            streak.n = other.streak.n; added += 1
        }
        if other.bestCombo > bestCombo { bestCombo = other.bestCombo; added += 1 }
        if !other.bf.isEmpty { bf.append(contentsOf: other.bf); added += other.bf.count }
        return added
    }
}

// MARK: - 成就徽章定义（升级为语数英三科全能徽章）
public struct BadgeDefinition: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let desc: String
    public let check: @Sendable (GameProgress) -> Bool

    public static let all: [BadgeDefinition] = [
        BadgeDefinition(id: "first",   title: "🎉 料理城开张", desc: "第一次通关任意一关", check: { $0.totalStars > 0 }),
        BadgeDefinition(id: "star3",   title: "⭐ 三星主厨",   desc: "任意关卡拿到三颗星", check: {
            $0.stars.values.contains(where: { $0 >= 3 })
            || $0.mathStars.values.contains(where: { $0 >= 3 })
            || $0.englishStars.values.contains(where: { $0 >= 3 })
        }),
        BadgeDefinition(id: "combo",   title: "⚡ 手速惊人",   desc: "单局连对 5 次",      check: { $0.bestCombo >= 5 }),
        BadgeDefinition(id: "food30",  title: "🍲 中华名厨",   desc: "收集 30 道拼音汉字菜肴", check: { $0.foodCount >= 30 }),
        BadgeDefinition(id: "math10",  title: "🧁 数学甜点师", desc: "收集 10 款数学烘焙甜点", check: { $0.dessertCount >= 10 }),
        BadgeDefinition(id: "eng15",   title: "🧃 双语调饮师", desc: "收集 15 张牛津英语闪卡", check: { $0.englishCardCount >= 15 }),
        BadgeDefinition(id: "day3",    title: "📅 天天来报到", desc: "连续打卡 3 天",      check: { $0.streak.n >= 3 }),
        BadgeDefinition(id: "bfevo",   title: "✨ 进化大师",   desc: "让 1 种蝴蝶完全进化（同种收集 6 只）", check: { prog in
            ButterflySpecies.all.contains(where: { prog.butterflyStage(for: $0.id) >= 3 })
        }),
        BadgeDefinition(id: "bfall",   title: "🏛️ 蝴蝶馆长",   desc: "集齐全部 20 种蝴蝶", check: { prog in
            Set(prog.bf.map(\.t)).count >= ButterflySpecies.all.count
        })
    ]
}
