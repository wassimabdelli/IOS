//
//  GeminiChatView.swift
//  IosDam
//
//  Full chat interface with AI API - iOS 14.3 Compatible

import SwiftUI
import Foundation

struct GeminiChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var messages: [AIChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    
    // Session management
    @State var currentSession: AIChatSession?
    var existingSessionId: UUID?
    
    var body: some View {
        ZStack {
            // Dark Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header
                chatHeader
                
                // Messages List
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(spacing: 16) {
                            ForEach(messages) { message in
                                AIMessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                        .onChange(of: messages.count) { _ in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Input Area
                inputArea
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadSession()
        }
    }
    
    // MARK: - Header
    
    private var chatHeader: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Assistant")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.white)
                Text("Powered by Groq AI")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "C4FF61"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black)
    }
    
    // MARK: - Input Area input
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            // Text Input
            HStack {
                TextField("Ask me anything...", text: $inputText)
                    .font(.system(size: 16))
                    .foregroundColor(Color.white)
                    .accentColor(Color(hex: "C4FF61"))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .disabled(isLoading)
            }
            .background(Color.white.opacity(0.1))
            .cornerRadius(24)
            
            // Send Button
            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(inputText.isEmpty ? Color.gray.opacity(0.3) : Color(hex: "C4FF61"))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: isLoading ? "stop.fill" : "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(inputText.isEmpty ? Color.gray : Color.black)
                        .rotationEffect(.degrees(45))
                }
            }
            .disabled(inputText.isEmpty && !isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black)
    }
    
    // MARK: - Send Message
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = AIChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        
        let prompt = inputText
        inputText = ""
        isLoading = true
        
        // Save session
        saveCurrentSession()
        
        // Add loading message
        let loadingMessage = AIChatMessage.loadingMessage()
        messages.append(loadingMessage)
        
        // Call AI API
        GrokAIService.shared.sendMessage(prompt: prompt) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                // Remove loading message
                if let index = messages.firstIndex(where: { $0.id == loadingMessage.id }) {
                    messages.remove(at: index)
                }
                
                switch result {
                case .success(let responseText):
                    let botMessage = AIChatMessage(text: responseText, isUser: false)
                    messages.append(botMessage)
                    saveCurrentSession()
                    
                case .failure(let error):
                    let errorMessage = AIChatMessage.errorMessage(text: error.localizedDescription)
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Session Management
    
    func loadSession() {
        if let sessionId = existingSessionId,
           let session = ChatHistoryService.shared.sessions.first(where: { $0.id == sessionId }) {
            self.currentSession = session
            self.messages = session.messages
        }
    }
    
    func saveCurrentSession() {
        if currentSession == nil {
            // Create new session
            let title = messages.first?.text.prefix(30) ?? "New Chat"
            let newSession = AIChatSession(title: String(title), messages: messages, previewText: messages.last?.text ?? "")
            currentSession = newSession
        } else {
            // Update existing session
            currentSession?.messages = messages
            currentSession?.previewText = messages.last?.text ?? ""
        }
        
        if let session = currentSession {
            ChatHistoryService.shared.saveSession(session)
        }
    }
}

// MARK: - AI Message Bubble View

struct AIMessageBubbleView: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            if message.isLoading {
                loadingBubble
            } else {
                messageBubble
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private var messageBubble: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .font(.system(size: 16))
                .foregroundColor(message.hasError ? Color.white.opacity(0.7) : Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.isUser ?
                    Color(hex: "C4FF61") :
                    (message.hasError ? Color.red.opacity(0.3) : Color.white.opacity(0.1))
                )
                .cornerRadius(20)
                .foregroundColor(message.isUser ? Color.black : Color.white)
        }
        .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
    }
    
    private var loadingBubble: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "C4FF61"))
                    .frame(width: 8, height: 8)
                    .opacity(0.6)
                    .scaleEffect(1.0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

// MARK: - Preview

struct GeminiChatView_Previews: PreviewProvider {
    static var previews: some View {
        GeminiChatView()
    }
}

