//
//  LoginView.swift
//  JourneyFrontEndIOS
//
//  Created by alaina riordan on 12/6/25.
//


import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Journey Login")
                .font(.title)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                Task {
                    await handleLogin()
                }
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private func handleLogin() async {
        guard !email.isEmpty, !password.isEmpty else {
            await MainActor.run { errorMessage = "Please enter email and password." }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        print("[LoginView] handleLogin tapped for email=\(email)")
        do {
            try await APIClient.shared.login(email: email, password: password)

            // Debug: check token saved
            let saved = UserDefaults.standard.string(forKey: "authToken")
            if let s = saved {
                let prefix = s.count > 6 ? String(s.prefix(6)) + "…" : s
                print("[LoginView] token in UserDefaults after login: len=\(s.count) prefix=\(prefix)")
            } else {
                print("[LoginView] token NOT found in UserDefaults after login")
            }

            await MainActor.run {
                appState.setLoggedIn(true)
                password = ""
                errorMessage = nil
                isLoading = false
            }
        } catch {
            let message: String
            if let apiErr = error as? APIError, let desc = apiErr.errorDescription {
                message = desc
            } else {
                message = error.localizedDescription
            }
            await MainActor.run {
                errorMessage = "Login failed: \(message)"
                isLoading = false
            }
            print("[LoginView] login failed: \(message)")
        }
    }
}
