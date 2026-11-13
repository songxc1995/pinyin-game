import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - 1. 👗 小公主魔法高定衣橱主视图 (PrincessWardrobeTabView)
public struct PrincessWardrobeTabView: View {
    @ObservedObject public var engine: GameEngine
    @State private var selectedItemId: String = "dress_0"
    @State private var twirlTrigger: Int = 0
    @State private var posterFileURL: URL? = nil
    @State private var posterPreviewImage: Image? = nil
    @State private var showPosterSheet: Bool = false

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var currentItems: [PrincessFashionItem] {
        PrincessFashionItem.items(for: engine.selectedWardrobeCategory)
    }

    private var inspectedItem: PrincessFashionItem {
        if let found = PrincessFashionItem.item(for: selectedItemId),
           found.category == engine.selectedWardrobeCategory {
            return found
        }
        return engine.progress.equippedItem(for: engine.selectedWardrobeCategory)
    }

    private var effectivePreviewSuitBonus: SuitBonusInfo {
        let item = inspectedItem
        var itemsByCategory: [PrincessFashionCategory: PrincessFashionItem] = [:]
        for cat in PrincessFashionCategory.allCases {
            itemsByCategory[cat] = (cat == item.category) ? item : engine.progress.equippedItem(for: cat)
        }
        var counts: [Int: Int] = [:]
        for cat in PrincessFashionCategory.allCases {
            if let piece = itemsByCategory[cat] {
                counts[piece.styleIndex, default: 0] += 1
            }
        }
        let dressStyle = itemsByCategory[.dress]?.styleIndex ?? item.styleIndex
        let bestStyle = counts.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            if lhs.key == dressStyle { return false }
            if rhs.key == dressStyle { return true }
            return lhs.key < rhs.key
        }?.key ?? dressStyle
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

    public var body: some View {
        let item = inspectedItem
        let ownedCount = engine.progress.fashionCount(for: item.id)
        let stage = engine.progress.fashionStage(for: item.id)
        let isEquipped = (engine.progress.equippedItem(for: item.category).id == item.id)

        GeometryReader { geo in
            let isWide = geo.size.width >= 820
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    glamourTopBar

                    if let toast = engine.wardrobeToast {
                        toastBannerView(text: toast)
                    }

                    if isWide {
                        HStack(alignment: .top, spacing: 16) {
                            stageColumnView(
                                item: item,
                                ownedCount: ownedCount,
                                stage: stage,
                                isEquipped: isEquipped
                            )
                            .frame(width: min(400, max(320, geo.size.width * 0.38)))

                            studioRightColumnView(
                                item: item,
                                ownedCount: ownedCount,
                                stage: stage,
                                isEquipped: isEquipped
                            )
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        VStack(spacing: 14) {
                            stageColumnView(
                                item: item,
                                ownedCount: ownedCount,
                                stage: stage,
                                isEquipped: isEquipped
                            )

                            studioRightColumnView(
                                item: item,
                                ownedCount: ownedCount,
                                stage: stage,
                                isEquipped: isEquipped
                            )
                        }
                    }

                    wardrobeRackSection
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            selectedItemId = engine.progress.equippedItem(for: engine.selectedWardrobeCategory).id
        }
        .sheet(isPresented: $showPosterSheet) {
            RoyalPosterExportSheet(
                posterImage: posterPreviewImage,
                posterFileURL: posterFileURL,
                suitName: effectivePreviewSuitBonus.suitName,
                glamourScore: engine.progress.totalGlamourScore,
                onDismiss: { showPosterSheet = false }
            )
        }
    }

    // MARK: - 顶部魅力爵位、星光丝线 & 套装共鸣状态条
    private var glamourTopBar: some View {
        let rank = engine.progress.glamourRank
        let suit = engine.progress.suitBonusInfo()
        let score = engine.progress.totalGlamourScore
        let rankColor = Color(hex: rank.frameHex)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 8) {
                    Text(rank.title)
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(rankColor))

                    Text(rank.coinBonus > 0 ? "伴读每题 +\(rank.coinBonus) 🪙" : "魅力 200 开启伴读加币")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#7A3E00"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(hex: "#FFF3C4")))
                }

