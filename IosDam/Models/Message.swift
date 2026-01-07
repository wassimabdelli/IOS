//
//  Message.swift
//  fakhripeakplay
//
//  Message data model matching backend structure
//

import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let senderId: String
    let receiverId: String
    let message: String
    let isRead: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case senderId
        case receiverId
        case message
        case isRead
        case createdAt
        case updatedAt
    }
}

