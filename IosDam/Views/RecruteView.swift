import SwiftUI

struct RecruteView: View {
    @Environment(\.presentationMode) var presentationMode

    var idAcademie: String?
    @State private var searchText = ""
    @State private var arbitres: [UserModel] = []
    @State private var isLoading = false
    @State private var arbitreStatus: [String: Bool] = [:] // idArbitre -> exists
    
    var body: some View {
        NavigationView {
            VStack {
                let _ = print("DEBUG: RecruteView idAcademie: \(String(describing: idAcademie))")
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Rechercher un arbitre...", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            performSearch(query: newValue)
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                if isLoading {
                    ProgressView()
                        .padding()
                }
                
                // Results List
                List(arbitres, id: \._id) { arbitre in
                    HStack {
                        if let picture = arbitre.picture, !picture.isEmpty,
                           let imageData = Data(base64Encoded: picture),
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("\(arbitre.prenom) \(arbitre.nom)")
                                .font(.headline)
                            Text(arbitre.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if idAcademie != nil {
                            if let exists = arbitreStatus[arbitre._id] {
                                if exists {
                                    Text("Déjà membre")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                } else {
                                    Button(action: {
                                        addStaff(user: arbitre)
                                    }) {
                                        Text("Ajouter")
                                            .foregroundColor(.white)
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 10)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                }
                            } else {
                                ProgressView()
                                    .onAppear {
                                        checkStatus(for: arbitre)
                                    }
                            }
                        } else {
                            Text("Reconnectez-vous")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitle("Recrutement", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Retour")
                    }
                    .foregroundColor(.green)
                },
                trailing: NavigationLink(destination: DetailSaffView(idAcademie: idAcademie)) {
                    Text("Mon Staff")
                        .foregroundColor(.blue)
                }
            )
        }
    }
    
    func performSearch(query: String) {
        guard !query.isEmpty else {
            arbitres = []
            return
        }
        
        isLoading = true
        // Use new unified search logic
        APIService.searchCoachsArbitres(query: query) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let users):
                    arbitres = users
                case .failure(let error):
                    print("Search error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkStatus(for user: UserModel) {
        guard let idAcademie = idAcademie else { return }
        
        let role = user.role.uppercased()
        
        if role == "ARBITRE" {
            APIService.checkArbitreExists(idAcademie: idAcademie, idArbitre: user._id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let exists):
                        arbitreStatus[user._id] = exists
                    case .failure(let error):
                        print("Check status error: \(error.localizedDescription)")
                        arbitreStatus[user._id] = false // Stop loading on error
                    }
                }
            }
        } else if role == "COACH" {
            APIService.isCoachInAcademie(idAcademie: idAcademie, idCoach: user._id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let exists):
                        arbitreStatus[user._id] = exists
                    case .failure(let error):
                        print("Check status error: \(error.localizedDescription)")
                        arbitreStatus[user._id] = false // Stop loading on error
                    }
                }
            }
        } else {
            // Unknown role, stop loading
            print("Unknown role: \(user.role)")
            arbitreStatus[user._id] = false
        }
    }
    
    func addStaff(user: UserModel) {
        guard let idAcademie = idAcademie else { return }
        
        if user.role == "ARBITRE" {
            APIService.addArbitreToAcademie(idAcademie: idAcademie, idArbitre: user._id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        arbitreStatus[user._id] = true
                    case .failure(let error):
                        print("Add arbitre error: \(error.localizedDescription)")
                    }
                }
            }
        } else if user.role == "COACH" {
            APIService.addCoachToAcademie(idAcademie: idAcademie, idCoach: user._id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        arbitreStatus[user._id] = true
                    case .failure(let error):
                        print("Add coach error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}


