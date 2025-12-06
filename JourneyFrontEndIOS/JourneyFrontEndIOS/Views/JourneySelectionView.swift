//
//  JourneySelectionView.swift
//  JourneyFrontEndIOS
//
//  Created by alaina riordan on 12/6/25.
//


import SwiftUI

struct JourneySelectionView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Text("Journey Selection")
                .font(.title)

            Text("This will show journeys from the backend.")

            Button("Mock: Set Active Journey") {
                appState.setHasActiveJourney(true)
            }

            Spacer()
        }
        .padding()
    }
}
