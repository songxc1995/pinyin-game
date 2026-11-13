import SwiftUI

// MARK: - 1. 🎆 礼花粒子爆发视图 (FireworkSparkBurstView)
public struct FireworkSparkBurstView: View {
    public let colorHex: String
    public var gentleMotion: Bool = false

    @State private var expand: Bool = false

    public init(colorHex: String, gentleMotion: Bool = false) {
        self.colorHex = colorHex
        self.gentleMotion = gentleMotion
    }

    public var body: some View {
        let dur: Double = gentleMotion ? 1.25 : 0.90
        let outerDist: CGFloat = expand ? (gentleMotion ? 36 : 48) : 4
        let innerDist: CGFloat = expand ? (gentleMotion ? 20 : 28) : 2

        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * (Double.pi * 2.0 / 12.0)
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: expand ? 4.5 : 9, height: expand ? 4.5 : 9)
                    .shadow(color: Color(hex: colorHex), radius: gentleMotion ? 2 : 5)
                    .offset(x: CGFloat(cos(angle)) * outerDist, y: CGFloat(sin(angle)) * outerDist)
                    .opacity(expand ? 0.0 : 1.0)
            }
            ForEach(0..<6, id: \.self) { j in
                let angle = Double(j) * (Double.pi / 3.0) + 0.25
                Circle()
                    .fill(Color(hex: "#FFD166"))
                    .frame(width: expand ? 3.5 : 6.5, height: expand ? 3.5 : 6.5)
                    .offset(x: CGFloat(cos(angle)) * innerDist, y: CGFloat(sin(angle)) * innerDist)
                    .opacity(expand ? 0.0 : 0.95)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: dur)) {
                expand = true
            }
        }
    }
}

// MARK: - 2. 🌈 局内小公主与守护萌宠伴读台 + 8格彩虹连击能量槽 + 飞金币落点光效 (CompanionPetStageWidget)
public struct CompanionPetStageWidget: View {
    @ObservedObject public var engine: GameEngine

    @State private var coinLandingPulse: Bool = false
    @State private var coinFlyProgress: CGFloat = 0
    @State private var showFlyingCoins: Bool = false

    private let rainbowColors = [
        "#FF595E", "#FF924C", "#FFCA3A", "#8AC926",
        "#2EC4B6", "#1982C4", "#6A4C93", "#E05385"
    ]

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        let pet = engine.equippedPet
        let stage = engine.equippedPetStage
        let dress = engine.progress.equippedItem(for: .dress)
        let gentle = engine.progress.eyeCare.gentleMotion
        let charge = max(0, min(8, engine.rainbowCharge))

        VStack(spacing: 6) {
            ZStack(alignment: .trailing) {
                HStack(spacing: 10) {
                    // 满满小公主实时盛装形象 + 守护萌宠双伴读
                    HStack(spacing: 5) {
                        Button {
                            engine.audio.sfxSpark()
                            engine.audio.speakText("满满小公主身穿\(dress.name)，为你加油！", slow: false)
                        } label: {
                            PrincessAvatarVectorView(
                                progress: engine.progress,
                                size: 54,
                                animated: true,
                                gentleMotion: gentle
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.audio.sfxPetHappy()
                            engine.audio.speakText("\(pet.name)为你加油！\(pet.cheerLine)", slow: false)
                        } label: {
                            GuardianPetVectorView(
                                species: pet,
                                stage: stage,
                                size: 50,
                                animated: true,
                                showHeartBurst: engine.petHeartBurst,
                                gentleMotion: gentle,
                                talentActive: engine.petTalentActive
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // 第一行：宠物名字 + 阶位 + 实效技能标签 + 凤凰护盾 + 华丽度 / 狂热
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                Text("👑 满满 & \(pet.name)")
                                    .font(.system(size: 12.5, weight: .heavy))
                                    .foregroundColor(Color(hex: "#4A2E14"))
                                    .lineLimit(1)

                                Text(GuardianPetSpecies.stageName(for: stage))
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: pet.primaryHex)))

                                Text(pet.effectiveSkillSummary(forStage: stage))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "#9A3412"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: "#FFEDD5")))

                                if pet.kind == .phoenix {
                                    let shields = engine.phoenixShieldsRemaining
                                    Text(shields > 0 ? "🔥 护盾 ×\(shields)" : "🔥 护盾已用")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(shields > 0 ? .white : Color(hex: "#9CA3AF"))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule().fill(
                                                shields > 0
                                                    ? Color(hex: "#E25247")
                                                    : Color.black.opacity(0.08)
                                            )
                                        )
                                }

                                Text("✨ \(engine.progress.totalGlamourScore)")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(Color(hex: "#BE185D"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: "#FCE7F3")))

                                if engine.isFeverMode {
                                    Text("🔥 狂热 1.5x")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule().fill(
                                                LinearGradient(
                                                    colors: [Color(hex: "#FF595E"), Color(hex: "#F59E0B")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        )
                                }
                            }
                        }

                        // 第二行：8 格彩虹连击能量槽（渐亮 + 6/7/8 发光提醒）
                        HStack(spacing: 6) {
                            Text("🌈 彩虹能量")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(charge >= 6 ? Color(hex: "#E05385") : Color(hex: "#7A6EE6"))

                            HStack(spacing: 3) {
                                ForEach(0..<8, id: \.self) { idx in
                                    let filled = idx < charge
                                    let col = Color(hex: rainbowColors[idx])
                                    let nearReadyGlow = filled && charge >= 6 && !gentle
                                    RoundedRectangle(cornerRadius: 3.5)
                                        .fill(
                                            filled
                                                ? col.opacity(0.55 + Double(idx + 1) * 0.056)
                                                : Color.black.opacity(0.08)
                                        )
                                        .frame(width: 14, height: filled && charge >= 7 ? 10 : 8)
                                        .shadow(
                                            color: nearReadyGlow ? col.opacity(0.75) : .clear,
                                            radius: charge >= 7 ? 4 : 2
                                        )
                                        .scaleEffect(filled ? (charge >= 7 ? 1.12 : 1.04) : 1.0)
                                        .animation(.spring(response: 0.28), value: charge)
                                }
                            }

                            Text("\(charge)/8")
                                .font(.system(size: 10.5, weight: .black, design: .rounded))
                                .foregroundColor(charge >= 6 ? Color(hex: "#E05385") : Color(hex: "#8A7765"))

                            if charge == 6 {
                                Text("✨ 快集满啦!")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(Color(hex: "#7A6EE6"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1.5)
                                    .background(Capsule().fill(Color(hex: "#EFEFFD")))
                            } else if charge == 7 {
                                Text("🌟 再对1题爆大奖!")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1.5)
                                    .background(
                                        Capsule().fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#F59E0B"), Color(hex: "#E05385")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    )
                            }
                        }
                    }

                    Spacer(minLength: 4)

                    // 右侧：实时星币胶囊 + 飞金币落点光效与弹跳
                    VStack(alignment: .trailing, spacing: 3) {
                        ZStack {
                            if coinLandingPulse {
                                Capsule()
                                    .stroke(Color(hex: "#F59E0B"), lineWidth: 2.5)
                                    .frame(width: 84, height: 30)
                                    .scaleEffect(1.26)
                                    .opacity(0.25)
                                    .transition(.opacity)
                            }

                            HStack(spacing: 4) {
                                Text("🪙")
                                    .font(.system(size: 14))
                                Text("\(engine.progress.coins)")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundColor(Color(hex: "#B45309"))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(
                                Capsule().fill(
                                    coinLandingPulse
                                        ? Color(hex: "#FDE68A")
                                        : Color(hex: "#FFF8E1")
                                )
                            )
                            .overlay(
                                Capsule().stroke(
                                    coinLandingPulse ? Color(hex: "#F59E0B") : Color(hex: "#FCD34D").opacity(0.6),
                                    lineWidth: coinLandingPulse ? 2 : 1
                                )
                            )
                            .scaleEffect(coinLandingPulse ? (gentle ? 1.07 : 1.15) : 1.0)
                            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: coinLandingPulse)
                        }

                        if let gain = engine.floatingCoinGainText {
                            Text(gain)
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(Color(hex: "#E25247"))
                                .lineLimit(1)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            HStack(spacing: 6) {
                                Text("🎟️ ×\(engine.progress.gachaTickets)")
                                Text("🌟 ×\(engine.progress.petCandy)")
                            }
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                        }
                    }
                }

                // 飞金币轨迹动画（由 engine.floatingCoinBurst 触发飞向右上角星币落点）
                if showFlyingCoins {
                    ForEach(0..<3, id: \.self) { idx in
                        let offsetX = -150.0 * (1.0 - coinFlyProgress) + CGFloat(idx * 10)
                        let arcY = -sin(coinFlyProgress * Double.pi) * (gentle ? 16.0 : 32.0) - CGFloat(idx * 4)
                        Text("🪙")
                            .font(.system(size: 14))
                            .offset(x: offsetX - 18, y: arcY - 8)
                            .opacity(Double(1.0 - max(0.0, (coinFlyProgress - 0.72) / 0.28)))
                    }
                    .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: engine.isFeverMode
                                ? [Color(hex: "#FFF8EB"), Color(hex: "#FFE4EC")]
                                : [Color(hex: "#FFFDF9"), Color(hex: "#FFF4E6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                engine.isFeverMode ? Color(hex: "#FF6B6B").opacity(0.65) : Color(hex: pet.primaryHex).opacity(0.32),
                                lineWidth: engine.isFeverMode ? 2.0 : 1.5
                            )
                    )
            )

            if let burstMsg = engine.rainbowChestBurstMessage {
                HStack(spacing: 6) {
                    Text("🎁")
                    Text(burstMsg)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF6B6B"), Color(hex: "#F07D2E"), Color(hex: "#7A6EE6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onCompatChange(of: engine.floatingCoinBurst) { _ in
            triggerCoinFlyAndLanding(gentle: gentle)
        }
    }

    private func triggerCoinFlyAndLanding(gentle: Bool) {
        coinFlyProgress = 0
        showFlyingCoins = true
        withAnimation(.easeOut(duration: gentle ? 0.35 : 0.44)) {
            coinFlyProgress = 1.0
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 240_000_000)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                coinLandingPulse = true
            }
            try? await Task.sleep(nanoseconds: 260_000_000)
            showFlyingCoins = false
            try? await Task.sleep(nanoseconds: 240_000_000)
            withAnimation(.easeOut(duration: 0.25)) {
                coinLandingPulse = false
            }
        }
    }
}

// MARK: - 3. 🎰 皇家梦幻扭蛋机动态矢量图 (GachaponMachineVectorView)
public struct GachaponMachineVectorView: View {
    public let isSpinning: Bool
    public var pityRemaining: Int = 10
    public var gentleMotion: Bool = false

