import SwiftUI

struct SceneRenderState: Equatable {
    let sceneID: RoomScene.ID
    let imagePath: String
    let weatherEffect: SceneWeatherEffect
    let weatherEffectsEnabled: Bool
    let presence: PresenceMode

    init(model: AppModel) {
        sceneID = model.selectedScene.id
        imagePath = model.selectedSceneImage.relativePath
        weatherEffect = model.selectedScene.weatherEffect
        weatherEffectsEnabled = model.weatherEffectsEnabled
        presence = model.presence
    }
}

struct SceneNativeRenderer: View {
    let model: AppModel
    let layout: SceneStageLayout

    var body: some View {
        ZStack {
            BundledSceneImage(relativePath: model.selectedSceneImage.relativePath)
                .accessibilityLabel(model.selectedSceneImage.accessibilityDescription)
            SceneLightingOverlay(presence: model.presence)
            SceneWeatherOverlay(
                effect: model.selectedScene.weatherEffect,
                isEnabled: model.weatherEffectsEnabled
            )
        }
        .clipped()
    }
}

private struct SceneLightingOverlay: View {
    let presence: PresenceMode

    var body: some View {
        Color.black
            .opacity(opacity)
            .blendMode(.multiply)
            .allowsHitTesting(false)
    }

    private var opacity: Double {
        switch presence {
        case .focus: 0.05
        case .quiet: 0.18
        case .rest: 0.0
        case .away: 0.28
        }
    }
}

struct SceneWeatherOverlay: View {
    let effect: SceneWeatherEffect
    let isEnabled: Bool

    var body: some View {
        if isEnabled, effect == .rain {
            RainOverlay()
        }
    }
}

private struct RainOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let drops = RainDrop.all

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                for drop in drops {
                    let progress = (elapsed * drop.speed + drop.phase).truncatingRemainder(dividingBy: 1)
                    let x = (drop.x + progress * 0.09).truncatingRemainder(dividingBy: 1.1) * size.width
                    let y = ((progress * 1.18 + drop.y).truncatingRemainder(dividingBy: 1.2) - 0.1) * size.height
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + drop.slant, y: y + drop.length))
                    context.stroke(path, with: .color(.white.opacity(drop.opacity)), lineWidth: drop.width)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct RainDrop {
    let x: Double
    let y: Double
    let phase: Double
    let speed: Double
    let length: Double
    let slant: Double
    let opacity: Double
    let width: Double

    static let all: [RainDrop] = (0..<70).map { index in
        let seed = Double(index + 1)
        return RainDrop(
            x: (seed * 0.6180339887).truncatingRemainder(dividingBy: 1),
            y: (seed * 0.3819660113).truncatingRemainder(dividingBy: 1),
            phase: (seed * 0.2718).truncatingRemainder(dividingBy: 1),
            speed: 0.65 + (seed.truncatingRemainder(dividingBy: 7) * 0.07),
            length: 8 + (seed.truncatingRemainder(dividingBy: 5) * 2),
            slant: 2.5,
            opacity: 0.20 + (seed.truncatingRemainder(dividingBy: 6) * 0.055),
            width: 0.7
        )
    }
}
