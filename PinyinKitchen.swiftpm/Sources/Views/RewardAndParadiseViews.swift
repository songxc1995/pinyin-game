import SwiftUI

// MARK: - 1. 🦄 12 只守护萌宠全矢量骨骼级动态视图 (GuardianPetVectorView)
public struct GuardianPetVectorView: View {
    public let species: GuardianPetSpecies
    public let stage: Int // 1 萌芽幼崽, 2 闪耀灵兽, 3 皇冠神兽
    public var size: CGFloat = 76
    public var animated: Bool = true
    public var showHeartBurst: Bool = false

    @State private var floatUp: Bool = false
    @State private var wingFlap: Bool = false
    @State private var haloSpin: Double = 0

    public init(
        species: GuardianPetSpecies,
        stage: Int = 1,
        size: CGFloat = 76,
        animated: Bool = true,
        showHeartBurst: Bool = false
    ) {
        self.species = species
        self.stage = max(1, stage)
        self.size = size
        self.animated = animated
        self.showHeartBurst = showHeartBurst
    }

    public var body: some View {
        ZStack {
            // 2阶/3阶神兽光环
            if stage >= 2 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: species.secondaryHex).opacity(stage >= 3 ? 0.78 : 0.50),
                                Color(hex: species.primaryHex).opacity(stage >= 3 ? 0.36 : 0.16),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.58
                        )
                    )
                    .frame(width: size * 1.16, height: size * 1.16)
                    .scaleEffect(floatUp ? 1.06 : 0.95)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: species.primaryHex),
                                Color(hex: "#FFD166"),
                                Color(hex: species.secondaryHex),
                                Color(hex: species.primaryHex)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: stage >= 3 ? 2.6 : 1.6, dash: [6, 5])
                    )
                    .frame(width: size * 0.98, height: size * 0.98)
                    .rotationEffect(.degrees(haloSpin))
            }

            // 核心萌宠矢量绘制
            Canvas { context, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                let sx = w / 100.0
                let sy = h / 100.0

                let c1 = Color(hex: species.primaryHex)
                let c2 = Color(hex: species.secondaryHex)
                let acc = Color(hex: species.accentHex)
                let ink = Color(hex: "#362517")

                // 地面柔和投影
                let shadowOval = Ellipse().path(in: CGRect(x: 24 * sx, y: 86 * sy, width: 52 * sx, height: 9 * sy))
                context.fill(shadowOval, with: .color(Color.black.opacity(0.12)))

                // 翅膀 / 尾巴后景装饰（根据不同神兽绘制特色部件）
                switch species.kind {
                case .fireDragon, .phoenix, .owlDoctor:
                    let wingSpread: CGFloat = wingFlap ? 6.0 : 0.0
                    var leftWing = Path()
                    leftWing.move(to: CGPoint(x: 28 * sx, y: 55 * sy))
                    leftWing.addQuadCurve(
                        to: CGPoint(x: (8 - wingSpread) * sx, y: (36 - wingSpread) * sy),
                        control: CGPoint(x: 10 * sx, y: 58 * sy)
                    )
                    leftWing.addQuadCurve(
                        to: CGPoint(x: 30 * sx, y: 44 * sy),
                        control: CGPoint(x: 18 * sx, y: 30 * sy)
                    )
                    leftWing.closeSubpath()

                    var rightWing = Path()
                    rightWing.move(to: CGPoint(x: 72 * sx, y: 55 * sy))
                    rightWing.addQuadCurve(
                        to: CGPoint(x: (92 + wingSpread) * sx, y: (36 - wingSpread) * sy),
                        control: CGPoint(x: 90 * sx, y: 58 * sy)
                    )
                    rightWing.addQuadCurve(
                        to: CGPoint(x: 70 * sx, y: 44 * sy),
                        control: CGPoint(x: 82 * sx, y: 30 * sy)
                    )
                    rightWing.closeSubpath()

                    context.fill(leftWing, with: .color(acc))
                    context.fill(rightWing, with: .color(acc))

                case .nineTailFox:
                    // 九尾仙狐的多条蓬松大尾巴
                    for i in [-2, -1, 1, 2] {
                        let ang = Double(i) * 18.0 + (wingFlap ? 5.0 : -5.0)
                        let rad = ang * Double.pi / 180.0
                        let tx = 50.0 + sin(rad) * 34.0
                        let ty = 56.0 - cos(rad) * 22.0
                        let tail = Ellipse().path(in: CGRect(x: (tx - 11) * sx, y: (ty - 16) * sy, width: 22 * sx, height: 32 * sy))
                        context.fill(tail, with: .color(c1))
                        let tip = Circle().path(in: CGRect(x: (tx - 5) * sx, y: (ty - 14) * sy, width: 10 * sx, height: 10 * sy))
                        context.fill(tip, with: .color(c2))
                    }

                case .whale:
                    // 小蓝鲸头顶喷出的彩虹水柱
                    var spoutL = Path()
                    spoutL.move(to: CGPoint(x: 50 * sx, y: 26 * sy))
                    spoutL.addQuadCurve(to: CGPoint(x: 32 * sx, y: 12 * sy), control: CGPoint(x: 46 * sx, y: 10 * sy))
                    var spoutR = Path()
                    spoutR.move(to: CGPoint(x: 50 * sx, y: 26 * sy))
                    spoutR.addQuadCurve(to: CGPoint(x: 68 * sx, y: 12 * sy), control: CGPoint(x: 54 * sx, y: 10 * sy))
                    context.stroke(spoutL, with: .color(Color(hex: "#4CC9F0")), style: StrokeStyle(lineWidth: 3.2 * sx, lineCap: .round))
                    context.stroke(spoutR, with: .color(Color(hex: "#4CC9F0")), style: StrokeStyle(lineWidth: 3.2 * sx, lineCap: .round))

                case .azureDragon:
                    // 祥云环绕
                    let cloudL = Capsule().path(in: CGRect(x: 8 * sx, y: 62 * sy, width: 26 * sx, height: 12 * sy))
                    let cloudR = Capsule().path(in: CGRect(x: 66 * sx, y: 62 * sy, width: 26 * sx, height: 12 * sy))
                    context.fill(cloudL, with: .color(Color.white.opacity(0.9)))
                    context.fill(cloudR, with: .color(Color.white.opacity(0.9)))

                default:
                    break
                }

                // 头顶双耳 / 鹿角 / 龙角
                switch species.kind {
                case .moonRabbit:
                    let earL = Capsule().path(in: CGRect(x: 30 * sx, y: 10 * sy, width: 13 * sx, height: 32 * sy))
                    let earR = Capsule().path(in: CGRect(x: 57 * sx, y: 10 * sy, width: 13 * sx, height: 32 * sy))
                    context.fill(earL, with: .color(c1))
                    context.fill(earR, with: .color(c1))
                    let innerL = Capsule().path(in: CGRect(x: 33.5 * sx, y: 15 * sy, width: 6 * sx, height: 20 * sy))
                    let innerR = Capsule().path(in: CGRect(x: 60.5 * sx, y: 15 * sy, width: 6 * sx, height: 20 * sy))
                    context.fill(innerL, with: .color(c2))
                    context.fill(innerR, with: .color(c2))

                case .pandaChef:
                    let earL = Circle().path(in: CGRect(x: 22 * sx, y: 20 * sy, width: 18 * sx, height: 18 * sy))
                    let earR = Circle().path(in: CGRect(x: 60 * sx, y: 20 * sy, width: 18 * sx, height: 18 * sy))
                    context.fill(earL, with: .color(ink))
                    context.fill(earR, with: .color(ink))

                case .auroraDeer, .azureDragon, .fireDragon:
                    var hornL = Path()
                    hornL.move(to: CGPoint(x: 35 * sx, y: 30 * sy))
                    hornL.addLine(to: CGPoint(x: 24 * sx, y: 13 * sy))
                    hornL.addLine(to: CGPoint(x: 32 * sx, y: 18 * sy))
                    var hornR = Path()
                    hornR.move(to: CGPoint(x: 65 * sx, y: 30 * sy))
                    hornR.addLine(to: CGPoint(x: 76 * sx, y: 13 * sy))
                    hornR.addLine(to: CGPoint(x: 68 * sx, y: 18 * sy))
                    context.stroke(hornL, with: .color(acc), style: StrokeStyle(lineWidth: 4.5 * sx, lineCap: .round, lineJoin: .round))
                    context.stroke(hornR, with: .color(acc), style: StrokeStyle(lineWidth: 4.5 * sx, lineCap: .round, lineJoin: .round))

                default:
                    // 萌宠尖耳
                    var earL = Path()
                    earL.move(to: CGPoint(x: 26 * sx, y: 38 * sy))
                    earL.addLine(to: CGPoint(x: 22 * sx, y: 16 * sy))
                    earL.addLine(to: CGPoint(x: 42 * sx, y: 28 * sy))
                    earL.closeSubpath()

                    var earR = Path()
                    earR.move(to: CGPoint(x: 74 * sx, y: 38 * sy))
                    earR.addLine(to: CGPoint(x: 78 * sx, y: 16 * sy))
                    earR.addLine(to: CGPoint(x: 58 * sx, y: 28 * sy))
                    earR.closeSubpath()
                    context.fill(earL, with: .color(c1))
                    context.fill(earR, with: .color(c1))
                }

                // 圆润身体与脑袋
                let bodyColor = (species.kind == .pandaChef) ? Color.white : c1
                let bellyColor = (species.kind == .pandaChef) ? Color(hex: "#F4F1EA") : c2

                let bodyRect = CGRect(x: 23 * sx, y: 26 * sy, width: 54 * sx, height: 56 * sy)
                let bodyPath = RoundedRectangle(cornerRadius: 26 * sx).path(in: bodyRect)
                context.fill(bodyPath, with: .color(bodyColor))
                context.stroke(bodyPath, with: .color(ink.opacity(0.22)), lineWidth: 2.0 * sx)

                // 软萌小肚皮
                let bellyRect = CGRect(x: 32 * sx, y: 54 * sy, width: 36 * sx, height: 24 * sy)
                context.fill(Ellipse().path(in: bellyRect), with: .color(bellyColor.opacity(0.92)))

                // 独角兽螺旋彩虹角 / 博士帽
                if species.kind == .unicorn {
                    var horn = Path()
                    horn.move(to: CGPoint(x: 44 * sx, y: 27 * sy))
                    horn.addLine(to: CGPoint(x: 50 * sx, y: 7 * sy))
                    horn.addLine(to: CGPoint(x: 56 * sx, y: 27 * sy))
                    horn.closeSubpath()
                    context.fill(horn, with: .color(Color(hex: "#FFD166")))
                    context.stroke(horn, with: .color(Color(hex: "#F07D2E")), lineWidth: 1.5 * sx)
                } else if species.kind == .owlDoctor {
                    var cap = Path()
                    cap.move(to: CGPoint(x: 50 * sx, y: 12 * sy))
                    cap.addLine(to: CGPoint(x: 74 * sx, y: 20 * sy))
                    cap.addLine(to: CGPoint(x: 50 * sx, y: 28 * sy))
                    cap.addLine(to: CGPoint(x: 26 * sx, y: 20 * sy))
                    cap.closeSubpath()
                    context.fill(cap, with: .color(ink))
                }

                // 熊猫黑眼圈
                if species.kind == .pandaChef {
                    let patchL = Ellipse().path(in: CGRect(x: 31 * sx, y: 40 * sy, width: 14 * sx, height: 11 * sy))
                    let patchR = Ellipse().path(in: CGRect(x: 55 * sx, y: 40 * sy, width: 14 * sx, height: 11 * sy))
                    context.fill(patchL, with: .color(ink))
                    context.fill(patchR, with: .color(ink))
                }

                // 闪亮大眼睛 + 高光
                let eyeL = Circle().path(in: CGRect(x: 34 * sx, y: 42 * sy, width: 8.8 * sx, height: 8.8 * sy))
                let eyeR = Circle().path(in: CGRect(x: 57.2 * sx, y: 42 * sy, width: 8.8 * sx, height: 8.8 * sy))
                context.fill(eyeL, with: .color(species.kind == .pandaChef ? .white : ink))
                context.fill(eyeR, with: .color(species.kind == .pandaChef ? .white : ink))

                let pupilL = Circle().path(in: CGRect(x: 35.8 * sx, y: 43.4 * sy, width: 3.4 * sx, height: 3.4 * sy))
                let pupilR = Circle().path(in: CGRect(x: 59.0 * sx, y: 43.4 * sy, width: 3.4 * sx, height: 3.4 * sy))
                context.fill(pupilL, with: .color(species.kind == .pandaChef ? ink : .white))
                context.fill(pupilR, with: .color(species.kind == .pandaChef ? ink : .white))

                // 粉嫩腮红
                let blushL = Ellipse().path(in: CGRect(x: 27 * sx, y: 50 * sy, width: 8.5 * sx, height: 4.8 * sy))
                let blushR = Ellipse().path(in: CGRect(x: 64.5 * sx, y: 50 * sy, width: 8.5 * sx, height: 4.8 * sy))
                context.fill(blushL, with: .color(Color(hex: "#FF758F").opacity(0.68)))
                context.fill(blushR, with: .color(Color(hex: "#FF758F").opacity(0.68)))

                // 微笑小嘴
                var mouth = Path()
                mouth.move(to: CGPoint(x: 45 * sx, y: 51 * sy))
                mouth.addQuadCurve(to: CGPoint(x: 55 * sx, y: 51 * sy), control: CGPoint(x: 50 * sx, y: 57 * sy))
                context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: 2.4 * sx, lineCap: .round))

                // 小爪子
                let pawL = Circle().path(in: CGRect(x: 22 * sx, y: 56 * sy, width: 9 * sx, height: 9 * sy))
                let pawR = Circle().path(in: CGRect(x: 69 * sx, y: 56 * sy, width: 9 * sx, height: 9 * sy))
                context.fill(pawL, with: .color(acc))
                context.fill(pawR, with: .color(acc))

                // 3阶神兽专属：头顶悬浮黄金皇冠
                if stage >= 3 {
                    var crown = Path()
                    crown.move(to: CGPoint(x: 37 * sx, y: 22 * sy))
                    crown.addLine(to: CGPoint(x: 34 * sx, y: 10 * sy))
                    crown.addLine(to: CGPoint(x: 43 * sx, y: 16 * sy))
                    crown.addLine(to: CGPoint(x: 50 * sx, y: 7 * sy))
                    crown.addLine(to: CGPoint(x: 57 * sx, y: 16 * sy))
                    crown.addLine(to: CGPoint(x: 66 * sx, y: 10 * sy))
                    crown.addLine(to: CGPoint(x: 63 * sx, y: 22 * sy))
                    crown.closeSubpath()
                    context.fill(crown, with: .color(Color(hex: "#FFD166")))
                    context.stroke(crown, with: .color(Color(hex: "#C8870A")), lineWidth: 1.8 * sx)
                }
            }
            .frame(width: size, height: size)
            .offset(y: (animated && floatUp) ? -4.5 : 2.0)
            .scaleEffect(x: (animated && floatUp) ? 1.03 : 0.98, y: (animated && floatUp) ? 0.98 : 1.02)

            // 3阶神兽环绕闪星
            if stage >= 3 {
                Text("✨")
                    .font(.system(size: size * 0.24))
                    .offset(x: size * 0.38, y: -size * 0.34)
                Text("👑")
                    .font(.system(size: size * 0.20))
                    .offset(x: -size * 0.36, y: -size * 0.32)
            }

            // 投喂时的爱心喷泉
            if showHeartBurst {
                HStack(spacing: 6) {
                    Text("💖")
                    Text("🍓")
                    Text("🎵")
                }
                .font(.system(size: size * 0.26))
                .offset(y: -size * 0.56)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                floatUp = true
            }
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                wingFlap = true
            }
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                haloSpin = 360
            }
        }
    }
}

