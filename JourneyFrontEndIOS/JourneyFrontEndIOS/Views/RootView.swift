//
//  RootView.swift
//  JourneyFrontEndIOS
//
//  Created by alaina riordan on 12/6/25.
//


import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.isLoggedIn {
                LoginView()
            } else {
                // User is logged in — show home (or selection if you implement separate flow)
                JourneyHomeView()
            }
        }
    }
}
