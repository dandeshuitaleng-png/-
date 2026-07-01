# 今天吃什么 2.0 参赛包

本包按 `019f1729-91df-7292-b9b8-eee535cdbe6d` 线程里的结论整理：2026 中国高校计算机大赛-移动应用创新赛要求作品面向 iOS / iPadOS / visionOS 方向，原 HarmonyOS 1.0 工程不能直接作为最终参赛作品提交。

## 2.0 定位

| 项目 | 1.0 | 2.0 |
| --- | --- | --- |
| 平台口径 | HarmonyOS ArkTS | iOS / SwiftUI 原型 |
| 产品定位 | 解决“今天吃什么”的随机决策工具 | 面向校园/园区场景的低决策成本饮食推荐助手 |
| 核心体验 | 直接抽取、回答两题、收藏 | 一键推荐、两题问答、预算/距离/忌口/出餐速度、推荐理由、收藏与历史回用 |
| 参赛目标 | 功能验证 | 初赛说明文档 + iOS 高保真原型 + SwiftUI MVP 骨架 |

## 文件说明

- `初赛作品说明.md`：按官方初赛作品说明模板补齐的参赛文案。
- `iOS原型/index.html`：可直接在浏览器打开的 iPhone 风格高保真原型，包含手机号/Apple ID 注册、新手引导、一键/两题推荐、位置降级、长期偏好、收藏、历史和餐饮数据维护闭环。
- `swiftui/EatWhat2Prototype.swift`：与原型定位一致的 SwiftUI MVP 骨架，内置约 30 条校园周边样本餐饮数据，方便后续在 Xcode 中创建 iOS 工程时迁移。

## 数据验证口径

当前版本没有把具体学校写成产品定位，只把用户提供的校园周边餐饮表作为冷启动样本数据。它用于验证一件事：当数据具备价格、距离、辣度、健康标签、出餐速度和营业时段这些字段时，App 可以在不接入完整点评平台的前提下给出“可解释、可执行”的一餐推荐。后续接入其他学校、办公园区或真实地图数据时，只需要替换同结构的数据源。

## 建议提交路线

1. 先用 `初赛作品说明.md` 完成平台作品说明。
2. 打开 `iOS原型/index.html`，截取首页、问答、结果、收藏四类截图。
3. 复赛前用 Xcode 将 `swiftui/EatWhat2Prototype.swift` 拆进真实 SwiftUI 工程，补充真机运行视频。

## 当前限制

- Windows 环境无法验证 Xcode 构建；SwiftUI 文件是可迁移原型骨架，不是已签名的 `.ipa`。
- 原 HarmonyOS 工程保留为 1.0 技术沉淀，未伪装成 iOS 作品。
%% Error: Cannot create a waypoint in a note that's not the folder note. For more information, check the instructions [here](https://github.com/IdreesInc/Waypoint) %%
