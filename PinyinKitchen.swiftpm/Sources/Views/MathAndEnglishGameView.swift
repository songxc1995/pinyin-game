import SwiftUI
#if os(macOS)
import AppKit
#endif

public struct CurriculumGameView: View {
    @ObservedObject public var engine: GameEngine
    #if os(macOS)
    @State private var keyMonitor: Any? = nil
    #endif

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var themeColor: Color {
        Color(hex: engine.currentSubject.themeHex)
    }

    public var body: some View {
        VStack(spacing: 11) {
            topGameBar
            hudStatusStrip

            GeometryReader { geo in
                let isWide = geo.size.width >= 760
                if isWide {
                    HStack(alignment: .top, spacing: 18) {
                        leftStageColumn
                            .frame(width: geo.size.width * 0.46)
                        rightInteractiveColumn
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            leftStageColumn
                            rightInteractiveColumn
                        }
                    }
                }
            }
        }
        .onAppear {
            installKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
    }

    // MARK: - 顶部导航栏
    private var topGameBar: some View {
        HStack(spacing: 12) {
            Button {
                engine.audio.sfxTap()
                engine.goHome()
            } label: {
                HStack(spacing: 4) {
                    Text("←")
                    Text("返回选关")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#3B2E22"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, y: 2)
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(stageTitle)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(Color(hex: "#3B2E22"))
                    Text(stageBadgeTag)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(themeColor))
                }
                Text(stageSubtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
                    .lineLimit(1)
            }

            Spacer()

            // 算理 / 语法小锦囊按钮
            Button {
                engine.toggleMathExplanationTip()
            } label: {
                Text(engine.showMathExplanation ? "💡 锦囊:已展开" : "💡 算理/语法小锦囊")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(engine.showMathExplanation ? .white : themeColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 11)
                            .fill(engine.showMathExplanation ? themeColor : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(themeColor.opacity(0.45), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            // 语速切换
            Button {
                engine.audio.sfxTap()
                engine.progress.tts.slow.toggle()
                engine.saveProgress()
                engine.speakCurrentCurriculumPrompt()
            } label: {
                Text(engine.progress.tts.slow ? "🐢 慢速朗读" : "🐇 正常语速")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Color(hex: "#3B2E22"))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 11).fill(Color.white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var stageTitle: String {
        if let sp = engine.specialMode {
            switch sp {
            case .wrong:   return "🛠️ \(engine.currentSubject.shortTitle) · 错题特训营"
            case .allstar: return "⚡ \(engine.currentSubject.shortTitle) · 全明星随机挑战"
            }
        }
        return engine.currentSubject == .math
            ? engine.currentMathStageDef.name
            : engine.currentEnglishStageDef.name
    }

    private var stageBadgeTag: String {
        if engine.specialMode != nil { return "专项特训" }
        return engine.currentSubject == .math
            ? engine.currentMathStageDef.semesterTag
            : engine.currentEnglishStageDef.unitCode
    }

    private var stageSubtitle: String {
        let base = engine.currentSubject == .math
            ? engine.currentMathStageDef.subtitle
            : engine.currentEnglishStageDef.subtitle
        return "\(base) · \(engine.currentFire.name)"
    }

    // MARK: - 局内进度状态条
    private var hudStatusStrip: some View {
        let total = max(1, engine.curriculumQueue.count)
        let current = min(total, engine.questionIndex + 1)
        let pct = Double(engine.questionIndex) / Double(total)

        return HStack(spacing: 14) {
            Text("📋 订单 \(current) / \(total)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Color(hex: "#5A3818"))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [themeColor, Color(hex: "#FFB347")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * pct)
                        .animation(.easeOut(duration: 0.25), value: pct)
                }
            }
            .frame(height: 10)

            Text("✓ 答对 \(engine.rightCount)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#2B7F4A"))

            if engine.comboCount >= 2 {
                Text("🔥 连击 ×\(engine.comboCount)")
                    .font(.system(size: 12.5, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(themeColor))
            }

            Text("回锅余量 \(engine.retryLeft)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#8A7765"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.88))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.07), lineWidth: 1))
        )
    }

