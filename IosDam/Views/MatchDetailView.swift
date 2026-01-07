//
//  MatchDetailView.swift
//  IosDam
//
//  Detailed Match View - Xcode 12.3 Compatible
//

import SwiftUI

struct MatchDetailView: View {
    let matchId: String
    let eq1Id: String?
    let eq2Id: String?
    let coupeCategorie: String?
    
    @State private var match: MatchDetail?
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var showingEditScore: Bool = false
    @State private var score1Input: String = ""
    @State private var score2Input: String = ""
    @State private var isSubmitting: Bool = false
    @State private var statSheet: Bool = false
    @State private var selectedStatType: String = "but"
    @State private var selectedEquipe: String = "eq1"
    @State private var selectedJoueurId: String = ""
    @State private var selectedStatus: MatchStatus = .SCHEDULED
    @State private var team1Players: [APIService.TeamMember] = []

    @State private var team2Players: [APIService.TeamMember] = []
    @State private var currentUserRole: String? = nil
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading match details...")
            } else if let error = errorMessage {
                errorView(message: error)
            } else if let match = match {
                matchContentView(match: match)
            }
        }
        .navigationBarTitle("Match Details", displayMode: .inline)
        .onAppear {
            loadUserRole()
            loadMatch()
        }
        .sheet(isPresented: $statSheet) {
            VStack(spacing: 12) {
                Picker("Type", selection: $selectedStatType) {
                    Text("but").tag("but")
                    Text("assist").tag("assist")
                    Text("offside").tag("offside")
                    Text("yellow").tag("yellow")
                    Text("red").tag("red")
                }
                Picker("Équipe", selection: $selectedEquipe) {
                    Text("eq1").tag("eq1")
                    Text("eq2").tag("eq2")
                }
                Picker("Joueur", selection: $selectedJoueurId) {
                    Text("Sélectionner un joueur").tag("")
                    let players = selectedEquipe == "eq1" ? team1Players : team2Players
                    ForEach(players) { player in
                        Text("\(player.nom) \(player.prenom)").tag(player.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Button(action: applyStat) {
                    Text("Appliquer")
                }
            }
            .padding()
        }
    }
    
    private func matchContentView(match: MatchDetail) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                matchHeaderSection(match: match)
                scoreSection(match: match)
                if isEditable {
                    actionButtons(match: match)
                }
                
                // Detailed Stats
                detailedStatsSection(match: match)
                
                if let events = match.events, !events.isEmpty {
                    eventsSection(events: events)
                }
            }
            .padding()
        }
    }
    
    private func detailedStatsSection(match: MatchDetail) -> some View {
        VStack(spacing: 16) {
            // Goals
            statCategoryView(title: "Buts", team1Players: match.But_eq1, team2Players: match.But_eq2)
            
            // Assists
            statCategoryView(title: "Assists", team1Players: match.assist_eq1, team2Players: match.assist_eq2)
            
            // Offsides
            statCategoryView(title: "Offsides", team1Players: match.offside_eq1, team2Players: match.offside_eq2)
            
            // Cards
            if let yellow = match.cartonJaune, !yellow.isEmpty {
                cardSection(title: "Cartons Jaunes", players: yellow, color: .yellow)
            }
            if let red = match.cartonRouge, !red.isEmpty {
                cardSection(title: "Cartons Rouges", players: red, color: .red)
            }
            
            // Corners & Penalties
            HStack {
                VStack {
                    Text("Corners")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(match.corner_eq1 ?? 0) - \(match.corner_eq2 ?? 0)")
                        .font(.headline)
                }
                Spacer()
                VStack {
                    Text("Penalties")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(match.penalty_eq1 ?? 0) - \(match.penalty_eq2 ?? 0)")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    private func statCategoryView(title: String, team1Players: [MatchPlayerInfo]?, team2Players: [MatchPlayerInfo]?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.leading, 4)
            
            HStack(alignment: .top) {
                // Team 1
                VStack(alignment: .leading, spacing: 4) {
                    if let players = team1Players, !players.isEmpty {
                        ForEach(players) { player in
                            Text(player.fullName)
                                .font(.caption)
                        }
                    } else {
                        Text("-")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Team 2
                VStack(alignment: .trailing, spacing: 4) {
                    if let players = team2Players, !players.isEmpty {
                        ForEach(players) { player in
                            Text(player.fullName)
                                .font(.caption)
                        }
                    } else {
                        Text("-")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    private func cardSection(title: String, players: [MatchPlayerInfo], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.fill")
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(players) { player in
                    Text(player.fullName)
                        .font(.caption)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    private func matchHeaderSection(match: MatchDetail) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                teamView(team: match.id_equipe1, isHome: true)
                Text("VS")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                teamView(team: match.id_equipe2, isHome: false)
            }
            
            statusBadge(status: match.statut)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func teamView(team: MatchTeamInfo?, isHome: Bool) -> some View {
        let name: String = team?.nom ?? "Team"
        return VStack(spacing: 8) {
            if team != nil {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(name.prefix(2)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                    )
                
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(isHome ? "Home" : "Away")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("TBD")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func scoreSection(match: MatchDetail) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 40) {
                let s1 = Int(score1Input) ?? match.score_eq1
                let s2 = Int(score2Input) ?? match.score_eq2
                VStack(spacing: 8) {
                    scoreBox(score: s1, teamName: match.id_equipe1?.nom ?? "Team 1")
                    if isEditable {
                        HStack {
                            Button(action: { incrementScore(team: 1) }) { Image(systemName: "plus.circle") }
                            Button(action: { decrementScore(team: 1) }) { Image(systemName: "minus.circle") }
                        }
                    }
                }
                Text("-")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                VStack(spacing: 8) {
                    scoreBox(score: s2, teamName: match.id_equipe2?.nom ?? "Team 2")
                    if isEditable {
                        HStack {
                            Button(action: { incrementScore(team: 2) }) { Image(systemName: "plus.circle") }
                            Button(action: { decrementScore(team: 2) }) { Image(systemName: "minus.circle") }
                        }
                    }
                }
            }
            
            if isEditable {
                Button(action: { statSheet = true }) { Text("Ajouter Stat/Carton/Hors-jeu") }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func scoreBox(score: Int, teamName: String) -> some View {
        VStack(spacing: 4) {
            Text("\(score)")
                .font(.system(size: 48, weight: .bold))
            Text(teamName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Removed matchInfoSection and statisticsSection as requested
    
    private func eventsSection(events: [MatchEvent]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Match Events")
                .font(.headline)
                .fontWeight(.bold)
            
            ForEach(events.sorted(by: { $0.minute < $1.minute })) { event in
                EventRow(event: event)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func statusBadge(status: MatchStatus) -> some View {
        Text(status.rawValue.replacingOccurrences(of: "_", with: " "))
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor(status))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private func statusColor(_ status: MatchStatus) -> Color {
        switch status {
        case .SCHEDULED:
            return Color.blue
        case .IN_PROGRESS:
            return Color.orange
        case .COMPLETED:
            return Color.green
        case .CANCELLED:
            return Color.red
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                loadMatch()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    private func loadTeamPlayers() {
        let category = coupeCategorie ?? "SENIOR"
        
        if let id1 = eq1Id ?? match?.id_equipe1?.id {
            APIService.getJoueursByRole(idAcademie: id1, categorie: category, role: "starter") { res in
                if case .success(let players) = res {
                    DispatchQueue.main.async { self.team1Players = players }
                }
            }
        }
        
        if let id2 = eq2Id ?? match?.id_equipe2?.id {
            APIService.getJoueursByRole(idAcademie: id2, categorie: category, role: "starter") { res in
                if case .success(let players) = res {
                    DispatchQueue.main.async { self.team2Players = players }
                }
            }
        }
    }

    private func loadMatch() {
        isLoading = true
        errorMessage = nil
        
        APIService.getMatchById(matchId: matchId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let matchDetail):
                    self.isLoading = false
                    self.match = matchDetail
                    self.score1Input = String(matchDetail.score_eq1)
                    self.score2Input = String(matchDetail.score_eq2)
                    self.selectedStatus = matchDetail.statut
                    
                    // Fallback for missing names
                    var idsToFetch: [String] = []
                    if let t1 = matchDetail.id_equipe1, t1.nom == nil || t1.nom == "Unknown" || t1.nom == "Fetching..." {
                        idsToFetch.append(t1.id)
                    }
                    if let t2 = matchDetail.id_equipe2, t2.nom == nil || t2.nom == "Unknown" || t2.nom == "Fetching..." {
                        idsToFetch.append(t2.id)
                    }
                    
                    if !idsToFetch.isEmpty {
                        APIService.getNames(ids: idsToFetch) { nameResult in
                            if case .success(let nameMap) = nameResult {
                                DispatchQueue.main.async {
                                    if let t1Id = self.match?.id_equipe1?.id, let n1 = nameMap[t1Id] {
                                        self.match?.id_equipe1?.nom = n1
                                    }
                                    if let t2Id = self.match?.id_equipe2?.id, let n2 = nameMap[t2Id] {
                                        self.match?.id_equipe2?.nom = n2
                                    }
                                }
                            }
                        }
                    }
                    
                    self.loadTeamPlayers()
                    
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func actionButtons(match: MatchDetail) -> some View {
        VStack(spacing: 12) {
            Picker("Status Match", selection: $selectedStatus) {
                Text("Programmé").tag(MatchStatus.SCHEDULED)
                Text("En cours").tag(MatchStatus.IN_PROGRESS)
                Text("Terminé").tag(MatchStatus.COMPLETED)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            Button(action: { validateMatchAndPromote(match) }) {
                if isSubmitting { ProgressView() } else { Text("Valider") }
            }
            .disabled(isSubmitting)
        }
    }

    private func incrementScore(team: Int) {
        guard let m = match else { return }
        if team == 1 {
            let current = Int(score1Input) ?? m.score_eq1
            score1Input = String(current + 1)
        } else {
            let current = Int(score2Input) ?? m.score_eq2
            score2Input = String(current + 1)
        }
    }

    private func decrementScore(team: Int) {
        guard let m = match else { return }
        if team == 1 {
            let current = Int(score1Input) ?? m.score_eq1
            score1Input = String(max(0, current - 1))
        } else {
            let current = Int(score2Input) ?? m.score_eq2
            score2Input = String(max(0, current - 1))
        }
    }

    private func applyStat() {
        guard let m = match else { return }
        guard !selectedJoueurId.isEmpty else {
            errorMessage = "Veuillez sélectionner un joueur"
            statSheet = false // Close sheet to show error
            return
        }
        if selectedStatType == "but" || selectedStatType == "assist" {
            let req = APIService.AddStatRequest(idJoueur: selectedJoueurId, equipe: selectedEquipe, type: selectedStatType)
            APIService.addStatToMatch(matchId: m.id, request: req) { result in
                DispatchQueue.main.async { handleMutation(result) }
            }
        } else if selectedStatType == "offside" {
            let academieId = (selectedEquipe == "eq1" ? (eq1Id ?? match?.id_equipe1?.id) : (eq2Id ?? match?.id_equipe2?.id)) ?? ""
            APIService.addOffside(matchId: m.id, idAcademie: academieId, idJoueur: selectedJoueurId) { result in
                DispatchQueue.main.async { handleMutation(result) }
            }
        } else {
            let cat = coupeCategorie ?? "SENIOR"
            let req = APIService.AddCartonRequest(idJoueur: selectedJoueurId, categorie: cat, color: selectedStatType)
            APIService.addCartonToMatch(matchId: m.id, request: req) { result in
                DispatchQueue.main.async { handleMutation(result) }
            }
        }
    }

    private func handleMutation(_ result: Result<MatchDetail, Error>) {
        switch result {
        case .success(let updated):
            match = updated
            statSheet = false
            selectedJoueurId = ""
        case .failure(let err):
            errorMessage = err.localizedDescription
        }
    }

    private func validateMatchAndPromote(_ m: MatchDetail) {
        isSubmitting = true
        let finalScore1 = Int(score1Input) ?? m.score_eq1
        let finalScore2 = Int(score2Input) ?? m.score_eq2
        
        let body = APIService.UpdateMatchRequest(score_eq1: finalScore1, score_eq2: finalScore2, statut: selectedStatus.rawValue, id_equipe1: nil, id_equipe2: nil)
        APIService.updateMatch(matchId: m.id, body: body) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updated):
                    if self.selectedStatus == .COMPLETED {
                        promoteWinnerIfNeeded(updated, finalScore1: finalScore1, finalScore2: finalScore2)
                    } else {
                        self.isSubmitting = false
                        self.match = updated
                    }
                case .failure(let err):
                    isSubmitting = false
                    errorMessage = err.localizedDescription
                }
            }
        }
    }

    private func promoteWinnerIfNeeded(_ m: MatchDetail, finalScore1: Int, finalScore2: Int) {
        guard let nextId = m.nextMatch, let pos = m.positionInNextMatch else { isSubmitting = false; return }
        let winnerTeamId: String? = finalScore1 >= finalScore2 ? (eq1Id ?? m.id_equipe1?.id) : (eq2Id ?? m.id_equipe2?.id)
        var body = APIService.UpdateMatchRequest(score_eq1: nil, score_eq2: nil, statut: nil, id_equipe1: nil, id_equipe2: nil)
        if pos == "eq1" { body = APIService.UpdateMatchRequest(score_eq1: nil, score_eq2: nil, statut: nil, id_equipe1: winnerTeamId, id_equipe2: nil) }
        else { body = APIService.UpdateMatchRequest(score_eq1: nil, score_eq2: nil, statut: nil, id_equipe1: nil, id_equipe2: winnerTeamId) }
        APIService.updateMatch(matchId: nextId, body: body) { _ in
            APIService.getMatchById(matchId: m.id) { res in
                DispatchQueue.main.async {
                    isSubmitting = false
                    switch res {
                    case .success(let refreshed): match = refreshed
                    case .failure(let err): errorMessage = err.localizedDescription
                    }
                }
            }
        }
    }

    
    private func loadUserRole() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            currentUserRole = user.role
        }
    }
    
    private var isEditable: Bool {
        return currentUserRole == "ARBITRE"
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct StatBar: View {
    let title: String
    let value1: Int
    let value2: Int
    var suffix: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(value1)\(suffix)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                GeometryReader { geometry in
                    let total = value1 + value2
                    let ratio = total > 0 ? CGFloat(value1) / CGFloat(total) : 0.5
                    
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * ratio)
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geometry.size.width * (1 - ratio))
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                }
                .frame(height: 8)
                
                Text("\(value2)\(suffix)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct EventRow: View {
    let event: MatchEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(event.minute)'")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 35)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(6)
            
            Image(systemName: eventIcon)
                .foregroundColor(eventColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.event_type.rawValue.replacingOccurrences(of: "_", with: " "))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let description = event.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var eventIcon: String {
        switch event.event_type {
        case .GOAL:
            return "sportscourt.fill"
        case .YELLOW_CARD:
            return "square.fill"
        case .RED_CARD:
            return "square.fill"
        case .SUBSTITUTION:
            return "arrow.left.arrow.right"
        case .PENALTY:
            return "exclamationmark.circle"
        }
    }
    
    private var eventColor: Color {
        switch event.event_type {
        case .GOAL:
            return .green
        case .YELLOW_CARD:
            return .yellow
        case .RED_CARD:
            return .red
        case .SUBSTITUTION:
            return .blue
        case .PENALTY:
            return .orange
        }
    }
}

// MARK: - Edit Score View

struct EditScoreView: View {
    @Environment(\.presentationMode) var presentationMode
    let match: MatchDetail
    let onUpdate: (MatchDetail) -> Void
    
    @State private var score1: String
    @State private var score2: String
    @State private var selectedStatus: MatchStatus
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    
    init(match: MatchDetail, onUpdate: @escaping (MatchDetail) -> Void) {
        self.match = match
        self.onUpdate = onUpdate
        _score1 = State(initialValue: "\(match.score_eq1)")
        _score2 = State(initialValue: "\(match.score_eq2)")
        _selectedStatus = State(initialValue: match.statut)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Scores")) {
                    HStack {
                        Text(match.id_equipe1?.nom ?? "Team 1")
                        Spacer()
                        TextField("Score", text: $score1)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                    
                    HStack {
                        Text(match.id_equipe2?.nom ?? "Team 2")
                        Spacer()
                        TextField("Score", text: $score2)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
                
                Section(header: Text("Match Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        Text("Scheduled").tag(MatchStatus.SCHEDULED)
                        Text("In Progress").tag(MatchStatus.IN_PROGRESS)
                        Text("Completed").tag(MatchStatus.COMPLETED)
                        Text("Cancelled").tag(MatchStatus.CANCELLED)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: updateScore) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Update Match")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationBarTitle("Edit Score", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func updateScore() {
        guard let s1 = Int(score1), let s2 = Int(score2) else {
            errorMessage = "Please enter valid scores"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        let scoreData = UpdateMatchScoreRequest(
            score_eq1: s1,
            score_eq2: s2,
            statut: selectedStatus
        )
        
        APIService.updateMatchScore(matchId: match.id, scoreData: scoreData) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success(let updatedMatch):
                    onUpdate(updatedMatch)
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct MatchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MatchDetailView(matchId: "sample-id", eq1Id: nil, eq2Id: nil, coupeCategorie: nil)
    }
}
