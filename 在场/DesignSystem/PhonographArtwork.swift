import SwiftUI

struct PhonographArtwork: View {
    enum Variant {
        case recorder(isRecording: Bool)
        case cardPlaceholder
    }

    let variant: Variant

    init(variant: Variant) {
        self.variant = variant
    }

    private var isRecording: Bool {
        if case let .recorder(isRecording) = variant {
            return isRecording
        }
        return false
    }

    private var showsSurface: Bool {
        if case .recorder = variant { return true }
        return false
    }

    private var showsRecordingBadge: Bool {
        if case let .recorder(isRecording) = variant {
            return isRecording
        }
        return false
    }

    private let shell = Color(red: 0.19, green: 0.17, blue: 0.16)
    private let shellLift = Color(red: 0.29, green: 0.24, blue: 0.20)
    private let warmEdge = Color(red: 0.98, green: 0.76, blue: 0.42)
    private let warmSoft = Color(red: 1.00, green: 0.88, blue: 0.62)
    private let wood = Color(red: 0.35, green: 0.24, blue: 0.16)
    private let woodDark = Color(red: 0.18, green: 0.13, blue: 0.10)

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if showsSurface {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Palette.surface3.opacity(0.42))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                }

                gramophone(in: size)
                musicNotes(in: size)

                if showsRecordingBadge {
                    recordingIndicator(in: size)
                }
            }
        }
    }

    @ViewBuilder
    private func gramophone(in size: CGSize) -> some View {
        let width = size.width
        let height = size.height

        GramophonePipeShape()
            .stroke(
                LinearGradient(
                    colors: [woodDark, shellLift, warmEdge.opacity(0.55)],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ),
                style: StrokeStyle(lineWidth: 13, lineCap: .round, lineJoin: .round)
            )
            .frame(width: width, height: height)

        GramophonePipeShape()
            .stroke(
                Color.black.opacity(0.28),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: width, height: height)

        HornBellShape()
            .fill(
                LinearGradient(
                    colors: [
                        shell,
                        Color(red: 0.25, green: 0.21, blue: 0.19),
                        Color(red: 0.13, green: 0.13, blue: 0.15)
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            )
            .frame(width: width * 0.56, height: height * 0.62)
            .position(x: width * 0.62, y: height * 0.36)
            .shadow(color: Color.black.opacity(0.22), radius: 8, x: 0, y: 7)

        HornBellShape()
            .stroke(warmEdge.opacity(0.46), lineWidth: 1.4)
            .frame(width: width * 0.56, height: height * 0.62)
            .position(x: width * 0.62, y: height * 0.36)

        HornRibsShape()
            .stroke(
                warmSoft.opacity(0.32),
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
            )
            .frame(width: width * 0.56, height: height * 0.62)
            .position(x: width * 0.62, y: height * 0.36)

        TurntableBase()
            .fill(
                LinearGradient(
                    colors: [woodDark, wood, Color(red: 0.27, green: 0.18, blue: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width * 0.68, height: height * 0.27)
            .position(x: width * 0.50, y: height * 0.77)
            .shadow(color: Color.black.opacity(0.20), radius: 5, x: 0, y: 4)

        TurntableBase()
            .stroke(warmEdge.opacity(0.35), lineWidth: 1)
            .frame(width: width * 0.68, height: height * 0.27)
            .position(x: width * 0.50, y: height * 0.77)

        turntableDisc(in: size)

        Capsule()
            .fill(Color.black.opacity(0.35))
            .frame(width: width * 0.70, height: 5)
            .position(x: width * 0.50, y: height * 0.94)
    }

    @ViewBuilder
    private func turntableDisc(in size: CGSize) -> some View {
        let width = size.width
        let height = size.height

        Ellipse()
            .fill(Color(red: 0.10, green: 0.10, blue: 0.11))
            .frame(width: width * 0.30, height: height * 0.088)
            .position(x: width * 0.47, y: height * 0.70)

        Ellipse()
            .stroke(warmSoft.opacity(0.54), lineWidth: 1.2)
            .frame(width: width * 0.24, height: height * 0.066)
            .position(x: width * 0.47, y: height * 0.70)

        Ellipse()
            .stroke(warmSoft.opacity(0.28), lineWidth: 1)
            .frame(width: width * 0.17, height: height * 0.047)
            .position(x: width * 0.47, y: height * 0.70)

        Circle()
            .fill(warmEdge)
            .frame(width: 8, height: 8)
            .position(x: width * 0.47, y: height * 0.70)

        GramophoneNeedleShape()
            .stroke(
                Color(red: 0.72, green: 0.66, blue: 0.57),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            .frame(width: width, height: height)

        Circle()
            .fill(shellLift)
            .frame(width: 8, height: 8)
            .position(x: width * 0.38, y: height * 0.66)
    }

    @ViewBuilder
    private func musicNotes(in size: CGSize) -> some View {
        let noteColor = isRecording ? warmSoft : Palette.muted.opacity(0.58)
        let liftedOpacity = isRecording ? 0.95 : 0.58

        Group {
            musicNote("♪", size: 18, rotation: -12, position: CGPoint(x: size.width * 0.20, y: size.height * 0.23))
            musicNote("♫", size: 16, rotation: 10, position: CGPoint(x: size.width * 0.35, y: size.height * 0.16))
            musicNote("♪", size: 13, rotation: 8, position: CGPoint(x: size.width * 0.78, y: size.height * 0.15))
            musicNote("♬", size: 15, rotation: -8, position: CGPoint(x: size.width * 0.84, y: size.height * 0.31))
        }
        .foregroundStyle(noteColor)
        .opacity(liftedOpacity)
    }

    private func musicNote(
        _ text: String,
        size: CGFloat,
        rotation: Double,
        position: CGPoint
    ) -> some View {
        Text(text)
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .rotationEffect(.degrees(rotation))
            .position(position)
            .shadow(color: Color.black.opacity(0.18), radius: 1, x: 0, y: 1)
    }

    @ViewBuilder
    private func recordingIndicator(in size: CGSize) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color(red: 0.91, green: 0.42, blue: 0.35))
                .frame(width: 7, height: 7)
            Text("录音中")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Palette.ink.opacity(0.82))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.24), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        .position(x: size.width * 0.79, y: size.height * 0.86)
    }
}

private struct GramophonePipeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.82))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.55),
            control1: CGPoint(x: rect.minX + rect.width * 0.17, y: rect.minY + rect.height * 0.75),
            control2: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.61)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.minY + rect.height * 0.52),
            control1: CGPoint(x: rect.minX + rect.width * 0.33, y: rect.minY + rect.height * 0.47),
            control2: CGPoint(x: rect.minX + rect.width * 0.37, y: rect.minY + rect.height * 0.50)
        )
        return path
    }
}

