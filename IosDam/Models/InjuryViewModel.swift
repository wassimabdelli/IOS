//
//  InjuryViewModel.swift
//  fakhripeakplay
//
//  ViewModel for Injury Management
//

import Foundation
import Combine

class InjuryViewModel: ObservableObject {
    @Published var myInjuries: Resource<[Injury]> = .idle
    @Published var academyInjuries: Resource<[Injury]> = .idle
    @Published var unavailablePlayers: Resource<[Injury]> = .idle
    @Published var createInjuryState: Resource<Injury> = .idle
    @Published var addEvolutionState: Resource<Injury> = .idle
    @Published var updateStatusState: Resource<Injury> = .idle
    @Published var addRecommendationState: Resource<Injury> = .idle
    @Published var errorMessage: String?
    
    private let injuryApiService = InjuryApiService()
    private var cancellables = Set<AnyCancellable>()
    
    // Mapping functions
    private func mapInjuryTypeToBackend(type: String) -> String {
        switch type {
        case "Fracture": return "fracture"
        case "Entorse": return "articulation"
        case "Déchirure musculaire": return "muscle"
        case "Contusion": return "choc"
        case "Luxation": return "articulation"
        case "Tendinite": return "tendon"
        default: return "other"
        }
    }
    
    private func mapSeverityToBackend(severity: String) -> String {
        switch severity {
        case "Légère": return "light"
        case "Modérée": return "medium"
        case "Grave": return "severe"
        case "Très grave": return "severe"
        default: return "medium"
        }
    }
    
    func createInjury(type: String, severity: String, description: String, playerId: String) {
        createInjuryState = .loading
        let mappedType = mapInjuryTypeToBackend(type: type)
        let mappedSeverity = mapSeverityToBackend(severity: severity)
        // Don't send playerId in the request - backend gets it from auth token
        let request = CreateInjuryRequest(
            type: mappedType,
            severity: mappedSeverity,
            description: description
        )
        injuryApiService.createInjury(request: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let injury):
                    self?.createInjuryState = .success(injury)
                    self?.loadMyInjuries(playerId: playerId)
                case .failure(let error):
                    self?.createInjuryState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addEvolution(injuryId: String, painLevel: Int, note: String, playerId: String) {
        addEvolutionState = .loading
        let request = AddEvolutionRequest(painLevel: painLevel, note: note)
        injuryApiService.addEvolution(injuryId: injuryId, request: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let injury):
                    self?.addEvolutionState = .success(injury)
                    self?.loadMyInjuries(playerId: playerId)
                case .failure(let error):
                    self?.addEvolutionState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadMyInjuries(playerId: String) {
        myInjuries = .loading
        injuryApiService.getMyInjuries(playerId: playerId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let injuries):
                    self?.myInjuries = .success(injuries)
                case .failure(let error):
                    self?.myInjuries = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func loadAcademyInjuries(academyId: String) {
        academyInjuries = .loading
        injuryApiService.getAcademyInjuries(academyId: academyId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let injuries):
                    self?.academyInjuries = .success(injuries)
                case .failure(let error):
                    self?.academyInjuries = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func updateStatus(injuryId: String, status: String) {
        updateStatusState = .loading
        let request = UpdateStatusRequest(status: status)
        injuryApiService.updateStatus(injuryId: injuryId, request: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let injury):
                    self?.updateStatusState = .success(injury)
                case .failure(let error):
                    self?.updateStatusState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addRecommendation(injuryId: String, recommendation: String) {
        addRecommendationState = .loading
        let request = AddRecommendationRequest(recommendation: recommendation)
        injuryApiService.addRecommendation(injuryId: injuryId, request: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let injury):
                    self?.addRecommendationState = .success(injury)
                case .failure(let error):
                    self?.addRecommendationState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadUnavailablePlayers() {
        unavailablePlayers = .loading
        injuryApiService.getUnavailablePlayers() { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let injuries):
                    self?.unavailablePlayers = .success(injuries)
                case .failure(let error):
                    self?.unavailablePlayers = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetCreateInjuryState() {
        createInjuryState = .idle
    }
    
    func resetAddEvolutionState() {
        addEvolutionState = .idle
    }
    
    func resetUpdateStatusState() {
        updateStatusState = .idle
    }
    
    func resetAddRecommendationState() {
        addRecommendationState = .idle
    }
}
