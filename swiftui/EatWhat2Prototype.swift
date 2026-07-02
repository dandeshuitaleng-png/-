import SwiftUI
import MapKit
import CoreLocation

// 集成到 Xcode 工程时，需要在 Info.plist 中配置 NSLocationWhenInUseUsageDescription。

struct CampusLocationChoice: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    static let campus = CampusLocationChoice(
        id: "campus",
        name: "安沙校区中心",
        detail: "默认校园位置",
        latitude: 28.3538,
        longitude: 113.0826
    )

    static let choices: [CampusLocationChoice] = [
        campus,
        CampusLocationChoice(
            id: "canteen",
            name: "北校区食堂",
            detail: "适合校内就餐",
            latitude: 28.3540,
            longitude: 113.0828
        ),
        CampusLocationChoice(
            id: "dorm",
            name: "学生宿舍区",
            detail: "适合夜间与外带",
            latitude: 28.3529,
            longitude: 113.0814
        )
    ]
}

final class AppLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var locationLabel = "尚未定位"
    @Published private(set) var isLocating = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var usesManualLocation = false

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 20
    }

    func requestPermissionAndLocate() {
        errorMessage = nil
        usesManualLocation = false

        switch manager.authorizationStatus {
        case .notDetermined:
            isLocating = true
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            requestCurrentLocation()
        case .denied, .restricted:
            isLocating = false
            errorMessage = "位置权限未开启，可以手动选择校区继续使用。"
        @unknown default:
            isLocating = false
            errorMessage = "暂时无法确认位置，可以手动选择校区。"
        }
    }

    func requestCurrentLocation() {
        guard manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse else {
            requestPermissionAndLocate()
            return
        }
        errorMessage = nil
        isLocating = true
        manager.requestLocation()
    }

    func useCampusLocation(_ choice: CampusLocationChoice) {
        currentLocation = choice.location
        locationLabel = choice.name
        isLocating = false
        errorMessage = nil
        usesManualLocation = true
    }

    var isOutsideCampusArea: Bool {
        guard !usesManualLocation, let currentLocation else { return false }
        return currentLocation.distance(from: CampusLocationChoice.campus.location) > 5000
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestCurrentLocation()
        case .denied, .restricted:
            isLocating = false
            errorMessage = "位置权限未开启，可以手动选择校区继续使用。"
        case .notDetermined:
            break
        @unknown default:
            isLocating = false
            errorMessage = "暂时无法确认位置，可以手动选择校区。"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationLabel = "当前位置"
        isLocating = false
        usesManualLocation = false
        errorMessage = location.horizontalAccuracy > 1000
            ? "定位精度较低，请重新定位或手动选择校区。"
            : nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        errorMessage = "定位失败，请重试或手动选择校区。"
    }
}

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

    var coordinate: CLLocationCoordinate2D {
        CampusDiningData.coordinate(for: self)
    }
}

struct NearbyDiningOption: Identifiable {
    let option: DiningOption
    let distanceMeters: CLLocationDistance

    var id: String { option.id }

    var distanceText: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters.rounded()))m"
        }
        return String(format: "%.1fkm", distanceMeters / 1000)
    }

    var walkingText: String {
        let minutes = max(1, Int((distanceMeters / 80).rounded()))
        return "步行约 \(minutes) 分钟"
    }
}

struct DiningRecommendation {
    let main: DiningOption
    let alternatives: [DiningOption]
    let reasons: [String]
    let notice: String?
}

@MainActor
final class DiningDecisionModel: ObservableObject {
    @Published var selectedBudget: BudgetFilter = .under20
    @Published var selectedDistance: DistanceFilter = .walkable
    @Published var selectedNeed: NeedFilter = .fast
    @Published var avoidsSpicy = true
    @Published var recommendation: DiningRecommendation?
    @Published var favoriteIds: [String] = []

    private let options: [DiningOption] = CampusDiningData.options

    var allOptions: [DiningOption] {
        options
    }

    var favoriteOptions: [DiningOption] {
        favoriteIds.compactMap { id in options.first { $0.id == id } }
    }