    public init(
        isSpinning: Bool,
        pityRemaining: Int = 10,
        gentleMotion: Bool = false
    ) {
        self.isSpinning = isSpinning
        self.pityRemaining = pityRemaining
        self.gentleMotion = gentleMotion
    }

    private let capsuleColors: [(String, String)] = [
        ("#FF595E", "#FFE5EC"),
        ("#FFCA3A", "#FFF8E1"),
        ("#8AC926", "#E8F9E9"),
        ("#1982C4", "#E0F4FF"),
        ("#6A4C93", "#F3E8FF"),
        ("#FF758F", "#FFF0F3"),
        ("#2EC4B6", "#E0FBF8")
    ]

    public var body: some View {
        let interval: TimeInterval = gentleMotion ? (1.0 / 15.0) : (1.0 / 30.0)
        TimelineView(.animation(minimumInterval: interval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let bodyShakeDeg: Double = isSpinning
                ? sin(t * 28.0) * (gentleMotion ? 2.4 : 5.2)
                : 0.0
            let bodyBounceY: CGFloat = isSpinning
                ? CGFloat(abs(sin(t * 20.0))) * (gentleMotion ? -2.5 : -5.0)
                : CGFloat(sin(t * 2.0)) * (gentleMotion ? 1.0 : 2.2)
            let crankDeg: Double = isSpinning ? (t * 480.0).truncatingRemainder(dividingBy: 360.0) : 0.0

            ZStack {
                // 柔和皇家背光（旋转时绽放黄金流光）
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: isSpinning ? "#FFCA3A" : "#FFD166").opacity(isSpinning ? 0.62 : 0.40),
                                Color(hex: "#FF758F").opacity(isSpinning ? 0.25 : 0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 118
                        )
                    )
                    .frame(width: 230, height: 230)
                    .scaleEffect(isSpinning ? (1.06 + 0.05 * sin(t * 10.0)) : 1.0)

                VStack(spacing: -10) {
                    // 1. 顶部皇家金冠顶盖
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF6B6B"), Color(hex: "#E63946")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 124, height: 26)
                            .overlay(Capsule().stroke(Color(hex: "#FFD166"), lineWidth: 2.5))
                            .shadow(color: Color(hex: "#C1121F").opacity(0.25), radius: 4, y: 2)

                        Text("👑 ROYAL GACHA")
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#FFF8E1"))
                    }
                    .zIndex(3)

                    // 2. 透明玻璃球舱 + 12 颗双向均匀翻滚的彩色扭蛋球 + 玻璃反光
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.95),
                                        Color(hex: "#E0F4FF").opacity(0.66),
                                        Color(hex: "#BDE0FE").opacity(0.42)
                                    ],
                                    center: .topLeading,
                                    startRadius: 10,
                                    endRadius: 96
                                )
                            )
                            .frame(width: 168, height: 168)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white, Color(hex: "#FFD166"), Color(hex: "#F07D2E")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )

                        // 12 颗彩色扭蛋球（TimelineView 驱动，解决原动画状态不变 Bug）
                        ForEach(0..<12, id: \.self) { i in
                            let pair = capsuleColors[i % capsuleColors.count]
                            let col = i % 4
                            let row = i / 4
                            let restX = CGFloat(col - 1) * 28.0 - 13.0 + CGFloat((row % 2) * 11)
                            let restY = CGFloat(row) * 24.0 - 4.0

                            let speed = 5.5 + Double(i % 4) * 1.6
                            let angle = t * speed + Double(i) * 1.15
                            let spinOffsetX: CGFloat = isSpinning
                                ? CGFloat(cos(angle)) * (gentleMotion ? 14.0 : 28.0)
                                : 0.0
                            let spinOffsetY: CGFloat = isSpinning
                                ? CGFloat(sin(angle * 1.3)) * (gentleMotion ? 12.0 : 26.0)
                                : CGFloat(sin(t * 2.2 + Double(i) * 0.7)) * (gentleMotion ? 1.5 : 3.2)

                            let clampedX = max(-54.0, min(54.0, restX * (isSpinning ? 0.55 : 1.0) + spinOffsetX))
                            let clampedY = max(-52.0, min(52.0, restY * (isSpinning ? 0.45 : 1.0) + spinOffsetY))
                            let ballRot = isSpinning ? (angle * 55.0) : Double(i * 15) + sin(t * 2.0 + Double(i)) * 6.0

                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: pair.0), Color(hex: pair.1)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.white.opacity(0.88), lineWidth: 1.5))
                                    .shadow(color: Color.black.opacity(0.14), radius: 2, y: 1)

                                Path { p in
                                    p.move(to: CGPoint(x: 2, y: 15))
                                    p.addLine(to: CGPoint(x: 28, y: 15))
                                }
                                .stroke(Color.white.opacity(0.75), lineWidth: 1.2)
                                .frame(width: 30, height: 30)

                                Text("★")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white.opacity(0.92))
                                    .offset(y: -5)
                            }
                            .rotationEffect(.degrees(ballRot))
                            .offset(x: clampedX, y: clampedY)
                        }

                        // 双层玻璃高光反光弧
                        Circle()
                            .trim(from: 0.56, to: 0.77)
                            .stroke(Color.white.opacity(0.82), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 146, height: 146)

                        Circle()
                            .trim(from: 0.08, to: 0.16)
                            .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .frame(width: 146, height: 146)
                    }
                    .clipShape(Circle())
                    .zIndex(2)

                    // 3. 扭蛋机红金底座 + 旋转金旋钮 + 高光出球口
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#E63946"), Color(hex: "#C1121F")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 156, height: 96)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color(hex: "#FFD166"), lineWidth: 3)
                            )
                            .shadow(color: Color(hex: "#780000").opacity(0.28), radius: 8, y: 5)

                        VStack(spacing: 7) {
                            // 金色旋转把手
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#FFF3B0"), Color(hex: "#F5A623")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 42, height: 42)
                                    .overlay(Circle().stroke(Color(hex: "#8A4B12"), lineWidth: 2))

                                Capsule()
                                    .fill(Color(hex: "#8A4B12"))
                                    .frame(width: 30, height: 7.5)
                                    .rotationEffect(.degrees(crankDeg))
                            }

                            // 出蛋滑道口（带发光高光边与出球光晕）
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "#2B1810"))
                                    .frame(width: 66, height: 24)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                isSpinning ? Color(hex: "#FFF3B0") : Color(hex: "#FFD166"),
                                                lineWidth: isSpinning ? 2.4 : 1.6
                                            )
                                    )
                                    .shadow(
                                        color: isSpinning ? Color(hex: "#FFD166").opacity(0.85) : .clear,
                                        radius: 6
                                    )

                                if isSpinning {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [Color(hex: "#FFF3B0"), Color(hex: "#FF758F")],
                                                center: .center,
                                                startRadius: 1,
                                                endRadius: 9
                                            )
                                        )
                                        .frame(width: 14, height: 14)
                                } else {
                                    Text("🎁")
                                        .font(.system(size: 11))
                                }
                            }
                        }
                        .offset(y: 4)
                    }
                    .zIndex(1)
                }
                .rotationEffect(.degrees(bodyShakeDeg))
                .offset(y: bodyBounceY)

                // 右上角保底小标签
                VStack {
                    HStack {
                        Spacer()
                        Text("✨ \(pityRemaining) 抽保底神话")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(hex: "#5E340B"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule().fill(Color(hex: "#FFF8E1"))
                                    .overlay(Capsule().stroke(Color(hex: "#FFD166"), lineWidth: 1.5))
                            )
                    }
                    Spacer()
                }
                .padding(4)
            }
        }
    }
}

// MARK: - 4. 🏰 皇家童话游乐园实时动态微缩景观 (CastleDioramaAnimatedView)
public struct CastleDioramaAnimatedView: View {
    @ObservedObject public var engine: GameEngine

    @State private var fireworkBursts: [(id: UUID, xRatio: CGFloat, yRatio: CGFloat, colorHex: String)] = []
    @State private var selectedAttraction: CastleAttraction? = nil
    @State private var bannerTip: String = "✨ 点击天空放烟花，或点游乐园建筑查看专属永久增益！"

    private struct HotspotCoord {
        let id: String
        let xRatio: CGFloat
        let yRatio: CGFloat
    }

    private let attractionCoords: [HotspotCoord] = [
        HotspotCoord(id: "ferris_wheel", xRatio: 0.14, yRatio: 0.48),
        HotspotCoord(id: "air_balloon",  xRatio: 0.27, yRatio: 0.24),
        HotspotCoord(id: "carousel",     xRatio: 0.30, yRatio: 0.72),
        HotspotCoord(id: "fountain",     xRatio: 0.50, yRatio: 0.80),
        HotspotCoord(id: "fireworks",    xRatio: 0.50, yRatio: 0.38),
        HotspotCoord(id: "clock_tower",  xRatio: 0.69, yRatio: 0.54),
        HotspotCoord(id: "music_box",    xRatio: 0.75, yRatio: 0.79),
        HotspotCoord(id: "windmill",     xRatio: 0.87, yRatio: 0.55)
    ]

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        let unlocked = engine.progress.castleUnlocked
        let ownedPets = GuardianPetSpecies.all.filter { (engine.progress.pets[$0.id] ?? 0) > 0 }
        let gentle = engine.progress.eyeCare.gentleMotion
        let interval: TimeInterval = gentle ? (1.0 / 15.0) : (1.0 / 30.0)

        GeometryReader { geo in
            let w = max(240, geo.size.width)
            let h = max(200, geo.size.height)

            ZStack(alignment: .bottom) {
                // 1. 极光渐变夜暮天空与点击放礼花热区
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#19224D"),
                                Color(hex: "#453A88"),
                                Color(hex: "#D9779B"),
                                Color(hex: "#FFE6D4")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w, height: h)
                    .onTapGesture {
                        selectedAttraction = nil
                        triggerRandomFirework()
                    }

                // 2. 全比例自适应动态景观 Canvas（全部采用 xRatio * w / yRatio * h）
                TimelineView(.animation(minimumInterval: interval)) { timeline in
                    let speed = gentle ? 0.42 : 1.0
                    let t = timeline.date.timeIntervalSinceReferenceDate * speed

                    Canvas { context, size in
                        drawParkCanvas(
                            context: &context,
                            size: size,
                            t: t,
                            unlocked: unlocked,
                            gentle: gentle
                        )
                    }
                    .frame(width: w, height: h)
                }
                .allowsHitTesting(false)

                // 3. 8 座设施按比例热区点击气泡触发层
                ForEach(attractionCoords, id: \.id) { spot in
                    if let attr = CastleAttraction.byId(spot.id) {
                        let isBuilt = (unlocked[attr.id] ?? 0) > 0
                        Button {
                            engine.audio.sfxTap()
                            withAnimation(.spring(response: 0.28)) {
                                selectedAttraction = attr
                            }
                            if isBuilt {
                                engine.audio.speakText(attr.cheerSpeech, slow: false)
                                bannerTip = "\(attr.icon) \(attr.name)：\(attr.perkDesc)"
                            } else {
                                bannerTip = "🔒 \(attr.name)（\(attr.costCoins) 🪙）：\(attr.perkDesc)"
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.001))
                                    .frame(width: max(42, w * 0.085), height: max(42, h * 0.20))

                                if !isBuilt {
                                    Text("🔒 \(attr.icon)")
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.black.opacity(0.35)))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .position(x: w * spot.xRatio, y: h * spot.yRatio)
                    }
                }

