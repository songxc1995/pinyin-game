import SwiftUI

// MARK: - 沪教版一年级数学 5 大可视化互动教具总入口
public struct MathVisualAidView: View {
    public let question: CurriculumQuestion
    public let showHint: Bool

    public init(question: CurriculumQuestion, showHint: Bool) {
        self.question = question
        self.showHint = showHint
    }

    public var body: some View {
        VStack(spacing: 6) {
            switch detectVisualKind() {
            case .clock(let hour, let isHalf):
                ClockFaceVisualView(hour: hour, isHalf: isHalf)
            case .numberWall(let bottom, let mid, let top):
                NumberWallVisualView(bottomRow: bottom, midRow: mid, topValue: top, revealAnswer: showHint)
            case .ruler(let startCm, let endCm):
                RulerVisualView(startCm: startCm, endCm: endCm)
            case .numberBond(let total, let left, let right, let hidePart):
                NumberBondVisualView(total: total, left: left, right: right, hidePart: showHint ? nil : hidePart)
            case .placeValue(let tens, let ones):
                PlaceValueVisualView(tens: tens, ones: ones)
            case .tenFrame(let first, let second, let isSub):
                TenFrameVisualView(firstCount: first, secondCount: second, isSubtraction: isSub)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#FFF9FC"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#E05385").opacity(0.25), lineWidth: 1.5)
                )
        )
    }

    private enum VisualKind {
        case clock(hour: Int, isHalf: Bool)
        case numberWall(bottom: [String], mid: [String], top: String)
        case ruler(startCm: Int, endCm: Int)
        case numberBond(total: Int, left: Int, right: Int, hidePart: String)
        case placeValue(tens: Int, ones: Int)
        case tenFrame(first: Int, second: Int, isSub: Bool)
    }

    private func detectVisualKind() -> VisualKind {
        let p = question.prompt
        let tid = question.topicId

        // 1. 钟表教具 (一下 U3 时间的初步认识)
        if tid.hasPrefix("hjm_g1b_u3_") || p.contains("钟面") || p.contains("时针") || p.contains("分针") || p.contains("时半") {
            let isHalf = p.contains("半") || p.contains("指着6") || p.contains("指着 6")
            let nums = extractNumbers(from: p)
            var h = nums.first(where: { (1...12).contains($0) && $0 != 12 }) ?? 8
            if p.contains("12时") || p.contains("12 时") { h = 12 }
            return .clock(hour: h, isHalf: isHalf)
        }

        // 2. 数墙金字塔教具 (一下 U7 数墙的秘密)
        if tid.hasPrefix("hjm_g1b_u7_") || p.contains("数墙") {
            let nums = extractNumbers(from: p)
            let ans = Int(question.answer) ?? 10
            if nums.count >= 3 {
                let a = nums[0], b = nums[1], c = nums[2]
                return .numberWall(
                    bottom: ["\(a)", "\(b)", "\(c)"],
                    mid: ["\(a + b)", "\(b + c)"],
                    top: showHint ? "\(ans)" : "？"
                )
            } else if nums.count == 2 {
                let a = nums[0], b = nums[1]
                if p.contains("下层") && p.contains("上层") {
                    return .numberWall(
                        bottom: ["\(a)", "？"],
                        mid: [],
                        top: "\(b)"
                    )
                } else {
                    return .numberWall(
                        bottom: ["\(a)", "\(b)"],
                        mid: [],
                        top: showHint ? "\(a + b)" : "？"
                    )
                }
            }
            return .numberWall(bottom: ["3", "4", "5"], mid: ["7", "9"], top: showHint ? "\(ans)" : "？")
        }

        // 3. 厘米直尺教具 (一下 U5 长度比较与测量)
        if tid.hasPrefix("hjm_g1b_u5_") || p.contains("厘米") || p.contains("直尺") || p.contains("刻度") {
            let nums = extractNumbers(from: p).filter { $0 <= 15 }
            if nums.count >= 2 {
                let s = min(nums[0], nums[1])
                let e = max(nums[0], nums[1])
                return .ruler(startCm: s, endCm: max(s + 1, min(12, e)))
            } else if let first = nums.first, first > 0 {
                return .ruler(startCm: 0, endCm: min(12, first))
            }
            return .ruler(startCm: 0, endCm: 7)
        }

        // 4. 分与合三角树 (一上 U3 分与合 / 10的游戏 / 组算式)
        if p.contains("分成") || p.contains("合起来") || p.contains("好朋友") || tid.hasPrefix("hjm_g1a_u3_l3") || tid.hasPrefix("hjm_g1a_u3_l6") || tid.hasPrefix("hjm_g1b_u1_l4") {
            let nums = extractNumbers(from: p).filter { $0 <= 20 }
            let ans = Int(question.answer) ?? 5
            if p.contains("合起来") && nums.count >= 2 {
                return .numberBond(total: nums[0] + nums[1], left: nums[0], right: nums[1], hidePart: "total")
            } else if nums.count >= 2 {
                let total = max(nums[0], nums[1])
                let part = min(nums[0], nums[1])
                return .numberBond(total: total, left: part, right: max(0, total - part), hidePart: "right")
            } else if let first = nums.first {
                return .numberBond(total: 10, left: min(10, first), right: max(0, 10 - min(10, first)), hidePart: "right")
            }
            return .numberBond(total: max(ans, 8), left: 3, right: 5, hidePart: "right")
        }

        // 5. 百以内数位值积木 (一下 U2 / U4 两位数)
        let nums = extractNumbers(from: p)
        if tid.hasPrefix("hjm_g1b_u2_") || tid.hasPrefix("hjm_g1b_u4_") || nums.contains(where: { $0 > 20 }) {
            let target = nums.first(where: { $0 >= 10 && $0 <= 100 }) ?? (Int(question.answer) ?? 36)
            let clamped = max(10, min(99, target))
            return .placeValue(tens: clamped / 10, ones: clamped % 10)
        }

        // 6. 默认：双轨十格阵 (20以内加减法、凑十法、破十法、数数)
        let smallNums = nums.filter { $0 >= 0 && $0 <= 20 }
        let isSub = p.contains("-") || p.contains("减") || p.contains("吃") || p.contains("拿走") || p.contains("飞走") || p.contains("走开") || p.contains("送给")
        if smallNums.count >= 2 {
            let a = min(20, smallNums[0])
            let b = min(10, smallNums[1])
            return .tenFrame(first: a, second: b, isSub: isSub)
        } else if let single = smallNums.first, single > 0 {
            return .tenFrame(first: min(20, single), second: 0, isSub: false)
        } else {
            let starCount = p.filter { $0 == "★" || $0 == "☆" }.count
            if starCount > 0 {
                return .tenFrame(first: min(20, starCount), second: 0, isSub: false)
            }
            return .tenFrame(first: 6, second: 4, isSub: false)
        }
    }

