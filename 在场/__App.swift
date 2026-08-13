//
//  __App.swift
//  在场
//
//  Created by 郑恩嵘 on 2026/8/10.
//

import SwiftUI

@main
struct __App: App {
    init() {
        AppStoragePaths.migrateLegacyRootIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1400, height: 860)
#endif
    }
}
