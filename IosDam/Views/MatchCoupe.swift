import SwiftUI

struct MatchCoupeView: View {
    let tournament: Tournament
    let academieId: String
    @State private var rounds: [Int: [MatchDetail]] = [:]
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading bracket...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    HStack(alignment: .top, spacing: 24) {
                        ForEach(sortedRounds, id: \.self) { round in
                            VStack(spacing: 16) {
                                Text("Round \(round)")
                                    .font(.headline)
                                ForEach(rounds[round] ?? [], id: \.id) { match in
                                    matchCard(match)
                                }
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .navigationBarTitle("Matches Bracket", displayMode: .inline)
            }
        }
        .onAppear(perform: loadBracket)
    }
    
    private var sortedRounds: [Int] {
        Array(rounds.keys).sorted()
    }
    
    private func loadBracket() {
        let idStrings = (tournament.matches?.map { $0.id }) ?? (tournament.matchIds?.compactMap { $0.stringValue }) ?? []
        guard !idStrings.isEmpty else {
            isLoading = false
            rounds = [:]
            errorMessage = "No matches found"
            return
        }
        isLoading = true
        errorMessage = nil
        var results: [MatchDetail] = []
        let group = DispatchGroup()
        for id in idStrings {
            group.enter()
            APIService.getMatchById(matchId: id) { result in
                switch result {
                case .success(let detail):
                    results.append(detail)
                case .failure:
                    break
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            isLoading = false
            if results.isEmpty {
                errorMessage = "No matches found"
                return
            }
            var dict: [Int: [MatchDetail]] = [:]
            
            // Group to wait for additional team fetches
            let teamFetchGroup = DispatchGroup()
            
            for i in 0..<results.count {
                // Check if team 1 needs fetching
                if let t1 = results[i].id_equipe1, t1.nom == "Fetching..." {
                    teamFetchGroup.enter()
                    APIService.getTeamById(teamId: t1.id) { res in
                        if case .success(let team) = res {
                            // Create a new MatchTeamInfo from the populated team
                            let info = MatchTeamInfo(_id: team.id, nom: team.nom, logo: team.logo)
                            // We need to update the struct in the array. 
                            // Since we are inside a closure, we need to be careful.
                            // However, we are iterating by index, but results is a value type (array of structs).
                            // We can't modify results[i] directly inside this closure easily without synchronization.
                            // A better approach: Update a local dictionary or use a thread-safe wrapper.
                            // For simplicity, let's just update the specific match in the main queue block later? 
                            // No, we need it before grouping.
                            
                            // Let's use a lock or serial queue for safety if modifying a shared resource, 
                            // but here we are just updating a local array before the final notify.
                            // Actually, 'results' is a local var captured by closure. 
                            // Swift arrays are value types, so capturing it in closure copies it? 
                            // No, if it's a var, it captures a reference to the box. 
                            // But concurrent modification is bad.
                            
                            // Alternative: Fetch all missing teams first, then build dict.
                            // Let's do a safe approach:
                            // We will use a separate dictionary to store fetched teams and apply them at the end.
                        }
                        teamFetchGroup.leave()
                    }
                }
                
                // Check if team 2 needs fetching
                if let t2 = results[i].id_equipe2, t2.nom == "Fetching..." {
                    teamFetchGroup.enter()
                    APIService.getTeamById(teamId: t2.id) { res in
                        if case .success(let team) = res {
                            // We will handle the update in the notify block
                        }
                        teamFetchGroup.leave()
                    }
                }
            }
            
            // RE-IMPLEMENTATION TO BE SAFE AND CLEAN:
            // 1. Identify all missing team IDs.
            // 2. Fetch them.
            // 3. Update the matches.
            
            var missingTeamIds: Set<String> = []
            for m in results {
                if let t1 = m.id_equipe1, t1.nom == "Fetching..." { missingTeamIds.insert(t1.id) }
                if let t2 = m.id_equipe2, t2.nom == "Fetching..." { missingTeamIds.insert(t2.id) }
            }
            
            if missingTeamIds.isEmpty {
                // No extra fetching needed
                for m in results {
                    dict[m.round, default: []].append(m)
                }
                finishLoading(dict)
                return
            }
            
            var fetchedTeams: [String: MatchTeamInfo] = [:]
            let fetchGroup = DispatchGroup()
            let fetchQueue = DispatchQueue(label: "com.iosdam.teamfetch")
            
            for teamId in missingTeamIds {
                fetchGroup.enter()
                // FIX: Fetch User (Academy) instead of Team
                APIService.getUserProfile(userId: teamId) { res in
                    if case .success(let user) = res {
                        // Map User to MatchTeamInfo
                        // Assuming 'nom' is the academy name, or we construct it from prenom/nom
                        // The user model has 'nom' and 'prenom'. Let's use 'nom' as it likely represents the academy name in this context,
                        // or user.fullName if appropriate. The user said "l'academie c'est un user de type OWNER".
                        // Usually academies have a name. In UserModel, there is 'nom'.
                        let info = MatchTeamInfo(_id: user._id, nom: user.nom, logo: user.picture)
                        fetchQueue.async {
                            fetchedTeams[teamId] = info
                        }
                    }
                    fetchGroup.leave()
                }
            }
            
            fetchGroup.notify(queue: .main) {
                // Update results with fetched teams
                var updatedResults = results
                for i in 0..<updatedResults.count {
                    if let t1 = updatedResults[i].id_equipe1, t1.nom == "Fetching...", let info = fetchedTeams[t1.id] {
                        updatedResults[i] = MatchDetail(
                            id: updatedResults[i].id,
                            id_equipe1: info,
                            id_equipe2: updatedResults[i].id_equipe2,
                            id_terrain: updatedResults[i].id_terrain,
                            id_arbitre: updatedResults[i].id_arbitre,
                            date: updatedResults[i].date,
                            score_eq1: updatedResults[i].score_eq1,
                            score_eq2: updatedResults[i].score_eq2,
                            statut: updatedResults[i].statut,
                            round: updatedResults[i].round,
                            nextMatch: updatedResults[i].nextMatch,
                            positionInNextMatch: updatedResults[i].positionInNextMatch,
                            statistics: updatedResults[i].statistics,
                            events: updatedResults[i].events,
                            createdAt: updatedResults[i].createdAt,
                            updatedAt: updatedResults[i].updatedAt
                        )
                    }
                    if let t2 = updatedResults[i].id_equipe2, t2.nom == "Fetching...", let info = fetchedTeams[t2.id] {
                        updatedResults[i] = MatchDetail(
                            id: updatedResults[i].id,
                            id_equipe1: updatedResults[i].id_equipe1,
                            id_equipe2: info,
                            id_terrain: updatedResults[i].id_terrain,
                            id_arbitre: updatedResults[i].id_arbitre,
                            date: updatedResults[i].date,
                            score_eq1: updatedResults[i].score_eq1,
                            score_eq2: updatedResults[i].score_eq2,
                            statut: updatedResults[i].statut,
                            round: updatedResults[i].round,
                            nextMatch: updatedResults[i].nextMatch,
                            positionInNextMatch: updatedResults[i].positionInNextMatch,
                            statistics: updatedResults[i].statistics,
                            events: updatedResults[i].events,
                            createdAt: updatedResults[i].createdAt,
                            updatedAt: updatedResults[i].updatedAt
                        )
                    }
                }
                
                for m in updatedResults {
                    dict[m.round, default: []].append(m)
                }
                finishLoading(dict)
            }
        }
    }
    
    private func finishLoading(_ dict: [Int: [MatchDetail]]) {
        var sortedDict = dict
        for key in sortedDict.keys {
            sortedDict[key]?.sort { ($0.date ?? Date()) < ($1.date ?? Date()) }
        }
        rounds = sortedDict
    }
    
    private func matchCard(_ match: MatchDetail) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(match.id_equipe1?.nom ?? "TBD")
                Spacer()
                Text("\(match.score_eq1) - \(match.score_eq2)")
                Spacer()
                Text(match.id_equipe2?.nom ?? "TBD")
            }
            .font(.subheadline)
            .padding(.vertical, 6)
            NavigationLink(destination: MatchDetailView(
                matchId: match.id,
                eq1Id: match.id_equipe1?.id,
                eq2Id: match.id_equipe2?.id,
                coupeCategorie: tournament.categorie
            )) {
                Text("Details")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