    private func extractNumbers(from text: String) -> [Int] {
        let pattern = #"\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: nsRange).compactMap { match in
            guard let r = Range(match.range, in: text) else { return nil }
            return Int(text[r])
        }
    }
}

// MARK: - 教具 1：双轨十格阵 (Ten-Frame 凑十法 / 破十法直观演示)
public struct TenFrameVisualView: View {
    public let firstCount: Int
    public let secondCount: Int
    public let isSubtraction: Bool

    public var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(isSubtraction ? "🍓 双轨十格阵 · 破十/拿走演示" : "🍓 双轨十格阵 · 凑十/合起来演示")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Spacer()
                if isSubtraction && secondCount > 0 {
                    Text("共 \(firstCount) 颗，划掉 \(secondCount) 颗")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else if secondCount > 0 {
                    Text("红果 \(firstCount) 颗 + 蓝莓 \(secondCount) 颗")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else {
                    Text("数一数十格阵里的果子")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
            }

            HStack(spacing: 10) {
                singleTenFrame(frameIndex: 0)
                if firstCount > 10 || (!isSubtraction && firstCount + secondCount > 10) {
                    singleTenFrame(frameIndex: 1)
                }
            }
        }
    }

    private func singleTenFrame(frameIndex: Int) -> some View {
        let baseIndex = frameIndex * 10
        return VStack(spacing: 3) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { col in
                        let idx = baseIndex + row * 5 + col
                        cellView(at: idx)
                    }
                }
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#E05385").opacity(0.45), lineWidth: 1.5))
        )
    }

    private func cellView(at idx: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "#FFF3F7"))
                .frame(width: 22, height: 22)

            if isSubtraction {
                if idx < firstCount {
                    let isCrossed = idx >= max(0, firstCount - secondCount)
                    Circle()
                        .fill(isCrossed ? Color(hex: "#FF6B8B").opacity(0.35) : Color(hex: "#E03E6D"))
                        .frame(width: 15, height: 15)
                    if isCrossed {
                        Text("✕")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color(hex: "#C91E4A"))
                    }
                }
            } else {
                if idx < firstCount {
                    Circle()
                        .fill(Color(hex: "#E03E6D"))
                        .frame(width: 15, height: 15)
                } else if idx < firstCount + secondCount {
                    Circle()
                        .fill(Color(hex: "#3685D6"))
                        .frame(width: 15, height: 15)
                }
            }
        }
    }
}

