import Foundation
import SwiftUI

public enum AppScreenState: Sendable {
    case home
    case playing
    case result
}

public enum HomeTab: String, CaseIterable, Sendable {
    case map     = "Map"
    case recipe  = "Coll"
    case garden  = "Bf"
    case records = "Rec"
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
    @Published public var pendingUpgrades: [ButterflyUpgradeEvent] = []
    @Published public var mascotLine: String = "小熊团团：欢迎来到《满满的奇妙料理城》，沪教版语数英边玩边学！"
    @Published public var importExportMessage: String? = nil

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
    @Published public var rewardedButterfliesInRound: [ButterflySpecies] = []
    @Published public var roundStars: Int = 0

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
        "小熊团团：拼音屋撒四声调料瓶，数学坊玩十格阵和数墙，英语吧拼鲜果句子积木！",
        "小熊团团：挑战「大火」模式，通关蝴蝶奖励翻倍哦！",
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

    // MARK: - 存档持久化与导入导出

    private static func saveFileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appDir = dir.appendingPathComponent("PinyinKitchen", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("progress_v2.json")
    }

    private static func loadProgress(key: String) -> GameProgress {
        let decoder = JSONDecoder()
        if let url = saveFileURL(),
           let data = try? Data(contentsOf: url),
           let loaded = try? decoder.decode(GameProgress.self, from: data) {
            return loaded
        }
        if let data = UserDefaults.standard.data(forKey: key),
           let loaded = try? decoder.decode(GameProgress.self, from: data) {
            return loaded
        }
        return GameProgress()
    }

    public func saveProgress() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        if let url = Self.saveFileURL() {
            try? data.write(to: url, options: .atomic)
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

    public func importJSONData(_ data: Data) -> String {
        let decoder = JSONDecoder()
        do {
            let incoming = try decoder.decode(GameProgress.self, from: data)
            let count = progress.merge(from: incoming)
            saveProgress()
            audio.sfxWin()
            return count > 0 ? "✅ 成功合并 \(count) 项学习记录与蝴蝶！" : "ℹ️ 这份记录里没有新的内容"
        } catch {
            audio.sfxBad()
            return "❌ 导入失败：文件格式不正确（\(error.localizedDescription)）"
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
        let species = rollButterfly(stars: 3, fire: .high)
        let beforeStage = progress.butterflyStage(for: species.id)
        progress.bf.append(CaughtButterfly(t: species.id, lv: 1, s: 3, d: GameProgress.todayString()))
        let afterStage = progress.butterflyStage(for: species.id)
        let newCount = progress.butterflyCount(for: species.id)
        saveProgress()
        audio.sfxSpark()
        pendingUpgrades.append(
            ButterflyUpgradeEvent(
                species: species,
                fromStage: max(1, beforeStage),
                toStage: max(1, afterStage),
                count: newCount,
                customTitle: afterStage > beforeStage ? nil : "🎁 盲盒开出新蝴蝶！"
            )
        )
    }

    public func rollButterfly(stars: Int, fire: FireDifficulty) -> ButterflySpecies {
        let x = Double.random(in: 0..<1)
        var targetRarity = 1
        if stars >= 3 {
            targetRarity = x < fire.rareBoost ? 3 : (x < fire.rareBoost + 0.30 ? 2 : 1)
        } else if stars == 2 {
            targetRarity = x < fire.rareBoost ? 2 : 1
        }
        let pool = ButterflySpecies.all.filter { $0.rarity == targetRarity }
        return pool.randomElement() ?? ButterflySpecies.all[0]
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
        rewardedButterfliesInRound = []
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
        rewardedButterfliesInRound = []
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
        rewardedButterfliesInRound = []
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
            if (progress.wrong[q.id] ?? 0) > 0 {
                if retriedCurrent {
                    let left = (progress.wrong[q.id] ?? 1) - 1
                    if left <= 0 {
                        progress.wrongMastered[q.id] = 1
                        progress.wrong.removeValue(forKey: q.id)
                    } else {
                        progress.wrong[q.id] = left
                    }
                } else {
                    progress.wrongMastered[q.id] = progress.wrong[q.id]
                    progress.wrong.removeValue(forKey: q.id)
                    masteredCount += 1
                }
            }
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
            audio.speakBaseFinal(base, slow: progress.tts.slow)
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
        audio.speakTonedFinal(toned, slow: progress.tts.slow)
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
        audio.speakTonedFinal(toned, slow: progress.tts.slow)
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

            if (progress.wrong[word.id] ?? 0) > 0 {
                if retriedCurrent {
                    let left = (progress.wrong[word.id] ?? 1) - 1
                    if left <= 0 {
                        progress.wrongMastered[word.id] = 1
                        progress.wrong.removeValue(forKey: word.id)
                    } else {
                        progress.wrong[word.id] = left
                    }
                } else {
                    progress.wrongMastered[word.id] = progress.wrong[word.id]
                    progress.wrong.removeValue(forKey: word.id)
                    masteredCount += 1
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

    // MARK: - 局末结算与蝴蝶进化（三科共享奖励与星星体系）

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

        var gifts: [ButterflySpecies] = []
        var upgrades: [ButterflyUpgradeEvent] = []
        if rightCount >= 4 {
            let clearKey = "\(currentSubject.rawValue)_\(currentLevelNumber)"
            let isFirstClear = (specialMode == nil && (progress.cleared[clearKey] ?? 0) == 0)
            if specialMode == nil {
                progress.cleared[clearKey] = 1
            }
            for _ in 0..<currentFire.butterflyRolls {
                gifts.append(rollButterfly(stars: stars, fire: currentFire))
            }
            if isFirstClear {
                gifts.append(rollButterfly(stars: stars, fire: currentFire))
            }

            var stageBefore: [String: Int] = [:]
            for g in gifts where stageBefore[g.id] == nil {
                stageBefore[g.id] = progress.butterflyStage(for: g.id)
            }
            for g in gifts {
                progress.bf.append(CaughtButterfly(t: g.id, lv: currentLevelNumber, s: stars, d: GameProgress.todayString()))
            }

            var checked = Set<String>()
            for g in gifts where !checked.contains(g.id) {
                checked.insert(g.id)
                let b0 = max(1, stageBefore[g.id] ?? 1)
                let b1 = progress.butterflyStage(for: g.id)
                if b1 > b0 {
                    upgrades.append(
                        ButterflyUpgradeEvent(
                            species: g,
                            fromStage: b0,
                            toStage: b1,
                            count: progress.butterflyCount(for: g.id),
                            customTitle: nil
                        )
                    )
                }
            }
        }

        rewardedButterfliesInRound = gifts
        saveProgress()
        screenState = .result

        if !gifts.isEmpty {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                self.audio.sfxSpark()
                if !upgrades.isEmpty {
                    try? await Task.sleep(nanoseconds: 650_000_000)
                    self.pendingUpgrades.append(contentsOf: upgrades)
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
