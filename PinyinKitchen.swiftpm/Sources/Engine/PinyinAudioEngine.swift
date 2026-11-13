import Foundation
import AVFoundation

@MainActor
public final class PinyinAudioEngine: ObservableObject {
    public static let shared = PinyinAudioEngine()

    private let synthesizer = AVSpeechSynthesizer()
    private var preferredVoice: AVSpeechSynthesisVoice?
    private var preferredEnglishVoice: AVSpeechSynthesisVoice?
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat?
    private var blendingTask: Task<Void, Never>?
    private var isPlayerAttached = false
    private var isPlayerConnected = false
    private var isReconfiguringAudio = false
    private var observerTokens: [NSObjectProtocol] = []

    // MARK: - 小学语文标准声母呼读音映射
    public static let initialCallouts: [String: String] = [
        "b": "玻", "p": "坡", "m": "摸", "f": "佛",
        "d": "得", "t": "特", "n": "讷", "l": "勒",
        "g": "哥", "k": "科", "h": "喝",
        "j": "基", "q": "欺", "x": "希",
        "zh": "知", "ch": "吃", "sh": "诗", "r": "日",
        "z": "资", "c": "雌", "s": "思",
        "y": "衣", "w": "乌"
    ]

    // MARK: - 无调韵母与整体认读母体标准本音映射
    public static let baseFinalCallouts: [String: String] = [
        "a": "阿", "o": "喔", "e": "鹅", "i": "衣", "u": "乌", "ü": "迂",
        "ai": "哀", "ei": "杯", "ui": "威", "ao": "熬", "ou": "欧", "iu": "优",
        "ie": "耶", "üe": "约", "ue": "约", "er": "儿",
        "an": "安", "en": "恩", "in": "音", "un": "温", "ün": "晕",
        "ang": "肮", "eng": "哼", "ing": "英", "ong": "翁",
        // 整体认读母体
        "zhi": "知", "chi": "吃", "shi": "诗", "ri": "日",
        "zi": "资", "ci": "疵", "si": "丝",
        "yi": "衣", "wu": "屋", "yu": "迂", "ye": "椰",
        "yue": "约", "yuan": "冤", "yin": "音", "yun": "晕", "ying": "英"
    ]

    // MARK: - 带调韵母四声精确同音字表（确保四声调料瓶点读 100% 准音）
    public static let tonedFinalCallouts: [String: String] = [
        // 单韵母四声
        "ā": "阿", "á": "啊", "ǎ": "啊", "à": "爸",
        "ō": "喔", "ó": "哦", "ǒ": "我", "ò": "卧",
        "ē": "婀", "é": "鹅", "ě": "噁", "è": "饿",
        "ī": "衣", "í": "姨", "ǐ": "椅", "ì": "意",
        "ū": "屋", "ú": "无", "ǔ": "五", "ù": "雾",
        "ǖ": "迂", "ǘ": "鱼", "ǚ": "雨", "ǜ": "玉",
        // 复韵母四声
        "āi": "哀", "ái": "挨", "ǎi": "矮", "ài": "爱",
        "ēi": "杯", "éi": "肥", "ěi": "美", "èi": "妹",
        "uī": "威", "uí": "围", "uǐ": "伟", "uì": "喂",
        "āo": "熬", "áo": "敖", "ǎo": "袄", "ào": "傲",
        "ōu": "欧", "óu": "鸥", "ǒu": "偶", "òu": "慪",
        "iū": "优", "iú": "油", "iǔ": "友", "iù": "右",
        "iē": "耶", "ié": "爷", "iě": "也", "iè": "叶",
        "üē": "约", "üé": "学", "üě": "雪", "üè": "月",
        "uē": "约", "ué": "学", "uě": "雪", "uè": "月",
        // 前鼻韵母四声
        "ān": "安", "án": "南", "ǎn": "俺", "àn": "暗",
        "ēn": "恩", "én": "人", "ěn": "忍", "èn": "认",
        "īn": "音", "ín": "银", "ǐn": "引", "ìn": "印",
        "ūn": "温", "ún": "文", "ǔn": "稳", "ùn": "问",
        "ǖn": "晕", "ǘn": "云", "ǚn": "允", "ǜn": "运",
        // 后鼻韵母四声
        "āng": "肮", "áng": "昂", "ǎng": "仰", "àng": "盎",
        "ēng": "风", "éng": "朋", "ěng": "冷", "èng": "梦",
        "īng": "英", "íng": "迎", "ǐng": "影", "ìng": "硬",
        "ōng": "翁", "óng": "红", "ǒng": "勇", "òng": "用",
        // 整体认读四声
        "zhī": "知", "zhí": "直", "zhǐ": "只", "zhì": "志",
        "chī": "吃", "chí": "迟", "chǐ": "尺", "chì": "翅",
        "shī": "诗", "shí": "十", "shǐ": "史", "shì": "是",
        "rì": "日",
        "zī": "资", "zǐ": "子", "zì": "字",
        "cí": "词", "cǐ": "此", "cì": "次",
        "sī": "丝", "sǐ": "死", "sì": "四",
        "yī": "一", "yí": "姨", "yǐ": "椅", "yì": "意",
        "wū": "屋", "wú": "无", "wǔ": "五", "wù": "雾",
        "yū": "淤", "yú": "鱼", "yǔ": "雨", "yù": "玉",
        "yē": "椰", "yé": "爷", "yě": "也", "yè": "叶",
        "yuē": "约", "yuè": "月",
        "yuān": "冤", "yuán": "圆", "yuǎn": "远", "yuàn": "院",
        "yīn": "因", "yín": "银", "yǐn": "引", "yìn": "印",
        "yūn": "晕", "yún": "云", "yǔn": "允", "yùn": "运",
        "yīng": "英", "yíng": "赢", "yǐng": "影", "yìng": "硬"
    ]

