//
//  APIConfig.swift
//  JourneyFrontEndIOS
//
//  Created by alaina riordan on 12/6/25.
//


import Foundation

enum APIConfig {
    // For simulator, assuming FastAPI runs on your Mac at this port
    static let baseURL = URL(string: "http://127.0.0.1:8000")!
}
