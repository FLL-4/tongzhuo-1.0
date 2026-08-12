# 场景背景图自适应窗口 —— 任务计划

- [✓] Task 1: 抽出场景图加载与内存缓存
    - 1.1: 在 `Platform/BundledSceneImage.swift` 增加 `SceneNativeImage` typealias（macOS→NSImage，iOS/visionOS→UIImage），收敛平台分支
    - 1.2: 将 `imageURL` 的查找逻辑（用户生成图 → Bundle 根 → Bundle 子目录 → Bundle 兜底）原样迁出为可复用的解析方法
    - 1.3: 新增 `SceneImageCache`（单例，`[relativePath: (stamp, image)]`，按 `contentModificationDate` 校验失效），提供 `image(for:) -> SceneNativeImage?`
    - 1.4: 改造 `BundledSceneImage.body` 走缓存取图，保持现有 `.scaledToFill()` 表现与 `fallback` 分支不变
    - 1.5: 编译验证，确认缩略图与预览渲染无回归

- [ ] Task 2: 新增显示模式并实现 fit + 模糊铺底
    - 2.1: 定义 `enum SceneImageFitMode { case fill, fitBlurred }`
    - 2.2: `BundledSceneImage` 增加 `var fitMode: SceneImageFitMode = .fill`，默认值保证既有两个调用点零改动
    - 2.3: 实现 `.fitBlurred` 分支：ZStack 内为 `scaledToFill().blur(radius: 36, opaque: true)` 背板 + `Color.black.opacity(0.34)` 压暗层 + `scaledToFit()` 主体，整体 `clipped()`
    - 2.4: 背板加 `accessibilityHidden(true)`，避免重复朗读
    - 2.5: 接入 `@Environment(\.accessibilityReduceTransparency)`，开启时背板退化为深色纯色

- [ ] Task 3: 主舞台接入自适应模式
    - 3.1: `SceneNativeRenderer.body` 中的 `BundledSceneImage` 传入 `fitMode: .fitBlurred`
    - 3.2: 确认 `accessibilityLabel` 仍作用于场景图，读屏描述不变
    - 3.3: 确认 `SceneLightingOverlay` 与 `SceneWeatherOverlay` 仍覆盖包含留边区的整个 stage
    - 3.4: 确认 `ScenePickerSheet.swift` 与 `SceneWorkshopView.swift` 未被改动、仍为 fill

- [ ] Task 4: 验证与收尾
    - 4.1: 执行项目构建（xcodebuild）确保无编译错误与新增警告
    - 4.2: 检查已有测试 `在场Tests/__Tests.swift` 是否受影响，必要时补充 `SceneImageFitMode` 默认值的断言
    - 4.3: 核对边界场景：图片缺失走 fallback、窗口极窄/极扁、比例恰好匹配、重新生成同名场景图后刷新
    - 4.4: 生成 `summary.md`
