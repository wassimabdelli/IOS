//
//  ProfileModels.swift
//  IosDam
//
//  Profile data models

import Foundation

// User Profile
struct UserProfile: Codable {
    let name: String
    let handle: String
    let level: Int
    let wins: Int
    let losses: Int
    let winRate: String
    let goalsScored: Int
    let assists: Int
    let cleanSheets: Int
    let totalMatches: Int
    let favoriteStadium: String
    let memberSince: String
    let pictureURL: String?
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
}



// Achievement
struct Achievement: Identifiable {
    let id = UUID()
    let iconName: String
    let iconColor: String // hex color
    let title: String
    let description: String
    let unlocked: Bool
}

// Match Result
struct MatchResultProfile: Identifiable, Codable {
    let id: String
    let status: String // "W", "L", "D"
    let title: String
    let date: String
    let score: String
    
    enum CodingKeys: String, CodingKey {
        case id, status, title, date, score
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        status = try container.decode(String.self, forKey: .status)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)
        score = try container.decode(String.self, forKey: .score)
    }
    
    init(id: String = UUID().uuidString, status: String, title: String, date: String, score: String) {
        self.id = id
        self.status = status
        self.title = title
        self.date = date
        self.score = score
    }
}

// Mock Data
extension UserProfile {
    static let mock = UserProfile(
        name: "Alex Rodriguez",
        handle: "alexrod",
        level: 12,
        wins: 28,
        losses: 12,
        winRate: "62%",
        goalsScored: 84,
        assists: 32,
        cleanSheets: 15,
        totalMatches: 45,
        favoriteStadium: "Arena Sports Complex",
        memberSince: "January 2024",
        pictureURL: nil
    )
}

extension Achievement {
    static let mockAchievements = [
        Achievement(iconName: "star.fill", iconColor: "FF9800", title: "Hat Trick Hero", description: "Score 3 goals in one match", unlocked: true),
        Achievement(iconName: "flame.fill", iconColor: "FF9800", title: "Winning Streak", description: "Win 5 matches in a row", unlocked: true),
        Achievement(iconName: "star.fill", iconColor: "FF9800", title: "Tournament Champion", description: "Win a tournament", unlocked: true),
        Achievement(iconName: "star.circle.fill", iconColor: "4CAF50", title: "Perfect Season", description: "Win all league matches", unlocked: false)
    ]
}

extension MatchResultProfile {
    static let mockMatches = [
        MatchResultProfile(status: "W", title: "Champions Cup", date: "Nov 5", score: "3-1"),
        MatchResultProfile(status: "W", title: "Sunday League", date: "Nov 3", score: "2-0"),
        MatchResultProfile(status: "L", title: "Quick Match", date: "Nov 1", score: "1-2"),
        MatchResultProfile(status: "W", title: "Elite Knockout", date: "Oct 28", score: "4-2"),
        MatchResultProfile(status: "D", title: "Weekend Warriors", date: "Oct 25", score: "2-2")
    ]
}
