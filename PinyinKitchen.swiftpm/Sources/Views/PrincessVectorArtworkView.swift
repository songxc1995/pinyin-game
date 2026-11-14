import SwiftUI

// MARK: - 1. 👗 满满小公主高定五阶全矢量插画视图 (PrincessAvatarVectorView)
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
    public let hairColor: HairColorOption
    public let expression: PrincessExpression
    public let pose: PrincessPose
    public let suitBonus: SuitBonusInfo
    public let isPreviewMode: Bool
    public let previewStage: Int
    public var size: CGFloat = 180
    public var animated: Bool = true
    public var twirlTrigger: Int = 0
    public var gentleMotion: Bool = false

    @State private var twirlAngle: Double = 0
    @State private var twirlFlare: Bool = false
    @State private var twirlSparkScale: CGFloat = 0.2
    @State private var twirlSparkOpacity: Double = 0.0

    public init(
        progress: GameProgress,
        size: CGFloat = 180,
        animated: Bool = true,
        twirlTrigger: Int = 0,
        gentleMotion: Bool = false
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
        self.hairColor = progress.currentHairColor
        self.expression = progress.currentExpression
        self.pose = progress.currentPose
        self.suitBonus = progress.suitBonusInfo()
        self.isPreviewMode = false
        self.previewStage = 1
        self.size = size
        self.animated = animated
        self.twirlTrigger = twirlTrigger
        self.gentleMotion = gentleMotion
    }

    public init(
        previewItem: PrincessFashionItem,
        previewStage: Int,
        progress: GameProgress,
        size: CGFloat = 180,
        animated: Bool = true,
        twirlTrigger: Int = 0,
        gentleMotion: Bool = false
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
        self.hairColor = progress.currentHairColor
        self.expression = progress.currentExpression
        self.pose = progress.currentPose
        self.suitBonus = Self.computeSuitBonus(dress: d, tiara: h, jewelry: j, wings: w, wand: wd)
        self.isPreviewMode = true
        self.previewStage = max(1, previewStage)
        self.size = size
        self.animated = animated
        self.twirlTrigger = twirlTrigger
        self.gentleMotion = gentleMotion
    }

    private static func computeSuitBonus(
        dress: PrincessFashionItem,
        tiara: PrincessFashionItem,
        jewelry: PrincessFashionItem,
        wings: PrincessFashionItem,
        wand: PrincessFashionItem
    ) -> SuitBonusInfo {
        let items = [dress, tiara, jewelry, wings, wand]
        var counts: [Int: Int] = [:]
        for item in items {
            counts[item.styleIndex, default: 0] += 1
        }
        let bestStyle = counts.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            if lhs.key == dress.styleIndex { return false }
            if rhs.key == dress.styleIndex { return true }
            return lhs.key < rhs.key
        }?.key ?? dress.styleIndex
        let matched = counts[bestStyle] ?? 0
        let suit = PrincessFashionSuit.byStyleIndex(bestStyle)
        let isHalf = matched >= 3
        let isFull = matched == 5
        let pct = isFull ? 35 : (isHalf ? 15 : 0)
        let mult = isFull ? 1.35 : (isHalf ? 1.15 : 1.0)
        return SuitBonusInfo(
            suit: suit,
            suitName: suit.name,
            matchedCount: matched,
            isHalfResonance: isHalf,
            isFullResonance: isFull,
            glamourBonusPercent: pct,
            glamourMultiplier: mult,
            stageThemeId: bestStyle,
            coinBonus: isFull ? suit.fullCoinBonus : 0
        )
    }

    private var effectiveMaxStage: Int {
        max(dressStage, max(tiaraStage, max(jewelryStage, max(wingsStage, wandStage))))
    }

    public var body: some View {
        let interval: TimeInterval = gentleMotion ? (1.0 / 8.0) : (size <= 64 ? (1.0 / 10.0) : (1.0 / 12.0))
        ZStack {
            Group {
                if animated {
                    TimelineView(.periodic(from: Date(timeIntervalSinceReferenceDate: 0), by: interval)) { timeline in
                        avatarCanvas(time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    avatarCanvas(time: 0)
                }
            }
            .scaleEffect(x: twirlFlare ? 1.09 : 1.0, y: twirlFlare ? 0.97 : 1.0)
            .rotation3DEffect(
                .degrees(twirlAngle),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.45
            )

            if twirlSparkOpacity > 0.01 {
                twirlSparkBurstLayer
            }
        }
        .frame(width: size, height: size)
        .onCompatChange(of: twirlTrigger) { _ in
            triggerTwirlAnimation()
        }
    }

    private func triggerTwirlAnimation() {
        withAnimation(.spring(response: 0.72, dampingFraction: 0.68)) {
            twirlAngle += 360
        }
        withAnimation(.easeOut(duration: 0.24)) {
            twirlFlare = true
            twirlSparkScale = 1.15
            twirlSparkOpacity = 1.0
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 320_000_000)
            withAnimation(.easeInOut(duration: 0.42)) {
                twirlFlare = false
                twirlSparkScale = 1.45
                twirlSparkOpacity = 0.0
            }
        }
    }

    private func avatarCanvas(time: TimeInterval) -> some View {
        let motionRate: Double = gentleMotion ? 0.42 : 1.0
        let ampScale: CGFloat = gentleMotion ? 0.50 : 1.0
        let t = animated ? time * motionRate : 0.0
        let breath = animated ? CGFloat(sin(t * 2.1)) * 2.6 * ampScale : 0.0
        let wingSway = animated ? CGFloat(sin(t * 3.4)) * ampScale : 0.0
        let skirtSway = animated ? CGFloat(sin(t * 2.3 + 0.7)) * ampScale : 0.0
        let auraSpin = animated ? (t * 22.0).truncatingRemainder(dividingBy: 360.0) : 0.0
        let shimmerPos = animated ? CGFloat((t * 0.45).truncatingRemainder(dividingBy: 1.6)) - 0.3 : 0.45

        return Canvas { context, canvasSize in
            let w = size
            let h = size
            let padX = (canvasSize.width - w) * 0.5
            let padY = (canvasSize.height - h) * 0.5
            let sx = w / 160.0
            let sy = h / 160.0

            // A. 套装共鸣光圈 + 高定星环背光（纯 Canvas 绘制，避免每帧触发布局重算）
            context.drawLayer { auraCtx in
                auraCtx.translateBy(x: padX, y: padY)
                drawResonanceAura(context: &auraCtx, auraSpin: auraSpin, t: t, ampScale: ampScale)
            }

            // B. 核心小公主高定 7 层矢量画布（呼吸偏移动画在画布层内部完成）
            context.drawLayer { bodyCtx in
                bodyCtx.translateBy(x: padX, y: padY + breath)
                let poseLift: CGFloat = pose.id == "leap" ? -6.5 : 0.0
                let skirtLiftL: CGFloat = pose.id == "curtsy" ? -2.2 : 0.0

                // 0. 舞台投影 & 4/5阶脚下旋转星阵
                drawStagePedestal(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    auraSpin: auraSpin,
                    maxStage: effectiveMaxStage,
                    suitBonus: suitBonus
                )

                // 1. 梦幻背饰与神翼
                drawBackWings(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    dy: poseLift,
                    flap: wingSway,
                    shimmerPos: shimmerPos
                )

                // 2. 柔顺长卷发后景（随 HairColorOption & hairTiara.styleIndex 分化）
                drawBackHair(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    dy: poseLift,
                    sway: skirtSway
                )

                // 3. 小公主双腿与芭蕾/玛丽珍鞋
                drawLegsAndShoes(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    dy: poseLift
                )

                // 4. 高定礼服裙装（6 大轮廓 + 5 阶刺绣/蕾丝/星钻/拖尾/虹彩扫光）
                drawDress(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    dy: poseLift,
                    sway: skirtSway,
                    skirtLiftL: skirtLiftL,
                    shimmerPos: shimmerPos,
                    flare: twirlFlare
                )

                // 5. 项链与耳坠珠宝
                drawJewelry(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    dy: poseLift
                )

                // 6. 甜美脸庞、4 种可切换表情与高光刘海
                drawFaceAndFrontHair(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    dy: poseLift
                )

                // 7. 皇冠发饰
                drawTiara(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    dy: poseLift
                )

                // 8. 双手 Pose 与魔法手持道具
                drawArmsAndWand(
                    context: &bodyCtx,
                    sx: sx,
                    sy: sy,
                    dy: poseLift,
                    sway: skirtSway
                )
            }
        }
        .frame(width: size * 1.16, height: size * 1.16)
    }

    // MARK: - 外层套装共鸣光圈 & 粒子星环（纯 GraphicsContext 绘制）
    private func drawResonanceAura(context: inout GraphicsContext, auraSpin: Double, t: Double, ampScale: CGFloat) {
        let cx = size * 0.5
        let cy = size * 0.5
        let center = CGPoint(x: cx, y: cy)
        let auraColor = Color(hex: suitBonus.suit.primaryHex)
        let accentColor = Color(hex: suitBonus.suit.accentHex)

        if suitBonus.isFullResonance {
            // 5件全套大共鸣：皇家粒子光环
            let glowR = size * 0.56
            let glowRect = CGRect(x: cx - glowR, y: cy - glowR, width: glowR * 2, height: glowR * 2)
            context.fill(
                Circle().path(in: glowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(hex: "#FFD166").opacity(0.42),
                        auraColor.opacity(0.28),
                        accentColor.opacity(0.14),
                        Color.clear
                    ]),
                    center: center,
                    startRadius: size * 0.06,
                    endRadius: glowR
                )
            )

            let ringR = size * 0.49
            let ringRect = CGRect(x: -ringR, y: -ringR, width: ringR * 2, height: ringR * 2)
            context.drawLayer { layer in
                layer.translateBy(x: cx, y: cy)
                layer.rotate(by: .degrees(auraSpin))
                layer.stroke(
                    Circle().path(in: ringRect),
                    with: .conicGradient(
                        Gradient(colors: [
                            Color(hex: "#FFD166"),
                            auraColor,
                            Color.white.opacity(0.9),
                            accentColor,
                            Color(hex: "#FFD166")
                        ]),
                        center: .zero
                    ),
                    style: StrokeStyle(lineWidth: 2.6, dash: [8, 5])
                )
            }

            // 环绕皇家共鸣粒子（纯几何星点）
            let orbitR = size * 0.46
            for idx in 0..<8 {
                let baseAngle = Double(idx) * (.pi / 4.0) + (auraSpin * .pi / 180.0)
                let px = cx + CGFloat(cos(baseAngle)) * orbitR
                let py = cy + CGFloat(sin(baseAngle)) * orbitR * 0.88
                let pulse = animated ? (0.75 + 0.25 * sin(t * 4.0 + Double(idx))) * Double(ampScale) : 0.9
                let r = size * (idx % 2 == 0 ? 0.036 : 0.025) * CGFloat(0.75 + 0.25 * pulse)
                let star = PrincessVectorShapes.starPath(center: CGPoint(x: px, y: py), outerRadius: r, innerRadius: r * 0.42, points: 4)
                let col = idx % 2 == 0 ? Color(hex: "#FFD166") : auraColor
                context.fill(star, with: .color(col.opacity(0.92)))
            }
        } else if suitBonus.isHalfResonance || effectiveMaxStage >= 3 {
            // 3件小共鸣柔光圈 / 高阶单品光晕
            let glowR = size * 0.52
            let glowRect = CGRect(x: cx - glowR, y: cy - glowR, width: glowR * 2, height: glowR * 2)
            context.fill(
                Circle().path(in: glowRect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(hex: suitBonus.suit.secondaryHex).opacity(0.45),
                        auraColor.opacity(0.18),
                        Color.clear
                    ]),
                    center: center,
                    startRadius: size * 0.05,
                    endRadius: glowR
                )
            )

            if suitBonus.isHalfResonance {
                let ringR = size * 0.46
                let ringRect = CGRect(x: -ringR, y: -ringR, width: ringR * 2, height: ringR * 2)
                context.drawLayer { layer in
                    layer.translateBy(x: cx, y: cy)
                    layer.rotate(by: .degrees(auraSpin * 0.6))
                    layer.stroke(
                        Circle().path(in: ringRect),
                        with: .color(auraColor.opacity(0.48)),
                        style: StrokeStyle(lineWidth: 1.8, dash: [5, 5])
                    )
                }
            }
        }

        // Lv.5 传世神装专属九彩极光内阵
        if effectiveMaxStage >= 5 {
            let haloR = size * 0.52
            let haloRect = CGRect(x: -haloR, y: -haloR, width: haloR * 2, height: haloR * 2)
            context.drawLayer { layer in
                layer.opacity = 0.85
                layer.translateBy(x: cx, y: cy)
                layer.rotate(by: .degrees(-auraSpin * 0.9))
                layer.stroke(
                    Circle().path(in: haloRect),
                    with: .conicGradient(
                        Gradient(colors: [
                            Color(hex: "#FF595E"),
                            Color(hex: "#FFCA3A"),
                            Color(hex: "#8AC926"),
                            Color(hex: "#4CC9F0"),
                            Color(hex: "#9B6EF3"),
                            Color(hex: "#FF758F"),
                            Color(hex: "#FF595E")
                        ]),
                        center: .zero
                    ),
                    style: StrokeStyle(lineWidth: 2.2, dash: [4, 4])
                )
            }
        }
    }

    private var twirlSparkBurstLayer: some View {
        Canvas { context, canvasSize in
            let cx = canvasSize.width * 0.5
            let cy = canvasSize.height * 0.5
            let radius = canvasSize.width * 0.42 * twirlSparkScale
            for i in 0..<10 {
                let angle = Double(i) * (.pi * 2.0 / 10.0)
                let pt = CGPoint(x: cx + CGFloat(cos(angle)) * radius, y: cy + CGFloat(sin(angle)) * radius * 0.82)
                let star = PrincessVectorShapes.starPath(center: pt, outerRadius: size * 0.045, innerRadius: size * 0.018, points: 4)
                context.fill(star, with: .color(i % 2 == 0 ? Color(hex: "#FFD166") : Color(hex: dress.primaryHex)))
            }
        }
        .frame(width: size, height: size)
        .opacity(twirlSparkOpacity)
    }

    // MARK: - 0. 舞台投影与脚下星阵
    private func drawStagePedestal(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        auraSpin: Double,
        maxStage: Int,
        suitBonus: SuitBonusInfo
    ) {
        let shadow = Ellipse().path(in: CGRect(x: 42 * sx, y: 144 * sy, width: 76 * sx, height: 9 * sy))
        context.fill(shadow, with: .color(Color.black.opacity(0.14)))

        if maxStage >= 4 || suitBonus.isFullResonance {
            let ringRect = CGRect(x: 34 * sx, y: 139 * sy, width: 92 * sx, height: 15 * sy)
            let outer = Ellipse().path(in: ringRect)
            let ringCol = maxStage >= 5 ? Color(hex: "#FFD166") : Color(hex: suitBonus.suit.primaryHex)
            context.stroke(outer, with: .color(ringCol.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5 * sx, dash: [4 * sx, 3 * sx]))
            let inner = Ellipse().path(in: ringRect.insetBy(dx: 8 * sx, dy: 2.5 * sy))
            context.stroke(inner, with: .color(Color.white.opacity(0.65)), lineWidth: 1.0 * sx)
        }
    }

    // MARK: - 1. 梦幻背饰与神翼 (styleIndex 0..5 × wingsStage 1..5)
    private func drawBackWings(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat,
        flap: CGFloat,
        shimmerPos: CGFloat
    ) {
        let c1 = Color(hex: wings.primaryHex)
        let c2 = Color(hex: wings.secondaryHex)
        let acc = Color(hex: wings.accentHex)
        let stage = wingsStage
        let flapOffset = flap * 4.5

        switch wings.styleIndex {
        case 0:
            // 甜心粉绸大丝带结：背在腰后的大双环丝带+飘动长尾，绝非蝙蝠翼
            var leftTail = Path()
            leftTail.move(to: CGPoint(x: 72 * sx, y: (86 + dy) * sy))
            leftTail.addQuadCurve(to: CGPoint(x: (52 - flap * 2.5) * sx, y: (126 + dy) * sy), control: CGPoint(x: 56 * sx, y: (106 + dy) * sy))
            leftTail.addLine(to: CGPoint(x: (60 - flap * 2.0) * sx, y: (122 + dy) * sy))
            leftTail.addLine(to: CGPoint(x: (63 - flap * 2.0) * sx, y: (129 + dy) * sy))
            leftTail.addQuadCurve(to: CGPoint(x: 77 * sx, y: (88 + dy) * sy), control: CGPoint(x: 68 * sx, y: (106 + dy) * sy))
            leftTail.closeSubpath()

            var rightTail = Path()
            rightTail.move(to: CGPoint(x: 88 * sx, y: (86 + dy) * sy))
            rightTail.addQuadCurve(to: CGPoint(x: (108 + flap * 2.5) * sx, y: (126 + dy) * sy), control: CGPoint(x: 104 * sx, y: (106 + dy) * sy))
            rightTail.addLine(to: CGPoint(x: (100 + flap * 2.0) * sx, y: (122 + dy) * sy))
            rightTail.addLine(to: CGPoint(x: (97 + flap * 2.0) * sx, y: (129 + dy) * sy))
            rightTail.addQuadCurve(to: CGPoint(x: 83 * sx, y: (88 + dy) * sy), control: CGPoint(x: 92 * sx, y: (106 + dy) * sy))
            rightTail.closeSubpath()

            context.fill(leftTail, with: .linearGradient(Gradient(colors: [c1, c2]), startPoint: CGPoint(x: 55 * sx, y: 85 * sy), endPoint: CGPoint(x: 55 * sx, y: 128 * sy)))
            context.fill(rightTail, with: .linearGradient(Gradient(colors: [c1, c2]), startPoint: CGPoint(x: 105 * sx, y: 85 * sy), endPoint: CGPoint(x: 105 * sx, y: 128 * sy)))

            let scaleW: CGFloat = 1.0 + CGFloat(stage - 1) * 0.08
            let bowP = PrincessVectorShapes.bowPath(center: CGPoint(x: 80 * sx, y: (81 + dy) * sy), width: 64 * scaleW * sx, height: 26 * scaleW * sy)
            context.fill(bowP, with: .linearGradient(Gradient(colors: [c1, c2, c1]), startPoint: CGPoint(x: 48 * sx, y: 68 * sy), endPoint: CGPoint(x: 112 * sx, y: 94 * sy)))
            context.stroke(bowP, with: .color(stage >= 4 ? Color(hex: "#FFD166") : acc.opacity(0.75)), lineWidth: (1.4 + CGFloat(stage) * 0.22) * sx)
            if stage >= 3 {
                PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 80 * sx, y: (81 + dy) * sy), size: 7.5 * sx, color: acc, rimColor: Color(hex: "#FFD166"))
            }

        case 1:
            // 森系花仙子透明薄翼：两对叶脉透明仙翼
            drawMirroredWingPair(context: &context, sx: sx, sy: sy, dy: dy, flap: flapOffset, stage: stage) { isRight, ctx in
                let dir: CGFloat = isRight ? 1 : -1
                var up = Path()
                up.move(to: CGPoint(x: (80 + 10 * dir) * sx, y: (72 + dy) * sy))
                up.addCurve(
                    to: CGPoint(x: (80 + (58 + flapOffset) * dir) * sx, y: (44 + dy - flapOffset * 0.6) * sy),
                    control1: CGPoint(x: (80 + 26 * dir) * sx, y: (42 + dy) * sy),
                    control2: CGPoint(x: (80 + 48 * dir) * sx, y: (36 + dy) * sy)
                )
                up.addCurve(
                    to: CGPoint(x: (80 + 12 * dir) * sx, y: (82 + dy) * sy),
                    control1: CGPoint(x: (80 + (54 + flapOffset * 0.5) * dir) * sx, y: (74 + dy) * sy),
                    control2: CGPoint(x: (80 + 28 * dir) * sx, y: (84 + dy) * sy)
                )
                up.closeSubpath()

                ctx.fill(up, with: .linearGradient(Gradient(colors: [c2.opacity(0.78), c1.opacity(0.55)]), startPoint: CGPoint(x: 80 * sx, y: 74 * sy), endPoint: CGPoint(x: (80 + 55 * dir) * sx, y: 46 * sy)))
                ctx.stroke(up, with: .color(stage >= 4 ? Color(hex: "#FFD166") : c1.opacity(0.85)), lineWidth: (1.3 + CGFloat(stage) * 0.2) * sx)

                // 叶脉纹理
                for v in 1...3 {
                    var vein = Path()
                    vein.move(to: CGPoint(x: (80 + 13 * dir) * sx, y: (75 + dy) * sy))
                    vein.addQuadCurve(
                        to: CGPoint(x: (80 + CGFloat(30 + v * 7) * dir) * sx, y: (49 + CGFloat(v) * 6 + dy) * sy),
                        control: CGPoint(x: (80 + 25 * dir) * sx, y: (60 + dy) * sy)
                    )
                    ctx.stroke(vein, with: .color(Color.white.opacity(0.65)), lineWidth: 0.9 * sx)
                }

                if stage >= 2 {
                    var low = Path()
                    low.move(to: CGPoint(x: (80 + 11 * dir) * sx, y: (79 + dy) * sy))
                    low.addQuadCurve(to: CGPoint(x: (80 + (42 + flapOffset * 0.4) * dir) * sx, y: (106 + dy) * sy), control: CGPoint(x: (80 + 48 * dir) * sx, y: (86 + dy) * sy))
                    low.addQuadCurve(to: CGPoint(x: (80 + 11 * dir) * sx, y: (88 + dy) * sy), control: CGPoint(x: (80 + 26 * dir) * sx, y: (104 + dy) * sy))
                    low.closeSubpath()
                    ctx.fill(low, with: .color(c2.opacity(0.62)))
                    ctx.stroke(low, with: .color(stage >= 4 ? Color(hex: "#FFD166") : c1.opacity(0.75)), lineWidth: 1.1 * sx)
                }
                if stage >= 3 {
                    PrincessVectorShapes.drawGem(in: &ctx, center: CGPoint(x: (80 + 45 * dir) * sx, y: (55 + dy) * sy), size: 4.5 * sx, color: acc, rimColor: .white)
                }
            }

        case 2:
            // 纯白雪绒白天鹅羽翼：三层层叠蓬松鹅羽
            drawMirroredWingPair(context: &context, sx: sx, sy: sy, dy: dy, flap: flapOffset, stage: stage) { isRight, ctx in
                let dir: CGFloat = isRight ? 1 : -1
                let tierCount = stage >= 4 ? 4 : (stage >= 2 ? 3 : 2)
                for layer in 0..<tierCount {
                    let spread = CGFloat(layer) * 7.5
                    let tipX = (80 + (54 + flapOffset - spread * 0.5) * dir) * sx
                    let tipY = (44 + spread * 1.45 + dy - flapOffset * 0.5) * sy
                    var plume = Path()
                    plume.move(to: CGPoint(x: (80 + 12 * dir) * sx, y: (70 + CGFloat(layer) * 4 + dy) * sy))
                    plume.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: CGPoint(x: (80 + 36 * dir) * sx, y: (36 + spread + dy) * sy))
                    plume.addQuadCurve(to: CGPoint(x: (80 + (38 - spread * 0.3) * dir) * sx, y: (75 + spread * 1.2 + dy) * sy), control: CGPoint(x: (80 + 54 * dir) * sx, y: (62 + spread + dy) * sy))
                    plume.addQuadCurve(to: CGPoint(x: (80 + 12 * dir) * sx, y: (80 + CGFloat(layer) * 4 + dy) * sy), control: CGPoint(x: (80 + 25 * dir) * sx, y: (82 + spread + dy) * sy))
                    plume.closeSubpath()

                    let col = layer % 2 == 0 ? c2 : c1.opacity(0.65)
                    ctx.fill(plume, with: .linearGradient(Gradient(colors: [.white, col]), startPoint: CGPoint(x: 80 * sx, y: 65 * sy), endPoint: CGPoint(x: tipX, y: tipY)))
                    ctx.stroke(plume, with: .color(stage >= 4 ? Color(hex: "#FFD166") : c1.opacity(0.85)), lineWidth: 1.2 * sx)
                }
                if stage >= 3 {
                    PrincessVectorShapes.drawGem(in: &ctx, center: CGPoint(x: (80 + 28 * dir) * sx, y: (64 + dy) * sy), size: 5.0 * sx, color: c1, rimColor: acc)
                }
            }

        case 3:
            // 幻彩琉璃嵌金翼：彩色玻璃镶嵌扇形仙翼
            drawMirroredWingPair(context: &context, sx: sx, sy: sy, dy: dy, flap: flapOffset, stage: stage) { isRight, ctx in
                let dir: CGFloat = isRight ? 1 : -1
                var top = Path()
                top.move(to: CGPoint(x: (80 + 10 * dir) * sx, y: (72 + dy) * sy))
                top.addCurve(
                    to: CGPoint(x: (80 + (62 + flapOffset) * dir) * sx, y: (38 + dy - flapOffset * 0.7) * sy),
                    control1: CGPoint(x: (80 + 22 * dir) * sx, y: (36 + dy) * sy),
                    control2: CGPoint(x: (80 + 50 * dir) * sx, y: (26 + dy) * sy)
                )
                top.addCurve(
                    to: CGPoint(x: (80 + 13 * dir) * sx, y: (83 + dy) * sy),
                    control1: CGPoint(x: (80 + (60 + flapOffset * 0.4) * dir) * sx, y: (74 + dy) * sy),
                    control2: CGPoint(x: (80 + 34 * dir) * sx, y: (83 + dy) * sy)
                )
                top.closeSubpath()

                ctx.fill(top, with: .linearGradient(Gradient(colors: [c1.opacity(0.88), c2.opacity(0.82), acc.opacity(0.75)]), startPoint: CGPoint(x: 80 * sx, y: 74 * sy), endPoint: CGPoint(x: (80 + 62 * dir) * sx, y: 38 * sy)))
                ctx.stroke(top, with: .color(stage >= 3 ? Color(hex: "#FFD166") : Color.white.opacity(0.85)), lineWidth: (1.6 + CGFloat(stage) * 0.25) * sx)

                // 琉璃彩窗几何分格线
                var rib = Path()
                rib.move(to: CGPoint(x: (80 + 14 * dir) * sx, y: (75 + dy) * sy))
                rib.addLine(to: CGPoint(x: (80 + 52 * dir) * sx, y: (52 + dy) * sy))
                rib.move(to: CGPoint(x: (80 + 30 * dir) * sx, y: (64 + dy) * sy))
                rib.addLine(to: CGPoint(x: (80 + 44 * dir) * sx, y: (42 + dy) * sy))
                ctx.stroke(rib, with: .color(Color(hex: "#FFD166").opacity(0.78)), lineWidth: 1.1 * sx)

                var low = Path()
                low.move(to: CGPoint(x: (80 + 12 * dir) * sx, y: (82 + dy) * sy))
                low.addQuadCurve(to: CGPoint(x: (80 + (48 + flapOffset * 0.4) * dir) * sx, y: (108 + dy) * sy), control: CGPoint(x: (80 + 54 * dir) * sx, y: (88 + dy) * sy))
                low.addQuadCurve(to: CGPoint(x: (80 + 13 * dir) * sx, y: (92 + dy) * sy), control: CGPoint(x: (80 + 28 * dir) * sx, y: (112 + dy) * sy))
                low.closeSubpath()
                ctx.fill(low, with: .linearGradient(Gradient(colors: [c2.opacity(0.85), c1.opacity(0.75)]), startPoint: CGPoint(x: 80 * sx, y: 85 * sy), endPoint: CGPoint(x: (80 + 48 * dir) * sx, y: 108 * sy)))
                ctx.stroke(low, with: .color(stage >= 3 ? Color(hex: "#FFD166") : .white.opacity(0.8)), lineWidth: 1.4 * sx)

                if stage >= 3 {
                    PrincessVectorShapes.drawGem(in: &ctx, center: CGPoint(x: (80 + 46 * dir) * sx, y: (49 + dy) * sy), size: 5.5 * sx, color: acc, rimColor: .white)
                }
            }

        case 4:
            // 星辰霓虹飞马天翼：流线星羽 + 流星尾迹
            drawMirroredWingPair(context: &context, sx: sx, sy: sy, dy: dy, flap: flapOffset, stage: stage) { isRight, ctx in
                let dir: CGFloat = isRight ? 1 : -1
                for pIdx in 0..<3 {
                    let yOff = CGFloat(pIdx) * 9.0
                    let xReach = 62.0 - CGFloat(pIdx) * 9.0 + flapOffset * 0.6
                    var feather = Path()
                    feather.move(to: CGPoint(x: (80 + 11 * dir) * sx, y: (68 + yOff * 0.4 + dy) * sy))
                    feather.addQuadCurve(to: CGPoint(x: (80 + xReach * dir) * sx, y: (36 + yOff + dy - flapOffset * 0.5) * sy), control: CGPoint(x: (80 + 36 * dir) * sx, y: (34 + yOff * 0.6 + dy) * sy))
                    feather.addQuadCurve(to: CGPoint(x: (80 + 13 * dir) * sx, y: (79 + yOff * 0.5 + dy) * sy), control: CGPoint(x: (80 + (xReach - 14) * dir) * sx, y: (68 + yOff + dy) * sy))
                    feather.closeSubpath()

                    ctx.fill(feather, with: .linearGradient(Gradient(colors: [c1, c2, acc]), startPoint: CGPoint(x: 80 * sx, y: 72 * sy), endPoint: CGPoint(x: (80 + xReach * dir) * sx, y: 40 * sy)))
                    ctx.stroke(feather, with: .color(stage >= 4 ? Color(hex: "#FFD166") : acc.opacity(0.85)), lineWidth: 1.3 * sx)
                }
                if stage >= 3 {
                    let star = PrincessVectorShapes.starPath(center: CGPoint(x: (80 + 46 * dir) * sx, y: (47 + dy) * sy), outerRadius: 4.5 * sx, innerRadius: 1.8 * sx, points: 4)
                    ctx.fill(star, with: .color(Color.white))
                }
            }

        default:
            // 5: 九天流金神凰圣翼（六翼流金火焰羽）
            drawMirroredWingPair(context: &context, sx: sx, sy: sy, dy: dy, flap: flapOffset, stage: stage) { isRight, ctx in
                let dir: CGFloat = isRight ? 1 : -1
                let pairs = stage >= 4 ? 3 : (stage >= 2 ? 2 : 1)
                for p in 0..<pairs {
                    let angleShift = CGFloat(p) * 14.0
                    let reach = (66.0 - CGFloat(p) * 6.0) + flapOffset * 0.6
                    var flameWing = Path()
                    flameWing.move(to: CGPoint(x: (80 + 10 * dir) * sx, y: (70 + CGFloat(p) * 5 + dy) * sy))
                    flameWing.addCurve(
                        to: CGPoint(x: (80 + reach * dir) * sx, y: (33 + angleShift + dy - flapOffset * 0.5) * sy),
                        control1: CGPoint(x: (80 + 28 * dir) * sx, y: (34 + angleShift * 0.4 + dy) * sy),
                        control2: CGPoint(x: (80 + (reach - 10) * dir) * sx, y: (28 + angleShift * 0.6 + dy) * sy)
                    )
                    flameWing.addQuadCurve(
                        to: CGPoint(x: (80 + (reach - 14) * dir) * sx, y: (62 + angleShift + dy) * sy),
                        control: CGPoint(x: (80 + (reach + 3) * dir) * sx, y: (50 + angleShift + dy) * sy)
                    )
                    flameWing.addQuadCurve(
                        to: CGPoint(x: (80 + 12 * dir) * sx, y: (82 + CGFloat(p) * 5 + dy) * sy),
                        control: CGPoint(x: (80 + 34 * dir) * sx, y: (74 + angleShift + dy) * sy)
                    )
                    flameWing.closeSubpath()

                    ctx.fill(flameWing, with: .linearGradient(Gradient(colors: [c2, c1, acc]), startPoint: CGPoint(x: 80 * sx, y: 74 * sy), endPoint: CGPoint(x: (80 + reach * dir) * sx, y: 36 * sy)))
                    ctx.stroke(flameWing, with: .color(Color(hex: "#FFD166")), lineWidth: (1.4 + CGFloat(stage) * 0.22) * sx)
                }
                if stage >= 3 {
                    PrincessVectorShapes.drawGem(in: &ctx, center: CGPoint(x: (80 + 44 * dir) * sx, y: (46 + dy) * sy), size: 5.5 * sx, color: acc, rimColor: Color(hex: "#FFD166"))
                }
            }
        }

        // Lv.5 背翼虹彩扫光星尘
        if stage >= 5 && wings.styleIndex > 0 {
            let sweepX = (30 + shimmerPos * 100) * sx
            let sparkle1 = PrincessVectorShapes.starPath(center: CGPoint(x: min(140 * sx, max(20 * sx, sweepX)), y: (46 + dy) * sy), outerRadius: 4.5 * sx, innerRadius: 1.8 * sx, points: 4)
            let sparkle2 = PrincessVectorShapes.starPath(center: CGPoint(x: min(140 * sx, max(20 * sx, 160 * sx - sweepX)), y: (56 + dy) * sy), outerRadius: 3.6 * sx, innerRadius: 1.5 * sx, points: 4)
            context.fill(sparkle1, with: .color(Color.white.opacity(0.95)))
            context.fill(sparkle2, with: .color(Color(hex: "#FFD166").opacity(0.95)))
        }
    }

    private func drawMirroredWingPair(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat,
        flap: CGFloat,
        stage: Int,
        drawer: (Bool, inout GraphicsContext) -> Void
    ) {
        drawer(false, &context)
        drawer(true, &context)
    }

    // MARK: - 2. 层次公主长卷发/编发/礼髻后景
    private func drawBackHair(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat,
        sway: CGFloat
    ) {
        let baseC = Color(hex: hairColor.primaryHex)
        let hiC = Color(hex: hairColor.highlightHex)
        let shC = Color(hex: hairColor.shadowHex)
        let swayX = sway * 3.0

        switch hairTiara.styleIndex {
        case 0:
            // 元气双马尾：两侧翘起的丰盈卷曲马尾
            for isRight in [false, true] {
                let dir: CGFloat = isRight ? 1 : -1
                var tail = Path()
                tail.move(to: CGPoint(x: (80 + 23 * dir) * sx, y: (34 + dy) * sy))
                tail.addCurve(
                    to: CGPoint(x: (80 + 42 * dir + swayX) * sx, y: (74 + dy) * sy),
                    control1: CGPoint(x: (80 + 44 * dir) * sx, y: (32 + dy) * sy),
                    control2: CGPoint(x: (80 + 48 * dir + swayX) * sx, y: (56 + dy) * sy)
                )
                tail.addCurve(
                    to: CGPoint(x: (80 + 25 * dir) * sx, y: (56 + dy) * sy),
                    control1: CGPoint(x: (80 + 34 * dir + swayX) * sx, y: (80 + dy) * sy),
                    control2: CGPoint(x: (80 + 28 * dir) * sx, y: (68 + dy) * sy)
                )
                tail.closeSubpath()
                context.fill(tail, with: .linearGradient(Gradient(colors: [hiC, baseC, shC]), startPoint: CGPoint(x: 80 * sx, y: 32 * sy), endPoint: CGPoint(x: 80 * sx, y: 78 * sy)))
                context.stroke(tail, with: .color(shC.opacity(0.65)), lineWidth: 1.2 * sx)
            }

        case 1:
            // 披肩柔顺内扣卷发
            var hair = Path()
            hair.move(to: CGPoint(x: 54 * sx, y: (30 + dy) * sy))
            hair.addCurve(to: CGPoint(x: (44 + swayX * 0.6) * sx, y: (72 + dy) * sy), control1: CGPoint(x: 42 * sx, y: (44 + dy) * sy), control2: CGPoint(x: 40 * sx, y: (62 + dy) * sy))
            hair.addQuadCurve(to: CGPoint(x: (116 + swayX * 0.6) * sx, y: (72 + dy) * sy), control: CGPoint(x: 80 * sx, y: (78 + dy) * sy))
            hair.addCurve(to: CGPoint(x: 106 * sx, y: (30 + dy) * sy), control1: CGPoint(x: 120 * sx, y: (62 + dy) * sy), control2: CGPoint(x: 118 * sx, y: (44 + dy) * sy))
            hair.closeSubpath()
            context.fill(hair, with: .linearGradient(Gradient(colors: [baseC, shC]), startPoint: CGPoint(x: 80 * sx, y: 28 * sy), endPoint: CGPoint(x: 80 * sx, y: 76 * sy)))

        case 2, 3:
            // 编发花环 / 公主半扎长卷发（垂肩大波浪）
            var back = Path()
            back.move(to: CGPoint(x: 52 * sx, y: (28 + dy) * sy))
            back.addCurve(to: CGPoint(x: (42 + swayX) * sx, y: (92 + dy) * sy), control1: CGPoint(x: 40 * sx, y: (50 + dy) * sy), control2: CGPoint(x: 38 * sx, y: (72 + dy) * sy))
            back.addQuadCurve(to: CGPoint(x: (118 + swayX) * sx, y: (92 + dy) * sy), control: CGPoint(x: 80 * sx, y: (100 + dy) * sy))
            back.addCurve(to: CGPoint(x: 108 * sx, y: (28 + dy) * sy), control1: CGPoint(x: 122 * sx, y: (72 + dy) * sy), control2: CGPoint(x: 120 * sx, y: (50 + dy) * sy))
            back.closeSubpath()
            context.fill(back, with: .linearGradient(Gradient(colors: [baseC, shC]), startPoint: CGPoint(x: 80 * sx, y: 28 * sy), endPoint: CGPoint(x: 80 * sx, y: 98 * sy)))

            // 编发纹理细节
            if hairTiara.styleIndex == 2 {
                for b in 0..<4 {
                    let by = (56.0 + Double(b) * 8.0) + Double(dy)
                    let plaitL = Ellipse().path(in: CGRect(x: 48 * sx, y: CGFloat(by) * sy, width: 7 * sx, height: 7.5 * sy))
                    let plaitR = Ellipse().path(in: CGRect(x: 105 * sx, y: CGFloat(by) * sy, width: 7 * sx, height: 7.5 * sy))
                    context.fill(plaitL, with: .color(hiC.opacity(0.65)))
                    context.fill(plaitR, with: .color(hiC.opacity(0.65)))
                }
            }

        case 4:
            // 及腰波浪星空长发
            var waveHair = Path()
            waveHair.move(to: CGPoint(x: 52 * sx, y: (28 + dy) * sy))
            waveHair.addCurve(to: CGPoint(x: (40 + swayX) * sx, y: (110 + dy) * sy), control1: CGPoint(x: 36 * sx, y: (56 + dy) * sy), control2: CGPoint(x: 35 * sx, y: (86 + dy) * sy))
            waveHair.addQuadCurve(to: CGPoint(x: (120 + swayX) * sx, y: (110 + dy) * sy), control: CGPoint(x: 80 * sx, y: (120 + dy) * sy))
            waveHair.addCurve(to: CGPoint(x: 108 * sx, y: (28 + dy) * sy), control1: CGPoint(x: 125 * sx, y: (86 + dy) * sy), control2: CGPoint(x: 124 * sx, y: (56 + dy) * sy))
            waveHair.closeSubpath()
            context.fill(waveHair, with: .linearGradient(Gradient(colors: [baseC, shC]), startPoint: CGPoint(x: 80 * sx, y: 28 * sy), endPoint: CGPoint(x: 80 * sx, y: 118 * sy)))

        default:
            // 5: 皇室高贵盘发礼髻 + 垂耳小卷发
            let bun = Circle().path(in: CGRect(x: 66 * sx, y: (8 + dy) * sy, width: 28 * sx, height: 22 * sy))
            context.fill(bun, with: .linearGradient(Gradient(colors: [hiC, baseC]), startPoint: CGPoint(x: 72 * sx, y: 8 * sy), endPoint: CGPoint(x: 88 * sx, y: 28 * sy)))
            context.stroke(bun, with: .color(shC.opacity(0.55)), lineWidth: 1.2 * sx)

            for isRight in [false, true] {
                let dir: CGFloat = isRight ? 1 : -1
                var lock = Path()
                lock.move(to: CGPoint(x: (80 + 21 * dir) * sx, y: (38 + dy) * sy))
                lock.addQuadCurve(to: CGPoint(x: (80 + 27 * dir) * sx, y: (64 + dy) * sy), control: CGPoint(x: (80 + 31 * dir) * sx, y: (50 + dy) * sy))
                lock.addQuadCurve(to: CGPoint(x: (80 + 18 * dir) * sx, y: (58 + dy) * sy), control: CGPoint(x: (80 + 21 * dir) * sx, y: (64 + dy) * sy))
                lock.closeSubpath()
                context.fill(lock, with: .color(baseC))
            }
        }
    }

    // MARK: - 3. 小公主双腿与鞋子
    private func drawLegsAndShoes(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat
    ) {
        let skin = Color(hex: "#FFE6D8")
        let shoeColor = Color(hex: dress.primaryHex)

        if pose.id == "leap" {
            // 芭蕾轻盈跃起：左腿伸展，右膝轻弯
            var legL = Path()
            legL.move(to: CGPoint(x: 72 * sx, y: (122 + dy) * sy))
            legL.addLine(to: CGPoint(x: 65 * sx, y: (143 + dy) * sy))
            context.stroke(legL, with: .color(skin), style: StrokeStyle(lineWidth: 6.2 * sx, lineCap: .round))

            var legR = Path()
            legR.move(to: CGPoint(x: 88 * sx, y: (122 + dy) * sy))
            legR.addLine(to: CGPoint(x: 96 * sx, y: (133 + dy) * sy))
            legR.addLine(to: CGPoint(x: 89 * sx, y: (141 + dy) * sy))
            context.stroke(legR, with: .color(skin), style: StrokeStyle(lineWidth: 6.2 * sx, lineCap: .round, lineJoin: .round))

            let shoeL = Ellipse().path(in: CGRect(x: 59 * sx, y: (140 + dy) * sy, width: 10 * sx, height: 6.5 * sy))
            let shoeR = Ellipse().path(in: CGRect(x: 84 * sx, y: (138 + dy) * sy, width: 10 * sx, height: 6.5 * sy))
            context.fill(shoeL, with: .color(shoeColor))
            context.fill(shoeR, with: .color(shoeColor))
        } else {
            let legL = RoundedRectangle(cornerRadius: 3 * sx).path(in: CGRect(x: 69 * sx, y: (123 + dy) * sy, width: 6.2 * sx, height: 21 * sy))
            let legR = RoundedRectangle(cornerRadius: 3 * sx).path(in: CGRect(x: 84.8 * sx, y: (123 + dy) * sy, width: 6.2 * sx, height: 21 * sy))
            context.fill(legL, with: .color(skin))
            context.fill(legR, with: .color(skin))

            let shoeL = RoundedRectangle(cornerRadius: 4 * sx).path(in: CGRect(x: 66.5 * sx, y: (141 + dy) * sy, width: 10.5 * sx, height: 6.5 * sy))
            let shoeR = RoundedRectangle(cornerRadius: 4 * sx).path(in: CGRect(x: 83 * sx, y: (141 + dy) * sy, width: 10.5 * sx, height: 6.5 * sy))
            context.fill(shoeL, with: .color(shoeColor))
            context.fill(shoeR, with: .color(shoeColor))
            context.stroke(shoeL, with: .color(Color(hex: "#FFD166")), lineWidth: 1.0 * sx)
            context.stroke(shoeR, with: .color(Color(hex: "#FFD166")), lineWidth: 1.0 * sx)
        }
    }

    // MARK: - 4. 高定礼服裙装 (6 大设计 × 5 阶细节进化)
    private func drawDress(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat,
        sway: CGFloat,
        skirtLiftL: CGFloat,
        shimmerPos: CGFloat,
        flare: Bool
    ) {
        let c1 = Color(hex: dress.primaryHex)
        let c2 = Color(hex: dress.secondaryHex)
        let acc = Color(hex: dress.accentHex)
        let stage = dressStage
        let flareBonus: CGFloat = flare ? 6.0 : 0.0
        let swayX = sway * 2.5

        let skirtWidthBonus: CGFloat = CGFloat(stage - 1) * 3.0 + flareBonus
        let skirtBottomY: CGFloat = dress.styleIndex >= 3 ? (138 + dy) : (132 + dy)

        // (1) 后层拖尾薄纱 (Lv.4+ 或冰雪长裙/星河裙专属)
        if stage >= 4 || dress.styleIndex == 3 || dress.styleIndex == 4 {
            var train = Path()
            train.move(to: CGPoint(x: 64 * sx, y: (81 + dy) * sy))
            train.addQuadCurve(
                to: CGPoint(x: (28 - skirtWidthBonus * 0.7 + swayX) * sx, y: (skirtBottomY + 4) * sy),
                control: CGPoint(x: (34 - skirtWidthBonus * 0.4) * sx, y: (110 + dy) * sy)
            )
            train.addQuadCurve(
                to: CGPoint(x: (132 + skirtWidthBonus * 0.7 + swayX) * sx, y: (skirtBottomY + 4) * sy),
                control: CGPoint(x: 80 * sx, y: (skirtBottomY + 12) * sy)
            )
            train.addQuadCurve(
                to: CGPoint(x: 96 * sx, y: (81 + dy) * sy),
                control: CGPoint(x: (126 + skirtWidthBonus * 0.4) * sx, y: (110 + dy) * sy)
            )
            train.closeSubpath()
            context.fill(train, with: .linearGradient(Gradient(colors: [c2.opacity(0.65), c1.opacity(0.45)]), startPoint: CGPoint(x: 80 * sx, y: 82 * sy), endPoint: CGPoint(x: 80 * sx, y: (skirtBottomY + 6) * sy)))
        }

        // (2) 主外裙轮廓（6 种裙型差异）
        let leftEdgeX = (36.0 - skirtWidthBonus + swayX) * sx
        let rightEdgeX = (124.0 + skirtWidthBonus + swayX) * sx
        var outerSkirt = Path()
        outerSkirt.move(to: CGPoint(x: 66 * sx, y: (80 + dy) * sy))

        switch dress.styleIndex {
        case 2:
            // 樱花五瓣花叠层裙摆：左起波浪花瓣弧
            outerSkirt.addQuadCurve(to: CGPoint(x: leftEdgeX, y: (skirtBottomY + skirtLiftL) * sy), control: CGPoint(x: (42 - skirtWidthBonus * 0.5) * sx, y: (102 + dy) * sy))
            let segments = 5
            let stepW = (rightEdgeX - leftEdgeX) / CGFloat(segments)
            for s in 0..<segments {
                let xStart = leftEdgeX + CGFloat(s) * stepW
                let xEnd = xStart + stepW
                let xMid = (xStart + xEnd) * 0.5
                outerSkirt.addQuadCurve(to: CGPoint(x: xEnd, y: skirtBottomY * sy), control: CGPoint(x: xMid, y: (skirtBottomY + 9) * sy))
            }
            outerSkirt.addQuadCurve(to: CGPoint(x: 94 * sx, y: (80 + dy) * sy), control: CGPoint(x: (118 + skirtWidthBonus * 0.5) * sx, y: (102 + dy) * sy))

        case 4:
            // 星空前短后长不规则渐变大摆裙
            outerSkirt.addQuadCurve(to: CGPoint(x: leftEdgeX, y: (123 + dy + skirtLiftL) * sy), control: CGPoint(x: 42 * sx, y: (100 + dy) * sy))
            outerSkirt.addCurve(
                to: CGPoint(x: rightEdgeX, y: (139 + dy) * sy),
                control1: CGPoint(x: 62 * sx, y: (119 + dy) * sy),
                control2: CGPoint(x: 96 * sx, y: (146 + dy) * sy)
            )
            outerSkirt.addQuadCurve(to: CGPoint(x: 94 * sx, y: (80 + dy) * sy), control: CGPoint(x: 122 * sx, y: (104 + dy) * sy))

        case 5:
            // 皇室宫廷织锦大撑裙（两侧圆鼓撑裙轮廓）
            outerSkirt.addCurve(
                to: CGPoint(x: (30 - skirtWidthBonus) * sx, y: (136 + dy + skirtLiftL) * sy),
                control1: CGPoint(x: (34 - skirtWidthBonus * 0.6) * sx, y: (82 + dy) * sy),
                control2: CGPoint(x: (28 - skirtWidthBonus * 0.8) * sx, y: (114 + dy) * sy)
            )
            outerSkirt.addQuadCurve(to: CGPoint(x: (130 + skirtWidthBonus) * sx, y: (136 + dy) * sy), control: CGPoint(x: 80 * sx, y: (144 + dy) * sy))
            outerSkirt.addCurve(
                to: CGPoint(x: 94 * sx, y: (80 + dy) * sy),
                control1: CGPoint(x: (132 + skirtWidthBonus * 0.8) * sx, y: (114 + dy) * sy),
                control2: CGPoint(x: (126 + skirtWidthBonus * 0.6) * sx, y: (82 + dy) * sy)
            )

        default:
            // 经典蓬蓬 / 厨娘 / 冰雪曳地轮廓
            outerSkirt.addQuadCurve(
                to: CGPoint(x: leftEdgeX, y: (skirtBottomY + skirtLiftL) * sy),
                control: CGPoint(x: (42 - skirtWidthBonus * 0.5) * sx, y: (102 + dy) * sy)
            )
            outerSkirt.addQuadCurve(
                to: CGPoint(x: rightEdgeX, y: skirtBottomY * sy),
                control: CGPoint(x: 80 * sx, y: (skirtBottomY + 10) * sy)
            )
            outerSkirt.addQuadCurve(
                to: CGPoint(x: 94 * sx, y: (80 + dy) * sy),
                control: CGPoint(x: (118 + skirtWidthBonus * 0.5) * sx, y: (102 + dy) * sy)
            )
        }
        outerSkirt.closeSubpath()

        context.fill(outerSkirt, with: .linearGradient(Gradient(colors: [c1, c2.opacity(0.95), c1]), startPoint: CGPoint(x: 55 * sx, y: 80 * sy), endPoint: CGPoint(x: 105 * sx, y: skirtBottomY * sy)))

        // (3) 裙摆风格专属细节
        switch dress.styleIndex {
        case 0:
            // 草莓厨娘波点白色荷叶围裙
            var apron = Path()
            apron.move(to: CGPoint(x: 68 * sx, y: (82 + dy) * sy))
            apron.addQuadCurve(to: CGPoint(x: 58 * sx, y: (122 + dy) * sy), control: CGPoint(x: 60 * sx, y: (104 + dy) * sy))
            apron.addQuadCurve(to: CGPoint(x: 102 * sx, y: (122 + dy) * sy), control: CGPoint(x: 80 * sx, y: (128 + dy) * sy))
            apron.addQuadCurve(to: CGPoint(x: 92 * sx, y: (82 + dy) * sy), control: CGPoint(x: 100 * sx, y: (104 + dy) * sy))
            apron.closeSubpath()
            context.fill(apron, with: .color(Color.white.opacity(0.94)))
            context.stroke(apron, with: .color(c1.opacity(0.7)), lineWidth: 1.2 * sx)
            // 围裙波点草莓点缀
            let dots: [(CGFloat, CGFloat)] = [(72, 98), (88, 98), (68, 113), (80, 108), (92, 113)]
            for pt in dots {
                let d = Circle().path(in: CGRect(x: (pt.0 - 2.1) * sx, y: (pt.1 + dy - 2.1) * sy, width: 4.2 * sx, height: 4.2 * sy))
                context.fill(d, with: .color(acc.opacity(0.85)))
            }

        case 1:
            // 薄荷马卡龙双层糖霜蓬蓬纱
            var tier1 = Path()
            tier1.move(to: CGPoint(x: 66 * sx, y: (81 + dy) * sy))
            tier1.addQuadCurve(to: CGPoint(x: 47 * sx, y: (110 + dy) * sy), control: CGPoint(x: 52 * sx, y: (96 + dy) * sy))
            tier1.addQuadCurve(to: CGPoint(x: 113 * sx, y: (110 + dy) * sy), control: CGPoint(x: 80 * sx, y: (119 + dy) * sy))
            tier1.addQuadCurve(to: CGPoint(x: 94 * sx, y: (81 + dy) * sy), control: CGPoint(x: 108 * sx, y: (96 + dy) * sy))
            tier1.closeSubpath()
            context.fill(tier1, with: .color(c2.opacity(0.90)))
            context.stroke(tier1, with: .color(.white), lineWidth: 1.4 * sx)

        case 2:
            // 樱花透明花瓣中层叠纱
            var petalLayer = Path()
            petalLayer.move(to: CGPoint(x: 67 * sx, y: (82 + dy) * sy))
            petalLayer.addQuadCurve(to: CGPoint(x: 51 * sx, y: (115 + dy) * sy), control: CGPoint(x: 54 * sx, y: (98 + dy) * sy))
            petalLayer.addQuadCurve(to: CGPoint(x: 80 * sx, y: (122 + dy) * sy), control: CGPoint(x: 65 * sx, y: (125 + dy) * sy))
            petalLayer.addQuadCurve(to: CGPoint(x: 109 * sx, y: (115 + dy) * sy), control: CGPoint(x: 95 * sx, y: (125 + dy) * sy))
            petalLayer.addQuadCurve(to: CGPoint(x: 93 * sx, y: (82 + dy) * sy), control: CGPoint(x: 106 * sx, y: (98 + dy) * sy))
            petalLayer.closeSubpath()
            context.fill(petalLayer, with: .color(c2.opacity(0.72)))

        case 3:
            // 冰雪水晶中分雪花薄纱 + 肩部飘纱披肩
            var splitPanel = Path()
            splitPanel.move(to: CGPoint(x: 75 * sx, y: (84 + dy) * sy))
            splitPanel.addQuadCurve(to: CGPoint(x: 61 * sx, y: (138 + dy) * sy), control: CGPoint(x: 68 * sx, y: (112 + dy) * sy))
            splitPanel.addLine(to: CGPoint(x: 99 * sx, y: (138 + dy) * sy))
            splitPanel.addQuadCurve(to: CGPoint(x: 85 * sx, y: (84 + dy) * sy), control: CGPoint(x: 92 * sx, y: (112 + dy) * sy))
            splitPanel.closeSubpath()
            context.fill(splitPanel, with: .color(Color.white.opacity(0.55)))
            let snowStar = PrincessVectorShapes.starPath(center: CGPoint(x: 80 * sx, y: (118 + dy) * sy), outerRadius: 6 * sx, innerRadius: 2.2 * sx, points: 6)
            context.fill(snowStar, with: .color(.white.opacity(0.9)))

        case 4:
            // 星河星座连线与四芒星群
            let constellation: [CGPoint] = [
                CGPoint(x: 63 * sx, y: (102 + dy) * sy),
                CGPoint(x: 82 * sx, y: (110 + dy) * sy),
                CGPoint(x: 97 * sx, y: (100 + dy) * sy),
                CGPoint(x: 106 * sx, y: (122 + dy) * sy)
            ]
            var line = Path()
            line.move(to: constellation[0])
            for pt in constellation.dropFirst() { line.addLine(to: pt) }
            context.stroke(line, with: .color(acc.opacity(0.72)), style: StrokeStyle(lineWidth: 0.9 * sx, dash: [2 * sx, 2 * sx]))
            for pt in constellation {
                let st = PrincessVectorShapes.starPath(center: pt, outerRadius: 3.6 * sx, innerRadius: 1.4 * sx, points: 4)
                context.fill(st, with: .color(acc))
            }

        default:
            // 5: 宫廷分片织锦中裙
            var brocade = Path()
            brocade.move(to: CGPoint(x: 75 * sx, y: (83 + dy) * sy))
            brocade.addQuadCurve(to: CGPoint(x: 63 * sx, y: (138 + dy) * sy), control: CGPoint(x: 68 * sx, y: (112 + dy) * sy))
            brocade.addQuadCurve(to: CGPoint(x: 97 * sx, y: (138 + dy) * sy), control: CGPoint(x: 80 * sx, y: (143 + dy) * sy))
            brocade.addQuadCurve(to: CGPoint(x: 85 * sx, y: (83 + dy) * sy), control: CGPoint(x: 92 * sx, y: (112 + dy) * sy))
            brocade.closeSubpath()
            context.fill(brocade, with: .color(c2.opacity(0.92)))
            context.stroke(brocade, with: .color(Color(hex: "#FFD166")), lineWidth: 1.4 * sx)
        }

        // (4) Lv.2+ 蕾丝花边裙脚
        if stage >= 2 {
            let laceCount = 9
            let span = rightEdgeX - leftEdgeX
            let r = (span / CGFloat(laceCount)) * 0.55
            for i in 0..<laceCount {
                let lx = leftEdgeX + (CGFloat(i) + 0.5) * (span / CGFloat(laceCount))
                let ly = (skirtBottomY - 1.5) * sy
                let lace = Circle().path(in: CGRect(x: lx - r, y: ly, width: r * 2, height: r * 1.4))
                context.fill(lace, with: .color(Color.white.opacity(0.88)))
            }
        }

        // (5) Lv.3+ 裙面宝石镶嵌
        if stage >= 3 {
            let gemPts: [(CGFloat, CGFloat)] = [(62, 102), (80, 96), (98, 102), (54, 121), (80, 118), (106, 121)]
            for pt in gemPts {
                PrincessVectorShapes.drawGem(
                    in: &context,
                    center: CGPoint(x: pt.0 * sx, y: (pt.1 + dy) * sy),
                    size: (stage >= 4 ? 4.8 : 3.8) * sx,
                    color: stage >= 4 ? Color(hex: "#FFD166") : Color.white,
                    rimColor: acc
                )
            }
        }

        // (6) 外裙高定金线描边 (Lv.4+ 金线滚边)
        let rimColor = stage >= 4 ? Color(hex: "#FFD166") : acc.opacity(0.85)
        context.stroke(outerSkirt, with: .color(rimColor), lineWidth: (1.5 + CGFloat(stage) * 0.28) * sx)

        // (7) Lv.5 礼服斜向虹彩极光扫光
        if stage >= 5 {
            var clipCtx = context
            clipCtx.clip(to: outerSkirt)
            let sweepCenter = (30 + shimmerPos * 100) * sx
            var band = Path()
            band.move(to: CGPoint(x: sweepCenter - 12 * sx, y: (78 + dy) * sy))
            band.addLine(to: CGPoint(x: sweepCenter + 8 * sx, y: (78 + dy) * sy))
            band.addLine(to: CGPoint(x: sweepCenter - 16 * sx, y: (skirtBottomY + 8) * sy))
            band.addLine(to: CGPoint(x: sweepCenter - 36 * sx, y: (skirtBottomY + 8) * sy))
            band.closeSubpath()
            clipCtx.fill(
                band,
                with: .linearGradient(
                    Gradient(colors: [.clear, Color.white.opacity(0.45), Color(hex: "#FFD166").opacity(0.38), .clear]),
                    startPoint: CGPoint(x: sweepCenter - 26 * sx, y: 80 * sy),
                    endPoint: CGPoint(x: sweepCenter + 12 * sx, y: 120 * sy)
                )
            )
        }

        // (8) 公主上身胸衣 + 泡泡袖 / 皇室披肩
        if dress.styleIndex == 3 {
            // 冰雪披肩
            var capelet = Path()
            capelet.move(to: CGPoint(x: 61 * sx, y: (64 + dy) * sy))
            capelet.addQuadCurve(to: CGPoint(x: 80 * sx, y: (73 + dy) * sy), control: CGPoint(x: 70 * sx, y: (74 + dy) * sy))
            capelet.addQuadCurve(to: CGPoint(x: 99 * sx, y: (64 + dy) * sy), control: CGPoint(x: 90 * sx, y: (74 + dy) * sy))
            capelet.addLine(to: CGPoint(x: 92 * sx, y: (61 + dy) * sy))
            capelet.addLine(to: CGPoint(x: 68 * sx, y: (61 + dy) * sy))
            capelet.closeSubpath()
            context.fill(capelet, with: .color(Color.white.opacity(0.75)))
        } else {
            let puffR = (dress.styleIndex == 1 ? 13.0 : 10.5) * sx
            let puffL = Circle().path(in: CGRect(x: 56 * sx, y: (61 + dy) * sy, width: puffR, height: puffR))
            let puffRight = Circle().path(in: CGRect(x: (104 * sx) - puffR, y: (61 + dy) * sy, width: puffR, height: puffR))
            context.fill(puffL, with: .color(c2))
            context.fill(puffRight, with: .color(c2))
            context.stroke(puffL, with: .color(rimColor.opacity(0.65)), lineWidth: 1.0 * sx)
            context.stroke(puffRight, with: .color(rimColor.opacity(0.65)), lineWidth: 1.0 * sx)
        }

        var bodice = Path()
        bodice.move(to: CGPoint(x: 66 * sx, y: (62 + dy) * sy))
        bodice.addQuadCurve(to: CGPoint(x: 80 * sx, y: (65 + dy) * sy), control: CGPoint(x: 73 * sx, y: (67 + dy) * sy))
        bodice.addQuadCurve(to: CGPoint(x: 94 * sx, y: (62 + dy) * sy), control: CGPoint(x: 87 * sx, y: (67 + dy) * sy))
        bodice.addLine(to: CGPoint(x: 93 * sx, y: (81 + dy) * sy))
        bodice.addQuadCurve(to: CGPoint(x: 67 * sx, y: (81 + dy) * sy), control: CGPoint(x: 80 * sx, y: (84 + dy) * sy))
        bodice.closeSubpath()
        context.fill(bodice, with: .linearGradient(Gradient(colors: [c1, c2.opacity(0.8)]), startPoint: CGPoint(x: 80 * sx, y: 62 * sy), endPoint: CGPoint(x: 80 * sx, y: 83 * sy)))
        context.stroke(bodice, with: .color(rimColor), lineWidth: 1.4 * sx)

        // 腰带 & 胸花结
        let waistBow = PrincessVectorShapes.bowPath(center: CGPoint(x: 80 * sx, y: (81 + dy) * sy), width: 16 * sx, height: 7 * sx)
        context.fill(waistBow, with: .color(acc))
        if dress.styleIndex == 5 {
            let rose = PrincessVectorShapes.flowerPath(center: CGPoint(x: 80 * sx, y: (70 + dy) * sy), petalRadius: 3.2 * sx, petalCount: 5)
            context.fill(rose, with: .color(acc))
        }
    }

    // MARK: - 5. 项链与耳坠首饰 (styleIndex 0..5 × jewelryStage 1..5)
    private func drawJewelry(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat
    ) {
        let c1 = Color(hex: jewelry.primaryHex)
        let c2 = Color(hex: jewelry.secondaryHex)
        let acc = Color(hex: jewelry.accentHex)
        let stage = jewelryStage

        // (1) 耳坠
        let earDropLen = (3.5 + CGFloat(stage) * 1.1) * sy
        for isRight in [false, true] {
            let ex = (isRight ? 105.5 : 54.5) * sx
            let ey = (44.0 + dy) * sy
            if jewelry.styleIndex == 0 {
                let daisy = PrincessVectorShapes.flowerPath(center: CGPoint(x: ex, y: ey), petalRadius: 2.3 * sx, petalCount: 5)
                context.fill(daisy, with: .color(.white))
                let core = Circle().path(in: CGRect(x: ex - 1.1 * sx, y: ey - 1.1 * sy, width: 2.2 * sx, height: 2.2 * sy))
                context.fill(core, with: .color(c1))
            } else if jewelry.styleIndex >= 3 {
                var chain = Path()
                chain.move(to: CGPoint(x: ex, y: ey - 1.5 * sy))
                chain.addLine(to: CGPoint(x: ex, y: ey + earDropLen))
                context.stroke(chain, with: .color(Color(hex: "#FFD166")), lineWidth: 1.0 * sx)
                PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: ex, y: ey + earDropLen), size: (3.2 + CGFloat(stage) * 0.35) * sx, color: c1, rimColor: acc)
            } else {
                let drop = Circle().path(in: CGRect(x: ex - 2.3 * sx, y: ey, width: 4.6 * sx, height: 4.6 * sy))
                context.fill(drop, with: .color(c1))
                context.stroke(drop, with: .color(c2), lineWidth: 0.9 * sx)
            }
        }

        // (2) 项链主链条
        var neckArc = Path()
        neckArc.move(to: CGPoint(x: 70 * sx, y: (60 + dy) * sy))
        neckArc.addQuadCurve(to: CGPoint(x: 90 * sx, y: (60 + dy) * sy), control: CGPoint(x: 80 * sx, y: (67 + dy) * sy))
        context.stroke(neckArc, with: .color(stage >= 3 || jewelry.styleIndex >= 3 ? Color(hex: "#FFD166") : c2), lineWidth: (1.2 + CGFloat(stage) * 0.18) * sx)

        switch jewelry.styleIndex {
        case 0:
            // 小雏菊颈链
            for offset in [-5.0, 0.0, 5.0] {
                let fx = (80.0 + offset) * sx
                let fy = (64.2 - abs(offset) * 0.25 + Double(dy)) * sy
                let daisy = PrincessVectorShapes.flowerPath(center: CGPoint(x: fx, y: fy), petalRadius: 2.2 * sx, petalCount: 5)
                context.fill(daisy, with: .color(.white))
                let centerDot = Circle().path(in: CGRect(x: fx - 1.1 * sx, y: fy - 1.1 * sy, width: 2.2 * sx, height: 2.2 * sy))
                context.fill(centerDot, with: .color(c1))
            }

        case 1:
            // 双排珍珠套链
            for i in -3...3 {
                let px = CGFloat(80.0 + Double(i) * 2.8) * sx
                let py = (CGFloat(64.5 - Double(abs(i)) * 0.6) + dy) * sy
                let pearl = Circle().path(in: CGRect(x: px - 1.5 * sx, y: py - 1.5 * sy, width: 3.0 * sx, height: 3.0 * sy))
                context.fill(pearl, with: .color(c1))
                context.stroke(pearl, with: .color(.white.opacity(0.8)), lineWidth: 0.5 * sx)
            }

        case 2:
            // 人鱼之泪水滴蓝晶
            PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 80 * sx, y: (65.5 + dy) * sy), size: (4.8 + CGFloat(stage) * 0.4) * sx, color: c1, rimColor: .white)

        case 3:
            // 新月宝石吊坠
            let moon = PrincessVectorShapes.crescentPath(center: CGPoint(x: 80 * sx, y: (66 + dy) * sy), radius: 4.2 * sx)
            context.fill(moon, with: .color(acc))
            PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 80 * sx, y: (66 + dy) * sy), size: 3.2 * sx, color: c1, rimColor: .white)

        case 4:
            // 海洋之心红宝石心形吊坠
            let hPath = PrincessVectorShapes.heartPath(center: CGPoint(x: 80 * sx, y: (66 + dy) * sy), width: 7.0 * sx, height: 6.4 * sy)
            context.fill(hPath, with: .color(c1))
            context.stroke(hPath, with: .color(acc), lineWidth: 1.1 * sx)

        default:
            // 5: 彩虹星钻皇后华链
            let gemColors = [Color(hex: "#FF595E"), Color(hex: "#FFCA3A"), Color(hex: "#4CC9F0"), Color(hex: "#9B6EF3"), Color(hex: "#FF758F")]
            for idx in 0..<5 {
                let offset = CGFloat(idx - 2) * 3.8
                let gx = (80.0 + offset) * sx
                let gy = (65.2 - abs(offset) * 0.25 + dy) * sy
                PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: gx, y: gy), size: (idx == 2 ? 4.8 : 3.2) * sx, color: gemColors[idx], rimColor: Color(hex: "#FFD166"))
            }
        }
    }

    // MARK: - 6. 甜美脸庞、表情系统 & 高光刘海
    private func drawFaceAndFrontHair(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat
    ) {
        let skin = Color(hex: "#FFE6D8")
        let skinShadow = Color(hex: "#F5C6B4")
        let hairBase = Color(hex: hairColor.primaryHex)
        let hairHi = Color(hex: hairColor.highlightHex)
        let hairSh = Color(hex: hairColor.shadowHex)
        let ink = Color(hex: "#362517")

        // 脖颈
        let neck = RoundedRectangle(cornerRadius: 3.5 * sx).path(in: CGRect(x: 75.5 * sx, y: (53 + dy) * sy, width: 9 * sx, height: 11 * sy))
        context.fill(neck, with: .color(skin))
        let neckShadow = Ellipse().path(in: CGRect(x: 75.5 * sx, y: (53 + dy) * sy, width: 9 * sx, height: 4.5 * sy))
        context.fill(neckShadow, with: .color(skinShadow.opacity(0.65)))

        // 可爱双耳
        let earL = Ellipse().path(in: CGRect(x: 53.5 * sx, y: (38 + dy) * sy, width: 5.5 * sx, height: 7 * sy))
        let earR = Ellipse().path(in: CGRect(x: 101 * sx, y: (38 + dy) * sy, width: 5.5 * sx, height: 7 * sy))
        context.fill(earL, with: .color(skin))
        context.fill(earR, with: .color(skin))

        // 柔和甜美瓜子/杏仁脸轮廓
        var face = Path()
        face.move(to: CGPoint(x: 57 * sx, y: (36 + dy) * sy))
        face.addCurve(
            to: CGPoint(x: 80 * sx, y: (21 + dy) * sy),
            control1: CGPoint(x: 57 * sx, y: (24 + dy) * sy),
            control2: CGPoint(x: 68 * sx, y: (21 + dy) * sy)
        )
        face.addCurve(
            to: CGPoint(x: 103 * sx, y: (36 + dy) * sy),
            control1: CGPoint(x: 92 * sx, y: (21 + dy) * sy),
            control2: CGPoint(x: 103 * sx, y: (24 + dy) * sy)
        )
        face.addCurve(
            to: CGPoint(x: 80 * sx, y: (56 + dy) * sy),
            control1: CGPoint(x: 103 * sx, y: (49 + dy) * sy),
            control2: CGPoint(x: 91 * sx, y: (56 + dy) * sy)
        )
        face.addCurve(
            to: CGPoint(x: 57 * sx, y: (36 + dy) * sy),
            control1: CGPoint(x: 69 * sx, y: (56 + dy) * sy),
            control2: CGPoint(x: 57 * sx, y: (49 + dy) * sy)
        )
        face.closeSubpath()
        context.fill(face, with: .color(skin))
        context.stroke(face, with: .color(skinShadow.opacity(0.6)), lineWidth: 1.2 * sx)

        // 蜜桃腮红
        let blushColor = Color(hex: "#FF758F").opacity(expression.id == "pout" ? 0.72 : 0.56)
        let blushL = Ellipse().path(in: CGRect(x: 60.5 * sx, y: (44.2 + dy) * sy, width: 7.5 * sx, height: 4.0 * sy))
        let blushR = Ellipse().path(in: CGRect(x: 92 * sx, y: (44.2 + dy) * sy, width: 7.5 * sx, height: 4.0 * sy))
        context.fill(blushL, with: .color(blushColor))
        context.fill(blushR, with: .color(blushColor))

        // 眼睛 & 表情（smile / wink / starry / pout）
        drawEyesAndMouth(context: &context, sx: sx, sy: sy, dy: dy, ink: ink)

        // 前额分层刘海与两侧修颜鬓发
        var bangs = Path()
        bangs.move(to: CGPoint(x: 55.5 * sx, y: (38 + dy) * sy))
        bangs.addCurve(
            to: CGPoint(x: 80 * sx, y: (19.5 + dy) * sy),
            control1: CGPoint(x: 55 * sx, y: (23 + dy) * sy),
            control2: CGPoint(x: 66 * sx, y: (19 + dy) * sy)
        )
        bangs.addCurve(
            to: CGPoint(x: 104.5 * sx, y: (38 + dy) * sy),
            control1: CGPoint(x: 94 * sx, y: (19 + dy) * sy),
            control2: CGPoint(x: 105 * sx, y: (23 + dy) * sy)
        )
        bangs.addQuadCurve(to: CGPoint(x: 97 * sx, y: (31 + dy) * sy), control: CGPoint(x: 101 * sx, y: (34 + dy) * sy))
        bangs.addQuadCurve(to: CGPoint(x: 87 * sx, y: (33 + dy) * sy), control: CGPoint(x: 92 * sx, y: (36 + dy) * sy))
        bangs.addQuadCurve(to: CGPoint(x: 80 * sx, y: (29 + dy) * sy), control: CGPoint(x: 84 * sx, y: (35 + dy) * sy))
        bangs.addQuadCurve(to: CGPoint(x: 71 * sx, y: (33 + dy) * sy), control: CGPoint(x: 75 * sx, y: (35 + dy) * sy))
        bangs.addQuadCurve(to: CGPoint(x: 63 * sx, y: (31 + dy) * sy), control: CGPoint(x: 68 * sx, y: (36 + dy) * sy))
        bangs.addQuadCurve(to: CGPoint(x: 55.5 * sx, y: (38 + dy) * sy), control: CGPoint(x: 59 * sx, y: (34 + dy) * sy))
        bangs.closeSubpath()

        context.fill(bangs, with: .linearGradient(Gradient(colors: [hairHi, hairBase, hairSh]), startPoint: CGPoint(x: 80 * sx, y: 19 * sy), endPoint: CGPoint(x: 80 * sx, y: 38 * sy)))
        context.stroke(bangs, with: .color(hairSh.opacity(0.45)), lineWidth: 1.0 * sx)

        // 天使发丝高光弧（二次元秀发光泽）
        var shineArc = Path()
        shineArc.move(to: CGPoint(x: 65 * sx, y: (25.5 + dy) * sy))
        shineArc.addQuadCurve(to: CGPoint(x: 95 * sx, y: (25.5 + dy) * sy), control: CGPoint(x: 80 * sx, y: (21.5 + dy) * sy))
        context.stroke(shineArc, with: .color(hairHi.opacity(0.85)), style: StrokeStyle(lineWidth: 2.2 * sx, lineCap: .round))
    }

    private func drawEyesAndMouth(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat,
        ink: Color
    ) {
        let eyeAccent = Color(hex: dress.primaryHex)

        func drawSparkleEye(cx: CGFloat, cy: CGFloat, starry: Bool) {
            let eyeRect = CGRect(x: cx - 3.6 * sx, y: cy - 4.1 * sy, width: 7.2 * sx, height: 8.2 * sy)
            let base = Ellipse().path(in: eyeRect)
            context.fill(base, with: .linearGradient(Gradient(colors: [ink, eyeAccent.opacity(0.85)]), startPoint: CGPoint(x: cx, y: cy - 4 * sy), endPoint: CGPoint(x: cx, y: cy + 4 * sy)))

            // 上睫毛翘起
            var lash = Path()
            lash.move(to: CGPoint(x: cx - 4.0 * sx, y: cy - 2.6 * sy))
            lash.addQuadCurve(to: CGPoint(x: cx + 4.4 * sx, y: cy - 2.6 * sy), control: CGPoint(x: cx, y: cy - 5.2 * sy))
            context.stroke(lash, with: .color(ink), style: StrokeStyle(lineWidth: 1.6 * sx, lineCap: .round))

            if starry {
                let star = PrincessVectorShapes.starPath(center: CGPoint(x: cx, y: cy + 0.3 * sy), outerRadius: 2.8 * sx, innerRadius: 1.1 * sx, points: 4)
                context.fill(star, with: .color(Color(hex: "#FFD166")))
            } else {
                let bigShine = Circle().path(in: CGRect(x: cx - 2.0 * sx, y: cy - 2.4 * sy, width: 2.6 * sx, height: 2.6 * sy))
                let miniShine = Circle().path(in: CGRect(x: cx + 0.6 * sx, y: cy + 1.1 * sy, width: 1.4 * sx, height: 1.4 * sy))
                context.fill(bigShine, with: .color(.white))
                context.fill(miniShine, with: .color(.white.opacity(0.9)))
            }
        }

        switch expression.id {
        case "wink":
            drawSparkleEye(cx: 70.0 * sx, cy: (39.5 + dy) * sy, starry: false)
            // 右眼眨眼俏皮弧
            var winkEye = Path()
            winkEye.move(to: CGPoint(x: 86 * sx, y: (40.2 + dy) * sy))
            winkEye.addQuadCurve(to: CGPoint(x: 94 * sx, y: (40.2 + dy) * sy), control: CGPoint(x: 90 * sx, y: (36.0 + dy) * sy))
            context.stroke(winkEye, with: .color(ink), style: StrokeStyle(lineWidth: 1.9 * sx, lineCap: .round))

            // 开心微笑嘴巴
            var smile = Path()
            smile.move(to: CGPoint(x: 76.2 * sx, y: (47.5 + dy) * sy))
            smile.addQuadCurve(to: CGPoint(x: 83.8 * sx, y: (47.5 + dy) * sy), control: CGPoint(x: 80 * sx, y: (52.0 + dy) * sy))
            smile.closeSubpath()
            context.fill(smile, with: .color(Color(hex: "#FF758F")))
            context.stroke(smile, with: .color(Color(hex: "#E05385")), lineWidth: 1.2 * sx)

        case "starry":
            drawSparkleEye(cx: 70.0 * sx, cy: (39.2 + dy) * sy, starry: true)
            drawSparkleEye(cx: 90.0 * sx, cy: (39.2 + dy) * sy, starry: true)

            var cheerMouth = Path()
            cheerMouth.move(to: CGPoint(x: 75.5 * sx, y: (47.2 + dy) * sy))
            cheerMouth.addQuadCurve(to: CGPoint(x: 84.5 * sx, y: (47.2 + dy) * sy), control: CGPoint(x: 80 * sx, y: (53.4 + dy) * sy))
            cheerMouth.closeSubpath()
            context.fill(cheerMouth, with: .color(Color(hex: "#FF758F")))
            context.stroke(cheerMouth, with: .color(Color(hex: "#E05385")), lineWidth: 1.2 * sx)

        case "pout":
            drawSparkleEye(cx: 70.0 * sx, cy: (39.5 + dy) * sy, starry: false)
            drawSparkleEye(cx: 90.0 * sx, cy: (39.5 + dy) * sy, starry: false)

            // 甜酷小嘟嘴（小猫/小樱桃嘟嘴弧）
            var pout = Path()
            pout.move(to: CGPoint(x: 78.2 * sx, y: (47.8 + dy) * sy))
            pout.addQuadCurve(to: CGPoint(x: 81.2 * sx, y: (48.8 + dy) * sy), control: CGPoint(x: 80.5 * sx, y: (47.2 + dy) * sy))
            pout.addQuadCurve(to: CGPoint(x: 78.2 * sx, y: (49.8 + dy) * sy), control: CGPoint(x: 80.5 * sx, y: (50.2 + dy) * sy))
            context.stroke(pout, with: .color(Color(hex: "#E05385")), style: StrokeStyle(lineWidth: 1.6 * sx, lineCap: .round))

        default:
            // smile
            drawSparkleEye(cx: 70.0 * sx, cy: (39.5 + dy) * sy, starry: false)
            drawSparkleEye(cx: 90.0 * sx, cy: (39.5 + dy) * sy, starry: false)

            var smile = Path()
            smile.move(to: CGPoint(x: 76.5 * sx, y: (47.8 + dy) * sy))
            smile.addQuadCurve(to: CGPoint(x: 83.5 * sx, y: (47.8 + dy) * sy), control: CGPoint(x: 80 * sx, y: (51.8 + dy) * sy))
            context.stroke(smile, with: .color(Color(hex: "#E05385")), style: StrokeStyle(lineWidth: 1.7 * sx, lineCap: .round))
        }
    }

    // MARK: - 7. 皇冠与发饰 (styleIndex 0..5 × tiaraStage 1..5)
    private func drawTiara(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat
    ) {
        let c1 = Color(hex: hairTiara.primaryHex)
        let c2 = Color(hex: hairTiara.secondaryHex)
        let acc = Color(hex: hairTiara.accentHex)
        let stage = tiaraStage

        switch hairTiara.styleIndex {
        case 0:
            // 元气双马尾丝带结：左右双马尾结 + 迷你中心发箍
            let bowL = PrincessVectorShapes.bowPath(center: CGPoint(x: 56 * sx, y: (26 + dy) * sy), width: (13 + CGFloat(stage) * 1.1) * sx, height: 7 * sx)
            let bowR = PrincessVectorShapes.bowPath(center: CGPoint(x: 104 * sx, y: (26 + dy) * sy), width: (13 + CGFloat(stage) * 1.1) * sx, height: 7 * sx)
            context.fill(bowL, with: .color(c1))
            context.fill(bowR, with: .color(c1))
            context.stroke(bowL, with: .color(stage >= 4 ? Color(hex: "#FFD166") : acc), lineWidth: 1.0 * sx)
            context.stroke(bowR, with: .color(stage >= 4 ? Color(hex: "#FFD166") : acc), lineWidth: 1.0 * sx)
            if stage >= 3 {
                PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 56 * sx, y: (26 + dy) * sy), size: 3.2 * sx, color: acc, rimColor: .white)
                PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 104 * sx, y: (26 + dy) * sy), size: 3.2 * sx, color: acc, rimColor: .white)
            }

        case 1:
            // 蜜桃珍珠发箍
            var band = Path()
            band.move(to: CGPoint(x: 58 * sx, y: (29 + dy) * sy))
            band.addQuadCurve(to: CGPoint(x: 102 * sx, y: (29 + dy) * sy), control: CGPoint(x: 80 * sx, y: (11 + dy) * sy))
            context.stroke(band, with: .color(c1), style: StrokeStyle(lineWidth: 3.2 * sx, lineCap: .round))
            for i in 0..<7 {
                let t = Double(i) / 6.0
                let px = CGFloat(59.0 + t * 42.0) * sx
                let py = (CGFloat(27.5 - sin(t * .pi) * 9.0) + dy) * sy
                let pearl = Circle().path(in: CGRect(x: px - 2.2 * sx, y: py - 2.2 * sy, width: 4.4 * sx, height: 4.4 * sy))
                context.fill(pearl, with: .color(c2))
                context.stroke(pearl, with: .color(acc.opacity(0.6)), lineWidth: 0.7 * sx)
            }
            let sideBow = PrincessVectorShapes.bowPath(center: CGPoint(x: 96 * sx, y: (20 + dy) * sy), width: 12 * sx, height: 6 * sx)
            context.fill(sideBow, with: .color(c1))

        case 2:
            // 森林晨露玫瑰花冠
            var vine = Path()
            vine.move(to: CGPoint(x: 58 * sx, y: (25 + dy) * sy))
            vine.addQuadCurve(to: CGPoint(x: 102 * sx, y: (25 + dy) * sy), control: CGPoint(x: 80 * sx, y: (16 + dy) * sy))
            context.stroke(vine, with: .color(c2), style: StrokeStyle(lineWidth: 2.6 * sx, lineCap: .round))
            let rosePositions: [(CGFloat, CGFloat, CGFloat)] = [(67, 21, 3.6), (80, 17, 4.4), (93, 21, 3.6)]
            for r in rosePositions {
                let flower = PrincessVectorShapes.flowerPath(center: CGPoint(x: r.0 * sx, y: (r.1 + dy) * sy), petalRadius: (r.2 + CGFloat(stage) * 0.25) * sx, petalCount: 5)
                context.fill(flower, with: .color(c1))
                let core = Circle().path(in: CGRect(x: (r.0 - 1.6) * sx, y: (r.1 + dy - 1.6) * sy, width: 3.2 * sx, height: 3.2 * sy))
                context.fill(core, with: .color(acc))
            }

        case 3:
            // 水晶天鹅羽毛银冠
            let crownH = (11.0 + CGFloat(stage) * 1.3) * sy
            var wingCrown = Path()
            wingCrown.move(to: CGPoint(x: 63 * sx, y: (22 + dy) * sy))
            wingCrown.addQuadCurve(to: CGPoint(x: 56 * sx, y: (21 + dy) * sy - crownH * 0.72), control: CGPoint(x: 56 * sx, y: (17 + dy) * sy))
            wingCrown.addQuadCurve(to: CGPoint(x: 74 * sx, y: (20 + dy) * sy - crownH * 0.45), control: CGPoint(x: 66 * sx, y: (14 + dy) * sy))
            wingCrown.addLine(to: CGPoint(x: 80 * sx, y: (21 + dy) * sy - crownH))
            wingCrown.addLine(to: CGPoint(x: 86 * sx, y: (20 + dy) * sy - crownH * 0.45))
            wingCrown.addQuadCurve(to: CGPoint(x: 104 * sx, y: (21 + dy) * sy - crownH * 0.72), control: CGPoint(x: 94 * sx, y: (14 + dy) * sy))
            wingCrown.addQuadCurve(to: CGPoint(x: 97 * sx, y: (22 + dy) * sy), control: CGPoint(x: 104 * sx, y: (17 + dy) * sy))
            wingCrown.closeSubpath()
            context.fill(wingCrown, with: .linearGradient(Gradient(colors: [c2, c1]), startPoint: CGPoint(x: 80 * sx, y: 10 * sy), endPoint: CGPoint(x: 80 * sx, y: 24 * sy)))
            context.stroke(wingCrown, with: .color(stage >= 4 ? Color(hex: "#FFD166") : acc), lineWidth: 1.3 * sx)
            PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 80 * sx, y: (19 + dy) * sy - crownH * 0.38), size: 5.0 * sx, color: acc, rimColor: .white)

        case 4:
            // 月光女神星钻大王冠
            let crownH = (12.0 + CGFloat(stage) * 1.4) * sy
            var tiara = Path()
            tiara.move(to: CGPoint(x: 62 * sx, y: (21 + dy) * sy))
            tiara.addLine(to: CGPoint(x: 59 * sx, y: (20 + dy) * sy - crownH * 0.68))
            tiara.addLine(to: CGPoint(x: 69 * sx, y: (20 + dy) * sy - crownH * 0.38))
            tiara.addLine(to: CGPoint(x: 73 * sx, y: (20 + dy) * sy - crownH * 0.82))
            tiara.addLine(to: CGPoint(x: 80 * sx, y: (20 + dy) * sy - crownH * 0.46))
            tiara.addLine(to: CGPoint(x: 87 * sx, y: (20 + dy) * sy - crownH * 0.82))
            tiara.addLine(to: CGPoint(x: 91 * sx, y: (20 + dy) * sy - crownH * 0.38))
            tiara.addLine(to: CGPoint(x: 101 * sx, y: (20 + dy) * sy - crownH * 0.68))
            tiara.addLine(to: CGPoint(x: 98 * sx, y: (21 + dy) * sy))
            tiara.closeSubpath()
            context.fill(tiara, with: .linearGradient(Gradient(colors: [c2, c1]), startPoint: CGPoint(x: 80 * sx, y: 8 * sy), endPoint: CGPoint(x: 80 * sx, y: 22 * sy)))
            context.stroke(tiara, with: .color(acc), lineWidth: 1.4 * sx)
            let moon = PrincessVectorShapes.crescentPath(center: CGPoint(x: 80 * sx, y: (17 + dy) * sy - crownH * 0.56), radius: 5.2 * sx)
            context.fill(moon, with: .color(acc))
            if stage >= 3 {
                let gemXs: [CGFloat] = [66, 80, 94]
                for sxPos in gemXs {
                    PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: sxPos * sx, y: (18 + dy) * sy), size: 3.0 * sx, color: .white, rimColor: acc)
                }
            }

        default:
            // 5: 太阳神耀金凤凰圣冠
            let crownH = (13.0 + CGFloat(stage) * 1.5) * sy
            // 背后太阳光芒轮
            if stage >= 2 {
                for ray in 0..<7 {
                    let ang = -Double.pi * 0.82 + Double(ray) * (Double.pi * 0.64 / 6.0)
                    let p0 = CGPoint(x: 80 * sx + CGFloat(cos(ang)) * 12 * sx, y: (16 + dy) * sy + CGFloat(sin(ang)) * 10 * sy)
                    let p1 = CGPoint(x: 80 * sx + CGFloat(cos(ang)) * (18 + CGFloat(stage) * 1.6) * sx, y: (16 + dy) * sy + CGFloat(sin(ang)) * (15 + CGFloat(stage) * 1.4) * sy)
                    var rp = Path()
                    rp.move(to: p0)
                    rp.addLine(to: p1)
                    context.stroke(rp, with: .color(Color(hex: "#FFD166")), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))
                }
            }
            var phoenixCrown = Path()
            phoenixCrown.move(to: CGPoint(x: 61 * sx, y: (21 + dy) * sy))
            phoenixCrown.addLine(to: CGPoint(x: 56 * sx, y: (21 + dy) * sy - crownH * 0.72))
            phoenixCrown.addLine(to: CGPoint(x: 68 * sx, y: (21 + dy) * sy - crownH * 0.42))
            phoenixCrown.addLine(to: CGPoint(x: 80 * sx, y: (21 + dy) * sy - crownH))
            phoenixCrown.addLine(to: CGPoint(x: 92 * sx, y: (21 + dy) * sy - crownH * 0.42))
            phoenixCrown.addLine(to: CGPoint(x: 104 * sx, y: (21 + dy) * sy - crownH * 0.72))
            phoenixCrown.addLine(to: CGPoint(x: 99 * sx, y: (21 + dy) * sy))
            phoenixCrown.closeSubpath()
            context.fill(phoenixCrown, with: .linearGradient(Gradient(colors: [c2, c1]), startPoint: CGPoint(x: 80 * sx, y: 6 * sy), endPoint: CGPoint(x: 80 * sx, y: 22 * sy)))
            context.stroke(phoenixCrown, with: .color(acc), lineWidth: 1.5 * sx)
            PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 80 * sx, y: (17 + dy) * sy - crownH * 0.36), size: 5.2 * sx, color: acc, rimColor: .white)
        }
    }

    // MARK: - 8. 手臂 Pose 与 6 种风格迥异的手持魔法道具
    private func drawArmsAndWand(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        dy: CGFloat,
        sway: CGFloat
    ) {
        let skin = Color(hex: "#FFE6D8")
        let armW = 5.0 * sx

        // 左手坐标根据 Pose 变化
        let leftHand: CGPoint
        let leftElbow: CGPoint
        switch pose.id {
        case "wand_up":
            leftHand = CGPoint(x: 62 * sx, y: (79 + dy) * sy)
            leftElbow = CGPoint(x: 55 * sx, y: (75 + dy) * sy)
        case "leap":
            leftHand = CGPoint(x: 45 * sx, y: (62 + dy) * sy)
            leftElbow = CGPoint(x: 52 * sx, y: (69 + dy) * sy)
        default: // curtsy 拎裙
            leftHand = CGPoint(x: 49 * sx, y: (95 + dy) * sy)
            leftElbow = CGPoint(x: 53 * sx, y: (81 + dy) * sy)
        }

        var armL = Path()
        armL.move(to: CGPoint(x: 61 * sx, y: (69 + dy) * sy))
        armL.addQuadCurve(to: leftHand, control: leftElbow)
        context.stroke(armL, with: .color(skin), style: StrokeStyle(lineWidth: armW, lineCap: .round))
        let handLCircle = Circle().path(in: CGRect(x: leftHand.x - 2.6 * sx, y: leftHand.y - 2.6 * sy, width: 5.2 * sx, height: 5.2 * sy))
        context.fill(handLCircle, with: .color(skin))

        // 右手坐标根据 Pose 变化
        let rightHand: CGPoint
        let rightElbow: CGPoint
        let wandTiltDeg: Double
        switch pose.id {
        case "wand_up":
            rightHand = CGPoint(x: 112 * sx, y: (61 + dy) * sy)
            rightElbow = CGPoint(x: 108 * sx, y: (71 + dy) * sy)
            wandTiltDeg = -18
        case "leap":
            rightHand = CGPoint(x: 114 * sx, y: (65 + dy) * sy)
            rightElbow = CGPoint(x: 107 * sx, y: (71 + dy) * sy)
            wandTiltDeg = -8
        default: // curtsy
            rightHand = CGPoint(x: 112 * sx, y: (84 + dy) * sy)
            rightElbow = CGPoint(x: 106 * sx, y: (76 + dy) * sy)
            wandTiltDeg = 14
        }

        var armR = Path()
        armR.move(to: CGPoint(x: 99 * sx, y: (69 + dy) * sy))
        armR.addQuadCurve(to: rightHand, control: rightElbow)
        context.stroke(armR, with: .color(skin), style: StrokeStyle(lineWidth: armW, lineCap: .round))
        let handRCircle = Circle().path(in: CGRect(x: rightHand.x - 2.6 * sx, y: rightHand.y - 2.6 * sy, width: 5.2 * sx, height: 5.2 * sy))
        context.fill(handRCircle, with: .color(skin))

        // 绘制手持道具（在 rightHand 处按角度旋正绘制）
        var propCtx = context
        propCtx.translateBy(x: rightHand.x, y: rightHand.y)
        propCtx.rotate(by: Angle.degrees(wandTiltDeg))

        drawHeldProp(context: &propCtx, sx: sx, sy: sy, sway: sway)
    }

    private func drawHeldProp(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        sway: CGFloat
    ) {
        let c1 = Color(hex: wand.primaryHex)
        let c2 = Color(hex: wand.secondaryHex)
        let acc = Color(hex: wand.accentHex)
        let stage = wandStage

        switch wand.styleIndex {
        case 0:
            // 爱心奶油甜品银勺
            var handle = Path()
            handle.move(to: CGPoint(x: -2 * sx, y: 10 * sy))
            handle.addLine(to: CGPoint(x: 4 * sx, y: -22 * sy))
            context.stroke(handle, with: .color(c2), style: StrokeStyle(lineWidth: 2.8 * sx, lineCap: .round))
            let bowl = Ellipse().path(in: CGRect(x: -0.5 * sx, y: -33 * sy, width: 10 * sx, height: 13 * sy))
            context.fill(bowl, with: .color(c2))
            context.stroke(bowl, with: .color(Color.gray.opacity(0.45)), lineWidth: 1.0 * sx)
            let creamHeart = PrincessVectorShapes.heartPath(center: CGPoint(x: 4.5 * sx, y: -27 * sy), width: 6.5 * sx, height: 5.8 * sy)
            context.fill(creamHeart, with: .color(c1))

        case 1:
            // 草莓马卡龙飘空气球（向上飘起的丝线 + 爱心气球）
            let floatShift = sway * 2.4 * sx
            var stringP = Path()
            stringP.move(to: CGPoint(x: 0, y: 0))
            stringP.addQuadCurve(to: CGPoint(x: 5 * sx + floatShift, y: -30 * sy), control: CGPoint(x: -4 * sx, y: -15 * sy))
            context.stroke(stringP, with: .color(acc), style: StrokeStyle(lineWidth: 1.3 * sx, lineCap: .round))
            let balloonCenter = CGPoint(x: 5 * sx + floatShift, y: -39 * sy)
            let bHeart = PrincessVectorShapes.heartPath(center: balloonCenter, width: (16 + CGFloat(stage)) * sx, height: (15 + CGFloat(stage)) * sy)
            context.fill(bHeart, with: .linearGradient(Gradient(colors: [c2, c1]), startPoint: CGPoint(x: balloonCenter.x - 6 * sx, y: balloonCenter.y - 8 * sy), endPoint: CGPoint(x: balloonCenter.x + 6 * sx, y: balloonCenter.y + 8 * sy)))
            context.stroke(bHeart, with: .color(stage >= 4 ? Color(hex: "#FFD166") : .white.opacity(0.75)), lineWidth: 1.2 * sx)

        case 2:
            // 玫瑰水晶音乐花篮（手挽精致花篮）
            var arch = Path()
            arch.move(to: CGPoint(x: -6 * sx, y: 7 * sy))
            arch.addQuadCurve(to: CGPoint(x: 9 * sx, y: 7 * sy), control: CGPoint(x: 1.5 * sx, y: -7 * sy))
            context.stroke(arch, with: .color(c1), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))
            var basket = Path()
            basket.move(to: CGPoint(x: -8 * sx, y: 7 * sy))
            basket.addLine(to: CGPoint(x: 11 * sx, y: 7 * sy))
            basket.addLine(to: CGPoint(x: 8 * sx, y: 19 * sy))
            basket.addLine(to: CGPoint(x: -5 * sx, y: 19 * sy))
            basket.closeSubpath()
            context.fill(basket, with: .color(c1))
            context.stroke(basket, with: .color(stage >= 4 ? Color(hex: "#FFD166") : Color(hex: "#8D5524").opacity(0.55)), lineWidth: 1.1 * sx)
            let flowerXs: [CGFloat] = [-2.5, 1.5, 5.5]
            for fx in flowerXs {
                let rose = PrincessVectorShapes.flowerPath(center: CGPoint(x: fx * sx, y: 5.5 * sy), petalRadius: 2.8 * sx, petalCount: 5)
                context.fill(rose, with: .color(c2))
            }

        case 3:
            // 星月仙子黄金魔法棒
            var staff = Path()
            staff.move(to: CGPoint(x: -1 * sx, y: 11 * sy))
            staff.addLine(to: CGPoint(x: 5 * sx, y: -25 * sy))
            context.stroke(staff, with: .color(c1), style: StrokeStyle(lineWidth: 2.6 * sx, lineCap: .round))
            let moon = PrincessVectorShapes.crescentPath(center: CGPoint(x: 5 * sx, y: -30 * sy), radius: (7.5 + CGFloat(stage) * 0.5) * sx)
            context.fill(moon, with: .color(acc))
            let star = PrincessVectorShapes.starPath(center: CGPoint(x: 6.5 * sx, y: -30 * sy), outerRadius: 4.5 * sx, innerRadius: 1.8 * sx, points: 5)
            context.fill(star, with: .color(c2))

        case 4:
            // 冰雪极光天鹅水晶竖琴
            var frame = Path()
            frame.move(to: CGPoint(x: -4 * sx, y: 5 * sy))
            frame.addCurve(to: CGPoint(x: 7 * sx, y: -20 * sy), control1: CGPoint(x: -8 * sx, y: -8 * sy), control2: CGPoint(x: -2 * sx, y: -20 * sy))
            frame.addQuadCurve(to: CGPoint(x: 9 * sx, y: 4 * sy), control: CGPoint(x: 13 * sx, y: -12 * sy))
            frame.closeSubpath()
            context.fill(frame, with: .linearGradient(Gradient(colors: [c2.opacity(0.85), c1.opacity(0.85)]), startPoint: CGPoint(x: -4 * sx, y: -18 * sy), endPoint: CGPoint(x: 8 * sx, y: 5 * sy)))
            context.stroke(frame, with: .color(acc), lineWidth: 1.5 * sx)
            for s in 0..<4 {
                let xPos = CGFloat(-1.0 + Double(s) * 2.3) * sx
                var str = Path()
                str.move(to: CGPoint(x: xPos, y: -14 * sy))
                str.addLine(to: CGPoint(x: xPos, y: 3 * sy))
                context.stroke(str, with: .color(Color.white.opacity(0.9)), lineWidth: 0.7 * sx)
            }

        default:
            // 5: 皇家彩虹独角兽圣光权杖（高杖+双翼+心形彩钻）
            var scepter = Path()
            scepter.move(to: CGPoint(x: -3 * sx, y: 18 * sy))
            scepter.addLine(to: CGPoint(x: 6 * sx, y: -28 * sy))
            context.stroke(scepter, with: .color(c2), style: StrokeStyle(lineWidth: 2.8 * sx, lineCap: .round))

            // 杖头小金翼
            let wingDirs: [CGFloat] = [-1, 1]
            for dir in wingDirs {
                var wPath = Path()
                wPath.move(to: CGPoint(x: 6 * sx, y: -30 * sy))
                wPath.addQuadCurve(to: CGPoint(x: (6 + 10 * dir) * sx, y: -38 * sy), control: CGPoint(x: (6 + 7 * dir) * sx, y: -38 * sy))
                wPath.addQuadCurve(to: CGPoint(x: 6 * sx, y: -27 * sy), control: CGPoint(x: (6 + 7 * dir) * sx, y: -28 * sy))
                wPath.closeSubpath()
                context.fill(wPath, with: .color(c2))
            }
            let orbHeart = PrincessVectorShapes.heartPath(center: CGPoint(x: 6 * sx, y: -32 * sy), width: (10 + CGFloat(stage) * 0.7) * sx, height: (9.5 + CGFloat(stage) * 0.7) * sy)
            context.fill(orbHeart, with: .linearGradient(Gradient(colors: [c1, acc]), startPoint: CGPoint(x: 2 * sx, y: -37 * sy), endPoint: CGPoint(x: 10 * sx, y: -27 * sy)))
            context.stroke(orbHeart, with: .color(.white), lineWidth: 1.1 * sx)
        }

        // 阶段特效：Lv.3+ 光晕与丝带；Lv.5 星尘光环
        if stage >= 3 {
            let headCenter = wand.styleIndex == 2 ? CGPoint(x: 2 * sx, y: 4 * sy) : CGPoint(x: 5 * sx, y: -32 * sy)
            let aura = PrincessVectorShapes.starPath(center: CGPoint(x: headCenter.x + 8 * sx, y: headCenter.y - 6 * sy), outerRadius: 3.4 * sx, innerRadius: 1.3 * sx, points: 4)
            context.fill(aura, with: .color(Color(hex: "#FFD166")))
            if stage >= 5 {
                let halo = Circle().path(in: CGRect(x: headCenter.x - 10 * sx, y: headCenter.y - 10 * sy, width: 20 * sx, height: 20 * sy))
                context.stroke(halo, with: .color(Color(hex: "#FFD166").opacity(0.65)), style: StrokeStyle(lineWidth: 1.1 * sx, dash: [3 * sx, 2.5 * sx]))
            }
        }
    }
}

