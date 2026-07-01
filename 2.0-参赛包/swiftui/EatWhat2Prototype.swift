import SwiftUI

enum BudgetFilter: String, CaseIterable, Identifiable {
    case all = "不限"
    case under10 = "10 内"
    case under20 = "20 内"
    case under30 = "30 内"
    case over30 = "30+"

    var id: String { rawValue }

    func matches(_ price: Int) -> Bool {
        switch self {
        case .all:
            return true
        case .under10:
            return price <= 10
        case .under20:
            return price <= 20
        case .under30:
            return price <= 30
        case .over30:
            return price > 30
        }
    }
}

enum DistanceFilter: String, CaseIterable, Identifiable {
    case all = "不限"
    case near = "0.5km"
    case walkable = "1km"
    case town = "2km"

    var id: String { rawValue }

    var limitKm: Double? {
        switch self {
        case .all:
            return nil
        case .near:
            return 0.5
        case .walkable:
            return 1
        case .town:
            return 2
        }
    }
}

enum NeedFilter: String, CaseIterable, Identifiable {
    case fast = "赶时间"
    case light = "清淡"
    case filling = "管饱"
    case treat = "奖励"

    var id: String { rawValue }
}

enum DecisionMode: String, CaseIterable, Identifiable {
    case quick = "一键推荐"
    case questions = "回答两题"

    var id: String { rawValue }
}

enum DiningDirection: String, CaseIterable, Identifiable {
    case random = "随便"
    case noodles = "粉面"
    case rice = "米饭"
    case snack = "小吃"
    case light = "轻食"

    var id: String { rawValue }
}

enum DietPreference: String, CaseIterable, Identifiable {
    case all = "不限"
    case light = "少油轻食"
    case vegetarian = "素食友好"

    var id: String { rawValue }
}

enum SpiceLevel: String {
    case no = "否"
    case optional = "可选"
    case yes = "是"
}

enum ServingSpeed: String {
    case fast = "快"
    case medium = "中"
    case slow = "慢"
}

struct DiningOption: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let averagePrice: Int
    let distanceKm: Double
    let spice: SpiceLevel
    let healthTags: [String]
    let speed: ServingSpeed
    let waitTime: String
    let businessHours: String

    var distanceText: String {
        distanceKm < 1 ? "\(Int(distanceKm * 1000))m" : String(format: "%.1fkm", distanceKm)
    }

    var subtitle: String {
        "\(category) · 人均 \(averagePrice) 元 · \(distanceText)"
    }
}

struct DiningRecommendation {
    let main: DiningOption
    let alternatives: [DiningOption]
    let reasons: [String]
    let notice: String?
}

struct DiningHistoryEntry: Identifiable {
    let id = UUID()
    let option: DiningOption
    let context: String
    let eaten: Bool
}

@MainActor
final class DiningDecisionModel: ObservableObject {
    @Published var mode: DecisionMode = .quick
    @Published var selectedBudget: BudgetFilter = .under20
    @Published var selectedDistance: DistanceFilter = .walkable
    @Published var selectedNeed: NeedFilter = .fast
    @Published var selectedDirection: DiningDirection = .random
    @Published var selectedDiet: DietPreference = .all
    @Published var prefersFastService = true
    @Published var avoidsSpicy = true
    @Published var selectedLocation = "长沙师范学院安沙校区"
    @Published var recommendation: DiningRecommendation?
    @Published var favoriteIds: [String] = []
    @Published var skippedIds: Set<String> = []
    @Published var history: [DiningHistoryEntry] = []

    private let options: [DiningOption] = CampusDiningData.options

    var favoriteOptions: [DiningOption] {
        favoriteIds.compactMap { id in options.first { $0.id == id } }
    }

    var activeOptionCount: Int { options.count - skippedIds.count }

    func decide() {
        var result = candidatePool()
        if result.options.isEmpty {
            skippedIds.removeAll()
            result = candidatePool()
        }
        let selected = result.options.max { score($0) < score($1) }
        guard let selected else { return }

        let alternatives = result.options
            .filter { $0.id != selected.id }
            .sorted { score($0) > score($1) }
            .prefix(3)

        recommendation = DiningRecommendation(
            main: selected,
            alternatives: Array(alternatives),
            reasons: reasons(for: selected),
            notice: result.notice
        )
        addHistory(selected, eaten: false)
    }

