import Foundation

public struct HistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String { uid ?? "\(d)|\(subj ?? "pinyin")|\(lv)|\(r)|\(t)|\(f ?? "mid")" }
    public var uid: String?
    public var ts: TimeInterval?
    public var d: String
    public var subj: String?
    public var lv: Int
    public var s: Int
    public var r: Int
    public var t: Int
    public var f: String?

    public init(
        uid: String? = UUID().uuidString,
        ts: TimeInterval? = Date().timeIntervalSince1970,
        d: String,
        subj: String? = nil,
        lv: Int,
        s: Int,
        r: Int,
        t: Int,
        f: String? = nil
    ) {
        self.uid = uid
        self.ts = ts
        self.d = d
        self.subj = subj
        self.lv = lv
        self.s = s
        self.r = r
        self.t = t
        self.f = f
    }

    enum CodingKeys: String, CodingKey {
        case uid, ts, d, subj, lv, s, r, t, f
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try c.decodeIfPresent(String.self, forKey: .uid)
        self.ts = try c.decodeIfPresent(TimeInterval.self, forKey: .ts)
        self.d = (try? c.decode(String.self, forKey: .d)) ?? GameProgress.todayString()
        self.subj = try c.decodeIfPresent(String.self, forKey: .subj)
        self.lv = (try? c.decode(Int.self, forKey: .lv)) ?? 1
        self.s = (try? c.decode(Int.self, forKey: .s)) ?? 0
        self.r = (try? c.decode(Int.self, forKey: .r)) ?? 0
        self.t = (try? c.decode(Int.self, forKey: .t)) ?? 0
        self.f = try c.decodeIfPresent(String.self, forKey: .f)
    }
}

public struct StreakState: Codable, Equatable, Sendable {
    public var last: String
    public var n: Int

    public init(last: String, n: Int) {
        self.last = last
        self.n = n
    }
}

public struct TTSPreference: Codable, Equatable, Sendable {
    public var slow: Bool

    public init(slow: Bool) {
        self.slow = slow
    }
}

public struct DailyProgress: Codable, Equatable, Sendable {
    public var d: String
    public var rounds: Int
    public var maxCombo: Int
    public var words: Int
    public var claimed: [String: Int]

    public init(d: String, rounds: Int, maxCombo: Int, words: Int, claimed: [String: Int]) {
        self.d = d
        self.rounds = rounds
        self.maxCombo = maxCombo
        self.words = words
        self.claimed = claimed
    }
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

/// 仅用于解码旧版存档中的蝴蝶数组以执行一次性静默迁移
private struct LegacyButterflyStub: Codable {
    var t: String?
    var uid: String?
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

    // 共享错题本、战绩、打卡
    public var wrong: [String: Int] = [:]
    public var wrongMastered: [String: Int] = [:]
    public var history: [HistoryEntry] = []
    public var streak: StreakState = StreakState(last: "", n: 0)
    public var bestCombo: Int = 0
    public var migratedLegacyButterflies: Bool = true
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

    // 🪙 奇妙料理星币、皇家扭蛋券、通用素材、12 只守护萌宠精灵、👗 满满公主变装衣橱与童话游乐园建筑
    public var coins: Int = 90
    public var gachaTickets: Int = 1
    public var starThread: Int = 0
    public var petCandy: Int = 0
    public var pets: [String: Int] = Self.defaultPets
    public var petFeedExp: [String: Int] = [:]
    public var equippedPetId: String = "fire_dragon"
    public var castleUnlocked: [String: Int] = ["fountain": 1]

    // 🎰 扭蛋保底与防连非计数器
    public var gachaPityMythic: Int = 0
    public var gachaRepeatMissCount: Int = 0

    /// 满满公主高定变装衣橱（itemId -> 累计拥有/高定织造次数，支持 1~5 阶华丽蜕变）
    public var wardrobe: [String: Int] = Self.defaultWardrobe
    /// 当前穿戴的 5 大部位（category.rawValue -> itemId）
    public var equippedOutfit: [String: String] = Self.defaultEquippedOutfit

