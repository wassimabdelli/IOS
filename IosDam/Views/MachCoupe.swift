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
            if results.isEmpty {
                isLoading = false
                errorMessage = "No matches found"
                return
            }
            
            // Fallback for missing names
            var idsToFetch: Set<String> = []
            for m in results {
                if let t1 = m.id_equipe1, t1.nom == nil || t1.nom == "Unknown" || t1.nom == "Fetching..." {
                    idsToFetch.insert(t1.id)
                }
                if let t2 = m.id_equipe2, t2.nom == nil || t2.nom == "Unknown" || t2.nom == "Fetching..." {
                    idsToFetch.insert(t2.id)
                }
            }
            
            if !idsToFetch.isEmpty {
                APIService.getNames(ids: Array(idsToFetch)) { nameResult in
                    DispatchQueue.main.async {
                        if case .success(let nameMap) = nameResult {
                            for i in 0..<results.count {
                                if let t1Id = results[i].id_equipe1?.id, let n1 = nameMap[t1Id] {
                                    results[i].id_equipe1?.nom = n1
                                }
                                if let t2Id = results[i].id_equipe2?.id, let n2 = nameMap[t2Id] {
                                    results[i].id_equipe2?.nom = n2
                                }
                            }
                        }
                        self.isLoading = false
                        var dict: [Int: [MatchDetail]] = [:]
                        for m in results {
                            dict[m.round, default: []].append(m)
                        }
                        self.finishLoading(dict)
                    }
                }
            } else {
                isLoading = false
                var dict: [Int: [MatchDetail]] = [:]
                for m in results {
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