    private init() {
        setupAudioSessionIfNeeded()
        setupAudioEngine()
        setupAudioObservers()
        selectPreferredChineseVoice()
    }

    private func setupAudioSessionIfNeeded() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // 静默容错
        }
        #endif
    }

    private func currentHardwareSampleRate() -> Double {
        let outputSR = audioEngine.outputNode.outputFormat(forBus: 0).sampleRate
        if outputSR > 0 {
            return outputSR
        }
        #if os(iOS)
        let sessionSR = AVAudioSession.sharedInstance().sampleRate
        if sessionSR > 0 {
            return sessionSR
        }
        #endif
        return 44100.0
    }

    private func setupAudioEngine() {
        rebuildAudioGraph(forceReconnect: true)
    }

    private func rebuildAudioGraph(forceReconnect: Bool = false) {
        guard !isReconfiguringAudio else { return }
        isReconfiguringAudio = true
        defer { isReconfiguringAudio = false }

        setupAudioSessionIfNeeded()

        let targetSampleRate = currentHardwareSampleRate()
        let needsFormatChange = audioFormat?.sampleRate != targetSampleRate

        if forceReconnect || needsFormatChange || !isPlayerAttached || !isPlayerConnected {
            if isPlayerAttached {
                playerNode.stop()
            }
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            if isPlayerAttached {
                audioEngine.disconnectNodeInput(playerNode)
                audioEngine.disconnectNodeOutput(playerNode)
                audioEngine.detach(playerNode)
                isPlayerAttached = false
                isPlayerConnected = false
            }
            audioEngine.reset()

            let finalSampleRate = currentHardwareSampleRate()
            let format = AVAudioFormat(standardFormatWithSampleRate: finalSampleRate, channels: 1)
            self.audioFormat = format

            audioEngine.attach(playerNode)
            isPlayerAttached = true

            if let format = format {
                audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
                isPlayerConnected = true
            }
        }

        if !audioEngine.isRunning {
            audioEngine.prepare()
            do {
                try audioEngine.start()
            } catch {
                // 静默容错
                return
            }
        }

        if isPlayerAttached && isPlayerConnected && audioEngine.isRunning && !playerNode.isPlaying {
            playerNode.play()
        }
    }

    private func ensureAudioReadyForPlayback() {
        let hwRate = currentHardwareSampleRate()
        let nodeFormat = playerNode.outputFormat(forBus: 0)
        let rateMismatch = (audioFormat?.sampleRate != hwRate) || (nodeFormat.sampleRate != audioFormat?.sampleRate)
        if !isPlayerAttached || !isPlayerConnected || !audioEngine.isRunning || rateMismatch {
            rebuildAudioGraph(forceReconnect: rateMismatch || !isPlayerAttached || !isPlayerConnected)
        } else if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    private func setupAudioObservers() {
        guard observerTokens.isEmpty else { return }
        let center = NotificationCenter.default

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        let interruptionToken = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self = self,
                      let rawType = rawType,
                      let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
                switch type {
                case .began:
                    if self.isPlayerAttached {
                        self.playerNode.pause()
                    }
                    if self.audioEngine.isRunning {
                        self.audioEngine.pause()
                    }
                case .ended:
                    let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions ?? 0)
                    self.setupAudioSessionIfNeeded()
                    if options.contains(.shouldResume) || !self.audioEngine.isRunning {
                        self.rebuildAudioGraph(forceReconnect: true)
                    }
                @unknown default:
                    break
                }
            }
        }
        observerTokens.append(interruptionToken)

        let routeChangeToken = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self = self,
                      let rawReason = rawReason,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else { return }
                switch reason {
                case .newDeviceAvailable, .oldDeviceUnavailable, .categoryChange, .override, .wakeFromSleep, .routeConfigurationChange:
                    self.rebuildAudioGraph(forceReconnect: true)
                default:
                    break
                }
            }
        }
        observerTokens.append(routeChangeToken)
        #endif

        let configChangeToken = center.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.rebuildAudioGraph(forceReconnect: true)
            }
        }
        observerTokens.append(configChangeToken)
    }

    private func selectPreferredChineseVoice() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let zhVoices = voices.filter { $0.language.lowercased().hasPrefix("zh") }
        let cnVoices = zhVoices.filter {
            let l = $0.language.lowercased()
            return l.contains("cn") || l.contains("hans")
        }
        let pool = cnVoices.isEmpty ? zhVoices : cnVoices
        preferredVoice = pool.sorted { a, b in
            func score(_ v: AVSpeechSynthesisVoice) -> Int {
                let n = v.name.lowercased()
                var s = v.quality == .enhanced ? 10 : 0
                if n.contains("tingting") || n.contains("婷婷") || n.contains("flo") || n.contains("sandy") || n.contains("shelley") {
                    s += 5
                }
                return s
            }
            return score(a) > score(b)
        }.first ?? AVSpeechSynthesisVoice(language: "zh-CN")

        let enVoices = voices.filter { $0.language.lowercased().hasPrefix("en") }
        let usVoices = enVoices.filter { $0.language.lowercased().contains("us") || $0.language.lowercased().contains("gb") }
        let enPool = usVoices.isEmpty ? enVoices : usVoices
        preferredEnglishVoice = enPool.sorted { a, b in
            func score(_ v: AVSpeechSynthesisVoice) -> Int {
                let n = v.name.lowercased()
                var s = v.quality == .enhanced ? 10 : 0
                if n.contains("samantha") || n.contains("ava") || n.contains("allison") || n.contains("flo") || n.contains("shelley") {
                    s += 5
                }
                return s
            }
            return score(a) > score(b)
        }.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - 英语与双语播报接口

    public func speakEnglish(_ text: String, slow: Bool = false) {
        guard !text.isEmpty else { return }
        setupAudioSessionIfNeeded()
        blendingTask?.cancel()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredEnglishVoice ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = slow ? 0.36 : 0.45
        utterance.pitchMultiplier = 1.06
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    public func speakBilingual(english: String?, chinese: String, slow: Bool = false) {
        setupAudioSessionIfNeeded()
        blendingTask?.cancel()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let en = english, !en.isEmpty {
            let u1 = AVSpeechUtterance(string: en)
            u1.voice = preferredEnglishVoice ?? AVSpeechSynthesisVoice(language: "en-US")
            u1.rate = slow ? 0.36 : 0.45
            u1.pitchMultiplier = 1.06
            u1.postUtteranceDelay = 0.18
            synthesizer.speak(u1)
        }
        if !chinese.isEmpty {
            let u2 = AVSpeechUtterance(string: chinese)
            u2.voice = preferredVoice ?? AVSpeechSynthesisVoice(language: "zh-CN")
            u2.rate = slow ? 0.38 : 0.47
            u2.pitchMultiplier = 1.06
            synthesizer.speak(u2)
        }
    }

    // MARK: - 语音播报接口

    /// 立即停止所有朗读（护眼休息、打烊时使用）
    public func stopAllSpeech() {
        blendingTask?.cancel()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    public func speakText(_ text: String, slow: Bool = false, rateOverride: Float? = nil) {
        guard !text.isEmpty else { return }
        blendingTask?.cancel()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        speakUtteranceImmediate(text, slow: slow, rateOverride: rateOverride)
    }

    private func speakUtteranceImmediate(_ text: String, slow: Bool = false, rateOverride: Float? = nil) {
        setupAudioSessionIfNeeded()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice ?? AVSpeechSynthesisVoice(language: "zh-CN")
        if let rateOverride = rateOverride {
            utterance.rate = rateOverride
        } else {
            utterance.rate = slow ? 0.36 : 0.47
        }
        utterance.pitchMultiplier = 1.08
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    /// 点读声母本音（如点 b 读「玻」）
    public func speakInitial(_ initial: String, slow: Bool = false) {
        let callout = Self.initialCallouts[initial] ?? initial
        speakText(callout, slow: slow, rateOverride: slow ? 0.42 : 0.52)
    }

    /// 点读无调韵母母体本音（如点 ai 读「哀」；若跟在 j/q/x 后面，u/un 读作 ü/ün 的本音「迂/晕」）
    public func speakBaseFinal(_ baseFinal: String, initial: String? = nil, slow: Bool = false) {
        let isJQX = ["j", "q", "x"].contains(initial ?? "")
        let effectiveBase: String
        if isJQX && baseFinal == "u" {
            effectiveBase = "ü"
        } else if isJQX && baseFinal == "un" {
            effectiveBase = "ün"
        } else {
            effectiveBase = baseFinal
        }
        let callout = Self.baseFinalCallouts[effectiveBase] ?? effectiveBase
        speakText(callout, slow: slow, rateOverride: slow ? 0.40 : 0.49)
    }

    /// 点读带调韵母或四声调料瓶（如点 á 读二声；若已选 j/q/x，则 ū/ú/ǔ/ù 按 ǖ/ǘ/ǚ/ǜ 读音）
    public func speakTonedFinal(_ tonedFinal: String, initial: String? = nil, previewCharacter: String? = nil, slow: Bool = false) {
        if let ch = previewCharacter, !ch.isEmpty {
            speakText(ch, slow: slow)
            return
        }
        let effectiveToned = Self.normalizeJQXFinalForSpeech(tonedFinal: tonedFinal, initial: initial)
        let callout = Self.tonedFinalCallouts[effectiveToned] ?? Self.baseFinalCallouts[PinyinHelper.stripTone(effectiveToned)] ?? tonedFinal
        speakText(callout, slow: slow)
    }

    /// 当声母为 j/q/x 时，去两点的 u/un 还原为 ü/ün 的真实读音
    public static func normalizeJQXFinalForSpeech(tonedFinal: String, initial: String?) -> String {
        guard ["j", "q", "x"].contains(initial ?? "") else { return tonedFinal }
        switch tonedFinal {
        case "ū": return "ǖ"
        case "ú": return "ǘ"
        case "ǔ": return "ǚ"
        case "ù": return "ǜ"
        case "ūn": return "ǖn"
        case "ún": return "ǘn"
        case "ǔn": return "ǚn"
        case "ùn": return "ǜn"
        default: return tonedFinal
        }
    }

    /// 核心教学升级：播放「声母 + (介音) + 韵母 → 汉字，词语」真实拼读连读过程，并驱动 UI 高亮对应槽位
    public func speakBlending(
        word: PinyinWord,
        phrase: String,
        slow: Bool,
        onHighlightStep: @escaping @MainActor (String?) -> Void
    ) {
        blendingTask?.cancel()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        blendingTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            let stepDelay: UInt64 = slow ? 520_000_000 : 380_000_000

            if word.mode == .whole {
                onHighlightStep("w")
                speakUtteranceImmediate(word.character, slow: slow, rateOverride: slow ? 0.40 : 0.48)
                try? await Task.sleep(nanoseconds: stepDelay + 120_000_000)
                guard !Task.isCancelled else { return }
                onHighlightStep("char")
                speakUtteranceImmediate("\(word.character)，\(phrase)", slow: slow)
                try? await Task.sleep(nanoseconds: 900_000_000)
                guard !Task.isCancelled else { return }
                onHighlightStep(nil)
                return
            }

            // 1. 读声母
            if let ini = word.initial {
                guard !Task.isCancelled else { return }
                onHighlightStep("i")
                let iniCallout = Self.initialCallouts[ini] ?? ini
                speakUtteranceImmediate(iniCallout, slow: slow, rateOverride: slow ? 0.44 : 0.54)
                try? await Task.sleep(nanoseconds: stepDelay)
                guard !Task.isCancelled else { return }
            }

            // 2. 如果是三拼，读介音
            if word.mode == .tri, let med = word.medial {
                guard !Task.isCancelled else { return }
                onHighlightStep("m")
                let medCallout = Self.baseFinalCallouts[med] ?? med
                speakUtteranceImmediate(medCallout, slow: slow, rateOverride: slow ? 0.44 : 0.54)
                try? await Task.sleep(nanoseconds: stepDelay)
                guard !Task.isCancelled else { return }
            }

            // 3. 读带调韵母（若为 j/q/x + u/un，自动按 ü/ün 真实读音播报）
            guard !Task.isCancelled else { return }
            onHighlightStep("f")
            let effectiveToned = Self.normalizeJQXFinalForSpeech(tonedFinal: word.tonedFinal, initial: word.initial)
            let finCallout = Self.tonedFinalCallouts[effectiveToned] ?? word.character
            speakUtteranceImmediate(finCallout, slow: slow, rateOverride: slow ? 0.42 : 0.50)
            try? await Task.sleep(nanoseconds: stepDelay + 70_000_000)
            guard !Task.isCancelled else { return }

            // 4. 连读出锅汉字与词组
            onHighlightStep("char")
            speakUtteranceImmediate("\(word.character)，\(phrase)", slow: slow)
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled {
                onHighlightStep(nil)
            }
        }
    }

    // MARK: - 趣味合成音效 (WebAudio 级实时波形合成)

    private func playTones(_ notes: [(freq: Double, delay: Double, duration: Double, wave: String, vol: Float)]) {
        ensureAudioReadyForPlayback()
        guard audioEngine.isRunning,
              isPlayerAttached,
              isPlayerConnected,
              let format = audioFormat else { return }
        let nodeFormat = playerNode.outputFormat(forBus: 0)
        guard nodeFormat.sampleRate == format.sampleRate,
              nodeFormat.channelCount == format.channelCount else {
            return
        }
        if !playerNode.isPlaying {
            playerNode.play()
        }
        let sampleRate = format.sampleRate
        let totalDur = (notes.map { $0.delay + $0.duration }.max() ?? 0.2) + 0.06
        let frameCount = AVAudioFrameCount(totalDur * sampleRate)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return }

        for i in 0..<Int(frameCount) {
            channelData[i] = 0
        }

        for note in notes {
            let startFrame = Int(note.delay * sampleRate)
            let durFrames = Int(note.duration * sampleRate)
            let attackFrames = max(1, Int(0.015 * sampleRate))
            for f in 0..<durFrames {
                let idx = startFrame + f
                if idx >= Int(frameCount) { break }
                let t = Double(f) / sampleRate
                let phase = 2.0 * Double.pi * note.freq * t
                let rawWave: Float
                if note.wave == "triangle" {
                    rawWave = Float(2.0 / Double.pi * asin(sin(phase)))
                } else {
                    rawWave = Float(sin(phase))
                }
                let env: Float
                if f < attackFrames {
                    env = Float(f) / Float(attackFrames)
                } else {
                    let progress = Float(f - attackFrames) / Float(max(1, durFrames - attackFrames))
                    env = pow(1.0 - progress, 2.2)
                }
                channelData[idx] += rawWave * env * note.vol
            }
        }

        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    public func sfxTap() {
        playTones([
            (587, 0.00, 0.05, "sine", 0.14),
            (880, 0.03, 0.06, "sine", 0.11)
        ])
    }

    public func sfxBubble() {
        playTones([
            (420, 0.00, 0.06, "sine", 0.13),
            (640, 0.05, 0.08, "sine", 0.15)
        ])
    }

    public func sfxSeasoning() {
        playTones([
            (659, 0.00, 0.05, "sine", 0.13),
            (987, 0.04, 0.07, "sine", 0.13)
        ])
    }

    public func sfxWin() {
        playTones([
            (784,  0.00, 0.12, "sine", 0.18),
            (1046, 0.08, 0.16, "sine", 0.18),
            (1318, 0.16, 0.24, "sine", 0.20)
        ])
    }

    public func sfxBig() {
        playTones([
            (784,  0.00, 0.12, "sine", 0.18),
            (988,  0.08, 0.14, "sine", 0.18),
            (1175, 0.15, 0.18, "sine", 0.20),
            (1568, 0.24, 0.30, "sine", 0.22)
        ])
    }

    public func sfxBad() {
        playTones([
            (233, 0.00, 0.22, "triangle", 0.18),
            (175, 0.10, 0.28, "triangle", 0.15)
        ])
    }

    public func sfxSpark() {
        playTones([
            (1046, 0.00, 0.10, "sine", 0.16),
            (1318, 0.08, 0.12, "sine", 0.16),
            (1568, 0.16, 0.20, "sine", 0.18),
            (2093, 0.24, 0.34, "sine", 0.20)
        ])
    }

    /// 清脆星币入账叮当声
    public func sfxCoin() {
        playTones([
            (1318, 0.00, 0.07, "sine", 0.16),
            (1760, 0.05, 0.18, "sine", 0.18)
        ])
    }

    /// 皇家扭蛋机旋钮齿轮与彩球翻滚声
    public func sfxGachaCrank() {
        playTones([
            (392,  0.00, 0.07, "triangle", 0.15),
            (494,  0.08, 0.07, "triangle", 0.15),
            (587,  0.16, 0.08, "triangle", 0.16),
            (784,  0.25, 0.10, "sine",     0.17),
            (1046, 0.36, 0.16, "sine",     0.19)
        ])
    }

    /// 神秘宝箱 / 扭蛋破壳大爆发凯旋和弦
    public func sfxChestOpen() {
        playTones([
            (523,  0.00, 0.10, "sine", 0.17),
            (659,  0.07, 0.10, "sine", 0.17),
            (784,  0.14, 0.12, "sine", 0.18),
            (1046, 0.22, 0.15, "sine", 0.20),
            (1318, 0.30, 0.18, "sine", 0.20),
            (1568, 0.38, 0.36, "sine", 0.22)
        ])
    }

    /// 守护萌宠开心撒娇音效
    public func sfxPetHappy() {
        playTones([
            (880,  0.00, 0.08, "sine", 0.16),
            (1175, 0.07, 0.09, "sine", 0.17),
            (1397, 0.14, 0.11, "sine", 0.18),
            (1760, 0.22, 0.22, "sine", 0.19)
        ])
    }

    /// 皇家烟花绽放星光音效
    public func sfxFirework() {
        playTones([
            (659,  0.00, 0.08, "sine", 0.14),
            (988,  0.06, 0.10, "sine", 0.15),
            (1318, 0.12, 0.14, "sine", 0.17),
            (1976, 0.18, 0.28, "sine", 0.19)
        ])
    }

    /// 狂热连击爆发欢呼音效
    public func sfxFever() {
        playTones([
            (523,  0.00, 0.08, "triangle", 0.12),
            (659,  0.05, 0.09, "sine",     0.14),
            (784,  0.10, 0.10, "sine",     0.15),
            (1047, 0.15, 0.14, "sine",     0.17),
            (1319, 0.21, 0.20, "sine",     0.16),
            (1568, 0.27, 0.28, "sine",     0.15)
        ])
    }

    /// 幸运大转盘飞转拨片音效
    public func sfxWheelSpin() {
        playTones([
            (740,  0.00, 0.035, "triangle", 0.11),
            (880,  0.05, 0.035, "triangle", 0.11),
            (988,  0.11, 0.035, "triangle", 0.12),
            (880,  0.18, 0.04,  "triangle", 0.11),
            (784,  0.26, 0.045, "triangle", 0.10),
            (1047, 0.36, 0.14,  "sine",     0.14)
        ])
    }

    /// 花式搅拌旋转魔法音效
    public func sfxTwirl() {
        playTones([
            (587,  0.00, 0.07, "sine",     0.12),
            (740,  0.05, 0.08, "sine",     0.13),
            (880,  0.10, 0.09, "triangle", 0.13),
            (1175, 0.15, 0.14, "sine",     0.15),
            (1480, 0.21, 0.22, "sine",     0.14)
        ])
    }
}
