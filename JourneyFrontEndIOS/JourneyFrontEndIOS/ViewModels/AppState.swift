//
//  AppState.swift
//  JourneyFrontEndIOS
//
//  Created by alaina riordan on 12/6/25.
//


import Foundation
import SwiftUI

final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var hasActiveJourney: Bool = false

    init() {
        // super simple: you're "logged in" if a token exists
        let token = UserDefaults.standard.string(forKey: "authToken")
        self.isLoggedIn = (token != nil)
    }

    func setLoggedIn(_ loggedIn: Bool) {
        isLoggedIn = loggedIn
    }

    func setHasActiveJourney(_ active: Bool) {
        hasActiveJourney = active
    }
}
