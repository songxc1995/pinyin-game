import SwiftUI

// MARK: - 魔法料理锅矢量视图（支持 5 款皮肤 + 蒸汽 + 灶火 + 表情变化）
public struct PotVectorView: View {
    public let skin: PotSkin
    public let isShaking: Bool
    public let isNope: Bool
    public let isHot: Bool
    public let steamOn: Bool
    public let fire: FireDifficulty
    public var size: CGFloat = 170

    @State private var flamePhase: Bool = false

    public init(
        skin: PotSkin,
        isShaking: Bool = false,
        isNope: Bool = false,
        isHot: Bool = false,
        steamOn: Bool = false,
        fire: FireDifficulty = .mid,
        size: CGFloat = 170
    ) {
        self.skin = skin
        self.isShaking = isShaking
        self.isNope = isNope
        self.isHot = isHot
        self.steamOn = steamOn
        self.fire = fire
        self.size = size
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 顶部蒸汽与糊锅小黑烟
            if steamOn {
                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 8, height: 28)
                            .shadow(color: Color(hex: "#F07D2E").opacity(0.4), radius: 4)
                            .offset(y: isShaking ? -36 : -22)
                            .animation(
                                .easeInOut(duration: 0.7).repeatForever(autoreverses: true).delay(Double(i) * 0.15),
                                value: steamOn
                            )
                    }
                }
                .offset(y: -size * 0.62)
            }

            if isNope {
                HStack(spacing: 10) {
                    Text("💨")
                    Text("☁️")
                    Text("💨")
                }
                .font(.system(size: 22))
                .offset(y: -size * 0.65)
                .transition(.scale.combined(with: .opacity))
            }

            // 锅体主体
            Canvas { context, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                let sx = w / 150.0
                let sy = h / 112.0

                let bodyColor = Color(hex: skin.bodyHex)
                let rimColor  = Color(hex: skin.rimHex)
                let lidColor  = Color(hex: skin.lidHex)
                let knobColor = Color(hex: skin.knobHex)
                let earColor  = Color(hex: skin.earHex)

                // 左右锅耳
                let leftEar = RoundedRectangle(cornerRadius: 6.5 * sx)
                    .path(in: CGRect(x: 6 * sx, y: 34 * sy, width: 30 * sx, height: 13 * sy))
                let rightEar = RoundedRectangle(cornerRadius: 6.5 * sx)
                    .path(in: CGRect(x: 114 * sx, y: 34 * sy, width: 30 * sx, height: 13 * sy))
                context.fill(leftEar, with: .color(earColor))
                context.fill(rightEar, with: .color(earColor))

                // 锅肚子
                var potBody = Path()
                potBody.move(to: CGPoint(x: 20 * sx, y: 34 * sy))
                potBody.addLine(to: CGPoint(x: 130 * sx, y: 34 * sy))
                potBody.addLine(to: CGPoint(x: 121 * sx, y: 89 * sy))
                potBody.addQuadCurve(
                    to: CGPoint(x: 104 * sx, y: 103 * sy),
                    control: CGPoint(x: 119 * sx, y: 103 * sy)
                )
                potBody.addLine(to: CGPoint(x: 46 * sx, y: 103 * sy))
                potBody.addQuadCurve(
                    to: CGPoint(x: 29 * sx, y: 89 * sy),
                    control: CGPoint(x: 31 * sx, y: 103 * sy)
                )
                potBody.closeSubpath()
                context.fill(potBody, with: .color(bodyColor))

                // 锅肚高光
                var highlight = Path()
                highlight.move(to: CGPoint(x: 31 * sx, y: 46 * sy))
                highlight.addQuadCurve(
                    to: CGPoint(x: 44 * sx, y: 90 * sy),
                    control: CGPoint(x: 34 * sx, y: 78 * sy)
                )
                context.stroke(highlight, with: .color(.white.opacity(0.32)), style: StrokeStyle(lineWidth: 4.2 * sx, lineCap: .round))

                // 锅沿
                let rimRect = RoundedRectangle(cornerRadius: 5.5 * sx)
                    .path(in: CGRect(x: 14 * sx, y: 29 * sy, width: 122 * sx, height: 11 * sy))
                context.fill(rimRect, with: .color(rimColor))

                // 锅盖（摇晃时向上弹起）
                let lidLift: CGFloat = isShaking ? -8.0 * sy : 0.0
                var lidPath = Path()
                lidPath.move(to: CGPoint(x: 24 * sx, y: 27 * sy + lidLift))
                lidPath.addQuadCurve(
                    to: CGPoint(x: 126 * sx, y: 27 * sy + lidLift),
                    control: CGPoint(x: 75 * sx, y: 5 * sy + lidLift)
                )
                lidPath.closeSubpath()
                context.fill(lidPath, with: .color(lidColor))

                let knobCircle = Circle().path(in: CGRect(x: 67.5 * sx, y: 4 * sy + lidLift, width: 15 * sx, height: 15 * sy))
                context.fill(knobCircle, with: .color(knobColor))

                var lidLine = Path()
                lidLine.move(to: CGPoint(x: 18 * sx, y: 26 * sy + lidLift))
                lidLine.addLine(to: CGPoint(x: 132 * sx, y: 26 * sy + lidLift))
                context.stroke(lidLine, with: .color(rimColor), style: StrokeStyle(lineWidth: 5.5 * sx, lineCap: .round))

                // 锅宝可爱表情
                let ink = Color(hex: "#3B2E22")
                let leftEye = Circle().path(in: CGRect(x: 52.2 * sx, y: 59.2 * sy, width: 9.6 * sx, height: 9.6 * sy))
                let rightEye = Circle().path(in: CGRect(x: 88.2 * sx, y: 59.2 * sy, width: 9.6 * sx, height: 9.6 * sy))
                context.fill(leftEye, with: .color(ink))
                context.fill(rightEye, with: .color(ink))

                let leftSpark = Circle().path(in: CGRect(x: 54 * sx, y: 60.8 * sy, width: 3.2 * sx, height: 3.2 * sy))
                let rightSpark = Circle().path(in: CGRect(x: 90 * sx, y: 60.8 * sy, width: 3.2 * sx, height: 3.2 * sy))
                context.fill(leftSpark, with: .color(.white))
                context.fill(rightSpark, with: .color(.white))

                // 腮红
                let leftBlush = Ellipse().path(in: CGRect(x: 42.5 * sx, y: 67.5 * sy, width: 9 * sx, height: 5 * sy))
                let rightBlush = Ellipse().path(in: CGRect(x: 98.5 * sx, y: 67.5 * sy, width: 9 * sx, height: 5 * sy))
                context.fill(leftBlush, with: .color(Color(hex: "#FFCDD2").opacity(0.75)))
                context.fill(rightBlush, with: .color(Color(hex: "#FFCDD2").opacity(0.75)))

                // 嘴巴（开心 vs 糊锅惊讶）
                var mouth = Path()
                if isNope {
                    mouth.move(to: CGPoint(x: 68 * sx, y: 77 * sy))
                    mouth.addQuadCurve(to: CGPoint(x: 82 * sx, y: 77 * sy), control: CGPoint(x: 75 * sx, y: 70 * sy))
                } else {
                    mouth.move(to: CGPoint(x: 68 * sx, y: 72 * sy))
                    mouth.addQuadCurve(to: CGPoint(x: 82 * sx, y: 72 * sy), control: CGPoint(x: 75 * sx, y: 80 * sy))
                }
                context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: 3.2 * sx, lineCap: .round))
            }
            .frame(width: size, height: size * 0.75)
            .rotationEffect(.degrees(isShaking ? -4 : (isNope ? 4 : 0)))
            .scaleEffect(isHot ? 1.06 : 1.0)
            .shadow(color: isHot ? Color(hex: "#FFA028").opacity(0.55) : Color.black.opacity(0.12), radius: isHot ? 14 : 6, y: 4)
            .animation(.spring(response: 0.28, dampingFraction: 0.45), value: isShaking)
            .animation(.spring(response: 0.22, dampingFraction: 0.40), value: isNope)

            // 底部灶火苗动画
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    let hScale: CGFloat = (i == 2) ? 1.25 : ((i == 1 || i == 3) ? 1.1 : 0.9)
                    let fireScale: CGFloat = fire == .high ? 1.22 : (fire == .low ? 0.80 : 1.0)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FFF176"), Color(hex: "#FF9800"), Color(hex: "#F44336")],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 13 * fireScale, height: 18 * hScale * fireScale)
                        .scaleEffect(y: flamePhase ? 1.14 : 0.88, anchor: .bottom)
                        .rotationEffect(.degrees(flamePhase ? Double(i % 2 == 0 ? 5 : -5) : Double(i % 2 == 0 ? -4 : 4)))
                        .animation(
                            .easeInOut(duration: 0.42).repeatForever(autoreverses: true).delay(Double(i) * 0.07),
                            value: flamePhase
                        )
                }
            }
            .offset(y: 6)
        }
        .onAppear {
            flamePhase = true
        }
    }
}

