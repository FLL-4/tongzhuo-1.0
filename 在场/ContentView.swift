//
//  ContentView.swift
//  在场
//
//  Created by 郑恩嵘 on 2026/8/10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()
#if os(iOS)
    @Environment(\.scenePhase) private var scenePhase
#endif

    var body: some View {
        AppShellView(model: model)
            .preferredColorScheme(.dark)
#if os(macOS)
            .ignoresSafeArea(.container, edges: .top)
            .frame(minWidth: 980, minHeight: 620)
            .onAppear {
                model.activateAudio()
            }
            .background {
                HostingWindowReader { window in
                    FloatingDeskPetWindow.shared.attach(
                        to: window,
                        controller: model.deskPet
                    )
                }
                .frame(width: 0, height: 0)
            }
#else
            .onAppear { model.activateAudio() }
#endif
            .onDisappear { model.deactivateAudio() }
#if os(iOS)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    model.activateAudio()
                case .background:
                    model.enterMobileBackground()
                case .inactive:
                    break
                @unknown default:
                    model.deactivateAudio()
                }
            }
#endif
    }
}

#Preview {
    ContentView()
}
