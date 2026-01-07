//
//  InjuryHomeView.swift
//  fakhripeakplay
//
//  Home screen for Injury Management
//

import SwiftUI

// MARK: - Custom Button Styles for iOS 14 Compatibility

struct ProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue)
            .cornerRadius(8)
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(Color.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? Color.blue.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
            )
    }
}

struct GreenProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.green.opacity(0.7) : Color.green)
            .cornerRadius(8)
    }
}

struct InjuryHomeView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("user_role") var currentUserRole: String = "JOUEUR"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Gestion des Blessures & Santé")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    // Player Card - Only for JOUEUR
                    if currentUserRole == "JOUEUR" {
                        NavigationLink(destination: PlayerInjuryView()) {
                            InjuryRoleCard(
                                title: "Joueur",
                                description: """
                                • Déclarer une blessure
                                • Voir mes blessures
                                • Suivre l'évolution
                                • Ajouter des notes
                                """,
                                color: .blue
                            )
                        }
                    }
                    
                    // Academy Card - For OWNER and COACH
                    if currentUserRole == "OWNER" || currentUserRole == "COACH" {
                        NavigationLink(destination: AcademyInjuryView()) {
                            InjuryRoleCard(
                                title: "Académie",
                                description: """
                                • Voir toutes les blessures
                                • Mettre à jour les statuts
                                • Ajouter des recommendations
                                • Gérer les joueurs
                                """,
                                color: .green
                            )
                        }
                    }
                    
                    // Referee Card - For ARBITRE and COACH
                    if currentUserRole == "ARBITRE" || currentUserRole == "COACH" {
                        NavigationLink(destination: RefereeInjuryView()) {
                            InjuryRoleCard(
                                title: "Arbitre",
                                description: """
                                • Voir les joueurs indisponibles
                                • Consulter les blessures
                                • Vérifier les statuts
                                """,
                                color: .orange
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Blessures")
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Retour")
                }
                .foregroundColor(.blue)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct InjuryRoleCard: View {
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(description)
                .font(.body)
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Player Injury View
struct PlayerInjuryView: View {
    @StateObject private var viewModel = InjuryViewModel()
    @StateObject private var userPreferences = UserPreferences()
    @State private var selectedTab = 0
    @State private var injuryType = ""
    @State private var severity = ""
    @State private var description = ""
    @State private var evolutionInjuryId = ""
    @State private var painLevel: Double = 5
    @State private var evolutionNote = ""
    
    let injuryTypes = ["Fracture", "Entorse", "Déchirure musculaire", "Contusion", "Luxation", "Tendinite", "Autre"]
    let severityLevels = ["Légère", "Modérée", "Grave", "Très grave"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            Picker("", selection: $selectedTab) {
                Text("Déclarer").tag(0)
                Text("Mes Blessures").tag(1)
                Text("Évolution").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content based on selected tab
            ScrollView {
                switch selectedTab {
                case 0:
                    createInjuryTab
                case 1:
                    myInjuriesTab
                case 2:
                    evolutionTab
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("Mes Blessures")
        .onAppear {
            // Utiliser le User ID configuré ou le User ID de test par défaut
            let userId = userPreferences.userId ?? Config.DEFAULT_TEST_USER_ID
            if userPreferences.userId == nil && Config.ENABLE_TEST_MODE {
                print("ℹ️ Mode test: chargement des blessures avec User ID par défaut '\(userId)'")
            }
            viewModel.loadMyInjuries(playerId: userId)
        }
        .onChange(of: viewModel.errorMessage) { errorMessage in
            if errorMessage != nil {
                // L'erreur sera affichée dans le message d'erreur ci-dessous
            }
        }
    }
    
    private var createInjuryTab: some View {
        VStack(spacing: 20) {
            injuryTypeSelector
            severitySelector
            descriptionEditor
            testModeIndicator
            submitInjuryButton
            createInjuryFeedback
            createInjuryErrorFeedback
            generalErrorFeedback
        }
        .padding()
    }
    
    private var injuryTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type de blessure")
                .font(.headline)
            Picker("Type", selection: $injuryType) {
                Text("Sélectionner").tag("")
                ForEach(injuryTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var severitySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Niveau de gravité")
                .font(.headline)
            Picker("Gravité", selection: $severity) {
                Text("Sélectionner").tag("")
                ForEach(severityLevels, id: \.self) { sev in
                    Text(sev).tag(sev)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var descriptionEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
            TextEditor(text: $description)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3))
                )
        }
    }
    
    @ViewBuilder
    private var testModeIndicator: some View {
        if Config.ENABLE_TEST_MODE {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(Color.blue)
                Text("Mode test: User ID = \(userPreferences.userId ?? Config.DEFAULT_TEST_USER_ID)")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            .padding(.horizontal)
        }
    }
    
    private var submitInjuryButton: some View {
        let isDisabled = injuryType.isEmpty || severity.isEmpty || description.isEmpty || viewModel.createInjuryState == .loading
        
        return Button(action: submitInjury) {
            Group {
                if case .loading = viewModel.createInjuryState {
                    HStack {
                        ProgressView()
                        Text("Déclaration en cours...")
                    }
                } else {
                    Text("Déclarer la blessure")
                }
            }
        }
        .buttonStyle(ProminentButtonStyle())
        .disabled(isDisabled)
    }
    
    private func submitInjury() {
        print("🔘 Bouton 'Déclarer la blessure' cliqué")
        let userId = userPreferences.userId ?? Config.DEFAULT_TEST_USER_ID
        if userPreferences.userId == nil && Config.ENABLE_TEST_MODE {
            print("ℹ️ Mode test activé: utilisation de User ID par défaut '\(userId)'")
        }
        
        print("📋 Données de la blessure:")
        print("   - Type: '\(injuryType)'")
        print("   - Gravité: '\(severity)'")
        print("   - Description: '\(description)'")
        print("   - Player ID: '\(userId)'")
        
        viewModel.createInjury(
            type: injuryType,
            severity: severity,
            description: description,
            playerId: userId
        )
    }
    
    @ViewBuilder
    private var createInjuryFeedback: some View {
        if case .success(let injury) = viewModel.createInjuryState {
            successFeedbackView(injury: injury)
        }
    }
    
    private func successFeedbackView(injury: Injury) -> some View {
        VStack(spacing: 12) {
            successHeader
            injuryIdDisplay(injury: injury)
            okButton
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var successHeader: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.green)
            Text("Blessure déclarée avec succès !")
                .foregroundColor(Color.green)
                .fontWeight(.semibold)
        }
    }
    
    private var okButton: some View {
        Button("OK") {
            resetCreateForm()
        }
        .buttonStyle(ProminentButtonStyle())
    }
    
    private func injuryIdDisplay(injury: Injury) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            injuryIdLabel
            injuryIdRow(injuryId: injury.id)
            injuryIdHint
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var injuryIdLabel: some View {
        Text("ID de la blessure:")
            .font(.caption)
            .foregroundColor(Color.secondary)
    }
    
    private func injuryIdRow(injuryId: String) -> some View {
        HStack {
            Text(injuryId)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            Button(action: {
                UIPasteboard.general.string = injuryId
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(Color.blue)
            }
        }
    }
    
    private var injuryIdHint: some View {
        Text("Copiez cet ID pour l'utiliser dans l'onglet Évolution")
            .font(.caption2)
            .foregroundColor(Color.secondary)
    }
    
    private func resetCreateForm() {
        injuryType = ""
        severity = ""
        description = ""
        viewModel.resetCreateInjuryState()
        let userId = userPreferences.userId ?? Config.DEFAULT_TEST_USER_ID
        viewModel.loadMyInjuries(playerId: userId)
    }
    
    @ViewBuilder
    private var createInjuryErrorFeedback: some View {
        if case .error(let message) = viewModel.createInjuryState {
            errorFeedbackView(message: message)
        }
    }
    
    private func errorFeedbackView(message: String) -> some View {
        VStack(spacing: 12) {
            errorHeader
            errorMessage(message: message)
            retryButton
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var errorHeader: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.red)
            Text("Erreur")
                .foregroundColor(Color.red)
                .fontWeight(.semibold)
        }
    }
    
    private func errorMessage(message: String) -> some View {
        Text(message)
            .font(.body)
            .foregroundColor(Color.secondary)
            .multilineTextAlignment(.center)
    }
    
    private var retryButton: some View {
        Button("Réessayer") {
            viewModel.resetCreateInjuryState()
        }
        .buttonStyle(OutlinedButtonStyle())
    }
    
    @ViewBuilder
    private var generalErrorFeedback: some View {
        if let errorMessage = viewModel.errorMessage {
            generalErrorView(message: errorMessage)
        }
    }
    
    private func generalErrorView(message: String) -> some View {
        VStack(spacing: 12) {
            generalErrorHeader
            generalErrorMessage(message: message)
            clearErrorButton
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var generalErrorHeader: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color.red)
            Text("Erreur")
                .foregroundColor(Color.red)
                .fontWeight(.semibold)
        }
    }
    
    private func generalErrorMessage(message: String) -> some View {
        Text(message)
            .font(.body)
            .foregroundColor(Color.secondary)
            .multilineTextAlignment(.center)
    }
    
    private var clearErrorButton: some View {
        Button("OK") {
            viewModel.clearError()
        }
        .buttonStyle(OutlinedButtonStyle())
    }
    
    private var myInjuriesTab: some View {
        Group {
            myInjuriesContent
        }
    }
    
    @ViewBuilder
    private var myInjuriesContent: some View {
        switch viewModel.myInjuries {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        case .success(let injuries):
            if injuries.isEmpty {
                emptyInjuriesView
            } else {
                injuriesListView(injuries: injuries)
            }
        case .error(let message):
            errorInjuriesView(message: message)
        }
    }
    
    private var emptyInjuriesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bandage.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.gray.opacity(0.5))
            Text("Aucune blessure déclarée")
                .font(.headline)
                .foregroundColor(Color.secondary)
            Text("Vous n'avez pas encore déclaré de blessure")
                .font(.caption)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func injuriesListView(injuries: [Injury]) -> some View {
        LazyVStack(spacing: 16) {
            ForEach(injuries) { injury in
                InjuryCardView(injury: injury)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private func errorInjuriesView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.red.opacity(0.5))
            Text("Erreur")
                .font(.headline)
                .foregroundColor(Color.red)
            Text(message)
                .font(.body)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
            Button("Réessayer") {
                let userId = userPreferences.userId ?? Config.DEFAULT_TEST_USER_ID
                viewModel.loadMyInjuries(playerId: userId)
            }
            .buttonStyle(ProminentButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var evolutionTab: some View {
        VStack(spacing: 20) {
            evolutionInjurySelector
            
            painLevelSlider
            
            evolutionNoteField
            
            evolutionSubmitButton
        }
        .padding()
    }
    
    private var evolutionInjurySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sélectionner une blessure")
                .font(.headline)
            
            if case .success(let injuries) = viewModel.myInjuries, !injuries.isEmpty {
                injuryPicker(injuries: injuries)
            } else {
                TextField("ID de la blessure", text: $evolutionInjuryId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if !evolutionInjuryId.isEmpty {
                injuryIdDisplay
            }
        }
    }
    
    private func injuryPicker(injuries: [Injury]) -> some View {
        Picker("Blessure", selection: $evolutionInjuryId) {
            Text("Sélectionner une blessure").tag("")
            ForEach(injuries) { injury in
                Text("\(injury.type) - \(injury.severity)").tag(injury.id)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    private var injuryIdDisplay: some View {
        HStack {
            Text("ID: \(evolutionInjuryId)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color.secondary)
            Spacer()
            Button(action: {
                UIPasteboard.general.string = evolutionInjuryId
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(Color.blue)
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(6)
    }
    
    private var painLevelSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Niveau de douleur: \(Int(painLevel))/10")
                .font(.headline)
            Slider(value: $painLevel, in: 0...10, step: 1)
        }
    }
    
    private var evolutionNoteField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note")
                .font(.headline)
            TextEditor(text: $evolutionNote)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
        }
    }
    
    private var evolutionSubmitButton: some View {
        Button(action: {
            let userId = userPreferences.userId ?? Config.DEFAULT_TEST_USER_ID
            viewModel.addEvolution(
                injuryId: evolutionInjuryId,
                painLevel: Int(painLevel),
                note: evolutionNote,
                playerId: userId
            )
        }) {
            if case .loading = viewModel.addEvolutionState {
                ProgressView()
            } else {
                Text("Ajouter l'évolution")
            }
        }
        .buttonStyle(ProminentButtonStyle())
        .disabled(evolutionInjuryId.isEmpty || evolutionNote.isEmpty)
    }
}

// MARK: - Academy Injury View
struct AcademyInjuryView: View {
    @StateObject private var viewModel = InjuryViewModel()
    @State private var selectedTab = 0
    @State private var statusInjuryId = ""
    @State private var selectedStatus = ""
    @State private var recInjuryId = ""
    @State private var recommendation = ""
    
    let statusOptions = ["apte", "surveille", "indisponible"]
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Liste").tag(0)
                Text("Mise à jour").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            ScrollView {
                switch selectedTab {
                case 0:
                    injuriesListTab
                case 1:
                    updateTab
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle("Blessures Académie")
        .onAppear {
            // Pour tester, utilisez un academyId par défaut
            viewModel.loadAcademyInjuries(academyId: "test-academy-id")
        }
    }
    
    private var injuriesListTab: some View {
        Group {
            academyInjuriesContent
        }
    }
    
    @ViewBuilder
    private var academyInjuriesContent: some View {
        switch viewModel.academyInjuries {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        case .success(let injuries):
            if injuries.isEmpty {
                emptyAcademyInjuriesView
            } else {
                academyInjuriesListView(injuries: injuries)
            }
        case .error(let message):
            errorAcademyInjuriesView(message: message)
        }
    }
    
    private var emptyAcademyInjuriesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bandage.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.gray.opacity(0.5))
            Text("Aucune blessure")
                .font(.headline)
                .foregroundColor(Color.secondary)
            Text("Aucune blessure n'a été déclarée pour cette académie")
                .font(.caption)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func academyInjuriesListView(injuries: [Injury]) -> some View {
        LazyVStack(spacing: 16) {
            ForEach(injuries) { injury in
                InjuryCardView(injury: injury)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private func errorAcademyInjuriesView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.red.opacity(0.5))
            Text("Erreur")
                .font(.headline)
                .foregroundColor(Color.red)
            Text(message)
                .font(.body)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
            Button("Réessayer") {
                viewModel.loadAcademyInjuries(academyId: "test-academy-id")
            }
            .buttonStyle(ProminentButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var updateTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                updateStatusSection
                
                Divider()
                    .padding(.vertical, 8)
                
                recommendationSection
            }
            .padding()
        }
    }
    
    private var updateStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(Color.blue)
                Text("Mettre à jour le statut")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            statusInjurySelector
            
            statusPicker
            
            updateStatusButton
            
            updateStatusFeedback
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var statusInjurySelector: some View {
        if case .success(let injuries) = viewModel.academyInjuries, !injuries.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sélectionner une blessure")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
                statusInjuryPicker(injuries: injuries)
            }
        } else {
            TextField("ID de la blessure", text: $statusInjuryId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        if !statusInjuryId.isEmpty {
            statusIdDisplay
        }
    }
    
    private func statusInjuryPicker(injuries: [Injury]) -> some View {
        Picker("Blessure", selection: $statusInjuryId) {
            Text("Sélectionner une blessure").tag("")
            ForEach(injuries) { injury in
                Text("\(injury.type) - \(injury.severity)").tag(injury.id)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    private var statusIdDisplay: some View {
        HStack {
            Text("ID: \(statusInjuryId)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color.secondary)
            Spacer()
            Button(action: {
                UIPasteboard.general.string = statusInjuryId
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(Color.blue)
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(6)
    }
    
    private var statusPicker: some View {
        Picker("Statut", selection: $selectedStatus) {
            Text("Sélectionner").tag("")
            ForEach(statusOptions, id: \.self) { status in
                Text(status.capitalized).tag(status)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    private var updateStatusButton: some View {
        Button(action: {
            viewModel.updateStatus(injuryId: statusInjuryId, status: selectedStatus)
        }) {
            HStack {
                if case .loading = viewModel.updateStatusState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("Mettre à jour le statut")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(ProminentButtonStyle())
        .disabled(statusInjuryId.isEmpty || selectedStatus.isEmpty || viewModel.updateStatusState == .loading)
    }
    
    @ViewBuilder
    private var updateStatusFeedback: some View {
        if case .success(let injury) = viewModel.updateStatusState {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.green)
                Text("Statut mis à jour: \(injury.status.capitalized)")
                    .foregroundColor(Color.green)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    viewModel.resetUpdateStatusState()
                    viewModel.loadAcademyInjuries(academyId: "test-academy-id")
                    statusInjuryId = ""
                    selectedStatus = ""
                }
            }
        }
        
        if case .error(let message) = viewModel.updateStatusState {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.red)
                Text(message)
                    .foregroundColor(Color.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color.green)
                Text("Ajouter une recommandation")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            recommendationInjurySelector
            
            recommendationTextField
            
            addRecommendationButton
            
            recommendationFeedback
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var recommendationInjurySelector: some View {
        if case .success(let injuries) = viewModel.academyInjuries, !injuries.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sélectionner une blessure")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary)
                recommendationInjuryPicker(injuries: injuries)
            }
        } else {
            TextField("ID de la blessure", text: $recInjuryId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        if !recInjuryId.isEmpty {
            recIdDisplay
        }
    }
    
    private func recommendationInjuryPicker(injuries: [Injury]) -> some View {
        Picker("Blessure", selection: $recInjuryId) {
            Text("Sélectionner une blessure").tag("")
            ForEach(injuries) { injury in
                Text("\(injury.type) - \(injury.severity)").tag(injury.id)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    private var recIdDisplay: some View {
        HStack {
            Text("ID: \(recInjuryId)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color.secondary)
            Spacer()
            Button(action: {
                UIPasteboard.general.string = recInjuryId
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(Color.blue)
            }
        }
        .padding(8)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(6)
    }
    
    private var recommendationTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommandation")
                .font(.headline)
                .foregroundColor(Color.secondary)
            
            ZStack(alignment: .topLeading) {
                if recommendation.isEmpty {
                    Text("Entrez votre recommandation ici...")
                        .font(.body)
                        .foregroundColor(Color.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: $recommendation)
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var addRecommendationButton: some View {
        Button(action: {
            viewModel.addRecommendation(injuryId: recInjuryId, recommendation: recommendation)
        }) {
            HStack {
                if case .loading = viewModel.addRecommendationState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "plus.circle.fill")
                }
                Text("Ajouter la recommandation")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(GreenProminentButtonStyle())
        .disabled(recInjuryId.isEmpty || recommendation.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.addRecommendationState == .loading)
    }
    
    @ViewBuilder
    private var recommendationFeedback: some View {
        if case .success = viewModel.addRecommendationState {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.green)
                Text("Recommandation ajoutée avec succès")
                    .foregroundColor(Color.green)
                    .fontWeight(.semibold)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    viewModel.resetAddRecommendationState()
                    viewModel.loadAcademyInjuries(academyId: "test-academy-id")
                    recInjuryId = ""
                    recommendation = ""
                }
            }
        }
        
        if case .error(let message) = viewModel.addRecommendationState {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.red)
                Text(message)
                    .foregroundColor(Color.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Referee Injury View
struct RefereeInjuryView: View {
    @StateObject private var viewModel = InjuryViewModel()
    
    var body: some View {
        ScrollView {
            refereeContent
        }
        .navigationTitle("Joueurs Indisponibles")
        .onAppear {
            viewModel.loadUnavailablePlayers()
        }
    }
    
    @ViewBuilder
    private var refereeContent: some View {
        switch viewModel.unavailablePlayers {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        case .success(let injuries):
            if injuries.isEmpty {
                emptyUnavailablePlayersView
            } else {
                unavailablePlayersListView(injuries: injuries)
            }
        case .error(let message):
            errorUnavailablePlayersView(message: message)
        }
    }
    
    private var emptyUnavailablePlayersView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.green.opacity(0.5))
            Text("Aucun joueur indisponible")
                .font(.headline)
                .foregroundColor(Color.secondary)
            Text("Tous les joueurs sont disponibles")
                .font(.caption)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func unavailablePlayersListView(injuries: [Injury]) -> some View {
        LazyVStack(spacing: 16) {
            ForEach(injuries) { injury in
                InjuryCardView(injury: injury)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private func errorUnavailablePlayersView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.red.opacity(0.5))
            Text("Erreur")
                .font(.headline)
                .foregroundColor(Color.red)
            Text(message)
                .font(.body)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
            Button("Réessayer") {
                viewModel.loadUnavailablePlayers()
            }
            .buttonStyle(ProminentButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// Helper struct for alert
struct ErrorMessage: Identifiable {
    let id: String
    let message: String
}

// MARK: - Injury Card View
struct InjuryCardView: View {
    let injury: Injury
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header avec type et statut
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(injury.type.capitalized)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Gravité: \(injury.severity.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                }
                
                Spacer()
                
                // Badge de statut
                Text(injury.status.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(injury.statusColor.opacity(0.2))
                    .foregroundColor(injury.statusColor)
                    .cornerRadius(12)
            }
            
            Divider()
            
            // Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.secondary)
                    .textCase(.uppercase)
                Text(injury.description)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            // ID de la blessure (compact)
            HStack {
                Image(systemName: "number")
                    .font(.caption2)
                    .foregroundColor(Color.secondary)
                Text(injury.id)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color.secondary)
                    .lineLimit(1)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = injury.id
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copier")
                    }
                    .font(.caption)
                    .foregroundColor(Color.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
            
            // Recommandations si disponibles
            if let recommendations = injury.recommendations, !recommendations.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .font(.caption)
                            .foregroundColor(Color.green)
                        Text("Recommandations médicales")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.secondary)
                            .textCase(.uppercase)
                    }
                    
                    ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(Color.green)
                                .padding(.top, 2)
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(12)
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Dernière évolution si disponible
            if let lastEvolution = injury.lastEvolution {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundColor(Color.blue)
                        Text("Dernière évolution")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.secondary)
                            .textCase(.uppercase)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Niveau de douleur")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundColor(lastEvolution.painLevel >= 7 ? .red : (lastEvolution.painLevel >= 4 ? .orange : .green))
                                Text("\(lastEvolution.painLevel)/10")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(lastEvolution.painLevel >= 7 ? .red : (lastEvolution.painLevel >= 4 ? .orange : .green))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if !lastEvolution.note.isEmpty {
                        Text(lastEvolution.note)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

