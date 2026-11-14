import SwiftUI
import UniformTypeIdentifiers

// MARK: - 1. 闯关地图视图 (LevelMapView - 支持语数英三科切换 + 学期筛选 + 防刷奖励状态提示)
public struct LevelMapView: View {
    @ObservedObject public var engine: GameEngine
    @State private var mathSemesterFilter: MathSemesterFilter = .all
    @State private var englishSemesterFilter: EnglishSemesterFilter = .all
    @State private var pinyinStageFilter: PinyinStageFilter = .all

    private enum MathSemesterFilter: String, CaseIterable, Identifiable {
        case all = "全部"
        case grade1A = "一年级上册"
        case grade1B = "一年级下册"
        case ext = "趣味拓展"

        var id: String { rawValue }

        var semester: CurriculumSemester? {
            switch self {
            case .all:     return nil
            case .grade1A: return .grade1A
            case .grade1B: return .grade1B
            case .ext:     return .extensionChallenge
            }
        }
    }

    private enum EnglishSemesterFilter: String, CaseIterable, Identifiable {
        case all = "全部"
        case grade1A = "1A 一上"
        case grade1B = "1B 一下"

        var id: String { rawValue }

        var semester: CurriculumSemester? {
            switch self {
            case .all:     return nil
            case .grade1A: return .grade1A
            case .grade1B: return .grade1B
            }
        }
    }

    private enum PinyinStageFilter: String, CaseIterable, Identifiable {
        case all = "全部"
        case split = "两拼声韵"
        case whole = "整体认读"
        case tri = "三拼音节"

        var id: String { rawValue }

        var mode: LevelMode? {
            switch self {
            case .all:   return nil
            case .split: return .split
            case .whole: return .whole
            case .tri:   return .tri
            }
        }
    }

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var themeColor: Color {
        Color(hex: engine.currentSubject.themeHex)
    }

    private var filteredPinyinLevels: [LevelDefinition] {
        guard let mode = pinyinStageFilter.mode else {
            return LevelRepository.levels
        }
        return LevelRepository.levels.filter { $0.mode == mode }
    }

    private var filteredMathStages: [MathStageDefinition] {
        guard let sem = mathSemesterFilter.semester else {
            return HujiaoCurriculumRepository.mathStages
        }
        return HujiaoCurriculumRepository.mathStages.filter { $0.semester == sem }
    }

