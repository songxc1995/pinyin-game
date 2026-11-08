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

// MARK: - 护眼与健康游戏设置（家长可调）
public struct EyeCareSettings: Codable, Equatable, Sendable {
    /// 护眼暖光滤镜（过滤部分蓝光、降低白色刺眼程度）
    public var warmFilter: Bool = true
    /// 暖光强度：1 轻柔 / 2 标准 / 3 强护眼
    public var warmStrength: Int = 2
    /// 晚上 19:00 以后自动加强暖光
    public var autoNightWarm: Bool = true
    /// 20-20-20 用眼休息提醒
    public var restReminder: Bool = true
    /// 连续游戏多少分钟后强制休息
    public var restIntervalMin: Int = 20
    /// 每次休息多少秒
    public var restSeconds: Int = 30
    /// 每日游戏时长上限
    public var dailyLimitEnabled: Bool = true
    public var dailyLimitMin: Int = 40
    /// 睡前打烊（时间段内不可游戏）
    public var bedtimeEnabled: Bool = true
    public var bedtimeHour: Int = 21
    public var wakeHour: Int = 7
    /// 柔和动效（减少晃动、闪烁类动画）
    public var gentleMotion: Bool = true

    public init() {}

    enum CodingKeys: String, CodingKey {
        case warmFilter, warmStrength, autoNightWarm, restReminder, restIntervalMin, restSeconds
        case dailyLimitEnabled, dailyLimitMin, bedtimeEnabled, bedtimeHour, wakeHour, gentleMotion
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = EyeCareSettings()
        warmFilter = (try? c.decode(Bool.self, forKey: .warmFilter)) ?? d.warmFilter
        warmStrength = (try? c.decode(Int.self, forKey: .warmStrength)) ?? d.warmStrength
        autoNightWarm = (try? c.decode(Bool.self, forKey: .autoNightWarm)) ?? d.autoNightWarm
        restReminder = (try? c.decode(Bool.self, forKey: .restReminder)) ?? d.restReminder
        restIntervalMin = (try? c.decode(Int.self, forKey: .restIntervalMin)) ?? d.restIntervalMin
        restSeconds = (try? c.decode(Int.self, forKey: .restSeconds)) ?? d.restSeconds
        dailyLimitEnabled = (try? c.decode(Bool.self, forKey: .dailyLimitEnabled)) ?? d.dailyLimitEnabled
        dailyLimitMin = (try? c.decode(Int.self, forKey: .dailyLimitMin)) ?? d.dailyLimitMin
        bedtimeEnabled = (try? c.decode(Bool.self, forKey: .bedtimeEnabled)) ?? d.bedtimeEnabled
        bedtimeHour = (try? c.decode(Int.self, forKey: .bedtimeHour)) ?? d.bedtimeHour
        wakeHour = (try? c.decode(Int.self, forKey: .wakeHour)) ?? d.wakeHour
        gentleMotion = (try? c.decode(Bool.self, forKey: .gentleMotion)) ?? d.gentleMotion
    }
}

public struct GameProgress: Codable, Equatable, Sendable {
    // 语文拼音进度
    public var unlocked: Int = 1
    public var stars: [String: Int] = [:]
    public var food: [String: Int] = [:]

    // 沪教版数学进度
    public var mathUnlocked: Int = 1
    public var mathStars: [String: Int] = [:]
    public var desserts: [String: Int] = [:]

    // 沪教牛津英语进度
    public var englishUnlocked: Int = 1
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

    // 护眼设置与每日游戏时长（按日期记录秒数 / 家长临时加时分钟数）
    public var eyeCare: EyeCareSettings = EyeCareSettings()
    public var playSeconds: [String: Int] = [:]
    public var bonusMinutes: [String: Int] = [:]

    // 🪙 奇妙料理星币、皇家扭蛋券、12 只守护萌宠精灵、👗 满满公主变装衣橱与童话游乐园建筑
    public var coins: Int = 90
    public var gachaTickets: Int = 1
    public var pets: [String: Int] = ["fire_dragon": 1]
    public var petFeedExp: [String: Int] = [:]
    public var equippedPetId: String = "fire_dragon"
    public var castleUnlocked: [String: Int] = ["fountain": 1]

    /// 满满公主高定变装衣橱（itemId -> 累计拥有/高定织造次数，支持 1~5 阶华丽蜕变）
    public var wardrobe: [String: Int] = Self.defaultWardrobe
    /// 当前穿戴的 5 大部位（category.rawValue -> itemId）
    public var equippedOutfit: [String: String] = Self.defaultEquippedOutfit

    public static let defaultWardrobe: [String: Int] = [
        "dress_0": 1,
        "hair_0": 1,
        "jewel_0": 1,
        "wings_0": 1,
        "wand_0": 1
    ]

    public static let defaultEquippedOutfit: [String: String] = [
        PrincessFashionCategory.dress.rawValue: "dress_0",
        PrincessFashionCategory.hairTiara.rawValue: "hair_0",
        PrincessFashionCategory.jewelry.rawValue: "jewel_0",
        PrincessFashionCategory.wings.rawValue: "wings_0",
        PrincessFashionCategory.wand.rawValue: "wand_0"
    ]

