import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

#if os(macOS)
private final class KitchenKeyMonitorGuard: @unchecked Sendable {
    var isBlocked: Bool = false
}
#endif

public struct KitchenGameView: View {
    @ObservedObject public var engine: GameEngine
    @State private var isDropTargeted: Bool = false
    #if os(macOS)
    @State private var keyMonitor: Any? = nil
    @State private var modalGuard = KitchenKeyMonitorGuard()
    #endif

    public init(engine: GameEngine) {
        self.engine = engine
    }

    private var gentleMotion: Bool {
        engine.progress.eyeCare.gentleMotion
    }

    private var isInputBlockedByModal: Bool {
        engine.screenState != .playing
            || engine.showBackupModal
            || engine.eyeRestActive
            || engine.parentGate != nil
            || engine.playLock != nil
            || engine.showParentSettings
            || engine.firePickerLevel != nil
            || engine.activeGachaHatch != nil
            || !engine.activeGachaBatch.isEmpty
            || !engine.pendingFashionUpgrades.isEmpty
            || engine.dailyWheelResult != nil
    }

    public var body: some View {
        VStack(spacing: 10) {
            topGameBar
            hudStatusStrip

            if engine.isFeverMode {
                feverBannerBar
            }

            // 核心升级：iPad 横屏与 Mac 宽屏「左右双独立滚动分栏」适配各类窗口高度不裁切
            GeometryReader { geo in
                let isWide = geo.size.width >= 760
                if isWide {
                    HStack(alignment: .top, spacing: 18) {
                        ScrollView(showsIndicators: false) {
                            leftStageColumn
                                .padding(.bottom, 12)
                        }
                        .frame(width: geo.size.width * 0.44)

                        ScrollView(showsIndicators: false) {
                            rightShelfColumn
                                .padding(.bottom, 12)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            leftStageColumn
                            rightShelfColumn
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
        .onAppear {
            #if os(macOS)
            modalGuard.isBlocked = isInputBlockedByModal
            #endif
            installKeyboardMonitor()
        }
        .onCompatChange(of: isInputBlockedByModal) { blocked in
            #if os(macOS)
            modalGuard.isBlocked = blocked
            #endif
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
    }

    private var feverBannerBar: some View {
        HStack(spacing: 8) {
            Text("🔥 5连击烈焰狂热模式！")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)
            Text("手感滚烫中 · 每题星币奖励 ×1.5 加成！")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#FFF4E3"))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FF7043"), Color(hex: "#E52E71")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#FFD54F").opacity(0.85), lineWidth: 1.5)
        )
        .shadow(color: Color(hex: "#FF7043").opacity(gentleMotion ? 0.14 : 0.30), radius: 6, y: 2)
    }

    // MARK: - 顶部关卡栏
    private var topGameBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                topBarBackAndTitle
                Spacer(minLength: 8)
                topBarActionToggles
            }
            VStack(alignment: .leading, spacing: 8) {
                topBarBackAndTitle
                ScrollView(.horizontal, showsIndicators: false) {
                    topBarActionToggles
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color(hex: "#D78741").opacity(0.14), radius: 6, y: 3)
        )
    }

    private var topBarBackAndTitle: some View {
        HStack(spacing: 10) {
            Button {
                engine.audio.sfxTap()
                engine.goHome()
            } label: {
                HStack(spacing: 4) {
                    Text("←")
                    Text("返回选关")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#3B2E22"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 2, y: 2)
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(Color(hex: "#3B2E22"))
                    .lineLimit(1)
                Text(headerSubtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
                    .lineLimit(1)
            }
        }
    }

    private var topBarActionToggles: some View {
        HStack(spacing: 8) {
            // 四声调料瓶减负模式 vs 传统卡片切换
            Button {
                engine.audio.sfxTap()
                engine.progress.seasoningMode.toggle()
                engine.saveProgress()
            } label: {
                Text(engine.progress.seasoningMode ? "🧂 调料瓶减负:开" : "🃏 传统全卡:开")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(engine.progress.seasoningMode ? Color(hex: "#B25614") : Color(hex: "#3B2E22"))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 11)
                            .fill(engine.progress.seasoningMode ? Color(hex: "#FFF0E2") : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color(hex: "#F07D2E").opacity(0.45), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)

            // 神秘锅盖盲听开关
            Button {
                engine.audio.sfxTap()
                engine.progress.blind.toggle()
                engine.isBlindRevealed = false
                engine.saveProgress()
            } label: {
                Text(engine.progress.blind ? "🛎️ 盲听:开" : "🛎️ 盲听:关")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(engine.progress.blind ? .white : Color(hex: "#3B2E22"))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 11)
                            .fill(engine.progress.blind ? Color(hex: "#7A6EE6") : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 局内 HUD 状态条
    private var hudStatusStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Text("第 \(engine.questionIndex + 1) / \(max(1, engine.questionQueue.count)) 道菜")
                    .font(.system(size: 13.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#4A2E14"))

                Text(engine.specialMode != nil ? (engine.specialMode == .wrong ? "🛠️ 错题营" : "⚡ 全明星") : "🔥 \(engine.currentFire.name)")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(engine.currentFire == .high ? Color(hex: "#E25247") : Color(hex: "#B25614"))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(engine.currentFire == .high ? Color(hex: "#FDECEB") : Color(hex: "#FFF0E2"))
                    )

                // 星星进度
                Text(String(repeating: "★", count: engine.rightCount) + String(repeating: "☆", count: max(0, engine.questionQueue.count - engine.rightCount)))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#F5A623"))

                if engine.comboCount >= 2 {
                    Text(engine.isFeverMode ? "🔥 狂热连击 ×\(engine.comboCount)" : "🔥 连击 \(engine.comboCount) 次")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: engine.isFeverMode ? [Color(hex: "#FF5722"), Color(hex: "#D81B60")] : [Color(hex: "#FF8A00"), Color(hex: "#E52E71")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                }

                if engine.phoenixShieldsRemaining > 0 {
                    Text("🛡️ 连击护盾 ×\(engine.phoenixShieldsRemaining)")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#B45309"))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#FEF3C7"))
                                .overlay(Capsule().stroke(Color(hex: "#F59E0B").opacity(0.6), lineWidth: 1))
                        )
                }

                // 回锅机会圆点
                HStack(spacing: 5) {
                    Text("回锅机会")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                    let maxRetry = engine.currentFire.retryAllowance
                    ForEach(0..<maxRetry, id: \.self) { i in
                        let used = i < (maxRetry - engine.retryLeft)
                        Circle()
                            .fill(used ? Color.gray.opacity(0.28) : Color(hex: "#3EA865"))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.leading, 6)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(Color.white.opacity(0.78))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.black.opacity(0.08), lineWidth: 1))
        )
    }

    // MARK: - 左栏：森林小动物顾客点单台 + 下锅槽位 + 魔法大铁锅（支持拖拽投放）
    private var leftStageColumn: some View {
        let word = engine.currentWord
        let ch = word?.character ?? "妈"
        let hint = LevelRepository.hint(for: ch)
        let hideChar = engine.progress.blind && !engine.isBlindRevealed

        return VStack(spacing: 10) {
            // 0. 伴读守护神兽 + 彩虹连击宝箱能量条 + 实时星币
            CompanionPetStageWidget(engine: engine)

            // 1. 森林小动物顾客点单卡片
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: engine.currentCustomer.accentHex).opacity(0.16))
                            .frame(width: 48, height: 48)
                        Text(engine.currentCustomer.emoji)
                            .font(.system(size: 30))
                            .scaleEffect(engine.customerMood == .happy ? 1.18 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: engine.customerMood)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("\(engine.currentCustomer.title)·\(engine.currentCustomer.name)")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color(hex: engine.currentCustomer.accentHex))
                            if engine.customerMood == .happy {
                                Text("😋 超满意！")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(hex: "#2B7F4A"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color(hex: "#E6F7ED")))
                            } else if engine.customerMood == .burnt {
                                Text("😵 糊锅啦")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(hex: "#E25247"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color(hex: "#FDECEB")))
                            }
                        }

                        Text(customerSpeechText(ch: ch, phrase: hint.phrase, blind: hideChar))
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(Color(hex: "#4A2E14"))
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#FFF8EE"))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#F07D2E").opacity(0.22), lineWidth: 1.5))
                )

                // 目标大字与神秘锅盖
                HStack(spacing: 16) {
                    if hideChar {
                        Button {
                            engine.audio.sfxTap()
                            engine.isBlindRevealed = true
                            engine.speakCurrentCharacter()
                        } label: {
                            VStack(spacing: 3) {
                                Text("🛎️")
                                    .font(.system(size: 28))
                                Text("点我揭锅盖看字")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(Color(hex: "#445368"))
                            }
                            .frame(width: 124, height: 74)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(LinearGradient(colors: [Color(hex: "#F5F7FA"), Color(hex: "#D8E0EA")], startPoint: .top, endPoint: .bottom))
                            )
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#99A8BC"), lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            engine.speakCurrentCharacter()
                        } label: {
                            Text(ch)
                                .font(.system(size: 62, weight: .black, design: .rounded))
                                .foregroundColor(engine.activeBlendingSlot == "char" ? Color(hex: "#F07D2E") : Color(hex: "#2E2115"))
                                .scaleEffect(engine.activeBlendingSlot == "char" ? 1.14 : 1.0)
                                .animation(.spring(response: 0.25), value: engine.activeBlendingSlot)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        // 词语配图胶囊
                        Button {
                            engine.speakCurrentWordAndPhrase()
                        } label: {
                            HStack(spacing: 6) {
                                Text(hint.emoji)
                                    .font(.system(size: 18))
                                Text(hideChar ? hint.phrase.replacingOccurrences(of: ch, with: "？") : hint.phrase)
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Color(hex: "#8A4B12"))
                                Text("🔊")
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#FFF3DC"))
                                    .overlay(Capsule().stroke(Color(hex: "#F07D2E").opacity(0.35), lineWidth: 1.5))
                            )
                        }
                        .buttonStyle(.plain)

                        // 点读按钮组（新增：拼读示范！）
                        HStack(spacing: 6) {
                            Button {
                                engine.speakCurrentCharacter()
                            } label: {
                                Label("读字", systemImage: "speaker.wave.2.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 9).fill(Color(hex: "#F07D2E")))
                            }
                            .buttonStyle(.plain)

                            Button {
                                engine.speakCurrentBlendingDemo()
                            } label: {
                                Text("🔗 拼读示范")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "#1F5F9E"))
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 9).fill(Color(hex: "#E6F2FF")))
                            }
                            .buttonStyle(.plain)