// MARK: - 2. 🎭 六大梦幻舞台背景视图 (PrincessStageBackdropView)
public struct PrincessStageBackdropView: View {
    public let stageThemeId: Int
    public var animated: Bool = true
    public var gentleMotion: Bool = false

    public init(stageThemeId: Int, animated: Bool = true, gentleMotion: Bool = false) {
        self.stageThemeId = stageThemeId
        self.animated = animated
        self.gentleMotion = gentleMotion
    }

    public var body: some View {
        let theme = ((stageThemeId % 6) + 6) % 6
        if animated {
            let interval: TimeInterval = gentleMotion ? (1.0 / 8.0) : (1.0 / 12.0)
            TimelineView(.periodic(from: Date(timeIntervalSinceReferenceDate: 0), by: interval)) { timeline in
                backdropCanvas(theme: theme, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        } else {
            backdropCanvas(theme: theme, time: 0)
        }
    }

    private func backdropCanvas(theme: Int, time: TimeInterval) -> some View {
        let drift = gentleMotion ? time * 0.25 : time * 0.72

        return Canvas { context, size in
            let w = size.width
            let h = size.height

            // 1. 主题天空与剧院幕布底色
            let skyColors: [Color] = skyPalette(for: theme)
            let bgRect = CGRect(origin: .zero, size: size)
            context.fill(
                Path(bgRect),
                with: .linearGradient(
                    Gradient(colors: skyColors),
                    startPoint: CGPoint(x: w * 0.5, y: 0),
                    endPoint: CGPoint(x: w * 0.5, y: h)
                )
            )

            // 2. 舞台背景主题建筑 / 极光 / 花廊
            drawThemeScenery(context: &context, theme: theme, w: w, h: h, drift: drift)

            // 3. 顶部双侧舞台丝绒幕布 / 拱门装饰
            drawCurtainArch(context: &context, theme: theme, w: w, h: h)

            // 4. 聚光灯柱 & 梦幻 T 台地台
            drawRunwayStage(context: &context, theme: theme, w: w, h: h)

            // 5. 主题漂浮花瓣/泡泡/星芒粒子
            drawAmbientParticles(context: &context, theme: theme, w: w, h: h, drift: drift)
        }
    }

    private func skyPalette(for theme: Int) -> [Color] {
        switch theme {
        case 0: return [Color(hex: "#FFE4EC"), Color(hex: "#FFF4F7"), Color(hex: "#FFF8EB")] // 草莓樱花舞台
        case 1: return [Color(hex: "#CFF5EE"), Color(hex: "#E6FAFC"), Color(hex: "#F5F0FF")] // 深海人鱼/马卡龙宫殿
        case 2: return [Color(hex: "#FFE0EC"), Color(hex: "#F2E6FF"), Color(hex: "#E3FAEA")] // 独角兽极光桥/樱花庭院
        case 3: return [Color(hex: "#1E3A6D"), Color(hex: "#3B7DD8"), Color(hex: "#CBEFFF")] // 银河冰雪水晶神殿
        case 4: return [Color(hex: "#250B4E"), Color(hex: "#6B21A8"), Color(hex: "#E879F9").opacity(0.65)] // 星河极光花庭
        default: return [Color(hex: "#581C3A"), Color(hex: "#B45309"), Color(hex: "#FEF3C7")] // 至尊皇家金殿
        }
    }

    private func drawThemeScenery(context: inout GraphicsContext, theme: Int, w: CGFloat, h: CGFloat, drift: Double) {
        switch theme {
        case 0:
            // 草莓甜心甜点花环圆窗
            let arch = RoundedRectangle(cornerRadius: w * 0.25).path(in: CGRect(x: w * 0.22, y: h * 0.08, width: w * 0.56, height: h * 0.68))
            context.fill(arch, with: .color(Color.white.opacity(0.45)))
            context.stroke(arch, with: .color(Color(hex: "#FF85A1").opacity(0.42)), lineWidth: 2)

        case 1:
            // 深海人鱼贝壳宫殿拱门
            for i in 0..<3 {
                let r = w * (0.22 + CGFloat(i) * 0.09)
                let shellArc = Circle().path(in: CGRect(x: w * 0.5 - r, y: h * 0.48 - r * 0.75, width: r * 2, height: r * 1.5))
                context.stroke(shellArc, with: .color(Color(hex: "#2EC4B6").opacity(0.24)), lineWidth: 2)
            }

        case 2:
            // 独角兽彩虹极光桥
            let rainbowColors = [Color(hex: "#FF85A1"), Color(hex: "#FFD166"), Color(hex: "#8AC926"), Color(hex: "#4CC9F0"), Color(hex: "#C77DFF")]
            for (idx, col) in rainbowColors.enumerated() {
                let inset = CGFloat(idx) * 6.0
                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: w * 0.5, y: h * 0.72),
                    radius: max(20, min(w, h) * 0.52 - inset),
                    startAngle: .degrees(190),
                    endAngle: .degrees(350),
                    clockwise: false
                )
                context.stroke(arc, with: .color(col.opacity(0.35)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }

        case 3:
            // 冰雪神殿水晶柱 + 弯月
            let moon = PrincessVectorShapes.crescentPath(center: CGPoint(x: w * 0.78, y: h * 0.22), radius: min(w, h) * 0.08)
            context.fill(moon, with: .color(Color(hex: "#FEF3C7").opacity(0.92)))
            for px in [w * 0.16, w * 0.84] {
                var pillar = Path()
                pillar.move(to: CGPoint(x: px - 12, y: h * 0.78))
                pillar.addLine(to: CGPoint(x: px - 8, y: h * 0.15))
                pillar.addLine(to: CGPoint(x: px, y: h * 0.07))
                pillar.addLine(to: CGPoint(x: px + 8, y: h * 0.15))
                pillar.addLine(to: CGPoint(x: px + 12, y: h * 0.78))
                pillar.closeSubpath()
                context.fill(pillar, with: .color(Color.white.opacity(0.22)))
            }

        case 4:
            // 极光星河波动彩带
            let waveShift = CGFloat(sin(drift * 0.7)) * 10
            var aurora = Path()
            aurora.move(to: CGPoint(x: 0, y: h * 0.30 + waveShift))
            aurora.addCurve(
                to: CGPoint(x: w, y: h * 0.22 - waveShift),
                control1: CGPoint(x: w * 0.35, y: h * 0.08),
                control2: CGPoint(x: w * 0.65, y: h * 0.44)
            )
            aurora.addLine(to: CGPoint(x: w, y: h * 0.40 - waveShift))
            aurora.addCurve(
                to: CGPoint(x: 0, y: h * 0.46 + waveShift),
                control1: CGPoint(x: w * 0.65, y: h * 0.56),
                control2: CGPoint(x: w * 0.35, y: h * 0.22)
            )
            aurora.closeSubpath()
            context.fill(aurora, with: .linearGradient(Gradient(colors: [Color(hex: "#4CC9F0").opacity(0.28), Color(hex: "#F72585").opacity(0.28)]), startPoint: .zero, endPoint: CGPoint(x: w, y: h * 0.5)))

        default:
            // 5: 至尊皇家金殿放射日光与金拱门
            for r in 0..<11 {
                let ang = -Double.pi * 0.9 + Double(r) * (Double.pi * 0.8 / 10.0)
                var ray = Path()
                ray.move(to: CGPoint(x: w * 0.5, y: h * 0.52))
                ray.addLine(to: CGPoint(x: w * 0.5 + CGFloat(cos(ang)) * w * 0.6, y: h * 0.52 + CGFloat(sin(ang)) * h * 0.6))
                context.stroke(ray, with: .color(Color(hex: "#FFD166").opacity(0.24)), lineWidth: 10)
            }
        }
    }

    private func drawCurtainArch(context: inout GraphicsContext, theme: Int, w: CGFloat, h: CGFloat) {
        let drapeColor: Color
        switch theme {
        case 0: drapeColor = Color(hex: "#FF85A1").opacity(0.32)
        case 1: drapeColor = Color(hex: "#2EC4B6").opacity(0.28)
        case 2: drapeColor = Color(hex: "#F472B6").opacity(0.28)
        case 3: drapeColor = Color(hex: "#60A5FA").opacity(0.28)
        case 4: drapeColor = Color(hex: "#9333EA").opacity(0.35)
        default: drapeColor = Color(hex: "#9F1239").opacity(0.36)
        }

        var leftDrape = Path()
        leftDrape.move(to: .zero)
        leftDrape.addLine(to: CGPoint(x: w * 0.20, y: 0))
        leftDrape.addQuadCurve(to: CGPoint(x: 0, y: h * 0.62), control: CGPoint(x: w * 0.14, y: h * 0.34))
        leftDrape.closeSubpath()

        var rightDrape = Path()
        rightDrape.move(to: CGPoint(x: w, y: 0))
        rightDrape.addLine(to: CGPoint(x: w * 0.80, y: 0))
        rightDrape.addQuadCurve(to: CGPoint(x: w, y: h * 0.62), control: CGPoint(x: w * 0.86, y: h * 0.34))
        rightDrape.closeSubpath()

        context.fill(leftDrape, with: .color(drapeColor))
        context.fill(rightDrape, with: .color(drapeColor))
    }

    private func drawRunwayStage(context: inout GraphicsContext, theme: Int, w: CGFloat, h: CGFloat) {
        // 聚光灯束
        var spotlight = Path()
        spotlight.move(to: CGPoint(x: w * 0.35, y: 0))
        spotlight.addLine(to: CGPoint(x: w * 0.65, y: 0))
        spotlight.addLine(to: CGPoint(x: w * 0.86, y: h * 0.88))
        spotlight.addLine(to: CGPoint(x: w * 0.14, y: h * 0.88))
        spotlight.closeSubpath()
        context.fill(
            spotlight,
            with: .linearGradient(
                Gradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.03)]),
                startPoint: CGPoint(x: w * 0.5, y: 0),
                endPoint: CGPoint(x: w * 0.5, y: h * 0.88)
            )
        )

