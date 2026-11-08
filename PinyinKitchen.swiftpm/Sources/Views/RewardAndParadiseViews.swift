import SwiftUI

// MARK: - 1. 🦄 12 只守护萌宠五阶进化全矢量动态视图 (GuardianPetVectorView)
public struct GuardianPetVectorView: View {
    public let species: GuardianPetSpecies
    public let stage: Int // 1 萌芽幼崽, 2 闪耀灵兽, 3 星辉圣兽, 4 皇冠神兽, 5 至尊幻兽
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
        self.stage = max(1, min(stage, GuardianPetSpecies.maxStage))
        self.size = size
        self.animated = animated
        self.showHeartBurst = showHeartBurst
    }

    public var body: some View {
        ZStack {
            // 5阶至尊幻兽专属：外层九色极光星阵
            if stage >= 5 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#FFD166").opacity(0.62),
                                Color(hex: "#FF758F").opacity(0.42),
                                Color(hex: "#7A6EE6").opacity(0.28),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: size * 0.68
                        )
                    )
                    .frame(width: size * 1.32, height: size * 1.32)
                    .scaleEffect(floatUp ? 1.08 : 0.94)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: "#FF595E"),
                                Color(hex: "#FFCA3A"),
                                Color(hex: "#8AC926"),
                                Color(hex: "#4CC9F0"),
                                Color(hex: "#9B6EF3"),
                                Color(hex: "#FF758F"),
                                Color(hex: "#FF595E")
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3.2, dash: [8, 4])
                    )
                    .frame(width: size * 1.15, height: size * 1.15)
                    .rotationEffect(.degrees(-haloSpin * 1.3))
            }

            // 2~5阶神兽渐进光环
            if stage >= 2 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: species.secondaryHex).opacity(stage >= 4 ? 0.85 : (stage >= 3 ? 0.68 : 0.45)),
                                Color(hex: species.primaryHex).opacity(stage >= 4 ? 0.45 : (stage >= 3 ? 0.30 : 0.14)),
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
                        style: StrokeStyle(lineWidth: stage >= 4 ? 2.8 : (stage >= 3 ? 2.2 : 1.5), dash: [6, 5])
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

                // 4~5阶神兽专属：全物种展开流光神翼
                if stage >= 4 {
                    let wingLift: CGFloat = wingFlap ? 8.0 : 1.0
                    var haloWingL = Path()
                    haloWingL.move(to: CGPoint(x: 24 * sx, y: 50 * sy))
                    haloWingL.addQuadCurve(
                        to: CGPoint(x: 3 * sx, y: (26 - wingLift) * sy),
                        control: CGPoint(x: 4 * sx, y: 52 * sy)
                    )
                    haloWingL.addQuadCurve(
                        to: CGPoint(x: 26 * sx, y: 38 * sy),
                        control: CGPoint(x: 15 * sx, y: 20 * sy)
                    )
                    haloWingL.closeSubpath()

                    var haloWingR = Path()
                    haloWingR.move(to: CGPoint(x: 76 * sx, y: 50 * sy))
                    haloWingR.addQuadCurve(
                        to: CGPoint(x: 97 * sx, y: (26 - wingLift) * sy),
                        control: CGPoint(x: 96 * sx, y: 52 * sy)
                    )
                    haloWingR.addQuadCurve(
                        to: CGPoint(x: 74 * sx, y: 38 * sy),
                        control: CGPoint(x: 85 * sx, y: 20 * sy)
                    )
                    haloWingR.closeSubpath()

                    let wingColor = stage >= 5 ? Color(hex: "#FFD166") : acc.opacity(0.88)
                    context.fill(haloWingL, with: .color(wingColor))
                    context.fill(haloWingR, with: .color(wingColor))
                    context.stroke(haloWingL, with: .color(Color.white.opacity(0.9)), lineWidth: 1.5 * sx)
                    context.stroke(haloWingR, with: .color(Color.white.opacity(0.9)), lineWidth: 1.5 * sx)
                }

                // 3阶：星辉圣兽额头星钻；4~5阶：头顶悬浮帝国皇冠 + 宝石项链
                if stage == 3 {
                    let starGem = Circle().path(in: CGRect(x: 46 * sx, y: 31 * sy, width: 8 * sx, height: 8 * sy))
                    context.fill(starGem, with: .color(Color(hex: "#FFD166")))
                    context.stroke(starGem, with: .color(.white), lineWidth: 1.4 * sx)
                } else if stage >= 4 {
                    var crown = Path()
                    crown.move(to: CGPoint(x: 35 * sx, y: 22 * sy))
                    crown.addLine(to: CGPoint(x: 31 * sx, y: 8 * sy))
                    crown.addLine(to: CGPoint(x: 42 * sx, y: 15 * sy))
                    crown.addLine(to: CGPoint(x: 50 * sx, y: 4 * sy))
                    crown.addLine(to: CGPoint(x: 58 * sx, y: 15 * sy))
                    crown.addLine(to: CGPoint(x: 69 * sx, y: 8 * sy))
                    crown.addLine(to: CGPoint(x: 65 * sx, y: 22 * sy))
                    crown.closeSubpath()
                    context.fill(crown, with: .color(Color(hex: "#FFD166")))
                    context.stroke(crown, with: .color(Color(hex: "#C8870A")), lineWidth: 1.8 * sx)

                    // 皇冠中心红宝石
                    let ruby = Circle().path(in: CGRect(x: 47 * sx, y: 12 * sy, width: 6 * sx, height: 6 * sy))
                    context.fill(ruby, with: .color(Color(hex: "#E63946")))

                    // 胸前圣兽宝石勋章
                    let collarGem = Circle().path(in: CGRect(x: 45.5 * sx, y: 58 * sy, width: 9 * sx, height: 9 * sy))
                    context.fill(collarGem, with: .color(stage >= 5 ? Color(hex: "#4CC9F0") : Color(hex: "#FF758F")))
                    context.stroke(collarGem, with: .color(Color(hex: "#FFD166")), lineWidth: 1.6 * sx)
                }
            }
            .frame(width: size, height: size)
            .offset(y: (animated && floatUp) ? -4.5 : 2.0)
            .scaleEffect(x: (animated && floatUp) ? 1.03 : 0.98, y: (animated && floatUp) ? 0.98 : 1.02)

            // 3~5阶神兽环绕特效徽记
            if stage >= 3 {
                Text(stage >= 5 ? "🌈" : "✨")
                    .font(.system(size: size * 0.24))
                    .offset(x: size * 0.40, y: -size * 0.36)
                Text(stage >= 4 ? "👑" : "⭐")
                    .font(.system(size: size * 0.21))
                    .offset(x: -size * 0.38, y: -size * 0.34)
            }
            if stage >= 5 {
                Text("💎")
                    .font(.system(size: size * 0.19))
                    .offset(x: size * 0.42, y: size * 0.28)
                Text("🌟")
                    .font(.system(size: size * 0.19))
                    .offset(x: -size * 0.42, y: size * 0.28)
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

// MARK: - 2. 🌈 局内小公主与守护萌宠伴读台 + 8格彩虹连击宝箱能量槽 (CompanionPetStageWidget)
public struct CompanionPetStageWidget: View {
    @ObservedObject public var engine: GameEngine

    public init(engine: GameEngine) {
        self.engine = engine
    }

    public var body: some View {
        let pet = engine.equippedPet
        let stage = engine.equippedPetStage
        let dress = engine.progress.equippedItem(for: .dress)

        VStack(spacing: 6) {
            HStack(spacing: 10) {
                // 满满小公主实时盛装形象 + 守护萌宠双伴读
                HStack(spacing: 4) {
                    Button {
                        engine.audio.sfxSpark()
                        engine.audio.speakText("满满小公主身穿\(dress.name)，为你加油！", slow: false)
                    } label: {
                        PrincessAvatarVectorView(progress: engine.progress, size: 54, animated: true)
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.audio.sfxPetHappy()
                        engine.audio.speakText("\(pet.name)为你加油！\(pet.cheerLine)", slow: false)
                    } label: {
                        GuardianPetVectorView(species: pet, stage: stage, size: 50, animated: true)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("👑 满满公主 & \(pet.name)")
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#4A2E14"))
                        Text(GuardianPetSpecies.stageName(for: stage))
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color(hex: pet.primaryHex)))
                        Text("✨华丽度 \(engine.progress.totalGlamourScore)")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(Color(hex: "#BE185D"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color(hex: "#FCE7F3")))
                    }

                    // 8格彩虹连击宝箱能量条（答错回退2格，集满8格开大奖）
                    HStack(spacing: 5) {
                        Text("🌈 彩虹宝箱")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(Color(hex: "#7A6EE6"))

                        HStack(spacing: 2.5) {
                            ForEach(0..<8, id: \.self) { idx in
                                let filled = idx < engine.rainbowCharge
                                let colors = ["#FF595E", "#FF924C", "#FFCA3A", "#8AC926", "#2EC4B6", "#1982C4", "#6A4C93", "#E05385"]
                                RoundedRectangle(cornerRadius: 3.5)
                                    .fill(filled ? Color(hex: colors[idx]) : Color.black.opacity(0.08))
                                    .frame(width: 14, height: 8)
                                    .scaleEffect(filled ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3), value: engine.rainbowCharge)
                            }
                        }

                        Text("\(engine.rainbowCharge)/8")
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 顶部标题栏 + 财富展示
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Text("🎰 皇家神兽扭蛋屋 · 五阶神兽进化养成")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(Color(hex: "#4A2E14"))
                        Text("已孵化 \(engine.progress.unlockedPetCount)/\(GuardianPetSpecies.all.count)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: "#E63946")))
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            Text("🪙")
                            Text("\(engine.progress.coins) 星光币")
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

                gachaAndPetSanctuarySection
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            selectedPetId = engine.equippedPet.id
        }
    }

    // MARK: - 5A. 皇家扭蛋机 + 守护萌宠五阶投喂进化台 + 12 神兽全图鉴
    private var gachaAndPetSanctuarySection: some View {
        let pet = inspectedPet
        let ownedCount = engine.progress.pets[pet.id] ?? 0
        let stage = engine.progress.petStage(for: pet.id)
        let totalExp = engine.progress.petTotalExp(for: pet.id)
        let nextNeed = engine.progress.nextPetStageNeed(for: pet.id)
        let feedCost = GuardianPetSpecies.feedCost(for: max(1, stage))
        let isEquipped = (engine.equippedPet.id == pet.id)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                // 左侧：动态皇家扭蛋机卡片
                VStack(spacing: 10) {
                    Text("🎰 奇妙皇家扭蛋机")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(Color(hex: "#4A2E14"))
                    Text("闯关攒星光币或集满 8 格彩虹能量领券，孵化 12 只五阶守护神兽！")
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
                                Text("🪙 120 星币抽一次")
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

                // 右侧：当前选中守护神兽互动与五阶投喂进化舞台
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

                    // 五阶成长路线阶梯条
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
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("📈 五阶进化进度：成长值 \(totalExp) / \(need)（还差 \(max(0, need - totalExp)) 点升至 Lv.\(stage + 1) \(GuardianPetSpecies.stageName(for: stage + 1))）")
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
                                } else {
                                    Text("🌈 已达最高 5 阶【至尊幻兽】九色极光神翼终极形态 ✨")
                                        .font(.system(size: 12.5, weight: .heavy))
                                        .foregroundColor(Color(hex: "#E63946"))
                                }

                                HStack(spacing: 10) {
                                    Button {
                                        engine.feedPet(pet.id)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text("🍓 投喂【\(pet.favoriteFood)】")
                                            Text("(\(feedCost) 🪙 · 成长+1)")
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
                Text("🦄 奇妙守护萌宠全图鉴（点击任意精灵可查看详情、投喂五阶进化或设为伴读）")
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

// MARK: - 7. 👗 满满小公主全套骨骼级矢量换装人物视图 (PrincessAvatarVectorView)
public struct PrincessAvatarVectorView: View {
    public let dress: PrincessFashionItem
    public let dressStage: Int
    public let hairTiara: PrincessFashionItem
    public let tiaraStage: Int
    public let jewelry: PrincessFashionItem
    public let jewelryStage: Int
    public let wings: PrincessFashionItem
    public let wingsStage: Int
    public let wand: PrincessFashionItem
    public let wandStage: Int
    public var size: CGFloat = 180
    public var animated: Bool = true

    @State private var floatUp: Bool = false
    @State private var wingFlap: Bool = false
    @State private var auraSpin: Double = 0

    public init(
        progress: GameProgress,
        size: CGFloat = 180,
        animated: Bool = true
    ) {
        self.dress = progress.equippedItem(for: .dress)
        self.dressStage = max(1, progress.equippedItemStage(for: .dress))
        self.hairTiara = progress.equippedItem(for: .hairTiara)
        self.tiaraStage = max(1, progress.equippedItemStage(for: .hairTiara))
        self.jewelry = progress.equippedItem(for: .jewelry)
        self.jewelryStage = max(1, progress.equippedItemStage(for: .jewelry))
        self.wings = progress.equippedItem(for: .wings)
        self.wingsStage = max(1, progress.equippedItemStage(for: .wings))
        self.wand = progress.equippedItem(for: .wand)
        self.wandStage = max(1, progress.equippedItemStage(for: .wand))
        self.size = size
        self.animated = animated
    }

    public init(
        previewItem: PrincessFashionItem,
        previewStage: Int,
        progress: GameProgress,
        size: CGFloat = 180,
        animated: Bool = true
    ) {
        let d = previewItem.category == .dress ? previewItem : progress.equippedItem(for: .dress)
        let ds = previewItem.category == .dress ? previewStage : max(1, progress.equippedItemStage(for: .dress))
        let h = previewItem.category == .hairTiara ? previewItem : progress.equippedItem(for: .hairTiara)
        let hs = previewItem.category == .hairTiara ? previewStage : max(1, progress.equippedItemStage(for: .hairTiara))
        let j = previewItem.category == .jewelry ? previewItem : progress.equippedItem(for: .jewelry)
        let js = previewItem.category == .jewelry ? previewStage : max(1, progress.equippedItemStage(for: .jewelry))
        let w = previewItem.category == .wings ? previewItem : progress.equippedItem(for: .wings)
        let ws = previewItem.category == .wings ? previewStage : max(1, progress.equippedItemStage(for: .wings))
        let wd = previewItem.category == .wand ? previewItem : progress.equippedItem(for: .wand)
        let wds = previewItem.category == .wand ? previewStage : max(1, progress.equippedItemStage(for: .wand))

        self.dress = d
        self.dressStage = max(1, ds)
        self.hairTiara = h
        self.tiaraStage = max(1, hs)
        self.jewelry = j
        self.jewelryStage = max(1, js)
        self.wings = w
        self.wingsStage = max(1, ws)
        self.wand = wd
        self.wandStage = max(1, wds)
        self.size = size
        self.animated = animated
    }

    private var maxStage: Int {
        max(dressStage, max(tiaraStage, max(jewelryStage, max(wingsStage, wandStage))))
    }

    public var body: some View {
        ZStack {
            // Lv.5 传世神装专属：九色极光魔法阵与流光背环
            if maxStage >= 5 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#FFD166").opacity(0.55),
                                Color(hex: dress.primaryHex).opacity(0.38),
                                Color(hex: "#9B6EF3").opacity(0.22),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: size * 0.62
                        )
                    )
                    .frame(width: size * 1.24, height: size * 1.24)
                    .scaleEffect(floatUp ? 1.06 : 0.95)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: "#FF595E"),
                                Color(hex: "#FFCA3A"),
                                Color(hex: "#8AC926"),
                                Color(hex: "#4CC9F0"),
                                Color(hex: "#9B6EF3"),
                                Color(hex: "#FF758F"),
                                Color(hex: "#FF595E")
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2.8, dash: [7, 4])
                    )
                    .frame(width: size * 1.06, height: size * 1.06)
                    .rotationEffect(.degrees(auraSpin))
            } else if maxStage >= 3 {
                // Lv.3~4 晶钻镶嵌/皇家高定光环
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: dress.secondaryHex).opacity(maxStage >= 4 ? 0.72 : 0.45),
                                Color(hex: dress.primaryHex).opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.54
                        )
                    )
                    .frame(width: size * 1.08, height: size * 1.08)

                if maxStage >= 4 {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#FFD166"), Color(hex: dress.primaryHex), Color(hex: "#FFD166")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2.2, dash: [5, 4])
                        )
                        .frame(width: size * 0.96, height: size * 0.96)
                        .rotationEffect(.degrees(auraSpin))
                }
            }

            // 核心小公主矢量绘制
            Canvas { context, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                let sx = w / 120.0
                let sy = h / 120.0

                let dressC1 = Color(hex: dress.primaryHex)
                let dressC2 = Color(hex: dress.secondaryHex)
                let dressAcc = Color(hex: dress.accentHex)
                let wingC1 = Color(hex: wings.primaryHex)
                let wingC2 = Color(hex: wings.secondaryHex)
                let tiaraC1 = Color(hex: hairTiara.primaryHex)
                let tiaraAcc = Color(hex: hairTiara.accentHex)
                let jewelC1 = Color(hex: jewelry.primaryHex)
                let jewelAcc = Color(hex: jewelry.accentHex)
                let wandC1 = Color(hex: wand.primaryHex)
                let wandAcc = Color(hex: wand.accentHex)
                let skinColor = Color(hex: "#FFE5D9")
                let hairColor = Color(hex: "#4A2C2A")
                let ink = Color(hex: "#362517")

                // 0. 舞台投影
                let shadow = Ellipse().path(in: CGRect(x: 30 * sx, y: 106 * sy, width: 60 * sx, height: 8 * sy))
                context.fill(shadow, with: .color(Color.black.opacity(0.12)))

                // 1. 🧚 梦幻背翼 (Wings)
                let flap: CGFloat = wingFlap ? 6.0 : 0.0
                let wingScale: CGFloat = 1.0 + CGFloat(wingsStage - 1) * 0.08
                var leftWingTop = Path()
                leftWingTop.move(to: CGPoint(x: 48 * sx, y: 54 * sy))
                leftWingTop.addQuadCurve(
                    to: CGPoint(x: (10 - flap) * sx, y: (30 - flap) * sy),
                    control: CGPoint(x: 18 * sx, y: 20 * sy)
                )
                leftWingTop.addQuadCurve(
                    to: CGPoint(x: 44 * sx, y: 66 * sy),
                    control: CGPoint(x: 12 * sx, y: 58 * sy)
                )
                leftWingTop.closeSubpath()

                var rightWingTop = Path()
                rightWingTop.move(to: CGPoint(x: 72 * sx, y: 54 * sy))
                rightWingTop.addQuadCurve(
                    to: CGPoint(x: (110 + flap) * sx, y: (30 - flap) * sy),
                    control: CGPoint(x: 102 * sx, y: 20 * sy)
                )
                rightWingTop.addQuadCurve(
                    to: CGPoint(x: 76 * sx, y: 66 * sy),
                    control: CGPoint(x: 108 * sx, y: 58 * sy)
                )
                rightWingTop.closeSubpath()

                context.fill(leftWingTop, with: .color(wingC1.opacity(0.86)))
                context.fill(rightWingTop, with: .color(wingC1.opacity(0.86)))
                context.stroke(leftWingTop, with: .color(wingsStage >= 3 ? Color(hex: "#FFD166") : wingC2), lineWidth: (1.6 + CGFloat(wingsStage) * 0.3) * sx)
                context.stroke(rightWingTop, with: .color(wingsStage >= 3 ? Color(hex: "#FFD166") : wingC2), lineWidth: (1.6 + CGFloat(wingsStage) * 0.3) * sx)

                // 高阶背翼下翼片
                if wings.rarity >= 2 || wingsStage >= 2 {
                    var leftWingLow = Path()
                    leftWingLow.move(to: CGPoint(x: 46 * sx, y: 62 * sy))
                    leftWingLow.addQuadCurve(
                        to: CGPoint(x: (16 - flap * 0.6) * sx * wingScale, y: 82 * sy),
                        control: CGPoint(x: 18 * sx, y: 68 * sy)
                    )
                    leftWingLow.addQuadCurve(
                        to: CGPoint(x: 48 * sx, y: 74 * sy),
                        control: CGPoint(x: 30 * sx, y: 88 * sy)
                    )
                    leftWingLow.closeSubpath()

                    var rightWingLow = Path()
                    rightWingLow.move(to: CGPoint(x: 74 * sx, y: 62 * sy))
                    rightWingLow.addQuadCurve(
                        to: CGPoint(x: (104 + flap * 0.6) * sx, y: 82 * sy),
                        control: CGPoint(x: 102 * sx, y: 68 * sy)
                    )
                    rightWingLow.addQuadCurve(
                        to: CGPoint(x: 72 * sx, y: 74 * sy),
                        control: CGPoint(x: 90 * sx, y: 88 * sy)
                    )
                    rightWingLow.closeSubpath()

                    context.fill(leftWingLow, with: .color(wingC2.opacity(0.82)))
                    context.fill(rightWingLow, with: .color(wingC2.opacity(0.82)))
                }

                // 2. 柔顺公主长卷发后景
                var backHair = Path()
                backHair.move(to: CGPoint(x: 36 * sx, y: 28 * sy))
                backHair.addQuadCurve(to: CGPoint(x: 28 * sx, y: 68 * sy), control: CGPoint(x: 24 * sx, y: 48 * sy))
                backHair.addQuadCurve(to: CGPoint(x: 92 * sx, y: 68 * sy), control: CGPoint(x: 60 * sx, y: 76 * sy))
                backHair.addQuadCurve(to: CGPoint(x: 84 * sx, y: 28 * sy), control: CGPoint(x: 96 * sx, y: 48 * sy))
                backHair.closeSubpath()
                context.fill(backHair, with: .color(hairColor))

                // 3. 👗 华丽蓬蓬公主礼服裙 (Dress) — 随高定等阶(1~5)解锁多层荷叶裙摆、金丝刺绣与星钻
                let skirtWidthBonus = CGFloat(dressStage - 1) * 3.2 + CGFloat(dress.rarity - 1) * 2.5
                var outerSkirt = Path()
                outerSkirt.move(to: CGPoint(x: 49 * sx, y: 60 * sy))
                outerSkirt.addQuadCurve(
                    to: CGPoint(x: (24 - skirtWidthBonus) * sx, y: 102 * sy),
                    control: CGPoint(x: (28 - skirtWidthBonus * 0.6) * sx, y: 76 * sy)
                )
                outerSkirt.addQuadCurve(
                    to: CGPoint(x: (96 + skirtWidthBonus) * sx, y: 102 * sy),
                    control: CGPoint(x: 60 * sx, y: 112 * sy)
                )
                outerSkirt.addQuadCurve(
                    to: CGPoint(x: 71 * sx, y: 60 * sy),
                    control: CGPoint(x: (92 + skirtWidthBonus * 0.6) * sx, y: 76 * sy)
                )
                outerSkirt.closeSubpath()
                context.fill(outerSkirt, with: .color(dressC1))
                context.stroke(outerSkirt, with: .color(dressStage >= 4 ? Color(hex: "#FFD166") : dressAcc), lineWidth: (1.8 + CGFloat(dressStage) * 0.35) * sx)

                // 礼服内衬层叠纱裙
                var innerSkirt = Path()
                innerSkirt.move(to: CGPoint(x: 51 * sx, y: 61 * sy))
                innerSkirt.addQuadCurve(to: CGPoint(x: 34 * sx, y: 97 * sy), control: CGPoint(x: 38 * sx, y: 78 * sy))
                innerSkirt.addQuadCurve(to: CGPoint(x: 86 * sx, y: 97 * sy), control: CGPoint(x: 60 * sx, y: 104 * sy))
                innerSkirt.addQuadCurve(to: CGPoint(x: 69 * sx, y: 61 * sy), control: CGPoint(x: 82 * sx, y: 78 * sy))
                innerSkirt.closeSubpath()
                context.fill(innerSkirt, with: .color(dressC2.opacity(0.92)))

                // Lv.2+ 珠光蕾丝裙摆花边
                if dressStage >= 2 {
                    for i in 0..<7 {
                        let lx = (31.0 + Double(i) * 9.5) * sx
                        let lace = Circle().path(in: CGRect(x: lx - 4.5 * sx, y: 97.5 * sy, width: 9 * sx, height: 6 * sy))
                        context.fill(lace, with: .color(Color.white.opacity(0.9)))
                    }
                }

                // Lv.3+ 晶钻镶嵌裙面宝石点缀
                if dressStage >= 3 {
                    let gemPoints: [(CGFloat, CGFloat)] = [(46, 78), (60, 74), (74, 78), (40, 90), (60, 88), (80, 90)]
                    for pt in gemPoints {
                        let g = Circle().path(in: CGRect(x: (pt.0 - 2.5) * sx, y: (pt.1 - 2.5) * sy, width: 5 * sx, height: 5 * sy))
                        context.fill(g, with: .color(dressStage >= 4 ? Color(hex: "#FFD166") : .white))
                    }
                }

                // 公主上身礼服胸衣 + 泡泡袖
                let puffL = Circle().path(in: CGRect(x: 39 * sx, y: 48 * sy, width: 11 * sx, height: 11 * sy))
                let puffR = Circle().path(in: CGRect(x: 70 * sx, y: 48 * sy, width: 11 * sx, height: 11 * sy))
                context.fill(puffL, with: .color(dressC2))
                context.fill(puffR, with: .color(dressC2))

                let bodice = RoundedRectangle(cornerRadius: 5 * sx).path(in: CGRect(x: 48 * sx, y: 47 * sy, width: 24 * sx, height: 16 * sy))
                context.fill(bodice, with: .color(dressC1))
                context.stroke(bodice, with: .color(dressAcc), lineWidth: 1.5 * sx)

                // 腰间蝴蝶结
                let bowCenter = Circle().path(in: CGRect(x: 57 * sx, y: 58 * sy, width: 6 * sx, height: 6 * sy))
                context.fill(bowCenter, with: .color(dressAcc))

                // 纤细小手臂
                var armL = Path()
                armL.move(to: CGPoint(x: 43 * sx, y: 55 * sy))
                armL.addQuadCurve(to: CGPoint(x: 32 * sx, y: 68 * sy), control: CGPoint(x: 35 * sx, y: 62 * sy))
                var armR = Path()
                armR.move(to: CGPoint(x: 77 * sx, y: 55 * sy))
                armR.addQuadCurve(to: CGPoint(x: 89 * sx, y: 64 * sy), control: CGPoint(x: 84 * sx, y: 60 * sy))
                context.stroke(armL, with: .color(skinColor), style: StrokeStyle(lineWidth: 4.5 * sx, lineCap: .round))
                context.stroke(armR, with: .color(skinColor), style: StrokeStyle(lineWidth: 4.5 * sx, lineCap: .round))

                // 4. 小公主脖颈与甜美脸庞
                let neck = RoundedRectangle(cornerRadius: 3 * sx).path(in: CGRect(x: 56 * sx, y: 41 * sy, width: 8 * sx, height: 9 * sy))
                context.fill(neck, with: .color(skinColor))

                let face = RoundedRectangle(cornerRadius: 16 * sx).path(in: CGRect(x: 42 * sx, y: 18 * sy, width: 36 * sx, height: 28 * sy))
                context.fill(face, with: .color(skinColor))
                context.stroke(face, with: .color(ink.opacity(0.18)), lineWidth: 1.4 * sx)

                // 齐刘海与两侧公主鬓发
                var bangs = Path()
                bangs.move(to: CGPoint(x: 41 * sx, y: 27 * sy))
                bangs.addQuadCurve(to: CGPoint(x: 60 * sx, y: 16 * sy), control: CGPoint(x: 47 * sx, y: 15 * sy))
                bangs.addQuadCurve(to: CGPoint(x: 79 * sx, y: 27 * sy), control: CGPoint(x: 73 * sx, y: 15 * sy))
                bangs.addQuadCurve(to: CGPoint(x: 60 * sx, y: 24 * sy), control: CGPoint(x: 70 * sx, y: 28 * sy))
                bangs.addQuadCurve(to: CGPoint(x: 41 * sx, y: 27 * sy), control: CGPoint(x: 50 * sx, y: 28 * sy))
                bangs.closeSubpath()
                context.fill(bangs, with: .color(hairColor))

                // 水汪汪大眼睛 + 睫毛 + 星光瞳孔
                let eyeL = Circle().path(in: CGRect(x: 48 * sx, y: 29 * sy, width: 6.2 * sx, height: 6.8 * sy))
                let eyeR = Circle().path(in: CGRect(x: 65.8 * sx, y: 29 * sy, width: 6.2 * sx, height: 6.8 * sy))
                context.fill(eyeL, with: .color(ink))
                context.fill(eyeR, with: .color(ink))

                let shineL = Circle().path(in: CGRect(x: 49.4 * sx, y: 30.2 * sy, width: 2.5 * sx, height: 2.5 * sy))
                let shineR = Circle().path(in: CGRect(x: 67.2 * sx, y: 30.2 * sy, width: 2.5 * sx, height: 2.5 * sy))
                context.fill(shineL, with: .color(.white))
                context.fill(shineR, with: .color(.white))

                // 蜜桃腮红与甜美微笑
                let blushL = Ellipse().path(in: CGRect(x: 44 * sx, y: 36 * sy, width: 6.5 * sx, height: 3.6 * sy))
                let blushR = Ellipse().path(in: CGRect(x: 69.5 * sx, y: 36 * sy, width: 6.5 * sx, height: 3.6 * sy))
                context.fill(blushL, with: .color(Color(hex: "#FF758F").opacity(0.65)))
                context.fill(blushR, with: .color(Color(hex: "#FF758F").opacity(0.65)))

                var smile = Path()
                smile.move(to: CGPoint(x: 56.5 * sx, y: 38.5 * sy))
                smile.addQuadCurve(to: CGPoint(x: 63.5 * sx, y: 38.5 * sy), control: CGPoint(x: 60 * sx, y: 42.2 * sy))
                context.stroke(smile, with: .color(Color(hex: "#E05385")), style: StrokeStyle(lineWidth: 1.8 * sx, lineCap: .round))

                // 5. 💎 项链与耳坠 (Jewelry)
                // 耳坠
                let earDropL = Circle().path(in: CGRect(x: 39 * sx, y: 35 * sy, width: (3.8 + CGFloat(jewelryStage) * 0.4) * sx, height: (3.8 + CGFloat(jewelryStage) * 0.4) * sy))
                let earDropR = Circle().path(in: CGRect(x: 77 * sx, y: 35 * sy, width: (3.8 + CGFloat(jewelryStage) * 0.4) * sx, height: (3.8 + CGFloat(jewelryStage) * 0.4) * sy))
                context.fill(earDropL, with: .color(jewelC1))
                context.fill(earDropR, with: .color(jewelC1))

                // 宝石项链
                var necklace = Path()
                necklace.move(to: CGPoint(x: 53 * sx, y: 46.5 * sy))
                necklace.addQuadCurve(to: CGPoint(x: 67 * sx, y: 46.5 * sy), control: CGPoint(x: 60 * sx, y: 52.5 * sy))
                context.stroke(necklace, with: .color(Color(hex: "#FFD166")), lineWidth: 1.8 * sx)
                let pendant = Circle().path(in: CGRect(x: 57.2 * sx, y: 47.5 * sy, width: 5.6 * sx, height: 5.6 * sy))
                context.fill(pendant, with: .color(jewelC1))
                context.stroke(pendant, with: .color(jewelAcc), lineWidth: 1.2 * sx)

                // 6. 👑 皇冠发饰 (HairTiara)
                let crownHeight = (10.0 + CGFloat(tiaraStage) * 1.6) * sy
                var tiaraPath = Path()
                tiaraPath.move(to: CGPoint(x: 45 * sx, y: 18 * sy))
                tiaraPath.addLine(to: CGPoint(x: 42 * sx, y: 18 * sy - crownHeight * 0.75))
                tiaraPath.addLine(to: CGPoint(x: 52 * sx, y: 18 * sy - crownHeight * 0.42))
                tiaraPath.addLine(to: CGPoint(x: 60 * sx, y: 18 * sy - crownHeight))
                tiaraPath.addLine(to: CGPoint(x: 68 * sx, y: 18 * sy - crownHeight * 0.42))
                tiaraPath.addLine(to: CGPoint(x: 78 * sx, y: 18 * sy - crownHeight * 0.75))
                tiaraPath.addLine(to: CGPoint(x: 75 * sx, y: 18 * sy))
                tiaraPath.closeSubpath()
                context.fill(tiaraPath, with: .color(tiaraC1))
                context.stroke(tiaraPath, with: .color(tiaraAcc), lineWidth: 1.6 * sx)

                let crownCenterGem = Circle().path(in: CGRect(x: 57.5 * sx, y: 13 * sy - crownHeight * 0.35, width: 5 * sx, height: 5 * sy))
                context.fill(crownCenterGem, with: .color(tiaraAcc))

                // 7. 🪄 魔法手持仙女棒 (Wand)
                var wandStick = Path()
                wandStick.move(to: CGPoint(x: 88 * sx, y: 74 * sy))
                wandStick.addLine(to: CGPoint(x: 98 * sx, y: 42 * sy))
                context.stroke(wandStick, with: .color(wandAcc), style: StrokeStyle(lineWidth: 2.8 * sx, lineCap: .round))

                let wandHeadSize = (11.0 + CGFloat(wandStage) * 1.4) * sx
                let wandOrb = Circle().path(in: CGRect(x: 98 * sx - wandHeadSize * 0.5, y: 42 * sy - wandHeadSize * 0.5, width: wandHeadSize, height: wandHeadSize))
                context.fill(wandOrb, with: .color(wandC1))
                context.stroke(wandOrb, with: .color(Color(hex: "#FFD166")), lineWidth: 1.8 * sx)
            }
            .frame(width: size, height: size)
            .offset(y: (animated && floatUp) ? -4.0 : 2.0)

            // 高定等阶环绕星芒粒子
            if maxStage >= 2 {
                Text("✨")
                    .font(.system(size: size * 0.16))
                    .offset(x: size * 0.36, y: -size * 0.28)
            }
            if maxStage >= 4 {
                Text("👑")
                    .font(.system(size: size * 0.15))
                    .offset(x: -size * 0.36, y: -size * 0.30)
                Text("💎")
                    .font(.system(size: size * 0.14))
                    .offset(x: -size * 0.38, y: size * 0.22)
            }
            if maxStage >= 5 {
                Text("🌈")
                    .font(.system(size: size * 0.16))
                    .offset(x: size * 0.38, y: size * 0.24)
            }
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                floatUp = true
            }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                wingFlap = true
            }
            withAnimation(.linear(duration: 9.0).repeatForever(autoreverses: false)) {
                auraSpin = 360
            }
        }
    }
}

