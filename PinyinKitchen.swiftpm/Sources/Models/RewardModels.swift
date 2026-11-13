import SwiftUI

// MARK: - 守护萌宠精灵种类枚举（全矢量骨骼级动态绘制）
public enum GuardianPetKind: String, Codable, CaseIterable, Sendable {
    case fireDragon   = "fire_dragon"
    case unicorn      = "unicorn"
    case whale        = "whale"
    case nineTailFox  = "nine_tail_fox"
    case pandaChef    = "panda_chef"
    case moonRabbit   = "moon_rabbit"
    case luckyCat     = "lucky_cat"
    case corgiPilot   = "corgi_pilot"
    case owlDoctor    = "owl_doctor"
    case auroraDeer   = "aurora_deer"
    case phoenix      = "phoenix"
    case azureDragon  = "azure_dragon"
}

// MARK: - 12 只动态守护萌宠精灵定义
public struct GuardianPetSpecies: Identifiable, Equatable, Sendable {
    public let id: String
    public let kind: GuardianPetKind
    public let name: String
    public let title: String
    public let rarity: Int // 1 史诗 / 2 传说 / 3 神话
    public let primaryHex: String
    public let secondaryHex: String
    public let accentHex: String
    public let favoriteFood: String
    public let baseCoinPerQuestion: Int
    public let skillShortTag: String
    public let skillDesc: String
    public let cheerLine: String

    public var rarityName: String {
        switch rarity {
        case 3: return "神话"
        case 2: return "传说"
        default: return "史诗"
        }
    }

    public var rarityColorHex: String {
        switch rarity {
        case 3: return "#E25247"
        case 2: return "#F07D2E"
        default: return "#7A6EE6"
        }
    }

    public func effectiveSkillSummary(forStage stage: Int) -> String {
        let mult = stage >= 4 ? 2 : 1
        let coin = baseCoinPerQuestion * mult
        let prefix = stage >= 4 ? "👑 4阶翻倍生效中 · " : ""
        switch kind {
        case .fireDragon:
            return "\(prefix)每答对 1 题额外 +\(coin) 🪙"
        case .unicorn:
            return "\(prefix)每题 +\(coin) 🪙，3连击起额外 +1 彩虹能量 & 满槽 +\(10 * mult) 🪙"
        case .nineTailFox:
            return "\(prefix)每题 +\(coin) 🪙，\(15 * mult)% 概率灵感爆发 +\(12 * mult) 🪙"
        case .azureDragon:
            return "\(prefix)每题 +\(coin) 🪙，连击额外每层 +\(mult) 🪙（至多 +\(5 * mult)）"
        case .phoenix:
            return "\(prefix)每题 +\(coin) 🪙，每局保护连击不断 \(mult) 次"
        case .pandaChef:
            return "\(prefix)每题 +\(coin) 🪙，拼音/数学首答正确额外 +\(3 * mult) 🪙"
        case .whale:
            return "\(prefix)每题 +\(coin) 🪙，彩虹宝箱额外喷出 +\(12 * mult) 🪙"
        case .luckyCat:
            return "\(prefix)每题 +\(coin) 🪙，\(18 * mult)% 概率触发此题星币双倍"
        case .owlDoctor:
            return "\(prefix)每题 +\(coin) 🪙，攻克错题额外 +\(15 * mult) 🪙"
        case .auroraDeer:
            return "\(prefix)每题 +\(coin) 🪙，高阶华服掉落率 +\(15 * mult)%"
        case .moonRabbit:
            return "\(prefix)每题 +\(coin) 🪙，英语首答正确额外 +\(3 * mult) 🪙"
        case .corgiPilot:
            return "\(prefix)每题 +\(coin) 🪙，通关结算速递 +\(15 * mult) 🪙"
        }
    }

    // 5 阶 RPG 递进式养成阈值：越往后升级越具挑战性，进化后特效呈指数级华丽蜕变
    public static let stageThresholds = [0, 1, 4, 10, 20, 35]
    public static let maxStage = 5

    public static func stageName(for stage: Int) -> String {
        switch stage {
        case 5: return "🌈 至尊幻兽"
        case 4: return "👑 皇冠神兽"
        case 3: return "⭐ 星辉圣兽"
        case 2: return "🌱 闪耀灵兽"
        case 1: return "🥚 萌芽幼崽"
        default: return "未孵化"
        }
    }

    public static func stageVisualPerk(for stage: Int) -> String {
        switch stage {
        case 5: return "九彩极光大法阵 + 双层流光神翼 + 宝石皇冠 + 漫天星雨"
        case 4: return "悬浮黄金皇冠 + 璀璨护体金盾 + 伴读技能与星币加成翻倍"
        case 3: return "旋转星芒魔法阵 + 幻彩流光羽翼与星尘"
        case 2: return "双色呼吸柔光光环 + 灵动漂浮特效"
        default: return "软萌初始幼崽形态"
        }
    }

    /// 每次投喂所需星币随当前阶位递增（越往后养成越有分量）
    public static func feedCost(for stage: Int) -> Int {
        switch stage {
        case 1: return 35
        case 2: return 50
        case 3: return 70
        case 4: return 95
        default: return 65
        }
    }

