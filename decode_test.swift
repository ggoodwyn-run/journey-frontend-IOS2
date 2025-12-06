import Foundation

// Minimal duplicate of the model + decoder used in the app to test decoding the backend sample JSON.

enum JourneyStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case archived = "archived"
}

struct JourneyWithProgress: Identifiable, Codable {
    let id: Int
    let name: String
    let startLabel: String
    let destLabel: String

    let totalDistanceMiles: Double
    let status: JourneyStatus

    let startedAt: Date?
    let completedAt: Date?

    let distanceCompletedMiles: Double
    let percentComplete: Double

    let lastMoodRating: Int?
    let lastActivityDate: Date?
}

// Create decoder like APIClient
let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let isoWithFraction = ISO8601DateFormatter()
    isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let isoNoFraction = ISO8601DateFormatter()
    isoNoFraction.formatOptions = [.withInternetDateTime]

    let fractionalFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return f
    }()
    let fractionalFormatterShort: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return f
    }()

    let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()

        if let dateStr = try? container.decode(String.self) {
            // Try ISO format with timezone/fraction
            if let d = isoWithFraction.date(from: dateStr) { return d }
            if let d = isoNoFraction.date(from: dateStr) { return d }
            // Try naive fractional format (microseconds)
            if let d = fractionalFormatter.date(from: dateStr) { return d }
            if let d = fractionalFormatterShort.date(from: dateStr) { return d }
            // Try short date like 2025-12-06
            if let d = shortDateFormatter.date(from: dateStr) { return d }
            // If string is numeric epoch
            if let seconds = TimeInterval(dateStr) { return Date(timeIntervalSince1970: seconds) }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date string: \(dateStr)")
        }

        if let ts = try? container.decode(Double.self) { return Date(timeIntervalSince1970: ts) }
        if let ts = try? container.decode(Int.self) { return Date(timeIntervalSince1970: TimeInterval(ts)) }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date from JSON")
    }

    return decoder
}()

let json = #"{"id":2,"name":"Charlotte → Atlanta","start_label":"Charlotte, NC","dest_label":"Atlanta, GA","total_distance_miles":250.0,"distance_completed_miles":3.0,"percent_complete":0.012,"status":"active","started_at":"2025-12-06T13:39:09.401345","completed_at":null,"last_mood_rating":2,"last_activity_date":"2025-12-06"}"#

let data = Data(json.utf8)

print("Decoding sample JSON...")

do {
    let j = try decoder.decode(JourneyWithProgress.self, from: data)
    print("Decoded successfully:")
    print("id: \(j.id)")
    print("name: \(j.name)")
    print("startLabel: \(j.startLabel)")
    print("destLabel: \(j.destLabel)")
    print("totalDistanceMiles: \(j.totalDistanceMiles)")
    print("distanceCompletedMiles: \(j.distanceCompletedMiles)")
    print("percentComplete: \(j.percentComplete)")
    print("status: \(j.status.rawValue)")
    if let started = j.startedAt { print("startedAt: \(started)") } else { print("startedAt: nil") }
    if let last = j.lastActivityDate { print("lastActivityDate: \(last)") } else { print("lastActivityDate: nil") }
} catch {
    print("Failed to decode: \(error)")
}