    // 🎨 公主个性化外观（发色 / 表情 / 舞台 Pose）
    public var princessHairColorId: String = "caramel"
    public var princessExpressionId: String = "smile"
    public var princessPoseId: String = "curtsy"

    // 🏆 段位晋升 / 摘星路 / 图鉴里程碑与每日惊喜领取记录
    public var claimedRankMilestones: [Int] = []
    public var claimedStarMilestones: [Int] = []
    public var claimedCollectionMilestones: [String: Int] = [:]
    public var dailyBallThemeClaimedDate: String = ""
    public var dailyWheelSpunDate: String = ""
    public var dailyPetPatDate: String = ""
    public var dailyPetPatCount: Int = 0
    public var dailyDessertFeedDate: String = ""

    public static let defaultPets: [String: Int] = [
        "fire_dragon": 1
    ]

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
        case wrong, wrongMastered, history, streak, bestCombo, migratedLegacyButterflies, cleared, tts, potSkin, blind, seasoningMode, daily
        case eyeCare, playSeconds, bonusMinutes
        case coins, gachaTickets, starThread, petCandy, pets, petFeedExp, equippedPetId, castleUnlocked
        case gachaPityMythic, gachaRepeatMissCount
        case wardrobe, equippedOutfit
        case princessHairColorId, princessExpressionId, princessPoseId
        case claimedRankMilestones, claimedStarMilestones, claimedCollectionMilestones
        case dailyBallThemeClaimedDate, dailyWheelSpunDate, dailyPetPatDate, dailyPetPatCount, dailyDessertFeedDate
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case bf
    }

