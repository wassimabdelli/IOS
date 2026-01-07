//
// TerrainViewModel.swift
// IosDam
//
// ViewModel for Stadium/Terrain Management

import Foundation
import Combine

class TerrainViewModel: ObservableObject {
    @Published var stadiums: Resource<[Terrain]> = .idle
    @Published var selectedStadium: Resource<Terrain> = .idle
    @Published var createStadiumState: Resource<Terrain> = .idle
    @Published var updateStadiumState: Resource<Terrain> = .idle
    @Published var deleteStadiumState: Resource<EmptyEquatable> = .idle
    @Published var errorMessage: String?
    
    private let terrainApiService = TerrainApiService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load All Stadiums
    
    func loadAllStadiums() {
        stadiums = .loading
        terrainApiService.getAllStadiums { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stadiums):
                    self?.stadiums = .success(stadiums)
                case .failure(let error):
                    self?.stadiums = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Load Stadiums by Academy
    
    func loadStadiumsByAcademy(academyId: String) {
        stadiums = .loading
        terrainApiService.getStadiumsByAcademy(academyId: academyId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stadiums):
                    self?.stadiums = .success(stadiums)
                case .failure(let error):
                    self?.stadiums = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Load Stadium by ID
    
    func loadStadiumById(stadiumId: String) {
        selectedStadium = .loading
        terrainApiService.getStadiumById(stadiumId: stadiumId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stadium):
                    self?.selectedStadium = .success(stadium)
                case .failure(let error):
                    self?.selectedStadium = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Create Stadium
    
    func createStadium(
        academyId: String,
        name: String,
        locationVerbal: String,
        latitude: Double,
        longitude: Double,
        capacity: Int,
        numberOfFields: Int,
        fieldNames: [String]? = nil,
        hasLights: Bool? = false,
        amenities: [String]? = nil,
        isAvailable: Bool? = true
    ) {
        createStadiumState = .loading
        
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        let request = CreateTerrainRequest(
            id_academie: academyId,
            name: name,
            location_verbal: locationVerbal,
            coordinates: coordinates,
            capacity: capacity,
            number_of_fields: numberOfFields,
            field_names: fieldNames,
            has_lights: hasLights,
            amenities: amenities,
            is_available: isAvailable
        )
        
        terrainApiService.createStadium(stadiumData: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stadium):
                    self?.createStadiumState = .success(stadium)
                    // Reload stadiums list
                    self?.loadStadiumsByAcademy(academyId: academyId)
                case .failure(let error):
                    self?.createStadiumState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Update Stadium
    
    func updateStadium(
        stadiumId: String,
        academyId: String,
        name: String? = nil,
        locationVerbal: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        capacity: Int? = nil,
        numberOfFields: Int? = nil,
        fieldNames: [String]? = nil,
        hasLights: Bool? = nil,
        amenities: [String]? = nil,
        isAvailable: Bool? = nil
    ) {
        updateStadiumState = .loading
        
        var coordinates: Coordinates? = nil
        if let lat = latitude, let lon = longitude {
            coordinates = Coordinates(latitude: lat, longitude: lon)
        }
        
        let request = UpdateTerrainRequest(
            name: name,
            location_verbal: locationVerbal,
            coordinates: coordinates,
            capacity: capacity,
            number_of_fields: numberOfFields,
            field_names: fieldNames,
            has_lights: hasLights,
            amenities: amenities,
            is_available: isAvailable
        )
        
        terrainApiService.updateStadium(stadiumId: stadiumId, stadiumData: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stadium):
                    self?.updateStadiumState = .success(stadium)
                    // Reload stadiums list
                    self?.loadStadiumsByAcademy(academyId: academyId)
                case .failure(let error):
                    self?.updateStadiumState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Delete Stadium
    
    func deleteStadium(stadiumId: String, academyId: String) {
        deleteStadiumState = .loading
        terrainApiService.deleteStadium(stadiumId: stadiumId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.deleteStadiumState = .success(EmptyEquatable())
                    // Reload stadiums list
                    self?.loadStadiumsByAcademy(academyId: academyId)
                case .failure(let error):
                    self?.deleteStadiumState = .error(error.localizedDescription)
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - State Reset
    
    func resetCreateStadiumState() {
        createStadiumState = .idle
    }
    
    func resetUpdateStadiumState() {
        updateStadiumState = .idle
    }
    
    func resetDeleteStadiumState() {
        deleteStadiumState = .idle
    }
    
    func clearError() {
        errorMessage = nil
    }
}

