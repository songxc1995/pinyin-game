import SwiftUI

// MARK: - 沪教版一年级数学 16 大可视化互动教具总入口
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
            case .clock(let hour, let isHalf, let caption):
                ClockFaceVisualView(hour: hour, isHalf: isHalf, revealLabel: showHint, customCaption: caption)
            case .numberWall(let bottom, let mid, let upperMid, let top):
                NumberWallVisualView(bottomRow: bottom, midRow: mid, topValue: top, revealAnswer: showHint, upperMidRow: upperMid)
            case .dualNumberWall(let bottomA, let bottomB):
                DualNumberWallVisualView(bottomA: bottomA, bottomB: bottomB, revealAnswer: showHint)
            case .geometry(let spec):
                GeometryShapeVisualView(spec: spec, showHint: showHint)
            case .flagLine(let spec):
                FlagLineVisualView(spec: spec, showHint: showHint)
            case .bodyRuler(let unitName, let formulaText):
                BodyRulerVisualView(unitName: unitName, formulaText: formulaText)
            case .ruler(let startCm, let endCm):
                RulerVisualView(startCm: startCm, endCm: endCm)
            case .measurementUnit(let itemText, let options):
                MeasurementUnitVisualView(itemText: itemText, options: options, answer: showHint ? question.answer : nil)
            case .digitCards(let digits, let goal):
                DigitCardsVisualView(digits: digits, goalText: goal, revealText: showHint ? question.answer : nil)
            case .expressionCompare(let leftText, let rightText, let candidates, let title):
                ExpressionCompareVisualView(
                    leftText: leftText,
                    rightText: rightText,
                    candidates: candidates,
                    highlightAnswer: showHint ? question.answer : nil,
                    title: title
                )
            case .queue(let spec):
                QueueVisualView(spec: spec, showHint: showHint)
            case .comparison(let spec):
                ComparisonVisualView(spec: spec, revealAnswer: showHint ? question.answer : nil)
            case .numberLine(let spec):
                NumberLineVisualView(spec: spec, revealAnswer: showHint ? question.answer : nil)
            case .numberBond(let total, let left, let right, let hidePart):
                NumberBondVisualView(total: total, left: left, right: right, hidePart: showHint ? nil : hidePart)
            case .placeValue(let tens, let ones, let revealBreakdown, let caption):
                PlaceValueVisualView(tens: tens, ones: ones, revealBreakdown: showHint || revealBreakdown, customCaption: caption)
            case .dotGroups(let total, let groupSize):
                DotGroupsVisualView(total: total, groupSize: groupSize, showGroupCount: showHint)
            case .multiOp(let steps, let title):
                MultiOpFlowVisualView(steps: steps, title: title, answer: showHint ? question.answer : nil)
            case .starCount(let filled, let empty):
                StarCountVisualView(filled: filled, empty: empty, totalHint: showHint ? question.answer : nil)
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

    // MARK: - 视觉模型定义

    private enum VisualKind {
        case clock(hour: Int, isHalf: Bool, caption: String?)
        case numberWall(bottom: [String], mid: [String], upperMid: [String], top: String)
        case dualNumberWall(bottomA: [String], bottomB: [String])
        case geometry(GeometryVisualSpec)
        case flagLine(FlagLineSpec)
        case bodyRuler(unitName: String, formulaText: String)
        case ruler(startCm: Int, endCm: Int)
        case measurementUnit(itemText: String, options: [String])
        case digitCards(digits: [Int], goal: String)
        case expressionCompare(leftText: String?, rightText: String?, candidates: [String], title: String)
        case queue(QueueSpec)
        case comparison(ComparisonSpec)
        case numberLine(NumberLineSpec)
        case numberBond(total: Int, left: Int, right: Int, hidePart: String)
        case placeValue(tens: Int, ones: Int, revealBreakdown: Bool, caption: String?)
        case dotGroups(total: Int, groupSize: Int)
        case multiOp(steps: [String], title: String)
        case starCount(filled: Int, empty: Int)
        case tenFrame(first: Int, second: Int, isSub: Bool)
    }

    private func detectVisualKind() -> VisualKind {
        let p = question.prompt
        let tid = question.topicId
        let opts = question.options
        let nums = extractNumbers(from: p)

        // 1. 钟表教具 (一下 U3 时间的初步认识)
        if tid.hasPrefix("hjm_g1b_u3_") || p.contains("钟面") || p.contains("时针") || p.contains("分针") || p.contains("时半") {
            return detectClockVisual(prompt: p, nums: nums)
        }

        // 2. 数墙金字塔教具 (一下 U7 数墙的秘密 —— 支持 2/3/4 层与双数墙对比)
        if p.contains("数墙") {
            return detectNumberWallVisual(prompt: p, nums: nums)
        }

        // 3. 几何与线段、图形规律教具 (一上 U2 立体/平面图形 + 一下 U5 线段 + U7 图形规律)
        if tid.hasPrefix("hjm_g1a_u2_") || (p.contains("线段") && !p.contains("厘米")) || p.contains("○、△") {
            return detectGeometryVisual(prompt: p, nums: nums)
        }

        // 4. 挂彩旗间隔与循环配色教具 (一下 U6 彩旗问题)
        if tid.hasPrefix("hjm_g1b_u6_l3") || p.contains("彩旗") {
            return detectFlagLineVisual(prompt: p, nums: nums)
        }

        // 5. 身体上的尺子教具 (一下 U6 拃 / 步 / 庹)
        if tid.hasPrefix("hjm_g1b_u6_l1") || tid.hasPrefix("hjm_g1b_u6_l2") || p.contains("拃") || p.contains("庹") {
            return detectBodyRulerVisual(prompt: p)
        }

        // 6. 厘米直尺 / 测量单位选择 / 厘米线段长度运算 (一下 U5)
        if p.contains("直尺") || p.contains("对准") || p.contains("刻度") {
            let smallCm = nums.filter { $0 <= 15 }
            if (p.contains("左端") || p.contains("刻度")) && smallCm.count >= 2 {
                let s = min(smallCm[0], smallCm[1])
                let e = max(smallCm[0], smallCm[1])
                return .ruler(startCm: s, endCm: max(s + 1, min(12, e)))
            } else if let first = smallCm.first, first > 0 {
                return .ruler(startCm: 0, endCm: min(12, first))
            }
        }
        if p.contains("什么单位") {
            return .measurementUnit(itemText: p, options: opts)
        }

        // 7. 数字卡片组数教具 (用 5、0、8 组成两位数等，不提前泄露答案)
        if p.contains("数字卡片") || (p.contains("组成") && p.contains("两位数") && nums.count >= 2) {
            let goal: String
            if p.contains("最大") && p.contains("最小") {
                goal = "先凑出最大与最小的两位数，再计算"
            } else if p.contains("最大") {
                goal = "大数字放十位（十位不能是 0）"
            } else if p.contains("最小") {
                goal = "非 0 最小数字放十位，较小放个位"
            } else {
                goal = "十位不能为 0，拼出一个两位数"
            }
            return .digitCards(digits: nums, goal: goal)
        }

        // 8. 算式对比、比大小符号填空、读写数及判断对错题
        if let exprVisual = detectExpressionCompareVisual(prompt: p, options: opts) {
            return exprVisual
        }

        // 9. 排队顺序 / 第几与前后人数教具
        if p.contains("排队") || p.contains("从左数") || p.contains("从右数") || p.contains("一排小动物") || p.contains("一排") || p.contains("之间有几人") {
            return detectQueueVisual(prompt: p, nums: nums)
        }

        // 10. 排序与大小/长短比较教具（无 min(10, ...) 截断）
        if let compVisual = detectComparisonVisual(prompt: p, topicId: tid, nums: nums) {
            return compVisual
        }

        // 11. 数列填空、相邻数、前后数与数轴教具
        if let lineVisual = detectNumberLineVisual(prompt: p, nums: nums) {
            return lineVisual
        }

        // 12. 星星数数题（保留实心/空心原样）
        let filledStars = p.filter { $0 == "★" }.count
        let emptyStars = p.filter { $0 == "☆" }.count
        if filledStars + emptyStars > 0 {
            return .starCount(filled: filledStars, empty: emptyStars)
        }

        // 13. 包含除/等分点数演示（如 “10 里面有几个 2？”）
        if p.contains("里面有几个") && !p.contains("个十") && !p.contains("个一") && nums.count == 2 {
            return .dotGroups(total: max(1, min(30, nums[0])), groupSize: max(1, min(10, nums[1])))
        }

        // 14. 加减法家族与分与合三角树
        if p.contains("分成") || p.contains("合起来") || p.contains("好朋友") || p.contains("加减法算式家族") || p.contains("组一道") || p.contains("组成的加法算式") || p.contains("组成的另一道减法算式") {
            return detectNumberBondVisual(prompt: p, nums: nums)
        }

        // 15. 显式算式解析（含 □ 缺项、0 加减、两位数、多步连算）
        if !p.contains("已知") && !p.contains("先算") && !p.contains("加法表中") {
            if let eq = extractEquationTokens(from: p) {
                if eq.tokens.count == 2 && !p.contains("再") {
                    let firstTok = eq.tokens[0]
                    let secondSigned = eq.tokens[1]
                    let isSub = secondSigned.hasPrefix("-")
                    let secondTok = String(secondSigned.dropFirst())
                    if let a = Int(firstTok), let b = Int(secondTok), a <= 20, b <= 20, eq.rhs == "？" || eq.rhs == "?" {
                        return .tenFrame(first: a, second: b, isSub: isSub)
                    }
                    if let rhsVal = Int(eq.rhs), rhsVal <= 20 {
                        if firstTok == "□", let b = Int(secondTok) {
                            let total = isSub ? (rhsVal + b) : rhsVal
                            let left = b
                            let right = isSub ? rhsVal : max(0, rhsVal - b)
                            return .numberBond(total: total, left: left, right: right, hidePart: isSub ? "total" : "right")
                        }
                        if secondTok == "□", let a = Int(firstTok) {
                            let total = isSub ? a : rhsVal
                            let right = isSub ? rhsVal : max(0, rhsVal - a)
                            return .numberBond(total: total, left: isSub ? max(0, a - rhsVal) : a, right: right, hidePart: isSub ? "left" : "right")
                        }
                    }
                }
                let formattedSteps = eq.tokens.map { tok -> String in
                    if tok.hasPrefix("+") || tok.hasPrefix("-") {
                        return tok
                    }
                    return tok
                }
                let stepsWithEq = (eq.rhs == "？" || eq.rhs == "?") ? formattedSteps : (formattedSteps + ["= \(eq.rhs)"])
                return .multiOp(steps: stepsWithEq, title: "🧮 一步步列式算一算")
            }
        }

        // 16. 百以内数位值积木（修复 100 被截成 99 的问题，支持 10 个十 = 100）
        if p.contains("10个十") || p.contains("10 个十") {
            return .placeValue(tens: 10, ones: 0, revealBreakdown: false, caption: "数一数：10 根整十长条合起来是多少？")
        }
        if p.contains("100") {
            if let numBond100 = detectHundredBondOrSteps(prompt: p, nums: nums) {
                return numBond100
            }
        }
        if (p.contains("个十") || p.contains("个一") || p.contains("十位") || p.contains("个位") || p.contains("里面有几个"))
            && !p.contains("再") && !p.contains("比") && !p.contains("还剩") && !p.contains("加起来") && !p.contains("添上") && !p.contains("去掉") && !p.contains("减") {
            if let pv = detectPlaceValueVisual(prompt: p, topicId: tid, nums: nums) {
                return pv
            }
        }

        // 17. 特殊趣味生活场景（两只手 / 吃完 / 全飞走）
        if p.contains("两只手") && p.contains("手指") {
            return .tenFrame(first: 5, second: 5, isSub: false)
        }
        if (p.contains("吃完") || p.contains("全飞走")) && nums.count == 1, let single = nums.first, (1...20).contains(single) {
            return .tenFrame(first: single, second: single, isSub: true)
        }

        // 18. 已知/先算/多步连加减/元角货币/两位数应用题 -> 步进步骤条
        if nums.count >= 3 || p.contains("再") || p.contains("元") || p.contains("角") || p.contains("先算") || p.contains("已知") || p.contains("加法表中") || p.contains("厘米") || nums.contains(where: { $0 > 20 }) {
            let steps = buildWordProblemSteps(from: p)
            let title: String
            if p.contains("元") || p.contains("角") {
                title = "💰 元角购物步骤演示"
            } else if p.contains("厘米") {
                title = "📏 厘米长度分段计算"
            } else {
                title = "🧮 分步思路卡片"
            }
            return .multiOp(steps: steps, title: title)
        }

        // 19. 两数加减法与 0 的运算（取消 min(10, ...) 截断，完整支持 0~20）
        let smallNums = nums.filter { $0 >= 0 && $0 <= 20 }
        let isSub = p.contains("-") || p.contains("减") || p.contains("吃") || p.contains("拿走") || p.contains("飞走") || p.contains("走开") || p.contains("送给") || p.contains("送出") || p.contains("还剩") || p.contains("借出") || p.contains("打破") || p.contains("剪去") || p.contains("去掉") || p.contains("少")
        if smallNums.count == 2 {
            return .tenFrame(first: smallNums[0], second: smallNums[1], isSub: isSub)
        }
        if let single = smallNums.first {
            return .tenFrame(first: single, second: 0, isSub: false)
        }

        return .multiOp(steps: [p], title: "🧁 数学思路小贴士")
    }

    // MARK: - 分类识别子助手

    private func detectClockVisual(prompt p: String, nums: [Int]) -> VisualKind {
        let isHalf = p.contains("半") || p.contains("指着6") || p.contains("指着 6")
        if p.contains("快要指到5") || p.contains("还没到5") {
            return .clock(hour: 4, isHalf: false, caption: "短时针走过 4、快靠近 5，分针指着 12")
        }
        let hourMatch = extractHourBeforeShi(from: p)
        let fallbackH = nums.first(where: { (1...12).contains($0) && !(p.contains("分针指着12") && $0 == 12) }) ?? 8
        let h = hourMatch ?? (p.contains("12时") || p.contains("12 时") ? 12 : fallbackH)
        let caption: String?
        if p.contains("小时后") || p.contains("再过") || p.contains("小时前") || p.contains("慢了") || p.contains("演了") || p.contains("画了") || p.contains("重播") || p.contains("看了") {
            caption = "先看钟面上的起始时刻，再按题干推算经过的时间"
        } else {
            caption = nil
        }
        return .clock(hour: max(1, min(12, h)), isHalf: isHalf, caption: caption)
    }

    private func detectNumberWallVisual(prompt p: String, nums: [Int]) -> VisualKind {
        let ansText = showHint ? question.answer : "？"
        if p.contains("数墙A") && p.contains("数墙B") {
            let parts = p.components(separatedBy: "数墙B")
            let numsA = extractNumbers(from: parts.first ?? p).map(String.init)
            let numsB = extractNumbers(from: parts.count > 1 ? parts[1] : "").map(String.init)
            return .dualNumberWall(
                bottomA: numsA.isEmpty ? ["4", "9"] : numsA,
                bottomB: numsB.isEmpty ? ["2", "3", "4"] : numsB
            )
        }
        if p.contains("底层是4、□、9") {
            return .numberWall(bottom: ["4", ansText, "9"], mid: ["11", "16"], upperMid: [], top: "27")
        }
        if p.contains("底层是□、6、□") {
            return .numberWall(bottom: [showHint ? "7" : "？", "6", showHint ? "9" : "？"], mid: ["13", "15"], upperMid: [], top: "28")
        }
        if p.contains("底层是1、2、3、4") || nums == [1, 2, 3, 4] {
            return .numberWall(
                bottom: ["1", "2", "3", "4"],
                mid: ["3", "5", "7"],
                upperMid: showHint ? ["8", "12"] : ["？", "？"],
                top: ansText
            )
        }
        if nums.count == 3 {
            let a = nums[0], b = nums[1], c = nums[2]
            if p.contains("中间层左块") {
                return .numberWall(bottom: ["\(a)", "\(b)", "\(c)"], mid: [ansText, "\(b + c)"], upperMid: [], top: "？")
            }
            return .numberWall(bottom: ["\(a)", "\(b)", "\(c)"], mid: ["\(a + b)", "\(b + c)"], upperMid: [], top: ansText)
        }
        if nums.count == 2 {
            let a = nums[0], b = nums[1]
            if p.contains("顶层是") || (p.contains("上层") && p.contains("下层")) {
                return .numberWall(bottom: ["\(min(a, b))", ansText], mid: [], upperMid: [], top: "\(max(a, b))")
            }
            return .numberWall(bottom: ["\(a)", "\(b)"], mid: [], upperMid: [], top: ansText)
        }
        return .numberWall(bottom: ["3", "4", "5"], mid: ["7", "9"], upperMid: [], top: ansText)
    }

    private func detectGeometryVisual(prompt p: String, nums: [Int]) -> VisualKind {
        if p.contains("○、△") {
            return .geometry(.shapePattern(items: ["○", "△", "○", "△", "○", "△"]))
        }
        if p.contains("线段") {
            if p.contains("三个点") {
                return .geometry(.dotConnections(dotCount: 3, note: "每 2 个点连成 1 条线段，一共能连几条？"))
            } else if p.contains("四个点") {
                return .geometry(.dotConnections(dotCount: 4, note: "4 个点每两点相连，数一数共有几条？"))
            } else if p.contains("五个点") {
                return .geometry(.dotConnections(dotCount: 5, note: "5 个点按顺序两两相连，一共几条？"))
            } else if p.contains("长方形纸") {
                return .geometry(.planeSingle(kind: .rectangle, note: "观察长方形的直边和顶点"))
            }
            return .geometry(.dotConnections(dotCount: 2, note: "直直的，两端各有一个端点"))
        }
        // 立体图形
        if p.contains("立体图形") || p.contains("正方体") || p.contains("长方体") || p.contains("圆柱") || p.contains("滚动") {
            if p.contains("两个正方体") {
                return .geometry(.solidInspect(kind: .twoCubes, note: p.contains("顶点") ? "观察正方体的角尖尖（顶点）" : "观察正方体平平的面"))
            } else if p.contains("两个长方体拼") {
                return .geometry(.solidInspect(kind: .joinedCuboids, note: "拼在一起时，中间贴合的面被挡住啦"))
            } else if p.contains("一个圆柱有几个面") {
                return .geometry(.solidInspect(kind: .cylinder, note: "圆柱上下两个平圆面 + 侧面一个曲面"))
            }
            let answerIdx: Int?
            if question.answer.contains("球") { answerIdx = 0 }
            else if question.answer.contains("正方体") { answerIdx = 1 }
            else if question.answer.contains("长方体") { answerIdx = 2 }
            else if question.answer.contains("圆柱") { answerIdx = 3 }
            else { answerIdx = nil }
            return .geometry(.gallery3D(highlightIndex: showHint ? answerIdx : nil))
        }
        // 平面图形
        if p.contains("对折两次") {
            return .geometry(.planeSingle(kind: .squareFoldTwice, note: "正方形横竖对折两次"))
        } else if p.contains("对折") && p.contains("长方形") {
            return .geometry(.planeSingle(kind: .rectangleFoldOnce, note: "把长方形沿中线对折"))
        } else if p.contains("剪去一个角") {
            return .geometry(.planeSingle(kind: .squareCutCorner, note: "沿虚线剪掉 1 个角，数一数新边界有几个角"))
        } else if p.contains("两个一样的三角形") {
            return .geometry(.planeSingle(kind: .twoTrianglesJoin, note: "把两个相同的三角形拼合在一起"))
        } else if p.contains("围成") || p.contains("不是平面图形") || p.contains("哪个是三角形") {
            let answerIdx: Int?
            if question.answer.contains("红领巾") || question.answer.contains("三角形") { answerIdx = 0 }
            else if question.answer.contains("正方形") { answerIdx = 1 }
            else if question.answer.contains("长方形") { answerIdx = 2 }
            else if question.answer.contains("皮球") { answerIdx = 3 }
            else { answerIdx = nil }
            return .geometry(.gallery2D(highlightIndex: showHint ? answerIdx : nil, includeSphere: p.contains("不是平面图形")))
        } else if p.contains("长方形有几条边") {
            return .geometry(.planeSingle(kind: .rectangle, note: "数一数长方形的四条直边"))
        } else if p.contains("正方形有几条边") {
            return .geometry(.planeSingle(kind: .square, note: "观察正方形的边和角"))
        }
        return .geometry(.gallery2D(highlightIndex: nil, includeSphere: false))
    }

    private func detectFlagLineVisual(prompt p: String, nums: [Int]) -> VisualKind {
        var colors: [String] = []
        if p.contains("红、红、黄") {
            colors = ["红", "红", "黄"]
        } else if p.contains("红、黄、蓝、绿") {
            colors = ["红", "黄", "蓝", "绿"]
        } else if p.contains("红、黄、蓝") {
            colors = ["红", "黄", "蓝"]
        } else if p.contains("红、黄") {
            colors = ["红", "黄"]
        }
        if !colors.isEmpty && p.contains("什么颜色") {
            let targetIndex = nums.last ?? 7
            return .flagLine(.cycle(colors: colors, askIndex: targetIndex))
        }
        let stepMeters: Int
        if p.contains("每隔2米") || p.contains("每2米") || p.contains("相隔2米") { stepMeters = 2 }
        else if p.contains("每隔3米") { stepMeters = 3 }
        else { stepMeters = 0 }
        let startMeter = p.contains("1米处") ? 1 : 0
        let caption: String
        if p.contains("第3面") {
            caption = "第1面在 \(startMeter) 米处，每间隔 \(stepMeters) 米插 1 面，数一数间隔数"
        } else if p.contains("一共长16米") {
            caption = "第1面到第5面之间一共有 4 段相等间隔，总长 16 米"
        } else if p.contains("一共挂了几面") || p.contains("一共挂几面") {
            caption = "先算一共分成几段间隔，再看两端插旗（间隔数 + 1）"
        } else {
            caption = "彩旗排排站：间隔数 = 旗帜面数 - 1"
        }
        return .flagLine(.spacing(startMeter: startMeter, intervalMeters: stepMeters, caption: caption, flagColors: colors.isEmpty ? ["红", "黄"] : colors))
    }

    private func detectBodyRulerVisual(prompt p: String) -> VisualKind {
        if p.contains("一拃") && p.contains("一庹") && p.contains("一步") {
            return .bodyRuler(unitName: "身体尺三剑客", formulaText: "一拃量桌边 · 一步量走廊 · 一庹量黑板")
        }
        let unit: String
        if p.contains("一庹") || p.contains("双臂") {
            unit = "一庹（张开双臂）"
        } else if p.contains("步") && !p.contains("拃") {
            unit = "一步（正常跨步）"
        } else {
            unit = "一拃（张开大拇指到中指）"
        }
        let steps = buildWordProblemSteps(from: p)
        let formula = steps.isEmpty ? p : steps.joined(separator: "  ·  ")
        return .bodyRuler(unitName: unit, formulaText: formula)
    }

    private func detectExpressionCompareVisual(prompt p: String, options opts: [String]) -> VisualKind? {
        if p.contains("○") && p.contains("填什么符号") {
            let lhs = p.components(separatedBy: "○").first?.trimmingCharacters(in: .whitespaces) ?? ""
            let afterCircle = p.components(separatedBy: "○").dropFirst().joined(separator: "○")
            let rhs = afterCircle.components(separatedBy: "，").first?.trimmingCharacters(in: .whitespaces) ?? ""
            return .expressionCompare(leftText: lhs, rightText: rhs, candidates: opts, title: "⚖️ 比较左右两边大小，选符号")
        }
        if opts.contains(where: { $0.contains("+") || $0.contains("-") || $0.contains("=") || $0.contains("<") || $0.contains(">") }) {
            return .expressionCompare(leftText: nil, rightText: nil, candidates: opts, title: "🧮 逐个算一算各选项的得数")
        }
        if p.contains("写作") || p.contains("读作") || p.contains("这句话对吗") || p.contains("下面哪个数") {
            return .expressionCompare(leftText: nil, rightText: nil, candidates: opts, title: "🔍 仔细辨一辨哪个正确")
        }
        return nil
    }

    private func detectQueueVisual(prompt p: String, nums: [Int]) -> VisualKind {
        let total = (p.contains("一排 10") || p.contains("一排10")) ? 10 : nil
        let targetHint: String
        if p.contains("前面有几") {
            targetHint = "排第 \(nums.first ?? 2)，数一数它前面站了几位"
        } else if p.contains("之间有几") {
            targetHint = "两端都去掉自己，只数中间夹着的小伙伴"
        } else if p.contains("一共有几") {
            targetHint = "别忘了把主角自己也算进去哦！"
        } else if let t = total {
            targetHint = "全排共有 \(t) 个位置，注意不要重复也别漏数"
        } else {
            targetHint = "画一排小圆点排一排位置，一眼看清前后顺序"
        }
        return .queue(QueueSpec(totalCount: total ?? 8, labelNumbers: nums, note: targetHint))
    }

    private func detectComparisonVisual(prompt p: String, topicId tid: String, nums: [Int]) -> VisualKind? {
        if p.contains("从小到大") || p.contains("从大到小") {
            let ascending = p.contains("从小到大")
            return .comparison(.sortCards(values: nums, ascending: ascending))
        }
        if tid.hasPrefix("hjm_g1b_u5_l1") {
            let clues = p.components(separatedBy: CharacterSet(charactersIn: "，。？"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.contains("谁") && !$0.contains("什么") && !$0.contains("排") }
            return .comparison(.wordClues(clues: clues, promptTitle: "📏 按线索排出长短关系"))
        }
        let asksDiffOrWinner = p.contains("谁大") || p.contains("哪个大")
            || p.contains("大几") || p.contains("多几") || p.contains("小几") || p.contains("少几")
        if asksDiffOrWinner && nums.count == 2
            && !p.contains("再") && !p.contains("十位") && !p.contains("个位")
            && !p.contains("两位数") && !p.contains("加起来") && !p.contains("一共") && !p.contains("吃了") {
            return .comparison(.numericPair(
                left: nums[0],
                right: nums[1],
                askText: (p.contains("谁大") || p.contains("哪个大")) ? "比一比哪个数更大" : "比一比两数相差多少"
            ))
        }
        return nil
    }

    private func detectNumberLineVisual(prompt p: String, nums: [Int]) -> VisualKind? {
        if p.contains("□") && p.contains("、") {
            let rawTokens = p
                .replacingOccurrences(of: "，□里填几？", with: "")
                .replacingOccurrences(of: "，□里应该填几？", with: "")
                .replacingOccurrences(of: "，□是几？", with: "")
                .components(separatedBy: CharacterSet(charactersIn: "、，："))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { $0 == "□" || Int($0) != nil }
            let cleanTokens = rawTokens.map { $0 == "□" ? "？" : $0 }
            if !cleanTokens.isEmpty {
                return .numberLine(.sequence(tokens: cleanTokens, hint: "找相邻两个数每次加几或减几"))
            }
        }
        if nums.count >= 3 && p.contains("、") && (p.contains("后面一个数") || p.contains("数列") || p.contains("最小的数")) {
            let tokens = nums.map(String.init) + (p.contains("后面一个数") ? ["？"] : [])
            let hint = p.contains("最小的数") ? "在数轴上越靠左越小" : "观察相邻两数之间的变化规律"
            return .numberLine(.sequence(tokens: tokens, hint: hint))
        }
        if p.contains("相邻") || p.contains("后面一个数") || p.contains("后面的一个数") || p.contains("前面一个数") || p.contains("前面的一个数") || p.contains("中间的数") || p.contains("往后数") || p.contains("往前数") || p.contains("倒着数") || p.contains("隔一个数") || p.contains("每次多数") || p.contains("每次少") || p.contains("在几十和几十之间") || (p.contains("之间") && !p.contains("还剩")) || p.contains("离") || p.contains("数轴") || p.contains("后面第") || p.contains("前面第") {
            if !p.contains("还剩") && !p.contains("一共") && !p.contains("加法表") {
                if let center = nums.first {
                    let lo = max(0, center - 4)
                    let hi = max(lo + 8, (nums.max() ?? center) + 2)
                    let spanLo = (hi - lo > 16) ? max(0, center - 5) : lo
                    let spanHi = (hi - spanLo > 16) ? spanLo + 12 : hi
                    return .numberLine(.rangeTrack(start: spanLo, end: spanHi, highlights: nums, note: "沿着数轴一格一格往左或往右数"))
                }
            }
        }
        return nil
    }

    private func detectNumberBondVisual(prompt p: String, nums: [Int]) -> VisualKind {
        let smallNums = nums.filter { $0 <= 20 }
        if (p.contains("加减法算式家族") || p.contains("组一道") || p.contains("组成的加法算式") || p.contains("组成的另一道减法算式")) && smallNums.count >= 3 {
            let trio = Array(smallNums.suffix(3)).sorted()
            return .numberBond(total: trio[2], left: trio[0], right: trio[1], hidePart: "")
        }
        if p.contains("合起来") && smallNums.count >= 2 {
            return .numberBond(total: smallNums[0] + smallNums[1], left: smallNums[0], right: smallNums[1], hidePart: "total")
        }
        if smallNums.count >= 2 {
            let total = max(smallNums[0], smallNums[1])
            let part = min(smallNums[0], smallNums[1])
            return .numberBond(total: total, left: part, right: max(0, total - part), hidePart: "right")
        }
        if let single = smallNums.first {
            return .numberBond(total: 10, left: min(10, single), right: max(0, 10 - min(10, single)), hidePart: "right")
        }
        return .numberBond(total: 10, left: 4, right: 6, hidePart: "right")
    }

    private func detectHundredBondOrSteps(prompt p: String, nums: [Int]) -> VisualKind? {
        if p.contains("里面有几个十") {
            return .placeValue(tens: 10, ones: 0, revealBreakdown: false, caption: "数一数 100 里一共有多少根整十长条")
        }
        if p.contains("添上") || p.contains("加上1就变成100") {
            let part = nums.first(where: { $0 < 100 }) ?? 90
            if p.contains("加上1") {
                return .numberBond(total: 100, left: 99, right: 1, hidePart: "left")
            }
            return .numberBond(total: 100, left: part, right: 100 - part, hidePart: "right")
        }
        if p.contains("100根小棒") {
            return .placeValue(tens: 10, ones: 0, revealBreakdown: false, caption: "一共 10 捆（100 根），捆走 7 捆后还剩几捆？")
        }
        return .multiOp(steps: buildWordProblemSteps(from: p), title: "💯 100 以内分步计算")
    }

    private func detectPlaceValueVisual(prompt p: String, topicId tid: String, nums: [Int]) -> VisualKind? {
        if tid.hasPrefix("hjm_g1a_u5_l1") || tid.hasPrefix("hjm_g1a_u5_l2") || tid.hasPrefix("hjm_g1b_u2_") {
            if p.contains("1 个十和") || p.contains("个十和") {
                if nums.count >= 2 && (nums[0] <= 9 && nums[1] <= 9) {
                    let reveal = p.contains("合起来") || p.contains("哪个数")
                    return .placeValue(
                        tens: nums[0],
                        ones: nums[1],
                        revealBreakdown: !reveal,
                        caption: "\(nums[0]) 根十位长条 + \(nums[1]) 块个位小方块"
                    )
                }
            }
            if let target = nums.first(where: { (10...100).contains($0) }) {
                let clamped = max(10, min(100, target))
                let asksTensOnes = p.contains("几个十") || p.contains("几个一")
                return .placeValue(
                    tens: clamped / 10,
                    ones: clamped % 10,
                    revealBreakdown: !asksTensOnes,
                    caption: asksTensOnes ? "观察积木的十位长条和个位方块数量" : nil
                )
            }
        }
        return nil
    }

    private func extractEquationTokens(from text: String) -> (tokens: [String], rhs: String)? {
        let pattern = #"((?:\d+|□)(?:\s*[+\-]\s*(?:\d+|□))+)\s*=\s*(?:？|\?|\d+|□)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: nsRange),
              let fullRange = Range(match.range, in: text) else { return nil }
        let compact = String(text[fullRange]).replacingOccurrences(of: " ", with: "")
        let halves = compact.components(separatedBy: "=")
        guard halves.count == 2 else { return nil }

        let tokPattern = #"[+\-]?(?:\d+|□)"#
        guard let tokRegex = try? NSRegularExpression(pattern: tokPattern) else { return nil }
        let lhs = halves[0]
        let lhsRange = NSRange(lhs.startIndex..<lhs.endIndex, in: lhs)
        let tokens = tokRegex.matches(in: lhs, range: lhsRange).compactMap { m -> String? in
            guard let r = Range(m.range, in: lhs) else { return nil }
            return String(lhs[r])
        }
        guard tokens.count >= 2 else { return nil }
        return (tokens, halves[1])
    }

    private func buildWordProblemSteps(from p: String) -> [String] {
        let pattern = #"\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [p] }
        let nsRange = NSRange(p.startIndex..<p.endIndex, in: p)
        let matches = regex.matches(in: p, range: nsRange)
        if matches.isEmpty { return [p] }

        let negKeys = ["吃", "飞走", "拿走", "送出", "送给", "分给", "花了", "花 ", "用了", "用去", "借出", "打破", "走开", "下车", "开走", "剪去", "去掉", "拆掉", "枯", "减去", "减 ", "少", "拼掉"]
        let posOverrideKeys = ["又买来", "又开来", "又来了", "飞来", "放进", "接上", "上车", "添上", "多拍", "再蒸", "再来", "一共"]
        var steps: [String] = []
        let nsStr = p as NSString

        for (idx, m) in matches.enumerated() {
            let numStr = nsStr.substring(with: m.range)
            let prevEnd = idx > 0 ? matches[idx - 1].range.location + matches[idx - 1].range.length : 0
            let clauseLen = max(0, m.range.location - prevEnd)
            let clause = nsStr.substring(with: NSRange(location: prevEnd, length: clauseLen))

            var unit = ""
            let afterStart = m.range.location + m.range.length
            let afterLen = min(2, nsStr.length - afterStart)
            if afterLen > 0 {
                let after = nsStr.substring(with: NSRange(location: afterStart, length: afterLen))
                for u in ["厘米", "元", "角", "米", "捆", "步", "拃"] {
                    if after.hasPrefix(u) {
                        unit = u
                        break
                    }
                }
            }

            if idx == 0 {
                steps.append("\(numStr)\(unit)")
            } else {
                let hasNeg = negKeys.contains(where: { clause.contains($0) })
                let hasPosOverride = posOverrideKeys.contains(where: { clause.contains($0) })
                let prefix = (hasNeg && !hasPosOverride) ? "-" : "+"
                steps.append("\(prefix)\(numStr)\(unit)")
            }
        }
        return steps
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

    private func extractHourBeforeShi(from text: String) -> Int? {
        let pattern = #"(\d+)\s*时"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: nsRange),
              match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: text),
              let val = Int(text[r]), (1...12).contains(val) else {
            return nil
        }
        return val
    }
}