    func decide() {
        let result = candidatePool()
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
        let strict = options.filter(matchesAllFilters)
        if !strict.isEmpty {
            return (strict, nil)
        }

        let relaxedDistance = options.filter { option in
            selectedBudget.matches(option.averagePrice) && matchesSpice(option)
        }
        if !relaxedDistance.isEmpty {
            return (relaxedDistance, "附近选择不多，已先放宽距离")
        }

        let relaxedBudget = options.filter { option in
            matchesDistance(option) && matchesSpice(option)
        }
        if !relaxedBudget.isEmpty {
            return (relaxedBudget, "预算内选择不多，已先保留距离和忌口")
        }

        let relaxedSpice = options.filter { option in
            selectedBudget.matches(option.averagePrice) && matchesDistance(option)
        }
        if !relaxedSpice.isEmpty {
            return (relaxedSpice, "完全不辣选择不多，已允许可选辣度")
        }

        return (options, "当前条件过窄，已给出校园附近可执行选择")
    }

    private func matchesAllFilters(_ option: DiningOption) -> Bool {
        selectedBudget.matches(option.averagePrice) && matchesDistance(option) && matchesSpice(option)
    }

    private func matchesDistance(_ option: DiningOption) -> Bool {
        guard let limit = selectedDistance.limitKm else { return true }
        return option.distanceKm <= limit
    }

    private func matchesSpice(_ option: DiningOption) -> Bool {
        !avoidsSpicy || option.spice != .yes
    }

    private func score(_ option: DiningOption) -> Int {
        var value = 100
        value -= Int(option.distanceKm * 12)
        value -= option.averagePrice / 2

        if favoriteIds.contains(option.id) {
            value += 18
        }
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
        return value
    }

    private func tagScore(_ option: DiningOption, _ keywords: [String]) -> Int {
        option.healthTags.reduce(0) { total, tag in
            total + (keywords.contains { tag.contains($0) } ? 8 : 0)
        }
    }

    private func reasons(for option: DiningOption) -> [String] {
        var items: [String] = []
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
}

enum CampusDiningData {
    static func coordinate(for option: DiningOption) -> CLLocationCoordinate2D {
        switch option.id {
        case "canteen-noodles", "canteen-steamed":
            return CLLocationCoordinate2D(latitude: 28.3539, longitude: 113.0827)
        case "canteen-light", "canteen-weigh", "canteen-malatang", "canteen-claypot":
            return CLLocationCoordinate2D(latitude: 28.3540, longitude: 113.0828)
        case "gate-breakfast":
            return CLLocationCoordinate2D(latitude: 28.3535, longitude: 113.0835)
        case "wanhuayuan-rice-noodle":
            return CLLocationCoordinate2D(latitude: 28.3542, longitude: 113.0848)
        case "wanhuayuan-gaima":
            return CLLocationCoordinate2D(latitude: 28.3545, longitude: 113.0860)
        case "shuitang-muton":
            return CLLocationCoordinate2D(latitude: 28.3550, longitude: 113.0870)
        case "chunjian-fried":
            return CLLocationCoordinate2D(latitude: 28.3557, longitude: 113.0884)
        case "chunjian-drypot":
            return CLLocationCoordinate2D(latitude: 28.3561, longitude: 113.0890)
        case "chunjian-dumpling":
            return CLLocationCoordinate2D(latitude: 28.3566, longitude: 113.0897)
        case "ansha-beef-noodle":
            return CLLocationCoordinate2D(latitude: 28.3580, longitude: 113.0920)
        case "ansha-tea-light":
            return CLLocationCoordinate2D(latitude: 28.3590, longitude: 113.0940)
        case "bolin":
            return CLLocationCoordinate2D(latitude: 28.3602, longitude: 113.0970)
        default:
            return fallbackCoordinate(for: option)
        }
    }