    // MARK: - 左栏：小动物点单 + 题干与语音栏 + 互动教具 + 烘焙烤箱/果汁机舞台
    private var leftStageColumn: some View {
        let q = engine.currentCurriculumQuestion

        return VStack(spacing: 10) {
            // 1. 森林小动物顾客与题目卡片
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#FFF3DC"))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(themeColor.opacity(0.45), lineWidth: 2))
                        Text(engine.currentCustomer.emoji)
                            .font(.system(size: 26))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("\(engine.currentCustomer.name)点单")
                                .font(.system(size: 13.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#4A2E14"))
                            if let difficulty = q?.difficulty {
                                let diffLabel = difficulty == "basic" ? "★ 基础配方" : (difficulty == "medium" ? "★★ 进阶特调" : "★★★ 压轴挑战")
                                Text(diffLabel)
                                    .font(.system(size: 10.5, weight: .heavy))
                                    .foregroundColor(themeColor)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(themeColor.opacity(0.12)))
                            }
                        }
                        Text(engine.currentSubject == .math ? "「帮我烤一份美味的数学甜点吧！」" : "「Can you make this fresh fruit drink for me?」")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                    Spacer()
                }

                // 题干展示区
                if let q = q {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(q.prompt)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#3B2E22"))
                            .fixedSize(horizontal: false, vertical: true)

                        // 仅当英文音频不会直接泄露答案，或者已经判题完毕后，才展示英文原句条
                        if let eng = q.englishAudio, !eng.isEmpty, engine.currentSubject == .english, (!engine.promptAudioRevealsAnswer || engine.isCurrentQuestionJudged) {
                            HStack(spacing: 8) {
                                Text("🇬🇧")
                                Text(eng)
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundColor(Color(hex: "#156947"))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "#E8FFF5"))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#2FB380").opacity(0.35), lineWidth: 1.5))
                            )
                        }

                        // 语音点读按钮栏
                        HStack(spacing: 8) {
                            Button {
                                engine.speakCurrentCurriculumPrompt(slow: false)
                            } label: {
                                Label(
                                    engine.currentSubject == .english
                                        ? ((!engine.promptAudioRevealsAnswer || engine.isCurrentQuestionJudged) ? "🇬🇧 听纯正发音" : "🔊 读题干要求")
                                        : "🔊 读题干",
                                    systemImage: "speaker.wave.2.fill"
                                )
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(themeColor))
                            }
                            .buttonStyle(.plain)