// MARK: - 教具 1：双轨十格阵 (Ten-Frame 凑十法 / 破十法 / 0 的运算直观演示)
public struct TenFrameVisualView: View {
    public let firstCount: Int
    public let secondCount: Int
    public let isSubtraction: Bool

    public init(firstCount: Int, secondCount: Int, isSubtraction: Bool) {
        self.firstCount = firstCount
        self.secondCount = secondCount
        self.isSubtraction = isSubtraction
    }

    public var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(isSubtraction ? "🍓 双轨十格阵 · 破十/拿走演示" : "🍓 双轨十格阵 · 凑十/合起来演示")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Spacer()
                if isSubtraction {
                    Text("原有 \(firstCount) 颗，拿走/划掉 \(secondCount) 颗")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else if secondCount > 0 || (firstCount == 0 && secondCount == 0) {
                    Text("红果 \(firstCount) 颗 + 蓝莓 \(secondCount) 颗")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else {
                    Text("数一数十格阵里的果子")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
            }

            let totalShown = isSubtraction ? firstCount : (firstCount + secondCount)
            let frameCount = max(1, min(4, (totalShown + 9) / 10))
            if frameCount <= 2 {
                HStack(spacing: 10) {
                    singleTenFrame(frameIndex: 0)
                    if frameCount == 2 {
                        singleTenFrame(frameIndex: 1)
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(0..<frameCount, id: \.self) { idx in
                        singleTenFrame(frameIndex: idx)
                    }
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
    public let hidePart: String? // "total", "left", "right", "", or nil

    public init(total: Int, left: Int, right: Int, hidePart: String?) {
        self.total = total
        self.left = left
        self.right = right
        self.hidePart = hidePart
    }

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
                Path { path in
                    path.move(to: CGPoint(x: 65, y: 20))
                    path.addLine(to: CGPoint(x: 30, y: 58))
                    path.move(to: CGPoint(x: 65, y: 20))
                    path.addLine(to: CGPoint(x: 100, y: 58))
                }
                .stroke(Color(hex: "#E05385"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                bondCircle(
                    text: hidePart == "total" ? "？" : "\(total)",
                    isMystery: hidePart == "total",
                    color: Color(hex: "#E05385")
                )
                .position(x: 65, y: 18)

                bondCircle(
                    text: hidePart == "left" ? "？" : "\(left)",
                    isMystery: hidePart == "left",
                    color: Color(hex: "#3685D6")
                )
                .position(x: 30, y: 58)

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
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(color, lineWidth: 2.2))
            Text(text)
                .font(.system(size: text.count >= 3 ? 12 : 14.5, weight: .black, design: .rounded))
                .foregroundColor(isMystery ? Color(hex: "#D96B00") : color)
        }
    }
}

// MARK: - 教具 3：数墙金字塔 (支持 2/3/4 层与双数墙对比)
public struct NumberWallVisualView: View {
    public let bottomRow: [String]
    public let midRow: [String]
    public let topValue: String
    public let revealAnswer: Bool
    public let upperMidRow: [String]

    public init(bottomRow: [String], midRow: [String], topValue: String, revealAnswer: Bool, upperMidRow: [String] = []) {
        self.bottomRow = bottomRow
        self.midRow = midRow
        self.topValue = topValue
        self.revealAnswer = revealAnswer
        self.upperMidRow = upperMidRow
    }

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
                brickView(text: topValue, highlight: topValue == "？", width: bottomRow.count >= 4 ? 34 : 42)
                if !upperMidRow.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(Array(upperMidRow.enumerated()), id: \.offset) { _, val in
                            brickView(text: val, highlight: val == "？", width: 34)
                        }
                    }
                }
                if !midRow.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(Array(midRow.enumerated()), id: \.offset) { _, val in
                            brickView(text: val, highlight: val == "？", width: bottomRow.count >= 4 ? 34 : 42)
                        }
                    }
                }
                HStack(spacing: 3) {
                    ForEach(Array(bottomRow.enumerated()), id: \.offset) { _, val in
                        brickView(text: val, highlight: val == "？", width: bottomRow.count >= 4 ? 34 : 42)
                    }
                }
            }
        }
    }

    private func brickView(text: String, highlight: Bool, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundColor(highlight ? Color(hex: "#D96B00") : Color(hex: "#4A2E14"))
            .frame(width: width, height: 22)
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

private struct DualNumberWallVisualView: View {
    let bottomA: [String]
    let bottomB: [String]
    let revealAnswer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🧱 双数墙顶层大比拼（由底向上两两相加）")
                .font(.system(size: 11.5, weight: .heavy))
                .foregroundColor(Color(hex: "#B8336A"))
            HStack(spacing: 14) {
                miniWall(label: "数墙 A", bottom: bottomA, accent: Color(hex: "#E05385"))
                Spacer()
                Text("VS")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#D96B00"))
                Spacer()
                miniWall(label: "数墙 B", bottom: bottomB, accent: Color(hex: "#3685D6"))
            }
        }
    }

    private func miniWall(label: String, bottom: [String], accent: Color) -> some View {
        let vals = bottom.compactMap(Int.init)
        let midVals: [Int] = vals.count >= 2 ? (0..<(vals.count - 1)).map { vals[$0] + vals[$0 + 1] } : []
        let topVal: Int? = midVals.count == 2 ? (midVals[0] + midVals[1]) : (midVals.count == 1 ? midVals[0] : nil)
        return VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10.5, weight: .heavy))
                .foregroundColor(accent)
            if vals.count >= 3 {
                brick(revealAnswer ? (topVal.map(String.init) ?? "？") : "？", accent: accent, mystery: !revealAnswer)
                HStack(spacing: 2) {
                    ForEach(Array(midVals.enumerated()), id: \.offset) { _, v in
                        brick(revealAnswer ? "\(v)" : "？", accent: accent, mystery: !revealAnswer)
                    }
                }
            } else {
                brick(revealAnswer ? (topVal.map(String.init) ?? "？") : "？", accent: accent, mystery: !revealAnswer)
            }
            HStack(spacing: 2) {
                ForEach(Array(bottom.enumerated()), id: \.offset) { _, txt in
                    brick(txt, accent: accent, mystery: false)
                }
            }
        }
    }

    private func brick(_ text: String, accent: Color, mystery: Bool) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundColor(mystery ? Color(hex: "#D96B00") : Color(hex: "#4A2E14"))
            .frame(width: 32, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(mystery ? Color(hex: "#FFF0B8") : accent.opacity(0.14))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(accent.opacity(0.5), lineWidth: 1.2))
            )
    }
}

