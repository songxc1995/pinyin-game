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
        "ā": "阿", "á": "啊", "ǎ": "呵", "à": "爸",
        "ō": "喔", "ó": "哦", "ǒ": "我", "ò": "卧",
        "ē": "阿", "é": "鹅", "ě": "恶", "è": "饿",
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
        setupAudioEngine()
        selectPreferredChineseVoice()
    }

    private func setupAudioEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        self.audioFormat = format
        audioEngine.attach(playerNode)
        if let format = format {
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        }
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            // 静默容错
        }
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

    /// 点读无调韵母母体本音（如点 ai 读「哀」）
    public func speakBaseFinal(_ baseFinal: String, slow: Bool = false) {
        let callout = Self.baseFinalCallouts[baseFinal] ?? baseFinal
        speakText(callout, slow: slow, rateOverride: slow ? 0.40 : 0.49)
    }

    /// 点读带调韵母或四声调料瓶（如点 á 读二声，或者如果已选声母则直接预读合成音）
    public func speakTonedFinal(_ tonedFinal: String, previewCharacter: String? = nil, slow: Bool = false) {
        if let ch = previewCharacter, !ch.isEmpty {
            speakText(ch, slow: slow)
            return
        }
        let callout = Self.tonedFinalCallouts[tonedFinal] ?? Self.baseFinalCallouts[PinyinHelper.stripTone(tonedFinal)] ?? tonedFinal
        speakText(callout, slow: slow)
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
            let stepDelay: UInt64 = slow ? 520_000_000 : 380_000_000

            if word.mode == .whole {
                onHighlightStep("w")
                speakUtteranceImmediate(word.character, slow: slow, rateOverride: slow ? 0.40 : 0.48)
                try? await Task.sleep(nanoseconds: stepDelay + 120_000_000)
                guard !Task.isCancelled else { return }
                onHighlightStep("char")
                speakUtteranceImmediate("\(word.character)，\(phrase)", slow: slow)
                try? await Task.sleep(nanoseconds: 900_000_000)
                onHighlightStep(nil)
                return
            }

            // 1. 读声母
            if let ini = word.initial {
                onHighlightStep("i")
                let iniCallout = Self.initialCallouts[ini] ?? ini
                speakUtteranceImmediate(iniCallout, slow: slow, rateOverride: slow ? 0.44 : 0.54)
                try? await Task.sleep(nanoseconds: stepDelay)
                guard !Task.isCancelled else { return }
            }

            // 2. 如果是三拼，读介音
            if word.mode == .tri, let med = word.medial {
                onHighlightStep("m")
                let medCallout = Self.baseFinalCallouts[med] ?? med
                speakUtteranceImmediate(medCallout, slow: slow, rateOverride: slow ? 0.44 : 0.54)
                try? await Task.sleep(nanoseconds: stepDelay)
                guard !Task.isCancelled else { return }
            }

            // 3. 读带调韵母
            onHighlightStep("f")
            let finCallout = Self.tonedFinalCallouts[word.tonedFinal] ?? word.character
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
        guard let format = audioFormat else { return }
        if !audioEngine.isRunning {
            try? audioEngine.start()
            playerNode.play()
        }
        let sampleRate = format.sampleRate
        let totalDur = (notes.map { $0.delay + $0.duration }.max() ?? 0.2) + 0.06
        let frameCount = AVAudioFrameCount(totalDur * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
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
}