// MARK: - 教具 2：分与合三角树 (Number Bond)
public struct NumberBondVisualView: View {
    public let total: Int
    public let left: Int
    public let right: Int
    public let hidePart: String? // "total", "left", "right", or nil

    public var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🌳 分与合三角树")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text("上面的总数可以分成左、右两个部分数，左右合起来等于总数！")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            Spacer()

            ZStack {
                // 分叉连线
                Path { path in
                    path.move(to: CGPoint(x: 65, y: 20))
                    path.addLine(to: CGPoint(x: 30, y: 58))
                    path.move(to: CGPoint(x: 65, y: 20))
                    path.addLine(to: CGPoint(x: 100, y: 58))
                }
                .stroke(Color(hex: "#E05385"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                // 顶部总数圆
                bondCircle(
                    text: hidePart == "total" ? "？" : "\(total)",
                    isMystery: hidePart == "total",
                    color: Color(hex: "#E05385")
                )
                .position(x: 65, y: 18)

                // 左分支
                bondCircle(
                    text: hidePart == "left" ? "？" : "\(left)",
                    isMystery: hidePart == "left",
                    color: Color(hex: "#3685D6")
                )
                .position(x: 30, y: 58)

                // 右分支
                bondCircle(
                    text: hidePart == "right" ? "？" : "\(right)",
                    isMystery: hidePart == "right",
                    color: Color(hex: "#3EA865")
                )
                .position(x: 100, y: 58)
            }
            .frame(width: 130, height: 76)
        }
    }

    private func bondCircle(text: String, isMystery: Bool, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(isMystery ? Color(hex: "#FFF3C4") : Color.white)
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(color, lineWidth: 2.2))
            Text(text)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(isMystery ? Color(hex: "#D96B00") : color)
        }
    }
}

// MARK: - 教具 3：数墙金字塔 (Number Wall)
public struct NumberWallVisualView: View {
    public let bottomRow: [String]
    public let midRow: [String]
    public let topValue: String
    public let revealAnswer: Bool

    public var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🧱 沪教特色 · 数墙金字塔")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text("每一块上层砖的数字 = 它下面相邻两块砖数字加起来的和！")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            Spacer()

            VStack(spacing: 3) {
                brickView(text: topValue, highlight: topValue == "？")
                if !midRow.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(Array(midRow.enumerated()), id: \.offset) { _, val in
                            brickView(text: val, highlight: val == "？")
                        }
                    }
                }
                HStack(spacing: 3) {
                    ForEach(Array(bottomRow.enumerated()), id: \.offset) { _, val in
                        brickView(text: val, highlight: val == "？")
                    }
                }
            }
        }
    }

    private func brickView(text: String, highlight: Bool) -> some View {
        Text(text)
            .font(.system(size: 13.5, weight: .black, design: .rounded))
            .foregroundColor(highlight ? Color(hex: "#D96B00") : Color(hex: "#4A2E14"))
            .frame(width: 42, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(highlight ? Color(hex: "#FFF0B8") : Color(hex: "#FFE4EE"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(highlight ? Color(hex: "#F07D2E") : Color(hex: "#E05385").opacity(0.5), lineWidth: 1.5)
                    )
            )
    }
}

// MARK: - 教具 4：整时与半时钟表 (Clock Face)
public struct ClockFaceVisualView: View {
    public let hour: Int
    public let isHalf: Bool