// MARK: - 教具 4：整时与半时钟表 (Clock Face —— 不提前剧透整点答案)
public struct ClockFaceVisualView: View {
    public let hour: Int
    public let isHalf: Bool
    public let revealLabel: Bool
    public let customCaption: String?

    public init(hour: Int, isHalf: Bool, revealLabel: Bool = true, customCaption: String? = nil) {
        self.hour = hour
        self.isHalf = isHalf
        self.revealLabel = revealLabel
        self.customCaption = customCaption
    }

    public var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(revealLabel ? "⏰ 滴答小钟表 · \(hour)时\(isHalf ? "半" : "")" : "⏰ 滴答小钟表 · 观察指针")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                if let caption = customCaption, !revealLabel {
                    Text(caption)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else if revealLabel {
                    Text(isHalf ? "长分针指着 6 是半时，短时针走过 \(hour) 和 \((hour % 12) + 1) 的正中间！" : "长分针指着 12 是整时，短时针指着 \(hour) 就是 \(hour) 时！")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else {
                    Text(isHalf ? "蓝色长分针指着 6（半时），看一看红色短时针刚走过几？" : "看一看红色短时针和蓝色长分针各指着数字几？")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 78, height: 78)
                    .overlay(Circle().stroke(Color(hex: "#E05385"), lineWidth: 3))

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

                let minAngle = (isHalf ? 6.0 : 0.0) * (.pi / 6.0) - (.pi / 2.0)
                Path { path in
                    path.move(to: CGPoint(x: 39, y: 39))
                    path.addLine(to: CGPoint(x: 39 + 24 * CGFloat(cos(minAngle)), y: 39 + 24 * CGFloat(sin(minAngle))))
                }
                .stroke(Color(hex: "#3685D6"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

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

    public init(startCm: Int, endCm: Int) {
        self.startCm = startCm
        self.endCm = endCm
    }

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
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Color(hex: "#FF9B44"), Color(hex: "#E05385")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, CGFloat(endCm - startCm) * step), height: 10)
                        .offset(x: 12 + CGFloat(startCm) * step, y: 2)

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

// MARK: - 教具 6：百以内数位值积木条 (完整支持 0 ~ 100，包括 10 个十 = 100)
public struct PlaceValueVisualView: View {
    public let tens: Int
    public let ones: Int
    public let revealBreakdown: Bool
    public let customCaption: String?

    public init(tens: Int, ones: Int, revealBreakdown: Bool = true, customCaption: String? = nil) {
        self.tens = tens
        self.ones = ones
        self.revealBreakdown = revealBreakdown
        self.customCaption = customCaption
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🧮 百数位值积木")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                if let custom = customCaption, !revealBreakdown {
                    Text(custom)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else if revealBreakdown {
                    Text(tens == 10 && ones == 0
                         ? "10 个十（10 根整十长条）= 100！"
                         : "\(tens) 个十（整十长条）和 \(ones) 个一（单个小方块）")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                } else {
                    Text("粉色长条每根代表 1 个十，蓝色方块每块代表 1 个一")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
            }
            Spacer()
            HStack(spacing: tens >= 9 ? 2.5 : 3) {
                ForEach(0..<max(0, min(10, tens)), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#E05385"))
                        .frame(width: tens >= 9 ? 7 : 8, height: 34)
                }
            }
            if ones > 0 {
                LazyVGrid(columns: [GridItem(.fixed(9), spacing: 2), GridItem(.fixed(9), spacing: 2), GridItem(.fixed(9), spacing: 2)], spacing: 2) {
                    ForEach(0..<max(0, min(9, ones)), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "#3685D6"))
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 34)
            }
        }
    }
}

// MARK: - 教具 7：立体/平面几何与线段端点矢量图
private enum SolidInspectKind {
    case twoCubes
    case joinedCuboids
    case cylinder
}

private enum PlaneInspectKind {
    case rectangle
    case square
    case rectangleFoldOnce
    case squareFoldTwice
    case squareCutCorner
    case twoTrianglesJoin
}

private enum GeometryVisualSpec {
    case gallery3D(highlightIndex: Int?)
    case gallery2D(highlightIndex: Int?, includeSphere: Bool)
    case solidInspect(kind: SolidInspectKind, note: String)
    case planeSingle(kind: PlaneInspectKind, note: String)
    case dotConnections(dotCount: Int, note: String)
    case shapePattern(items: [String])
}

private struct GeometryShapeVisualView: View {
    let spec: GeometryVisualSpec
    let showHint: Bool

