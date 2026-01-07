//
//  ChatApiService.swift
//  fakhripeakplay
//
//  Chat API service
//

import Foundation

class ChatApiService {
    private let apiClient = ApiClient.shared
    
    func getConversations(userId: String, completion: @escaping (Result<[ConversationResponse], Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/conversations/\(userId)",
            method: "GET",
            body: nil,
            responseType: [ConversationResponse].self,
            completion: completion
        )
    }
    
    func getMessages(userId: String, otherUserId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/\(userId)/\(otherUserId)",
            method: "GET",
            body: nil,
            responseType: [Message].self,
            completion: completion
        )
    }
    
    func sendMessage(request: SendMessageBackendRequest, completion: @escaping (Result<Message, Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/send",
            method: "POST",
            body: request,
            responseType: Message.self,
            completion: completion
        )
    }
    
    func markAsRead(messageId: String, completion: @escaping (Result<Message, Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/read/\(messageId)",
            method: "PATCH",
            body: nil,
            responseType: Message.self,
            completion: completion
        )
    }
    
    // Group chat
    func getGroup(groupId: String, completion: @escaping (Result<ChatGroup, Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/groups/\(groupId)",
            method: "GET",
            body: nil,
            responseType: ChatGroup.self,
            completion: completion
        )
    }
    
    func createGroup(request: CreateGroupRequest, completion: @escaping (Result<ChatGroup, Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/groups",
            method: "POST",
            body: request,
            responseType: ChatGroup.self,
            completion: completion
        )
    }
    
    func sendGroupMessage(groupId: String, request: SendGroupMessageRequest, completion: @escaping (Result<GroupMessage, Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/groups/\(groupId)/send",
            method: "POST",
            body: request,
            responseType: GroupMessage.self,
            completion: completion
        )
    }
    
    func addMemberToGroup(groupId: String, request: AddMemberRequest, completion: @escaping (Result<ChatGroup, Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/groups/\(groupId)/members",
            method: "POST",
            body: request,
            responseType: ChatGroup.self,
            completion: completion
        )
    }
    
    func getGroupMessages(groupId: String, completion: @escaping (Result<[GroupMessage], Error>) -> Void) {
        apiClient.request(
            endpoint: "chat/groups/\(groupId)/messages",
            method: "GET",
            body: nil,
            responseType: [GroupMessage].self,
            completion: completion
        )
    }
}

struct ConversationResponse: Codable {
    let otherUserId: String
    let otherUserName: String?
    let lastMessage: Message?
    let unreadCount: Int
}

struct EmptyResponse: Codable {}