    func skipCurrent() {
        guard let id = recommendation?.main.id else { return }
        skippedIds.insert(id)
        decide()
    }

    func markCurrentAsEaten() {
        guard let option = recommendation?.main else { return }
        addHistory(option, eaten: true)
    }

    func recommendAgain(_ option: DiningOption) {
        recommendation = DiningRecommendation(
            main: option,
            alternatives: options.filter { $0.id != option.id && !skippedIds.contains($0.id) }.prefix(2).map { $0 },
            reasons: reasons(for: option),
            notice: "已按历史记录再次推荐"
        )
    }

    func toggleFavorite() {
        guard let id = recommendation?.main.id else { return }
        if favoriteIds.contains(id) {
            favoriteIds.removeAll { $0 == id }
        } else {
            favoriteIds.insert(id, at: 0)
        }
    }

    func isFavorite(_ option: DiningOption) -> Bool {
        favoriteIds.contains(option.id)
    }

    private func candidatePool() -> (options: [DiningOption], notice: String?) {
        let available = options.filter { !skippedIds.contains($0.id) }
        let strict = available.filter(matchesAllFilters)
        if !strict.isEmpty {
            return (strict, nil)
        }

        let relaxedDistance = available.filter { option in
            selectedBudget.matches(option.averagePrice) && matchesSpice(option) && matchesDirection(option)
        }
        if !relaxedDistance.isEmpty {
            return (relaxedDistance, "附近选择不多，已先放宽距离")
        }

        let relaxedBudget = available.filter { option in
            matchesDistance(option) && matchesSpice(option) && matchesDirection(option)
        }
        if !relaxedBudget.isEmpty {
            return (relaxedBudget, "预算内选择不多，已先保留距离和忌口")
        }

        let relaxedSpice = available.filter { option in
            selectedBudget.matches(option.averagePrice) && matchesDistance(option) && matchesDirection(option)
        }
        if !relaxedSpice.isEmpty {
            return (relaxedSpice, "完全不辣选择不多，已允许可选辣度")
        }

        return (available, "当前条件过窄，已给出校园附近可执行选择")
    }

    private func matchesAllFilters(_ option: DiningOption) -> Bool {
        selectedBudget.matches(option.averagePrice) && matchesDistance(option) && matchesSpice(option) &&
            matchesDirection(option) && matchesDiet(option) && matchesSpeed(option)
    }

    private func matchesDistance(_ option: DiningOption) -> Bool {
        guard let limit = selectedDistance.limitKm else { return true }
        return option.distanceKm <= limit
    }

    private func matchesSpice(_ option: DiningOption) -> Bool {
        !avoidsSpicy || option.spice != .yes
    }

    private func matchesDirection(_ option: DiningOption) -> Bool {
        guard mode == .questions else { return true }
        let text = "\(option.name) \(option.category) \(option.healthTags.joined(separator: " "))"
        switch selectedDirection {
        case .random:
            return true
        case .noodles:
            return text.contains("粉") || text.contains("面")
        case .rice:
            return text.contains("饭") || text.contains("快餐") || text.contains("蒸菜")
        case .snack:
            return text.contains("小吃") || text.contains("炸串") || text.contains("茶饮")
        case .light:
            return text.contains("轻食") || text.contains("少油") || text.contains("低脂") || text.contains("蔬菜")
        }
    }

    private func matchesDiet(_ option: DiningOption) -> Bool {
        let text = "\(option.category) \(option.healthTags.joined(separator: " "))"
        switch selectedDiet {
        case .all:
            return true
        case .light:
            return ["少油", "低脂", "控卡", "轻食", "清淡", "蔬菜"].contains { text.contains($0) }
        case .vegetarian:
            return ["蔬菜", "自选", "轻食", "蒸菜", "素食"].contains { text.contains($0) }
        }
    }

    private func matchesSpeed(_ option: DiningOption) -> Bool {
        !prefersFastService || option.speed == .fast
    }

    private func score(_ option: DiningOption) -> Int {
        var value = 100
        value -= Int(option.distanceKm * 12)
        value -= option.averagePrice / 2

        if favoriteIds.contains(option.id) {
            value += 18
        }
        if mode == .questions {
            switch selectedNeed {
            case .fast:
                if option.speed == .fast { value += 24 }
                if option.distanceKm <= 0.5 { value += 12 }
            case .light:
                if option.spice == .no { value += 10 }
                value += tagScore(option, ["少油", "清淡", "低脂", "控卡", "低油", "蔬菜多", "轻食"])
            case .filling:
                value += tagScore(option, ["饱腹", "高蛋白", "高碳水", "主食稳定"])
            case .treat:
                value += tagScore(option, ["聚餐", "夜宵", "现炒", "正餐", "重口味"])
                if option.averagePrice >= 30 { value += 8 }
            }
        }
        return value
    }