    var body: some View {
        switch spec {
        case .gallery3D(let hi):
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("🧊 认识立体图形")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#B8336A"))
                    Text("观察哪种物体能稳稳立住、哪种四面八方都能滚")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                HStack(spacing: 8) {
                    solidBadge(idx: 0, title: "球", hi: hi) { sphereVector }
                    solidBadge(idx: 1, title: "正方体", hi: hi) { cubeVector(width: 24, height: 24) }
                    solidBadge(idx: 2, title: "长方体", hi: hi) { cubeVector(width: 32, height: 18) }
                    solidBadge(idx: 3, title: "圆柱", hi: hi) { cylinderVector }
                }
            }
        case .gallery2D(let hi, let includeSphere):
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("📐 认识平面图形")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#B8336A"))
                    Text("平面图形平平地印在纸上，对比它们的边和角")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                HStack(spacing: 8) {
                    solidBadge(idx: 0, title: "三角形", hi: hi) { triangleVector(color: Color(hex: "#E05385")) }
                    solidBadge(idx: 1, title: "正方形", hi: hi) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#3685D6").opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: "#3685D6"), lineWidth: 2))
                            .frame(width: 22, height: 22)
                    }
                    solidBadge(idx: 2, title: "长方形", hi: hi) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#3EA865").opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: "#3EA865"), lineWidth: 2))
                            .frame(width: 30, height: 18)
                    }
                    if includeSphere {
                        solidBadge(idx: 3, title: "皮球(立体)", hi: hi) { sphereVector }
                    } else {
                        solidBadge(idx: 4, title: "圆", hi: hi) {
                            Circle().fill(Color(hex: "#F07D2E").opacity(0.25))
                                .overlay(Circle().stroke(Color(hex: "#F07D2E"), lineWidth: 2))
                                .frame(width: 22, height: 22)
                        }
                    }
                }
            }
        case .solidInspect(let kind, let note):
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("🧊 立体图形特征观察")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#B8336A"))
                    Text(note)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                switch kind {
                case .twoCubes:
                    HStack(spacing: 10) {
                        cubeVector(width: 26, height: 26)
                        cubeVector(width: 26, height: 26)
                    }
                case .joinedCuboids:
                    HStack(spacing: 1) {
                        cubeVector(width: 24, height: 20)
                        cubeVector(width: 24, height: 20)
                    }
                case .cylinder:
                    cylinderVector
                        .scaleEffect(1.3)
                        .padding(.horizontal, 10)
                }
            }
        case .planeSingle(let kind, let note):
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("✂️ 折一折、剪一剪小实验")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#B8336A"))
                    Text(note)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                planeSingleGraphic(kind)
            }
        case .dotConnections(let dotCount, let note):
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("📍 端点连线段（\(dotCount) 个点）")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#B8336A"))
                    Text(note)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                dotsDiagram(dotCount: dotCount)
            }
        case .shapePattern(let items):
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("🔁 图形规律小火车")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#B8336A"))
                    Text("按顺序两个两个看规律")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#8A7765"))
                }
                Spacer()
                HStack(spacing: 5) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, symbol in
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .frame(width: 24, height: 26)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#E05385").opacity(0.4), lineWidth: 1.2))
                            if symbol == "○" {
                                Circle().stroke(Color(hex: "#E05385"), lineWidth: 2).frame(width: 13, height: 13)
                            } else {
                                triangleVector(color: Color(hex: "#3685D6")).scaleEffect(0.6)
                            }
                        }
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#FFF0B8"))
                            .frame(width: 26, height: 26)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "#F07D2E"), lineWidth: 1.5))
                        Text(showHint ? "○" : "？")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(Color(hex: "#D96B00"))
                    }
                }
            }
        }
    }

    private func solidBadge<Content: View>(idx: Int, title: String, hi: Int?, @ViewBuilder content: () -> Content) -> some View {
        let isHighlighted = (hi == idx)
        return VStack(spacing: 2) {
            content()
                .frame(height: 28)
            Text(title)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(isHighlighted ? Color(hex: "#C91E4A") : Color(hex: "#5A4634"))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isHighlighted ? Color(hex: "#FFE4EE") : Color.white.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(isHighlighted ? Color(hex: "#E03E6D") : Color(hex: "#E05385").opacity(0.25), lineWidth: isHighlighted ? 1.8 : 1))
        )
    }

    private var sphereVector: some View {
        Circle()
            .fill(RadialGradient(colors: [Color.white, Color(hex: "#FF7BA9"), Color(hex: "#C91E4A")], center: .topLeading, startRadius: 2, endRadius: 20))
            .frame(width: 24, height: 24)
    }

    private func cubeVector(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Path { path in
                let d: CGFloat = 6
                // Top face
                path.move(to: CGPoint(x: 0, y: d))
                path.addLine(to: CGPoint(x: d, y: 0))
                path.addLine(to: CGPoint(x: width + d, y: 0))
                path.addLine(to: CGPoint(x: width, y: d))
                path.closeSubpath()
            }
            .fill(Color(hex: "#B7E1FF"))
            Path { path in
                let d: CGFloat = 6
                // Front face
                path.addRect(CGRect(x: 0, y: d, width: width, height: height))
            }
            .fill(Color(hex: "#67B8F7"))
            Path { path in
                let d: CGFloat = 6
                // Right face
                path.move(to: CGPoint(x: width, y: d))
                path.addLine(to: CGPoint(x: width + d, y: 0))
                path.addLine(to: CGPoint(x: width + d, y: height))
                path.addLine(to: CGPoint(x: width, y: height + d))
                path.closeSubpath()
            }
            .fill(Color(hex: "#3685D6"))
            Path { path in
                let d: CGFloat = 6
                path.addRect(CGRect(x: 0, y: d, width: width, height: height))
                path.move(to: CGPoint(x: 0, y: d))
                path.addLine(to: CGPoint(x: d, y: 0))
                path.addLine(to: CGPoint(x: width + d, y: 0))
                path.addLine(to: CGPoint(x: width, y: d))
                path.move(to: CGPoint(x: width + d, y: 0))
                path.addLine(to: CGPoint(x: width + d, y: height))
                path.addLine(to: CGPoint(x: width, y: height + d))
            }
            .stroke(Color(hex: "#1D4F8A"), lineWidth: 1.2)
        }
        .frame(width: width + 6, height: height + 6)
    }

    private var cylinderVector: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 2, y: 6))
                path.addLine(to: CGPoint(x: 2, y: 24))
                path.addQuadCurve(to: CGPoint(x: 22, y: 24), control: CGPoint(x: 12, y: 29))
                path.addLine(to: CGPoint(x: 22, y: 6))
                path.closeSubpath()
            }
            .fill(Color(hex: "#78CE94"))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 2, y: 6))
                    path.addLine(to: CGPoint(x: 2, y: 24))
                    path.addQuadCurve(to: CGPoint(x: 22, y: 24), control: CGPoint(x: 12, y: 29))
                    path.addLine(to: CGPoint(x: 22, y: 6))
                }
                .stroke(Color(hex: "#216E3D"), lineWidth: 1.2)
            )
            Ellipse()
                .fill(Color(hex: "#B5ECC7"))
                .overlay(Ellipse().stroke(Color(hex: "#216E3D"), lineWidth: 1.2))
                .frame(width: 20, height: 8)
                .position(x: 12, y: 6)
        }
        .frame(width: 24, height: 30)
    }

    private func triangleVector(color: Color) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 12, y: 2))
            path.addLine(to: CGPoint(x: 23, y: 22))
            path.addLine(to: CGPoint(x: 1, y: 22))
            path.closeSubpath()
        }
        .fill(color.opacity(0.25))
        .overlay(
            Path { path in
                path.move(to: CGPoint(x: 12, y: 2))
                path.addLine(to: CGPoint(x: 23, y: 22))
                path.addLine(to: CGPoint(x: 1, y: 22))
                path.closeSubpath()
            }
            .stroke(color, lineWidth: 2)
        )
        .frame(width: 24, height: 24)
    }

    @ViewBuilder
    private func planeSingleGraphic(_ kind: PlaneInspectKind) -> some View {
        switch kind {
        case .rectangle:
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#3EA865").opacity(0.2))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3EA865"), lineWidth: 2.2))
                .frame(width: 58, height: 34)
        case .square:
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#3685D6").opacity(0.2))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3685D6"), lineWidth: 2.2))
                .frame(width: 38, height: 38)
        case .rectangleFoldOnce:
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#3EA865").opacity(0.2))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3EA865"), lineWidth: 2))
                Path { path in
                    path.move(to: CGPoint(x: 29, y: 2))
                    path.addLine(to: CGPoint(x: 29, y: 34))
                }
                .stroke(Color(hex: "#E03E6D"), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            }
            .frame(width: 58, height: 36)
        case .squareFoldTwice:
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#3685D6").opacity(0.2))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "#3685D6"), lineWidth: 2))
                Path { path in
                    path.move(to: CGPoint(x: 21, y: 2))
                    path.addLine(to: CGPoint(x: 21, y: 40))
                    path.move(to: CGPoint(x: 2, y: 21))
                    path.addLine(to: CGPoint(x: 40, y: 21))
                }
                .stroke(Color(hex: "#E03E6D"), style: StrokeStyle(lineWidth: 1.8, dash: [4, 3]))
            }
            .frame(width: 42, height: 42)
        case .squareCutCorner:
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 2, y: 2))
                    path.addLine(to: CGPoint(x: 26, y: 2))
                    path.addLine(to: CGPoint(x: 40, y: 16))
                    path.addLine(to: CGPoint(x: 40, y: 40))
                    path.addLine(to: CGPoint(x: 2, y: 40))
                    path.closeSubpath()
                }
                .fill(Color(hex: "#3685D6").opacity(0.22))
                .overlay(
                    Path { path in
                        path.move(to: CGPoint(x: 2, y: 2))
                        path.addLine(to: CGPoint(x: 26, y: 2))
                        path.addLine(to: CGPoint(x: 40, y: 16))
                        path.addLine(to: CGPoint(x: 40, y: 40))
                        path.addLine(to: CGPoint(x: 2, y: 40))
                        path.closeSubpath()
                    }
                    .stroke(Color(hex: "#3685D6"), lineWidth: 2)
                )
                Path { path in
                    path.move(to: CGPoint(x: 26, y: 2))
                    path.addLine(to: CGPoint(x: 40, y: 2))
                    path.addLine(to: CGPoint(x: 40, y: 16))
                }
                .stroke(Color(hex: "#E03E6D"), style: StrokeStyle(lineWidth: 1.6, dash: [3, 2]))
            }
            .frame(width: 44, height: 44)
        case .twoTrianglesJoin:
            HStack(spacing: 4) {
                triangleVector(color: Color(hex: "#E05385"))
                Text("+")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color(hex: "#8A7765"))
                triangleVector(color: Color(hex: "#3685D6"))
                    .rotationEffect(.degrees(180))
            }
        }
    }

    private func dotsDiagram(dotCount: Int) -> some View {
        let pts = dotPoints(count: dotCount, size: CGSize(width: 72, height: 52))
        return ZStack {
            if dotCount == 2 || showHint {
                Path { path in
                    for i in 0..<pts.count {
                        for j in (i + 1)..<pts.count {
                            path.move(to: pts[i])
                            path.addLine(to: pts[j])
                        }
                    }
                }
                .stroke(Color(hex: "#3685D6"), lineWidth: 1.8)
            }
            ForEach(0..<pts.count, id: \.self) { idx in
                Circle()
                    .fill(Color(hex: "#E03E6D"))
                    .frame(width: 8, height: 8)
                    .position(pts[idx])
            }
        }
        .frame(width: 72, height: 52)
    }

    private func dotPoints(count: Int, size: CGSize) -> [CGPoint] {
        if count == 2 {
            return [CGPoint(x: 10, y: size.height / 2), CGPoint(x: size.width - 10, y: size.height / 2)]
        }
        let cx = size.width / 2
        let cy = size.height / 2
        let r = min(cx, cy) - 7
        return (0..<count).map { i in
            let angle = (Double(i) / Double(count)) * (2.0 * .pi) - (.pi / 2.0)
            return CGPoint(x: cx + r * CGFloat(cos(angle)), y: cy + r * CGFloat(sin(angle)))
        }
    }
}

