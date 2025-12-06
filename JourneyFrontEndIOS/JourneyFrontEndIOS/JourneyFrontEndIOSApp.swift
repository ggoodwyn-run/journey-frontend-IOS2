//
//  JourneyFrontEndIOSApp.swift
//  JourneyFrontEndIOS
//
//  Created by alaina riordan on 12/6/25.
//

import SwiftUI

@main
struct JourneyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
