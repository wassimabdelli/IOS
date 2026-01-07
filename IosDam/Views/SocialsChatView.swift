//
//  SocialsChatView.swift
//  IosDam
//
//  Created by macbook on 1/12/2025.
//

import SwiftUI

// MARK: - Social Stats Model
struct ConversationListView: View {
    @ObservedObject var viewModel: ConversationsViewModel
    let currentUserId: String?
    @Binding var selectedConversationId: String?
    let onConversationClick: (String) -> Void
    let onGroupChatClick: ((String) -> Void)?
    var onBackClick: (() -> Void)? = nil
    
    @State private var showGroupDialog = false
    @State private var groupIdText = ""
    @State private var showCreateGroupDialog = false
    @State private var groupNameText = ""
    @State private var groupDescriptionText = ""
    @State private var isCreatingGroup = false
    @State private var showLogoutAlert = false
    @State private var showNewMessageDialog = false
    @State private var receiverIdText = ""
    @State private var messageText = ""
    @State private var isSendingMessage = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var hasLoaded = false
    
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                if let onBack = onBackClick {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                Text("Message")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Button(action: { showNewMessageDialog = true }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                
                Menu {
                    Button(action: { showCreateGroupDialog = true }) {
                        Label("Créer un groupe", systemImage: "plus.circle")
                    }
                    
                    if onGroupChatClick != nil {
                        Button(action: { showGroupDialog = true }) {
                            Label("Rejoindre un groupe", systemImage: "person.2.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            
            // Search Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                    
                    TextField("Search Anything", text: $searchText)
                        .font(.system(size: 15))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            contentView
        }
        .navigationBarHidden(true)
        .onAppear {
            // Charger les conversations au démarrage (une seule fois)
            guard !hasLoaded else {
                print("⏭️ ConversationListView: Déjà chargé, onAppear ignoré")
                return
            }
            
            print("📱 ConversationListView: onAppear appelé")
            print("🔧 Configuration serveur: \(Config.REST_BASE_URL)")
            hasLoaded = true
            viewModel.refreshUserId()
            if let userId = viewModel.currentUserId {
                print("✅ ConversationListView: userId trouvé: \(userId)")
                viewModel.loadConversations(userId: userId)
            } else {
                print("⚠️ ConversationListView: Aucun userId trouvé dans UserDefaults")
                viewModel.conversations = .error("Aucun utilisateur connecté. Veuillez vous connecter d'abord.")
            }
        }
        .onDisappear {
            // Réinitialiser le flag quand on quitte la vue
            hasLoaded = false
        }
        .sheet(isPresented: $showGroupDialog) {
            JoinGroupDialogView(
                groupIdText: $groupIdText,
                onJoin: {
                    let trimmedGroupId = groupIdText.trimmingCharacters(in: .whitespaces)
                    if !trimmedGroupId.isEmpty {
                        print("🔍 Tentative de rejoindre le groupe: \(trimmedGroupId)")
                        showGroupDialog = false
                        groupIdText = ""
                        onGroupChatClick?(trimmedGroupId)
                    } else {
                        errorMessage = "Veuillez entrer un ID de groupe valide"
                        showErrorAlert = true
                    }
                },
                onCancel: {
                    showGroupDialog = false
                    groupIdText = ""
                }
            )
        }
        .sheet(isPresented: $showCreateGroupDialog) {
            CreateGroupDialogView(
                groupNameText: $groupNameText,
                groupDescriptionText: $groupDescriptionText,
                isCreating: $isCreatingGroup,
                onCreate: {
                    createGroup()
                },
                onCancel: {
                    showCreateGroupDialog = false
                    groupNameText = ""
                    groupDescriptionText = ""
                }
            )
        }
        .sheet(isPresented: $showNewMessageDialog) {
            NewMessageDialogView(
                receiverIdText: $receiverIdText,
                messageText: $messageText,
                isSending: $isSendingMessage,
                onSend: {
                    sendNewMessage()
                },
                onCancel: {
                    showNewMessageDialog = false
                    receiverIdText = ""
                    messageText = ""
                }
            )
        }
        .alert(isPresented: $showLogoutAlert) {
            Alert(
                title: Text("Déconnexion"),
                message: Text("Voulez-vous vous déconnecter et revenir à l'écran de connexion ?"),
                primaryButton: .destructive(Text("Déconnecter")) {
                    // Logout handled by HomeView
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Erreur"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.conversations {
        case .idle, .loading:
            loadingView
        case .success(let conversations):
            if conversations.isEmpty {
                emptyStateView
            } else {
                conversationsListView(conversations)
            }
        case .error(let message):
            errorView(message: message)
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "message.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.blue.opacity(0.5))
            
            Text("Aucune conversation")
                .font(.headline)
            
            Text("Envoyez un message à un autre utilisateur pour commencer")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showNewMessageDialog = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Nouveau message")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 8)
            Spacer()
        }
    }
    
    private func conversationsListView(_ conversations: [Conversation]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Active Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(conversations.prefix(6)) { conversation in
                                if let currentUserId = currentUserId {
                                    NavigationLink(
                                        destination: ChatView(
                                            viewModel: ChatViewModel(
                                                currentUserId: currentUserId,
                                                otherUserId: conversation.otherUserId
                                            ),
                                            otherUserName: conversation.otherUserName,
                                            onBackClick: {
                                                selectedConversationId = nil
                                            }
                                        )
                                    ) {
                                        activeConversationAvatar(for: conversation)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    Button(action: {
                                        onConversationClick(conversation.otherUserId)
                                    }) {
                                        activeConversationAvatar(for: conversation)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
                
                // Messages Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Messages")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
                        ForEach(filteredConversations(conversations)) { conversation in
                            ModernConversationItemView(
                                conversation: conversation,
                                currentUserId: currentUserId,
                                selectedConversationId: $selectedConversationId,
                                onClick: {
                                    onConversationClick(conversation.otherUserId)
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func filteredConversations(_ conversations: [Conversation]) -> [Conversation] {
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
                conversation.otherUserName.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessageText.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func activeConversationAvatar(for conversation: Conversation) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.5, green: 0.4, blue: 0.9),
                                Color(red: 0.7, green: 0.3, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Text(String(conversation.otherUserName.prefix(1)).uppercased())
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 64, height: 64)
                
                // Online indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: -2, y: 2)
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.orange)
            
            Text("Erreur")
                .font(.headline)
                .foregroundColor(Color.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Afficher des informations de débogage si nécessaire
            if message.contains("connect") || message.contains("server") || message.contains("connexion") {
                VStack(spacing: 8) {
                    Text("Vérifiez que:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.secondary)
                    Text("• Le serveur est démarré")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                    Text("• L'URL est correcte dans Config.swift")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                    Text("• Votre connexion internet fonctionne")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button("Réessayer") {
                viewModel.refresh()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            Spacer()
        }
    }
    
    private func createGroup() {
        print("🔘 Fonction createGroup appelée")
        print("📋 État actuel:")
        print("   - Nom du groupe: '\(groupNameText)'")
        print("   - Description: '\(groupDescriptionText)'")
        print("   - User ID: '\(viewModel.currentUserId ?? "nil")'")
        print("   - Nom vide: \(groupNameText.isEmpty)")
        
        guard let currentUserId = viewModel.currentUserId else {
            errorMessage = "Aucun utilisateur connecté"
            showErrorAlert = true
            return
        }
        
        guard !groupNameText.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("❌ Nom du groupe vide")
            errorMessage = "Veuillez entrer un nom pour le groupe."
            showErrorAlert = true
            return
        }
        
        isCreatingGroup = true
        print("✅ Démarrage de la création du groupe...")
        
        let trimmedName = groupNameText.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = groupDescriptionText.trimmingCharacters(in: .whitespaces)
        
        let request = CreateGroupRequest(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            creatorId: currentUserId,
            groupId: nil,
            avatar: nil
        )
        
        print("📤 Envoi de la requête de création de groupe:")
        print("   - Name: '\(request.name)'")
        print("   - Description: '\(request.description ?? "nil")'")
        print("   - Creator ID: '\(request.creatorId)'")
        
        ChatApiService().createGroup(request: request) { result in
            switch result {
            case .success(let group):
                print("✅ Groupe créé avec succès!")
                print("   - Group ID: '\(group.id)'")
                print("   - Group Name: '\(group.name)'")
                
                DispatchQueue.main.async {
                    // Fermer le dialogue
                    self.showCreateGroupDialog = false
                    self.groupNameText = ""
                    self.groupDescriptionText = ""
                    self.isCreatingGroup = false
                    
                    // Ouvrir le groupe créé
                    if let onGroupClick = self.onGroupChatClick {
                        onGroupClick(group.id)
                    }
                }
            case .failure(let error):
                print("❌ Erreur lors de la création du groupe:")
                print("   - Type: \(type(of: error))")
                print("   - Message: \(error.localizedDescription)")
                if let apiError = error as? ApiError {
                    print("   - API Error: \(apiError.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    self.isCreatingGroup = false
                    let errorMsg = (error as? ApiError)?.localizedDescription ?? error.localizedDescription
                    self.errorMessage = errorMsg
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func sendNewMessage() {
        guard let currentUserId = viewModel.currentUserId else {
            errorMessage = "Aucun utilisateur connecté"
            showErrorAlert = true
            return
        }
        
        guard !receiverIdText.isEmpty,
              !messageText.isEmpty else {
            return
        }
        
        isSendingMessage = true
        
        let request = SendMessageBackendRequest(
            senderId: currentUserId,
            receiverId: receiverIdText.trimmingCharacters(in: .whitespaces),
            message: messageText.trimmingCharacters(in: .whitespaces)
        )
        
        ChatApiService().sendMessage(request: request) { result in
            switch result {
            case .success(let message):
                DispatchQueue.main.async {
                    // Fermer le dialogue
                    self.showNewMessageDialog = false
                    self.receiverIdText = ""
                    self.messageText = ""
                    self.isSendingMessage = false
                    
                    // Rafraîchir la liste des conversations
                    self.viewModel.refresh()
                    
                    // Attendre un peu pour que la liste se mette à jour, puis ouvrir la conversation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let otherUserId = message.receiverId == currentUserId ? message.senderId : message.receiverId
                        self.onConversationClick(otherUserId)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isSendingMessage = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    print("❌ Erreur lors de l'envoi du message: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ConversationItemView: View {
    let conversation: Conversation
    let currentUserId: String?
    @Binding var selectedConversationId: String?
    let onClick: () -> Void
    
    var body: some View {
        Group {
            if let currentUserId = currentUserId {
                NavigationLink(
                    destination: ChatView(
                        viewModel: ChatViewModel(
                            currentUserId: currentUserId,
                            otherUserId: conversation.otherUserId
                        ),
                        otherUserName: conversation.otherUserName,
                        onBackClick: {
                            selectedConversationId = nil
                        }
                    )
                ) {
                    HStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 56, height: 56)
                            
                            Text(String(conversation.otherUserName.prefix(1)).uppercased())
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(conversation.otherUserName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(conversation.lastMessageTime)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(conversation.lastMessageText)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if conversation.unreadCount > 0 {
                                    Text("\(conversation.unreadCount)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                        .frame(minWidth: 20)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: onClick) {
                    HStack(spacing: 12) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 56, height: 56)
                            
                            Text(String(conversation.otherUserName.prefix(1)).uppercased())
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                        }
                        
                        // Content
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(conversation.otherUserName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(conversation.lastMessageTime)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text(conversation.lastMessageText)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if conversation.unreadCount > 0 {
                                    Text("\(conversation.unreadCount)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                        .frame(minWidth: 20)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Modern Conversation Item View
struct ModernConversationItemView: View {
    let conversation: Conversation
    let currentUserId: String?
    @Binding var selectedConversationId: String?
    let onClick: () -> Void
    
    var body: some View {
        Group {
            if let currentUserId = currentUserId {
                NavigationLink(
                    destination: ChatView(
                        viewModel: ChatViewModel(
                            currentUserId: currentUserId,
                            otherUserId: conversation.otherUserId
                        ),
                        otherUserName: conversation.otherUserName,
                        onBackClick: {
                            selectedConversationId = nil
                        }
                    )
                ) {
                    conversationContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: onClick) {
                    conversationContent
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var conversationContent: some View {
        HStack(spacing: 14) {
            // Avatar with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.5, green: 0.4, blue: 0.9),
                                Color(red: 0.7, green: 0.3, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Text(String(conversation.otherUserName.prefix(1)).uppercased())
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .semibold))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(conversation.lastMessageTime)
                        .font(.system(size: 13))
                        .foregroundColor(Color(.systemGray))
                }
                
                Text(conversation.lastMessageText)
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))
                    .lineLimit(1)
            }
        }
    }
}


struct NewMessageDialogView: View {
    @Binding var receiverIdText: String
    @Binding var messageText: String
    @Binding var isSending: Bool
    let onSend: () -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    @State private var searchResults: [UserModel] = []
    @State private var isSearching = false
    @State private var selectedUser: UserModel? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search bar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Destinataire")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Rechercher un utilisateur...", text: $searchText)
                            .onChange(of: searchText) { newValue in
                                if newValue.isEmpty {
                                    searchResults = []
                                    selectedUser = nil
                                } else {
                                    performSearch(query: newValue)
                                }
                            }
                            .disabled(isSending)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                                selectedUser = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if let user = selectedUser {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(user.prenom) \(user.nom)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Search results
                if isSearching {
                    ProgressView()
                        .padding()
                } else if !searchText.isEmpty && selectedUser == nil {
                    ScrollView {
                        VStack(spacing: 8) {
                            if searchResults.isEmpty {
                                Text("Aucun utilisateur trouvé")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                ForEach(searchResults, id: \._id) { user in
                                    Button(action: {
                                        selectedUser = user
                                        receiverIdText = user._id
                                        searchText = "\(user.prenom) \(user.nom)"
                                        searchResults = []
                                    }) {
                                        HStack {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(red: 0.5, green: 0.4, blue: 0.9),
                                                                Color(red: 0.7, green: 0.3, blue: 0.8)
                                                            ]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 44, height: 44)
                                                
                                                Text(String(user.prenom.prefix(1)).uppercased())
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 18, weight: .semibold))
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(user.prenom) \(user.nom)")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                Text(user.email)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                
                // Message input (only show if user is selected)
                if selectedUser != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            if messageText.isEmpty {
                                Text("Tapez votre message ici...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $messageText)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .disabled(isSending)
                        }
                    }
                }
                
                Spacer()
                
                // Buttons
                HStack(spacing: 16) {
                    Button("Annuler", action: onCancel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .disabled(isSending)
                    
                    Button(action: onSend) {
                        if isSending {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Envoi...")
                            }
                        } else {
                            Text("Envoyer")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(selectedUser == nil || messageText.isEmpty || isSending ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(selectedUser == nil || messageText.isEmpty || isSending)
                }
            }
            .padding()
            .navigationTitle("Nouveau message")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func performSearch(query: String) {
        isSearching = true
        
        // Try to search users - using searchAllUsers to search across all roles
        APIService.searchAllUsers(query: query) { result in
            DispatchQueue.main.async {
                isSearching = false
                switch result {
                case .success(let users):
                    searchResults = users
                case .failure(let error):
                    print("❌ Erreur lors de la recherche: \(error.localizedDescription)")
                    searchResults = []
                }
            }
        }
    }
}


struct CreateGroupDialogView: View {
    @Binding var groupNameText: String
    @Binding var groupDescriptionText: String
    @Binding var isCreating: Bool
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom du groupe")
                        .font(.headline)
                    
                    TextField("Ex: Équipe A, Groupe Projet...", text: $groupNameText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isCreating)
                    
                    Text("Le nom du groupe sera visible par tous les membres")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (optionnel)")
                        .font(.headline)
                    
                    ZStack(alignment: .topLeading) {
                        if groupDescriptionText.isEmpty {
                            Text("Ajoutez une description pour votre groupe...")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        
                        TextEditor(text: $groupDescriptionText)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .disabled(isCreating)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Annuler", action: onCancel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .disabled(isCreating)
                    
                    Button(action: {
                        print("🔘 Bouton 'Créer' cliqué dans CreateGroupDialogView")
                        print("   - Nom du groupe: '\(groupNameText)'")
                        print("   - Nom vide: \(groupNameText.isEmpty)")
                        print("   - Nom trimmed vide: \(groupNameText.trimmingCharacters(in: .whitespaces).isEmpty)")
                        print("   - Is creating: \(isCreating)")
                        if groupNameText.trimmingCharacters(in: .whitespaces).isEmpty {
                            print("⚠️ Le nom du groupe est vide, le bouton devrait être désactivé")
                        }
                        onCreate()
                    }) {
                        if isCreating {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Création...")
                            }
                        } else {
                            Text("Créer")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(groupNameText.trimmingCharacters(in: .whitespaces).isEmpty || isCreating ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(groupNameText.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .padding()
            .navigationTitle("Créer un groupe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct JoinGroupDialogView: View {
    @Binding var groupIdText: String
    let onJoin: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Rejoindre un groupe")
                    .font(.headline)
                
                Text("Entrez l'ID du groupe pour accéder au chat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Group ID", text: $groupIdText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                HStack(spacing: 16) {
                    Button("Annuler", action: onCancel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    
                    Button("Rejoindre", action: onJoin)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(groupIdText.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(groupIdText.isEmpty)
                }
            }
            .padding()
            .navigationTitle("Rejoindre un groupe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - SocialsChatView Wrapper
struct SocialsChatView: View {
    @StateObject private var viewModel = ConversationsViewModel()
    @State private var selectedConversationId: String? = nil
    @State private var selectedGroupId: String? = nil
    
    var body: some View {
        NavigationView {
            ConversationListView(
                viewModel: viewModel,
                currentUserId: viewModel.currentUserId,
                selectedConversationId: $selectedConversationId,
                onConversationClick: { userId in
                    selectedConversationId = userId
                },
                onGroupChatClick: { groupId in
                    selectedGroupId = groupId
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