// MARK: - 8. 👗 满满公主魔法变装衣橱 & 五阶高定工坊主视图 (PrincessWardrobeTabView)
public struct PrincessWardrobeTabView: View {
    @ObservedObject public var engine: GameEngine
    @State private var selectedItemId: String = "dress_sakura"

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var currentItems: [PrincessFashionItem] {
        PrincessFashionItem.items(for: engine.selectedWardrobeCategory)
    }

    private var inspectedItem: PrincessFashionItem {
        if let found = PrincessFashionItem.item(for: selectedItemId), found.category == engine.selectedWardrobeCategory {
            return found
        }
        return engine.progress.equippedItem(for: engine.selectedWardrobeCategory)
    }

    public var body: some View {
        let item = inspectedItem
        let ownedCount = engine.progress.fashionCount(for: item.id)
        let stage = engine.progress.fashionStage(for: item.id)
        let nextNeed = engine.progress.nextFashionStageNeed(for: item.id)
        let craftCost = PrincessFashionItem.upgradeCraftCost(for: max(0, stage), rarity: item.rarity)
        let isEquipped = (engine.progress.equippedItem(for: item.category).id == item.id)

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                // 顶部标题与华丽度/星光币展示栏
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Text("👗 满满公主魔法变装秀 · 五阶高定裁缝工坊")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(Color(hex: "#4A2E14"))
                        Text("已收集 \(engine.progress.unlockedFashionCount)/\(PrincessFashionItem.all.count)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: "#E05385")))
                        Text("✨ 总华丽度 \(engine.progress.totalGlamourScore)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color(hex: "#7A6EE6"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(hex: "#EFEFFD")))
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("🪙")
                        Text("\(engine.progress.coins) 星光币")
                            .font(.system(size: 13.5, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#B45309"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color(hex: "#FEF3C7")))
                }

                if let toast = engine.wardrobeToast {
                    HStack(spacing: 8) {
                        Text("👗")
                        Text(toast)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#4A2E14"))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "#FFF0F5"))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#E05385"), lineWidth: 1.5))
                    )
                }

                // 上半部：左侧「满满公主全身 T 台秀 + 当前穿戴 5 槽位一览」 + 右侧「高定工坊升阶台」
                HStack(alignment: .top, spacing: 16) {
                    // 左侧：满满公主全身换装 T 台秀
                    VStack(spacing: 10) {
                        HStack {
                            Text("👑 满满小公主皇家 T 台秀")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color(hex: "#4A2E14"))
                            Spacer()
                            Button {
                                engine.audio.sfxSpark()
                                let d = engine.progress.equippedItem(for: .dress)
                                let h = engine.progress.equippedItem(for: .hairTiara)
                                engine.audio.speakText("满满小公主身穿\(d.name)，头戴\(h.name)，华丽度\(engine.progress.totalGlamourScore)分！", slow: false)
                            } label: {
                                Text("🔊 语音播报穿搭")
                                    .font(.system(size: 11.5, weight: .heavy))
                                    .foregroundColor(Color(hex: "#E05385"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Color(hex: "#FCE7F3")))
                            }
                            .buttonStyle(.plain)
                        }

                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#FFF0F5"), Color(hex: "#F3E8FF"), Color(hex: "#FFF8E7")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 220)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color(hex: "#FFD166"), lineWidth: 2.2)
                                )

                            // 若正在预览已解锁服饰，可实时试穿预览
                            if ownedCount > 0 {
                                PrincessAvatarVectorView(
                                    previewItem: item,
                                    previewStage: max(1, stage),
                                    progress: engine.progress,
                                    size: 196,
                                    animated: true
                                )
                            } else {
                                PrincessAvatarVectorView(
                                    progress: engine.progress,
                                    size: 196,
                                    animated: true
                                )
                            }
                        }

                        // 当前穿戴中的 5 大部位快捷徽章
                        HStack(spacing: 6) {
                            ForEach(PrincessFashionCategory.allCases) { cat in
                                let eq = engine.progress.equippedItem(for: cat)
                                let eqSt = engine.progress.equippedItemStage(for: cat)
                                Button {
                                    engine.selectedWardrobeCategory = cat
                                    selectedItemId = eq.id
                                    engine.audio.sfxTap()
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(eq.icon)
                                            .font(.system(size: 16))
                                        Text("Lv.\(eqSt)")
                                            .font(.system(size: 9.5, weight: .black, design: .rounded))
                                            .foregroundColor(Color(hex: "#E05385"))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(engine.selectedWardrobeCategory == cat ? Color(hex: "#FCE7F3") : Color(hex: "#FAF7F2"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(engine.selectedWardrobeCategory == cat ? Color(hex: "#E05385") : Color.black.opacity(0.08), lineWidth: 1.4)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .frame(width: 340)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.95))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "#F5A623").opacity(0.45), lineWidth: 2))
                    )

                    // 右侧：当前选中服饰详情 & 五阶高定裁缝升阶工坊
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 10) {
                                Text(item.icon)
                                    .font(.system(size: 32))
                                    .frame(width: 54, height: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: item.secondaryHex).opacity(0.6))
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Text(item.name)
                                            .font(.system(size: 20, weight: .black))
                                            .foregroundColor(Color(hex: "#3B2E22"))
                                        Text(item.rarityName)
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color(hex: item.rarityColorHex)))
                                        if stage > 0 {
                                            Text("Lv.\(stage) \(PrincessFashionItem.stageName(for: stage))")
                                                .font(.system(size: 11, weight: .heavy))
                                                .foregroundColor(Color(hex: "#BE185D"))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color(hex: "#FCE7F3")))
                                        }
                                    }
                                    Text("\(item.category.title) · \(item.subtitle)")
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(Color(hex: "#8A7765"))
                                }
                            }

                            Spacer()

                            if ownedCount > 0 {
                                Button {
                                    engine.equipFashionItem(item)
                                } label: {
                                    Text(isEquipped ? "✓ 已穿在身上" : "👗 立即换上")
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundColor(isEquipped ? Color(hex: "#2B7F4A") : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 9)
                                        .background(
                                            Capsule().fill(isEquipped ? Color(hex: "#E6F7ED") : Color(hex: "#E05385"))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // 五阶高定进化路线阶梯条
                        VStack(alignment: .leading, spacing: 6) {
                            Text("🧵 五阶高定华丽蜕变路线（越往后升阶越难，裙摆/皇冠/神翼特效越炫酷！）")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#8A7765"))

                            HStack(spacing: 6) {
                                ForEach(1...PrincessFashionItem.maxStage, id: \.self) { st in
                                    let reached = stage >= st
                                    let needVal = PrincessFashionItem.stageThresholds[st]
                                    HStack(spacing: 3) {
                                        Text("Lv.\(st)")
                                            .font(.system(size: 10, weight: .black, design: .rounded))
                                        Text(PrincessFashionItem.stageName(for: st))
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
                                                ? LinearGradient(colors: [Color(hex: item.primaryHex), Color(hex: "#E05385")], startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(colors: [Color(hex: "#F4EFE8"), Color(hex: "#F4EFE8")], startPoint: .leading, endPoint: .trailing)
                                        )
                                    )
                                }
                            }
                        }

                        // 当前阶特效说明与升级进度条
                        VStack(alignment: .leading, spacing: 8) {
                            Text("✨ 当前高定特效：\(PrincessFashionItem.stageEffectDesc(for: max(1, stage)))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#4A2E14"))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF8EE")))

                            if ownedCount > 0 {
                                if let need = nextNeed {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("📈 锦缎高定进度：已注入 \(ownedCount) / \(need) 份星光锦缎（再注入 \(max(0, need - ownedCount)) 次即可升至 Lv.\(stage + 1) \(PrincessFashionItem.stageName(for: stage + 1))！）")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color(hex: "#7A6EE6"))

                                        GeometryReader { geo in
                                            let prevNeed = PrincessFashionItem.stageThresholds[max(1, min(stage, 4))]
                                            let span = max(1, need - prevNeed)
                                            let ratio = min(1.0, max(0.08, Double(ownedCount - prevNeed) / Double(span)))
                                            ZStack(alignment: .leading) {
                                                Capsule().fill(Color.black.opacity(0.08))
                                                Capsule()
                                                    .fill(LinearGradient(colors: [Color(hex: item.primaryHex), Color(hex: "#FFD166")], startPoint: .leading, endPoint: .trailing))
                                                    .frame(width: geo.size.width * ratio)
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                } else {
                                    Text("🌈 已达最高 5 阶【传世神装】九色极光星雨终极形态 ✨")
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundColor(Color(hex: "#E63946"))
                                }
                            } else {
                                Text("💡 通关语数英关卡（尤其是大火🔥三星通关）可免费掉落礼盒，也可直接用星光币裁制解锁！")
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(Color(hex: "#B25614"))
                            }

                            HStack(spacing: 12) {
                                if stage < PrincessFashionItem.maxStage {
                                    Button {
                                        engine.unlockOrUpgradeFashionItem(item)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(ownedCount == 0 ? "🪡 裁制解锁新装" : "🧵 注入星光丝线升阶")
                                            Text("(\(craftCost) 🪙 · 锦缎+1)")
                                                .font(.system(size: 11.5, weight: .bold))
                                        }
                                        .font(.system(size: 13.5, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: "#E05385"), Color(hex: "#7A6EE6")],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button {
                                    engine.audio.sfxTap()
                                    engine.audio.speakText("\(item.name)，\(item.subtitle)", slow: false)
                                } label: {
                                    Text("🔊 听服饰介绍")
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(Color(hex: "#4A2E14"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FFF0D6")))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.95))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: item.primaryHex).opacity(0.38), lineWidth: 2))
                    )
                }

                // 下半部：5 大部位分类切换 + 服饰衣橱网格
                VStack(alignment: .leading, spacing: 12) {
                    // 5 大分类切换按钮
                    HStack(spacing: 8) {
                        ForEach(PrincessFashionCategory.allCases) { cat in
                            let on = (engine.selectedWardrobeCategory == cat)
                            let catItems = PrincessFashionItem.items(for: cat)
                            let unlockedInCat = catItems.filter { engine.progress.fashionCount(for: $0.id) > 0 }.count
                            Button {
                                engine.audio.sfxTap()
                                withAnimation(.spring(response: 0.28)) {
                                    engine.selectedWardrobeCategory = cat
                                    selectedItemId = engine.progress.equippedItem(for: cat).id
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Text(cat.title)
                                    Text("(\(unlockedInCat)/\(catItems.count))")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(on ? .white : Color(hex: "#4A2E14"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(on ? Color(hex: "#E05385") : Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#E05385").opacity(0.35), lineWidth: 1.5))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 165, maximum: 220), spacing: 10)], spacing: 10) {
                        ForEach(currentItems) { fashion in
                            let cnt = engine.progress.fashionCount(for: fashion.id)
                            let owned = cnt > 0
                            let st = engine.progress.fashionStage(for: fashion.id)
                            let isSel = (inspectedItem.id == fashion.id)
                            let isEq = (engine.progress.equippedItem(for: fashion.category).id == fashion.id)

                            Button {
                                selectedItemId = fashion.id
                                engine.audio.sfxTap()
                                if owned {
                                    engine.equipFashionItem(fashion)
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack(alignment: .topTrailing) {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(hex: fashion.secondaryHex), Color(hex: fashion.primaryHex).opacity(0.35)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 62, height: 62)
                                                .overlay(
                                                    Circle()
                                                        .stroke(st >= 4 ? Color(hex: "#FFD166") : Color.white, lineWidth: 2)
                                                )

                                            Text(fashion.icon)
                                                .font(.system(size: 32))
                                                .opacity(owned ? 1.0 : 0.45)
                                        }
                                        .frame(maxWidth: .infinity)

                                        if isEq && owned {
                                            Text("穿戴中")
                                                .font(.system(size: 9.5, weight: .black))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color(hex: "#2B7F4A")))
                                        }
                                    }

                                    Text(fashion.name)
                                        .font(.system(size: 13.5, weight: .heavy))
                                        .foregroundColor(Color(hex: "#3B2E22"))
                                        .lineLimit(1)

                                    HStack(spacing: 4) {
                                        Text(fashion.rarityName)
                                            .font(.system(size: 10, weight: .heavy))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1.5)
                                            .background(Capsule().fill(Color(hex: fashion.rarityColorHex)))

                                        Text(owned ? "Lv.\(st) \(PrincessFashionItem.stageName(for: st))" : "未解锁")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(owned ? Color(hex: "#BE185D") : .gray)
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(isSel ? Color(hex: "#FFF0F5") : (owned ? Color.white : Color(hex: "#FAF7F2")))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    isSel ? Color(hex: fashion.primaryHex) : (st >= 4 ? Color(hex: "#FFD166") : Color.black.opacity(0.08)),
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
            .padding(.vertical, 4)
        }
        .onAppear {
            selectedItemId = engine.progress.equippedItem(for: engine.selectedWardrobeCategory).id
        }
    }
}

// MARK: - 9. 🎊 公主华服解锁 & 五阶高定蜕变全屏庆典弹窗 (FashionUpgradeBurstOverlay)
public struct FashionUpgradeBurstOverlay: View {
    @ObservedObject public var engine: GameEngine
    public let event: FashionUpgradeEvent

    public init(engine: GameEngine, event: FashionUpgradeEvent) {
        self.engine = engine
        self.event = event
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            FireworkSparkBurstView(colorHex: event.item.primaryHex)
                .scaleEffect(2.3)
            FireworkSparkBurstView(colorHex: "#FFD166")
                .scaleEffect(1.8)

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text(event.item.rarityName + "高定")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: event.item.rarityColorHex)))

                    Text("Lv.\(event.toStage) \(PrincessFashionItem.stageName(for: event.toStage))")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color(hex: "#BE185D"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "#FCE7F3")))
                }

                PrincessAvatarVectorView(
                    previewItem: event.item,
                    previewStage: event.toStage,
                    progress: engine.progress,
                    size: 170,
                    animated: true
                )

                Text(event.customTitle ?? (event.isNewUnlock ? "🎉 恭喜解锁新公主服饰！" : "👑 公主服饰华丽高定升阶！"))
                    .font(.system(size: 21, weight: .black))
                    .foregroundColor(Color(hex: "#5E340B"))
                    .multilineTextAlignment(.center)

                Text("【\(event.item.name)】\(event.isNewUnlock ? "已收入衣橱" : "Lv.\(event.fromStage) → Lv.\(event.toStage) \(PrincessFashionItem.stageName(for: event.toStage))")")
                    .font(.system(size: 15.5, weight: .heavy))
                    .foregroundColor(Color(hex: event.item.primaryHex))

                Text("✨ \(PrincessFashionItem.stageEffectDesc(for: event.toStage))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#7A624B"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                HStack(spacing: 12) {
                    Button {
                        engine.equipFashionItem(event.item)
                        if !engine.pendingFashionUpgrades.isEmpty {
                            engine.pendingFashionUpgrades.removeFirst()
                        }
                    } label: {
                        Text("👗 立即穿戴并收下")
                            .font(.system(size: 14.5, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#E05385")))
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.audio.sfxTap()
                        if !engine.pendingFashionUpgrades.isEmpty {
                            engine.pendingFashionUpgrades.removeFirst()
                        }
                    } label: {
                        Text("太漂亮啦 ✨")
                            .font(.system(size: 14.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#4A2E14"))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FFF0D6")))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(26)
            .frame(maxWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(hex: "#FFF0F5")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(hex: "#FFD166"), lineWidth: 3))
                    .shadow(color: Color.black.opacity(0.28), radius: 24, y: 10)
            )
        }
    }
}
