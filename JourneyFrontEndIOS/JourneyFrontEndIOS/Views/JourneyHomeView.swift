import SwiftUI

struct JourneyHomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Modern dark blue gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.13, blue: 0.22), // Deep navy
                    Color(red: 0.12, green: 0.18, blue: 0.30)  // Slightly lighter navy
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Home Tab - Journey List
                JourneyListView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Home", systemImage: "location.fill")
                    }
                    .tag(0)

                // Add Run Tab
                AddRunView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Add Run", systemImage: "figure.stairs")
                    }
                    .tag(1)

                // Add Journey Tab
                AddJourneyView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Journey", systemImage: "map.fill")
                    }
                    .tag(2)
            }
            .accentColor(JourneyColors.primary)
        }
    }
}

// MARK: - Journey List View (Home Tab)

struct JourneyListView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    
    @State private var journeys: [JourneyRead] = []
    @State private var journeyProgressMap: [Int: JourneyWithProgress] = [:]
    @State private var isLoading = true
    @State private var error: String?
    
    @State private var expandedJourneyIds: Set<Int> = []
    @State private var journeyToDelete: JourneyRead?

    var currentJourneys: [JourneyRead] {
        journeys.filter { $0.status.lowercased() == "active" }
    }

    var completedJourneys: [JourneyRead] {
        journeys.filter { $0.status.lowercased() == "completed" }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(JourneyColors.primary)
                        Text("Loading your journeys...")
                            .font(.subheadline)
                            .foregroundColor(JourneyColors.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if let error {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(JourneyColors.accent)
                            Text(error)
                                .foregroundColor(.gray)
                        }
                        if !appState.isLoggedIn {
                            Button(action: { appState.setLoggedIn(false) }) {
                                Text("Log In")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(JourneyColors.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current Journeys Section
                            if !currentJourneys.isEmpty {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "figure.stairs")
                                            .font(.title3)
                                            .foregroundColor(JourneyColors.primary)
                                        Text(currentJourneys.count == 1 ? "Current Journey" : "Current Journeys")
                                            .font(.headline)
                                            .foregroundColor(JourneyColors.textPrimary)
                                    }
                                    .padding(.horizontal)

                                    VStack(spacing: 12) {
                                        ForEach(currentJourneys) { journey in
                                            ExpandableJourneyCard(
                                                journey: journey,
                                                isExpanded: expandedJourneyIds.contains(journey.id),
                                                journeyProgress: journeyProgressMap[journey.id],
                                                onTap: {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        if expandedJourneyIds.contains(journey.id) {
                                                            expandedJourneyIds.remove(journey.id)
                                                        } else {
                                                            expandedJourneyIds.insert(journey.id)
                                                        }
                                                    }
                                                },
                                                onDelete: {
                                                    journeyToDelete = journey
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Completed Journeys Section
                            if !completedJourneys.isEmpty {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(JourneyColors.success)
                                        Text("Completed Journeys")
                                            .font(.headline)
                                            .foregroundColor(JourneyColors.textPrimary)
                                    }
                                    .padding(.horizontal)

                                    VStack(spacing: 12) {
                                        ForEach(completedJourneys) { journey in
                                            ExpandableJourneyCard(
                                                journey: journey,
                                                isExpanded: expandedJourneyIds.contains(journey.id),
                                                journeyProgress: nil,
                                                onTap: {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        if expandedJourneyIds.contains(journey.id) {
                                                            expandedJourneyIds.remove(journey.id)
                                                        } else {
                                                            expandedJourneyIds.insert(journey.id)
                                                        }
                                                    }
                                                },
                                                onDelete: {
                                                    journeyToDelete = journey
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.bottom)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Your Journeys")
            .navigationBarTitleDisplayMode(.large)
            .task { await loadJourneys() }
            .onChange(of: selectedTab) { newTab in
                if newTab == 0 {
                    Task { await loadJourneys() }
                }
            }
            .alert("Delete Journey", isPresented: .constant(journeyToDelete != nil), presenting: journeyToDelete) { journey in
                Button("Cancel", role: .cancel) { journeyToDelete = nil }
                Button("Delete", role: .destructive) {
                    Task { await deleteJourney(journey) }
                }
            } message: { journey in
                Text("Are you sure you want to delete '\(journey.name)'? This cannot be undone.")
            }
        }
    }

    @MainActor
    private func loadJourneys() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let allJourneys = try await APIClient.shared.fetchAllJourneys()
            journeys = allJourneys
            
            // Fetch progress for ALL active journeys
            let activeJourneys = allJourneys.filter { $0.status.lowercased() == "active" }
            for journey in activeJourneys {
                do {
                    let progress = try await APIClient.shared.fetchJourneyProgress(journey.id)
                    journeyProgressMap[progress.id] = progress
                } catch {
                    print("[JourneyListView] Failed to fetch progress for journey \(journey.id): \(error)")
                }
            }
            error = nil
        } catch {
            if let apiErr = error as? APIError, case .authenticationRequired = apiErr {
                appState.setLoggedIn(false)
                self.error = "Please log in to view your journeys."
            } else {
                self.error = "Failed to load journeys: \(error.localizedDescription)"
            }
            journeys = []
            journeyProgressMap = [:]
        }
    }

    private func deleteJourney(_ journey: JourneyRead) async {
        do {
            try await APIClient.shared.deleteJourney(journey.id)
            journeyToDelete = nil
            await loadJourneys()
        } catch {
            if let apiErr = error as? APIError, case .authenticationRequired = apiErr {
                await MainActor.run {
                    appState.setLoggedIn(false)
                }
            }
        }
    }
}

// MARK: - Expandable Journey Card

struct ExpandableJourneyCard: View {
    let journey: JourneyRead
    let isExpanded: Bool
    let journeyProgress: JourneyWithProgress?
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed/Header View
            HStack(spacing: 12) {
                // Running stick figure icon
                Text("🏃")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(journey.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(JourneyColors.textPrimary)

                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(JourneyColors.secondary)
                        Text("\(journey.startLabel) → \(journey.destLabel)")
                            .font(.caption)
                            .foregroundColor(JourneyColors.textSecondary)
                    }

                    HStack(spacing: 12) {
                        Text("\(journey.totalDistanceMiles, specifier: "%.0f") mi")
                            .font(.caption2)
                            .foregroundColor(JourneyColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.2, green: 0.25, blue: 0.35))
                            .cornerRadius(4)
                        
                        if journey.status.lowercased() == "completed" {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(JourneyColors.success)
                        }
                    }
                }
                
                Spacer()
                
                // Only show delete button for active journeys
                if journey.status.lowercased() == "active" {
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.subheadline)
                            .foregroundColor(JourneyColors.accent)
                            .padding(10)
                            .background(Color(red: 0.3, green: 0.15, blue: 0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .background(JourneyColors.cardBackground)

            // Expanded Detail View
            if isExpanded {
                Divider()
                    .padding(0)
                
                if let progress = journeyProgress {
                    VStack(alignment: .leading, spacing: 16) {
                        // Progress Bar
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Progress")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(JourneyColors.textPrimary)
                                Spacer()
                                Text(String(format: "%.0f%%", progress.percentComplete * 100))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(JourneyColors.primary)
                            }
                            
                            ProgressView(value: progress.percentComplete)
                                .tint(JourneyColors.primary)
                            
                            HStack {
                                Text(String(format: "%.1f", progress.distanceCompletedMiles))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(JourneyColors.textPrimary)
                                Text("/ \(journey.totalDistanceMiles, specifier: "%.0f") miles")
                                    .font(.caption)
                                    .foregroundColor(JourneyColors.textSecondary)
                            }
                        }
                        .padding()
                        .background(Color(red: 0.16, green: 0.2, blue: 0.3))
                        .cornerRadius(8)
                        
                        // Activity Info
                        if let lastDate = progress.lastActivityDate {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(JourneyColors.secondary)
                                    Text("Last Activity")
                                        .font(.caption2)
                                        .foregroundColor(JourneyColors.textSecondary)
                                }
                                Text(lastDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(JourneyColors.textPrimary)
                            }
                            .padding()
                            .background(Color(red: 0.16, green: 0.2, blue: 0.3))
                            .cornerRadius(8)
                        }
                        
                        if let mood = progress.lastMoodRating {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "smiley.fill")
                                        .font(.caption)
                                        .foregroundColor(JourneyColors.secondary)
                                    Text("Mood Rating")
                                        .font(.caption2)
                                        .foregroundColor(JourneyColors.textSecondary)
                                }
                                HStack {
                                    ForEach(1...5, id: \.self) { i in
                                        Image(systemName: i <= mood ? "star.fill" : "star")
                                            .font(.caption)
                                            .foregroundColor(JourneyColors.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color(red: 0.16, green: 0.2, blue: 0.3))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(JourneyColors.cardBackground)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Journey Completed! 🎉")
                            .font(.headline)
                            .foregroundColor(JourneyColors.success)
                        Text("You've successfully completed this journey!")
                            .font(.caption)
                            .foregroundColor(JourneyColors.textSecondary)
                    }
                    .padding(16)
                    .background(JourneyColors.cardBackground)
                }
            }
        }
        .cornerRadius(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(JourneyColors.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Add Run View (Tab)

struct AddRunView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    
    @State private var journeys: [JourneyRead] = []
    @State private var selectedJourney: JourneyRead?
    @State private var newRunDistance = ""
    @State private var newRunDate = Date()
    @State private var newRunMood: Int = 5
    @State private var isCreatingRun = false
    @State private var createRunError: String?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(JourneyColors.primary)
                        Text("Loading...")
                            .foregroundColor(JourneyColors.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    Form {
                        Section(header: Text("Select Journey").font(.headline)) {
                            Picker("Journey", selection: $selectedJourney) {
                                Text("Choose a journey").tag(JourneyRead?.none)
                                ForEach(journeys) { journey in
                                    HStack {
                                        Text("🏃")
                                        Text(journey.name)
                                    }
                                    .tag(JourneyRead?.some(journey))
                                }
                            }
                        }

                        Section(header: Text("Run Details").font(.headline)) {
                            TextField("Distance (miles)", text: $newRunDistance)
                                .keyboardType(.decimalPad)
                            DatePicker("Date", selection: $newRunDate, displayedComponents: .date)
                            Stepper(value: $newRunMood, in: 1...10) {
                                HStack {
                                    Text("Mood rating")
                                    Spacer()
                                    HStack(spacing: 2) {
                                        ForEach(1...newRunMood, id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(JourneyColors.secondary)
                                        }
                                    }
                                }
                            }
                        }

                        if let createRunError {
                            Section {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(JourneyColors.accent)
                                    Text(createRunError)
                                        .foregroundColor(JourneyColors.accent)
                                }
                            }
                        }

                        Section {
                            Button(action: { Task { await createRun() } }) {
                                if isCreatingRun {
                                    HStack {
                                        ProgressView()
                                            .tint(Color.white)
                                        Text("Creating Run...")
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    Text("Create Run")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .disabled(isCreatingRun || selectedJourney == nil)
                            .tint(JourneyColors.primary)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(JourneyColors.background)
                }
            }
            .navigationTitle("Log a Run")
            .navigationBarTitleDisplayMode(.large)
            .task { await loadJourneys() }
            .onChange(of: selectedTab) { newTab in
                if newTab == 1 {
                    Task { await loadJourneys() }
                }
            }
        }
    }

    @MainActor
    private func loadJourneys() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let allJourneys = try await APIClient.shared.fetchAllJourneys()
            journeys = allJourneys.filter { $0.status.lowercased() == "active" }
            if !journeys.isEmpty {
                selectedJourney = journeys[0]
            }
        } catch {
            if let apiErr = error as? APIError, case .authenticationRequired = apiErr {
                appState.setLoggedIn(false)
            }
        }
    }

    private func createRun() async {
        createRunError = nil
        guard let selectedJourney = selectedJourney else {
            createRunError = "Please select a journey."
            return
        }
        guard let distance = Double(newRunDistance) else {
            createRunError = "Please enter a valid distance."
            return
        }
        
        isCreatingRun = true
        let request = RunCreateRequest(
            distanceMiles: distance,
            date: newRunDate,
            moodRating: newRunMood,
            journeyId: selectedJourney.id
        )
        
        do {
            _ = try await APIClient.shared.createRun(request)
            await MainActor.run {
                newRunDistance = ""
                newRunDate = Date()
                newRunMood = 5
                self.selectedJourney = journeys.first
                selectedTab = 0
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

// MARK: - Add Journey View (Tab)

struct AddJourneyView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            JourneySelectionView(onJourneyCreated: {
                selectedTab = 0
            })
            .navigationTitle("Create Journey")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
