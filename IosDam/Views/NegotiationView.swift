import SwiftUI

struct NegotiationScreen: View {
    @ObservedObject var user: UserModel
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("show_negotiation") var showNegotiation: Bool = false
    @State private var selectedCategorie = "SENIOR"
    @State private var membres: [APIService.TeamMember] = []
    @State private var searchText = ""
    @State private var searchResults: [UserModel] = []
    @State private var isLoading = false
    @State private var memberIds: Set<String> = []
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var academieId: String {
        user.academieId ?? user._id
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            NavigationView {
                VStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Rechercher un joueur...", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            if newValue.isEmpty {
                                searchResults = []
                            } else {
                                isLoading = true
                                APIService.searchJoueurs(query: newValue) { result in
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        switch result {
                                        case .success(let users):
                                            searchResults = users
                                        case .failure:
                                            searchResults = []
                                        }
                                    }
                                }
                            }
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                Picker("Catégorie", selection: $selectedCategorie) {
                    Text("MINIM").tag("MINIM")
                    Text("JUNIOR").tag("JUNIOR")
                    Text("SENIOR").tag("SENIOR")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedCategorie) { _ in
                    loadMembers()
                }

                if isLoading {
                    ProgressView()
                        .padding()
                }

                if searchText.isEmpty {
                    List(membres, id: \._id) { membre in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(membre.prenom) \(membre.nom)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text(membre.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            HStack(spacing: 12) {
                                if user.role == "COACH" {
                                    NavigationLink(destination: EditMaillotView(playerId: membre._id, academyId: academieId)) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                }
                                Button(action: {
                                    removeMember(membre)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(PlainListStyle())
                } else {
                    List(searchResults, id: \._id) { joueur in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(joueur.prenom) \(joueur.nom)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text(joueur.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if memberIds.contains(joueur._id) {
                                HStack(spacing: 12) {
                                    if user.role == "COACH" {
                                        NavigationLink(destination: EditMaillotView(playerId: joueur._id, academyId: academieId)) {
                                            Image(systemName: "pencil")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    Button(action: {
                                        removeJoueur(joueur: joueur)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            } else {
                                Button(action: {
                                    addJoueur(joueur: joueur)
                                }) {
                                    Text("Ajouter")
                                        .foregroundColor(.white)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 10)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(PlainListStyle())
                }
                }
                .padding()
                .navigationBarTitle("Negotiation", displayMode: .inline)
                .navigationBarItems(
                    leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Retour")
                        }
                        .foregroundColor(.green)
                    }
                )
                .alert(isPresented: $showError) {
                    Alert(title: Text("Erreur"), message: Text(errorMessage ?? "Une erreur est survenue"), dismissButton: .default(Text("OK")))
                }
            }
            .onAppear { loadMembers() }
        }
    }

    private func loadMembers() {
        isLoading = true
        APIService.getMembresByAcademieCategorie(idAcademie: academieId, categorie: selectedCategorie) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let list):
                    membres = list
                    memberIds = Set(list.map { $0._id })
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    membres = []
                    memberIds = []
                }
            }
        }
    }

    private func addJoueur(joueur: UserModel) {
        APIService.addJoueurToAcademie(idAcademie: academieId, idJoueur: joueur._id, categorie: selectedCategorie) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    memberIds.insert(joueur._id)
                    let newMember = APIService.TeamMember(_id: joueur._id, nom: joueur.nom, prenom: joueur.prenom, email: joueur.email)
                    membres.append(newMember)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func removeJoueur(joueur: UserModel) {
        APIService.removeJoueurFromAcademie(idAcademie: academieId, idJoueur: joueur._id, categorie: selectedCategorie) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    memberIds.remove(joueur._id)
                    membres.removeAll { $0._id == joueur._id }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func removeMember(_ membre: APIService.TeamMember) {
        APIService.removeJoueurFromAcademie(idAcademie: academieId, idJoueur: membre._id, categorie: selectedCategorie) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    memberIds.remove(membre._id)
                    membres.removeAll { $0._id == membre._id }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

