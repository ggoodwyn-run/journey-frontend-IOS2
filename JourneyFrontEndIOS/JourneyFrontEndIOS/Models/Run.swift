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
}

// MARK: - Predefined cities with distances

struct City: Identifiable, Hashable {
    let id: String
    let name: String
    let state: String
    
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
    City(id: "charlotte", name: "Charlotte", state: "NC"),
    City(id: "atlanta", name: "Atlanta", state: "GA"),
    City(id: "nashville", name: "Nashville", state: "TN"),
    City(id: "memphis", name: "Memphis", state: "TN"),
    City(id: "miami", name: "Miami", state: "FL"),
    City(id: "orlando", name: "Orlando", state: "FL"),
    City(id: "austin", name: "Austin", state: "TX"),
    City(id: "dallas", name: "Dallas", state: "TX"),
    City(id: "houston", name: "Houston", state: "TX"),
    City(id: "new_orleans", name: "New Orleans", state: "LA"),
    City(id: "denver", name: "Denver", state: "CO"),
    City(id: "phoenix", name: "Phoenix", state: "AZ"),
    City(id: "los_angeles", name: "Los Angeles", state: "CA"),
    City(id: "san_francisco", name: "San Francisco", state: "CA"),
    City(id: "seattle", name: "Seattle", state: "WA"),
    City(id: "portland", name: "Portland", state: "OR"),
    City(id: "chicago", name: "Chicago", state: "IL"),
    City(id: "new_york", name: "New York", state: "NY"),
    City(id: "boston", name: "Boston", state: "MA"),
    City(id: "philadelphia", name: "Philadelphia", state: "PA"),
]
