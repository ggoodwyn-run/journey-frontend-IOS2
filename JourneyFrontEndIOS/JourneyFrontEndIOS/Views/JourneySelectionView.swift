import SwiftUI

struct JourneySelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var startCity: City?
    @State private var destCity: City?
    @State private var isCreatingJourney = false
    @State private var error: String?
    
    var onJourneyCreated: (() -> Void)?

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
                // Header
                VStack(spacing: 12) {
                    Text("🗺️")
                        .font(.system(size: 48))
                    
                    Text("Create a New Journey")
                        .font(.headline)
                        .foregroundColor(JourneyColors.textPrimary)
                    
                    Text("Pick your route")
                        .font(.caption)
                        .foregroundColor(JourneyColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                
                // Form
                ScrollView {
                    VStack(spacing: 16) {
                        // Starting City
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(JourneyColors.secondary)
                                Text("Starting City")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(JourneyColors.textPrimary)
                            }
                            
                            Picker("Select start city", selection: $startCity) {
                                Text("Choose a city").tag(City?.none)
                                    .foregroundColor(JourneyColors.textSecondary)
                                ForEach(predefinedCities) { city in
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                        Text(city.displayName)
                                    }
                                    .tag(City?.some(city))
                                    .foregroundColor(JourneyColors.textPrimary)
                                }
                            }
                            .tint(JourneyColors.secondary)
                            .padding(14)
                            .background(JourneyColors.cardBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(startCity != nil ? JourneyColors.secondary : JourneyColors.primary.opacity(0.2), lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Destination City
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(JourneyColors.secondary)
                                Text("Destination City")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(JourneyColors.textPrimary)
                            }
                            
                            Picker("Select destination city", selection: $destCity) {
                                Text("Choose a city").tag(City?.none)
                                    .foregroundColor(JourneyColors.textSecondary)
                                ForEach(predefinedCities) { city in
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                        Text(city.displayName)
                                    }
                                    .tag(City?.some(city))
                                    .foregroundColor(JourneyColors.textPrimary)
                                }
                            }
                            .tint(JourneyColors.secondary)
                            .padding(14)
                            .background(JourneyColors.cardBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(destCity != nil ? JourneyColors.secondary : JourneyColors.primary.opacity(0.2), lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Error Message
                        if let error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(JourneyColors.accent)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(JourneyColors.accent)
                            }
                            .padding(12)
                            .background(JourneyColors.accent.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
                
                // Create Button
                VStack(spacing: 12) {
                    Button(action: { Task { await createJourney() } }) {
                        if isCreatingJourney {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Creating Journey...")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(JourneyColors.primary.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right")
                                Text("Create Journey")
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
                    .disabled(isCreatingJourney || startCity == nil || destCity == nil || startCity?.id == destCity?.id)
                    
                    if startCity == destCity && startCity != nil {
                        Text("Start and destination cities must be different")
                            .font(.caption)
                            .foregroundColor(JourneyColors.accent)
                    }
                }
                .padding(20)
                .background(JourneyColors.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 8)
                .padding(16)
            }
        }
    }

    @MainActor
    private func createJourney() async {
        guard let startCity = startCity, let destCity = destCity else {
            error = "Please select both cities."
            return
        }
        
        guard startCity.id != destCity.id else {
            error = "Start and destination cities must be different."
            return
        }

        error = nil
        isCreatingJourney = true

        let journeyName = "\(startCity.name) → \(destCity.name)"
        let distance = calculateDistance(from: startCity, to: destCity)
        let request = JourneyCreateRequest(
            startCity: startCity.id,
            destCity: destCity.id,
            startLabel: startCity.displayName,
            destLabel: destCity.displayName,
            name: journeyName,
            totalDistanceMiles: distance
        )

        do {
            _ = try await APIClient.shared.createJourney(request)
            onJourneyCreated?()
            try await Task.sleep(nanoseconds: 500_000_000)
            dismiss()
        } catch {
            if let apiErr = error as? APIError, case .authenticationRequired = apiErr {
                appState.setLoggedIn(false)
                self.error = "Please log in to create a journey."
            } else {
                self.error = "Failed to create journey: \(error.localizedDescription)"
            }
        }

        isCreatingJourney = false
    }
    
    private func calculateDistance(from start: City, to dest: City) -> Double {
        let cityDistances: [String: [String: Double]] = [
            "charlotte": ["atlanta": 245, "nashville": 330, "memphis": 420, "miami": 600, "orlando": 550, "austin": 800, "dallas": 790, "houston": 900, "neworleans": 700, "denver": 1100, "phoenix": 1200, "losangeles": 2000, "sanfrancisco": 2100, "seattle": 2200, "portland": 2300, "chicago": 650, "newyork": 500, "boston": 550, "philadelphia": 480],
            "atlanta": ["charlotte": 245, "nashville": 280, "memphis": 350, "miami": 550, "orlando": 450, "austin": 850, "dallas": 800, "houston": 900, "neworleans": 650, "denver": 1150, "phoenix": 1250, "losangeles": 2050, "sanfrancisco": 2150, "seattle": 2250, "portland": 2350, "chicago": 700, "newyork": 550, "boston": 600, "philadelphia": 530],
            "nashville": ["charlotte": 330, "atlanta": 280, "memphis": 210, "miami": 650, "orlando": 550, "austin": 600, "dallas": 550, "houston": 700, "neworleans": 500, "denver": 900, "phoenix": 1000, "losangeles": 1800, "sanfrancisco": 1900, "seattle": 2000, "portland": 2100, "chicago": 450, "newyork": 700, "boston": 800, "philadelphia": 700],
            "memphis": ["charlotte": 420, "atlanta": 350, "nashville": 210, "miami": 750, "orlando": 650, "austin": 450, "dallas": 400, "houston": 550, "neworleans": 350, "denver": 750, "phoenix": 850, "losangeles": 1650, "sanfrancisco": 1750, "seattle": 1850, "portland": 1950, "chicago": 350, "newyork": 800, "boston": 900, "philadelphia": 800],
            "miami": ["charlotte": 600, "atlanta": 550, "nashville": 650, "memphis": 750, "orlando": 200, "austin": 1050, "dallas": 1000, "houston": 1100, "neworleans": 900, "denver": 1400, "phoenix": 1500, "losangeles": 2200, "sanfrancisco": 2300, "seattle": 2400, "portland": 2500, "chicago": 1200, "newyork": 1100, "boston": 1200, "philadelphia": 1100],
            "orlando": ["charlotte": 550, "atlanta": 450, "nashville": 550, "memphis": 650, "miami": 200, "austin": 1000, "dallas": 950, "houston": 1050, "neworleans": 850, "denver": 1350, "phoenix": 1450, "losangeles": 2150, "sanfrancisco": 2250, "seattle": 2350, "portland": 2450, "chicago": 1150, "newyork": 1050, "boston": 1150, "philadelphia": 1050],
            "austin": ["charlotte": 800, "atlanta": 850, "nashville": 600, "memphis": 450, "miami": 1050, "orlando": 1000, "dallas": 200, "houston": 165, "neworleans": 350, "denver": 600, "phoenix": 700, "losangeles": 1500, "sanfrancisco": 1600, "seattle": 1700, "portland": 1800, "chicago": 900, "newyork": 1200, "boston": 1300, "philadelphia": 1200],
            "dallas": ["charlotte": 790, "atlanta": 800, "nashville": 550, "memphis": 400, "miami": 1000, "orlando": 950, "austin": 200, "houston": 240, "neworleans": 400, "denver": 500, "phoenix": 600, "losangeles": 1400, "sanfrancisco": 1500, "seattle": 1600, "portland": 1700, "chicago": 900, "newyork": 1200, "boston": 1300, "philadelphia": 1200],
            "houston": ["charlotte": 900, "atlanta": 900, "nashville": 700, "memphis": 550, "miami": 1100, "orlando": 1050, "austin": 165, "dallas": 240, "neworleans": 350, "denver": 600, "phoenix": 700, "losangeles": 1500, "sanfrancisco": 1600, "seattle": 1700, "portland": 1800, "chicago": 1000, "newyork": 1300, "boston": 1400, "philadelphia": 1300],
            "neworleans": ["charlotte": 700, "atlanta": 650, "nashville": 500, "memphis": 350, "miami": 900, "orlando": 850, "austin": 350, "dallas": 400, "houston": 350, "denver": 750, "phoenix": 850, "losangeles": 1650, "sanfrancisco": 1750, "seattle": 1850, "portland": 1950, "chicago": 650, "newyork": 1100, "boston": 1200, "philadelphia": 1100],
            "denver": ["charlotte": 1100, "atlanta": 1150, "nashville": 900, "memphis": 750, "miami": 1400, "orlando": 1350, "austin": 600, "dallas": 500, "houston": 600, "neworleans": 750, "phoenix": 450, "losangeles": 1050, "sanfrancisco": 1150, "seattle": 1300, "portland": 1400, "chicago": 600, "newyork": 1450, "boston": 1550, "philadelphia": 1450],
            "phoenix": ["charlotte": 1200, "atlanta": 1250, "nashville": 1000, "memphis": 850, "miami": 1500, "orlando": 1450, "austin": 700, "dallas": 600, "houston": 700, "neworleans": 850, "denver": 450, "losangeles": 600, "sanfrancisco": 700, "seattle": 850, "portland": 950, "chicago": 900, "newyork": 1550, "boston": 1650, "philadelphia": 1550],
            "losangeles": ["charlotte": 2000, "atlanta": 2050, "nashville": 1800, "memphis": 1650, "miami": 2200, "orlando": 2150, "austin": 1500, "dallas": 1400, "houston": 1500, "neworleans": 1650, "denver": 1050, "phoenix": 600, "sanfrancisco": 350, "seattle": 850, "portland": 950, "chicago": 1700, "newyork": 2300, "boston": 2400, "philadelphia": 2300],
            "sanfrancisco": ["charlotte": 2100, "atlanta": 2150, "nashville": 1900, "memphis": 1750, "miami": 2300, "orlando": 2250, "austin": 1600, "dallas": 1500, "houston": 1600, "neworleans": 1750, "denver": 1150, "phoenix": 700, "losangeles": 350, "seattle": 650, "portland": 750, "chicago": 1800, "newyork": 2400, "boston": 2500, "philadelphia": 2400],
            "seattle": ["charlotte": 2200, "atlanta": 2250, "nashville": 2000, "memphis": 1850, "miami": 2400, "orlando": 2350, "austin": 1700, "dallas": 1600, "houston": 1700, "neworleans": 1850, "denver": 1300, "phoenix": 850, "losangeles": 850, "sanfrancisco": 650, "portland": 150, "chicago": 1900, "newyork": 2500, "boston": 2600, "philadelphia": 2500],
            "portland": ["charlotte": 2300, "atlanta": 2350, "nashville": 2100, "memphis": 1950, "miami": 2500, "orlando": 2450, "austin": 1800, "dallas": 1700, "houston": 1800, "neworleans": 1950, "denver": 1400, "phoenix": 950, "losangeles": 950, "sanfrancisco": 750, "seattle": 150, "chicago": 2000, "newyork": 2600, "boston": 2700, "philadelphia": 2600],
            "chicago": ["charlotte": 650, "atlanta": 700, "nashville": 450, "memphis": 350, "miami": 1200, "orlando": 1150, "austin": 900, "dallas": 900, "houston": 1000, "neworleans": 650, "denver": 600, "phoenix": 900, "losangeles": 1700, "sanfrancisco": 1800, "seattle": 1900, "portland": 2000, "newyork": 600, "boston": 700, "philadelphia": 600],
            "newyork": ["charlotte": 500, "atlanta": 550, "nashville": 700, "memphis": 800, "miami": 1100, "orlando": 1050, "austin": 1200, "dallas": 1200, "houston": 1300, "neworleans": 1100, "denver": 1450, "phoenix": 1550, "losangeles": 2300, "sanfrancisco": 2400, "seattle": 2500, "portland": 2600, "chicago": 600, "boston": 200, "philadelphia": 100],
            "boston": ["charlotte": 550, "atlanta": 600, "nashville": 800, "memphis": 900, "miami": 1200, "orlando": 1150, "austin": 1300, "dallas": 1300, "houston": 1400, "neworleans": 1200, "denver": 1550, "phoenix": 1650, "losangeles": 2400, "sanfrancisco": 2500, "seattle": 2600, "portland": 2700, "chicago": 700, "newyork": 200, "philadelphia": 300],
            "philadelphia": ["charlotte": 480, "atlanta": 530, "nashville": 700, "memphis": 800, "miami": 1100, "orlando": 1050, "austin": 1200, "dallas": 1200, "houston": 1300, "neworleans": 1100, "denver": 1450, "phoenix": 1550, "losangeles": 2300, "sanfrancisco": 2400, "seattle": 2500, "portland": 2600, "chicago": 600, "newyork": 100, "boston": 300]
        ]
        
        return cityDistances[start.id]?[dest.id] ?? 250.0
    }
}

#Preview {
    JourneySelectionView()
        .environmentObject(AppState())
}