// MARK: - 教具 8：彩旗循环与间隔插旗演示
private enum FlagLineSpec {
    case cycle(colors: [String], askIndex: Int)
    case spacing(startMeter: Int, intervalMeters: Int, caption: String, flagColors: [String])
}

private struct FlagLineVisualView: View {
    let spec: FlagLineSpec
    let showHint: Bool

    var body: some View {
        switch spec {
        case .cycle(let colors, let askIndex):
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("🚩 彩旗循环找规律（\(colors.count) 面一组）")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color(hex: "#B8336A"))
                    Spacer()
                    Text("第 \(askIndex) 面 = ？")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(hex: "#D96B00"))
                }
                HStack(spacing: 6) {
                    ForEach(0..<max(4, colors.count * 2), id: \.self) { idx in
                        let cName = colors[idx % colors.count]
                        VStack(spacing: 1) {
                            pennantFlag(color: swiftColor(for: cName))
                            Text("\(idx + 1)")
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#8A7765"))
                        }
                    }
                    Text("··· 第 \(askIndex) 面？")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(Color(hex: "#B8336A"))
                }
            }
        case .spacing(let startMeter, let intervalMeters, let caption, let flagColors):
            VStack(alignment: .leading, spacing: 5) {
                Text("🚩 彩旗与间隔演示")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { idx in
                        VStack(spacing: 1) {
                            pennantFlag(color: swiftColor(for: flagColors[idx % flagColors.count]))
                            Text("\(startMeter + idx * max(1, intervalMeters))m")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(Color(hex: "#5A4634"))
                        }
                        if idx < 3 {
                            Text(intervalMeters > 0 ? "↔\(intervalMeters)m" : "↔间隔")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "#3685D6"))
                        }
                    }
                    Spacer()
                    Text(caption)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#8A7765"))
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private func swiftColor(for name: String) -> Color {
        switch name {
        case "红": return Color(hex: "#E24957")
        case "黄": return Color(hex: "#F5B82E")
        case "蓝": return Color(hex: "#3685D6")
        default: return Color(hex: "#3EA865")
        }
    }

    private func pennantFlag(color: Color) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Color(hex: "#5A4634")).frame(width: 2, height: 18)
            Path { path in
                path.move(to: CGPoint(x: 2, y: 1))
                path.addLine(to: CGPoint(x: 15, y: 6))
                path.addLine(to: CGPoint(x: 2, y: 11))
                path.closeSubpath()
            }
            .fill(color)
        }
        .frame(width: 16, height: 18)
    }
}

