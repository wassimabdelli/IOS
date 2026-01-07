//
//  Conversation.swift
//  fakhripeakplay
//
//  Conversation model for the conversation list
//

import Foundation

struct Conversation: Identifiable, Equatable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    let lastMessage: Message?
    let unreadCount: Int
    
    init(otherUserId: String, otherUserName: String? = nil, lastMessage: Message? = nil, unreadCount: Int = 0) {
        self.id = otherUserId
        self.otherUserId = otherUserId
        self.otherUserName = otherUserName ?? otherUserId
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
    }
    
    var lastMessageText: String {
        lastMessage?.message ?? "No messages"
    }
    
    var lastMessageTime: String {
        guard let createdAt = lastMessage?.createdAt,
              let date = ISO8601DateFormatter().date(from: createdAt) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

