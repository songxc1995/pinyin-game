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
    public let animated: Bool
    public let gentleMotion: Bool

    public init(
        skin: PotSkin,
        isShaking: Bool = false,
        isNope: Bool = false,
        isHot: Bool = false,
        steamOn: Bool = false,
        fire: FireDifficulty = .mid,
        size: CGFloat = 170,
        animated: Bool = true,
        gentleMotion: Bool = false
    ) {
        self.skin = skin
        self.isShaking = isShaking
        self.isNope = isNope
        self.isHot = isHot
        self.steamOn = steamOn
        self.fire = fire
        self.size = size
        self.animated = animated
        self.gentleMotion = gentleMotion
    }

    public var body: some View {
        let shouldAnimate = animated && !gentleMotion
        let flameScaleUnit: CGFloat = min(1.0, max(0.30, size / 140.0))

        ZStack(alignment: .bottom) {
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

                // 锅沿光泽（立体感双层描边）
                let rimRect = RoundedRectangle(cornerRadius: 5.5 * sx)
                    .path(in: CGRect(x: 14 * sx, y: 29 * sy, width: 122 * sx, height: 11 * sy))
                context.fill(rimRect, with: .color(rimColor))
                var rimGloss = Path()
                rimGloss.move(to: CGPoint(x: 20 * sx, y: 31.5 * sy))
                rimGloss.addLine(to: CGPoint(x: 130 * sx, y: 31.5 * sy))
                context.stroke(rimGloss, with: .color(.white.opacity(0.36)), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))

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

                var lidHighlight = Path()
                lidHighlight.move(to: CGPoint(x: 38 * sx, y: 22 * sy + lidLift))
                lidHighlight.addQuadCurve(
                    to: CGPoint(x: 68 * sx, y: 15 * sy + lidLift),
                    control: CGPoint(x: 50 * sx, y: 15.5 * sy + lidLift)
                )
                context.stroke(lidHighlight, with: .color(.white.opacity(0.42)), style: StrokeStyle(lineWidth: 2.8 * sx, lineCap: .round))

                let knobCircle = Circle().path(in: CGRect(x: 67.5 * sx, y: 4 * sy + lidLift, width: 15 * sx, height: 15 * sy))
                context.fill(knobCircle, with: .color(knobColor))
                let knobSpec = Circle().path(in: CGRect(x: 70.5 * sx, y: 6.2 * sy + lidLift, width: 4.5 * sx, height: 4.5 * sy))
                context.fill(knobSpec, with: .color(.white.opacity(0.55)))

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
            .rotationEffect(.degrees(gentleMotion ? 0 : (isShaking ? -4 : (isNope ? 4 : 0))))
            .scaleEffect(isHot ? (gentleMotion ? 1.03 : 1.06) : 1.0)
            .shadow(color: isHot ? Color(hex: "#FFA028").opacity(0.55) : Color.black.opacity(0.12), radius: isHot ? 14 : 6, y: 4)
            .animation(gentleMotion ? .easeOut(duration: 0.25) : .spring(response: 0.28, dampingFraction: 0.45), value: isShaking)
            .animation(gentleMotion ? .easeOut(duration: 0.25) : .spring(response: 0.22, dampingFraction: 0.40), value: isNope)

            // 底部灶火苗动画（固定外框 + 仅在 animated && !gentleMotion 时以 20fps Canvas 绘制，避免触发布局重算）
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !shouldAnimate)) { timeline in
                let t = shouldAnimate ? timeline.date.timeIntervalSinceReferenceDate : 0.0
                Canvas { context, canvasSize in
                    let fireScale: CGFloat = fire == .high ? 1.22 : (fire == .low ? 0.80 : 1.0)
                    let cx = canvasSize.width * 0.5
                    let baseY = canvasSize.height - 6 * flameScaleUnit

                    // 火苗底部柔光椭圆
                    let glowW = min(canvasSize.width, size * 0.56)
                    let glowH = 10 * flameScaleUnit
                    let glowRect = CGRect(x: cx - glowW * 0.5, y: baseY - glowH * 0.35, width: glowW, height: glowH)
                    context.fill(
                        Ellipse().path(in: glowRect),
                        with: .color(Color(hex: "#FF9800").opacity(gentleMotion ? 0.16 : 0.26))
                    )

                    let spacing = 6.0 * flameScaleUnit
                    let capW = 13.0 * fireScale * flameScaleUnit
                    let totalW = 5.0 * capW + 4.0 * spacing
                    let startX = cx - totalW * 0.5
                    let grad = Gradient(colors: [Color(hex: "#FFF59D"), Color(hex: "#FF9800"), Color(hex: "#E64A19")])

                    for i in 0..<5 {
                        let hScale: CGFloat = (i == 2) ? 1.25 : ((i == 1 || i == 3) ? 1.1 : 0.9)
                        let baseH = 18.0 * hScale * fireScale * flameScaleUnit
                        let wave: Double = shouldAnimate
                            ? 0.5 + 0.5 * sin(t * (Double.pi / 0.48) - Double(i) * 0.45)
                            : 0.46
                        let stretchY = shouldAnimate ? CGFloat(0.88 + 0.26 * wave) : 1.0
                        let deg: Double = shouldAnimate
                            ? (i % 2 == 0 ? (-4.0 + 9.0 * wave) : (4.0 - 9.0 * wave))
                            : 0.0

                        let flameX = startX + CGFloat(i) * (capW + spacing) + capW * 0.5
                        let drawH = baseH * stretchY
                        let rect = CGRect(x: -capW * 0.5, y: -drawH, width: capW, height: drawH)
                        let capsulePath = Capsule().path(in: rect)

                        context.drawLayer { layer in
                            layer.translateBy(x: flameX, y: baseY)
                            if abs(deg) > 0.05 {
                                layer.rotate(by: .degrees(deg))
                            }
                            layer.fill(
                                capsulePath,
                                with: .linearGradient(
                                    grad,
                                    startPoint: CGPoint(x: 0, y: 0),
                                    endPoint: CGPoint(x: 0, y: -drawH)
                                )
                            )
                        }
                    }
                }
            }
            .frame(width: max(size * 0.85, 118 * flameScaleUnit), height: 34 * flameScaleUnit)
            .offset(y: 6 * flameScaleUnit)
        }
        .frame(width: size, height: size * 0.82)
        .background(alignment: .bottom) {
            if isHot {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#FFB347").opacity(gentleMotion ? 0.25 : 0.42),
                                Color(hex: "#FF6B6B").opacity(0.14),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: size * 0.65
                        )
                    )
                    .frame(width: size * 1.25, height: size * 1.05)
                    .offset(y: -size * 0.08)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .bottom) {
            Group {
                if steamOn {
                    TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: !shouldAnimate)) { timeline in
                        let t = shouldAnimate ? timeline.date.timeIntervalSinceReferenceDate : 0.0
                        Canvas { context, canvasSize in
                            let cx = canvasSize.width * 0.5
                            let spacing: CGFloat = 14
                            let capW: CGFloat = 9
                            let totalW = 4 * capW + 3 * spacing
                            let startX = cx - totalW * 0.5
                            let grad = Gradient(colors: [Color.white.opacity(0.92), Color(hex: "#FFF4E3").opacity(0.45)])

                            for i in 0..<4 {
                                let capH: CGFloat = i.isMultiple(of: 2) ? 30 : 24
                                let wave: Double = shouldAnimate
                                    ? 0.5 + 0.5 * sin(t * (Double.pi / 0.85) - Double(i) * 0.52)
                                    : (isShaking ? 0.55 : 0.25)
                                let liftOffset: CGFloat = gentleMotion
                                    ? (isShaking ? -6 : 0)
                                    : CGFloat(-18.0 * wave)
                                let alpha: Double = gentleMotion
                                    ? 0.85
                                    : (0.55 + 0.40 * wave)
                                let x = startX + CGFloat(i) * (capW + spacing)
                                let y = canvasSize.height - capH - 6 + liftOffset
                                let rect = CGRect(x: x, y: y, width: capW, height: capH)
                                context.drawLayer { layer in
                                    layer.opacity = alpha
                                    layer.addFilter(.shadow(color: Color(hex: "#F07D2E").opacity(0.32), radius: 4))
                                    layer.fill(
                                        Capsule().path(in: rect),
                                        with: .linearGradient(
                                            grad,
                                            startPoint: CGPoint(x: x, y: y),
                                            endPoint: CGPoint(x: x, y: y + capH)
                                        )
                                    )
                                }
                            }
                        }
                    }
                    .frame(width: 96, height: 64)
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
            }
            .allowsHitTesting(false)
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
    public let gentleMotion: Bool
    public let action: () -> Void

    public init(
        kind: String,
        text: String,
        isSelected: Bool,
        isCorrectHint: Bool,
        isDimmed: Bool,
        gentleMotion: Bool = false,
        action: @escaping () -> Void
    ) {
        self.kind = kind
        self.text = text
        self.isSelected = isSelected
        self.isCorrectHint = isCorrectHint
        self.isDimmed = isDimmed
        self.gentleMotion = gentleMotion
        self.action = action
    }

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
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(isCorrectHint ? Color(hex: "#E6F7ED") : theme.bg)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.65), Color.white.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 16)
                            .padding(.horizontal, 3)
                            .padding(.top, 2)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            isCorrectHint ? Color(hex: "#3EA865") : (isSelected ? theme.activeBorder : theme.border),
                            lineWidth: (isSelected || isCorrectHint) ? 3.0 : 2.0
                        )
                )
                .shadow(color: theme.lip.opacity(0.28), radius: 0, x: 0, y: isSelected ? 1.5 : 3.5)
                .scaleEffect(isSelected ? (gentleMotion ? 1.02 : 1.06) : 1.0)
                .opacity(isDimmed ? 0.28 : 1.0)
                .animation(gentleMotion ? .easeOut(duration: 0.16) : .spring(response: 0.24, dampingFraction: 0.65), value: isSelected)
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
    public let gentleMotion: Bool
    public let action: () -> Void

    public init(
        bottle: ToneSeasoningBottle,
        baseFinal: String?,
        initial: String?,
        medial: String?,
        mode: LevelMode,
        isSelected: Bool,
        isCorrectHint: Bool,
        gentleMotion: Bool = false,
        action: @escaping () -> Void
    ) {
        self.bottle = bottle
        self.baseFinal = baseFinal
        self.initial = initial
        self.medial = medial
        self.mode = mode
        self.isSelected = isSelected
        self.isCorrectHint = isCorrectHint
        self.gentleMotion = gentleMotion
        self.action = action
    }

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
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isCorrectHint
                            ? Color(hex: "#E6F7ED")
                            : (isSelected ? accent.opacity(0.16) : (active ? Color.white : Color(hex: "#FAF6F0")))
                        )
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.75), Color.white.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 15)
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                }
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
            .scaleEffect(isSelected ? (gentleMotion ? 1.02 : 1.04) : 1.0)
            .animation(gentleMotion ? .easeOut(duration: 0.16) : .spring(response: 0.24, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
        .onDrag {
            NSItemProvider(object: "t:\(bottle.id)" as NSString)
        }
    }
}

