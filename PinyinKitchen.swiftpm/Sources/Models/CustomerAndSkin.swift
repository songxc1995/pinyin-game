import SwiftUI

// MARK: - 森林小动物餐厅顾客
public enum CustomerMood: Sendable {
    case waiting
    case happy
    case burnt
}

public struct AnimalCustomer: Identifiable, Equatable, Sendable {
    public let id: String
    public let emoji: String
    public let name: String
    public let title: String
    public let accentHex: String
    public let favoriteDishType: String

    public static let all: [AnimalCustomer] = [
        AnimalCustomer(id: "rabbit",  emoji: "🐰", name: "朵朵", title: "小白兔食客", accentHex: "#E05385", favoriteDishType: "鲜甜脆脆锅"),
        AnimalCustomer(id: "panda",   emoji: "🐼", name: "团子", title: "胖熊猫美食家", accentHex: "#3EA865", favoriteDishType: "竹叶清香煲"),
        AnimalCustomer(id: "fox",     emoji: "🦊", name: "阿狸", title: "小狐狸探长", accentHex: "#F07D2E", favoriteDishType: "蜜汁烧烤锅"),
        AnimalCustomer(id: "frog",    emoji: "🐸", name: "呱呱", title: "荷叶小歌手", accentHex: "#2FB380", favoriteDishType: "荷塘咕嘟汤"),
        AnimalCustomer(id: "tiger",   emoji: "🐯", name: "威威", title: "森林小虎王", accentHex: "#E8873B", favoriteDishType: "能量黄金煲"),
        AnimalCustomer(id: "koala",   emoji: "🐨", name: "抱抱", title: "桉树小睡神", accentHex: "#7A6EE6", favoriteDishType: "暖心软绵粥"),
        AnimalCustomer(id: "penguin", emoji: "🐧", name: "波波", title: "冰川小绅士", accentHex: "#3685D6", favoriteDishType: "极地海鲜锅"),
        AnimalCustomer(id: "unicorn", emoji: "🦄", name: "星宝", title: "彩虹独角兽", accentHex: "#9B6EF3", favoriteDishType: "星光彩虹汤")
    ]

    public func orderLine(for char: String, phrase: String, blind: Bool) -> String {
        if blind {
            return "「神秘点单！先听声音，猜猜我想点哪道菜？」"
        }
        return "「大厨你好！我想点一份【\(phrase)】里的『\(char)』字料理！」"
    }

    public func happyLine(for char: String, phrase: String) -> String {
        let lines = [
            "「哇！香喷喷的『\(char) · \(phrase)』出锅啦，太美味了！」",
            "「咕嘟咕嘟好香呀！给你一颗闪亮大金星 ⭐」",
            "「这锅『\(char)』字汤火候刚刚好，大厨手艺真棒！」"
        ]
        return lines[abs(char.hashValue) % lines.count]
    }

    public func burntLine(isToneError: Bool, rightTone: Int) -> String {
        if isToneError {
            return "「咳咳～食材都选对啦，但调料要撒第 \(rightTone) 声哦！」"
        }
        return "「哎呀，锅里冒小黑烟啦～我们看准绿色提示重做一锅吧！」"
    }
}

// MARK: - 四声调料瓶定义
public struct ToneSeasoningBottle: Identifiable, Sendable {
    public let id: Int // 1...4
    public let name: String
    public let markSymbol: String
    public let gestureHint: String
    public let bottleEmoji: String
    public let colorHex: String

    public static let all: [ToneSeasoningBottle] = [
        ToneSeasoningBottle(id: 1, name: "一声平", markSymbol: "—", gestureHint: "小车平平开", bottleEmoji: "🧂", colorHex: "#3685D6"),
        ToneSeasoningBottle(id: 2, name: "二声扬", markSymbol: "／", gestureHint: "小车上山坡", bottleEmoji: "🍯", colorHex: "#3EA865"),
        ToneSeasoningBottle(id: 3, name: "三声拐弯", markSymbol: "∨", gestureHint: "下坡又上坡", bottleEmoji: "🧀", colorHex: "#F07D2E"),
        ToneSeasoningBottle(id: 4, name: "四声降", markSymbol: "＼", gestureHint: "小车滑下坡", bottleEmoji: "🍅", colorHex: "#E25247")
    ]
}

// MARK: - 5 款可解锁魔法锅具皮肤
public struct PotSkin: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let needStars: Int
    public let bodyHex: String
    public let rimHex: String
    public let lidHex: String
    public let knobHex: String
    public let earHex: String

    public static let all: [PotSkin] = [
        PotSkin(id: "classic", name: "番茄红锅",   needStars: 0,  bodyHex: "#E2574C", rimHex: "#C0392B", lidHex: "#D96B43", knobHex: "#F5B82E", earHex: "#C85A32"),
        PotSkin(id: "pumpkin", name: "南瓜魔法锅", needStars: 3,  bodyHex: "#F08A24", rimHex: "#C8640A", lidHex: "#F5A623", knobHex: "#4CAF50", earHex: "#B85A08"),
        PotSkin(id: "mint",    name: "翡翠薄荷锅", needStars: 8,  bodyHex: "#2FB380", rimHex: "#1E8A5E", lidHex: "#4CC998", knobHex: "#FFE082", earHex: "#1D7A53"),
        PotSkin(id: "sakura",  name: "樱花甜心锅", needStars: 15, bodyHex: "#EC6EAD", rimHex: "#C84B89", lidHex: "#F48FB1", knobHex: "#FFF59D", earHex: "#B83D79"),
        PotSkin(id: "dragon",  name: "黄金小当家", needStars: 22, bodyHex: "#F5B82E", rimHex: "#C8870A", lidHex: "#FFD54F", knobHex: "#E53935", earHex: "#B57806")
    ]
}

