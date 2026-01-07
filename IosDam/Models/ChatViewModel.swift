//
//  ChatViewModel.swift
//  fakhripeakplay
//
//  ViewModel for Chat Screen
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: Resource<[Message]> = .idle
    @Published var errorMessage: String?
    @Published var connectionState: String = "disconnected"
    
    private let chatApiService = ChatApiService()
    let currentUserId: String
    let otherUserId: String
    
    init(currentUserId: String, otherUserId: String) {
        self.currentUserId = currentUserId
        self.otherUserId = otherUserId
        loadConversation()
    }
    
    func loadConversation() {
        messages = .loading
        
        chatApiService.getMessages(userId: currentUserId, otherUserId: otherUserId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let messagesList):
                    self?.messages = .success(messagesList)
                case .failure(let error):
                    self?.messages = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func sendMessage(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Le backend nécessite senderId, receiverId et message
        let backendRequest = SendMessageBackendRequest(
            senderId: currentUserId,
            receiverId: otherUserId,
            message: text
        )
        
        chatApiService.sendMessage(request: backendRequest) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newMessage):
                    if case .success(var messagesList) = self?.messages {
                        messagesList.append(newMessage)
                        self?.messages = .success(messagesList)
                    } else {
                        self?.messages = .success([newMessage])
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
