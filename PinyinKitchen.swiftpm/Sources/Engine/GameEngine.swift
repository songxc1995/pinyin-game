import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum AppScreenState: Sendable {
    case home
    case playing
    case result
}

public enum HomeTab: String, CaseIterable, Sendable {
    case map      = "Map"
    case recipe   = "Coll"
    case paradise = "Paradise"
    case garden   = "Bf"
    case records  = "Rec"
}

public enum SpecialModeType: String, Sendable {
    case wrong   = "wrong"
    case allstar = "allstar"
}

public struct DailyQuestItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let goal: Int
    public let current: Int
    public let claimed: Bool
    public var isCompleted: Bool { current >= goal }
}

/// 游戏被锁定的原因（每日时长用完 / 睡前打烊）
public enum PlayLockReason: Sendable, Equatable {
    case dailyLimit
    case bedtime
}

/// 家长验证门用途
public enum ParentGatePurpose: Sendable, Equatable {
    case settings
    case skipRest
    case extendTime
}

@MainActor
public final class GameEngine: ObservableObject {
    @Published public var progress: GameProgress
    @Published public var currentSubject: SubjectKind = .pinyin
    @Published public var screenState: AppScreenState = .home
    @Published public var activeTab: HomeTab = .map
    @Published public var showSkinDrawer: Bool = false
    @Published public var firePickerLevel: Int? = nil
    @Published public var pendingFashionUpgrades: [FashionUpgradeEvent] = []
    @Published public var selectedWardrobeCategory: PrincessFashionCategory = .dress
    @Published public var wardrobeToast: String? = nil
    @Published public var mascotLine: String = "小熊团团：欢迎来到《满满的奇妙料理城》，闯关赢皇家扭蛋与公主高定华服！"
    @Published public var importExportMessage: String? = nil
    @Published public var showBackupModal: Bool = false

    // MARK: - 局内闯关通用状态
    @Published public var currentLevelNumber: Int = 1
    @Published public var currentMode: LevelMode = .split
    @Published public var currentFire: FireDifficulty = .mid
    @Published public var specialMode: SpecialModeType? = nil
    @Published public var questionQueue: [PinyinWord] = []
    @Published public var curriculumQueue: [CurriculumQuestion] = []
    @Published public var questionIndex: Int = 0
    @Published public var rightCount: Int = 0
    @Published public var comboCount: Int = 0
    @Published public var retryLeft: Int = 2
    @Published public var retriedCurrent: Bool = false
    @Published public var masteredCount: Int = 0
    @Published public var newFoodsInRound: [String] = []
    @Published public var newDessertsInRound: [BakeryDessert] = []
    @Published public var newFlashcardsInRound: [EnglishFlashcard] = []
    @Published public var rewardedFashionInRound: [PrincessFashionItem] = []
    @Published public var roundStars: Int = 0

    // MARK: - 🪙 局内星币、🌈 彩虹连击宝箱、🎁 局末三选一宝箱、🎰 皇家扭蛋与🦄 守护萌宠状态
    @Published public var rainbowCharge: Int = 0
    @Published public var roundCoinsEarned: Int = 0
    @Published public var floatingCoinGainText: String? = nil
    @Published public var floatingCoinBurst: Int = 0
    @Published public var isFeverMode: Bool = false
    @Published public var rainbowChestBurstMessage: String? = nil
    @Published public var mysteryChests: [MysteryChestItem] = []
    @Published public var openedChestIndex: Int? = nil
    @Published public var isSpinningGacha: Bool = false
    @Published public var activeGachaHatch: GachaHatchEvent? = nil
    @Published public var activeGachaBatch: [GachaHatchEvent] = []
    @Published public var petFeedToast: String? = nil
    @Published public var petHeartBurst: Bool = false
    @Published public var petTalentActive: Bool = false
    @Published public var phoenixShieldsRemaining: Int = 0
    @Published public var dailyWheelResult: DailyWheelSlice? = nil
    @Published public var canSpinDailyWheel: Bool = false
    @Published public var milestoneToast: String? = nil
    @Published public var preparedBackupFileURL: URL? = nil

    // MARK: - 语文拼音题目交互槽位状态
    @Published public var pickedInitial: String? = nil
    @Published public var pickedMedial: String? = nil
    @Published public var pickedBaseFinal: String? = nil
    @Published public var pickedTone: Int? = nil
    @Published public var pickedTonedFinal: String? = nil

    // MARK: - 沪教数学 & 牛津英语题目交互状态
    @Published public var numericInput: String = ""
    @Published public var numericSmartOptions: [String] = []
    @Published public var sentencePickedIndices: [Int] = []
    /// 鲜果积木的展示顺序（打乱后的原始下标，避免按答案顺序排列）
    @Published public var sentenceDisplayOrder: [Int] = []
    /// 选择题打乱后的展示选项（原始数据中正确答案常排在第一位）
    @Published public var displayOptions: [String] = []
    @Published public var pickedChoiceOption: String? = nil
    @Published public var showMathExplanation: Bool = false

    // MARK: - 护眼与健康游戏状态
    @Published public var eyeRestActive: Bool = false
    @Published public var restRemaining: Int = 0
    @Published public var playLock: PlayLockReason? = nil
    @Published public var timeWarning: String? = nil
    @Published public var parentGate: ParentGatePurpose? = nil
    @Published public var showParentSettings: Bool = false
    private var continuousPlaySeconds: Int = 0
    private var unsavedPlaySeconds: Int = 0
    private var bedtimeOverrideUntil: Date? = nil
    private var warnedDate: String = ""

    /// 每开一局 / 返回主页自增，防止上一局遗留的延时任务篡改新一局的进度
    private var roundGeneration: Int = 0
    /// 每次重置存档时自增，防止重置前开启的扭蛋等异步任务覆盖状态
    private var stateResetGeneration: Int = 0

    @Published public var isLocked: Bool = false
    @Published public var isBlindRevealed: Bool = false
    @Published public var judgeState: String = "idle" // "idle", "good", "bad"
    @Published public var tipMessage: String = ""
    @Published public var tipStyle: String = "normal" // "normal", "ok", "no", "note"
    @Published public var chefBubble: String = "按顺序点卡片或拖进锅里吧！"
    @Published public var praisePopup: String? = nil
    @Published public var dishPopup: String? = nil
    @Published public var jqxRuleBanner: String? = nil
    @Published public var potShaking: Bool = false
    @Published public var potNope: Bool = false
    @Published public var steamActive: Bool = false
    @Published public var activeBlendingSlot: String? = nil

    // MARK: - 森林小动物顾客状态
    @Published public var currentCustomer: AnimalCustomer = AnimalCustomer.all[0]
    @Published public var customerMood: CustomerMood = .waiting

    // MARK: - 键盘连击缓冲
    private var keyBuffer: String = ""
    private var lastKeyTime: Date = .distantPast

    private let storageKey = "pinyin_kitchen_swiftui_v2"
    public let audio = PinyinAudioEngine.shared

    public static let mascotTips: [String] = [
        "小熊团团：欢迎来到《满满的奇妙料理城》，语数英三大工坊随心切换！",
        "小熊团团：闯关收集星币与华服礼盒，为满满公主换上皇冠、宝石项链和神翼吧！",
        "小熊团团：挑战「大火」模式，通关高定变装礼盒翻倍，还能培养 5 阶至尊神兽！",
        "小熊团团：在 Mac 上可直接按数字和字母答题，iPad 上小手点一点超丝滑！",
        "小熊团团：三科全部严格同步上海沪教版一年级上/下册教材哦！",
        "小熊团团：眼睛离屏幕要有一臂远（约 50 厘米），坐直身体再闯关！",
        "小熊团团：每玩 20 分钟，小熊会提醒你看看远处，让眼睛休息一下～"
    ]

    public static let praiseLines: [String] = [
        "太棒了！", "厨师长级别！", "火力全开！", "香喷喷！",
        "这一炉绝了！", "太厉害了！", "你是料理小天才！", "色香味俱全！"
    ]

    public init() {
        self.progress = Self.loadProgress(key: "pinyin_kitchen_swiftui_v2")
        self.progress.ensureDaily()
        refreshDailyDerivedState()
        saveProgress()
    }

    /// 同步派生状态（如每日转盘可用状态等）
    public func refreshDailyDerivedState() {
        canSpinDailyWheel = !progress.isDailyWheelSpunToday
    }

    // MARK: - 存档持久化与导入导出（iPad / Mac 多重本地自动保存 + 一键备份导出）

    private static func saveFileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appDir = dir.appendingPathComponent("PinyinKitchen", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("progress_v2.json")
    }