// MARK: - 🪙 悬浮星币爆发飘字组件（护眼温和动效兼容）
public struct CoinBurstPillView: View {
    public let text: String
    public let isFever: Bool
    public let gentleMotion: Bool

    @State private var appeared: Bool = false

    public init(text: String, isFever: Bool = false, gentleMotion: Bool = false) {
        self.text = text
        self.isFever = isFever
        self.gentleMotion = gentleMotion
    }

    public var body: some View {
        HStack(spacing: 5) {
            Text(isFever ? "🔥" : "🪙")
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(
                LinearGradient(
                    colors: isFever
                        ? [Color(hex: "#FF7043"), Color(hex: "#D84315")]
                        : [Color(hex: "#F5B82E"), Color(hex: "#E68A00")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.85), lineWidth: 1.8)
        )
        .shadow(color: Color(hex: isFever ? "#FF7043" : "#F5B82E").opacity(0.42), radius: 8, y: 3)
        .offset(y: appeared ? (gentleMotion ? -6 : -18) : 6)
        .scaleEffect(appeared ? 1.0 : (gentleMotion ? 0.96 : 0.78))
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(gentleMotion ? .easeOut(duration: 0.28) : .spring(response: 0.34, dampingFraction: 0.58)) {
                appeared = true
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - ✨ 护眼温和礼花撒花脉冲组件（不与烟花重名）
public struct CustomConfettiBurstView: View {
    public let burstID: Int
    public let isFever: Bool
    public let gentleMotion: Bool

    @State private var progress: CGFloat = 0

    public init(burstID: Int, isFever: Bool = false, gentleMotion: Bool = false) {
        self.burstID = burstID
        self.isFever = isFever
        self.gentleMotion = gentleMotion
    }

    private static let particleColors: [String] = [
        "#FFD54F", "#FF8A65", "#F06292", "#81C784", "#4FC3F7", "#BA68C8"
    ]

    public var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { idx in
                let angle = Double(idx) * (.pi * 2.0 / 12.0) + (idx.isMultiple(of: 2) ? 0.12 : -0.12)
                let maxRadius: CGFloat = gentleMotion ? (isFever ? 46 : 36) : (isFever ? 78 : 62)
                let dist = maxRadius * progress
                let x = cos(angle) * dist
                let y = sin(angle) * dist
                let colorHex = Self.particleColors[idx % Self.particleColors.count]

                Group {
                    if idx % 3 == 0 {
                        Image(systemName: "sparkle")
                            .font(.system(size: isFever ? 13 : 11, weight: .bold))
                            .foregroundColor(Color(hex: colorHex))
                    } else if idx % 3 == 1 {
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 7, height: 7)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: colorHex))
                            .frame(width: 8, height: 5)
                            .rotationEffect(.degrees(Double(idx) * 35 + Double(progress) * (gentleMotion ? 20 : 110)))
                    }
                }
                .offset(x: x, y: y)
                .scaleEffect(max(0.25, 1.08 - progress * 0.45))
                .opacity(progress <= 0.02 ? 0 : Double(max(0, 1.0 - max(0, progress - 0.35) / 0.65)))
            }
        }
        .onAppear { triggerBurst() }
        .onCompatChange(of: burstID) { _ in triggerBurst() }
        .allowsHitTesting(false)
    }

    private func triggerBurst() {
        guard burstID > 0 else { return }
        progress = 0.01
        withAnimation(gentleMotion ? .easeOut(duration: 0.65) : .easeOut(duration: 0.85)) {
            progress = 1.0
        }
    }
}

public extension View {
    /// 跨 iOS 16/17+ 与 macOS 13/14+ 的零警告值变更监听
    @ViewBuilder
    func onCompatChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}