                Spacer(minLength: 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        statCapsule(icon: "✨", label: "魅力 \(score)", fg: "#6D28D9", bg: "#EFEFFD")
                        statCapsule(icon: "🧵", label: "星光丝线 \(engine.progress.starThread)", fg: "#BE185D", bg: "#FCE7F3")
                        statCapsule(icon: "🪙", label: "\(engine.progress.coins)", fg: "#B45309", bg: "#FEF3C7")
                        statCapsule(icon: "👗", label: "\(engine.progress.unlockedFashionCount)/\(PrincessFashionItem.all.count)", fg: "#2B7F4A", bg: "#E6F7ED")
                    }
                }
            }

            // 距下一级爵位进度条
            if let nextMin = rank.nextMinScore, let nextTitle = rank.nextTitle {
                let span = max(1, nextMin - rank.currentMinScore)
                let ratio = min(1.0, max(0.06, Double(score - rank.currentMinScore) / Double(span)))
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🌟 小公主魅力进阶：\(score) / \(nextMin)（下一级【\(nextTitle)】）")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color(hex: "#4A2E14"))
                        Spacer()
                        Text("差 \(max(0, nextMin - score)) 点")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(rankColor)
                    }
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.08))
                            Capsule()
                                .fill(LinearGradient(colors: [rankColor, Color(hex: "#E05385")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: barGeo.size.width * ratio)
                        }
                    }
                    .frame(height: 7)
                }
            } else {
                Text("👑 已登顶最高魅力爵位【\(rank.title)】，伴读答题每题额外 +\(rank.coinBonus) 🪙！")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B45309"))
            }

            // 🔥 套装共鸣状态条
            HStack(spacing: 8) {
                Text("🔥")
                    .font(.system(size: 14))
                if suit.isFullResonance {
                    Text("【\(suit.suitName)】5/5 全套大共鸣激活！魅力 +\(suit.glamourBonusPercent)% · 专属舞台 · 每题 +\(suit.coinBonus) 🪙")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#9D174D"))
                } else if suit.isHalfResonance {
                    Text("【\(suit.suitName)】\(suit.matchedCount)/5 小共鸣激活（魅力 +\(suit.glamourBonusPercent)%），再穿 \(5 - suit.matchedCount) 件触发全套每题 +\(suit.suit.fullCoinBonus) 🪙！")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#6D28D9"))
                } else {
                    Text("当前搭配【\(suit.suitName)】\(suit.matchedCount)/5 件 · 穿齐同系列 3 件激活小共鸣，5 件解锁专属主题舞台！")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(hex: "#7A624B"))
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(suit.isFullResonance ? Color(hex: "#FCE7F3") : (suit.isHalfResonance ? Color(hex: "#F3E8FF") : Color(hex: "#FAF7F2")))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(rankColor.opacity(0.55), lineWidth: 2))
        )
    }

    private func statCapsule(icon: String, label: String, fg: String, bg: String) -> some View {
        HStack(spacing: 4) {
            Text(icon)
            Text(label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
        }
        .foregroundColor(Color(hex: fg))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color(hex: bg)))
    }

    private func toastBannerView(text: String) -> some View {
        HStack(spacing: 8) {
            Text("✨")
            Text(text)
                .font(.system(size: 12.5, weight: .bold))
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

    // MARK: - 左侧舞台展示区（梦幻舞台 + 点击转圈 + 拍照海报 + 每日舞会主题）
    private func stageColumnView(
        item: PrincessFashionItem,
        ownedCount: Int,
        stage: Int,
        isEquipped: Bool
    ) -> some View {
        let rankColor = Color(hex: engine.progress.glamourRank.frameHex)
        let previewSuit = effectivePreviewSuitBonus
        let theme = DailyBallTheme.today()
        let ballMatch = engine.dailyBallMatchCount(for: theme)
        let glamourNow = engine.progress.totalGlamourScore

        return VStack(spacing: 12) {
            // 舞台标题行
            HStack {
                Text("👑 小公主魔法舞台")
                    .font(.system(size: 15.5, weight: .black))
                    .foregroundColor(Color(hex: "#4A2E14"))
                Spacer()
                Button {
                    engine.audio.sfxSpark()
                    let d = engine.progress.equippedItem(for: .dress)
                    let h = engine.progress.equippedItem(for: .hairTiara)
                    engine.audio.speakText("满满小公主身穿\(d.name)，头戴\(h.name)，魅力值\(engine.progress.totalGlamourScore)分！", slow: false)
                } label: {
                    Text("🔊 语音播报")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#E05385"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color(hex: "#FCE7F3")))
                }
                .buttonStyle(.plain)
            }

            // 核心 T 台画布（点击小公主转圈）
            ZStack {
                PrincessStageBackdropView(
                    stageThemeId: previewSuit.stageThemeId,
                    gentleMotion: engine.progress.eyeCare.gentleMotion
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

                PrincessAvatarVectorView(
                    previewItem: item,
                    previewStage: max(1, stage),
                    progress: engine.progress,
                    size: 222,
                    animated: true,
                    twirlTrigger: twirlTrigger,
                    gentleMotion: engine.progress.eyeCare.gentleMotion
                )

                // 左上角试穿提示 & 右上角恢复穿戴按钮
                VStack {
                    HStack {
                        if !isEquipped {
                            Text(ownedCount > 0 ? "👀 试穿预览" : "🔒 未解锁试穿")
                                .font(.system(size: 10.5, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.black.opacity(0.45)))
                        }
                        Spacer()
                        if !isEquipped {
                            Button {
                                selectedItemId = engine.progress.equippedItem(for: engine.selectedWardrobeCategory).id
                                engine.audio.sfxTap()
                            } label: {
                                Text("↩️ 看穿戴")
                                    .font(.system(size: 10.5, weight: .heavy))
                                    .foregroundColor(Color(hex: "#4A2E14"))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white.opacity(0.92)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Spacer()
                    HStack {
                        Text(previewSuit.suit.stageThemeName)
                            .font(.system(size: 10.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#4A2E14"))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.86)))
                        Spacer()
                        Text("✨ 点公主转圈圈")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color(hex: "#9D174D"))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.86)))
                    }
                }
                .padding(10)
            }
            .frame(height: 264)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(rankColor, lineWidth: 2.5))
            .contentShape(Rectangle())
            .onTapGesture {
                twirlTrigger += 1
                PinyinAudioEngine.shared.sfxTwirl()
            }

            // 舞台互动按钮行：转圈 & 拍照保存海报
            HStack(spacing: 10) {
                Button {
                    twirlTrigger += 1
                    PinyinAudioEngine.shared.sfxTwirl()
                } label: {
                    HStack(spacing: 5) {
                        Text("💃")
                        Text("旋转秀舞姿")
                    }
                    .font(.system(size: 12.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#9D174D"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FCE7F3")))
                }
                .buttonStyle(.plain)

                Button {
                    captureRoyalPoster()
                } label: {
                    HStack(spacing: 5) {
                        Text("📸")
                        Text("拍照保存海报")
                    }
                    .font(.system(size: 12.5, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [Color(hex: "#E05385"), Color(hex: "#7A6EE6")], startPoint: .leading, endPoint: .trailing))
                    )
                }
                .buttonStyle(.plain)
            }

            // 当前穿戴 5 部位矢量速览条
            HStack(spacing: 6) {
                ForEach(PrincessFashionCategory.allCases) { cat in
                    let eq = engine.progress.equippedItem(for: cat)
                    let eqSt = engine.progress.equippedItemStage(for: cat)
                    let on = (engine.selectedWardrobeCategory == cat)
                    Button {
                        engine.selectedWardrobeCategory = cat
                        selectedItemId = eq.id
                        engine.audio.sfxTap()
                    } label: {
                        VStack(spacing: 3) {
                            FashionItemIconVectorView(item: eq, stage: eqSt, size: 30)
                            Text("Lv.\(eqSt)")
                                .font(.system(size: 9.5, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: "#E05385"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(on ? Color(hex: "#FCE7F3") : Color(hex: "#FAF7F2"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(on ? Color(hex: "#E05385") : Color.black.opacity(0.08), lineWidth: 1.4)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // 今天的小舞会主题挑战卡片
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🎭 今天的小舞会主题")
                        .font(.system(size: 13.5, weight: .black))
                        .foregroundColor(Color(hex: "#4A2E14"))
                    Spacer()
                    Text("+\(theme.rewardCoins) 🪙 +\(theme.rewardStarThread) 🧵")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(Color(hex: "#BE185D"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: "#FCE7F3")))
                }

                Text(theme.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Color(hex: "#9D174D"))

                Text(theme.subtitle)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(Color(hex: "#7A624B"))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    ballMetricPill(
                        label: "同主题 \(ballMatch)/\(theme.minMatchingPieces) 件",
                        done: ballMatch >= theme.minMatchingPieces
                    )
                    ballMetricPill(
                        label: "魅力 \(glamourNow)/\(theme.minGlamour)",
                        done: glamourNow >= theme.minGlamour
                    )
                }

                if engine.progress.isDailyBallClaimedToday {
                    Text("✅ 今日小舞会已盛装赴宴领奖！明天换新主题")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#2B7F4A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 11).fill(Color(hex: "#E6F7ED")))
                } else if engine.canClaimDailyBallReward {
                    Button {
                        engine.claimDailyBallReward()
                    } label: {
                        Text("🎉 盛装赴宴 · 领取今日舞会大奖！")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [Color(hex: "#F59E0B"), Color(hex: "#E05385")], startPoint: .leading, endPoint: .trailing))
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        engine.equipFashionSuit(theme.targetStyleIndex)
                    } label: {
                        Text("✨ 一键穿戴对应主题套装部件")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color(hex: "#7A6EE6"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(Color(hex: "#EFEFFD"))
                                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "#7A6EE6").opacity(0.4), lineWidth: 1.2))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#FFF9FB"))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F472B6").opacity(0.45), lineWidth: 1.5))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(rankColor.opacity(0.45), lineWidth: 2))
        )
    }

    private func ballMetricPill(label: String, done: Bool) -> some View {
        HStack(spacing: 4) {
            Text(done ? "✅" : "⏳")
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 11.5, weight: .bold))
        }
        .foregroundColor(done ? Color(hex: "#2B7F4A") : Color(hex: "#7A624B"))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(done ? Color(hex: "#E6F7ED") : Color(hex: "#F4EFE8")))
    }

    // MARK: - 右侧高定工坊台 + 一键套装栏 + 个性妆造栏
    private func studioRightColumnView(
        item: PrincessFashionItem,
        ownedCount: Int,
        stage: Int,
        isEquipped: Bool
    ) -> some View {
        VStack(spacing: 14) {
            inspectedItemInspectorCard(
                item: item,
                ownedCount: ownedCount,
                stage: stage,
                isEquipped: isEquipped
            )

            suitOneTapBarCard

            customizationStudioCard
        }
    }

    private func inspectedItemInspectorCard(
        item: PrincessFashionItem,
        ownedCount: Int,
        stage: Int,
        isEquipped: Bool
    ) -> some View {
        let nextNeed = engine.progress.nextFashionStageNeed(for: item.id)
        let craftCost = PrincessFashionItem.upgradeCraftCost(for: max(1, stage), tier: item.tier)

        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: item.secondaryHex).opacity(0.65))
                        .frame(width: 60, height: 60)
                    FashionItemIconVectorView(item: item, stage: max(1, stage), size: 52)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.system(size: 17.5, weight: .black))
                            .foregroundColor(Color(hex: "#3B2E22"))
                        Text(item.tierName)
                            .font(.system(size: 10.5, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: item.tierColorHex)))
                        if stage > 0 {
                            Text("Lv.\(stage) \(PrincessFashionItem.stageName(for: stage))")
                                .font(.system(size: 10.5, weight: .heavy))
                                .foregroundColor(Color(hex: "#BE185D"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: "#FCE7F3")))
                        }
                    }

                    Text("\(item.category.title) · \(item.subtitle)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }

                Spacer(minLength: 6)

                if ownedCount > 0 {
                    Button {
                        engine.equipFashionItem(item)
                    } label: {
                        Text(isEquipped ? "✓ 穿戴中" : "👗 立即换上")
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(isEquipped ? Color(hex: "#2B7F4A") : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(isEquipped ? Color(hex: "#E6F7ED") : Color(hex: "#E05385")))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 五阶高定阶梯条（可横向滚动不压扁）
            ScrollView(.horizontal, showsIndicators: false) {
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
                        .padding(.horizontal, 9)
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

            Text("✨ \(max(1, stage))阶高定特效：\(PrincessFashionItem.stageVisualPerk(for: max(1, stage)))")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color(hex: "#4A2E14"))
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 11).fill(Color(hex: "#FFF8EE")))

            // 解锁条件 / 升阶进度 & 操作按钮
            if ownedCount == 0 {
                let starsMet = engine.progress.totalStars >= item.needStars
                let coinsMet = engine.progress.coins >= item.costCoins
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ballMetricPill(
                            label: starsMet ? "星数达标 (\(engine.progress.totalStars)/\(item.needStars)★)" : "需累计 \(item.needStars)★ (差 \(item.needStars - engine.progress.totalStars)★)",
                            done: starsMet
                        )
                        ballMetricPill(
                            label: "裁制费 \(item.costCoins) 🪙",
                            done: coinsMet
                        )
                    }

                    HStack(spacing: 10) {
                        Button {
                            engine.unlockOrUpgradeFashionItem(item)
                        } label: {
                            HStack(spacing: 6) {
                                Text("🪡 裁制解锁新装")
                                Text("(\(item.costCoins) 🪙)")
                                    .font(.system(size: 11.5, weight: .bold))
                            }
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        (starsMet && coinsMet)
                                            ? LinearGradient(colors: [Color(hex: "#E05385"), Color(hex: "#7A6EE6")], startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(colors: [Color(hex: "#9CA3AF"), Color(hex: "#6B7280")], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                        }
                        .buttonStyle(.plain)

                        listenItemButton(item: item)
                    }
                }
            } else if let need = nextNeed {
                let prevNeed = PrincessFashionItem.stageThresholds[max(1, min(stage, 4))]
                let span = max(1, need - prevNeed)
                let ratio = min(1.0, max(0.08, Double(ownedCount - prevNeed) / Double(span)))
                VStack(alignment: .leading, spacing: 7) {
                    Text("📈 高定锦缎进度：\(ownedCount) / \(need)（再注入 \(max(0, need - ownedCount)) 次升入 Lv.\(stage + 1) \(PrincessFashionItem.stageName(for: stage + 1))）")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#6D28D9"))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.08))
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: item.primaryHex), Color(hex: "#FFD166")], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * ratio)
                        }
                    }
                    .frame(height: 8)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 185), spacing: 8)], alignment: .leading, spacing: 8) {
                        Button {
                            engine.upgradeFashionWithThread(item)
                        } label: {
                            HStack(spacing: 5) {
                                Text("🧵 星光丝线升阶")
                                Text("(余 \(engine.progress.starThread))")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        engine.progress.starThread > 0
                                            ? LinearGradient(colors: [Color(hex: "#EC4899"), Color(hex: "#8B5CF6")], startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(colors: [Color(hex: "#9CA3AF"), Color(hex: "#6B7280")], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            engine.unlockOrUpgradeFashionItem(item)
                        } label: {
                            HStack(spacing: 5) {
                                Text("🪙 星币织造升阶")
                                Text("(\(craftCost) 🪙)")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: [Color(hex: "#F59E0B"), Color(hex: "#E05385")], startPoint: .leading, endPoint: .trailing))
                            )
                        }
                        .buttonStyle(.plain)

                        listenItemButton(item: item)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Text("🌈 已达最高 5 阶【传世神装】极光星雨形态 ✨")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#E11D48"))
                    Spacer()
                    listenItemButton(item: item)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: item.primaryHex).opacity(0.42), lineWidth: 2))
        )
    }

    private func listenItemButton(item: PrincessFashionItem) -> some View {
        Button {
            engine.audio.sfxTap()
            engine.audio.speakText("\(item.name)，\(item.subtitle)", slow: false)
        } label: {
            Text("🔊 听服饰介绍")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#4A2E14"))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#FFF0D6")))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 一键套装栏（6 大高定套装）
    private var suitOneTapBarCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("👑 六大高定套装 · 一键换装")
                    .font(.system(size: 14.5, weight: .black))
                    .foregroundColor(Color(hex: "#4A2E14"))
                Spacer()
                Text("穿齐 3 件小共鸣 · 5 件全套舞台")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PrincessFashionSuit.all) { suit in
                        let ownedCount = suit.items.filter { engine.progress.fashionCount(for: $0.id) > 0 }.count
                        let activeSuit = (engine.progress.suitBonusInfo().suit.styleIndex == suit.styleIndex && engine.progress.suitBonusInfo().matchedCount >= 3)
                        let dressPreview = PrincessFashionItem.byId("dress_\(suit.styleIndex)")

                        Button {
                            engine.equipFashionSuit(suit.styleIndex)
                            selectedItemId = engine.progress.equippedItem(for: engine.selectedWardrobeCategory).id
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 7) {
                                    FashionItemIconVectorView(item: dressPreview, stage: max(1, engine.progress.fashionStage(for: dressPreview.id)), size: 34)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suit.name)
                                            .font(.system(size: 12, weight: .black))
                                            .foregroundColor(Color(hex: "#3B2E22"))
                                            .lineLimit(1)
                                        Text("已集 \(ownedCount)/5 件 · 满套+\(suit.fullCoinBonus)🪙")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color(hex: "#8A7765"))
                                    }
                                }
                                Text(ownedCount > 0 ? "✨ 一键穿齐已拥有" : "🔒 暂未收集")
                                    .font(.system(size: 10.5, weight: .heavy))
                                    .foregroundColor(ownedCount > 0 ? .white : Color(hex: "#8A7765"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule().fill(
                                            ownedCount > 0
                                                ? Color(hex: suit.primaryHex)
                                                : Color(hex: "#EFECE6")
                                        )
                                    )
                            }
                            .padding(10)
                            .frame(width: 185)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(activeSuit ? Color(hex: "#FFF0F5") : Color(hex: "#FAF7F2"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(activeSuit ? Color(hex: suit.primaryHex) : Color.black.opacity(0.08), lineWidth: activeSuit ? 2.0 : 1.2)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#E05385").opacity(0.28), lineWidth: 1.5))
        )
    }

    // MARK: - 个性妆造栏（发色 / 表情 / 站姿）
    private var customizationStudioCard: some View {
        let curHair = engine.progress.currentHairColor
        let curExpr = engine.progress.currentExpression
        let curPose = engine.progress.currentPose

        return VStack(alignment: .leading, spacing: 10) {
            Text("🎨 满满公主个性妆造（发色 · 表情 · 站姿）")
                .font(.system(size: 14.5, weight: .black))
                .foregroundColor(Color(hex: "#4A2E14"))

            // 1. 发色选择
            VStack(alignment: .leading, spacing: 5) {
                Text("发色")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#8A7765"))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(HairColorOption.all) { opt in
                            let unlocked = engine.progress.isHairColorUnlocked(opt)
                            let selected = (curHair.id == opt.id)
                            Button {
                                engine.setHairColor(opt)
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: opt.highlightHex), Color(hex: opt.primaryHex), Color(hex: opt.shadowHex)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 18, height: 18)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(opt.name)
                                            .font(.system(size: 11.5, weight: .heavy))
                                            .foregroundColor(unlocked ? Color(hex: "#3B2E22") : Color.gray)
                                        if !unlocked {
                                            Text("🔒 \(opt.unlockDesc)")
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(Color(hex: "#B45309"))
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selected ? Color(hex: "#FCE7F3") : Color(hex: "#FAF7F2"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selected ? Color(hex: "#E05385") : Color.black.opacity(0.08), lineWidth: selected ? 1.8 : 1.0)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // 2. 表情与 3. 站姿
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("甜美表情")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#8A7765"))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(PrincessExpression.all) { expr in
                                let unlocked = engine.progress.isExpressionUnlocked(expr)
                                let selected = (curExpr.id == expr.id)
                                Button {
                                    engine.setExpression(expr)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(expr.emoji)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(expr.name)
                                                .font(.system(size: 11, weight: .heavy))
                                                .foregroundColor(unlocked ? Color(hex: "#3B2E22") : .gray)
                                            if !unlocked {
                                                Text("🔒 \(expr.unlockDesc)")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(Color(hex: "#B45309"))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(selected ? Color(hex: "#EFEFFD") : Color(hex: "#FAF7F2"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 11)
                                                    .stroke(selected ? Color(hex: "#7A6EE6") : Color.black.opacity(0.08), lineWidth: selected ? 1.8 : 1.0)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 5) {
                    Text("舞台站姿")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#8A7765"))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(PrincessPose.all) { pose in
                                let unlocked = engine.progress.isPoseUnlocked(pose)
                                let selected = (curPose.id == pose.id)
                                Button {
                                    engine.setPose(pose)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(pose.emoji)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(pose.name)
                                                .font(.system(size: 11, weight: .heavy))
                                                .foregroundColor(unlocked ? Color(hex: "#3B2E22") : .gray)
                                            if !unlocked {
                                                Text("🔒 \(pose.unlockDesc)")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(Color(hex: "#B45309"))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(selected ? Color(hex: "#FEF3C7") : Color(hex: "#FAF7F2"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 11)
                                                    .stroke(selected ? Color(hex: "#F59E0B") : Color.black.opacity(0.08), lineWidth: selected ? 1.8 : 1.0)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#7A6EE6").opacity(0.28), lineWidth: 1.5))
        )
    }

    // MARK: - 5 分类高定衣架网格
    private var wardrobeRackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
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
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(on ? .white : Color(hex: "#4A2E14"))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(on ? Color(hex: "#E05385") : Color.white)
                                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: "#E05385").opacity(0.35), lineWidth: 1.4))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 156, maximum: 215), spacing: 10)], spacing: 10) {
                ForEach(currentItems) { fashion in
                    let cnt = engine.progress.fashionCount(for: fashion.id)
                    let owned = cnt > 0
                    let st = engine.progress.fashionStage(for: fashion.id)
                    let isSel = (inspectedItem.id == fashion.id)
                    let isEq = (engine.progress.equippedItem(for: fashion.category).id == fashion.id)

                    VStack(spacing: 7) {
                        Button {
                            selectedItemId = fashion.id
                            engine.audio.sfxTap()
                        } label: {
                            VStack(spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(hex: fashion.secondaryHex), Color(hex: fashion.primaryHex).opacity(0.32)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 62, height: 62)
                                            .overlay(
                                                Circle()
                                                    .stroke(st >= 4 ? Color(hex: "#FFD166") : Color.white, lineWidth: 2)
                                            )

                                        FashionItemIconVectorView(item: fashion, stage: max(1, st), size: 50)
                                            .opacity(owned ? 1.0 : 0.62)
                                    }
                                    .frame(maxWidth: .infinity)

                                    if isEq && owned {
                                        Text("穿戴中")
                                            .font(.system(size: 9.5, weight: .black))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color(hex: "#2B7F4A")))
                                    } else if isSel {
                                        Text("试穿中")
                                            .font(.system(size: 9.5, weight: .black))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color(hex: "#E05385")))
                                    }
                                }

                                Text(fashion.name)
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundColor(Color(hex: "#3B2E22"))
                                    .lineLimit(1)

                                HStack(spacing: 4) {
                                    Text(fashion.tierName)
                                        .font(.system(size: 9.5, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(Capsule().fill(Color(hex: fashion.tierColorHex)))

                                    Text(owned ? "Lv.\(st) \(PrincessFashionItem.stageName(for: st))" : "🔒 \(fashion.needStars)★ · \(fashion.costCoins)🪙")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundColor(owned ? Color(hex: "#BE185D") : Color(hex: "#7A624B"))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        if owned {
                            HStack(spacing: 5) {
                                Button {
                                    selectedItemId = fashion.id
                                    engine.equipFashionItem(fashion)
                                } label: {
                                    Text(isEq ? "已穿戴" : "换上")
                                        .font(.system(size: 10.5, weight: .heavy))
                                        .foregroundColor(isEq ? Color(hex: "#2B7F4A") : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(isEq ? Color(hex: "#E6F7ED") : Color(hex: "#E05385")))
                                }
                                .buttonStyle(.plain)

                                if st < PrincessFashionItem.maxStage && engine.progress.starThread > 0 {
                                    Button {
                                        selectedItemId = fashion.id
                                        engine.upgradeFashionWithThread(fashion)
                                    } label: {
                                        Text("🧵升阶")
                                            .font(.system(size: 10.5, weight: .heavy))
                                            .foregroundColor(Color(hex: "#6D28D9"))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(Color(hex: "#EFEFFD")))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
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
                                        lineWidth: isSel ? 2.4 : 1.3
                                    )
                            )
                    )
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.92)))
    }

    // MARK: - 📸 @MainActor 静态皇室画报快照导出 (ImageRenderer + ShareLink)
    @MainActor
    private func captureRoyalPoster() {
        let item = inspectedItem
        let stage = max(1, engine.progress.fashionStage(for: item.id))
        let suitBonus = effectivePreviewSuitBonus
        let posterContent = PrincessRoyalPosterCardView(
            progress: engine.progress,
            equippedPet: engine.equippedPet,
            petStage: engine.equippedPetStage,
            previewItem: item,
            previewStage: stage,
            suitBonus: suitBonus
        )

        let renderer = ImageRenderer(content: posterContent)
        renderer.scale = 2.0
        guard let cgImg = renderer.cgImage else {
            engine.audio.sfxBad()
            engine.wardrobeToast = "⚠️ 海报生成失败，请稍后重试。"
            return
        }

        let pngData: Data?
        #if canImport(UIKit)
        pngData = UIImage(cgImage: cgImg).pngData()
        #elseif canImport(AppKit)
        let rep = NSBitmapImageRep(cgImage: cgImg)
        pngData = rep.representation(using: .png, properties: [:])
        #else
        pngData = nil
        #endif

        guard let data = pngData else {
            engine.audio.sfxBad()
            return
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("满满公主皇家画报_\(GameProgress.todayString()).png")
        do {
            try data.write(to: fileURL, options: .atomic)
            posterFileURL = fileURL
            posterPreviewImage = Image(decorative: cgImg, scale: 2.0)
            showPosterSheet = true
            engine.audio.sfxSpark()
            engine.wardrobeToast = "📸 皇家高定画报拍摄成功！可点击分享或保存到相册/文件！"
        } catch {
            engine.audio.sfxBad()
            engine.wardrobeToast = "⚠️ 无法写入临时画报文件。"
        }
    }
}