    private var filteredEnglishStages: [EnglishStageDefinition] {
        guard let sem = englishSemesterFilter.semester else {
            return HujiaoCurriculumRepository.englishStages
        }
        return HujiaoCurriculumRepository.englishStages.filter { $0.semester == sem }
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

                // 顶部两大特训营（含今日防刷奖励档位徽章）
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 310), spacing: 12)], spacing: 12) {
                    let wrongCount = currentSubjectWrongCount
                    specialModeCard(
                        type: .wrong,
                        icon: "🛠️",
                        title: "\(engine.currentSubject.shortTitle) · 错题特训营",
                        subtitle: wrongCount > 0 ? "当前学科有 \(wrongCount) 道错题待攻克，点我专项突破！" : "目前 0 错题欠账！点我随机温习巩固",
                        titleColor: Color(hex: "#7A2E1D"),
                        subtitleColor: Color(hex: "#9E543E"),
                        gradientColors: [Color(hex: "#FFF3EE"), Color(hex: "#FFE4D9")],
                        borderColor: Color(hex: "#E25247").opacity(0.35),
                        preview: engine.specialModeRewardPreview(type: .wrong, subject: engine.currentSubject)
                    )

                    specialModeCard(
                        type: .allstar,
                        icon: "⚡",
                        title: "\(engine.currentSubject.shortTitle) · 名厨随机全明星挑战",
                        subtitle: "同步当前学期重点随机抽题 · 赢取高定华服与星币！",
                        titleColor: Color(hex: "#4A358E"),
                        subtitleColor: Color(hex: "#6B57B0"),
                        gradientColors: [Color(hex: "#F5F2FF"), Color(hex: "#E6E0FF")],
                        borderColor: Color(hex: "#7A6EE6").opacity(0.35),
                        preview: engine.specialModeRewardPreview(type: .allstar, subject: engine.currentSubject)
                    )
                }

                // 学科分册/类型筛选条 + 今日奖励图例
                stageFilterBar

                // 学科关卡网格（Mac/iPad 横屏自适应）
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 295, maximum: 450), spacing: 12)], spacing: 12) {
                    switch engine.currentSubject {
                    case .pinyin:
                        ForEach(filteredPinyinLevels) { lv in
                            pinyinLevelCard(lv)
                        }
                    case .math:
                        ForEach(filteredMathStages) { stg in
                            mathStageCard(stg)
                        }
                    case .english:
                        ForEach(filteredEnglishStages) { stg in
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

    @ViewBuilder
    private var stageFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                switch engine.currentSubject {
                case .pinyin:
                    ForEach(PinyinStageFilter.allCases) { item in
                        let count = item.mode == nil
                            ? LevelRepository.levels.count
                            : LevelRepository.levels.filter { $0.mode == item.mode }.count
                        filterPillButton(
                            title: item.rawValue,
                            count: count,
                            isSelected: pinyinStageFilter == item,
                            accent: themeColor
                        ) {
                            pinyinStageFilter = item
                        }
                    }
                    Text("✨ 共 \(LevelRepository.levels.count) 关，第 10 关专注后鼻音强化")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .padding(.leading, 4)

                case .math:
                    ForEach(MathSemesterFilter.allCases) { item in
                        let count = item.semester == nil
                            ? HujiaoCurriculumRepository.mathStages.count
                            : HujiaoCurriculumRepository.mathStages.filter { $0.semester == item.semester }.count
                        let pillAccent: Color = {
                            switch item {
                            case .all:     return themeColor
                            case .grade1A: return Color(hex: "#E05385")
                            case .grade1B: return Color(hex: "#3A86FF")
                            case .ext:     return Color(hex: "#7A6EE6")
                            }
                        }()
                        filterPillButton(
                            title: item.rawValue,
                            count: count,
                            isSelected: mathSemesterFilter == item,
                            accent: pillAccent
                        ) {
                            mathSemesterFilter = item
                        }
                    }
                    Text("💡 上册新手推荐先选「一年级上册」")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .padding(.leading, 4)

                case .english:
                    ForEach(EnglishSemesterFilter.allCases) { item in
                        let count = item.semester == nil
                            ? HujiaoCurriculumRepository.englishStages.count
                            : HujiaoCurriculumRepository.englishStages.filter { $0.semester == item.semester }.count
                        let pillAccent: Color = item == .grade1B ? Color(hex: "#7A6EE6") : themeColor
                        filterPillButton(
                            title: item.rawValue,
                            count: count,
                            isSelected: englishSemesterFilter == item,
                            accent: pillAccent
                        ) {
                            englishSemesterFilter = item
                        }
                    }
                    Text("💡 入门推荐先选「1A 一上」")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    private func filterPillButton(
        title: String,
        count: Int,
        isSelected: Bool,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            engine.audio.sfxTap()
            withAnimation(.easeInOut(duration: 0.16)) {
                action()
            }
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12.5, weight: .heavy))
                Text("\(count)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .padding(.horizontal, 5.5)
                    .padding(.vertical, 1)
                    .background(
                        Capsule().fill(isSelected ? Color.white.opacity(0.24) : accent.opacity(0.14))
                    )
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#4A3520"))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? accent : Color.white)
                    .overlay(
                        Capsule().stroke(isSelected ? accent : accent.opacity(0.28), lineWidth: 1.4)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func specialModeCard(
        type: SpecialModeType,
        icon: String,
        title: String,
        subtitle: String,
        titleColor: Color,
        subtitleColor: Color,
        gradientColors: [Color],
        borderColor: Color,
        preview: StageRewardPreview
    ) -> some View {
        Button {
            engine.audio.sfxTap()
            engine.startSpecialMode(type)
        } label: {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 30))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(titleColor)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        rewardStatusPill(preview)
                    }
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(subtitleColor)
                        .lineLimit(1)
                    Text(preview.detailText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(rewardPreviewStyle(for: preview.tier).fg)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(borderColor, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }

    private func rewardPreviewStyle(for tier: StageRewardTier) -> (fg: Color, bg: Color, border: Color) {
        switch tier {
        case .full:
            return (Color(hex: "#15803D"), Color(hex: "#DCFCE7"), Color(hex: "#22C55E").opacity(0.45))
        case .reduced:
            return (Color(hex: "#B45309"), Color(hex: "#FEF3C7"), Color(hex: "#F59E0B").opacity(0.55))
        case .warmup:
            return (Color(hex: "#6B5B7B"), Color(hex: "#F1EEF5"), Color(hex: "#A594B8").opacity(0.45))
        }
    }

    private func rewardBadgeLabel(for preview: StageRewardPreview) -> String {
        switch preview.tier {
        case .full:
            return preview.badgeText
        case .reduced:
            return preview.badgeText
        case .warmup:
            return preview.isMasteredThreeStar ? "🌱 明日再来" : preview.badgeText
        }
    }

    private func rewardStatusPill(_ preview: StageRewardPreview) -> some View {
        let style = rewardPreviewStyle(for: preview.tier)
        return Text(rewardBadgeLabel(for: preview))
            .font(.system(size: 10.5, weight: .heavy))
            .foregroundColor(style.fg)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(
                Capsule()
                    .fill(style.bg)
                    .overlay(Capsule().stroke(style.border, lineWidth: 1))
            )
    }

    private func semesterBadgeColor(for semester: CurriculumSemester, subject: SubjectKind) -> Color {
        switch semester {
        case .grade1A:
            return subject == .english ? Color(hex: "#2FB380") : Color(hex: "#E05385")
        case .grade1B:
            return Color(hex: "#3A86FF")
        case .extensionChallenge:
            return Color(hex: "#7A6EE6")
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
            return "同步沪教牛津上海版一年级英语！支持美式发音点读、慢速跟读与鲜果单词块拼句（把单词果粒按顺序放进料理杯即可榨出美味果饮），闯关还能收集 \(HujiaoCurriculumRepository.englishFlashcards.count) 张有声单词闪卡！"
        }
    }

    private func stageProgressBar(pct: Double, color: Color) -> some View {
        let clamped = CGFloat(max(0.0, min(1.0, pct)))
        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.black.opacity(0.08))
                .frame(width: 78, height: 6)
            Capsule()
                .fill(color)
                .frame(width: 78 * clamped, height: 6)
        }
        .frame(width: 78, height: 6)
    }

    private func stageCardView(
        stageId: Int,
        locked: Bool,
        stars: Int,
        iconText: String,
        iconFontSize: CGFloat,
        accentColor: Color,
        progressColor: Color,
        title: String,
        tagText: String,
        subtitle: String,
        tipText: String?,
        tipColor: Color,
        statText: String,
        progressPct: Double,
        rewardPreview: StageRewardPreview
    ) -> some View {
        Button {
            guard !locked else { return }
            engine.audio.sfxTap()
            engine.firePickerLevel = stageId
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(locked ? Color.gray.opacity(0.18) : accentColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Text(locked ? "🔒" : iconText)
                        .font(.system(size: locked ? 20 : iconFontSize, weight: .black, design: .rounded))
                        .foregroundColor(locked ? .gray : accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#3B2E22"))
                            .lineLimit(1)
                        Text(tagText)
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(accentColor))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .lineLimit(1)
                    if let tipText {
                        Text(tipText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(tipColor)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if !locked {
                        rewardStatusPill(rewardPreview)
                        Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars))
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(Color(hex: "#F5A623"))
                    }
                    Text(statText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))

                    if !locked {
                        stageProgressBar(pct: progressPct, color: progressColor)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(locked ? Color.black.opacity(0.08) : accentColor.opacity(0.32), lineWidth: 1.8)
                    )
                    .shadow(color: Color.black.opacity(locked ? 0.02 : 0.06), radius: 5, y: 3)
            )
            .opacity(locked ? 0.58 : (rewardPreview.tier == .warmup ? 0.88 : 1.0))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 语文拼音关卡卡片
    private func pinyinLevelCard(_ lv: LevelDefinition) -> some View {
        let locked = !engine.progress.freeUnlockAll && (lv.id > engine.progress.unlocked)
        let stars = engine.progress.starsForLevel(lv.id)
        let gotWords = lv.words.filter { (engine.progress.food[$0.character] ?? 0) > 0 }.count
        let pct = lv.words.isEmpty ? 0.0 : Double(gotWords) / Double(lv.words.count)
        let rewardPreview = engine.stageRewardPreview(subject: .pinyin, stageId: lv.id)

        let badgeColor: Color = lv.mode == .whole
            ? Color(hex: "#7A6EE6")
            : (lv.mode == .tri ? Color(hex: "#3EA865") : Color(hex: "#F07D2E"))
        let modeTag: String = lv.id == 10
            ? "后鼻音"
            : (lv.mode == .whole ? "整体认读" : (lv.mode == .tri ? "三拼" : "两拼"))

        return stageCardView(
            stageId: lv.id,
            locked: locked,
            stars: stars,
            iconText: "\(lv.id)",
            iconFontSize: 20,
            accentColor: badgeColor,
            progressColor: badgeColor,
            title: lv.shortName,
            tagText: modeTag,
            subtitle: lv.subtitle,
            tipText: lv.tip.map { "💡 \($0)" },
            tipColor: Color(hex: "#B25614"),
            statText: locked ? "先过上一关" : "已收 \(gotWords)/\(lv.words.count) 字",
            progressPct: pct,
            rewardPreview: rewardPreview
        )
    }

    // MARK: - 沪教数学关卡卡片
    private func mathStageCard(_ stg: MathStageDefinition) -> some View {
        let locked = !engine.progress.freeUnlockAll && (stg.id > engine.progress.mathUnlocked)
        let stars = engine.progress.starsForLevel(stg.id, subject: .math)
        let stageQuestions = HujiaoCurriculumRepository.questionsForMathStage(stg.id)
        let gotDesserts = stg.dessertIds.filter { (engine.progress.desserts[$0] ?? 0) > 0 }.count
        let pct = stg.dessertIds.isEmpty ? 0.0 : Double(gotDesserts) / Double(stg.dessertIds.count)
        let semColor = semesterBadgeColor(for: stg.semester, subject: .math)
        let rewardPreview = engine.stageRewardPreview(subject: .math, stageId: stg.id)
        let shortTitle = stg.name.replacingOccurrences(of: #"^第 \d+ 关 · "#, with: "", options: .regularExpression)

        return stageCardView(
            stageId: stg.id,
            locked: locked,
            stars: stars,
            iconText: "🧁\(stg.id)",
            iconFontSize: 17,
            accentColor: semColor,
            progressColor: Color(hex: "#E05385"),
            title: shortTitle,
            tagText: stg.semesterTag,
            subtitle: stg.subtitle,
            tipText: "💡 \(stg.tip)",
            tipColor: Color(hex: "#B8336A"),
            statText: "题库 \(stageQuestions.count) 题 · 甜点 \(gotDesserts)/\(stg.dessertIds.count)",
            progressPct: pct,
            rewardPreview: rewardPreview
        )
    }

    // MARK: - 牛津英语关卡卡片
    private func englishStageCard(_ stg: EnglishStageDefinition) -> some View {
        let locked = !engine.progress.freeUnlockAll && (stg.id > engine.progress.englishUnlocked)
        let stars = engine.progress.starsForLevel(stg.id, subject: .english)
        let stageQuestions = HujiaoCurriculumRepository.questionsForEnglishStage(stg.id)
        let stageFlashcards = HujiaoCurriculumRepository.flashcards(forEnglishStage: stg.id)
        let gotCards = stageFlashcards.filter { (engine.progress.englishCards[$0.word] ?? 0) > 0 }.count
        let pct = stageFlashcards.isEmpty ? 0.0 : Double(gotCards) / Double(stageFlashcards.count)
        let semColor = semesterBadgeColor(for: stg.semester, subject: .english)
        let rewardPreview = engine.stageRewardPreview(subject: .english, stageId: stg.id)
        let shortTitle = stg.name.replacingOccurrences(of: #"^第 \d+ 关 · "#, with: "", options: .regularExpression)

        return stageCardView(
            stageId: stg.id,
            locked: locked,
            stars: stars,
            iconText: "🧃\(stg.id)",
            iconFontSize: 17,
            accentColor: semColor,
            progressColor: Color(hex: "#2FB380"),
            title: shortTitle,
            tagText: "\(stg.semester.rawValue) · \(stg.unitCode)",
            subtitle: stg.subtitle,
            tipText: "🗣️ 句型：\(stg.keySentences.first ?? "")",
            tipColor: Color(hex: "#156947"),
            statText: "题库 \(stageQuestions.count) 题 · 闪卡 \(gotCards)/\(stageFlashcards.count)",
            progressPct: pct,
            rewardPreview: rewardPreview
        )
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
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
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

                collectionMilestoneBanner(for: bookKind)

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
        .onCompatChange(of: engine.currentSubject) { newValue in
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

    private func collectionMilestoneBanner(for subject: SubjectKind) -> some View {
        let status = engine.collectionMilestoneStatus(for: subject)
        let accent = Color(hex: subject.themeHex)
        let denominator = max(1, status.nextTarget ?? status.maxCount)
        let pct = min(1.0, Double(status.currentCount) / Double(denominator))

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                collectionMilestoneInfo(subject: subject, status: status, accent: accent, pct: pct)
                Spacer(minLength: 8)
                collectionMilestoneAction(subject: subject, status: status, accent: accent)
            }
            VStack(alignment: .leading, spacing: 10) {
                collectionMilestoneInfo(subject: subject, status: status, accent: accent, pct: pct)
                collectionMilestoneAction(subject: subject, status: status, accent: accent)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.11), Color.white.opacity(0.95)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(status.canClaim ? accent : accent.opacity(0.32), lineWidth: status.canClaim ? 2.2 : 1.5)
                )
        )
    }

    private func collectionMilestoneInfo(subject: SubjectKind, status: CollectionMilestoneStatus, accent: Color, pct: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text("🏆 \(subject.shortTitle)图鉴收集里程碑")
                    .font(.system(size: 14.5, weight: .black))
                    .foregroundColor(Color(hex: "#3B2E22"))
                Text("\(status.currentCount) / \(status.maxCount)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white))
            }

            if let nextTarget = status.nextTarget {
                Text(status.canClaim
                     ? "🎉 已突破 \(nextTarget) 件收集大关！可立即领取奖励：\(status.rewardDesc)"
                     : "每收集 \(status.step) 件领惊喜大礼 · 距下一档（\(nextTarget) 件）还差 \(max(0, nextTarget - status.currentCount)) 件 · 奖品：\(status.rewardDesc)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(status.canClaim ? Color(hex: "#B45309") : Color(hex: "#6B5642"))
            } else {
                Text("✨ 恭喜你！本馆全部里程碑收集奖励已圆满领完！")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#2B7F4A"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [accent, Color(hex: "#F5B82E")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * pct))
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private func collectionMilestoneAction(subject: SubjectKind, status: CollectionMilestoneStatus, accent: Color) -> some View {
        if status.canClaim, let target = status.nextTarget {
            Button {
                engine.claimCollectionMilestone(subject: subject)
            } label: {
                Text("🎁 领 \(target) 件奖励")
                    .font(.system(size: 13.5, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [accent, Color(hex: "#F5A623")], startPoint: .leading, endPoint: .trailing)
                        )
                    )
                    .shadow(color: accent.opacity(0.32), radius: 5, y: 2)
            }
            .buttonStyle(.plain)
        } else if let nextTarget = status.nextTarget {
            Text("🎯 目标 \(nextTarget) 件")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.9)))
        } else {
            Text("👑 已满贯")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(Color(hex: "#2B7F4A"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(hex: "#E6F7ED")))
        }
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

    // MARK: - 2B. 沪教数学梦幻甜点柜（含一年级算理口诀）
    private var mathDessertCabinetContent: some View {
        let allDesserts = HujiaoCurriculumRepository.bakeryDesserts
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🍰 梦幻数学甜点柜（\(allDesserts.count)款甜点 + 沪教一年级算理口诀）")
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

    // MARK: - 2C. 沪教牛津上海版一年级有声英语闪卡吧（全册核心词汇+双语例句）
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

// MARK: - 3. 🎡 每日幸运大转盘弹窗（DailyWheelSlice.all 可视化转盘 + 必中抽奖）
public struct DailyLuckyWheelModal: View {
    @ObservedObject public var engine: GameEngine
    @Binding public var isPresented: Bool

    @State private var wheelRotation: Double = 0
    @State private var isSpinning: Bool = false
    @State private var revealWinCard: Bool = false

    public init(engine: GameEngine, isPresented: Binding<Bool>) {
        self.engine = engine
        self._isPresented = isPresented
    }

    private var gentleMotion: Bool {
        engine.progress.eyeCare.gentleMotion
    }

    public var body: some View {
        let slices = DailyWheelSlice.all
        let stepAngle = 360.0 / Double(max(1, slices.count))

        return ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    guard !isSpinning else { return }
                    closeModal()
                }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("🎡 每日幸运大转盘")
                                .font(.system(size: 21, weight: .black))
                                .foregroundColor(Color(hex: "#4A2E14"))
                            Text("每天免费抽 1 次 · 100% 必中好礼！" + ((engine.progress.castleUnlocked["clock_tower"] ?? 0) > 0 ? "（🕰️ 天文钟楼额外 +15 🪙）" : ""))
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(Color(hex: "#8A7765"))
                        }
                        Spacer()
                        Button {
                            guard !isSpinning else { return }
                            closeModal()
                        } label: {
                            Text("关闭 ✕")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color(hex: "#5A4634"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color(hex: "#F5EFE6")))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSpinning)
                    }

                    // 指针 + 彩色扇形转盘主体
                    ZStack(alignment: .top) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FFF4D9"))
                                .frame(width: 268, height: 268)
                                .shadow(color: Color(hex: "#D9953B").opacity(0.28), radius: 12, y: 4)

                            ZStack {
                                ForEach(Array(slices.enumerated()), id: \.element.id) { idx, slice in
                                    let startDeg = -90.0 + Double(idx) * stepAngle - stepAngle / 2.0
                                    let endDeg = startDeg + stepAngle
                                    let midAngle = Angle.degrees(-90.0 + Double(idx) * stepAngle)
                                    let rad = midAngle.radians

                                    WheelSectorShape(startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                                        .fill(Color(hex: slice.colorHex))
                                        .overlay(
                                            WheelSectorShape(startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                                                .stroke(Color.white, lineWidth: 2.2)
                                        )

                                    VStack(spacing: 2) {
                                        Text(slice.emoji)
                                            .font(.system(size: 20))
                                        Text(slice.title)
                                            .font(.system(size: 10.5, weight: .black))
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.28), radius: 1, y: 1)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 64)
                                    }
                                    .offset(
                                        x: CGFloat(cos(rad)) * 78,
                                        y: CGFloat(sin(rad)) * 78
                                    )
                                    .rotationEffect(.degrees(Double(idx) * stepAngle))
                                }
                            }
                            .frame(width: 248, height: 248)
                            .clipShape(Circle())
                            .rotationEffect(.degrees(wheelRotation))

                            Circle()
                                .stroke(Color(hex: "#F5B82E"), lineWidth: 7)
                                .frame(width: 252, height: 252)

                            Button {
                                triggerWheelSpin()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#FFF9E6"), Color(hex: "#FFD54F")],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 66, height: 66)
                                        .overlay(Circle().stroke(Color(hex: "#B45309"), lineWidth: 3))
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                                    Text(isSpinning ? "飞转中" : (engine.canSpinDailyWheel ? "抽奖" : "已领"))
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(Color(hex: "#6E3508"))
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(!engine.canSpinDailyWheel || isSpinning)
                        }
                        .padding(.top, 14)

                        // 顶部金色倒三角指针
                        WheelPointerTriangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF5252"), Color(hex: "#D32F2F")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 26, height: 24)
                            .overlay(WheelPointerTriangle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.25), radius: 3, y: 2)
                    }

                    if let win = engine.dailyWheelResult, revealWinCard {
                        HStack(spacing: 10) {
                            Text(win.emoji)
                                .font(.system(size: 30))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("🎊 恭喜转中：【\(win.title)】！")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundColor(Color(hex: "#9A3412"))
                                Text("奖品已自动放进你的奇妙包包啦！")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "#2B7F4A"))
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "#FFF4D9"))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F5A623"), lineWidth: 2))
                        )
                    } else if !engine.canSpinDailyWheel && !isSpinning {
                        Text("✅ 今日幸运大转盘已抽过啦！明天记得再来转哦～")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#2B7F4A"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#E8F6EE")))
                    }

                    Button {
                        if engine.canSpinDailyWheel {
                            triggerWheelSpin()
                        } else {
                            closeModal()
                        }
                    } label: {
                        Text(isSpinning ? "✨ 好运飞转中..." : (engine.canSpinDailyWheel ? "🎡 立即旋转大转盘！" : "太棒了，收下好运 ✓"))
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: engine.canSpinDailyWheel
                                                ? [Color(hex: "#FF7043"), Color(hex: "#E52E71")]
                                                : [Color(hex: "#2FB380"), Color(hex: "#248C64")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSpinning)
                }
                .padding(22)
            }
            .frame(maxWidth: 460)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: "#FFFDF9"))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#F5A623").opacity(0.6), lineWidth: 2.2))
                    .shadow(color: Color.black.opacity(0.28), radius: 22, y: 10)
            )
            .padding(20)
        }
        .onAppear {
            if let existing = engine.dailyWheelResult, !isSpinning {
                let step = 360.0 / Double(max(1, DailyWheelSlice.all.count))
                wheelRotation = -Double(existing.id) * step
                revealWinCard = true
            }
        }
    }

    private func triggerWheelSpin() {
        guard engine.canSpinDailyWheel, !isSpinning else { return }
        isSpinning = true
        revealWinCard = false
        PinyinAudioEngine.shared.sfxWheelSpin()
        engine.spinDailyWheel()

        let slices = DailyWheelSlice.all
        let stepAngle = 360.0 / Double(max(1, slices.count))
        let targetIdx = engine.dailyWheelResult?.id ?? 0
        let baseRounds: Double = gentleMotion ? 360.0 : 1080.0
        let currentBase = (wheelRotation / 360.0).rounded(.down) * 360.0
        let targetRotation = currentBase + baseRounds + (360.0 - Double(targetIdx) * stepAngle)
        let duration = gentleMotion ? 0.45 : 1.15

        withAnimation(.timingCurve(0.16, 0.88, 0.24, 1.0, duration: duration)) {
            wheelRotation = targetRotation
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.06) * 1_000_000_000))
            isSpinning = false
            withAnimation(.easeOut(duration: 0.22)) {
                revealWinCard = true
            }
        }
    }

    private func closeModal() {
        engine.audio.sfxTap()
        engine.dailyWheelResult = nil
        isPresented = false
    }
}