    public init() {}

    enum CodingKeys: String, CodingKey {
        case unlocked, stars, food
        case mathUnlocked, mathStars, desserts
        case englishUnlocked, englishStars, englishCards
        case freeUnlockAll
        case wrong, wrongMastered, history, streak, bestCombo, bf, cleared, tts, potSkin, blind, seasoningMode, daily
        case eyeCare, playSeconds, bonusMinutes
        case coins, gachaTickets, pets, petFeedExp, equippedPetId, castleUnlocked
        case wardrobe, equippedOutfit
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.unlocked = (try? c.decode(Int.self, forKey: .unlocked)) ?? 1
        self.stars = (try? c.decode([String: Int].self, forKey: .stars)) ?? [:]
        self.food = (try? c.decode([String: Int].self, forKey: .food)) ?? [:]
        self.mathUnlocked = (try? c.decode(Int.self, forKey: .mathUnlocked)) ?? 1
        self.mathStars = (try? c.decode([String: Int].self, forKey: .mathStars)) ?? [:]
        self.desserts = (try? c.decode([String: Int].self, forKey: .desserts)) ?? [:]
        self.englishUnlocked = (try? c.decode(Int.self, forKey: .englishUnlocked)) ?? 1
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
        self.eyeCare = (try? c.decode(EyeCareSettings.self, forKey: .eyeCare)) ?? EyeCareSettings()
        self.playSeconds = (try? c.decode([String: Int].self, forKey: .playSeconds)) ?? [:]
        self.bonusMinutes = (try? c.decode([String: Int].self, forKey: .bonusMinutes)) ?? [:]
        self.coins = (try? c.decode(Int.self, forKey: .coins)) ?? 90
        self.gachaTickets = (try? c.decode(Int.self, forKey: .gachaTickets)) ?? 1
        let decodedPets = (try? c.decode([String: Int].self, forKey: .pets)) ?? ["fire_dragon": 1]
        self.pets = decodedPets.isEmpty ? ["fire_dragon": 1] : decodedPets
        self.petFeedExp = (try? c.decode([String: Int].self, forKey: .petFeedExp)) ?? [:]
        self.equippedPetId = (try? c.decode(String.self, forKey: .equippedPetId)) ?? "fire_dragon"
        let decodedCastle = (try? c.decode([String: Int].self, forKey: .castleUnlocked)) ?? ["fountain": 1]
        self.castleUnlocked = decodedCastle.isEmpty ? ["fountain": 1] : decodedCastle

        var decodedWardrobe = (try? c.decode([String: Int].self, forKey: .wardrobe)) ?? Self.defaultWardrobe
        for (k, v) in Self.defaultWardrobe where (decodedWardrobe[k] ?? 0) < v {
            decodedWardrobe[k] = v
        }
        // 兼容旧版存档：如果旧存档里抓过蝴蝶且还没解锁过新衣服，自动将旧蝴蝶一对一折算为初级/进阶礼服首饰奖励！
        if decodedWardrobe.count <= Self.defaultWardrobe.count && !self.bf.isEmpty {
            let bonusPool = PrincessFashionItem.all.filter { $0.tier <= 2 }
            for (idx, _) in self.bf.enumerated() {
                let item = bonusPool[idx % bonusPool.count]
                decodedWardrobe[item.id] = (decodedWardrobe[item.id] ?? 0) + 1
            }
        }
        self.wardrobe = decodedWardrobe

        var decodedEquipped = (try? c.decode([String: String].self, forKey: .equippedOutfit)) ?? Self.defaultEquippedOutfit
        for (catKey, defId) in Self.defaultEquippedOutfit where decodedEquipped[catKey] == nil {
            decodedEquipped[catKey] = defId
        }
        self.equippedOutfit = decodedEquipped
    }

    /// 今日已游戏秒数
    public var todayPlaySeconds: Int {
        playSeconds[Self.todayString()] ?? 0
    }

    /// 今日可游戏总分钟数（上限 + 家长临时加时）
    public var todayAllowedMinutes: Int {
        eyeCare.dailyLimitMin + (bonusMinutes[Self.todayString()] ?? 0)
    }

