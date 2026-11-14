import SwiftUI

// MARK: - 1. 顶部护眼状态快捷胶囊条
public struct EyeCareTopBarView: View {
    @ObservedObject public var engine: GameEngine

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                posturePrompt
                Spacer(minLength: 6)
                topBarControls
            }
            VStack(alignment: .leading, spacing: 6) {
                posturePrompt
                ScrollView(.horizontal, showsIndicators: false) {
                    topBarControls
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#F1F7EE"))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#3EA865").opacity(0.28), lineWidth: 1.2))
        )
    }

    private var posturePrompt: some View {
        HStack(spacing: 8) {
            // 护眼坐姿与距离提示
            HStack(spacing: 6) {
                Text("👁️")
                    .font(.system(size: 14))
                Text("护眼小卫士：请保持眼睛离屏幕一臂远（约50厘米）")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#2E5A36"))
                    .lineLimit(1)
            }

            if let warn = engine.timeWarning {
                Text(warn)
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B25614"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: "#FFF3D6")))
                    .lineLimit(1)
            }
        }
    }

    private var topBarControls: some View {
        HStack(spacing: 8) {
            // 一键切换暖光护眼纸张滤镜
            Button {
                engine.audio.sfxTap()
                engine.progress.eyeCare.warmFilter.toggle()
                engine.saveProgress()
            } label: {
                HStack(spacing: 4) {
                    Text(engine.progress.eyeCare.warmFilter ? "☀️ 暖光护眼:开" : "☀️ 暖光护眼:关")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(engine.progress.eyeCare.warmFilter ? Color(hex: "#8A4B12") : Color(hex: "#5A4634"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(engine.progress.eyeCare.warmFilter ? Color(hex: "#FFECC8") : Color.white.opacity(0.85))
                        .overlay(Capsule().stroke(Color(hex: "#D9953B").opacity(0.45), lineWidth: 1.2))
                )
            }
            .buttonStyle(.plain)

            // 主动进入 30 秒远眺护眼操
            Button {
                engine.startEyeRestBreak()
            } label: {
                HStack(spacing: 4) {
                    Text("🌿 远眺休息 (\(engine.minutesUntilNextEyeRest)分后)")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#246B43"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(hex: "#E3F6EA"))
                        .overlay(Capsule().stroke(Color(hex: "#3EA865").opacity(0.45), lineWidth: 1.2))
                )
            }
            .buttonStyle(.plain)

            // 一键打开存档备份/导出弹窗（iPad / Mac 随时可见）
            Button {
                engine.audio.sfxTap()
                engine.importExportMessage = nil
                engine.showBackupModal = true
            } label: {
                HStack(spacing: 4) {
                    Text("💾 存档备份")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#B25614"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(hex: "#FFF3D6"))
                        .overlay(Capsule().stroke(Color(hex: "#F07D2E").opacity(0.45), lineWidth: 1.2))
                )
            }
            .buttonStyle(.plain)

            // 今日已用时长与家长设置入口
            Button {
                engine.requestParentGate(.settings)
            } label: {
                HStack(spacing: 4) {
                    Text("⏳ 今日 \(engine.todayPlayedMinutes)/\(engine.progress.todayAllowedMinutes)分 · 🔒家长设置")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#4A358E"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(hex: "#EFEFFD"))
                        .overlay(Capsule().stroke(Color(hex: "#7A6EE6").opacity(0.4), lineWidth: 1.2))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 2. 20-20-20 森林绿洲护眼休息全屏弹窗
public struct EyeRestOverlayView: View {
    @ObservedObject public var engine: GameEngine
    @State private var breatheScale: Bool = false

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        ZStack {
            // 柔和森林豆沙绿护眼背景（放松睫状肌）
            LinearGradient(
                colors: [Color(hex: "#1E4631").opacity(0.88), Color(hex: "#2A5C40").opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#A8E6CF").opacity(0.25))
                            .frame(width: 136, height: 136)
                            .scaleEffect(engine.progress.eyeCare.gentleMotion ? 1.0 : (breatheScale ? 1.15 : 0.92))
                            .animation(
                                engine.progress.eyeCare.gentleMotion
                                    ? .default
                                    : .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: breatheScale
                            )

                        Circle()
                            .fill(Color(hex: "#DCEDC1"))
                            .frame(width: 96, height: 96)

                        Text("🌲👀🌿")
                            .font(.system(size: 34))
                    }
                    .onAppear {
                        if !engine.progress.eyeCare.gentleMotion {
                            breatheScale = true
                        }
                    }
                    .onDisappear {
                        withAnimation(.easeOut(duration: 0.1)) {
                            breatheScale = false
                        }
                    }
                    .onCompatChange(of: engine.progress.eyeCare.gentleMotion) { isGentle in
                        if isGentle {
                            withAnimation(.easeOut(duration: 0.15)) {
                                breatheScale = false
                            }
                        } else {
                            breatheScale = true
                        }
                    }

                    Text("🌿 小熊护眼时间 · 让眼睛做个深呼吸")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(Color(hex: "#214E34"))
                        .multilineTextAlignment(.center)

                    Text("你已经认真学习了 \(engine.progress.eyeCare.restIntervalMin) 分钟啦！跟着小熊团团做 3 件护眼小事：")
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(Color(hex: "#3D6B50"))
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 10) {
                        eyeStepRow(num: "1", icon: "🏞️", text: "抬头望向窗外或 6 米（20英尺）以外的远处绿植")
                        eyeStepRow(num: "2", icon: "😌", text: "轻轻闭上眼睛再睁开，慢速眨眼 10 下润润眼")
                        eyeStepRow(num: "3", icon: "🪑", text: "挺直小背脊，检查眼睛离屏幕是否有一臂远（约50厘米）")
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.78))
                    )

                    // 倒计时大圆环
                    HStack(spacing: 10) {
                        Text("⏳ 护眼倒计时：")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Color(hex: "#214E34"))
                        Text("\(engine.restRemaining) 秒")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#1B7A43"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#D4F5E2"))
                            .overlay(Capsule().stroke(Color(hex: "#2FB380"), lineWidth: 2))
                    )

                    Button {
                        engine.requestParentGate(.skipRest)
                    } label: {
                        Text("🔒 家长验证跳过本次休息")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(Color(hex: "#5A7A66"))
                            .padding(.top, 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(26)
            }
            .frame(maxWidth: 540)
            .fixedSize(horizontal: false, vertical: false)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(LinearGradient(colors: [Color(hex: "#F2FBF5"), Color(hex: "#E1F5E8")], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color(hex: "#56C596"), lineWidth: 3))
                    .shadow(color: Color.black.opacity(0.25), radius: 24, y: 10)
            )
            .padding(20)
        }
    }

    private func eyeStepRow(num: String, icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(num)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color(hex: "#2FB380")))
            Text(icon)
                .font(.system(size: 18))
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#214E34"))
            Spacer()
        }
    }
}