                            Button {
                                engine.progress.tts.slow.toggle()
                                engine.saveProgress()
                                engine.speakCurrentCharacter()
                            } label: {
                                Text(engine.progress.tts.slow ? "🐢 慢速:开" : "🐢 慢速:关")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(engine.progress.tts.slow ? Color(hex: "#2B7F4A") : Color(hex: "#8A7765"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 9).fill(engine.progress.tts.slow ? Color(hex: "#E6F7ED") : Color(hex: "#F5EFE6")))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 下锅槽位展示
                slotsRowView
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(isDropTargeted ? Color(hex: "#3EA865") : Color(hex: "#F07D2E").opacity(0.25), lineWidth: isDropTargeted ? 3 : 2)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
            )

            // 2. j q x 去两点规则专属提示横幅（位于出题/槽位卡下方、料理锅上方，不遮挡右侧字母卡）
            if let jqxBanner = engine.jqxRuleBanner {
                HStack(alignment: .top, spacing: 8) {
                    Text("🪄")
                        .font(.system(size: 15))
                    Text(jqxBanner)
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#4C409E"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#EFEFFD"))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#7A6EE6"), lineWidth: 1.6))
                        .shadow(color: Color(hex: "#7A6EE6").opacity(0.12), radius: 4, y: 2)
                )
                .transition(.scale.combined(with: .opacity))
            }

