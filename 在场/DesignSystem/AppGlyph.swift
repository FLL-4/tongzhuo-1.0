import SwiftUI

struct AppGlyph: View {
    enum Kind {
        case phonograph
        case desk
        case memory
        case scene
    }

    let kind: Kind
    let size: CGFloat

    init(_ kind: Kind, size: CGFloat = 20) {
        self.kind = kind
        self.size = size
    }

    var body: some View {
        ZStack {
            switch kind {
            case .phonograph:
                GlyphVinylIcon()
            case .desk:
                Image(systemName: "person.2")
                    .font(.system(size: size * 0.68, weight: .semibold))
            case .memory:
                Image(systemName: "book.closed")
                    .font(.system(size: size * 0.62, weight: .semibold))
            case .scene:
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: size * 0.62, weight: .semibold))
            }
        }
        .frame(width: size, height: size)
    }
}

private struct GlyphVinylIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.16, green: 0.14, blue: 0.13))
            Circle()
                .stroke(Color(red: 0.34, green: 0.29, blue: 0.26), lineWidth: 1.2)
                .padding(2)
            Circle()
                .stroke(Color(red: 0.26, green: 0.22, blue: 0.20), lineWidth: 1)
                .padding(5)
            Circle()
                .fill(Color(red: 0.84, green: 0.61, blue: 0.31))
                .frame(width: 6, height: 6)
            Circle()
                .fill(Color(red: 0.12, green: 0.09, blue: 0.08))
                .frame(width: 2, height: 2)
                .overlay(alignment: .trailing) {
                    Capsule()
                        .fill(Color(red: 0.78, green: 0.70, blue: 0.58))
                        .frame(width: 7, height: 1.5)
                        .offset(x: 8, y: -10)
                }
        }
        .overlay(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 0.4)
                .fill(Color(red: 0.84, green: 0.76, blue: 0.64))
                .frame(width: 1.2, height: 1.2)
                .offset(x: -8, y: 7)
        }
    }
}
