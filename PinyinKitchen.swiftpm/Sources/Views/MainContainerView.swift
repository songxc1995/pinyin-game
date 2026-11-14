import SwiftUI

public struct MainContainerView: View {
    @StateObject private var engine = GameEngine()
    @State private var showMilestoneDrawer: Bool = false
    @State private var showDailyWheelModal: Bool = false
    private let eyeTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    public init() {}

    private var themeColor: Color {
        Color(hex: engine.currentSubject.themeHex)
    }

    private var gentleMotion: Bool {
        engine.progress.eyeCare.gentleMotion
    }

    private var claimableGiftCount: Int {
        engine.claimableStarMilestones.count + engine.claimableRankMilestones.count
    }

    public var body: some View {
        ZStack {
            // 柔和护眼豆沙米黄纸张背景（告别刺眼纯白眩光）
            LinearGradient(
                colors: [Color(hex: "#F6F1E3"), Color(hex: "#EFE6D2"), Color(hex: "#E8DCC4")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部彩色料理城遮阳棚条
                awningStripeBar

                // 顶部常驻儿童护眼卫士状态条
                EyeCareTopBarView(engine: engine)
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

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
                .padding(.vertical, 8)
                .frame(maxWidth: 1240, maxHeight: .infinity)
            }

            // 选火候弹窗
            if let lvNum = engine.firePickerLevel {
                firePickerOverlay(levelNumber: levelNumberClamped(lvNum))
            }

            // 星星之路（10~90★）& 厨神段位晋升大礼中心弹窗
            if showMilestoneDrawer {
                StarPathAndRankGiftOverlay(engine: engine, isPresented: $showMilestoneDrawer)
            }

            // 每日幸运大转盘弹窗
            if showDailyWheelModal {
                DailyLuckyWheelModal(engine: engine, isPresented: $showDailyWheelModal)
            } else if let wheelWin = engine.dailyWheelResult {
                dailyWheelResultFallbackOverlay(wheelWin)
            }

            // 公主华服解锁 & 五阶高定升阶全屏庆典弹窗
            if let upgrade = engine.pendingFashionUpgrades.first {
                FashionUpgradeBurstOverlay(engine: engine, event: upgrade)
            }

            // 皇家扭蛋孵化 & 守护神兽进化全屏庆典弹窗（支持十连批量 & 单抽）
            if !engine.activeGachaBatch.isEmpty {
                GachaponEggBurstOverlay(engine: engine, events: engine.activeGachaBatch)
            } else if let hatch = engine.activeGachaHatch {
                GachaponEggBurstOverlay(engine: engine, event: hatch)
            }

            // 跨设备存档备份与一键导出面板
            if engine.showBackupModal {
                BackupAndRestoreOverlayView(engine: engine)
            }

            // 20-20-20 森林绿洲护眼休息弹窗（覆盖在普通奖励/备份弹窗之上）
            if engine.eyeRestActive {
                EyeRestOverlayView(engine: engine)
            }

            // 每日时长上限 / 睡前打烊锁屏弹窗（覆盖在普通奖励/备份弹窗之上）
            if let lockReason = engine.playLock {
                PlayLockOverlayView(engine: engine, reason: lockReason)
            }

            // 家长护眼设置中心面板（家长解锁后可调整限制/重置）
            if engine.showParentSettings {
                ParentEyeCareSettingsSheet(engine: engine)
            }

            // 家长乘法口诀验证门（保持在护眼/锁屏层之上以执行解锁）
            if let gatePurpose = engine.parentGate {
                ParentGateOverlayView(engine: engine, purpose: gatePurpose)
            }

            // 顶部非阻塞里程碑祝贺飘浮横幅
            if let toast = engine.milestoneToast {
                VStack {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            engine.milestoneToast = nil
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(toast)
                                .font(.system(size: 13.5, weight: .heavy))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                            Text("✕")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF7043"), Color(hex: "#E52E71")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                        .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                        .shadow(color: Color.black.opacity(0.22), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 18)
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // 全局防蓝光暖光护眼滤镜层（不拦截任何点击）
            if engine.effectiveWarmFilterOpacity > 0 {
                Color(hex: "#FFB74D")
                    .opacity(engine.effectiveWarmFilterOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onReceive(eyeTimer) { _ in
            engine.tickEyeCareSecond()
        }
    }

    private func levelNumberClamped(_ n: Int) -> Int {
        max(1, min(engine.currentMaxStageCount, n))
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
            // 1. 顶部招牌《满满的奇妙料理城》 + 自适应货币与奖励入口芯片条
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    homeBrandBadge
                    Spacer(minLength: 4)
                    headerCurrencyPills
                }
                VStack(alignment: .leading, spacing: 8) {
                    homeBrandBadge
                    ScrollView(.horizontal, showsIndicators: false) {
                        headerCurrencyPills
                    }
                }
            }

            // 2. 语数英三大主题场馆切换横幅 (🍲 拼音料理屋 | 🧁 数学烘焙坊 | 🧃 英语饮品吧)
            subjectVenueSwitcherBar

            // 3. 厨神头衔条 + 今日小厨神目标（窄屏自动堆叠不挤压）
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    chefRankBar
                    dailyQuestsBar
                }
                VStack(spacing: 8) {
                    chefRankBar
                    dailyQuestsBar
                }
            }

            // 可展开的魔法锅具换装抽屉
            if engine.showSkinDrawer {
                potSkinDrawerView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // 4. 五大主 Tab 切换栏（闯关厨房 | 图鉴宝典 | 萌宠乐园 | 公主衣橱 | 成长档案）
            ViewThatFits(in: .horizontal) {
                mainFiveTabsRow
                ScrollView(.horizontal, showsIndicators: false) {
                    mainFiveTabsRow
                }
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
                case .paradise:
                    RewardParadiseTabView(engine: engine)
                case .recipe:
                    RecipeBookView(engine: engine)
                case .garden:
                    PrincessWardrobeTabView(engine: engine)
                case .records:
                    RecordsAndWrongView(engine: engine)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var homeBrandBadge: some View {
        HStack(spacing: 10) {
            Button {
                engine.audio.sfxTap()
                withAnimation(.spring(response: 0.28)) {
                    engine.showSkinDrawer.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Color(hex: "#FFE8C2"), Color(hex: "#FFC97A")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(hex: "#D9953B"), radius: 0, x: 0, y: 3)
                    PotVectorView(skin: engine.currentPotSkin, size: 38, animated: false, gentleMotion: gentleMotion)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("满满的奇妙料理城")
                        .font(.system(size: 19, weight: .black))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .lineLimit(1)
                    Text("沪教一年级 · 语数英")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [themeColor, Color(hex: "#FF8A48")], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                        .fixedSize()
                }
                Text(engine.mascotLine)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(themeColor.opacity(0.26), lineWidth: 1.8))
        )
    }

    private var headerCurrencyPills: some View {
        HStack(spacing: 7) {
            statPill(icon: "🪙", value: "\(engine.progress.coins)", label: "星光币", color: Color(hex: "#E63946"), tab: .paradise)
            statPill(icon: "🎟️", value: "\(engine.progress.gachaTickets)", label: "扭蛋券", color: Color(hex: "#D97706"), tab: .paradise)
            statPill(icon: "🧵", value: "\(engine.progress.starThread)", label: "丝线", color: Color(hex: "#9B6EF3"), tab: .garden)
            statPill(icon: "🌟", value: "\(engine.progress.petCandy)", label: "糖果", color: Color(hex: "#2FB380"), tab: .paradise)

            // 星星之路 & 段位晋升领奖入口（带可领小红点）
            Button {
                engine.audio.sfxTap()
                showMilestoneDrawer = true
            } label: {
                HStack(spacing: 6) {
                    Text("⭐")
                        .font(.system(size: 17))
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text("\(engine.progress.totalStars)★")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#D97706"))
                            if claimableGiftCount > 0 {
                                Text("\(claimableGiftCount)礼")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color(hex: "#E52E71")))
                            }
                        }
                        Text("星星之路")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(claimableGiftCount > 0 ? Color(hex: "#FFF4D9") : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(claimableGiftCount > 0 ? Color(hex: "#F5A623") : Color(hex: "#F5A623").opacity(0.32), lineWidth: claimableGiftCount > 0 ? 2.0 : 1.5)
                        )
                )
            }
            .buttonStyle(.plain)

            // 每日幸运大转盘快捷入口
            Button {
                engine.audio.sfxTap()
                showDailyWheelModal = true
            } label: {
                HStack(spacing: 5) {
                    Text("🎡")
                        .font(.system(size: 17))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(engine.canSpinDailyWheel ? "免费转" : "已抽奖")
                            .font(.system(size: 12.5, weight: .black))
                            .foregroundColor(engine.canSpinDailyWheel ? Color(hex: "#E52E71") : Color(hex: "#2B7F4A"))
                        Text("幸运转盘")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(engine.canSpinDailyWheel ? Color(hex: "#FFF0F5") : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(engine.canSpinDailyWheel ? Color(hex: "#E05385") : Color.black.opacity(0.1), lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var mainFiveTabsRow: some View {
        HStack(spacing: 8) {
            tabButton(tab: .map, title: "🍳 闯关厨房")
            tabButton(tab: .recipe, title: "📖 图鉴宝典")
            tabButton(tab: .paradise, title: "🦄 萌宠乐园")
            tabButton(tab: .garden, title: "👗 公主衣橱")
            tabButton(tab: .records, title: "🏆 成长档案")
        }
    }

    // MARK: - 语数英三大场馆切换卡片条
    private var subjectVenueSwitcherBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                venueButtonsContent
            }
            VStack(spacing: 8) {
                venueButtonsContent
            }
        }
    }

    @ViewBuilder
    private var venueButtonsContent: some View {
        let pinyinCount = LevelRepository.allUniqueCharacters.count
        let mathCount = HujiaoCurriculumRepository.allQuestions.filter { $0.id.hasPrefix("hjm_") }.count
        let englishCount = HujiaoCurriculumRepository.allQuestions.filter { $0.id.hasPrefix("hje_") }.count

        venueButton(
            subject: .pinyin,
            badge: "\(LevelRepository.levels.count)关 · \(pinyinCount)字",
            desc: "声母+无调韵母+四声调料瓶"
        )
        venueButton(
            subject: .math,
            badge: "\(HujiaoCurriculumRepository.mathStages.count)关 · \(mathCount)题",
            desc: "沪教一上/一下 · 5大互动教具"
        )
        venueButton(
            subject: .english,
            badge: "\(HujiaoCurriculumRepository.englishStages.count)关 · \(englishCount)题",
            desc: "沪教牛津上海版 · 听说与鲜果拼句"
        )
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
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(subject.title)
                        .font(.system(size: 15.5, weight: .black))
                        .foregroundColor(isSelected ? .white : Color(hex: "#3B2E22"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Spacer(minLength: 4)

                    if isSelected {
                        Text("当前场馆 ✓")
                            .font(.system(size: 10.5, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.16)))
                    }
                }
                .frame(minHeight: 22)

                HStack(spacing: 6) {
                    Text(badge)
                        .font(.system(size: 10.5, weight: .heavy))
                        .foregroundColor(isSelected ? color : .white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(isSelected ? Color.white : color))

                    Text(desc)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(isSelected ? Color.white.opacity(0.92) : Color(hex: "#8A7765"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .frame(minWidth: 0, idealWidth: 115, maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - 厨神等级、伴读守护神兽与换锅/段位大礼按钮
    private var chefRankBar: some View {
        let info = engine.chefRank
        let stars = engine.progress.totalStars
        let pet = engine.equippedPet
        let petStage = engine.equippedPetStage
        let rankGiftCount = engine.claimableRankMilestones.count

        return HStack(spacing: 10) {
            Button {
                engine.audio.sfxSpark()
                engine.activeTab = .garden
                engine.audio.speakText("满满小公主的魔法衣橱！", slow: false)
            } label: {
                PrincessAvatarVectorView(progress: engine.progress, size: 44, animated: false, gentleMotion: gentleMotion)
            }
            .buttonStyle(.plain)

            Button {
                engine.audio.sfxPetHappy()
                engine.activeTab = .paradise
                engine.audio.speakText("\(pet.name)陪你闯关！", slow: false)
            } label: {
                GuardianPetVectorView(species: pet, stage: petStage, size: 42, animated: false, gentleMotion: gentleMotion)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Button {
                        engine.audio.sfxTap()
                        showMilestoneDrawer = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(info.name)
                                .font(.system(size: 13.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#4A2E14"))
                            if rankGiftCount > 0 {
                                Text("🎁\(rankGiftCount)")
                                    .font(.system(size: 10.5, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color(hex: "#E52E71")))
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Text("🦄 \(pet.name)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A4B12"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.85)))
                        .lineLimit(1)
                }
                if let nextName = info.nextRankName, let nextMin = info.nextMinStars {
                    Text("再拿 \(max(0, nextMin - stars))★ 升级 → \(nextName)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .lineLimit(1)
                } else {
                    Text("已达最高料理城主厨等级 ✨")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#F07D2E"))
                }
            }
            Spacer(minLength: 4)
            Button {
                engine.audio.sfxTap()
                withAnimation(.spring(response: 0.28)) {
                    engine.showSkinDrawer.toggle()
                }
            } label: {
                Text("🍲 换锅具")
                    .font(.system(size: 12.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#8A4B12"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 11).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "#F07D2E").opacity(0.35), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color(hex: "#FFF6E5"), Color(hex: "#FFE8C5")], startPoint: .leading, endPoint: .trailing))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#F07D2E").opacity(0.28), lineWidth: 1.5))
        )
    }

    // MARK: - 今日小厨神目标栏（含 3/3 全清大礼状态 & 转盘快捷入口）
    private var dailyQuestsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
                            Text(q.claimed ? "✓已领" : (q.isCompleted ? "🎁领礼服" : "\(q.current)/\(q.goal)"))
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

                // 3/3 每日全清大礼盒进度提示
                Text(engine.isDailyFullClearClaimed ? "🎊 3/3全清大礼已发放" : "🎁 3/3全清额外送大礼")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(engine.isDailyFullClearClaimed ? Color(hex: "#2B7F4A") : Color(hex: "#9A3412"))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 11)
                            .fill(engine.isDailyFullClearClaimed ? Color(hex: "#E6F7ED") : Color(hex: "#FFF4D9"))
                    )
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

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
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
                            PotVectorView(skin: skin, size: 54, animated: false, gentleMotion: gentleMotion)
                            Text(skin.name)
                                .font(.system(size: 12.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#3B2E22"))
                            Text(unlocked ? (isCurrent ? "✓ 使用中" : "点我换上") : "需 \(skin.needStars) ★")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(unlocked ? (isCurrent ? Color(hex: "#2B7F4A") : Color(hex: "#F07D2E")) : .gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minWidth: 115)
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
        }
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.95)))
    }

    private func tabButton(tab: HomeTab, title: String) -> some View {
        let on = (engine.activeTab == tab)
        return Button {
            engine.audio.sfxTap()
            engine.activeTab = tab
        } label: {
            Text(title)
                .font(.system(size: 13.5, weight: .heavy))
                .foregroundColor(on ? .white : Color(hex: "#5A4634"))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Text(stageInfo.title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .multilineTextAlignment(.center)
                    Text(stageInfo.sub)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .multilineTextAlignment(.center)

                    Text(stageInfo.wrongCount > 0 ? "🎯 这一关还有 \(stageInfo.wrongCount) 道以前错过的题，这次把它们全部拿下！" : "✨ 这一关熟门熟路啦，可以挑战「大火」拿双倍公主华服礼盒！")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#B25614"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: "#FFF3DC")))

                    // 拼音专属快捷开关
                    if engine.currentSubject == .pinyin {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 10)], spacing: 10) {
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
            }
            .frame(maxWidth: 490)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.22), radius: 20, y: 10)
            )
            .padding(20)
        }
    }

    private func dailyWheelResultFallbackOverlay(_ slice: DailyWheelSlice) -> some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.dailyWheelResult = nil
                }

            VStack(spacing: 12) {
                Text(slice.emoji)
                    .font(.system(size: 48))
                Text("🎡 幸运大转盘中奖啦！")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(Color(hex: "#4A2E14"))
                Text(slice.title)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(Color(hex: "#E52E71"))
                Button("开心收下 ✓") {
                    engine.audio.sfxTap()
                    engine.dailyWheelResult = nil
                }
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color(hex: "#2FB380")))
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#FFFDF9"))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: "#F5A623"), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.25), radius: 18, y: 8)
            )
            .padding(20)
        }
    }
}

