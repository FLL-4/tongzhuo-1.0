import Combine
import Foundation

enum PresenceMode: String, CaseIterable, Identifiable {
    case focus
    case quiet
    case rest = "break"
    case away

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: "专注中"
        case .quiet: "安静待着"
        case .rest: "休息一下"
        case .away: "离开一会"
        }
    }

    var detail: String {
        switch self {
        case .focus: "灯会一直亮着"
        case .quiet: "暂停所有提醒"
        case .rest: "给自己十分钟"
        case .away: "保留桌上的灯"
        }
    }

    var symbol: String {
        switch self {
        case .focus: "lamp.desk"
        case .quiet: "moon.stars"
        case .rest: "cup.and.saucer"
        case .away: "door.left.hand.open"
        }
    }
}

struct FocusTask: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool
}

enum PresenceSuggestionAction: Equatable {
    case beginFocus
    case openVoiceRecorder
    case openDeskRoom
    case beginRest
}

enum PresenceSuggestionContext: Equatable {
    case waitingForPartner(roomID: DeskRoom.ID)
    case timerReset
    case focusCompleted(partnerID: DeskPartner.ID?)
}

struct PresenceSuggestion: Identifiable, Equatable {
    let id: UUID
    let message: String
    let actionTitle: String
    let action: PresenceSuggestionAction
    let context: PresenceSuggestionContext

    init(
        id: UUID = UUID(),
        message: String,
        actionTitle: String,
        action: PresenceSuggestionAction,
        context: PresenceSuggestionContext
    ) {
        self.id = id
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.context = context
    }
}

enum AppSheet: String, Identifiable {
    case desk
    case voice
    case memory
    case scenes
    case sceneWorkshop
    case context

    var id: String { rawValue }
}

struct DeskPartner: Equatable, Identifiable {
    let id: UUID
    let name: String
    let character: String
    let focusSeconds: Int

    static let ahe = DeskPartner(
        id: UUID(uuidString: "A11E0000-0000-0000-0000-000000000001")!,
        name: "阿禾",
        character: "禾",
        focusSeconds: 18 * 60 + 6
    )

    var focusText: String {
        String(format: "%02d:%02d", focusSeconds / 60, focusSeconds % 60)
    }
}

struct DeskRoom: Equatable, Identifiable {
    let id: UUID
    let code: String
    let createdAt: Date
    let expiresAt: Date
    var partner: DeskPartner?

    static func preview(now: Date = Date()) -> DeskRoom {
        DeskRoom(
            id: UUID(uuidString: "DE5C0000-0000-0000-0000-000000000001")!,
            code: "YUZU-2048",
            createdAt: now.addingTimeInterval(-18 * 60),
            expiresAt: now.addingTimeInterval(30 * 60),
            partner: .ahe
        )
    }
}

enum DeskSessionState: Equatable {
    case disconnected
    case joining(code: String)
    case connected(DeskRoom)
}

@MainActor
final class AppModel: ObservableObject {
    static let maximumTaskCount = 5
    static let maximumTaskTitleLength = 30

    @Published private(set) var scenes = RoomSceneCatalog.builtIn
    @Published private(set) var selectedSceneID = RoomSceneCatalog.rainyStudy.id
    @Published var presence: PresenceMode = .focus
    @Published var weatherEffectsEnabled = true
    @Published var ambientEnabled = true
    @Published var remainingSeconds = 24 * 60 + 18
    @Published var timerRunning = true
    @Published var presenceSeconds = 42 * 60
    @Published var activeSheet: AppSheet?
    @Published var toastMessage: String?
    @Published var deskSession: DeskSessionState = .connected(.preview())
    @Published var deskErrorMessage: String?
    @Published private(set) var activeSuggestion: PresenceSuggestion?
    @Published var tasks = [
        FocusTask(title: "整理首页文案", isCompleted: true),
        FocusTask(title: "补齐方案最后两页", isCompleted: false),
        FocusTask(title: "给阿禾回一段留声", isCompleted: false),
    ]
    @Published private(set) var dailyTodoCompletedAt: Date?

