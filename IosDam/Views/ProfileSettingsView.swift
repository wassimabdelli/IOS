//
//  ProfileSettingsView.swift
//  IosDam
//
//  Profile Settings screen matching Android design - Xcode 12.3 Compatible

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutDialog = false
    @State private var darkTheme = false
    @State private var dataSaver = false
    @State private var currentUserRole: String? = nil
    @State private var isLoggedOut = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            customNavigationBar
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Card
                    ProfileCardSettings()
                    
                    // Account Settings
                    SettingsSectionView(
                        title: "Account Settings",
                        items: accountSettingsItems
                    )
                    
                    // Support & About - Masqué car vide
                    if !supportAboutItems.isEmpty {
                        SettingsSectionView(
                            title: "Support & About",
                            items: supportAboutItems
                        )
                    }
                    
                    // Cache & Cellular - Masqué car vide
                    if !cacheCellularItems.isEmpty {
                        SettingsSectionView(
                            title: "Cache & cellular",
                            items: cacheCellularItems
                        )
                    }
                    
                    // Actions
                    SettingsSectionView(
                        title: "Actions",
                        items: actionsItems,
                        onItemTap: handleItemTap
                    )
                    
                    Spacer().frame(height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadUserRole)
        .fullScreenCover(isPresented: $isLoggedOut) {
            LoginView()
        }
        .alert(isPresented: $showLogoutDialog) {
            Alert(
                title: Text("End Session"),
                message: Text("Are you sure you want to log out?"),
                primaryButton: .destructive(Text("Yes, End Session")) {
                    performLogout()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    // MARK: - Custom Navigation Bar
    
    private var customNavigationBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Text("Profile")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            Button(action: {
                // Notifications action
            }) {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(Color(UIColor.label))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Settings Items
    
    private var accountSettingsItems: [SettingItem] {
        var items = [
            SettingItem(icon: "person", title: "Edit Profile", iconColor: "4CAF50", type: .navigation),
            SettingItem(icon: "cross.case", title: "Gestion des blessures", iconColor: "FF9800", type: .navigation),
            SettingItem(icon: "brain.head.profile", title: "Prédiction IA - Blessures", iconColor: "9C27B0", type: .navigation),
            SettingItem(icon: "leaf", title: "Régimes Alimentaire", iconColor: "4CAF50", type: .navigation)
        ]
        
        if currentUserRole == "OWNER" || currentUserRole == "COACH" {
            items.append(SettingItem(icon: "doc.text", title: "Negotiation", iconColor: "673AB7", type: .navigation))
        }
        
        if currentUserRole == "OWNER" {
            items.append(SettingItem(icon: "person.badge.plus", title: "Recruter arbitre", iconColor: "4CAF50", type: .navigation))
            items.append(SettingItem(icon: "building.2", title: "Stadiums", iconColor: "673AB7", type: .navigation))
        }
        
        return items
    }
    
    private var supportAboutItems: [SettingItem] {
        // Tous les items de cette section n'ont pas d'action de navigation
        []
    }
    
    private var cacheCellularItems: [SettingItem] {
        // Tous les items de cette section n'ont pas d'action de navigation fonctionnelle
        []
    }
    
    private var actionsItems: [SettingItem] {
        [
            SettingItem(icon: "rectangle.portrait.and.arrow.right", title: "Log out", iconColor: "F44336", type: .action)
        ]
    }
    
    // MARK: - Functions
    
    func loadUserRole() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            currentUserRole = user.role
        }
    }
    
    func performLogout() {
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        isLoggedOut = true
    }
    
    func handleItemTap(_ item: SettingItem) {
        if item.title == "Log out" {
            showLogoutDialog = true
        }
        // Add other navigation handlers here
    }
}

// MARK: - Profile Card Settings

struct ProfileCardSettings: View {
    @State private var user: UserModel?
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar - Support both URL and base64
            if let picture = user?.picture, !picture.isEmpty {
                if picture.hasPrefix("http") {
                    // It's a URL (Supabase)
                    ProfilePhotoViewSettings(urlString: picture, size: 100)
                } else if let imageData = Data(base64Encoded: picture),
                          let uiImage = UIImage(data: imageData) {
                    // It's base64
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    // Fallback
                    defaultAvatar
                }
            } else {
                defaultAvatar
            }
            
            // Name
            Text("Hello, \(user?.fullName ?? "User")")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(UIColor.label))
            
            // Phone
            Text(user?.tel != nil ? "+\(user!.tel)" : "No phone")
                .font(.system(size: 16))
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            // Department Badge
            HStack(spacing: 6) {
                Image(systemName: "building.2")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white)
                Text(user?.role ?? "User")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "4CAF50"))
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear(perform: loadUser)
    }
    
    var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(UIColor.secondarySystemBackground))
                .frame(width: 100, height: 100)
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
    }
    
    func loadUser() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let decodedUser = try? JSONDecoder().decode(UserModel.self, from: userData) {
            user = decodedUser
        }
    }
}

