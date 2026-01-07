//
//  DietApiService.swift
//  fakhripeakplay
//
//  Diet API service
//

import Foundation

class DietApiService {
    private let apiClient = ApiClient.shared
    
    // Backend a deux endpoints séparés: predict et meal-plan
    func predictDiet(request: PredictRequest, completion: @escaping (Result<DietPrediction, Error>) -> Void) {
        apiClient.request(
            endpoint: "diet/predict",
            method: "POST",
            body: request,
            responseType: DietPrediction.self,
            completion: completion
        )
    }
    
    func generateMealPlan(request: MealPlanRequest, completion: @escaping (Result<MealPlanResponse, Error>) -> Void) {
        apiClient.request(
            endpoint: "diet/meal-plan",
            method: "POST",
            body: request,
            responseType: MealPlanResponse.self,
            completion: completion
        )
    }
    
    // Méthode combinée pour faciliter l'utilisation
    func predictAndGenerateMealPlan(input: DietInput, completion: @escaping (Result<(DietPrediction, MealPlanResponse), Error>) -> Void) {
        print("🍽️ Starting diet prediction for input: age=\(input.age), height=\(input.heightCm), weight=\(input.weightKg)")
        
        // 1. Convertir DietInput en PredictRequest
        let predictRequest = PredictRequest(
            age: Int(input.age),
            height: Int(input.heightCm),
            weight: Int(input.weightKg),
            position: mapPositionToBackend(input.position),
            goal: mapGoalToBackend(input.goal),
            trainingIntensity: Int(input.trainingIntensity),
            matchesPerWeek: Int(input.matchesPerWeek),
            injuryRisk: mapInjuryRiskToBackend(input.injuryRisk),
            bodyfatPercent: Int(input.bodyfatPercent)
        )
        
        print("📤 Sending predict request: \(predictRequest)")
        
        // 2. Obtenir la prédiction
        predictDiet(request: predictRequest) { [weak self] result in
            switch result {
            case .success(let prediction):
                print("✅ Prediction received: calories=\(prediction.targetCalories), protein=\(prediction.protein)")
                
                // 3. Générer le plan de repas avec les valeurs prédites
                let mealPlanRequest = MealPlanRequest(
                    targetCalories: prediction.targetCalories,
                    protein: prediction.protein,
                    carbs: prediction.carbs,
                    fats: prediction.fats,
                    hydration: prediction.hydration,
                    goal: self?.mapGoalToBackend(input.goal) ?? input.goal.lowercased()
                )
                
                print("📤 Sending meal plan request: \(mealPlanRequest)")
                self?.generateMealPlan(request: mealPlanRequest) { mealPlanResult in
                    switch mealPlanResult {
                    case .success(let mealPlan):
                        print("✅ Meal plan received: breakfast=\(mealPlan.breakfast.count) items")
                        completion(.success((prediction, mealPlan)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Mappers pour convertir les valeurs du frontend vers le backend
    private func mapPositionToBackend(_ position: String) -> String {
        switch position.lowercased() {
        case "gardien": return "goalkeeper"
        case "défenseur": return "defender"
        case "milieu": return "midfielder"
        case "attaquant": return "forward"
        default: return position.lowercased()
        }
    }
    
    private func mapGoalToBackend(_ goal: String) -> String {
        switch goal.lowercased() {
        case "perte de poids": return "weight_loss"
        case "gain de masse": return "muscle_gain"
        case "maintien": return "maintenance"
        case "performance": return "performance"
        default: return goal.lowercased()
        }
    }
    
    private func mapInjuryRiskToBackend(_ risk: String) -> String {
        switch risk.lowercased() {
        case "faible": return "low"
        case "modéré": return "medium"
        case "élevé": return "high"
        default: return risk.lowercased()
        }
    }
}

// Structures pour les requêtes backend
struct PredictRequest: Codable, CustomStringConvertible {
    let age: Int
    let height: Int
    let weight: Int
    let position: String
    let goal: String
    let trainingIntensity: Int
    let matchesPerWeek: Int
    let injuryRisk: String
    let bodyfatPercent: Int
    
    var description: String {
        "PredictRequest(age: \(age), height: \(height), weight: \(weight), position: \(position), goal: \(goal), trainingIntensity: \(trainingIntensity), matchesPerWeek: \(matchesPerWeek), injuryRisk: \(injuryRisk), bodyfatPercent: \(bodyfatPercent))"
    }
}

// Structure pour MealPlanRequest (différente de celle utilisée pour predict)
struct MealPlanRequest: Codable, CustomStringConvertible {
    let targetCalories: Float
    let protein: Float
    let carbs: Float
    let fats: Float
    let hydration: Float
    let goal: String
    
    var description: String {
        "MealPlanRequest(targetCalories: \(targetCalories), protein: \(protein), carbs: \(carbs), fats: \(fats), hydration: \(hydration), goal: \(goal))"
    }
}

struct MealPlanResponse: Codable {
    let breakfast: [String]
    let snack1: [String]
    let lunch: [String]
    let snack2: [String]
    let dinner: [String]
    let pdfLink: String?
    let pdfFilename: String?
}

// Structure pour la réponse de predict (différente de DietPrediction)
struct DietPrediction: Codable {
    let targetCalories: Float
    let protein: Float
    let carbs: Float
    let fats: Float
    let hydration: Float
}