    public static let all: [GuardianPetSpecies] = [
        GuardianPetSpecies(
            id: "fire_dragon",
            kind: .fireDragon,
            name: "炙炎小火龙·焰焰",
            title: "灶台火焰小守护神",
            rarity: 3,
            primaryHex: "#FF6B4A",
            secondaryHex: "#FFD166",
            accentHex: "#E63946",
            favoriteFood: "火焰脆皮烤肉",
            baseCoinPerQuestion: 5,
            skillShortTag: "🔥 每题+5币",
            skillDesc: "答对题目时额外加成 +5 星币（4阶起翻倍至 +10）",
            cheerLine: "嗷呜～我的小火苗帮你把料理烤得香喷喷！"
        ),
        GuardianPetSpecies(
            id: "unicorn",
            kind: .unicorn,
            name: "星云独角兽·星梦",
            title: "彩虹糖霜魔法师",
            rarity: 3,
            primaryHex: "#A66CFF",
            secondaryHex: "#FF9EBB",
            accentHex: "#FFD166",
            favoriteFood: "彩虹棉花糖马卡龙",
            baseCoinPerQuestion: 3,
            skillShortTag: "🌈 彩虹加速",
            skillDesc: "每题 +3 星币，3连击起额外 +1 彩虹能量 & 满槽额外 +10 星币（4阶翻倍）",
            cheerLine: "叮咚✨ 独角兽的彩虹星尘为你照亮满分答案！"
        ),
        GuardianPetSpecies(
            id: "nine_tail_fox",
            kind: .nineTailFox,
            name: "九尾仙狐·绒绒",
            title: "樱花幻境小甜心",
            rarity: 3,
            primaryHex: "#FF758F",
            secondaryHex: "#FFE5EC",
            accentHex: "#FB5607",
            favoriteFood: "蜜汁樱花豆皮寿司",
            baseCoinPerQuestion: 3,
            skillShortTag: "🦊 灵感暴击",
            skillDesc: "每题 +3 星币，15% 概率触发「狐仙灵感」额外 +12 星币（4阶概率与奖励翻倍）",
            cheerLine: "摇摇大尾巴～今天你也是最聪明的小厨神！"
        ),
        GuardianPetSpecies(
            id: "azure_dragon",
            kind: .azureDragon,
            name: "祥云小青龙·敖敖",
            title: "东海云端小龙王",
            rarity: 3,
            primaryHex: "#00B4D8",
            secondaryHex: "#90E0EF",
            accentHex: "#FFB703",
            favoriteFood: "水晶虾饺皇",
            baseCoinPerQuestion: 2,
            skillShortTag: "🐉 连击加码",
            skillDesc: "每题 +2 星币，每多 1 层连击额外 +1 星币（至多 +5，4阶翻倍）",
            cheerLine: "腾云驾雾来陪你读书闯关，冲呀！"
        ),
        GuardianPetSpecies(
            id: "phoenix",
            kind: .phoenix,
            name: "朝阳小凤凰·晞晞",
            title: "金羽浴火小仙鸟",
            rarity: 3,
            primaryHex: "#F77F00",
            secondaryHex: "#FCBF49",
            accentHex: "#D62828",
            favoriteFood: "黄金流沙蛋黄酥",
            baseCoinPerQuestion: 3,
            skillShortTag: "🔥 护连击盾",
            skillDesc: "每题 +3 星币，每局免疫 1 次答错连击中断（4阶起加成翻倍至 2 次）",
            cheerLine: "啾啾～金羽闪耀，难题统统难不倒你！"
        ),
        GuardianPetSpecies(
            id: "panda_chef",
            kind: .pandaChef,
            name: "功夫熊猫厨神·阿宝",
            title: "中华料理特级掌勺",
            rarity: 2,
            primaryHex: "#2B2D42",
            secondaryHex: "#FFFFFF",
            accentHex: "#3EA865",
            favoriteFood: "翡翠鲜笋小笼包",
            baseCoinPerQuestion: 3,
            skillShortTag: "🐼 语数专精",
            skillDesc: "每题 +3 星币，语文拼音与数学首次答对额外 +3 星币（4阶翻倍）",
            cheerLine: "嘿哈！吃饱竹笋小笼包，拼音数学全拿捏！"
        ),
        GuardianPetSpecies(
            id: "whale",
            kind: .whale,
            name: "云海小蓝鲸·泡泡",
            title: "星空喷泉领航员",
            rarity: 2,
            primaryHex: "#3A86FF",
            secondaryHex: "#BDE0FE",
            accentHex: "#FFBE0B",
            favoriteFood: "海盐蓝莓果冻杯",
            baseCoinPerQuestion: 3,
            skillShortTag: "🐳 彩虹加奖",
            skillDesc: "每题 +3 星币，爆出彩虹宝箱时额外喷出 +12 星币（4阶翻倍）",
            cheerLine: "噗噜噜🐳 我喷出一道大彩虹送给你！"
        ),
        GuardianPetSpecies(
            id: "lucky_cat",
            kind: .luckyCat,
            name: "招财布丁喵·金宝",
            title: "黄金铃铛福气官",
            rarity: 2,
            primaryHex: "#FCA311",
            secondaryHex: "#FFF3B0",
            accentHex: "#E63946",
            favoriteFood: "焦糖烤布丁小鱼干",
            baseCoinPerQuestion: 2,
            skillShortTag: "🐱 双倍招财",
            skillDesc: "每题 +2 星币，18% 概率触发「招财双倍」本题星币翻倍（4阶概率翻倍）",
            cheerLine: "喵呜～金爪招一招，满屏金星飞过来！"
        ),
        GuardianPetSpecies(
            id: "owl_doctor",
            kind: .owlDoctor,
            name: "智慧猫头鹰·知知",
            title: "皇家学院大博士",
            rarity: 2,
            primaryHex: "#8338EC",
            secondaryHex: "#E0AAFF",
            accentHex: "#FFBE0B",
            favoriteFood: "坚果巧克力曲奇",
            baseCoinPerQuestion: 2,
            skillShortTag: "🦉 消错翻倍",
            skillDesc: "每题 +2 星币，成功消灭错题本题目额外 +15 星币（4阶翻倍）",
            cheerLine: "咕咕🦉 仔细看题、认真听音，你一定能行！"
        ),
        GuardianPetSpecies(
            id: "aurora_deer",
            kind: .auroraDeer,
            name: "极光梅花鹿·呦呦",
            title: "森林花冠小精灵",
            rarity: 2,
            primaryHex: "#2EC4B6",
            secondaryHex: "#CBF3F0",
            accentHex: "#FF9F1C",
            favoriteFood: "鲜果抹茶千层蛋糕",
            baseCoinPerQuestion: 2,
            skillShortTag: "🦌 华服幸运",
            skillDesc: "每题 +2 星币，通关掉落高阶公主华服概率 +15%（4阶翻倍）",
            cheerLine: "呦呦鹿鸣～你看我的鹿角开出小花啦！"
        ),
        GuardianPetSpecies(
            id: "moon_rabbit",
            kind: .moonRabbit,
            name: "月桂玉兔·糯糯",
            title: "桂花糖糕甜点师",
            rarity: 1,
            primaryHex: "#FF8FA3",
            secondaryHex: "#FFF0F3",
            accentHex: "#FFB703",
            favoriteFood: "桂花豆沙雪媚娘",
            baseCoinPerQuestion: 2,
            skillShortTag: "🐰 英语专精",
            skillDesc: "每题 +2 星币，英语关首次答对额外 +3 星币（4阶翻倍）",
            cheerLine: "蹦蹦跳跳🐰 我做了甜甜的雪媚娘奖励你！"
        ),
        GuardianPetSpecies(
            id: "corgi_pilot",
            kind: .corgiPilot,
            name: "飞行员柯基·旺仔",
            title: "螺旋桨速递小队长",
            rarity: 1,
            primaryHex: "#F4A261",
            secondaryHex: "#FEFAE0",
            accentHex: "#2A9D8F",
            favoriteFood: "芝士热狗华夫饼",
            baseCoinPerQuestion: 2,
            skillShortTag: "🐶 通关速递",
            skillDesc: "每题 +2 星币，每局通关结算额外速递 +15 星币（4阶翻倍）",
            cheerLine: "汪汪！小短腿火力全开，冲向下一关！"
        )
    ]