    private func tagScore(_ option: DiningOption, _ keywords: [String]) -> Int {
        option.healthTags.reduce(0) { total, tag in
            total + (keywords.contains { tag.contains($0) } ? 8 : 0)
        }
    }

    private func reasons(for option: DiningOption) -> [String] {
        var items: [String] = []
        if mode == .quick {
            items.append("结合 \(selectedLocation)、当前餐段和长期偏好")
        } else {
            items.append("匹配“\(selectedNeed.rawValue)”和“\(selectedDirection.rawValue)”")
        }
        if selectedBudget.matches(option.averagePrice) {
            items.append("人均 \(option.averagePrice) 元，符合预算")
        }
        if matchesDistance(option) {
            items.append("距离 \(option.distanceText)，下课后可直接去")
        }
        if avoidsSpicy && option.spice != .yes {
            items.append(option.spice == .no ? "不辣，符合忌口" : "可选辣度，能避开重辣")
        }
        if option.speed == .fast {
            items.append("出餐快，约 \(option.waitTime)")
        }
        if let tag = option.healthTags.first {
            items.append(tag)
        }
        if favoriteIds.contains(option.id) {
            items.append("与你的收藏偏好相近")
        }
        return Array(items.prefix(4))
    }

    private func addHistory(_ option: DiningOption, eaten: Bool) {
        history.removeAll { $0.option.id == option.id && $0.eaten == eaten }
        let context = mode == .quick ? "一键推荐" : "\(selectedNeed.rawValue) · \(selectedDirection.rawValue)"
        history.insert(DiningHistoryEntry(option: option, context: context, eaten: eaten), at: 0)
        history = Array(history.prefix(6))
    }
}

