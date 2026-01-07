//
//  MatchModels.swift
//  IosDam
//
//  Match data models for detailed match information
//

import Foundation

// MARK: - Match Status Enum

enum MatchStatus: String, Codable {
    case SCHEDULED = "PROGRAMME"
    case IN_PROGRESS = "EN_COURS"
    case COMPLETED = "TERMINE"
    case CANCELLED = "CANCELLED" // Kept for safety, though backend might not support it
}

// MARK: - Match Event Type

enum MatchEventType: String, Codable {
    case GOAL = "GOAL"
    case YELLOW_CARD = "YELLOW_CARD"
    case RED_CARD = "RED_CARD"
    case SUBSTITUTION = "SUBSTITUTION"
    case PENALTY = "PENALTY"
}

// MARK: - Match Event

struct MatchEvent: Codable, Identifiable {
    let id: String
    let match_id: String
    let event_type: MatchEventType
    let team_id: String
    let player_id: String?
    let minute: Int
    let description: String?
    let created_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case match_id
        case event_type
        case team_id
        case player_id
        case minute
        case description
        case created_at
    }
}

// MARK: - Match Statistics

struct MatchStatistics: Codable {
    let possession_team1: Int? // Percentage
    let possession_team2: Int?
    let shots_team1: Int?
    let shots_team2: Int?
    let shots_on_target_team1: Int?
    let shots_on_target_team2: Int?
    let corners_team1: Int?
    let corners_team2: Int?
    let fouls_team1: Int?
    let fouls_team2: Int?
    let yellow_cards_team1: Int?
    let yellow_cards_team2: Int?
    let red_cards_team1: Int?
    let red_cards_team2: Int?
}

// MARK: - Team Info (lightweight for match details)

struct MatchTeamInfo: Codable, Identifiable {
    let _id: String
    var nom: String?
    let logo: String?
    
    var id: String { _id }
    
    enum CodingKeys: String, CodingKey {
        case _id, id, nom, logo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let idVal = try? container.decode(String.self, forKey: ._id) {
            _id = idVal
        } else if let idObj = try? container.decode([String: String].self, forKey: ._id),
                  let oid = idObj["$oid"] {
            _id = oid
        } else if let idVal2 = try? container.decode(String.self, forKey: .id) {
            _id = idVal2
        } else {
            // Fallback or throw
            throw DecodingError.dataCorruptedError(forKey: ._id, in: container, debugDescription: "Missing _id or id")
        }
        
        nom = try? container.decode(String.self, forKey: .nom)
        logo = try? container.decode(String.self, forKey: .logo)
    }
    
    // Memberwise initializer
    init(_id: String, nom: String?, logo: String?) {
        self._id = _id
        self.nom = nom
        self.logo = logo
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(nom, forKey: .nom)
        try container.encode(logo, forKey: .logo)
    }
}

// MARK: - Referee Info

struct MatchRefereeInfo: Codable, Identifiable {
    let _id: String
    let nom: String
    let prenom: String
    
    var id: String { _id }
    var fullName: String { "\(prenom) \(nom)" }
}

// MARK: - Stadium Info

struct MatchStadiumInfo: Codable, Identifiable {
    let _id: String
    let nom: String
    let adresse: String?
    
    var id: String { _id }
}

// MARK: - Detailed Match Model

// MARK: - Match Player Info
struct MatchPlayerInfo: Codable, Identifiable {
    let _id: String
    let nom: String
    let prenom: String
    
    var id: String { _id }
    var fullName: String { "\(prenom) \(nom)" }
}

// MARK: - Detailed Match Model

struct MatchDetail: Codable, Identifiable {
    let id: String
    var id_equipe1: MatchTeamInfo?
    var id_equipe2: MatchTeamInfo?
    let id_terrain: MatchStadiumInfo?
    let id_arbitre: MatchRefereeInfo?
    let date: Date?
    var score_eq1: Int
    var score_eq2: Int
    let statut: MatchStatus
    let round: Int
    let nextMatch: String?
    let positionInNextMatch: String?
    let statistics: MatchStatistics?
    let events: [MatchEvent]?
    let createdAt: String?
    let updatedAt: String?
    
    // Detailed Stats Lists
    let cartonJaune: [MatchPlayerInfo]?
    let cartonRouge: [MatchPlayerInfo]?
    let But_eq1: [MatchPlayerInfo]?
    let But_eq2: [MatchPlayerInfo]?
    let assist_eq1: [MatchPlayerInfo]?
    let assist_eq2: [MatchPlayerInfo]?
    let offside_eq1: [MatchPlayerInfo]?
    let offside_eq2: [MatchPlayerInfo]?
    let corner_eq1: Int?
    let corner_eq2: Int?
    let penalty_eq1: Int?
    let penalty_eq2: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case id_equipe1
        case id_equipe2
        case id_terrain
        case id_arbitre
        case date
        case score_eq1
        case score_eq2
        case statut
        case round
        case nextMatch
        case positionInNextMatch
        case statistics
        case events
        case createdAt
        case updatedAt
        case cartonJaune
        case cartonRouge
        case But_eq1
        case But_eq2
        case assist_eq1
        case assist_eq2
        case offside_eq1
        case offside_eq2
        case corner_eq1
        case corner_eq2
        case penalty_eq1
        case penalty_eq2
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        
        // Handle id_equipe1 as object or string
        if let team1 = try? container.decode(MatchTeamInfo.self, forKey: .id_equipe1) {
            id_equipe1 = team1
        } else if let team1Id = try? container.decode(String.self, forKey: .id_equipe1) {
            id_equipe1 = MatchTeamInfo(_id: team1Id, nom: "Fetching...", logo: nil)
        } else {
            id_equipe1 = nil
        }
        
