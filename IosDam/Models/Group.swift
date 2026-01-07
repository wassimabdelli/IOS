//
//  Group.swift
//  fakhripeakplay
//
//  Group chat models
//

import Foundation

struct ChatGroup: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let members: [GroupMember]?
    let messages: [GroupMessage]?
    let createdAt: String
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case members
        case messages
        case createdAt
        case updatedAt
    }
    
    // Initializer personnalisé pour gérer les cas où certains champs sont manquants
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        members = try container.decodeIfPresent([GroupMember].self, forKey: .members)
        messages = try container.decodeIfPresent([GroupMessage].self, forKey: .messages)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
    
    // Initializer manuel pour créer un ChatGroup
    init(id: String, name: String, description: String?, members: [GroupMember]?, messages: [GroupMessage]?, createdAt: String, updatedAt: String?) {
        self.id = id
        self.name = name
        self.description = description
        self.members = members
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct GroupMember: Codable, Identifiable {
    let id: String
    let userId: String
    let role: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case role
    }
}

struct GroupMessage: Codable, Identifiable, Equatable {
    let id: String
    let groupId: String
    let senderId: String
    let message: String
    let readBy: [String]
    let createdAt: String
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case groupId
        case senderId
        case message
        case readBy
        case createdAt
        case updatedAt
    }
    
    static func == (lhs: GroupMessage, rhs: GroupMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CreateGroupRequest: Codable {
    let name: String
    let description: String?
    let creatorId: String
    let groupId: String?
    let avatar: String?
}

struct SendGroupMessageRequest: Codable {
    let groupId: String
    let senderId: String
    let message: String
}

struct AddMemberRequest: Codable {
    let userId: String
}

struct SendMessageRequest: Codable {
    let receiverId: String
    let message: String
}

struct SendMessageBackendRequest: Codable {
    let senderId: String
    let receiverId: String
    let message: String
}

struct MarkReadRequest: Codable {
    let messageIds: [String]
}