                // 4. 动态礼花粒子层（按比例定位，永不溢出）
                ForEach(fireworkBursts, id: \.id) { fw in
                    FireworkSparkBurstView(colorHex: fw.colorHex, gentleMotion: gentle)
                        .position(x: w * fw.xRatio, y: h * fw.yRatio)
                }
                .allowsHitTesting(false)

                // 5. 草坪漫步的守护神兽（响应式比例间距）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: max(10, w * 0.028)) {
                        ForEach(Array(ownedPets.prefix(6))) { pet in
                            let st = engine.progress.petStage(for: pet.id)
                            let petSize = min(52, max(38, w * 0.072))
                            Button {
                                engine.audio.sfxPetHappy()
                                engine.audio.speakText("\(pet.name)：\(pet.cheerLine)", slow: false)
                                bannerTip = "🦄 \(pet.name)：\(pet.cheerLine)"
                            } label: {
                                GuardianPetVectorView(
                                    species: pet,
                                    stage: st,
                                    size: petSize,
                                    animated: true,
                                    gentleMotion: gentle
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 6)

                // 6. 点击设施弹出的实效加成详情气泡
                if let attr = selectedAttraction {
                    let built = (unlocked[attr.id] ?? 0) > 0
                    HStack(spacing: 10) {
                        Text(attr.icon)
                            .font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(attr.name)
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(Color(hex: "#3B2E22"))
                                Text(attr.perkShortTag)
                                    .font(.system(size: 10.5, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: attr.primaryHex)))
                            }
                            Text(attr.perkDesc)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#6B5744"))
                                .lineLimit(2)
                        }
                        Spacer(minLength: 4)
                        if !built {
                            Button {
                                engine.unlockCastleAttraction(attr)
                                withAnimation { selectedAttraction = nil }
                            } label: {
                                Text("\(attr.costCoins)🪙点亮")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color(hex: "#E05385")))
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            withAnimation { selectedAttraction = nil }
                        } label: {
                            Text("✕")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#8A7765"))
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.96))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: attr.primaryHex), lineWidth: 1.8))
                            .shadow(color: Color.black.opacity(0.16), radius: 8, y: 3)
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 58)
                    .transition(.scale.combined(with: .opacity))
                }

                // 7. 顶部互动提示条 + 放礼花按钮
                HStack(spacing: 8) {
                    Text(bannerTip)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(hex: "#3B2E22"))
                        .lineLimit(1)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.90)))

                    Spacer(minLength: 4)

                    Button {
                        triggerRandomFirework()
                    } label: {
                        Text("🎆 放烟花")
                            .font(.system(size: 11.5, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#E63946"), Color(hex: "#F07D2E")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(11)
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .frame(height: 255)
    }

    private func triggerRandomFirework() {
        engine.audio.sfxFirework()
        let colors = ["#FFD166", "#FF595E", "#4CC9F0", "#8AC926", "#FF758F", "#E0AAFF"]
        for _ in 0..<2 {
            let item = (
                id: UUID(),
                xRatio: CGFloat.random(in: 0.16...0.84),
                yRatio: CGFloat.random(in: 0.16...0.46),
                colorHex: colors.randomElement() ?? "#FFD166"
            )
            fireworkBursts.append(item)
            let removeId = item.id
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                fireworkBursts.removeAll { $0.id == removeId }
            }
        }
    }

    // MARK: - 游乐园 Canvas 绘制管线（全部比例布局）
    private func drawParkCanvas(
        context: inout GraphicsContext,
        size: CGSize,
        t: Double,
        unlocked: [String: Int],
        gentle: Bool
    ) {
        let w = size.width
        let h = size.height
        let unit = min(w * 0.13, h * 0.36)

        // 1. 极光云海 + 闪烁繁星 + 流星
        drawAuroraSkyAndStars(context: &context, w: w, h: h, t: t, gentle: gentle)

        // 2. 远景与近景软萌草坡
        var hillBack = Path()
        hillBack.move(to: CGPoint(x: 0, y: h * 0.72))
        hillBack.addQuadCurve(to: CGPoint(x: w, y: h * 0.74), control: CGPoint(x: w * 0.5, y: h * 0.54))
        hillBack.addLine(to: CGPoint(x: w, y: h))
        hillBack.addLine(to: CGPoint(x: 0, y: h))
        hillBack.closeSubpath()
        context.fill(hillBack, with: .color(Color(hex: "#74C69D")))

        var hillFront = Path()
        hillFront.move(to: CGPoint(x: 0, y: h * 0.80))
        hillFront.addQuadCurve(to: CGPoint(x: w, y: h * 0.80), control: CGPoint(x: w * 0.5, y: h * 0.67))
        hillFront.addLine(to: CGPoint(x: w, y: h))
        hillFront.addLine(to: CGPoint(x: 0, y: h))
        hillFront.closeSubpath()
        context.fill(hillFront, with: .color(Color(hex: "#52B788")))

        // 3. 中央糖果童话城堡（霓虹呼吸窗口与旗帜）
        drawCandyCastle(context: &context, w: w, h: h, unit: unit, t: t)

        // 4. 八座梦幻游乐园动态设施
        if (unlocked["ferris_wheel"] ?? 0) > 0 {
            drawFerrisWheel(context: &context, cx: w * 0.14, cy: h * 0.48, radius: unit * 0.78, t: t)
        }
        if (unlocked["air_balloon"] ?? 0) > 0 {
            drawHotAirBalloon(context: &context, w: w, h: h, unit: unit, t: t)
        }
        if (unlocked["carousel"] ?? 0) > 0 {
            drawCarousel(context: &context, cx: w * 0.30, cy: h * 0.72, unit: unit, t: t)
        }
        if (unlocked["clock_tower"] ?? 0) > 0 {
            drawClockTower(context: &context, cx: w * 0.69, cy: h * 0.58, unit: unit, t: t)
        }
        if (unlocked["windmill"] ?? 0) > 0 {
            drawCandyWindmill(context: &context, cx: w * 0.87, cy: h * 0.55, unit: unit, t: t)
        }
        if (unlocked["fountain"] ?? 0) > 0 {
            drawGemFountain(context: &context, cx: w * 0.50, cy: h * 0.82, unit: unit, t: t)
        }
        if (unlocked["music_box"] ?? 0) > 0 {
            drawSwanMusicBox(context: &context, cx: w * 0.75, cy: h * 0.80, unit: unit, t: t)
        }
        if (unlocked["fireworks"] ?? 0) > 0 {
            drawRoyalFireworkCannons(context: &context, w: w, h: h, unit: unit, t: t)
        }
    }

    private func drawAuroraSkyAndStars(
        context: inout GraphicsContext,
        w: CGFloat,
        h: CGFloat,
        t: Double,
        gentle: Bool
    ) {
        // 极光彩带
        var aurora = Path()
        aurora.move(to: CGPoint(x: 0, y: h * 0.25))
        aurora.addCurve(
            to: CGPoint(x: w, y: h * 0.20),
            control1: CGPoint(x: w * 0.32, y: h * (0.10 + 0.04 * sin(t * 0.6))),
            control2: CGPoint(x: w * 0.68, y: h * (0.34 + 0.04 * cos(t * 0.7)))
        )
        context.stroke(
            aurora,
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: "#4CC9F0").opacity(0.28),
                    Color(hex: "#8AC926").opacity(0.24),
                    Color(hex: "#F72585").opacity(0.26)
                ]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: w, y: h * 0.35)
            ),
            style: StrokeStyle(lineWidth: h * 0.11, lineCap: .round)
        )

        // 闪烁星点
        let starCoords: [(CGFloat, CGFloat)] = [
            (0.08, 0.16), (0.19, 0.11), (0.35, 0.14), (0.46, 0.09),
            (0.61, 0.15), (0.76, 0.11), (0.91, 0.18), (0.83, 0.28)
        ]
        for (idx, coord) in starCoords.enumerated() {
            let alpha = 0.45 + 0.50 * abs(sin(t * 1.4 + Double(idx) * 0.9))
            let r: CGFloat = (idx % 2 == 0) ? 2.4 : 1.7
            let rect = CGRect(x: w * coord.0 - r, y: h * coord.1 - r, width: r * 2, height: r * 2)
            context.fill(Circle().path(in: rect), with: .color(Color(hex: "#FFF8E1").opacity(alpha)))
        }

        // 流星划过（每 ~5 秒一次）
        if !gentle {
            let cycle = t.truncatingRemainder(dividingBy: 5.0)
            if cycle < 1.2 {
                let p = CGFloat(cycle / 1.2)
                let sx = w * (0.15 + p * 0.55)
                let sy = h * (0.08 + p * 0.22)
                var meteor = Path()
                meteor.move(to: CGPoint(x: sx, y: sy))
                meteor.addLine(to: CGPoint(x: sx - 28, y: sy - 11))
                context.stroke(
                    meteor,
                    with: .linearGradient(
                        Gradient(colors: [Color.white, Color(hex: "#FFD166").opacity(0.0)]),
                        startPoint: CGPoint(x: sx, y: sy),
                        endPoint: CGPoint(x: sx - 28, y: sy - 11)
                    ),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )
            }
        }

        // 梦幻柔云
        for (idx, cxRatio) in [0.18, 0.55, 0.84].enumerated() {
            let drift = CGFloat(sin(t * 0.25 + Double(idx))) * (w * 0.02)
            let cloud = Capsule().path(in: CGRect(x: w * cxRatio + drift - 26, y: h * (0.28 + CGFloat(idx % 2) * 0.06), width: 52, height: 14))
            context.fill(cloud, with: .color(Color.white.opacity(0.26)))
        }
    }

    private func drawCandyCastle(
        context: inout GraphicsContext,
        w: CGFloat,
        h: CGFloat,
        unit: CGFloat,
        t: Double
    ) {
        let cx = w * 0.50
        let cy = h * 0.66
        let bw = unit * 1.45
        let bh = unit * 0.95

        // 主殿 + 左右侧塔
        let mainWall = RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: cx - bw * 0.5, y: cy - bh * 0.8, width: bw, height: bh))
        context.fill(mainWall, with: .color(Color(hex: "#FFF8F0")))

        let sideW = bw * 0.30
        let sideH = bh * 1.28
        let towerL = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: cx - bw * 0.68, y: cy - sideH + bh * 0.20, width: sideW, height: sideH))
        let towerR = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: cx + bw * 0.38, y: cy - sideH + bh * 0.20, width: sideW, height: sideH))
        context.fill(towerL, with: .color(Color(hex: "#FFE5EC")))
        context.fill(towerR, with: .color(Color(hex: "#FFE5EC")))

        // 糖果屋顶
        var mainRoof = Path()
        mainRoof.move(to: CGPoint(x: cx - bw * 0.44, y: cy - bh * 0.80))
        mainRoof.addLine(to: CGPoint(x: cx, y: cy - bh * 1.56))
        mainRoof.addLine(to: CGPoint(x: cx + bw * 0.44, y: cy - bh * 0.80))
        mainRoof.closeSubpath()
        context.fill(mainRoof, with: .color(Color(hex: "#E05385")))

        for tx in [cx - bw * 0.53, cx + bw * 0.53] {
            var cone = Path()
            cone.move(to: CGPoint(x: tx - sideW * 0.6, y: cy - sideH + bh * 0.20))
            cone.addLine(to: CGPoint(x: tx, y: cy - sideH - bh * 0.22))
            cone.addLine(to: CGPoint(x: tx + sideW * 0.6, y: cy - sideH + bh * 0.20))
            cone.closeSubpath()
            context.fill(cone, with: .color(Color(hex: "#9B6EF3")))
        }

        // 霓虹呼吸暖窗与大门
        let glowAlpha = 0.55 + 0.40 * abs(sin(t * 2.0))
        let door = RoundedRectangle(cornerRadius: 8).path(in: CGRect(x: cx - bw * 0.14, y: cy - bh * 0.30, width: bw * 0.28, height: bh * 0.50))
        context.fill(door, with: .color(Color(hex: "#F59E0B").opacity(0.85)))
        for wx in [cx - bw * 0.25, cx + bw * 0.17] {
            let win = Circle().path(in: CGRect(x: wx, y: cy - bh * 0.60, width: bw * 0.11, height: bw * 0.11))
            context.fill(win, with: .color(Color(hex: "#FFD166").opacity(glowAlpha)))
        }
    }

    private func drawFerrisWheel(
        context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        t: Double
    ) {
        var stand = Path()
        stand.move(to: CGPoint(x: cx - radius * 0.56, y: cy + radius * 1.25))
        stand.addLine(to: CGPoint(x: cx, y: cy))
        stand.addLine(to: CGPoint(x: cx + radius * 0.56, y: cy + radius * 1.25))
        context.stroke(stand, with: .color(Color(hex: "#FFD166")), lineWidth: 3)

        let rim = Circle().path(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
        context.stroke(rim, with: .color(Color(hex: "#FF758F")), lineWidth: 3)

        let cols = ["#FF595E", "#FFCA3A", "#8AC926", "#1982C4", "#6A4C93", "#FF9F1C"]
        for i in 0..<6 {
            let ang = t * 0.72 + Double(i) * (Double.pi / 3.0)
            let gx = cx + CGFloat(cos(ang)) * radius
            let gy = cy + CGFloat(sin(ang)) * radius
            var spoke = Path()
            spoke.move(to: CGPoint(x: cx, y: cy))
            spoke.addLine(to: CGPoint(x: gx, y: gy))
            context.stroke(spoke, with: .color(Color.white.opacity(0.75)), lineWidth: 1.4)

            // 保持竖直的马卡龙座舱
            let cabin = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: gx - 6, y: gy - 3, width: 12, height: 10))
            context.fill(cabin, with: .color(Color(hex: cols[i % cols.count])))
            context.stroke(cabin, with: .color(.white.opacity(0.85)), lineWidth: 1)
        }
        context.fill(Circle().path(in: CGRect(x: cx - 5, y: cy - 5, width: 10, height: 10)), with: .color(Color(hex: "#FFD166")))
    }

    private func drawHotAirBalloon(
        context: inout GraphicsContext,
        w: CGFloat,
        h: CGFloat,
        unit: CGFloat,
        t: Double
    ) {
        let bx = w * 0.27 + CGFloat(sin(t * 0.65)) * (w * 0.03)
        let by = h * 0.24 + CGFloat(cos(t * 1.15)) * (h * 0.03)
        let r = unit * 0.42
        let balloon = Circle().path(in: CGRect(x: bx - r, y: by - r * 1.05, width: r * 2, height: r * 2.15))
        context.fill(
            balloon,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#9B6EF3"), Color(hex: "#FF758F"), Color(hex: "#FFD166")]),
                startPoint: CGPoint(x: bx - r, y: by - r),
                endPoint: CGPoint(x: bx + r, y: by + r)
            )
        )
        // 燃烧火苗
        let flame = Circle().path(in: CGRect(x: bx - 3, y: by + r * 1.10, width: 6, height: 6))
        context.fill(flame, with: .color(Color(hex: "#FF9F1C")))
        let basket = RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: bx - 7, y: by + r * 1.32, width: 14, height: 9))
        context.fill(basket, with: .color(Color(hex: "#D97706")))
    }

    private func drawCarousel(
        context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        unit: CGFloat,
        t: Double
    ) {
        let halfW = unit * 0.62
        // 底座与华盖顶棚
        let base = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: cx - halfW, y: cy + unit * 0.16, width: halfW * 2, height: 9))
        context.fill(base, with: .color(Color(hex: "#E05385")))

        // 三匹随波浪起伏的旋转小木马
        let horseColors = ["#FFFFFF", "#FFE5EC", "#BDE0FE"]
        for idx in -1...1 {
            let hx = cx + CGFloat(idx) * (halfW * 0.55)
            let bob = CGFloat(sin(t * 3.0 + Double(idx) * 1.8)) * 5.0
            var pole = Path()
            pole.move(to: CGPoint(x: hx, y: cy - unit * 0.25))
            pole.addLine(to: CGPoint(x: hx, y: cy + unit * 0.16))
            context.stroke(pole, with: .color(Color(hex: "#FFD166")), lineWidth: 1.8)
            let pony = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: hx - 6, y: cy - 3 + bob, width: 12, height: 8))
            context.fill(pony, with: .color(Color(hex: horseColors[idx + 1])))
        }

        var roof = Path()
        roof.move(to: CGPoint(x: cx - halfW * 1.05, y: cy - unit * 0.22))
        roof.addLine(to: CGPoint(x: cx, y: cy - unit * 0.62))
        roof.addLine(to: CGPoint(x: cx + halfW * 1.05, y: cy - unit * 0.22))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(hex: "#FFCA3A")))
        context.stroke(roof, with: .color(Color(hex: "#E05385")), lineWidth: 2)
    }

    private func drawClockTower(
        context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        unit: CGFloat,
        t: Double
    ) {
        let tw = unit * 0.56
        let th = unit * 1.15
        let body = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: cx - tw * 0.5, y: cy - th * 0.65, width: tw, height: th))
        context.fill(body, with: .color(Color(hex: "#FFE8C2")))
        var roof = Path()
        roof.move(to: CGPoint(x: cx - tw * 0.65, y: cy - th * 0.65))
        roof.addLine(to: CGPoint(x: cx, y: cy - th * 1.0))
        roof.addLine(to: CGPoint(x: cx + tw * 0.65, y: cy - th * 0.65))
        roof.closeSubpath()
        context.fill(roof, with: .color(Color(hex: "#C8870A")))

        let dialR = tw * 0.36
        let dialCenter = CGPoint(x: cx, y: cy - th * 0.38)
        let dial = Circle().path(in: CGRect(x: dialCenter.x - dialR, y: dialCenter.y - dialR, width: dialR * 2, height: dialR * 2))
        context.fill(dial, with: .color(.white))
        context.stroke(dial, with: .color(Color(hex: "#C8870A")), lineWidth: 2)

        // 转动的金色分针与时针
        let minAng = t * 1.4
        let hrAng = t * 0.2
        var hands = Path()
        hands.move(to: dialCenter)
        hands.addLine(to: CGPoint(x: dialCenter.x + CGFloat(cos(minAng)) * dialR * 0.72, y: dialCenter.y + CGFloat(sin(minAng)) * dialR * 0.72))
        hands.move(to: dialCenter)
        hands.addLine(to: CGPoint(x: dialCenter.x + CGFloat(cos(hrAng)) * dialR * 0.48, y: dialCenter.y + CGFloat(sin(hrAng)) * dialR * 0.48))
        context.stroke(hands, with: .color(Color(hex: "#8A4B12")), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private func drawCandyWindmill(
        context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        unit: CGFloat,
        t: Double
    ) {
        let tower = RoundedRectangle(cornerRadius: 5).path(in: CGRect(x: cx - unit * 0.28, y: cy, width: unit * 0.56, height: unit * 0.96))
        context.fill(tower, with: .color(Color(hex: "#FFF3B0")))
        // 冒出的糖果彩珠
        for pIdx in 0..<3 {
            let phase = (t * 0.8 + Double(pIdx) * 0.33).truncatingRemainder(dividingBy: 1.0)
            let py = cy - unit * 0.3 - CGFloat(phase) * (unit * 0.5)
            let px = cx + CGFloat(sin(t * 2.0 + Double(pIdx))) * 7.0
            let bubble = Circle().path(in: CGRect(x: px - 3, y: py - 3, width: 6, height: 6))
            context.fill(bubble, with: .color(Color(hex: pIdx == 0 ? "#4CC9F0" : "#FF758F").opacity(1.0 - phase)))
        }
        let bladeLen = unit * 0.62
        for i in 0..<4 {
            let ang = t * 1.35 + Double(i) * (Double.pi / 2.0)
            let bx = cx + CGFloat(cos(ang)) * bladeLen
            let by = cy + CGFloat(sin(ang)) * bladeLen
            var blade = Path()
            blade.move(to: CGPoint(x: cx, y: cy))
            blade.addLine(to: CGPoint(x: bx, y: by))
            context.stroke(blade, with: .color(Color(hex: "#E63946")), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            let candy = Circle().path(in: CGRect(x: bx - 5.5, y: by - 5.5, width: 11, height: 11))
            context.fill(candy, with: .color(Color(hex: i % 2 == 0 ? "#FF758F" : "#4CC9F0")))
        }
        context.fill(Circle().path(in: CGRect(x: cx - 5, y: cy - 5, width: 10, height: 10)), with: .color(Color(hex: "#FFD166")))
    }

    private func drawGemFountain(
        context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        unit: CGFloat,
        t: Double
    ) {
        let poolW = unit * 1.75
        let pool = Ellipse().path(in: CGRect(x: cx - poolW * 0.5, y: cy - 7, width: poolW, height: 17))
        context.fill(pool, with: .color(Color(hex: "#4CC9F0")))
        context.stroke(pool, with: .color(.white), lineWidth: 2)

        for i in -3...3 {
            let bounce = abs(sin(t * 3.1 + Double(i) * 0.5)) * Double(unit * 0.44) + Double(unit * 0.18)
            let dropX = cx + CGFloat(i) * (unit * 0.18)
            let dropY = cy - CGFloat(bounce)
            var jet = Path()
            jet.move(to: CGPoint(x: cx, y: cy))
            jet.addQuadCurve(to: CGPoint(x: dropX, y: dropY), control: CGPoint(x: (cx + dropX) * 0.5, y: dropY - 9))
            context.stroke(jet, with: .color(Color.white.opacity(0.90)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        }
    }

    private func drawSwanMusicBox(
        context: inout GraphicsContext,
        cx: CGFloat,
        cy: CGFloat,
        unit: CGFloat,
        t: Double
    ) {
        let lake = Ellipse().path(in: CGRect(x: cx - unit * 0.72, y: cy - 4, width: unit * 1.44, height: 18))
        context.fill(lake, with: .color(Color(hex: "#90E0EF").opacity(0.88)))
        context.stroke(lake, with: .color(.white.opacity(0.8)), lineWidth: 1.5)

        let rock = CGFloat(sin(t * 1.8)) * 5.0
        let sx = cx + rock
        let swanBody = Ellipse().path(in: CGRect(x: sx - 13, y: cy - 10, width: 26, height: 14))
        context.fill(swanBody, with: .color(.white))
        var neck = Path()
        neck.move(to: CGPoint(x: sx - 7, y: cy - 6))
        neck.addQuadCurve(to: CGPoint(x: sx - 12, y: cy - 20), control: CGPoint(x: sx - 14, y: cy - 13))
        context.stroke(neck, with: .color(.white), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        // 飘起小音符弧
        for nIdx in 0..<2 {
            let lift = CGFloat((t * 1.2 + Double(nIdx) * 0.5).truncatingRemainder(dividingBy: 1.0)) * 22.0
            let noteDot = Circle().path(in: CGRect(x: sx + CGFloat(nIdx * 10) - 2, y: cy - 18 - lift, width: 5, height: 5))
            context.fill(noteDot, with: .color(Color(hex: nIdx == 0 ? "#E0AAFF" : "#FFD166").opacity(0.9)))
        }
    }

    private func drawRoyalFireworkCannons(
        context: inout GraphicsContext,
        w: CGFloat,
        h: CGFloat,
        unit: CGFloat,
        t: Double
    ) {
        for side in [-1.0, 1.0] {
            let cx = w * (side < 0 ? 0.40 : 0.60)
            let cy = h * 0.46
            let cannon = RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: cx - 5, y: cy - 9, width: 10, height: 14))
            context.fill(cannon, with: .color(Color(hex: "#E63946")))
            context.stroke(cannon, with: .color(Color(hex: "#FFD166")), lineWidth: 1.5)
            let sparkR: CGFloat = 3.0 + CGFloat(abs(sin(t * 5.0))) * 2.5
            context.fill(Circle().path(in: CGRect(x: cx - sparkR, y: cy - 12 - sparkR, width: sparkR * 2, height: sparkR * 2)), with: .color(Color(hex: "#FFD166")))
        }
    }
}

// MARK: - 5. 🎰 皇家扭蛋机与五阶神兽养成屋主视图 (RewardParadiseTabView)
public struct RewardParadiseTabView: View {
    @ObservedObject public var engine: GameEngine
    @State private var selectedPetId: String = "fire_dragon"

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var inspectedPet: GuardianPetSpecies {
        GuardianPetSpecies.byId(selectedPetId)
    }

    public var body: some View {
        GeometryReader { outerGeo in
            let isWide = outerGeo.size.width >= 760
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerWealthBar
                    if let toast = engine.petFeedToast {
                        toastBanner(toast)
                    }

                    // 1. 🦄 顶部焦点区：守护神兽互动小屋（摸摸/表演才艺/投喂数学甜品）
                    petInteractiveHouseSection(isWide: isWide)

                    // 2. 🎰 奢华扭蛋机台 + 萌宠图鉴详情双路升阶
                    gachaAndInspectedPetSection(isWide: isWide)

                    // 3. 🌟 12 只守护神兽全图鉴网格
                    petCodexGridSection

                    // 4. 🏰 皇家童话游乐园动态景观 & 8 大设施建设面板
                    castleAmusementParkSection
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            selectedPetId = engine.equippedPet.id
        }
    }

    // MARK: - 顶部财富条（自适应换行防挤压）
    private var headerWealthBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                titleCluster
                Spacer(minLength: 8)
                currencyPills
            }
            VStack(alignment: .leading, spacing: 8) {
                titleCluster
                ScrollView(.horizontal, showsIndicators: false) {
                    currencyPills
                }
            }
        }
    }

    private var titleCluster: some View {
        HStack(spacing: 8) {
            Text("🎰 皇家神兽扭蛋屋 · 城堡游乐园")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(Color(hex: "#4A2E14"))
            Text("已孵化 \(engine.progress.unlockedPetCount)/\(GuardianPetSpecies.all.count)")
                .font(.system(size: 11.5, weight: .heavy))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(hex: "#E63946")))
        }
    }

    private var currencyPills: some View {
        HStack(spacing: 8) {
            wealthChip(emoji: "🪙", text: "\(engine.progress.coins) 星币", fg: "#B45309", bg: "#FEF3C7")
            wealthChip(emoji: "🎟️", text: "\(engine.progress.gachaTickets) 扭蛋券", fg: "#BE185D", bg: "#FCE7F3")
            wealthChip(emoji: "🌟", text: "\(engine.progress.petCandy) 魔法糖果", fg: "#5B21B6", bg: "#EDE9FE")
        }
    }

    private func wealthChip(emoji: String, text: String, fg: String, bg: String) -> some View {
        HStack(spacing: 4) {
            Text(emoji)
            Text(text)
                .font(.system(size: 12.5, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: fg))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color(hex: bg)))
    }

    private func toastBanner(_ toast: String) -> some View {
        HStack(spacing: 8) {
            Text("✨")
            Text(toast)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#4A2E14"))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#FFF8E1"))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#F5A623"), lineWidth: 1.5))
        )
    }

    // MARK: - 1. 🦄 顶部焦点区：神兽互动小屋
    private func petInteractiveHouseSection(isWide: Bool) -> some View {
        let pet = engine.equippedPet
        let stage = engine.equippedPetStage
        let gentle = engine.progress.eyeCare.gentleMotion
        let patsUsed = engine.progress.effectiveDailyPetPatCount
        let patsMax = engine.progress.maxDailyPetPats
        let unlockedDesserts = HujiaoCurriculumRepository.bakeryDesserts.filter {
            (engine.progress.desserts[$0.id] ?? 0) > 0
        }
        let dessertFedToday = engine.progress.isDailyDessertFedToday

        return VStack(alignment: .leading, spacing: 12) {
            Group {
                if isWide {
                    HStack(alignment: .center, spacing: 18) {
                        petInteractiveAvatarStage(pet: pet, stage: stage, gentle: gentle, patsUsed: patsUsed, patsMax: patsMax)
                        petInteractiveControlPanel(
                            pet: pet,
                            stage: stage,
                            patsUsed: patsUsed,
                            patsMax: patsMax,
                            unlockedDesserts: unlockedDesserts,
                            dessertFedToday: dessertFedToday
                        )
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        petInteractiveAvatarStage(pet: pet, stage: stage, gentle: gentle, patsUsed: patsUsed, patsMax: patsMax)
                            .frame(maxWidth: .infinity)
                        petInteractiveControlPanel(
                            pet: pet,
                            stage: stage,
                            patsUsed: patsUsed,
                            patsMax: patsMax,
                            unlockedDesserts: unlockedDesserts,
                            dessertFedToday: dessertFedToday
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFFDF9"), Color(hex: pet.secondaryHex).opacity(0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(hex: pet.primaryHex).opacity(0.40), lineWidth: 2)
                )
        )
    }

    private func petInteractiveAvatarStage(
        pet: GuardianPetSpecies,
        stage: Int,
        gentle: Bool,
        patsUsed: Int,
        patsMax: Int
    ) -> some View {
        Button {
            engine.patPet()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            RadialGradient(
                                colors: [Color.white, Color(hex: pet.secondaryHex).opacity(0.55)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 95
                            )
                        )
                        .frame(width: 170, height: 158)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color(hex: pet.primaryHex).opacity(0.35), lineWidth: 2)
                        )

                    GuardianPetVectorView(
                        species: pet,
                        stage: stage,
                        size: 126,
                        animated: true,
                        showHeartBurst: engine.petHeartBurst,
                        gentleMotion: gentle,
                        talentActive: engine.petTalentActive
                    )
                }

                Text("🤗 点我摸摸头（今日 \(patsUsed)/\(patsMax) 次）")
                    .font(.system(size: 11.5, weight: .black))
                    .foregroundColor(Color(hex: "#BE185D"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "#FCE7F3")))
            }
        }
        .buttonStyle(.plain)
    }

    private func petInteractiveControlPanel(
        pet: GuardianPetSpecies,
        stage: Int,
        patsUsed: Int,
        patsMax: Int,
        unlockedDesserts: [BakeryDessert],
        dessertFedToday: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("🏠 神兽互动小屋 · \(pet.name)")
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(Color(hex: "#3B2E22"))
                Text("Lv.\(stage) \(GuardianPetSpecies.stageName(for: stage))")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: pet.primaryHex)))
                if pet.kind == .phoenix {
                    Text("🔥 护盾 ×\(engine.phoenixShieldsRemaining)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: "#E25247")))
                }
            }

            Text("✨ 当前出战实效：\(pet.effectiveSkillSummary(forStage: stage))")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color(hex: "#9A3412"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#FFF8EE")))

            // 摸头互动 + 表演才艺
            HStack(spacing: 10) {
                Button {
                    engine.patPet()
                } label: {
                    HStack(spacing: 5) {
                        Text("🤗 摸摸抱抱")
                        Text("(\(patsUsed)/\(patsMax))")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8.5)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#FF758F"), Color(hex: "#E05385")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                }
                .buttonStyle(.plain)

                Button {
                    engine.performPetTalent()
                } label: {
                    Text("✨ 表演才艺")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8.5)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#FEF3C7"))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#F59E0B"), lineWidth: 1.5))
                        )
                }
                .buttonStyle(.plain)
            }

            // 投喂已解锁数学烘焙甜品
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("🍰 投喂已解锁甜品")
                        .font(.system(size: 12.5, weight: .black))
                        .foregroundColor(Color(hex: "#3B2E22"))
                    if dessertFedToday {
                        Text("✅ 今日已款待")
                            .font(.system(size: 10.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#2B7F4A"))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#E6F7ED")))
                    } else if !unlockedDesserts.isEmpty {
                        Text("✨ 今日免费特供 (+2成长/+15🪙)")
                            .font(.system(size: 10.5, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#F07D2E")))
                    }
                }

                if unlockedDesserts.isEmpty {
                    Text("💡 在数学烘焙屋通关解锁甜品后，每天可免费挑 1 款甜品款待神兽！")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(unlockedDesserts) { dessert in
                                Button {
                                    engine.feedPetWithUnlockedDessert(dessert.id)
                                } label: {
                                    HStack(spacing: 5) {
                                        Text(dessert.emoji)
                                        Text(dessert.name)
                                            .font(.system(size: 11.5, weight: .bold))
                                    }
                                    .foregroundColor(dessertFedToday ? Color(hex: "#8A7765") : Color(hex: "#5E340B"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(dessertFedToday ? Color(hex: "#F3EFE8") : Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(dessertFedToday ? Color.black.opacity(0.08) : Color(hex: "#F59E0B"), lineWidth: 1.5)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(dessertFedToday)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 2. 🎰 奢华扭蛋机台 + 选中神兽详情与双路升阶
    private func gachaAndInspectedPetSection(isWide: Bool) -> some View {
        Group {
            if isWide {
                HStack(alignment: .top, spacing: 16) {
                    gachaMachineCard
                        .frame(minWidth: 300, maxWidth: 360)
                    inspectedPetDetailCard
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    gachaMachineCard
                    inspectedPetDetailCard
                }
            }
        }
    }

    private var gachaMachineCard: some View {
        let pityLeft = engine.progress.gachaRemainingToMythic
        let repeatMiss = engine.progress.gachaRepeatMissCount
        let gentle = engine.progress.eyeCare.gentleMotion

        return VStack(spacing: 10) {
            Text("🎰 奢华皇家扭蛋机")
                .font(.system(size: 17, weight: .black))
                .foregroundColor(Color(hex: "#4A2E14"))

            GachaponMachineVectorView(
                isSpinning: engine.isSpinningGacha,
                pityRemaining: pityLeft,
                gentleMotion: gentle
            )
            .frame(height: 238)

            // 神话保底倒计时 & 防连非保护提示
            VStack(spacing: 4) {
                Text("✨ 再抽 \(pityLeft) 次必出【神话】神兽（每 10 抽硬保底）")
                    .font(.system(size: 11.5, weight: .black))
                    .foregroundColor(Color(hex: "#BE185D"))
                Text(
                    repeatMiss >= 3
                    ? "🛡️ 重复保护已激活：下抽未拥有神兽概率提升至 75%！（满5阶溢出→+1🌟+60🪙）"
                    : "🛡️ 重复保护：连续 3 次重复自动触发 75% 新品 UP · 满 5 阶溢出转 +1 🌟 + 60 🪙"
                )
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(repeatMiss >= 3 ? Color(hex: "#2B7F4A") : Color(hex: "#8A7765"))
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF8EE")))

            // 单抽按钮行（1🎟️ 或 120🪙）
            HStack(spacing: 8) {
                Button {
                    engine.spinGacha(useTicket: true)
                } label: {
                    gachaButtonLabel(title: "🎟️ 单抽 ×1", sub: "剩 \(engine.progress.gachaTickets) 券", colors: ["#E05385", "#C1121F"], textColor: .white)
                }
                .buttonStyle(.plain)

                Button {
                    engine.spinGacha(useTicket: false)
                } label: {
                    gachaButtonLabel(title: "🪙 120 星币单抽", sub: "单次孵化", colors: ["#FFE082", "#F5A623"], textColor: Color(hex: "#4A2E14"))
                }
                .buttonStyle(.plain)
            }

            // 五连抽 8.5 折特惠按钮行（5🎟️ 或 510🪙）
            HStack(spacing: 8) {
                Button {
                    engine.spinGachaFive(useTicket: true)
                } label: {
                    gachaButtonLabel(title: "🎟️ 五连抽 ×5", sub: "保底传说/新品", colors: ["#9B6EF3", "#6A4C93"], textColor: .white)
                }
                .buttonStyle(.plain)

                Button {
                    engine.spinGachaFive(useTicket: false)
                } label: {
                    gachaButtonLabel(title: "🌟 510 币五连", sub: "8.5折 · 省90🪙", colors: ["#FF9F1C", "#E25247"], textColor: .white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "#FFD166"), lineWidth: 2))
        )
    }

    private func gachaButtonLabel(title: String, sub: String, colors: [String], textColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 12.5, weight: .black))
            Text(sub)
                .font(.system(size: 10, weight: .bold))
                .opacity(0.9)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(LinearGradient(colors: colors.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom))
        )
    }

    private var inspectedPetDetailCard: some View {
        let pet = inspectedPet
        let ownedCount = engine.progress.pets[pet.id] ?? 0
        let stage = engine.progress.petStage(for: pet.id)
        let totalExp = engine.progress.petTotalExp(for: pet.id)
        let nextNeed = engine.progress.nextPetStageNeed(for: pet.id)
        let feedCost = GuardianPetSpecies.feedCost(for: max(1, stage))
        let isEquipped = (engine.equippedPet.id == pet.id)
        let isMaxStage = (stage >= GuardianPetSpecies.maxStage)
        let gentle = engine.progress.eyeCare.gentleMotion

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(pet.name)
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(Color(hex: "#3B2E22"))
                        Text(pet.rarityName)
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: pet.rarityColorHex)))
                        if stage > 0 {
                            Text("Lv.\(stage) \(GuardianPetSpecies.stageName(for: stage))")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(Color(hex: "#534AB7"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: "#EFEFFD")))
                        }
                    }
                    Text("\(pet.title) · 最爱美食：🍓 \(pet.favoriteFood)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                if ownedCount > 0 {
                    Button {
                        engine.equipPet(pet.id)
                    } label: {
                        Text(isEquipped ? "✓ 正在伴读" : "🌟 设为伴读")
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(isEquipped ? Color(hex: "#2B7F4A") : .white)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(isEquipped ? Color(hex: "#E6F7ED") : Color(hex: "#F07D2E")))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 五阶成长阶梯条（可横向滚动防止小屏裁切）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(1...GuardianPetSpecies.maxStage, id: \.self) { st in
                        let reached = stage >= st
                        let needVal = GuardianPetSpecies.stageThresholds[st]
                        HStack(spacing: 3) {
                            Text("Lv.\(st)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                            Text(GuardianPetSpecies.stageName(for: st))
                                .font(.system(size: 10.5, weight: .heavy))
                            Text("(\(needVal))")
                                .font(.system(size: 9.5, weight: .semibold))
                        }
                        .foregroundColor(reached ? .white : Color(hex: "#8A7765"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(
                                reached
                                    ? LinearGradient(colors: [Color(hex: pet.primaryHex), Color(hex: "#7A6EE6")], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color(hex: "#F4EFE8"), Color(hex: "#F4EFE8")], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                    }
                }
            }

            // 预览舞台 + 技能详情 + 双路升阶
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    inspectedPetAvatarBox(pet: pet, ownedCount: ownedCount, stage: stage, gentle: gentle)
                    inspectedPetInfoAndUpgradeColumn(
                        pet: pet,
                        ownedCount: ownedCount,
                        stage: stage,
                        totalExp: totalExp,
                        nextNeed: nextNeed,
                        feedCost: feedCost,
                        isMaxStage: isMaxStage
                    )
                }
                VStack(alignment: .leading, spacing: 12) {
                    inspectedPetAvatarBox(pet: pet, ownedCount: ownedCount, stage: stage, gentle: gentle)
                        .frame(maxWidth: .infinity)
                    inspectedPetInfoAndUpgradeColumn(
                        pet: pet,
                        ownedCount: ownedCount,
                        stage: stage,
                        totalExp: totalExp,
                        nextNeed: nextNeed,
                        feedCost: feedCost,
                        isMaxStage: isMaxStage
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: pet.primaryHex).opacity(0.35), lineWidth: 2))
        )
    }

    private func inspectedPetAvatarBox(pet: GuardianPetSpecies, ownedCount: Int, stage: Int, gentle: Bool) -> some View {
        Button {
            engine.audio.sfxPetHappy()
            engine.audio.speakText("\(pet.name)说：\(pet.cheerLine)", slow: false)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: pet.secondaryHex).opacity(0.45), Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 150, height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: pet.primaryHex).opacity(0.35), lineWidth: 2)
                    )

                if ownedCount > 0 {
                    GuardianPetVectorView(
                        species: pet,
                        stage: stage,
                        size: 120,
                        animated: true,
                        showHeartBurst: engine.petHeartBurst && engine.equippedPet.id == pet.id,
                        gentleMotion: gentle
                    )
                } else {
                    VStack(spacing: 6) {
                        Text("🥚")
                            .font(.system(size: 54))
                        Text("待扭蛋孵化")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func inspectedPetInfoAndUpgradeColumn(
        pet: GuardianPetSpecies,
        ownedCount: Int,
        stage: Int,
        totalExp: Int,
        nextNeed: Int?,
        feedCost: Int,
        isMaxStage: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("💬 「\(pet.cheerLine)」")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#4A2E14"))
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF8EE")))

            VStack(alignment: .leading, spacing: 3) {
                Text("✨ 专属技能：\(pet.skillDesc)")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Color(hex: "#B25614"))
                Text("👑 4阶解锁伴读技能与星币加成翻倍！当前实效：\(pet.effectiveSkillSummary(forStage: max(1, stage)))")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(stage >= 4 ? Color(hex: "#BE185D") : Color(hex: "#7A6EE6"))
            }

            if ownedCount > 0 {
                if let need = nextNeed, !isMaxStage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📈 进化进度：\(totalExp) / \(need)（还差 \(max(0, need - totalExp)) 点升至 Lv.\(stage + 1) \(GuardianPetSpecies.stageName(for: stage + 1))）")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#7A6EE6"))

                        GeometryReader { geo in
                            let prevNeed = GuardianPetSpecies.stageThresholds[max(1, min(stage, 4))]
                            let span = max(1, need - prevNeed)
                            let ratio = min(1.0, max(0.08, Double(totalExp - prevNeed) / Double(span)))
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.black.opacity(0.08))
                                Capsule()
                                    .fill(LinearGradient(colors: [Color(hex: pet.primaryHex), Color(hex: "#FFD166")], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * ratio)
                            }
                        }
                        .frame(height: 8)
                    }

                    // 双路升阶按钮：星币喂食 + 魔法糖果喂食
                    HStack(spacing: 8) {
                        Button {
                            engine.feedPet(pet.id)
                        } label: {
                            VStack(spacing: 1) {
                                Text("🍓 金币投喂")
                                    .font(.system(size: 12.5, weight: .heavy))
                                Text("\(feedCost) 🪙 · 成长+1")
                                    .font(.system(size: 10.5, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [Color(hex: "#FF758F"), Color(hex: "#E05385")], startPoint: .top, endPoint: .bottom))
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.feedPetWithCandy(pet.id)
                        } label: {
                            VStack(spacing: 1) {
                                Text("🌟 喂魔法糖果")
                                    .font(.system(size: 12.5, weight: .heavy))
                                Text("余 \(engine.progress.petCandy) 颗 · 成长+3")
                                    .font(.system(size: 10.5, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [Color(hex: "#9B6EF3"), Color(hex: "#6A4C93")], startPoint: .top, endPoint: .bottom))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // Lv.5 满阶绝不渲染可扣币投喂按钮，明确展示满级至尊徽章！
                    HStack(spacing: 8) {
                        Text("👑 满级至尊 · 技能翻倍")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#F59E0B"), Color(hex: "#E05385"), Color(hex: "#7A6EE6")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                        Text("已达 Lv.5 终极形态，无需再喂啦！")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                    .padding(.top, 2)
                }
            } else {
                Text("💡 在左侧摇动皇家扭蛋机，就能把「\(pet.name)」带回家并解锁它的专属技能！")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(Color(hex: "#E63946"))
            }
        }
    }

    // MARK: - 3. 🌟 12 只守护神兽全图鉴网格
    private var petCodexGridSection: some View {
        let gentle = engine.progress.eyeCare.gentleMotion
        return VStack(alignment: .leading, spacing: 10) {
            Text("🦄 12 大守护神兽图鉴（点击查看详情、双路升阶或切换伴读）")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color(hex: "#3B2E22"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155, maximum: 210), spacing: 10)], spacing: 10) {
                ForEach(GuardianPetSpecies.all) { sp in
                    let owned = (engine.progress.pets[sp.id] ?? 0) > 0
                    let st = engine.progress.petStage(for: sp.id)
                    let isSel = (selectedPetId == sp.id)
                    let isEq = (engine.equippedPet.id == sp.id)

                    Button {
                        selectedPetId = sp.id
                        engine.audio.sfxTap()
                        if owned {
                            engine.audio.speakText(sp.name, slow: false)
                        }
                    } label: {
                        VStack(spacing: 5) {
                            ZStack(alignment: .topTrailing) {
                                if owned {
                                    GuardianPetVectorView(
                                        species: sp,
                                        stage: st,
                                        size: 64,
                                        animated: isSel,
                                        gentleMotion: gentle
                                    )
                                } else {
                                    Text("🥚")
                                        .font(.system(size: 38))
                                        .frame(width: 64, height: 64)
                                        .opacity(0.55)
                                }
                                if isEq && owned {
                                    Text("伴读中")
                                        .font(.system(size: 9.5, weight: .black))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color(hex: "#2B7F4A")))
                                }
                            }

                            Text(sp.name)
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color(hex: "#3B2E22"))
                                .lineLimit(1)

                            Text(sp.skillShortTag)
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(Color(hex: "#9A3412"))

                            HStack(spacing: 4) {
                                Text(sp.rarityName)
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1.5)
                                    .background(Capsule().fill(Color(hex: sp.rarityColorHex)))

                                Text(owned ? "Lv.\(st) \(GuardianPetSpecies.stageName(for: st))" : "未孵化")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(owned ? Color(hex: "#534AB7") : .gray)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSel ? Color(hex: "#FFF8EE") : (owned ? Color.white : Color(hex: "#FAF7F2")))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isSel ? Color(hex: sp.primaryHex) : (st >= 4 ? Color(hex: "#FFD166") : Color.black.opacity(0.08)),
                                            lineWidth: isSel ? 2.4 : 1.4
                                        )
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

    // MARK: - 4. 🏰 城堡游乐园实时景观看板 & 8 座实效加成设施建设面板
    private var castleAmusementParkSection: some View {
        let unlockedCount = engine.progress.unlockedAttractionCount
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("🏰 皇家童话游乐园 · 实效景观建筑")
                    .font(.system(size: 16.5, weight: .black))
                    .foregroundColor(Color(hex: "#3B2E22"))
                Text("已点亮 \(unlockedCount)/\(CastleAttraction.all.count) 座")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: unlockedCount >= 5 ? "#2B7F4A" : "#7A6EE6")))
                Spacer()
                if unlockedCount < 5 {
                    Text("点亮 5 座解锁「🏰 皇家游乐园主」徽章")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
            }

            CastleDioramaAnimatedView(engine: engine)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 10)], spacing: 10) {
                ForEach(CastleAttraction.all) { attr in
                    let isBuilt = (engine.progress.castleUnlocked[attr.id] ?? 0) > 0
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 8) {
                            Text(attr.icon)
                                .font(.system(size: 26))
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 11)
                                        .fill(Color(hex: attr.secondaryHex).opacity(0.65))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Text(attr.name)
                                        .font(.system(size: 13.5, weight: .black))
                                        .foregroundColor(Color(hex: "#3B2E22"))
                                        .lineLimit(1)
                                }
                                Text(attr.perkShortTag)
                                    .font(.system(size: 10.5, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: attr.primaryHex)))
                            }
                            Spacer(minLength: 0)
                        }

                        Text(attr.perkDesc)
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color(hex: "#6B5744"))
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            engine.unlockCastleAttraction(attr)
                        } label: {
                            HStack {
                                Spacer()
                                Text(isBuilt ? "✨ 已点亮生效中（点击赏景）" : "🏗️ 解锁建造（\(attr.costCoins) 🪙）")
                                    .font(.system(size: 12, weight: .heavy))
                                Spacer()
                            }
                            .foregroundColor(isBuilt ? Color(hex: "#2B7F4A") : .white)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(
                                        isBuilt
                                            ? Color(hex: "#E6F7ED")
                                            : Color(hex: attr.primaryHex)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isBuilt ? Color.white : Color(hex: "#FAF7F2"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isBuilt ? Color(hex: attr.primaryHex).opacity(0.45) : Color.black.opacity(0.08),
                                        lineWidth: isBuilt ? 1.8 : 1.2
                                    )
                            )
                    )
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.92)))
    }
}

