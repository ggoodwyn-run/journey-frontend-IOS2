import SwiftUI
import MapKit

// MARK: - Notification for data refresh

extension Notification.Name {
    static let journeyDataChanged = Notification.Name("journeyDataChanged")
}

// MARK: - Main Home View (Globe with Floating Buttons)

struct JourneyHomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddRun = false
    @State private var showingAddJourney = false

    var body: some View {
        ZStack {
            // Main content: Globe View (includes journey sheet)
            GlobeView()
            
            // Floating action buttons - ALWAYS visible in top right
            floatingButtons
        }
        .fullScreenCover(isPresented: $showingAddRun) {
            AddRunSheet(isPresented: $showingAddRun)
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showingAddJourney) {
            AddJourneySheet(isPresented: $showingAddJourney)
                .environmentObject(appState)
        }
    }
    
    private var floatingButtons: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Add Run button
                    Button(action: { showingAddRun = true }) {
                        Image(systemName: "figure.run")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(colors: [JourneyColors.primary, JourneyColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())
                            .shadow(color: JourneyColors.primary.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    
                    // Add Journey button
                    Button(action: { showingAddJourney = true }) {
                        Image(systemName: "map.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(colors: [JourneyColors.secondary, JourneyColors.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())
                            .shadow(color: JourneyColors.secondary.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 60)
            
            Spacer()
        }
        .zIndex(100)
    }
}

// MARK: - Stars Background View

struct StarsBackgroundView: View {
    let starCount: Int
    
    init(starCount: Int = 150) {
        self.starCount = starCount
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<starCount, id: \.self) { i in
                    let seed = Double(i)
                    let x = seededRandom(seed: seed * 1.1) * geo.size.width
                    let y = seededRandom(seed: seed * 2.3) * geo.size.height
                    let size = seededRandom(seed: seed * 3.7) * 2.5 + 0.5
                    let opacity = seededRandom(seed: seed * 4.9) * 0.7 + 0.3
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: size, height: size)
                        .position(x: x, y: y)
                        .opacity(opacity)
                }
            }
        }
    }
    
    private func seededRandom(seed: Double) -> Double {
        let x = sin(seed * 12.9898 + 78.233) * 43758.5453
        return x - floor(x)
    }
}

// MARK: - Add Run Sheet

