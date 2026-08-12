#if os(macOS)
import AppKit
import SwiftUI

/// 管理桌宠浮动窗口：主窗口最小化时桌宠从原位置"掉落"到屏幕右下角，
/// 主窗口恢复时桌宠回到应用内。
@MainActor
final class FloatingDeskPetWindow {
    static let shared = FloatingDeskPetWindow()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var miniaturizeObserver: Any?
    private var deminiaturizeObserver: Any?
    private var willMiniaturizeObserver: Any?
    private weak var mainWindow: NSWindow?
    private weak var controller: DeskPetController?

    private init() {}

    // MARK: - Public

    func setup(controller: DeskPetController) {
        self.controller = controller

        // 延迟获取主窗口（onAppear 时窗口可能还没就绪）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.bindToMainWindow(controller: controller)
        }
    }

    private func bindToMainWindow(controller: DeskPetController) {
        guard let window = NSApplication.shared.windows.first(where: {
            !($0 is NSPanel) && $0.isVisible
        }) else { return }

        mainWindow = window

        willMiniaturizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willMiniaturizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.showFloatingPet(controller: controller)
        }

        deminiaturizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didDeminiaturizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.hideFloatingPet()
        }
    }

    func showFloatingPet(controller: DeskPetController) {
        guard let profile = controller.activeProfile else { return }
        guard panel == nil else { return }
        guard let screen = NSScreen.main else { return }

        // 标记为浮动状态，隐藏场景内的桌宠
        controller.isFloating = true

        let screenFrame = screen.visibleFrame

        // 桌宠在应用内的实际大小（和 DeskPetOverlay 中的计算一致）
        let petSize = petSizeFromMainWindow()

        // 起始位置：桌宠在主窗口中的屏幕坐标（右下角）
        let startPosition = petScreenPosition(petSize: petSize)

        // 最终位置：屏幕右下角
        let margin: CGFloat = 20
        let finalX = screenFrame.maxX - petSize - margin
        let finalY = screenFrame.minY + margin

        let petView = FloatingDeskPetView(profile: profile, size: petSize)

        let panel = NSPanel(
            contentRect: NSRect(x: startPosition.x, y: startPosition.y, width: petSize, height: petSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        let hosting = NSHostingView(rootView: AnyView(petView))
        hosting.frame = NSRect(x: 0, y: 0, width: petSize, height: petSize)
        panel.contentView = hosting

        self.panel = panel
        self.hostingView = hosting

        panel.orderFrontRegardless()

        // 从原位置掉落到屏幕右下角
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.7
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(
                NSRect(x: finalX, y: finalY, width: petSize, height: petSize),
                display: true
            )
        } completionHandler: {
            self.bounceAnimation(finalX: finalX, finalY: finalY, petSize: petSize)
        }
    }

    func hideFloatingPet() {
        guard let panel else { return }

        let petSize = panel.frame.width

        // 回到主窗口原位置
        let targetPosition = petScreenPosition(petSize: petSize)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(
                NSRect(x: targetPosition.x, y: targetPosition.y, width: petSize, height: petSize),
                display: true
            )
        } completionHandler: { [weak self] in
            // 动画结束后再恢复场景内桌宠并销毁浮动窗口
            self?.controller?.isFloating = false
            self?.dismissPanel()
        }
    }

    // MARK: - Private

    /// 计算桌宠在应用内的尺寸（和 DeskPetOverlay GeometryReader 逻辑一致）
    private func petSizeFromMainWindow() -> CGFloat {
        guard let window = mainWindow else { return 136 }
        let frame = window.frame
        // 场景区域大约是窗口减去侧边栏(72)和右侧面板(320)
        let sceneWidth = frame.width - 72 - 320
        let sceneHeight = frame.height
        let size = min(sceneWidth, sceneHeight) * 0.22
        return min(max(size, 80), 200)
    }

    /// 计算桌宠在主窗口中的屏幕坐标（右下角位置）
    private func petScreenPosition(petSize: CGFloat) -> NSPoint {
        guard let window = mainWindow else {
            let screen = NSScreen.main!.visibleFrame
            return NSPoint(x: screen.maxX - petSize - 22, y: screen.midY)
        }
        let windowFrame = window.frame
        // 桌宠在场景内的位置：右下角，padding trailing 22, bottom 84
        let x = windowFrame.maxX - 320 - 22 - petSize  // 减去右侧面板宽度和 padding
        let y = windowFrame.minY + 84  // bottom padding
        return NSPoint(x: x, y: y)
    }

    private func bounceAnimation(finalX: CGFloat, finalY: CGFloat, petSize: CGFloat) {
        guard let panel else { return }
        let bounceHeight: CGFloat = 12

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(
                NSRect(x: finalX, y: finalY + bounceHeight, width: petSize, height: petSize),
                display: true
            )
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.panel?.animator().setFrame(
                    NSRect(x: finalX, y: finalY, width: petSize, height: petSize),
                    display: true
                )
            }
        }
    }

    private func dismissPanel() {
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
    }

    deinit {
        if let observer = willMiniaturizeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = deminiaturizeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - Floating Pet View

private struct FloatingDeskPetView: View {
    let profile: DeskPetProfile
    let size: CGFloat

    var body: some View {
        DeskPetImage(data: profile.generatedImageData)
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
    }
}
#endif