// MARK: - 蝴蝶矢量视图（支持 20 种配色 + 3 阶进化光环与金边）
public struct ButterflyVectorView: View {
    public let species: ButterflySpecies
    public let stage: Int // 1 初见, 2 闪耀, 3 华丽
    public var size: CGFloat = 56
    public var animated: Bool = true

    @State private var flapping: Bool = false

    public init(species: ButterflySpecies, stage: Int = 1, size: CGFloat = 56, animated: Bool = true) {
        self.species = species
        self.stage = max(1, stage)
        self.size = size
        self.animated = animated
    }

    public var body: some View {
        ZStack {
            // 2阶/3阶进化背后的柔光光环
            if stage >= 2 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: species.secondaryHex).opacity(stage >= 3 ? 0.72 : 0.48),
                                Color(hex: species.primaryHex).opacity(stage >= 3 ? 0.35 : 0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.55
                        )
                    )
                    .frame(width: size * 1.1, height: size * 1.1)
            }

            // 稀有蝶虚线光圈
            if species.rarity == 3 {
                Circle()
                    .stroke(
                        Color(hex: species.id == "h" ? "#7F77DD" : "#FAC775").opacity(0.75),
                        style: StrokeStyle(lineWidth: 1.6, dash: [6, 5])
                    )
                    .frame(width: size * 0.92, height: size * 0.92)
            }

            // 蝴蝶双翅与身体
            Canvas { context, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                let sx = w / 100.0
                let sy = h / 92.0

                let c1 = Color(hex: species.primaryHex)
                let c2 = Color(hex: species.secondaryHex)
                let grad = Gradient(colors: [c1, c2])

                func drawHalfWing(mirror: Bool) {
                    var ctx = context
                    if mirror {
                        ctx.transform = CGAffineTransform(translationX: w, y: 0).scaledBy(x: -1, y: 1)
                    }

                    // 上翅
                    var upper = Path()
                    upper.move(to: CGPoint(x: 50 * sx, y: 45 * sy))
                    upper.addCurve(
                        to: CGPoint(x: 15 * sx, y: 9 * sy),
                        control1: CGPoint(x: 45 * sx, y: 20 * sy),
                        control2: CGPoint(x: 31 * sx, y: 5 * sy)
                    )
                    upper.addCurve(
                        to: CGPoint(x: 17 * sx, y: 37 * sy),
                        control1: CGPoint(x: 5 * sx, y: 12 * sy),
                        control2: CGPoint(x: 5 * sx, y: 26 * sy)
                    )
                    upper.addCurve(
                        to: CGPoint(x: 50 * sx, y: 45 * sy),
                        control1: CGPoint(x: 26 * sx, y: 45 * sy),
                        control2: CGPoint(x: 40 * sx, y: 48 * sy)
                    )
                    upper.closeSubpath()

                    // 下翅
                    var lower = Path()
                    lower.move(to: CGPoint(x: 50 * sx, y: 51 * sy))
                    lower.addCurve(
                        to: CGPoint(x: 29 * sx, y: 76 * sy),
                        control1: CGPoint(x: 41 * sx, y: 58 * sy),
                        control2: CGPoint(x: 29 * sx, y: 64 * sy)
                    )
                    lower.addCurve(
                        to: CGPoint(x: 47 * sx, y: 78 * sy),
                        control1: CGPoint(x: 29 * sx, y: 86 * sy),
                        control2: CGPoint(x: 40 * sx, y: 88 * sy)
                    )
                    lower.addCurve(
                        to: CGPoint(x: 50 * sx, y: 51 * sy),
                        control1: CGPoint(x: 51 * sx, y: 72 * sy),
                        control2: CGPoint(x: 51 * sx, y: 60 * sy)
                    )
                    lower.closeSubpath()

                    ctx.fill(upper, with: .linearGradient(grad, startPoint: CGPoint(x: 10 * sx, y: 10 * sy), endPoint: CGPoint(x: 50 * sx, y: 50 * sy)))
                    ctx.fill(lower, with: .linearGradient(grad, startPoint: CGPoint(x: 25 * sx, y: 50 * sy), endPoint: CGPoint(x: 50 * sx, y: 85 * sy)))

                    if stage >= 2 {
                        let goldColor = Color(hex: stage >= 3 ? "#F5C542" : "#F0C95C")
                        let strokeW = (stage >= 3 ? 2.4 : 1.3) * sx
                        ctx.stroke(upper, with: .color(goldColor), lineWidth: strokeW)
                        ctx.stroke(lower, with: .color(goldColor), lineWidth: strokeW)
                    }

                    // 翅斑点缀
                    let spot1 = Circle().path(in: CGRect(x: 16 * sx, y: 20 * sy, width: 12 * sx, height: 12 * sy))
                    ctx.fill(spot1, with: .color(c1.opacity(0.85)))
                    let spot1Inner = Circle().path(in: CGRect(x: 18.6 * sx, y: 22.6 * sy, width: 6.8 * sx, height: 6.8 * sy))
                    ctx.fill(spot1Inner, with: .color(.white.opacity(0.82)))

                    let spot2 = Circle().path(in: CGRect(x: 33.4 * sx, y: 70.4 * sy, width: 7.2 * sx, height: 7.2 * sy))
                    ctx.fill(spot2, with: .color(.white.opacity(0.75)))
                }

                drawHalfWing(mirror: false)
                drawHalfWing(mirror: true)

                // 身体与触角
                let bodyColor = Color(hex: "#4A3F33")
                let bodyOval = Ellipse().path(in: CGRect(x: 46.2 * sx, y: 39 * sy, width: 7.6 * sx, height: 34 * sy))
                context.fill(bodyOval, with: .color(bodyColor))
                let headCircle = Circle().path(in: CGRect(x: 45.6 * sx, y: 33.6 * sy, width: 8.8 * sx, height: 8.8 * sy))
                context.fill(headCircle, with: .color(bodyColor))

                var antL = Path()
                antL.move(to: CGPoint(x: 48 * sx, y: 35 * sy))
                antL.addQuadCurve(to: CGPoint(x: 32 * sx, y: 21 * sy), control: CGPoint(x: 41 * sx, y: 25 * sy))
                var antR = Path()
                antR.move(to: CGPoint(x: 52 * sx, y: 35 * sy))
                antR.addQuadCurve(to: CGPoint(x: 68 * sx, y: 21 * sy), control: CGPoint(x: 59 * sx, y: 25 * sy))
                context.stroke(antL, with: .color(bodyColor), style: StrokeStyle(lineWidth: 1.8 * sx, lineCap: .round))
                context.stroke(antR, with: .color(bodyColor), style: StrokeStyle(lineWidth: 1.8 * sx, lineCap: .round))
            }
            .frame(width: size, height: size * 0.92)
            .scaleEffect(x: (animated && flapping) ? 0.86 : 1.0, y: 1.0)
            .animation(
                animated ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true) : .default,
                value: flapping
            )

            // 3阶完全进化星光点缀
            if stage >= 3 {
                Text("✨")
                    .font(.system(size: size * 0.26))
                    .offset(x: size * 0.34, y: -size * 0.32)
            }
        }
        .onAppear {
            if animated { flapping = true }
        }
    }
}