struct AddRunSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var journeys: [JourneyRead] = []
    @State private var selectedJourney: JourneyRead?
    @State private var distance = ""
    @State private var date = Date()
    @State private var mood = 5
    @State private var isCreating = false
    @State private var error: String?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(red: 0.08, green: 0.12, blue: 0.20), Color(red: 0.12, green: 0.16, blue: 0.26)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().scaleEffect(1.3).tint(JourneyColors.primary)
                        Text("Loading journeys...").foregroundColor(JourneyColors.textSecondary)
                    }
                } else if journeys.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "map").font(.system(size: 50)).foregroundColor(.white.opacity(0.3))
                        Text("No active journeys").font(.title3).foregroundColor(.white.opacity(0.6))
                        Text("Create a journey first to log runs").font(.caption).foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    Form {
                        Section(header: Text("Select Journey").foregroundColor(.white)) {
                            Picker("Journey", selection: $selectedJourney) {
                                Text("Choose a journey...").tag(JourneyRead?.none)
                                ForEach(journeys) { j in
                                    HStack {
                                        Text("🏃")
                                        Text(j.name)
                                    }.tag(JourneyRead?.some(j))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Section(header: Text("Run Details").foregroundColor(.white)) {
                            TextField("Distance (miles)", text: $distance)
                                .keyboardType(.decimalPad)
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                            Stepper("Mood: \(mood) ⭐️", value: $mood, in: 1...10)
                        }
                        
                        if let e = error {
                            Section {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                                    Text(e).foregroundColor(.red)
                                }
                            }
                        }
                        
                        Section {
                            Button(action: { Task { await createRun() } }) {
                                HStack {
                                    Spacer()
                                    if isCreating {
                                        ProgressView().tint(.white)
                                        Text("Creating...").foregroundColor(.white)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Log Run")
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .disabled(isCreating || selectedJourney == nil || distance.isEmpty)
                            .listRowBackground(
                                (selectedJourney != nil && !distance.isEmpty && !isCreating)
                                    ? JourneyColors.primary
                                    : JourneyColors.primary.opacity(0.4)
                            )
                            .foregroundColor(.white)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Log a Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(red: 0.08, green: 0.12, blue: 0.20), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task { await loadJourneys() }
        }
    }
    
    @MainActor private func loadJourneys() async {
        isLoading = true
        defer { isLoading = false }
        journeys = ((try? await APIClient.shared.fetchAllJourneys()) ?? []).filter { $0.status.lowercased() == "active" }
        selectedJourney = journeys.first
    }
    
    private func createRun() async {
        guard let j = selectedJourney, let d = Double(distance) else {
            error = "Please fill in all fields"
            return
        }
        isCreating = true
        error = nil
        do {
            _ = try await APIClient.shared.createRun(RunCreateRequest(distanceMiles: d, date: date, moodRating: mood, journeyId: j.id))
            NotificationCenter.default.post(name: .journeyDataChanged, object: nil)
            await MainActor.run { isPresented = false }
        } catch {
            self.error = "Failed to create run"
        }
        isCreating = false
    }
}

// MARK: - Add Journey Sheet

struct AddJourneySheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            JourneySelectionView(onJourneyCreated: {
                NotificationCenter.default.post(name: .journeyDataChanged, object: nil)
                isPresented = false
            })
            .navigationTitle("Create Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color(red: 0.08, green: 0.12, blue: 0.20), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Globe View

struct GlobeView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35, longitude: -98), span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50))
    @State private var journeys: [JourneyRead] = []
    @State private var progressMap: [Int: JourneyWithProgress] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedJourney: JourneyRead?
    @State private var selectedProgress: JourneyWithProgress?
    @State private var selectedProgressLocation: ProgressLocation?
    @State private var showingRoute = false

    var currentJourneys: [JourneyRead] { journeys.filter { $0.status.lowercased() == "active" } }
    var completedJourneys: [JourneyRead] { journeys.filter { $0.status.lowercased() == "completed" } }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.7
            ZStack {
                // Space background with gradient
                LinearGradient(colors: [.black, Color(red: 0.02, green: 0.02, blue: 0.08), Color(red: 0.05, green: 0.02, blue: 0.15)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                
                // Stars
                StarsBackgroundView(starCount: 200)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !showingRoute {
                        titleSection
                        Spacer()
                    }
                    
                    mapSection(size: size, fullSize: geo.size)
                    
                    if !showingRoute {
                        Spacer()
                        controlsSection
                    }
                }
                
                // Route overlay when showing a journey
                if showingRoute {
                    routeOverlay
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !showingRoute {
                journeyListSheet
            }
        }
        .task { await loadJourneys() }
        .onReceive(NotificationCenter.default.publisher(for: .journeyDataChanged)) { _ in
            Task { await loadJourneys() }
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Explore").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text("Your Journey Awaits").font(.system(size: 14, weight: .light)).foregroundColor(.white.opacity(0.6))
        }.padding(.top, 60)
    }
    
    private func mapSection(size: CGFloat, fullSize: CGSize) -> some View {
        ZStack {
            // Atmospheric glow behind the globe
            if !showingRoute {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.cyan.opacity(0.3),
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.45,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 1.2, height: size * 1.2)
                    .blur(radius: 15)
            }
            
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: annotations) { item in
                MapAnnotation(coordinate: item.coord) { annotationView(for: item) }
            }
            .frame(width: showingRoute ? fullSize.width : size, height: showingRoute ? fullSize.height : size)
            .clipShape(showingRoute ? AnyShape(Rectangle()) : AnyShape(Circle()))
            .overlay(showingRoute ? nil : globeOverlay(size: size))
            .shadow(color: showingRoute ? .clear : Color.cyan.opacity(0.3), radius: 25)
            .animation(.easeInOut(duration: 0.6), value: showingRoute)
        }
    }
    
    private func annotationView(for item: MapItem) -> some View {
        VStack(spacing: 2) {
            Circle().fill(item.type == .progress ? JourneyColors.primary : (item.type == .start ? JourneyColors.success : JourneyColors.accent))
                .frame(width: item.type == .progress ? 16 : 12, height: item.type == .progress ? 16 : 12)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: item.type == .progress ? JourneyColors.primary.opacity(0.5) : .clear, radius: 6)
            if item.type != .progress {
                Text(item.name).font(.caption2).fontWeight(.medium).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2).background(.black.opacity(0.75)).cornerRadius(6)
            }
        }
    }
    
    private func globeOverlay(size: CGFloat) -> AnyView {
        AnyView(ZStack {
            // Inner shadow for depth
            Circle().fill(RadialGradient(colors: [.clear, .clear, .black.opacity(0.15), .black.opacity(0.3)], center: UnitPoint(x: 0.4, y: 0.4), startRadius: size * 0.2, endRadius: size * 0.5)).allowsHitTesting(false)
            
            // Light reflection
            Circle().fill(RadialGradient(colors: [.white.opacity(0.2), .white.opacity(0.08), .clear], center: UnitPoint(x: 0.3, y: 0.3), startRadius: 0, endRadius: size * 0.3)).allowsHitTesting(false)
            
            // Atmospheric edge glow
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.6),
                            Color.blue.opacity(0.4),
                            Color.cyan.opacity(0.3),
                            Color.blue.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .blur(radius: 2)
            
            // Sharp edge
            Circle().stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        })
    }
    
    private var routeOverlay: some View {
        VStack {
            HStack {
                Button(action: closeRoute) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 4)
                }
                .padding(.leading, 20).padding(.top, 60)
                Spacer()
            }
            Spacer()
            if let j = selectedJourney { statsCard(j) }
        }
    }
    
    private func statsCard(_ j: JourneyRead) -> some View {
        VStack(spacing: 16) {
            HStack { Text("🏃").font(.title2); Text(j.name).font(.title3).fontWeight(.bold).foregroundColor(.white); Spacer() }
            Divider().background(Color.white.opacity(0.3))
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Distance").font(.caption).foregroundColor(.white.opacity(0.6))
                    Text("\(Int(j.totalDistanceMiles)) miles").font(.title2).fontWeight(.bold).foregroundColor(.white)
                }
                Spacer()
            }
            
            if let p = selectedProgress {
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress").font(.subheadline).foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(Int(p.percentComplete * 100))%").font(.title3).fontWeight(.bold).foregroundColor(JourneyColors.primary)
                    }
                    ProgressView(value: p.percentComplete).tint(JourneyColors.primary).scaleEffect(y: 2)
                    HStack {
                        Text(String(format: "%.1f mi done", p.distanceCompletedMiles)).font(.caption).foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(String(format: "%.1f mi left", j.totalDistanceMiles - p.distanceCompletedMiles)).font(.caption).foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            HStack {
                Text(j.startLabel).font(.caption).fontWeight(.medium).foregroundColor(JourneyColors.success)
                Image(systemName: "arrow.right").font(.caption2).foregroundColor(.white.opacity(0.5))
                Text(j.destLabel).font(.caption).fontWeight(.medium).foregroundColor(JourneyColors.accent)
                Spacer()
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(JourneyColors.primary.opacity(0.3), lineWidth: 1)))
        .padding(.horizontal, 16).padding(.bottom, 40)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 20) {
                Button { zoomIn() } label: { Image(systemName: "plus.magnifyingglass").font(.title2).foregroundColor(.white).frame(width: 50, height: 50).background(Color.white.opacity(0.15)).clipShape(Circle()) }
                Button { zoomOut() } label: { Image(systemName: "minus.magnifyingglass").font(.title2).foregroundColor(.white).frame(width: 50, height: 50).background(Color.white.opacity(0.15)).clipShape(Circle()) }
                Spacer()
                Button { resetView() } label: { Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white).frame(width: 50, height: 50).background(Color.white.opacity(0.15)).clipShape(Circle()) }
            }.padding(.horizontal, 30)
            Text("Pinch to zoom • Drag to explore").font(.caption).foregroundColor(.white.opacity(0.5)).padding(.bottom, 8)
        }
    }
    
    private var journeyListSheet: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            Text("Your Journeys").font(.headline).foregroundColor(.white).padding(.vertical, 12)
            
            if isLoading {
                ProgressView().tint(JourneyColors.primary).padding(.bottom, 20)
            } else if journeys.isEmpty {
                VStack(spacing: 8) {
                    Text("No journeys yet").foregroundColor(.white.opacity(0.5))
                    Text("Tap the map icon to create one!").font(.caption).foregroundColor(.white.opacity(0.3))
                }.padding(.bottom, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(currentJourneys) { j in
                            journeyCard(j)
                        }
                        ForEach(completedJourneys) { j in
                            journeyCard(j, completed: true)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.04, green: 0.06, blue: 0.12).opacity(0.95))
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
    
    private func journeyCard(_ j: JourneyRead, completed: Bool = false) -> some View {
        Button { Task { await selectJourney(j) } } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🏃")
                    Text(j.name).fontWeight(.semibold).foregroundColor(.white).lineLimit(1)
                }
                Text("\(j.startLabel) → \(j.destLabel)").font(.caption2).foregroundColor(.white.opacity(0.6)).lineLimit(1)
                if let p = progressMap[j.id] {
                    ProgressView(value: p.percentComplete).tint(JourneyColors.primary)
                    Text("\(Int(p.percentComplete * 100))%").font(.caption2).foregroundColor(JourneyColors.primary)
                } else if completed {
                    Text("✓ Completed").font(.caption2).foregroundColor(JourneyColors.success)
                }
            }
            .frame(width: 150)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
    
    private var annotations: [MapItem] {
        guard let j = selectedJourney, showingRoute else { return [] }
        var items: [MapItem] = []
        if let lat = j.startLat, let lng = j.startLng { items.append(MapItem(id: "start", name: j.startLabel, coord: CLLocationCoordinate2D(latitude: lat, longitude: lng), type: .start)) }
        if let lat = j.destLat, let lng = j.destLng { items.append(MapItem(id: "dest", name: j.destLabel, coord: CLLocationCoordinate2D(latitude: lat, longitude: lng), type: .end)) }
        if let loc = selectedProgressLocation { items.append(MapItem(id: "progress", name: "You", coord: CLLocationCoordinate2D(latitude: loc.currentLat, longitude: loc.currentLng), type: .progress)) }
        return items
    }
    
    @MainActor
    private func selectJourney(_ j: JourneyRead) async {
        selectedJourney = j
        selectedProgress = progressMap[j.id]
        
        if j.status.lowercased() == "active" && j.startLat != nil && j.destLat != nil {
            selectedProgressLocation = try? await APIClient.shared.fetchProgressLocation(j.id)
        } else {
            selectedProgressLocation = nil
        }
        
        if let startLat = j.startLat, let startLng = j.startLng, let destLat = j.destLat, let destLng = j.destLng {
            let centerLat = (startLat + destLat) / 2
            let centerLng = (startLng + destLng) / 2
            withAnimation(.easeInOut(duration: 0.8)) {
                region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng), span: MKCoordinateSpan(latitudeDelta: max(abs(startLat - destLat) * 1.8, 3), longitudeDelta: max(abs(startLng - destLng) * 1.8, 3)))
                showingRoute = true
            }
        }
    }
    
    private func closeRoute() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showingRoute = false
            selectedJourney = nil
            selectedProgress = nil
            selectedProgressLocation = nil
            region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35, longitude: -98), span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50))
        }
    }
    
    private func zoomIn() { withAnimation { region.span.latitudeDelta = max(region.span.latitudeDelta / 2, 2); region.span.longitudeDelta = max(region.span.longitudeDelta / 2, 2) } }
    private func zoomOut() { withAnimation { region.span.latitudeDelta = min(region.span.latitudeDelta * 2, 150); region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 150) } }
    private func resetView() { withAnimation { region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35, longitude: -98), span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)) } }
    
    @MainActor private func loadJourneys() async {
        isLoading = true
        defer { isLoading = false }
        do {
            journeys = try await APIClient.shared.fetchAllJourneys()
            for j in journeys.filter({ $0.status.lowercased() == "active" }) {
                if let p = try? await APIClient.shared.fetchJourneyProgress(j.id) { progressMap[p.id] = p }
            }
        } catch {
            if let apiErr = error as? APIError, case .authenticationRequired = apiErr {
                appState.setLoggedIn(false)
            }
            journeys = []
        }
    }
}

// MARK: - Helper Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct MapItem: Identifiable {
    enum Kind { case start, end, progress }
    let id: String
    let name: String
    let coord: CLLocationCoordinate2D
    let type: Kind
}

struct AnyShape: Shape {
    private let builder: (CGRect) -> Path
    init<S: Shape>(_ s: S) { builder = { s.path(in: $0) } }
    func path(in rect: CGRect) -> Path { builder(rect) }
}
