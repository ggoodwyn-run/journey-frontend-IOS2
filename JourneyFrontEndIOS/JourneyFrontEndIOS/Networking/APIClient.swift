import Foundation

// MARK: - Shared decoder

private let decoder: JSONDecoder = {
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
            if let d = isoWithFraction.date(from: dateStr) { return d }
            if let d = isoNoFraction.date(from: dateStr) { return d }
            if let d = fractionalFormatter.date(from: dateStr) { return d }
            if let d = fractionalFormatterShort.date(from: dateStr) { return d }
            if let d = shortDateFormatter.date(from: dateStr) { return d }
            if let seconds = TimeInterval(dateStr) { return Date(timeIntervalSince1970: seconds) }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date string: \(dateStr)")
        }

        if let ts = try? container.decode(Double.self) { return Date(timeIntervalSince1970: ts) }
        if let ts = try? container.decode(Int.self) { return Date(timeIntervalSince1970: TimeInterval(ts)) }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date from JSON")
    }

    return decoder
}()

// MARK: - Errors

enum APIError: LocalizedError {
    case authenticationRequired(message: String? = nil)
    case serverError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .authenticationRequired(let message): return message ?? "Authentication required"
        case .serverError(let statusCode, let message): return message ?? "Server error \(statusCode)"
        }
    }
}

private struct LoginResponse: Decodable {
    let access_token: String
    let token_type: String?
}

