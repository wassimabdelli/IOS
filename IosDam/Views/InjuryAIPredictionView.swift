//
//  InjuryAIPredictionView.swift
//  fakhripeakplay
//
//  Injury AI Prediction View
//

import SwiftUI

// MARK: - Custom Button Style for iOS 14 Compatibility
struct AIPredictionButtonStyle: ButtonStyle {
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

struct InjuryAIPredictionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedInjuryType = ""
    @State private var selectedSeverity = ""
    @State private var painLevel: Double = 5
    @State private var predictionResult: InjuryPredictionResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let injuryTypes = [
        "Entorse cheville",
        "Déchirure quadriceps",
        "Tendinite genou",
        "Déchirure musculaire",
        "Luxation épaule",
        "Foulure poignet",
        "Fracture tibia",
        "Contusion cuisse",
        "Rupture ligament croisé",
        "Déchirure ischio-jambiers",
        "Élongation mollet",
        "Blessure hanche"
    ]
    
    let severityLevels = ["Légère", "Modérée", "Grave", "Très grave"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                inputCard
                predictButton
                errorSection
                resultSection
            }
            .padding()
        }
        .navigationTitle("Prédiction IA")
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
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Prédiction IA - Blessures")
                .font(.title)
                .fontWeight(.bold)
            Text("Estimer le temps de guérison")
                .font(.subheadline)
                .foregroundColor(Color.secondary)
        }
        .padding(.top)
    }
    
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Informations de la blessure")
                .font(.headline)
            
            injuryTypePicker
            severityPicker
            painLevelSlider
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var injuryTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type de blessure")
                .font(.subheadline)
            Picker("Type", selection: $selectedInjuryType) {
                Text("Sélectionner").tag("")
                ForEach(injuryTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedInjuryType) { _ in
                predictionResult = nil
                errorMessage = nil
            }
        }
    }
    
    private var severityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Niveau de gravité")
                .font(.subheadline)
            Picker("Gravité", selection: $selectedSeverity) {
                Text("Sélectionner").tag("")
                ForEach(severityLevels, id: \.self) { severity in
                    Text(severity).tag(severity)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedSeverity) { _ in
                predictionResult = nil
                errorMessage = nil
            }
        }
    }
    
    private var painLevelSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Niveau de douleur")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(painLevel))/10")
                    .font(.headline)
                    .foregroundColor(Color.primary)
            }
            Slider(value: $painLevel, in: 0...10, step: 1)
                .onChange(of: painLevel) { _ in
                    predictionResult = nil
                    errorMessage = nil
                }
        }
    }
    
    private var predictButton: some View {
        Button(action: predictInjury) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Générer la prédiction")
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(AIPredictionButtonStyle())
        .frame(maxWidth: .infinity)
        .disabled(isLoading || selectedInjuryType.isEmpty || selectedSeverity.isEmpty)
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let error = errorMessage {
            Text(error)
                .foregroundColor(Color.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var resultSection: some View {
        if let result = predictionResult {
            resultCard(result: result)
        }
    }
    
    private func resultCard(result: InjuryPredictionResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Résultats de la prédiction")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            healingDaysView(days: result.healingDays)
            severityView(label: result.severityLabel)
            
            Divider()
            
            recommendationView(recommendation: result.recommendation)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func healingDaysView(days: Float) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Temps de guérison estimé")
                .font(.subheadline)
                .foregroundColor(Color.secondary)
            Text("\(Int(days)) jours")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.blue)
        }
    }
    
    private func severityView(label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Niveau de gravité")
                .font(.subheadline)
                .foregroundColor(Color.secondary)
            Text(label)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.blue)
        }
    }
    
    private func recommendationView(recommendation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommandations")
                .font(.headline)
            Text(recommendation)
                .font(.body)
                .foregroundColor(Color.secondary)
        }
    }
    
    private func predictInjury() {
        guard !selectedInjuryType.isEmpty && !selectedSeverity.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }
        
        isLoading = true
        errorMessage = nil
        predictionResult = nil
        
        // Simuler un délai de traitement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Calcul basique basé sur les inputs (simulation du modèle IA)
            let healingDays = calculateHealingDays(
                injuryType: selectedInjuryType,
                severity: selectedSeverity,
                painLevel: painLevel
            )
            
            let severityIndex = getSeverityIndex(selectedSeverity)
            let severityLabel = getSeverityLabel(severityIndex)
            let recommendation = buildRecommendation(severityIndex: severityIndex)
            
            predictionResult = InjuryPredictionResult(
                healingDays: healingDays,
                severityIndex: severityIndex,
                severityLabel: severityLabel,
                recommendation: recommendation
            )
            
            isLoading = false
        }
    }
    
    private func calculateHealingDays(injuryType: String, severity: String, painLevel: Double) -> Float {
        var baseDays: Float = 0
        
        // Base days selon le type de blessure
        if injuryType.contains("Fracture") || injuryType.contains("Rupture") {
            baseDays = 60
        } else if injuryType.contains("Déchirure") {
            baseDays = 30
        } else if injuryType.contains("Luxation") {
            baseDays = 21
        } else if injuryType.contains("Entorse") || injuryType.contains("Foulure") {
            baseDays = 14
        } else if injuryType.contains("Tendinite") {
            baseDays = 21
        } else {
            baseDays = 14
        }
        
        // Ajustement selon la gravité
        let severityMultiplier: Float = {
            switch severity {
            case "Légère": return 0.5
            case "Modérée": return 1.0
            case "Grave": return 2.0
            case "Très grave": return 3.0
            default: return 1.0
            }
        }()
        
        // Ajustement selon la douleur
        let painMultiplier = Float(painLevel / 10.0)
        
        return baseDays * severityMultiplier * (1.0 + painMultiplier * 0.5)
    }
    
    private func getSeverityIndex(_ severity: String) -> Int {
        switch severity {
        case "Légère": return 0
        case "Modérée": return 1
        case "Grave": return 2
        case "Très grave": return 3
        default: return 1
        }
    }
    
    private func getSeverityLabel(_ index: Int) -> String {
        switch index {
        case 0: return "Légère"
        case 1: return "Modérée"
        case 2: return "Grave"
        case 3: return "Très grave"
        default: return "Modérée"
        }
    }
    
    private func buildRecommendation(severityIndex: Int) -> String {
        switch severityIndex {
        case 0, 1:
            return "Exercices légers, étirements et bonne hydratation. Reprise progressive de l'activité."
        case 2:
            return "Kinésithérapie recommandée, renforcement musculaire progressif, protéines et oméga-3. Repos relatif."
        case 3:
            return "Repos total absolu. Consulter un médecin ou spécialiste. Aucun effort sans avis médical."
        default:
            return "Consulter un professionnel de santé."
        }
    }
}

struct InjuryPredictionResult {
    let healingDays: Float
    let severityIndex: Int
    let severityLabel: String
    let recommendation: String
}