        // 前景 T 台地台
        let floorColor = theme >= 3 ? Color(hex: "#FFFBEB").opacity(0.28) : Color.white.opacity(0.65)
        let stageTop = Ellipse().path(in: CGRect(x: w * 0.08, y: h * 0.76, width: w * 0.84, height: h * 0.24))
        context.fill(stageTop, with: .color(floorColor))
        context.stroke(stageTop, with: .color(Color(hex: "#FFD166").opacity(0.75)), lineWidth: 1.8)
    }

    private func drawAmbientParticles(context: inout GraphicsContext, theme: Int, w: CGFloat, h: CGFloat, drift: Double) {
        let particleCol: Color
        switch theme {
        case 0, 2: particleCol = Color(hex: "#FF85A1")
        case 1: particleCol = Color.white
        case 3: particleCol = Color(hex: "#E0F2FE")
        case 4: particleCol = Color(hex: "#FDE047")
        default: particleCol = Color(hex: "#FFD166")
        }

        for i in 0..<10 {
            let fx = CGFloat(0.09 + Double((i * 19) % 82) / 100.0) * w
            let baseY = CGFloat(0.12 + Double((i * 23) % 62) / 100.0) * h
            let yWave = CGFloat(sin(drift + Double(i) * 0.9) * (gentleMotion ? 3.5 : 8.0))
            let pt = CGPoint(x: fx, y: baseY + yWave)
            if theme == 1 {
                let bubble = Circle().path(in: CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8))
                context.stroke(bubble, with: .color(particleCol.opacity(0.65)), lineWidth: 1.2)
            } else if theme == 0 || theme == 2 {
                let petal = Ellipse().path(in: CGRect(x: pt.x - 3.5, y: pt.y - 2, width: 7, height: 4))
                context.fill(petal, with: .color(particleCol.opacity(0.55)))
            } else {
                let star = PrincessVectorShapes.starPath(center: pt, outerRadius: i % 2 == 0 ? 4.5 : 3.0, innerRadius: 1.5, points: 4)
                context.fill(star, with: .color(particleCol.opacity(0.85)))
            }
        }
    }
}

