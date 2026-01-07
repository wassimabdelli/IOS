//
//  ChatHistoryService.swift
//  IosDam
//
//  Service for persisting chat history

import Foundation

class ChatHistoryService: ObservableObject {
    static let shared = ChatHistoryService()
    
    @Published var sessions: [AIChatSession] = []
    
    private let saveKey = "saved_chat_sessions"
    
    private init() {
        loadSessions()
    }
    
    // MARK: - Load Sessions
    
    func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([AIChatSession].self, from: data) {
                self.sessions = decoded.sorted(by: { $0.date > $1.date })
                return
            }
        }
        self.sessions = []
    }
    
    // MARK: - Save Session
    
    func saveSession(_ session: AIChatSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }
        persist()
    }
    
    // MARK: - Delete Session
    
    func deleteSession(id: UUID) {
        sessions.removeAll(where: { $0.id == id })
        persist()
    }
    
    // MARK: - Persistence
    
    private func persist() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}

