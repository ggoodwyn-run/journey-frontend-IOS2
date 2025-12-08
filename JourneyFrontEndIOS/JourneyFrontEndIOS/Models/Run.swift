import Foundation

// MARK: - Run models

struct RunCreateRequest: Encodable {
    let distanceMiles: Double
    let date: Date
    let moodRating: Int?
    let activityType: String
    let journeyId: Int

    init(distanceMiles: Double, date: Date, moodRating: Int?, journeyId: Int, activityType: String = "run") {
        self.distanceMiles = distanceMiles
        self.date = date
        self.moodRating = moodRating
        self.activityType = activityType
        self.journeyId = journeyId
    }
}

struct RunResponse: Decodable, Identifiable {
    let id: Int
    let distanceMiles: Double
    let date: Date
    let moodRating: Int?
}

// MARK: - Journey creation models

struct JourneyCreateRequest: Encodable {
    let startCity: String
    let destCity: String
    let startLabel: String
    let destLabel: String
    let name: String
    let totalDistanceMiles: Double
    
    // Coordinate fields for map display
    let startLat: Double?
    let startLng: Double?
    let destLat: Double?
    let destLng: Double?
    
    init(startCity: String, destCity: String, startLabel: String, destLabel: String, name: String, totalDistanceMiles: Double, startLat: Double? = nil, startLng: Double? = nil, destLat: Double? = nil, destLng: Double? = nil) {
        self.startCity = startCity
        self.destCity = destCity
        self.startLabel = startLabel
        self.destLabel = destLabel
        self.name = name
        self.totalDistanceMiles = totalDistanceMiles
        self.startLat = startLat
        self.startLng = startLng
        self.destLat = destLat
        self.destLng = destLng
    }
}

struct JourneyCreateResponse: Decodable, Identifiable {
    let id: Int
    let name: String
    let startLabel: String
    let destLabel: String
    let totalDistanceMiles: Double
    let status: String
    let startedAt: Date?
    let completedAt: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct JourneyRead: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let startLabel: String
    let destLabel: String
    let totalDistanceMiles: Double
    let status: String
    let startedAt: Date?
    let completedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Coordinate fields from backend
    let startLat: Double?
    let startLng: Double?
    let destLat: Double?
    let destLng: Double?
}

// MARK: - Progress Location (from /journeys/{id}/progress-location)

struct ProgressLocation: Decodable {
    let journeyId: Int
    let currentLat: Double
    let currentLng: Double
    let distanceCompletedMiles: Double
    let percentComplete: Double
}

// MARK: - Predefined cities with distances

struct City: Identifiable, Hashable {
    let id: String
    let name: String
    let state: String
    let lat: Double
    let lng: Double
    
    var displayName: String {
        "\(name), \(state)"
    }
}

// City distance data (miles) - indexed by city IDs for easy lookup
let cityDistances: [String: [String: Double]] = [
    "charlotte": ["atlanta": 250, "nashville": 330, "memphis": 450, "miami": 600, "orlando": 550, "austin": 800, "dallas": 700, "houston": 750, "new_orleans": 750, "denver": 1000, "phoenix": 1400, "los_angeles": 2100, "san_francisco": 2300, "seattle": 2400, "portland": 2500, "chicago": 450, "new_york": 400, "boston": 450, "philadelphia": 350],
    "atlanta": ["charlotte": 250, "nashville": 250, "memphis": 350, "miami": 500, "orlando": 450, "austin": 700, "dallas": 600, "houston": 650, "new_orleans": 650, "denver": 900, "phoenix": 1300, "los_angeles": 2000, "san_francisco": 2200, "seattle": 2300, "portland": 2400, "chicago": 350, "new_york": 300, "boston": 350, "philadelphia": 250],
    "nashville": ["charlotte": 330, "atlanta": 250, "memphis": 200, "miami": 650, "orlando": 600, "austin": 600, "dallas": 500, "houston": 550, "new_orleans": 550, "denver": 800, "phoenix": 1200, "los_angeles": 1900, "san_francisco": 2100, "seattle": 2200, "portland": 2300, "chicago": 300, "new_york": 450, "boston": 500, "philadelphia": 400],
]

let predefinedCities: [City] = [
    City(id: "charlotte", name: "Charlotte", state: "NC", lat: 35.2271, lng: -80.8431),
    City(id: "atlanta", name: "Atlanta", state: "GA", lat: 33.749, lng: -84.388),
    City(id: "nashville", name: "Nashville", state: "TN", lat: 36.1627, lng: -86.7816),
    City(id: "memphis", name: "Memphis", state: "TN", lat: 35.1495, lng: -90.049),
    City(id: "miami", name: "Miami", state: "FL", lat: 25.7617, lng: -80.1918),
    City(id: "orlando", name: "Orlando", state: "FL", lat: 28.5383, lng: -81.3792),
    City(id: "austin", name: "Austin", state: "TX", lat: 30.2672, lng: -97.7431),
    City(id: "dallas", name: "Dallas", state: "TX", lat: 32.7767, lng: -96.797),
    City(id: "houston", name: "Houston", state: "TX", lat: 29.7604, lng: -95.3698),
    City(id: "new_orleans", name: "New Orleans", state: "LA", lat: 29.9511, lng: -90.0715),
    City(id: "denver", name: "Denver", state: "CO", lat: 39.7392, lng: -104.9903),
    City(id: "phoenix", name: "Phoenix", state: "AZ", lat: 33.4484, lng: -112.074),
    City(id: "los_angeles", name: "Los Angeles", state: "CA", lat: 34.0522, lng: -118.2437),
    City(id: "san_francisco", name: "San Francisco", state: "CA", lat: 37.7749, lng: -122.4194),
    City(id: "seattle", name: "Seattle", state: "WA", lat: 47.6062, lng: -122.3321),
    City(id: "portland", name: "Portland", state: "OR", lat: 45.5152, lng: -122.6784),
    City(id: "chicago", name: "Chicago", state: "IL", lat: 41.8781, lng: -87.6298),
    City(id: "new_york", name: "New York", state: "NY", lat: 40.7128, lng: -74.006),
    City(id: "boston", name: "Boston", state: "MA", lat: 42.3601, lng: -71.0589),
    City(id: "philadelphia", name: "Philadelphia", state: "PA", lat: 39.9526, lng: -75.1652),
]