    private static func sanitizeWrongMap(_ raw: [String: Int]) -> [String: Int] {
        var clean: [String: Int] = [:]
        for (k, v) in raw where v > 0 {
            // 修复历史版本 merge 3^N 累加导致的异常极大错题次数
            clean[k] = v > 20 ? 5 : v
        }
        return clean
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

        let rawWrong = (try? c.decode([String: Int].self, forKey: .wrong)) ?? [:]
        self.wrong = Self.sanitizeWrongMap(rawWrong)
        self.wrongMastered = (try? c.decode([String: Int].self, forKey: .wrongMastered)) ?? [:]
        self.history = (try? c.decode([HistoryEntry].self, forKey: .history)) ?? []
        self.streak = (try? c.decode(StreakState.self, forKey: .streak)) ?? StreakState(last: "", n: 0)
        self.bestCombo = (try? c.decode(Int.self, forKey: .bestCombo)) ?? 0
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
        self.coins = max(0, (try? c.decode(Int.self, forKey: .coins)) ?? 90)
        self.gachaTickets = max(0, (try? c.decode(Int.self, forKey: .gachaTickets)) ?? 1)
        self.starThread = max(0, (try c.decodeIfPresent(Int.self, forKey: .starThread)) ?? 0)
        self.petCandy = max(0, (try c.decodeIfPresent(Int.self, forKey: .petCandy)) ?? 0)

        let decodedPets = (try? c.decode([String: Int].self, forKey: .pets)) ?? Self.defaultPets
        self.pets = decodedPets.isEmpty ? Self.defaultPets : decodedPets
        self.petFeedExp = (try? c.decode([String: Int].self, forKey: .petFeedExp)) ?? [:]
        self.equippedPetId = (try? c.decode(String.self, forKey: .equippedPetId)) ?? "fire_dragon"
        var decodedCastle = (try? c.decode([String: Int].self, forKey: .castleUnlocked)) ?? ["fountain": 1]
        if decodedCastle.isEmpty { decodedCastle = ["fountain": 1] }
        if (decodedCastle["fountain"] ?? 0) == 0 { decodedCastle["fountain"] = 1 }
        self.castleUnlocked = decodedCastle

        self.gachaPityMythic = max(0, min(9, (try c.decodeIfPresent(Int.self, forKey: .gachaPityMythic)) ?? 0))
        self.gachaRepeatMissCount = max(0, (try c.decodeIfPresent(Int.self, forKey: .gachaRepeatMissCount)) ?? 0)

        var decodedWardrobe = (try? c.decode([String: Int].self, forKey: .wardrobe)) ?? Self.defaultWardrobe
        for (k, v) in Self.defaultWardrobe where (decodedWardrobe[k] ?? 0) < v {
            decodedWardrobe[k] = v
        }

        // 一次性兼容旧版蝴蝶存档：仅当尚未迁移、衣橱未扩充且存在旧 bf 记录时，跳过初始服装折算 1 次
        let decodedMigrated = try c.decodeIfPresent(Bool.self, forKey: .migratedLegacyButterflies)
        let legacyContainer = try? decoder.container(keyedBy: LegacyCodingKeys.self)
        let legacyBf = (try? legacyContainer?.decode([LegacyButterflyStub].self, forKey: .bf)) ?? []
        if decodedMigrated == nil && decodedWardrobe.count <= Self.defaultWardrobe.count && !legacyBf.isEmpty {
            let bonusPool = PrincessFashionItem.all.filter { $0.tier <= 2 && Self.defaultWardrobe[$0.id] == nil }
            if !bonusPool.isEmpty {
                for idx in legacyBf.indices {
                    let item = bonusPool[idx % bonusPool.count]
                    decodedWardrobe[item.id] = (decodedWardrobe[item.id] ?? 0) + 1
                }
            }
        }
        self.migratedLegacyButterflies = decodedMigrated ?? true
        self.wardrobe = decodedWardrobe

        var decodedEquipped = (try? c.decode([String: String].self, forKey: .equippedOutfit)) ?? Self.defaultEquippedOutfit
        for (catKey, defId) in Self.defaultEquippedOutfit {
            if let existing = decodedEquipped[catKey], (decodedWardrobe[existing] ?? 0) > 0, PrincessFashionItem.item(for: existing) != nil {
                continue
            }
            decodedEquipped[catKey] = defId
        }
        self.equippedOutfit = decodedEquipped

        self.princessHairColorId = (try c.decodeIfPresent(String.self, forKey: .princessHairColorId)) ?? "caramel"
        self.princessExpressionId = (try c.decodeIfPresent(String.self, forKey: .princessExpressionId)) ?? "smile"
        self.princessPoseId = (try c.decodeIfPresent(String.self, forKey: .princessPoseId)) ?? "curtsy"

        self.claimedRankMilestones = (try c.decodeIfPresent([Int].self, forKey: .claimedRankMilestones)) ?? []
        self.claimedStarMilestones = (try c.decodeIfPresent([Int].self, forKey: .claimedStarMilestones)) ?? []
        self.claimedCollectionMilestones = (try c.decodeIfPresent([String: Int].self, forKey: .claimedCollectionMilestones)) ?? [:]
        self.dailyBallThemeClaimedDate = (try c.decodeIfPresent(String.self, forKey: .dailyBallThemeClaimedDate)) ?? ""
        self.dailyWheelSpunDate = (try c.decodeIfPresent(String.self, forKey: .dailyWheelSpunDate)) ?? ""
        self.dailyPetPatDate = (try c.decodeIfPresent(String.self, forKey: .dailyPetPatDate)) ?? ""
        self.dailyPetPatCount = max(0, (try c.decodeIfPresent(Int.self, forKey: .dailyPetPatCount)) ?? 0)
        self.dailyDessertFeedDate = (try c.decodeIfPresent(String.self, forKey: .dailyDessertFeedDate)) ?? ""
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
        fmt.calendar = Calendar(identifier: .gregorian)
        fmt.locale = Locale(identifier: "en_US_POSIX")
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

    public var gachaRemainingToMythic: Int {
        max(1, 10 - gachaPityMythic)
    }

    public var maxDailyPetPats: Int {
        3 + ((castleUnlocked["carousel"] ?? 0) > 0 ? 1 : 0)
    }

    public var effectiveDailyPetPatCount: Int {
        dailyPetPatDate == Self.todayString() ? dailyPetPatCount : 0
    }

    public var isDailyDessertFedToday: Bool {
        dailyDessertFeedDate == Self.todayString()
    }

    public var isDailyBallClaimedToday: Bool {
        dailyBallThemeClaimedDate == Self.todayString()
    }

    public var isDailyWheelSpunToday: Bool {
        dailyWheelSpunDate == Self.todayString()
    }

    // MARK: - 👗 满满公主高定变装衣橱（5阶华丽升级与套装共鸣）辅助方法
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

    /// 六大高定套装共鸣状态（3/5 +15% 华丽度；5/5 +35% 华丽度 + 专属主题舞台 + 每题 +1~+3 币）
    public func suitBonusInfo() -> SuitBonusInfo {
        var counts: [Int: Int] = [:]
        for cat in PrincessFashionCategory.allCases {
            let item = equippedItem(for: cat)
            counts[item.styleIndex, default: 0] += 1
        }
        let dressStyle = equippedItem(for: .dress).styleIndex
        let bestStyle = counts.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            if lhs.key == dressStyle { return false }
            if rhs.key == dressStyle { return true }
            return lhs.key < rhs.key
        }?.key ?? dressStyle
        let matchedCount = counts[bestStyle] ?? 0
        let suit = PrincessFashionSuit.byStyleIndex(bestStyle)
        let isHalf = matchedCount >= 3
        let isFull = matchedCount == 5
        let bonusPct = isFull ? 35 : (isHalf ? 15 : 0)
        let mult = isFull ? 1.35 : (isHalf ? 1.15 : 1.0)
        let coinBonus = isFull ? suit.fullCoinBonus : 0
        return SuitBonusInfo(
            suit: suit,
            suitName: suit.name,
            matchedCount: matchedCount,
            isHalfResonance: isHalf,
            isFullResonance: isFull,
            glamourBonusPercent: bonusPct,
            glamourMultiplier: mult,
            stageThemeId: bestStyle,
            coinBonus: coinBonus
        )
    }