// MARK: - 6. 🎊 扭蛋三连点破壳孵化 & 5连抽高光庆典弹窗 (GachaponEggBurstOverlay)
public struct GachaponEggBurstOverlay: View {
    @ObservedObject public var engine: GameEngine
    public let events: [GachaHatchEvent]

    @State private var crackCounts: [UUID: Int] = [:]
    @State private var focusedEventId: UUID? = nil

    public init(engine: GameEngine, event: GachaHatchEvent) {
        self.engine = engine
        self.events = [event]
    }

    public init(engine: GameEngine, events: [GachaHatchEvent]) {
        self.engine = engine
        self.events = events
    }

    private var allOpened: Bool {
        !events.isEmpty && events.allSatisfy { (crackCounts[$0.id] ?? 0) >= 3 }
    }

    private var activeSingleEvent: GachaHatchEvent? {
        if events.count == 1 { return events.first }
        if let fid = focusedEventId {
            return events.first(where: { $0.id == fid })
        }
        return nil
    }

    private var gentle: Bool {
        engine.progress.eyeCare.gentleMotion
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            if let primary = activeSingleEvent, (crackCounts[primary.id] ?? 0) >= 3 {
                FireworkSparkBurstView(colorHex: primary.pet.primaryHex, gentleMotion: gentle)
                    .scaleEffect(2.4)
                FireworkSparkBurstView(colorHex: "#FFD166", gentleMotion: gentle)
                    .scaleEffect(1.8)
            } else if allOpened, let top = highlightedEvent {
                FireworkSparkBurstView(colorHex: top.pet.primaryHex, gentleMotion: gentle)
                    .scaleEffect(2.3)
            }

            if events.count <= 1, let single = events.first {
                singleEggPanel(event: single)
            } else {
                batchEggsPanel
            }
        }
    }

    private var highlightedEvent: GachaHatchEvent? {
        events.first(where: { $0.pet.rarity == 3 })
            ?? events.first(where: { $0.isNew })
            ?? events.last
    }

    // MARK: - 单抽 3 连点破壳互动面板
    private func singleEggPanel(event: GachaHatchEvent) -> some View {
        let crackLevel = crackCounts[event.id] ?? 0
        let opened = crackLevel >= 3

        return VStack(spacing: 14) {
            if !opened {
                VStack(spacing: 14) {
                    Text(crackHintTitle(crackLevel: crackLevel))
                        .font(.system(size: 19, weight: .black))
                        .foregroundColor(Color(hex: "#5E340B"))
                        .multilineTextAlignment(.center)

                    Button {
                        tapEgg(event)
                    } label: {
                        InteractiveCrackEggView(
                            pet: event.pet,
                            crackLevel: crackLevel,
                            eggSize: 146,
                            gentleMotion: gentle
                        )
                    }
                    .buttonStyle(.plain)

                    // 3 击进度指示点
                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { step in
                            Capsule()
                                .fill(crackLevel >= step ? Color(hex: "#F07D2E") : Color.black.opacity(0.12))
                                .frame(width: 34, height: 8)
                        }
                    }

                    Text("👆 连点 3 下彩蛋破壳孵化（当前 \(crackLevel)/3 击）")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                .padding(24)
            } else {
                openedPetShowcase(event: event)
            }
        }
        .padding(26)
        .frame(maxWidth: 460)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [Color.white, Color(hex: "#FFF6E5")], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#FFD166"), lineWidth: 3))
                .shadow(color: Color.black.opacity(0.28), radius: 24, y: 10)
        )
        .padding(.horizontal, 16)
    }

    private func openedPetShowcase(event: GachaHatchEvent) -> some View {
        VStack(spacing: 11) {
            HStack(spacing: 8) {
                Text(event.pet.rarityName + "品质")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: event.pet.rarityColorHex)))

                Text("Lv.\(event.toStage) \(GuardianPetSpecies.stageName(for: event.toStage))")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Color(hex: "#534AB7"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "#EFEFFD")))
            }

            GuardianPetVectorView(
                species: event.pet,
                stage: event.toStage,
                size: 154,
                animated: true,
                showHeartBurst: true,
                gentleMotion: gentle
            )

            Text(
                event.isMaxOverflow
                ? "🌟 满级幻兽溢出丰厚回馈！"
                : (event.isNew
                    ? "🎉 恭喜孵化新守护神兽！"
                    : (event.toStage > event.fromStage ? "👑 神兽华丽升阶进化啦！" : "✨ 守护神兽成长值 +2！"))
            )
            .font(.system(size: 21, weight: .black))
            .foregroundColor(Color(hex: "#5E340B"))
            .multilineTextAlignment(.center)

            Text("【\(event.pet.name)】· \(event.pet.title)")
                .font(.system(size: 15.5, weight: .heavy))
                .foregroundColor(Color(hex: event.pet.primaryHex))

            if event.isMaxOverflow {
                Text("🌈 该神兽已满 5 阶，自动转化：+\(event.overflowCandy) 🌟魔法糖果 + \(event.overflowCoins) 🪙星币！")
                    .font(.system(size: 13.5, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color(hex: "#9B6EF3"), Color(hex: "#E05385")], startPoint: .leading, endPoint: .trailing))
                    )
                    .multilineTextAlignment(.center)
            } else {
                Text("「\(event.pet.cheerLine)」")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(Color(hex: "#7A624B"))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    engine.equipPet(event.pet.id)
                    engine.dismissGachaHatch()
                } label: {
                    Text("🌟 设为伴读并收下")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#F07D2E")))
                }
                .buttonStyle(.plain)

                Button {
                    engine.audio.sfxTap()
                    engine.dismissGachaHatch()
                } label: {
                    Text("太棒啦！")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FFF0D6")))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - 五连抽 5 枚彩蛋互动矩阵面板
    private var batchEggsPanel: some View {
        let openedCount = events.filter { (crackCounts[$0.id] ?? 0) >= 3 }.count
        let overflowCandyTotal = events.reduce(0) { $0 + $1.overflowCandy }
        let overflowCoinsTotal = events.reduce(0) { $0 + $1.overflowCoins }

        return VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("🎰 皇家五连扭蛋盛典（\(openedCount)/\(events.count) 已破壳）")
                        .font(.system(size: 19, weight: .black))
                        .foregroundColor(Color(hex: "#5E340B"))
                    Text("点击任意彩蛋 3 下破壳，或点击下方「⚡ 一键全部开启」")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                if overflowCandyTotal > 0 {
                    Text("满阶转化: +\(overflowCandyTotal)🌟 +\(overflowCoinsTotal)🪙")
                        .font(.system(size: 11.5, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(hex: "#9B6EF3")))
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 122, maximum: 155), spacing: 10)], spacing: 10) {
                ForEach(events) { ev in
                    let crackLevel = crackCounts[ev.id] ?? 0
                    let isOpened = crackLevel >= 3

                    Button {
                        if !isOpened {
                            tapEgg(ev)
                        } else {
                            engine.audio.sfxPetHappy()
                            focusedEventId = ev.id
                        }
                    } label: {
                        VStack(spacing: 6) {
                            if !isOpened {
                                InteractiveCrackEggView(
                                    pet: ev.pet,
                                    crackLevel: crackLevel,
                                    eggSize: 82,
                                    gentleMotion: gentle
                                )
                                Text(ev.pet.rarityName + "彩蛋")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: ev.pet.rarityColorHex)))
                                Text("点 \(3 - crackLevel) 下开启")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundColor(Color(hex: "#8A7765"))
                            } else {
                                ZStack(alignment: .topTrailing) {
                                    GuardianPetVectorView(
                                        species: ev.pet,
                                        stage: ev.toStage,
                                        size: 74,
                                        animated: true,
                                        showHeartBurst: focusedEventId == ev.id,
                                        gentleMotion: gentle
                                    )
                                    if ev.isNew {
                                        Text("NEW")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color(hex: "#E63946")))
                                    }
                                }

                                Text(ev.pet.name)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(Color(hex: "#3B2E22"))
                                    .lineLimit(1)

                                if ev.isMaxOverflow {
                                    Text("+\(ev.overflowCandy)🌟 +\(ev.overflowCoins)🪙")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Color(hex: "#7A6EE6"))
                                } else {
                                    Text(
                                        ev.toStage > ev.fromStage
                                        ? "👑 Lv.\(ev.fromStage)→\(ev.toStage)"
                                        : "Lv.\(ev.toStage) \(GuardianPetSpecies.stageName(for: ev.toStage))"
                                    )
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "#534AB7"))
                                    .lineLimit(1)
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 152)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isOpened ? Color.white : Color(hex: "#FFF8EE"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            isOpened ? Color(hex: ev.pet.rarityColorHex) : Color(hex: "#FFD166"),
                                            lineWidth: isOpened ? 2 : 1.5
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                if !allOpened {
                    Button {
                        openAllBatchEggs()
                    } label: {
                        Text("⚡ 一键全部开启")
                            .font(.system(size: 14.5, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#FF758F"), Color(hex: "#E05385")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                if allOpened {
                    if let top = highlightedEvent {
                        Button {
                            engine.equipPet(top.pet.id)
                            engine.dismissGachaHatch()
                        } label: {
                            Text("🌟 装备【\(top.pet.name)】并收下")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#F07D2E")))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        engine.audio.sfxTap()
                        engine.dismissGachaHatch()
                    } label: {
                        Text("✨ 全部收下")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(Color(hex: "#4A2E14"))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FFF0D6")))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: 740)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [Color.white, Color(hex: "#FFF6E5")], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#FFD166"), lineWidth: 3))
                .shadow(color: Color.black.opacity(0.28), radius: 24, y: 10)
        )
        .padding(.horizontal, 14)
    }

    private func crackHintTitle(crackLevel: Int) -> String {
        switch crackLevel {
        case 1: return "💥 第 1 击裂纹出现！再点 2 下裂开彩蛋！"
        case 2: return "✨ 第 2 击光芒泄出！最后 1 击召唤神兽！"
        default: return "🥚 神秘皇家扭蛋驾到！点一点敲开它！"
        }
    }

    private func tapEgg(_ ev: GachaHatchEvent) {
        let next = min(3, (crackCounts[ev.id] ?? 0) + 1)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
            crackCounts[ev.id] = next
            if next >= 3 {
                focusedEventId = ev.id
            }
        }
        switch next {
        case 1:
            engine.audio.sfxTap()
        case 2:
            engine.audio.sfxBubble()
        default:
            engine.audio.sfxChestOpen()
        }
    }

    private func openAllBatchEggs() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) {
            for ev in events {
                crackCounts[ev.id] = 3
            }
            focusedEventId = highlightedEvent?.id
        }
        engine.audio.sfxChestOpen()
    }
}

// MARK: - 🥚 3 连点裂纹与光束泄出互动彩蛋视图
private struct InteractiveCrackEggView: View {
    let pet: GuardianPetSpecies
    let crackLevel: Int // 0, 1, 2
    let eggSize: CGFloat
    let gentleMotion: Bool

    var body: some View {
        let interval: TimeInterval = gentleMotion ? (1.0 / 15.0) : (1.0 / 30.0)
        TimelineView(.animation(minimumInterval: interval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let shakeAmp: Double = crackLevel == 2 ? (gentleMotion ? 4 : 9) : (crackLevel == 1 ? (gentleMotion ? 2.5 : 5) : 1.8)
            let tilt = sin(t * (crackLevel >= 1 ? 18.0 : 4.5)) * shakeAmp

            ZStack {
                // 第 2 击：裂缝光芒泄出（放射光柱）
                if crackLevel >= 2 {
                    Canvas { ctx, sz in
                        let cx = sz.width * 0.5
                        let cy = sz.height * 0.5
                        for i in 0..<8 {
                            let ang = Double(i) * (Double.pi / 4.0) + t * 0.6
                            var ray = Path()
                            ray.move(to: CGPoint(x: cx, y: cy))
                            ray.addLine(to: CGPoint(x: cx + CGFloat(cos(ang - 0.12)) * sz.width * 0.5, y: cy + CGFloat(sin(ang - 0.12)) * sz.height * 0.5))
                            ray.addLine(to: CGPoint(x: cx + CGFloat(cos(ang + 0.12)) * sz.width * 0.5, y: cy + CGFloat(sin(ang + 0.12)) * sz.height * 0.5))
                            ray.closeSubpath()
                            ctx.fill(ray, with: .color(Color(hex: "#FFF3B0").opacity(0.65)))
                        }
                    }
                    .frame(width: eggSize * 1.45, height: eggSize * 1.45)
                }

                // 彩蛋本体 + 阶梯裂纹
                Canvas { ctx, sz in
                    let w = sz.width
                    let h = sz.height
                    let rect = CGRect(x: w * 0.10, y: h * 0.06, width: w * 0.80, height: h * 0.88)
                    let eggPath = Ellipse().path(in: rect)

                    let topColor = pet.rarity == 3 ? Color(hex: "#FF595E") : Color(hex: pet.primaryHex)
                    let botColor = pet.rarity == 3 ? Color(hex: "#FFD166") : Color(hex: pet.secondaryHex)
                    ctx.fill(
                        eggPath,
                        with: .linearGradient(
                            Gradient(colors: [topColor, botColor]),
                            startPoint: CGPoint(x: w * 0.3, y: 0),
                            endPoint: CGPoint(x: w * 0.7, y: h)
                        )
                    )
                    ctx.stroke(eggPath, with: .color(Color(hex: "#FFD166")), lineWidth: 3)

                    // 彩蛋腰带
                    let belt = Path { p in
                        p.move(to: CGPoint(x: w * 0.11, y: h * 0.50))
                        p.addQuadCurve(to: CGPoint(x: w * 0.89, y: h * 0.50), control: CGPoint(x: w * 0.50, y: h * 0.58))
                    }
                    ctx.stroke(belt, with: .color(Color.white.opacity(0.85)), lineWidth: max(2, w * 0.04))

                    // 高光
                    let hi = Ellipse().path(in: CGRect(x: w * 0.24, y: h * 0.16, width: w * 0.16, height: h * 0.26))
                    ctx.fill(hi, with: .color(Color.white.opacity(0.45)))

                    // 第 1 击裂纹
                    if crackLevel >= 1 {
                        var crack1 = Path()
                        crack1.move(to: CGPoint(x: w * 0.36, y: h * 0.36))
                        crack1.addLine(to: CGPoint(x: w * 0.48, y: h * 0.48))
                        crack1.addLine(to: CGPoint(x: w * 0.42, y: h * 0.57))
                        crack1.addLine(to: CGPoint(x: w * 0.58, y: h * 0.68))
                        ctx.stroke(crack1, with: .color(Color(hex: "#3B2E22")), style: StrokeStyle(lineWidth: max(2.2, w * 0.03), lineCap: .round, lineJoin: .round))
                    }

                    // 第 2 击大裂纹 + 内部金色光缝
                    if crackLevel >= 2 {
                        var crack2 = Path()
                        crack2.move(to: CGPoint(x: w * 0.68, y: h * 0.28))
                        crack2.addLine(to: CGPoint(x: w * 0.54, y: h * 0.44))
                        crack2.addLine(to: CGPoint(x: w * 0.66, y: h * 0.56))
                        crack2.addLine(to: CGPoint(x: w * 0.48, y: h * 0.72))
                        ctx.stroke(crack2, with: .color(Color(hex: "#FFF8E1")), style: StrokeStyle(lineWidth: max(3.0, w * 0.045), lineCap: .round, lineJoin: .round))
                    }
                }
                .frame(width: eggSize, height: eggSize)
                .rotationEffect(.degrees(tilt))
            }
            .frame(width: eggSize * 1.15, height: eggSize * 1.15)
        }
    }
}
