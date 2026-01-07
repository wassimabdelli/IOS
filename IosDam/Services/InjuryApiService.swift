//
//  InjuryApiService.swift
//  fakhripeakplay
//
//  Injury API service
//

import Foundation

class InjuryApiService {
    private let apiClient = ApiClient.shared
    
    func getMyInjuries(playerId: String, completion: @escaping (Result<[Injury], Error>) -> Void) {
        // Backend utilise GET /injury/my avec auth, mais pour compatibilité on peut utiliser un endpoint alternatif
        // Note: Le backend nécessite l'authentification via req.user.userId
        // Pour le moment, on utilise un endpoint de test si disponible
        apiClient.request(
            endpoint: "injury/my",
            method: "GET",
            body: nil,
            responseType: [Injury].self,
            completion: completion
        )
    }
    
    func getAcademyInjuries(academyId: String, completion: @escaping (Result<[Injury], Error>) -> Void) {
        apiClient.request(
            endpoint: "injury/academy/\(academyId)",
            method: "GET",
            body: nil,
            responseType: [Injury].self,
            completion: completion
        )
    }
    
    func getUnavailablePlayers(completion: @escaping (Result<[Injury], Error>) -> Void) {
        apiClient.request(
            endpoint: "injury/unavailable",
            method: "GET",
            body: nil,
            responseType: [Injury].self,
            completion: completion
        )
    }
    
    func createInjury(request: CreateInjuryRequest, completion: @escaping (Result<Injury, Error>) -> Void) {
        apiClient.request(
            endpoint: "injury",
            method: "POST",
            body: request,
            responseType: Injury.self,
            completion: completion
        )
    }
    
    func addEvolution(injuryId: String, request: AddEvolutionRequest, completion: @escaping (Result<Injury, Error>) -> Void) {
        apiClient.request(
            endpoint: "injury/\(injuryId)/evolution",
            method: "POST",
            body: request,
            responseType: Injury.self,
            completion: completion
        )
    }
    
    func addRecommendation(injuryId: String, request: AddRecommendationRequest, completion: @escaping (Result<Injury, Error>) -> Void) {
        apiClient.request(
            endpoint: "injury/\(injuryId)/recommendations",
            method: "PATCH",
            body: request,
            responseType: Injury.self,
            completion: completion
        )
    }
    
    func updateStatus(injuryId: String, request: UpdateStatusRequest, completion: @escaping (Result<Injury, Error>) -> Void) {
        apiClient.request(
            endpoint: "injury/\(injuryId)/status",
            method: "PATCH",
            body: request,
            responseType: Injury.self,
            completion: completion
        )
    }
}
