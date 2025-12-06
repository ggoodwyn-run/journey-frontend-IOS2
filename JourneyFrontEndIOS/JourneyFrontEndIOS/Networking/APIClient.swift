//
//  LoginResponse.swift
//  JourneyFrontEndIOS
//
//  Created by alaina riordan on 12/6/25.
//


import Foundation

struct LoginResponse: Decodable {
    let access_token: String
    let token_type: String
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private var token: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws {
        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent("/auth/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
        token = decoded.access_token
    }

    // Helper for authed requests
    private func makeAuthedRequest(path: String,
                                   method: String = "GET",
                                   body: Data? = nil) throws -> URLRequest {
        guard let token else {
            throw URLError(.userAuthenticationRequired)
        }

        var request = URLRequest(url: APIConfig.baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        return request
    }

    // You’ll add:
    // - fetchJourneys()
    // - startJourney(journeyId:)
    // - logRun(distance:date:)
    // - fetchProgress()
}
