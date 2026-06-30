# 吃什么 App

面向长沙师范学院安沙校区附近的吃饭决策助手。核心流程是：回答今日问题 -> 翻牌推荐 -> 收藏 / 换一张 / 查看详情 / 去这里。

## 功能概览

- 今日问题：人数、想吃类型、口味、当前状态、堂食/打包/外卖
- 翻牌推荐：根据今日偏好和长期偏好给出餐厅卡片
- 推荐卡片：店名、品类、人均、步行时间、辣度、健康标签、出餐速度、营业时间、推荐理由
- 收藏页：收藏餐厅筛选、取消收藏、查看详情、推荐相似
- 我的页：默认预算、默认距离、饮食禁忌、历史记录
- 高德接入：本地后端代理读取 `AMAP_WEB_KEY`，封装周边餐饮和步行路线接口，避免前端暴露 Key

## 目录结构

```text
app/                 Web/iOS 风格可运行原型
  index.html         原型入口
  app-v2.js          翻牌推荐、收藏、详情、路线交互
  server.js          本地高德 Web 服务代理
  start-app.ps1      Windows 启动脚本
  .env.example       环境变量示例，不含真实 Key
swiftui/             SwiftUI 单文件原型
docs/                作品说明和高德接入设计文档
```

## 本地运行 Web 原型

1. 进入 `app/` 目录。
2. 复制 `.env.example` 为 `.env.local`。
3. 在 `.env.local` 中填入高德 Web 服务 Key：

```env
AMAP_WEB_KEY=你的高德Web服务Key
PORT=8787
```

4. 启动服务：

```powershell
.\start-app.ps1
```

5. 浏览器打开：

```text
http://127.0.0.1:8787/index.html
```

## 安全说明

不要把 `.env.local` 或真实高德 Key 提交到仓库。前端只请求本地代理接口：

- `GET /api/food/nearby`
- `GET /api/route/walking`

## 文档

- [初赛作品说明](docs/初赛作品说明.md)
- [高德地图接入方法与店铺信息设计](docs/高德地图接入方法与店铺信息设计.md)