enum CampusDiningData {
    static let options: [DiningOption] = [
        DiningOption(id: "canteen-noodles", name: "北校区食堂二楼粉面档", category: "湖南米粉/面", averagePrice: 10, distanceKm: 0.1, spice: .optional, healthTags: ["早餐", "低价", "少油可选"], speed: .fast, waitTime: "3-5分钟", businessHours: "06:30-13:30"),
        DiningOption(id: "canteen-steamed", name: "北校区食堂二楼蒸菜档", category: "蒸菜/快餐", averagePrice: 13, distanceKm: 0.1, spice: .optional, healthTags: ["少油", "蔬菜多", "热量适中"], speed: .fast, waitTime: "5-8分钟", businessHours: "10:30-13:30 / 16:30-19:30"),
        DiningOption(id: "canteen-weigh", name: "北校区食堂三楼自选餐", category: "自选称重餐", averagePrice: 18, distanceKm: 0.1, spice: .optional, healthTags: ["蔬菜多", "可控量", "均衡"], speed: .fast, waitTime: "5-8分钟", businessHours: "10:30-19:30"),
        DiningOption(id: "canteen-malatang", name: "北校区食堂三楼麻辣烫", category: "麻辣烫/冒菜", averagePrice: 19, distanceKm: 0.1, spice: .yes, healthTags: ["可多蔬菜", "可少油"], speed: .medium, waitTime: "8-12分钟", businessHours: "10:30-20:30"),
        DiningOption(id: "canteen-light", name: "北校区食堂四楼轻食饭", category: "轻食/鸡胸肉饭", averagePrice: 20, distanceKm: 0.1, spice: .no, healthTags: ["低脂", "高蛋白", "控卡"], speed: .fast, waitTime: "6-10分钟", businessHours: "10:30-19:30"),
        DiningOption(id: "canteen-claypot", name: "北校区食堂四楼煲仔饭", category: "煲仔饭", averagePrice: 21, distanceKm: 0.1, spice: .optional, healthTags: ["饱腹", "现做", "高碳水"], speed: .slow, waitTime: "12-18分钟", businessHours: "10:30-20:00"),
        DiningOption(id: "gate-breakfast", name: "校门口早餐铺", category: "包子/豆浆/粥", averagePrice: 8, distanceKm: 0.2, spice: .no, healthTags: ["早餐", "清淡", "低价"], speed: .fast, waitTime: "2-4分钟", businessHours: "06:00-10:30"),
        DiningOption(id: "wanhuayuan-rice-noodle", name: "万花园路拌粉小店", category: "拌粉/汤粉", averagePrice: 11, distanceKm: 0.3, spice: .optional, healthTags: ["低价", "快餐", "早餐"], speed: .fast, waitTime: "3-6分钟", businessHours: "07:00-14:00 / 17:00-21:00"),
        DiningOption(id: "wanhuayuan-gaima", name: "万花园路现炒盖码饭", category: "湘菜盖饭", averagePrice: 17, distanceKm: 0.4, spice: .yes, healthTags: ["高蛋白", "现炒", "饱腹"], speed: .medium, waitTime: "8-12分钟", businessHours: "10:30-21:30"),
        DiningOption(id: "shuitang-muton", name: "水塘垸社区木桶饭", category: "木桶饭/快餐", averagePrice: 16, distanceKm: 0.5, spice: .optional, healthTags: ["饱腹", "可加青菜"], speed: .fast, waitTime: "6-10分钟", businessHours: "10:00-21:00"),
        DiningOption(id: "shuitang-chicken", name: "水塘垸社区黄焖鸡", category: "黄焖鸡米饭", averagePrice: 18, distanceKm: 0.6, spice: .optional, healthTags: ["高蛋白", "热量适中"], speed: .medium, waitTime: "8-12分钟", businessHours: "10:00-22:00"),
        DiningOption(id: "chunjian-fried", name: "春建路炸串铺", category: "炸串/小吃", averagePrice: 14, distanceKm: 0.6, spice: .optional, healthTags: ["夜宵", "小吃", "热量较高"], speed: .fast, waitTime: "5-8分钟", businessHours: "15:00-23:30"),
        DiningOption(id: "niumoxi-bbq", name: "牛魔系烤串长沙师范学院店", category: "烧烤/夜宵", averagePrice: 45, distanceKm: 0.7, spice: .yes, healthTags: ["高蛋白", "夜宵", "重口味"], speed: .slow, waitTime: "15-25分钟", businessHours: "17:00-02:00"),
        DiningOption(id: "chunjian-drypot", name: "春建路麻辣香锅", category: "香锅/自选", averagePrice: 24, distanceKm: 0.7, spice: .yes, healthTags: ["可加蔬菜", "高蛋白"], speed: .medium, waitTime: "10-15分钟", businessHours: "10:30-22:00"),
        DiningOption(id: "chunjian-dumpling", name: "春建路东北水饺", category: "饺子/简餐", averagePrice: 15, distanceKm: 0.8, spice: .no, healthTags: ["少油", "主食稳定"], speed: .medium, waitTime: "8-12分钟", businessHours: "10:00-21:30"),
        DiningOption(id: "ansha-braised", name: "安沙镇卤味饭", category: "卤味/盖饭", averagePrice: 17, distanceKm: 0.9, spice: .optional, healthTags: ["高蛋白", "饱腹"], speed: .fast, waitTime: "5-8分钟", businessHours: "10:30-22:30"),
        DiningOption(id: "ansha-beef-noodle", name: "安沙镇兰州牛肉面", category: "牛肉面/拉面", averagePrice: 18, distanceKm: 1.0, spice: .optional, healthTags: ["高蛋白", "汤面", "少油可选"], speed: .medium, waitTime: "8-12分钟", businessHours: "09:00-22:00"),
        DiningOption(id: "ansha-luosifen", name: "安沙镇螺蛳粉", category: "螺蛳粉", averagePrice: 16, distanceKm: 1.0, spice: .yes, healthTags: ["重口味", "饱腹"], speed: .medium, waitTime: "8-12分钟", businessHours: "10:00-23:00"),
        DiningOption(id: "ansha-small-bowl", name: "安沙镇小碗菜", category: "小碗菜/快餐", averagePrice: 15, distanceKm: 1.1, spice: .optional, healthTags: ["菜品多", "价格低", "可控量"], speed: .fast, waitTime: "5-8分钟", businessHours: "10:30-20:30"),
        DiningOption(id: "ansha-bibimbap", name: "安沙镇石锅拌饭", category: "韩式简餐", averagePrice: 22, distanceKm: 1.2, spice: .optional, healthTags: ["蔬菜多", "主食均衡"], speed: .medium, waitTime: "8-12分钟", businessHours: "10:30-21:30"),
        DiningOption(id: "ansha-tea-light", name: "安沙镇茶饮轻食站", category: "茶饮/三明治", averagePrice: 16, distanceKm: 1.2, spice: .no, healthTags: ["轻食", "下午茶", "低油"], speed: .fast, waitTime: "3-6分钟", businessHours: "09:00-22:30"),
        DiningOption(id: "ansha-juice", name: "安沙镇鲜榨果饮", category: "果汁/酸奶杯", averagePrice: 15, distanceKm: 1.3, spice: .no, healthTags: ["维生素", "低油", "轻负担"], speed: .fast, waitTime: "3-5分钟", businessHours: "10:00-22:00"),
        DiningOption(id: "bolin", name: "伯林餐馆", category: "家常菜/炒菜", averagePrice: 35, distanceKm: 1.5, spice: .optional, healthTags: ["聚餐", "现炒", "高蛋白"], speed: .slow, waitTime: "15-25分钟", businessHours: "10:30-21:30"),
        DiningOption(id: "shunfeng", name: "顺丰酒店", category: "中餐/宴席", averagePrice: 55, distanceKm: 1.8, spice: .optional, healthTags: ["聚餐", "正餐", "多人用餐"], speed: .slow, waitTime: "20-35分钟", businessHours: "11:00-14:00 / 17:00-21:00"),
        DiningOption(id: "lige", name: "立哥私房菜", category: "湘菜/私房菜", averagePrice: 50, distanceKm: 2.0, spice: .yes, healthTags: ["聚餐", "现炒", "重口味"], speed: .slow, waitTime: "20-35分钟", businessHours: "11:00-14:00 / 17:00-22:00"),
        DiningOption(id: "ansha-pork-rice", name: "安沙北路猪脚饭", category: "猪脚饭/快餐", averagePrice: 21, distanceKm: 2.1, spice: .optional, healthTags: ["高蛋白", "高热量", "饱腹"], speed: .fast, waitTime: "6-10分钟", businessHours: "10:00-21:30"),
        DiningOption(id: "ansha-congee", name: "安沙北路砂锅粥", category: "粥/砂锅", averagePrice: 26, distanceKm: 2.3, spice: .no, healthTags: ["清淡", "夜宵", "养胃"], speed: .slow, waitTime: "15-25分钟", businessHours: "11:00-01:00"),
        DiningOption(id: "road107-fast", name: "107国道旁快餐店", category: "快餐/盒饭", averagePrice: 16, distanceKm: 2.5, spice: .optional, healthTags: ["低价", "饱腹", "出餐快"], speed: .fast, waitTime: "5-8分钟", businessHours: "10:00-20:30"),
        DiningOption(id: "road107-noodle", name: "107国道旁米粉馆", category: "米粉/面馆", averagePrice: 12, distanceKm: 2.6, spice: .optional, healthTags: ["早餐", "低价", "少油可选"], speed: .fast, waitTime: "3-6分钟", businessHours: "06:30-14:00"),
        DiningOption(id: "ansha-coffee", name: "安沙镇咖啡简餐", category: "咖啡/轻食", averagePrice: 28, distanceKm: 2.8, spice: .no, healthTags: ["轻食", "低油", "办公友好"], speed: .medium, waitTime: "8-12分钟", businessHours: "08:30-21:00")
    ]
}

