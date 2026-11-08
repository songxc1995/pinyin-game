import SwiftUI
import UniformTypeIdentifiers

// MARK: - 1. 闯关地图视图 (LevelMapView - 支持语数英三科切换)
public struct LevelMapView: View {
    @ObservedObject public var engine: GameEngine

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var themeColor: Color {
        Color(hex: engine.currentSubject.themeHex)
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 沪教版教材同步说明栏 + 自由选关开关
                HStack(spacing: 12) {
                    Text(engine.currentSubject == .pinyin ? "🍲" : (engine.currentSubject == .math ? "🧁" : "🧃"))
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.currentSubject.title + " · 沪教版一年级同步闯关")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Color(hex: "#3B2E22"))
                        Text(engine.currentSubject.textbookSubtitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                    Spacer()
                    Button {
                        engine.audio.sfxTap()
                        engine.progress.freeUnlockAll.toggle()
                        engine.saveProgress()
                    } label: {
                        HStack(spacing: 5) {
                            Text(engine.progress.freeUnlockAll ? "🔓 全关卡自由玩:开" : "🔒 逐关解锁模式")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(engine.progress.freeUnlockAll ? themeColor : Color(hex: "#5A4634"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(engine.progress.freeUnlockAll ? themeColor.opacity(0.14) : Color(hex: "#F5EFE6"))
                                .overlay(Capsule().stroke(themeColor.opacity(0.35), lineWidth: 1.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(themeColor.opacity(0.25), lineWidth: 1.5))
                )

                // 顶部两大特训营
                HStack(spacing: 12) {
                    let wrongCount = currentSubjectWrongCount
                    Button {
                        engine.audio.sfxTap()
                        engine.startSpecialMode(.wrong)
                    } label: {
                        HStack(spacing: 12) {
                            Text("🛠️")
                                .font(.system(size: 30))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(engine.currentSubject.shortTitle) · 错题特训营")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Color(hex: "#7A2E1D"))
                                Text(wrongCount > 0 ? "当前学科有 \(wrongCount) 道错题待攻克，点我专项突破！" : "目前 0 错题欠账！点我随机温习巩固")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#9E543E"))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(colors: [Color(hex: "#FFF3EE"), Color(hex: "#FFE4D9")], startPoint: .top, endPoint: .bottom))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#E25247").opacity(0.35), lineWidth: 1.5))
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.audio.sfxTap()
                        engine.startSpecialMode(.allstar)
                    } label: {
                        HStack(spacing: 12) {
                            Text("⚡")
                                .font(.system(size: 30))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(engine.currentSubject.shortTitle) · 名厨随机全明星挑战")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Color(hex: "#4A358E"))
                                Text("全册知识点混合随机抽题 · 通关同样送小蝴蝶！")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: "#6B57B0"))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(colors: [Color(hex: "#F5F2FF"), Color(hex: "#E6E0FF")], startPoint: .top, endPoint: .bottom))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#7A6EE6").opacity(0.35), lineWidth: 1.5))
                        )
                    }
                    .buttonStyle(.plain)
                }

                // 学科关卡网格（Mac/iPad 横屏自适应）
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 295, maximum: 450), spacing: 12)], spacing: 12) {
                    switch engine.currentSubject {
                    case .pinyin:
                        ForEach(LevelRepository.levels) { lv in
                            pinyinLevelCard(lv)
                        }
                    case .math:
                        ForEach(HujiaoCurriculumRepository.mathStages) { stg in
                            mathStageCard(stg)
                        }
                    case .english:
                        ForEach(HujiaoCurriculumRepository.englishStages) { stg in
                            englishStageCard(stg)
                        }
                    }
                }

                // 趣味玩法指南
                HStack(alignment: .top, spacing: 10) {
                    Text("🎯")
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(engine.currentSubject.title) · 趣味玩法指南")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#5A3818"))
                        Text(subjectGuideText)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Color(hex: "#7A624B"))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#FFF8EB"))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(themeColor.opacity(0.25), lineWidth: 1.5))
                )
            }
            .padding(.vertical, 4)
        }
    }

    private var currentSubjectWrongCount: Int {
        switch engine.currentSubject {
        case .pinyin:
            return engine.progress.wrong.filter { !$0.key.hasPrefix("hjm_") && !$0.key.hasPrefix("hje_") && $0.value > 0 }.count
        case .math:
            return engine.progress.wrong.filter { $0.key.hasPrefix("hjm_") && $0.value > 0 }.count
        case .english:
            return engine.progress.wrong.filter { $0.key.hasPrefix("hje_") && $0.value > 0 }.count
        }
    }

    private var subjectGuideText: String {
        switch engine.currentSubject {
        case .pinyin:
            return "听森林小动物顾客点菜，先选蓝色声母，再选橙色无调韵母，最后撒上「四声调料瓶」咕嘟一声就煮出汉字啦！支持 iPad 手指拖拽下锅与 Mac 键盘盲打快捷键。"
        case .math:
            return "同步沪教版一年级数学上/下册！每道题自动配备双轨十格阵、分与合三角树、数墙金字塔、滴答钟表或厘米直尺教具，既可直接点选甜点答案卡，也可按烘焙数字盘输入。"
        case .english:
            return "同步沪教牛津上海版一年级英语！支持美式发音点读、慢速跟读与鲜果单词块拼句（把单词果粒按顺序放进料理杯即可榨出美味果饮），闯关还能收集 62 张有声单词闪卡！"
        }
    }

    // MARK: - 语文拼音关卡卡片
    private func pinyinLevelCard(_ lv: LevelDefinition) -> some View {
        let locked = !engine.progress.freeUnlockAll && (lv.id > engine.progress.unlocked)
        let stars = engine.progress.starsForLevel(lv.id)
        let gotWords = lv.words.filter { (engine.progress.food[$0.character] ?? 0) > 0 }.count
        let pct = lv.words.isEmpty ? 0.0 : Double(gotWords) / Double(lv.words.count)

        let badgeColor: Color = lv.mode == .whole
            ? Color(hex: "#7A6EE6")
            : (lv.mode == .tri ? Color(hex: "#3EA865") : Color(hex: "#F07D2E"))

        return Button {
            guard !locked else { return }
            engine.audio.sfxTap()
            engine.firePickerLevel = lv.id
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(locked ? Color.gray.opacity(0.18) : badgeColor.opacity(0.16))
                        .frame(width: 48, height: 48)
                    Text(locked ? "🔒" : "\(lv.id)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(locked ? .gray : badgeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(lv.shortName)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Color(hex: "#3B2E22"))
                    Text(lv.subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .lineLimit(1)
                    if let tip = lv.tip {
                        Text("💡 \(tip)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#B25614"))
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    if !locked {
                        Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#F5A623"))
                    }
                    Text(locked ? "先过上一关" : "已收 \(gotWords)/\(lv.words.count) 字")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))

                    if !locked {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.black.opacity(0.08))
                                Capsule().fill(badgeColor).frame(width: g.size.width * pct)
                            }
                        }
                        .frame(width: 78, height: 6)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(locked ? Color.black.opacity(0.08) : badgeColor.opacity(0.32), lineWidth: 1.8)
                    )
                    .shadow(color: Color.black.opacity(locked ? 0.02 : 0.06), radius: 5, y: 3)
            )
            .opacity(locked ? 0.58 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 沪教数学关卡卡片
    private func mathStageCard(_ stg: MathStageDefinition) -> some View {
        let locked = !engine.progress.freeUnlockAll && (stg.id > engine.progress.mathUnlocked)
        let stars = engine.progress.starsForLevel(stg.id, subject: .math)
        let stageQuestions = HujiaoCurriculumRepository.questionsForMathStage(stg.id)
        let gotDesserts = stg.dessertIds.filter { (engine.progress.desserts[$0] ?? 0) > 0 }.count
        let pct = stg.dessertIds.isEmpty ? 0.0 : Double(gotDesserts) / Double(stg.dessertIds.count)
        let badgeColor = Color(hex: "#E05385")

        return Button {
            guard !locked else { return }
            engine.audio.sfxTap()
            engine.firePickerLevel = stg.id
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(locked ? Color.gray.opacity(0.18) : badgeColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Text(locked ? "🔒" : "🧁\(stg.id)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(locked ? .gray : badgeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(stg.name)
                            .font(.system(size: 15.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#3B2E22"))
                            .lineLimit(1)
                        Text(stg.semesterTag)
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(badgeColor))
                    }
                    Text(stg.subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .lineLimit(1)
                    Text("💡 \(stg.tip)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#B8336A"))
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    if !locked {
                        Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#F5A623"))
                    }
                    Text("题库 \(stageQuestions.count) 题 · 甜点 \(gotDesserts)/\(stg.dessertIds.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))

                    if !locked {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.black.opacity(0.08))
                                Capsule().fill(badgeColor).frame(width: g.size.width * pct)
                            }
                        }
                        .frame(width: 78, height: 6)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(locked ? Color.black.opacity(0.08) : badgeColor.opacity(0.32), lineWidth: 1.8)
                    )
                    .shadow(color: Color.black.opacity(locked ? 0.02 : 0.06), radius: 5, y: 3)
            )
            .opacity(locked ? 0.58 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 牛津英语关卡卡片
    private func englishStageCard(_ stg: EnglishStageDefinition) -> some View {
        let locked = !engine.progress.freeUnlockAll && (stg.id > engine.progress.englishUnlocked)
        let stars = engine.progress.starsForLevel(stg.id, subject: .english)
        let stageQuestions = HujiaoCurriculumRepository.questionsForEnglishStage(stg.id)
        let stageFlashcards = HujiaoCurriculumRepository.flashcards(forEnglishStage: stg.id)
        let gotCards = stageFlashcards.filter { (engine.progress.englishCards[$0.word] ?? 0) > 0 }.count
        let pct = stageFlashcards.isEmpty ? 0.0 : Double(gotCards) / Double(stageFlashcards.count)
        let badgeColor = Color(hex: "#2FB380")

        return Button {
            guard !locked else { return }
            engine.audio.sfxTap()
            engine.firePickerLevel = stg.id
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(locked ? Color.gray.opacity(0.18) : badgeColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Text(locked ? "🔒" : "🧃\(stg.id)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(locked ? .gray : badgeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(stg.name)
                            .font(.system(size: 15.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#3B2E22"))
                            .lineLimit(1)
                        Text(stg.unitCode)
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(badgeColor))
                    }
                    Text(stg.subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .lineLimit(1)
                    Text("🗣️ 句型：\(stg.keySentences.first ?? "")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#156947"))
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    if !locked {
                        Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#F5A623"))
                    }
                    Text("题库 \(stageQuestions.count) 题 · 闪卡 \(gotCards)/\(stageFlashcards.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))

                    if !locked {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.black.opacity(0.08))
                                Capsule().fill(badgeColor).frame(width: g.size.width * pct)
                            }
                        }
                        .frame(width: 78, height: 6)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(locked ? Color.black.opacity(0.08) : badgeColor.opacity(0.32), lineWidth: 1.8)
                    )
                    .shadow(color: Color.black.opacity(locked ? 0.02 : 0.06), radius: 5, y: 3)
            )
            .opacity(locked ? 0.58 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 2. 语数英三合一料理图鉴馆 (RecipeBookView)
public struct RecipeBookView: View {
    @ObservedObject public var engine: GameEngine
    @State private var bookKind: SubjectKind = .pinyin
    @State private var filter: String = "all" // "all", "got", "todo"
    @State private var selectedChar: String? = "妈"
    @State private var selectedDessert: BakeryDessert = HujiaoCurriculumRepository.bakeryDesserts[0]
    @State private var selectedFlashcard: EnglishFlashcard = HujiaoCurriculumRepository.englishFlashcards[0]

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 三馆切换横幅
                HStack(spacing: 10) {
                    subBookTab(
                        kind: .pinyin,
                        title: "📖 中华小菜谱 (\(engine.progress.foodCount)/\(LevelRepository.allUniqueCharacters.count)字)",
                        color: Color(hex: "#F07D2E")
                    )
                    subBookTab(
                        kind: .math,
                        title: "🍰 梦幻甜点柜 (\(engine.progress.dessertCount)/\(HujiaoCurriculumRepository.bakeryDesserts.count)款)",
                        color: Color(hex: "#E05385")
                    )
                    subBookTab(
                        kind: .english,
                        title: "🍹 牛津英语闪卡 (\(engine.progress.englishCardCount)/\(HujiaoCurriculumRepository.englishFlashcards.count)张)",
                        color: Color(hex: "#2FB380")
                    )
                }

                switch bookKind {
                case .pinyin:
                    pinyinRecipeContent
                case .math:
                    mathDessertCabinetContent
                case .english:
                    englishFlashcardBarContent
                }
            }
        }
        .onAppear {
            bookKind = engine.currentSubject
        }
        .onChange(of: engine.currentSubject) { newValue in
            bookKind = newValue
        }
    }

    private func subBookTab(kind: SubjectKind, title: String, color: Color) -> some View {
        let on = (bookKind == kind)
        return Button {
            engine.audio.sfxTap()
            bookKind = kind
        } label: {
            Text(title)
                .font(.system(size: 13.5, weight: .heavy))
                .foregroundColor(on ? .white : Color(hex: "#4A2E14"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(on ? color : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.35), lineWidth: 1.5))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2A. 语文拼音中华小菜谱
    private var pinyinRecipeContent: some View {
        let allChars = LevelRepository.allUniqueCharacters
        let gotChars = allChars.filter { (engine.progress.food[$0] ?? 0) > 0 }
        let filteredChars = allChars.filter { ch in
            if filter == "got" { return (engine.progress.food[ch] ?? 0) > 0 }
            if filter == "todo" { return (engine.progress.food[ch] ?? 0) == 0 }
            return true
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("📖 我的中华小菜谱（沪教一年级识字与拼音点读）")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Color(hex: "#3B2E22"))
                    Text("点击任意汉字可听标准普通话发音与组词，已端上菜谱 \(gotChars.count) / \(allChars.count) 个字")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                HStack(spacing: 6) {
                    filterButton(key: "all", label: "全部 (\(allChars.count))")
                    filterButton(key: "got", label: "已上菜 (\(gotChars.count))")
                    filterButton(key: "todo", label: "待解锁 (\(allChars.count - gotChars.count))")
                }
            }

            if let ch = selectedChar {
                let h = LevelRepository.hint(for: ch)
                let readings = LevelRepository.readings(of: ch).joined(separator: " / ")
                let lv = LevelRepository.firstLevel(for: ch)
                HStack(spacing: 16) {
                    Text(ch)
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .frame(width: 68, height: 68)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(readings)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "#F07D2E"))
                        Text("\(h.emoji) \(h.phrase)（第 \(lv) 关）")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#5A4634"))
                    }

                    Spacer()

                    Button {
                        engine.audio.speakText("\(ch)，\(h.phrase)", slow: engine.progress.tts.slow)
                    } label: {
                        Label("点读发音", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#F07D2E")))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#FFF6E8"))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F07D2E").opacity(0.35), lineWidth: 1.5))
                )
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56, maximum: 68), spacing: 8)], spacing: 8) {
                ForEach(filteredChars, id: \.self) { ch in
                    let isGot = (engine.progress.food[ch] ?? 0) > 0
                    let h = LevelRepository.hint(for: ch)
                    Button {
                        selectedChar = ch
                        engine.audio.sfxTap()
                        engine.audio.speakText("\(ch)，\(h.phrase)", slow: engine.progress.tts.slow)
                    } label: {
                        VStack(spacing: 2) {
                            Text(ch)
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(isGot ? Color(hex: "#3B2E22") : Color.gray.opacity(0.55))
                            Text(h.emoji)
                                .font(.system(size: 12))
                                .opacity(isGot ? 1.0 : 0.45)
                        }
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 13)
                                .fill(isGot ? (selectedChar == ch ? Color(hex: "#FFF0D6") : Color.white) : Color(hex: "#F7F3EC"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(selectedChar == ch ? Color(hex: "#F07D2E") : Color.black.opacity(0.08), lineWidth: selectedChar == ch ? 2.2 : 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.92)))
    }

    // MARK: - 2B. 沪教数学梦幻甜点柜（含 30 条一年级算理口诀）
    private var mathDessertCabinetContent: some View {
        let allDesserts = HujiaoCurriculumRepository.bakeryDesserts
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🍰 梦幻数学甜点柜（30款甜点 + 沪教一年级算理口诀）")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Color(hex: "#3B2E22"))
                Text("点击任意甜点即可听小熊烘焙师朗读它背后的数学算理秘籍！")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            // 选中甜点详情卡
            HStack(spacing: 16) {
                Text(selectedDessert.emoji)
                    .font(.system(size: 46))
                    .frame(width: 70, height: 70)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(selectedDessert.name)
                            .font(.system(size: 19, weight: .black))
                            .foregroundColor(Color(hex: "#7A1C3E"))
                        Text("第 \(selectedDessert.stageId) 关甜点")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#E05385")))
                    }
                    Text("💡 算理秘籍：\(selectedDessert.mathSecret)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#4A2E14"))
                }

                Spacer()

                Button {
                    engine.audio.speakText("\(selectedDessert.name)。算理秘籍：\(selectedDessert.mathSecret)", slow: engine.progress.tts.slow)
                } label: {
                    Label("听算理口诀", systemImage: "speaker.wave.2.fill")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#E05385")))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#FFF4F8"))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E05385").opacity(0.35), lineWidth: 1.5))
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 10)], spacing: 10) {
                ForEach(allDesserts) { item in
                    let isGot = (engine.progress.desserts[item.id] ?? 0) > 0
                    let isSelected = (selectedDessert.id == item.id)

                    Button {
                        selectedDessert = item
                        engine.audio.sfxTap()
                        engine.audio.speakText("\(item.name)，\(item.mathSecret)", slow: engine.progress.tts.slow)
                    } label: {
                        VStack(spacing: 6) {
                            Text(item.emoji)
                                .font(.system(size: 36))
                            Text(item.name)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(Color(hex: "#3B2E22"))
                            Text(isGot ? "✓ 已烘焙出炉" : "第 \(item.stageId) 关可收集")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isGot ? Color(hex: "#2B7F4A") : Color(hex: "#E05385"))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSelected ? Color(hex: "#FFE8F0") : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isSelected ? Color(hex: "#E05385") : Color.black.opacity(0.08), lineWidth: isSelected ? 2.2 : 1.2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.92)))
    }

    // MARK: - 2C. 沪教牛津上海版一年级有声英语闪卡吧（62 张核心词汇+双语例句）
    private var englishFlashcardBarContent: some View {
        let cards = HujiaoCurriculumRepository.englishFlashcards
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🍹 牛津特调有声闪卡吧（沪教牛津上海版一年级核心词汇与例句）")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Color(hex: "#3B2E22"))
                Text("点击任意鲜果单词卡即可听纯正英语发音与课本例句！")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            // 选中闪卡双语点读台
            HStack(spacing: 16) {
                Text(selectedFlashcard.emoji)
                    .font(.system(size: 46))
                    .frame(width: 72, height: 72)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(selectedFlashcard.word)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#156947"))
                        Text(selectedFlashcard.chinese)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#4A2E14"))
                        Text(selectedFlashcard.unitName)
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#2FB380")))
                    }
                    Text("🗣️ 例句：\(selectedFlashcard.example)  （\(selectedFlashcard.exampleCn)）")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(hex: "#5A4634"))
                }

                Spacer()

                VStack(spacing: 6) {
                    Button {
                        engine.audio.speakEnglish("\(selectedFlashcard.word). \(selectedFlashcard.example)", slow: engine.progress.tts.slow)
                    } label: {
                        Label("🇬🇧 读单词与例句", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 11).fill(Color(hex: "#2FB380")))
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.audio.speakBilingual(
                            english: "\(selectedFlashcard.word). \(selectedFlashcard.example)",
                            chinese: "\(selectedFlashcard.chinese)。\(selectedFlashcard.exampleCn)",
                            slow: engine.progress.tts.slow
                        )
                    } label: {
                        Text("🇨🇳 双语慢读跟学")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#156947"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#E8FFF5"))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#2FB380").opacity(0.4), lineWidth: 1.5))
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145, maximum: 190), spacing: 10)], spacing: 10) {
                ForEach(cards) { card in
                    let isGot = (engine.progress.englishCards[card.word] ?? 0) > 0
                    let isSelected = (selectedFlashcard.word == card.word)

                    Button {
                        selectedFlashcard = card
                        engine.audio.sfxTap()
                        engine.audio.speakEnglish("\(card.word). \(card.example)", slow: engine.progress.tts.slow)
                    } label: {
                        VStack(spacing: 4) {
                            Text(card.emoji)
                                .font(.system(size: 28))
                            Text(card.word)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#156947"))
                            Text(card.chinese)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#5A4634"))
                            Text(isGot ? "✓ 已调制" : card.unitName)
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(isGot ? Color(hex: "#2FB380") : Color(hex: "#8A7765"))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(isSelected ? Color(hex: "#E8FFF5") : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(isSelected ? Color(hex: "#2FB380") : Color.black.opacity(0.08), lineWidth: isSelected ? 2.2 : 1.2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.92)))
    }

    private func filterButton(key: String, label: String) -> some View {
        Button {
            engine.audio.sfxTap()
            filter = key
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(filter == key ? .white : Color(hex: "#5A4634"))
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(filter == key ? Color(hex: "#F07D2E") : Color(hex: "#F5EFE6"))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 3. 奇妙蝴蝶生态花园 (ButterflyGardenView)
public struct ButterflyGardenView: View {
    @ObservedObject public var engine: GameEngine
    @State private var gardenTip: String = "✨ 点一点花丛中飞舞的小蝴蝶，它会向你跳舞并报出名字哦！"
    @State private var actorOffsets: [Int: CGSize] = [:]

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        let uniqueCollected = Set(engine.progress.bf.map(\.t)).count
        let maxEvolvedCount = ButterflySpecies.all.filter { engine.progress.butterflyStage(for: $0.id) >= 3 }.count
        let recentFlies = Array(engine.progress.bf.suffix(8))

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("🦋 奇妙蝴蝶生态花园（语数英三科通关共享奖励）")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(Color(hex: "#3B2E22"))
                            Text("一共 \(engine.progress.bf.count) 只 · 已认识 \(uniqueCollected) / \(ButterflySpecies.all.count) 种" + (maxEvolvedCount > 0 ? " · 完全进化 \(maxEvolvedCount) 种" : ""))
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(Color(hex: "#8A7765"))
                        }
                        Spacer()
                    }

                    // 互动花园舞台
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#D4F1FF"), Color(hex: "#E8F9E9"), Color(hex: "#C5EFA0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 185)

                        Circle()
                            .fill(Color(hex: "#FFD54F"))
                            .frame(width: 42, height: 42)
                            .shadow(color: Color(hex: "#FFB300").opacity(0.5), radius: 10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(16)

                        Text(gardenTip)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#2E5A36"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.82)))
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding(.top, 10)

                        if recentFlies.isEmpty {
                            Text("🌱 花园还在等第一只小蝴蝶，快去闯关吧！")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(Color(hex: "#3B6E45"))
                                .frame(maxHeight: .infinity)
                        } else {
                            GeometryReader { geo in
                                ForEach(Array(recentFlies.enumerated()), id: \.element.id) { idx, item in
                                    let sp = ButterflySpecies.byId(item.t)
                                    let st = engine.progress.butterflyStage(for: sp.id)
                                    let baseX = geo.size.width * CGFloat(0.14 + Double((idx * 13) % 72) / 100.0)
                                    let baseY = geo.size.height * CGFloat(0.28 + Double((idx * 19) % 45) / 100.0)
                                    let extra = actorOffsets[idx] ?? .zero

                                    Button {
                                        engine.audio.sfxSpark()
                                        engine.audio.speakText(sp.name, slow: false)
                                        withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
                                            actorOffsets[idx] = CGSize(
                                                width: CGFloat.random(in: -45...45),
                                                height: CGFloat.random(in: -25...25)
                                            )
                                        }
                                        gardenTip = "🦋 \(sp.name)（\(ButterflySpecies.stageName(for: st))）开心地向你扇了扇翅膀！"
                                    } label: {
                                        ButterflyVectorView(species: sp, stage: st, size: 48, animated: true)
                                    }
                                    .buttonStyle(.plain)
                                    .position(x: baseX + extra.width, y: baseY + extra.height)
                                }
                            }
                            .frame(height: 185)
                        }

                        HStack(spacing: 28) {
                            Text("🌷"); Text("🌻"); Text("🌸"); Text("🌼"); Text("🌺"); Text("🍀")
                        }
                        .font(.system(size: 24))
                        .padding(.bottom, 6)
                    }

                    // 20 种蝴蝶图鉴网格
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145, maximum: 185), spacing: 10)], spacing: 10) {
                        ForEach(ButterflySpecies.all) { sp in
                            let count = engine.progress.butterflyCount(for: sp.id)
                            let stage = engine.progress.butterflyStage(for: sp.id)
                            let nextNeed = engine.progress.nextStageNeed(for: sp.id)

                            Button {
                                guard count > 0 else { return }
                                engine.audio.sfxSpark()
                                engine.audio.speakText("\(sp.name)，\(ButterflySpecies.stageName(for: stage))形态", slow: false)
                            } label: {
                                VStack(spacing: 6) {
                                    if count > 0 {
                                        ButterflyVectorView(species: sp, stage: stage, size: 58, animated: false)
                                        Text(sp.name)
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(Color(hex: "#3B2E22"))
                                        Text("×\(count)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color(hex: "#8A7765"))
                                        HStack(spacing: 4) {
                                            Text(sp.rarityName)
                                                .font(.system(size: 10.5, weight: .heavy))
                                                .foregroundColor(sp.rarity == 3 ? Color(hex: "#B25614") : Color(hex: "#3685D6"))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color(hex: "#FFF0D6")))
                                            Text(ButterflySpecies.stageName(for: stage))
                                                .font(.system(size: 10.5, weight: .heavy))
                                                .foregroundColor(Color(hex: "#534AB7"))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color(hex: "#EFEFFD")))
                                        }
                                        if let need = nextNeed {
                                            Text("再收 \(max(0, need - count)) 只进化")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(Color(hex: "#8A7765"))
                                        } else {
                                            Text("已完全进化 ✨")
                                                .font(.system(size: 11, weight: .heavy))
                                                .foregroundColor(Color(hex: "#F07D2E"))
                                        }
                                    } else {
                                        Text("?")
                                            .font(.system(size: 32, weight: .black, design: .rounded))
                                            .foregroundColor(Color.gray.opacity(0.35))
                                            .frame(height: 58)
                                        Text("还没见过")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: "#8A7765"))
                                        Text(sp.rarity == 3 ? "三星大火最易遇到" : "通关就有机会")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Color.gray)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(count > 0 ? Color.white : Color(hex: "#FAF7F2"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(stage >= 3 ? Color(hex: "#F5B82E") : Color.black.opacity(0.08), lineWidth: stage >= 3 ? 2.2 : 1.2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.92)))
            }
        }
    }
}