    public var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("⏰ 滴答小钟表 · \(hour)时\(isHalf ? "半" : "")")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text(isHalf ? "长分针指着 6 是半时，短时针走过 \(hour) 和 \((hour % 12) + 1) 的正中间！" : "长分针指着 12 是整时，短时针指着 \(hour) 就是 \(hour) 时！")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 78, height: 78)
                    .overlay(Circle().stroke(Color(hex: "#E05385"), lineWidth: 3))

                // 12 个数字刻度
                ForEach(1...12, id: \.self) { num in
                    let angle = Double(num) * (.pi / 6.0) - (.pi / 2.0)
                    let r: CGFloat = 28
                    Text("\(num)")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .position(
                            x: 39 + r * CGFloat(cos(angle)),
                            y: 39 + r * CGFloat(sin(angle))
                        )
                }

                // 蓝色长分针
                let minAngle = (isHalf ? 6.0 : 0.0) * (.pi / 6.0) - (.pi / 2.0)
                Path { path in
                    path.move(to: CGPoint(x: 39, y: 39))
                    path.addLine(to: CGPoint(x: 39 + 24 * CGFloat(cos(minAngle)), y: 39 + 24 * CGFloat(sin(minAngle))))
                }
                .stroke(Color(hex: "#3685D6"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                // 红色短时针
                let hourFloat = Double(hour % 12) + (isHalf ? 0.5 : 0.0)
                let hrAngle = hourFloat * (.pi / 6.0) - (.pi / 2.0)
                Path { path in
                    path.move(to: CGPoint(x: 39, y: 39))
                    path.addLine(to: CGPoint(x: 39 + 16 * CGFloat(cos(hrAngle)), y: 39 + 16 * CGFloat(sin(hrAngle))))
                }
                .stroke(Color(hex: "#E25247"), style: StrokeStyle(lineWidth: 3.2, lineCap: .round))

                Circle()
                    .fill(Color(hex: "#4A2E14"))
                    .frame(width: 6, height: 6)
            }
            .frame(width: 78, height: 78)
        }
    }
}

// MARK: - 教具 5：厘米直尺与断尺测量 (Centimeter Ruler)
public struct RulerVisualView: View {
    public let startCm: Int
    public let endCm: Int

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("📏 厘米小直尺（从刻度 \(startCm) 到刻度 \(endCm)）")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Spacer()
                Text("终点刻度 - 起点刻度 = 长度")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }

            GeometryReader { geo in
                let maxTick = max(10, endCm + 1)
                let step = (geo.size.width - 24) / CGFloat(maxTick)
                ZStack(alignment: .topLeading) {
                    // 被测小铅笔条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color(hex: "#FF9B44"), Color(hex: "#E05385")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, CGFloat(endCm - startCm) * step), height: 10)
                        .offset(x: 12 + CGFloat(startCm) * step, y: 2)

                    // 直尺主体
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#FFF5D6"))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#D9953B"), lineWidth: 1.2))
                        .frame(height: 28)
                        .offset(y: 15)

                    ForEach(0...maxTick, id: \.self) { cm in
                        let x = 12 + CGFloat(cm) * step
                        let isEndpoint = (cm == startCm || cm == endCm)
                        VStack(spacing: 1) {
                            Rectangle()
                                .fill(isEndpoint ? Color(hex: "#E03E6D") : Color(hex: "#5A4634"))
                                .frame(width: isEndpoint ? 2.2 : 1.2, height: isEndpoint ? 10 : 7)
                            Text("\(cm)")
                                .font(.system(size: 8.5, weight: isEndpoint ? .black : .semibold, design: .rounded))
                                .foregroundColor(isEndpoint ? Color(hex: "#E03E6D") : Color(hex: "#5A4634"))
                        }
                        .position(x: x, y: 27)
                    }
                }
            }
            .frame(height: 44)
        }
    }
}

// MARK: - 教具 6：百以内数位值积木条 (Tens & Ones Place Value)
public struct PlaceValueVisualView: View {
    public let tens: Int
    public let ones: Int

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🧮 百数位值积木")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text("\(tens) 个十（整十长条）和 \(ones) 个一（单个小方块）")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            Spacer()
            // 十位积木柱
            HStack(spacing: 3) {
                ForEach(0..<min(10, tens), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#E05385"))
                        .frame(width: 8, height: 34)
                }
            }
            // 个位小方块
            LazyVGrid(columns: [GridItem(.fixed(9), spacing: 2), GridItem(.fixed(9), spacing: 2), GridItem(.fixed(9), spacing: 2)], spacing: 2) {
                ForEach(0..<min(9, ones), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#3685D6"))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(width: 34)
        }
    }
}