                            if engine.currentSubject == .english {
                                Button {
                                    engine.speakCurrentCurriculumPrompt(slow: true)
                                } label: {
                                    Text("🐢 慢速跟读")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(hex: "#156947"))
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color(hex: "#E8FFF5")))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    engine.toggleMathExplanationTip()
                                } label: {
                                    Text("💡 语法小锦囊")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(hex: "#5A4634"))
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color(hex: "#FFF3DC")))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    engine.toggleMathExplanationTip()
                                } label: {
                                    Text("💡 听算理小锦囊")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(hex: "#B8336A"))
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color(hex: "#FFE8F0")))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#FFFDF9"))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(themeColor.opacity(0.28), lineWidth: 1.5))
                    )
                }

                // 2. 沪教数学 5 大可视化互动教具 / 牛津英语造句调制杯
                if let q = q {
                    if engine.currentSubject == .math {
                        MathVisualAidView(
                            question: q,
                            showHint: engine.isCurrentQuestionJudged
                        )
                    } else if q.type == "sentence" {
                        englishSentenceBlenderTray(q)
                    } else {
                        englishUnitKeyCard
                    }
                }

                // 算理 / 语法小锦囊展开条（答题前展示思考方法提示，判题后展示完整解析）
                if engine.showMathExplanation, q != nil {
                    HStack(alignment: .top, spacing: 8) {
                        Text("💡")
                            .font(.system(size: 16))
                        Text(engine.hintText)
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(Color(hex: "#7A2E1D"))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#FFF4D9"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#F5A623"), lineWidth: 1.5))
                    )
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(themeColor.opacity(0.22), lineWidth: 1.8))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, y: 3)
            )

            // 3. 烘焙烤箱 / 鲜果料理机舞台
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(engine.currentSubject == .math ? "🧁 团团烘焙师：" : "🧃 团团调饮师：")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundColor(themeColor)
                    Text(engine.chefBubble)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.9)))

                if engine.currentSubject == .math {
                    MathOvenVectorView(
                        shaking: engine.potShaking,
                        nope: engine.potNope,
                        steamActive: engine.steamActive,
                        dishPopup: engine.dishPopup
                    )
                } else {
                    EnglishBlenderVectorView(
                        shaking: engine.potShaking,
                        nope: engine.potNope,
                        steamActive: engine.steamActive,
                        dishPopup: engine.dishPopup
                    )
                }

                if !engine.tipMessage.isEmpty {
                    Text(engine.tipMessage)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(
                            engine.tipStyle == "ok" ? Color(hex: "#2B7F4A") :
                                (engine.tipStyle == "no" ? Color(hex: "#E25247") : Color(hex: "#B25614"))
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    engine.tipStyle == "ok" ? Color(hex: "#E6F7ED") :
                                        (engine.tipStyle == "no" ? Color(hex: "#FDECEB") : Color(hex: "#FFF5E0"))
                                )
                        )
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(themeColor.opacity(0.2), lineWidth: 1.5))
            )
        }
    }

    // MARK: - 英语果粒句子调制杯托盘
    private func englishSentenceBlenderTray(_ q: CurriculumQuestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("🍹 鲜果句子调制杯（已放入 \(engine.sentencePickedIndices.count)/\(q.options.count) 块）")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#156947"))
                Spacer()
                if !engine.sentencePickedIndices.isEmpty {
                    Button {
                        engine.clearSentenceBlocks()
                    } label: {
                        Text("🔄 清空重拼")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color(hex: "#E25247"))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 6) {
                if engine.sentencePickedIndices.isEmpty {
                    Text("👉 请按顺序点击右侧的鲜果英文词块，拼出完整句子！")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(engine.sentencePickedIndices.enumerated()), id: \.offset) { _, optIdx in
                        if optIdx < q.options.count {
                            let word = q.options[optIdx]
                            Button {
                                engine.toggleSentenceBlock(at: optIdx)
                            } label: {
                                Text(word)
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: "#2FB380"))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Spacer()
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#F2FFF9"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "#2FB380"), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    )
            )
        }
    }

    // MARK: - 英语单元重点词汇与句型点读条
    private var englishUnitKeyCard: some View {
        let stg = engine.currentEnglishStageDef
        return VStack(alignment: .leading, spacing: 5) {
            Text("📘 \(stg.unitCode) 单元核心鲜果词（点词可听发音）")
                .font(.system(size: 11.5, weight: .heavy))
                .foregroundColor(Color(hex: "#156947"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(stg.topicWords, id: \.self) { w in
                        Button {
                            engine.audio.speakEnglish(w, slow: engine.progress.tts.slow)
                        } label: {
                            HStack(spacing: 4) {
                                Text("🔊")
                                    .font(.system(size: 10))
                                Text(w)
                                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#156947"))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#E8FFF5"))
                                    .overlay(Capsule().stroke(Color(hex: "#2FB380").opacity(0.4), lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#F9FFFC"))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#2FB380").opacity(0.25), lineWidth: 1.2))
        )
    }

    // MARK: - 右栏：根据题型自适应（数学双模式答题台 / 英语选项与鲜果积木台）
    private var rightInteractiveColumn: some View {
        let q = engine.currentCurriculumQuestion

        return VStack(alignment: .leading, spacing: 12) {
            if let q = q {
                if q.type == "numeric" && engine.currentSubject == .math {
                    mathNumericDualPanel(q)
                } else if q.type == "sentence" {
                    englishSentenceFruitBlocksPanel(q)
                } else {
                    multipleChoiceCardsPanel(q)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(themeColor.opacity(0.25), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }

    // MARK: - 1. 数学填空题：4 张快捷甜点选项卡 + 烘焙数字键盘双模式
    private func mathNumericDualPanel(_ q: CurriculumQuestion) -> some View {
        let dessertIcons = ["🧁", "🍰", "🥐", "🍩"]

        return VStack(alignment: .leading, spacing: 12) {
            // 上半区：4 张智能甜点答案卡（点一下直接交卷）
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🍰 方式一：直接点选正确的甜点答案卡")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "#7A1C3E"))
                    Spacer()
                    Text("iPad 点一下即出炉")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(Array(engine.numericSmartOptions.enumerated()), id: \.offset) { idx, opt in
                        let isRightAnswer = (opt == q.answer)
                        let isPicked = (engine.pickedChoiceOption == opt)
                        let showGood = (engine.judgeState == "good" && isRightAnswer)
                        let showHintRight = (engine.judgeState == "bad" && isRightAnswer)

                        Button {
                            engine.selectCurriculumChoice(opt)
                        } label: {
                            HStack(spacing: 10) {
                                Text(dessertIcons[idx % dessertIcons.count])
                                    .font(.system(size: 26))
                                Text(opt)
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .foregroundColor(
                                        showGood || showHintRight ? Color(hex: "#2B7F4A") : Color(hex: "#4A2E14")
                                    )
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        showGood || showHintRight ? Color(hex: "#E6F7ED") :
                                            (isPicked ? Color(hex: "#FFE4EE") : Color(hex: "#FFF9FC"))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                showGood || showHintRight ? Color(hex: "#3EA865") :
                                                    Color(hex: "#E05385").opacity(0.38),
                                                lineWidth: showGood || showHintRight ? 2.5 : 1.8
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // 下半区：烘焙师计算器数字盘（支持手算输入与 Mac 键盘 0~9 + Return）
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🔢 方式二：用烘焙数字盘自己输入答案")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "#7A1C3E"))
                    Spacer()
                    Text("支持 Mac 键盘 0~9 与回车键")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }

                // 数字显示屏 + 退格 + 确认烘焙
                HStack(spacing: 10) {
                    HStack {
                        Text("烘焙温度计：")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                        Text(engine.numericInput.isEmpty ? "请按数字..." : engine.numericInput)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(engine.numericInput.isEmpty ? Color.gray.opacity(0.5) : Color(hex: "#E03E6D"))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "#FFF5F8"))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#E05385"), lineWidth: 2))
                    )

                    Button {
                        engine.deleteNumericDigit()
                    } label: {
                        Text("⌫ 退格")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Color(hex: "#5A4634"))
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#F5EFE6")))
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.submitNumericInput()
                    } label: {
                        Text("✨ 确认烘焙")
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(engine.numericInput.isEmpty ? Color.gray.opacity(0.4) : Color(hex: "#E05385"))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.numericInput.isEmpty)
                }

                // 0~9 烘焙数字按键网格 (5列 × 2行)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                    ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 0], id: \.self) { num in
                        Button {
                            engine.appendNumericDigit("\(num)")
                        } label: {
                            Text("\(num)")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#4A2E14"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E05385").opacity(0.32), lineWidth: 1.5))
                                        .shadow(color: Color.black.opacity(0.04), radius: 2, y: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 2. 数学 / 英语选择题大卡片面板
    private func multipleChoiceCardsPanel(_ q: CurriculumQuestion) -> some View {
        let icons = engine.currentSubject == .math
            ? ["🧁", "🍰", "🥐", "🍪"]
            : ["🍹", "🍓", "🍊", "🍑"]

        let opts = engine.displayOptions.isEmpty ? q.options : engine.displayOptions

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(engine.currentSubject == .math ? "🧁 请点选正确的烘焙配方卡片" : "🧃 请点选正确的牛津英语特调卡片")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color(hex: "#3B2E22"))
                Spacer()
                Text("可按键盘数字 1~\(opts.count) 快速选择")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            VStack(spacing: 12) {
                ForEach(Array(opts.enumerated()), id: \.offset) { idx, opt in
                    let isRight = (opt == q.answer)
                    let isPicked = (engine.pickedChoiceOption == opt)
                    let showGood = (engine.judgeState == "good" && isRight)
                    let showHintRight = (engine.judgeState == "bad" && isRight)
                    let showWrongPick = (engine.judgeState == "bad" && isPicked && !isRight)

                    Button {
                        engine.selectCurriculumChoice(opt)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(themeColor.opacity(0.15))
                                    .frame(width: 42, height: 42)
                                Text("\(idx + 1)")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(themeColor)
                            }

                            Text(icons[idx % icons.count])
                                .font(.system(size: 26))

                            Text(opt)
                                .font(.system(size: 21, weight: .heavy, design: .rounded))
                                .foregroundColor(
                                    showGood || showHintRight ? Color(hex: "#2B7F4A") :
                                        (showWrongPick ? Color(hex: "#E25247") : Color(hex: "#3B2E22"))
                                )
                                .multilineTextAlignment(.leading)

                            Spacer()

                            // 独立发音试听小喇叭
                            Button {
                                let hasLatin = opt.range(of: "[A-Za-z]", options: .regularExpression) != nil
                                if hasLatin {
                                    engine.audio.speakEnglish(opt, slow: engine.progress.tts.slow)
                                } else {
                                    engine.audio.speakText(opt, slow: engine.progress.tts.slow)
                                }
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(themeColor)
                                    .padding(9)
                                    .background(Circle().fill(Color.white))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    showGood || showHintRight ? Color(hex: "#E6F7ED") :
                                        (showWrongPick ? Color(hex: "#FDECEB") : Color(hex: "#FCF9F5"))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            showGood || showHintRight ? Color(hex: "#3EA865") :
                                                (showWrongPick ? Color(hex: "#E25247") : themeColor.opacity(0.35)),
                                            lineWidth: (showGood || showHintRight || showWrongPick) ? 2.6 : 1.8
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 3. 英语鲜果句子积木拼接面板
    private func englishSentenceFruitBlocksPanel(_ q: CurriculumQuestion) -> some View {
        let fruitEmojis = ["🍓", "🍊", "🍑", "🍎", "🍋", "🍇", "🍍", "🥝"]
        let order = engine.sentenceDisplayOrder.isEmpty ? Array(0..<q.options.count) : engine.sentenceDisplayOrder

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("🧱 鲜果句子积木台（点击单词块投入左侧料理杯）")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Color(hex: "#156947"))
                    Text("点击每个英文单词都会朗读发音，把所有果粒按顺序放进料理杯即可自动榨汁判题！")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 230), spacing: 12)], spacing: 12) {
                ForEach(Array(order.enumerated()), id: \.offset) { displayIdx, optIdx in
                    let word = q.options[optIdx]
                    let isPicked = engine.sentencePickedIndices.contains(optIdx)
                    let orderNum = (engine.sentencePickedIndices.firstIndex(of: optIdx) ?? -1) + 1

                    Button {
                        engine.toggleSentenceBlock(at: optIdx)
                    } label: {
                        HStack(spacing: 10) {
                            Text(fruitEmojis[displayIdx % fruitEmojis.count])
                                .font(.system(size: 26))
                            Text(word)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(isPicked ? Color(hex: "#2FB380") : Color(hex: "#156947"))
                            Spacer()
                            if isPicked {
                                Text("#\(orderNum)")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color(hex: "#2FB380")))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isPicked ? Color(hex: "#E8FFF5").opacity(0.55) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(isPicked ? Color(hex: "#2FB380") : Color(hex: "#2FB380").opacity(0.45), lineWidth: isPicked ? 2.5 : 1.8)
                                )
                                .shadow(color: Color.black.opacity(isPicked ? 0.01 : 0.06), radius: 4, y: 3)
                        )
                        .opacity(isPicked ? 0.65 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }

            if engine.judgeState == "bad" {
                HStack(spacing: 8) {
                    Text("✅ 正确句子顺序：")
                        .font(.system(size: 13.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#2B7F4A"))
                    Text(q.answer)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#156947"))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#E6F7ED")))
            }
        }
    }

    // MARK: - Mac 键盘监听
    private func installKeyboardMonitor() {
        #if os(macOS)
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
                if event.keyCode == 51 {
                    Task { @MainActor in
                        engine.handleKeyInput("backspace")
                    }
                    return nil
                }
                if event.keyCode == 36 || event.keyCode == 76 {
                    Task { @MainActor in
                        engine.handleKeyInput("return")
                    }
                    return nil
                }
                if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                    Task { @MainActor in
                        engine.handleKeyInput(chars)
                    }
                    return nil
                }
            }
            return event
        }
        #endif
    }

    private func removeKeyboardMonitor() {
        #if os(macOS)
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        #endif
    }
}