@main
struct EatWhat2PrototypeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var model = DiningDecisionModel()

    var body: some View {
        TabView {
            DecisionView(model: model)
                .tabItem {
                    Label("决定", systemImage: "sparkles")
                }

            FavoritesView(model: model)
                .tabItem {
                    Label("收藏", systemImage: "star")
                }

            ProfileView(model: model)
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
        .tint(.green)
    }
}

struct DecisionView: View {
    @ObservedObject var model: DiningDecisionModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    Picker("推荐方式", selection: $model.mode) {
                        ForEach(DecisionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if model.mode == .questions {
                        questions
                    }
                    filters

                    Button {
                        model.decide()
                    } label: {
                        Label("一键决定这一餐", systemImage: "wand.and.stars")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)

                    if let recommendation = model.recommendation {
                        ResultCard(
                            recommendation: recommendation,
                            isFavorite: model.isFavorite(recommendation.main),
                            onFavorite: model.toggleFavorite,
                            onSkip: model.skipCurrent,
                            onAte: model.markCurrentAsEaten
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("今天吃什么 2.0")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("校园附近午晚餐")
                .font(.largeTitle.bold())
            Text("用位置、时间和长期偏好，在 10 秒内给出一个有理由、可执行的选择。")
                .foregroundStyle(.secondary)
        }
    }

    private var questions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("只回答两题")
                .font(.headline)

            Picker("当下需求", selection: $model.selectedNeed) {
                ForEach(NeedFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Picker("饮食方向", selection: $model.selectedDirection) {
                ForEach(DiningDirection.allCases) { direction in
                    Text(direction.rawValue).tag(direction)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("偏好")
                .font(.headline)

            Picker("预算", selection: $model.selectedBudget) {
                ForEach(BudgetFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Picker("距离", selection: $model.selectedDistance) {
                ForEach(DistanceFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Picker("饮食", selection: $model.selectedDiet) {
                ForEach(DietPreference.allCases) { preference in
                    Text(preference.rawValue).tag(preference)
                }
            }
            .pickerStyle(.segmented)

            Toggle("避开重辣", isOn: $model.avoidsSpicy)
            Toggle("优先快出餐", isOn: $model.prefersFastService)
        }
    }
}

struct ResultCard: View {
    let recommendation: DiningRecommendation
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onSkip: () -> Void
    let onAte: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let notice = recommendation.notice {
                Label(notice, systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(recommendation.main.name)
                    .font(.title2.bold())
                Text(recommendation.main.subtitle)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("\(recommendation.main.averagePrice) 元", systemImage: "creditcard")
                Label(recommendation.main.distanceText, systemImage: "figure.walk")
                Label(recommendation.main.speed.rawValue, systemImage: "timer")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            FlowTags(tags: recommendation.reasons)

            VStack(alignment: .leading, spacing: 8) {
                Text("附近备选")
                    .font(.headline)
                ForEach(recommendation.alternatives) { option in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.name)
                            .font(.subheadline.weight(.semibold))
                        Text("\(option.category) · \(option.averagePrice) 元 · \(option.distanceText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
                onFavorite()
            } label: {
                Label(isFavorite ? "已收藏这个选择" : "收藏这个选择", systemImage: isFavorite ? "star.fill" : "star")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            HStack {
                Button("近期不推荐", action: onSkip)
                    .buttonStyle(.bordered)
                Button("记录已吃", action: onAte)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FlowTags: View {
    let tags: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
}

struct FavoritesView: View {
    @ObservedObject var model: DiningDecisionModel

    var body: some View {
        NavigationStack {
            List {
                if model.favoriteOptions.isEmpty {
                    ContentUnavailableView("暂无收藏", systemImage: "star", description: Text("满意的校园餐饮点会出现在这里。"))
                } else {
                    ForEach(model.favoriteOptions) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name)
                                .font(.headline)
                            Text(item.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("收藏")
        }
    }
}

struct ProfileView: View {
    @ObservedObject var model: DiningDecisionModel
    private let locations = ["长沙师范学院安沙校区", "北校区食堂", "学生宿舍区"]

    var body: some View {
        NavigationStack {
            List {
                Section("位置降级") {
                    Picker("当前区域", selection: $model.selectedLocation) {
                        ForEach(locations, id: \.self) { location in
                            Text(location).tag(location)
                        }
                    }
                    Text("系统定位不可用时，可手动选择校园区域继续推荐。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("使用概况") {
                    LabeledContent("可用餐饮数据", value: "\(model.activeOptionCount) 条")
                    LabeledContent("收藏", value: "\(model.favoriteIds.count) 个")
                }

                Section("最近记录") {
                    if model.history.isEmpty {
                        Text("最近推荐和实际选择会显示在这里。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.history) { entry in
                            Button {
                                model.recommendAgain(entry.option)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(entry.eaten ? "已吃" : "推荐") · \(entry.option.name)")
                                        .foregroundStyle(.primary)
                                    Text("\(entry.context) · 点击再次推荐")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的")
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: width, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
%% Error: Cannot create a waypoint in a note that's not the folder note. For more information, check the instructions [here](https://github.com/IdreesInc/Waypoint) %%
%% Error: Cannot create a waypoint in a note that's not the folder note. For more information, check the instructions [here](https://github.com/IdreesInc/Waypoint) %%
