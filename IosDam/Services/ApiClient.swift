//
//  ApiClient.swift
//  fakhripeakplay
//
//  API client using URLSession
//

import Foundation

// MARK: - Config
struct Config {
    // IMPORTANT: Configurez l'URL de votre serveur backend ici
    // Exemples:
    // - Simulateur iOS avec serveur local: "http://localhost:3001/api/v1"
    // - Appareil physique sur même réseau: "http://192.168.x.x:3001/api/v1"
    // - Serveur distant: "https://votre-serveur.com/api/v1"
    static let REST_BASE_URL = "http://192.168.42.1:3000/api/v1"
    
    // Alternative pour le simulateur iOS (décommentez si besoin)
    // static let REST_BASE_URL = "http://localhost:3001/api/v1"
    
    static let READ_TIMEOUT_SECONDS: TimeInterval = 30.0
    
    // Test mode configuration
    static let ENABLE_TEST_MODE = true
    static let DEFAULT_TEST_USER_ID = "test-user-id"
}
// MARK: - User Preferences
class UserPreferences: ObservableObject {
    @Published var userId: String?
    
    init() {
        // Tenter de charger l'utilisateur depuis UserDefaults
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(UserModel.self, from: userData) {
            self.userId = user._id
        }
    }
}

class ApiClient {
    static let shared = ApiClient()
    
    private let baseURL: String
    
    init() {
        self.baseURL = Config.REST_BASE_URL
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Ensure proper URL construction: baseURL should end with / and endpoint should start with /
        let cleanBaseURL = baseURL.hasSuffix("/") ? baseURL : baseURL + "/"
        let cleanEndpoint = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let fullURL = cleanBaseURL + cleanEndpoint
        
        guard let url = URL(string: fullURL) else {
            print("❌ URL invalide: \(fullURL)")
            completion(.failure(ApiError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available (like APIService does)
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔐 Token d'authentification ajouté")
        }
        
        // Log de la requête pour déboguer
        print("📤 API Request: \(method) \(url.absoluteString)")
        
        if let body = body {
            do {
                // Encode the body using JSONEncoder
                // For iOS 14 compatibility, we use a type-erased encoding approach
                let encoder = JSONEncoder()
                let jsonData = try encodeEncodable(body, encoder: encoder)
                request.httpBody = jsonData
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📤 Request body: \(jsonString.prefix(500))")
                }
            } catch {
                completion(.failure(ApiError.decodingError(error)))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network Error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ApiError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Essayer d'extraire le message d'erreur du backend
                var errorMessage = "Erreur inconnue"
                let data = data ?? Data()
                
                if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                    print("❌ API Error Response [\(httpResponse.statusCode)]: \(responseString)")
                    
                    // Essayer de parser le JSON d'erreur (format NestJS)
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Format NestJS: {"statusCode": 500, "message": "..."}
                        if let message = json["message"] as? String {
                            errorMessage = message
                        } else if let error = json["error"] as? String {
                            errorMessage = error
                        } else {
                            // Si c'est un objet mais sans message clair, utiliser la réponse complète
                            errorMessage = responseString
                        }
                    } else {
                        // Si ce n'est pas du JSON, utiliser la réponse brute
                        errorMessage = responseString
                    }
                } else {
                    // Si pas de données, utiliser un message générique
                    errorMessage = "Erreur HTTP \(httpResponse.statusCode)"
                }
                
                print("❌ API Error [\(httpResponse.statusCode)]: \(errorMessage)")
                completion(.failure(ApiError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("❌ Empty response data")
                completion(.failure(ApiError.invalidResponse))
                return
            }
            
            // Log de la réponse pour déboguer
            if let responseString = String(data: data, encoding: .utf8) {
                print("✅ API Response: \(responseString.prefix(200))")
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(T.self, from: data)
                completion(.success(result))
            } catch {
                print("❌ Decoding Error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Response was: \(responseString.prefix(1000))")
                    
                    // Vérifier si la réponse est en fait une erreur HTTP
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if json["statusCode"] != nil || json["error"] != nil || json["message"] != nil {
                            // C'est une réponse d'erreur, pas une réponse valide
                            let statusCode = json["statusCode"] as? Int ?? 500
                            let message = json["message"] as? String ?? json["error"] as? String ?? "Erreur serveur"
                            print("   ⚠️ La réponse est une erreur HTTP, pas une réponse valide")
                            completion(.failure(ApiError.httpError(statusCode: statusCode, message: message)))
                            return
                        }
                    }
                }
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("   Missing key: \(key.stringValue) in \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch: expected \(type) in \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("   Value not found: \(type) in \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("   Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("   Unknown decoding error")
                    }
                }
                completion(.failure(ApiError.decodingError(error)))
            }
        }.resume()
    }
    
    // Helper function to encode any Encodable type (iOS 14 compatible)
    // Uses JSONSerialization with Mirror reflection as a workaround for protocol existentials
    private func encodeEncodable(_ value: Encodable, encoder: JSONEncoder) throws -> Data {
        // Convert the Encodable to a dictionary using Mirror reflection
        let mirror = Mirror(reflecting: value)
        var dict: [String: Any] = [:]
        
        for child in mirror.children {
            if let label = child.label {
                // Convert child value to JSON-compatible type
                let jsonValue = convertToJSONValue(child.value)
                dict[label] = jsonValue
            }
        }
        
        // Encode the dictionary using JSONSerialization
        return try JSONSerialization.data(withJSONObject: dict, options: [])
    }
    
    // Helper to convert any value to a JSON-compatible type
    private func convertToJSONValue(_ value: Any) -> Any {
        // Handle common types
        if let string = value as? String {
            return string
        } else if let int = value as? Int {
            return int
        } else if let double = value as? Double {
            return double
        } else if let float = value as? Float {
            return Double(float)
        } else if let bool = value as? Bool {
            return bool
        } else if let array = value as? [Any] {
            return array.map { convertToJSONValue($0) }
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { convertToJSONValue($0) }
        } else if let encodable = value as? Encodable {
            // For nested Encodable types, use Mirror recursively
            let mirror = Mirror(reflecting: encodable)
            var nestedDict: [String: Any] = [:]
            for child in mirror.children {
                if let label = child.label {
                    nestedDict[label] = convertToJSONValue(child.value)
                }
            }
            return nestedDict
        } else {
            // Fallback: convert to string
            return String(describing: value)
        }
    }
}

enum ApiError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String = "")
    case decodingError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide"
        case .httpError(let statusCode, let message):
            if !message.isEmpty {
                return "Erreur HTTP \(statusCode): \(message)"
            }
            return "Erreur HTTP: \(statusCode)"
        case .decodingError(let error):
            return "Erreur de décodage: \(error.localizedDescription)"
        }
    }
}