            // 3. 奇妙料理锅舞台（支持把食材卡片直接拖进大铁锅！）
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        RadialGradient(
                            colors: [
                                (engine.isFeverMode ? Color(hex: "#FFD180") : Color(hex: "#FFE5B8")).opacity(0.58),
                                Color.white.opacity(0.45)
                            ],
                            center: .bottom,
                            startRadius: 10,
                            endRadius: 200
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                isDropTargeted
                                    ? Color(hex: "#3EA865")
                                    : (engine.isFeverMode ? Color(hex: "#FF6B35").opacity(0.85) : Color.black.opacity(0.08)),
                                style: StrokeStyle(
                                    lineWidth: (isDropTargeted || engine.isFeverMode) ? 3 : 1.5,
                                    dash: isDropTargeted ? [7, 4] : []
                                )
                            )
                    )

                if engine.floatingCoinBurst > 0 {
                    CustomConfettiBurstView(
                        burstID: engine.floatingCoinBurst,
                        isFever: engine.isFeverMode,
                        gentleMotion: gentleMotion
                    )
                    .offset(y: -70)
                }

                VStack(spacing: 4) {
                    if let praise = engine.praisePopup {
                        Text(praise)
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [Color(hex: "#FF8A00"), Color(hex: "#FF5252")], startPoint: .leading, endPoint: .trailing)
                                )
                            )
                            .transition(.scale.combined(with: .opacity))
                    }

                    if let dish = engine.dishPopup {
                        Text(dish)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#8A3E08"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#FFF5E0"))
                                    .overlay(Capsule().stroke(Color(hex: "#F07D2E"), lineWidth: 2))
                            )
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 4)

                    HStack(alignment: .bottom, spacing: 10) {
                        // 小熊大厨助手
                        HStack(alignment: .bottom, spacing: 6) {
                            Text("🐻‍❄️")
                                .font(.system(size: 34))
                            Text(engine.chefBubble)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(Color(hex: "#7A4816"))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .frame(maxWidth: 138, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#F07D2E").opacity(0.35), lineWidth: 1.5))
                                )
                        }

                        Spacer()

                        // 魔法锅本体
                        Button {
                            engine.audio.sfxBubble()
                            engine.potShaking = true
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 450_000_000)
                                engine.potShaking = false
                            }
                        } label: {
                            PotVectorView(
                                skin: engine.currentPotSkin,
                                isShaking: engine.potShaking,
                                isNope: engine.potNope,
                                isHot: engine.comboCount >= 3 || engine.isFeverMode,
                                steamOn: engine.steamActive,
                                fire: engine.currentFire,
                                size: 156,
                                gentleMotion: gentleMotion
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
                .padding(.top, 8)
            }
            .overlay(alignment: .topTrailing) {
                if let coinText = engine.floatingCoinGainText, engine.floatingCoinBurst > 0 {
                    CoinBurstPillView(
                        text: coinText,
                        isFever: engine.isFeverMode,
                        gentleMotion: gentleMotion
                    )
                    .id(engine.floatingCoinBurst)
                    .padding(.top, 10)
                    .padding(.trailing, 12)
                }
            }
            .frame(minHeight: 175, maxHeight: 215)

            // 底部提示横条
            if !engine.tipMessage.isEmpty {
                Text(engine.tipMessage)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(tipColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
            }
        }
        .onDrop(of: [.text, .plainText], isTargeted: $isDropTargeted) { providers in
            guard let first = providers.first else { return false }
            first.loadObject(ofClass: NSString.self) { item, _ in
                if let str = item as? String {
                    Task { @MainActor in
                        _ = engine.handleDropPayload(str)
                    }
                }
            }
            return true
        }
    }

    // MARK: - 下锅槽位行
    private var slotsRowView: some View {
        HStack(spacing: 10) {
            if engine.currentMode == .whole {
                slotBox(
                    slotKey: "w",
                    title: "整体认读",
                    value: engine.pickedTonedFinal ?? (engine.pickedBaseFinal.map { "\($0) (待撒声调🧂)" }),
                    accent: Color(hex: "#7A6EE6"),
                    wide: true
                )
            } else {
                slotBox(
                    slotKey: "i",
                    title: "1.声母",
                    value: engine.pickedInitial,
                    accent: Color(hex: "#3685D6"),
                    wide: false
                )
                Text("+")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(Color(hex: "#8A7765"))

                if engine.currentMode == .tri {
                    slotBox(
                        slotKey: "m",
                        title: "2.介音",
                        value: engine.pickedMedial,
                        accent: Color(hex: "#7A6EE6"),
                        wide: false
                    )
                    Text("+")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color(hex: "#8A7765"))
                }

                let finalStepTitle = engine.currentMode == .tri ? "3.韵母+声调" : "2.韵母+声调"
                let finalDisplay: String? = {
                    if let toned = engine.pickedTonedFinal {
                        return toned
                    }
                    if let base = engine.pickedBaseFinal {
                        return "\(base) + 🧂?"
                    }
                    return nil
                }()
                slotBox(
                    slotKey: "f",
                    title: finalStepTitle,
                    value: finalDisplay,
                    accent: Color(hex: "#F07D2E"),
                    wide: true
                )
            }

            if engine.pickedInitial != nil || engine.pickedMedial != nil || engine.pickedBaseFinal != nil {
                Button {
                    engine.undoLastPick()
                } label: {
                    Text("↩︎ 退回")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: "#F5EFE6")))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private func slotBox(slotKey: String, title: String, value: String?, accent: Color, wide: Bool) -> some View {
        let filled = (value != nil)
        let isHighlighted = (engine.activeBlendingSlot == slotKey)
        let isGood = (engine.judgeState == "good")
        let isBad = (engine.judgeState == "bad")

        let borderColor: Color = isGood ? Color(hex: "#3EA865") : (isBad ? Color(hex: "#E25247") : (filled ? accent : Color.black.opacity(0.20)))
        let bgColor: Color = isGood ? Color(hex: "#E6F7ED") : (isBad ? Color(hex: "#FDECEB") : (filled ? accent.opacity(0.13) : Color(hex: "#FCF9F4")))

        return Text(value ?? title)
            .font(.system(size: filled ? 22 : 14, weight: .heavy, design: .rounded))
            .foregroundColor(isGood ? Color(hex: "#2B7F4A") : (isBad ? Color(hex: "#E25247") : (filled ? accent : Color(hex: "#8A7765"))))
            .padding(.horizontal, 12)
            .frame(minWidth: wide ? 116 : 74, minHeight: 46)
            .background(RoundedRectangle(cornerRadius: 14).fill(bgColor))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        borderColor,
                        style: StrokeStyle(lineWidth: (filled || isHighlighted) ? 2.5 : 2.0, dash: filled ? [] : [5, 4])
                    )
            )
            .scaleEffect(isHighlighted ? 1.12 : 1.0)
            .animation(.spring(response: 0.25), value: isHighlighted)
    }

    // MARK: - 右栏：一屏零滚动分类食材架 + 四声调料台
    private var rightShelfColumn: some View {
        let word = engine.currentWord
        let showAnswerHint = (engine.judgeState == "bad")

        return VStack(alignment: .leading, spacing: 11) {
            if engine.currentMode == .whole {
                // 整体认读音节架
                shelfSection(
                    badgeColor: Color(hex: "#7A6EE6"),
                    title: engine.progress.seasoningMode
                        ? "第一步：选整体认读主料（整块下锅，共 \(engine.availableBaseFinals.count) 种）"
                        : "整体认读音节（点击或拖进锅里）"
                ) {
                    if engine.progress.seasoningMode {
                        FlowLayoutGrid(items: engine.availableBaseFinals) { base in
                            PinyinIngredientCardView(
                                kind: "b",
                                text: base,
                                isSelected: engine.pickedBaseFinal == base,
                                isCorrectHint: showAnswerHint && word?.baseFinal == base,
                                isDimmed: showAnswerHint && word?.baseFinal != base,
                                gentleMotion: gentleMotion
                            ) {
                                engine.selectBaseFinal(base)
                            }
                        }
                    } else {
                        FlowLayoutGrid(items: engine.availableTonedFinals) { toned in
                            PinyinIngredientCardView(
                                kind: "f",
                                text: toned,
                                isSelected: engine.pickedTonedFinal == toned,
                                isCorrectHint: showAnswerHint && word?.tonedFinal == toned,
                                isDimmed: showAnswerHint && word?.tonedFinal != toned,
                                gentleMotion: gentleMotion
                            ) {
                                engine.selectDirectTonedFinal(toned)
                            }
                        }
                    }
                }
            } else {
                // 1. 蓝色声母篮
                shelfSection(
                    badgeColor: Color(hex: "#3685D6"),
                    title: "第一步：选声母（蓝色食材 · 点击发声母本音或拖入锅中）"
                ) {
                    FlowLayoutGrid(items: engine.availableInitials) { ini in
                        PinyinIngredientCardView(
                            kind: "i",
                            text: ini,
                            isSelected: engine.pickedInitial == ini,
                            isCorrectHint: showAnswerHint && word?.initial == ini,
                            isDimmed: showAnswerHint && word?.initial != ini,
                            gentleMotion: gentleMotion
                        ) {
                            engine.selectInitial(ini)
                        }
                    }
                }

                // 2. 紫色介音碗（仅三拼音节）
                if engine.currentMode == .tri {
                    shelfSection(
                        badgeColor: Color(hex: "#7A6EE6"),
                        title: "第二步：选介音（紫色高汤 i / u / ü）"
                    ) {
                        FlowLayoutGrid(items: engine.availableMedials) { med in
                            PinyinIngredientCardView(
                                kind: "m",
                                text: med,
                                isSelected: engine.pickedMedial == med,
                                isCorrectHint: showAnswerHint && word?.medial == med,
                                isDimmed: showAnswerHint && word?.medial != med,
                                gentleMotion: gentleMotion
                            ) {
                                engine.selectMedial(med)
                            }
                        }
                    }
                }

                // 3. 橙色无调韵母架（核心减负升级！）
                shelfSection(
                    badgeColor: Color(hex: "#F07D2E"),
                    title: engine.progress.seasoningMode
                        ? "\(engine.currentMode == .tri ? "第三步" : "第二步")：选无调韵母（橙色香料 · 仅 \(engine.availableBaseFinals.count) 张清晰大卡）"
                        : "选带调韵母（橙色香料）"
                ) {
                    if engine.progress.seasoningMode {
                        FlowLayoutGrid(items: engine.availableBaseFinals) { base in
                            PinyinIngredientCardView(
                                kind: "b",
                                text: base,
                                isSelected: engine.pickedBaseFinal == base,
                                isCorrectHint: showAnswerHint && word?.baseFinal == base,
                                isDimmed: showAnswerHint && word?.baseFinal != base,
                                gentleMotion: gentleMotion
                            ) {
                                engine.selectBaseFinal(base)
                            }
                        }
                    } else {
                        FlowLayoutGrid(items: engine.availableTonedFinals) { toned in
                            PinyinIngredientCardView(
                                kind: "f",
                                text: toned,
                                isSelected: engine.pickedTonedFinal == toned,
                                isCorrectHint: showAnswerHint && word?.tonedFinal == toned,
                                isDimmed: showAnswerHint && word?.tonedFinal != toned,
                                gentleMotion: gentleMotion
                            ) {
                                engine.selectDirectTonedFinal(toned)
                            }
                        }
                    }
                }
            }

            // 4. 🧂 四声调料台（两段式声调选择）
            if engine.progress.seasoningMode {
                shelfSection(
                    badgeColor: Color(hex: "#F5B82E"),
                    title: "🧂 最后一步：撒四声调料瓶（选好韵母后点调料瓶，或按数字键 1 ~ 4）"
                ) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(ToneSeasoningBottle.all) { bottle in
                            ToneBottleCardView(
                                bottle: bottle,
                                baseFinal: engine.pickedBaseFinal,
                                initial: engine.pickedInitial,
                                medial: engine.pickedMedial,
                                mode: engine.currentMode,
                                isSelected: engine.pickedTone == bottle.id,
                                isCorrectHint: showAnswerHint && word?.toneNumber == bottle.id,
                                gentleMotion: gentleMotion
                            ) {
                                engine.selectTone(bottle.id)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // 底部操作引导条（iPad 触控拖拽 + Mac 键盘快捷键提示）
            HStack(spacing: 8) {
                Text("💡 玩法秘籍：")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#8A4B12"))
                Text("iPad 可用手指把卡片拖进铁锅；Mac 可直接按字母键选拼音（ü 按 V 键）、按数字 1~4 撒四声、空格重听！")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#FFF8EB"))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#F07D2E").opacity(0.22), lineWidth: 1))
            )
        }
    }

    private func shelfSection<Content: View>(badgeColor: Color, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(badgeColor)
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(Color(hex: "#5A4634"))
            }
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.82))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.08), lineWidth: 1.5))
        )
    }

    // MARK: - 辅助文本与颜色
    private var headerTitle: String {
        if let sp = engine.specialMode {
            return sp == .wrong ? "🛠️ 消灭糊锅菜 · 错题特训" : "⚡ 名厨随机全明星挑战"
        }
        return engine.currentLevelDef.name
    }

    private var headerSubtitle: String {
        if let sp = engine.specialMode {
            return sp == .wrong ? "把以前错过的字全部攻克！" : "已解锁关卡混合出题 · 冲榜赢高定与星币"
        }
        return "\(engine.currentLevelDef.subtitle) · \(engine.currentFire.name)（\(engine.currentFire.desc)）"
    }

    private func customerSpeechText(ch: String, phrase: String, blind: Bool) -> String {
        switch engine.customerMood {
        case .waiting:
            return engine.currentCustomer.orderLine(for: ch, phrase: phrase, blind: blind)
        case .happy:
            return engine.currentCustomer.happyLine(for: ch, phrase: phrase)
        case .burnt:
            let rightTone = engine.currentWord?.toneNumber ?? 1
            let isToneErr = (engine.pickedInitial == engine.currentWord?.initial && engine.pickedBaseFinal == engine.currentWord?.baseFinal)
            return engine.currentCustomer.burntLine(isToneError: isToneErr, rightTone: rightTone)
        }
    }

    private var tipColor: Color {
        switch engine.tipStyle {
        case "ok":   return Color(hex: "#2B7F4A")
        case "no":   return Color(hex: "#E25247")
        case "note": return Color(hex: "#C86419")
        default:     return Color(hex: "#8A7765")
        }
    }

    // MARK: - macOS 键盘监听
    private func installKeyboardMonitor() {
        #if os(macOS)
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak engine] event in
            // 保留系统快捷键（如 Cmd+Q / Cmd+W / Cmd+H）正常生效
            guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty else {
                return event
            }
            // 有任何弹窗/护眼/家长锁/备份输入框激活，或焦点处于文本输入控件时，禁止劫持键盘！
            guard !modalGuard.isBlocked else {
                return event
            }
            if let responder = NSApp.keyWindow?.firstResponder, responder is NSTextView || responder is NSText {
                return event
            }
            guard let engine = engine else { return event }

            if event.keyCode == 51 { // Backspace 退格键
                Task { @MainActor in
                    guard !self.isInputBlockedByModal else { return }
                    engine.handleKeyInput("backspace")
                }
                return nil
            }
            if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
                Task { @MainActor in
                    guard !self.isInputBlockedByModal else { return }
                    engine.handleKeyInput(chars)
                }
                return nil
            }
            return event
        }
        #endif
    }

    private func removeKeyboardMonitor() {
        #if os(macOS)
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        #endif
    }
}

// MARK: - 自适应流式卡片网格（兼容 macOS 13+ / iPadOS 16+）
public struct FlowLayoutGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    public let items: Data
    public let content: (Data.Element) -> Content

    public init(items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }

    public var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 68, maximum: 96), spacing: 9)],
            alignment: .leading,
            spacing: 9
        ) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
            }
        }
    }
}
