//
//  ChatMessage.swift
//  IosDam
//
//  Model for AI chat messages

import Foundation

struct AIChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    var isLoading: Bool
    var hasError: Bool
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date(), isLoading: Bool = false, hasError: Bool = false) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.isLoading = isLoading
        self.hasError = hasError
    }
    
    // Create a loading message
    static func loadingMessage() -> AIChatMessage {
        AIChatMessage(text: "", isUser: false, isLoading: true)
    }
    
    // Create an error message
    static func errorMessage(text: String = "Sorry, I encountered an error. Please try again.") -> AIChatMessage {
        AIChatMessage(text: text, isUser: false, hasError: true)
    }
}

