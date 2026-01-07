//
// TerrainApiService.swift
// IosDam
//
// API service for Stadium/Terrain management

import Foundation

class TerrainApiService {
    private let apiClient = ApiClient.shared
    
    // MARK: - Get All Stadiums
    
    /// Get all stadiums/terrains
    func getAllStadiums(completion: @escaping (Result<[Terrain], Error>) -> Void) {
        apiClient.request(
            endpoint: "terrains",
            method: "GET",
            body: nil as String?,
            responseType: [Terrain].self,
            completion: completion
        )
    }
    
    // MARK: - Get Stadium by ID
    
    /// Get stadium details by ID
    func getStadiumById(stadiumId: String, completion: @escaping (Result<Terrain, Error>) -> Void) {
        apiClient.request(
            endpoint: "terrains/\(stadiumId)",
            method: "GET",
            body: nil as String?,
            responseType: Terrain.self,
            completion: completion
        )
    }
    
    // MARK: - Get Stadiums by Academy
    
    /// Get all stadiums for a specific academy
    func getStadiumsByAcademy(academyId: String, completion: @escaping (Result<[Terrain], Error>) -> Void) {
        apiClient.request(
            endpoint: "terrains/academie/\(academyId)",
            method: "GET",
            body: nil as String?,
            responseType: [Terrain].self,
            completion: completion
        )
    }
    
    // MARK: - Create Stadium
    
    /// Create a new stadium
    func createStadium(stadiumData: CreateTerrainRequest, completion: @escaping (Result<Terrain, Error>) -> Void) {
        apiClient.request(
            endpoint: "terrains",
            method: "POST",
            body: stadiumData,
            responseType: Terrain.self,
            completion: completion
        )
    }
    
    // MARK: - Update Stadium
    
    /// Update stadium details
    func updateStadium(stadiumId: String, stadiumData: UpdateTerrainRequest, completion: @escaping (Result<Terrain, Error>) -> Void) {
        apiClient.request(
            endpoint: "terrains/\(stadiumId)",
            method: "PATCH",
            body: stadiumData,
            responseType: Terrain.self,
            completion: completion
        )
    }
    
    // MARK: - Delete Stadium
    
    /// Delete a stadium
    func deleteStadium(stadiumId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Special handling for DELETE requests that don't return data
        apiClient.request(
            endpoint: "terrains/\(stadiumId)",
            method: "DELETE",
            body: nil as String?,
            responseType: EmptyResponse.self
        ) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