    private static func fallbackCoordinate(for option: DiningOption) -> CLLocationCoordinate2D {
        let origin = CampusLocationChoice.campus
        let index = options.firstIndex { $0.id == option.id } ?? 0
        let angle = Double(index) * 2.3999632297
        let distance = max(option.distanceKm, 0.08)
        let latitudeOffset = cos(angle) * distance / 111
        let longitudeScale = 111 * cos(origin.latitude * .pi / 180)
        let longitudeOffset = sin(angle) * distance / longitudeScale
        return CLLocationCoordinate2D(
            latitude: origin.latitude + latitudeOffset,
            longitude: origin.longitude + longitudeOffset
        )
    }

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

enum AppTab: Hashable {
    case recommendation
    case nearby
    case favorites
}

struct ContentView: View {
    @StateObject private var model = DiningDecisionModel()
    @StateObject private var locationManager = AppLocationManager()
    @State private var selectedTab: AppTab = .nearby

    var body: some View {
        TabView(selection: $selectedTab) {
            DecisionView(model: model)
                .tabItem {
                    Label("推荐", systemImage: "sparkles")
                }
                .tag(AppTab.recommendation)

            NearbyMapView(model: model, locationManager: locationManager)
                .tabItem {
                    Label("附近", systemImage: "map")
                }
                .tag(AppTab.nearby)

            FavoritesView(model: model)
                .tabItem {
                    Label("想吃", systemImage: "bookmark")
                }
                .tag(AppTab.favorites)
        }
        .tint(.black)
        .preferredColorScheme(.light)
    }
}

struct NearbyMapView: View {
    @ObservedObject var model: DiningDecisionModel
    @ObservedObject var locationManager: AppLocationManager

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 28.3538, longitude: 113.0826),
            latitudinalMeters: 1800,
            longitudinalMeters: 1800
        )
    )
    @State private var selectedOptionID: String?
    @State private var showsLocationSheet = true

    private var origin: CLLocation {
        locationManager.currentLocation ?? CampusLocationChoice.campus.location
    }

    private var nearbyOptions: [NearbyDiningOption] {
        model.allOptions
            .map { option in
                let destination = CLLocation(
                    latitude: option.coordinate.latitude,
                    longitude: option.coordinate.longitude
                )
                return NearbyDiningOption(
                    option: option,
                    distanceMeters: destination.distance(from: origin)
                )
            }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    private var visibleOptions: [NearbyDiningOption] {
        Array(nearbyOptions.prefix(16))
    }

    private var selectedOption: NearbyDiningOption? {
        guard let selectedOptionID else { return visibleOptions.first }
        return visibleOptions.first { $0.id == selectedOptionID }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: $selectedOptionID) {
                Marker(
                    locationManager.locationLabel,
                    systemImage: "location.fill",
                    coordinate: origin.coordinate
                )
                .tint(.black)

                ForEach(visibleOptions) { item in
                    Marker(
                        item.option.name,
                        systemImage: "fork.knife",
                        coordinate: item.option.coordinate
                    )
                    .tint(item.id == selectedOptionID ? Color.black : Color.gray)
                    .tag(item.id)
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                mapHeader
                Spacer()

                if locationManager.isLocating {
                    LocationStateCard(
                        title: "正在定位你的位置",
                        message: "正在确认当前校区和附近餐饮点。",
                        showsProgress: true,
                        primaryActionTitle: "",
                        secondaryActionTitle: "",
                        onRetry: {},
                        onManual: {}
                    )
                } else if let errorMessage = locationManager.errorMessage {
                    LocationStateCard(
                        title: "暂时无法获取你的位置",
                        message: errorMessage,
                        showsProgress: false,
                        primaryActionTitle: "重新定位",
                        secondaryActionTitle: "手动选校区",
                        onRetry: locationManager.requestPermissionAndLocate,
                        onManual: { showsLocationSheet = true }
                    )
                } else if locationManager.isOutsideCampusArea {
                    LocationStateCard(
                        title: "你似乎不在安沙校区附近",
                        message: "可以继续按安沙校区推荐，或切换到一个校园位置。",
                        showsProgress: false,
                        primaryActionTitle: "按安沙校区推荐",
                        secondaryActionTitle: "切换位置",
                        onRetry: { locationManager.useCampusLocation(.campus) },
                        onManual: { showsLocationSheet = true }
                    )
                } else if let selectedOption {
                    MapRestaurantCard(item: selectedOption) {
                        openInMaps(selectedOption.option)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showsLocationSheet) {
            LocationPermissionSheet(locationManager: locationManager)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            selectedOptionID = selectedOptionID ?? visibleOptions.first?.id
        }
        .onChange(of: locationManager.currentLocation) { _, location in
            guard let location else { return }
            centerMap(on: location.coordinate)
            selectedOptionID = nearbyOptions.first?.id
        }
        .onChange(of: selectedOptionID) { _, id in
            guard let id, let option = visibleOptions.first(where: { $0.id == id }) else { return }
            centerMap(on: option.option.coordinate, spanMeters: 1000)
        }
    }

    private var mapHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(locationManager.locationLabel)
                    .font(.headline)
                    .lineLimit(1)
                Text("附近 \(visibleOptions.count) 家 · 按距离排序")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if locationManager.authorizationStatus == .notDetermined {
                    showsLocationSheet = true
                } else {
                    locationManager.requestPermissionAndLocate()
                }
            } label: {
                Image(systemName: "location")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("重新定位")
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D, spanMeters: CLLocationDistance = 1800) {
        withAnimation(.easeInOut(duration: 0.25)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: spanMeters,
                    longitudinalMeters: spanMeters
                )
            )
        }
    }

    private func openInMaps(_ option: DiningOption) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: option.coordinate))
        item.name = option.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