    private static func documentsSaveFileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return dir.appendingPathComponent("PinyinKitchen_progress_v2.json")
    }

    private static func backupTempFileURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("满满的奇妙料理城_存档备份.json")
    }

    private static func loadProgress(key: String) -> GameProgress {
        let decoder = JSONDecoder()
        var merged = GameProgress()
        var foundAny = false

        // 依次读取 ApplicationSupport、Documents、UserDefaults 并合并，确保 iPad / Mac 任意路径存档都不丢失
        // merge(from:) 对 wrong 等字典采用 max 策略而非相加，绝不会把多端存档倍增放大
        if let url = saveFileURL(),
           let data = try? Data(contentsOf: url),
           let loaded = try? decoder.decode(GameProgress.self, from: data) {
            merged = loaded
            foundAny = true
        }
        if let docURL = documentsSaveFileURL(),
           let data = try? Data(contentsOf: docURL),
           let loaded = try? decoder.decode(GameProgress.self, from: data) {
            if foundAny {
                _ = merged.merge(from: loaded)
            } else {
                merged = loaded
                foundAny = true
            }
        }
        if let data = UserDefaults.standard.data(forKey: key),
           let loaded = try? decoder.decode(GameProgress.self, from: data) {
            if foundAny {
                _ = merged.merge(from: loaded)
            } else {
                merged = loaded
                foundAny = true
            }
        }
        return merged
    }

    public func saveProgress() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        if let url = Self.saveFileURL() {
            try? data.write(to: url, options: .atomic)
        }
        if let docURL = Self.documentsSaveFileURL() {
            try? data.write(to: docURL, options: .atomic)
        }
    }

    public func exportJSONString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(progress),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    /// 显式按需生成 .json 备份文件供 ShareLink / AirDrop 导出（不要在 SwiftUI body 内调用）
    @discardableResult
    public func prepareBackupFile() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(progress) else { return nil }
        let fileURL = Self.backupTempFileURL()
        do {
            try data.write(to: fileURL, options: .atomic)
            preparedBackupFileURL = fileURL
            return fileURL
        } catch {
            return nil
        }
    }

    /// 兼容旧调用名称：按需生成可供 iPad「文件(Files)」/ AirDrop / 微信 分享导出的 .json 备份文件 URL
    public func exportBackupFileURL() -> URL? {
        prepareBackupFile()
    }

    /// 一键复制存档 JSON 到 iPad / Mac 剪贴板
    @discardableResult
    public func copySaveToClipboard() -> String {
        let str = exportJSONString()
        #if canImport(UIKit)
        UIPasteboard.general.string = str
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(str, forType: .string)
        #endif
        audio.sfxWin()
        let msg = "✅ 存档已复制到剪贴板！可粘贴到备忘录或微信保存，换设备/更新后点「从剪贴板恢复」即可。"
        importExportMessage = msg
        return msg
    }

    /// 一键从 iPad / Mac 剪贴板读取并合并恢复存档
    @discardableResult
    public func restoreSaveFromClipboard() -> String {
        var clipStr: String? = nil
        #if canImport(UIKit)
        clipStr = UIPasteboard.general.string
        #elseif canImport(AppKit)
        clipStr = NSPasteboard.general.string(forType: .string)
        #endif
        guard let raw = clipStr?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let data = raw.data(using: .utf8) else {
            audio.sfxBad()
            let msg = "⚠️ 剪贴板里还没有存档内容，请先复制备份的 JSON 文本。"
            importExportMessage = msg
            return msg
        }
        let res = importJSONData(data)
        importExportMessage = res
        return res
    }

    public func importJSONData(_ data: Data) -> String {
        let decoder = JSONDecoder()
        do {
            let incoming = try decoder.decode(GameProgress.self, from: data)
            let count = progress.merge(from: incoming)
            progress.ensureDaily()
            refreshDailyDerivedState()
            saveProgress()
            audio.sfxWin()
            return count > 0 ? "✅ 成功合并恢复 \(count) 项学习记录、星币与奖励！" : "ℹ️ 这份存档里的进度已全部包含在当前记录中"
        } catch {
            audio.sfxBad()
            return "❌ 导入失败：存档格式不正确（请确认复制了完整的 JSON 内容）"
        }
    }

    private func wipeAllSavedFiles() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        if let url = Self.saveFileURL() {
            try? FileManager.default.removeItem(at: url)
        }
        if let docURL = Self.documentsSaveFileURL() {
            try? FileManager.default.removeItem(at: docURL)
        }
        try? FileManager.default.removeItem(at: Self.backupTempFileURL())
    }

    private func resetPublishedTransientState(keepScreenHome: Bool) {
        if keepScreenHome {
            screenState = .home
            questionQueue = []
            curriculumQueue = []
            questionIndex = 0
            rightCount = 0
            comboCount = 0
            retryLeft = 2
            retriedCurrent = false
            masteredCount = 0
            showBackupModal = false
            showMathExplanation = false
            praisePopup = nil
            dishPopup = nil
            jqxRuleBanner = nil
            potShaking = false
            potNope = false
            steamActive = false
            activeBlendingSlot = nil
            pickedInitial = nil
            pickedMedial = nil
            pickedBaseFinal = nil
            pickedTone = nil
            pickedTonedFinal = nil
            numericInput = ""
            numericSmartOptions = []
            sentencePickedIndices = []
            sentenceDisplayOrder = []
            displayOptions = []
            pickedChoiceOption = nil
            roundCoinsEarned = 0
            rainbowCharge = 0
            roundStars = 0
            newFoodsInRound = []
            newDessertsInRound = []
            newFlashcardsInRound = []
        }
        rewardedFashionInRound = []
        floatingCoinGainText = nil
        floatingCoinBurst = 0
        isFeverMode = false
        rainbowChestBurstMessage = nil
        mysteryChests = []
        openedChestIndex = nil
        isSpinningGacha = false
        activeGachaHatch = nil
        activeGachaBatch = []
        pendingFashionUpgrades = []
        petFeedToast = nil
        petHeartBurst = false
        petTalentActive = false
        phoenixShieldsRemaining = 0
        dailyWheelResult = nil
        milestoneToast = nil
        preparedBackupFileURL = nil
        isLocked = false
        refreshDailyDerivedState()
    }

    /// 彻底重置全部存档（保留护眼设置与今日已用眼时长），清除三端存储与临时导出文件
    public func resetAllProgress() {
        stateResetGeneration += 1
        roundGeneration += 1
        audio.stopAllSpeech()

        // 护眼设置与今日游戏时长属于家长管控，清空学习记录时保留
        let keepEye = progress.eyeCare
        let keepPlay = progress.playSeconds
        let keepBonus = progress.bonusMinutes

        wipeAllSavedFiles()

        var fresh = GameProgress()
        fresh.eyeCare = keepEye
        fresh.playSeconds = keepPlay
        fresh.bonusMinutes = keepBonus
        fresh.ensureDaily()
        progress = fresh

        resetPublishedTransientState(keepScreenHome: true)
        importExportMessage = "✅ 已彻底清空所有学习与奖励存档！"
        saveProgress()
        audio.sfxTap()
    }

    /// 仅重置奖励与经济（保留全部语/数/英星星、关卡解锁、图鉴、错题本、历史记录、连续打卡、护眼与朗读偏好）
    public func resetRewardsOnlyKeepLearning() {
        stateResetGeneration += 1
        audio.stopAllSpeech()

        var clean = GameProgress()
        // 保留学习记录与偏好
        clean.unlocked = progress.unlocked
        clean.stars = progress.stars
        clean.food = progress.food
        clean.mathUnlocked = progress.mathUnlocked
        clean.mathStars = progress.mathStars
        clean.desserts = progress.desserts
        clean.englishUnlocked = progress.englishUnlocked
        clean.englishStars = progress.englishStars
        clean.englishCards = progress.englishCards
        clean.freeUnlockAll = progress.freeUnlockAll
        clean.wrong = progress.wrong
        clean.wrongMastered = progress.wrongMastered
        clean.history = progress.history
        clean.streak = progress.streak
        clean.bestCombo = progress.bestCombo
        clean.cleared = progress.cleared
        clean.tts = progress.tts
        clean.blind = progress.blind
        clean.seasoningMode = progress.seasoningMode
        clean.eyeCare = progress.eyeCare
        clean.playSeconds = progress.playSeconds
        clean.bonusMinutes = progress.bonusMinutes
        clean.daily = DailyProgress(
            d: GameProgress.todayString(),
            rounds: progress.daily.rounds,
            maxCombo: progress.daily.maxCombo,
            words: progress.daily.words,
            claimed: [:]
        )

        // 清零全部经济/衣橱/神兽/游乐园/里程碑奖励
        clean.coins = 0
        clean.gachaTickets = 0
        clean.starThread = 0
        clean.petCandy = 0
        clean.potSkin = "classic"
        clean.wardrobe = GameProgress.defaultWardrobe
        clean.equippedOutfit = GameProgress.defaultEquippedOutfit
        clean.pets = GameProgress.defaultPets
        clean.petFeedExp = [:]
        clean.equippedPetId = "fire_dragon"
        clean.castleUnlocked = ["fountain": 1]
        clean.gachaPityMythic = 0
        clean.gachaRepeatMissCount = 0
        clean.princessHairColorId = "caramel"
        clean.princessExpressionId = "smile"
        clean.princessPoseId = "curtsy"
        clean.claimedRankMilestones = []
        clean.claimedStarMilestones = []
        clean.claimedCollectionMilestones = [:]
        clean.dailyBallThemeClaimedDate = ""
        clean.dailyWheelSpunDate = ""
        clean.dailyPetPatDate = GameProgress.todayString()
        clean.dailyPetPatCount = 0
        clean.dailyDessertFeedDate = ""
        clean.migratedLegacyButterflies = true
        clean.ensureDaily()

        try? FileManager.default.removeItem(at: Self.backupTempFileURL())
        progress = clean
        resetPublishedTransientState(keepScreenHome: false)
        importExportMessage = "✅ 已重置星币、华服、神兽与里程碑奖励，完整保留所有学习成果与错题记录！"
        saveProgress()
        audio.sfxTap()
    }

    // MARK: - 派生属性

    public var currentPotSkin: PotSkin {
        let stars = progress.totalStars
        if let found = PotSkin.all.first(where: { $0.id == progress.potSkin && stars >= $0.needStars }) {
            return found
        }
        return PotSkin.all[0]
    }

    /// 当前伴读出战的守护萌宠精灵
    public var equippedPet: GuardianPetSpecies {
        let id = progress.equippedPetId
        if (progress.pets[id] ?? 0) > 0, let found = GuardianPetSpecies.all.first(where: { $0.id == id }) {
            return found
        }
        if let firstOwned = GuardianPetSpecies.all.first(where: { (progress.pets[$0.id] ?? 0) > 0 }) {
            return firstOwned
        }
        return GuardianPetSpecies.all[0]
    }

    public var equippedPetStage: Int {
        max(1, progress.petStage(for: equippedPet.id))
    }

    public var chefRank: ChefRankInfo {
        ChefRankInfo.compute(totalStars: progress.totalStars)
    }

    public var totalQuestionCountInRound: Int {
        currentSubject == .pinyin ? questionQueue.count : curriculumQueue.count
    }

    public var currentMaxStageCount: Int {
        switch currentSubject {
        case .pinyin:  return LevelRepository.levels.count
        case .math:    return HujiaoCurriculumRepository.mathStages.count
        case .english: return HujiaoCurriculumRepository.englishStages.count
        }
    }

    public var dailyQuests: [DailyQuestItem] {
        [
            DailyQuestItem(
                id: "q_round",
                title: "🍲 今日闯关完成 1 局",
                goal: 1,
                current: min(1, progress.daily.rounds),
                claimed: (progress.daily.claimed["q_round"] ?? 0) > 0
            ),
            DailyQuestItem(
                id: "q_combo",
                title: "⚡ 单局达成 4 连击",
                goal: 4,
                current: min(4, progress.daily.maxCombo),
                claimed: (progress.daily.claimed["q_combo"] ?? 0) > 0
            ),
            DailyQuestItem(
                id: "q_words",
                title: "📖 今日答对 6 道料理题",
                goal: 6,
                current: min(6, progress.daily.words),
                claimed: (progress.daily.claimed["q_words"] ?? 0) > 0
            )
        ]
    }

    public var isDailyFullClearClaimed: Bool {
        (progress.daily.claimed["q_full_bonus"] ?? 0) > 0
    }

    public func claimDailyQuest(_ questId: String) {
        progress.ensureDaily()
        guard let quest = dailyQuests.first(where: { $0.id == questId }),
              quest.isCompleted,
              !quest.claimed else {
            return
        }
        progress.daily.claimed[questId] = 1
        progress.coins += 35
        if questId == "q_words" {
            progress.gachaTickets += 1
        }
        let allThreeDone = ["q_round", "q_combo", "q_words"].allSatisfy { (progress.daily.claimed[$0] ?? 0) > 0 }
        var grantedFullClear = false
        if allThreeDone && (progress.daily.claimed["q_full_bonus"] ?? 0) == 0 {
            progress.daily.claimed["q_full_bonus"] = 1
            progress.gachaTickets += 1
            progress.starThread += 1
            progress.coins += 50
            grantedFullClear = true
        }

        let item = rollFashionReward(stars: 3, fire: .high)
        let wasOwned = progress.fashionCount(for: item.id) > 0
        let beforeStage = max(1, progress.fashionStage(for: item.id))
        progress.wardrobe[item.id] = (progress.wardrobe[item.id] ?? 0) + 1
        if !wasOwned {
            let currentEquipped = progress.equippedItem(for: item.category)
            if item.tier >= currentEquipped.tier {
                progress.equippedOutfit[item.category.rawValue] = item.id
            }
        }
        let afterStage = max(1, progress.fashionStage(for: item.id))
        let newCount = progress.fashionCount(for: item.id)
        saveProgress()
        audio.sfxChestOpen()

        let baseTitle = questId == "q_words"
            ? "🎁 每日目标达成！+35星币 · +1扭蛋券 · 获赠【\(item.name)】！"
            : "🎁 每日目标达成！+35星币 · 获赠【\(item.name)】！"
        let fullTitle = grantedFullClear
            ? baseTitle + "\n🌟 今日目标全清礼盒：额外 +1🎟️ +1🧵 +50🪙！"
            : baseTitle
        if grantedFullClear {
            milestoneToast = "🎁 今日目标全清大礼盒：+1 🎟️ +1 🧵 +50 🪙！"
        }
        pendingFashionUpgrades.append(
            FashionUpgradeEvent(
                item: item,
                isNewUnlock: !wasOwned,
                fromStage: beforeStage,
                toStage: afterStage,
                totalCount: newCount,
                customTitle: fullTitle
            )
        )
    }

    // MARK: - 🎰 皇家扭蛋机孵化（单抽 / 五连 / 10抽神话保底 / Lv.5溢出转化）、👗 满满公主高定变装、🏆 里程碑 & 🏰 游乐园建造

    private func performSingleGachaRoll(guaranteeRareOrNew: Bool) -> GachaHatchEvent {
        let isMythicPity = progress.gachaPityMythic >= 9
        let roll = Double.random(in: 0..<1)
        let targetRarity: Int
        if isMythicPity {
            targetRarity = 3
        } else if guaranteeRareOrNew {
            targetRarity = roll < 0.28 ? 3 : 2
        } else {
            targetRarity = roll < 0.16 ? 3 : (roll < 0.52 ? 2 : 1)
        }

        let rarityPool = GuardianPetSpecies.all.filter { $0.rarity == targetRarity }
        let unownedInTier = rarityPool.filter { (progress.pets[$0.id] ?? 0) == 0 }
        let allUnowned = GuardianPetSpecies.all.filter { (progress.pets[$0.id] ?? 0) == 0 }

        let pickedPet: GuardianPetSpecies
        if progress.gachaRepeatMissCount >= 3 && !allUnowned.isEmpty && Double.random(in: 0..<1) < 0.75 {
            pickedPet = (unownedInTier.isEmpty ? allUnowned : unownedInTier).randomElement() ?? rarityPool[0]
        } else if guaranteeRareOrNew && !unownedInTier.isEmpty {
            pickedPet = unownedInTier.randomElement() ?? rarityPool[0]
        } else if !unownedInTier.isEmpty && Double.random(in: 0..<1) < 0.45 {
            pickedPet = unownedInTier.randomElement() ?? rarityPool[0]
        } else {
            let notMaxed = rarityPool.filter { progress.petStage(for: $0.id) < GuardianPetSpecies.maxStage }
            if !notMaxed.isEmpty && Double.random(in: 0..<1) < 0.70 {
                pickedPet = notMaxed.randomElement() ?? rarityPool[0]
            } else {
                pickedPet = rarityPool.randomElement() ?? GuardianPetSpecies.all[0]
            }
        }

        if pickedPet.rarity == 3 {
            progress.gachaPityMythic = 0
        } else {
            progress.gachaPityMythic = min(9, progress.gachaPityMythic + 1)
        }

        let wasOwned = (progress.pets[pickedPet.id] ?? 0) > 0
        if !wasOwned {
            progress.gachaRepeatMissCount = 0
        } else {
            progress.gachaRepeatMissCount += 1
        }

        let beforeStage = max(1, progress.petStage(for: pickedPet.id))
        if wasOwned && beforeStage >= GuardianPetSpecies.maxStage {
            // 满级 5 阶神兽溢出转化为：+1 🌟 神兽糖果 + 60 🪙 星币补偿
            progress.petCandy += 1
            progress.coins += 60
            return GachaHatchEvent(
                pet: pickedPet,
                isNew: false,
                fromStage: beforeStage,
                toStage: beforeStage,
                totalExp: progress.petTotalExp(for: pickedPet.id),
                isMaxOverflow: true,
                overflowCandy: 1,
                overflowCoins: 60
            )
        }

        // 若抽到已拥有的未满级守护萌宠，直接获得 +2 点高额神兽成长值，加速冲击 5 阶至尊幻兽！
        progress.pets[pickedPet.id] = (progress.pets[pickedPet.id] ?? 0) + (wasOwned ? 2 : 1)
        if progress.equippedPetId.isEmpty {
            progress.equippedPetId = pickedPet.id
        }
        let afterStage = max(1, progress.petStage(for: pickedPet.id))
        let totalExp = progress.petTotalExp(for: pickedPet.id)
        return GachaHatchEvent(
            pet: pickedPet,
            isNew: !wasOwned,
            fromStage: beforeStage,
            toStage: afterStage,
            totalExp: totalExp
        )
    }

    /// 旋转皇家扭蛋机单抽（需 1 张皇家扭蛋券 或 120 料理星币；10 抽必出神话神兽，3 次未出新宠触发 75% 新宠保底）
    public func spinGacha(useTicket: Bool) {
        guard !isSpinningGacha && activeGachaHatch == nil && activeGachaBatch.isEmpty else { return }
        if useTicket {
            guard progress.gachaTickets >= 1 else {
                audio.sfxBad()
                petFeedToast = "🎟️ 扭蛋券不够啦！在大火模式集满彩虹能量或完成每日答题目标就能获得扭蛋券哦！"
                return
            }
            progress.gachaTickets -= 1
        } else {
            guard progress.coins >= 120 else {
                audio.sfxBad()
                petFeedToast = "🪙 旋转皇家扭蛋需要 120 星币（当前 \(progress.coins) 星币），去闯关答题攒星币吧！"
                return
            }
            progress.coins -= 120
        }

        isSpinningGacha = true
        petFeedToast = nil
        audio.sfxGachaCrank()

        let ev = performSingleGachaRoll(guaranteeRareOrNew: false)
        let resetGen = stateResetGeneration
        saveProgress()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 680_000_000)
            guard self.stateResetGeneration == resetGen else { return }
            self.isSpinningGacha = false
            guard !self.eyeRestActive && self.playLock == nil else {
                self.activeGachaBatch = [ev]
                self.activeGachaHatch = ev
                return
            }
            self.audio.sfxChestOpen()
            self.activeGachaBatch = [ev]
            self.activeGachaHatch = ev
            if ev.isMaxOverflow {
                self.petFeedToast = "✨ 「\(ev.pet.name)」已满 5 阶！自动转化为 +\(ev.overflowCandy) 🌟 神兽糖果 & +\(ev.overflowCoins) 🪙！"
            }
            self.audio.speakText("\(ev.pet.name)！\(ev.pet.cheerLine)", slow: false)
        }
    }

    /// 皇家扭蛋五连抽（5 张扭蛋券 或 8.5 折 510 星币，保底至少 1 只传说/神话或未解锁神兽！）
    public func spinGachaFive(useTicket: Bool) {
        guard !isSpinningGacha && activeGachaHatch == nil && activeGachaBatch.isEmpty else { return }
        if useTicket {
            guard progress.gachaTickets >= 5 else {
                audio.sfxBad()
                petFeedToast = "🎟️ 五连抽需要 5 张扭蛋券（当前 \(progress.gachaTickets) 张）！"
                return
            }
            progress.gachaTickets -= 5
        } else {
            guard progress.coins >= 510 else {
                audio.sfxBad()
                petFeedToast = "🪙 五连特惠需要 510 星币（8.5 折，当前 \(progress.coins) 星币）！"
                return
            }
            progress.coins -= 510
        }

        isSpinningGacha = true
        petFeedToast = nil
        audio.sfxGachaCrank()

        var events: [GachaHatchEvent] = []
        for idx in 0..<5 {
            let needGuarantee = (idx == 4) && !events.contains(where: { $0.pet.rarity >= 2 || $0.isNew })
            events.append(performSingleGachaRoll(guaranteeRareOrNew: needGuarantee))
        }
        let resetGen = stateResetGeneration
        saveProgress()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 780_000_000)
            guard self.stateResetGeneration == resetGen else { return }
            self.isSpinningGacha = false
            self.activeGachaBatch = events
            let highlight = events.first(where: { $0.pet.rarity == 3 })
                ?? events.first(where: { $0.isNew })
                ?? events.last
            self.activeGachaHatch = highlight
            let overflowCandySum = events.reduce(0) { $0 + $1.overflowCandy }
            let overflowCoinsSum = events.reduce(0) { $0 + $1.overflowCoins }
            if overflowCandySum > 0 {
                self.petFeedToast = "🎰 五连孵化完成！满阶溢出转化 +\(overflowCandySum) 🌟 神兽糖果 & +\(overflowCoinsSum) 🪙！"
            } else {
                let newCount = events.filter(\.isNew).count
                self.petFeedToast = newCount > 0
                    ? "🎰 五连孵化大吉！喜提 \(newCount) 只全新守护神兽！"
                    : "🎰 五连孵化完成！神兽们成长值大涨！"
            }
            guard !self.eyeRestActive && self.playLock == nil else { return }
            self.audio.sfxChestOpen()
            if let top = highlight {
                self.audio.speakText("五连皇家扭蛋开启啦！恭喜获得\(top.pet.name)！", slow: false)
            }
        }
    }

    public func dismissGachaHatch() {
        activeGachaHatch = nil
        activeGachaBatch = []
    }

    /// 投喂守护萌宠美食（投喂星币随阶位 1~4 阶递增：35 -> 50 -> 70 -> 95 星币；满 5 阶禁止继续消费扣币）
    public func feedPet(_ petId: String) {
        let pet = GuardianPetSpecies.byId(petId)
        guard (progress.pets[petId] ?? 0) > 0 else {
            audio.sfxBad()
            petFeedToast = "🥚 这只小精灵还没孵化呢，快去摇左侧的皇家扭蛋机吧！"
            return
        }
        let beforeStage = progress.petStage(for: petId)
        guard beforeStage < GuardianPetSpecies.maxStage else {
            audio.sfxSpark()
            petFeedToast = "🌈 「\(pet.name)」已经达到最高 5 阶「至尊幻兽」，无需再花星币投喂啦！"
            return
        }
        let cost = GuardianPetSpecies.feedCost(for: beforeStage)
        guard progress.coins >= cost else {
            audio.sfxBad()
            petFeedToast = "🪙 当前 \(beforeStage) 阶投喂【\(pet.favoriteFood)】需要 \(cost) 星币，去闯关答题赚星币吧！"
            return
        }

        progress.coins -= cost
        progress.petFeedExp[petId] = (progress.petFeedExp[petId] ?? 0) + 1
        let afterStage = progress.petStage(for: petId)
        let totalExp = progress.petTotalExp(for: petId)
        let resetGen = stateResetGeneration
        saveProgress()

        petHeartBurst = true
        audio.sfxPetHappy()

        if afterStage > beforeStage {
            petFeedToast = "👑 华丽蜕变！「\(pet.name)」突破至 \(afterStage) 阶【\(GuardianPetSpecies.stageName(for: afterStage))】！解锁：\(GuardianPetSpecies.stageVisualPerk(for: afterStage))！"
            let ev = GachaHatchEvent(
                pet: pet,
                isNew: false,
                fromStage: beforeStage,
                toStage: afterStage,
                totalExp: totalExp
            )
            activeGachaBatch = [ev]
            activeGachaHatch = ev
            audio.speakText("太酷啦！\(pet.name)进化成\(GuardianPetSpecies.stageName(for: afterStage))啦！", slow: false)
        } else {
            let nextNeed = progress.nextPetStageNeed(for: petId) ?? totalExp
            petFeedToast = "🍓 投喂【\(pet.favoriteFood)】成功！「\(pet.name)」成长值 \(totalExp)/\(nextNeed) 💖"
            audio.speakText(pet.cheerLine, slow: false)
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard self.stateResetGeneration == resetGen else { return }
            self.petHeartBurst = false
        }
    }

    /// 使用 🌟 神兽糖果投喂萌宠（+3 成长值）
    public func feedPetWithCandy(_ petId: String) {
        let pet = GuardianPetSpecies.byId(petId)
        guard (progress.pets[petId] ?? 0) > 0 else {
            audio.sfxBad()
            petFeedToast = "🥚 这只小精灵还没孵化呢！"
            return
        }
        let beforeStage = progress.petStage(for: petId)
        guard beforeStage < GuardianPetSpecies.maxStage else {
            audio.sfxSpark()
            petFeedToast = "🌈 「\(pet.name)」已是最高 5 阶至尊幻兽，把 🌟 神兽糖果留给其他伙伴吧！"
            return
        }
        guard progress.petCandy >= 1 else {
            audio.sfxBad()
            petFeedToast = "🌟 神兽糖果不足！达成里程碑、每日转盘或满阶扭蛋溢出均可获得糖果！"
            return
        }

        progress.petCandy -= 1
        progress.petFeedExp[petId] = (progress.petFeedExp[petId] ?? 0) + 3
        let afterStage = progress.petStage(for: petId)
        let totalExp = progress.petTotalExp(for: petId)
        let resetGen = stateResetGeneration
        saveProgress()

        petHeartBurst = true
        audio.sfxPetHappy()

        if afterStage > beforeStage {
            petFeedToast = "🌟 糖果突破！「\(pet.name)」直接跃升至 \(afterStage) 阶【\(GuardianPetSpecies.stageName(for: afterStage))】！"
            let ev = GachaHatchEvent(
                pet: pet,
                isNew: false,
                fromStage: beforeStage,
                toStage: afterStage,
                totalExp: totalExp
            )
            activeGachaBatch = [ev]
            activeGachaHatch = ev
            audio.speakText("太棒啦！吃下神兽糖果，\(pet.name)进化啦！", slow: false)
        } else {
            let nextNeed = progress.nextPetStageNeed(for: petId) ?? totalExp
            petFeedToast = "🌟 喂食神兽糖果成功！「\(pet.name)」+3 成长值（\(totalExp)/\(nextNeed)）！"
            audio.speakText(pet.cheerLine, slow: false)
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard self.stateResetGeneration == resetGen else { return }
            self.petHeartBurst = false
        }
    }

    /// 每日免费「摸摸抱抱」互动（每日至多 3 次，建造旋转木马后增至 4 次；每次 +10 🪙，第 3 次额外 +1 成长值）
    public func patPet() {
        progress.ensureDaily()
        let maxPats = progress.maxDailyPetPats
        let currentPats = progress.effectiveDailyPetPatCount
        guard currentPats < maxPats else {
            performPetTalent()
            petFeedToast = "💖 今天已经和「\(equippedPet.name)」亲密摸摸 \(maxPats)/\(maxPats) 次啦，明天再来找它玩！"
            return
        }

        progress.dailyPetPatDate = GameProgress.todayString()
        progress.dailyPetPatCount = currentPats + 1
        progress.coins += 10
        var bonusMsg = "+10 🪙"

        let targetId = equippedPet.id
        let beforeStage = progress.petStage(for: targetId)
        if progress.dailyPetPatCount == 3 {
            if beforeStage < GuardianPetSpecies.maxStage {
                progress.petFeedExp[targetId] = (progress.petFeedExp[targetId] ?? 0) + 1
                bonusMsg += " · 第 3 次贴贴额外 +1 成长值！"
                let afterStage = progress.petStage(for: targetId)
                if afterStage > beforeStage {
                    let ev = GachaHatchEvent(
                        pet: equippedPet,
                        isNew: false,
                        fromStage: beforeStage,
                        toStage: afterStage,
                        totalExp: progress.petTotalExp(for: targetId)
                    )
                    activeGachaBatch = [ev]
                    activeGachaHatch = ev
                }
            } else {
                progress.coins += 15
                bonusMsg += " · 第 3 次贴贴额外 +15 🪙！"
            }
        }

        let resetGen = stateResetGeneration
        saveProgress()
        petHeartBurst = true
        petTalentActive = true
        audio.sfxPetHappy()
        petFeedToast = "🤗 摸摸「\(equippedPet.name)」软乎乎的脑袋（今日 \(progress.dailyPetPatCount)/\(maxPats)）：\(bonusMsg)"
        audio.speakText("\(equippedPet.name)好开心呀！\(equippedPet.cheerLine)", slow: false)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard self.stateResetGeneration == resetGen else { return }
            self.petHeartBurst = false
            self.petTalentActive = false
        }
    }

    /// 触发出战守护神兽的展示才艺动作与语音应援
    public func performPetTalent() {
        let resetGen = stateResetGeneration
        petHeartBurst = true
        petTalentActive = true
        audio.sfxPetHappy()
        petFeedToast = "✨ 「\(equippedPet.name)」正在舞台闪亮展示！技能：\(equippedPet.effectiveSkillSummary(forStage: equippedPetStage))"
        audio.speakText("\(equippedPet.name)来给你加油啦！\(equippedPet.cheerLine)", slow: false)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            guard self.stateResetGeneration == resetGen else { return }
            self.petHeartBurst = false
            self.petTalentActive = false
        }
    }

    /// 每日免费 1 次：用数学烘焙屋已解锁的甜品投喂出战萌宠（+2 成长值 & +15 🪙；满阶返 +40 🪙）
    public func feedPetWithUnlockedDessert(_ dessertId: String) {
        progress.ensureDaily()
        guard (progress.desserts[dessertId] ?? 0) > 0 else {
            audio.sfxBad()
            petFeedToast = "🧁 这道甜品还没在数学烘焙屋制作解锁哦，先去数学关烘焙吧！"
            return
        }
        guard !progress.isDailyDessertFedToday else {
            audio.sfxBad()
            petFeedToast = "🍰 今天已经用数学烘焙甜品款待过萌宠啦，明天再来分享新甜品吧！"
            return
        }

        let dessertTitle = HujiaoCurriculumRepository.bakeryDesserts.first(where: { $0.id == dessertId })?.name ?? "数学烘焙甜品"
        progress.dailyDessertFeedDate = GameProgress.todayString()

        let petId = equippedPet.id
        let beforeStage = progress.petStage(for: petId)
        if beforeStage < GuardianPetSpecies.maxStage {
            progress.petFeedExp[petId] = (progress.petFeedExp[petId] ?? 0) + 2
            progress.coins += 15
            let afterStage = progress.petStage(for: petId)
            if afterStage > beforeStage {
                let ev = GachaHatchEvent(
                    pet: equippedPet,
                    isNew: false,
                    fromStage: beforeStage,
                    toStage: afterStage,
                    totalExp: progress.petTotalExp(for: petId)
                )
                activeGachaBatch = [ev]
                activeGachaHatch = ev
            }
            petFeedToast = "🍰 免费请「\(equippedPet.name)」品尝【\(dessertTitle)】！+2 成长值 & +15 🪙！"
        } else {
            progress.coins += 40
            petFeedToast = "🍰 请满阶「\(equippedPet.name)」品尝【\(dessertTitle)】！它回赠了 +40 🪙 幸运星币！"
        }

        let resetGen = stateResetGeneration
        saveProgress()
        petHeartBurst = true
        audio.sfxPetHappy()
        audio.speakText("\(equippedPet.name)吃到了香甜的\(dessertTitle)，能量满满！", slow: false)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 950_000_000)
            guard self.stateResetGeneration == resetGen else { return }
            self.petHeartBurst = false
        }
    }

    public func equipPet(_ petId: String) {
        guard (progress.pets[petId] ?? 0) > 0 else { return }
        progress.equippedPetId = petId
        saveProgress()
        audio.sfxPetHappy()
        let pet = GuardianPetSpecies.byId(petId)
        petFeedToast = "✨ 已将「\(pet.name)」设为伴读守护精灵，技能：\(pet.effectiveSkillSummary(forStage: progress.petStage(for: petId)))"
        audio.speakText("我是\(pet.name)，陪满满公主一起闯关！", slow: false)
    }

    // MARK: - 👗 满满公主换装穿戴、一键套装、星光锦缎升阶 & 发色/表情/Pose 个性定制

    public func equipFashionItem(_ item: PrincessFashionItem) {
        guard progress.fashionCount(for: item.id) > 0 else {
            unlockOrUpgradeFashionItem(item)
            return
        }
        progress.equippedOutfit[item.category.rawValue] = item.id
        saveProgress()
        audio.sfxTwirl()
        let st = progress.fashionStage(for: item.id)
        let suit = progress.suitBonusInfo()
        wardrobeToast = "👗 已换上 \(st) 阶【\(item.name)】，当前华丽值 \(progress.totalGlamourScore)（\(suit.suitName) \(suit.matchedCount)/5）！"
        audio.speakText("换上\(item.name)，真漂亮！", slow: false)
    }

    /// 一键穿戴指定高定套装中已解锁的所有部件（0...5）
    public func equipFashionSuit(_ styleIndex: Int) {
        let suitDef = PrincessFashionSuit.byStyleIndex(styleIndex)
        let ownedItems = suitDef.items.filter { progress.fashionCount(for: $0.id) > 0 }
        guard !ownedItems.isEmpty else {
            audio.sfxBad()
            wardrobeToast = "👗 还没解锁【\(suitDef.name)】的部件，先去闯关或星币裁制一件吧！"
            return
        }
        for item in ownedItems {
            progress.equippedOutfit[item.category.rawValue] = item.id
        }
        saveProgress()
        audio.sfxTwirl()
        let info = progress.suitBonusInfo()
        let resonanceText = info.isFullResonance
            ? "👑 5/5 满套装共鸣激活：+\(info.glamourBonusPercent)% 华丽度 & 每题 +\(info.coinBonus) 🪙！"
            : (info.isHalfResonance ? "✨ 3/5 套装共鸣激活：+\(info.glamourBonusPercent)% 华丽度！" : "已穿戴 \(ownedItems.count)/5 件！")
        wardrobeToast = "👗 一键换装【\(suitDef.name)】！\(resonanceText)"
        audio.speakText("换上\(suitDef.name)，闪亮登场！", slow: false)
    }

    public func unlockOrUpgradeFashionItem(_ item: PrincessFashionItem) {
        let currentCount = progress.fashionCount(for: item.id)
        if currentCount == 0 {
            // 首次解锁：检查总星数门槛与星币
            if progress.totalStars < item.needStars {
                audio.sfxBad()
                wardrobeToast = "⭐ 解锁【\(item.name)】需要先累计拿到 \(item.needStars) 颗星星（当前 \(progress.totalStars) 颗），快去闯关摘星吧！"
                return
            }
            guard progress.coins >= item.costCoins else {
                audio.sfxBad()
                wardrobeToast = "🪙 裁制【\(item.name)】需要 \(item.costCoins) 星币（当前 \(progress.coins) 星币），去闯关赚星币吧！"
                return
            }
            progress.coins -= item.costCoins
            progress.wardrobe[item.id] = 1
            progress.equippedOutfit[item.category.rawValue] = item.id
            saveProgress()
            audio.sfxChestOpen()
            wardrobeToast = "🎉 成功解锁并穿戴【\(item.name)】！继续收集或高定织造可升至 5 阶传世神装！"
            pendingFashionUpgrades.append(
                FashionUpgradeEvent(
                    item: item,
                    isNewUnlock: true,
                    fromStage: 1,
                    toStage: 1,
                    totalCount: 1,
                    customTitle: "👗 喜获新装！满满公主换上了【\(item.name)】！"
                )
            )
            audio.speakText("太美啦！成功解锁\(item.name)！", slow: false)
        } else {
            // 已拥有：执行高定织造（+1 升阶经验），越往后升阶所需次数与星币越高，外观越华丽
            let beforeStage = progress.fashionStage(for: item.id)
            guard beforeStage < PrincessFashionItem.maxStage else {
                audio.sfxSpark()
                progress.equippedOutfit[item.category.rawValue] = item.id
                saveProgress()
                wardrobeToast = "🌈【\(item.name)】已经达到最高 5 阶「传世神装」啦！"
                return
            }
            let craftCost = PrincessFashionItem.upgradeCraftCost(for: beforeStage, tier: item.tier)
            guard progress.coins >= craftCost else {
                audio.sfxBad()
                wardrobeToast = "🪙 高定织造【\(item.name)】需要 \(craftCost) 星币（当前 \(progress.coins) 星币），去闯关答题赚星币吧！"
                return
            }
            progress.coins -= craftCost
            progress.wardrobe[item.id] = currentCount + 1
            progress.equippedOutfit[item.category.rawValue] = item.id
            let afterStage = progress.fashionStage(for: item.id)
            let newCount = progress.fashionCount(for: item.id)
            saveProgress()

            if afterStage > beforeStage {
                audio.sfxChestOpen()
                wardrobeToast = "👑 高定升阶！【\(item.name)】华丽蜕变为 \(afterStage) 阶「\(PrincessFashionItem.stageName(for: afterStage))」！"
                pendingFashionUpgrades.append(
                    FashionUpgradeEvent(
                        item: item,
                        isNewUnlock: false,
                        fromStage: beforeStage,
                        toStage: afterStage,
                        totalCount: newCount,
                        customTitle: nil
                    )
                )
                audio.speakText("哇！\(item.name)华丽升阶为\(PrincessFashionItem.stageName(for: afterStage))！", slow: false)
            } else {
                audio.sfxSpark()
                let need = progress.nextFashionStageNeed(for: item.id) ?? newCount
                wardrobeToast = "🧵 高定织造成功！【\(item.name)】华丽度 \(newCount)/\(need)（再织造 \(max(1, need - newCount)) 次即可升入 \(beforeStage + 1) 阶）✨"
            }
        }
    }

    /// 消耗 1 份 🧵 星光锦缎 对已解锁华服进行 +1 升阶经验织造
    public func upgradeFashionWithThread(_ item: PrincessFashionItem) {
        let currentCount = progress.fashionCount(for: item.id)
        guard currentCount > 0 else {
            audio.sfxBad()
            wardrobeToast = "🔒 请先裁制解锁【\(item.name)】，再使用 🧵 星光锦缎升阶！"
            return
        }
        let beforeStage = progress.fashionStage(for: item.id)
        guard beforeStage < PrincessFashionItem.maxStage else {
            audio.sfxSpark()
            wardrobeToast = "🌈【\(item.name)】已是最高 5 阶传世神装，把 🧵 星光锦缎留给其他华服吧！"
            return
        }
        guard progress.starThread >= 1 else {
            audio.sfxBad()
            wardrobeToast = "🧵 星光锦缎不足！可通过每日任务全清、幸运转盘、舞会挑战与里程碑获得！"
            return
        }

        progress.starThread -= 1
        progress.wardrobe[item.id] = currentCount + 1
        let currentEq = progress.equippedItem(for: item.category)
        if item.tier >= currentEq.tier {
            progress.equippedOutfit[item.category.rawValue] = item.id
        }
        let afterStage = progress.fashionStage(for: item.id)
        let newCount = progress.fashionCount(for: item.id)
        saveProgress()

        if afterStage > beforeStage {
            audio.sfxChestOpen()
            wardrobeToast = "🧵✨ 星光锦缎织造蜕变！【\(item.name)】升至 \(afterStage) 阶「\(PrincessFashionItem.stageName(for: afterStage))」！"
            pendingFashionUpgrades.append(
                FashionUpgradeEvent(
                    item: item,
                    isNewUnlock: false,
                    fromStage: beforeStage,
                    toStage: afterStage,
                    totalCount: newCount,
                    customTitle: "🧵 星光锦缎注入，【\(item.name)】升阶啦！"
                )
            )
            audio.speakText("星光锦缎生效！\(item.name)升级到\(PrincessFashionItem.stageName(for: afterStage))！", slow: false)
        } else {
            audio.sfxSpark()
            let need = progress.nextFashionStageNeed(for: item.id) ?? newCount
            wardrobeToast = "🧵 消耗 1 份星光锦缎！【\(item.name)】华丽度 \(newCount)/\(need) ✨"
        }
    }

    public func setHairColor(_ option: HairColorOption) {
        guard progress.isHairColorUnlocked(option) else {
            audio.sfxBad()
            wardrobeToast = "🔒 发色【\(option.name)】需要「\(option.unlockDesc)」才能解锁哦！"
            return
        }
        progress.princessHairColorId = option.id
        saveProgress()
        audio.sfxSpark()
        wardrobeToast = "🎨 已为满满公主染上【\(option.name)】秀发！"
    }

    public func setExpression(_ expr: PrincessExpression) {
        guard progress.isExpressionUnlocked(expr) else {
            audio.sfxBad()
            wardrobeToast = "🔒 表情【\(expr.name)】需要「\(expr.unlockDesc)」才能解锁哦！"
            return
        }
        progress.princessExpressionId = expr.id
        saveProgress()
        audio.sfxSpark()
        wardrobeToast = "😊 满满公主换上了【\(expr.name)】甜美表情！"
    }

    public func setPose(_ pose: PrincessPose) {
        guard progress.isPoseUnlocked(pose) else {
            audio.sfxBad()
            wardrobeToast = "🔒 舞台 Pose【\(pose.name)】需要「\(pose.unlockDesc)」才能解锁哦！"
            return
        }
        progress.princessPoseId = pose.id
        saveProgress()
        audio.sfxTwirl()
        wardrobeToast = "💃 满满公主摆出【\(pose.name)】优雅造型！"
    }

    // MARK: - 💃 每日舞会主题挑战、👑 爵位/摘星/图鉴里程碑 & 🎡 每日幸运小转盘

    public func dailyBallMatchCount(for theme: DailyBallTheme = DailyBallTheme.today()) -> Int {
        PrincessFashionCategory.allCases.filter {
            progress.equippedItem(for: $0).styleIndex == theme.targetStyleIndex
        }.count
    }

    public var canClaimDailyBallReward: Bool {
        let theme = DailyBallTheme.today()
        return !progress.isDailyBallClaimedToday
            && dailyBallMatchCount(for: theme) >= theme.minMatchingPieces
            && progress.totalGlamourScore >= theme.minGlamour
    }

    public func claimDailyBallReward() {
        let theme = DailyBallTheme.today()
        guard !progress.isDailyBallClaimedToday else {
            audio.sfxSpark()
            wardrobeToast = "💃 今日舞会主题【\(theme.title)】已赴宴领奖啦，明天会有新舞会哦！"
            return
        }
        let matched = dailyBallMatchCount(for: theme)
        guard matched >= theme.minMatchingPieces && progress.totalGlamourScore >= theme.minGlamour else {
            audio.sfxBad()
            wardrobeToast = "👗 赴宴还差一点点：需同主题部件 \(matched)/\(theme.minMatchingPieces) 件、华丽度 \(progress.totalGlamourScore)/\(theme.minGlamour)！"
            return
        }

        progress.dailyBallThemeClaimedDate = GameProgress.todayString()
        progress.coins += theme.rewardCoins
        progress.starThread += theme.rewardStarThread
        saveProgress()
        audio.sfxWin()
        let msg = "💃 今日舞会主题「\(theme.title)」华丽赴宴成功！+\(theme.rewardCoins) 🪙 +\(theme.rewardStarThread) 🧵！"
        wardrobeToast = msg
        milestoneToast = msg
        audio.speakText("太美艳动人啦！每日公主舞会赴宴成功！", slow: false)
    }

    public var claimableRankMilestones: [ChefRankMilestone] {
        ChefRankMilestone.all.filter {
            $0.level > 0
                && progress.totalStars >= $0.minStars
                && !progress.claimedRankMilestones.contains($0.level)
        }
    }

    public func claimRankPromotionGift(_ level: Int) {
        guard let milestone = ChefRankMilestone.all.first(where: { $0.level == level && $0.level > 0 }),
              progress.totalStars >= milestone.minStars,
              !progress.claimedRankMilestones.contains(level) else {
            return
        }
        progress.claimedRankMilestones.append(level)
        progress.coins += milestone.rewardCoins
        progress.gachaTickets += milestone.rewardTickets
        progress.starThread += milestone.rewardStarThread
        progress.petCandy += milestone.rewardPetCandy
        saveProgress()
        audio.sfxWin()
        milestoneToast = "👑 晋升头衔【\(milestone.name)】！领到贺礼：\(milestone.rewardDesc)"
        audio.speakText("恭喜晋升\(milestone.name)！", slow: false)
    }

    public func isStarMilestoneClaimed(_ needStars: Int) -> Bool {
        progress.claimedStarMilestones.contains(needStars)
    }

    public var claimableStarMilestones: [StarMilestone] {
        StarMilestone.all.filter {
            progress.totalStars >= $0.needStars && !progress.claimedStarMilestones.contains($0.needStars)
        }
    }

    public func claimStarMilestone(_ needStars: Int) {
        guard let milestone = StarMilestone.all.first(where: { $0.needStars == needStars }),
              progress.totalStars >= milestone.needStars,
              !progress.claimedStarMilestones.contains(needStars) else {
            return
        }
        progress.claimedStarMilestones.append(needStars)
        progress.coins += milestone.rewardCoins
        progress.gachaTickets += milestone.rewardTickets
        progress.starThread += milestone.rewardStarThread
        progress.petCandy += milestone.rewardPetCandy
        saveProgress()
        audio.sfxWin()
        milestoneToast = "⭐ 摘星之路 \(needStars)★【\(milestone.title)】达成！获赠：\(milestone.rewardDesc)"
        audio.speakText("恭喜完成\(needStars)颗星里程碑！", slow: false)
    }

    public func collectionMilestoneStatus(for subject: SubjectKind) -> CollectionMilestoneStatus {
        let currentCount: Int
        let step: Int
        let maxCount: Int
        let rewardCoins: Int
        switch subject {
        case .pinyin:
            currentCount = progress.foodCount
            step = 15
            maxCount = max(15, Set(LevelRepository.levels.flatMap(\.words).map(\.character)).count)
            rewardCoins = 80
        case .math:
            currentCount = progress.dessertCount
            step = 5
            maxCount = max(5, HujiaoCurriculumRepository.bakeryDesserts.count)
            rewardCoins = 70
        case .english:
            currentCount = progress.englishCardCount
            step = 10
            maxCount = max(10, HujiaoCurriculumRepository.englishFlashcards.count)
            rewardCoins = 75
        }
        let lastClaimed = progress.claimedCollectionMilestones[subject.rawValue] ?? 0
        let steppedNext = ((lastClaimed / step) + 1) * step
        let nextTarget: Int?
        if steppedNext <= maxCount {
            nextTarget = steppedNext
        } else if lastClaimed < maxCount {
            nextTarget = maxCount
        } else {
            nextTarget = nil
        }
        let canClaim = nextTarget.map { currentCount >= $0 } ?? false
        return CollectionMilestoneStatus(
            subject: subject,
            currentCount: currentCount,
            step: step,
            maxCount: maxCount,
            lastClaimedThreshold: lastClaimed,
            nextTarget: nextTarget,
            canClaim: canClaim,
            rewardCoins: rewardCoins,
            rewardTickets: 1,
            rewardStarThread: 1,
            rewardDesc: "+\(rewardCoins) 🪙 +1 🎟️ +1 🧵"
        )
    }

    public func claimCollectionMilestone(subject: SubjectKind) {
        let status = collectionMilestoneStatus(for: subject)
        guard status.canClaim, let target = status.nextTarget else { return }
        progress.claimedCollectionMilestones[subject.rawValue] = target
        progress.coins += status.rewardCoins
        progress.gachaTickets += status.rewardTickets
        progress.starThread += status.rewardStarThread
        saveProgress()
        audio.sfxWin()
        milestoneToast = "📚 【\(subject.title)】图鉴突破 \(target) 件里程碑！获赠：\(status.rewardDesc)"
        audio.speakText("\(subject.title)图鉴收集突破\(target)件啦！", slow: false)
    }

    /// 旋转每日幸运小转盘（每日免费 1 次，100% 中奖；解锁魔法天文钟楼额外 +15 🪙）
    public func spinDailyWheel() {
        progress.ensureDaily()
        guard !progress.isDailyWheelSpunToday else {
            refreshDailyDerivedState()
            audio.sfxBad()
            milestoneToast = "🎡 今天已经转过幸运大转盘啦，明天再来转好礼吧！"
            return
        }

        let slice = DailyWheelSlice.all.randomElement() ?? DailyWheelSlice.all[0]
        progress.dailyWheelSpunDate = GameProgress.todayString()
        switch slice.rewardType {
        case "coins":  progress.coins += slice.amount
        case "ticket": progress.gachaTickets += slice.amount
        case "thread": progress.starThread += slice.amount
        case "candy":  progress.petCandy += slice.amount
        default:       progress.coins += 30
        }

        var bonusText = ""
        if (progress.castleUnlocked["clock_tower"] ?? 0) > 0 {
            progress.coins += 15
            bonusText = " + 🕰️ 天文钟楼 +15 🪙"
        }

        dailyWheelResult = slice
        refreshDailyDerivedState()
        saveProgress()
        audio.sfxWheelSpin()
        audio.sfxWin()
        milestoneToast = "🎡 每日幸运大转盘转中【\(slice.title)】\(bonusText)！"
        audio.speakText("幸运大转盘转中了\(slice.title)！", slow: false)
    }

    public func unlockCastleAttraction(_ item: CastleAttraction) {
        if (progress.castleUnlocked[item.id] ?? 0) > 0 {
            audio.sfxFirework()
            audio.speakText(item.cheerSpeech, slow: false)
            petFeedToast = "🎡 \(item.name)（\(item.perkShortTag)）：\(item.cheerSpeech)"
            return
        }
        guard progress.coins >= item.costCoins else {
            audio.sfxBad()
            petFeedToast = "🪙 点亮「\(item.name)」需要 \(item.costCoins) 星币，去闯关答题赚星币吧！"
            return
        }
        progress.coins -= item.costCoins
        progress.castleUnlocked[item.id] = 1
        saveProgress()
        audio.sfxChestOpen()
        audio.speakText("恭喜点亮\(item.name)！\(item.cheerSpeech)", slow: false)
        petFeedToast = "🎉 成功建造「\(item.name)」！已激活永久增益：\(item.perkDesc)！"
    }

    /// 局内每答对 1 题发放星币、彩虹能量槽与 12 大守护萌宠专属技能 + Fever 狂热连击倍率
    public func grantQuestionCorrectReward(wasWrongMastered: Bool) {
        let baseCoin: Int
        switch currentFire {
        case .low:  baseCoin = 5
        case .mid:  baseCoin = 7
        case .high: baseCoin = 10
        }

        let mult = equippedPetStage >= 4 ? 2 : 1
        let petBaseCoin = equippedPet.baseCoinPerQuestion * mult + equippedPetStage
        let comboBonus = min(comboCount, 5) * 2
        let masterBonus = wasWrongMastered ? 10 : 0
        let suitCoin = progress.suitBonusInfo().coinBonus
        let glamourCoin = progress.glamourRank.coinBonus
        let fountainCoin = (progress.castleUnlocked["fountain"] ?? 0) > 0 ? 1 : 0
        let musicBoxCoin = ((progress.castleUnlocked["music_box"] ?? 0) > 0 && comboCount >= 3) ? 1 : 0

        var petSkillCoin = 0
        var skillTag: String? = nil
        var unicornExtraCharge = 0
        var doubleQuestionGain = false

        switch equippedPet.kind {
        case .fireDragon:
            break
        case .unicorn:
            if comboCount >= 3 {
                unicornExtraCharge = 1
                skillTag = "🦄 +1彩虹"
            }
        case .nineTailFox:
            if Double.random(in: 0..<1) < (0.15 * Double(mult)) {
                petSkillCoin += 12 * mult
                skillTag = "🦊 狐仙暴击+\(12 * mult)"
            }
        case .azureDragon:
            petSkillCoin += min(comboCount, 5) * mult
        case .phoenix:
            break
        case .pandaChef:
            if !retriedCurrent && (currentSubject == .pinyin || currentSubject == .math) {
                petSkillCoin += 3 * mult
            }
        case .whale:
            break
        case .luckyCat:
            if Double.random(in: 0..<1) < (0.18 * Double(mult)) {
                doubleQuestionGain = true
                skillTag = "🐱 招财双倍"
            }
        case .owlDoctor:
            if wasWrongMastered {
                petSkillCoin += 15 * mult
                skillTag = "🦉 消错+\(15 * mult)"
            }
        case .auroraDeer:
            break
        case .moonRabbit:
            if !retriedCurrent && currentSubject == .english {
                petSkillCoin += 3 * mult
            }
        case .corgiPilot:
            break
        }

        var gain = baseCoin + comboBonus + petBaseCoin + masterBonus + suitCoin + glamourCoin + fountainCoin + musicBoxCoin + petSkillCoin
        if doubleQuestionGain {
            gain *= 2
        }

        let wasFever = isFeverMode
        isFeverMode = (comboCount >= 5)
        if isFeverMode {
            gain = Int((Double(gain) * 1.5).rounded())
            if !wasFever {
                audio.sfxFever()
            }
        }

        progress.coins += gain
        roundCoinsEarned += gain
        rainbowCharge += 1 + unicornExtraCharge
        floatingCoinBurst += 1
        audio.sfxCoin()

        if rainbowCharge >= 8 {
            rainbowCharge -= 8
            var chestCoins = 35
            if (progress.castleUnlocked["ferris_wheel"] ?? 0) > 0 {
                chestCoins += 10
            }
            if equippedPet.kind == .whale {
                chestCoins += 12 * mult
            }
            if equippedPet.kind == .unicorn {
                chestCoins += 10 * mult
            }
            progress.coins += chestCoins
            roundCoinsEarned += chestCoins
            if currentFire == .high || comboCount >= 6 {
                progress.gachaTickets += 1
                floatingCoinGainText = "🌈 彩虹宝箱 +\(chestCoins)🪙 +1🎟️"
                rainbowChestBurstMessage = "🌈 集满 8 格彩虹能量！爆出 +\(chestCoins) 🪙 星币 & 1 张皇家扭蛋券 🎟️！"
            } else {
                floatingCoinGainText = "🌈 彩虹宝箱 +\(chestCoins)🪙"
                rainbowChestBurstMessage = "🌈 集满 8 格彩虹能量！惊喜爆出 +\(chestCoins) 🪙 料理星币！（挑战大火或 6 连击还能掉扭蛋券哦）"
            }
            audio.sfxChestOpen()
        } else {
            let feverTag = isFeverMode ? " 🔥1.5x" : ""
            let suffix = skillTag.map { " · \($0)" } ?? ""
            floatingCoinGainText = "+\(gain) 🪙\(feverTag)\(suffix)"
            rainbowChestBurstMessage = nil
        }
    }

    /// 局末三选一神秘宝箱翻牌
    public func openMysteryChest(at index: Int) {
        guard openedChestIndex == nil, index >= 0, index < mysteryChests.count else { return }
        openedChestIndex = index
        let chosen = mysteryChests[index]
        switch chosen.rewardType {
        case "coins":
            progress.coins += chosen.amount
            roundCoinsEarned += chosen.amount
        case "ticket":
            progress.gachaTickets += chosen.amount
            progress.coins += 15
            roundCoinsEarned += 15
        case "thread":
            progress.starThread += chosen.amount
            progress.coins += 15
            roundCoinsEarned += 15
        case "candy":
            progress.petCandy += chosen.amount
            progress.coins += 15
            roundCoinsEarned += 15
        case "fashion":
            let item = chosen.fashionItemId.map { PrincessFashionItem.byId($0) } ?? rollFashionReward(stars: 3, fire: .high)
            let wasOwned = progress.fashionCount(for: item.id) > 0
            let beforeStage = max(1, progress.fashionStage(for: item.id))
            progress.wardrobe[item.id] = (progress.wardrobe[item.id] ?? 0) + 1
            if !wasOwned {
                let currentEquipped = progress.equippedItem(for: item.category)
                if item.tier >= currentEquipped.tier {
                    progress.equippedOutfit[item.category.rawValue] = item.id
                }
            }
            let afterStage = max(1, progress.fashionStage(for: item.id))
            rewardedFashionInRound.append(item)
            if !wasOwned || afterStage > beforeStage {
                pendingFashionUpgrades.append(
                    FashionUpgradeEvent(
                        item: item,
                        isNewUnlock: !wasOwned,
                        fromStage: beforeStage,
                        toStage: afterStage,
                        totalCount: progress.fashionCount(for: item.id),
                        customTitle: !wasOwned ? "🎁 宝箱爆出新华服【\(item.name)】！" : nil
                    )
                )
            }
        default:
            progress.coins += 35
            roundCoinsEarned += 35
        }

        if (progress.castleUnlocked["windmill"] ?? 0) > 0 {
            progress.coins += 10
            roundCoinsEarned += 10
        }

        saveProgress()
        audio.sfxChestOpen()
        audio.speakText("太棒啦！打开神秘宝箱获得\(chosen.title)！", slow: false)
    }

    /// 根据本局星级与火候难度抽取满满公主变装服饰（限制最多前瞻当前总星数 +8 颗星，杜绝 0 星直接掉高阶）
    public func rollFashionReward(stars: Int, fire: FireDifficulty) -> PrincessFashionItem {
        let rawRoll = Double.random(in: 0..<1)
        let deerBoost: Double = equippedPet.kind == .auroraDeer ? (equippedPetStage >= 4 ? 0.30 : 0.15) : 0.0
        let x = max(0.0, rawRoll - deerBoost)

        let wantedMaxTier: Int
        if stars >= 3 && fire == .high {
            wantedMaxTier = x < 0.22 ? 4 : (x < 0.58 ? 3 : 2)
        } else if stars >= 3 {
            wantedMaxTier = x < 0.10 ? 4 : (x < 0.42 ? 3 : (x < 0.78 ? 2 : 1))
        } else if stars == 2 {
            wantedMaxTier = x < 0.25 ? 3 : (x < 0.65 ? 2 : 1)
        } else {
            wantedMaxTier = x < 0.35 ? 2 : 1
        }

        let maxAllowedNeedStars = progress.totalStars + 8
        var selectedPool: [PrincessFashionItem] = []
        for t in stride(from: wantedMaxTier, through: 1, by: -1) {
            let candidates = PrincessFashionItem.all.filter {
                $0.tier == t && $0.needStars <= maxAllowedNeedStars
            }
            if !candidates.isEmpty {
                selectedPool = candidates
                break
            }
        }
        if selectedPool.isEmpty {
            selectedPool = PrincessFashionItem.all.filter { $0.tier == 1 }
        }

        let notMaxed = selectedPool.filter { progress.fashionStage(for: $0.id) < PrincessFashionItem.maxStage }
        let workingPool = notMaxed.isEmpty ? selectedPool : notMaxed
        let unowned = workingPool.filter { progress.fashionCount(for: $0.id) == 0 }
        let unownedBoost = fire.rareBoost
        if !unowned.isEmpty && Double.random(in: 0..<1) < unownedBoost {
            return unowned.randomElement() ?? workingPool[0]
        }
        return workingPool.randomElement() ?? PrincessFashionItem.all[0]
    }

    // MARK: - 当前题目与卡片数据

    public var currentWord: PinyinWord? {
        guard currentSubject == .pinyin, questionIndex >= 0, questionIndex < questionQueue.count else { return nil }
        return questionQueue[questionIndex]
    }

    public var currentCurriculumQuestion: CurriculumQuestion? {
        guard currentSubject != .pinyin, questionIndex >= 0, questionIndex < curriculumQueue.count else { return nil }
        return curriculumQueue[questionIndex]
    }

    public var currentLevelDef: LevelDefinition {
        let lvNum = currentWord?.levelNumber ?? currentLevelNumber
        return LevelRepository.levels[max(0, min(LevelRepository.levels.count - 1, lvNum - 1))]
    }

    public var currentMathStageDef: MathStageDefinition {
        // 错题特训 / 全明星模式下题目来自不同关卡，按题目反查所属关卡
        let stageId = currentCurriculumQuestion.flatMap { HujiaoCurriculumRepository.mathStageId(for: $0) } ?? currentLevelNumber
        let idx = max(0, min(HujiaoCurriculumRepository.mathStages.count - 1, stageId - 1))
        return HujiaoCurriculumRepository.mathStages[idx]
    }

    public var currentEnglishStageDef: EnglishStageDefinition {
        let stageId = currentCurriculumQuestion.flatMap { HujiaoCurriculumRepository.englishStageId(for: $0) } ?? currentLevelNumber
        let idx = max(0, min(HujiaoCurriculumRepository.englishStages.count - 1, stageId - 1))
        return HujiaoCurriculumRepository.englishStages[idx]
    }

    /// 英语题目的英文音频是否就是答案本身（答题前不能展示/朗读，否则等于直接给答案）
    public var promptAudioRevealsAnswer: Bool {
        guard currentSubject == .english,
              let q = currentCurriculumQuestion,
              let eng = q.englishAudio, !eng.isEmpty else { return false }
        if q.type == "sentence" { return true }
        let a = eng.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let b = q.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return a == b
    }

    /// 当前题目是否已经判定完毕（判定后才展示完整讲解与答案）
    public var isCurrentQuestionJudged: Bool {
        judgeState != "idle"
    }

    /// 锦囊内容：答题前给不泄露答案的方法提示，判定后才给完整讲解
    public var hintText: String {
        guard let q = currentCurriculumQuestion else { return "" }
        if isCurrentQuestionJudged { return q.explanation }
        if currentSubject == .math {
            return "想一想：\(currentMathStageDef.tip)"
        }
        if q.type == "sentence" {
            return "想一想：英语句子一般先说「谁」，再说「做什么」；首字母大写的单词放最前面，带句号、问号或感叹号的单词放最后面！"
        }
        return "想一想：先把题目的中文意思读懂，再点选项旁边的小喇叭逐个听一听，选出最合适的那一个！"
    }

    /// 仅用于语音朗读的题干清洗（去掉 emoji 与特殊符号）
    private static func speakableText(_ text: String) -> String {
        let replaced = text
            .replacingOccurrences(of: "🧱 句子果粒积木：", with: "")
            .replacingOccurrences(of: "□", with: "方框")
            .replacingOccurrences(of: "○", with: "圆圈")
            .replacingOccurrences(of: "△", with: "三角形")
            .replacingOccurrences(of: "★", with: "星星")
            .replacingOccurrences(of: "☆", with: "空心星星")
        let scalars = replaced.unicodeScalars.filter { s in
            !(s.properties.isEmojiPresentation || s.value == 0xFE0F || s.value == 0x200D)
        }
        return String(String.UnicodeScalarView(scalars))
    }

    public var availableInitials: [String] {
        let lv = currentLevelDef
        guard lv.mode != .whole else { return [] }
        let set = Set(lv.words.compactMap(\.initial))
        return set.sorted {
            (PinyinHelper.initialOrder.firstIndex(of: $0) ?? 99) < (PinyinHelper.initialOrder.firstIndex(of: $1) ?? 99)
        }
    }

    public var availableMedials: [String] {
        let lv = currentLevelDef
        guard lv.mode == .tri else { return [] }
        let set = Set(lv.words.compactMap(\.medial))
        let order = ["i", "u", "ü"]
        return set.sorted { (order.firstIndex(of: $0) ?? 9) < (order.firstIndex(of: $1) ?? 9) }
    }

    public var availableBaseFinals: [String] {
        let lv = currentLevelDef
        let set = Set(lv.words.map(\.baseFinal))
        if lv.mode == .whole {
            return set.sorted {
                (PinyinHelper.wholeOrder.firstIndex(of: $0) ?? 99) < (PinyinHelper.wholeOrder.firstIndex(of: $1) ?? 99)
            }
        } else {
            return set.sorted {
                (PinyinHelper.finalOrder.firstIndex(of: $0) ?? 99) < (PinyinHelper.finalOrder.firstIndex(of: $1) ?? 99)
            }
        }
    }

    public var availableTonedFinals: [String] {
        let lv = currentLevelDef
        let set = Set(lv.words.map(\.tonedFinal))
        return set.sorted { a, b in
            let ba = PinyinHelper.stripTone(a)
            let bb = PinyinHelper.stripTone(b)
            if ba != bb {
                let orderList = lv.mode == .whole ? PinyinHelper.wholeOrder : PinyinHelper.finalOrder
                return (orderList.firstIndex(of: ba) ?? 99) < (orderList.firstIndex(of: bb) ?? 99)
            }
            return PinyinHelper.toneNumber(of: a) < PinyinHelper.toneNumber(of: b)
        }
    }

    // MARK: - 开启关卡或特训模式（支持语数英三科）

    public func startSubjectStage(stageId: Int, fire: FireDifficulty) {
        switch currentSubject {
        case .pinyin:
            startLevel(levelNumber: stageId, fire: fire)
        case .math:
            startCurriculumStage(subject: .math, stageId: stageId, fire: fire)
        case .english:
            startCurriculumStage(subject: .english, stageId: stageId, fire: fire)
        }
    }

    public func startLevel(levelNumber: Int, fire: FireDifficulty) {
        roundGeneration += 1
        currentSubject = .pinyin
        progress.touchStreak()
        saveProgress()
        let lv = LevelRepository.levels[max(0, min(LevelRepository.levels.count - 1, levelNumber - 1))]
        var shuffled = lv.words.shuffled()
        var wrongWords: [PinyinWord] = []
        var normalWords: [PinyinWord] = []
        for w in shuffled {
            if (progress.wrong[w.id] ?? 0) > 0 {
                wrongWords.append(w)
            } else {
                normalWords.append(w)
            }
        }
        var queue = wrongWords + normalWords
        while queue.count < fire.questionCount {
            shuffled = (wrongWords + normalWords).shuffled()
            queue.append(contentsOf: shuffled)
        }
        queue = Array(queue.prefix(fire.questionCount))

        currentLevelNumber = levelNumber
        currentMode = lv.mode
        currentFire = fire
        specialMode = nil
        questionQueue = queue
        curriculumQueue = []
        questionIndex = 0
        rightCount = 0
        comboCount = 0
        isFeverMode = false
        phoenixShieldsRemaining = (equippedPet.kind == .phoenix) ? (equippedPetStage >= 4 ? 2 : 1) : 0
        retryLeft = fire.retryAllowance
        retriedCurrent = false
        masteredCount = 0
        newFoodsInRound = []
        newDessertsInRound = []
        newFlashcardsInRound = []
        rewardedFashionInRound = []
        roundCoinsEarned = 0
        floatingCoinGainText = nil
        rainbowChestBurstMessage = nil
        mysteryChests = []
        openedChestIndex = nil
        firePickerLevel = nil
        screenState = .playing
        setupCurrentQuestion()
    }

    public func startCurriculumStage(subject: SubjectKind, stageId: Int, fire: FireDifficulty) {
        roundGeneration += 1
        currentSubject = subject
        progress.touchStreak()
        saveProgress()

        let rawPool: [CurriculumQuestion] = (subject == .math)
            ? HujiaoCurriculumRepository.questionsForMathStage(stageId)
            : HujiaoCurriculumRepository.questionsForEnglishStage(stageId)

        var shuffled = rawPool.shuffled()
        // 根据火候难度智能倾向题目难度，但保持多样化
        if fire == .low {
            shuffled.sort { a, b in
                let rankA = a.difficulty == "basic" ? 0 : (a.difficulty == "medium" ? 1 : 2)
                let rankB = b.difficulty == "basic" ? 0 : (b.difficulty == "medium" ? 1 : 2)
                return rankA < rankB
            }
        } else if fire == .high {
            shuffled.sort { a, b in
                let rankA = a.difficulty == "hard" ? 0 : (a.difficulty == "medium" ? 1 : 2)
                let rankB = b.difficulty == "hard" ? 0 : (b.difficulty == "medium" ? 1 : 2)
                return rankA < rankB
            }
        }

        var wrongItems: [CurriculumQuestion] = []
        var normalItems: [CurriculumQuestion] = []
        for q in shuffled {
            if (progress.wrong[q.id] ?? 0) > 0 {
                wrongItems.append(q)
            } else {
                normalItems.append(q)
            }
        }
        var queue = wrongItems + normalItems
        while queue.count < fire.questionCount && !rawPool.isEmpty {
            queue.append(contentsOf: rawPool.shuffled())
        }
        queue = Array(queue.prefix(fire.questionCount))

        currentLevelNumber = stageId
        currentFire = fire
        specialMode = nil
        questionQueue = []
        curriculumQueue = queue
        questionIndex = 0
        rightCount = 0
        comboCount = 0
        isFeverMode = false
        phoenixShieldsRemaining = (equippedPet.kind == .phoenix) ? (equippedPetStage >= 4 ? 2 : 1) : 0
        retryLeft = fire.retryAllowance
        retriedCurrent = false
        masteredCount = 0
        newFoodsInRound = []
        newDessertsInRound = []
        newFlashcardsInRound = []
        rewardedFashionInRound = []
        roundCoinsEarned = 0
        floatingCoinGainText = nil
        rainbowChestBurstMessage = nil
        mysteryChests = []
        openedChestIndex = nil
        firePickerLevel = nil
        screenState = .playing
        setupCurrentQuestion()
    }

    public func startSpecialMode(_ type: SpecialModeType) {
        roundGeneration += 1
        progress.touchStreak()
        saveProgress()

        if currentSubject == .pinyin {
            var pool: [PinyinWord] = []
            if type == .wrong {
                for lv in LevelRepository.levels {
                    for w in lv.words where (progress.wrong[w.id] ?? 0) > 0 {
                        pool.append(w)
                    }
                }
            }
            if pool.isEmpty {
                let maxLv = progress.freeUnlockAll ? LevelRepository.levels.count : max(1, min(progress.unlocked, LevelRepository.levels.count))
                for i in 0..<maxLv {
                    pool.append(contentsOf: LevelRepository.levels[i].words)
                }
            }
            pool.shuffle()
            let picked = Array(pool.prefix(8))
            guard let first = picked.first else { return }

            currentLevelNumber = first.levelNumber
            currentMode = first.mode
            currentFire = .mid
            specialMode = type
            questionQueue = picked
            curriculumQueue = []
        } else {
            let prefix = currentSubject == .math ? "hjm_" : "hje_"
            let allSubjQuestions = HujiaoCurriculumRepository.allQuestions.filter { $0.id.hasPrefix(prefix) }
            let maxStage = currentSubject == .math
                ? (progress.freeUnlockAll ? HujiaoCurriculumRepository.mathStages.count : max(1, min(progress.mathUnlocked, HujiaoCurriculumRepository.mathStages.count)))
                : (progress.freeUnlockAll ? HujiaoCurriculumRepository.englishStages.count : max(1, min(progress.englishUnlocked, HujiaoCurriculumRepository.englishStages.count)))
            let unlockedPool: [CurriculumQuestion] = (1...maxStage).flatMap { stId in
                currentSubject == .math
                    ? HujiaoCurriculumRepository.questionsForMathStage(stId)
                    : HujiaoCurriculumRepository.questionsForEnglishStage(stId)
            }
            var pool: [CurriculumQuestion] = []
            if type == .wrong {
                pool = allSubjQuestions.filter { (progress.wrong[$0.id] ?? 0) > 0 }
            }
            if pool.isEmpty {
                pool = unlockedPool.isEmpty ? allSubjQuestions : unlockedPool
            }
            pool.shuffle()
            let picked = Array(pool.prefix(8))
            guard !picked.isEmpty else { return }

            currentLevelNumber = 1
            currentFire = .mid
            specialMode = type
            questionQueue = []
            curriculumQueue = picked
        }

        questionIndex = 0
        rightCount = 0
        comboCount = 0
        isFeverMode = false
        phoenixShieldsRemaining = (equippedPet.kind == .phoenix) ? (equippedPetStage >= 4 ? 2 : 1) : 0
        retryLeft = 2
        retriedCurrent = false
        masteredCount = 0
        newFoodsInRound = []
        newDessertsInRound = []
        newFlashcardsInRound = []
        rewardedFashionInRound = []
        roundCoinsEarned = 0
        floatingCoinGainText = nil
        rainbowChestBurstMessage = nil
        mysteryChests = []
        openedChestIndex = nil
        screenState = .playing
        setupCurrentQuestion()
    }

    public func goHome() {
        roundGeneration += 1
        audio.stopAllSpeech()
        isFeverMode = false
        screenState = .home
        mascotLine = Self.mascotTips.randomElement() ?? mascotLine
    }

    // MARK: - 题目初始化与流转

    public func setupCurrentQuestion() {
        isLocked = false
        retriedCurrent = false
        isBlindRevealed = false
        judgeState = "idle"
        tipMessage = ""
        tipStyle = "normal"
        praisePopup = nil
        dishPopup = nil
        jqxRuleBanner = nil
        potShaking = false
        potNope = false
        steamActive = false
        activeBlendingSlot = nil
        keyBuffer = ""
        numericInput = ""
        numericSmartOptions = []
        sentencePickedIndices = []
        sentenceDisplayOrder = []
        displayOptions = []
        pickedChoiceOption = nil
        showMathExplanation = false
        floatingCoinGainText = nil
        rainbowChestBurstMessage = nil

        // 切题间隙检查是否到达每日时长上限或睡前打烊
        checkPlayLockStatus(allowDuringQuestion: true)
        guard playLock == nil else { return }

        let gen = roundGeneration

        if currentSubject == .pinyin {
            guard let word = currentWord else {
                finishRound()
                return
            }
            currentLevelNumber = word.levelNumber
            currentMode = word.mode
            pickedInitial = nil
            pickedMedial = nil
            pickedBaseFinal = nil
            pickedTone = nil
            pickedTonedFinal = nil

            currentCustomer = AnimalCustomer.all[(questionIndex + word.levelNumber) % AnimalCustomer.all.count]
            customerMood = .waiting

            if word.mode == .whole {
                chefBubble = "整体认读整块下锅，再撒四声调料！"
            } else if comboCount >= 3 {
                chefBubble = "🔥 连击 \(comboCount) 连！火力全开！"
            } else {
                chefBubble = "先选蓝色声母，或直接把卡片拖进锅里！"
            }

            let ch = word.character
            let slow = progress.tts.slow
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 140_000_000)
                if self.roundGeneration == gen && self.currentWord == word && self.screenState == .playing && !self.eyeRestActive {
                    self.audio.speakText(ch, slow: slow)
                }
            }
        } else {
            guard let q = currentCurriculumQuestion else {
                finishRound()
                return
            }
            currentCustomer = AnimalCustomer.all[(questionIndex + currentLevelNumber) % AnimalCustomer.all.count]
            customerMood = .waiting

            if q.type == "choice" {
                displayOptions = q.options.shuffled()
            } else if q.type == "sentence" {
                var order = Array(0..<q.options.count).shuffled()
                let answerJoined = q.answer.trimmingCharacters(in: .whitespacesAndNewlines)
                if q.options.count > 1 && order.map({ q.options[$0] }).joined(separator: " ") == answerJoined {
                    order.swapAt(0, 1)
                }
                sentenceDisplayOrder = order
            }

            if currentSubject == .math {
                if q.type == "numeric" {
                    numericSmartOptions = Self.buildSmartNumericOptions(correctAnswer: q.answer)
                    chefBubble = comboCount >= 3 ? "🔥 连击 \(comboCount) 连！数学烘焙大师！" : "可以直接点甜点答案卡，也可以按数字盘输入哦！"
                } else {
                    chefBubble = "看清题目和教具演示，点选正确的甜点配方吧！"
                }
            } else {
                if q.type == "sentence" {
                    chefBubble = "按顺序点击鲜果单词块，放进料理杯拼出完整英文句子！"
                } else {
                    chefBubble = "先听题干要求，再点选项小喇叭听发音，选出正确的特调卡！"
                }
            }

            let slow = progress.tts.slow
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard self.roundGeneration == gen && self.currentCurriculumQuestion == q && self.screenState == .playing && !self.eyeRestActive else { return }
                self.speakCurrentCurriculumPrompt(slow: slow)
            }
        }
    }

    private static func buildSmartNumericOptions(correctAnswer: String) -> [String] {
        guard let ans = Int(correctAnswer) else {
            return [correctAnswer]
        }
        var set = Set<Int>([ans])
        let upper = max(120, ans + 30)
        let offsets = [-2, -1, 1, 2, 10, -10, 20, -20, 3, -3]
        for off in offsets.shuffled() {
            let cand = ans + off
            if cand >= 0 && cand <= upper {
                set.insert(cand)
            }
            if set.count >= 4 { break }
        }
        var fallback = max(0, ans + 1)
        while set.count < 4 {
            if !set.contains(fallback) {
                set.insert(fallback)
            }
            fallback += 1
        }
        return Array(set).sorted().map(String.init)
    }

    // MARK: - 沪教数学 & 牛津英语答题交互

    public func speakCurrentCurriculumPrompt(slow: Bool? = nil) {
        guard let q = currentCurriculumQuestion else { return }
        let useSlow = slow ?? progress.tts.slow
        if currentSubject == .english {
            // 若 englishAudio 就是答案本身，答题前只朗读中文题干（避免把答案直接报出来）；判题后可朗读英文答案
            if let eng = q.englishAudio, !eng.isEmpty, (!promptAudioRevealsAnswer || isCurrentQuestionJudged) {
                audio.speakEnglish(eng, slow: useSlow)
            } else {
                audio.speakText(Self.speakableText(q.prompt), slow: useSlow)
            }
        } else {
            audio.speakText(Self.speakableText(q.prompt), slow: useSlow)
        }
    }

    public func toggleMathExplanationTip() {
        guard currentCurriculumQuestion != nil else { return }
        audio.sfxTap()
        showMathExplanation.toggle()
        if showMathExplanation {
            audio.speakText(Self.speakableText(hintText), slow: progress.tts.slow)
        }
    }

    public func selectCurriculumChoice(_ option: String) {
        guard !isLocked, currentCurriculumQuestion != nil else { return }
        audio.sfxTap()
        pickedChoiceOption = option
        if currentSubject == .english {
            let hasLatin = option.range(of: "[A-Za-z]", options: .regularExpression) != nil
            if hasLatin {
                audio.speakEnglish(option, slow: progress.tts.slow)
            } else {
                audio.speakText(option, slow: progress.tts.slow)
            }
        } else {
            audio.speakText(option, slow: progress.tts.slow)
        }
        isLocked = true
        let gen = roundGeneration
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 240_000_000)
            guard self.roundGeneration == gen else { return }
            self.judgeCurriculumAnswer(submitted: option)
        }
    }

    public func appendNumericDigit(_ digit: String) {
        guard !isLocked, currentSubject == .math else { return }
        audio.sfxTap()
        if numericInput.count < 3 {
            if numericInput == "0" {
                numericInput = digit
            } else {
                numericInput += digit
            }
            audio.speakText(digit, slow: false)
        }
    }

    public func deleteNumericDigit() {
        guard !isLocked, currentSubject == .math else { return }
        audio.sfxTap()
        if !numericInput.isEmpty {
            numericInput.removeLast()
        }
    }

    public func submitNumericInput() {
        guard !isLocked, !numericInput.isEmpty else { return }
        audio.sfxSeasoning()
        isLocked = true
        let submitted = numericInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let gen = roundGeneration
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard self.roundGeneration == gen else { return }
            self.judgeCurriculumAnswer(submitted: submitted)
        }
    }

    /// 英语果粒句子积木：点击添加或移出单词块
    public func toggleSentenceBlock(at optionIndex: Int) {
        guard !isLocked, let q = currentCurriculumQuestion, q.type == "sentence" else { return }
        guard optionIndex >= 0 && optionIndex < q.options.count else { return }
        audio.sfxTap()
        let word = q.options[optionIndex]
        audio.speakEnglish(word, slow: progress.tts.slow)

        if let pos = sentencePickedIndices.firstIndex(of: optionIndex) {
            sentencePickedIndices.remove(at: pos)
            return
        }
        sentencePickedIndices.append(optionIndex)

        // 当所有果粒积木都放入料理杯后，自动摇匀判题
        if sentencePickedIndices.count == q.options.count {
            let builtSentence = sentencePickedIndices.map { q.options[$0] }.joined(separator: " ")
            isLocked = true
            let gen = roundGeneration
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 280_000_000)
                guard self.roundGeneration == gen else { return }
                self.judgeCurriculumAnswer(submitted: builtSentence)
            }
        }
    }

    public func clearSentenceBlocks() {
        guard !isLocked else { return }
        audio.sfxTap()
        sentencePickedIndices.removeAll()
    }

    private func judgeCurriculumAnswer(submitted: String) {
        guard let q = currentCurriculumQuestion else { return }
        let normSubmitted = submitted.trimmingCharacters(in: .whitespacesAndNewlines)
        let normAnswer = q.answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCorrect = (normSubmitted == normAnswer)

        if isCorrect {
            rightCount += 1
            comboCount += 1
            judgeState = "good"
            customerMood = .happy

            progress.ensureDaily()
            progress.daily.words += 1
            if comboCount > progress.daily.maxCombo {
                progress.daily.maxCombo = comboCount
            }
            if comboCount > progress.bestCombo {
                progress.bestCombo = comboCount
            }

            potShaking = true
            steamActive = true
            let praise = Self.praiseLines.randomElement() ?? "太棒了！"
            praisePopup = comboCount >= 3 ? "🔥 连击 \(comboCount) 连！\(praise)" : praise

            if comboCount >= 3 {
                audio.sfxBig()
            } else {
                audio.sfxWin()
            }

            if currentSubject == .math {
                let stg = currentMathStageDef
                let desserts = HujiaoCurriculumRepository.bakeryDesserts.filter { stg.dessertIds.contains($0.id) }
                let pickedDessert = desserts.isEmpty
                    ? HujiaoCurriculumRepository.bakeryDesserts[questionIndex % HujiaoCurriculumRepository.bakeryDesserts.count]
                    : desserts[questionIndex % desserts.count]
                dishPopup = "\(pickedDessert.emoji) \(pickedDessert.name)"
                chefBubble = "叮！香喷喷的「\(pickedDessert.name)」出炉啦！"
                tipMessage = "🧁 答对啦！\(q.explanation)"
                tipStyle = "ok"

                if progress.desserts[pickedDessert.id] == nil {
                    progress.desserts[pickedDessert.id] = 1
                    if !newDessertsInRound.contains(pickedDessert) {
                        newDessertsInRound.append(pickedDessert)
                    }
                }
                audio.speakText("答对啦！答案是 \(q.answer)", slow: false)
            } else {
                let stg = currentEnglishStageDef
                let stageCards = HujiaoCurriculumRepository.englishFlashcards.filter { stg.topicWords.contains($0.word) }
                let card = stageCards.isEmpty
                    ? HujiaoCurriculumRepository.englishFlashcards[questionIndex % HujiaoCurriculumRepository.englishFlashcards.count]
                    : stageCards[questionIndex % stageCards.count]
                dishPopup = "🍹 \(card.emoji) \(card.word)"
                chefBubble = "Awesome! 调制出「\(card.word) · \(card.chinese)」特调果饮！"
                tipMessage = "🧃 Great job! \(q.explanation)"
                tipStyle = "ok"

                if progress.englishCards[card.word] == nil {
                    progress.englishCards[card.word] = 1
                    if !newFlashcardsInRound.contains(card) {
                        newFlashcardsInRound.append(card)
                    }
                }
                if let eng = q.englishAudio, !eng.isEmpty {
                    audio.speakEnglish(eng, slow: progress.tts.slow)
                } else if q.answer.range(of: "[A-Za-z]", options: .regularExpression) != nil {
                    audio.speakEnglish(q.answer, slow: progress.tts.slow)
                } else {
                    audio.speakText("答对啦！\(Self.speakableText(q.answer))", slow: progress.tts.slow)
                }
            }

            // 错题本消消乐
            var masteredNow = false
            if (progress.wrong[q.id] ?? 0) > 0 {
                if retriedCurrent {
                    let left = (progress.wrong[q.id] ?? 1) - 1
                    if left <= 0 {
                        progress.wrongMastered[q.id] = 1
                        progress.wrong.removeValue(forKey: q.id)
                        masteredCount += 1
                        masteredNow = true
                    } else {
                        progress.wrong[q.id] = left
                    }
                } else {
                    progress.wrongMastered[q.id] = progress.wrong[q.id]
                    progress.wrong.removeValue(forKey: q.id)
                    masteredCount += 1
                    masteredNow = true
                }
            }
            grantQuestionCorrectReward(wasWrongMastered: masteredNow)
            saveProgress()

            let gen = roundGeneration
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 550_000_000)
                guard self.roundGeneration == gen else { return }
                self.potShaking = false
                try? await Task.sleep(nanoseconds: 1_550_000_000)
                while self.eyeRestActive {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                guard self.roundGeneration == gen && self.screenState == .playing else { return }
                self.questionIndex += 1
                self.setupCurrentQuestion()
            }
        } else {
            // 触发回锅重试机会
            if retryLeft > 0 && !retriedCurrent {
                retryLeft -= 1
                retriedCurrent = true
                var shieldMsg = ""
                if equippedPet.kind == .phoenix && phoenixShieldsRemaining > 0 && comboCount > 0 {
                    phoenixShieldsRemaining -= 1
                    shieldMsg = "（🔥 凤凰护连击盾生效，保留 \(comboCount) 连击！）"
                } else {
                    comboCount = 0
                }
                isFeverMode = (comboCount >= 5)
                rainbowCharge = max(0, rainbowCharge - 2)
                isLocked = false
                customerMood = .burnt
                pickedChoiceOption = nil
                numericInput = ""
                sentencePickedIndices.removeAll()
                showMathExplanation = true
                audio.sfxBad()

                chefBubble = "差一点点！看看「小锦囊」的方法提示，再试一次吧！\(shieldMsg)"
                tipMessage = "💡 \(hintText)（本局还能重做 \(retryLeft) 次）\(shieldMsg)"
                tipStyle = "note"
                return
            }

            var shieldMsg = ""
            if equippedPet.kind == .phoenix && phoenixShieldsRemaining > 0 && comboCount > 0 {
                phoenixShieldsRemaining -= 1
                shieldMsg = " · 🔥 凤凰守护保留连击！"
            } else {
                comboCount = 0
            }
            isFeverMode = (comboCount >= 5)
            // 单题只扣减 1 次彩虹能量，防止回锅再错双重 -4 惩罚
            if !retriedCurrent {
                rainbowCharge = max(0, rainbowCharge - 2)
            }
            judgeState = "bad"
            customerMood = .burnt
            potNope = true
            showMathExplanation = true
            audio.sfxBad()
            progress.wrong[q.id] = (progress.wrong[q.id] ?? 0) + 1
            saveProgress()

            chefBubble = "没关系，记住正确答案「\(q.answer)」哦！\(shieldMsg)"
            tipMessage = "正确答案是【\(q.answer)】· \(q.explanation)"
            tipStyle = "no"
            if currentSubject == .english, let eng = q.englishAudio, !eng.isEmpty {
                audio.speakEnglish(eng, slow: true)
            } else {
                audio.speakText("正确答案是 \(Self.speakableText(q.answer))。\(Self.speakableText(q.explanation))", slow: true)
            }

            let gen = roundGeneration
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                guard self.roundGeneration == gen else { return }
                self.potNope = false
                try? await Task.sleep(nanoseconds: 2_100_000_000)
                while self.eyeRestActive {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                guard self.roundGeneration == gen && self.screenState == .playing else { return }
                self.questionIndex += 1
                self.setupCurrentQuestion()
            }
        }
    }

    // MARK: - 语文拼音选卡交互

    /// 1. 选声母
    public func selectInitial(_ ini: String) {
        guard !isLocked, currentMode != .whole else { return }
        audio.sfxTap()
        keyBuffer = ""
        if pickedInitial == ini {
            pickedInitial = nil
        } else {
            pickedInitial = ini
            audio.speakInitial(ini, slow: progress.tts.slow)
            if currentMode == .tri && pickedMedial == nil {
                chefBubble = "声母 \(ini) 下锅啦！接着选紫色介音（i/u/ü）"
            } else if pickedBaseFinal == nil {
                chefBubble = "声母 \(ini) 下锅啦！接着选橙色韵母吧！"
            }
        }
        checkIfReadyToJudge()
    }

    /// 2. 选介音（三拼模式）
    public func selectMedial(_ med: String) {
        guard !isLocked, currentMode == .tri else { return }
        if pickedInitial == nil {
            tipMessage = "先选第一步「蓝色声母」下锅哦！"
            tipStyle = "note"
            chefBubble = "别急，先放蓝色声母！"
            audio.sfxTap()
            return
        }
        audio.sfxTap()
        if pickedMedial == med {
            pickedMedial = nil
        } else {
            pickedMedial = med
            audio.speakBaseFinal(med, slow: progress.tts.slow)
            chefBubble = "介音 \(med) 就位！快选橙色韵母吧！"
        }
        checkIfReadyToJudge()
    }

    /// 3. 选无调韵母母体（或整体认读母体）
    public func selectBaseFinal(_ base: String) {
        guard !isLocked else { return }
        if currentMode != .whole && pickedInitial == nil {
            tipMessage = "先选第一步「蓝色声母」下锅哦！"
            tipStyle = "note"
            chefBubble = "先放蓝色声母，再放韵母香料！"
            audio.sfxTap()
            return
        }
        if currentMode == .tri && pickedMedial == nil {
            tipMessage = "三拼音节要先选第二步「紫色介音」哦！"
            tipStyle = "note"
            chefBubble = "中间还要加一勺紫色介音高汤！"
            audio.sfxTap()
            return
        }
        audio.sfxTap()
        if pickedBaseFinal == base && pickedTone == nil {
            pickedBaseFinal = nil
            pickedTonedFinal = nil
        } else {
            pickedBaseFinal = base
            pickedTone = nil
            pickedTonedFinal = nil
            audio.speakBaseFinal(base, initial: pickedInitial, slow: progress.tts.slow)
            tipMessage = "🧂 请点击下方「四声调料瓶」（或按键盘 1~4）给 \(base) 加上声调！"
            tipStyle = "note"
            chefBubble = "最后一步：撒上第几声调料呢？"
        }
    }

    /// 4. 撒四声调料瓶 (1...4)
    public func selectTone(_ tone: Int) {
        guard !isLocked, (1...4).contains(tone) else { return }
        if currentMode != .whole && pickedInitial == nil {
            tipMessage = "先选蓝色声母和橙色韵母，最后撒四声调料哦！"
            tipStyle = "note"
            audio.sfxTap()
            return
        }
        guard let base = pickedBaseFinal else {
            tipMessage = "先在上方选一个橙色韵母，再撒四声调料瓶哦！"
            tipStyle = "note"
            chefBubble = "还没有选韵母呢，先点橙色韵母卡！"
            audio.sfxTap()
            return
        }
        audio.sfxSeasoning()
        pickedTone = tone
        let toned = PinyinHelper.applyTone(base: base, tone: tone)
        pickedTonedFinal = toned
        audio.speakTonedFinal(toned, initial: pickedInitial, slow: progress.tts.slow)
        checkIfReadyToJudge()
    }

    /// 兼容传统直接点带调韵母卡片
    public func selectDirectTonedFinal(_ toned: String) {
        guard !isLocked else { return }
        if currentMode != .whole && pickedInitial == nil {
            tipMessage = "先选第一步「蓝色声母」下锅哦！"
            tipStyle = "note"
            audio.sfxTap()
            return
        }
        if currentMode == .tri && pickedMedial == nil {
            tipMessage = "先选第二步「紫色介音」下锅哦！"
            tipStyle = "note"
            audio.sfxTap()
            return
        }
        audio.sfxTap()
        pickedBaseFinal = PinyinHelper.stripTone(toned)
        pickedTone = PinyinHelper.toneNumber(of: toned)
        pickedTonedFinal = toned
        audio.speakTonedFinal(toned, initial: pickedInitial, slow: progress.tts.slow)
        checkIfReadyToJudge()
    }

    /// 处理拖拽下锅 (Drag & Drop payload: "i:b", "m:u", "b:ao", "t:2", "f:áo")
    public func handleDropPayload(_ payload: String) -> Bool {
        let parts = payload.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return false }
        let kind = parts[0]
        let val = parts[1]
        switch kind {
        case "i":
            selectInitial(val)
            return true
        case "m":
            selectMedial(val)
            return true
        case "b":
            selectBaseFinal(val)
            return true
        case "t":
            if let t = Int(val) {
                selectTone(t)
                return true
            }
        case "f":
            selectDirectTonedFinal(val)
            return true
        default:
            break
        }
        return false
    }

    /// Mac 键盘快捷键直连处理（支持拼音、数学数字键盘、选择题 1~4）
    public func handleKeyInput(_ rawKey: String) {
        guard screenState == .playing,
              !isLocked,
              !eyeRestActive,
              playLock == nil,
              parentGate == nil,
              !showParentSettings,
              !showBackupModal else { return }
        let key = rawKey.lowercased()

        // 数学与英语键盘直连
        if currentSubject != .pinyin {
            guard let q = currentCurriculumQuestion else { return }
            if key == " " {
                speakCurrentCurriculumPrompt()
                return
            }
            if q.type == "numeric" && currentSubject == .math {
                if let digit = Int(key), (0...9).contains(digit) {
                    appendNumericDigit(String(digit))
                    return
                }
                if key == "\r" || key == "\n" || key == "return" || key == "enter" {
                    submitNumericInput()
                    return
                }
                if key == "\u{08}" || key == "\u{7f}" || key == "delete" || key == "backspace" {
                    deleteNumericDigit()
                    return
                }
            } else if q.type == "choice" {
                let opts = displayOptions.isEmpty ? q.options : displayOptions
                if let idx = Int(key), idx >= 1 && idx <= opts.count {
                    selectCurriculumChoice(opts[idx - 1])
                    return
                }
            } else if q.type == "sentence" {
                let order = sentenceDisplayOrder.isEmpty ? Array(0..<q.options.count) : sentenceDisplayOrder
                if let idx = Int(key), idx >= 1 && idx <= order.count {
                    toggleSentenceBlock(at: order[idx - 1])
                    return
                }
                if key == "\u{08}" || key == "\u{7f}" || key == "delete" || key == "backspace" {
                    clearSentenceBlocks()
                    return
                }
            }
            return
        }

        // 语文拼音键盘直连
        if key == " " {
            speakCurrentWordAndPhrase()
            return
        }

        if key == "\u{08}" || key == "\u{7f}" || key == "delete" || key == "backspace" {
            undoLastPick()
            return
        }

        if let tone = Int(key), (1...4).contains(tone) {
            selectTone(tone)
            return
        }

        guard key.count == 1, let ch = key.first, ch.isLetter else { return }
        let mappedChar = (key == "v") ? "ü" : key
        let now = Date()
        if now.timeIntervalSince(lastKeyTime) > 0.65 {
            keyBuffer = mappedChar
        } else {
            keyBuffer += mappedChar
        }
        lastKeyTime = now

        if currentMode != .whole {
            if let prev = pickedInitial, ["z", "c", "s"].contains(prev), mappedChar == "h" {
                let digraph = prev + "h"
                if availableInitials.contains(digraph) {
                    selectInitial(digraph)
                    return
                }
            }
            if pickedInitial == nil {
                if availableInitials.contains(keyBuffer) {
                    selectInitial(keyBuffer)
                    return
                } else if availableInitials.contains(mappedChar) {
                    selectInitial(mappedChar)
                    return
                }
            }
            if currentMode == .tri && pickedMedial == nil {
                if availableMedials.contains(mappedChar) {
                    keyBuffer = ""
                    selectMedial(mappedChar)
                    return
                }
            }
        }

        let bases = availableBaseFinals
        let altBuffer = keyBuffer.replacingOccurrences(of: "ü", with: "u")
        let altMapped = (mappedChar == "ü") ? "u" : mappedChar
        if bases.contains(keyBuffer) {
            selectBaseFinal(keyBuffer)
        } else if bases.contains(altBuffer) {
            selectBaseFinal(altBuffer)
        } else if bases.contains(mappedChar) {
            keyBuffer = mappedChar
            selectBaseFinal(mappedChar)
        } else if bases.contains(altMapped) {
            keyBuffer = altMapped
            selectBaseFinal(altMapped)
        }
    }

    public func undoLastPick() {
        guard !isLocked else { return }
        audio.sfxTap()
        if pickedTonedFinal != nil || pickedTone != nil {
            pickedTone = nil
            pickedTonedFinal = nil
            return
        }
        if pickedBaseFinal != nil {
            pickedBaseFinal = nil
            return
        }
        if pickedMedial != nil {
            pickedMedial = nil
            return
        }
        if pickedInitial != nil {
            pickedInitial = nil
        }
    }

    private func checkIfReadyToJudge() {
        let ready: Bool
        switch currentMode {
        case .whole:
            ready = (pickedTonedFinal != nil)
        case .split:
            ready = (pickedInitial != nil && pickedTonedFinal != nil)
        case .tri:
            ready = (pickedInitial != nil && pickedMedial != nil && pickedTonedFinal != nil)
        }
        if ready {
            isLocked = true
            let gen = roundGeneration
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 280_000_000)
                guard self.roundGeneration == gen else { return }
                self.judgeCurrentPick()
            }
        }
    }

    // MARK: - 语文拼音判题、声调专项纠错与连读演示

    private func judgeCurrentPick() {
        guard let word = currentWord, let tonedFinal = pickedTonedFinal else { return }
        let ch = word.character
        let hint = LevelRepository.hint(for: ch)

        let pickedSyllable = PinyinWord.computeSyllable(
            mode: currentMode,
            initial: pickedInitial,
            medial: pickedMedial,
            tonedFinal: tonedFinal
        )
        let exactMatch = (pickedInitial == word.initial)
            && (pickedMedial == word.medial)
            && (tonedFinal == word.tonedFinal)
        let allValidReadings = LevelRepository.readings(of: ch)
        let isCorrect = exactMatch || allValidReadings.contains(pickedSyllable)

        let isOnlyToneWrong = !isCorrect
            && (pickedInitial == word.initial)
            && (pickedMedial == word.medial)
            && (pickedBaseFinal == word.baseFinal)

        isBlindRevealed = true

        if isCorrect {
            rightCount += 1
            comboCount += 1
            judgeState = "good"
            customerMood = .happy

            progress.ensureDaily()
            progress.daily.words += 1
            if comboCount > progress.daily.maxCombo {
                progress.daily.maxCombo = comboCount
            }
            if comboCount > progress.bestCombo {
                progress.bestCombo = comboCount
            }

            potShaking = true
            steamActive = true
            dishPopup = "\(hint.emoji) \(pickedSyllable) \(ch)"
            let praise = Self.praiseLines.randomElement() ?? "太棒了！"
            praisePopup = comboCount >= 3 ? "🔥 连击 \(comboCount) 连！\(praise)" : praise
            chefBubble = comboCount >= 3 ? "太神啦！神厨小当家！" : "好香呀！\(hint.phrase)出锅喽！"

            if comboCount >= 3 {
                audio.sfxBig()
            } else {
                audio.sfxWin()
            }

            audio.speakBlending(word: word, phrase: hint.phrase, slow: progress.tts.slow) { [weak self] step in
                self?.activeBlendingSlot = step
            }

            if progress.food[ch] == nil {
                progress.food[ch] = 1
                newFoodsInRound.append(ch)
            }

            var masteredNow = false
            if (progress.wrong[word.id] ?? 0) > 0 {
                if retriedCurrent {
                    let left = (progress.wrong[word.id] ?? 1) - 1
                    if left <= 0 {
                        progress.wrongMastered[word.id] = 1
                        progress.wrong.removeValue(forKey: word.id)
                        masteredCount += 1
                        masteredNow = true
                    } else {
                        progress.wrong[word.id] = left
                    }
                } else {
                    progress.wrongMastered[word.id] = progress.wrong[word.id]
                    progress.wrong.removeValue(forKey: word.id)
                    masteredCount += 1
                    masteredNow = true
                }
            }

            var extraNote = ""
            if word.triggersJQXRule {
                jqxRuleBanner = "🕶️ 小熊摘墨镜：\(word.initial ?? "j/q/x") 遇到 ü 要去掉两点写成 u，但读音还是 ü 哦！"
                extraNote = "（j q x 遇到 ü 去两点写成 u）"
            }
            let otherReadings = allValidReadings.filter { $0 != word.fullSyllable }
            if !otherReadings.isEmpty {
                extraNote += "（「\(ch)」还读 \(otherReadings.joined(separator: "、"))）"
            }
            tipMessage = "🍲 咕嘟！变出「\(ch) · \(hint.phrase)」\(extraNote)"
            tipStyle = "ok"
            grantQuestionCorrectReward(wasWrongMastered: masteredNow)
            saveProgress()

            let gen = roundGeneration
            let extraDelayNs: UInt64
            if currentMode == .tri && progress.tts.slow {
                extraDelayNs = 2_650_000_000
            } else if progress.tts.slow {
                extraDelayNs = 2_050_000_000
            } else {
                extraDelayNs = 1_550_000_000
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 550_000_000)
                guard self.roundGeneration == gen else { return }
                self.potShaking = false
                try? await Task.sleep(nanoseconds: extraDelayNs)
                while self.eyeRestActive {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                guard self.roundGeneration == gen && self.screenState == .playing else { return }
                self.questionIndex += 1
                self.setupCurrentQuestion()
            }
        } else {
            if retryLeft > 0 && !retriedCurrent {
                retryLeft -= 1
                retriedCurrent = true
                var shieldMsg = ""
                if equippedPet.kind == .phoenix && phoenixShieldsRemaining > 0 && comboCount > 0 {
                    phoenixShieldsRemaining -= 1
                    shieldMsg = "（🔥 凤凰护连击盾生效，保留 \(comboCount) 连击！）"
                } else {
                    comboCount = 0
                }
                isFeverMode = (comboCount >= 5)
                rainbowCharge = max(0, rainbowCharge - 2)
                isLocked = false
                customerMood = .burnt
                audio.sfxBad()

                if isOnlyToneWrong {
                    let wrongT = pickedTone ?? 1
                    pickedTone = nil
                    pickedTonedFinal = nil
                    chefBubble = "食材对啦！只是调料放成了 \(wrongT) 声，换第 \(word.toneNumber) 声试试！\(shieldMsg)"
                    tipMessage = "🧂 声母韵母全对！只是声调选成第 \(wrongT) 声啦，请改点「第 \(word.toneNumber) 声」调料瓶（还剩 \(retryLeft) 次回锅）\(shieldMsg)"
                    tipStyle = "note"
                } else {
                    pickedInitial = nil
                    pickedMedial = nil
                    pickedBaseFinal = nil
                    pickedTone = nil
                    pickedTonedFinal = nil
                    chefBubble = "差一点点，回锅再试一次吧！\(shieldMsg)"
                    tipMessage = "🍳 再想想～本局还能回锅 \(retryLeft) 次\(shieldMsg)"
                    tipStyle = "note"
                }
                return
            }

            var shieldMsg = ""
            if equippedPet.kind == .phoenix && phoenixShieldsRemaining > 0 && comboCount > 0 {
                phoenixShieldsRemaining -= 1
                shieldMsg = " · 🔥 凤凰守护保留连击！"
            } else {
                comboCount = 0
            }
            isFeverMode = (comboCount >= 5)
            // 单题只扣减 1 次彩虹能量，防止回锅再错双重 -4 惩罚
            if !retriedCurrent {
                rainbowCharge = max(0, rainbowCharge - 2)
            }
            judgeState = "bad"
            customerMood = .burnt
            potNope = true
            audio.sfxBad()
            progress.wrong[word.id] = (progress.wrong[word.id] ?? 0) + 1
            saveProgress()

            if isOnlyToneWrong {
                chefBubble = "记住哦：「\(ch)」是第 \(word.toneNumber) 声（\(word.tonedFinal)）！\(shieldMsg)"
                tipMessage = "声调差一点点，正确是 \(word.fullSyllable)（第 \(word.toneNumber) 声 · \(ch) \(hint.phrase)）"
            } else {
                chefBubble = "没关系，记住绿色的正确食材卡片哦！\(shieldMsg)"
                tipMessage = "不对哦，正确是 \(word.fullSyllable)（\(ch) · \(hint.phrase)）"
            }
            tipStyle = "no"
            audio.speakText("\(ch)，\(hint.phrase)", slow: true)

            let gen = roundGeneration
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                guard self.roundGeneration == gen else { return }
                self.potNope = false
                try? await Task.sleep(nanoseconds: 1_950_000_000)
                while self.eyeRestActive {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                guard self.roundGeneration == gen && self.screenState == .playing else { return }
                self.questionIndex += 1
                self.setupCurrentQuestion()
            }
        }
    }

    // MARK: - 局末结算与公主华服变装掉落（三科共享奖励与星星体系）

    private func finishRound() {
        let total = totalQuestionCountInRound
        let ratio = total > 0 ? Double(rightCount) / Double(total) : 0
        let stars = ratio >= 0.85 ? 3 : (ratio >= 0.62 ? 2 : (ratio >= 0.50 ? 1 : 0))
        roundStars = stars

        progress.ensureDaily()
        if stars >= 1 {
            progress.daily.rounds += 1
        }

        if specialMode == nil {
            let lvKey = String(currentLevelNumber)
            switch currentSubject {
            case .pinyin:
                if stars > (progress.stars[lvKey] ?? 0) {
                    progress.stars[lvKey] = stars
                }
                if stars >= 1 && currentLevelNumber + 1 > progress.unlocked && currentLevelNumber < LevelRepository.levels.count {
                    progress.unlocked = currentLevelNumber + 1
                }
            case .math:
                if stars > (progress.mathStars[lvKey] ?? 0) {
                    progress.mathStars[lvKey] = stars
                }
                if stars >= 1 && currentLevelNumber + 1 > progress.mathUnlocked && currentLevelNumber < HujiaoCurriculumRepository.mathStages.count {
                    progress.mathUnlocked = currentLevelNumber + 1
                }
            case .english:
                if stars > (progress.englishStars[lvKey] ?? 0) {
                    progress.englishStars[lvKey] = stars
                }
                if stars >= 1 && currentLevelNumber + 1 > progress.englishUnlocked && currentLevelNumber < HujiaoCurriculumRepository.englishStages.count {
                    progress.englishUnlocked = currentLevelNumber + 1
                }
            }
        }

        progress.history.append(
            HistoryEntry(
                uid: UUID().uuidString,
                ts: Date().timeIntervalSince1970,
                d: GameProgress.todayString(),
                subj: currentSubject.rawValue,
                lv: currentLevelNumber,
                s: stars,
                r: rightCount,
                t: total,
                f: currentFire.rawValue
            )
        )
        progress.history.sort {
            let t0 = $0.ts ?? 0
            let t1 = $1.ts ?? 0
            if t0 != t1 { return t0 < t1 }
            return $0.d < $1.d
        }
        if progress.history.count > 60 {
            progress.history = Array(progress.history.suffix(60))
        }

        var gifts: [PrincessFashionItem] = []
        var upgrades: [FashionUpgradeEvent] = []
        if stars >= 1 {
            let clearKey = "\(currentSubject.rawValue)_\(currentLevelNumber)"
            let isFirstClear = (specialMode == nil && (progress.cleared[clearKey] ?? 0) == 0)
            if specialMode == nil {
                progress.cleared[clearKey] = 1
            }
            for _ in 0..<currentFire.fashionRolls {
                gifts.append(rollFashionReward(stars: stars, fire: currentFire))
            }
            if isFirstClear {
                gifts.append(rollFashionReward(stars: stars, fire: currentFire))
            }

            var stageBefore: [String: Int] = [:]
            var countBefore: [String: Int] = [:]
            for g in gifts where stageBefore[g.id] == nil {
                stageBefore[g.id] = progress.fashionStage(for: g.id)
                countBefore[g.id] = progress.fashionCount(for: g.id)
            }
            for g in gifts {
                progress.wardrobe[g.id] = (progress.wardrobe[g.id] ?? 0) + 1
                // 仅当掉落服饰严格高于当前已穿戴品阶且为首次解锁时自动换上，绝不覆盖更高阶穿搭
                let currentItem = progress.equippedItem(for: g.category)
                if g.tier > currentItem.tier && (countBefore[g.id] ?? 0) == 0 {
                    progress.equippedOutfit[g.category.rawValue] = g.id
                }
            }

            var checked = Set<String>()
            for g in gifts where !checked.contains(g.id) {
                checked.insert(g.id)
                let c0 = countBefore[g.id] ?? 0
                let b0 = max(1, stageBefore[g.id] ?? 1)
                let b1 = progress.fashionStage(for: g.id)
                if c0 == 0 {
                    upgrades.append(
                        FashionUpgradeEvent(
                            item: g,
                            isNewUnlock: true,
                            fromStage: 0,
                            toStage: 1,
                            totalCount: progress.fashionCount(for: g.id),
                            customTitle: "👗 通关解锁新装 · \(g.name)！"
                        )
                    )
                } else if b1 > b0 {
                    upgrades.append(
                        FashionUpgradeEvent(
                            item: g,
                            isNewUnlock: false,
                            fromStage: b0,
                            toStage: b1,
                            totalCount: progress.fashionCount(for: g.id),
                            customTitle: nil
                        )
                    )
                }
            }

            // 通关额外星币奖励 + 萌宠/游乐园结算增益 + 局末「三选一神秘宝箱」
            let mult = equippedPetStage >= 4 ? 2 : 1
            var clearBonus = isFirstClear ? 35 : (stars * 8)
            if equippedPet.kind == .corgiPilot {
                clearBonus += 15 * mult
            }
            if (progress.castleUnlocked["air_balloon"] ?? 0) > 0 {
                clearBonus += 8
            }
            if stars == 3 && (progress.castleUnlocked["fireworks"] ?? 0) > 0 {
                clearBonus += 20
                audio.sfxFirework()
            }
            progress.coins += clearBonus
            roundCoinsEarned += clearBonus

            let ticketTemplate = MysteryChestItem(id: 0, title: "皇家扭蛋券 ×1 + 15星币", subtitle: "可免费孵化 1 只五阶守护神兽", emoji: "🎟️", rewardType: "ticket", amount: 1, accentHex: "#E05385")
            let fashionTemplate = MysteryChestItem(id: 1, title: "高定华服变装盲盒", subtitle: "立刻获得 1 件公主礼服或皇冠首饰", emoji: "👗", rewardType: "fashion", amount: 1, accentHex: "#7A6EE6")
            let optionalPool: [MysteryChestItem] = [
                MysteryChestItem(id: 2, title: "58 枚星光币福袋", subtitle: "金光闪闪的裁缝星光币", emoji: "💰", rewardType: "coins", amount: 58, accentHex: "#F5A623"),
                MysteryChestItem(id: 3, title: "星光锦缎 ×1 + 15星币", subtitle: "直接为任意公主华服 +1 升阶经验", emoji: "🧵", rewardType: "thread", amount: 1, accentHex: "#9B6EF3"),
                MysteryChestItem(id: 4, title: "神兽糖果 ×1 + 15星币", subtitle: "可口高甜魔法糖果，直接 +3 成长值", emoji: "🌟", rewardType: "candy", amount: 1, accentHex: "#3A86FF"),
                MysteryChestItem(id: 5, title: "38 枚星光币礼盒", subtitle: "可升级高定礼服或投喂神兽", emoji: "🪙", rewardType: "coins", amount: 38, accentHex: "#3EA865")
            ].shuffled()

            let pickedTemplates: [MysteryChestItem]
            if stars == 3 && currentFire == .high {
                pickedTemplates = ([ticketTemplate, fashionTemplate] + Array(optionalPool.prefix(1))).shuffled()
            } else {
                pickedTemplates = Array(([ticketTemplate, fashionTemplate] + optionalPool).shuffled().prefix(3))
            }

            let canPeek = progress.totalGlamourScore >= 500 || progress.suitBonusInfo().isHalfResonance
            let peekIdx = canPeek ? Int.random(in: 0..<3) : -1
            mysteryChests = pickedTemplates.enumerated().map { idx, item in
                MysteryChestItem(
                    id: idx,
                    title: item.title,
                    subtitle: item.subtitle,
                    emoji: item.emoji,
                    rewardType: item.rewardType,
                    amount: item.amount,
                    accentHex: item.accentHex,
                    fashionItemId: item.fashionItemId,
                    isPeeked: idx == peekIdx
                )
            }
            openedChestIndex = nil
        } else {
            mysteryChests = []
            openedChestIndex = nil
        }

        rewardedFashionInRound = gifts
        refreshDailyDerivedState()
        saveProgress()
        screenState = .result

        if !gifts.isEmpty {
            let gen = roundGeneration
            let resetGen = stateResetGeneration
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                while self.eyeRestActive {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                guard self.roundGeneration == gen
                        && self.stateResetGeneration == resetGen
                        && self.screenState == .result
                        && self.playLock == nil else { return }
                self.audio.sfxSpark()
                if !upgrades.isEmpty {
                    try? await Task.sleep(nanoseconds: 650_000_000)
                    while self.eyeRestActive {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                    }
                    guard self.roundGeneration == gen
                            && self.stateResetGeneration == resetGen
                            && self.screenState == .result
                            && self.playLock == nil else { return }
                    self.pendingFashionUpgrades.append(contentsOf: upgrades)
                }
            }
        }
    }

    // MARK: - 语文拼音语音快捷辅助

    public func speakCurrentCharacter() {
        guard let w = currentWord else { return }
        audio.speakText(w.character, slow: progress.tts.slow)
    }

    public func speakCurrentWordAndPhrase() {
        guard let w = currentWord else { return }
        let h = LevelRepository.hint(for: w.character)
        audio.speakText("\(w.character)，\(h.phrase)", slow: progress.tts.slow)
    }

    public func speakCurrentBlendingDemo() {
        guard let w = currentWord else { return }
        let h = LevelRepository.hint(for: w.character)
        audio.speakBlending(word: w, phrase: h.phrase, slow: progress.tts.slow) { [weak self] step in
            self?.activeBlendingSlot = step
        }
    }

    // MARK: - 👁️ 儿童护眼卫士与健康时长管理

    /// 当前护眼暖光滤镜不透明度（支持夜间自动加强）
    public var effectiveWarmFilterOpacity: Double {
        guard progress.eyeCare.warmFilter else { return 0.0 }
        let base: Double
        switch progress.eyeCare.warmStrength {
        case 1:  base = 0.06
        case 3:  base = 0.16
        default: base = 0.11
        }
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight = (hour >= 19 || hour < 7)
        let nightBoost = (progress.eyeCare.autoNightWarm && isNight) ? 0.04 : 0.0
        return min(0.22, base + nightBoost)
    }

    /// 距离下次 20-20-20 护眼休息还剩多少分钟
    public var minutesUntilNextEyeRest: Int {
        let targetSec = max(5, progress.eyeCare.restIntervalMin) * 60
        let remainSec = max(0, targetSec - continuousPlaySeconds)
        return max(1, Int(ceil(Double(remainSec) / 60.0)))
    }

    /// 今日已玩分钟数（向上取整方便展示）
    public var todayPlayedMinutes: Int {
        Int(ceil(Double(progress.todayPlaySeconds) / 60.0))
    }

    /// 每秒心跳：统计用眼时长、触发 20-20-20 望远护眼操、检查每日上限与睡前打烊
    public func tickEyeCareSecond() {
        let today = GameProgress.todayString()
        if progress.daily.d != today {
            progress.ensureDaily()
            refreshDailyDerivedState()
        }

        // 如果正在护眼休息倒计时
        if eyeRestActive {
            if restRemaining > 0 {
                restRemaining -= 1
            }
            if restRemaining <= 0 {
                completeEyeRest()
            }
            return
        }

        // 检查睡前打烊与每日上限（若正在答题中，仅在剩 3 分钟时温和提醒，等切题或主页再锁屏）
        checkPlayLockStatus(allowDuringQuestion: screenState != .playing)
        guard playLock == nil else { return }

        progress.playSeconds[today] = (progress.playSeconds[today] ?? 0) + 1
        unsavedPlaySeconds += 1
        continuousPlaySeconds += 1

        if unsavedPlaySeconds >= 15 {
            unsavedPlaySeconds = 0
            progress.trimPlayTimeHistory()
            saveProgress()
        }

        // 距离每日上限还剩 3 分钟时温馨提醒
        if progress.eyeCare.dailyLimitEnabled {
            let limitSec = progress.todayAllowedMinutes * 60
            let usedSec = progress.playSeconds[today] ?? 0
            let leftSec = limitSec - usedSec
            if leftSec > 0 && leftSec <= 180 && warnedDate != today {
                warnedDate = today
                timeWarning = "⏰ 今日护眼约定时间还剩最后 3 分钟，打完这一关就让眼睛休息吧！"
            } else if leftSec > 180 {
                timeWarning = nil
            }
        } else {
            timeWarning = nil
        }

        // 20-20-20 护眼休息提醒（每玩 N 分钟触发一次望远护眼操）
        if progress.eyeCare.restReminder {
            let intervalSec = max(5, progress.eyeCare.restIntervalMin) * 60
            if continuousPlaySeconds >= intervalSec {
                startEyeRestBreak()
            }
        }
    }

    public func startEyeRestBreak() {
        continuousPlaySeconds = 0
        restRemaining = max(15, progress.eyeCare.restSeconds)
        eyeRestActive = true
        audio.stopAllSpeech()
        audio.sfxSpark()
        audio.speakText("小熊护眼时间到啦！请抬头看看六米外的远处，眨眨眼睛休息一下吧！", slow: false)
    }

    public func completeEyeRest() {
        eyeRestActive = false
        restRemaining = 0
        continuousPlaySeconds = 0
        audio.sfxWin()
        audio.speakText("眼睛休息好啦，继续保持一臂距离哦！", slow: false)
    }

    public func checkPlayLockStatus(allowDuringQuestion: Bool) {
        let now = Date()
        if let overrideUntil = bedtimeOverrideUntil, now < overrideUntil {
            playLock = nil
            return
        }

        // 1. 检查睡前打烊时间
        if progress.eyeCare.bedtimeEnabled {
            let hour = Calendar.current.component(.hour, from: now)
            let bed = progress.eyeCare.bedtimeHour
            let wake = progress.eyeCare.wakeHour
            let isInBedtime: Bool = (bed > wake) ? (hour >= bed || hour < wake) : (hour >= bed && hour < wake)
            if isInBedtime && allowDuringQuestion {
                audio.stopAllSpeech()
                playLock = .bedtime
                return
            }
        }

        // 2. 检查每日时长上限
        if progress.eyeCare.dailyLimitEnabled {
            let limitSec = progress.todayAllowedMinutes * 60
            if progress.todayPlaySeconds >= limitSec && allowDuringQuestion {
                audio.stopAllSpeech()
                playLock = .dailyLimit
                return
            }
        }

        playLock = nil
    }

    public func requestParentGate(_ purpose: ParentGatePurpose) {
        audio.sfxTap()
        parentGate = purpose
    }

    public func handleParentGatePassed(_ purpose: ParentGatePurpose) {
        parentGate = nil
        switch purpose {
        case .settings:
            showParentSettings = true
        case .skipRest:
            completeEyeRest()
        case .extendTime:
            grantBonusPlayTime(minutes: 15)
        }
    }

    public func grantBonusPlayTime(minutes: Int) {
        let today = GameProgress.todayString()
        progress.bonusMinutes[today] = (progress.bonusMinutes[today] ?? 0) + minutes
        bedtimeOverrideUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        playLock = nil
        timeWarning = nil
        continuousPlaySeconds = 0
        saveProgress()
        audio.sfxWin()
    }
}