// MARK: - 教具 9：身体上的尺子 / 测量单位 / 数字卡片
private struct BodyRulerVisualView: View {
    let unitName: String
    let formulaText: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🖐️ 身体尺测量 · \(unitName)")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text(formulaText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            Spacer()
            HStack(spacing: 6) {
                unitBadge(icon: "🖐️", label: "一拃")
                unitBadge(icon: "🦶", label: "一步")
                unitBadge(icon: "🙌", label: "一庹")
            }
        }
    }

    private func unitBadge(icon: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(icon).font(.system(size: 15))
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(Color(hex: "#5A4634"))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.white))
    }
}

private struct MeasurementUnitVisualView: View {
    let itemText: String
    let options: [String]
    let answer: String?

    var body: some View {
        HStack(spacing: 10) {
            Text("📏 选合适单位")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(Color(hex: "#B8336A"))
            Spacer()
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { opt in
                    let isAns = (answer == opt)
                    Text(opt)
                        .font(.system(size: 11.5, weight: .bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isAns ? Color(hex: "#DDF5E6") : Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isAns ? Color(hex: "#3EA865") : Color(hex: "#E05385").opacity(0.3), lineWidth: 1.2))
                }
            }
        }
    }
}

private struct DigitCardsVisualView: View {
    let digits: [Int]
    let goalText: String
    let revealText: String?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🃏 数字卡片组数")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text(revealText.map { "提示答案：\($0)" } ?? goalText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(Array(digits.enumerated()), id: \.offset) { _, d in
                    Text("\(d)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#4A2E14"))
                        .frame(width: 28, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color(hex: "#FFF5D6"))
                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#D9953B"), lineWidth: 1.6))
                        )
                }
            }
        }
    }
}

