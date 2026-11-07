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

    public static let stageThresholds = [0, 1, 3, 6]

    public static func stageName(for stage: Int) -> String {
        switch stage {
        case 3: return "皇冠神兽"
        case 2: return "闪耀灵兽"
        case 1: return "萌芽幼崽"
        default: return "未孵化"
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
            skillDesc: "答对题目时额外加成 +5 星币",
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
            skillDesc: "连击能量满槽时额外掉落星光祝福",
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
            skillDesc: "摇动蓬松狐尾为你注入灵感",
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
            skillDesc: "呼风唤雨，助你乘风破浪连战连捷",
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
            skillDesc: "华丽尾羽发光，守护你的每一次连击",
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
            skillDesc: "精通四声调料与加减口诀",
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
            skillDesc: "头顶喷出彩虹水柱为你欢呼",
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
            skillDesc: "金色猫爪摇一摇，星币滚滚来",
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
            skillDesc: "头戴金穗博士帽，最懂算理与单词",
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
            skillDesc: "鹿角盛开水晶花，带来森林好运",
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
            skillDesc: "长耳朵一抖一抖，陪你开心背单词",
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
            skillDesc: "戴着飞行护目镜，摇着小短腿为你助威",
            cheerLine: "汪汪！小短腿火力全开，冲向下一关！"
        )
    ]

    public static func byId(_ id: String) -> GuardianPetSpecies {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

// MARK: - 🏰 皇家童话游乐园 8 大动态景观设施
public struct CastleAttraction: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let costCoins: Int
    public let icon: String
    public let primaryHex: String
    public let secondaryHex: String
    public let cheerSpeech: String

    public static let all: [CastleAttraction] = [
        CastleAttraction(
            id: "fountain",
            name: "音乐宝石喷泉",
            subtitle: "水柱随音乐欢快跳动，喷涌七彩水珠",
            costCoins: 0,
            icon: "⛲",
            primaryHex: "#3685D6",
            secondaryHex: "#90E0EF",
            cheerSpeech: "哗啦啦！音乐宝石喷泉正在为你喷洒幸运水珠！"
        ),
        CastleAttraction(
            id: "ferris_wheel",
            name: "彩虹糖果摩天轮",
            subtitle: "6 个马卡龙座舱 360° 缓缓旋转俯瞰全城",
            costCoins: 80,
            icon: "🎡",
            primaryHex: "#E05385",
            secondaryHex: "#FFD166",
            cheerSpeech: "彩虹糖果摩天轮转起来啦，坐上最高处看星星吧！"
        ),
        CastleAttraction(
            id: "carousel",
            name: "皇家梦幻旋转木马",
            subtitle: "金色华盖下小木马随八音盒上下欢快起伏",
            costCoins: 100,
            icon: "🎠",
            primaryHex: "#F07D2E",
            secondaryHex: "#FFE5EC",
            cheerSpeech: "叮叮当当，皇家旋转木马带你进入童话王国！"
        ),
        CastleAttraction(
            id: "air_balloon",
            name: "追梦星空热气球",
            subtitle: "喷射温暖火焰，载着小精灵在云端轻盈漂浮",
            costCoins: 120,
            icon: "🎈",
            primaryHex: "#7A6EE6",
            secondaryHex: "#FF9EBB",
            cheerSpeech: "呼——星空热气球飞上蓝天白云间啦！"
        ),
        CastleAttraction(
            id: "windmill",
            name: "棒棒糖大风车",
            subtitle: "四片彩色棒棒糖扇叶迎风旋转，甜香四溢",
            costCoins: 110,
            icon: "🍭",
            primaryHex: "#2FB380",
            secondaryHex: "#FFD166",
            cheerSpeech: "呼呼转动的棒棒糖大风车，吹来甜甜的奶油香气！"
        ),
        CastleAttraction(
            id: "clock_tower",
            name: "魔法黄金天文钟楼",
            subtitle: "齿轮与金针滴答旋转，守护料理城的美好时光",
            costCoins: 140,
            icon: "🕰️",
            primaryHex: "#C8870A",
            secondaryHex: "#FFF3B0",
            cheerSpeech: "铛——铛——魔法天文钟楼为你敲响胜利的钟声！"
        ),
        CastleAttraction(
            id: "music_box",
            name: "水晶天鹅八音盒",
            subtitle: "舞台中央闪耀水晶光芒，彩色音符漫天飞舞",
            costCoins: 150,
            icon: "🎶",
            primaryHex: "#9B6EF3",
            secondaryHex: "#E0AAFF",
            cheerSpeech: "叮咚叮咚，水晶八音盒奏响了最动听的凯旋曲！"
        ),
        CastleAttraction(
            id: "fireworks",
            name: "皇家盛典烟花礼炮",
            subtitle: "点击随时在游乐园高空绽放漫天绚丽烟花",
            costCoins: 160,
            icon: "🎆",
            primaryHex: "#E25247",
            secondaryHex: "#FFD166",
            cheerSpeech: "砰！啪！漫天绚丽的皇家烟花为你绽放！"
        )
    ]
}

// MARK: - 🎁 局末结算「三选一神秘宝箱」定义
public struct MysteryChestItem: Identifiable, Equatable, Sendable {
    public let id: Int // 0, 1, 2
    public let title: String
    public let subtitle: String
    public let emoji: String
    public let rewardType: String // "coins", "ticket", "pet_food", "butterfly"
    public let amount: Int
    public let accentHex: String
}

// MARK: - 🎰 扭蛋开盒动画事件
public struct GachaHatchEvent: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let pet: GuardianPetSpecies
    public let isNew: Bool
    public let fromStage: Int
    public let toStage: Int
    public let totalExp: Int
}