private struct HornBellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.70))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.06),
            control1: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.38),
            control2: CGPoint(x: rect.minX + rect.width * 0.29, y: rect.minY + rect.height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.96, y: rect.minY + rect.height * 0.20),
            control1: CGPoint(x: rect.minX + rect.width * 0.66, y: rect.minY + rect.height * 0.02),
            control2: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.07)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.90),
            control1: CGPoint(x: rect.minX + rect.width * 0.80, y: rect.minY + rect.height * 0.43),
            control2: CGPoint(x: rect.minX + rect.width * 0.79, y: rect.minY + rect.height * 0.69)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.70),
            control1: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.minY + rect.height * 0.88),
            control2: CGPoint(x: rect.minX + rect.width * 0.33, y: rect.minY + rect.height * 0.76)
        )
        path.closeSubpath()
        return path
    }
}

private struct HornRibsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let throat = CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.69)
        let endpoints = [
            CGPoint(x: rect.minX + rect.width * 0.86, y: rect.minY + rect.height * 0.20),
            CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.38),
            CGPoint(x: rect.minX + rect.width * 0.91, y: rect.minY + rect.height * 0.58),
            CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.78)
        ]

        for endpoint in endpoints {
            path.move(to: throat)
            path.addCurve(
                to: endpoint,
                control1: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.42),
                control2: CGPoint(x: rect.minX + rect.width * 0.60, y: endpoint.y)
            )
        }
        return path
    }
}

private struct TurntableBase: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.95, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.80))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.80))
        path.closeSubpath()
        return path
    }
}

private struct GramophoneNeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.66))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.50, y: rect.minY + rect.height * 0.68))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.56, y: rect.minY + rect.height * 0.71))
        return path
    }
}