// MARK: - 3. 👜 高定单品 30 款矢量缩略图标 (FashionItemIconVectorView)
public struct FashionItemIconVectorView: View {
    public let item: PrincessFashionItem
    public var stage: Int = 1
    public var size: CGFloat = 44

    public init(item: PrincessFashionItem, stage: Int = 1, size: CGFloat = 44) {
        self.item = item
        self.stage = max(1, min(stage, PrincessFashionItem.maxStage))
        self.size = size
    }

    public var body: some View {
        ZStack {
            if stage >= 5 {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Color(hex: "#FF595E"), Color(hex: "#FFCA3A"), Color(hex: "#4CC9F0"), Color(hex: "#9B6EF3"), Color(hex: "#FF595E")],
                            center: .center
                        ),
                        lineWidth: 2.0
                    )
                    .frame(width: size * 0.96, height: size * 0.96)
            } else if stage >= 4 {
                Circle()
                    .stroke(Color(hex: "#FFD166"), lineWidth: 1.8)
                    .frame(width: size * 0.94, height: size * 0.94)
            }

            Canvas { context, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                let sx = w / 48.0
                let sy = h / 48.0

                let c1 = Color(hex: item.primaryHex)
                let c2 = Color(hex: item.secondaryHex)
                let acc = Color(hex: item.accentHex)

                switch item.category {
                case .dress:
                    drawDressIcon(context: &context, sx: sx, sy: sy, c1: c1, c2: c2, acc: acc)
                case .hairTiara:
                    drawTiaraIcon(context: &context, sx: sx, sy: sy, c1: c1, c2: c2, acc: acc)
                case .jewelry:
                    drawJewelryIcon(context: &context, sx: sx, sy: sy, c1: c1, c2: c2, acc: acc)
                case .wings:
                    drawWingsIcon(context: &context, sx: sx, sy: sy, c1: c1, c2: c2, acc: acc)
                case .wand:
                    drawWandIcon(context: &context, sx: sx, sy: sy, c1: c1, c2: c2, acc: acc)
                }

                // Lv.3+ 单品图标闪烁角标星芒
                if stage >= 3 {
                    let st = PrincessVectorShapes.starPath(center: CGPoint(x: 39 * sx, y: 10 * sy), outerRadius: 4.0 * sx, innerRadius: 1.5 * sx, points: 4)
                    context.fill(st, with: .color(Color(hex: "#FFD166")))
                }
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }

    private func drawDressIcon(context: inout GraphicsContext, sx: CGFloat, sy: CGFloat, c1: Color, c2: Color, acc: Color) {
        let bodice = RoundedRectangle(cornerRadius: 2.5 * sx).path(in: CGRect(x: 18 * sx, y: 8 * sy, width: 12 * sx, height: 10 * sy))
        context.fill(bodice, with: .color(c1))

        var skirt = Path()
        skirt.move(to: CGPoint(x: 18 * sx, y: 18 * sy))
        switch item.styleIndex {
        case 2:
            skirt.addQuadCurve(to: CGPoint(x: 8 * sx, y: 38 * sy), control: CGPoint(x: 10 * sx, y: 26 * sy))
            skirt.addQuadCurve(to: CGPoint(x: 24 * sx, y: 40 * sy), control: CGPoint(x: 16 * sx, y: 43 * sy))
            skirt.addQuadCurve(to: CGPoint(x: 40 * sx, y: 38 * sy), control: CGPoint(x: 32 * sx, y: 43 * sy))
            skirt.addQuadCurve(to: CGPoint(x: 30 * sx, y: 18 * sy), control: CGPoint(x: 38 * sx, y: 26 * sy))
        case 4:
            skirt.addQuadCurve(to: CGPoint(x: 9 * sx, y: 34 * sy), control: CGPoint(x: 11 * sx, y: 26 * sy))
            skirt.addCurve(to: CGPoint(x: 40 * sx, y: 42 * sy), control1: CGPoint(x: 18 * sx, y: 32 * sy), control2: CGPoint(x: 30 * sx, y: 45 * sy))
            skirt.addQuadCurve(to: CGPoint(x: 30 * sx, y: 18 * sy), control: CGPoint(x: 39 * sx, y: 28 * sy))
        default:
            let flare: CGFloat = item.styleIndex == 5 ? 4.0 : 0.0
            skirt.addQuadCurve(to: CGPoint(x: (9 - flare) * sx, y: 40 * sy), control: CGPoint(x: 10 * sx, y: 26 * sy))
            skirt.addQuadCurve(to: CGPoint(x: (39 + flare) * sx, y: 40 * sy), control: CGPoint(x: 24 * sx, y: 44 * sy))
            skirt.addQuadCurve(to: CGPoint(x: 30 * sx, y: 18 * sy), control: CGPoint(x: 38 * sx, y: 26 * sy))
        }
        skirt.closeSubpath()
        context.fill(skirt, with: .linearGradient(Gradient(colors: [c1, c2]), startPoint: CGPoint(x: 24 * sx, y: 18 * sy), endPoint: CGPoint(x: 24 * sx, y: 42 * sy)))
        context.stroke(skirt, with: .color(stage >= 4 ? Color(hex: "#FFD166") : acc), lineWidth: 1.3 * sx)

        if item.styleIndex == 0 {
            let apron = RoundedRectangle(cornerRadius: 4 * sx).path(in: CGRect(x: 16 * sx, y: 20 * sy, width: 16 * sx, height: 17 * sy))
            context.fill(apron, with: .color(.white.opacity(0.92)))
        } else if item.styleIndex == 1 {
            let puffL = Circle().path(in: CGRect(x: 11 * sx, y: 8 * sy, width: 8 * sx, height: 8 * sy))
            let puffR = Circle().path(in: CGRect(x: 29 * sx, y: 8 * sy, width: 8 * sx, height: 8 * sy))
            context.fill(puffL, with: .color(c2))
            context.fill(puffR, with: .color(c2))
        }
        let belt = PrincessVectorShapes.bowPath(center: CGPoint(x: 24 * sx, y: 18.5 * sy), width: 10 * sx, height: 4.5 * sy)
        context.fill(belt, with: .color(acc))
    }

    private func drawTiaraIcon(context: inout GraphicsContext, sx: CGFloat, sy: CGFloat, c1: Color, c2: Color, acc: Color) {
        switch item.styleIndex {
        case 0:
            let b1 = PrincessVectorShapes.bowPath(center: CGPoint(x: 15 * sx, y: 24 * sy), width: 16 * sx, height: 10 * sy)
            let b2 = PrincessVectorShapes.bowPath(center: CGPoint(x: 33 * sx, y: 24 * sy), width: 16 * sx, height: 10 * sy)
            context.fill(b1, with: .color(c1))
            context.fill(b2, with: .color(c1))
            context.stroke(b1, with: .color(acc), lineWidth: 1.1 * sx)
            context.stroke(b2, with: .color(acc), lineWidth: 1.1 * sx)
        case 1:
            var arc = Path()
            arc.move(to: CGPoint(x: 8 * sx, y: 31 * sy))
            arc.addQuadCurve(to: CGPoint(x: 40 * sx, y: 31 * sy), control: CGPoint(x: 24 * sx, y: 8 * sy))
            context.stroke(arc, with: .color(c1), style: StrokeStyle(lineWidth: 3.5 * sx, lineCap: .round))
            for i in 0..<5 {
                let t = Double(i) / 4.0
                let px = CGFloat(11.0 + t * 26.0) * sx
                let py = CGFloat(27.5 - sin(t * .pi) * 8.5) * sy
                let pearl = Circle().path(in: CGRect(x: px - 2.3 * sx, y: py - 2.3 * sy, width: 4.6 * sx, height: 4.6 * sy))
                context.fill(pearl, with: .color(c2))
            }
        case 2:
            var arc = Path()
            arc.move(to: CGPoint(x: 9 * sx, y: 31 * sy))
            arc.addQuadCurve(to: CGPoint(x: 39 * sx, y: 31 * sy), control: CGPoint(x: 24 * sx, y: 15 * sy))
            context.stroke(arc, with: .color(c2), style: StrokeStyle(lineWidth: 2.8 * sx, lineCap: .round))
            let rosePts: [(CGFloat, CGFloat)] = [(14, 24), (24, 19), (34, 24)]
            for pos in rosePts {
                let fl = PrincessVectorShapes.flowerPath(center: CGPoint(x: pos.0 * sx, y: pos.1 * sy), petalRadius: 4.2 * sx, petalCount: 5)
                context.fill(fl, with: .color(c1))
            }
        default:
            var crown = Path()
            crown.move(to: CGPoint(x: 9 * sx, y: 33 * sy))
            crown.addLine(to: CGPoint(x: 7 * sx, y: 15 * sy))
            crown.addLine(to: CGPoint(x: 17 * sx, y: 23 * sy))
            crown.addLine(to: CGPoint(x: 24 * sx, y: 10 * sy))
            crown.addLine(to: CGPoint(x: 31 * sx, y: 23 * sy))
            crown.addLine(to: CGPoint(x: 41 * sx, y: 15 * sy))
            crown.addLine(to: CGPoint(x: 39 * sx, y: 33 * sy))
            crown.closeSubpath()
            context.fill(crown, with: .linearGradient(Gradient(colors: [c2, c1]), startPoint: CGPoint(x: 24 * sx, y: 10 * sy), endPoint: CGPoint(x: 24 * sx, y: 33 * sy)))
            context.stroke(crown, with: .color(stage >= 4 ? Color(hex: "#FFD166") : acc), lineWidth: 1.4 * sx)
            PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 24 * sx, y: 24 * sy), size: 4.5 * sx, color: acc, rimColor: .white)
        }
    }

    private func drawJewelryIcon(context: inout GraphicsContext, sx: CGFloat, sy: CGFloat, c1: Color, c2: Color, acc: Color) {
        var chain = Path()
        chain.move(to: CGPoint(x: 9 * sx, y: 15 * sy))
        chain.addQuadCurve(to: CGPoint(x: 39 * sx, y: 15 * sy), control: CGPoint(x: 24 * sx, y: 35 * sy))
        context.stroke(chain, with: .color(stage >= 3 ? Color(hex: "#FFD166") : c2), lineWidth: 2.0 * sx)

        if item.styleIndex == 0 {
            let fl = PrincessVectorShapes.flowerPath(center: CGPoint(x: 24 * sx, y: 27 * sy), petalRadius: 4.5 * sx, petalCount: 5)
            context.fill(fl, with: .color(.white))
            let core = Circle().path(in: CGRect(x: 22 * sx, y: 25 * sy, width: 4 * sx, height: 4 * sy))
            context.fill(core, with: .color(c1))
        } else if item.styleIndex == 4 {
            let heart = PrincessVectorShapes.heartPath(center: CGPoint(x: 24 * sx, y: 29 * sy), width: 11 * sx, height: 10 * sy)
            context.fill(heart, with: .color(c1))
            context.stroke(heart, with: .color(acc), lineWidth: 1.2 * sx)
        } else if item.styleIndex == 3 {
            let moon = PrincessVectorShapes.crescentPath(center: CGPoint(x: 24 * sx, y: 28 * sy), radius: 6 * sx)
            context.fill(moon, with: .color(acc))
            PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 24 * sx, y: 28 * sy), size: 4 * sx, color: c1, rimColor: .white)
        } else {
            PrincessVectorShapes.drawGem(in: &context, center: CGPoint(x: 24 * sx, y: 28 * sy), size: 7.0 * sx, color: c1, rimColor: acc)
        }
    }

    private func drawWingsIcon(context: inout GraphicsContext, sx: CGFloat, sy: CGFloat, c1: Color, c2: Color, acc: Color) {
        if item.styleIndex == 0 {
            let bow = PrincessVectorShapes.bowPath(center: CGPoint(x: 24 * sx, y: 20 * sy), width: 32 * sx, height: 16 * sy)
            context.fill(bow, with: .linearGradient(Gradient(colors: [c1, c2]), startPoint: CGPoint(x: 8 * sx, y: 12 * sy), endPoint: CGPoint(x: 40 * sx, y: 28 * sy)))
            context.stroke(bow, with: .color(acc), lineWidth: 1.3 * sx)
            var tL = Path()
            tL.move(to: CGPoint(x: 21 * sx, y: 24 * sy))
            tL.addLine(to: CGPoint(x: 13 * sx, y: 40 * sy))
            tL.addLine(to: CGPoint(x: 19 * sx, y: 37 * sy))
            tL.closeSubpath()
            var tR = Path()
            tR.move(to: CGPoint(x: 27 * sx, y: 24 * sy))
            tR.addLine(to: CGPoint(x: 35 * sx, y: 40 * sy))
            tR.addLine(to: CGPoint(x: 29 * sx, y: 37 * sy))
            tR.closeSubpath()
            context.fill(tL, with: .color(c1))
            context.fill(tR, with: .color(c1))
        } else {
            let dirs: [CGFloat] = [-1, 1]
            for dir in dirs {
                var wPath = Path()
                wPath.move(to: CGPoint(x: (24 + 2 * dir) * sx, y: 24 * sy))
                wPath.addQuadCurve(to: CGPoint(x: (24 + 19 * dir) * sx, y: 10 * sy), control: CGPoint(x: (24 + 14 * dir) * sx, y: 7 * sy))
                wPath.addQuadCurve(to: CGPoint(x: (24 + 15 * dir) * sx, y: 32 * sy), control: CGPoint(x: (24 + 21 * dir) * sx, y: 25 * sy))
                wPath.closeSubpath()
                context.fill(wPath, with: .linearGradient(Gradient(colors: [c1, c2]), startPoint: CGPoint(x: 24 * sx, y: 24 * sy), endPoint: CGPoint(x: (24 + 18 * dir) * sx, y: 12 * sy)))
                context.stroke(wPath, with: .color(stage >= 4 ? Color(hex: "#FFD166") : acc), lineWidth: 1.2 * sx)
            }
        }
    }

    private func drawWandIcon(context: inout GraphicsContext, sx: CGFloat, sy: CGFloat, c1: Color, c2: Color, acc: Color) {
        switch item.styleIndex {
        case 0:
            var stick = Path()
            stick.move(to: CGPoint(x: 13 * sx, y: 39 * sy))
            stick.addLine(to: CGPoint(x: 28 * sx, y: 22 * sy))
            context.stroke(stick, with: .color(c2), style: StrokeStyle(lineWidth: 2.8 * sx, lineCap: .round))
            let spoon = Ellipse().path(in: CGRect(x: 25 * sx, y: 9 * sy, width: 13 * sx, height: 15 * sy))
            context.fill(spoon, with: .color(c2))
            let heart = PrincessVectorShapes.heartPath(center: CGPoint(x: 31.5 * sx, y: 16.5 * sy), width: 7 * sx, height: 6.5 * sy)
            context.fill(heart, with: .color(c1))
        case 1:
            var line = Path()
            line.move(to: CGPoint(x: 20 * sx, y: 42 * sy))
            line.addQuadCurve(to: CGPoint(x: 25 * sx, y: 25 * sy), control: CGPoint(x: 27 * sx, y: 34 * sy))
            context.stroke(line, with: .color(acc), style: StrokeStyle(lineWidth: 1.4 * sx, lineCap: .round))
            let heart = PrincessVectorShapes.heartPath(center: CGPoint(x: 25 * sx, y: 17 * sy), width: 18 * sx, height: 16 * sy)
            context.fill(heart, with: .linearGradient(Gradient(colors: [c2, c1]), startPoint: CGPoint(x: 18 * sx, y: 10 * sy), endPoint: CGPoint(x: 32 * sx, y: 24 * sy)))
        case 2:
            var handle = Path()
            handle.move(to: CGPoint(x: 13 * sx, y: 24 * sy))
            handle.addQuadCurve(to: CGPoint(x: 35 * sx, y: 24 * sy), control: CGPoint(x: 24 * sx, y: 7 * sy))
            context.stroke(handle, with: .color(c1), style: StrokeStyle(lineWidth: 2.4 * sx, lineCap: .round))
            let basket = RoundedRectangle(cornerRadius: 4 * sx).path(in: CGRect(x: 11 * sx, y: 23 * sy, width: 26 * sx, height: 16 * sy))
            context.fill(basket, with: .color(c1))
            let fl = PrincessVectorShapes.flowerPath(center: CGPoint(x: 24 * sx, y: 22 * sy), petalRadius: 4 * sx, petalCount: 5)
            context.fill(fl, with: .color(c2))
        case 4:
            var frame = Path()
            frame.move(to: CGPoint(x: 15 * sx, y: 38 * sy))
            frame.addCurve(to: CGPoint(x: 31 * sx, y: 11 * sy), control1: CGPoint(x: 9 * sx, y: 21 * sy), control2: CGPoint(x: 19 * sx, y: 8 * sy))
            frame.addQuadCurve(to: CGPoint(x: 33 * sx, y: 38 * sy), control: CGPoint(x: 39 * sx, y: 22 * sy))
            frame.closeSubpath()
            context.fill(frame, with: .linearGradient(Gradient(colors: [c2, c1]), startPoint: CGPoint(x: 15 * sx, y: 11 * sy), endPoint: CGPoint(x: 33 * sx, y: 38 * sy)))
            context.stroke(frame, with: .color(acc), lineWidth: 1.4 * sx)
        default:
            var stick = Path()
            stick.move(to: CGPoint(x: 13 * sx, y: 40 * sy))
            stick.addLine(to: CGPoint(x: 29 * sx, y: 20 * sy))
            context.stroke(stick, with: .color(acc), style: StrokeStyle(lineWidth: 2.8 * sx, lineCap: .round))
            let star = PrincessVectorShapes.starPath(center: CGPoint(x: 31 * sx, y: 16 * sy), outerRadius: 9 * sx, innerRadius: 4 * sx, points: 5)
            context.fill(star, with: .color(c1))
            context.stroke(star, with: .color(c2), lineWidth: 1.2 * sx)
        }
    }
}

