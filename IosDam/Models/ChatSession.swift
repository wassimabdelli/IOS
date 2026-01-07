//
//  ChatSession.swift
//  IosDam
//
//  Model for a chat session containing multiple messages

import Foundation

struct AIChatSession: Identifiable, Codable {
    let id: UUID
    var title: String
    let date: Date
    var messages: [AIChatMessage]
    var previewText: String
    
    init(id: UUID = UUID(), title: String, date: Date = Date(), messages: [AIChatMessage] = [], previewText: String = "") {
        self.id = id
        self.title = title
        self.date = date
        self.messages = messages
        self.previewText = previewText
    }
}

