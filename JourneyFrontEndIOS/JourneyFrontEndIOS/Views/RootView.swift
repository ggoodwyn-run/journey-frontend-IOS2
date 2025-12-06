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
            } else if !appState.hasActiveJourney {
                JourneySelectionView()
            } else {
                JourneyHomeView()
            }
        }
    }
}
