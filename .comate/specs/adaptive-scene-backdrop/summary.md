# 场景背景图自适应窗口 —— 完成总结

## 结果

主场景舞台的背景图从 `scaledToFill()`（裁切）改为 `scaledToFit()`（完整展示），窗口比例与图片比例不一致时，多出来的区域由同一张图放大模糊后铺底。拖动窗口到任意尺寸，场景内容不再被裁掉。

## 代码改动

**`在场/Platform/BundledSceneImage.swift`**（主要改动）
- 新增 `SceneImageFitMode`：`.fill`（原行为）/ `.fitBlurred`（fit + 模糊铺底）。`BundledSceneImage.fitMode` 默认 `.fill`，因此缩略图与预览调用点零改动。
- `.fitBlurred` 分支为 `ZStack { 模糊背板, scaledToFit 主体 }`；背板为 `scaledToFill().blur(radius: 36, opaque: true)` 叠 `Color.black.opacity(0.34)` 压暗，`opaque: true` 避免边缘羽化漏边，背板 `accessibilityHidden(true)`。
- 接入 `accessibilityReduceTransparency`：开启时背板退化为深色纯色。
- 新增 `SceneNativeImage` typealias 收敛 NSImage/UIImage 分支；图片查找逻辑原样迁至 `SceneImageLocator.url(for:)`。
- 新增 `SceneImageCache`（`@MainActor` 单例）：按 `relativePath` 缓存解码结果，用文件 `contentModificationDate` 校验失效。这一步是必要的——fit + blur 会复用同一张图，且窗口缩放时 `body` 高频重算，原实现每次都从磁盘解码会掉帧；同时生成新场景图覆盖同名文件后仍能立即刷新。

**`在场/SceneNativeRenderer.swift`**
- `BundledSceneImage` 传入 `fitMode: .fitBlurred`，`accessibilityLabel` 保持不变。
- `SceneLightingOverlay` 与 `SceneWeatherOverlay` 仍覆盖整个 stage（含留边区），保证明暗与雨效连续，不会出现中间有雨两侧没雨的断裂。

未改动：`ScenePickerSheet.swift`、`Scenes/SceneWorkshopView.swift`，仍走默认 `.fill`。

## 验证

- `xcodebuild -scheme 在场 -destination 'platform=macOS' build`：BUILD SUCCEEDED，无新增警告（仅有既存的 AppIntents metadata 提示）。
- 单元测试 `在场Tests` 全部通过（25 项，含 `sceneRenderStateTracksModel`、`packagedScenePathsAreStable`）。
  注意：直接跑 `xcodebuild test` 会因测试 target 的签名配置（team ID `7ZQ2ZLJ2S3` 无匹配 Mac Development 证书）失败，这是仓库既有的环境问题，与本次改动无关；加 `CODE_SIGNING_ALLOWED=NO` 后正常通过。
- 未做的验证：实际拖动窗口的视觉效果、`reduceTransparency` 开启后的观感，需要在真机运行时目视确认。模糊半径 36 与压暗 0.34 是初始取值，可按观感调整。
