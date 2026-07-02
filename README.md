# NearBite

面向 2026 中国高校计算机大赛—移动应用创新赛的校园用餐决策 App。

## 当前保留内容

- `swiftui/EatWhat2Prototype.swift`：最新 SwiftUI 实现，包含推荐、收藏、MapKit 地图定位、距离排序和步行导航。
- `3.0-参赛包/iOS原型/`：最新 Web 高保真原型，用于初赛截图、演示视频和交互验证，不作为最终可运行 App 提交。
- `docs/`：初赛作品说明、版本说明、竞品分析和地图接入文档。
- `audit/`：产品定位审查截图与分析记录。

旧 HarmonyOS 工程、旧 Web 副本和本地 HarmonyOS 工具链已移除，避免与 iOS 参赛方向混淆。

## SwiftUI 运行要求

SwiftUI 版本需要在 macOS 的 Xcode 中创建 iOS App 工程后运行：

1. 将 `swiftui/EatWhat2Prototype.swift` 加入工程。
2. Deployment Target 设为 iOS 17 或更高版本。
3. 在 `Info.plist` 添加 `NSLocationWhenInUseUsageDescription`。
4. 使用模拟器或 iPhone 验证定位、地图点位和步行导航。

当前仓库尚未包含 `.xcodeproj`，因此 SwiftUI 文件仍需迁移为真实 Xcode 工程，才能用于复赛或决赛的设备运行演示。

## Web 原型运行

```powershell
cd .\3.0-参赛包\iOS原型
.\start-app.ps1
```

然后访问 `http://127.0.0.1:8787/`。

## 赛事材料口径

- 初赛：官方模板作品说明文档；可选提交一张 App 效果图或宣传海报。
- 复赛：作品说明文档和演示视频；产品原型或部分源代码按赛道选交。
- 决赛：演示视频和可在 iOS/iPadOS/visionOS 设备运行的 App。
