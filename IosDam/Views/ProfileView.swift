//
//  ProfileView.swift
//  IosDam
//
//  Profile screen matching Android design - Xcode 12.3 Compatible

import SwiftUI

struct ProfileView: View {
    @State private var user: UserProfile = .mock
    @State private var realUser: UserModel?

    @State private var matches: [MatchResultProfile] = MatchResultProfile.mockMatches
    @AppStorage("user_role") var currentUserRole: String = "OWNER"
    
    // Dynamic stats
    @State private var profileStats: ProfileStatsResponse?
    @State private var isLoadingStats = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Custom Header
                customHeader
                
                // Main Profile Card
                MainProfileCardView(user: user, realUser: realUser, themeColor: currentUserRole.roleColor, profileStats: profileStats)
                
                Spacer().frame(height: 16)
                
                // Dynamic Stats Grid based on role
                if isLoadingStats {
                    ProgressView()
                        .padding()
                } else if let stats = profileStats {
                    DynamicStatsGridView(stats: stats, role: currentUserRole, themeColor: currentUserRole.roleColor)
                } else {
                    // Fallback to static stats
                    QuickStatsGridView(user: user, themeColor: currentUserRole.roleColor)
                }
                
                Spacer().frame(height: 8)
                
                // Achievements and Matches Section
                achievementsAndMatchesSection
                