    public static func byId(_ id: String) -> GuardianPetSpecies {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

// MARK: - 🏰 皇家童话游乐园 8 大动态景观设施（含实质加成）
public struct CastleAttraction: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let costCoins: Int
    public let icon: String
    public let primaryHex: String
    public let secondaryHex: String
    public let cheerSpeech: String
    public let perkShortTag: String
    public let perkDesc: String

    public static let all: [CastleAttraction] = [
        CastleAttraction(
            id: "fountain",
            name: "音乐宝石喷泉",
            subtitle: "水柱随音乐欢快跳动，喷涌七彩水珠",
            costCoins: 0,
            icon: "⛲",
            primaryHex: "#3685D6",
            secondaryHex: "#90E0EF",
            cheerSpeech: "哗啦啦！音乐宝石喷泉正在为你喷洒幸运水珠！",
            perkShortTag: "💧 每题 +1 币",
            perkDesc: "游乐园开园祝福：每答对 1 题额外 +1 幸运星币"
        ),
        CastleAttraction(
            id: "ferris_wheel",
            name: "彩虹糖果摩天轮",
            subtitle: "6 个马卡龙座舱 360° 缓缓旋转俯瞰全城",
            costCoins: 150,
            icon: "🎡",
            primaryHex: "#E05385",
            secondaryHex: "#FFD166",
            cheerSpeech: "彩虹糖果摩天轮转起来啦，坐上最高处看星星吧！",
            perkShortTag: "🌈 宝箱 +10 币",
            perkDesc: "集满 8 格彩虹宝箱时额外掉落 +10 星币"
        ),
        CastleAttraction(
            id: "carousel",
            name: "皇家梦幻旋转木马",
            subtitle: "金色华盖下小木马随八音盒上下欢快起伏",
            costCoins: 180,
            icon: "🎠",
            primaryHex: "#F07D2E",
            secondaryHex: "#FFE5EC",
            cheerSpeech: "叮叮当当，皇家旋转木马带你进入童话王国！",
            perkShortTag: "💖 摸宠 +1 次",
            perkDesc: "每日免费「摸摸抱抱」互动次数 +1（3→4 次）"
        ),
        CastleAttraction(
            id: "air_balloon",
            name: "追梦星空热气球",
            subtitle: "喷射温暖火焰，载着小精灵在云端轻盈漂浮",
            costCoins: 220,
            icon: "🎈",
            primaryHex: "#7A6EE6",
            secondaryHex: "#FF9EBB",
            cheerSpeech: "呼——星空热气球飞上蓝天白云间啦！",
            perkShortTag: "🎈 结算 +8 币",
            perkDesc: "每局获星通关结算额外飘落 +8 星币"
        ),
        CastleAttraction(
            id: "windmill",
            name: "棒棒糖大风车",
            subtitle: "四片彩色棒棒糖扇叶迎风旋转，甜香四溢",
            costCoins: 200,
            icon: "🍭",
            primaryHex: "#2FB380",
            secondaryHex: "#FFD166",
            cheerSpeech: "呼呼转动的棒棒糖大风车，吹来甜甜的奶油香气！",
            perkShortTag: "🎁 翻牌 +10 币",
            perkDesc: "开启局末三选一神秘宝箱时额外附赠 +10 星币"
        ),
        CastleAttraction(
            id: "clock_tower",
            name: "魔法黄金天文钟楼",
            subtitle: "齿轮与金针滴答旋转，守护料理城的美好时光",
            costCoins: 260,
            icon: "🕰️",
            primaryHex: "#C8870A",
            secondaryHex: "#FFF3B0",
            cheerSpeech: "铛——铛——魔法天文钟楼为你敲响胜利的钟声！",
            perkShortTag: "🎡 转盘 +15 币",
            perkDesc: "每次旋转每日幸运小转盘额外赠送 +15 星币"
        ),
        CastleAttraction(
            id: "music_box",
            name: "水晶天鹅八音盒",
            subtitle: "舞台中央闪耀水晶光芒，彩色音符漫天飞舞",
            costCoins: 300,
            icon: "🎶",
            primaryHex: "#9B6EF3",
            secondaryHex: "#E0AAFF",
            cheerSpeech: "叮咚叮咚，水晶八音盒奏响了最动听的凯旋曲！",
            perkShortTag: "🎵 连击 +1 币",
            perkDesc: "达成 3 连击及以上时，每答对 1 题额外 +1 星币"
        ),
        CastleAttraction(
            id: "fireworks",
            name: "皇家盛典烟花礼炮",
            subtitle: "点击随时在游乐园高空绽放漫天绚丽烟花",
            costCoins: 380,
            icon: "🎆",
            primaryHex: "#E25247",
            secondaryHex: "#FFD166",
            cheerSpeech: "砰！啪！漫天绚丽的皇家烟花为你绽放！",
            perkShortTag: "🎆 三星 +20 币",
            perkDesc: "3 星通关自动放皇家烟花并额外奖励 +20 星币"
        )
    ]

    public static func byId(_ id: String) -> CastleAttraction? {
        all.first(where: { $0.id == id })
    }
}

// MARK: - 👗 满满公主换装衣橱与珠宝首饰系统（5 大自由搭配部位 · 4 阶华丽度）
public enum PrincessFashionCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    public var id: String { rawValue }
    case dress     = "dress"      // 👗 礼服裙装
    case hairTiara = "hair_tiara" // 👑 发型与皇冠发饰
    case jewelry   = "jewelry"    // 💎 项链与耳坠首饰
    case wings     = "wings"      // 🧚 梦幻背饰与神翼
    case wand      = "wand"       // 🪄 魔法权杖与手持

    public var title: String {
        switch self {
        case .dress:     return "👗 华丽礼服"
        case .hairTiara: return "👑 皇冠发饰"
        case .jewelry:   return "💎 项链耳坠"
        case .wings:     return "🧚 梦幻神翼"
        case .wand:      return "🪄 魔法手持"
        }
    }

    public var shortName: String {
        switch self {
        case .dress:     return "礼服"
        case .hairTiara: return "皇冠"
        case .jewelry:   return "首饰"
        case .wings:     return "神翼"
        case .wand:      return "手持"
        }
    }
}

