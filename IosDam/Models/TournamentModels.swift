//
// TournamentModels.swift
// IosDam
//
// Tournament/Event data models

import Foundation

// MARK: - Organizer

struct Organizer: Codable, Identifiable {
    let id: String
    let nom: String?
    let prenom: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nom
        case prenom
    }
}

// MARK: - Match

// Robust team info for bracket
struct BracketTeamInfo: Codable {
    let _id: String?
    let id: String?
    let nom: String?
    let name: String?
    let logo: String?
    
    var displayName: String {
        return nom ?? name ?? "Team"
    }
    
    // Custom decoding to handle various cases
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let idStr = try? container.decode(String.self, forKey: ._id) {
            _id = idStr
        } else if let idObj = try? container.decode([String: String].self, forKey: ._id) {
            _id = idObj["$oid"] ?? idObj["_id"] ?? idObj["id"]
        } else {
            _id = nil
        }
        
        if let idStr2 = try? container.decode(String.self, forKey: .id) {
            id = idStr2
        } else if let idObj2 = try? container.decode([String: String].self, forKey: .id) {
            id = idObj2["$oid"] ?? idObj2["_id"] ?? idObj2["id"]
        } else {
            id = nil
        }
        nom = try? container.decode(String.self, forKey: .nom)
        name = try? container.decode(String.self, forKey: .name)
        logo = try? container.decode(String.self, forKey: .logo)
    }
    
    init(id: String, name: String) {
        self._id = id
        self.id = id
        self.nom = name
        self.name = name
        self.logo = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case _id, id, nom, name, logo
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: ._id)
        try container.encode(nom, forKey: .nom)
    }
}

struct Match: Codable, Identifiable {
    let id: String
    let idEquipe1: BracketTeamInfo?
    let idEquipe2: BracketTeamInfo?
    let scoreEq1: Int?
    let scoreEq2: Int?
    let date: Date?
    let status: MatchStatus?
    let round: Int?
    let matchNumber: Int?
    let nextMatchId: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case idEquipe1 = "id_equipe1"
        case idEquipe2 = "id_equipe2"
        case scoreEq1 = "score_eq1"
        case scoreEq2 = "score_eq2"
        case date
        case status
        case round
        case matchNumber
        case nextMatchId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        // Flexible decoding for Team 1
        if let teamInfo = try? container.decode(BracketTeamInfo.self, forKey: .idEquipe1) {
            idEquipe1 = teamInfo
        } else if let teamId = try? container.decode(String.self, forKey: .idEquipe1) {
            idEquipe1 = BracketTeamInfo(id: teamId, name: "Team")
        } else if let obj = try? container.decode([String: String].self, forKey: .idEquipe1),
                  let oid = obj["$oid"] {
            idEquipe1 = BracketTeamInfo(id: oid, name: "Team")
        } else {
            idEquipe1 = nil
        }
        
        // Flexible decoding for Team 2
        if let teamInfo = try? container.decode(BracketTeamInfo.self, forKey: .idEquipe2) {
            idEquipe2 = teamInfo
        } else if let teamId = try? container.decode(String.self, forKey: .idEquipe2) {
            idEquipe2 = BracketTeamInfo(id: teamId, name: "Team")
        } else if let obj = try? container.decode([String: String].self, forKey: .idEquipe2),
                  let oid = obj["$oid"] {
            idEquipe2 = BracketTeamInfo(id: oid, name: "Team")
        } else {
            idEquipe2 = nil
        }
        
        scoreEq1 = try? container.decode(Int.self, forKey: .scoreEq1)
        scoreEq2 = try? container.decode(Int.self, forKey: .scoreEq2)
        
        if let dateString = try? container.decode(String.self, forKey: .date) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            date = formatter.date(from: dateString)
        } else {
            date = nil
        }
        
        status = try? container.decode(MatchStatus.self, forKey: .status)
        round = try? container.decode(Int.self, forKey: .round)
        matchNumber = try? container.decode(Int.self, forKey: .matchNumber)
        nextMatchId = try? container.decode(String.self, forKey: .nextMatchId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(idEquipe1, forKey: .idEquipe1)
        try container.encode(idEquipe2, forKey: .idEquipe2)
        try container.encode(scoreEq1, forKey: .scoreEq1)
        try container.encode(scoreEq2, forKey: .scoreEq2)
        
        if let date = date {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: date)
            try container.encode(dateString, forKey: .date)
        }
        
        try container.encode(status, forKey: .status)
        try container.encode(round, forKey: .round)
        try container.encode(matchNumber, forKey: .matchNumber)
        try container.encode(nextMatchId, forKey: .nextMatchId)
    }
}

