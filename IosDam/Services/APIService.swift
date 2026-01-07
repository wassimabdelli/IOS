//
// APIService.swift
// IosDam
//
// Comprehensive API Service for all backend endpoints



import Foundation

// MARK: - API Configuration

struct APIConfig {
    // Update this to match your backend URL
    // For local dev: "http://192.168.x.x:3001/api/v1"
    // For production: "https://your-backend-api.com/api/v1"
    static let baseURL = "http://192.168.42.1:3000/api/v1"
}

// MARK: - API Error

struct APIError: Codable, Error, LocalizedError {
    let message: String?
    
    var errorDescription: String? {
        return message ?? "An unknown error occurred"
    }
}

// MARK: - API Response Models

struct APIResponse: Codable {
    let message: String?
    let access_token: String?
    let user: UserModel?
    let coupe: CoupeModel?
}

struct MessageResponse: Codable {
    let message: String
}

// MARK: - Profile Stats Response (Dynamic based on role)

struct ProfileStatsResponse: Codable {
    let role: String
    let recentMatches: [MatchResultProfile]?
    
    // OWNER fields
    let wins: Int?
    let losses: Int?
    let totalMatches: Int?
    let winRate: String?
    let totalPlayers: Int?
    let trophies: Int?
    
    // JOUEUR fields
    let teamName: String?
    let matchesPlayed: Int?
    let goals: Int?
    let assists: Int?
    
    // ARBITRE fields
    let matchesRefereed: Int?
    let academyName: String?
    
    // COACH fields
    let matchesCoached: Int?
    let teamWins: Int?
    let teamLosses: Int?
}



// MARK: - Create Coupe DTO (Assuming CoupeModel, Equipe, PopulatedEquipe, CreateEquipeRequest, UpdateEquipeRequest, Terrain, CreateTerrainRequest, AddParticipantRequest exist elsewhere)

struct CreateCoupeDto: Codable {
    let nom: String
    let participants: [String]
    let date_debut: Date
    let date_fin: Date
    let tournamentName: String
    let stadium: String
    let date: String
    let time: String
    let maxParticipants: Int
    let entryFee: Int?
    let prizePool: Int?
    let referee: [String]
    let categorie: String
    let type: String
}

// MARK: - APIService Class

class APIService {
    
    static let shared = APIService()
    private init() {}
    
    // MARK: - Match DTOs
    struct UpdateMatchRequest: Codable {
        let score_eq1: Int?
        let score_eq2: Int?
        let statut: String?
        let id_equipe1: String?
        let id_equipe2: String?
    }
    
    struct AddStatRequest: Codable {
        let idJoueur: String
        let equipe: String
        let type: String
    }
    
    struct AddCartonRequest: Codable {
        let idJoueur: String
        let categorie: String
        let color: String
    }
    
    // MARK: - Custom Date Formatter Setup
    
    // The backend uses ISO8601 with milliseconds (e.g., "2025-11-24T01:47:22.895Z")
    private static var customDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Format string must include milliseconds (.SSS) and the UTC indicator (Z)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    // MARK: - Helper Functions
    