// MARK: - Profile Photo View for Settings

struct ProfilePhotoViewSettings: View {
    let urlString: String
    let size: CGFloat
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading {
                ZStack {
                    Circle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(width: size, height: size)
                    ProgressView()
                }
                .onAppear {
                    loadImage()
                }
            } else {
                // Fallback if image failed to load
                ZStack {
                    Circle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(width: size, height: size)
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
        }
    }
    
    func loadImage() {
        SupabaseService.loadImage(from: urlString) { loadedImage in
            DispatchQueue.main.async {
                self.isLoading = false
                self.image = loadedImage
            }
        }
    }
}

// MARK: - Settings Section

struct SettingsSectionView: View {
    let title: String
    let items: [SettingItem]
    var onItemTap: ((SettingItem) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
                .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    SettingsRowView(item: item, showDivider: index < items.count - 1, onTap: onItemTap)
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Row

struct SettingsRowView: View {
    let item: SettingItem
    let showDivider: Bool
    var onTap: ((SettingItem) -> Void)? = nil
    @State private var navigateToEditProfile = false
    @State private var navigateToRecrute = false
    @State private var navigateToStades = false
    @State private var navigateToNegotiation = false
    @State private var navigateToInjuries = false
    @State private var navigateToAIPrediction = false
    @State private var navigateToDiet = false
    @State private var showLogoutDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                handleTap()
            }) {
                HStack(spacing: 16) {
                    // Icon with background
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: item.iconColor).opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: item.icon)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: item.iconColor))
                    }
                    
                    // Title
                    Text(item.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(UIColor.label))
                    
                    Spacer()
                    
                    // Trailing content
                    trailingContent
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())
            
            if showDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
        .background(
            Group {
                NavigationLink(destination: EditProfileView(), isActive: $navigateToEditProfile) {
                    EmptyView()
                }
                NavigationLink(destination: RecruteView(idAcademie: getUserId()), isActive: $navigateToRecrute) {
                    EmptyView()
                }
                NavigationLink(destination: StadiumsListView(), isActive: $navigateToStades) {
                    EmptyView()
                }
                NavigationLink(destination: NegotiationScreen(user: getUserModel()), isActive: $navigateToNegotiation) {
                    EmptyView()
                }
                NavigationLink(destination: InjuryHomeView(), isActive: $navigateToInjuries) {
                    EmptyView()
                }
                NavigationLink(destination: InjuryAIPredictionView(), isActive: $navigateToAIPrediction) {
                    EmptyView()
                }
                NavigationLink(destination: FootballDietPredictionView(), isActive: $navigateToDiet) {
                    EmptyView()
                }
            }
        )
    }
    
    // MARK: - Helper Functions
    
    func handleTap() {
        onTap?(item)
        
        switch item.title {
        case "Edit Profile":
            navigateToEditProfile = true
        case "Recruter arbitre":
            navigateToRecrute = true
        case "Stadiums":
            navigateToStades = true
        case "Negotiation":
            navigateToNegotiation = true
        case "Gestion des blessures":
            navigateToInjuries = true
        case "Prédiction IA - Blessures":
            navigateToAIPrediction = true
        case "Régimes Alimentaire":
            navigateToDiet = true
        default:
            break
        }
    }
    
    func getUserId() -> String {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            return user._id
        }
        return ""
    }
    
    func getUserModel() -> UserModel {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            return user
        }
        return UserModel(_id: "", prenom: "", nom: "", email: "", age: "", tel: 0, role: "", isVerified: false, picture: nil, academieId: nil)
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        switch item.type {
        case .navigation:
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        case .toggle(let binding):
            Toggle("", isOn: binding)
                .labelsHidden()
        case .action:
            EmptyView()
        }
    }
}

// MARK: - Setting Item Model

struct SettingItem {
    let icon: String
    let title: String
    let iconColor: String
    let type: SettingItemType
}

enum SettingItemType {
    case navigation
    case toggle(binding: Binding<Bool>)
    case action
}

// MARK: - Preview

struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView()
    }
}
