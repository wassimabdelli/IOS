import SwiftUI

struct HomeView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var isLoggedOut = false
    @AppStorage("user_role") var currentUserRole: String = "OWNER"
    @AppStorage("user_prenom") var appStoragePrenom: String = "Loading..."
    @AppStorage("user_nom") var appStorageNom: String = "Loading..."
    @State private var currentUserId: String? = nil
    @State private var currentAcademieId: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Welcome Header (Only on Home Tab)
                    if selectedTab == 0 {
                        welcomeHeader
                    }
                    
                    // Main Content - TabView
                    TabView(selection: $selectedTab) {
                        // Home Feed
                        ScrollView {
                            VStack(spacing: 20) {
                                quickActions
                                Spacer()
                            }
                            .padding()
                        }
                        .tag(0)

                        // Events
                        EventsView()
                            .tag(1)

                        // Add Tournament - OWNER only, Calendar for others
                        if currentUserRole == "OWNER" {
                            ChooseTournamentView()
                                .tag(2)
                        } else {
                            CalendarHomeView()
                                .tag(2)
                        }

                        // Social
                        SocialsChatView()
                            .tag(3)

                        // Profile
                        if currentUserRole == "ARBITRE" || currentUserRole == "COACH" {
                            ProfileSettingsView()
                                .tag(4)
                        } else {
                            ProfileView()
                                .tag(4)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                    // MARK: - Bottom Navbar
                    HStack {
                        navButton(icon: "house.fill", label: "Home", index: 0)
                        Spacer()
                        navButton(icon: "calendar", label: "Events", index: 1)
                        Spacer()
                        
                        // Add button - OWNER ONLY, Schedule for others
                        if currentUserRole == "OWNER" {
                            navButton(icon: "plus.circle.fill", label: "Add", index: 2)
                            Spacer()
                        } else if currentUserRole == "JOUEUR" || currentUserRole == "ARBITRE" {
                            navButton(icon: "calendar.circle", label: "Schedule", index: 2)
                            Spacer()
                        } else {
                            navButton(icon: "calendar.badge.clock", label: "Schedule", index: 2)
                            Spacer()
                        }
                        
                        navButton(icon: "person.2.fill", label: "Social", index: 3)
                        Spacer()
                        navButton(icon: "person.crop.circle", label: (currentUserRole == "ARBITRE" || currentUserRole == "COACH") ? "Settings" : "Profile", index: 4)
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(currentUserRole.roleColor.ignoresSafeArea(edges: .bottom))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, y: -2)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $isLoggedOut) {
            LoginView()
                .navigationBarHidden(true)
        }
        .onAppear {
            loadUserRole()
        }
    }

    // MARK: - Bottom Nav Button
    func navButton(icon: String, label: String, index: Int) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(selectedTab == index ? Color.white : Color.white.opacity(0.6))

            Text(label)
                .font(.caption)
                .foregroundColor(selectedTab == index ? Color.white : Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            selectedTab = index
        }
    }
    
    // MARK: - Load User Role
    
    func loadUserRole() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            // Save to AppStorage for synchronous access
            UserDefaults.standard.set(user.role, forKey: "user_role")
            currentUserId = user._id
            currentAcademieId = user.academieId
        }
    }
    
    // MARK: - Welcome Header
    
    var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Welcome Back! 👋")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("\(appStorageNom) \(appStoragePrenom)")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(currentUserRole.roleColor.ignoresSafeArea(edges: .top))
    }
    
    // MARK: - Quick Actions
    
    var quickActions: some View {
        VStack(spacing: 15) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            NavigationLink(destination: ProfileSettingsView()) {
                quickActionCard(icon: "gearshape.fill", title: "Settings", subtitle: "Manage your account", color: .gray)
            }

            // OWNER only sections
            if currentUserRole == "OWNER" {
                if let userId = currentUserId {
                    let academieIdToUse = currentAcademieId ?? userId
                    NavigationLink(destination: PlanView(idAcademie: academieIdToUse, idJoueur: userId)) {
                        quickActionCard(icon: "sportscourt.fill", title: "PlanJeu", subtitle: "Composer votre plan", color: .orange)
                    }
                }
                
                NavigationLink(destination: StadiumsListView()) {
                    quickActionCard(icon: "building.2.fill", title: "Stadiums", subtitle: "View and manage stadiums", color: .blue)
                }
                
                NavigationLink(destination: RecruteView(idAcademie: currentAcademieId ?? currentUserId)) {
                    quickActionCard(icon: "person.badge.plus", title: "Negotiation Staff", subtitle: "Recruter arbitres et coachs", color: .purple)
                }
                
            }
            
            // AI Assistant Button (available for all users)
            NavigationLink(destination: AiChatBotView()) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "C4FF61"), Color(hex: "A0D040")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Assistant")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Chat with AI powered by Groq")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            
        }
    }
    
    func quickActionCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Logout
    func logout() {
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "user_role")  // Clear role
        UserDefaults.standard.set(false, forKey: "rememberMe")
        isLoggedOut = true
    }
}
