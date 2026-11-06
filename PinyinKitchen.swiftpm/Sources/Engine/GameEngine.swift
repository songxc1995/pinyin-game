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
    @Published public var pickedChoiceOption: String? = nil
    @Published public var showMathExplanation: Bool = false

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
        "小熊团团：三科全部严格同步上海沪教版一年级上/下册教材哦！"
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
        progress = GameProgress()
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
        let idx = max(0, min(HujiaoCurriculumRepository.mathStages.count - 1, currentLevelNumber - 1))
        return HujiaoCurriculumRepository.mathStages[idx]
    }

    public var currentEnglishStageDef: EnglishStageDefinition {
        let idx = max(0, min(HujiaoCurriculumRepository.englishStages.count - 1, currentLevelNumber - 1))
        return HujiaoCurriculumRepository.englishStages[idx]
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
        pickedChoiceOption = nil
        showMathExplanation = false

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
                if self.currentWord == word && self.screenState == .playing {
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
                    chefBubble = "听一听地道牛津英语发音，选出正确的鲜果特调卡片吧！"
                }
            }

            let slow = progress.tts.slow
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard self.currentCurriculumQuestion == q && self.screenState == .playing else { return }
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
            if let eng = q.englishAudio, !eng.isEmpty {
                audio.speakEnglish(eng, slow: useSlow)
            } else {
                audio.speakText(q.prompt, slow: useSlow)
            }
        } else {
            let cleanPrompt = q.prompt
                .replacingOccurrences(of: "□", with: "方框")
                .replacingOccurrences(of: "○", with: "圆圈")
                .replacingOccurrences(of: "★", with: "星星")
                .replacingOccurrences(of: "☆", with: "星星")
            audio.speakText(cleanPrompt, slow: useSlow)
        }
    }

    public func toggleMathExplanationTip() {
        guard let q = currentCurriculumQuestion else { return }
        audio.sfxTap()
        showMathExplanation.toggle()
        if showMathExplanation {
            audio.speakText(q.explanation, slow: progress.tts.slow)
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
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 240_000_000)
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
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
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
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 280_000_000)
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

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 550_000_000)
                self.potShaking = false
                try? await Task.sleep(nanoseconds: 1_550_000_000)
                guard self.screenState == .playing else { return }
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

                chefBubble = "差一点点！看看「算理小锦囊」，再试一次吧！"
                tipMessage = "💡 锦囊提示：\(q.explanation)（本局还能重做 \(retryLeft) 次）"
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

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                self.potNope = false
                try? await Task.sleep(nanoseconds: 2_100_000_000)
                guard self.screenState == .playing else { return }
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
        guard screenState == .playing, !isLocked else { return }
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
                if let idx = Int(key), idx >= 1 && idx <= q.options.count {
                    selectCurriculumChoice(q.options[idx - 1])
                    return
                }
            } else if q.type == "sentence" {
                if let idx = Int(key), idx >= 1 && idx <= q.options.count {
                    toggleSentenceBlock(at: idx - 1)
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
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 280_000_000)
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

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 550_000_000)
                self.potShaking = false
                try? await Task.sleep(nanoseconds: 1_550_000_000)
                guard self.screenState == .playing else { return }
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

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                self.potNope = false
                try? await Task.sleep(nanoseconds: 1_950_000_000)
                guard self.screenState == .playing else { return }
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
}
