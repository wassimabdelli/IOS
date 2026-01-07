//
//  FootballDietPredictionView.swift
//  fakhripeakplay
//
//  Football Diet Prediction View
//

import SwiftUI

struct FootballDietPredictionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = FootballDietViewModel()
    
    @State private var age: String = ""
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var trainingIntensity: Float = 5.0
    @State private var matchesPerWeek: Float = 2.0
    @State private var bodyfatPercent: Float = 15.0
    @State private var selectedPosition: String = ""
    @State private var selectedGoal: String = ""
    @State private var selectedInjuryRisk: String = ""
    
    let positions = ["Gardien", "Défenseur", "Milieu", "Attaquant"]
    let goals = ["Perte de poids", "Gain de masse", "Maintien", "Performance"]
    let injuryRisks = ["Faible", "Modéré", "Élevé"]
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    personalInfoCard
                    sportsInfoCard
                    predictButton
                    validationWarning
                    resultsSection
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Retour")
                }
                .foregroundColor(.blue)
            })
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Régime Alimentaire")
                .font(.title)
                .fontWeight(.bold)
            Text("Recommandations nutritionnelles personnalisées")
                .font(.caption)
                .foregroundColor(Color.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
    }
    
    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informations personnelles")
                .font(.headline)
            
            TextField("Âge (ans)", text: $age)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Taille (cm)", text: $heightCm)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Poids (kg)", text: $weightKg)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var sportsInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informations sportives")
                .font(.headline)
            
            positionPicker
            goalPicker
            trainingIntensitySlider
            matchesPerWeekSlider
            injuryRiskPicker
            bodyfatSlider
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var positionPicker: some View {
        Picker("Position", selection: $selectedPosition) {
            Text("Sélectionner").tag("")
            ForEach(positions, id: \.self) { position in
                Text(position).tag(position)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    private var goalPicker: some View {
        Picker("Objectif", selection: $selectedGoal) {
            Text("Sélectionner").tag("")
            ForEach(goals, id: \.self) { goal in
                Text(goal).tag(goal)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    private var trainingIntensitySlider: some View {
        VStack(alignment: .leading) {
            Text("Intensité d'entraînement: \(Int(trainingIntensity))/10")
            Slider(value: $trainingIntensity, in: 0...10, step: 1)
        }
    }
    
    private var matchesPerWeekSlider: some View {
        VStack(alignment: .leading) {
            Text("Matchs par semaine: \(Int(matchesPerWeek))")
            Slider(value: $matchesPerWeek, in: 0...7, step: 1)
        }
    }
    
    private var injuryRiskPicker: some View {
        Picker("Risque de blessure", selection: $selectedInjuryRisk) {
            Text("Sélectionner").tag("")
            ForEach(injuryRisks, id: \.self) { risk in
                Text(risk).tag(risk)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    private var bodyfatSlider: some View {
        VStack(alignment: .leading) {
            Text("Graisse corporelle: \(Int(bodyfatPercent))%")
            Slider(value: $bodyfatPercent, in: 0...100, step: 1)
        }
    }
    
    private var predictButton: some View {
        Button(action: handlePredictButton) {
            HStack {
                if case .loading = viewModel.uiState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "checkmark.circle")
                }
                Text("Générer les recommandations")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.uiState == .loading)
    }
    
    private func handlePredictButton() {
        print("🔘 Bouton 'Générer les recommandations' cliqué")
        print("📋 État du formulaire:")
        print("   - Âge: '\(age)'")
        print("   - Taille: '\(heightCm)'")
        print("   - Poids: '\(weightKg)'")
        print("   - Position: '\(selectedPosition)'")
        print("   - Objectif: '\(selectedGoal)'")
        print("   - Risque: '\(selectedInjuryRisk)'")
        print("   - Formulaire valide: \(isFormValid)")
        
        if !isFormValid {
            let missing = missingFields.joined(separator: ", ")
            let errorMsg = "Veuillez remplir tous les champs obligatoires : \(missing)"
            print("❌ \(errorMsg)")
            viewModel.uiState = .error(errorMsg)
        } else {
            predictDiet()
        }
    }
    
    @ViewBuilder
    private var validationWarning: some View {
        if !isFormValid && !missingFields.isEmpty {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(Color.orange)
                Text("Champs manquants : \(missingFields.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(Color.orange)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var resultsSection: some View {
        if case .success(let result) = viewModel.uiState {
            DietResultsView(result: result)
                .transition(.opacity)
        } else if case .error(let message) = viewModel.uiState {
            errorView(message: message)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(Color.red)
            Text("Erreur")
                .font(.headline)
                .foregroundColor(Color.red)
            Text(message)
                .font(.body)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
            Button("Réessayer") {
                predictDiet()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .transition(.opacity)
    }
    
    private var isFormValid: Bool {
        !age.isEmpty && !heightCm.isEmpty && !weightKg.isEmpty &&
        !selectedPosition.isEmpty && !selectedGoal.isEmpty && !selectedInjuryRisk.isEmpty
    }
    
    private var missingFields: [String] {
        var missing: [String] = []
        if age.isEmpty { missing.append("Âge") }
        if heightCm.isEmpty { missing.append("Taille") }
        if weightKg.isEmpty { missing.append("Poids") }
        if selectedPosition.isEmpty { missing.append("Position") }
        if selectedGoal.isEmpty { missing.append("Objectif") }
        if selectedInjuryRisk.isEmpty { missing.append("Risque de blessure") }
        return missing
    }
    
    private func predictDiet() {
        // Vérifier que tous les champs sont remplis
        guard isFormValid else {
            print("❌ Formulaire invalide. Champs manquants: \(missingFields.joined(separator: ", "))")
            return
        }
        
        // Vérifier que les valeurs numériques sont valides
        guard let ageFloat = Float(age),
              let heightFloat = Float(heightCm),
              let weightFloat = Float(weightKg),
              ageFloat > 0,
              heightFloat > 0,
              weightFloat > 0 else {
            print("❌ Valeurs numériques invalides: age=\(age), height=\(heightCm), weight=\(weightKg)")
            viewModel.uiState = .error("Veuillez entrer des valeurs numériques valides pour l'âge, la taille et le poids.")
            return
        }
        
        let input = DietInput(
            age: ageFloat,
            heightCm: heightFloat,
            weightKg: weightFloat,
            position: selectedPosition,
            goal: selectedGoal,
            trainingIntensity: trainingIntensity,
            matchesPerWeek: matchesPerWeek,
            injuryRisk: selectedInjuryRisk,
            bodyfatPercent: bodyfatPercent
        )
        
        viewModel.predictDiet(input: input)
    }
}

struct DietResultsView: View {
    let result: DietPredictionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommandations nutritionnelles")
                .font(.headline)
            
            HStack {
                Text("Calories cibles:")
                Spacer()
                Text("\(Int(result.prediction.targetCalories)) kcal/jour")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Protéines:")
                Spacer()
                Text("\(Int(result.prediction.proteinG)) g")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Glucides:")
                Spacer()
                Text("\(Int(result.prediction.carbsG)) g")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Lipides:")
                Spacer()
                Text("\(Int(result.prediction.fatsG)) g")
                    .fontWeight(.bold)
            }
            
            HStack {
                Text("Hydratation:")
                Spacer()
                Text(String(format: "%.2f L", result.prediction.hydrationL))
                    .fontWeight(.bold)
            }
            
            // Afficher le plan de repas
            if !result.mealPlan.breakfast.isEmpty {
                Divider()
                Text("Plan de repas")
                    .font(.headline)
                    .padding(.top, 8)
                
                MealPlanView(mealPlan: result.mealPlan)
            }
            
            // Lien PDF si disponible
            if let pdfLink = result.pdfLink {
                Divider()
                Link("Télécharger le PDF", destination: URL(string: pdfLink)!)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MealPlanView: View {
    let mealPlan: MealPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MealSection(title: "Petit-déjeuner", items: mealPlan.breakfast)
            MealSection(title: "Collation matin", items: mealPlan.snack1)
            MealSection(title: "Déjeuner", items: mealPlan.lunch)
            MealSection(title: "Collation après-midi", items: mealPlan.snack2)
            MealSection(title: "Dîner", items: mealPlan.dinner)
        }
    }
}

struct MealSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.caption)
            }
        }
    }
}

// ViewModel and Result types
enum DietUIState: Equatable {
    case idle
    case loading
    case success(DietPredictionResult)
    case error(String)
}

struct DietPredictionResult: Equatable {
    let prediction: DietPredictionForView
    let mealPlan: MealPlan
    let pdfLink: String?
    let pdfFilename: String?
}

struct DietPredictionForView: Equatable {
    let targetCalories: Float
    let proteinG: Float
    let carbsG: Float
    let fatsG: Float
    let hydrationL: Float
}

class FootballDietViewModel: ObservableObject {
    @Published var uiState: DietUIState = .idle
    private let dietApiService = DietApiService()
    
    func predictDiet(input: DietInput) {
        uiState = .loading
        
        // iOS 14 compatible: Use completion handlers instead of async/await
        dietApiService.predictAndGenerateMealPlan(input: input) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (prediction, mealPlanResponse)):
                    // Convertir la prédiction pour la vue
                    let predictionForView = DietPredictionForView(
                        targetCalories: prediction.targetCalories,
                        proteinG: prediction.protein,
                        carbsG: prediction.carbs,
                        fatsG: prediction.fats,
                        hydrationL: prediction.hydration
                    )
                    
                    // Créer le MealPlan
                    let mealPlan = MealPlan(
                        breakfast: mealPlanResponse.breakfast,
                        snack1: mealPlanResponse.snack1,
                        lunch: mealPlanResponse.lunch,
                        snack2: mealPlanResponse.snack2,
                        dinner: mealPlanResponse.dinner
                    )
                    
                    self.uiState = .success(DietPredictionResult(
                        prediction: predictionForView,
                        mealPlan: mealPlan,
                        pdfLink: mealPlanResponse.pdfLink,
                        pdfFilename: mealPlanResponse.pdfFilename
                    ))
                    
                case .failure(let error):
                    let errorMessage: String
                    if let apiError = error as? ApiError {
                        errorMessage = apiError.localizedDescription
                    } else {
                        errorMessage = "Erreur: \(error.localizedDescription)"
                    }
                    print("❌ Diet prediction error: \(errorMessage)")
                    self.uiState = .error(errorMessage)
                }
            }
        }
    }
}

