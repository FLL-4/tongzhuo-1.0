import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct PolaroidMemoryCard: View {
    let draft: MemoryDraft

    var body: some View {
        VStack(spacing: 0) {
            artwork
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.93, green: 0.90, blue: 0.84))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .padding(.bottom, 42)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.96, green: 0.93, blue: 0.86))
                .shadow(color: .black.opacity(0.34), radius: 18, x: 0, y: 10)
        )
        .rotationEffect(.degrees(-1.1))
        .aspectRatio(0.82, contentMode: .fit)
    }

    private var artwork: some View {
        Group {
            if let image = imageFromData(draft.imageData) {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.37, green: 0.29, blue: 0.22),
                                Color(red: 0.18, green: 0.17, blue: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        PhonographArtwork(variant: .cardPlaceholder)
                            .padding(12)
                            .accessibilityHidden(true)
                    }
            }
        }
        .clipped()
    }

    private func imageFromData(_ data: Data?) -> Image? {
        guard let data else { return nil }
#if os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
#else
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
#endif
    }
}