    /// 仅保留最近 14 天的时长记录
    public mutating func trimPlayTimeHistory() {
        guard playSeconds.count > 14 else { return }
        let keep = Set(playSeconds.keys.sorted().suffix(14))
        playSeconds = playSeconds.filter { keep.contains($0.key) }
        bonusMinutes = bonusMinutes.filter { keep.contains($0.key) }
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

    // MARK: - 守护萌宠精灵（5阶进化）与游乐园辅助方法
    public var unlockedPetCount: Int {
        pets.filter { $0.value > 0 }.count
    }

    public func petTotalExp(for petId: String) -> Int {
        let gachaCount = pets[petId] ?? 0
        let feedCount = petFeedExp[petId] ?? 0
        return gachaCount + feedCount
    }

    public func petStage(for petId: String) -> Int {
        let gachaCount = pets[petId] ?? 0
        guard gachaCount > 0 else { return 0 }
        let exp = petTotalExp(for: petId)
        for st in stride(from: GuardianPetSpecies.maxStage, through: 1, by: -1) {
            if exp >= GuardianPetSpecies.stageThresholds[st] {
                return st
            }
        }
        return 1
    }

    public func nextPetStageNeed(for petId: String) -> Int? {
        let st = petStage(for: petId)
        guard st > 0 && st < GuardianPetSpecies.maxStage else { return nil }
        return GuardianPetSpecies.stageThresholds[st + 1]
    }

    // MARK: - 👗 满满公主高定变装衣橱（5阶华丽升级）辅助方法
    public var unlockedFashionCount: Int {
        wardrobe.filter { $0.value > 0 }.count
    }

    public func fashionCount(for itemId: String) -> Int {
        wardrobe[itemId] ?? 0
    }

    public func fashionStage(for itemId: String) -> Int {
        let count = fashionCount(for: itemId)
        guard count > 0 else { return 0 }
        for st in stride(from: PrincessFashionItem.maxStage, through: 1, by: -1) {
            if count >= PrincessFashionItem.stageThresholds[st] {
                return st
            }
        }
        return 1
    }

    public func nextFashionStageNeed(for itemId: String) -> Int? {
        let st = fashionStage(for: itemId)
        guard st > 0 && st < PrincessFashionItem.maxStage else { return nil }
        return PrincessFashionItem.stageThresholds[st + 1]
    }

    public func equippedItem(for category: PrincessFashionCategory) -> PrincessFashionItem {
        if let id = equippedOutfit[category.rawValue],
           fashionCount(for: id) > 0,
           let found = PrincessFashionItem.all.first(where: { $0.id == id }) {
            return found
        }
        return PrincessFashionItem.defaultItem(for: category)
    }

    public func equippedItemStage(for category: PrincessFashionCategory) -> Int {
        let item = equippedItem(for: category)
        return max(1, fashionStage(for: item.id))
    }

    /// 全身最高华服阶位（用于驱动人物整体光环与舞台特效）
    public var maxEquippedFashionStage: Int {
        PrincessFashionCategory.allCases.map { equippedItemStage(for: $0) }.max() ?? 1
    }

    /// 全身总华丽值评分（品阶 + 升阶等级综合评分）
    public var totalGlamourScore: Int {
        var score = 0
        for cat in PrincessFashionCategory.allCases {
            let item = equippedItem(for: cat)
            let st = equippedItemStage(for: cat)
            score += item.tier * 25 + st * 20
        }
        return score
    }

    public var unlockedAttractionCount: Int {
        castleUnlocked.filter { $0.value > 0 }.count
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

        if other.coins > coins { coins = other.coins; added += 1 }
        if other.gachaTickets > gachaTickets { gachaTickets = other.gachaTickets; added += 1 }
        for (k, v) in other.pets where v > (pets[k] ?? 0) { pets[k] = v; added += 1 }
        for (k, v) in other.petFeedExp where v > (petFeedExp[k] ?? 0) { petFeedExp[k] = v; added += 1 }
        for (k, v) in other.castleUnlocked where v > 0 && castleUnlocked[k] == nil { castleUnlocked[k] = 1; added += 1 }
        for (k, v) in other.wardrobe where v > (wardrobe[k] ?? 0) { wardrobe[k] = v; added += 1 }
        for (k, v) in other.equippedOutfit where !v.isEmpty { equippedOutfit[k] = v }

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
        let existingBfUIDs = Set(bf.map(\.uid))
        for b in other.bf where !existingBfUIDs.contains(b.uid) {
            bf.append(b)
            added += 1
        }
        return added
    }
}

// MARK: - 成就徽章定义（升级为语数英三科全能徽章 + 精灵游乐园徽章）
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
        BadgeDefinition(id: "pet6",    title: "🎰 扭蛋收藏家", desc: "孵化收集 6 只不同的守护萌宠", check: { $0.unlockedPetCount >= 6 }),
        BadgeDefinition(id: "petmax",  title: "👑 至尊驯兽师", desc: "将 1 只守护萌宠培养进化至 5 阶至尊幻兽", check: { prog in
            GuardianPetSpecies.all.contains(where: { prog.petStage(for: $0.id) >= 5 })
        }),
        BadgeDefinition(id: "castle5", title: "🏰 皇家游乐园主", desc: "在童话游乐园点亮 5 座动态景观建筑", check: { $0.unlockedAttractionCount >= 5 }),
        BadgeDefinition(id: "dress12", title: "👗 百变小公主", desc: "在变装衣橱解锁 12 件漂亮礼服、皇冠或首饰", check: { $0.unlockedFashionCount >= 12 }),
        BadgeDefinition(id: "dressmax", title: "🌈 传世高定女王", desc: "将任意 1 件华服或皇冠首饰升阶至 5 阶【传世神装】", check: { prog in
            PrincessFashionItem.all.contains(where: { prog.fashionStage(for: $0.id) >= 5 })
        })
    ]
}