// MARK: - 火候难度与厨神头衔
public enum FireDifficulty: String, CaseIterable, Codable, Sendable {
    case low  = "low"
    case mid  = "mid"
    case high = "high"

    public var name: String {
        switch self {
        case .low:  return "小火"
        case .mid:  return "中火"
        case .high: return "大火"
        }
    }

    public var questionCount: Int {
        switch self {
        case .low:  return 8
        case .mid:  return 10
        case .high: return 12
        }
    }

    public var retryAllowance: Int {
        switch self {
        case .low:  return 2
        case .mid:  return 2
        case .high: return 3
        }
    }

    public var fashionRolls: Int {
        self == .high ? 2 : 1
    }

    public var rareBoost: Double {
        switch self {
        case .low:  return 0.40
        case .mid:  return 0.45
        case .high: return 0.65
        }
    }

    public var desc: String {
        "\(questionCount) 道题 · \(retryAllowance) 次回锅"
    }

    public var tip: String {
        switch self {
        case .low:  return "第一次玩这一关，选它最稳"
        case .mid:  return "大多数时候选这个，刚刚好"
        case .high: return "👗 华服礼盒翻倍！高定衣饰更容易出"
        }
    }
}

public struct ChefRankMilestone: Identifiable, Equatable, Sendable {
    public var id: Int { level }
    public let level: Int
    public let minStars: Int
    public let name: String
    public let rewardCoins: Int
    public let rewardTickets: Int
    public let rewardStarThread: Int
    public let rewardPetCandy: Int
    public let rewardDesc: String

    public static let all: [ChefRankMilestone] = [
        ChefRankMilestone(
            level: 0, minStars: 0, name: "🎀 甜心小学徒",
            rewardCoins: 0, rewardTickets: 0, rewardStarThread: 0, rewardPetCandy: 0,
            rewardDesc: "初始启程头衔"
        ),
        ChefRankMilestone(
            level: 1, minStars: 8, name: "🍓 掌勺小厨娘",
            rewardCoins: 100, rewardTickets: 1, rewardStarThread: 1, rewardPetCandy: 0,
            rewardDesc: "+100 🪙 +1 🎟️ +1 🧵"
        ),
        ChefRankMilestone(
            level: 2, minStars: 18, name: "🧁 星光甜点师",
            rewardCoins: 120, rewardTickets: 1, rewardStarThread: 1, rewardPetCandy: 0,
            rewardDesc: "+120 🪙 +1 🎟️ +1 🧵"
        ),
        ChefRankMilestone(
            level: 3, minStars: 30, name: "🪄 魔法料理师",
            rewardCoins: 150, rewardTickets: 1, rewardStarThread: 0, rewardPetCandy: 1,
            rewardDesc: "+150 🪙 +1 🎟️ +1 🌟"
        ),
        ChefRankMilestone(
            level: 4, minStars: 45, name: "👑 皇家小主厨",
            rewardCoins: 180, rewardTickets: 2, rewardStarThread: 1, rewardPetCandy: 0,
            rewardDesc: "+180 🪙 +2 🎟️ +1 🧵"
        ),
        ChefRankMilestone(
            level: 5, minStars: 62, name: "💎 璀璨料理公主",
            rewardCoins: 220, rewardTickets: 2, rewardStarThread: 0, rewardPetCandy: 1,
            rewardDesc: "+220 🪙 +2 🎟️ +1 🌟"
        ),
        ChefRankMilestone(
            level: 6, minStars: 80, name: "✨ 传奇全能女王",
            rewardCoins: 260, rewardTickets: 2, rewardStarThread: 2, rewardPetCandy: 0,
            rewardDesc: "+260 🪙 +2 🎟️ +2 🧵"
        ),
        ChefRankMilestone(
            level: 7, minStars: 90, name: "🌈 料理城大圆满女王",
            rewardCoins: 300, rewardTickets: 3, rewardStarThread: 2, rewardPetCandy: 2,
            rewardDesc: "+300 🪙 +3 🎟️ +2 🧵 +2 🌟"
        )
    ]
}

public struct ChefRankInfo: Sendable {
    public let level: Int
    public let name: String
    public let currentMinStars: Int
    public let nextRankName: String?
    public let nextMinStars: Int?
    public let progressPercent: Double

    public var currentMilestone: ChefRankMilestone {
        ChefRankMilestone.all.first(where: { $0.level == level }) ?? ChefRankMilestone.all[0]
    }

    public static func compute(totalStars: Int) -> ChefRankInfo {
        let ranks = ChefRankMilestone.all
        var lv = 0
        for (i, r) in ranks.enumerated() where totalStars >= r.minStars {
            lv = i
        }
        let cur = ranks[lv]
        if lv + 1 < ranks.count {
            let nx = ranks[lv + 1]
            let pct = min(1.0, max(0.0, Double(totalStars - cur.minStars) / Double(nx.minStars - cur.minStars)))
            return ChefRankInfo(
                level: lv,
                name: cur.name,
                currentMinStars: cur.minStars,
                nextRankName: nx.name,
                nextMinStars: nx.minStars,
                progressPercent: pct
            )
        } else {
            return ChefRankInfo(
                level: lv,
                name: cur.name,
                currentMinStars: cur.minStars,
                nextRankName: nil,
                nextMinStars: nil,
                progressPercent: 1.0
            )
        }
    }
}

// MARK: - 颜色 Hex 辅助扩展
extension Color {
    public init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (240, 125, 46)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }
}
