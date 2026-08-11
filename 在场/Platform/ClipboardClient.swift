import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum ClipboardClient {
    static func readText() -> String? {
#if os(macOS)
        NSPasteboard.general.string(forType: .string)
#elseif os(iOS)
        UIPasteboard.general.string
#else
        nil
#endif
    }

    static func writeText(_ value: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
#elseif os(iOS)
        UIPasteboard.general.string = value
#endif
    }
}