struct MapRestaurantCard: View {
    let item: NearbyDiningOption
    let onNavigate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("附近推荐")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(item.option.name)
                .font(.title3.bold())
                .lineLimit(2)

            HStack(spacing: 12) {
                Label("¥\(item.option.averagePrice)", systemImage: "creditcard")
                Label(item.distanceText, systemImage: "figure.walk")
                Text(item.walkingText)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("离你较近，符合当前步行范围。")
                .font(.subheadline)

            Button("去这里", action: onNavigate)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
    }
}

struct LocationStateCard: View {
    let title: String
    let message: String
    let showsProgress: Bool
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let onRetry: () -> Void
    let onManual: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsProgress {
                ProgressView()
                    .tint(.black)
            }

            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !showsProgress {
                HStack(spacing: 10) {
                    Button(primaryActionTitle, action: onRetry)
                        .buttonStyle(.borderedProminent)
                    Button(secondaryActionTitle, action: onManual)
                        .buttonStyle(.bordered)
                }
                .tint(.black)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
    }
}

struct LocationPermissionSheet: View {
    @ObservedObject var locationManager: AppLocationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("先确认你在哪")
                            .font(.largeTitle.bold())
                        Text("NearBite 会根据你的位置，优先推荐步行可达、距离更近的餐饮点。")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        locationManager.requestPermissionAndLocate()
                        dismiss()
                    } label: {
                        Label("允许定位", systemImage: "location.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("或手动选择校区位置")
                            .font(.headline)

                        ForEach(CampusLocationChoice.choices) { choice in
                            Button {
                                locationManager.useCampusLocation(choice)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(choice.name)
                                            .font(.body.weight(.semibold))
                                        Text(choice.detail)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .background(Color.black.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("稍后") {
                        locationManager.useCampusLocation(.campus)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DecisionView: View {
    @ObservedObject var model: DiningDecisionModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
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
                        ResultCard(recommendation: recommendation, isFavorite: model.isFavorite(recommendation.main)) {
                            model.toggleFavorite()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("长师安沙吃什么")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("安沙校区午晚餐")
                .font(.largeTitle.bold())
            Text("用预算、距离、忌口和当下状态，从 30 个校园周边餐饮点里给出一个可执行选择。")
                .foregroundStyle(.secondary)
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

            Picker("状态", selection: $model.selectedNeed) {
                ForEach(NeedFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Toggle("今天不吃重辣", isOn: $model.avoidsSpicy)
        }
    }
}

struct ResultCard: View {
    let recommendation: DiningRecommendation
    let isFavorite: Bool
    let onFavorite: () -> Void

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
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
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