public struct PrincessFashionItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let category: PrincessFashionCategory
    public let styleIndex: Int // 0...5 对应矢量绘制样式
    public let name: String
    public let subtitle: String
    public let tier: Int       // 1 初级甜心 / 2 进阶优雅 / 3 高级华丽 / 4 皇家神话
    public let costCoins: Int
    public let needStars: Int  // 需累计获得的星星门槛（防止不学习直接买顶级礼服）
    public let icon: String
    public let primaryHex: String
    public let secondaryHex: String
    public let accentHex: String

    public var tierName: String {
        switch tier {
        case 4: return "皇家神话"
        case 3: return "高级华丽"
        case 2: return "进阶优雅"
        default: return "初级甜心"
        }
    }

    public var tierColorHex: String {
        switch tier {
        case 4: return "#E25247"
        case 3: return "#9B6EF3"
        case 2: return "#3685D6"
        default: return "#2FB380"
        }
    }

    public var rarity: Int { tier }
    public var rarityName: String { tierName }
    public var rarityColorHex: String { tierColorHex }

    // 5 阶高定华服升阶阈值：越往后升级难度递增，升阶后礼服/皇冠/首饰/翅膀特效层层蜕变
    public static let stageThresholds = [0, 1, 3, 7, 13, 22]
    public static let maxStage = 5

    public static func stageName(for stage: Int) -> String {
        switch stage {
        case 5: return "🌈 传世神装"
        case 4: return "👑 皇家高定"
        case 3: return "💎 晶钻镶嵌"
        case 2: return "✨ 珠光刺绣"
        case 1: return "🎀 初裁新装"
        default: return "🔒 未解锁"
        }
    }

    public static func stageVisualPerk(for stage: Int) -> String {
        switch stage {
        case 5: return "九彩极光霓虹流光 + 漫天宝石星雨 + 全身璀璨圣光大法阵"
        case 4: return "纯金流光镶边 + 旋转魔法星轨光环 + 华贵光冕"
        case 3: return "璀璨晶钻点缀 + 飘舞星尘花瓣特效"
        case 2: return "银丝蕾丝镶边 + 柔光呼吸光晕"
        default: return "清新初裁原画款式"
        }
    }

    public static func stageEffectDesc(for stage: Int) -> String {
        stageVisualPerk(for: stage)
    }

    /// 每次高定织造（+1 升阶经验）所需星币，随当前阶位与华服品阶递增
    public static func upgradeCraftCost(for stage: Int, tier: Int) -> Int {
        let base: Int
        switch stage {
        case 1: base = 35
        case 2: base = 55
        case 3: base = 80
        case 4: base = 110
        default: base = 75
        }
        return base + max(0, tier - 1) * 15
    }

    public static func upgradeCraftCost(for stage: Int, rarity: Int) -> Int {
        upgradeCraftCost(for: stage, tier: rarity)
    }

    public static let all: [PrincessFashionItem] = [
        // ==================== 1. 👗 华丽礼服 (6 款) ====================
        PrincessFashionItem(
            id: "dress_0", category: .dress, styleIndex: 0,
            name: "草莓奶油小厨娘裙", subtitle: "甜美波点围裙配荷叶边裙摆",
            tier: 1, costCoins: 0, needStars: 0, icon: "🍓",
            primaryHex: "#FF85A1", secondaryHex: "#FFF0F5", accentHex: "#E63946"
        ),
        PrincessFashionItem(
            id: "dress_1", category: .dress, styleIndex: 1,
            name: "薄荷马卡龙泡泡袖裙", subtitle: "清爽薄荷绿双层蝴蝶结蓬蓬裙",
            tier: 1, costCoins: 110, needStars: 5, icon: "🧁",
            primaryHex: "#2EC4B6", secondaryHex: "#CBF3F0", accentHex: "#FF9F1C"
        ),
        PrincessFashionItem(
            id: "dress_2", category: .dress, styleIndex: 2,
            name: "樱花仙子多层纱纱裙", subtitle: "轻盈花瓣叠纱，走起路来飘逸灵动",
            tier: 2, costCoins: 210, needStars: 14, icon: "🌸",
            primaryHex: "#FF6B9D", secondaryHex: "#FFE3EE", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "dress_3", category: .dress, styleIndex: 3,
            name: "冰雪水晶公主曳地长裙", subtitle: "镶嵌冰蓝雪花晶钻的优雅晚礼服",
            tier: 3, costCoins: 350, needStars: 26, icon: "❄️",
            primaryHex: "#3A86FF", secondaryHex: "#CAF0F8", accentHex: "#90E0EF"
        ),
        PrincessFashionItem(
            id: "dress_4", category: .dress, styleIndex: 4,
            name: "璀璨星河极光渐变礼服", subtitle: "裙摆流淌紫金星云，自带闪烁星尘特效",
            tier: 4, costCoins: 520, needStars: 42, icon: "🌌",
            primaryHex: "#7209B7", secondaryHex: "#F72585", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "dress_5", category: .dress, styleIndex: 5,
            name: "黄金蔷薇皇家加冕宫廷裙", subtitle: "传世高定金丝蕾丝裙，宝石流光溢彩",
            tier: 4, costCoins: 680, needStars: 60, icon: "👗",
            primaryHex: "#F59E0B", secondaryHex: "#FEF3C7", accentHex: "#E11D48"
        ),

        // ==================== 2. 👑 皇冠发饰 (6 款) ====================
        PrincessFashionItem(
            id: "hair_0", category: .hairTiara, styleIndex: 0,
            name: "元气双马尾蝴蝶结", subtitle: "活泼可爱的红丝带双马尾",
            tier: 1, costCoins: 0, needStars: 0, icon: "🎀",
            primaryHex: "#FF5C8A", secondaryHex: "#FFE5EC", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "hair_1", category: .hairTiara, styleIndex: 1,
            name: "蜜桃珍珠蝴蝶发箍", subtitle: "圆润白珍珠编织的甜心发箍",
            tier: 1, costCoins: 95, needStars: 4, icon: "🫧",
            primaryHex: "#FF9EBB", secondaryHex: "#FFFFFF", accentHex: "#F4A261"
        ),
        PrincessFashionItem(
            id: "hair_2", category: .hairTiara, styleIndex: 2,
            name: "森林晨露玫瑰花冠", subtitle: "盛开粉玫瑰与翡翠藤蔓交织的花环",
            tier: 2, costCoins: 180, needStars: 12, icon: "🌹",
            primaryHex: "#E05385", secondaryHex: "#52B788", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "hair_3", category: .hairTiara, styleIndex: 3,
            name: "水晶天鹅羽毛银冠", subtitle: "纯银雕琢天鹅羽翼配冰蓝主钻",
            tier: 3, costCoins: 320, needStars: 24, icon: "🦢",
            primaryHex: "#4CC9F0", secondaryHex: "#F8F9FA", accentHex: "#4361EE"
        ),
        PrincessFashionItem(
            id: "hair_4", category: .hairTiara, styleIndex: 4,
            name: "月光女神星钻大王冠", subtitle: "镶嵌 7 颗璀璨星芒钻的女神皇冠",
            tier: 4, costCoins: 480, needStars: 38, icon: "👑",
            primaryHex: "#9D4EDD", secondaryHex: "#E0AAFF", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "hair_5", category: .hairTiara, styleIndex: 5,
            name: "太阳神耀金凤凰圣冠", subtitle: "纯金凤羽镶红宝石，头顶绽放圣洁金辉",
            tier: 4, costCoins: 640, needStars: 55, icon: "🔥",
            primaryHex: "#FFB703", secondaryHex: "#FFF3B0", accentHex: "#D62828"
        ),

        // ==================== 3. 💎 项链与耳坠首饰 (6 款) ====================
        PrincessFashionItem(
            id: "jewel_0", category: .jewelry, styleIndex: 0,
            name: "小雏菊幸运颈链", subtitle: "清新小巧的白色雏菊花朵锁骨链",
            tier: 1, costCoins: 0, needStars: 0, icon: "🌼",
            primaryHex: "#FFD166", secondaryHex: "#FFFFFF", accentHex: "#FF85A1"
        ),
        PrincessFashionItem(
            id: "jewel_1", category: .jewelry, styleIndex: 1,
            name: "粉红甜心珍珠套链", subtitle: "南海粉珍珠项链配圆润珍珠耳钉",
            tier: 1, costCoins: 105, needStars: 5, icon: "📿",
            primaryHex: "#FFAFCC", secondaryHex: "#FFF0F5", accentHex: "#FB6F92"
        ),
        PrincessFashionItem(
            id: "jewel_2", category: .jewelry, styleIndex: 2,
            name: "人鱼之泪蓝水晶吊坠", subtitle: "水滴形海洋蓝水晶项链与耳坠",
            tier: 2, costCoins: 195, needStars: 14, icon: "💧",
            primaryHex: "#00B4D8", secondaryHex: "#CAF0F8", accentHex: "#0077B6"
        ),
        PrincessFashionItem(
            id: "jewel_3", category: .jewelry, styleIndex: 3,
            name: "紫罗兰星月宝石颈链", subtitle: "神秘紫水晶新月吊坠配摇曳星芒耳环",
            tier: 3, costCoins: 340, needStars: 25, icon: "🔮",
            primaryHex: "#8338EC", secondaryHex: "#E0AAFF", accentHex: "#FFBE0B"
        ),
        PrincessFashionItem(
            id: "jewel_4", category: .jewelry, styleIndex: 4,
            name: "海洋之心皇室红宝套链", subtitle: "鸽血红心形主石配碎钻流苏耳坠",
            tier: 4, costCoins: 500, needStars: 40, icon: "💎",
            primaryHex: "#E63946", secondaryHex: "#FFE5EC", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "jewel_5", category: .jewelry, styleIndex: 5,
            name: "永恒彩虹星钻皇后华链", subtitle: "七彩星钻环绕胸前，闪烁炫彩星芒",
            tier: 4, costCoins: 650, needStars: 58, icon: "✨",
            primaryHex: "#F72585", secondaryHex: "#4CC9F0", accentHex: "#FFD166"
        ),

        // ==================== 4. 🧚 梦幻背饰与神翼 (6 款) ====================
        PrincessFashionItem(
            id: "wings_0", category: .wings, styleIndex: 0,
            name: "甜心粉绸大蝴蝶结", subtitle: "系在背后的软萌丝绸飘带蝴蝶结",
            tier: 1, costCoins: 0, needStars: 0, icon: "🎀",
            primaryHex: "#FF85A1", secondaryHex: "#FFE5EC", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "wings_1", category: .wings, styleIndex: 1,
            name: "森系花仙子透明薄翼", subtitle: "如蝉翼般晶莹剔透的翡翠精灵翅膀",
            tier: 1, costCoins: 130, needStars: 6, icon: "🧚",
            primaryHex: "#52B788", secondaryHex: "#D8F3DC", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "wings_2", category: .wings, styleIndex: 2,
            name: "纯白雪绒白天鹅羽翼", subtitle: "洁白蓬松的层叠鹅羽，圣洁优雅",
            tier: 2, costCoins: 240, needStars: 16, icon: "🕊️",
            primaryHex: "#A2D2FF", secondaryHex: "#FFFFFF", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "wings_3", category: .wings, styleIndex: 3,
            name: "幻彩琉璃彩蝶双翼", subtitle: "五彩斑斓的宝石蝶翼，随呼吸轻轻扇动",
            tier: 3, costCoins: 380, needStars: 28, icon: "🦋",
            primaryHex: "#9B5DE5", secondaryHex: "#F15BB5", accentHex: "#FEE440"
        ),
        PrincessFashionItem(
            id: "wings_4", category: .wings, styleIndex: 4,
            name: "星辰霓虹飞马天翼", subtitle: "流淌极光星尘的梦幻神翼",
            tier: 4, costCoins: 540, needStars: 44, icon: "🦄",
            primaryHex: "#4361EE", secondaryHex: "#F72585", accentHex: "#4CC9F0"
        ),
        PrincessFashionItem(
            id: "wings_5", category: .wings, styleIndex: 5,
            name: "九天流金神凰圣翼", subtitle: "金焰辉煌的六翼神凰羽衣，尊贵无比",
            tier: 4, costCoins: 720, needStars: 64, icon: "🔥",
            primaryHex: "#FF9F1C", secondaryHex: "#FFF3B0", accentHex: "#E63946"
        ),

        // ==================== 5. 🪄 魔法权杖与手持 (6 款) ====================
        PrincessFashionItem(
            id: "wand_0", category: .wand, styleIndex: 0,
            name: "爱心奶油甜品银勺", subtitle: "小厨娘随身携带的魔法尝味勺",
            tier: 1, costCoins: 0, needStars: 0, icon: "🥄",
            primaryHex: "#FF85A1", secondaryHex: "#E2E8F0", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "wand_1", category: .wand, styleIndex: 1,
            name: "草莓马卡龙飘空气球", subtitle: "系着金色丝带的粉色心形气球",
            tier: 1, costCoins: 90, needStars: 4, icon: "🎈",
            primaryHex: "#FF5D8F", secondaryHex: "#FFC4D6", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "wand_2", category: .wand, styleIndex: 2,
            name: "玫瑰水晶音乐花篮", subtitle: "装满晨露鲜花与糖果的精致手提篮",
            tier: 2, costCoins: 175, needStars: 12, icon: "🧺",
            primaryHex: "#F4A261", secondaryHex: "#FF85A1", accentHex: "#2A9D8F"
        ),
        PrincessFashionItem(
            id: "wand_3", category: .wand, styleIndex: 3,
            name: "星月仙子黄金魔法棒", subtitle: "挥动时会洒下金色星尘的仙女棒",
            tier: 3, costCoins: 310, needStars: 24, icon: "🪄",
            primaryHex: "#FFB703", secondaryHex: "#9B5DE5", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "wand_4", category: .wand, styleIndex: 4,
            name: "冰雪极光天鹅水晶竖琴", subtitle: "弹奏出梦幻彩音符的宝石小竖琴",
            tier: 4, costCoins: 480, needStars: 38, icon: "🎻",
            primaryHex: "#00B4D8", secondaryHex: "#E0AAFF", accentHex: "#FFD166"
        ),
        PrincessFashionItem(
            id: "wand_5", category: .wand, styleIndex: 5,
            name: "皇家彩虹独角兽圣光权杖", subtitle: "顶镶彩虹宝石心与双翼的至尊女王权杖",
            tier: 4, costCoins: 620, needStars: 56, icon: "👑",
            primaryHex: "#F72585", secondaryHex: "#FFD166", accentHex: "#4CC9F0"
        )
    ]

    public static func byId(_ id: String) -> PrincessFashionItem {
        all.first(where: { $0.id == id }) ?? all[0]
    }

    public static func item(for id: String) -> PrincessFashionItem? {
        all.first(where: { $0.id == id })
    }

    public static func items(for category: PrincessFashionCategory) -> [PrincessFashionItem] {
        all.filter { $0.category == category }
    }

    public static func defaultItem(for category: PrincessFashionCategory) -> PrincessFashionItem {
        all.first(where: { $0.category == category && $0.styleIndex == 0 }) ?? all[0]
    }
}

