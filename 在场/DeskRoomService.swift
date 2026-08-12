import Foundation

enum DeskRoomServiceError: Error, Equatable {
    case emptyInviteCode
}

protocol DeskRoomServicing {
    func createRoom() async throws -> DeskRoom
    func joinRoom(inviteCode: String) async throws -> DeskRoom
}

struct MockDeskRoomService: DeskRoomServicing {
    private let roomID = UUID(uuidString: "DE5C0000-0000-0000-0000-000000000001")!

    func createRoom() async throws -> DeskRoom {
        room(code: "DEMO-ROOM")
    }

    func joinRoom(inviteCode: String) async throws -> DeskRoom {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { throw DeskRoomServiceError.emptyInviteCode }
        return room(code: code)
    }

    private func room(code: String) -> DeskRoom {
        let now = Date()
        return DeskRoom(
            id: roomID,
            code: code,
            createdAt: now,
            expiresAt: now.addingTimeInterval(30 * 60),
            partner: .ahe
        )
    }
}