// MARK: - 2. 🌈 局内守护萌宠伴读台 + 彩虹连击宝箱能量槽 (CompanionPetStageWidget)
public struct CompanionPetStageWidget: View {
    @ObservedObject public var engine: GameEngine

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        let pet = engine.equippedPet
        let stage = engine.equippedPetStage

        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    engine.audio.sfxPetHappy()
                    engine.audio.speakText("\(pet.name)为你加油！\(pet.cheerLine)", slow: false)
                } label: {
                    GuardianPetVectorView(species: pet, stage: stage, size: 52, animated: true)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("守护伴读：\(pet.name)")
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#4A2E14"))
                        Text(GuardianPetSpecies.stageName(for: stage))
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color(hex: pet.primaryHex)))
                    }

                    // 5格彩虹连击宝箱能量条
                    HStack(spacing: 5) {
                        Text("🌈 彩虹宝箱")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(Color(hex: "#7A6EE6"))

                        HStack(spacing: 3) {
                            ForEach(0..<5, id: \.self) { idx in
                                let filled = idx < engine.rainbowCharge
                                let colors = ["#FF595E", "#FFCA3A", "#8AC926", "#1982C4", "#6A4C93"]
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(filled ? Color(hex: colors[idx]) : Color.black.opacity(0.08))
                                    .frame(width: 18, height: 8)
                                    .scaleEffect(filled ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3), value: engine.rainbowCharge)
                            }
                        }

                        Text("\(engine.rainbowCharge)/5")
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                }

                Spacer()

                // 实时星币与飞入动效
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("🪙")
                            .font(.system(size: 14))
                        Text("\(engine.progress.coins)")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#D97706"))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "#FFF8E1")))

                    if let gain = engine.floatingCoinGainText {
                        Text(gain)
                            .font(.system(size: 11.5, weight: .black))
                            .foregroundColor(Color(hex: "#E25247"))
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("🎟️ 扭蛋券 ×\(engine.progress.gachaTickets)")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFFDF9"), Color(hex: "#FFF4E6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: pet.primaryHex).opacity(0.32), lineWidth: 1.5)
                    )
            )

            if let burstMsg = engine.rainbowChestBurstMessage {
                HStack(spacing: 6) {
                    Text("🎁")
                    Text(burstMsg)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
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
    }
}

