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

public struct ButterflyUpgradeEvent: Identifiable, Sendable {
    public let id = UUID()
    public let species: ButterflySpecies
    public let fromStage: Int
    public let toStage: Int
    public let count: Int
    public let customTitle: String?
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
    @Published public var rainbowChestBurstMessage: String? = nil
    @Published public var mysteryChests: [MysteryChestItem] = []
    @Published public var openedChestIndex: Int? = nil
    @Published public var isSpinningGacha: Bool = false
    @Published public var activeGachaHatch: GachaHatchEvent? = nil
    @Published public var petFeedToast: String? = nil
    @Published public var petHeartBurst: Bool = false

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
        saveProgress()
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

    private static func loadProgress(key: String) -> GameProgress {
        let decoder = JSONDecoder()
        var merged = GameProgress()
        var foundAny = false

        // 依次读取 ApplicationSupport、Documents、UserDefaults 并合并，确保 iPad / Mac 任意路径存档都不丢失
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

    /// 生成可供 iPad「文件(Files)」/ AirDrop / 微信 分享导出的 .json 备份文件 URL
    public func exportBackupFileURL() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(progress) else { return nil }
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("满满的奇妙料理城_存档备份.json")
        try? data.write(to: fileURL, options: .atomic)
        return fileURL
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
            saveProgress()
            audio.sfxWin()
            return count > 0 ? "✅ 成功合并恢复 \(count) 项学习记录、星币与奖励！" : "ℹ️ 这份存档里的进度已全部包含在当前记录中"
        } catch {
            audio.sfxBad()
            return "❌ 导入失败：存档格式不正确（请确认复制了完整的 JSON 内容）"
        }
    }

    public func resetAllProgress() {
        // 护眼设置与今日游戏时长属于家长管控，清空学习记录时保留
        let keepEye = progress.eyeCare
        let keepPlay = progress.playSeconds
        let keepBonus = progress.bonusMinutes
        progress = GameProgress()
        progress.eyeCare = keepEye
        progress.playSeconds = keepPlay
        progress.bonusMinutes = keepBonus
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

    public func claimDailyQuest(_ questId: String) {
        progress.ensureDaily()
        guard (progress.daily.claimed[questId] ?? 0) == 0 else { return }
        progress.daily.claimed[questId] = 1
        progress.coins += 35
        if questId == "q_words" {
            progress.gachaTickets += 1
        }
        let item = rollFashionReward(stars: 3, fire: .high)
        let wasOwned = progress.fashionCount(for: item.id) > 0
        let beforeStage = max(1, progress.fashionStage(for: item.id))
        progress.wardrobe[item.id] = (progress.wardrobe[item.id] ?? 0) + 1
        if !wasOwned {
            progress.equippedOutfit[item.category.rawValue] = item.id
        }
        let afterStage = max(1, progress.fashionStage(for: item.id))
        let newCount = progress.fashionCount(for: item.id)
        saveProgress()
        audio.sfxChestOpen()
        pendingFashionUpgrades.append(
            FashionUpgradeEvent(
                item: item,
                isNewUnlock: !wasOwned,
                fromStage: beforeStage,
                toStage: afterStage,
                totalCount: newCount,
                customTitle: questId == "q_words"
                    ? "🎁 每日目标达成！+35星币 · +1扭蛋券 · 获赠【\(item.name)】！"
                    : "🎁 每日目标达成！+35星币 · 获赠【\(item.name)】！"
            )
        )
    }

    // MARK: - 🎰 皇家扭蛋机孵化（5阶神兽进化）、👗 满满公主高定变装 & 🏰 游乐园建造

    /// 旋转皇家扭蛋机（需 1 张皇家扭蛋券 或 120 料理星币，重复抽中自动转化为 +2 神兽成长值）
    public func spinGacha(useTicket: Bool) {
        guard !isSpinningGacha && activeGachaHatch == nil else { return }
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

        // 真实 RPG 稀有度权重：16% 神话(3星)、36% 传说(2星)、48% 史诗(1星)
        let roll = Double.random(in: 0..<1)
        let targetRarity = roll < 0.16 ? 3 : (roll < 0.52 ? 2 : 1)
        let rarityPool = GuardianPetSpecies.all.filter { $0.rarity == targetRarity }
        let unownedInTier = rarityPool.filter { (progress.pets[$0.id] ?? 0) == 0 }

        let pickedPet: GuardianPetSpecies
        if !unownedInTier.isEmpty && Double.random(in: 0..<1) < 0.45 {
            pickedPet = unownedInTier.randomElement() ?? rarityPool[0]
        } else {
            pickedPet = rarityPool.randomElement() ?? GuardianPetSpecies.all[0]
        }

        let wasOwned = (progress.pets[pickedPet.id] ?? 0) > 0
        let beforeStage = max(1, progress.petStage(for: pickedPet.id))
        // 若抽到已拥有的守护萌宠，直接获得 +2 点高额神兽成长值，加速冲击 5 阶至尊幻兽！
        progress.pets[pickedPet.id] = (progress.pets[pickedPet.id] ?? 0) + (wasOwned ? 2 : 1)
        if progress.equippedPetId.isEmpty {
            progress.equippedPetId = pickedPet.id
        }
        let afterStage = max(1, progress.petStage(for: pickedPet.id))
        let totalExp = progress.petTotalExp(for: pickedPet.id)
        saveProgress()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 680_000_000)
            self.isSpinningGacha = false
            self.audio.sfxChestOpen()
            self.activeGachaHatch = GachaHatchEvent(
                pet: pickedPet,
                isNew: !wasOwned,
                fromStage: beforeStage,
                toStage: afterStage,
                totalExp: totalExp
            )
            self.audio.speakText("\(pickedPet.name)！\(pickedPet.cheerLine)", slow: false)
        }
    }

    /// 投喂守护萌宠美食（投喂星币随阶位 1~5 阶递增：35 -> 50 -> 70 -> 95 星币，越往后越难、进化越炫酷）
    public func feedPet(_ petId: String) {
        let pet = GuardianPetSpecies.byId(petId)
        guard (progress.pets[petId] ?? 0) > 0 else {
            audio.sfxBad()
            petFeedToast = "🥚 这只小精灵还没孵化呢，快去摇左侧的皇家扭蛋机吧！"
            return
        }
        let beforeStage = progress.petStage(for: petId)
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
        saveProgress()

        petHeartBurst = true
        audio.sfxPetHappy()

        if afterStage > beforeStage {
            petFeedToast = "👑 华丽蜕变！「\(pet.name)」突破至 \(afterStage) 阶【\(GuardianPetSpecies.stageName(for: afterStage))】！解锁：\(GuardianPetSpecies.stageVisualPerk(for: afterStage))！"
            activeGachaHatch = GachaHatchEvent(
                pet: pet,
                isNew: false,
                fromStage: beforeStage,
                toStage: afterStage,
                totalExp: totalExp
            )
            audio.speakText("太酷啦！\(pet.name)进化成\(GuardianPetSpecies.stageName(for: afterStage))啦！", slow: false)
        } else {
            let nextNeed = progress.nextPetStageNeed(for: petId) ?? totalExp
            petFeedToast = "🍓 投喂【\(pet.favoriteFood)】成功！「\(pet.name)」成长值 \(totalExp)/\(nextNeed) 💖"
            audio.speakText(pet.cheerLine, slow: false)
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            self.petHeartBurst = false
        }
    }

    public func equipPet(_ petId: String) {
        guard (progress.pets[petId] ?? 0) > 0 else { return }
        progress.equippedPetId = petId
        saveProgress()
        audio.sfxPetHappy()
        let pet = GuardianPetSpecies.byId(petId)
        petFeedToast = "✨ 已将「\(pet.name)」设为伴读守护精灵，它会和满满公主一起闯关答题哦！"
        audio.speakText("我是\(pet.name)，陪满满公主一起闯关！", slow: false)
    }

    // MARK: - 👗 满满公主换装穿戴、星币解锁与 5 阶高定织造升阶

    public func equipFashionItem(_ item: PrincessFashionItem) {
        guard progress.fashionCount(for: item.id) > 0 else {
            unlockOrUpgradeFashionItem(item)
            return
        }
        progress.equippedOutfit[item.category.rawValue] = item.id
        saveProgress()
        audio.sfxSpark()
        let st = progress.fashionStage(for: item.id)
        wardrobeToast = "👗 满满已换上 \(st) 阶【\(item.name)】，华丽值高达 \(progress.totalGlamourScore) 分！"
        audio.speakText("换上\(item.name)，真漂亮！", slow: false)
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

    public func unlockCastleAttraction(_ item: CastleAttraction) {
        if (progress.castleUnlocked[item.id] ?? 0) > 0 {
            audio.sfxFirework()
            audio.speakText(item.cheerSpeech, slow: false)
            petFeedToast = "🎡 \(item.name)：\(item.cheerSpeech)"
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
        petFeedToast = "🎉 成功建造「\(item.name)」！快看上方游乐园画布，它已经动起来啦！"
    }

    /// 局内每答对 1 题发放星币与彩虹能量槽充能（紧凑递进经济：需集满 8 格能量才爆彩虹宝箱，答错回锅扣减能量）
    public func grantQuestionCorrectReward(wasWrongMastered: Bool) {
        let baseCoin: Int
        switch currentFire {
        case .low:  baseCoin = 5
        case .mid:  baseCoin = 7
        case .high: baseCoin = 10
        }
        let petStageBonus = equippedPetStage + (equippedPet.id == "fire_dragon" ? 2 : 0)
        let comboBonus = min(comboCount, 5) * 2
        let masterBonus = wasWrongMastered ? 10 : 0
        let gain = baseCoin + comboBonus + petStageBonus + masterBonus

        progress.coins += gain
        roundCoinsEarned += gain
        rainbowCharge += 1

        if rainbowCharge >= 8 {
            rainbowCharge = 0
            let chestCoins = 35
            progress.coins += chestCoins
            roundCoinsEarned += chestCoins
            if currentFire == .high || comboCount >= 6 {
                progress.gachaTickets += 1
                floatingCoinGainText = "🌈 彩虹宝箱 +35🪙 +1🎟️"
                rainbowChestBurstMessage = "🌈 连续集满 8 格彩虹能量！爆出 +35 🪙 星币 & 1 张皇家扭蛋券 🎟️！"
            } else {
                floatingCoinGainText = "🌈 彩虹宝箱 +35🪙"
                rainbowChestBurstMessage = "🌈 集满 8 格彩虹能量！惊喜爆出 +35 🪙 料理星币！（挑战大火或 6 连击还能掉扭蛋券哦）"
            }
            audio.sfxChestOpen()
        } else {
            floatingCoinGainText = "+\(gain) 🪙"
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
        case "fashion":
            let item = chosen.fashionItemId.map { PrincessFashionItem.byId($0) } ?? rollFashionReward(stars: 3, fire: .high)
            let wasOwned = progress.fashionCount(for: item.id) > 0
            let beforeStage = max(1, progress.fashionStage(for: item.id))
            progress.wardrobe[item.id] = (progress.wardrobe[item.id] ?? 0) + 1
            if !wasOwned {
                progress.equippedOutfit[item.category.rawValue] = item.id
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
        saveProgress()
        audio.sfxChestOpen()
        audio.speakText("太棒啦！打开神秘宝箱获得\(chosen.title)！", slow: false)
    }

    /// 根据本局星级与火候难度抽取满满公主变装服饰（高星级 + 大火更容易掉落高级华丽/皇家神话服饰）
    public func rollFashionReward(stars: Int, fire: FireDifficulty) -> PrincessFashionItem {
        let x = Double.random(in: 0..<1)
        let maxAllowedTier: Int
        if stars >= 3 && fire == .high {
            maxAllowedTier = x < 0.22 ? 4 : (x < 0.58 ? 3 : 2)
        } else if stars >= 3 {
            maxAllowedTier = x < 0.10 ? 4 : (x < 0.42 ? 3 : (x < 0.78 ? 2 : 1))
        } else if stars == 2 {
            maxAllowedTier = x < 0.25 ? 3 : (x < 0.65 ? 2 : 1)
        } else {
            maxAllowedTier = x < 0.35 ? 2 : 1
        }
        let tierPool = PrincessFashionItem.all.filter { $0.tier == maxAllowedTier }
        let unowned = tierPool.filter { progress.fashionCount(for: $0.id) == 0 && progress.totalStars >= max(0, $0.needStars - 10) }
        if !unowned.isEmpty && Double.random(in: 0..<1) < 0.45 {
            return unowned.randomElement() ?? tierPool[0]
        }
        return tierPool.randomElement() ?? PrincessFashionItem.all[0]
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
        retryLeft = fire.retryAllowance
        retriedCurrent = false
        masteredCount = 0
        newFoodsInRound = []
        newDessertsInRound = []
        newFlashcardsInRound = []
        rewardedFashionInRound = []
        rainbowCharge = 0
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
        retryLeft = fire.retryAllowance
        retriedCurrent = false
        masteredCount = 0
        newFoodsInRound = []
        newDessertsInRound = []
        newFlashcardsInRound = []
        rewardedFashionInRound = []
        rainbowCharge = 0
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
            var pool: [CurriculumQuestion] = []
            if type == .wrong {
                pool = allSubjQuestions.filter { (progress.wrong[$0.id] ?? 0) > 0 }
            }
            if pool.isEmpty {
                pool = allSubjQuestions
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
        retryLeft = 2
        retriedCurrent = false
        masteredCount = 0
        newFoodsInRound = []
        newDessertsInRound = []
        newFlashcardsInRound = []
        rewardedFashionInRound = []
        rainbowCharge = 0
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
        let offsets = [-2, -1, 1, 2, 10, -10, 3, -3]
        for off in offsets.shuffled() {
            let cand = ans + off
            if cand >= 0 && cand <= 120 {
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
                } else {
                    audio.speakEnglish(q.answer, slow: progress.tts.slow)
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
                comboCount = 0
                rainbowCharge = max(0, rainbowCharge - 2)
                isLocked = false
                customerMood = .burnt
                pickedChoiceOption = nil
                numericInput = ""
                sentencePickedIndices.removeAll()
                showMathExplanation = true
                audio.sfxBad()

                chefBubble = "差一点点！看看「小锦囊」的方法提示，再试一次吧！"
                tipMessage = "💡 \(hintText)（本局还能重做 \(retryLeft) 次）"
                tipStyle = "note"
                return
            }

            comboCount = 0
            rainbowCharge = max(0, rainbowCharge - 2)
            judgeState = "bad"
            customerMood = .burnt
            potNope = true
            showMathExplanation = true
            audio.sfxBad()
            progress.wrong[q.id] = (progress.wrong[q.id] ?? 0) + 1
            saveProgress()

            chefBubble = "没关系，记住正确答案「\(q.answer)」哦！"
            tipMessage = "正确答案是【\(q.answer)】· \(q.explanation)"
            tipStyle = "no"
            if currentSubject == .english, let eng = q.englishAudio {
                audio.speakEnglish(eng, slow: true)
            } else {
                audio.speakText("正确答案是 \(q.answer)。\(q.explanation)", slow: true)
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
        guard screenState == .playing, !isLocked, !eyeRestActive, playLock == nil, parentGate == nil, !showParentSettings else { return }
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
            if pickedInitial == nil || (["z","c","s"].contains(pickedInitial ?? "") && mappedChar == "h") {
                if availableInitials.contains(keyBuffer) {
                    selectInitial(keyBuffer)
                    return
                } else if availableInitials.contains(mappedChar) {
                    keyBuffer = mappedChar
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
        if bases.contains(keyBuffer) {
            selectBaseFinal(keyBuffer)
        } else if bases.contains(mappedChar) {
            keyBuffer = mappedChar
            selectBaseFinal(mappedChar)
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
            if retryLeft > 0 && !retriedCurrent {
                retryLeft -= 1
                retriedCurrent = true
                comboCount = 0
                rainbowCharge = max(0, rainbowCharge - 2)
                isLocked = false
                customerMood = .burnt
                audio.sfxBad()

                if isOnlyToneWrong {
                    let wrongT = pickedTone ?? 1
                    pickedTone = nil
                    pickedTonedFinal = nil
                    chefBubble = "食材对啦！只是调料放成了 \(wrongT) 声，换第 \(word.toneNumber) 声试试！"
                    tipMessage = "🧂 声母韵母全对！只是声调选成第 \(wrongT) 声啦，请改点「第 \(word.toneNumber) 声」调料瓶（还剩 \(retryLeft) 次回锅）"
                    tipStyle = "note"
                } else {
                    pickedInitial = nil
                    pickedMedial = nil
                    pickedBaseFinal = nil
                    pickedTone = nil
                    pickedTonedFinal = nil
                    chefBubble = "差一点点，回锅再试一次吧！"
                    tipMessage = "🍳 再想想～本局还能回锅 \(retryLeft) 次"
                    tipStyle = "note"
                }
                return
            }

            comboCount = 0
            rainbowCharge = max(0, rainbowCharge - 2)
            judgeState = "bad"
            customerMood = .burnt
            potNope = true
            audio.sfxBad()
            progress.wrong[word.id] = (progress.wrong[word.id] ?? 0) + 1
            saveProgress()

            if isOnlyToneWrong {
                chefBubble = "记住哦：「\(ch)」是第 \(word.toneNumber) 声（\(word.tonedFinal)）！"
                tipMessage = "声调差一点点，正确是 \(word.fullSyllable)（第 \(word.toneNumber) 声 · \(ch) \(hint.phrase)）"
            } else {
                chefBubble = "没关系，记住绿色的正确食材卡片哦！"
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
        if rightCount >= 4 {
            progress.daily.rounds += 1
        }

        if specialMode == nil {
            let lvKey = String(currentLevelNumber)
            switch currentSubject {
            case .pinyin:
                if stars > (progress.stars[lvKey] ?? 0) {
                    progress.stars[lvKey] = stars
                }
                if rightCount >= 4 && currentLevelNumber + 1 > progress.unlocked && currentLevelNumber < LevelRepository.levels.count {
                    progress.unlocked = currentLevelNumber + 1
                }
            case .math:
                if stars > (progress.mathStars[lvKey] ?? 0) {
                    progress.mathStars[lvKey] = stars
                }
                if rightCount >= 4 && currentLevelNumber + 1 > progress.mathUnlocked && currentLevelNumber < HujiaoCurriculumRepository.mathStages.count {
                    progress.mathUnlocked = currentLevelNumber + 1
                }
            case .english:
                if stars > (progress.englishStars[lvKey] ?? 0) {
                    progress.englishStars[lvKey] = stars
                }
                if rightCount >= 4 && currentLevelNumber + 1 > progress.englishUnlocked && currentLevelNumber < HujiaoCurriculumRepository.englishStages.count {
                    progress.englishUnlocked = currentLevelNumber + 1
                }
            }
        }

        progress.history.append(
            HistoryEntry(
                d: GameProgress.todayString(),
                subj: currentSubject.rawValue,
                lv: currentLevelNumber,
                s: stars,
                r: rightCount,
                t: total,
                f: currentFire.rawValue
            )
        )
        if progress.history.count > 60 {
            progress.history = Array(progress.history.suffix(60))
        }

        var gifts: [PrincessFashionItem] = []
        var upgrades: [FashionUpgradeEvent] = []
        if rightCount >= 4 {
            let clearKey = "\(currentSubject.rawValue)_\(currentLevelNumber)"
            let isFirstClear = (specialMode == nil && (progress.cleared[clearKey] ?? 0) == 0)
            if specialMode == nil {
                progress.cleared[clearKey] = 1
            }
            for _ in 0..<currentFire.butterflyRolls {
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
                // 若当前槽位装备的是更低稀有度且新获得了更高阶或新部位，可自动为公主换上新衣
                let catKey = g.category.rawValue
                if let currentId = progress.equippedOutfit[catKey],
                   let currentItem = PrincessFashionItem.item(for: currentId),
                   g.rarity > currentItem.rarity && (countBefore[g.id] ?? 0) == 0 {
                    progress.equippedOutfit[catKey] = g.id
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

            // 通关额外星币奖励（精细化难度梯度）+ 生成局末「三选一神秘宝箱」
            let clearBonus = isFirstClear ? 35 : (stars * 8)
            progress.coins += clearBonus
            roundCoinsEarned += clearBonus

            let chestPool: [MysteryChestItem] = [
                MysteryChestItem(id: 0, title: "58 枚星光币福袋", subtitle: "金光闪闪的裁缝星光币", emoji: "💰", rewardType: "coins", amount: 58, accentHex: "#F5A623"),
                MysteryChestItem(id: 1, title: "皇家扭蛋券 ×1 + 15星币", subtitle: "可免费孵化 1 只五阶守护神兽", emoji: "🎟️", rewardType: "ticket", amount: 1, accentHex: "#E05385"),
                MysteryChestItem(id: 2, title: "高定华服变装盲盒", subtitle: "立刻获得 1 件公主礼服或皇冠首饰", emoji: "👗", rewardType: "fashion", amount: 1, accentHex: "#7A6EE6"),
                MysteryChestItem(id: 3, title: "38 枚星光币礼盒", subtitle: "可升级高定礼服或投喂神兽", emoji: "🪙", rewardType: "coins", amount: 38, accentHex: "#3EA865")
            ].shuffled()
            mysteryChests = Array(chestPool.prefix(3)).enumerated().map { idx, item in
                MysteryChestItem(
                    id: idx,
                    title: item.title,
                    subtitle: item.subtitle,
                    emoji: item.emoji,
                    rewardType: item.rewardType,
                    amount: item.amount,
                    accentHex: item.accentHex
                )
            }
            openedChestIndex = nil
        } else {
            mysteryChests = []
            openedChestIndex = nil
        }

        rewardedFashionInRound = gifts
        saveProgress()
        screenState = .result

        if !gifts.isEmpty {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                self.audio.sfxSpark()
                if !upgrades.isEmpty {
                    try? await Task.sleep(nanoseconds: 650_000_000)
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

        let today = GameProgress.todayString()
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