// MARK: - 3. 每日时长到达上限 / 睡前打烊锁屏弹窗
public struct PlayLockOverlayView: View {
    @ObservedObject public var engine: GameEngine
    public let reason: PlayLockReason

    public init(engine: GameEngine, reason: PlayLockReason) {
        self.engine = engine
        self.reason = reason
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1B2838").opacity(0.90), Color(hex: "#2C3E50").opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Text(reason == .bedtime ? "🌙😴✨" : "🏞️⚽🌳")
                        .font(.system(size: 48))

                    Text(reason == .bedtime ? "奇妙料理城打烊休息啦" : "今日护眼约定时间到啦！")
                        .font(.system(size: 25, weight: .black))
                        .foregroundColor(Color(hex: "#3B2E22"))
                        .multilineTextAlignment(.center)

                    Text(
                        reason == .bedtime
                            ? "现在是夜间休息时间（\(engine.progress.eyeCare.bedtimeHour):00 – 次日 0\(engine.progress.eyeCare.wakeHour):00），小熊团团和小动物们都去睡觉喽，小朋友也要早点休息长高高！"
                            : "今天你已经在料理城学习了 \(engine.todayPlayedMinutes) 分钟，收获满满！快去户外跑一跑、看看远处的天空和绿树，明天再来闯关吧！"
                    )
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(Color(hex: "#5A4634"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                    // 今日收获展示（自适应网格防溢出）
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                        summaryBadge(icon: "⭐", label: "累计总星", value: "\(engine.progress.totalStars)")
                        summaryBadge(icon: "📖", label: "料理图鉴", value: "\(engine.progress.totalCollectionCount)")
                        summaryBadge(icon: "👗", label: "公主衣橱", value: "\(engine.progress.unlockedFashionCount)/30")
                        summaryBadge(icon: "🦄", label: "守护萌宠", value: "\(engine.progress.unlockedPetCount)/12")
                    }
                    .padding(.vertical, 6)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 185), spacing: 12)], spacing: 10) {
                        Button {
                            engine.requestParentGate(.extendTime)
                        } label: {
                            Text("🔒 家长验证延长 15 分钟")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#2FB380")))
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.requestParentGate(.settings)
                        } label: {
                            Text("⚙️ 家长护眼设置")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(Color(hex: "#4A2E14"))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FFF0D6")))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)
                }
                .padding(26)
            }
            .frame(maxWidth: 540)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [Color(hex: "#FFFDF9"), Color(hex: "#F2EFE6")], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#D9953B"), lineWidth: 2.5))
                    .shadow(color: Color.black.opacity(0.3), radius: 24, y: 10)
            )
            .padding(20)
        }
    }

    private func summaryBadge(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 22))
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "#4A2E14"))
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#8A7765"))
        }
        .frame(width: 110)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
    }
}