// MARK: - 3. 🎰 皇家梦幻扭蛋机动态矢量图 (GachaponMachineVectorView)
public struct GachaponMachineVectorView: View {
    public let isSpinning: Bool
    @State private var idleFloat: Bool = false

    public init(isSpinning: Bool) {
        self.isSpinning = isSpinning
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
        ZStack {
            // 柔和背光
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#FFD166").opacity(0.45), Color.clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 115
                    )
                )
                .frame(width: 230, height: 230)

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
                        .frame(width: 120, height: 24)
                        .overlay(Capsule().stroke(Color(hex: "#FFD166"), lineWidth: 2.5))
                    Text("👑 ROYAL GACHA")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#FFF8E1"))
                }
                .zIndex(3)

                // 2. 透明玻璃球舱 + 内部翻滚的彩色扭蛋球
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.92),
                                    Color(hex: "#E0F4FF").opacity(0.65),
                                    Color(hex: "#BDE0FE").opacity(0.45)
                                ],
                                center: .topLeading,
                                startRadius: 10,
                                endRadius: 95
                            )
                        )
                        .frame(width: 166, height: 166)
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

                    // 12 颗彩色扭蛋球在舱内弹跳
                    ForEach(0..<12, id: \.self) { i in
                        let pair = capsuleColors[i % capsuleColors.count]
                        let col = i % 4
                        let row = i / 4
                        let baseX = CGFloat(col - 1) * 30.0 - 14.0 + CGFloat((row % 2) * 12)
                        let baseY = CGFloat(row) * 26.0 - 8.0
                        let jumpY: CGFloat = isSpinning
                            ? CGFloat((i % 2 == 0) ? -22 : 18)
                            : (idleFloat ? CGFloat((i % 2 == 0) ? -4 : 4) : 0)
                        let jumpX: CGFloat = isSpinning
                            ? CGFloat((i % 3 == 0) ? 16 : -14)
                            : 0

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
                                .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                                .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1)
                            Text("★")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .offset(x: baseX + jumpX, y: baseY + jumpY)
                        .rotationEffect(.degrees(isSpinning ? Double(i * 45 + 180) : Double(i * 15)))
                        .animation(
                            isSpinning
                                ? .easeInOut(duration: 0.18).repeatForever(autoreverses: true)
                                : .easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(Double(i) * 0.08),
                            value: isSpinning ? isSpinning : idleFloat
                        )
                    }

                    // 玻璃高光弧线
                    Circle()
                        .trim(from: 0.58, to: 0.78)
                        .stroke(Color.white.opacity(0.75), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 142, height: 142)
                }
                .zIndex(2)

                // 3. 扭蛋机红金底座 + 360° 旋转金旋钮 + 出蛋口
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#E63946"), Color(hex: "#C1121F")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 152, height: 92)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color(hex: "#FFD166"), lineWidth: 3)
                        )
                        .shadow(color: Color(hex: "#780000").opacity(0.28), radius: 8, y: 5)

                    VStack(spacing: 8) {
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
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(Color(hex: "#8A4B12"), lineWidth: 2))

                            Capsule()
                                .fill(Color(hex: "#8A4B12"))
                                .frame(width: 32, height: 8)
                                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                                .animation(.easeInOut(duration: 0.6), value: isSpinning)
                        }

                        // 出蛋滑道口
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color(hex: "#2B1810"))
                            .frame(width: 58, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(Color(hex: "#FFD166"), lineWidth: 1.5)
                            )
                    }
                    .offset(y: 4)
                }
                .zIndex(1)
            }
        }
        .onAppear {
            idleFloat = true
        }
    }
}

