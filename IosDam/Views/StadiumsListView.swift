
//
// StadiumsListView.swift
// IosDam
//
// List all stadiums

import SwiftUI
import MapKit

struct StadiumsListView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var stadiums: [Terrain] = []
    @State private var filteredStadiums: [Terrain] = []
    @State private var searchText = ""
    @State private var showAvailableOnly = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var viewMode: ViewMode = .list
    @State private var stadiumToDelete: Terrain?
    @State private var showDeleteConfirmation = false
    @State private var activeSheet: ActiveSheet?
    
    enum ViewMode {
        case list, map
    }
    
    enum ActiveSheet: Identifiable {
        case create
        case stadiumMap(Terrain)
        
        var id: Int {
            switch self {
            case .create: return 1
            case .stadiumMap: return 2
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                        }
                        .padding(.trailing, 8)

                        Text("Stadiums")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button(action: {
                            print("🔵 Plus button tapped - opening modal")
                            activeSheet = .create
                            print("🔵 activeSheet set to: \(activeSheet?.id ?? -1)")
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search stadiums...", text: $searchText)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Filters
                    HStack {
                        Toggle("Available Only", isOn: $showAvailableOnly)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // View Mode Toggle
                    Picker("View Mode", selection: $viewMode) {
                        Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                        Label("Map", systemImage: "map").tag(ViewMode.map)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                
                // Content - List or Map
                if viewMode == .list {
                    // Stadiums list
                    if isLoading {
                        Spacer()
                        ProgressView("Loading stadiums...")
                        Spacer()
                    } else if filteredStadiums.isEmpty {
                        Spacer()
                        VStack(spacing: 15) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.gray)
                            Text("No stadiums found")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredStadiums) { stadium in
                                    StadiumCardView(
                                        stadium: stadium,
                                        onDelete: {
                                            stadiumToDelete = stadium
                                            showDeleteConfirmation = true
                                        }
                                    )
                                    .onTapGesture {
                                        activeSheet = .stadiumMap(stadium)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    // Map view
                    if filteredStadiums.isEmpty {
                        VStack {
                            Spacer()
                            Text("No stadiums to display on map")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        StadiumMapView(stadiums: filteredStadiums) { stadium in
                            print("Stadium tapped: \(stadium.name)")
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadStadiums()
        }
        .onChange(of: searchText) { _ in
            filterStadiums()
        }
        .onChange(of: showAvailableOnly) { _ in
            filterStadiums()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .create:
                CreateStadiumView(onStadiumCreated: {
                    print("🟢 Stadium created callback")
                    loadStadiums()
                })
                .onAppear {
                    print("🟢 CreateStadiumView appeared")
                }
                
            case .stadiumMap(let stadium):
                NavigationView {
                    StadiumMapView(stadiums: [stadium]) { selectedStadium in
                        print("Stadium selected: \(selectedStadium.name)")
                    }
                    .navigationTitle(stadium.name)
                    .navigationBarItems(
                        trailing: Button("Fermer") {
                            activeSheet = nil
                        }
                    )
                }
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Supprimer le stade"),
                message: Text("Voulez-vous vraiment supprimer '\(stadiumToDelete?.name ?? "")'? Cette action est irréversible."),
                primaryButton: .destructive(Text("Supprimer")) {
                    if let stadium = stadiumToDelete {
                        deleteStadium(stadium)
                    }
                    stadiumToDelete = nil
                },
                secondaryButton: .cancel(Text("Annuler")) {
                    stadiumToDelete = nil
                }
            )
        }
    }
    
    func loadStadiums() {
        isLoading = true
        
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let currentUser = try? JSONDecoder().decode(UserModel.self, from: data) else {
            isLoading = false
            alertMessage = "User not found. Please log in again."
            showAlert = true
            return
        }
        
        APIService.getAllStadiums { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let allStadiums):
                    self.stadiums = allStadiums.filter { $0.id_academie == currentUser._id }
                    filterStadiums()
                    
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    func filterStadiums() {
        var filtered = stadiums
        
        if !searchText.isEmpty {
            filtered = filtered.filter { stadium in
                stadium.name.lowercased().contains(searchText.lowercased()) ||
                stadium.location_verbal.lowercased().contains(searchText.lowercased())
            }
        }
        
        if showAvailableOnly {
            filtered = filtered.filter { $0.is_available }
        }
        
        filteredStadiums = filtered
    }
    
    func deleteStadium(_ stadium: Terrain) {
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let currentUser = try? JSONDecoder().decode(UserModel.self, from: data) else {
            alertMessage = "User not found. Please log in again."
            showAlert = true
            return
        }
        
        // Check if user owns this stadium
        guard stadium.id_academie == currentUser._id else {
            alertMessage = "Vous ne pouvez supprimer que vos propres stades."
            showAlert = true
            return
        }
        
        APIService.deleteStadium(stadiumId: stadium._id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Remove from local array
                    stadiums.removeAll { $0._id == stadium._id }
                    filterStadiums()
                    alertMessage = "Stade supprimé avec succès"
                    showAlert = true
                    
                case .failure(let error):
                    alertMessage = "Erreur: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Stadium Card View

struct StadiumCardView: View {
    let stadium: Terrain
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(stadium.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(stadium.location_verbal)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text(stadium.is_available ? "Available" : "In Use")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(stadium.is_available ? Color.green : Color.orange)
                        .cornerRadius(15)
                    
                    // Delete Button
                    if let onDelete = onDelete {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            
            HStack(spacing: 20) {
                DetailItem(icon: "person.3.fill", text: "\(stadium.capacity)")
                DetailItem(icon: "figure.american.football", text: "\(stadium.number_of_fields) fields")
                if stadium.has_lights {
                    DetailItem(icon: "lightbulb.fill", text: "Lights")
                }
            }
            
            if !stadium.amenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(stadium.amenities, id: \.self) { amenity in
                            Text(amenity)
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Detail Item

struct DetailItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview

struct StadiumsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StadiumsListView()
        }
    }
}