// MARK: - 4. 家长乘法口诀验证门（防止低龄儿童自行关闭护眼锁）
public struct ParentGateOverlayView: View {
    @ObservedObject public var engine: GameEngine
    public let purpose: ParentGatePurpose

    @State private var factorA: Int = Int.random(in: 6...9)
    @State private var factorB: Int = Int.random(in: 6...9)
    @State private var options: [Int] = []
    @State private var errorHint: String? = nil

    public init(engine: GameEngine, purpose: ParentGatePurpose) {
        self.engine = engine
        self.purpose = purpose
    }

    public var body: some View {
        let answer = factorA * factorB

        return ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.parentGate = nil
                }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Text("🔒 家长护眼验证")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color(hex: "#3B2E22"))

                    Text("为保护小朋友视力，请家长完成下方乘法验证：")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#7A624B"))
                        .multilineTextAlignment(.center)

                    Text("\(factorA) × \(factorB) = ?")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#4A358E"))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 28)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#F5F2FF")))

                    if let err = errorHint {
                        Text(err)
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(Color(hex: "#E25247"))
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                        ForEach(options, id: \.self) { opt in
                            Button {
                                if opt == answer {
                                    engine.audio.sfxWin()
                                    engine.handleParentGatePassed(purpose)
                                } else {
                                    engine.audio.sfxBad()
                                    errorHint = "答案不对哦，请家长来点选～"
                                    regenerateQuestion()
                                }
                            } label: {
                                Text("\(opt)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(Color(hex: "#3B2E22"))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white)
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#7A6EE6").opacity(0.45), lineWidth: 1.8))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("取消") {
                        engine.audio.sfxTap()
                        engine.parentGate = nil
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
                    .padding(.top, 4)
                }
                .padding(24)
            }
            .frame(maxWidth: 420)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#FFFDF9"))
                    .shadow(color: Color.black.opacity(0.25), radius: 20, y: 8)
            )
            .padding(20)
            .onAppear {
                regenerateQuestion()
            }
        }
    }

    private func regenerateQuestion() {
        factorA = Int.random(in: 6...9)
        factorB = Int.random(in: 6...9)
        let ans = factorA * factorB
        var set = Set<Int>([ans])
        let candidates = [ans - 6, ans - 3, ans + 3, ans + 6, ans + 8, ans - 4]
        for c in candidates.shuffled() where c > 10 {
            set.insert(c)
            if set.count >= 4 { break }
        }
        options = Array(set).sorted()
    }
}

