//
//  Injury.swift
//  fakhripeakplay
//
//  Injury data model
//

import Foundation
import SwiftUI

struct Injury: Codable, Identifiable, Equatable {
    let id: String
    let type: String
    let severity: String
    let description: String
    let status: String // "apte" | "surveille" | "indisponible"
    let playerId: String?
    let academyId: String?
    let evolutions: [Evolution]?
    let recommendations: [String]?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case severity
        case description
        case status
        case playerId
        case academyId
        case evolutions
        case recommendations
        case createdAt
        case updatedAt
    }
    
    var lastEvolution: Evolution? {
        evolutions?.last
    }
    
    var statusColor: Color {
        switch status.lowercased() {
        case "apte":
            return .green
        case "surveille":
            return .orange
        case "indisponible":
            return .red
        default:
            return .gray
        }
    }
}

struct Evolution: Codable, Identifiable, Equatable {
    let id = UUID() // Add a unique ID for Identifiable
    let date: String
    let painLevel: Int // Changed from notes to painLevel
    let note: String // Changed from status to note
    
    enum CodingKeys: String, CodingKey {
        case date
        case painLevel
        case note
    }
}

struct CreateInjuryRequest: Codable {
    let type: String
    let severity: String
    let description: String
    // playerId is not needed - the backend gets it from the authentication token
}

struct AddEvolutionRequest: Codable {
    let painLevel: Int // 0-10
    let note: String
}

struct AddRecommendationRequest: Codable {
    let recommendation: String
}

struct UpdateStatusRequest: Codable {
    let status: String
}