// MARK: - 2. 📸 皇室拍立得海报静态视图与分享 Sheet
private struct PrincessRoyalPosterCardView: View {
    let progress: GameProgress
    let equippedPet: GuardianPetSpecies
    let petStage: Int
    let previewItem: PrincessFashionItem
    let previewStage: Int
    let suitBonus: SuitBonusInfo

    var body: some View {
        let rank = progress.glamourRank
        let rankColor = Color(hex: rank.frameHex)

        VStack(spacing: 12) {
            HStack {
                Text("👑 满满的奇妙料理城 · 皇家画报")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(Color(hex: "#4A2E14"))
                Spacer()
                Text(GameProgress.todayString())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            ZStack {
                PrincessStageBackdropView(
                    stageThemeId: suitBonus.stageThemeId,
                    gentleMotion: true
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))

                PrincessAvatarVectorView(
                    previewItem: previewItem,
                    previewStage: previewStage,
                    progress: progress,
                    size: 230,
                    animated: false,
                    twirlTrigger: 0,
                    gentleMotion: true
                )
            }
            .frame(width: 340, height: 270)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(rankColor, lineWidth: 3))

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(rank.title)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(rankColor))
                    Text("✨ 魅力值 \(progress.totalGlamourScore)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color(hex: "#6D28D9"))
                }