// MARK: - APIClient

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let tokenKey = "authToken"

    private var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    // Redirect delegate that preserves the Authorization header
    private class RedirectDelegate: NSObject, URLSessionTaskDelegate {
        let authorizationValue: String?
        init(authorizationValue: String?) { self.authorizationValue = authorizationValue }

        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            var newRequest = request
            if let auth = authorizationValue {
                newRequest.setValue(auth, forHTTPHeaderField: "Authorization")
            }
            completionHandler(newRequest)
        }
    }

    private func sessionPreservingAuthorization(_ authValue: String?) -> URLSession {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config, delegate: RedirectDelegate(authorizationValue: authValue), delegateQueue: nil)
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        print("[APIClient] login: attempting login for email=\(email)")
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent("/api/v1/auth/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8)
            print("[APIClient] login failed status=\(http.statusCode)")
            throw APIError.serverError(statusCode: http.statusCode, message: bodyStr)
        }

        // Decode token from response
        if let decoded = try? JSONDecoder().decode(LoginResponse.self, from: data) {
            token = decoded.access_token
        } else if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let t = obj["access_token"] as? String { token = t }
            else if let t = obj["accessToken"] as? String { token = t }
            else if let t = obj["token"] as? String { token = t }
            else if let t = obj["auth_token"] as? String { token = t }
        }

        guard token != nil else {
            throw APIError.serverError(statusCode: http.statusCode, message: "No access token in login response")
        }

        print("[APIClient] login succeeded, token saved")
    }

    // Helper to build a request and attach Bearer token
    private func makeAuthedRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let tokenRaw = token?.trimmingCharacters(in: .whitespacesAndNewlines), !tokenRaw.isEmpty else {
            throw APIError.authenticationRequired()
        }

        // Normalize token: remove wrapping quotes and existing scheme
        var normalized = tokenRaw
        if normalized.hasPrefix("\"") && normalized.hasSuffix("\"") {
            normalized = String(normalized.dropFirst().dropLast())
        }
        if normalized.lowercased().starts(with: "bearer ") {
            normalized = String(normalized.dropFirst("bearer ".count))
        } else if normalized.lowercased().starts(with: "token ") {
            normalized = String(normalized.dropFirst("token ".count))
        }
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)

        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let authHeaderValue = "Bearer \(normalized)"
        request.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        request.httpBody = body

        print("[APIClient] Authorization header set for \(path)")
        return request
    }

    // MARK: - Endpoints

    func fetchCurrentJourney() async throws -> JourneyWithProgress {
        let request = try makeAuthedRequest(path: "api/v1/journeys/current")
        print("[APIClient] fetchCurrentJourney starting")

        let session = sessionPreservingAuthorization(request.value(forHTTPHeaderField: "Authorization"))
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8)
            print("[APIClient] fetchCurrentJourney failed status=\(http.statusCode)")
            if http.statusCode == 401 { throw APIError.authenticationRequired(message: body) }
            throw APIError.serverError(statusCode: http.statusCode, message: body)
        }

        let journey = try decoder.decode(JourneyWithProgress.self, from: data)
        print("[APIClient] fetchCurrentJourney succeeded")
        return journey
    }

    func createRun(_ requestBody: RunCreateRequest) async throws -> RunResponse {
        // Build body with snake_case keys and date-only format
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .iso8601)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        fmt.dateFormat = "yyyy-MM-dd"

        var dict: [String: Any] = [
            "distance_miles": requestBody.distanceMiles,
            "date": fmt.string(from: requestBody.date),
            "activity_type": requestBody.activityType,
            "journey_id": requestBody.journeyId
        ]
        if let mood = requestBody.moodRating { dict["mood_rating"] = mood }

        let body = try JSONSerialization.data(withJSONObject: dict, options: [])
        let request = try makeAuthedRequest(path: "api/v1/runs", method: "POST", body: body)
        print("[APIClient] createRun starting")

        let session = sessionPreservingAuthorization(request.value(forHTTPHeaderField: "Authorization"))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if !(200...299).contains(http.statusCode) {
            let bodyString = String(data: data, encoding: .utf8)
            print("[APIClient] createRun failed status=\(http.statusCode)")
            if http.statusCode == 401 { throw APIError.authenticationRequired(message: bodyString) }
            throw APIError.serverError(statusCode: http.statusCode, message: bodyString)
        }

        let runResponse = try decoder.decode(RunResponse.self, from: data)
        print("[APIClient] createRun succeeded")
        return runResponse
    }


    func fetchAllJourneys() async throws -> [JourneyRead] {
        let request = try makeAuthedRequest(path: "api/v1/journeys")
        let session = sessionPreservingAuthorization(request.value(forHTTPHeaderField: "Authorization"))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8)
            if http.statusCode == 401 { throw APIError.authenticationRequired(message: body) }
            throw APIError.serverError(statusCode: http.statusCode, message: body)
        }
        return try decoder.decode([JourneyRead].self, from: data)
    }

    func createJourney(_ requestBody: JourneyCreateRequest) async throws -> JourneyCreateResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(requestBody)
        let request = try makeAuthedRequest(path: "api/v1/journeys", method: "POST", body: body)
        let session = sessionPreservingAuthorization(request.value(forHTTPHeaderField: "Authorization"))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if !(200...299).contains(http.statusCode) {
            let bodyString = String(data: data, encoding: .utf8)
            if http.statusCode == 401 { throw APIError.authenticationRequired(message: bodyString) }
            throw APIError.serverError(statusCode: http.statusCode, message: bodyString)
        }
        let journeyResponse = try decoder.decode(JourneyCreateResponse.self, from: data)
        return journeyResponse
    }

    func deleteJourney(_ journeyId: Int) async throws {
        let request = try makeAuthedRequest(path: "api/v1/journeys/\(journeyId)", method: "DELETE")
        let session = sessionPreservingAuthorization(request.value(forHTTPHeaderField: "Authorization"))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8)
            if http.statusCode == 401 { throw APIError.authenticationRequired(message: bodyString) }
            throw APIError.serverError(statusCode: http.statusCode, message: bodyString)
        }
    }
}
extension APIClient {
    func fetchJourneyProgress(_ journeyId: Int) async throws -> JourneyWithProgress {
        let request = try makeAuthedRequest(path: "api/v1/journeys/\(journeyId)")
        let session = sessionPreservingAuthorization(request.value(forHTTPHeaderField: "Authorization"))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if !(200...299).contains(http.statusCode) {
            let bodyString = String(data: data, encoding: .utf8)
            if http.statusCode == 401 { throw APIError.authenticationRequired(message: bodyString) }
            throw APIError.serverError(statusCode: http.statusCode, message: bodyString)
        }
        return try decoder.decode(JourneyWithProgress.self, from: data)
    }
}

extension APIClient {
    /// Fetch the interpolated progress location for a journey from the backend
    func fetchProgressLocation(_ journeyId: Int) async throws -> ProgressLocation {
        let request = try makeAuthedRequest(path: "api/v1/journeys/\(journeyId)/progress-location")
        let session = sessionPreservingAuthorization(request.value(forHTTPHeaderField: "Authorization"))
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if !(200...299).contains(http.statusCode) {
            let bodyString = String(data: data, encoding: .utf8)
            if http.statusCode == 401 { throw APIError.authenticationRequired(message: bodyString) }
            throw APIError.serverError(statusCode: http.statusCode, message: bodyString)
        }
        return try decoder.decode(ProgressLocation.self, from: data)
    }
}