    let voiceRecorder: VoiceRecorderController
    let memory: MemoryController
    let deskPet: DeskPetController
    let sceneGenerator: any SceneGenerating

    private let ambientAudio: AmbientAudioControlling
    private var audioActivated = false
    private var timerTask: Task<Void, Never>?
    private var timerEndDate: Date?
    private var toastTask: Task<Void, Never>?
    private var deskJoinTask: Task<Void, Never>?

    init(
        ambientAudio: AmbientAudioControlling? = nil,
        sceneGenerator: (any SceneGenerating)? = nil,
        deskPetGenerator: (any DeskPetGenerating)? = nil
    ) {
        let audio = ambientAudio ?? AmbientAudioEngine()
        self.ambientAudio = audio
        self.sceneGenerator = sceneGenerator ?? HybridSceneGenerator()
        deskPet = DeskPetController(generator: deskPetGenerator ?? HybridDeskPetGenerator())
        voiceRecorder = VoiceRecorderController(ambientAudio: audio)
        memory = MemoryController()
        timerEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.tick()
            }
        }
    }

    deinit {
        timerTask?.cancel()
        toastTask?.cancel()
        deskJoinTask?.cancel()
    }

    var timerText: String { Self.formatDuration(remainingSeconds) }
    var presenceText: String { "\(presenceSeconds / 60) 分钟" }
    var completedTaskCount: Int { tasks.filter(\.isCompleted).count }
    var canAddTask: Bool { tasks.count < Self.maximumTaskCount }

    var currentDeskRoom: DeskRoom? {
        guard case let .connected(room) = deskSession else { return nil }
        return room
    }

    var currentDeskPartner: DeskPartner? { currentDeskRoom?.partner }
    var deskActionTitle: String { currentDeskRoom == nil ? "加入同桌" : "邀请同桌" }
    var selectedScene: RoomScene {
        scenes.first(where: { $0.id == selectedSceneID }) ?? RoomSceneCatalog.rainyStudy
    }

    var selectedSceneImage: SceneImageAsset {
        selectedScene.image
    }

    func selectScene(_ scene: RoomScene) {
        guard scenes.contains(where: { $0.id == scene.id }) else { return }
        selectedSceneID = scene.id
        if audioActivated {
            ambientAudio.setPreset(scene.ambientPreset)
        }
        showToast("已换到\(scene.name)")
    }

    func saveGeneratedScene(_ scene: RoomScene) {
        guard scene.origin == .generated else { return }
        scenes.removeAll { $0.id == scene.id }
        scenes.append(scene)
        selectedSceneID = scene.id
        if audioActivated {
            ambientAudio.setPreset(scene.ambientPreset)
        }
        showToast("\(scene.name)已经点亮")
    }

    func activateAudio() {
        guard !audioActivated else { return }
        audioActivated = true
        ambientAudio.start(preset: selectedScene.ambientPreset, enabled: ambientEnabled)
    }

    func deactivateAudio() {
        guard audioActivated else { return }
        audioActivated = false
        ambientAudio.stop()
    }

    func enterMobileBackground() {
        if voiceRecorder.isRecording {
            voiceRecorder.finishRecording()
        } else {
            voiceRecorder.stopPlayback()
        }
        deactivateAudio()
    }

    func setPresence(_ mode: PresenceMode) {
        presence = mode
        if mode == .focus {
            resumeTimer()
        } else {
            pauseTimer()
        }
        showToast("状态已切换为“\(mode.title)”")
    }

    func toggleTimer() {
        timerRunning ? pauseTimer() : resumeTimer()
        showToast(timerRunning ? "继续这一段" : "计时已暂停")
    }

    func resetTimer() {
        remainingSeconds = 25 * 60
        timerRunning = false
        timerEndDate = nil
        activeSuggestion = PresenceSuggestion(
            message: "计时器已经准备好，要从一段完整的 25 分钟重新开始吗？",
            actionTitle: "开始这一段",
            action: .beginFocus,
            context: .timerReset
        )
    }

    func beginFocusSession() {
        presence = .focus
        remainingSeconds = 25 * 60
        timerRunning = true
        timerEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        activeSuggestion = nil
        showToast("台灯已亮起，25 分钟从现在开始")
    }

    func toggleWeather() {
        weatherEffectsEnabled.toggle()
        showToast(weatherEffectsEnabled ? "窗外天气已打开" : "窗外天气已关闭")
    }

    func toggleAmbient() {
        ambientEnabled.toggle()
        if audioActivated {
            ambientAudio.setEnabled(ambientEnabled)
        }
        let soundName = selectedScene.ambientPreset.displayName
        showToast(ambientEnabled ? "\(soundName)已打开" : "\(soundName)已关闭")
    }

    func toggleTask(_ taskID: FocusTask.ID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].isCompleted.toggle()
        if tasks[index].isCompleted {
            showToast("这件事已经收好了")
            if !tasks.isEmpty, tasks.allSatisfy(\.isCompleted), dailyTodoCompletedAt == nil {
                dailyTodoCompletedAt = Date()
                activeSheet = .memory
                showToast("今天的事都完成了，打开今日留声机")
            }
        } else {
            dailyTodoCompletedAt = nil
        }
    }

    @discardableResult
    func addTask(title rawTitle: String) -> Bool {
        guard canAddTask else {
            showToast("桌上最多放 \(Self.maximumTaskCount) 件事")
            return false
        }
        let title = normalizedTaskTitle(rawTitle)
        guard !title.isEmpty else { return false }
        guard !containsTask(named: title) else {
            showToast("这件事已经在桌上了")
            return false
        }

        tasks.append(FocusTask(title: title, isCompleted: false))
        showToast("已经放到桌上")
        return true
    }

    @discardableResult
    func renameTask(_ taskID: FocusTask.ID, title rawTitle: String) -> Bool {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return false }
        let title = normalizedTaskTitle(rawTitle)
        guard !title.isEmpty else { return false }
        guard !containsTask(named: title, excluding: taskID) else {
            showToast("这件事已经在桌上了")
            return false
        }

        tasks[index].title = title
        return true
    }

    func deleteTask(_ taskID: FocusTask.ID) {
        tasks.removeAll { $0.id == taskID }
    }

    func formatDeskCode(_ value: String) -> String {
        let characters = value.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(8)
        let compact = String(characters)
        guard compact.count > 4 else { return compact }
        let split = compact.index(compact.startIndex, offsetBy: 4)
        return "\(compact[..<split])-\(compact[split...])"
    }

    func isValidDeskCode(_ value: String) -> Bool {
        formatDeskCode(value).filter { $0 != "-" }.count == 8
    }

    func joinDesk(code rawCode: String) {
        let code = formatDeskCode(rawCode)
        guard isValidDeskCode(code) else {
            deskErrorMessage = "请输入完整的 8 位同桌码。"
            return
        }

        deskJoinTask?.cancel()
        deskErrorMessage = nil
        deskSession = .joining(code: code)
        clearDeskDependentSuggestion()
        deskJoinTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled, let self else { return }
            let now = Date()
            deskSession = .connected(
                DeskRoom(
                    id: UUID(),
                    code: code,
                    createdAt: now,
                    expiresAt: now.addingTimeInterval(30 * 60),
                    partner: .ahe
                )
            )
            clearDeskDependentSuggestion()
            showToast("已经和阿禾坐到一起")
        }
    }

    func createDeskRoom() {
        deskJoinTask?.cancel()
        deskErrorMessage = nil
        let compact = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8))
        let code = formatDeskCode(compact)
        let now = Date()
        let room = DeskRoom(
            id: UUID(),
            code: code,
            createdAt: now,
            expiresAt: now.addingTimeInterval(30 * 60),
            partner: nil
        )
        deskSession = .connected(room)
        activeSuggestion = PresenceSuggestion(
            message: "房间已经点亮。等待同桌的时候，可以先开始一小段自己的专注。",
            actionTitle: "开始 25 分钟",
            action: .beginFocus,
            context: .waitingForPartner(roomID: room.id)
        )
    }

    func updateDeskPartner(_ partner: DeskPartner?) {
        guard case var .connected(room) = deskSession else { return }
        room.partner = partner
        deskSession = .connected(room)
        if partner != nil {
            clearDeskDependentSuggestion()
        } else {
            deskPet.clear()
        }
    }

    func cancelDeskJoin() {
        deskJoinTask?.cancel()
        deskSession = .disconnected
        deskErrorMessage = nil
        clearDeskDependentSuggestion()
    }

    func copyDeskCode() {
        guard let code = currentDeskRoom?.code else { return }
        ClipboardClient.writeText(code)
        showToast("同桌码 \(code) 已复制")
    }

    func leaveDesk() {
        deskJoinTask?.cancel()
        deskSession = .disconnected
        deskPet.clear()
        deskErrorMessage = nil
        clearDeskDependentSuggestion()
        showToast("已经离开同桌房间")
    }

    func performSuggestion(_ suggestionID: PresenceSuggestion.ID) {
        guard let suggestion = activeSuggestion, suggestion.id == suggestionID else { return }
        activeSuggestion = nil

        switch suggestion.action {
        case .beginFocus:
            beginFocusSession()
        case .openVoiceRecorder:
            activeSheet = .voice
        case .openDeskRoom:
            activeSheet = .desk
        case .beginRest:
            setPresence(.rest)
        }
    }

    func dismissSuggestion(_ suggestionID: PresenceSuggestion.ID) {
        guard activeSuggestion?.id == suggestionID else { return }
        activeSuggestion = nil
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.toastMessage = nil }
        }
    }

    private func resumeTimer() {
        guard remainingSeconds > 0 else { return }
        timerRunning = true
        timerEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        activeSuggestion = nil
    }

    private func pauseTimer() {
        updateRemainingTime()
        timerRunning = false
        timerEndDate = nil
    }

    private func tick() {
        guard timerRunning else { return }
        presenceSeconds += 1
        updateRemainingTime()
        if remainingSeconds == 0 {
            completeFocusSession()
        }
    }

    func completeFocusSession() {
        remainingSeconds = 0
        timerRunning = false
        timerEndDate = nil

        if let partner = currentDeskPartner {
            activeSuggestion = PresenceSuggestion(
                message: "这一段已经完成。要给\(partner.name)留一句话吗？",
                actionTitle: "打开留声机",
                action: .openVoiceRecorder,
                context: .focusCompleted(partnerID: partner.id)
            )
        } else {
            activeSuggestion = PresenceSuggestion(
                message: "这一段已经完成，先休息一会儿。",
                actionTitle: "休息一下",
                action: .beginRest,
                context: .focusCompleted(partnerID: nil)
            )
        }
    }

    private func clearDeskDependentSuggestion() {
        guard let suggestion = activeSuggestion else { return }
        switch suggestion.context {
        case .waitingForPartner, .focusCompleted(partnerID: .some(_)):
            activeSuggestion = nil
        case .timerReset, .focusCompleted(partnerID: nil):
            break
        }
    }

    private func updateRemainingTime() {
        guard let timerEndDate else { return }
        remainingSeconds = max(0, Int(ceil(timerEndDate.timeIntervalSinceNow)))
    }

    private func normalizedTaskTitle(_ rawTitle: String) -> String {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(Self.maximumTaskTitleLength))
    }

    private func containsTask(named title: String, excluding taskID: FocusTask.ID? = nil) -> Bool {
        tasks.contains {
            $0.id != taskID && $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame
        }
    }

    private static func formatDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