// MARK: - Tournament/Coupe

struct Tournament: Codable, Identifiable {
    let id: String
    let nom: String
    let tournamentName: String
    let participants: [ParticipantID]
    let dateDebut: Date
    let dateFin: Date
    let stadium: String
    let date: Date
    let time: String
    let maxParticipants: Int
    let entryFee: Int?
    let prizePool: Int?
    let referee: [String]
    let categorie: String
    let type: String
    let idOrganisateur: Organizer?
    let matches: [Match]?
    let matchIds: [ParticipantID]?
    let isBracketGenerated: Bool
    let currentRound: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nom
        case tournamentName
        case participants
        case dateDebut = "date_debut"
        case dateFin = "date_fin"
        case stadium
        case date
        case time
        case maxParticipants
        case entryFee
        case prizePool
        case referee
        case categorie
        case type
        case idOrganisateur = "id_organisateur"
        case matches
        case isBracketGenerated
        case currentRound
    }
    
    // Custom initializer to provide defaults for optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        nom = try container.decode(String.self, forKey: .nom)
        tournamentName = try container.decode(String.self, forKey: .tournamentName)
        participants = try container.decode([ParticipantID].self, forKey: .participants)
        
        // Decode dates - handle both ISO8601 strings and Date objects
        let dateFormatter = ISO8601DateFormatter()
        
        if let dateDebutString = try? container.decode(String.self, forKey: .dateDebut),
           let parsedDate = dateFormatter.date(from: dateDebutString) {
            dateDebut = parsedDate
        } else {
            dateDebut = try container.decode(Date.self, forKey: .dateDebut)
        }
        
        if let dateFinString = try? container.decode(String.self, forKey: .dateFin),
           let parsedDate = dateFormatter.date(from: dateFinString) {
            dateFin = parsedDate
        } else {
            dateFin = try container.decode(Date.self, forKey: .dateFin)
        }
        
        if let dateString = try? container.decode(String.self, forKey: .date),
           let parsedDate = dateFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            date = try container.decode(Date.self, forKey: .date)
        }
        
        stadium = try container.decode(String.self, forKey: .stadium)
        time = try container.decode(String.self, forKey: .time)
        maxParticipants = try container.decode(Int.self, forKey: .maxParticipants)
        entryFee = try? container.decode(Int.self, forKey: .entryFee)
        prizePool = try? container.decode(Int.self, forKey: .prizePool)
        referee = (try? container.decode([String].self, forKey: .referee)) ?? []
        categorie = try container.decode(String.self, forKey: .categorie)
        type = try container.decode(String.self, forKey: .type)
        idOrganisateur = try? container.decode(Organizer.self, forKey: .idOrganisateur)
        matches = try? container.decode([Match].self, forKey: .matches)
        matchIds = try? container.decode([ParticipantID].self, forKey: .matches)
        isBracketGenerated = (try? container.decode(Bool.self, forKey: .isBracketGenerated)) ?? false
        currentRound = try? container.decode(Int.self, forKey: .currentRound)
    }
}

// MARK: - Participant ID (can be string or object with $oid)

enum ParticipantID: Codable {
    case string(String)
    case object([String: String])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let obj = try? container.decode([String: String].self) {
            self = .object(obj)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid participant ID format")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .object(let obj):
            try container.encode(obj)
        }
    }
    
    var stringValue: String? {
        switch self {
        case .string(let str):
            return str
        case .object(let obj):
            return obj["$oid"] ?? obj["_id"] ?? obj["id"]
        }
    }
}

// MARK: - Add Participant Request

struct AddParticipantRequest: Codable {
    let userId: String
}

// MARK: - Participant Name Response

struct ParticipantNameResponse: Codable {
    let exists: Bool?
}
