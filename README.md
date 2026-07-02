# NearBite

## 3.0 参赛包

当前演示版本统一使用 3.0：

- `3.0-参赛包/iOS原型/index.html`：iPhone 风格高保真原型，可直接打开体验。
- `docs/3.0-版本说明.md`：3.0 的定位、功能变化和后续开发建议。

原 HarmonyOS 工程保留为 1.0 技术沉淀；旧的 2.0 参赛包已从本地工作区移除。

本目录已从 Obsidian Markdown 归档还原为 HarmonyOS 工程文件。保留 `.md` 归档文件，同时生成了对应的 `.ets`、`.json5`、`.ts`、`.json` 和 `.txt` 文件。

## 运行方式

1. 使用 DevEco Studio 打开当前项目目录。
2. 等待 DevEco Studio 同步 Hvigor、HarmonyOS SDK 和 ohpm 依赖。
3. 连接 HarmonyOS 真机或启动模拟器。
4. 在 DevEco Studio 中运行 `entry` 模块。

## 命令行验证

如果本机已安装 HarmonyOS 命令行工具，可在项目根目录执行：

```powershell
.\hvigorw.bat test --no-daemon
.\hvigorw.bat assembleHap --no-daemon
```

## 当前本地工具链状态

Codex 已在项目内放置本地 JDK 17 和华为官方旧版 Command Line Tools：

- `.toolchain/jdk/jdk17`
- `.toolchain/commandline-tools`

旧版 Command Line Tools 可以启动 `sdkmgr`，但只能列出 HarmonyOS API 9 及以下 SDK；本项目配置为 HarmonyOS `6.1.1(24)`，仍需要通过华为下载中心获取新版 Command Line Tools / SDK 后才能在命令行中完成 `hvigorw` 测试和 HAP 构建。
%% Error: Cannot create a waypoint in a note that's not the folder note. For more information, check the instructions [here](https://github.com/IdreesInc/Waypoint) %%
