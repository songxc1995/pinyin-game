import SwiftUI

// MARK: - 🦄 12 只守护萌宠五阶进化全矢量动态视图 (GuardianPetVectorView)
public struct GuardianPetVectorView: View {
    public let species: GuardianPetSpecies
    public let stage: Int // 1 萌芽幼崽, 2 闪耀灵兽, 3 星辉圣兽, 4 皇冠神兽, 5 至尊幻兽
    public var size: CGFloat = 76
    public var animated: Bool = true
    public var showHeartBurst: Bool = false
    public var gentleMotion: Bool = false
    public var talentActive: Bool = false

    public init(
        species: GuardianPetSpecies,
        stage: Int = 1,
        size: CGFloat = 76,
        animated: Bool = true,
        showHeartBurst: Bool = false,
        gentleMotion: Bool = false,
        talentActive: Bool = false
    ) {
        self.species = species
        self.stage = max(1, min(stage, GuardianPetSpecies.maxStage))
        self.size = size
        self.animated = animated
        self.showHeartBurst = showHeartBurst
        self.gentleMotion = gentleMotion
        self.talentActive = talentActive
    }

    private var frameInterval: TimeInterval {
        gentleMotion ? (1.0 / 14.0) : (1.0 / 30.0)
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: frameInterval, paused: !animated)) { timeline in
            let rawT = animated ? timeline.date.timeIntervalSinceReferenceDate : 0.0
            let speedScale: Double = gentleMotion ? 0.38 : 1.0
            let t = rawT * speedScale
            let motionAmp: CGFloat = gentleMotion ? 0.45 : 1.0
            let talentBoost: CGFloat = talentActive ? 1.08 : 1.0
            let bobY: CGFloat = animated
                ? CGFloat(sin(t * 2.5)) * (size * 0.036) * motionAmp * (talentActive ? 1.45 : 1.0)
                : 0.0
            let squashX: CGFloat = animated
                ? 1.0 + CGFloat(cos(t * 2.5)) * 0.022 * motionAmp
                : 1.0
            let squashY: CGFloat = animated
                ? 1.0 - CGFloat(cos(t * 2.5)) * 0.022 * motionAmp
                : 1.0

            ZStack {
                Canvas { context, canvasSize in
                    drawPetScene(
                        context: &context,
                        canvasSize: canvasSize,
                        t: t,
                        motionAmp: motionAmp,
                        bobY: bobY,
                        squashX: squashX,
                        squashY: squashY
                    )
                }
                .frame(width: size * 1.32, height: size * 1.32)
                .scaleEffect(talentBoost)

                if showHeartBurst {
                    heartBurstOverlay(t: t, motionAmp: motionAmp)
                }
            }
            .frame(width: size, height: size)
        }
    }

    @ViewBuilder
    private func heartBurstOverlay(t: Double, motionAmp: CGFloat) -> some View {
        let lift = animated ? CGFloat(abs(sin(t * 3.8))) * (size * 0.08) * motionAmp : 0
        HStack(spacing: max(3, size * 0.06)) {
            Text("💖")
            Text("✨")
            Text("🎵")
        }
        .font(.system(size: max(10, size * 0.23)))
        .offset(y: -size * 0.54 - lift)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - 主绘制管线（基于 132x132 坐标系，主体居中于 66, 68）
    private func drawPetScene(
        context: inout GraphicsContext,
        canvasSize: CGSize,
        t: Double,
        motionAmp: CGFloat,
        bobY: CGFloat,
        squashX: CGFloat,
        squashY: CGFloat
    ) {
        let sx = canvasSize.width / 132.0
        let sy = canvasSize.height / 132.0
        let c1 = Color(hex: species.primaryHex)
        let c2 = Color(hex: species.secondaryHex)
        let acc = Color(hex: species.accentHex)
        let ink = Color(hex: "#362517")

        // 1. 阶位背景光环与魔法阵（Lv.2 ~ Lv.5 递进蜕变）
        drawStageBackAura(context: &context, sx: sx, sy: sy, t: t, c1: c1, c2: c2, acc: acc)

        // 2. 地面投影（随悬浮高度轻微缩放）
        let shadowScale = 1.0 - max(-0.08, min(0.08, bobY / max(1.0, size)))
        let shadowRect = CGRect(
            x: (66 - 26 * shadowScale) * sx,
            y: 103 * sy,
            width: 52 * shadowScale * sx,
            height: 8.5 * shadowScale * sy
        )
        context.fill(Ellipse().path(in: shadowRect), with: .color(Color.black.opacity(0.13)))

        // 3. 角色本体弹性坐标变换层
        context.drawLayer { petCtx in
            let cx = 66.0 * sx
            let cy = 68.0 * sy
            petCtx.translateBy(x: cx, y: cy + bobY)
            petCtx.scaleBy(x: squashX, y: squashY)
            petCtx.translateBy(x: -cx, y: -cy)

            // 3A. Lv.3+ 星纱披肩 / Lv.5 皇家星斗斗篷（后层）
            drawStageBackCloakAndWings(context: &petCtx, sx: sx, sy: sy, t: t, motionAmp: motionAmp, c1: c1, c2: c2, acc: acc)

            // 3B. 物种后景结构（尾巴、固有双翼、热气水柱等）
            drawSpeciesRearFeatures(context: &petCtx, sx: sx, sy: sy, t: t, motionAmp: motionAmp, c1: c1, c2: c2, acc: acc, ink: ink)

            // 3C. 12 种神兽独立解剖级轮廓与五官
            drawSpeciesBodyAndHead(context: &petCtx, sx: sx, sy: sy, t: t, motionAmp: motionAmp, c1: c1, c2: c2, acc: acc, ink: ink)

            // 3D. 阶位饰品与头冠（Lv.1 嫩芽/蝴蝶结 → Lv.2 星光吊坠 → Lv.3 新月额饰 → Lv.4 金丝宝石皇冠 → Lv.5 星系王冠）
            drawStageAccessories(context: &petCtx, sx: sx, sy: sy, t: t, c1: c1, c2: c2, acc: acc)
        }

        // 4. Lv.3 ~ Lv.5 前景环绕星辰与公转行星粒子
        drawStageForegroundStars(context: &context, sx: sx, sy: sy, t: t, c1: c1, c2: c2, acc: acc)
    }

    // MARK: - 1. 阶位背景光环与双层魔法阵
    private func drawStageBackAura(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        t: Double,
        c1: Color,
        c2: Color,
        acc: Color
    ) {
        let cx = 66.0 * sx
        let cy = 68.0 * sy

        // Lv.1 柔光晕
        let baseGlow = Circle().path(in: CGRect(x: 20 * sx, y: 22 * sy, width: 92 * sx, height: 92 * sy))
        context.fill(
            baseGlow,
            with: .radialGradient(
                Gradient(colors: [c2.opacity(stage >= 3 ? 0.55 : 0.34), c1.opacity(0.10), .clear]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 2 * sx,
                endRadius: 48 * sx
            )
        )

        // Lv.2+ 闪耀灵兽：呼吸柔光环 + 旋转虚线星环
        if stage >= 2 {
            let pulse = animated ? (1.0 + 0.04 * sin(t * 2.2)) : 1.0
            let r2 = 44.0 * pulse
            let ringRect = CGRect(x: cx - r2 * sx, y: cy - r2 * sy, width: r2 * 2 * sx, height: r2 * 2 * sy)
            context.drawLayer { ringCtx in
                ringCtx.translateBy(x: cx, y: cy)
                ringCtx.rotate(by: .radians(t * 0.45))
                ringCtx.translateBy(x: -cx, y: -cy)
                ringCtx.stroke(
                    Circle().path(in: ringRect),
                    with: .color(Color(hex: "#FFD166").opacity(stage >= 4 ? 0.80 : 0.55)),
                    style: StrokeStyle(lineWidth: (stage >= 4 ? 2.2 : 1.5) * sx, dash: [5 * sx, 4 * sx])
                )
            }
        }

        // Lv.4+ 皇冠神兽：双层圣光六芒星魔法阵
        if stage >= 4 {
            context.drawLayer { runeCtx in
                runeCtx.translateBy(x: cx, y: cy)
                runeCtx.rotate(by: .radians(-t * 0.35))
                let rad: CGFloat = (stage >= 5 ? 51.0 : 47.0) * sx
                for offset in [0.0, Double.pi / 3.0] {
                    var tri = Path()
                    for k in 0..<3 {
                        let a = offset + Double(k) * (Double.pi * 2.0 / 3.0)
                        let pt = CGPoint(x: CGFloat(cos(a)) * rad, y: CGFloat(sin(a)) * rad)
                        if k == 0 { tri.move(to: pt) } else { tri.addLine(to: pt) }
                    }
                    tri.closeSubpath()
                    runeCtx.stroke(tri, with: .color(Color(hex: "#FFD166").opacity(0.48)), lineWidth: 1.4 * sx)
                }
            }
        }

        // Lv.5 至尊幻兽：九色极光星环
        if stage >= 5 {
            let auroraRadius: CGFloat = 56.0
            let auroraRect = CGRect(
                x: cx - auroraRadius * sx,
                y: cy - auroraRadius * sy,
                width: auroraRadius * 2 * sx,
                height: auroraRadius * 2 * sy
            )
            let rainbowColors: [Color] = [
                Color(hex: "#FF595E"),
                Color(hex: "#FF924C"),
                Color(hex: "#FFCA3A"),
                Color(hex: "#8AC926"),
                Color(hex: "#2EC4B6"),
                Color(hex: "#4CC9F0"),
                Color(hex: "#7A6EE6"),
                Color(hex: "#F72585"),
                Color(hex: "#FF595E")
            ]
            context.fill(
                Circle().path(in: CGRect(x: 8 * sx, y: 10 * sy, width: 116 * sx, height: 116 * sy)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(hex: "#FFD166").opacity(0.40),
                        c1.opacity(0.26),
                        Color(hex: "#7A6EE6").opacity(0.18),
                        .clear
                    ]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 8 * sx,
                    endRadius: 58 * sx
                )
            )
            context.drawLayer { arcCtx in
                arcCtx.translateBy(x: cx, y: cy)
                arcCtx.rotate(by: .radians(t * 0.65))
                arcCtx.translateBy(x: -cx, y: -cy)
                arcCtx.stroke(
                    Circle().path(in: auroraRect),
                    with: .conicGradient(Gradient(colors: rainbowColors), center: CGPoint(x: cx, y: cy)),
                    style: StrokeStyle(lineWidth: 2.8 * sx, lineCap: .round, dash: [9 * sx, 4 * sx])
                )
            }
        }
    }

    // MARK: - 2. 阶位后景星纱披肩 / 琉璃结晶大翼 / 皇家星斗斗篷
    private func drawStageBackCloakAndWings(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        t: Double,
        motionAmp: CGFloat,
        c1: Color,
        c2: Color,
        acc: Color
    ) {
        let hasNativeWings = (species.kind == .fireDragon || species.kind == .phoenix || species.kind == .owlDoctor)
        let flap = animated ? CGFloat(sin(t * 4.2)) * 5.0 * motionAmp : 0.0

        // Lv.3+ 星纱披肩 / Lv.5 皇家星斗斗篷
        if stage >= 3 {
            let cloakColor = stage >= 5 ? Color(hex: "#432371") : c1.opacity(0.75)
            let cloakTrim = stage >= 5 ? Color(hex: "#FFD166") : c2
            let wave = animated ? CGFloat(sin(t * 2.8)) * 2.5 * motionAmp : 0.0
            var cloak = Path()
            cloak.move(to: CGPoint(x: 42 * sx, y: 66 * sy))
            cloak.addQuadCurve(
                to: CGPoint(x: (25 - wave) * sx, y: 100 * sy),
                control: CGPoint(x: 30 * sx, y: 84 * sy)
            )
            cloak.addQuadCurve(
                to: CGPoint(x: 66 * sx, y: (104 + wave * 0.4) * sy),
                control: CGPoint(x: 46 * sx, y: 106 * sy)
            )
            cloak.addQuadCurve(
                to: CGPoint(x: (107 + wave) * sx, y: 100 * sy),
                control: CGPoint(x: 86 * sx, y: 106 * sy)
            )
            cloak.addQuadCurve(
                to: CGPoint(x: 90 * sx, y: 66 * sy),
                control: CGPoint(x: 102 * sx, y: 84 * sy)
            )
            cloak.closeSubpath()

            context.fill(cloak, with: .color(cloakColor.opacity(stage >= 5 ? 0.88 : 0.36)))
            context.stroke(cloak, with: .color(cloakTrim.opacity(0.85)), lineWidth: (stage >= 5 ? 2.0 : 1.3) * sx)

            if stage >= 5 {
                // 斗篷内的点点银河星辰
                let cloakStars: [(CGFloat, CGFloat, CGFloat)] = [
                    (37, 92, 1.8), (47, 96, 1.5), (85, 93, 1.8), (94, 96, 1.5), (66, 98, 2.0)
                ]
                for (px, py, pr) in cloakStars {
                    let sRect = CGRect(x: (px - pr) * sx, y: (py - pr) * sy, width: pr * 2 * sx, height: pr * 2 * sy)
                    context.fill(Circle().path(in: sRect), with: .color(Color(hex: "#FFF3B0")))
                }
            }
        }

        // 为非固有双翼物种在 Lv.3+ 增加半透明魔法光翼；Lv.5 全物种升级或叠加琉璃结晶大翼
        if stage >= 3 && !hasNativeWings {
            let wingSpan: CGFloat = stage >= 5 ? 1.28 : (stage >= 4 ? 1.12 : 0.96)
            for side in [-1.0, 1.0] {
                let s = CGFloat(side)
                let baseX = 66.0 + s * 22.0
                let tipX = 66.0 + s * (50.0 * wingSpan)
                let tipY = 40.0 - flap - (stage >= 5 ? 8.0 : 0.0)

                var upperWing = Path()
                upperWing.move(to: CGPoint(x: baseX * sx, y: 66 * sy))
                upperWing.addQuadCurve(
                    to: CGPoint(x: tipX * sx, y: tipY * sy),
                    control: CGPoint(x: (66 + s * 46 * wingSpan) * sx, y: 64 * sy)
                )
                upperWing.addQuadCurve(
                    to: CGPoint(x: (66 + s * 18) * sx, y: 54 * sy),
                    control: CGPoint(x: (66 + s * 32 * wingSpan) * sx, y: (34 - flap * 0.5) * sy)
                )
                upperWing.closeSubpath()

                let fillCol: Color = stage >= 5 ? Color(hex: "#A2D2FF") : acc
                context.fill(
                    upperWing,
                    with: .linearGradient(
                        Gradient(colors: [Color.white.opacity(0.88), fillCol.opacity(stage >= 5 ? 0.78 : 0.52)]),
                        startPoint: CGPoint(x: baseX * sx, y: 62 * sy),
                        endPoint: CGPoint(x: tipX * sx, y: tipY * sy)
                    )
                )
                context.stroke(upperWing, with: .color(Color.white.opacity(0.92)), lineWidth: 1.4 * sx)

                // Lv.5 琉璃结晶下翼片
                if stage >= 5 {
                    var lowerWing = Path()
                    lowerWing.move(to: CGPoint(x: baseX * sx, y: 72 * sy))
                    lowerWing.addQuadCurve(
                        to: CGPoint(x: (66 + s * 46) * sx, y: (78 - flap * 0.4) * sy),
                        control: CGPoint(x: (66 + s * 44) * sx, y: 66 * sy)
                    )
                    lowerWing.addQuadCurve(
                        to: CGPoint(x: (66 + s * 19) * sx, y: 80 * sy),
                        control: CGPoint(x: (66 + s * 32) * sx, y: 86 * sy)
                    )
                    lowerWing.closeSubpath()
                    context.fill(lowerWing, with: .color(Color(hex: "#E0AAFF").opacity(0.68)))
                    context.stroke(lowerWing, with: .color(Color(hex: "#FFD166").opacity(0.9)), lineWidth: 1.2 * sx)
                }
            }
        }
    }

    // MARK: - 3. 物种特有后景结构（九尾/龙翼/凤尾/喷泉/祥云等）
    private func drawSpeciesRearFeatures(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        t: Double,
        motionAmp: CGFloat,
        c1: Color,
        c2: Color,
        acc: Color,
        ink: Color
    ) {
        let sway = animated ? CGFloat(sin(t * 3.1)) * 4.5 * motionAmp : 0.0
        let flap = animated ? CGFloat(sin(t * 4.4)) * 6.5 * motionAmp : 0.0

        switch species.kind {
        case .fireDragon:
            // 带火焰尖的弯曲龙尾 + 物种固有火龙翼（随阶位显著变大华丽，无重复叠翼）
            var tail = Path()
            tail.move(to: CGPoint(x: 82 * sx, y: 86 * sy))
            tail.addQuadCurve(to: CGPoint(x: (106 + sway * 0.4) * sx, y: (74 - sway * 0.3) * sy), control: CGPoint(x: 99 * sx, y: 90 * sy))
            context.stroke(tail, with: .color(c1), style: StrokeStyle(lineWidth: 7 * sx, lineCap: .round))
            var flame = Path()
            let fx = 106.0 + sway * 0.4
            let fy = 74.0 - sway * 0.3
            flame.move(to: CGPoint(x: fx * sx, y: (fy + 5) * sy))
            flame.addQuadCurve(to: CGPoint(x: (fx + 4) * sx, y: (fy - 11) * sy), control: CGPoint(x: (fx + 10) * sx, y: fy * sy))
            flame.addQuadCurve(to: CGPoint(x: (fx - 5) * sx, y: (fy - 2) * sy), control: CGPoint(x: (fx - 6) * sx, y: (fy - 7) * sy))
            flame.closeSubpath()
            context.fill(flame, with: .color(Color(hex: "#FFD166")))
            context.stroke(flame, with: .color(acc), lineWidth: 1.3 * sx)

            // 龙翼（Lv.1 迷你龙翼 -> Lv.5 琉璃炽焰双层龙翼）
            let wingScale: CGFloat = stage == 1 ? 0.72 : (stage >= 4 ? 1.24 : 1.0)
            for side in [-1.0, 1.0] {
                let s = CGFloat(side)
                var wing = Path()
                wing.move(to: CGPoint(x: (66 + s * 18) * sx, y: 70 * sy))
                wing.addQuadCurve(
                    to: CGPoint(x: (66 + s * (46 * wingScale)) * sx, y: (42 - flap - (stage >= 4 ? 7 : 0)) * sy),
                    control: CGPoint(x: (66 + s * (44 * wingScale)) * sx, y: 66 * sy)
                )
                wing.addLine(to: CGPoint(x: (66 + s * (38 * wingScale)) * sx, y: (58 - flap * 0.5) * sy))
                wing.addLine(to: CGPoint(x: (66 + s * (30 * wingScale)) * sx, y: (50 - flap * 0.4) * sy))
                wing.addLine(to: CGPoint(x: (66 + s * 19) * sx, y: 58 * sy))
                wing.closeSubpath()
                let wingColor = stage >= 5 ? Color(hex: "#FFD166") : acc
                context.fill(wing, with: .linearGradient(Gradient(colors: [wingColor, c2.opacity(0.9)]), startPoint: CGPoint(x: 66 * sx, y: 66 * sy), endPoint: CGPoint(x: (66 + s * 48) * sx, y: 40 * sy)))
                context.stroke(wing, with: .color(stage >= 4 ? Color.white : ink.opacity(0.28)), lineWidth: 1.5 * sx)
            }

        case .phoenix:
            // 3 根飘逸长凤尾羽 + 阶进烈焰羽翼
            for i in [-1, 0, 1] {
                let dx = CGFloat(i) * 11.0
                let len = (i == 0 ? 28.0 : 23.0) + (stage >= 4 ? 6.0 : 0.0)
                var feather = Path()
                feather.move(to: CGPoint(x: 66 * sx, y: 88 * sy))
                feather.addQuadCurve(
                    to: CGPoint(x: (66 + dx * 1.4 + sway * 0.5) * sx, y: (86 + len) * sy),
                    control: CGPoint(x: (66 + dx * 0.6) * sx, y: (94 + len * 0.5) * sy)
                )
                context.stroke(feather, with: .color(i == 0 ? Color(hex: "#FFD166") : acc), style: StrokeStyle(lineWidth: 4.5 * sx, lineCap: .round))
                let tipDot = Circle().path(in: CGRect(x: (63 + dx * 1.4 + sway * 0.5) * sx, y: (83 + len) * sy, width: 6 * sx, height: 6 * sy))
                context.fill(tipDot, with: .color(c2))
            }
            let wingSpan: CGFloat = stage == 1 ? 0.78 : (stage >= 4 ? 1.25 : 1.02)
            for side in [-1.0, 1.0] {
                let s = CGFloat(side)
                var wPath = Path()
                wPath.move(to: CGPoint(x: (66 + s * 17) * sx, y: 68 * sy))
                wPath.addQuadCurve(
                    to: CGPoint(x: (66 + s * 48 * wingSpan) * sx, y: (38 - flap) * sy),
                    control: CGPoint(x: (66 + s * 46 * wingSpan) * sx, y: 64 * sy)
                )
                wPath.addQuadCurve(
                    to: CGPoint(x: (66 + s * 32 * wingSpan) * sx, y: (56 - flap * 0.4) * sy),
                    control: CGPoint(x: (66 + s * 40 * wingSpan) * sx, y: 52 * sy)
                )
                wPath.addQuadCurve(
                    to: CGPoint(x: (66 + s * 17) * sx, y: 56 * sy),
                    control: CGPoint(x: (66 + s * 28 * wingSpan) * sx, y: 46 * sy)
                )
                wPath.closeSubpath()
                context.fill(wPath, with: .linearGradient(Gradient(colors: [c1, c2, stage >= 5 ? Color.white : acc]), startPoint: CGPoint(x: 66 * sx, y: 68 * sy), endPoint: CGPoint(x: (66 + s * 50) * sx, y: 36 * sy)))
                context.stroke(wPath, with: .color(Color.white.opacity(stage >= 4 ? 0.9 : 0.4)), lineWidth: 1.4 * sx)
            }

        case .owlDoctor:
            // 猫头鹰羽毛双翼（Lv.4-5 升级紫金流光大翼）
            let span: CGFloat = stage >= 4 ? 1.20 : 1.0
            for side in [-1.0, 1.0] {
                let s = CGFloat(side)
                var owlWing = Path()
                owlWing.move(to: CGPoint(x: (66 + s * 22) * sx, y: 62 * sy))
                owlWing.addQuadCurve(
                    to: CGPoint(x: (66 + s * 41 * span) * sx, y: (76 - flap * 0.55) * sy),
                    control: CGPoint(x: (66 + s * 43 * span) * sx, y: 56 * sy)
                )
                owlWing.addQuadCurve(
                    to: CGPoint(x: (66 + s * 20) * sx, y: 84 * sy),
                    control: CGPoint(x: (66 + s * 32 * span) * sx, y: 88 * sy)
                )
                owlWing.closeSubpath()
                context.fill(owlWing, with: .color(stage >= 4 ? Color(hex: "#9B6EF3") : c1.opacity(0.92)))
                context.stroke(owlWing, with: .color(stage >= 4 ? Color(hex: "#FFD166") : c2), lineWidth: 1.6 * sx)
            }

        case .nineTailFox:
            // 阶进九尾扇形大尾：Lv.1=3尾, Lv.2=5尾, Lv.3+=9尾！
            let tailCount = stage >= 3 ? 9 : (stage == 2 ? 5 : 3)
            let half = (tailCount - 1) / 2
            for idx in (-half)...half {
                let angleDeg = Double(idx) * (stage >= 3 ? 17.5 : 25.0) + Double(sway * 0.8)
                let rad = angleDeg * Double.pi / 180.0
                let dist: Double = stage >= 3 ? 33.0 : 27.0
                let tx = 66.0 + sin(rad) * dist
                let ty = 74.0 - cos(rad) * (dist * 0.72)

                context.drawLayer { tailCtx in
                    tailCtx.translateBy(x: tx * sx, y: ty * sy)
                    tailCtx.rotate(by: .radians(rad))
                    let tailOval = Ellipse().path(in: CGRect(x: -7.5 * sx, y: -15 * sy, width: 15 * sx, height: 28 * sy))
                    tailCtx.fill(tailOval, with: .color(c1))
                    tailCtx.stroke(tailOval, with: .color(Color.white.opacity(0.5)), lineWidth: 0.9 * sx)
                    let tipOval = Ellipse().path(in: CGRect(x: -5.2 * sx, y: -15 * sy, width: 10.4 * sx, height: 10 * sy))
                    tailCtx.fill(tipOval, with: .color(stage >= 4 ? Color(hex: "#FFD166") : c2))
                }
            }

        case .unicorn:
            // 独角兽蓬松彩虹长尾
            var uTail = Path()
            uTail.move(to: CGPoint(x: 84 * sx, y: 78 * sy))
            uTail.addQuadCurve(to: CGPoint(x: (104 + sway * 0.6) * sx, y: 86 * sy), control: CGPoint(x: 102 * sx, y: 66 * sy))
            uTail.addQuadCurve(to: CGPoint(x: (86 + sway * 0.3) * sx, y: 92 * sy), control: CGPoint(x: 98 * sx, y: 96 * sy))
            uTail.closeSubpath()
            context.fill(uTail, with: .linearGradient(Gradient(colors: [c2, acc, Color(hex: "#4CC9F0")]), startPoint: CGPoint(x: 84 * sx, y: 78 * sy), endPoint: CGPoint(x: 106 * sx, y: 92 * sy)))

        case .whale:
            // 云海小蓝鲸：双弧彩虹水柱 + 漂浮气泡
            let jetHeight = 14.0 + (animated ? abs(sin(t * 2.5)) * 5.0 * motionAmp : 0.0)
            var spoutL = Path()
            spoutL.move(to: CGPoint(x: 62 * sx, y: 42 * sy))
            spoutL.addQuadCurve(to: CGPoint(x: 42 * sx, y: (38 - jetHeight) * sy), control: CGPoint(x: 56 * sx, y: (28 - jetHeight) * sy))
            var spoutR = Path()
            spoutR.move(to: CGPoint(x: 62 * sx, y: 42 * sy))
            spoutR.addQuadCurve(to: CGPoint(x: 82 * sx, y: (38 - jetHeight) * sy), control: CGPoint(x: 68 * sx, y: (28 - jetHeight) * sy))
            context.stroke(spoutL, with: .color(Color(hex: "#4CC9F0")), style: StrokeStyle(lineWidth: 3.0 * sx, lineCap: .round))
            context.stroke(spoutR, with: .color(Color(hex: "#90E0EF")), style: StrokeStyle(lineWidth: 3.0 * sx, lineCap: .round))
            for bx in [38.0, 46.0, 78.0, 86.0] {
                let bRect = CGRect(x: bx * sx, y: (34 - jetHeight) * sy, width: 4.5 * sx, height: 4.5 * sy)
                context.fill(Circle().path(in: bRect), with: .color(Color.white.opacity(0.9)))
            }

        case .azureDragon:
            // 东海青龙：S 型祥云底托
            for (cx, cy, cw) in [(32.0, 84.0, 26.0), (96.0, 82.0, 26.0), (66.0, 92.0, 42.0)] {
                let cloud = Capsule().path(in: CGRect(x: (cx - cw * 0.5) * sx, y: cy * sy, width: cw * sx, height: 11 * sy))
                context.fill(cloud, with: .color(Color.white.opacity(0.92)))
                context.stroke(cloud, with: .color(c2.opacity(0.75)), lineWidth: 1.2 * sx)
            }

        case .moonRabbit:
            // 侧面圆滚滚雪白兔尾巴
            let tail = Circle().path(in: CGRect(x: 84 * sx, y: 78 * sy, width: 12 * sx, height: 12 * sy))
            context.fill(tail, with: .color(.white))
            context.stroke(tail, with: .color(c1.opacity(0.4)), lineWidth: 1.2 * sx)

        case .luckyCat:
            // 翘起的小猫尾巴
            var catTail = Path()
            catTail.move(to: CGPoint(x: 86 * sx, y: 86 * sy))
            catTail.addQuadCurve(to: CGPoint(x: (102 + sway * 0.4) * sx, y: 64 * sy), control: CGPoint(x: 103 * sx, y: 84 * sy))
            context.stroke(catTail, with: .color(c1), style: StrokeStyle(lineWidth: 5.5 * sx, lineCap: .round))

        case .corgiPilot:
            // 迎风飘扬的飞行员红色领巾尾端
            var scarfTail = Path()
            scarfTail.move(to: CGPoint(x: 80 * sx, y: 72 * sy))
            scarfTail.addQuadCurve(to: CGPoint(x: (104 + sway * 0.5) * sx, y: (66 - sway * 0.3) * sy), control: CGPoint(x: 94 * sx, y: 75 * sy))
            scarfTail.addLine(to: CGPoint(x: (101 + sway * 0.4) * sx, y: (73 - sway * 0.2) * sy))
            scarfTail.closeSubpath()
            context.fill(scarfTail, with: .color(Color(hex: "#E63946")))

        case .pandaChef, .auroraDeer:
            break
        }
    }

    // MARK: - 4. 12 种神兽独立解剖轮廓（耳朵/角/鬓毛/躯干/四肢/五官）
    private func drawSpeciesBodyAndHead(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        t: Double,
        motionAmp: CGFloat,
        c1: Color,
        c2: Color,
        acc: Color,
        ink: Color
    ) {
        let wave = animated ? CGFloat(sin(t * 3.5)) * 3.0 * motionAmp : 0.0

        switch species.kind {
        case .fireDragon:
            // 梨形龙身 + 圆龙首 + 弯曲双角 + 锯齿背鳍 + 龙吻鼻孔
            drawHornsPair(context: &context, sx: sx, sy: sy, leftBase: (52, 42), leftTip: (41, 24), rightBase: (80, 42), rightTip: (91, 24), color: Color(hex: "#FFD166"), width: 4.4)
            let body = Ellipse().path(in: CGRect(x: 43 * sx, y: 62 * sy, width: 46 * sx, height: 37 * sy))
            context.fill(body, with: .linearGradient(Gradient(colors: [c1, acc]), startPoint: CGPoint(x: 66 * sx, y: 62 * sy), endPoint: CGPoint(x: 66 * sx, y: 99 * sy)))
            context.stroke(body, with: .color(ink.opacity(0.24)), lineWidth: 1.8 * sx)
            // 龙腹横纹肚皮
            let belly = Ellipse().path(in: CGRect(x: 52 * sx, y: 69 * sy, width: 28 * sx, height: 26 * sy))
            context.fill(belly, with: .color(c2.opacity(0.92)))
            for rowY in [76.0, 82.0, 88.0] {
                var rib = Path()
                rib.move(to: CGPoint(x: 56 * sx, y: rowY * sy))
                rib.addQuadCurve(to: CGPoint(x: 76 * sx, y: rowY * sy), control: CGPoint(x: 66 * sx, y: (rowY + 2) * sy))
                context.stroke(rib, with: .color(acc.opacity(0.45)), lineWidth: 1.2 * sx)
            }
            // 圆润龙首
            let head = RoundedRectangle(cornerRadius: 20 * sx).path(in: CGRect(x: 42 * sx, y: 36 * sy, width: 48 * sx, height: 37 * sy))
            context.fill(head, with: .color(c1))
            context.stroke(head, with: .color(ink.opacity(0.24)), lineWidth: 1.8 * sx)
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 51, lx: 54, rx: 78, ink: ink, blushColor: Color(hex: "#FF758F"))
            // 龙吻小鼻孔与小虎牙微笑
            for nx in [62.0, 69.0] {
                context.fill(Circle().path(in: CGRect(x: nx * sx, y: 57 * sy, width: 2.2 * sx, height: 2.2 * sy)), with: .color(ink))
            }
            drawSmile(context: &context, sx: sx, sy: sy, y: 62, ink: ink)
            drawPaws(context: &context, sx: sx, sy: sy, lx: 46, rx: 80, y: 79, color: acc)

        case .unicorn:
            // 独角兽：侧身奔腾小马躯干 + 四蹄 + 彩虹波浪鬃毛 + 螺旋黄金独角
            let body = Capsule().path(in: CGRect(x: 44 * sx, y: 66 * sy, width: 46 * sx, height: 26 * sy))
            context.fill(body, with: .linearGradient(Gradient(colors: [.white, c2.opacity(0.75)]), startPoint: CGPoint(x: 44 * sx, y: 66 * sy), endPoint: CGPoint(x: 90 * sx, y: 92 * sy)))
            context.stroke(body, with: .color(c1.opacity(0.45)), lineWidth: 1.8 * sx)
            // 小蹄腿
            for lx in [48.0, 58.0, 74.0, 82.0] {
                let leg = Capsule().path(in: CGRect(x: lx * sx, y: 85 * sy, width: 6.5 * sx, height: 14 * sy))
                context.fill(leg, with: .color(.white))
                let hoof = Capsule().path(in: CGRect(x: lx * sx, y: 94 * sy, width: 6.5 * sx, height: 5 * sy))
                context.fill(hoof, with: .color(acc))
            }
            // 马耳
            drawPointyEars(context: &context, sx: sx, sy: sy, lx: 47, rx: 77, topY: 26, baseY: 42, outerColor: .white, innerColor: c2)
            // 彩虹流苏鬃毛
            for (idx, hex) in ["#FF758F", "#FFD166", "#A66CFF", "#4CC9F0"].enumerated() {
                let my = 40.0 + CGFloat(idx) * 7.0
                let puff = Circle().path(in: CGRect(x: 72 * sx, y: my * sy, width: 13 * sx, height: 11 * sy))
                context.fill(puff, with: .color(Color(hex: hex)))
            }
            // 小马头
            let head = RoundedRectangle(cornerRadius: 17 * sx).path(in: CGRect(x: 40 * sx, y: 36 * sy, width: 42 * sx, height: 34 * sy))
            context.fill(head, with: .color(.white))
            context.stroke(head, with: .color(c1.opacity(0.45)), lineWidth: 1.8 * sx)
            // 螺旋黄金彩虹独角
            var horn = Path()
            horn.move(to: CGPoint(x: 56 * sx, y: 37 * sy))
            horn.addLine(to: CGPoint(x: 61 * sx, y: (stage >= 3 ? 13 : 18) * sy))
            horn.addLine(to: CGPoint(x: 66 * sx, y: 37 * sy))
            horn.closeSubpath()
            context.fill(horn, with: .linearGradient(Gradient(colors: [Color(hex: "#FFD166"), Color(hex: "#FF758F"), Color(hex: "#4CC9F0")]), startPoint: CGPoint(x: 61 * sx, y: 14 * sy), endPoint: CGPoint(x: 61 * sx, y: 37 * sy)))
            context.stroke(horn, with: .color(Color(hex: "#C8870A")), lineWidth: 1.2 * sx)
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 49, lx: 49, rx: 69, ink: ink, blushColor: c2)
            drawSmile(context: &context, sx: sx, sy: sy, y: 59, cx: 59, ink: ink)

        case .whale:
            // 横向胖嘟嘟云海蓝鲸 + 心形翘尾鳍 + 两侧小鳍 + 微笑大弧嘴
            var tailFin = Path()
            tailFin.move(to: CGPoint(x: 92 * sx, y: 68 * sy))
            tailFin.addQuadCurve(to: CGPoint(x: 110 * sx, y: (50 + wave * 0.4) * sy), control: CGPoint(x: 108 * sx, y: 62 * sy))
            tailFin.addQuadCurve(to: CGPoint(x: 99 * sx, y: 68 * sy), control: CGPoint(x: 100 * sx, y: 58 * sy))
            tailFin.addQuadCurve(to: CGPoint(x: 112 * sx, y: (82 + wave * 0.4) * sy), control: CGPoint(x: 109 * sx, y: 74 * sy))
            tailFin.addQuadCurve(to: CGPoint(x: 92 * sx, y: 74 * sy), control: CGPoint(x: 102 * sx, y: 78 * sy))
            tailFin.closeSubpath()
            context.fill(tailFin, with: .color(c1))

            let whaleBody = RoundedRectangle(cornerRadius: 27 * sx).path(in: CGRect(x: 28 * sx, y: 42 * sy, width: 69 * sx, height: 50 * sy))
            context.fill(whaleBody, with: .linearGradient(Gradient(colors: [c1, Color(hex: "#4CC9F0")]), startPoint: CGPoint(x: 40 * sx, y: 42 * sy), endPoint: CGPoint(x: 86 * sx, y: 92 * sy)))
            context.stroke(whaleBody, with: .color(ink.opacity(0.22)), lineWidth: 1.8 * sx)
            // 奶油条纹鲸肚
            let belly = Ellipse().path(in: CGRect(x: 34 * sx, y: 70 * sy, width: 52 * sx, height: 21 * sy))
            context.fill(belly, with: .color(c2.opacity(0.95)))
            for gx in [44.0, 52.0, 60.0, 68.0] {
                var line = Path()
                line.move(to: CGPoint(x: gx * sx, y: 74 * sy))
                line.addLine(to: CGPoint(x: gx * sx, y: 88 * sy))
                context.stroke(line, with: .color(c1.opacity(0.32)), lineWidth: 1.3 * sx)
            }
            // 小鲸鳍
            var flipper = Path()
            flipper.move(to: CGPoint(x: 46 * sx, y: 74 * sy))
            flipper.addQuadCurve(to: CGPoint(x: 32 * sx, y: (86 + wave * 0.3) * sy), control: CGPoint(x: 34 * sx, y: 76 * sy))
            flipper.addQuadCurve(to: CGPoint(x: 50 * sx, y: 80 * sy), control: CGPoint(x: 42 * sx, y: 87 * sy))
            flipper.closeSubpath()
            context.fill(flipper, with: .color(c1))
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 57, lx: 43, rx: 67, ink: ink, blushColor: Color(hex: "#FF758F"))
            drawSmile(context: &context, sx: sx, sy: sy, y: 65, cx: 55, ink: ink)

        case .nineTailFox:
            // 修长灵动仙狐：白尖狐耳 + 蓬松白胸毛 + 精致狐吻
            drawPointyEars(context: &context, sx: sx, sy: sy, lx: 45, rx: 87, topY: 20, baseY: 42, outerColor: c1, innerColor: c2)
            let body = Ellipse().path(in: CGRect(x: 46 * sx, y: 62 * sy, width: 40 * sx, height: 36 * sy))
            context.fill(body, with: .color(c1))
            let ruff = Ellipse().path(in: CGRect(x: 52 * sx, y: 64 * sy, width: 28 * sx, height: 20 * sy))
            context.fill(ruff, with: .color(.white))
            // 精致倒三角小狐脸
            let head = RoundedRectangle(cornerRadius: 19 * sx).path(in: CGRect(x: 43 * sx, y: 36 * sy, width: 46 * sx, height: 35 * sy))
            context.fill(head, with: .color(c1))
            let cheekWhite = Ellipse().path(in: CGRect(x: 46 * sx, y: 52 * sy, width: 40 * sx, height: 18 * sy))
            context.fill(cheekWhite, with: .color(.white.opacity(0.95)))
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 49, lx: 54, rx: 78, ink: ink, blushColor: Color(hex: "#FF758F"))
            context.fill(Circle().path(in: CGRect(x: 64.5 * sx, y: 56 * sy, width: 3 * sx, height: 2.5 * sy)), with: .color(ink))
            drawSmile(context: &context, sx: sx, sy: sy, y: 60, ink: ink)
            drawPaws(context: &context, sx: sx, sy: sy, lx: 49, rx: 77, y: 84, color: .white)

        case .pandaChef:
            // 功夫熊猫厨神：圆黑耳 + 经典黑眼圈 + 厨师高帽 + 竹青围巾
            context.fill(Circle().path(in: CGRect(x: 38 * sx, y: 27 * sy, width: 16 * sx, height: 16 * sy)), with: .color(ink))
            context.fill(Circle().path(in: CGRect(x: 78 * sx, y: 27 * sy, width: 16 * sx, height: 16 * sy)), with: .color(ink))
            let body = RoundedRectangle(cornerRadius: 24 * sx).path(in: CGRect(x: 41 * sx, y: 60 * sy, width: 50 * sx, height: 38 * sy))
            context.fill(body, with: .color(.white))
            context.stroke(body, with: .color(ink.opacity(0.24)), lineWidth: 1.8 * sx)
            // 黑肩带
            let sash = Capsule().path(in: CGRect(x: 41 * sx, y: 63 * sy, width: 50 * sx, height: 11 * sy))
            context.fill(sash, with: .color(ink))
            // 翡翠绿厨师围巾
            let scarf = Capsule().path(in: CGRect(x: 49 * sx, y: 65 * sy, width: 34 * sx, height: 6.5 * sy))
            context.fill(scarf, with: .color(acc))
            // 圆圆大白头
            let head = RoundedRectangle(cornerRadius: 22 * sx).path(in: CGRect(x: 40 * sx, y: 33 * sy, width: 52 * sx, height: 39 * sy))
            context.fill(head, with: .color(.white))
            context.stroke(head, with: .color(ink.opacity(0.24)), lineWidth: 1.8 * sx)
            // 熊猫黑眼圈 + 亮白星眸
            context.fill(Ellipse().path(in: CGRect(x: 47 * sx, y: 45 * sy, width: 13 * sx, height: 10 * sy)), with: .color(ink))
            context.fill(Ellipse().path(in: CGRect(x: 72 * sx, y: 45 * sy, width: 13 * sx, height: 10 * sy)), with: .color(ink))
            context.fill(Circle().path(in: CGRect(x: 50 * sx, y: 46.5 * sy, width: 6.5 * sx, height: 6.5 * sy)), with: .color(.white))
            context.fill(Circle().path(in: CGRect(x: 75.5 * sx, y: 46.5 * sy, width: 6.5 * sx, height: 6.5 * sy)), with: .color(.white))
            context.fill(Circle().path(in: CGRect(x: 51.8 * sx, y: 48 * sy, width: 3 * sx, height: 3 * sy)), with: .color(ink))
            context.fill(Circle().path(in: CGRect(x: 77.3 * sx, y: 48 * sy, width: 3 * sx, height: 3 * sy)), with: .color(ink))
            drawCheeks(context: &context, sx: sx, sy: sy, y: 56, lx: 46, rx: 80, color: Color(hex: "#FF8FA3"))
            context.fill(Ellipse().path(in: CGRect(x: 63.5 * sx, y: 55 * sy, width: 5 * sx, height: 3.5 * sy)), with: .color(ink))
            drawSmile(context: &context, sx: sx, sy: sy, y: 60, ink: ink)
            // Lv.2+ 厨师高帽
            if stage >= 2 {
                let chefPuff = Capsule().path(in: CGRect(x: 50 * sx, y: 17 * sy, width: 32 * sx, height: 15 * sy))
                context.fill(chefPuff, with: .color(.white))
                context.stroke(chefPuff, with: .color(Color(hex: "#FFD166")), lineWidth: 1.5 * sx)
                let band = RoundedRectangle(cornerRadius: 3 * sx).path(in: CGRect(x: 53 * sx, y: 29 * sy, width: 26 * sx, height: 6 * sy))
                context.fill(band, with: .color(Color(hex: "#FFD166")))
            }
            drawPaws(context: &context, sx: sx, sy: sy, lx: 43, rx: 83, y: 82, color: ink)

        case .moonRabbit:
            // 月桂玉兔：超长垂/翘玉兔双耳 + 饱满白兔身 + 额头新月印
            // 左耳微弯可爱感，右耳挺立
            let earL = Capsule().path(in: CGRect(x: 47 * sx, y: 12 * sy, width: 11 * sx, height: 30 * sy))
            let earR = Capsule().path(in: CGRect(x: 74 * sx, y: 12 * sy, width: 11 * sx, height: 30 * sy))
            context.fill(earL, with: .color(.white))
            context.fill(earR, with: .color(.white))
            context.stroke(earL, with: .color(c1.opacity(0.45)), lineWidth: 1.5 * sx)
            context.stroke(earR, with: .color(c1.opacity(0.45)), lineWidth: 1.5 * sx)
            context.fill(Capsule().path(in: CGRect(x: 49.8 * sx, y: 16 * sy, width: 5.4 * sx, height: 21 * sy)), with: .color(c1.opacity(0.75)))
            context.fill(Capsule().path(in: CGRect(x: 76.8 * sx, y: 16 * sy, width: 5.4 * sx, height: 21 * sy)), with: .color(c1.opacity(0.75)))

            let body = Ellipse().path(in: CGRect(x: 44 * sx, y: 63 * sy, width: 44 * sx, height: 36 * sy))
            context.fill(body, with: .color(.white))
            context.stroke(body, with: .color(c1.opacity(0.42)), lineWidth: 1.6 * sx)
            context.fill(Ellipse().path(in: CGRect(x: 53 * sx, y: 70 * sy, width: 26 * sx, height: 24 * sy)), with: .color(c2))
            let head = RoundedRectangle(cornerRadius: 20 * sx).path(in: CGRect(x: 43 * sx, y: 36 * sy, width: 46 * sx, height: 35 * sy))
            context.fill(head, with: .color(.white))
            context.stroke(head, with: .color(c1.opacity(0.42)), lineWidth: 1.6 * sx)
            // 额头金色新月印
            var crescent = Path()
            crescent.addArc(center: CGPoint(x: 66 * sx, y: 42 * sy), radius: 4 * sx, startAngle: .degrees(30), endAngle: .degrees(210), clockwise: false)
            context.stroke(crescent, with: .color(acc), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 50, lx: 54, rx: 78, ink: ink, blushColor: c1)
            context.fill(Circle().path(in: CGRect(x: 64.5 * sx, y: 56 * sy, width: 3.2 * sx, height: 2.6 * sy)), with: .color(c1))
            drawSmile(context: &context, sx: sx, sy: sy, y: 60, ink: ink)
            drawPaws(context: &context, sx: sx, sy: sy, lx: 46, rx: 80, y: 78, color: c2)

        case .luckyCat:
            // 招财布丁喵：黄金猫耳 + 举起摆动招财右爪 + 金铃铛项圈 + 猫胡须
            drawPointyEars(context: &context, sx: sx, sy: sy, lx: 45, rx: 87, topY: 22, baseY: 42, outerColor: c1, innerColor: Color(hex: "#FFD166"))
            let body = RoundedRectangle(cornerRadius: 21 * sx).path(in: CGRect(x: 44 * sx, y: 62 * sy, width: 44 * sx, height: 36 * sy))
            context.fill(body, with: .color(c2))
            context.stroke(body, with: .color(c1.opacity(0.55)), lineWidth: 1.7 * sx)
            let head = RoundedRectangle(cornerRadius: 20 * sx).path(in: CGRect(x: 42 * sx, y: 36 * sy, width: 48 * sx, height: 35 * sy))
            context.fill(head, with: .linearGradient(Gradient(colors: [c1, c2]), startPoint: CGPoint(x: 66 * sx, y: 36 * sy), endPoint: CGPoint(x: 66 * sx, y: 71 * sy)))
            context.stroke(head, with: .color(ink.opacity(0.22)), lineWidth: 1.7 * sx)
            // 招财赤红项圈 + 金铃铛
            let collar = Capsule().path(in: CGRect(x: 50 * sx, y: 66 * sy, width: 32 * sx, height: 5.5 * sy))
            context.fill(collar, with: .color(acc))
            context.fill(Circle().path(in: CGRect(x: 61.5 * sx, y: 68 * sy, width: 9 * sx, height: 9 * sy)), with: .color(Color(hex: "#FFD166")))
            context.stroke(Circle().path(in: CGRect(x: 61.5 * sx, y: 68 * sy, width: 9 * sx, height: 9 * sy)), with: .color(Color(hex: "#B45309")), lineWidth: 1.3 * sx)
            // 举起挥舞的招财右爪！
            let beckonY = 52.0 - abs(wave) * 1.4
            let beckonArm = Capsule().path(in: CGRect(x: 80 * sx, y: beckonY * sy, width: 9 * sx, height: 18 * sy))
            context.fill(beckonArm, with: .color(.white))
            context.stroke(beckonArm, with: .color(c1), lineWidth: 1.4 * sx)
            // 猫胡须
            for wy in [52.0, 56.0] {
                var wl = Path()
                wl.move(to: CGPoint(x: 44 * sx, y: wy * sy))
                wl.addLine(to: CGPoint(x: 35 * sx, y: (wy - 2) * sy))
                var wr = Path()
                wr.move(to: CGPoint(x: 88 * sx, y: wy * sy))
                wr.addLine(to: CGPoint(x: 97 * sx, y: (wy - 2) * sy))
                context.stroke(wl, with: .color(ink.opacity(0.6)), lineWidth: 1.3 * sx)
                context.stroke(wr, with: .color(ink.opacity(0.6)), lineWidth: 1.3 * sx)
            }
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 49, lx: 54, rx: 78, ink: ink, blushColor: Color(hex: "#FF758F"))
            drawSmile(context: &context, sx: sx, sy: sy, y: 58, ink: ink)

        case .corgiPilot:
            // 飞行员柯基：大圆耳 + 棕皮飞行员帽与护目镜 + 吐司色身白胸毛 + 领巾
            // 圆润大柯基耳
            context.fill(Ellipse().path(in: CGRect(x: 38 * sx, y: 24 * sy, width: 15 * sx, height: 22 * sy)), with: .color(c1))
            context.fill(Ellipse().path(in: CGRect(x: 79 * sx, y: 24 * sy, width: 15 * sx, height: 22 * sy)), with: .color(c1))
            let body = RoundedRectangle(cornerRadius: 20 * sx).path(in: CGRect(x: 43 * sx, y: 63 * sy, width: 46 * sx, height: 34 * sy))
            context.fill(body, with: .color(c1))
            context.fill(Ellipse().path(in: CGRect(x: 53 * sx, y: 68 * sy, width: 26 * sx, height: 26 * sy)), with: .color(.white))
            // 飞行红领巾
            let scarf = Capsule().path(in: CGRect(x: 49 * sx, y: 65 * sy, width: 34 * sx, height: 6.5 * sy))
            context.fill(scarf, with: .color(Color(hex: "#E63946")))
            // 柯基脑袋 + 白色鼻梁
            let head = RoundedRectangle(cornerRadius: 19 * sx).path(in: CGRect(x: 42 * sx, y: 36 * sy, width: 48 * sx, height: 34 * sy))
            context.fill(head, with: .color(c1))
            context.fill(Ellipse().path(in: CGRect(x: 52 * sx, y: 50 * sy, width: 28 * sx, height: 19 * sy)), with: .color(.white))
            // 飞行员皮帽与护目镜
            var cap = Path()
            cap.addArc(center: CGPoint(x: 66 * sx, y: 44 * sy), radius: 22 * sx, startAngle: .degrees(185), endAngle: .degrees(355), clockwise: false)
            cap.closeSubpath()
            context.fill(cap, with: .color(Color(hex: "#6B4226")))
            let strap = Capsule().path(in: CGRect(x: 43 * sx, y: 35 * sy, width: 46 * sx, height: 4.5 * sy))
            context.fill(strap, with: .color(Color(hex: "#362517")))
            for gx in [50.0, 68.0] {
                let lens = RoundedRectangle(cornerRadius: 5 * sx).path(in: CGRect(x: gx * sx, y: 31 * sy, width: 14 * sx, height: 10.5 * sy))
                context.fill(lens, with: .color(Color(hex: "#90E0EF")))
                context.stroke(lens, with: .color(Color(hex: "#FFD166")), lineWidth: 1.8 * sx)
            }
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 50, lx: 54, rx: 78, ink: ink, blushColor: Color(hex: "#FF8FA3"))
            context.fill(Ellipse().path(in: CGRect(x: 63.5 * sx, y: 55 * sy, width: 5 * sx, height: 3.5 * sy)), with: .color(ink))
            drawSmile(context: &context, sx: sx, sy: sy, y: 60, ink: ink)
            drawPaws(context: &context, sx: sx, sy: sy, lx: 46, rx: 80, y: 84, color: .white)

        case .owlDoctor:
            // 智慧猫头鹰：椭圆羽体 + V形眉羽 + 金边圆眼镜 + 橙色小喙 + 博士学士帽
            let body = Ellipse().path(in: CGRect(x: 41 * sx, y: 36 * sy, width: 50 * sx, height: 61 * sy))
            context.fill(body, with: .linearGradient(Gradient(colors: [c1, Color(hex: "#5A189A")]), startPoint: CGPoint(x: 66 * sx, y: 36 * sy), endPoint: CGPoint(x: 66 * sx, y: 97 * sy)))
            context.stroke(body, with: .color(c2), lineWidth: 1.8 * sx)
            let chest = Ellipse().path(in: CGRect(x: 50 * sx, y: 60 * sy, width: 32 * sx, height: 32 * sy))
            context.fill(chest, with: .color(c2.opacity(0.9)))
            // V形耳羽簇
            var brow = Path()
            brow.move(to: CGPoint(x: 42 * sx, y: 37 * sy))
            brow.addLine(to: CGPoint(x: 66 * sx, y: 47 * sy))
            brow.addLine(to: CGPoint(x: 90 * sx, y: 37 * sy))
            context.stroke(brow, with: .color(c2), style: StrokeStyle(lineWidth: 3.2 * sx, lineCap: .round))
            // 博士学士帽
            var mortar = Path()
            mortar.move(to: CGPoint(x: 66 * sx, y: 20 * sy))
            mortar.addLine(to: CGPoint(x: 90 * sx, y: 29 * sy))
            mortar.addLine(to: CGPoint(x: 66 * sx, y: 37 * sy))
            mortar.addLine(to: CGPoint(x: 42 * sx, y: 29 * sy))
            mortar.closeSubpath()
            context.fill(mortar, with: .color(ink))
            context.stroke(mortar, with: .color(acc), lineWidth: 1.4 * sx)
            var tassel = Path()
            tassel.move(to: CGPoint(x: 86 * sx, y: 30 * sy))
            tassel.addLine(to: CGPoint(x: 88 * sx, y: 42 * sy))
            context.stroke(tassel, with: .color(acc), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))
            // 圆眼镜 + 猫头鹰大眼睛
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 50, lx: 55, rx: 77, ink: ink, blushColor: Color(hex: "#FF9F1C"))
            context.stroke(Circle().path(in: CGRect(x: 48 * sx, y: 44.5 * sy, width: 14 * sx, height: 14 * sy)), with: .color(acc), lineWidth: 1.8 * sx)
            context.stroke(Circle().path(in: CGRect(x: 70 * sx, y: 44.5 * sy, width: 14 * sx, height: 14 * sy)), with: .color(acc), lineWidth: 1.8 * sx)
            // 菱形小尖嘴
            var beak = Path()
            beak.move(to: CGPoint(x: 63 * sx, y: 54 * sy))
            beak.addLine(to: CGPoint(x: 69 * sx, y: 54 * sy))
            beak.addLine(to: CGPoint(x: 66 * sx, y: 60 * sy))
            beak.closeSubpath()
            context.fill(beak, with: .color(Color(hex: "#FF9F1C")))

        case .auroraDeer:
            // 极光梅花鹿：侧向展开鹿耳 + 分叉开花水晶鹿角 + 梅花点斑 + 优雅小鹿身
            // 分叉开花鹿角（随阶位开出更多晶花）
            drawDeerAntlers(context: &context, sx: sx, sy: sy, acc: acc)
            // 侧伸小鹿耳
            context.fill(Ellipse().path(in: CGRect(x: 34 * sx, y: 36 * sy, width: 14 * sx, height: 8 * sy)), with: .color(c1))
            context.fill(Ellipse().path(in: CGRect(x: 84 * sx, y: 36 * sy, width: 14 * sx, height: 8 * sy)), with: .color(c1))
            let body = RoundedRectangle(cornerRadius: 19 * sx).path(in: CGRect(x: 46 * sx, y: 63 * sy, width: 40 * sx, height: 34 * sy))
            context.fill(body, with: .color(c1))
            context.fill(Ellipse().path(in: CGRect(x: 56 * sx, y: 68 * sy, width: 20 * sx, height: 24 * sy)), with: .color(c2))
            // 梅花斑点
            for (dx, dy) in [(51.0, 74.0), (80.0, 76.0), (53.0, 84.0), (78.0, 86.0)] {
                context.fill(Circle().path(in: CGRect(x: dx * sx, y: dy * sy, width: 4 * sx, height: 4 * sy)), with: .color(.white.opacity(0.9)))
            }
            let head = RoundedRectangle(cornerRadius: 19 * sx).path(in: CGRect(x: 43 * sx, y: 36 * sy, width: 46 * sx, height: 34 * sy))
            context.fill(head, with: .color(c1))
            context.stroke(head, with: .color(ink.opacity(0.22)), lineWidth: 1.6 * sx)
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 50, lx: 54, rx: 78, ink: ink, blushColor: Color(hex: "#FF8FA3"))
            context.fill(Circle().path(in: CGRect(x: 64 * sx, y: 56 * sy, width: 4 * sx, height: 3 * sy)), with: .color(ink))
            drawSmile(context: &context, sx: sx, sy: sy, y: 60, ink: ink)

        case .phoenix:
            // 朝阳小凤凰：三羽凤冠翎毛 + 修长羽胸 + 金色灵鸟喙
            for (dx, topY, col) in [(-7.0, 21.0, c1), (0.0, 14.0, Color(hex: "#FFD166")), (7.0, 21.0, acc)] {
                var plume = Path()
                plume.move(to: CGPoint(x: 66 * sx, y: 38 * sy))
                plume.addQuadCurve(to: CGPoint(x: (66 + dx * 1.4) * sx, y: topY * sy), control: CGPoint(x: (66 + dx * 0.4) * sx, y: (topY + 8) * sy))
                context.stroke(plume, with: .color(col), style: StrokeStyle(lineWidth: 3.4 * sx, lineCap: .round))
                context.fill(Circle().path(in: CGRect(x: (63.5 + dx * 1.4) * sx, y: (topY - 2.5) * sy, width: 5 * sx, height: 5 * sy)), with: .color(Color(hex: "#FFD166")))
            }
            let body = Ellipse().path(in: CGRect(x: 45 * sx, y: 60 * sy, width: 42 * sx, height: 36 * sy))
            context.fill(body, with: .linearGradient(Gradient(colors: [c1, acc]), startPoint: CGPoint(x: 66 * sx, y: 60 * sy), endPoint: CGPoint(x: 66 * sx, y: 96 * sy)))
            context.fill(Ellipse().path(in: CGRect(x: 54 * sx, y: 66 * sy, width: 24 * sx, height: 24 * sy)), with: .color(c2))
            let head = Circle().path(in: CGRect(x: 45 * sx, y: 36 * sy, width: 42 * sx, height: 36 * sy))
            context.fill(head, with: .color(c1))
            context.stroke(head, with: .color(Color(hex: "#FFD166")), lineWidth: 1.5 * sx)
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 50, lx: 55, rx: 77, ink: ink, blushColor: Color(hex: "#FF758F"))
            var beak = Path()
            beak.move(to: CGPoint(x: 63 * sx, y: 54 * sy))
            beak.addLine(to: CGPoint(x: 69 * sx, y: 54 * sy))
            beak.addLine(to: CGPoint(x: 66 * sx, y: 60 * sy))
            beak.closeSubpath()
            context.fill(beak, with: .color(Color(hex: "#FFD166")))

        case .azureDragon:
            // 祥云小青龙：S 形盘云东方龙身 + 分叉黄金龙角 + 龙须 + 手捧金龙珠
            drawDeerAntlers(context: &context, sx: sx, sy: sy, acc: acc, isDragonHorn: true)
            // S形盘旋青龙躯干
            var dragonBody = Path()
            dragonBody.move(to: CGPoint(x: 66 * sx, y: 60 * sy))
            dragonBody.addCurve(
                to: CGPoint(x: 66 * sx, y: 90 * sy),
                control1: CGPoint(x: 42 * sx, y: 74 * sy),
                control2: CGPoint(x: 92 * sx, y: 78 * sy)
            )
            context.stroke(dragonBody, with: .color(c1), style: StrokeStyle(lineWidth: 20 * sx, lineCap: .round))
            context.stroke(dragonBody, with: .color(c2), style: StrokeStyle(lineWidth: 10 * sx, lineCap: .round))
            // 龙头
            let head = RoundedRectangle(cornerRadius: 18 * sx).path(in: CGRect(x: 43 * sx, y: 36 * sy, width: 46 * sx, height: 33 * sy))
            context.fill(head, with: .color(c1))
            context.stroke(head, with: .color(ink.opacity(0.22)), lineWidth: 1.7 * sx)
            // 飘逸金色龙须
            for side in [-1.0, 1.0] {
                let s = CGFloat(side)
                var whisker = Path()
                whisker.move(to: CGPoint(x: (66 + s * 16) * sx, y: 56 * sy))
                whisker.addQuadCurve(
                    to: CGPoint(x: (66 + s * 32) * sx, y: (62 + wave * 0.4) * sy),
                    control: CGPoint(x: (66 + s * 26) * sx, y: 50 * sy)
                )
                context.stroke(whisker, with: .color(acc), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))
            }
            drawCuteEyesAndCheeks(context: &context, sx: sx, sy: sy, eyeY: 48, lx: 54, rx: 78, ink: ink, blushColor: Color(hex: "#FF758F"))
            drawSmile(context: &context, sx: sx, sy: sy, y: 58, ink: ink)
            // 发光金龙珠
            let pearl = Circle().path(in: CGRect(x: 61 * sx, y: 72 * sy, width: 10 * sx, height: 10 * sy))
            context.fill(pearl, with: .radialGradient(Gradient(colors: [.white, Color(hex: "#FFD166"), acc]), center: CGPoint(x: 65 * sx, y: 76 * sy), startRadius: 0.5 * sx, endRadius: 6 * sx))
        }
    }

    // MARK: - 5. 阶位专属装饰与皇冠演化（Lv.1 → Lv.5 巨大蜕变）
    private func drawStageAccessories(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        t: Double,
        c1: Color,
        c2: Color,
        acc: Color
    ) {
        // Lv.1 萌芽幼崽：可爱头顶小嫩芽/粉嫩蝴蝶结
        if stage == 1 {
            var stem = Path()
            stem.move(to: CGPoint(x: 66 * sx, y: 36 * sy))
            stem.addQuadCurve(to: CGPoint(x: 68 * sx, y: 26 * sy), control: CGPoint(x: 64 * sx, y: 30 * sy))
            context.stroke(stem, with: .color(Color(hex: "#52B788")), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))
            let leafL = Ellipse().path(in: CGRect(x: 60 * sx, y: 23 * sy, width: 8 * sx, height: 5 * sy))
            let leafR = Ellipse().path(in: CGRect(x: 67 * sx, y: 22 * sy, width: 8 * sx, height: 5 * sy))
            context.fill(leafL, with: .color(Color(hex: "#74C69D")))
            context.fill(leafR, with: .color(Color(hex: "#52B788")))
            return
        }

        // Lv.2+ 闪耀灵兽：星光吊坠 + 腮红星纹
        if stage >= 2 {
            // 腮红旁闪烁小星纹
            drawMiniStar(context: &context, center: CGPoint(x: 47 * sx, y: 58 * sy), radius: 2.8 * sx, color: Color(hex: "#FFD166"))
            drawMiniStar(context: &context, center: CGPoint(x: 85 * sx, y: 58 * sy), radius: 2.8 * sx, color: Color(hex: "#FFD166"))

            // 胸前星光吊坠
            if stage < 4 {
                let pendant = Circle().path(in: CGRect(x: 62 * sx, y: 69 * sy, width: 8 * sx, height: 8 * sy))
                context.fill(pendant, with: .color(Color(hex: "#FFD166")))
                context.stroke(pendant, with: .color(.white), lineWidth: 1.2 * sx)
            }
        }

        // Lv.3 星辉圣兽：新月额饰
        if stage == 3 {
            let gem = Circle().path(in: CGRect(x: 62.5 * sx, y: 38 * sy, width: 7 * sx, height: 7 * sy))
            context.fill(gem, with: .color(Color(hex: "#4CC9F0")))
            context.stroke(gem, with: .color(Color(hex: "#FFD166")), lineWidth: 1.5 * sx)
        }

        // Lv.4+ 皇冠神兽 & Lv.5 至尊幻兽：金丝宝石皇冠 / 星系王冠 + 宝石项圈
        if stage >= 4 {
            let crownY: CGFloat = (species.kind == .pandaChef) ? 16.0 : 28.0
            var crown = Path()
            crown.move(to: CGPoint(x: 51 * sx, y: crownY * sy))
            crown.addLine(to: CGPoint(x: 47 * sx, y: (crownY - 12) * sy))
            crown.addLine(to: CGPoint(x: 57 * sx, y: (crownY - 6) * sy))
            crown.addLine(to: CGPoint(x: 66 * sx, y: (crownY - 16) * sy))
            crown.addLine(to: CGPoint(x: 75 * sx, y: (crownY - 6) * sy))
            crown.addLine(to: CGPoint(x: 85 * sx, y: (crownY - 12) * sy))
            crown.addLine(to: CGPoint(x: 81 * sx, y: crownY * sy))
            crown.closeSubpath()

            context.fill(
                crown,
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#FFF3B0"), Color(hex: "#FFD166"), Color(hex: "#F59E0B")]),
                    startPoint: CGPoint(x: 66 * sx, y: (crownY - 16) * sy),
                    endPoint: CGPoint(x: 66 * sx, y: crownY * sy)
                )
            )
            context.stroke(crown, with: .color(Color(hex: "#B45309")), lineWidth: 1.5 * sx)

            // 皇冠宝石
            let mainGemColor = stage >= 5 ? Color(hex: "#4CC9F0") : Color(hex: "#E63946")
            let gem = Circle().path(in: CGRect(x: 63 * sx, y: (crownY - 9) * sy, width: 6 * sx, height: 6 * sy))
            context.fill(gem, with: .color(mainGemColor))
            context.stroke(gem, with: .color(.white), lineWidth: 1.0 * sx)

            // Lv.5 星系王冠外拱星环
            if stage >= 5 {
                var halo = Path()
                halo.addArc(
                    center: CGPoint(x: 66 * sx, y: (crownY - 13) * sy),
                    radius: 17 * sx,
                    startAngle: .degrees(200),
                    endAngle: .degrees(340),
                    clockwise: false
                )
                context.stroke(halo, with: .color(Color(hex: "#FFF3B0").opacity(0.95)), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))
            }

            // 胸前宝石项圈
            let collarGem = Circle().path(in: CGRect(x: 61 * sx, y: 69 * sy, width: 10 * sx, height: 10 * sy))
            context.fill(collarGem, with: .color(stage >= 5 ? Color(hex: "#4CC9F0") : Color(hex: "#FF5D8F")))
            context.stroke(collarGem, with: .color(Color(hex: "#FFD166")), lineWidth: 1.7 * sx)
        }
    }

    // MARK: - 6. 阶位前景环绕星点与 Lv.5 公转星辰
    private func drawStageForegroundStars(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        t: Double,
        c1: Color,
        c2: Color,
        acc: Color
    ) {
        guard stage >= 3 else { return }

        let count = stage >= 5 ? 6 : (stage == 4 ? 4 : 3)
        let orbitR: CGFloat = stage >= 5 ? 55.0 : 48.0
        let palette: [Color] = [
            Color(hex: "#FFD166"),
            Color(hex: "#FF758F"),
            Color(hex: "#4CC9F0"),
            Color(hex: "#A66CFF"),
            Color(hex: "#8AC926"),
            Color(hex: "#FFF3B0")
        ]

        for i in 0..<count {
            let phase = Double(i) * (Double.pi * 2.0 / Double(count)) + t * (stage >= 5 ? 1.1 : 0.75)
            let px = 66.0 + CGFloat(cos(phase)) * orbitR
            let py = 68.0 + CGFloat(sin(phase)) * (orbitR * 0.85)
            let starR: CGFloat = (stage >= 5 && i % 2 == 0) ? 4.4 : 3.2
            drawMiniStar(
                context: &context,
                center: CGPoint(x: px * sx, y: py * sy),
                radius: starR * sx,
                color: palette[i % palette.count]
            )
        }
    }

    // MARK: - 通用矢量绘图小助手
    private func drawPointyEars(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        lx: CGFloat,
        rx: CGFloat,
        topY: CGFloat,
        baseY: CGFloat,
        outerColor: Color,
        innerColor: Color
    ) {
        var earL = Path()
        earL.move(to: CGPoint(x: (lx - 4) * sx, y: baseY * sy))
        earL.addLine(to: CGPoint(x: (lx - 6) * sx, y: topY * sy))
        earL.addLine(to: CGPoint(x: (lx + 11) * sx, y: (baseY - 6) * sy))
        earL.closeSubpath()

        var earR = Path()
        earR.move(to: CGPoint(x: (rx + 4) * sx, y: baseY * sy))
        earR.addLine(to: CGPoint(x: (rx + 6) * sx, y: topY * sy))
        earR.addLine(to: CGPoint(x: (rx - 11) * sx, y: (baseY - 6) * sy))
        earR.closeSubpath()

        context.fill(earL, with: .color(outerColor))
        context.fill(earR, with: .color(outerColor))

        var inL = Path()
        inL.move(to: CGPoint(x: (lx - 1) * sx, y: (baseY - 3) * sy))
        inL.addLine(to: CGPoint(x: (lx - 3) * sx, y: (topY + 5) * sy))
        inL.addLine(to: CGPoint(x: (lx + 7) * sx, y: (baseY - 6) * sy))
        inL.closeSubpath()

        var inR = Path()
        inR.move(to: CGPoint(x: (rx + 1) * sx, y: (baseY - 3) * sy))
        inR.addLine(to: CGPoint(x: (rx + 3) * sx, y: (topY + 5) * sy))
        inR.addLine(to: CGPoint(x: (rx - 7) * sx, y: (baseY - 6) * sy))
        inR.closeSubpath()

        context.fill(inL, with: .color(innerColor))
        context.fill(inR, with: .color(innerColor))
    }

    private func drawHornsPair(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        leftBase: (CGFloat, CGFloat),
        leftTip: (CGFloat, CGFloat),
        rightBase: (CGFloat, CGFloat),
        rightTip: (CGFloat, CGFloat),
        color: Color,
        width: CGFloat
    ) {
        var hL = Path()
        hL.move(to: CGPoint(x: leftBase.0 * sx, y: leftBase.1 * sy))
        hL.addQuadCurve(to: CGPoint(x: leftTip.0 * sx, y: leftTip.1 * sy), control: CGPoint(x: (leftBase.0 - 8) * sx, y: (leftTip.1 + 6) * sy))
        var hR = Path()
        hR.move(to: CGPoint(x: rightBase.0 * sx, y: rightBase.1 * sy))
        hR.addQuadCurve(to: CGPoint(x: rightTip.0 * sx, y: rightTip.1 * sy), control: CGPoint(x: (rightBase.0 + 8) * sx, y: (rightTip.1 + 6) * sy))
        context.stroke(hL, with: .color(color), style: StrokeStyle(lineWidth: width * sx, lineCap: .round))
        context.stroke(hR, with: .color(color), style: StrokeStyle(lineWidth: width * sx, lineCap: .round))
    }

    private func drawDeerAntlers(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        acc: Color,
        isDragonHorn: Bool = false
    ) {
        let hornColor = isDragonHorn ? Color(hex: "#FFD166") : acc
        for side in [-1.0, 1.0] {
            let s = CGFloat(side)
            var main = Path()
            main.move(to: CGPoint(x: (66 + s * 10) * sx, y: 38 * sy))
            main.addLine(to: CGPoint(x: (66 + s * 20) * sx, y: 18 * sy))
            context.stroke(main, with: .color(hornColor), style: StrokeStyle(lineWidth: 3.2 * sx, lineCap: .round))

            var twig = Path()
            twig.move(to: CGPoint(x: (66 + s * 15) * sx, y: 28 * sy))
            twig.addLine(to: CGPoint(x: (66 + s * 24) * sx, y: 25 * sy))
            context.stroke(twig, with: .color(hornColor), style: StrokeStyle(lineWidth: 2.5 * sx, lineCap: .round))

            // 阶位越高，鹿角开花越多
            if !isDragonHorn && stage >= 2 {
                let flower = Circle().path(in: CGRect(x: (63.5 + s * 24) * sx, y: 22.5 * sy, width: 5 * sx, height: 5 * sy))
                context.fill(flower, with: .color(Color(hex: "#FF85A1")))
            }
            if !isDragonHorn && stage >= 3 {
                let topCrystal = Circle().path(in: CGRect(x: (63.5 + s * 20) * sx, y: 15 * sy, width: 5.5 * sx, height: 5.5 * sy))
                context.fill(topCrystal, with: .color(Color(hex: "#4CC9F0")))
            }
        }
    }

    private func drawCuteEyesAndCheeks(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        eyeY: CGFloat,
        lx: CGFloat,
        rx: CGFloat,
        ink: Color,
        blushColor: Color
    ) {
        let eyeR: CGFloat = 7.4
        for ex in [lx, rx] {
            let eRect = CGRect(x: (ex - eyeR * 0.5) * sx, y: (eyeY - eyeR * 0.5) * sy, width: eyeR * sx, height: eyeR * sy)
            context.fill(Circle().path(in: eRect), with: .color(ink))
            // 双高光星眸
            let hiMain = CGRect(x: (ex - 2.2) * sx, y: (eyeY - 2.4) * sy, width: 2.8 * sx, height: 2.8 * sy)
            let hiSub = CGRect(x: (ex + 0.8) * sx, y: (eyeY + 0.8) * sy, width: 1.5 * sx, height: 1.5 * sy)
            context.fill(Circle().path(in: hiMain), with: .color(.white))
            context.fill(Circle().path(in: hiSub), with: .color(.white.opacity(0.9)))
        }
        drawCheeks(context: &context, sx: sx, sy: sy, y: eyeY + 6.5, lx: lx - 4, rx: rx + 4, color: blushColor)
    }

    private func drawCheeks(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        y: CGFloat,
        lx: CGFloat,
        rx: CGFloat,
        color: Color
    ) {
        context.fill(Ellipse().path(in: CGRect(x: (lx - 4) * sx, y: (y - 2) * sy, width: 8 * sx, height: 4.5 * sy)), with: .color(color.opacity(0.65)))
        context.fill(Ellipse().path(in: CGRect(x: (rx - 4) * sx, y: (y - 2) * sy, width: 8 * sx, height: 4.5 * sy)), with: .color(color.opacity(0.65)))
    }

    private func drawSmile(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        y: CGFloat,
        cx: CGFloat = 66,
        ink: Color
    ) {
        var mouth = Path()
        mouth.move(to: CGPoint(x: (cx - 4.5) * sx, y: y * sy))
        mouth.addQuadCurve(to: CGPoint(x: cx * sx, y: (y + 3.2) * sy), control: CGPoint(x: (cx - 2.2) * sx, y: (y + 4) * sy))
        mouth.addQuadCurve(to: CGPoint(x: (cx + 4.5) * sx, y: y * sy), control: CGPoint(x: (cx + 2.2) * sx, y: (y + 4) * sy))
        context.stroke(mouth, with: .color(ink), style: StrokeStyle(lineWidth: 1.9 * sx, lineCap: .round, lineJoin: .round))
    }

    private func drawPaws(
        context: inout GraphicsContext,
        sx: CGFloat,
        sy: CGFloat,
        lx: CGFloat,
        rx: CGFloat,
        y: CGFloat,
        color: Color
    ) {
        context.fill(Circle().path(in: CGRect(x: (lx - 4) * sx, y: (y - 4) * sy, width: 8 * sx, height: 8 * sy)), with: .color(color))
        context.fill(Circle().path(in: CGRect(x: (rx - 4) * sx, y: (y - 4) * sy, width: 8 * sx, height: 8 * sy)), with: .color(color))
    }

    private func drawMiniStar(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color
    ) {
        var star = Path()
        for i in 0..<8 {
            let r = (i % 2 == 0) ? radius : radius * 0.42
            let ang = Double(i) * (Double.pi / 4.0)
            let pt = CGPoint(x: center.x + CGFloat(cos(ang)) * r, y: center.y + CGFloat(sin(ang)) * r)
            if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
        }
        star.closeSubpath()
        context.fill(star, with: .color(color))
    }
}
