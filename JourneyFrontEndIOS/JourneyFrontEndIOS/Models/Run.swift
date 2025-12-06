import Foundation

// MARK: - Run models

struct RunCreateRequest: Encodable {
    let distanceMiles: Double
    let date: Date
    let moodRating: Int?
    let activityType: String

    init(distanceMiles: Double, date: Date, moodRating: Int?, activityType: String = "run") {
        self.distanceMiles = distanceMiles
        self.date = date
        self.moodRating = moodRating
        self.activityType = activityType
    }
}

struct RunResponse: Decodable, Identifiable {
    let id: Int
    let distanceMiles: Double
    let date: Date
    let moodRating: Int?
}
