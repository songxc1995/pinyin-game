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

// MARK: - 20 种蝴蝶图鉴与 3 阶进化
public struct ButterflySpecies: Identifiable, Equatable, Sendable {
    public let id: String   // 对应原版 t
    public let name: String
    public let primaryHex: String
    public let secondaryHex: String
    public let rarity: Int  // 1 普通 / 2 漂亮 / 3 稀有

    public var rarityName: String {
        switch rarity {
        case 3: return "稀有"
        case 2: return "漂亮"
        default: return "普通"
        }
    }

    public static let evolutionThresholds = [0, 1, 3, 6]
    public static func stageName(for stage: Int) -> String {
        switch stage {
        case 3: return "华丽"
        case 2: return "闪耀"
        case 1: return "初见"
        default: return "未见过"
        }
    }

    public static let all: [ButterflySpecies] = [
        ButterflySpecies(id: "r", name: "辣椒红",   primaryHex: "#D2544B", secondaryHex: "#F09595", rarity: 1),
        ButterflySpecies(id: "o", name: "南瓜橙",   primaryHex: "#E8873B", secondaryHex: "#FAC775", rarity: 1),
        ButterflySpecies(id: "y", name: "柠檬黄",   primaryHex: "#EF9F27", secondaryHex: "#FAE3A8", rarity: 1),
        ButterflySpecies(id: "g", name: "青苹果",   primaryHex: "#639922", secondaryHex: "#C0DD97", rarity: 1),
        ButterflySpecies(id: "m", name: "薄荷绿",   primaryHex: "#1D9E75", secondaryHex: "#9FE1CB", rarity: 1),
        ButterflySpecies(id: "b", name: "天空蓝",   primaryHex: "#378ADD", secondaryHex: "#B5D4F4", rarity: 1),
        ButterflySpecies(id: "p", name: "紫葡萄",   primaryHex: "#7F77DD", secondaryHex: "#CECBF6", rarity: 1),
        ButterflySpecies(id: "k", name: "樱花粉",   primaryHex: "#D4537E", secondaryHex: "#F4C0D1", rarity: 2),
        ButterflySpecies(id: "s", name: "海水双色", primaryHex: "#0F6E56", secondaryHex: "#85B7EB", rarity: 2),
        ButterflySpecies(id: "w", name: "雪花白",   primaryHex: "#5F5E5A", secondaryHex: "#EFEDE7", rarity: 2),
        ButterflySpecies(id: "d", name: "金翅蝶",   primaryHex: "#BA7517", secondaryHex: "#FAC775", rarity: 3),
        ButterflySpecies(id: "h", name: "彩虹蝶",   primaryHex: "#D4537E", secondaryHex: "#378ADD", rarity: 3),
        ButterflySpecies(id: "a", name: "玫瑰粉",   primaryHex: "#E86A8F", secondaryHex: "#F9C9D6", rarity: 2),
        ButterflySpecies(id: "c", name: "珊瑚橘",   primaryHex: "#F2704A", secondaryHex: "#FBC9A6", rarity: 1),
        ButterflySpecies(id: "e", name: "翡翠青",   primaryHex: "#2FA38A", secondaryHex: "#A9E6D6", rarity: 2),
        ButterflySpecies(id: "f", name: "火焰红",   primaryHex: "#C0392B", secondaryHex: "#F5B041", rarity: 3),
        ButterflySpecies(id: "i", name: "靛青蓝",   primaryHex: "#3C4F9E", secondaryHex: "#A9B6EE", rarity: 2),
        ButterflySpecies(id: "j", name: "芥末黄",   primaryHex: "#C9A227", secondaryHex: "#F2E49C", rarity: 1),
        ButterflySpecies(id: "l", name: "薰衣草",   primaryHex: "#9B7FD4", secondaryHex: "#DCCEF7", rarity: 1),
        ButterflySpecies(id: "n", name: "夜空蓝",   primaryHex: "#1B3A6B", secondaryHex: "#7FA8E8", rarity: 3)
    ]

    public static func byId(_ id: String) -> ButterflySpecies {
        all.first(where: { $0.id == id }) ?? all[0]
    }
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

    public var butterflyRolls: Int {
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

public struct ChefRankInfo: Sendable {
    public let level: Int
    public let name: String
    public let currentMinStars: Int
    public let nextRankName: String?
    public let nextMinStars: Int?
    public let progressPercent: Double

    public static func compute(totalStars: Int) -> ChefRankInfo {
        let ranks: [(min: Int, name: String)] = [
            (0,  "🎀 甜心小学徒"),
            (8,  "🍓 掌勺小厨娘"),
            (18, "🧁 星光甜点师"),
            (30, "🪄 魔法料理师"),
            (45, "👑 皇家小主厨"),
            (62, "💎 璀璨料理公主"),
            (80, "🌈 传奇全能女王")
        ]
        var lv = 0
        for (i, r) in ranks.enumerated() where totalStars >= r.min {
            lv = i
        }
        let cur = ranks[lv]
        if lv + 1 < ranks.count {
            let nx = ranks[lv + 1]
            let pct = min(1.0, max(0.0, Double(totalStars - cur.min) / Double(nx.min - cur.min)))
            return ChefRankInfo(level: lv, name: cur.name, currentMinStars: cur.min, nextRankName: nx.name, nextMinStars: nx.min, progressPercent: pct)
        } else {
            return ChefRankInfo(level: lv, name: cur.name, currentMinStars: cur.min, nextRankName: nil, nextMinStars: nil, progressPercent: 1.0)
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