// MARK: - 教具 10：算式筛选 / 符号对比卡
private struct ExpressionCompareVisualView: View {
    let leftText: String?
    let rightText: String?
    let candidates: [String]
    let highlightAnswer: String?
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11.5, weight: .heavy))
                .foregroundColor(Color(hex: "#B8336A"))
            if let l = leftText, let r = rightText {
                HStack(spacing: 10) {
                    Spacer()
                    pill(l, highlight: false)
                    Text(highlightAnswer ?? "○")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(highlightAnswer == nil ? Color(hex: "#D96B00") : Color(hex: "#3EA865"))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color(hex: "#FFF3C4")))
                    pill(r, highlight: false)
                    Spacer()
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(candidates, id: \.self) { item in
                        pill(item, highlight: highlightAnswer == item)
                    }
                }
            }
        }
    }

    private func pill(_ text: String, highlight: Bool) -> some View {
        Text(text)
            .font(.system(size: 12.5, weight: .bold, design: .rounded))
            .foregroundColor(highlight ? Color(hex: "#1E7442") : Color(hex: "#4A2E14"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(highlight ? Color(hex: "#DDF5E6") : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(highlight ? Color(hex: "#3EA865") : Color(hex: "#E05385").opacity(0.35), lineWidth: 1.3))
            )
    }
}

// MARK: - 教具 11：排队序号点阵演示
private struct QueueSpec {
    let totalCount: Int
    let labelNumbers: [Int]
    let note: String
}