// MARK: - 4. 🏰 皇家童话游乐园实时动态微缩景观 (CastleDioramaAnimatedView)
public struct CastleDioramaAnimatedView: View {
    @ObservedObject public var engine: GameEngine
    @State private var fireworkBursts: [(id: UUID, x: CGFloat, y: CGFloat, colorHex: String)] = []
    @State private var bannerTip: String = "✨ 点击天空或右侧「🎆 放礼花」按钮，随时在游乐园上空绽放绚丽烟花！"

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        let unlocked = engine.progress.castleUnlocked
        let ownedPets = GuardianPetSpecies.all.filter { (engine.progress.pets[$0.id] ?? 0) > 0 }

        ZStack(alignment: .bottom) {
            // 1. 梦幻渐变天空与点击放烟花热区
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1D3557"), Color(hex: "#457B9D"), Color(hex: "#F4A261"), Color(hex: "#FFE8D6")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 235)
                .onTapGesture {
                    triggerRandomFirework()
                }

            // 2. 动态时间轴画布（旋转摩天轮、喷泉水珠、旋转木马、热气球、风车、钟楼、音符）
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    let w = size.width
                    let h = size.height

                    // 远景草坡与城堡剪影
                    var hillBack = Path()
                    hillBack.move(to: CGPoint(x: 0, y: h * 0.72))
                    hillBack.addQuadCurve(to: CGPoint(x: w, y: h * 0.74), control: CGPoint(x: w * 0.5, y: h * 0.55))
                    hillBack.addLine(to: CGPoint(x: w, y: h))
                    hillBack.addLine(to: CGPoint(x: 0, y: h))
                    hillBack.closeSubpath()
                    context.fill(hillBack, with: .color(Color(hex: "#74C69D")))

                    var hillFront = Path()
                    hillFront.move(to: CGPoint(x: 0, y: h * 0.80))
                    hillFront.addQuadCurve(to: CGPoint(x: w, y: h * 0.80), control: CGPoint(x: w * 0.5, y: h * 0.68))
                    hillFront.addLine(to: CGPoint(x: w, y: h))
                    hillFront.addLine(to: CGPoint(x: 0, y: h))
                    hillFront.closeSubpath()
                    context.fill(hillFront, with: .color(Color(hex: "#52B788")))

                    // 中央童话主城堡
                    let cx = w * 0.50
                    let cy = h * 0.66
                    let castleBase = RoundedRectangle(cornerRadius: 6).path(in: CGRect(x: cx - 36, y: cy - 38, width: 72, height: 48))
                    context.fill(castleBase, with: .color(Color(hex: "#FFF8F0")))
                    let towerL = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: cx - 48, y: cy - 54, width: 22, height: 64))
                    let towerR = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: cx + 26, y: cy - 54, width: 22, height: 64))
                    context.fill(towerL, with: .color(Color(hex: "#FFE5EC")))
                    context.fill(towerR, with: .color(Color(hex: "#FFE5EC")))

                    var roofM = Path()
                    roofM.move(to: CGPoint(x: cx - 30, y: cy - 38))
                    roofM.addLine(to: CGPoint(x: cx, y: cy - 78))
                    roofM.addLine(to: CGPoint(x: cx + 30, y: cy - 38))
                    roofM.closeSubpath()
                    context.fill(roofM, with: .color(Color(hex: "#E05385")))

                    // (A) 🎡 彩虹摩天轮 (左侧)
                    if (unlocked["ferris_wheel"] ?? 0) > 0 {
                        let fx = w * 0.16
                        let fy = h * 0.52
                        let r: CGFloat = 38
                        var stand = Path()
                        stand.move(to: CGPoint(x: fx - 22, y: fy + r + 12))
                        stand.addLine(to: CGPoint(x: fx, y: fy))
                        stand.addLine(to: CGPoint(x: fx + 22, y: fy + r + 12))
                        context.stroke(stand, with: .color(Color(hex: "#FFD166")), lineWidth: 3)

                        let wheelCircle = Circle().path(in: CGRect(x: fx - r, y: fy - r, width: r * 2, height: r * 2))
                        context.stroke(wheelCircle, with: .color(Color(hex: "#FF758F")), lineWidth: 3)

                        for i in 0..<6 {
                            let ang = t * 0.8 + Double(i) * (Double.pi / 3.0)
                            let gx = fx + CGFloat(cos(ang)) * r
                            let gy = fy + CGFloat(sin(ang)) * r
                            var spoke = Path()
                            spoke.move(to: CGPoint(x: fx, y: fy))
                            spoke.addLine(to: CGPoint(x: gx, y: gy))
                            context.stroke(spoke, with: .color(Color.white.opacity(0.75)), lineWidth: 1.5)

                            let cabin = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: gx - 6, y: gy - 5, width: 12, height: 10))
                            let cols = ["#FF595E", "#FFCA3A", "#8AC926", "#1982C4", "#6A4C93", "#FF9F1C"]
                            context.fill(cabin, with: .color(Color(hex: cols[i % cols.count])))
                        }
                    }

                    // (B) ⛲ 音乐宝石喷泉 (正前方)
                    if (unlocked["fountain"] ?? 0) > 0 {
                        let px = w * 0.50
                        let py = h * 0.82
                        let pool = Ellipse().path(in: CGRect(x: px - 42, y: py - 8, width: 84, height: 18))
                        context.fill(pool, with: .color(Color(hex: "#4CC9F0")))
                        context.stroke(pool, with: .color(.white), lineWidth: 2)

                        for i in -3...3 {
                            let bounce = abs(sin(t * 3.2 + Double(i) * 0.5)) * 22.0 + 10.0
                            let dropX = px + CGFloat(i * 9)
                            let dropY = py - CGFloat(bounce)
                            var jet = Path()
                            jet.move(to: CGPoint(x: px, y: py))
                            jet.addQuadCurve(to: CGPoint(x: dropX, y: dropY), control: CGPoint(x: (px + dropX) * 0.5, y: dropY - 10))
                            context.stroke(jet, with: .color(Color.white.opacity(0.88)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        }
                    }

                    // (C) 🍭 棒棒糖大风车 (右侧)
                    if (unlocked["windmill"] ?? 0) > 0 {
                        let wx = w * 0.83
                        let wy = h * 0.56
                        let tower = RoundedRectangle(cornerRadius: 5).path(in: CGRect(x: wx - 14, y: wy, width: 28, height: 48))
                        context.fill(tower, with: .color(Color(hex: "#FFF3B0")))
                        for i in 0..<4 {
                            let ang = t * 1.4 + Double(i) * (Double.pi / 2.0)
                            let bx = wx + CGFloat(cos(ang)) * 30
                            let by = wy + CGFloat(sin(ang)) * 30
                            var blade = Path()
                            blade.move(to: CGPoint(x: wx, y: wy))
                            blade.addLine(to: CGPoint(x: bx, y: by))
                            context.stroke(blade, with: .color(Color(hex: "#E63946")), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            let candy = Circle().path(in: CGRect(x: bx - 6, y: by - 6, width: 12, height: 12))
                            context.fill(candy, with: .color(Color(hex: "#FF758F")))
                        }
                    }

                    // (D) 🎈 追梦星空热气球 (高空漂浮)
                    if (unlocked["air_balloon"] ?? 0) > 0 {
                        let bx = w * 0.30 + CGFloat(sin(t * 0.6) * 24.0)
                        let by = h * 0.24 + CGFloat(cos(t * 1.1) * 8.0)
                        let balloon = Circle().path(in: CGRect(x: bx - 20, y: by - 22, width: 40, height: 44))
                        context.fill(balloon, with: .color(Color(hex: "#9B6EF3")))
                        let basket = RoundedRectangle(cornerRadius: 3).path(in: CGRect(x: bx - 7, y: by + 26, width: 14, height: 10))
                        context.fill(basket, with: .color(Color(hex: "#D97706")))
                    }

                    // (E) 🎠 皇家旋转木马 & 🕰️ 天文钟楼 & 🎶 八音盒音符
                    if (unlocked["carousel"] ?? 0) > 0 {
                        let mx = w * 0.32
                        let my = h * 0.72
                        var roof = Path()
                        roof.move(to: CGPoint(x: mx - 26, y: my - 12))
                        roof.addLine(to: CGPoint(x: mx, y: my - 30))
                        roof.addLine(to: CGPoint(x: mx + 26, y: my - 12))
                        roof.closeSubpath()
                        context.fill(roof, with: .color(Color(hex: "#FFCA3A")))
                        let base = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: mx - 24, y: my + 8, width: 48, height: 8))
                        context.fill(base, with: .color(Color(hex: "#E05385")))
                    }

                    if (unlocked["clock_tower"] ?? 0) > 0 {
                        let tx = w * 0.67
                        let ty = h * 0.64
                        let body = RoundedRectangle(cornerRadius: 4).path(in: CGRect(x: tx - 14, y: ty - 42, width: 28, height: 56))
                        context.fill(body, with: .color(Color(hex: "#FFE8C2")))
                        let dial = Circle().path(in: CGRect(x: tx - 9, y: ty - 32, width: 18, height: 18))
                        context.fill(dial, with: .color(.white))
                        context.stroke(dial, with: .color(Color(hex: "#C8870A")), lineWidth: 2)
                    }
                }
            }
            .frame(height: 235)
            .allowsHitTesting(false)

            // 3. 绽放的动态礼花粒子层
            ForEach(fireworkBursts, id: \.id) { fw in
                FireworkSparkBurstView(colorHex: fw.colorHex)
                    .position(x: fw.x, y: fw.y)
            }

            // 4. 草坪上漫步的已拥有守护萌宠精灵（点击可说话互动）
            HStack(spacing: 18) {
                ForEach(Array(ownedPets.prefix(6))) { pet in
                    let st = engine.progress.petStage(for: pet.id)
                    Button {
                        engine.audio.sfxPetHappy()
                        engine.audio.speakText("\(pet.name)：\(pet.cheerLine)", slow: false)
                        bannerTip = "🦄 \(pet.name)：\(pet.cheerLine)"
                    } label: {
                        GuardianPetVectorView(species: pet, stage: st, size: 54, animated: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)

            // 顶部互动提示条 + 放礼花按钮
            HStack {
                Text(bannerTip)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#3B2E22"))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.88)))

                Spacer()

                Button {
                    triggerRandomFirework()
                } label: {
                    Text("🎆 点我放皇家烟花")
                        .font(.system(size: 12, weight: .heavy))
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
            .padding(12)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 235)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func triggerRandomFirework() {
        engine.audio.sfxFirework()
        let colors = ["#FFD166", "#FF595E", "#4CC9F0", "#8AC926", "#FF758F", "#E0AAFF"]
        for _ in 0..<2 {
            let item = (
                id: UUID(),
                x: CGFloat.random(in: 120...680),
                y: CGFloat.random(in: 42...115),
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
}

public struct FireworkSparkBurstView: View {
    public let colorHex: String
    @State private var expand: Bool = false

    public var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * (Double.pi * 2.0 / 12.0)
                let dist: CGFloat = expand ? 46 : 4
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: expand ? 5 : 9, height: expand ? 5 : 9)
                    .shadow(color: Color(hex: colorHex), radius: 4)
                    .offset(x: CGFloat(cos(angle)) * dist, y: CGFloat(sin(angle)) * dist)
                    .opacity(expand ? 0.0 : 1.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.95)) {
                expand = true
            }
        }
    }
}

// MARK: - 5. 🎡 精灵扭蛋与童话游乐园主视图 (RewardParadiseTabView)
public struct RewardParadiseTabView: View {
    @ObservedObject public var engine: GameEngine
    @State private var selectedPetId: String = "fire_dragon"
    @State private var mode: String = "gacha" // "gacha" | "castle"

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var inspectedPet: GuardianPetSpecies {
        GuardianPetSpecies.byId(selectedPetId)
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 顶部子模式切换栏 + 财富展示
                HStack(spacing: 10) {
                    subTabButton(
                        key: "gacha",
                        title: "🎰 皇家扭蛋机 & 守护神兽屋 (\(engine.progress.unlockedPetCount)/\(GuardianPetSpecies.all.count))",
                        color: Color(hex: "#E63946")
                    )
                    subTabButton(
                        key: "castle",
                        title: "🏰 皇家童话游乐园 (\(engine.progress.unlockedAttractionCount)/\(CastleAttraction.all.count))",
                        color: Color(hex: "#7A6EE6")
                    )

                    Spacer()

                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            Text("🪙")
                            Text("\(engine.progress.coins) 星币")
                                .font(.system(size: 13.5, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#B45309"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color(hex: "#FEF3C7")))

                        HStack(spacing: 4) {
                            Text("🎟️")
                            Text("\(engine.progress.gachaTickets) 扭蛋券")
                                .font(.system(size: 13.5, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#BE185D"))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color(hex: "#FCE7F3")))
                    }
                }

                if let toast = engine.petFeedToast {
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

                if mode == "gacha" {
                    gachaAndPetSanctuarySection
                } else {
                    castleAmusementParkSection
                }
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            selectedPetId = engine.equippedPet.id
        }
    }

    private func subTabButton(key: String, title: String, color: Color) -> some View {
        let on = (mode == key)
        return Button {
            engine.audio.sfxTap()
            withAnimation(.spring(response: 0.28)) {
                mode = key
            }
        } label: {
            Text(title)
                .font(.system(size: 13.5, weight: .heavy))
                .foregroundColor(on ? .white : Color(hex: "#4A2E14"))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(on ? color : Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.35), lineWidth: 1.5))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 5A. 皇家扭蛋机 + 守护萌宠互动喂食台 + 12 神兽全图鉴
    private var gachaAndPetSanctuarySection: some View {
        let pet = inspectedPet
        let ownedCount = engine.progress.pets[pet.id] ?? 0
        let stage = engine.progress.petStage(for: pet.id)
        let totalExp = engine.progress.petTotalExp(for: pet.id)
        let nextNeed = engine.progress.nextPetStageNeed(for: pet.id)
        let isEquipped = (engine.equippedPet.id == pet.id)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                // 左侧：动态皇家扭蛋机卡片
                VStack(spacing: 10) {
                    Text("🎰 奇妙皇家扭蛋机")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Color(hex: "#4A2E14"))
                    Text("答题赚星币或集彩虹能量领券，摇出 12 只神话/传说守护神兽！")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .multilineTextAlignment(.center)

                    GachaponMachineVectorView(isSpinning: engine.isSpinningGacha)
                        .frame(height: 245)

                    HStack(spacing: 10) {
                        Button {
                            engine.spinGacha(useTicket: true)
                        } label: {
                            HStack(spacing: 5) {
                                Text("🎟️ 扭蛋券免费抽")
                                Text("(\(engine.progress.gachaTickets))")
                            }
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#E05385"), Color(hex: "#C1121F")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.spinGacha(useTicket: false)
                        } label: {
                            HStack(spacing: 5) {
                                Text("🪙 60 星币抽一次")
                            }
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#4A2E14"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#FFE082"), Color(hex: "#F5A623")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .frame(width: 340)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.95))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "#FFD166"), lineWidth: 2))
                )

                // 右侧：当前选中守护神兽互动与投喂进化舞台
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
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
                                    Text(GuardianPetSpecies.stageName(for: stage))
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
                                Text(isEquipped ? "✓ 正在伴读出战" : "🌟 设为伴读精灵")
                                    .font(.system(size: 12.5, weight: .heavy))
                                    .foregroundColor(isEquipped ? Color(hex: "#2B7F4A") : .white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(isEquipped ? Color(hex: "#E6F7ED") : Color(hex: "#F07D2E"))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 精灵大舞台
                    HStack(spacing: 20) {
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
                                    .frame(width: 155, height: 155)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(hex: pet.primaryHex).opacity(0.35), lineWidth: 2)
                                    )

                                if ownedCount > 0 {
                                    GuardianPetVectorView(
                                        species: pet,
                                        stage: stage,
                                        size: 122,
                                        animated: true,
                                        showHeartBurst: engine.petHeartBurst
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

                        VStack(alignment: .leading, spacing: 9) {
                            Text("💬 伴读口号：「\(pet.cheerLine)」")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(Color(hex: "#4A2E14"))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF8EE")))

                            Text("✨ 专属守护祝福：\(pet.skillDesc)")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(Color(hex: "#B25614"))

                            if ownedCount > 0 {
                                if let need = nextNeed {
                                    Text("📈 进化进度：当前成长值 \(totalExp) / \(need)（再投喂或抽到 \(max(0, need - totalExp)) 次即可进化为下一形态！）")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(hex: "#7A6EE6"))
                                } else {
                                    Text("👑 已达最高 3 阶【皇冠神兽】终极华丽形态 ✨")
                                        .font(.system(size: 12.5, weight: .heavy))
                                        .foregroundColor(Color(hex: "#E63946"))
                                }

                                HStack(spacing: 10) {
                                    Button {
                                        engine.feedPet(pet.id)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text("🍓 投喂【\(pet.favoriteFood)】")
                                            Text("(25 🪙 · 亲密+1)")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 9)
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
                                        engine.audio.sfxPetHappy()
                                        engine.audio.speakText("\(pet.name)说：\(pet.cheerLine)", slow: false)
                                    } label: {
                                        Text("🔊 摸一摸听声音")
                                            .font(.system(size: 12.5, weight: .bold))
                                            .foregroundColor(Color(hex: "#4A2E14"))
                                            .padding(.horizontal, 13)
                                            .padding(.vertical, 9)
                                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF0D6")))
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Text("💡 点击左侧「皇家扭蛋机」就有机会把「\(pet.name)」孵化带回家哦！")
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(Color(hex: "#E63946"))
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.95))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: pet.primaryHex).opacity(0.35), lineWidth: 2))
                )
            }

            // 下方：12 只守护神兽全图鉴网格
            VStack(alignment: .leading, spacing: 10) {
                Text("🦄 奇妙守护萌宠全图鉴（点击任意精灵可查看详情、投喂升阶或设为伴读）")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Color(hex: "#3B2E22"))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 155, maximum: 200), spacing: 10)], spacing: 10) {
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
                                        GuardianPetVectorView(species: sp, stage: st, size: 64, animated: isSel)
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

                                HStack(spacing: 4) {
                                    Text(sp.rarityName)
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Capsule().fill(Color(hex: sp.rarityColorHex)))

                                    Text(owned ? GuardianPetSpecies.stageName(for: st) : "未孵化")
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
                                                isSel ? Color(hex: sp.primaryHex) : (st >= 3 ? Color(hex: "#FFD166") : Color.black.opacity(0.08)),
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
    }

    // MARK: - 5B. 皇家童话游乐园微缩景观与设施建造
    private var castleAmusementParkSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            CastleDioramaAnimatedView(engine: engine)

            VStack(alignment: .leading, spacing: 10) {
                Text("🏰 皇家童话游乐园设施建造（用闯关赚到的星币点亮动态游乐设施！）")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Color(hex: "#3B2E22"))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240, maximum: 320), spacing: 12)], spacing: 12) {
                    ForEach(CastleAttraction.all) { item in
                        let unlocked = (engine.progress.castleUnlocked[item.id] ?? 0) > 0

                        Button {
                            engine.unlockCastleAttraction(item)
                        } label: {
                            HStack(spacing: 12) {
                                Text(item.icon)
                                    .font(.system(size: 34))
                                    .frame(width: 56, height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: item.secondaryHex).opacity(0.45))
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(item.name)
                                            .font(.system(size: 14.5, weight: .heavy))
                                            .foregroundColor(Color(hex: "#3B2E22"))
                                        if unlocked {
                                            Text("✓ 已点亮")
                                                .font(.system(size: 10, weight: .heavy))
                                                .foregroundColor(Color(hex: "#2B7F4A"))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color(hex: "#E6F7ED")))
                                        }
                                    }
                                    Text(item.subtitle)
                                        .font(.system(size: 11.5, weight: .medium))
                                        .foregroundColor(Color(hex: "#8A7765"))
                                        .lineLimit(2)

                                    Text(unlocked ? "🔊 点击播放景观互动音效" : "🪙 建造需 \(item.costCoins) 星币")
                                        .font(.system(size: 11.5, weight: .black))
                                        .foregroundColor(unlocked ? Color(hex: item.primaryHex) : Color(hex: "#D97706"))
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(unlocked ? Color.white : Color(hex: "#FAF7F2"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(unlocked ? Color(hex: item.primaryHex).opacity(0.45) : Color.black.opacity(0.08), lineWidth: 1.8)
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

// MARK: - 6. 🎊 扭蛋破壳孵化 & 萌宠进化全屏高光庆典弹窗 (GachaponEggBurstOverlay)
public struct GachaponEggBurstOverlay: View {
    @ObservedObject public var engine: GameEngine
    public let event: GachaHatchEvent

    @State private var cracked: Bool = false
    @State private var eggShake: Bool = false

    public init(engine: GameEngine, event: GachaHatchEvent) {
        self.engine = engine
        self.event = event
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            // 满屏彩色礼花粒子层
            if cracked {
                FireworkSparkBurstView(colorHex: event.pet.primaryHex)
                    .scaleEffect(2.4)
                FireworkSparkBurstView(colorHex: "#FFD166")
                    .scaleEffect(1.8)
            }

            VStack(spacing: 14) {
                if !cracked {
                    // 第一阶段：发光巨型扭蛋剧烈摇晃破壳
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: event.pet.primaryHex), Color(hex: event.pet.secondaryHex)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 130, height: 130)
                                .overlay(Circle().stroke(Color(hex: "#FFD166"), lineWidth: 5))
                                .shadow(color: Color(hex: "#FFD166"), radius: 22)
                                .rotationEffect(.degrees(eggShake ? 12 : -12))

                            Text("✨")
                                .font(.system(size: 48))
                        }

                        Text("咔嚓咔嚓……神秘扭蛋正在发光破壳！")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(Color(hex: "#5E340B"))
                    }
                    .padding(28)
                } else {
                    // 第二阶段：守护萌宠华丽登场
                    HStack(spacing: 8) {
                        Text(event.pet.rarityName + "品质")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: event.pet.rarityColorHex)))

                        Text(GuardianPetSpecies.stageName(for: event.toStage))
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color(hex: "#534AB7"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: "#EFEFFD")))
                    }

                    GuardianPetVectorView(
                        species: event.pet,
                        stage: event.toStage,
                        size: 158,
                        animated: true,
                        showHeartBurst: true
                    )

                    Text(
                        event.isNew
                        ? "🎉 恭喜孵化新守护神兽！"
                        : (event.toStage > event.fromStage ? "👑 神兽华丽升阶进化啦！" : "✨ 守护神兽成长值 +1！")
                    )
                    .font(.system(size: 23, weight: .black))
                    .foregroundColor(Color(hex: "#5E340B"))

                    Text("【\(event.pet.name)】· \(event.pet.title)")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Color(hex: event.pet.primaryHex))

                    Text("「\(event.pet.cheerLine)」")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color(hex: "#7A624B"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)

                    HStack(spacing: 12) {
                        Button {
                            engine.equipPet(event.pet.id)
                            engine.activeGachaHatch = nil
                        } label: {
                            Text("🌟 设为伴读并收下")
                                .font(.system(size: 14.5, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#F07D2E")))
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.audio.sfxTap()
                            engine.activeGachaHatch = nil
                        } label: {
                            Text("太棒啦！")
                                .font(.system(size: 14.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#4A2E14"))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FFF0D6")))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)
                }
            }
            .padding(28)
            .frame(maxWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(hex: "#FFF6E5")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#FFD166"), lineWidth: 3))
                    .shadow(color: Color.black.opacity(0.28), radius: 24, y: 10)
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                eggShake = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 420_000_000)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
                    cracked = true
                }
            }
        }
    }
}
