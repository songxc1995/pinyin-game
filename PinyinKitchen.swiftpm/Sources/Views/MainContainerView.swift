import SwiftUI

public struct MainContainerView: View {
    @StateObject private var engine = GameEngine()

    public init() {}

    private var themeColor: Color {
        Color(hex: engine.currentSubject.themeHex)
    }

    public var body: some View {
        ZStack {
            // 温暖奶油料理城背景渐变
            LinearGradient(
                colors: [Color(hex: "#FFFDF9"), Color(hex: "#FFF5E5"), Color(hex: "#FFEBD2")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部彩色料理城遮阳棚条
                awningStripeBar

                ZStack {
                    switch engine.screenState {
                    case .home:
                        homeContentView
                    case .playing:
                        if engine.currentSubject == .pinyin {
                            KitchenGameView(engine: engine)
                        } else {
                            CurriculumGameView(engine: engine)
                        }
                    case .result:
                        RoundResultView(engine: engine)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(maxWidth: 1240, maxHeight: .infinity)
            }

            // 选火候弹窗
            if let lvNum = engine.firePickerLevel {
                firePickerOverlay(levelNumber: lvNum)
            }

            // 蝴蝶进化全屏庆典弹窗
            if let upgrade = engine.pendingUpgrades.first {
                butterflyUpgradeOverlay(upgrade)
            }
        }
    }

    // MARK: - 顶部遮阳棚装饰条
    private var awningStripeBar: some View {
        GeometryReader { geo in
            let stripeWidth: CGFloat = 28
            let count = Int(ceil(geo.size.width / stripeWidth)) + 1
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    let color: Color = {
                        switch i % 4 {
                        case 0: return themeColor
                        case 2: return Color(hex: "#FFB347")
                        default: return Color(hex: "#FFF7EC")
                        }
                    }()
                    Rectangle()
                        .fill(color)
                        .frame(width: stripeWidth, height: 10)
                }
            }
        }
        .frame(height: 10)
        .shadow(color: Color(hex: "#B45F1E").opacity(0.18), radius: 4, y: 2)
    }

    // MARK: - 主页内容
    private var homeContentView: some View {
        VStack(spacing: 10) {
            // 1. 顶部招牌《满满的奇妙料理城》 + 4 大统计指标
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        engine.audio.sfxTap()
                        withAnimation(.spring(response: 0.28)) {
                            engine.showSkinDrawer.toggle()
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [Color(hex: "#FFE8C2"), Color(hex: "#FFC97A")], startPoint: .top, endPoint: .bottom))
                                .frame(width: 52, height: 52)
                                .shadow(color: Color(hex: "#D9953B"), radius: 0, x: 0, y: 3)
                            PotVectorView(skin: engine.currentPotSkin, size: 42)
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 7) {
                            Text("满满的奇妙料理城")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(Color(hex: "#4A2E14"))
                            Text("沪教一年级 · 语数英冒险屋")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 2.5)
                                .background(
                                    Capsule().fill(
                                        LinearGradient(colors: [themeColor, Color(hex: "#FF8A48")], startPoint: .leading, endPoint: .trailing)
                                    )
                                )
                        }
                        Text(engine.mascotLine)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#8A7765"))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(themeColor.opacity(0.26), lineWidth: 1.8))
                )

                Spacer(minLength: 4)

                // 4 大统计胶囊
                HStack(spacing: 8) {
                    statPill(icon: "⭐", value: "\(engine.progress.totalStars)", label: "三科总星", color: Color(hex: "#F5A623"), tab: .map)
                    statPill(icon: "📖", value: "\(engine.progress.foodCount + engine.progress.dessertCount + engine.progress.englishCardCount)", label: "料理图鉴", color: Color(hex: "#3EA865"), tab: .recipe)
                    statPill(icon: "📅", value: "\(engine.progress.streak.n)", label: "连续打卡", color: Color(hex: "#3685D6"), tab: .records)
                    statPill(icon: "🦋", value: "\(engine.progress.bf.count)", label: "小蝴蝶", color: Color(hex: "#7A6EE6"), tab: .garden)
                }
            }

            // 2. 语数英三大主题场馆切换横幅 (🍲 拼音料理屋 | 🧁 数学烘焙坊 | 🧃 英语饮品吧)
            subjectVenueSwitcherBar

            // 3. 厨神头衔条 + 今日小厨神目标（双栏并排）
            HStack(spacing: 12) {
                chefRankBar
                dailyQuestsBar
            }

            // 可展开的魔法锅具换装抽屉
            if engine.showSkinDrawer {
                potSkinDrawerView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // 4. 四大主 Tab 切换栏
            HStack(spacing: 8) {
                tabButton(tab: .map, title: "🍳 \(engine.currentSubject.shortTitle)闯关地图")
                tabButton(tab: .recipe, title: "📖 语数英料理图鉴")
                tabButton(tab: .garden, title: "🦋 蝴蝶生态花园")
                tabButton(tab: .records, title: "🏆 错题本与成就")
            }
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.78))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08), lineWidth: 1))
            )

            // 5. 当前激活的 Tab 视图
            Group {
                switch engine.activeTab {
                case .map:
                    LevelMapView(engine: engine)
                case .recipe:
                    RecipeBookView(engine: engine)
                case .garden:
                    ButterflyGardenView(engine: engine)
                case .records:
                    RecordsAndWrongView(engine: engine)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 语数英三大场馆切换卡片条
    private var subjectVenueSwitcherBar: some View {
        HStack(spacing: 10) {
            venueButton(
                subject: .pinyin,
                badge: "9关 · 443字",
                desc: "声母+无调韵母+四声调料瓶"
            )
            venueButton(
                subject: .math,
                badge: "10关 · 468题",
                desc: "沪教一上/一下 · 5大互动教具"
            )
            venueButton(
                subject: .english,
                badge: "11关 · 223题",
                desc: "沪教牛津上海版 · 听说与鲜果拼句"
            )
        }
    }

    private func venueButton(subject: SubjectKind, badge: String, desc: String) -> some View {
        let isSelected = (engine.currentSubject == subject)
        let color = Color(hex: subject.themeHex)

        return Button {
            engine.audio.sfxTap()
            withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                engine.currentSubject = subject
                if engine.activeTab != .map && engine.activeTab != .recipe {
                    engine.activeTab = .map
                }
            }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(subject.title)
                            .font(.system(size: 15.5, weight: .black))
                            .foregroundColor(isSelected ? .white : Color(hex: "#3B2E22"))
                        Text(badge)
                            .font(.system(size: 10.5, weight: .heavy))
                            .foregroundColor(isSelected ? color : .white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(isSelected ? Color.white : color))
                    }
                    Text(desc)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(isSelected ? Color.white.opacity(0.92) : Color(hex: "#8A7765"))
                        .lineLimit(1)
                }
                Spacer()
                if isSelected {
                    Text("当前场馆 ✓")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.16)))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : Color.white.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(isSelected ? 0.9 : 0.35), lineWidth: isSelected ? 2.2 : 1.5)
                    )
                    .shadow(color: isSelected ? color.opacity(0.25) : Color.black.opacity(0.03), radius: 5, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func statPill(icon: String, value: String, label: String, color: Color, tab: HomeTab) -> some View {
        Button {
            engine.audio.sfxTap()
            engine.activeTab = tab
        } label: {
            HStack(spacing: 7) {
                Text(icon)
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 1) {
                    Text(value)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.28), lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 厨神等级与换锅按钮
    private var chefRankBar: some View {
        let info = engine.chefRank
        let stars = engine.progress.totalStars

        return HStack(spacing: 10) {
            Text("👑")
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(info.name)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "#4A2E14"))
                    Text("🍲 \(engine.currentPotSkin.name)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A4B12"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.85)))
                }
                if let nextName = info.nextRankName, let nextMin = info.nextMinStars {
                    Text("再拿 \(max(0, nextMin - stars)) 颗星升级 → \(nextName)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else {
                    Text("已达最高料理城主厨等级 ✨")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#F07D2E"))
                }
            }
            Spacer()
            Button {
                engine.audio.sfxTap()
                withAnimation(.spring(response: 0.28)) {
                    engine.showSkinDrawer.toggle()
                }
            } label: {
                Text("🍲 换锅具")
                    .font(.system(size: 12.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#8A4B12"))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 11).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "#F07D2E").opacity(0.35), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color(hex: "#FFF6E5"), Color(hex: "#FFE8C5")], startPoint: .leading, endPoint: .trailing))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#F07D2E").opacity(0.28), lineWidth: 1.5))
        )
    }

    // MARK: - 今日小厨神目标栏
    private var dailyQuestsBar: some View {
        HStack(spacing: 8) {
            Text("📅 今日目标")
                .font(.system(size: 12.5, weight: .heavy))
                .foregroundColor(Color(hex: "#5A3818"))

            ForEach(engine.dailyQuests) { q in
                Button {
                    guard q.isCompleted && !q.claimed else { return }
                    engine.claimDailyQuest(q.id)
                } label: {
                    HStack(spacing: 5) {
                        Text(q.title)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color(hex: "#3B2E22"))
                            .lineLimit(1)
                        Text(q.claimed ? "✓已领蝶" : (q.isCompleted ? "🎁点我领蝶" : "\(q.current)/\(q.goal)"))
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(q.claimed ? Color(hex: "#2B7F4A") : (q.isCompleted ? .white : Color(hex: "#8A7765")))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(
                                    q.claimed ? Color(hex: "#E6F7ED") : (q.isCompleted ? Color(hex: "#F07D2E") : Color(hex: "#F5EFE6"))
                                )
                            )
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 11)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 11)
                                    .stroke(q.isCompleted && !q.claimed ? Color(hex: "#F07D2E") : Color.black.opacity(0.08), lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.88))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.08), lineWidth: 1.5))
        )
    }

    // MARK: - 5 款魔法锅具换装栏
    private var potSkinDrawerView: some View {
        let stars = engine.progress.totalStars
        let curId = engine.currentPotSkin.id

        return HStack(spacing: 12) {
            ForEach(PotSkin.all) { skin in
                let unlocked = stars >= skin.needStars
                let isCurrent = (curId == skin.id)

                Button {
                    guard unlocked else { return }
                    engine.progress.potSkin = skin.id
                    engine.saveProgress()
                    engine.audio.sfxWin()
                } label: {
                    VStack(spacing: 4) {
                        PotVectorView(skin: skin, size: 54)
                        Text(skin.name)
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#3B2E22"))
                        Text(unlocked ? (isCurrent ? "✓ 使用中" : "点我换上") : "需 \(skin.needStars) ★")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(unlocked ? (isCurrent ? Color(hex: "#2B7F4A") : Color(hex: "#F07D2E")) : .gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isCurrent ? Color(hex: "#FFF3DC") : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isCurrent ? Color(hex: "#F07D2E") : Color.black.opacity(0.1), lineWidth: isCurrent ? 2.2 : 1.2)
                            )
                    )
                    .opacity(unlocked ? 1.0 : 0.5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.95)))
    }

    private func tabButton(tab: HomeTab, title: String) -> some View {
        let on = (engine.activeTab == tab)
        return Button {
            engine.audio.sfxTap()
            engine.activeTab = tab
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(on ? .white : Color(hex: "#5A4634"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(on ? themeColor : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 选火候弹窗（适配语数英三科）
    private func firePickerOverlay(levelNumber: Int) -> some View {
        let stageInfo: (title: String, sub: String, wrongCount: Int) = {
            switch engine.currentSubject {
            case .pinyin:
                let lv = LevelRepository.levels[max(0, min(LevelRepository.levels.count - 1, levelNumber - 1))]
                let wc = lv.words.filter { (engine.progress.wrong[$0.id] ?? 0) > 0 }.count
                return (lv.name, lv.subtitle, wc)
            case .math:
                let stg = HujiaoCurriculumRepository.mathStages[max(0, min(HujiaoCurriculumRepository.mathStages.count - 1, levelNumber - 1))]
                let qs = HujiaoCurriculumRepository.questionsForMathStage(stg.id)
                let wc = qs.filter { (engine.progress.wrong[$0.id] ?? 0) > 0 }.count
                return ("🧁 " + stg.name, "\(stg.semesterTag) · \(stg.subtitle)", wc)
            case .english:
                let stg = HujiaoCurriculumRepository.englishStages[max(0, min(HujiaoCurriculumRepository.englishStages.count - 1, levelNumber - 1))]
                let qs = HujiaoCurriculumRepository.questionsForEnglishStage(stg.id)
                let wc = qs.filter { (engine.progress.wrong[$0.id] ?? 0) > 0 }.count
                return ("🧃 " + stg.name, "\(stg.unitCode) · \(stg.subtitle)", wc)
            }
        }()

        return ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.firePickerLevel = nil
                }

            VStack(spacing: 14) {
                Text(stageInfo.title)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(Color(hex: "#4A2E14"))
                    .multilineTextAlignment(.center)
                Text(stageInfo.sub)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
                    .multilineTextAlignment(.center)

                Text(stageInfo.wrongCount > 0 ? "🎯 这一关还有 \(stageInfo.wrongCount) 道以前错过的题，这次把它们全部拿下！" : "✨ 这一关熟门熟路啦，可以挑战「大火」拿双倍小蝴蝶！")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(Color(hex: "#B25614"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "#FFF3DC")))

                // 拼音专属快捷开关
                if engine.currentSubject == .pinyin {
                    HStack(spacing: 10) {
                        Button {
                            engine.audio.sfxTap()
                            engine.progress.seasoningMode.toggle()
                            engine.saveProgress()
                        } label: {
                            HStack {
                                Text("🧂 四声调料瓶减负")
                                    .font(.system(size: 12.5, weight: .bold))
                                Spacer()
                                Text(engine.progress.seasoningMode ? "已开启" : "关")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(engine.progress.seasoningMode ? Color(hex: "#2B7F4A") : .gray)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FAF6F0")))
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.audio.sfxTap()
                            engine.progress.blind.toggle()
                            engine.saveProgress()
                        } label: {
                            HStack {
                                Text("🛎️ 神秘锅盖盲听")
                                    .font(.system(size: 12.5, weight: .bold))
                                Spacer()
                                Text(engine.progress.blind ? "已开启" : "关")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(engine.progress.blind ? Color(hex: "#7A6EE6") : .gray)
                            }
                            .padding(10)
                            .frame(width: 170)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FAF6F0")))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 小火 / 中火 / 大火选项
                VStack(spacing: 9) {
                    ForEach(FireDifficulty.allCases, id: \.self) { fire in
                        Button {
                            engine.audio.sfxTap()
                            engine.startSubjectStage(stageId: levelNumber, fire: fire)
                        } label: {
                            HStack(spacing: 12) {
                                Text(fire == .high ? "🔥🔥" : "🔥")
                                    .font(.system(size: 22))
                                    .frame(width: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(fire.name) · \(fire.desc)")
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundColor(Color(hex: "#3B2E22"))
                                    Text(fire.tip)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(fire == .high ? Color(hex: "#E25247") : Color(hex: "#8A7765"))
                                }
                                Spacer()
                                Text("开始 →")
                                    .font(.system(size: 13.5, weight: .black))
                                    .foregroundColor(themeColor)
                            }
                            .padding(13)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(fire == .high ? Color(hex: "#FFF4F2") : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(fire == .high ? Color(hex: "#E25247").opacity(0.45) : Color.black.opacity(0.12), lineWidth: 1.8)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button("先不玩") {
                    engine.audio.sfxTap()
                    engine.firePickerLevel = nil
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#8A7765"))
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 490)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.22), radius: 20, y: 10)
            )
        }
    }

    // MARK: - 蝴蝶进化全屏庆典弹窗
    private func butterflyUpgradeOverlay(_ event: ButterflyUpgradeEvent) -> some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ButterflyVectorView(species: event.species, stage: event.toStage, size: 160, animated: true)

                Text(event.customTitle ?? (event.toStage >= 3 ? "✨ 完全进化啦！" : "🎉 蝴蝶进化啦！"))
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(Color(hex: "#5E340B"))

                Text("\(event.species.name) 已收集 \(event.count) 只 · 当前形态：【\(ButterflySpecies.stageName(for: event.toStage))】")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#7A624B"))

                Text(event.toStage >= 3 ? "这是它最华丽的终极形态 ✨" : "继续闯关收集同种蝴蝶，还能再次进化哦！")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#F07D2E"))

                Button {
                    engine.audio.sfxTap()
                    if !engine.pendingUpgrades.isEmpty {
                        engine.pendingUpgrades.removeFirst()
                    }
                } label: {
                    Text(engine.pendingUpgrades.count > 1 ? "下一只（还有 \(engine.pendingUpgrades.count - 1) 只）" : "太棒了！")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#F07D2E")))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(28)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [Color.white, Color(hex: "#FFF6E5")], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#F5B82E"), lineWidth: 2.5))
                    .shadow(color: Color.black.opacity(0.25), radius: 22, y: 10)
            )
        }
    }
}
