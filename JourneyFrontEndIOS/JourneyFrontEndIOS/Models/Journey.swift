//
//  Journey.swift
//  JourneyFrontEndIOS
//
//  Created by alaina riordan on 12/6/25.
//

//todo: define properties of a Journey from/api/current response

import Foundation

enum JourneyStatus: String, Codable {
    case active = "active"
    case completed = "completed"
    case archived = "archived"
}

/// Mirrors the JourneyWithProgress response from /journeys/current
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