                // Footer Section
                footerSection
            }
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            loadRealUser()
            loadProfileStats()
        }
    }
    
    // MARK: - Load Real User
    
    func loadRealUser() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let decodedUser = try? JSONDecoder().decode(UserModel.self, from: userData) {
            realUser = decodedUser
        }
    }
    
    // MARK: - Load Profile Stats
    
    func loadProfileStats() {
        guard let userData = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(UserModel.self, from: userData) else {
            isLoadingStats = false
            return
        }
        
        APIService.getProfileStats(userId: user._id) { result in
            DispatchQueue.main.async {
                isLoadingStats = false
                switch result {
                case .success(let stats):
                    profileStats = stats
                    print("✅ Profile stats loaded: \(stats)")
                case .failure(let error):
                    print("❌ Error loading profile stats: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Achievements and Matches Section
    
    private var achievementsAndMatchesSection: some View {
        Group {

            
            // Recent Matches Section
            SectionHeaderView(title: "Recent Matches", showViewAll: true, themeColor: currentUserRole.roleColor)
            
            VStack(spacing: 0) {
                if let recentMatches = profileStats?.recentMatches, !recentMatches.isEmpty {
                    ForEach(recentMatches) { match in
                        MatchRowView(match: match)
                    }
                } else {
                    Text("No recent matches")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            Spacer().frame(height: 16)
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        Group {
            Spacer().frame(height: 32)
        }
    }
    
    // MARK: - Custom Header
    
    private var customHeader: some View {
        HStack {
            Text("Profile")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            NavigationLink(destination: ProfileSettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(UIColor.label))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Main Profile Card

struct MainProfileCardView: View {
    let user: UserProfile
    let realUser: UserModel?
    let themeColor: Color
    let profileStats: ProfileStatsResponse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Photo or Initials Circle
                if let pictureURL = realUser?.picture, !pictureURL.isEmpty {
                    // Show profile photo
                    ProfilePhotoView(urlString: pictureURL, size: 64)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                } else {
                    // Show initials
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 64, height: 64)
                        Text(user.initials)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(realUser?.fullName ?? user.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color.white)
                    

                }
                
                Spacer()
            }
            .padding(20)
            
            // Stats Row
            HStack(spacing: 0) {
                if let stats = profileStats {
                    // Dynamic Stats
                    switch stats.role.uppercased() {
                    case "OWNER":
                        Spacer()
                        ProfileStatCircleView(value: "\(stats.trophies ?? 0)", label: "Trophies", iconName: "trophy.fill")
                        Spacer()
                        
                    case "JOUEUR":
                        ProfileStatCircleView(value: "\(stats.matchesPlayed ?? 0)", label: "Matches")
                        Spacer()
                        ProfileStatCircleView(value: "\(stats.goals ?? 0)", label: "Goals")
                        Spacer()
                        ProfileStatCircleView(value: "\(stats.assists ?? 0)", label: "Assists")
                        
                    case "ARBITRE":
                        ProfileStatCircleView(value: "\(stats.matchesRefereed ?? 0)", label: "Refereed")
                        Spacer()
                        ProfileStatCircleView(value: "PRO", label: "Status")
                        Spacer()
                        ProfileStatCircleView(value: "-", label: "-")
                        
                    case "COACH":
                        ProfileStatCircleView(value: "\(stats.matchesCoached ?? 0)", label: "Matches")
                        Spacer()
                        ProfileStatCircleView(value: "\(stats.teamWins ?? 0)", label: "Wins")
                        Spacer()
                        ProfileStatCircleView(value: calculateWinRate(wins: stats.teamWins ?? 0, losses: stats.teamLosses ?? 0), label: "Win Rate")
                        
                    default:
                        // Fallback to static if role unknown
                        ProfileStatCircleView(value: "\(user.wins)", label: "Wins")
                        Spacer()
                        ProfileStatCircleView(value: "\(user.losses)", label: "Losses")
                        Spacer()
                        ProfileStatCircleView(value: user.winRate, label: "Win Rate")
                    }
                } else {
                    // Fallback to static stats (Mock)
                    ProfileStatCircleView(value: "\(user.wins)", label: "Wins")
                    Spacer()
                    ProfileStatCircleView(value: "\(user.losses)", label: "Losses")
                    Spacer()
                    ProfileStatCircleView(value: user.winRate, label: "Win Rate")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(themeColor)
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func calculateWinRate(wins: Int, losses: Int) -> String {
        let total = wins + losses
        if total == 0 { return "0%" }
        let rate = (Double(wins) / Double(total)) * 100
        return String(format: "%.1f%%", rate)
    }
}

// MARK: - Profile Stat Circle

struct ProfileStatCircleView: View {
    let value: String
    let label: String
    var iconName: String? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                if let iconName = iconName {
                    VStack(spacing: 2) {
                        Image(systemName: iconName)
                            .font(.system(size: 20))
                            .foregroundColor(Color.white)
                        Text(value)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Color.white)
                    }
                } else {
                    Text(value)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(Color.white)
                }
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.9))
        }
    }
}

// MARK: - Dynamic Stats Grid (Based on Role)

struct DynamicStatsGridView: View {
    let stats: ProfileStatsResponse
    let role: String
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            switch role.uppercased() {
            case "OWNER":
                ownerStatsView
            case "JOUEUR":
                playerStatsView
            case "ARBITRE":
                refereeStatsView
            case "COACH":
                coachStatsView
            default:
                Text("Unknown role")
            }
        }
        .padding(.horizontal, 16)
    }
    
    // OWNER Stats
    private var ownerStatsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                QuickStatCardView(
                    iconName: "trophy.fill",
                    iconColor: Color(hex: "4CAF50"),
                    value: "\(stats.wins ?? 0)",
                    label: "Victories"
                )
                QuickStatCardView(
                    iconName: "xmark.circle.fill",
                    iconColor: Color(hex: "F44336"),
                    value: "\(stats.losses ?? 0)",
                    label: "Losses"
                )
            }
            HStack(spacing: 16) {
                QuickStatCardView(
                    iconName: "percent",
                    iconColor: Color(hex: "2196F3"),
                    value: stats.winRate ?? "0%",
                    label: "Win Rate"
                )
                QuickStatCardView(
                    iconName: "person.3.fill",
                    iconColor: themeColor,
                    value: "\(stats.totalPlayers ?? 0)",
                    label: "Total Players"
                )
            }

        }
    }
    
    // JOUEUR Stats
    private var playerStatsView: some View {
        VStack(spacing: 16) {
            // Academy Name (full width)
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeColor)
                Text(stats.academyName ?? "Independent")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            
            HStack(spacing: 16) {
                QuickStatCardView(
                    iconName: "sportscourt.fill",
                    iconColor: Color(hex: "2196F3"),
                    value: "\(stats.matchesPlayed ?? 0)",
                    label: "Matches Played"
                )
                QuickStatCardView(
                    iconName: "soccerball.inverse",
                    iconColor: Color(hex: "4CAF50"),
                    value: "\(stats.goals ?? 0)",
                    label: "Goals"
                )
            }
            HStack(spacing: 16) {
                QuickStatCardView(
                    iconName: "arrow.up.right",
                    iconColor: Color(hex: "673AB7"),
                    value: "\(stats.assists ?? 0)",
                    label: "Assists"
                )
                QuickStatCardView(
                    iconName: "chart.bar.fill",
                    iconColor: themeColor,
                    value: "\((stats.goals ?? 0) + (stats.assists ?? 0))",
                    label: "Total Contributions"
                )
            }
        }
    }
    
    // ARBITRE Stats
    private var refereeStatsView: some View {
        VStack(spacing: 16) {
            // Academy Name (full width)
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeColor)
                Text(stats.academyName ?? "Independent")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            
            HStack(spacing: 16) {
                QuickStatCardView(
                    iconName: "sportscourt.fill",
                    iconColor: Color(hex: "FF9800"),
                    value: "\(stats.matchesRefereed ?? 0)",
                    label: "Matches Refereed"
                )
                QuickStatCardView(
                    iconName: "flag.fill",
                    iconColor: themeColor,
                    value: "PRO",
                    label: "Status"
                )
            }
        }
    }
    
    // COACH Stats
    private var coachStatsView: some View {
        VStack(spacing: 16) {
            // Team Name (full width)
            HStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeColor)
                Text(stats.teamName ?? "No team")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            
            HStack(spacing: 16) {
                QuickStatCardView(
                    iconName: "sportscourt.fill",
                    iconColor: Color(hex: "2196F3"),
                    value: "\(stats.matchesCoached ?? 0)",
                    label: "Matches Coached"
                )
                QuickStatCardView(
                    iconName: "trophy.fill",
                    iconColor: Color(hex: "4CAF50"),
                    value: "\(stats.teamWins ?? 0)",
                    label: "Team Wins"
                )
            }
            HStack(spacing: 16) {
                QuickStatCardView(
                    iconName: "xmark.circle.fill",
                    iconColor: Color(hex: "F44336"),
                    value: "\(stats.teamLosses ?? 0)",
                    label: "Team Losses"
                )
                QuickStatCardView(
                    iconName: "percent",
                    iconColor: themeColor,
                    value: calculateWinRate(wins: stats.teamWins ?? 0, losses: stats.teamLosses ?? 0),
                    label: "Win Rate"
                )
            }
        }
    }
    
    private func calculateWinRate(wins: Int, losses: Int) -> String {
        let total = wins + losses
        if total == 0 { return "0%" }
        let rate = (Double(wins) / Double(total)) * 100
        return String(format: "%.1f%%", rate)
    }
}