// MARK: - 5. 家长护眼与健康时长设置面板
public struct ParentEyeCareSettingsSheet: View {
    @ObservedObject public var engine: GameEngine
    @State private var showResetRewardsAlert: Bool = false
    @State private var showResetAllAlert: Bool = false
    @State private var resetFeedbackBanner: String? = nil

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.showParentSettings = false
                }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🛡️ 家长护眼与健康时长设置中心")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(Color(hex: "#3B2E22"))
                        Text("今日已用眼 \(engine.todayPlayedMinutes) 分钟 · 当前上限 \(engine.progress.todayAllowedMinutes) 分钟")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(Color(hex: "#2B7F4A"))
                    }
                    Spacer()
                    Button {
                        engine.audio.sfxTap()
                        engine.showParentSettings = false
                    } label: {
                        Text("完成 ✓")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color(hex: "#2FB380")))
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if let banner = resetFeedbackBanner {
                            Text(banner)
                                .font(.system(size: 12.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#246B43"))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#E8F6EE")))
                        }

                        // 1. 屏幕暖光滤镜与动效减负
                        VStack(alignment: .leading, spacing: 8) {
                            Text("☀️ 1. 屏幕蓝光过滤与柔和视觉")
                                .font(.system(size: 14.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#4A2E14"))

                            Toggle("开启纸张暖光护眼滤镜（降低白光眩光与蓝光刺激）", isOn: Binding(
                                get: { engine.progress.eyeCare.warmFilter },
                                set: { engine.progress.eyeCare.warmFilter = $0; engine.saveProgress() }
                            ))
                            .font(.system(size: 13, weight: .semibold))

                            if engine.progress.eyeCare.warmFilter {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Text("暖光浓度：")
                                            .font(.system(size: 12.5, weight: .bold))
                                        ForEach([(1, "轻柔"), (2, "标准推荐"), (3, "强效防蓝光")], id: \.0) { level, title in
                                            let on = (engine.progress.eyeCare.warmStrength == level)
                                            Button {
                                                engine.progress.eyeCare.warmStrength = level
                                                engine.saveProgress()
                                            } label: {
                                                Text(title)
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(on ? .white : Color(hex: "#5A4634"))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 5)
                                                    .background(Capsule().fill(on ? Color(hex: "#D9953B") : Color(hex: "#F5EFE6")))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            Toggle("夜间（19:00后）自动加深暖光保护", isOn: Binding(
                                get: { engine.progress.eyeCare.autoNightWarm },
                                set: { engine.progress.eyeCare.autoNightWarm = $0; engine.saveProgress() }
                            ))
                            .font(.system(size: 13, weight: .semibold))

                            Toggle("柔和动效模式（减弱锅具晃动与高频闪烁动画）", isOn: Binding(
                                get: { engine.progress.eyeCare.gentleMotion },
                                set: { engine.progress.eyeCare.gentleMotion = $0; engine.saveProgress() }
                            ))
                            .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FAF6EE")))

                        // 2. 20-20-20 远眺休息提醒
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🌿 2. 20-20-20 远眺护眼休息操")
                                .font(.system(size: 14.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#214E34"))

                            Toggle("定时弹出「远眺 6 米外绿植」护眼休息锁屏", isOn: Binding(
                                get: { engine.progress.eyeCare.restReminder },
                                set: { engine.progress.eyeCare.restReminder = $0; engine.saveProgress() }
                            ))
                            .font(.system(size: 13, weight: .semibold))

                            if engine.progress.eyeCare.restReminder {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Text("每隔多久休息：")
                                            .font(.system(size: 12.5, weight: .bold))
                                        ForEach([15, 20, 30], id: \.self) { mins in
                                            let on = (engine.progress.eyeCare.restIntervalMin == mins)
                                            Button {
                                                engine.progress.eyeCare.restIntervalMin = mins
                                                engine.saveProgress()
                                            } label: {
                                                Text("\(mins) 分钟")
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(on ? .white : Color(hex: "#214E34"))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 5)
                                                    .background(Capsule().fill(on ? Color(hex: "#2FB380") : Color(hex: "#E6F4EC")))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#F1F9F4")))

                        // 3. 每日总时长与睡前打烊
                        VStack(alignment: .leading, spacing: 8) {
                            Text("⏰ 3. 每日时长上限与睡前打烊")
                                .font(.system(size: 14.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#4A358E"))

                            Toggle("开启每日游戏总时长限制", isOn: Binding(
                                get: { engine.progress.eyeCare.dailyLimitEnabled },
                                set: {
                                    engine.progress.eyeCare.dailyLimitEnabled = $0
                                    engine.checkPlayLockStatus(allowDuringQuestion: true)
                                    engine.saveProgress()
                                }
                            ))
                            .font(.system(size: 13, weight: .semibold))

                            if engine.progress.eyeCare.dailyLimitEnabled {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        Text("每日上限：")
                                            .font(.system(size: 12.5, weight: .bold))
                                        ForEach([20, 30, 40, 60], id: \.self) { mins in
                                            let on = (engine.progress.eyeCare.dailyLimitMin == mins)
                                            Button {
                                                engine.progress.eyeCare.dailyLimitMin = mins
                                                engine.checkPlayLockStatus(allowDuringQuestion: true)
                                                engine.saveProgress()
                                            } label: {
                                                Text("\(mins) 分钟")
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(on ? .white : Color(hex: "#4A358E"))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 5)
                                                    .background(Capsule().fill(on ? Color(hex: "#7A6EE6") : Color(hex: "#EFEFFD")))
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        Button {
                                            engine.grantBonusPlayTime(minutes: 15)
                                        } label: {
                                            Text("🎁 今日临时 +15 分钟")
                                                .font(.system(size: 12, weight: .heavy))
                                                .foregroundColor(Color(hex: "#B25614"))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Capsule().fill(Color(hex: "#FFF0D6")))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            Toggle("睡前自动打烊（晚上 21:00 至次日 07:00 锁屏休息）", isOn: Binding(
                                get: { engine.progress.eyeCare.bedtimeEnabled },
                                set: {
                                    engine.progress.eyeCare.bedtimeEnabled = $0
                                    engine.checkPlayLockStatus(allowDuringQuestion: true)
                                    engine.saveProgress()
                                }
                            ))
                            .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#F6F4FC")))

                        // 4. 家长专属：双重置与新奖励重启管理
                        VStack(alignment: .leading, spacing: 10) {
                            Text("🧰 4. 存档重开与旧奖励清理（已通过家长锁）")
                                .font(.system(size: 14.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#8A3E08"))

                            Text("如果孩子想重新体验「公主衣橱 + 萌宠 + 游乐园」新收集路线，可选择只重置旧奖励并完整保留之前的星星成绩；或一键全部从零重开。")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#6B5642"))

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                                Button {
                                    engine.audio.sfxTap()
                                    showResetRewardsAlert = true
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("🎁 仅重置旧奖励（保留学习成绩）")
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundColor(Color(hex: "#8A4B12"))
                                        Text("清空金币/萌宠/衣橱/游乐园/转盘等奖励，保留所有星星、图鉴和错题")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Color(hex: "#7A624B"))
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: "#FFF4E0"))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#F07D2E").opacity(0.5), lineWidth: 1.5))
                                    )
                                }
                                .buttonStyle(.plain)

                                Button {
                                    engine.audio.sfxTap()
                                    showResetAllAlert = true
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("🗑️ 清空全部记录（从零重开）")
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundColor(Color(hex: "#C62828"))
                                        Text("将星星、图鉴、错题、历史战绩与一切奖励彻底清零，不可恢复")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(Color(hex: "#8E4A4A"))
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: "#FDECEB"))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#E25247").opacity(0.5), lineWidth: 1.5))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FFFBF3")))
                    }
                }
            }
            .padding(22)
            .frame(maxWidth: 620)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(hex: "#FFFDF9"))
                    .shadow(color: Color.black.opacity(0.25), radius: 24, y: 10)
            )
            .padding(20)
            .alert("确认仅重置旧奖励？", isPresented: $showResetRewardsAlert) {
                Button("取消", role: .cancel) {}
                Button("确认仅清空奖励（保留成绩）", role: .destructive) {
                    engine.resetRewardsOnlyKeepLearning()
                    resetFeedbackBanner = "✅ 已重置旧奖励进度！各科学习星星、图鉴与错题本均完整保留。"
                }
            } message: {
                Text("将清空星币、扭蛋券、丝线、糖果、守护萌宠、公主衣橱、游乐园、宝箱与幸运大转盘进度；完整保留各科关卡星星、图鉴收集与错题记录。")
            }
            .alert("确认清空全部记录并从零重开？", isPresented: $showResetAllAlert) {
                Button("取消", role: .cancel) {}
                Button("确认全部清空", role: .destructive) {
                    engine.resetAllProgress()
                    resetFeedbackBanner = "🗑️ 已清空全部学习与奖励记录，祝小公主开启全新冒险！"
                    engine.showParentSettings = false
                }
            } message: {
                Text("此操作不可撤销：全部学习星星、图鉴收集、错题本、历史记录以及金币、萌宠、公主衣橱和游乐园进度都会一并清零。")
            }
        }
    }
}

// MARK: - 6. iPad / Mac 跨端存档备份、一键复制与文件导出中心
public struct BackupAndRestoreOverlayView: View {
    @ObservedObject public var engine: GameEngine
    @State private var jsonText: String = ""

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.showBackupModal = false
                }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("💾 存档备份与导出中心（iPad / Mac 互通）")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(Color(hex: "#3B2E22"))
                            Text("本机每答一题都会自动保存！如在 iPad 更新版本或跨设备游玩，可一键复制存档码或导出到「文件」App。")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(Color(hex: "#7A624B"))
                        }
                        Spacer()
                        Button {
                            engine.audio.sfxTap()
                            engine.showBackupModal = false
                        } label: {
                            Text("关闭 ✕")
                                .font(.system(size: 13.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#5A4634"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color(hex: "#F3ECE0")))
                        }
                        .buttonStyle(.plain)
                    }

                    // 当前存档概览条（聚焦新系统核心收集维度）
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 102), spacing: 8)], spacing: 8) {
                        statTag(icon: "⭐", title: "总星数", val: "\(engine.progress.totalStars)")
                        statTag(icon: "🪙", title: "星光币", val: "\(engine.progress.coins)")
                        statTag(icon: "👗", title: "公主衣橱", val: "\(engine.progress.unlockedFashionCount)/30")
                        statTag(icon: "🦄", title: "守护萌宠", val: "\(engine.progress.unlockedPetCount)/12")
                        statTag(icon: "🏰", title: "游乐园", val: "\(engine.progress.unlockedAttractionCount)/8")
                        statTag(icon: "📖", title: "图鉴总数", val: "\(engine.progress.totalCollectionCount)")
                    }

                    if let msg = engine.importExportMessage {
                        Text(msg)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(msg.hasPrefix("❌") || msg.hasPrefix("⚠️") ? Color(hex: "#D63B2F") : Color(hex: "#246B43"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#E8F6EE")))
                    }

                    // iPad 最省心的一键操作栏
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 175), spacing: 10)], spacing: 10) {
                        Button {
                            engine.copySaveToClipboard()
                            jsonText = engine.exportJSONString()
                            _ = engine.prepareBackupFile()
                        } label: {
                            Text("📋 一键复制存档码")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(colors: [Color(hex: "#F07D2E"), Color(hex: "#E05A1B")], startPoint: .top, endPoint: .bottom))
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.restoreSaveFromClipboard()
                            jsonText = engine.exportJSONString()
                            _ = engine.prepareBackupFile()
                        } label: {
                            Text("📌 一键从剪贴板恢复")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(colors: [Color(hex: "#2FB380"), Color(hex: "#208B60")], startPoint: .top, endPoint: .bottom))
                                )
                        }
                        .buttonStyle(.plain)

                        if let fileURL = engine.preparedBackupFileURL {
                            ShareLink(item: fileURL) {
                                Text("📤 导出到「文件」/ 微信")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(Color(hex: "#4A358E"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "#EFEFFD"))
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#7A6EE6").opacity(0.45), lineWidth: 1.5))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            engine.audio.sfxTap()
                            if engine.prepareBackupFile() != nil {
                                engine.importExportMessage = "✅ 已重新生成最新备份文件！"
                            } else {
                                engine.importExportMessage = "❌ 备份文件生成失败，请重试。"
                            }
                        } label: {
                            Text("🔄 重新生成备份文件")
                                .font(.system(size: 13.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#5A4634"))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(hex: "#F5EFE6"))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.12), lineWidth: 1.2))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("📝 存档 JSON 文本框（也可手动粘贴 JSON 到下方后点右侧「手动合并导入」）：")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#7A624B"))

                        TextEditor(text: $jsonText)
                            .font(.system(size: 11.5, design: .monospaced))
                            .frame(height: 165)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.12), lineWidth: 1))
                    }

                    HStack(spacing: 10) {
                        Text("💡 提示：在 iPad 备忘录里粘贴保存一份存档码，以后随时点「一键从剪贴板恢复」就能找回全部进度！")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(Color(hex: "#8A7765"))
                        Spacer()
                        Button {
                            if let data = jsonText.data(using: .utf8) {
                                engine.importExportMessage = engine.importJSONData(data)
                                jsonText = engine.exportJSONString()
                                _ = engine.prepareBackupFile()
                            }
                        } label: {
                            Text("📥 手动合并导入下方文本")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color(hex: "#3B2E22"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFECC8")))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: 660)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color(hex: "#FFFDF9"))
                    .shadow(color: Color.black.opacity(0.28), radius: 24, y: 10)
            )
            .padding(20)
            .onAppear {
                jsonText = engine.exportJSONString()
                _ = engine.prepareBackupFile()
            }
        }
    }

    private func statTag(icon: String, title: String, val: String) -> some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
                Text(val)
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#3B2E22"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FAF5EB")))
    }
}
