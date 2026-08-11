import SwiftUI
import WebKit

struct SceneRenderState: Equatable {
    let sceneID: RoomScene.ID
    let imagePath: String
    let imageAlt: String
    let weatherEffect: SceneWeatherEffect
    let atmosphericEffect: SceneAtmosphericEffect
    let steamAnchors: [SteamAnchor]
    let weatherEffectsEnabled: Bool
    let presence: String

    init(model: AppModel) {
        let scene = model.selectedScene
        let image = model.selectedSceneImage
        sceneID = scene.id
        imagePath = image.webPath
        imageAlt = image.accessibilityDescription
        weatherEffect = scene.weatherEffect
        atmosphericEffect = scene.atmosphericEffect
        steamAnchors = image.steamAnchors
        weatherEffectsEnabled = model.weatherEffectsEnabled
        presence = model.presence.rawValue
    }

    var payload: [String: Any] {
        [
            "sceneID": sceneID,
            "imagePath": imagePath,
            "imageAlt": imageAlt,
            "weatherEffect": weatherEffect.rawValue,
            "atmosphericEffect": atmosphericEffect.rawValue,
            "steamAnchors": steamAnchors.map {
                [
                    "xPercent": $0.xPercent,
                    "yPercent": $0.yPercent,
                    "particleCount": $0.particleCount,
                    "opacity": $0.opacity,
                ] as [String: Any]
            },
            "weatherEffectsEnabled": weatherEffectsEnabled,
            "presence": presence,
        ]
    }
}

private struct SceneWebResource {
    let indexURL: URL
    let readAccessURL: URL

    static func locate(in bundle: Bundle = .main) -> SceneWebResource? {
        if let indexURL = bundle.url(
            forResource: "scene",
            withExtension: "html",
            subdirectory: "WebApp"
        ) {
            return SceneWebResource(
                indexURL: indexURL,
                readAccessURL: indexURL.deletingLastPathComponent()
            )
        }

        if let indexURL = bundle.url(forResource: "scene", withExtension: "html") {
            return SceneWebResource(
                indexURL: indexURL,
                readAccessURL: bundle.resourceURL ?? indexURL.deletingLastPathComponent()
            )
        }

        return nil
    }
}

final class SceneWebCoordinator: NSObject, WKNavigationDelegate {
    var state: SceneRenderState
    var isLoaded = false
    var lastAppliedState: SceneRenderState?

    init(state: SceneRenderState) {
        self.state = state
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
        applyState(to: webView, force: true)
    }

    func applyState(to webView: WKWebView, force: Bool = false) {
        guard isLoaded, force || lastAppliedState != state else { return }
        guard
            JSONSerialization.isValidJSONObject(state.payload),
            let data = try? JSONSerialization.data(withJSONObject: state.payload),
            let json = String(data: data, encoding: .utf8)
        else { return }

        webView.evaluateJavaScript("window.ZaichangScene?.render(\(json));")
        lastAppliedState = state
    }
}

#if os(macOS)
struct SceneWebView: NSViewRepresentable {
    let state: SceneRenderState

    func makeCoordinator() -> SceneWebCoordinator {
        SceneWebCoordinator(state: state)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false

        if let resource = SceneWebResource.locate() {
            webView.loadFileURL(resource.indexURL, allowingReadAccessTo: resource.readAccessURL)
        } else {
            webView.loadHTMLString(
                "<body style='margin:0;background:#0e1827;color:#aaa;font:13px system-ui;display:grid;place-items:center;height:100vh'>场景资源暂时不可用</body>",
                baseURL: nil
            )
        }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.state = state
        context.coordinator.applyState(to: webView)
    }
}
#else
struct SceneWebView: UIViewRepresentable {
    let state: SceneRenderState

    func makeCoordinator() -> SceneWebCoordinator {
        SceneWebCoordinator(state: state)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        if let resource = SceneWebResource.locate() {
            webView.loadFileURL(resource.indexURL, allowingReadAccessTo: resource.readAccessURL)
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.state = state
        context.coordinator.applyState(to: webView)
    }
}
#endif