    /// 基础华丽度（未计入套装共鸣前）
    public var baseGlamourScore: Int {
        var score = 0
        for cat in PrincessFashionCategory.allCases {
            let item = equippedItem(for: cat)
            let st = equippedItemStage(for: cat)
            score += item.tier * 25 + st * 20
        }
        return score
    }

    /// 全身总华丽值评分（品阶 + 升阶等级 × 套装共鸣倍率）
    public var totalGlamourScore: Int {
        Int((Double(baseGlamourScore) * suitBonusInfo().glamourMultiplier).rounded())
    }

    /// 公主舞会爵位与伴读加币档位
    public var glamourRank: GlamourRankInfo {
        GlamourRankInfo.compute(score: totalGlamourScore)
    }

    // MARK: - 🎨 发色 / 表情 / 舞台 Pose 解锁判断
    public func isHairColorUnlocked(_ option: HairColorOption) -> Bool {
        totalStars >= option.needStars && totalGlamourScore >= option.needGlamour
    }

    public func isExpressionUnlocked(_ expr: PrincessExpression) -> Bool {
        totalStars >= expr.needStars
    }

    public func isPoseUnlocked(_ pose: PrincessPose) -> Bool {
        totalStars >= pose.needStars && totalGlamourScore >= pose.needGlamour
    }

    public var currentHairColor: HairColorOption {
        let opt = HairColorOption.byId(princessHairColorId)
        return isHairColorUnlocked(opt) ? opt : HairColorOption.all[0]
    }

    public var currentExpression: PrincessExpression {
        let expr = PrincessExpression.byId(princessExpressionId)
        return isExpressionUnlocked(expr) ? expr : PrincessExpression.all[0]
    }

    public var currentPose: PrincessPose {
        let pose = PrincessPose.byId(princessPoseId)
        return isPoseUnlocked(pose) ? pose : PrincessPose.all[0]
    }

    public var unlockedAttractionCount: Int {
        castleUnlocked.filter { $0.value > 0 }.count
    }