// MARK: - 拼音食材 3D 卡片（支持点击 + 手指/鼠标拖拽下锅）
public struct PinyinIngredientCardView: View {
    public let kind: String   // "i" 声母, "m" 介音, "b" 无调韵母, "f" 带调韵母
    public let text: String
    public let isSelected: Bool
    public let isCorrectHint: Bool
    public let isDimmed: Bool
    public let action: () -> Void

    public var body: some View {
        let theme = cardTheme
        Button(action: action) {
            Text(text)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(isCorrectHint ? Color(hex: "#2B7F4A") : theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minWidth: 62, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isCorrectHint ? Color(hex: "#E6F7ED") : theme.bg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            isCorrectHint ? Color(hex: "#3EA865") : (isSelected ? theme.activeBorder : theme.border),
                            lineWidth: (isSelected || isCorrectHint) ? 3.0 : 2.0
                        )
                )
                .shadow(color: theme.lip.opacity(0.28), radius: 0, x: 0, y: isSelected ? 1.5 : 3.5)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .opacity(isDimmed ? 0.28 : 1.0)
        }
        .buttonStyle(.plain)
        .onDrag {
            NSItemProvider(object: "\(kind):\(text)" as NSString)
        }
    }

    private var cardTheme: (bg: Color, border: Color, activeBorder: Color, text: Color, lip: Color) {
        switch kind {
        case "i":
            return (
                Color(hex: "#EBF5FF"),
                Color(hex: "#A8D0F8"),
                Color(hex: "#3685D6"),
                Color(hex: "#1F5F9E"),
                Color(hex: "#2564A8")
            )
        case "m":
            return (
                Color(hex: "#F2F0FF"),
                Color(hex: "#C3BEF7"),
                Color(hex: "#7A6EE6"),
                Color(hex: "#4E44A8"),
                Color(hex: "#564AB8")
            )
        default: // "b" or "f"
            return (
                Color(hex: "#FFF4E8"),
                Color(hex: "#F6CB9F"),
                Color(hex: "#F07D2E"),
                Color(hex: "#B25614"),
                Color(hex: "#C85D14")
            )
        }
    }
}