// MARK: - 数学烘焙坊烤箱舞台与英语饮品吧果汁机舞台矢量图
public struct MathOvenVectorView: View {
    public let shaking: Bool
    public let nope: Bool
    public let steamActive: Bool
    public let dishPopup: String?

    public init(shaking: Bool, nope: Bool, steamActive: Bool, dishPopup: String?) {
        self.shaking = shaking
        self.nope = nope
        self.steamActive = steamActive
        self.dishPopup = dishPopup
    }

    public var body: some View {
        ZStack {
            // 烤箱外壳
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [Color(hex: "#FF9EB5"), Color(hex: "#E05385")], startPoint: .top, endPoint: .bottom))
                .frame(width: 196, height: 116)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "#A82855"), lineWidth: 3))
                .shadow(color: Color(hex: "#A82855").opacity(0.22), radius: 8, y: 4)

            // 顶部旋钮栏
            HStack(spacing: 14) {
                Circle().fill(Color(hex: "#FFF0D6")).frame(width: 11, height: 11)
                Capsule().fill(Color(hex: "#FFF0D6")).frame(width: 58, height: 7)
                Circle().fill(Color(hex: "#FFF0D6")).frame(width: 11, height: 11)
            }
            .offset(y: -42)

            // 烤箱暖光玻璃窗
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: steamActive
                            ? [Color(hex: "#FFF6B3"), Color(hex: "#FFBA52")]
                            : [Color(hex: "#4A2535"), Color(hex: "#6E354C")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 152, height: 68)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.65), lineWidth: 2))
                .offset(y: 8)

            // 烤箱内甜点
            Text(steamActive ? "🥐🧁🍰" : "🧁")
                .font(.system(size: steamActive ? 28 : 26))
                .offset(y: 10)

            if let popup = dishPopup {
                Text(popup)
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(Color(hex: "#7A1C3E"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .overlay(Capsule().stroke(Color(hex: "#E05385"), lineWidth: 2))
                            .shadow(radius: 6)
                    )
                    .offset(y: -48)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .rotationEffect(.degrees(shaking ? -3.5 : (nope ? 4.5 : 0)))
        .animation(.spring(response: 0.22, dampingFraction: 0.45), value: shaking)
        .animation(.spring(response: 0.18, dampingFraction: 0.35), value: nope)
    }
}

public struct EnglishBlenderVectorView: View {
    public let shaking: Bool
    public let nope: Bool
    public let steamActive: Bool
    public let dishPopup: String?

    public init(shaking: Bool, nope: Bool, steamActive: Bool, dishPopup: String?) {
        self.shaking = shaking
        self.nope = nope
        self.steamActive = steamActive
        self.dishPopup = dishPopup
    }

    public var body: some View {
        ZStack {
            // 底座
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(hex: "#2FB380"), Color(hex: "#1E855D")], startPoint: .top, endPoint: .bottom))
                .frame(width: 116, height: 34)
                .offset(y: 40)

            // 透明料理杯身
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [Color(hex: "#E8FFF5"), Color(hex: "#B5F5DA")], startPoint: .top, endPoint: .bottom))
                .frame(width: 102, height: 78)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#2FB380"), lineWidth: 3))
                .offset(y: -8)

            // 果汁波浪与鲜果
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: steamActive
                            ? [Color(hex: "#FF9B44"), Color(hex: "#FF5E7E")]
                            : [Color(hex: "#6CE0B6"), Color(hex: "#2FB380")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 90, height: steamActive ? 56 : 42)
                .offset(y: steamActive ? 0 : 7)

            Text(steamActive ? "🍹🍓🍊" : "🍎🍋🍑")
                .font(.system(size: 23))
                .offset(y: -4)

            // 杯盖
            Capsule()
                .fill(Color(hex: "#FF8A48"))
                .frame(width: 112, height: 14)
                .offset(y: -48)

            if let popup = dishPopup {
                Text(popup)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(Color(hex: "#156947"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .overlay(Capsule().stroke(Color(hex: "#2FB380"), lineWidth: 2))
                            .shadow(radius: 6)
                    )
                    .offset(y: -52)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 118)
        .rotationEffect(.degrees(shaking ? -4 : (nope ? 4 : 0)))
        .animation(.spring(response: 0.22, dampingFraction: 0.45), value: shaking)
        .animation(.spring(response: 0.18, dampingFraction: 0.35), value: nope)
    }
}