// MARK: - 🌟 星星之路（10~90★）& 👑 厨神段位晋升大礼中心弹窗
public struct StarPathAndRankGiftOverlay: View {
    @ObservedObject public var engine: GameEngine
    @Binding public var isPresented: Bool
    @State private var sectionTab: Int = 0 // 0 星星之路, 1 段位大礼

    public init(engine: GameEngine, isPresented: Binding<Bool>) {
        self.engine = engine
        self._isPresented = isPresented
    }

    public var body: some View {
        let totalStars = engine.progress.totalStars

        return ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🌟 星星之路 & 厨神段位晋升大礼")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(Color(hex: "#4A2E14"))
                        Text("当前三科累计 \(totalStars) ★ · 段位：\(engine.chefRank.name)")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(Color(hex: "#D97706"))
                    }
                    Spacer()
                    Button {
                        engine.audio.sfxTap()
                        isPresented = false
                    } label: {
                        Text("完成 ✕")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#5A4634"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color(hex: "#F5EFE6")))
                    }
                    .buttonStyle(.plain)
                }

                // 切换标签
                HStack(spacing: 8) {
                    milestoneTabButton(
                        index: 0,
                        title: "⭐ 星星之路 (10~90★)",
                        badge: engine.claimableStarMilestones.count
                    )
                    milestoneTabButton(
                        index: 1,
                        title: "👑 厨神段位晋升礼",
                        badge: engine.claimableRankMilestones.count
                    )
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        if sectionTab == 0 {
                            ForEach(StarMilestone.all) { item in
                                let claimed = engine.isStarMilestoneClaimed(item.needStars)
                                let unlocked = totalStars >= item.needStars
                                milestoneRow(
                                    badgeText: "\(item.needStars) ★",
                                    title: item.title,
                                    rewardDesc: item.rewardDesc,
                                    claimed: claimed,
                                    unlocked: unlocked,
                                    remainText: "还差 \(max(0, item.needStars - totalStars)) ★",
                                    accent: Color(hex: "#F5A623")
                                ) {
                                    engine.claimStarMilestone(item.needStars)
                                }
                            }
                        } else {
                            ForEach(ChefRankMilestone.all.filter { $0.level > 0 }) { rank in
                                let claimed = engine.progress.claimedRankMilestones.contains(rank.level)
                                let unlocked = totalStars >= rank.minStars
                                milestoneRow(
                                    badgeText: "Lv.\(rank.level) · \(rank.minStars)★",
                                    title: rank.name,
                                    rewardDesc: rank.rewardDesc,
                                    claimed: claimed,
                                    unlocked: unlocked,
                                    remainText: "还差 \(max(0, rank.minStars - totalStars)) ★",
                                    accent: Color(hex: "#E05385")
                                ) {
                                    engine.claimRankPromotionGift(rank.level)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(22)
            .frame(maxWidth: 600)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(hex: "#FFFDF9"))
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color(hex: "#F5A623").opacity(0.45), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.28), radius: 22, y: 10)
            )
            .padding(20)
        }
        .onAppear {
            if engine.claimableStarMilestones.isEmpty && !engine.claimableRankMilestones.isEmpty {
                sectionTab = 1
            }
        }
    }

    private func milestoneTabButton(index: Int, title: String, badge: Int) -> some View {
        let on = (sectionTab == index)
        return Button {
            engine.audio.sfxTap()
            sectionTab = index
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 13.5, weight: .heavy))
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color(hex: "#E52E71")))
                }
            }
            .foregroundColor(on ? .white : Color(hex: "#5A4634"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(on ? Color(hex: "#F07D2E") : Color(hex: "#F5EFE6"))
            )
        }
        .buttonStyle(.plain)
    }

    private func milestoneRow(
        badgeText: String,
        title: String,
        rewardDesc: String,
        claimed: Bool,
        unlocked: Bool,
        remainText: String,
        accent: Color,
        onClaim: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Text(badgeText)
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundColor(unlocked ? .white : Color(hex: "#8A7765"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(unlocked ? accent : Color(hex: "#EFE7D8")))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#3B2E22"))
                Text("大礼内容：\(rewardDesc)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#8A4B12"))
            }

            Spacer(minLength: 6)

            if claimed {
                Text("✓ 已领取")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#2B7F4A"))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "#E6F7ED")))
            } else if unlocked {
                Button(action: onClaim) {
                    Text("🎁 立即领奖")
                        .font(.system(size: 12.5, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [accent, Color(hex: "#E52E71")], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                }
                .buttonStyle(.plain)
            } else {
                Text(remainText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "#F5EFE6")))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(claimed ? Color(hex: "#F7FBF8") : (unlocked ? Color(hex: "#FFF8EB") : Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(unlocked && !claimed ? accent : Color.black.opacity(0.08), lineWidth: unlocked && !claimed ? 2.0 : 1.2)
                )
        )
    }
}
