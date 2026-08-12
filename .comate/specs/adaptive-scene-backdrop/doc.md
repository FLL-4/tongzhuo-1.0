# 场景背景图自适应窗口（adaptive-scene-backdrop）

## 1. 需求场景与处理逻辑

**现状**：主场景舞台的背景图使用 `scaledToFill()`，图片按较长边填满窗口，超出部分被 `clipped()` 裁掉。窗口被拖成宽扁或窄高比例时，画面会被裁掉大量内容（比如书桌、窗户被切走），无法完整展示场景。

**目标**：窗口任意尺寸/比例下，完整的场景背景图都能自适应展示（不裁切），窗口比例与图片比例不一致时，多出来的区域用同一张图放大模糊铺底，避免黑边割裂感。

**已确认的两个决策**：
- 留边处理：同图放大模糊铺底（`fill` + blur 作为背板，`fit` 作为主体）。
- 生效范围：只有主场景舞台（`SceneNativeRenderer` → `SceneStageView`）改为 fit；场景选择器缩略图 `ScenePickerSheet.swift:30`、生成结果预览 `SceneWorkshopView.swift:163` 保持原有 fill 行为。

## 2. 架构与技术方案

`BundledSceneImage` 是唯一的场景图渲染入口（`在场/Platform/BundledSceneImage.swift:8`），三处调用共用。为满足"只改主舞台"，给它增加一个显示模式参数，默认值保持 `.fill`，从而现有两个调用点零改动。

```
SceneStageView
  └── SceneNativeRenderer                       // 传入 .fitBlurred
        └── BundledSceneImage(fitMode:)
              ├── 背板: Image.scaledToFill().blur()   （超出裁掉）
              └── 主体: Image.scaledToFit()           （完整可见）
```

新增 `SceneImageFitMode` 枚举：
- `.fill`：现有行为，铺满裁切。
- `.fitBlurred`：完整展示 + 模糊铺底。

同时做一处必要的重构：当前实现每次 `body` 求值都会 `NSImage(contentsOf:)` 从磁盘解码一次。改成 fit+blur 后同一张图会被用两次，且拖动窗口时 `body` 会高频重算，磁盘解码 + 大图模糊会明显掉帧。因此把加载逻辑抽出并加一层轻量内存缓存（按 `relativePath` + 文件修改时间做 key，保证生成新图/覆盖同名文件后能失效）。

## 3. 影响的文件

| 文件 | 修改类型 | 影响范围 |
| --- | --- | --- |
| `/Users/zouya/Desktop/ZaiChang/在场/Platform/BundledSceneImage.swift` | 修改 | 新增 `SceneImageFitMode`；`BundledSceneImage` 增加 `fitMode` 参数（默认 `.fill`）；抽出 `resolvedImage` 与 `SceneImageCache` |
| `/Users/zouya/Desktop/ZaiChang/在场/SceneNativeRenderer.swift` | 修改 | `SceneNativeRenderer.body` 中的 `BundledSceneImage` 传入 `fitMode: .fitBlurred` |
| `/Users/zouya/Desktop/ZaiChang/在场/ScenePickerSheet.swift` | 不修改 | 依赖默认参数保持 fill |
| `/Users/zouya/Desktop/ZaiChang/在场/Scenes/SceneWorkshopView.swift` | 不修改 | 同上 |

## 4. 实现细节

### 4.1 显示模式与跨平台图片加载

```swift
enum SceneImageFitMode {
    case fill        // 铺满窗口，裁掉溢出（缩略图/预览）
    case fitBlurred  // 完整展示，留边处用同图模糊铺底（主舞台）
}
```

平台图片类型用 typealias 收敛，避免在视图里重复 `#if`：

```swift
#if os(macOS)
private typealias SceneNativeImage = NSImage
#elseif os(iOS) || os(visionOS)
private typealias SceneNativeImage = UIImage
#endif
```

`imageURL` 的查找逻辑（用户生成图 → Bundle 根 → Bundle 子目录 → Bundle 兜底）完全保留，不做改动。