        // Handle id_equipe2 as object or string
        if let team2 = try? container.decode(MatchTeamInfo.self, forKey: .id_equipe2) {
            id_equipe2 = team2
        } else if let team2Id = try? container.decode(String.self, forKey: .id_equipe2) {
            id_equipe2 = MatchTeamInfo(_id: team2Id, nom: "Fetching...", logo: nil)
        } else {
            id_equipe2 = nil
        }
        id_terrain = try? container.decode(MatchStadiumInfo.self, forKey: .id_terrain)
        id_arbitre = try? container.decode(MatchRefereeInfo.self, forKey: .id_arbitre)
        
        // Handle date parsing
        if let dateString = try? container.decode(String.self, forKey: .date) {
            let formatter = ISO8601DateFormatter()
            date = formatter.date(from: dateString)
        } else {
            date = try? container.decode(Date.self, forKey: .date)
        }
        
        score_eq1 = (try? container.decode(Int.self, forKey: .score_eq1)) ?? 0
        score_eq2 = (try? container.decode(Int.self, forKey: .score_eq2)) ?? 0
        
        if let statusString = try? container.decode(String.self, forKey: .statut) {
            statut = MatchStatus(rawValue: statusString) ?? .SCHEDULED
        } else {
            statut = .SCHEDULED
        }
        
        round = try container.decode(Int.self, forKey: .round)
        nextMatch = try? container.decode(String.self, forKey: .nextMatch)
        positionInNextMatch = try? container.decode(String.self, forKey: .positionInNextMatch)
        statistics = try? container.decode(MatchStatistics.self, forKey: .statistics)
        events = try? container.decode([MatchEvent].self, forKey: .events)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
        
        cartonJaune = try? container.decode([MatchPlayerInfo].self, forKey: .cartonJaune)
        cartonRouge = try? container.decode([MatchPlayerInfo].self, forKey: .cartonRouge)
        But_eq1 = try? container.decode([MatchPlayerInfo].self, forKey: .But_eq1)
        But_eq2 = try? container.decode([MatchPlayerInfo].self, forKey: .But_eq2)
        assist_eq1 = try? container.decode([MatchPlayerInfo].self, forKey: .assist_eq1)
        assist_eq2 = try? container.decode([MatchPlayerInfo].self, forKey: .assist_eq2)
        offside_eq1 = try? container.decode([MatchPlayerInfo].self, forKey: .offside_eq1)
        offside_eq2 = try? container.decode([MatchPlayerInfo].self, forKey: .offside_eq2)
        corner_eq1 = try? container.decode(Int.self, forKey: .corner_eq1)
        corner_eq2 = try? container.decode(Int.self, forKey: .corner_eq2)
        penalty_eq1 = try? container.decode(Int.self, forKey: .penalty_eq1)
        penalty_eq2 = try? container.decode(Int.self, forKey: .penalty_eq2)
    }
    
    // Memberwise initializer
    init(id: String, id_equipe1: MatchTeamInfo?, id_equipe2: MatchTeamInfo?, id_terrain: MatchStadiumInfo?, id_arbitre: MatchRefereeInfo?, date: Date?, score_eq1: Int, score_eq2: Int, statut: MatchStatus, round: Int, nextMatch: String?, positionInNextMatch: String?, statistics: MatchStatistics?, events: [MatchEvent]?, createdAt: String?, updatedAt: String?, cartonJaune: [MatchPlayerInfo]? = nil, cartonRouge: [MatchPlayerInfo]? = nil, But_eq1: [MatchPlayerInfo]? = nil, But_eq2: [MatchPlayerInfo]? = nil, assist_eq1: [MatchPlayerInfo]? = nil, assist_eq2: [MatchPlayerInfo]? = nil, offside_eq1: [MatchPlayerInfo]? = nil, offside_eq2: [MatchPlayerInfo]? = nil, corner_eq1: Int? = nil, corner_eq2: Int? = nil, penalty_eq1: Int? = nil, penalty_eq2: Int? = nil) {
        self.id = id
        self.id_equipe1 = id_equipe1
        self.id_equipe2 = id_equipe2
        self.id_terrain = id_terrain
        self.id_arbitre = id_arbitre
        self.date = date
        self.score_eq1 = score_eq1
        self.score_eq2 = score_eq2
        self.statut = statut
        self.round = round
        self.nextMatch = nextMatch
        self.positionInNextMatch = positionInNextMatch
        self.statistics = statistics
        self.events = events
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cartonJaune = cartonJaune
        self.cartonRouge = cartonRouge
        self.But_eq1 = But_eq1
        self.But_eq2 = But_eq2
        self.assist_eq1 = assist_eq1
        self.assist_eq2 = assist_eq2
        self.offside_eq1 = offside_eq1
        self.offside_eq2 = offside_eq2
        self.corner_eq1 = corner_eq1
        self.corner_eq2 = corner_eq2
        self.penalty_eq1 = penalty_eq1
        self.penalty_eq2 = penalty_eq2
    }
}

// MARK: - Update Match Score Request

struct UpdateMatchScoreRequest: Codable {
    let score_eq1: Int
    let score_eq2: Int
    let statut: MatchStatus?
}

// MARK: - API Response Wrappers

struct MatchDetailResponse: Codable {
    let match: MatchDetail
}

struct MatchListResponse: Codable {
    let matches: [MatchDetail]
}