                Text("\(suitBonus.suitName)（\(suitBonus.matchedCount)/5）· 伴读神兽【\(equippedPet.name) Lv.\(petStage)】")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#5A3818"))
            }
            .padding(.bottom, 4)
        }
        .padding(18)
        .frame(width: 390)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color.white, Color(hex: "#FFF5F8")], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: "#FFD166"), lineWidth: 3))
        )
    }
}

private struct RoyalPosterExportSheet: View {
    let posterImage: Image?
    let posterFileURL: URL?
    let suitName: String
    let glamourScore: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("📸 满满公主皇家高定画报")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(Color(hex: "#4A2E14"))
                Spacer()
                Button(action: onDismiss) {
                    Text("关闭")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: "#F3F4F6")))
                }
                .buttonStyle(.plain)
            }

            if let img = posterImage {
                img
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.black.opacity(0.14), radius: 12, y: 6)
            }

            HStack(spacing: 12) {
                if let url = posterFileURL, let img = posterImage {
                    ShareLink(
                        item: url,
                        preview: SharePreview("满满公主皇家画报 · \(suitName)（魅力 \(glamourScore)）", image: img)
                    ) {
                        HStack(spacing: 6) {
                            Text("📤")
                            Text("保存相册 / 分享到微信与文件")
                        }
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: [Color(hex: "#E05385"), Color(hex: "#7A6EE6")], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onDismiss) {
                    Text("返回衣橱")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#FFF0D6")))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(minWidth: 380, idealWidth: 450, minHeight: 500)
        .background(Color(hex: "#FFFDF9"))
    }
}

// MARK: - 3. 🎊 公主华服解锁 & 五阶高定锻造升阶全屏庆典遮罩 (FashionUpgradeBurstOverlay)
public struct FashionUpgradeBurstOverlay: View {
    @ObservedObject public var engine: GameEngine
    public let event: FashionUpgradeEvent

    @State private var burstExpanded: Bool = false

    public init(engine: GameEngine, event: FashionUpgradeEvent) {
        self.engine = engine
        self.event = event
    }

    private func dismissOverlay() {
        if !engine.pendingFashionUpgrades.isEmpty {
            engine.pendingFashionUpgrades.removeFirst()
        }
    }

    public var body: some View {
        let gentle = engine.progress.eyeCare.gentleMotion

        ZStack {
            Color.black.opacity(0.56)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.audio.sfxTap()
                    dismissOverlay()
                }

            // 绚丽礼花光芒特效（完全独立自包含，不依赖外部烟花视图）
            coutureBurstBackdrop(colorHex: event.item.primaryHex, gentleMotion: gentle)

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text(event.item.tierName + "高定")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: event.item.tierColorHex)))

                    Text("Lv.\(event.toStage) \(PrincessFashionItem.stageName(for: event.toStage))")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(Color(hex: "#BE185D"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "#FCE7F3")))
                }

                // 升阶前/后单品对照光芒展示
                if !event.isNewUnlock && event.fromStage < event.toStage {
                    HStack(spacing: 14) {
                        VStack(spacing: 3) {
                            FashionItemIconVectorView(item: event.item, stage: event.fromStage, size: 44)
                            Text("Lv.\(event.fromStage)")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(Color(hex: "#8A7765"))
                        }

                        Text("✨ → ✨")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(Color(hex: "#F59E0B"))

                        VStack(spacing: 3) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#FFD166").opacity(0.28))
                                    .frame(width: 64, height: 64)
                                FashionItemIconVectorView(item: event.item, stage: event.toStage, size: 54)
                            }
                            Text("Lv.\(event.toStage) 焕新！")
                                .font(.system(size: 10.5, weight: .black))
                                .foregroundColor(Color(hex: "#BE185D"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#FFF8EB")))
                }

                PrincessAvatarVectorView(
                    previewItem: event.item,
                    previewStage: event.toStage,
                    progress: engine.progress,
                    size: 176,
                    animated: true,
                    gentleMotion: gentle
                )

                Text(event.customTitle ?? (event.isNewUnlock ? "🎉 恭喜解锁新公主服饰！" : "👑 公主服饰华丽高定升阶！"))
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(Color(hex: "#5E340B"))
                    .multilineTextAlignment(.center)

                Text("【\(event.item.name)】\(event.isNewUnlock ? "已收入衣橱" : "Lv.\(event.fromStage) → Lv.\(event.toStage) \(PrincessFashionItem.stageName(for: event.toStage))")")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color(hex: event.item.primaryHex))

                Text("✨ \(PrincessFashionItem.stageVisualPerk(for: event.toStage))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#7A624B"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                HStack(spacing: 12) {
                    Button {
                        engine.equipFashionItem(event.item)
                        dismissOverlay()
                    } label: {
                        Text("👗 立即穿戴并收下")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "#E05385")))
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.audio.sfxTap()
                        dismissOverlay()
                    } label: {
                        Text("太漂亮啦 ✨")
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
            .padding(24)
            .frame(maxWidth: 450)
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
            .padding(16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: gentle ? 1.2 : 0.8)) {
                burstExpanded = true
            }
        }
    }

    @ViewBuilder
    private func coutureBurstBackdrop(colorHex: String, gentleMotion: Bool) -> some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                let angle = Double(i) * (Double.pi * 2.0 / 14.0)
                let radius: CGFloat = burstExpanded ? (gentleMotion ? 130 : 175) : 16
                Circle()
                    .fill(i % 2 == 0 ? Color(hex: colorHex) : Color(hex: "#FFD166"))
                    .frame(width: burstExpanded ? 8 : 14, height: burstExpanded ? 8 : 14)
                    .offset(x: CGFloat(cos(angle)) * radius, y: CGFloat(sin(angle)) * radius)
                    .opacity(burstExpanded ? 0.0 : 0.95)
            }
        }
        .allowsHitTesting(false)
    }
}
