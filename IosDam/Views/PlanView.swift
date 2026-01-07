import SwiftUI
import UIKit

struct PlanView: View {
    var idAcademie: String
    var idJoueur: String
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategorie = "SENIOR"
    @State private var joueurs: [APIService.TeamMember] = []
    @State private var isLoading = false
    @State private var remplacents: [APIService.TeamMember] = []
    @State private var selectedAId: String? = nil
    @State private var selectedBId: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
                Picker("Catégorie", selection: Binding(
                    get: { selectedCategorie },
                    set: { selectedCategorie = $0; loadJoueurs() }
                )) {
                    Text("MINIM").tag("MINIM")
                    Text("JUNIOR").tag("JUNIOR")
                    Text("SENIOR").tag("SENIOR")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(remplacents.indices, id: \.self) { idx in
                            let p = remplacents[idx]
                            playerDot(p, color: .gray)
                                .onTapGesture { selectSwap(p._id) }
                        }
                    }
                    .padding(.horizontal)
                }

                if isLoading {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium).padding()
                }

                ZStack {
                    Image("planjeu")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 460)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                        .padding(.horizontal)
                    GeometryReader { proxy in
                        let size = proxy.size
                        let limited = Array(joueurs.prefix(8))
                        let parts = splitPlayers(limited)
                        renderLine(parts.gk, color: .yellow, y: 0.18, size: size)
                        renderLine(parts.defs, color: .blue, y: 0.38, size: size)
                        renderLine(parts.mids, color: .green, y: 0.60, size: size)
                        renderLine(parts.att, color: .red, y: 0.82, size: size)
                    }
                    .frame(height: 460)
                }
                Spacer()
            }
            .navigationBarTitle("Plan Jeu", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack { Image(systemName: "chevron.left"); Text("Retour") }
                        .foregroundColor(.blue)
                }
            )
        .onAppear { loadJoueurs() }
    }

    private func loadJoueurs() {
        print("DEBUG: loadJoueurs called. Academie: \(idAcademie), Category: \(selectedCategorie)")
        isLoading = true
        selectedAId = nil
        selectedBId = nil
        
        // Enforce roster size first
        print("DEBUG: Calling enforceRosterSizes...")
        APIService.enforceRosterSizes(idAcademie: idAcademie, categorie: selectedCategorie) { result in
            print("DEBUG: enforceRosterSizes completed. Result: \(result)")
            // Regardless of success or failure, we try to load the players.
            // If enforcement failed, we might show an error, but we still want to see the current state.
            if case .failure(let error) = result {
                print("Error enforcing roster: \(error.localizedDescription)")
            }
            
            // Proceed to fetch players
            self.fetchPlayers()
        }
    }
    
    private func fetchPlayers() {
        let group = DispatchGroup()
        
        group.enter()
        APIService.getJoueursByRole(idAcademie: idAcademie, categorie: selectedCategorie, role: "starter") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let list):
                    self.joueurs = list
                case .failure:
                    self.joueurs = []
                }
                group.leave()
            }
        }
        
        group.enter()
        APIService.getJoueursByRole(idAcademie: idAcademie, categorie: selectedCategorie, role: "substitute") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let list):
                    self.remplacents = list
                case .failure:
                    self.remplacents = []
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }

    private func selectSwap(_ id: String) {
        print("DEBUG: selectSwap called for \(id)")
        if selectedAId == nil {
            selectedAId = id
            print("DEBUG: Selected A: \(id)")
        } else if selectedAId == id {
            selectedAId = nil
            print("DEBUG: Deselected A")
        } else if selectedBId == nil {
            selectedBId = id
            print("DEBUG: Selected B: \(id)")
            if let idA = selectedAId, let idB = selectedBId {
                print("DEBUG: Swapping \(idA) and \(idB)")
                swapPlayers(id1: idA, id2: idB)
            }
        } else if selectedBId == id {
            selectedBId = nil
            print("DEBUG: Deselected B")
        } else {
            selectedAId = id
            selectedBId = nil
            print("DEBUG: Reset selection to A: \(id)")
        }
    }
    
    private func swapPlayers(id1: String, id2: String) {
        isLoading = true
        print("DEBUG: Calling API swapPlayers")
        APIService.swapPlayers(idAcademie: idAcademie, idStarter: id1, idSubstitute: id2, categorie: selectedCategorie) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    print("DEBUG: Swap success, reloading players")
                    loadJoueurs() // Reload to reflect changes
                    selectedAId = nil
                    selectedBId = nil
                case .failure(let error):
                    print("DEBUG: Swap error: \(error.localizedDescription)")
                    // Optionally show alert
                    selectedAId = nil
                    selectedBId = nil
                }
            }
        }
    }

    private func playerDot(_ user: APIService.TeamMember, color: Color = .green) -> some View {
        let isSelected = (selectedAId == user._id || selectedBId == user._id)
        return VStack(spacing: 4) {
            Text(initials(for: user))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(gradient: Gradient(colors: [isSelected ? .orange : color, (isSelected ? .orange : color).opacity(0.8)] ), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(isSelected ? Color.white : Color.white.opacity(0.9), lineWidth: isSelected ? 4 : 2))
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(), value: isSelected)
            
            Text(user.nom) // Or user.prenom + " " + user.nom
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2, x: 0, y: 1)
        }
    }

    private func splitPlayers(_ players: [APIService.TeamMember]) -> (gk: [APIService.TeamMember], defs: [APIService.TeamMember], mids: [APIService.TeamMember], att: [APIService.TeamMember]) {
        let gkCount = min(1, players.count)
        let gk = Array(players.prefix(gkCount))
        let afterGk = Array(players.dropFirst(gkCount))
        let defsCount = min(3, afterGk.count)
        let defs = Array(afterGk.prefix(defsCount))
        let afterDefs = Array(afterGk.dropFirst(defsCount))
        let midsCount = min(3, afterDefs.count)
        let mids = Array(afterDefs.prefix(midsCount))
        let afterMids = Array(afterDefs.dropFirst(midsCount))
        let attCount = min(1, afterMids.count)
        let att = Array(afterMids.prefix(attCount))
        return (gk, defs, mids, att)
    }

    private func linePoints(count: Int, y: CGFloat, in size: CGSize) -> [CGPoint] {
        let xs: [CGFloat]
        switch count {
        case 0: xs = []
        case 1: xs = [0.5]
        case 2: xs = [0.35, 0.65]
        case 3: xs = [0.22, 0.5, 0.78]
        case 4: xs = [0.15, 0.38, 0.62, 0.85]
        default:
            var tmp: [CGFloat] = []
            let step = 1.0 / Double(count + 1)
            for i in 1...count { tmp.append(CGFloat(Double(i) * step)) }
            xs = tmp
        }
        return xs.map { CGPoint(x: size.width * $0, y: size.height * y) }
    }

    @ViewBuilder
    private func renderLine(_ players: [APIService.TeamMember], color: Color, y: CGFloat, size: CGSize) -> some View {
        let pts = linePoints(count: players.count, y: y, in: size)
        ForEach(0..<players.count, id: \.self) { idx in
            playerDot(players[idx], color: color)
                .onTapGesture { selectSwap(players[idx]._id) }
                .position(x: pts[idx].x, y: pts[idx].y)
        }
    }

    struct ActivityIndicator: UIViewRepresentable {
        @Binding var isAnimating: Bool
        let style: UIActivityIndicatorView.Style
        func makeUIView(context: Context) -> UIActivityIndicatorView { UIActivityIndicatorView(style: style) }
        func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
            isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        }
    }
    

    private func initials(for user: APIService.TeamMember) -> String {
        let first = user.prenom.first.map(String.init) ?? ""
        let last = user.nom.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}