### 4.2 视图组合

```swift
struct BundledSceneImage: View {
    let relativePath: String
    var fitMode: SceneImageFitMode = .fill

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if let image = SceneImageCache.shared.image(for: relativePath) {
            switch fitMode {
            case .fill:
                sceneImage(image)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            case .fitBlurred:
                ZStack {
                    backdrop(image)
                    sceneImage(image)
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        } else {
            fallback
        }
    }

    @ViewBuilder
    private func backdrop(_ image: SceneNativeImage) -> some View {
        if reduceTransparency {
            Color(red: 0.07, green: 0.08, blue: 0.11)
        } else {
            sceneImage(image)
                .scaledToFill()
                .blur(radius: 36, opaque: true)
                .overlay(Color.black.opacity(0.34))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
        }
    }
}
```

要点：
- `blur(radius:opaque:)` 的 `opaque: true` 避免边缘出现透明羽化导致的漏边。
- 背板 `accessibilityHidden(true)`，`accessibilityLabel` 仍由外层 `SceneNativeRenderer` 提供，读屏内容不变。
- `reduceTransparency` 打开时退化为深色纯色板，兼顾无障碍与性能。

### 4.3 图片缓存

```swift
final class SceneImageCache {
    static let shared = SceneImageCache()
    private var cache: [String: (stamp: Date, image: SceneNativeImage)] = [:]

    @MainActor func image(for relativePath: String) -> SceneNativeImage? { ... }
}
```

- key 为 `relativePath`，附带文件 `contentModificationDate` 做校验；时间戳变化则重新解码。
- 只在主线程访问（SwiftUI `body` 均在主线程），无需加锁。
- 缓存上限：场景数量有限（内置 3 张 + 用户生成），不做淘汰策略；若后续图片数量增长再引入 `NSCache`。

### 4.4 覆盖层的处理

`SceneLightingOverlay`（`SceneNativeRenderer.swift:38`）与 `SceneWeatherOverlay`（雨滴 Canvas）保持覆盖整个 stage 区域，即也覆盖模糊留边区。这样留边区与主体区的明暗、天气表现一致，视觉上是一整块窗景，不会出现"中间有雨、两侧没雨"的断裂。

## 5. 边界条件与异常处理

| 情况 | 行为 |
| --- | --- |
| 图片文件缺失/解码失败 | 走原有 `fallback`（深色底 + photo 图标），不崩溃 |
| 窗口比例恰好等于图片比例 | fit 结果铺满，模糊背板被完全遮住，视觉与改动前一致 |
| 窗口极窄/极扁 | 主体图缩小居中，两侧或上下为模糊铺底，场景内容始终完整 |
| 窗口尺寸极小（compact 布局） | 逻辑同上，`layout` 不参与判断，避免新增分支 |
| 用户重新生成同名场景图 | 缓存按修改时间失效，立即显示新图 |
| `reduceTransparency` 开启 | 背板改为深色纯色 |
| `reduceMotion` | 与本次改动无关，雨效已有处理 |

## 6. 数据流

```
AppModel.selectedSceneImage.relativePath
   → SceneNativeRenderer(fitMode: .fitBlurred)
   → BundledSceneImage
   → SceneImageCache.image(for:)  ──miss──> SceneAssetStore / Bundle 查找 → 解码 → 缓存
   → ZStack{ blurred fill 背板, fit 主体 }
   → SceneLightingOverlay / SceneWeatherOverlay 覆盖全区
```

## 7. 预期结果

- 拖动窗口到任意尺寸与比例，场景背景图始终完整可见，不再被裁切。
- 比例不匹配时留边区为同图模糊放大，观感连续，没有黑边或空白。
- 场景选择器缩略图、生成结果预览的表现与改动前完全一致。
- 拖动窗口时不再有反复磁盘解码，缩放过程流畅。
- 开启"降低透明度"辅助功能时，留边区为深色纯色。
