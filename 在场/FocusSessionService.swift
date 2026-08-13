import Foundation

struct FocusSessionConfiguration: Equatable {
    static let allowedDurations = [15, 25, 45, 60]

    let durationMinutes: Int
    let taskIDs: [FocusTask.ID]
    let customTaskTitle: String?

    init(durationMinutes: Int, taskID: FocusTask.ID) {
        self.init(durationMinutes: durationMinutes, taskIDs: [taskID])
    }

    init(
        durationMinutes: Int,
        taskIDs: [FocusTask.ID] = [],
        customTaskTitle: String? = nil
    ) {
        self.durationMinutes = durationMinutes
        self.taskIDs = taskIDs
        self.customTaskTitle = customTaskTitle
    }

    var taskID: FocusTask.ID? { taskIDs.first }
}

struct FocusSession: Equatable, Identifiable {
    let id: UUID
    let roomID: DeskRoom.ID?
    let taskIDs: [FocusTask.ID]
    let customTaskTitle: String?
    let durationSeconds: Int
    let startedAt: Date

    init(
        id: UUID,
        roomID: DeskRoom.ID?,
        taskIDs: [FocusTask.ID],
        customTaskTitle: String?,
        durationSeconds: Int,
        startedAt: Date
    ) {
        self.id = id
        self.roomID = roomID
        self.taskIDs = taskIDs
        self.customTaskTitle = customTaskTitle
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
    }

    var taskID: FocusTask.ID? { taskIDs.first }
}

enum ActivityEndReason: Equatable {
    case timerCompleted
    case manuallyEnded
}

struct ActivityEndedEvent: Equatable, Identifiable {
    let id: UUID
    let sessionID: FocusSession.ID
    let reason: ActivityEndReason
    let endedAt: Date
}

enum FocusSessionServiceError: Error, Equatable {
    case invalidDuration
}

protocol FocusSessionServicing {
    func startSession(
        roomID: DeskRoom.ID?,
        configuration: FocusSessionConfiguration
    ) throws -> FocusSession

    func endSession(_ session: FocusSession, reason: ActivityEndReason) -> ActivityEndedEvent
}

struct MockFocusSessionService: FocusSessionServicing {
    func startSession(
        roomID: DeskRoom.ID?,
        configuration: FocusSessionConfiguration
    ) throws -> FocusSession {
        guard FocusSessionConfiguration.allowedDurations.contains(configuration.durationMinutes) else {
            throw FocusSessionServiceError.invalidDuration
        }

        return FocusSession(
            id: UUID(),
            roomID: roomID,
            taskIDs: configuration.taskIDs,
            customTaskTitle: configuration.customTaskTitle,
            durationSeconds: configuration.durationMinutes * 60,
            startedAt: Date()
        )
    }

    func endSession(_ session: FocusSession, reason: ActivityEndReason) -> ActivityEndedEvent {
        ActivityEndedEvent(
            id: UUID(),
            sessionID: session.id,
            reason: reason,
            endedAt: Date()
        )
    }
}