    /**
     Handles API responses expecting a JSON Body (Decodable).
     */
    private static func handleResponse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(APIError(message: "Invalid response")))
            return
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let data = data, let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                completion(.failure(apiError))
            } else {
                completion(.failure(APIError(message: "Server error: \(httpResponse.statusCode)")))
            }
            return
        }
        
        guard let data = data, !data.isEmpty else {
            // Handle 204 No Content gracefully if T is Void/MessageResponse
            if T.self == MessageResponse.self || T.self == Void.self {
                // Try to construct an empty/default instance if the API expects one, otherwise fail
                if let messageResponse = MessageResponse(message: "") as? T {
                    completion(.success(messageResponse))
                    return
                }
            }
            completion(.failure(APIError(message: "No data received")))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            // ⭐️ FIX 1: Use custom date decoding strategy for backend format
            decoder.dateDecodingStrategy = .formatted(customDateFormatter)
            
            let result = try decoder.decode(T.self, from: data)
            completion(.success(result))
        } catch {
            print("❌ Decoding error: \(error)")
            completion(.failure(error))
        }
    }
    
    /**
     Handles API responses expecting NO Content (Void).
     */
    private static func handleVoidResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<Void, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(APIError(message: "Invalid response")))
            return
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let data = data, let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                completion(.failure(apiError))
            } else {
                completion(.failure(APIError(message: "Server error: \(httpResponse.statusCode)")))
            }
            return
        }
        
        completion(.success(()))
    }
    
    /**
     Helper to create authenticated requests with JWT token.
     */
    private static func createAuthenticatedRequest(url: URL, method: String, token: String? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use provided token or get from UserDefaults
        let authToken = token ?? UserDefaults.standard.string(forKey: "userToken")
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    // MARK: - Authentication APIs
    
    /// Register a new user
    static func registerUser(nom: String, prenom: String, tel: String, email: String, age: String, role: String, password: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/register") else { return }
        let body: [String: Any] = ["nom": nom, "prenom": prenom, "tel": tel, "email": email, "age": age, "role": role, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Login user
    static func loginUser(email: String, password: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/login") else { return }
        let body: [String: Any] = ["email": email, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Verify OTP code after registration
    static func verifyCode(email: String, code: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/verify-code") else { return }
        let body: [String: Any] = ["email": email, "code": code]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Resend verification OTP (uses send-code endpoint)
    static func resendVerificationCode(email: String, completion: @escaping (Result<MessageResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/send-code") else { return }
        let body: [String: Any] = ["email": email]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Forgot password - send reset code
    static func forgotPassword(email: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/forgot-password") else { return }
        let body: [String: Any] = ["email": email]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Verify reset code
    static func verifyResetCode(email: String, code: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/forgot-password/verify-code") else { return }
        let body: [String: Any] = ["email": email, "code": code]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Reset password
    static func resetPassword(email: String, code: String, newPassword: String, confirmPassword: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/forgot-password/reset") else { return }
        let body: [String: Any] = ["email": email, "code": code, "newPassword": newPassword, "confirmPassword": confirmPassword]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - User APIs
    
    /// Get user profile
    static func getUserProfile(userId: String, completion: @escaping (Result<UserModel, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/users/\(userId)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Update user profile
    static func updateUserProfile(updateData: [String: Any], completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(UserModel.self, from: data) else {
            completion(.failure(APIError(message: "User not found")))
            return
        }
        
        guard let url = URL(string: "\(APIConfig.baseURL)/users/\(user._id)") else { return }
        var request = createAuthenticatedRequest(url: url, method: "PATCH") // Keep var because httpBody is set later
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updateData, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Get profile statistics based on user role
    static func getProfileStats(userId: String, completion: @escaping (Result<ProfileStatsResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/users/\(userId)/profile-stats") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Teams/Equipe APIs
    
    /// Get all teams
    static func getAllTeams(completion: @escaping (Result<[Equipe], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Get team by ID (populated with player details)
    static func getTeamById(teamId: String, completion: @escaping (Result<PopulatedEquipe, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/\(teamId)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Create new team
    static func createTeam(teamData: CreateEquipeRequest, completion: @escaping (Result<Equipe, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes") else { return }
        var request = createAuthenticatedRequest(url: url, method: "POST") // Keep var because httpBody is set later
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(teamData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Update team
    static func updateTeam(teamId: String, updateData: UpdateEquipeRequest, completion: @escaping (Result<Equipe, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/\(teamId)") else { return }
        var request = createAuthenticatedRequest(url: url, method: "PATCH") // Keep var because httpBody is set later
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(updateData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Stadium/Terrain APIs
    
    /// Get all stadiums
    static func getAllStadiums(completion: @escaping (Result<[Terrain], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/terrains") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError(message: "Invalid response")))
                return
            }
            
            print("📡 Stadium API Status Code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data, let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    completion(.failure(apiError))
                } else {
                    completion(.failure(APIError(message: "Server error: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data, !data.isEmpty else {
                completion(.failure(APIError(message: "No data received")))
                return
            }
            
            // Print raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Raw stadium response: \(jsonString.prefix(500))")
            }
            
            do {
                let decoder = JSONDecoder()
                // ⭐️ FIX 2: Use custom date decoding strategy for backend format in this specific block
                decoder.dateDecodingStrategy = .formatted(customDateFormatter)
                
                // Try to decode as direct array first
                if let stadiums = try? decoder.decode([Terrain].self, from: data) {
                    print("✅ Decoded \(stadiums.count) stadiums")
                    completion(.success(stadiums))
                    return
                }
                
                // If that fails, try wrapped response format
                struct WrappedResponse: Codable {
                    let data: [Terrain]?
                    let terrains: [Terrain]?
                }
                
                if let wrapped = try? decoder.decode(WrappedResponse.self, from: data) {
                    let stadiums = wrapped.data ?? wrapped.terrains ?? []
                    print("✅ Decoded \(stadiums.count) stadiums from wrapped response")
                    completion(.success(stadiums))
                    return
                }
                
                // If both fail, throw decoding error
                throw APIError(message: "Failed to decode stadium response")
                
            } catch {
                print("❌ Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Get stadium by ID
    static func getStadiumById(stadiumId: String, completion: @escaping (Result<Terrain, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/terrains/\(stadiumId)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Create new stadium
    static func createStadium(stadiumData: CreateTerrainRequest, completion: @escaping (Result<Terrain, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/terrains") else { return }
        var request = createAuthenticatedRequest(url: url, method: "POST") // Keep var because httpBody is set later
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(stadiumData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Delete stadium
    static func deleteStadium(stadiumId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/terrains/\(stadiumId)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError(message: "Invalid response")))
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                if let data = data, let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    completion(.failure(apiError))
                } else {
                    completion(.failure(APIError(message: "Delete failed: \(httpResponse.statusCode)")))
                }
            }
        }.resume()
    }
    
    // MARK: - Tournament/Coupe APIs
    
    /// Create tournament
    static func createCoupe(coupeData: CreateCoupeDto, token: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        
        guard let url = URL(string: "\(APIConfig.baseURL)/coupes/create-coupe") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        var request = createAuthenticatedRequest(url: url, method: "POST", token: token) // Keep var because httpBody is set later
        
        let encoder = JSONEncoder()
        // ⭐️ FIX 3: Use custom date encoding strategy for sending dates to the backend
        encoder.dateEncodingStrategy = .formatted(customDateFormatter)
        
        do {
            request.httpBody = try encoder.encode(coupeData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Staff Management APIs
    
    /// Get all staff for an academie
    static func getAllStaff(academieId: String, completion: @escaping (Result<[PopulatedStaff], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/academie/\(academieId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error) { (result: Result<StaffListResponse, Error>) in
                switch result {
                case .success(let response):
                    completion(.success(response.staff))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Get staff member by ID
    static func getStaffById(staffId: String, completion: @escaping (Result<PopulatedStaff, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/\(staffId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Create new staff member
    static func createStaff(staffData: CreateStaffRequest, completion: @escaping (Result<Staff, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        var request = createAuthenticatedRequest(url: url, method: "POST")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(staffData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error) { (result: Result<StaffResponse, Error>) in
                switch result {
                case .success(let response):
                    completion(.success(response.staff))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Update staff member
    static func updateStaff(staffId: String, updateData: UpdateStaffRequest, completion: @escaping (Result<Staff, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/\(staffId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(updateData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error) { (result: Result<StaffResponse, Error>) in
                switch result {
                case .success(let response):
                    completion(.success(response.staff))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Delete staff member
    static func deleteStaff(staffId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/\(staffId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Get arbitres by academie
    static func getArbitresByAcademie(idAcademie: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/arbitres/\(idAcademie)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Add arbitre to academie
    static func addArbitreToAcademie(idAcademie: String, idArbitre: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/add-arbitre/\(idAcademie)") else { return }
        
        let body: [String: Any] = ["idArbitre": idArbitre]
        var request = createAuthenticatedRequest(url: url, method: "PATCH") // Keep var because httpBody is set later
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Remove arbitre from academie
    static func removeArbitreFromAcademie(idAcademie: String, idArbitre: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/remove-arbitre/\(idAcademie)/\(idArbitre)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Search arbitres
    static func searchArbitres(query: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(APIConfig.baseURL)/users/search/arbitres?q=\(encodedQuery)") else { return }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Check if arbitre exists in academie
    static func checkArbitreExists(idAcademie: String, idArbitre: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/exists/\(idAcademie)/\(idArbitre)") else { return }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            struct ExistsResponse: Codable { let exists: Bool }
            handleResponse(data: data, response: response, error: error) { (result: Result<ExistsResponse, Error>) in
                switch result {
                case .success(let existsResponse):
                    completion(.success(existsResponse.exists))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Tournament/Coupe APIs (Additional)
    
    /// Get all tournaments
    static func getTournaments(completion: @escaping (Result<[Tournament], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/coupes") else {
            print("❌ Invalid URL for getTournaments")
            return
        }
        print("📡 Fetching tournaments from: \(url)")
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        // Print request details
        print("📋 Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error)")
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Response status: \(httpResponse.statusCode)")
            }
            if let data = data {
                print("📦 Response data size: \(data.count) bytes")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Response JSON: \(jsonString.prefix(500))")
                }
            }
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Get tournament by ID (fully populated)
    static func getTournamentById(id: String, completion: @escaping (Result<Tournament, Error>) -> Void) {
        // Note: CoupeController is now mapped to /coupes
        guard let url = URL(string: "\(APIConfig.baseURL)/coupes/\(id)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Add participant to tournament
    static func addParticipant(coupeId: String, userId: String, completion: @escaping (Result<Tournament, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/coupes/add-participant/\(coupeId)") else { return }
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        
        do {
            // NOTE: Assuming AddParticipantRequest struct exists elsewhere and is Codable
            struct AddParticipantRequest: Codable { let userId: String }
            let body = AddParticipantRequest(userId: userId)
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Generate tournament bracket
    static func generateBracket(coupeId: String, completion: @escaping (Result<MessageResponse, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/coupes/\(coupeId)/generate-bracket") else { return }
        let request = createAuthenticatedRequest(url: url, method: "POST")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Check if user is arbitre in academy
    static func checkArbitreInAcademie(academieId: String, userId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/exists/\(academieId)/\(userId)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            struct ExistsResponse: Codable { let exists: Bool }
            handleResponse(data: data, response: response, error: error) { (result: Result<ExistsResponse, Error>) in
                switch result {
                case .success(let existsResponse):
                    completion(.success(existsResponse.exists))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Match Management APIs
    
    /// Get match by ID with full details
    static func getMatchById(matchId: String, completion: @escaping (Result<MatchDetail, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/matches/\(matchId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func updateMatch(matchId: String, body: UpdateMatchRequest, completion: @escaping (Result<MatchDetail, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/matches/\(matchId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func addStatToMatch(matchId: String, request body: AddStatRequest, completion: @escaping (Result<MatchDetail, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/matches/\(matchId)/stat") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        var request = createAuthenticatedRequest(url: url, method: "POST")
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func addOffside(matchId: String, idAcademie: String, idJoueur: String, completion: @escaping (Result<MatchDetail, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/matches/add-offside/\(matchId)/\(idAcademie)/\(idJoueur)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        let request = createAuthenticatedRequest(url: url, method: "POST")
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func addCartonToMatch(matchId: String, request body: AddCartonRequest, completion: @escaping (Result<MatchDetail, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/matches/\(matchId)/carton") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        var request = createAuthenticatedRequest(url: url, method: "POST")
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Update match score
    static func updateMatchScore(matchId: String, scoreData: UpdateMatchScoreRequest, completion: @escaping (Result<MatchDetail, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/matches/\(matchId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(scoreData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Get all matches for a tournament
    static func getMatchesByTournament(tournamentId: String, completion: @escaping (Result<[MatchDetail], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/match/tournament/\(tournamentId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Leaderboard APIs
    
    /// Get tournament standings/leaderboard
    static func getTournamentStandings(tournamentId: String, completion: @escaping (Result<[LeaderboardEntry], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/coupe/\(tournamentId)/standings") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Try to decode as direct array or wrapped response
            handleResponse(data: data, response: response, error: error) { (result: Result<LeaderboardListResponse, Error>) in
                switch result {
                case .success(let response):
                    completion(.success(response.leaderboard))
                case .failure:
                    // Fallback to direct array
                    handleResponse(data: data, response: response, error: error, completion: completion)
                }
            }
        }.resume()
    }
    
    /// Get team statistics
    static func getTeamStatistics(teamId: String, completion: @escaping (Result<StatsEquipe, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/\(teamId)/stats") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    /// Search all users by query
    static func searchAllUsers(query: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/users/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    // MARK: - Forum/Messages APIs
    
    /// Get all messages for a tournament forum
    static func getTournamentMessages(tournamentId: String, completion: @escaping (Result<[ForumMessage], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/messages/tournament/\(tournamentId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error) { (result: Result<ForumMessagesListResponse, Error>) in
                switch result {
                case .success(let response):
                    completion(.success(response.messages))
                case .failure:
                    // Fallback to direct array
                    handleResponse(data: data, response: response, error: error, completion: completion)
                }
            }
        }.resume()
    }
    
    /// Post a new message to tournament forum
    static func postTournamentMessage(messageData: CreateMessageRequest, completion: @escaping (Result<ForumMessage, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/messages") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        var request = createAuthenticatedRequest(url: url, method: "POST")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(messageData)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error) { (result: Result<ForumMessageResponse, Error>) in
                switch result {
                case .success(let response):
                    completion(.success(response.message))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Delete a forum message
    static func deleteMessage(messageId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/messages/\(messageId)") else {
            completion(.failure(APIError(message: "Invalid URL")))
            return
        }
        
        let request = createAuthenticatedRequest(url: url, method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    // MARK: - Maillots
    
    struct JoueurMaillotInfo: Codable {
        let nom: String
        let prenom: String
        let email: String
        let numero: Int?
    }

    static func getJoueurMaillot(idJoueur: String, idAcademie: String, completion: @escaping (Result<JoueurMaillotInfo, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/maillolts/joueur?idJoueur=\(idJoueur)&idAcademie=\(idAcademie)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    static func assignMaillot(idJoueur: String, idAcademie: String, numero: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/maillots/assign?idJoueur=\(idJoueur)&idAcademie=\(idAcademie)&numero=\(numero)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "POST")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    static func updateMaillot(idJoueur: String, idAcademie: String, numero: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/maillots/update?idJoueur=\(idJoueur)&idAcademie=\(idAcademie)&numero=\(numero)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "PATCH")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    // MARK: - Search & Team Members
    
    static func searchJoueurs(query: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(APIConfig.baseURL)/users/search/joueurs?q=\(encodedQuery)") else { return }
        
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    struct TeamMember: Codable, Identifiable {
        let _id: String
        let nom: String
        let prenom: String
        let email: String
        var id: String { _id }
    }

    static func getMembresByAcademieCategorie(idAcademie: String, categorie: String, completion: @escaping (Result<[TeamMember], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/membres/\(idAcademie)/\(categorie)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func addJoueurToAcademie(idAcademie: String, idJoueur: String, categorie: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/add-joueur/\(idAcademie)") else { return }
        let body: [String: Any] = [
            "idJoueur": idJoueur,
            "categorie": categorie
        ]
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func removeJoueurFromAcademie(idAcademie: String, idJoueur: String, categorie: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/remove-joueur/\(idAcademie)/\(idJoueur)") else { return }
        let body: [String: Any] = [
            "categorie": categorie
        ]
        var request = createAuthenticatedRequest(url: url, method: "DELETE")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func getJoueursByRole(idAcademie: String, categorie: String, role: String = "titulaire", completion: @escaping (Result<[TeamMember], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/\(idAcademie)/joueurs?categorie=\(categorie)&role=\(role)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Coach Management
    
    static func getCoachByAcademie(idAcademie: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/coachs/\(idAcademie)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func removeCoachFromAcademie(idAcademie: String, idCoach: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/\(idAcademie)/coach/\(idCoach)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func searchCoachsArbitres(query: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(APIConfig.baseURL)/users/search/coachs-arbitres?q=\(encodedQuery)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func addCoachToAcademie(idAcademie: String, idCoach: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/\(idAcademie)/coach/\(idCoach)") else { return }
        let request = createAuthenticatedRequest(url: url, method: "POST")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleVoidResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func isCoachInAcademie(idAcademie: String, idCoach: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/staff/\(idAcademie)/coach/\(idCoach)/check") else { return }
        let request = createAuthenticatedRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
             struct ExistsResponse: Codable { let exists: Bool }
             handleResponse(data: data, response: response, error: error) { (result: Result<ExistsResponse, Error>) in
                switch result {
                case .success(let existsResponse):
                    completion(.success(existsResponse.exists))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }.resume()
    }

      // MARK: - Swap Players
    static func swapPlayers(idAcademie: String, idStarter: String, idSubstitute: String, categorie: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/toggle-starter-substitute/\(idAcademie)") else { return }
        
        let body: [String: Any] = [
            "idStarter": idStarter,
            "idSubstitute": idSubstitute,
            "categorie": categorie
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                completion(.failure(APIError(message: "Failed to swap players")))
            }
        }.resume()
    }

    // MARK: - Roster Management
    static func enforceRosterSizes(idAcademie: String, categorie: String, completion: @escaping (Result<Equipe, Error>) -> Void) {
        // Corrected URL to include 'equipes' path segment
        guard let url = URL(string: "\(APIConfig.baseURL)/equipes/enforce-roster/\(idAcademie)") else {
            completion(.failure(APIError(message: "Invalid URL for enforceRosterSizes")))
            return
        }
        
        let body: [String: Any] = ["categorie": categorie]
        var request = createAuthenticatedRequest(url: url, method: "PATCH")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    static func getNames(ids: [String], completion: @escaping (Result<[String: String], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseURL)/users/names") else { return }
        var request = createAuthenticatedRequest(url: url, method: "POST")
        let body = ["ids": ids]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
}