// MARK: - 4. 私有几何矢量辅助路径库 (PrincessVectorShapes)
private enum PrincessVectorShapes {
    static func starPath(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, points: Int) -> Path {
        var path = Path()
        guard points >= 3 else { return path }
        let total = points * 2
        let step = Double.pi / Double(points)
        for i in 0..<total {
            let r = (i % 2 == 0) ? outerRadius : innerRadius
            let angle = Double(i) * step - Double.pi / 2.0
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }

    static func heartPath(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        let topY = center.y - height * 0.22
        let bottomY = center.y + height * 0.50
        path.move(to: CGPoint(x: center.x, y: bottomY))
        path.addCurve(
            to: CGPoint(x: center.x - width * 0.50, y: topY),
            control1: CGPoint(x: center.x - width * 0.42, y: center.y + height * 0.20),
            control2: CGPoint(x: center.x - width * 0.55, y: topY + height * 0.20)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y - height * 0.08),
            control1: CGPoint(x: center.x - width * 0.45, y: center.y - height * 0.52),
            control2: CGPoint(x: center.x - width * 0.05, y: center.y - height * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: center.x + width * 0.50, y: topY),
            control1: CGPoint(x: center.x + width * 0.05, y: center.y - height * 0.42),
            control2: CGPoint(x: center.x + width * 0.45, y: center.y - height * 0.52)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: bottomY),
            control1: CGPoint(x: center.x + width * 0.55, y: topY + height * 0.20),
            control2: CGPoint(x: center.x + width * 0.42, y: center.y + height * 0.20)
        )
        path.closeSubpath()
        return path
    }

    static func bowPath(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        let hw = width * 0.5
        let hh = height * 0.5
        // 左翼
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x - hw, y: center.y - hh * 0.8),
            control1: CGPoint(x: center.x - hw * 0.35, y: center.y - hh * 1.1),
            control2: CGPoint(x: center.x - hw * 0.95, y: center.y - hh * 1.15)
        )
        path.addCurve(
            to: CGPoint(x: center.x - hw, y: center.y + hh * 0.8),
            control1: CGPoint(x: center.x - hw * 1.05, y: center.y - hh * 0.1),
            control2: CGPoint(x: center.x - hw * 1.05, y: center.y + hh * 0.2)
        )
        path.addCurve(
            to: center,
            control1: CGPoint(x: center.x - hw * 0.85, y: center.y + hh * 1.15),
            control2: CGPoint(x: center.x - hw * 0.35, y: center.y + hh * 1.05)
        )
        // 右翼
        path.move(to: center)
        path.addCurve(
            to: CGPoint(x: center.x + hw, y: center.y - hh * 0.8),
            control1: CGPoint(x: center.x + hw * 0.35, y: center.y - hh * 1.1),
            control2: CGPoint(x: center.x + hw * 0.95, y: center.y - hh * 1.15)
        )
        path.addCurve(
            to: CGPoint(x: center.x + hw, y: center.y + hh * 0.8),
            control1: CGPoint(x: center.x + hw * 1.05, y: center.y - hh * 0.1),
            control2: CGPoint(x: center.x + hw * 1.05, y: center.y + hh * 0.2)
        )
        path.addCurve(
            to: center,
            control1: CGPoint(x: center.x + hw * 0.85, y: center.y + hh * 1.15),
            control2: CGPoint(x: center.x + hw * 0.35, y: center.y + hh * 1.05)
        )
        path.closeSubpath()
        return path
    }

    static func flowerPath(center: CGPoint, petalRadius: CGFloat, petalCount: Int) -> Path {
        var path = Path()
        for i in 0..<petalCount {
            let angle = Double(i) * (Double.pi * 2.0 / Double(petalCount))
            let px = center.x + CGFloat(cos(angle)) * petalRadius * 0.65
            let py = center.y + CGFloat(sin(angle)) * petalRadius * 0.65
            let pr = petalRadius * 0.56
            path.addEllipse(in: CGRect(x: px - pr, y: py - pr, width: pr * 2, height: pr * 2))
        }
        return path
    }

    static func crescentPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .degrees(35), endAngle: .degrees(325), clockwise: false)
        path.addArc(
            center: CGPoint(x: center.x + radius * 0.38, y: center.y),
            radius: radius * 0.82,
            startAngle: .degrees(315),
            endAngle: .degrees(45),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }

    static func drawGem(
        in context: inout GraphicsContext,
        center: CGPoint,
        size: CGFloat,
        color: Color,
        rimColor: Color
    ) {
        var diamond = Path()
        diamond.move(to: CGPoint(x: center.x, y: center.y - size))
        diamond.addLine(to: CGPoint(x: center.x + size * 0.78, y: center.y))
        diamond.addLine(to: CGPoint(x: center.x, y: center.y + size))
        diamond.addLine(to: CGPoint(x: center.x - size * 0.78, y: center.y))
        diamond.closeSubpath()
        context.fill(diamond, with: .color(color))
        context.stroke(diamond, with: .color(rimColor), lineWidth: max(0.7, size * 0.22))
        let shine = Circle().path(in: CGRect(x: center.x - size * 0.25, y: center.y - size * 0.45, width: size * 0.36, height: size * 0.36))
        context.fill(shine, with: .color(.white.opacity(0.9)))
    }
}