    public mutating func ensureDaily() {
        let t = Self.todayString()
        if daily.d != t {
            daily = DailyProgress(d: t, rounds: 0, maxCombo: 0, words: 0, claimed: [:])
        }
        if dailyPetPatDate != t {
            dailyPetPatDate = t
            dailyPetPatCount = 0
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
        let isFreshLocal = totalStars == 0
            && history.isEmpty
            && unlockedFashionCount <= Self.defaultWardrobe.count
            && coins == 90
            && gachaTickets == 1
            && unlockedPetCount <= 1

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

        // 使用 max 合并错题次数，并清洗历史异常溢出值
        for (k, v) in other.wrong where v > 0 {
            let sanitized = v > 20 ? 5 : v
            let cur = wrong[k] ?? 0
            if sanitized > cur {
                wrong[k] = sanitized
                added += 1
            }
        }
        for (k, v) in other.wrongMastered where v > (wrongMastered[k] ?? 0) {
            wrongMastered[k] = v
            added += 1
        }

        if other.coins > coins { coins = other.coins; added += 1 }
        if other.gachaTickets > gachaTickets { gachaTickets = other.gachaTickets; added += 1 }
        if other.starThread > starThread { starThread = other.starThread; added += 1 }
        if other.petCandy > petCandy { petCandy = other.petCandy; added += 1 }

        for (k, v) in other.pets where v > (pets[k] ?? 0) { pets[k] = v; added += 1 }
        for (k, v) in other.petFeedExp where v > (petFeedExp[k] ?? 0) { petFeedExp[k] = v; added += 1 }
        for (k, v) in other.castleUnlocked where v > 0 && castleUnlocked[k] == nil { castleUnlocked[k] = 1; added += 1 }
        for (k, v) in other.wardrobe where v > (wardrobe[k] ?? 0) { wardrobe[k] = v; added += 1 }

        if other.gachaPityMythic > gachaPityMythic {
            gachaPityMythic = min(9, other.gachaPityMythic)
            added += 1
        }
        if other.gachaRepeatMissCount > gachaRepeatMissCount {
            gachaRepeatMissCount = other.gachaRepeatMissCount
            added += 1
        }

        // 合并当前出战宠与锅具皮肤（仅在新存档或当前无效/默认时采纳，不盲目覆盖本地偏好）
        if isFreshLocal || (pets[equippedPetId] ?? 0) == 0 || (equippedPetId == "fire_dragon" && other.equippedPetId != "fire_dragon") {
            if !other.equippedPetId.isEmpty && (pets[other.equippedPetId] ?? 0) > 0 && equippedPetId != other.equippedPetId {
                equippedPetId = other.equippedPetId
                added += 1
            }
        }
        if isFreshLocal || (potSkin == "classic" && other.potSkin != "classic") {
            if PotSkin.all.contains(where: { $0.id == other.potSkin && totalStars >= $0.needStars }) && potSkin != other.potSkin {
                potSkin = other.potSkin
                added += 1
            }
        }

        // 合并当前穿戴服饰：绝不盲目覆盖本地更高或已定制的装扮
        for (catKey, otherId) in other.equippedOutfit where !otherId.isEmpty {
            guard (wardrobe[otherId] ?? 0) > 0, let otherItem = PrincessFashionItem.item(for: otherId) else { continue }
            if isFreshLocal {
                if equippedOutfit[catKey] != otherId {
                    equippedOutfit[catKey] = otherId
                    added += 1
                }
            } else if let curId = equippedOutfit[catKey], (wardrobe[curId] ?? 0) > 0, let curItem = PrincessFashionItem.item(for: curId) {
                if curItem.styleIndex == 0 && otherItem.tier > curItem.tier {
                    equippedOutfit[catKey] = otherId
                    added += 1
                }
            } else {
                equippedOutfit[catKey] = otherId
                added += 1
            }
        }

        // 合并发色、表情、Pose
        if isFreshLocal || princessHairColorId == "caramel" {
            let opt = HairColorOption.byId(other.princessHairColorId)
            if isHairColorUnlocked(opt) && opt.id != princessHairColorId {
                princessHairColorId = opt.id
                added += 1
            }
        }
        if isFreshLocal || princessExpressionId == "smile" {
            let expr = PrincessExpression.byId(other.princessExpressionId)
            if isExpressionUnlocked(expr) && expr.id != princessExpressionId {
                princessExpressionId = expr.id
                added += 1
            }
        }
        if isFreshLocal || princessPoseId == "curtsy" {
            let pose = PrincessPose.byId(other.princessPoseId)
            if isPoseUnlocked(pose) && pose.id != princessPoseId {
                princessPoseId = pose.id
                added += 1
            }
        }

        // 合并开关、护眼与时长设置
        if isFreshLocal {
            if tts != other.tts { tts = other.tts; added += 1 }
            if blind != other.blind { blind = other.blind; added += 1 }
            if seasoningMode != other.seasoningMode { seasoningMode = other.seasoningMode; added += 1 }
            if freeUnlockAll != other.freeUnlockAll { freeUnlockAll = other.freeUnlockAll; added += 1 }
            if eyeCare != other.eyeCare { eyeCare = other.eyeCare; added += 1 }
        }
        for (dKey, sec) in other.playSeconds where sec > (playSeconds[dKey] ?? 0) {
            playSeconds[dKey] = sec
            added += 1
        }
        for (dKey, minVal) in other.bonusMinutes where minVal > (bonusMinutes[dKey] ?? 0) {
            bonusMinutes[dKey] = minVal
            added += 1
        }
        trimPlayTimeHistory()

        // 合并每日进度与已领取任务（防止跨设备重复领奖）
        if other.daily.d > daily.d {
            daily = other.daily
            added += 1
        } else if other.daily.d == daily.d {
            if other.daily.rounds > daily.rounds { daily.rounds = other.daily.rounds; added += 1 }
            if other.daily.maxCombo > daily.maxCombo { daily.maxCombo = other.daily.maxCombo; added += 1 }
            if other.daily.words > daily.words { daily.words = other.daily.words; added += 1 }
            for (k, v) in other.daily.claimed where v > 0 && (daily.claimed[k] ?? 0) == 0 {
                daily.claimed[k] = 1
                added += 1
            }
        }

        // 合并里程碑与每日领奖日期
        let rankSet = Set(claimedRankMilestones).union(other.claimedRankMilestones)
        if rankSet.count > claimedRankMilestones.count {
            claimedRankMilestones = rankSet.sorted()
            added += 1
        }
        let starSet = Set(claimedStarMilestones).union(other.claimedStarMilestones)
        if starSet.count > claimedStarMilestones.count {
            claimedStarMilestones = starSet.sorted()
            added += 1
        }
        for (k, v) in other.claimedCollectionMilestones where v > (claimedCollectionMilestones[k] ?? 0) {
            claimedCollectionMilestones[k] = v
            added += 1
        }
        if other.dailyBallThemeClaimedDate > dailyBallThemeClaimedDate {
            dailyBallThemeClaimedDate = other.dailyBallThemeClaimedDate
            added += 1
        }
        if other.dailyWheelSpunDate > dailyWheelSpunDate {
            dailyWheelSpunDate = other.dailyWheelSpunDate
            added += 1
        }
        if other.dailyDessertFeedDate > dailyDessertFeedDate {
            dailyDessertFeedDate = other.dailyDessertFeedDate
            added += 1
        }
        if other.dailyPetPatDate > dailyPetPatDate {
            dailyPetPatDate = other.dailyPetPatDate
            dailyPetPatCount = other.dailyPetPatCount
            added += 1
        } else if other.dailyPetPatDate == dailyPetPatDate && other.dailyPetPatCount > dailyPetPatCount {
            dailyPetPatCount = other.dailyPetPatCount
            added += 1
        }

        // 合并历史战绩并按时间正序排序后再截取最近 60 条
        var existingHist = Set(history.map(\.id))
        for h in other.history where !existingHist.contains(h.id) {
            history.append(h)
            existingHist.insert(h.id)
            added += 1
        }
        history.sort { lhs, rhs in
            if lhs.d != rhs.d { return lhs.d < rhs.d }
            return (lhs.ts ?? 0) < (rhs.ts ?? 0)
        }
        if history.count > 60 { history = Array(history.suffix(60)) }

        if other.streak.last > streak.last {
            streak = other.streak; added += 1
        } else if other.streak.last == streak.last && other.streak.n > streak.n {
            streak.n = other.streak.n; added += 1
        }
        if other.bestCombo > bestCombo { bestCombo = other.bestCombo; added += 1 }
        if other.migratedLegacyButterflies { migratedLegacyButterflies = true }

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
