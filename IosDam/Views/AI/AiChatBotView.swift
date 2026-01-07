//
//  AiChatBotView.swift
//  IosDam
//
//  AI Assistant Chat Interface - iOS 14.3 Compatible

import SwiftUI

struct AiChatBotView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var user: UserModel?
    
    var body: some View {
        ZStack {
            // Dark Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Decorative wavy lines in background
            GeometryReader { geometry in
                Image(systemName: "waveform.path")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .foregroundColor(Color.white.opacity(0.05))
                    .position(x: geometry.size.width - 80, y: 100)
            }
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Greeting
                        greetingSection
                        
                        // Action Cards
                        actionCardsSection
                        
                        // History Section
                        historySection
                        
                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUser()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 16) {
            // Back Button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.white)
            }
            
            // User Avatar
            if let picture = user?.picture, !picture.isEmpty {
                AsyncAvatarImage(urlString: picture)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.6))
                    )
            }
            
            // Greeting Text
            Text("Hi, \(user?.prenom ?? "User")~ 👋")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.white)
            
            Spacer()
            
            // Bot Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "C4FF61"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
    
    // MARK: - Greeting Section
    
    private var greetingSection: some View {
        Text("How may I help\nyou today?")
            .font(.system(size: 34, weight: .semibold))
            .foregroundColor(Color(hex: "C4FF61"))
            .lineSpacing(4)
    }
    
    // MARK: - Action Cards
    
    private var actionCardsSection: some View {
        HStack(spacing: 12) {
            // Large "Talk with Bot" card - Navigate to Voice Chat
            NavigationLink(destination: AiVoiceChatBotView()) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.black.opacity(0.7))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("Talk\nwith Bot")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.8))
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "C4FF61"))
                        .shadow(color: Color(hex: "C4FF61").opacity(0.6), radius: 20, x: 0, y: 10)
                )
            }
            
            // Right side cards
            VStack(spacing: 12) {
                // "Chat with Bot" card - Navigate to Text Chat
                NavigationLink(destination: GeminiChatView()) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.black.opacity(0.6))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Text("Chat with Bot")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, minHeight: 94)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "C4B5F8"))
                            .shadow(color: Color(hex: "C4B5F8").opacity(0.5), radius: 15, x: 0, y: 8)
                    )
                }
                
                // "Search by Image" card -Navigate to Text Chat
                NavigationLink(destination: GeminiChatView()) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.black.opacity(0.6))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.black.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Text("Search by Image")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, minHeight: 94)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "FFB5D5"))
                            .shadow(color: Color(hex: "FFB5D5").opacity(0.5), radius: 15, x: 0, y: 8)
                    )
                }
            }
        }
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.white)
                
                Spacer()
                
                if !ChatHistoryService.shared.sessions.isEmpty {
                    Text("See all")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.gray)
                }
            }
            
            // History Items
            if ChatHistoryService.shared.sessions.isEmpty {
                Text("No recent conversations")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(ChatHistoryService.shared.sessions.prefix(3)) { session in
                        NavigationLink(destination: GeminiChatView(existingSessionId: session.id)) {
                            HistoryItemRow(iconColor: "C4FF61", text: session.title)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
        .onAppear {
            ChatHistoryService.shared.loadSessions()
        }
    }
    
    // MARK: - Helper Functions
    
    func loadUser() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let decodedUser = try? JSONDecoder().decode(UserModel.self, from: userData) {
            user = decodedUser
        }
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let iconColor: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: iconColor).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: iconColor))
            }
            
            // Text
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.8))
            
            Spacer()
            
            // Menu button
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundColor(Color.gray)
                .rotationEffect(.degrees(90))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Async Avatar Image (iOS 14 compatible)

struct AsyncAvatarImage: View {
    let urlString: String
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    func loadImage() {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let loadedImage = UIImage(data: data) else {
                return
            }
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }.resume()
    }
}

// MARK: - Preview

struct AiChatBotView_Previews: PreviewProvider {
    static var previews: some View {
        AiChatBotView()
    }
}

    