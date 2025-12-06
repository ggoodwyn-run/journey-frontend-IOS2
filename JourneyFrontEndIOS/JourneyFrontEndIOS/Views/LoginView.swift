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
            errorMessage = "Please enter email and password."
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            try await APIClient.shared.login(email: email, password: password)
            await MainActor.run {
                appState.setLoggedIn(true)
                // After login, backend can tell us if journey exists later
            }
        } catch {
            await MainActor.run {
                errorMessage = "Login failed. Check your credentials."
            }
        }
        isLoading = false
    }
}