// MARK: - 👑 六大高定套装图鉴与套装共鸣系统（styleIndex 0...5）
public struct PrincessFashionSuit: Identifiable, Equatable, Sendable {
    public var id: Int { styleIndex }
    public let styleIndex: Int
    public let name: String
    public let subtitle: String
    public let stageThemeName: String
    public let primaryHex: String
    public let secondaryHex: String
    public let accentHex: String
    public let fullCoinBonus: Int

    public var itemIds: [String] {
        ["dress_\(styleIndex)", "hair_\(styleIndex)", "jewel_\(styleIndex)", "wings_\(styleIndex)", "wand_\(styleIndex)"]
    }

    public var items: [PrincessFashionItem] {
        itemIds.map { PrincessFashionItem.byId($0) }
    }

    public static let all: [PrincessFashionSuit] = [
        PrincessFashionSuit(
            styleIndex: 0,
            name: "草莓甜心厨娘套装",
            subtitle: "甜美波点围裙配荷叶双马尾，料理城初心启航",
            stageThemeName: "🍓 甜心莓果厨房舞台",
            primaryHex: "#FF85A1",
            secondaryHex: "#FFF0F5",
            accentHex: "#E63946",
            fullCoinBonus: 1
        ),
        PrincessFashionSuit(
            styleIndex: 1,
            name: "薄荷马卡龙仙子套装",
            subtitle: "清爽薄荷泡泡袖配透明仙翼，元气飘浮气球",
            stageThemeName: "🧁 马卡龙花园舞台",
            primaryHex: "#2EC4B6",
            secondaryHex: "#CBF3F0",
            accentHex: "#FF9F1C",
            fullCoinBonus: 1
        ),
        PrincessFashionSuit(
            styleIndex: 2,
            name: "樱花晨露森林套装",
            subtitle: "花瓣叠纱裙配粉玫瑰花冠与天鹅绒羽翼",
            stageThemeName: "🌸 樱花飘落庭院舞台",
            primaryHex: "#FF6B9D",
            secondaryHex: "#FFE3EE",
            accentHex: "#52B788",
            fullCoinBonus: 2
        ),
        PrincessFashionSuit(
            styleIndex: 3,
            name: "冰雪天鹅水晶套装",
            subtitle: "冰蓝曳地礼服配水晶天鹅冠与琉璃蝶翼",
            stageThemeName: "❄️ 极光冰晶雪宫舞台",
            primaryHex: "#3A86FF",
            secondaryHex: "#CAF0F8",
            accentHex: "#9B5DE5",
            fullCoinBonus: 2
        ),
        PrincessFashionSuit(
            styleIndex: 4,
            name: "璀璨星月极光套装",
            subtitle: "紫金星河礼服配七星女神冠与天鹅水晶竖琴",
            stageThemeName: "🌌 星月极光银河舞台",
            primaryHex: "#7209B7",
            secondaryHex: "#F72585",
            accentHex: "#FFD166",
            fullCoinBonus: 3
        ),
        PrincessFashionSuit(
            styleIndex: 5,
            name: "太阳神金蔷薇套装",
            subtitle: "加冕黄金宫廷裙配凤凰圣冠与九天流金神翼",
            stageThemeName: "👑 黄金蔷薇皇家殿堂",
            primaryHex: "#F59E0B",
            secondaryHex: "#FEF3C7",
            accentHex: "#E11D48",
            fullCoinBonus: 3
        )
    ]

