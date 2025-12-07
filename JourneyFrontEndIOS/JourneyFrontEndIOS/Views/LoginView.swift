import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Dark blue gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    JourneyColors.background,
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with running emoji
                VStack(spacing: 12) {
                    Text("🏃")
                        .font(.system(size: 64))
                    
                    Text("Journey")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(JourneyColors.textPrimary)
                    
                    Text("Track your running adventures")
                        .font(.subheadline)
                        .foregroundColor(JourneyColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                
                // Login Form
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Email", systemImage: "envelope.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(JourneyColors.textPrimary)
                            
                            TextField("Enter your email", text: $email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .padding(14)
                                .background(JourneyColors.cardBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(JourneyColors.primary.opacity(0.3), lineWidth: 1)
                                )
                                .foregroundColor(JourneyColors.textPrimary)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Password", systemImage: "lock.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(JourneyColors.textPrimary)
                            
                            SecureField("Enter your password", text: $password)
                                .padding(14)
                                .background(JourneyColors.cardBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(JourneyColors.primary.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Error Message
                    if let errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(JourneyColors.accent)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(JourneyColors.accent)
                        }
                        .padding(12)
                        .background(JourneyColors.accent.opacity(0.15))
                        .cornerRadius(8)
                    }
                    
                    // Login Button
                    Button {
                        Task {
                            await handleLogin()
                        }
                    } label: {
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Logging in...")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(JourneyColors.primary.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right")
                                Text("Log In")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        JourneyColors.primary,
                                        JourneyColors.secondary
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .cornerRadius(10)
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(24)
                .background(JourneyColors.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 8)
                .padding(20)
                
                Spacer()
            }
        }
    }

    @MainActor
    private func handleLogin() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await APIClient.shared.login(email: email, password: password)
            appState.setLoggedIn(true)
        } catch {
            if let apiErr = error as? APIError {
                errorMessage = apiErr.errorDescription ?? "Login failed"
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