private struct WheelSectorShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct WheelPointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 4. 成就、语数英三科错题本与记录导入导出 (RecordsAndWrongView)
public struct RecordsAndWrongView: View {
    @ObservedObject public var engine: GameEngine
    @State private var wrongSubjectFilter: String = "all" // "all", "pinyin", "math", "english"

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var filteredWrongs: [(key: String, value: Int)] {
        engine.progress.wrong
            .filter { $0.value > 0 }
            .filter { item in
                switch wrongSubjectFilter {
                case "pinyin":  return !item.key.hasPrefix("hjm_") && !item.key.hasPrefix("hje_")
                case "math":    return item.key.hasPrefix("hjm_")
                case "english": return item.key.hasPrefix("hje_")
                default:        return true
                }
            }
            .sorted { $0.value > $1.value }
    }

    private var sortedHistory: [HistoryEntry] {
        engine.progress.history.enumerated().sorted { lhs, rhs in
            let lt = lhs.element.ts ?? 0
            let rt = rhs.element.ts ?? 0
            if lt != rt { return lt > rt }
            return lhs.offset > rhs.offset
        }.map(\.element)
    }

    public var body: some View {
        let activeWrongs = filteredWrongs

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 1. 跨端存档备份与重开管理（置顶醒目展示，iPad 一键复制/恢复/导出文件）
                VStack(alignment: .leading, spacing: 10) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            backupHeaderTitle
                            Spacer()
                            backupHeaderBadges
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            backupHeaderTitle
                            backupHeaderBadges
                        }
                    }

                    if let msg = engine.importExportMessage {
                        Text(msg)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(msg.hasPrefix("❌") || msg.hasPrefix("⚠️") ? Color(hex: "#D63B2F") : Color(hex: "#2B7F4A"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#E8F6EE")))
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 10)], spacing: 10) {
                        Button {
                            engine.copySaveToClipboard()
                            _ = engine.prepareBackupFile()
                        } label: {
                            Text("📋 一键复制存档码")
                                .font(.system(size: 13.5, weight: .black))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#F07D2E")))
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.restoreSaveFromClipboard()
                            _ = engine.prepareBackupFile()
                        } label: {
                            Text("📌 一键从剪贴板恢复")
                                .font(.system(size: 13.5, weight: .black))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#2FB380")))
                        }
                        .buttonStyle(.plain)

                        if let fileURL = engine.preparedBackupFileURL {
                            ShareLink(item: fileURL) {
                                Text("📤 导出到「文件」/ 微信")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundColor(Color(hex: "#4A358E"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#EFEFFD")))
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            engine.audio.sfxTap()
                            if engine.prepareBackupFile() != nil {
                                engine.importExportMessage = "✅ 已重新生成最新备份文件！"
                            }
                        } label: {
                            Text("🔄 刷新备份文件")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#5A4634"))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#F5EFE6")))
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.showBackupModal = true
                        } label: {
                            Text("📝 查看/粘贴 JSON")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(Color(hex: "#3B2E22"))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF0D6")))
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.audio.sfxTap()
                            engine.requestParentGate(.settings)
                        } label: {
                            Text("🔒 重开/清空旧记录（家长锁）")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#C62828"))
                                .frame(maxWidth: .infinity)
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

                // 2. 语数英三科错题糊锅本（支持分学科筛选）
                VStack(alignment: .leading, spacing: 10) {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            wrongSectionTitle
                            Spacer()
                            wrongPracticeButton(activeCount: activeWrongs.count)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            wrongSectionTitle
                            wrongPracticeButton(activeCount: activeWrongs.count)
                        }
                    }

                    // 学科筛选胶囊
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            wrongFilterPill(id: "all", title: "🌟 全部三科", accent: Color(hex: "#5A4634"))
                            wrongFilterPill(id: "pinyin", title: "🍲 语文拼音", accent: Color(hex: "#F07D2E"))
                            wrongFilterPill(id: "math", title: "🧁 沪教数学", accent: Color(hex: "#E05385"))
                            wrongFilterPill(id: "english", title: "🧃 牛津英语", accent: Color(hex: "#2FB380"))
                        }
                    }

                    if activeWrongs.isEmpty {
                        Text(wrongSubjectFilter == "all"
                             ? "🎉 太棒了！语数英三科目前都没有错题欠账，继续保持！"
                             : "🎉 太棒了！该学科目前没有待消灭错题！")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(Color(hex: "#2B7F4A"))
                            .padding(.vertical, 6)
                    } else {
                        ForEach(Array(activeWrongs.prefix(16).enumerated()), id: \.offset) { _, entry in
                            wrongItemRow(key: entry.key, count: entry.value)
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.92)))

                // 3. 近期闯关历史战绩（按最新时间倒序排列）
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("📜 近期闯关历史战绩")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(Color(hex: "#3B2E22"))
                        Spacer()
                        Text("共 \(sortedHistory.count) 场冒险")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }

                    if sortedHistory.isEmpty {
                        Text("🍳 还没有闯关历史记录，快去挑战第一关吧！")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                            .padding(.vertical, 4)
                    } else {
                        ForEach(Array(sortedHistory.prefix(12).enumerated()), id: \.element.id) { _, entry in
                            historyEntryRow(entry)
                        }
                    }
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.92)))

                // 4. 12 大全能厨神成就徽章
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
        .onAppear {
            _ = engine.prepareBackupFile()
        }
    }

    private var backupHeaderTitle: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("💾 存档保存与导出备份（iPad / Mac 互通）")
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(Color(hex: "#3B2E22"))
            Text("每答完一题都会自动保存在当前 iPad / Mac！如要在 iPad 更新版本或跨设备同步，请点下方按钮一键备份：")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(Color(hex: "#8A7765"))
        }
    }

    private var backupHeaderBadges: some View {
        HStack(spacing: 8) {
            Text("✅ 已开启三重自动保存")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(Color(hex: "#246B43"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: "#E3F6EA")))
        }
    }

    private var wrongSectionTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("🔥 语数英三科错题本")
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(Color(hex: "#3B2E22"))
            Text("答错过的拼音、数学或英语题目会自动记在这里，累计已攻克 \(engine.progress.wrongMastered.count) 道错题")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#8A7765"))
        }
    }

    @ViewBuilder
    private func wrongPracticeButton(activeCount: Int) -> some View {
        if activeCount > 0 {
            Button {
                engine.audio.sfxTap()
                switch wrongSubjectFilter {
                case "pinyin":  engine.currentSubject = .pinyin
                case "math":    engine.currentSubject = .math
                case "english": engine.currentSubject = .english
                default: break
                }
                engine.startSpecialMode(.wrong)
            } label: {
                Text(wrongSubjectFilter == "all" ? "🛠️ 去消灭当前科错题" : "🛠️ 专攻该科错题 (\(activeCount))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#F07D2E")))
            }
            .buttonStyle(.plain)
        }
    }

    private func wrongFilterPill(id: String, title: String, accent: Color) -> some View {
        let on = (wrongSubjectFilter == id)
        return Button {
            engine.audio.sfxTap()
            wrongSubjectFilter = id
        } label: {
            Text(title)
                .font(.system(size: 12.5, weight: .heavy))
                .foregroundColor(on ? .white : accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(on ? accent : Color(hex: "#FAF6F0"))
                        .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 1.2))
                )
        }
        .buttonStyle(.plain)
    }

    private func historyEntryRow(_ entry: HistoryEntry) -> some View {
        let subjKind = SubjectKind(rawValue: entry.subj ?? "pinyin") ?? .pinyin
        let subjBadge: (String, Color) = {
            switch subjKind {
            case .pinyin:  return ("🍲 拼音", Color(hex: "#F07D2E"))
            case .math:    return ("🧁 数学", Color(hex: "#E05385"))
            case .english: return ("🧃 英语", Color(hex: "#2FB380"))
            }
        }()
        let fireLabel: String = {
            switch entry.f {
            case "low":  return "小火"
            case "high": return "大火"
            default:     return "中火"
            }
        }()

        return HStack(spacing: 10) {
            Text(subjBadge.0)
                .font(.system(size: 11.5, weight: .heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(subjBadge.1))

            Text("第 \(entry.lv) 关 · \(fireLabel)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#3B2E22"))

            Text("答对 \(entry.r)/\(entry.t)")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(Color(hex: "#2B7F4A"))

            Spacer()

            Text(String(repeating: "★", count: max(0, min(3, entry.s))) + String(repeating: "☆", count: max(0, 3 - entry.s)))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#F5A623"))

            Text(entry.d)
                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#8A7765"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFFDF9")).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06), lineWidth: 1)))
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

// MARK: - 5. 局末结算庆祝视图 (RoundResultView - 支持语数英三科奖励展示 + 两段式偷看神秘宝箱)
public struct RoundResultView: View {
    @ObservedObject public var engine: GameEngine
    @State private var chestWiggle: Bool = false
    @State private var peekedChestIndices: Set<Int> = []
    @State private var showResultWheelModal: Bool = false

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var gentleMotion: Bool {
        engine.progress.eyeCare.gentleMotion
    }

    public var body: some View {
        let total: Int = engine.totalQuestionCountInRound
        let right: Int = engine.rightCount
        let stars: Int = engine.roundStars
        let themeColor: Color = Color(hex: engine.currentSubject.themeHex)

        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    resultHeaderSection(stars: stars, right: right, total: total)
                    if let antiFarmMsg = engine.roundAntiFarmMessage {
                        antiFarmNoticeBanner(message: antiFarmMsg)
                    }
                    resultPromptRow
                    if !engine.mysteryChests.isEmpty {
                        RoundResultMysteryChestSection(
                            engine: engine,
                            chestWiggle: chestWiggle,
                            gentleMotion: gentleMotion,
                            peekedChestIndices: $peekedChestIndices
                        )
                    }
                    resultRewardsSections
                    resultActionButtonsSection(themeColor: themeColor)
                }
                .padding(24)
                .frame(maxWidth: 740)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient(colors: [Color.white, Color(hex: "#FFF7EB")], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(themeColor.opacity(0.35), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)
                )
                .frame(maxWidth: .infinity)
            }

            if showResultWheelModal {
                DailyLuckyWheelModal(engine: engine, isPresented: $showResultWheelModal)
            }
        }
        .onAppear {
            if !gentleMotion {
                withAnimation(.easeInOut(duration: 0.28).repeatForever(autoreverses: true)) {
                    chestWiggle = true
                }
            }
        }
        .onDisappear {
            withAnimation(.easeOut(duration: 0.1)) {
                chestWiggle = false
            }
        }
        .onCompatChange(of: gentleMotion) { isGentle in
            if isGentle {
                withAnimation(.easeOut(duration: 0.15)) {
                    chestWiggle = false
                }
            } else {
                withAnimation(.easeInOut(duration: 0.28).repeatForever(autoreverses: true)) {
                    chestWiggle = true
                }
            }
        }
    }

    @ViewBuilder
    private func resultHeaderSection(stars: Int, right: Int, total: Int) -> some View {
        let pet: GuardianPetSpecies = engine.equippedPet
        let petStage: Int = engine.equippedPetStage
        let starText: String = String(repeating: "★", count: stars) + String(repeating: "☆", count: max(0, 3 - stars))

        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                PrincessAvatarVectorView(progress: engine.progress, size: 66, animated: true, gentleMotion: gentleMotion)
                GuardianPetVectorView(species: pet, stage: petStage, size: 62, animated: true, gentleMotion: gentleMotion)
                resultTitleCluster(st: stars)
            }
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    PrincessAvatarVectorView(progress: engine.progress, size: 60, animated: true, gentleMotion: gentleMotion)
                    GuardianPetVectorView(species: pet, stage: petStage, size: 58, animated: true, gentleMotion: gentleMotion)
                }
                resultTitleCluster(st: stars)
            }
        }

        Text(starText)
            .font(.system(size: 44, weight: .black))
            .foregroundColor(Color(hex: "#F5A623"))
            .shadow(color: Color(hex: "#B4640A").opacity(0.25), radius: 2, y: 3)

        Text(resultSummaryText(right: right, total: total))
            .font(.system(size: 14.5, weight: .bold))
            .foregroundColor(Color(hex: "#7A624B"))
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var resultPromptRow: some View {
        let claimableStarsCount: Int = engine.claimableStarMilestones.count + engine.claimableRankMilestones.count
        if claimableStarsCount > 0 || engine.canSpinDailyWheel {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                if claimableStarsCount > 0 {
                    HStack(spacing: 8) {
                        Text("🌟")
                            .font(.system(size: 20))
                        Text("你有 \(claimableStarsCount) 份「星星之路/段位晋升」大礼可领取！回主页顶栏即可一键拆礼盒！")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color(hex: "#9A3412"))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#FFF4D9"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#F5A623"), lineWidth: 1.5))
                    )
                }

                if engine.canSpinDailyWheel {
                    Button {
                        engine.audio.sfxTap()
                        showResultWheelModal = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("🎡")
                                .font(.system(size: 20))
                            Text("每日幸运大转盘待抽奖！点我免费转好运 →")
                                .font(.system(size: 12.5, weight: .black))
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(colors: [Color(hex: "#FF7043"), Color(hex: "#E52E71")], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var resultRewardsSections: some View {
        if !engine.newFoodsInRound.isEmpty {
            RoundResultFoodsSection(engine: engine)
        }
        if !engine.newDessertsInRound.isEmpty {
            RoundResultDessertsSection(engine: engine)
        }
        if !engine.newFlashcardsInRound.isEmpty {
            RoundResultFlashcardsSection(engine: engine)
        }
        if !engine.rewardedFashionInRound.isEmpty {
            RoundResultFashionSection(engine: engine)
        }
    }

    private func antiFarmNoticeBanner(message: String) -> some View {
        let isWarmup = (engine.activeRoundRewardTier == .warmup)
        let fg = isWarmup ? Color(hex: "#58486B") : Color(hex: "#92400E")
        let bg = isWarmup ? Color(hex: "#F4F1F8") : Color(hex: "#FFF8E1")
        let border = isWarmup ? Color(hex: "#A594B8").opacity(0.6) : Color(hex: "#F59E0B").opacity(0.6)
        let heading = isWarmup
            ? "🌱 暖心练手护航提示"
            : "🌓 巩固半额护航提示"
        let formattedMessage = message
            .replacingOccurrences(of: #"^[🌓🌱]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "恢复🎁全额", with: "恢复 🎁 全额")
            .replacingOccurrences(of: "拿🎁全额", with: "拿 🎁 全额")

        return VStack(alignment: .leading, spacing: 8) {
            Text(heading)
                .font(.system(size: 13.5, weight: .black))
                .foregroundColor(fg)

            Text(formattedMessage)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(fg)
                .fixedSize(horizontal: false, vertical: true)

            if engine.specialMode != nil, let nextId = engine.recommendedNextStageId {
                let nextPreview = engine.stageRewardPreview(subject: engine.currentSubject, stageId: nextId)
                Button {
                    engine.audio.sfxTap()
                    engine.goHome()
                    engine.firePickerLevel = nextId
                } label: {
                    Text(nextPreview.tier == .full
                         ? "🚀 挑战推荐第 \(nextId) 关（🎁 全额奖励）"
                         : "🚀 前往推荐第 \(nextId) 关（\(nextPreview.badgeText)）")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(hex: "#2FB380")))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(bg)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1.5))
        )
    }

    private func resultActionButtonsSection(themeColor: Color) -> some View {
        VStack(spacing: 10) {
            if engine.specialMode == nil, let nextId = engine.recommendedNextStageId {
                let nextPreview = engine.stageRewardPreview(subject: engine.currentSubject, stageId: nextId)
                let ctaTitle = nextPreview.tier == .full
                    ? "🚀 挑战推荐第 \(nextId) 关（🎁 全额奖励）"
                    : "🚀 前往推荐第 \(nextId) 关（\(nextPreview.badgeText)）"
                Button {
                    engine.audio.sfxTap()
                    engine.goHome()
                    engine.firePickerLevel = nextId
                } label: {
                    Text(ctaTitle)
                        .font(.system(size: 15.5, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: nextPreview.tier == .full
                                            ? [Color(hex: "#2FB380"), Color(hex: "#1E9666")]
                                            : [themeColor, themeColor.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                Button {
                    engine.audio.sfxTap()
                    if let sp = engine.specialMode {
                        engine.startSpecialMode(sp)
                    } else {
                        engine.startSubjectStage(stageId: engine.currentLevelNumber, fire: engine.currentFire)
                    }
                } label: {
                    resultActionButtonLabel("🔄 再来一局", foreground: .white, fill: themeColor)
                }
                .buttonStyle(.plain)

                if engine.specialMode == nil && engine.recommendedNextStageId == nil && engine.currentLevelNumber < engine.currentMaxStageCount {
                    let nextLv = min(engine.currentMaxStageCount, engine.currentLevelNumber + 1)
                    if !engine.progress.isStageLocked(nextLv, subject: engine.currentSubject) {
                        Button {
                            engine.audio.sfxTap()
                            engine.goHome()
                            engine.firePickerLevel = nextLv
                        } label: {
                            resultActionButtonLabel("下一关 →", foreground: .white, fill: Color(hex: "#3EA865"))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    engine.audio.sfxTap()
                    engine.activeTab = .garden
                    engine.goHome()
                } label: {
                    resultActionButtonLabel("👗 去公主换装", foreground: .white, fill: Color(hex: "#E05385"))
                }
                .buttonStyle(.plain)

                Button {
                    engine.audio.sfxTap()
                    engine.activeTab = .paradise
                    engine.goHome()
                } label: {
                    resultActionButtonLabel("🎰 去扭蛋抽神兽", foreground: .white, fill: Color(hex: "#E63946"))
                }
                .buttonStyle(.plain)

                Button {
                    engine.audio.sfxTap()
                    engine.goHome()
                } label: {
                    resultActionButtonLabel("🏠 返回选关", foreground: Color(hex: "#3B2E22"), fill: .white, stroke: Color.black.opacity(0.15))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private func resultActionButtonLabel(
        _ title: String,
        foreground: Color,
        fill: Color,
        stroke: Color? = nil
    ) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .heavy))
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(RoundedRectangle(cornerRadius: 14).fill(fill))
            .overlay(
                Group {
                    if let stroke {
                        RoundedRectangle(cornerRadius: 14).stroke(stroke, lineWidth: 1.5)
                    }
                }
            )
    }

    private func resultTitleCluster(st: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(st > 0 ? "🎉 香喷喷出炉通关啦！" : "💪 差一点点，再试一次吧！")
                    .font(.system(size: 23, weight: .black))
                    .foregroundColor(Color(hex: "#5E340B"))
                if st >= 1 && engine.activeRoundRewardTier != .full {
                    let isWarmup = (engine.activeRoundRewardTier == .warmup)
                    Text(isWarmup ? "🌱 暖心练手" : "🌓 巩固半额")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(isWarmup ? Color(hex: "#6B5B7B") : Color(hex: "#B45309"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(isWarmup ? Color(hex: "#F1EEF5") : Color(hex: "#FEF3C7"))
                        )
                }
            }
            Text("🪙 +\(engine.roundCoinsEarned) 枚星币 · 🎟️ \(engine.progress.gachaTickets) · 🧵 \(engine.progress.starThread) · 🌟 \(engine.progress.petCandy)")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Color(hex: "#D97706"))
        }
    }

    private func resultSummaryText(right: Int, total: Int) -> String {
        var s = "本局答对 \(right) / \(total) 道题"
        if engine.masteredCount > 0 {
            s += "，成功消灭了 \(engine.masteredCount) 道以前错过的题！"
        }
        if !engine.rewardedFashionInRound.isEmpty {
            let count = engine.rewardedFashionInRound.count
            s += count > 1
                ? "，太棒了，获得了 \(count) 件高定公主华服与首饰锦缎！"
                : "，获得了一件漂亮的公主华服礼盒！"
        } else if engine.roundStars >= 1 && engine.activeRoundRewardTier != .full {
            let modeLabel = engine.activeRoundRewardTier == .reduced ? "巩固半额" : "暖心练手"
            if engine.roundAntiFarmMessage != nil {
                s += "，本局为「\(modeLabel)」温习模式，未重复发放华服礼盒。"
            } else {
                s += "，本局为「\(modeLabel)」温习模式，未重复发放华服礼盒，换新关挑战可立即恢复 🎁 全额礼盒哦！"
            }
        } else {
            s += "，再加把劲达到 1★ 就能赢取公主华服礼盒哦！"
        }
        return s
    }
}

private struct RoundResultMysteryChestSection: View {
    @ObservedObject var engine: GameEngine
    let chestWiggle: Bool
    let gentleMotion: Bool
    @Binding var peekedChestIndices: Set<Int>

    var body: some View {
        let hasOpened: Bool = (engine.openedChestIndex != nil)
        let titleText: String = hasOpened
            ? "🎊 惊喜盲盒已开启！"
            : "🎁 通关惊喜盲盒！第1次点击可「👀偷看预览」，再点1次爆开抱走大奖："

        VStack(spacing: 10) {
            Text(titleText)
                .font(.system(size: 13.5, weight: .black))
                .foregroundColor(Color(hex: "#B45309"))
                .multilineTextAlignment(.center)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 12)], spacing: 12) {
                ForEach(Array(engine.mysteryChests.enumerated()), id: \.element.id) { idx, chest in
                    RoundResultMysteryChestCard(
                        idx: idx,
                        chest: chest,
                        isChosen: engine.openedChestIndex == idx,
                        isRevealed: hasOpened,
                        isPeekedNow: !hasOpened && (chest.isPeeked || peekedChestIndices.contains(idx)),
                        chestWiggle: chestWiggle,
                        gentleMotion: gentleMotion
                    ) {
                        if chest.isPeeked || peekedChestIndices.contains(idx) {
                            engine.openMysteryChest(at: idx)
                        } else {
                            engine.audio.sfxSpark()
                            peekedChestIndices.insert(idx)
                        }
                    }
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
}

private struct RoundResultMysteryChestCard: View {
    let idx: Int
    let chest: MysteryChestItem
    let isChosen: Bool
    let isRevealed: Bool
    let isPeekedNow: Bool
    let chestWiggle: Bool
    let gentleMotion: Bool
    let onTap: () -> Void

    private var iconText: String {
        switch chest.rewardType {
        case "thread":  return "🧵"
        case "candy":   return "🌟"
        case "ticket":  return "🎟️"
        case "fashion": return "👗"
        case "coins":   return "🪙"
        default:        return chest.emoji
        }
    }

    var body: some View {
        let fillColor: Color = isChosen ? Color(hex: "#FFF8E1") : (isPeekedNow ? Color(hex: "#FFF5FC") : Color.white)
        let strokeColor: Color = isChosen ? Color(hex: "#F5A623") : (isPeekedNow ? Color(hex: "#E05385") : Color(hex: "#F5A623").opacity(0.38))
        let lineWidth: CGFloat = (isChosen || isPeekedNow) ? 2.6 : 1.5
        let mainEmoji: String = (isRevealed || isPeekedNow) ? iconText : "🎁"
        let mainTitle: String = isRevealed ? chest.title : (isPeekedNow ? "发现 \(chest.subtitle)！" : "神秘金宝箱 #\(idx + 1)")
        let statusText: String = isRevealed
            ? (isChosen ? "✓ 已收入囊中！" : "未选：\(chest.subtitle)")
            : (isPeekedNow ? "✨ 再点一次爆开领奖！" : "第1点偷看 · 第2点爆开")
        let statusColor: Color = isChosen ? Color(hex: "#2B7F4A") : (isPeekedNow ? Color(hex: "#B45309") : Color(hex: "#8A7765"))
        let wiggleAngle: Double = (!isRevealed && !gentleMotion && chestWiggle) ? (idx.isMultiple(of: 2) ? 6 : -6) : 0

        Button(action: onTap) {
            ZStack {
                if isChosen {
                    FireworkSparkBurstView(colorHex: chest.accentHex)
                }
                VStack(spacing: 6) {
                    if isPeekedNow {
                        Text("👀 偷看：\(iconText) \(chest.title)")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [Color(hex: "#7A6EE6"), Color(hex: "#E05385")], startPoint: .leading, endPoint: .trailing)
                                )
                            )
                            .opacity(gentleMotion ? 1.0 : (chestWiggle ? 1.0 : 0.85))
                    }

                    Text(mainEmoji)
                        .font(.system(size: isChosen ? 36 : 32))
                        .rotationEffect(.degrees(wiggleAngle))

                    Text(mainTitle)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(isChosen ? Color(hex: "#B45309") : Color(hex: "#3B2E22"))
                        .lineLimit(1)

                    Text(statusText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(statusColor)
                        .lineLimit(1)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(fillColor)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(strokeColor, lineWidth: lineWidth))
                )
                .opacity(isRevealed && !isChosen ? 0.58 : 1.0)
                .scaleEffect(isChosen ? 1.04 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .disabled(isRevealed)
    }
}

private struct RoundResultFoodsSection: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 8) {
            Text("🍲 本局新端上《中华小菜谱》的汉字（点击可听发音）")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Color(hex: "#8A7765"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56, maximum: 70), spacing: 8)], spacing: 8) {
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
}

private struct RoundResultDessertsSection: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 8) {
            Text("🧁 本局新收入《梦幻甜点柜》的数学甜点（点击听算理秘籍）")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Color(hex: "#B8336A"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
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
                        .frame(maxWidth: .infinity)
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
}

private struct RoundResultFlashcardsSection: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 8) {
            Text("🍹 本局新收入《牛津特调闪卡吧》的单词卡（点击听英语发音）")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Color(hex: "#156947"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 10)], spacing: 10) {
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
                        .frame(maxWidth: .infinity, alignment: .leading)
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
}

private struct RoundResultFashionSection: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 8) {
            Text("👗 通关公主华服与首饰礼盒（点击可直接给满满小公主穿戴并听介绍）")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Color(hex: "#BE185D"))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(Array(engine.rewardedFashionInRound.enumerated()), id: \.offset) { _, fashion in
                    let stg: Int = engine.progress.fashionStage(for: fashion.id)
                    Button {
                        engine.equipFashionItem(fashion)
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: fashion.secondaryHex), Color(hex: fashion.primaryHex).opacity(0.35)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                Text(fashion.icon)
                                    .font(.system(size: 32))
                            }
                            Text(fashion.name)
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color(hex: "#3B2E22"))
                            Text("\(fashion.rarityName) · Lv.\(stg) \(PrincessFashionItem.stageName(for: stg))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#E05385"))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#E05385").opacity(0.45), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#FFF0F5")))
    }
}