    public static func byStyleIndex(_ styleIndex: Int) -> PrincessFashionSuit {
        all.first(where: { $0.styleIndex == styleIndex }) ?? all[0]
    }
}

public struct SuitBonusInfo: Equatable, Sendable {
    public let suit: PrincessFashionSuit
    public let suitName: String
    public let matchedCount: Int
    public let isHalfResonance: Bool
    public let isFullResonance: Bool
    public let glamourBonusPercent: Int
    public let glamourMultiplier: Double
    public let stageThemeId: Int
    public let coinBonus: Int
}

// MARK: - 🎨 满满公主发色、表情、舞台 Pose 个性化定义
public struct HairColorOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let primaryHex: String
    public let highlightHex: String
    public let shadowHex: String
    public let needStars: Int
    public let needGlamour: Int
    public let unlockDesc: String

    public static let all: [HairColorOption] = [
        HairColorOption(id: "caramel", name: "焦糖暖棕", primaryHex: "#5A332B", highlightHex: "#8B5A4C", shadowHex: "#3A1E19", needStars: 0, needGlamour: 0, unlockDesc: "默认解锁"),
        HairColorOption(id: "honey", name: "蜜糖金发", primaryHex: "#E9A93B", highlightHex: "#FFE082", shadowHex: "#B87314", needStars: 6, needGlamour: 0, unlockDesc: "累计 6 ★ 解锁"),
        HairColorOption(id: "sakura", name: "樱花蜜粉", primaryHex: "#F472B6", highlightHex: "#FBCFE8", shadowHex: "#BE185D", needStars: 0, needGlamour: 350, unlockDesc: "华丽度 350 解锁"),
        HairColorOption(id: "silver", name: "冰雪银霜", primaryHex: "#CBD5E1", highlightHex: "#F8FAFC", shadowHex: "#64748B", needStars: 24, needGlamour: 0, unlockDesc: "累计 24 ★ 解锁"),
        HairColorOption(id: "aurora", name: "星空幻紫", primaryHex: "#8B5CF6", highlightHex: "#DDD6FE", shadowHex: "#5B21B6", needStars: 0, needGlamour: 500, unlockDesc: "华丽度 500 解锁")
    ]

    public static func byId(_ id: String) -> HairColorOption {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

public struct PrincessExpression: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let needStars: Int
    public let unlockDesc: String

    public static let all: [PrincessExpression] = [
        PrincessExpression(id: "smile", name: "甜美微笑", emoji: "😊", needStars: 0, unlockDesc: "默认解锁"),
        PrincessExpression(id: "wink", name: "俏皮 Wink", emoji: "😉", needStars: 0, unlockDesc: "默认解锁"),
        PrincessExpression(id: "starry", name: "闪亮星星眼", emoji: "🤩", needStars: 10, unlockDesc: "累计 10 ★ 解锁"),
        PrincessExpression(id: "pout", name: "甜酷嘟嘟嘴", emoji: "😗", needStars: 20, unlockDesc: "累计 20 ★ 解锁")
    ]

    public static func byId(_ id: String) -> PrincessExpression {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

public struct PrincessPose: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let needGlamour: Int
    public let needStars: Int
    public let unlockDesc: String

    public static let all: [PrincessPose] = [
        PrincessPose(id: "curtsy", name: "优雅拎裙礼", emoji: "🩰", needGlamour: 0, needStars: 0, unlockDesc: "默认解锁"),
        PrincessPose(id: "wand_up", name: "魔法举杖礼", emoji: "🪄", needGlamour: 350, needStars: 0, unlockDesc: "华丽度 350 解锁"),
        PrincessPose(id: "leap", name: "星光轻盈跃起", emoji: "🌟", needGlamour: 500, needStars: 0, unlockDesc: "华丽度 500 解锁")
    ]

    public static func byId(_ id: String) -> PrincessPose {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

// MARK: - ✨ 华丽度舞会爵位与成长里程碑系统
public struct GlamourRankInfo: Equatable, Sendable {
    public let level: Int
    public let title: String
    public let coinBonus: Int
    public let currentMinScore: Int
    public let nextMinScore: Int?
    public let nextTitle: String?
    public let frameHex: String

    public static let tiers: [(minScore: Int, title: String, coinBonus: Int, frameHex: String)] = [
        (0,   "🎀 甜心见习公主", 0, "#E2C9A8"),
        (200, "🌸 星光舞会少女", 1, "#FF85A1"),
        (350, "💎 优雅花冠名媛", 2, "#3A86FF"),
        (500, "✨ 璀璨水晶殿下", 3, "#9D4EDD"),
        (650, "👑 绝代风华女王", 4, "#F59E0B")
    ]

    public static func compute(score: Int) -> GlamourRankInfo {
        var lv = 0
        for (i, t) in tiers.enumerated() where score >= t.minScore {
            lv = i
        }
        let cur = tiers[lv]
        let next = lv + 1 < tiers.count ? tiers[lv + 1] : nil
        return GlamourRankInfo(
            level: lv,
            title: cur.title,
            coinBonus: cur.coinBonus,
            currentMinScore: cur.minScore,
            nextMinScore: next?.minScore,
            nextTitle: next?.title,
            frameHex: cur.frameHex
        )
    }
}

public struct StarMilestone: Identifiable, Equatable, Sendable {
    public var id: Int { needStars }
    public let needStars: Int
    public let title: String
    public let rewardCoins: Int
    public let rewardTickets: Int
    public let rewardStarThread: Int
    public let rewardPetCandy: Int
    public let rewardDesc: String

    public static let all: [StarMilestone] = [
        StarMilestone(needStars: 10, title: "🌱 初露锋芒", rewardCoins: 60, rewardTickets: 1, rewardStarThread: 1, rewardPetCandy: 0, rewardDesc: "+60 🪙 +1 🎟️ +1 🧵"),
        StarMilestone(needStars: 20, title: "🍓 甜蜜摘星", rewardCoins: 80, rewardTickets: 1, rewardStarThread: 0, rewardPetCandy: 1, rewardDesc: "+80 🪙 +1 🎟️ +1 🌟"),
        StarMilestone(needStars: 30, title: "🧁 烘焙新星", rewardCoins: 100, rewardTickets: 1, rewardStarThread: 1, rewardPetCandy: 0, rewardDesc: "+100 🪙 +1 🎟️ +1 🧵"),
        StarMilestone(needStars: 40, title: "🌸 花园精灵", rewardCoins: 120, rewardTickets: 1, rewardStarThread: 0, rewardPetCandy: 1, rewardDesc: "+120 🪙 +1 🎟️ +1 🌟"),
        StarMilestone(needStars: 50, title: "✨ 半程辉煌", rewardCoins: 150, rewardTickets: 2, rewardStarThread: 1, rewardPetCandy: 1, rewardDesc: "+150 🪙 +2 🎟️ +1 🧵 +1 🌟"),
        StarMilestone(needStars: 60, title: "💎 水晶公主", rewardCoins: 180, rewardTickets: 2, rewardStarThread: 2, rewardPetCandy: 0, rewardDesc: "+180 🪙 +2 🎟️ +2 🧵"),
        StarMilestone(needStars: 70, title: "🦄 神兽挚友", rewardCoins: 200, rewardTickets: 2, rewardStarThread: 0, rewardPetCandy: 2, rewardDesc: "+200 🪙 +2 🎟️ +2 🌟"),
        StarMilestone(needStars: 80, title: "👑 皇家荣光", rewardCoins: 240, rewardTickets: 2, rewardStarThread: 2, rewardPetCandy: 1, rewardDesc: "+240 🪙 +2 🎟️ +2 🧵 +1 🌟"),
        StarMilestone(needStars: 90, title: "🌈 大圆满女王", rewardCoins: 320, rewardTickets: 3, rewardStarThread: 2, rewardPetCandy: 2, rewardDesc: "+320 🪙 +3 🎟️ +2 🧵 +2 🌟")
    ]
}

public struct CollectionMilestoneStatus: Equatable, Sendable {
    public let subject: SubjectKind
    public let currentCount: Int
    public let step: Int
    public let maxCount: Int
    public let lastClaimedThreshold: Int
    public let nextTarget: Int?
    public let canClaim: Bool
    public let rewardCoins: Int
    public let rewardTickets: Int
    public let rewardStarThread: Int
    public let rewardDesc: String
}

// MARK: - 💃 每日公主舞会主题挑战 & 🎡 每日幸运小转盘
public struct DailyBallTheme: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let emoji: String
    public let targetStyleIndex: Int
    public let preferredCategory: PrincessFashionCategory
    public let minMatchingPieces: Int
    public let minGlamour: Int
    public let rewardCoins: Int
    public let rewardStarThread: Int

    public static let all: [DailyBallTheme] = [
        DailyBallTheme(
            id: "ball_strawberry",
            title: "🍓 甜心莓果茶话会",
            subtitle: "穿戴至少 3 件【草莓甜心厨娘】部件，且华丽度 ≥ 220",
            emoji: "🍓",
            targetStyleIndex: 0,
            preferredCategory: .dress,
            minMatchingPieces: 3,
            minGlamour: 220,
            rewardCoins: 35,
            rewardStarThread: 1
        ),
        DailyBallTheme(
            id: "ball_macaron",
            title: "🧁 马卡龙糖果派对",
            subtitle: "穿戴至少 2 件【薄荷马卡龙仙子】部件，且华丽度 ≥ 240",
            emoji: "🧁",
            targetStyleIndex: 1,
            preferredCategory: .hairTiara,
            minMatchingPieces: 2,
            minGlamour: 240,
            rewardCoins: 40,
            rewardStarThread: 1
        ),
        DailyBallTheme(
            id: "ball_sakura",
            title: "🌸 樱花森林花神祭",
            subtitle: "穿戴至少 2 件【樱花晨露森林】部件，且华丽度 ≥ 280",
            emoji: "🌸",
            targetStyleIndex: 2,
            preferredCategory: .wings,
            minMatchingPieces: 2,
            minGlamour: 280,
            rewardCoins: 45,
            rewardStarThread: 1
        ),
        DailyBallTheme(
            id: "ball_snow",
            title: "❄️ 冰雪水晶宫廷舞会",
            subtitle: "穿戴至少 2 件【冰雪天鹅水晶】部件，且华丽度 ≥ 320",
            emoji: "❄️",
            targetStyleIndex: 3,
            preferredCategory: .jewelry,
            minMatchingPieces: 2,
            minGlamour: 320,
            rewardCoins: 50,
            rewardStarThread: 1
        ),
        DailyBallTheme(
            id: "ball_aurora",
            title: "🌌 璀璨星河极光夜宴",
            subtitle: "穿戴至少 1 件【璀璨星月极光】部件，且华丽度 ≥ 360",
            emoji: "🌌",
            targetStyleIndex: 4,
            preferredCategory: .wand,
            minMatchingPieces: 1,
            minGlamour: 360,
            rewardCoins: 60,
            rewardStarThread: 1
        ),
        DailyBallTheme(
            id: "ball_phoenix",
            title: "👑 黄金蔷薇加冕盛典",
            subtitle: "穿戴至少 1 件【太阳神金蔷薇】部件，且华丽度 ≥ 400",
            emoji: "👑",
            targetStyleIndex: 5,
            preferredCategory: .dress,
            minMatchingPieces: 1,
            minGlamour: 400,
            rewardCoins: 70,
            rewardStarThread: 1
        )
    ]

    public static func today(date: Date = Date()) -> DailyBallTheme {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = cal.component(.year, from: date)
        let idx = abs(year * 37 + dayOfYear) % all.count
        return all[idx]
    }
}

public struct DailyWheelSlice: Identifiable, Equatable, Sendable {
    public let id: Int
    public let title: String
    public let emoji: String
    public let rewardType: String // "coins", "ticket", "thread", "candy"
    public let amount: Int
    public let colorHex: String

    public static let all: [DailyWheelSlice] = [
        DailyWheelSlice(id: 0, title: "+30 星币", emoji: "🪙", rewardType: "coins", amount: 30, colorHex: "#FFD166"),
        DailyWheelSlice(id: 1, title: "扭蛋券 ×1", emoji: "🎟️", rewardType: "ticket", amount: 1, colorHex: "#FF85A1"),
        DailyWheelSlice(id: 2, title: "星光锦缎 ×1", emoji: "🧵", rewardType: "thread", amount: 1, colorHex: "#9B6EF3"),
        DailyWheelSlice(id: 3, title: "+50 星币", emoji: "💰", rewardType: "coins", amount: 50, colorHex: "#2FB380"),
        DailyWheelSlice(id: 4, title: "神兽糖果 ×1", emoji: "🌟", rewardType: "candy", amount: 1, colorHex: "#3A86FF"),
        DailyWheelSlice(id: 5, title: "+80 星币大礼", emoji: "👑", rewardType: "coins", amount: 80, colorHex: "#F07D2E")
    ]
}

// MARK: - 🎁 局末结算「三选一神秘宝箱」定义
public struct MysteryChestItem: Identifiable, Equatable, Sendable {
    public let id: Int // 0, 1, 2
    public let title: String
    public let subtitle: String
    public let emoji: String
    public let rewardType: String // "coins", "ticket", "fashion", "thread", "candy"
    public let amount: Int
    public let accentHex: String
    public var fashionItemId: String? = nil
    public var isPeeked: Bool = false
}

// MARK: - 🎰 扭蛋开盒动画事件
public struct GachaHatchEvent: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let pet: GuardianPetSpecies
    public let isNew: Bool
    public let fromStage: Int
    public let toStage: Int
    public let totalExp: Int
    public let isMaxOverflow: Bool
    public let overflowCandy: Int
    public let overflowCoins: Int

    public init(
        id: UUID = UUID(),
        pet: GuardianPetSpecies,
        isNew: Bool,
        fromStage: Int,
        toStage: Int,
        totalExp: Int,
        isMaxOverflow: Bool = false,
        overflowCandy: Int = 0,
        overflowCoins: Int = 0
    ) {
        self.id = id
        self.pet = pet
        self.isNew = isNew
        self.fromStage = fromStage
        self.toStage = toStage
        self.totalExp = totalExp
        self.isMaxOverflow = isMaxOverflow
        self.overflowCandy = overflowCandy
        self.overflowCoins = overflowCoins
    }
}

// MARK: - 👗 满满公主高定华服解锁与升阶庆典事件
public struct FashionUpgradeEvent: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let item: PrincessFashionItem
    public let isNewUnlock: Bool
    public let fromStage: Int
    public let toStage: Int
    public let totalCount: Int
    public let customTitle: String?
}
