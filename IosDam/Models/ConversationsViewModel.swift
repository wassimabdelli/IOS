//
//  ConversationsViewModel.swift
//  fakhripeakplay
//
//  ViewModel for Conversations List Screen
//

import Foundation
import Combine

enum Resource<T: Equatable>: Equatable {
    case idle
    case loading
    case success(T)
    case error(String)
    
    static func == (lhs: Resource<T>, rhs: Resource<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.success(let lhsValue), .success(let rhsValue)):
            return lhsValue == rhsValue
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Empty Equatable Type for Void-like operations
struct EmptyEquatable: Equatable {
    // Empty struct to use with Resource when no data is returned
}

class ConversationsViewModel: ObservableObject {
    @Published var conversations: Resource<[Conversation]> = .idle
    @Published var currentUserId: String?
    
    private let chatApiService = ChatApiService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load current user ID from UserDefaults
        loadUserIdFromUserDefaults()
    }
    
    private func loadUserIdFromUserDefaults() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            self.currentUserId = user._id
            print("✅ ConversationsViewModel: userId chargé depuis UserDefaults: \(user._id)")
        } else {
            print("⚠️ ConversationsViewModel: Aucun utilisateur trouvé dans UserDefaults")
            print("⚠️ Clés disponibles dans UserDefaults: \(UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.contains("user") || $0.contains("current") })")
        }
    }
    
    func refreshUserId() {
        loadUserIdFromUserDefaults()
    }
    
    func loadConversations(userId: String) {
        print("📱 ConversationsViewModel: Chargement des conversations pour userId: \(userId)")
        conversations = .loading
        
        chatApiService.getConversations(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ ConversationsViewModel: \(response.count) conversations reçues")
                    
                    // Créer les conversations avec les IDs temporairement
                    let conversationsList = response.map { response in
                        Conversation(
                            otherUserId: response.otherUserId,
                            otherUserName: response.otherUserName,
                            lastMessage: response.lastMessage,
                            unreadCount: response.unreadCount
                        )
                    }
                    
                    // Mettre à jour immédiatement pour ne pas bloquer l'interface
                    self?.conversations = .success(conversationsList)
                    
                    // Charger les noms complets des utilisateurs en arrière-plan
                    self?.loadUserNames(for: conversationsList, originalResponse: response)
                    
                case .failure(let error):
                    let errorMessage = error.localizedDescription
                    print("❌ ConversationsViewModel: Erreur lors du chargement: \(errorMessage)")
                    print("❌ Type d'erreur: \(type(of: error))")
                    if let apiError = error as? ApiError {
                        print("❌ ApiError details: \(apiError)")
                    }
                    self?.conversations = .error(errorMessage)
                }
            }
        }
    }
    
    private func loadUserNames(for conversations: [Conversation], originalResponse: [ConversationResponse]) {
        print("👤 ConversationsViewModel: Chargement des noms complets pour \(conversations.count) utilisateurs")
        
        let group = DispatchGroup()
        var updatedConversations = conversations
        
        for (index, conversation) in conversations.enumerated() {
            let otherUserId = conversation.otherUserId
            
            group.enter()
            APIService.getUserProfile(userId: otherUserId) { result in
                defer { group.leave() }
                
                switch result {
                case .success(let user):
                    let fullName = "\(user.prenom) \(user.nom)"
                    print("✅ ConversationsViewModel: Nom récupéré pour \(otherUserId): \(fullName)")
                    
                    DispatchQueue.main.async {
                        let response = originalResponse[index]
                        updatedConversations[index] = Conversation(
                            otherUserId: response.otherUserId,
                            otherUserName: fullName,
                            lastMessage: response.lastMessage,
                            unreadCount: response.unreadCount
                        )
                    }
                    
                case .failure(let error):
                    print("⚠️ ConversationsViewModel: Erreur lors de la récupération du nom pour \(otherUserId): \(error.localizedDescription)")
                    // Garde le nom existant (probablement l'ID) en cas d'erreur
                }
            }
        }
        
        group.notify(queue: .main) {
            print("✅ ConversationsViewModel: Tous les noms complets chargés")
            self.conversations = .success(updatedConversations)
        }
    }
    
    func refresh() {
        refreshUserId()
        guard let userId = currentUserId else {
            print("⚠️ Aucun userId trouvé dans UserDefaults")
            conversations = .error("Aucun utilisateur connecté")
            return
        }
        loadConversations(userId: userId)
    }
    
    func addOrUpdateConversation(message: Message, currentUserId: String) {
        guard case .success(var currentList) = conversations else {
            conversations = .success([Conversation(
                otherUserId: message.senderId == currentUserId ? message.receiverId : message.senderId,
                otherUserName: nil,
                lastMessage: message,
                unreadCount: message.receiverId == currentUserId && !message.isRead ? 1 : 0
            )])
            return
        }
        
        let otherUserId = message.senderId == currentUserId ? message.receiverId : message.senderId
        let existingIndex = currentList.firstIndex { $0.otherUserId == otherUserId }
        
        if let index = existingIndex {
            let existing = currentList[index]
            currentList[index] = Conversation(
                otherUserId: existing.otherUserId,
                otherUserName: existing.otherUserName,
                lastMessage: message,
                unreadCount: message.receiverId == currentUserId && !message.isRead ? existing.unreadCount + 1 : existing.unreadCount
            )
        } else {
            currentList.append(Conversation(
                otherUserId: otherUserId,
                otherUserName: nil,
                lastMessage: message,
                unreadCount: message.receiverId == currentUserId && !message.isRead ? 1 : 0
            ))
        }
        
        // Sort by last message time
        currentList.sort { ($0.lastMessage?.createdAt ?? "") > ($1.lastMessage?.createdAt ?? "") }
        conversations = .success(currentList)
    }
}