// MARK: - 4. 成就、语数英三科错题本与记录导入导出 (RecordsAndWrongView)
public struct RecordsAndWrongView: View {
    @ObservedObject public var engine: GameEngine
    @State private var showJSONSheet: Bool = false
    @State private var jsonInputText: String = ""
    @State private var showResetConfirm: Bool = false

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        let activeWrongs = engine.progress.wrong.filter { $0.value > 0 }.sorted { $0.value > $1.value }

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 1. 跨端存档备份与重置（置顶醒目展示，iPad 一键复制/恢复/导出文件）
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("💾 存档保存与导出备份（iPad / Mac 互通）")
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundColor(Color(hex: "#3B2E22"))
                            Text("每答完一题都会自动保存在当前 iPad / Mac！如要在 iPad 更新版本或跨设备同步，请点下方按钮一键备份：")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(Color(hex: "#8A7765"))
                        }
                        Spacer()
                        Text("✅ 已开启三重自动保存")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color(hex: "#246B43"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color(hex: "#E3F6EA")))
                    }

                    if let msg = engine.importExportMessage {
                        Text(msg)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(msg.hasPrefix("❌") || msg.hasPrefix("⚠️") ? Color(hex: "#D63B2F") : Color(hex: "#2B7F4A"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#E8F6EE")))
                    }

                    HStack(spacing: 10) {
                        Button {
                            engine.copySaveToClipboard()
                        } label: {
                            Text("📋 一键复制存档码")
                                .font(.system(size: 13.5, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#F07D2E")))
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.restoreSaveFromClipboard()
                        } label: {
                            Text("📌 一键从剪贴板恢复")
                                .font(.system(size: 13.5, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#2FB380")))
                        }
                        .buttonStyle(.plain)

                        if let fileURL = engine.exportBackupFileURL() {
                            ShareLink(item: fileURL) {
                                Text("📤 导出到「文件」/ 微信")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundColor(Color(hex: "#4A358E"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#EFEFFD")))
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            engine.showBackupModal = true
                        } label: {
                            Text("📝 查看/粘贴 JSON")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(Color(hex: "#3B2E22"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF0D6")))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            showResetConfirm = true
                        } label: {
                            Text("🗑️ 清空记录")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#E25247"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FDECEB")))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.95))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#F07D2E").opacity(0.35), lineWidth: 1.5))
                )

                // 2. 语数英三科错题糊锅本
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("🔥 语数英三科错题本")
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundColor(Color(hex: "#3B2E22"))
                            Text("答错过的拼音、数学或英语题目会自动记在这里，累计已攻克 \(engine.progress.wrongMastered.count) 道错题")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#8A7765"))
                        }
                        Spacer()
                        if !activeWrongs.isEmpty {
                            Button {
                                engine.audio.sfxTap()
                                engine.startSpecialMode(.wrong)
                            } label: {
                                Text("🛠️ 去消灭当前科错题")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#F07D2E")))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if activeWrongs.isEmpty {
                        Text("🎉 太棒了！语数英三科目前都没有错题欠账，继续保持！")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(Color(hex: "#2B7F4A"))
                            .padding(.vertical, 6)
                    } else {
                        ForEach(Array(activeWrongs.prefix(12).enumerated()), id: \.offset) { _, entry in
                            wrongItemRow(key: entry.key, count: entry.value)
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.92)))

                // 3. 12 大全能厨神成就徽章
                VStack(alignment: .leading, spacing: 10) {
                    Text("🏅 奇妙料理城 · 全能成就徽章")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(Color(hex: "#3B2E22"))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 340), spacing: 10)], spacing: 10) {
                        ForEach(BadgeDefinition.all) { badge in
                            let unlocked = badge.check(engine.progress)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(unlocked ? badge.title : "🔒 未解锁 · \(badge.title)")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(unlocked ? Color(hex: "#4A2E14") : Color.gray)
                                Text(badge.desc)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#8A7765"))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(unlocked ? Color(hex: "#FFF5E4") : Color(hex: "#FAF7F2"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(unlocked ? Color(hex: "#F07D2E").opacity(0.45) : Color.black.opacity(0.08), lineWidth: 1.5)
                                    )
                            )
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.92)))
            }
        }
        .sheet(isPresented: $showJSONSheet) {
            VStack(alignment: .leading, spacing: 12) {
                Text("💾 存档 JSON 导出与导入")
                    .font(.system(size: 18, weight: .heavy))
                Text("下方是当前存档的 JSON 内容。你可以全选复制保存，或者将备份 JSON 粘贴到下方并点击「合并导入记录」：")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                TextEditor(text: $jsonInputText)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(minHeight: 240)
                    .border(Color.gray.opacity(0.3))

                HStack {
                    Button("关闭") {
                        showJSONSheet = false
                    }
                    Spacer()
                    Button("合并导入记录") {
                        if let data = jsonInputText.data(using: .utf8) {
                            engine.importExportMessage = engine.importJSONData(data)
                        }
                        showJSONSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .frame(minWidth: 520, minHeight: 380)
        }
        .alert("确定清空所有星星、图鉴、蝴蝶和记录吗？", isPresented: $showResetConfirm) {
            Button("取消", role: .cancel) {}
            Button("确定清空", role: .destructive) {
                engine.resetAllProgress()
            }
        } message: {
            Text("清空后不能恢复，建议清空前先导出一份 JSON 备份。")
        }
    }

    @ViewBuilder
    private func wrongItemRow(key: String, count: Int) -> some View {
        if key.hasPrefix("hjm_") || key.hasPrefix("hje_") {
            if let q = HujiaoCurriculumRepository.allQuestions.first(where: { $0.id == key }) {
                let isMath = key.hasPrefix("hjm_")
                Button {
                    engine.audio.speakText("\(q.prompt)，正确答案是 \(q.answer)", slow: false)
                } label: {
                    HStack(spacing: 10) {
                        Text(isMath ? "🧁 数学" : "🧃 英语")
                            .font(.system(size: 11.5, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: isMath ? "#E05385" : "#2FB380")))
                        Text(q.prompt)
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(Color(hex: "#3B2E22"))
                            .lineLimit(1)
                        Spacer()
                        Text("答案: \(q.answer)")
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#2B7F4A"))
                        Text("错 \(count) 次 🔊")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color(hex: "#E25247"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF8EE")))
                }
                .buttonStyle(.plain)
            }
        } else {
            let p = key.split(separator: "|").map(String.init)
            if p.count >= 3 {
                let lv = Int(p[0]) ?? 1
                let py = p[1]
                let ch = p[2]
                let h = LevelRepository.hint(for: ch)
                Button {
                    engine.audio.speakText("\(ch)，\(h.phrase)", slow: false)
                } label: {
                    HStack(spacing: 12) {
                        Text("🍲 拼音")
                            .font(.system(size: 11.5, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: "#F07D2E")))
                        Text(ch)
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(Color(hex: "#3B2E22"))
                        Text("\(py)（\(h.emoji) \(h.phrase) · 第 \(lv) 关）")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(Color(hex: "#5A4634"))
                        Spacer()
                        Text("错 \(count) 次 🔊")
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#E25247"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF8EE")))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 5. 局末结算庆祝视图 (RoundResultView - 支持语数英三科奖励展示 + 三选一神秘宝箱)
public struct RoundResultView: View {
    @ObservedObject public var engine: GameEngine
    @State private var chestWiggle: Bool = false

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        let total = engine.totalQuestionCountInRound
        let r = engine.rightCount
        let st = engine.roundStars
        let themeColor = Color(hex: engine.currentSubject.themeHex)
        let pet = engine.equippedPet
        let petStage = engine.equippedPetStage

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    GuardianPetVectorView(species: pet, stage: petStage, size: 62, animated: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(st > 0 ? "🎉 香喷喷出炉通关啦！" : "💪 差一点点，再试一次吧！")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(Color(hex: "#5E340B"))
                        Text("🪙 本局共收获 +\(engine.roundCoinsEarned) 枚料理星币（当前共 \(engine.progress.coins) 🪙 · 扭蛋券 \(engine.progress.gachaTickets) 🎟️）")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#D97706"))
                    }
                }

                Text(String(repeating: "★", count: st) + String(repeating: "☆", count: 3 - st))
                    .font(.system(size: 44, weight: .black))
                    .foregroundColor(Color(hex: "#F5A623"))
                    .shadow(color: Color(hex: "#B4640A").opacity(0.25), radius: 2, y: 3)

                Text(resultSummaryText(right: r, total: total))
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(Color(hex: "#7A624B"))
                    .multilineTextAlignment(.center)

                // 🎁 厨神惊喜盲盒 · 三选一翻牌
                if !engine.mysteryChests.isEmpty {
                    VStack(spacing: 10) {
                        Text(engine.openedChestIndex == nil ? "🎁 通关惊喜盲盒！快从下面 3 个金宝箱中点选 1 个开启大奖：" : "🎊 惊喜盲盒已开启！")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(Color(hex: "#B45309"))

                        HStack(spacing: 12) {
                            ForEach(Array(engine.mysteryChests.enumerated()), id: \.element.id) { idx, chest in
                                let isChosen = (engine.openedChestIndex == idx)
                                let isRevealed = (engine.openedChestIndex != nil)

                                Button {
                                    engine.openMysteryChest(at: idx)
                                } label: {
                                    ZStack {
                                        if isChosen {
                                            FireworkSparkBurstView(colorHex: chest.accentHex)
                                        }
                                        VStack(spacing: 5) {
                                            Text(isRevealed ? chest.emoji : "🎁")
                                                .font(.system(size: isChosen ? 36 : 32))
                                                .rotationEffect(.degrees(!isRevealed && chestWiggle ? (idx % 2 == 0 ? 6 : -6) : 0))
                                            Text(isRevealed ? chest.title : "神秘金宝箱 #\(idx + 1)")
                                                .font(.system(size: 13, weight: .heavy))
                                                .foregroundColor(isChosen ? Color(hex: "#B45309") : Color(hex: "#3B2E22"))
                                                .lineLimit(1)
                                            Text(isRevealed ? (isChosen ? "✓ 已收入囊中！" : "未选：\(chest.subtitle)") : "点我翻牌开奖 ✨")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(isChosen ? Color(hex: "#2B7F4A") : Color(hex: "#8A7765"))
                                                .lineLimit(1)
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(isChosen ? Color(hex: "#FFF8E1") : Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(
                                                            isChosen ? Color(hex: "#F5A623") : Color(hex: "#F5A623").opacity(0.38),
                                                            lineWidth: isChosen ? 2.8 : 1.5
                                                        )
                                                )
                                        )
                                        .opacity(isRevealed && !isChosen ? 0.58 : 1.0)
                                        .scaleEffect(isChosen ? 1.04 : 1.0)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(isRevealed)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FFFDF5"), Color(hex: "#FEF3C7")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#F5A623").opacity(0.55), lineWidth: 1.8))
                    )
                }

                // 1. 语文拼音：新收汉字
                if !engine.newFoodsInRound.isEmpty {
                    VStack(spacing: 8) {
                        Text("🍲 本局新端上《中华小菜谱》的汉字（点击可听发音）")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#8A7765"))
                        HStack(spacing: 8) {
                            ForEach(engine.newFoodsInRound, id: \.self) { ch in
                                let h = LevelRepository.hint(for: ch)
                                Button {
                                    engine.audio.speakText("\(ch)，\(h.phrase)", slow: false)
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(ch)
                                            .font(.system(size: 22, weight: .black))
                                            .foregroundColor(Color(hex: "#3B2E22"))
                                        Text(h.emoji)
                                            .font(.system(size: 13))
                                    }
                                    .frame(width: 54, height: 54)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#F07D2E"), lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#FFF8EE")))
                }

                // 2. 沪教数学：新收甜点
                if !engine.newDessertsInRound.isEmpty {
                    VStack(spacing: 8) {
                        Text("🧁 本局新收入《梦幻甜点柜》的数学甜点（点击听算理秘籍）")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#B8336A"))
                        HStack(spacing: 10) {
                            ForEach(engine.newDessertsInRound) { ds in
                                Button {
                                    engine.audio.speakText("\(ds.name)，\(ds.mathSecret)", slow: false)
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(ds.emoji)
                                            .font(.system(size: 24))
                                        Text(ds.name)
                                            .font(.system(size: 13.5, weight: .heavy))
                                            .foregroundColor(Color(hex: "#7A1C3E"))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E05385"), lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#FFF4F8")))
                }

                // 3. 牛津英语：新收有声闪卡
                if !engine.newFlashcardsInRound.isEmpty {
                    VStack(spacing: 8) {
                        Text("🍹 本局新收入《牛津特调闪卡吧》的单词卡（点击听英语发音）")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#156947"))
                        HStack(spacing: 10) {
                            ForEach(engine.newFlashcardsInRound) { card in
                                Button {
                                    engine.audio.speakEnglish("\(card.word). \(card.example)", slow: false)
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(card.emoji)
                                            .font(.system(size: 22))
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(card.word)
                                                .font(.system(size: 14, weight: .black, design: .rounded))
                                                .foregroundColor(Color(hex: "#156947"))
                                            Text(card.chinese)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Color(hex: "#5A4634"))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#2FB380"), lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#E8FFF5")))
                }

                // 本局蝴蝶奖励
                if !engine.rewardedButterfliesInRound.isEmpty {
                    VStack(spacing: 8) {
                        Text("🦋 通关蝴蝶奖励（点击蝴蝶听名字）")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#8A7765"))
                        HStack(spacing: 14) {
                            ForEach(Array(engine.rewardedButterfliesInRound.enumerated()), id: \.offset) { _, sp in
                                let stg = engine.progress.butterflyStage(for: sp.id)
                                Button {
                                    engine.audio.sfxSpark()
                                    engine.audio.speakText(sp.name, slow: false)
                                } label: {
                                    VStack(spacing: 4) {
                                        ButterflyVectorView(species: sp, stage: stg, size: 68, animated: true)
                                        Text(sp.name)
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundColor(Color(hex: "#3B2E22"))
                                        Text("\(sp.rarityName) · \(ButterflySpecies.stageName(for: stg))")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Color(hex: "#7A6EE6"))
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F5B82E").opacity(0.5), lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // 底部操作按钮
                HStack(spacing: 12) {
                    Button {
                        engine.audio.sfxTap()
                        if let sp = engine.specialMode {
                            engine.startSpecialMode(sp)
                        } else {
                            engine.firePickerLevel = engine.currentLevelNumber
                            engine.screenState = .home
                        }
                    } label: {
                        Text("🔄 再来一局")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 14).fill(themeColor))
                    }
                    .buttonStyle(.plain)

                    if engine.specialMode == nil && engine.currentLevelNumber < engine.currentMaxStageCount {
                        Button {
                            engine.audio.sfxTap()
                            let nextLv = min(engine.currentMaxStageCount, engine.currentLevelNumber + 1)
                            engine.firePickerLevel = nextLv
                            engine.screenState = .home
                        } label: {
                            Text("下一关 →")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#3EA865")))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        engine.audio.sfxTap()
                        engine.activeTab = .paradise
                        engine.goHome()
                    } label: {
                        Text("🎰 去扭蛋抽神兽")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#E63946")))
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.audio.sfxTap()
                        engine.goHome()
                    } label: {
                        Text("🏠 返回选关")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Color(hex: "#3B2E22"))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.15), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 720)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [Color.white, Color(hex: "#FFF7EB")], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(themeColor.opacity(0.35), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)
            )
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.24).repeatForever(autoreverses: true)) {
                chestWiggle = true
            }
        }
    }

    private func resultSummaryText(right: Int, total: Int) -> String {
        var s = "本局答对 \(right) / \(total) 道题"
        if engine.masteredCount > 0 {
            s += "，成功消灭了 \(engine.masteredCount) 道以前错过的题！"
        }
        if right >= 4 {
            let count = engine.rewardedButterfliesInRound.count
            s += count > 1 ? "，太棒了，飞来了 \(count) 只漂亮的小蝴蝶！" : "，吸引来了一只漂亮的小蝴蝶！"
        } else {
            s += "，答对 4 道题就有小蝴蝶飞过来哦！"
        }
        return s
    }
}
