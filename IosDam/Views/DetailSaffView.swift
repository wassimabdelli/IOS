import SwiftUI

struct DetailSaffView: View {
    var idAcademie: String?
    
    @State private var staffMembers: [UserModel] = []
    @State private var coachMembers: [UserModel] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedTab = 0 // 0: Arbitres, 1: Coachs
    
    @State private var showingDeleteAlert = false
    @State private var memberToDelete: UserModel?
    
    var filteredStaff: [UserModel] {
        let members = selectedTab == 0 ? staffMembers : coachMembers
        if searchText.isEmpty {
            return members
        } else {
            return members.filter { member in
                let fullName = "\(member.prenom) \(member.nom)".lowercased()
                return fullName.contains(searchText.lowercased()) || member.email.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        VStack {
            // Segmented Control
            Picker("Type de Staff", selection: $selectedTab) {
                Text("Arbitres").tag(0)
                Text("Coachs").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Rechercher dans mon staff...", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if isLoading {
                ProgressView()
                    .padding()
            } else if filteredStaff.isEmpty {
                Text("Aucun membre trouvé.")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            List(filteredStaff, id: \._id) { member in
                HStack {
                    if let picture = member.picture, !picture.isEmpty,
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
                        Text("\(member.prenom) \(member.nom)")
                            .font(.headline)
                        Text(member.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        memberToDelete = member
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationBarTitle("Mon Staff", displayMode: .inline)
        .onAppear {
            fetchStaff()
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Confirmer la suppression"),
                message: Text("Voulez-vous vraiment retirer \(memberToDelete?.prenom ?? "ce membre") du staff ?"),
                primaryButton: .destructive(Text("Supprimer")) {
                    if let member = memberToDelete {
                        if selectedTab == 0 {
                            removeArbitre(member)
                        } else {
                            removeCoach(member)
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func fetchStaff() {
        guard let idAcademie = idAcademie else { return }
        isLoading = true
        
        let group = DispatchGroup()
        
        group.enter()
        APIService.getArbitresByAcademie(idAcademie: idAcademie) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let users):
                    staffMembers = users
                case .failure(let error):
                    print("Error fetching arbitres: \(error.localizedDescription)")
                }
                group.leave()
            }
        }
        
        group.enter()
        APIService.getCoachByAcademie(idAcademie: idAcademie) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let users):
                    coachMembers = users
                case .failure(let error):
                    print("Error fetching coaches: \(error.localizedDescription)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
    
    func removeArbitre(_ arbitre: UserModel) {
        guard let idAcademie = idAcademie else { return }
        APIService.removeArbitreFromAcademie(idAcademie: idAcademie, idArbitre: arbitre._id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = staffMembers.firstIndex(where: { $0._id == arbitre._id }) {
                        staffMembers.remove(at: index)
                    }
                case .failure(let error):
                    print("Error removing arbitre: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func removeCoach(_ coach: UserModel) {
        guard let idAcademie = idAcademie else { return }
        APIService.removeCoachFromAcademie(idAcademie: idAcademie, idCoach: coach._id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = coachMembers.firstIndex(where: { $0._id == coach._id }) {
                        coachMembers.remove(at: index)
                    }
                case .failure(let error):
                    print("Error removing coach: \(error.localizedDescription)")
                }
            }
        }
    }
}