// MARK: - Quick Stats Grid (Fallback)

struct QuickStatsGridView: View {
    let user: UserProfile
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                QuickStatCardView(iconName: "sportscourt.fill", iconColor: Color(hex: "2196F3"), value: "\(user.goalsScored)", label: "Goals Scored")
                QuickStatCardView(iconName: "arrow.up.right", iconColor: Color(hex: "673AB7"), value: "\(user.assists)", label: "Assists")
            }
            HStack(spacing: 16) {
                QuickStatCardView(iconName: "shield.fill", iconColor: Color(hex: "FF9800"), value: "\(user.cleanSheets)", label: "Clean Sheets")
                QuickStatCardView(iconName: "person.3.fill", iconColor: themeColor, value: "\(user.totalMatches)", label: "Total Matches")
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Quick Stat Card

struct QuickStatCardView: View {
    let iconName: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(Color(UIColor.label))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Section Header

struct SectionHeaderView: View {
    let title: String
    let showViewAll: Bool
    let themeColor: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
            
            Spacer()
            
            if showViewAll {
                HStack(spacing: 4) {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeColor)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(themeColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}



// MARK: - Match Row

struct MatchRowView: View {
    let match: MatchResultProfile
    
    var statusColor: Color {
        switch match.status {
        case "W": return Color(hex: "4CAF50")
        case "L": return Color(hex: "F44336")
        case "D": return Color(hex: "9E9E9E")
        default: return Color.black
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Status Box
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(statusColor)
                        .frame(width: 40, height: 40)
                    Text(match.status)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Color.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                    Text(match.date)
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                Text(match.score)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.top, 4)
        }
    }
}

// MARK: - Footer Detail Row

struct FooterDetailRowView: View {
    let iconName: String
    let title: String
    let value: String
    let themeColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(themeColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Profile Photo View

struct ProfilePhotoView: View {
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
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
                    .onAppear {
                        loadImage()
                    }
            } else {
                // Fallback if image failed to load
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.5))
                            .foregroundColor(.white)
                    )
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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
