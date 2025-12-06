import SwiftUI

struct JourneyHomeView: View {
    @EnvironmentObject var appState: AppState

    @State private var journey: JourneyWithProgress?
    @State private var isLoading = true
    @State private var error: String?

    // Add Run sheet
    @State private var isAddRunPresented = false
    @State private var newRunDistance = ""
    @State private var newRunDate = Date()
    @State private var newRunMood: Int = 5
    @State private var isCreatingRun = false
    @State private var createRunError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let journey {
                Text(journey.name)
                    .font(.title2)

                Text(String(format: "%.1f / %.1f miles", journey.distanceCompletedMiles, journey.totalDistanceMiles))

                Text(String(format: "%.0f%% complete", journey.percentComplete * 100))

                ProgressView(value: journey.percentComplete)

                if let lastDate = journey.lastActivityDate {
                    Text("Last activity: \(lastDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: { isAddRunPresented = true }) {
                    Label("Add Run", systemImage: "plus")
                }
                .padding(.top)
                .sheet(isPresented: $isAddRunPresented) {
                    NavigationView {
                        Form {
                            Section(header: Text("Run details")) {
                                TextField("Distance (miles)", text: $newRunDistance)
                                    .keyboardType(.decimalPad)
                                DatePicker("Date", selection: $newRunDate, displayedComponents: .date)
                                Stepper(value: $newRunMood, in: 1...10) {
                                    Text("Mood rating: \(newRunMood)")
                                }
                            }

                            if let createRunError {
                                Section { Text(createRunError).foregroundColor(.red) }
                            }

                            Section {
                                Button(action: { Task { await createRun() } }) {
                                    if isCreatingRun { ProgressView() } else { Text("Create Run") }
                                }
                                .disabled(isCreatingRun)
                            }
                        }
                        .navigationTitle("Add Run")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { isAddRunPresented = false }
                            }
                        }
                    }
                }

            } else if isLoading {
                ProgressView("Loading journey…")
            } else if let error {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error).foregroundColor(.red)
                    if !appState.isLoggedIn {
                        Button("Log in") { appState.setLoggedIn(false) }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .task { await loadJourney() }
    }

    private func loadJourney() async {
        isLoading = true
        do {
            journey = try await APIClient.shared.fetchCurrentJourney()
            error = nil
        } catch {
            // Handle authentication-specific error so UI can show login
            if let apiErr = error as? APIError, case .authenticationRequired = apiErr {
                await MainActor.run {
                    appState.setLoggedIn(false)
                    self.error = "Please log in to load your journey."
                }
            } else {
                self.error = "Failed to load journey: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }

    private func createRun() async {
        createRunError = nil
        guard let distance = Double(newRunDistance) else {
            createRunError = "Please enter a valid distance."
            return
        }
        isCreatingRun = true
        let request = RunCreateRequest(distanceMiles: distance, date: newRunDate, moodRating: newRunMood)
        do {
            _ = try await APIClient.shared.createRun(request)
            await loadJourney()
            await MainActor.run {
                newRunDistance = ""
                newRunDate = Date()
                newRunMood = 5
                isAddRunPresented = false
            }
        } catch {
            if let apiErr = error as? APIError, case .authenticationRequired = apiErr {
                await MainActor.run {
                    appState.setLoggedIn(false)
                    createRunError = "Please log in to create a run."
                }
            } else {
                createRunError = "Failed to create run: \(error.localizedDescription)"
            }
        }
        isCreatingRun = false
    }
}
