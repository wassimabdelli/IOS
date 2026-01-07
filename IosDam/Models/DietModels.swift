//
//  DietModels.swift
//  fakhripeakplay
//
//  Diet prediction models
//

import Foundation

// Structures utilisées par les vues uniquement
// Les structures pour les requêtes API sont dans DietApiService.swift

struct MealPlan: Codable, Equatable {
    let breakfast: [String]
    let snack1: [String]
    let lunch: [String]
    let snack2: [String]
    let dinner: [String]
    
    func getEstimatedCalories() -> Int {
        // Estimation simple basée sur le nombre d'items
        let totalItems = breakfast.count + snack1.count + lunch.count + snack2.count + dinner.count
        return totalItems * 200 // Estimation approximative
    }
}

struct DietInput {
    let age: Float
    let heightCm: Float
    let weightKg: Float
    let position: String
    let goal: String
    let trainingIntensity: Float
    let matchesPerWeek: Float
    let injuryRisk: String
    let bodyfatPercent: Float
}

struct DietInjuryPredictionResult: Codable {
    let riskLevel: String
    let probability: Float
    let recommendations: [String]
}