private struct QueueVisualView: View {
    let spec: QueueSpec
    let showHint: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("🐥 排队位置示意图")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Spacer()
                Text(spec.note)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            HStack(spacing: 4) {
                Text("左")
                    .font(.system(size: 9.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#3685D6"))
                ForEach(1...min(10, max(5, spec.totalCount)), id: \.self) { idx in
                    Circle()
                        .fill(Color(hex: "#FFE4EE"))
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color(hex: "#E05385").opacity(0.6), lineWidth: 1.2))
                        .overlay(
                            Text("\(idx)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#5A4634"))
                        )
                }
                Text("右")
                    .font(.system(size: 9.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#3EA865"))
            }
        }
    }
}

// MARK: - 教具 12：排序卡片 / 文字长短线索 / 无截断比例条形对比
private enum ComparisonSpec {
    case sortCards(values: [Int], ascending: Bool)
    case wordClues(clues: [String], promptTitle: String)
    case numericPair(left: Int, right: Int, askText: String)
}

private struct ComparisonVisualView: View {
    let spec: ComparisonSpec
    let revealAnswer: String?

    var body: some View {
        switch spec {
        case .sortCards(let values, let ascending):
            SortCardsComparisonRow(
                values: values,
                ascending: ascending,
                isRevealed: revealAnswer != nil
            )
        case .wordClues(let clues, let promptTitle):
            WordCluesComparisonRow(clues: clues, promptTitle: promptTitle)
        case .numericPair(let left, let right, let askText):
            NumericPairComparisonRow(
                left: left,
                right: right,
                askText: askText,
                revealAnswer: revealAnswer
            )
        }
    }
}

private struct SortCardsComparisonRow: View {
    let values: [Int]
    let ascending: Bool
    let isRevealed: Bool

    private var displayValues: [Int] {
        guard isRevealed else { return values }
        return ascending ? values.sorted() : values.sorted(by: >)
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ascending ? "📶 从小到大排队" : "📶 从大到小排队")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text(ascending ? "左小 → 右大" : "左大 → 右小")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            Spacer()
            HStack(spacing: 5) {
                ForEach(Array(displayValues.enumerated()), id: \.offset) { _, val in
                    sortTile(val)
                }
            }
        }
    }

    private func sortTile(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 13.5, weight: .black, design: .rounded))
            .foregroundColor(Color(hex: "#4A2E14"))
            .frame(minWidth: 26, minHeight: 28)
            .padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#3685D6").opacity(0.45), lineWidth: 1.3))
    }
}

private struct WordCluesComparisonRow: View {
    let clues: [String]
    let promptTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(promptTitle)
                .font(.system(size: 11.5, weight: .heavy))
                .foregroundColor(Color(hex: "#B8336A"))
            HStack(spacing: 6) {
                ForEach(Array(clues.prefix(3).enumerated()), id: \.offset) { idx, clue in
                    Text("\(idx + 1). \(clue)")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Color(hex: "#5A4634"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white))
                }
            }
        }
    }
}

private struct NumericPairComparisonRow: View {
    let left: Int
    let right: Int
    let askText: String
    let revealAnswer: String?

    private var headerRightText: String {
        if let ans = revealAnswer {
            return "答案：\(ans)"
        }
        return askText
    }

    private func scaledBarWidth(value: Int, totalWidth: CGFloat) -> CGFloat {
        let maxVal: CGFloat = CGFloat(max(1, max(left, right)))
        let maxBarW: CGFloat = max(60, totalWidth - 54)
        return max(8, maxBarW * CGFloat(value) / maxVal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("📊 数量条形对照")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Spacer()
                Text(headerRightText)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 4) {
                    barRow(value: left, color: Color(hex: "#E05385"), textColor: Color(hex: "#E03E6D"), totalWidth: geo.size.width)
                    barRow(value: right, color: Color(hex: "#3685D6"), textColor: Color(hex: "#3685D6"), totalWidth: geo.size.width)
                }
            }
            .frame(height: 30)
        }
    }

    private func barRow(value: Int, color: Color, textColor: Color, totalWidth: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(textColor)
                .frame(width: 32, alignment: .trailing)
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: scaledBarWidth(value: value, totalWidth: totalWidth), height: 12)
        }
    }
}

// MARK: - 教具 13：数列格子与数轴定位教具
private enum NumberLineSpec {
    case sequence(tokens: [String], hint: String)
    case rangeTrack(start: Int, end: Int, highlights: [Int], note: String)
}

private struct NumberLineVisualView: View {
    let spec: NumberLineSpec
    let revealAnswer: String?

    var body: some View {
        switch spec {
        case .sequence(let tokens, let hint):
            NumberSequenceRow(tokens: tokens, hint: hint, revealAnswer: revealAnswer)
        case .rangeTrack(let start, let end, let highlights, let note):
            NumberTrackRow(start: start, end: end, highlights: highlights, note: note)
        }
    }
}

private struct NumberSequenceRow: View {
    let tokens: [String]
    let hint: String
    let revealAnswer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("🚂 找规律数字列车")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Spacer()
                Text(hint)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            HStack(spacing: 5) {
                ForEach(Array(tokens.enumerated()), id: \.offset) { _, tok in
                    sequenceTile(tok)
                }
            }
        }
    }

    private func sequenceTile(_ tok: String) -> some View {
        let isMystery = (tok == "？")
        let shown: String = isMystery ? (revealAnswer ?? "？") : tok
        let fg: Color = isMystery ? Color(hex: "#D96B00") : Color(hex: "#4A2E14")
        let bg: Color = isMystery ? Color(hex: "#FFF0B8") : Color.white
        let border: Color = isMystery ? Color(hex: "#F07D2E") : Color(hex: "#E05385").opacity(0.4)
        return Text(shown)
            .font(.system(size: 13.5, weight: .black, design: .rounded))
            .foregroundColor(fg)
            .frame(minWidth: 26, minHeight: 26)
            .padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 7).fill(bg))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(border, lineWidth: 1.4))
    }
}

private struct NumberTrackRow: View {
    let start: Int
    let end: Int
    let highlights: [Int]
    let note: String

    private var ticks: [Int] {
        let safeEnd = max(start + 1, end)
        let strideStep = (safeEnd - start > 14) ? 2 : 1
        return Array(stride(from: start, through: safeEnd, by: strideStep))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("🧭 数轴小路（左小 → 右大）")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Spacer()
                Text(note)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            HStack(spacing: 3) {
                ForEach(ticks, id: \.self) { val in
                    trackTick(val)
                }
            }
        }
    }

    private func trackTick(_ val: Int) -> some View {
        let isHi = highlights.contains(val)
        let fg: Color = isHi ? Color.white : Color(hex: "#5A4634")
        let bg: Color = isHi ? Color(hex: "#E05385") : Color.white
        let wt: Font.Weight = isHi ? .black : .semibold
        return Text("\(val)")
            .font(.system(size: 10.5, weight: wt, design: .rounded))
            .foregroundColor(fg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 5).fill(bg))
    }
}

// MARK: - 教具 14：等分点数 / 多步流程卡 / 星星数数
private struct DotGroupsVisualView: View {
    let total: Int
    let groupSize: Int
    let showGroupCount: Bool

    var body: some View {
        let groupCount = max(1, total / max(1, groupSize))
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🔵 按每 \(groupSize) 个圈一组")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text(showGroupCount ? "一共可以圈成 \(groupCount) 组！" : "数一数一共有几份？")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<groupCount, id: \.self) { _ in
                    HStack(spacing: 3) {
                        ForEach(0..<groupSize, id: \.self) { _ in
                            Circle().fill(Color(hex: "#3685D6")).frame(width: 10, height: 10)
                        }
                    }
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#3685D6").opacity(0.6), lineWidth: 1.3))
                }
            }
        }
    }
}

private struct MultiOpFlowVisualView: View {
    let steps: [String]
    let title: String
    let answer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11.5, weight: .heavy))
                .foregroundColor(Color(hex: "#B8336A"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                        if idx > 0 && !step.hasPrefix("=") {
                            Text("→")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(Color(hex: "#8A7765"))
                        }
                        let isNeg = step.hasPrefix("-")
                        let isPos = step.hasPrefix("+")
                        Text(step)
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                            .foregroundColor(isNeg ? Color(hex: "#C91E4A") : (isPos ? Color(hex: "#1E7442") : Color(hex: "#4A2E14")))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isNeg ? Color(hex: "#FFE6EC") : (isPos ? Color(hex: "#E6F8ED") : Color.white))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#E05385").opacity(0.35), lineWidth: 1.2))
                            )
                    }
                    if !(steps.last?.hasPrefix("=") ?? false) {
                        Text("=")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color(hex: "#8A7765"))
                        Text(answer ?? "？")
                            .font(.system(size: 13.5, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#D96B00"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#FFF0B8")))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#F07D2E"), lineWidth: 1.4))
                    }
                }
            }
        }
    }
}

private struct StarCountVisualView: View {
    let filled: Int
    let empty: Int
    let totalHint: String?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("⭐ 星星数一数")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#B8336A"))
                Text(totalHint.map { "一共有 \($0) 颗星星！" } ?? "指着一颗一颗慢慢数，不要数漏了")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A7765"))
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<max(0, filled), id: \.self) { _ in
                    Text("★").font(.system(size: 18)).foregroundColor(Color(hex: "#F5A623"))
                }
                ForEach(0..<max(0, empty), id: \.self) { _ in
                    Text("☆").font(.system(size: 18)).foregroundColor(Color(hex: "#F5A623"))
                }
            }
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