// MARK: - 🧂 四声调料瓶卡片组件（带声调坡度轨迹 + 实时音节预览 + 拖拽支持）
public struct ToneBottleCardView: View {
    public let bottle: ToneSeasoningBottle
    public let baseFinal: String?
    public let initial: String?
    public let medial: String?
    public let mode: LevelMode
    public let isSelected: Bool
    public let isCorrectHint: Bool
    public let action: () -> Void

    public var previewSyllable: String {
        guard let base = baseFinal else {
            return "\(bottle.id)声 \(bottle.markSymbol)"
        }
        let toned = PinyinHelper.applyTone(base: base, tone: bottle.id)
        if mode == .whole {
            return toned
        }
        let ini = initial ?? ""
        var med = medial ?? ""
        if ["j", "q", "x"].contains(ini) && med == "ü" {
            med = "u"
        }
        return ini + med + toned
    }

    public var previewTonedFinal: String {
        guard let base = baseFinal else { return bottle.markSymbol }
        return PinyinHelper.applyTone(base: base, tone: bottle.id)
    }

    public var body: some View {
        let active = (baseFinal != nil)
        let accent = Color(hex: bottle.colorHex)

        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(bottle.bottleEmoji)
                        .font(.system(size: 18))
                    Text(previewTonedFinal)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(active ? accent : Color(hex: "#8A7765"))
                    Spacer(minLength: 2)
                    Text("\(bottle.id)")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(active ? accent : Color.gray.opacity(0.45)))
                }

                // 完整拼读预览与手势口诀
                HStack(spacing: 4) {
                    Text(bottle.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#4A2E14"))
                    Spacer(minLength: 2)
                    if active {
                        Text("→ \(previewSyllable)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(accent)
                    } else {
                        Text(bottle.gestureHint)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#8A7765"))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isCorrectHint
                        ? Color(hex: "#E6F7ED")
                        : (isSelected ? accent.opacity(0.16) : (active ? Color.white : Color(hex: "#FAF6F0")))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isCorrectHint
                        ? Color(hex: "#3EA865")
                        : (isSelected ? accent : (active ? accent.opacity(0.55) : Color.black.opacity(0.10))),
                        lineWidth: (isSelected || isCorrectHint) ? 3.0 : (active ? 2.0 : 1.5)
                    )
            )
            .shadow(color: active ? accent.opacity(0.18) : .clear, radius: 4, x: 0, y: 3)
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .onDrag {
            NSItemProvider(object: "t:\(bottle.id)" as NSString)
        }
    }
}
