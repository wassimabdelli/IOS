//
//  APIService.swift
//  IosDam
//

import Foundation

struct APIResponse: Codable {
    let message: String?
    let access_token: String?
    let user: UserModel?
}

struct APIError: Codable, Error {
    let message: String?
}

    class APIService {
    
    static let baseURL = "http://192.168.92.1:3000/api/v1"
    
    // MARK: - Register User
    static func registerUser(nom: String,
                             prenom: String,
                             tel: String,
                             email: String,
                             age: String,
                             role: String,
                             password: String,
                             completion: @escaping (Result<APIResponse, Error>) -> Void) {
        
        guard let url = URL(string: "\(baseURL)/auth/register") else { return }
        
        let body: [String: Any] = [
            "nom": nom,
            "prenom": prenom,
            "tel": tel,
            "email": email,
            "age": age,
            "role": role,
            "password": password
        ]
        
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
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError(message: "No data received")))
                return
            }
            
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    do {
                        let apiError = try JSONDecoder().decode(APIError.self, from: data)
                        completion(.failure(apiError))
                    } catch {
                        let rawMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                        completion(.failure(APIError(message: rawMessage)))
                    }
                    return
                }
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Login Response JSON: \(jsonString)")
                }
                
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(.success(apiResponse))
                
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Login User
    static func loginUser(email: String,
                          password: String,
                          completion: @escaping (Result<APIResponse, Error>) -> Void) {
        
        guard let url = URL(string: "\(baseURL)/auth/login") else { return }
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
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
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError(message: "No data received")))
                return
            }
            
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    do {
                        let apiError = try JSONDecoder().decode(APIError.self, from: data)
                        completion(.failure(apiError))
                    } catch {
                        let rawMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                        completion(.failure(APIError(message: rawMessage)))
                    }
                    return
                }
                
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(.success(apiResponse))
                
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Update User Profile (PATCH /users/:id)
    static func updateUserProfile(updateData: [String: Any], completion: @escaping (Result<APIResponse, Error>) -> Void) {
        // Récupérer l'ID du user depuis UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(UserModel.self, from: data) else {
            completion(.failure(APIError(message: "Utilisateur non trouvé")))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(user._id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ajouter le token JWT si présent
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updateData, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError(message: "No data received")))
                return
            }
            
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Erreur serveur")))
                    return
                }
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(.success(apiResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Verify Code
    static func verifyCode(email: String, code: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/verify-code") else { return }

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
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError(message: "No data received"))); return }

            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Code invalide ou expiré")) )
                    return
                }
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(.success(apiResponse))
            } catch { completion(.failure(error)) }
        }.resume()
    }
    
}
// MARK: - Maillots
extension APIService {
    struct JoueurMaillotInfo: Codable {
        let nom: String
        let prenom: String
        let email: String
        let numero: Int?
    }

    static func getJoueurMaillot(idJoueur: String, idAcademie: String, completion: @escaping (Result<JoueurMaillotInfo, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/maillolts/joueur?idJoueur=\(idJoueur)&idAcademie=\(idAcademie)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError(message: "No data received"))); return }
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Erreur serveur")))
                    return
                }
                let info = try JSONDecoder().decode(JoueurMaillotInfo.self, from: data)
                completion(.success(info))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    static func assignMaillot(idJoueur: String, idAcademie: String, numero: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/maillots/assign?idJoueur=\(idJoueur)&idAcademie=\(idAcademie)&numero=\(numero)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                if let data = data, let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    completion(.failure(apiError))
                } else {
                    completion(.failure(APIError(message: "Erreur serveur")))
                }
            }
        }.resume()
    }
    static func updateMaillot(idJoueur: String, idAcademie: String, numero: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/maillots/update?idJoueur=\(idJoueur)&idAcademie=\(idAcademie)&numero=\(numero)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                if let data = data, let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    completion(.failure(apiError))
                } else {
                    completion(.failure(APIError(message: "Erreur serveur")))
                }
            }
        }.resume()
    }
}
// MARK: - Forgot Password Extension
extension APIService {
    
    // Step 1: Request reset code
    static func forgotPassword(email: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/forgot-password") else { return }
        let body: [String: Any] = ["email": email]
        sendRequest(url: url, body: body, completion: completion)
    }
    
    // Step 2: Verify reset code
    static func verifyResetCode(email: String, code: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/forgot-password/verify-code") else { return }
        let body: [String: Any] = ["email": email, "code": code]
        sendRequest(url: url, body: body, completion: completion)
    }
    
    // Step 3: Reset password
    static func resetPassword(email: String, code: String, newPassword: String, confirmPassword: String, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/forgot-password/reset") else { return }
        let body: [String: Any] = [
            "email": email,
            "code": code,
            "newPassword": newPassword,
            "confirmPassword": confirmPassword
        ]
        sendRequest(url: url, body: body, completion: completion)
    }
    
    // MARK: - Reusable Request Function
    private static func sendRequest(url: URL, body: [String: Any], completion: @escaping (Result<APIResponse, Error>) -> Void) {
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
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError(message: "No data received")))
                return
            }
            
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Erreur serveur")))
                    return
                }
                let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(.success(apiResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    // MARK: - Search Arbitres
    static func searchArbitres(query: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/search/arbitres?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ajouter le token JWT si présent
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError(message: "No data received")))
                return
            }
            
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Erreur serveur")))
                    return
                }
                // Le backend retourne une liste d'utilisateurs
                let users = try JSONDecoder().decode([UserModel].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    static func searchJoueurs(query: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/search/joueurs?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError(message: "No data received")))
                return
            }
            
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Erreur serveur")))
                    return
                }
                let users = try JSONDecoder().decode([UserModel].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
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
        guard let url = URL(string: "\(baseURL)/equipes/membres/\(idAcademie)/\(categorie)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError(message: "No data received"))); return }
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Erreur serveur")))
                    return
                }
                let members = try JSONDecoder().decode([TeamMember].self, from: data)
                completion(.success(members))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    static func addJoueurToAcademie(idAcademie: String, idJoueur: String, categorie: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/equipes/add-joueur/\(idAcademie)") else { return }
        let body: [String: Any] = [
            "idJoueur": idJoueur,
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
                completion(.failure(APIError(message: "Failed to add joueur")))
            }
        }.resume()
    }

    static func removeJoueurFromAcademie(idAcademie: String, idJoueur: String, categorie: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/equipes/remove-joueur/\(idAcademie)/\(idJoueur)") else { return }
        let body: [String: Any] = [
            "categorie": categorie
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
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
                completion(.failure(APIError(message: "Failed to remove joueur")))
            }
        }.resume()
    }

    static func getJoueursByRole(idAcademie: String, categorie: String, role: String = "titulaire", completion: @escaping (Result<[TeamMember], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/equipes/\(idAcademie)/joueurs?categorie=\(categorie)&role=\(role)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError(message: "No data received"))); return }
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Erreur serveur")))
                    return
                }
                let users = try JSONDecoder().decode([TeamMember].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Check Arbitre Exists in Academie
    static func checkArbitreExists(idAcademie: String, idArbitre: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/staff/exists/\(idAcademie)/\(idArbitre)") else { return }
        print("DEBUG: Checking arbitre exists URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("DEBUG: Check arbitre error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = data else { completion(.failure(APIError(message: "No data"))); return }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: Check arbitre status code: \(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: Check arbitre response: \(jsonString)")
            }
            
            struct ExistsResponse: Codable {
                let exists: Bool
            }
            
            do {
                let result = try JSONDecoder().decode(ExistsResponse.self, from: data)
                completion(.success(result.exists))
            } catch {
                print("DEBUG: Check arbitre decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Add Arbitre to Academie
    static func addArbitreToAcademie(idAcademie: String, idArbitre: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/staff/add-arbitre/\(idAcademie)") else { return }
        
        let body: [String: Any] = ["idArbitre": idArbitre]
        
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
                completion(.failure(APIError(message: "Failed to add arbitre")))
            }
        }.resume()
    }
    // MARK: - Get Arbitres by Academie
    static func getArbitresByAcademie(idAcademie: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/staff/arbitres/\(idAcademie)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError(message: "No data"))); return }
            
            do {
                let users = try JSONDecoder().decode([UserModel].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Remove Arbitre from Academie
    static func removeArbitreFromAcademie(idAcademie: String, idArbitre: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/staff/remove-arbitre/\(idAcademie)/\(idArbitre)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                completion(.failure(APIError(message: "Failed to remove arbitre")))
            }
        }.resume()
    }

    // MARK: - Get Coachs by Academie
    static func getCoachByAcademie(idAcademie: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/staff/coachs/\(idAcademie)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError(message: "No data"))); return }
            
            do {
                let users = try JSONDecoder().decode([UserModel].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Remove Coach from Academie
    static func removeCoachFromAcademie(idAcademie: String, idCoach: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/staff/\(idAcademie)/coach/\(idCoach)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                completion(.failure(APIError(message: "Failed to remove coach")))
            }
        }.resume()
    }

    // MARK: - Search Coachs and Arbitres
    static func searchCoachsArbitres(query: String, completion: @escaping (Result<[UserModel], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/search/coachs-arbitres?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError(message: "No data received")))
                return
            }
            
            do {
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    completion(.failure(apiError ?? APIError(message: "Erreur serveur")))
                    return
                }
                let users = try JSONDecoder().decode([UserModel].self, from: data)
                completion(.success(users))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Add Coach to Academie
    static func addCoachToAcademie(idAcademie: String, idCoach: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/staff/\(idAcademie)/coach/\(idCoach)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                completion(.failure(APIError(message: "Failed to add coach")))
            }
        }.resume()
    }

    // MARK: - Check Coach Exists in Academie
    static func isCoachInAcademie(idAcademie: String, idCoach: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/staff/\(idAcademie)/coach/\(idCoach)/check") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError(message: "No data"))); return }
            
            struct CheckResponse: Codable {
                let isCoach: Bool
            }
            
            do {
                let result = try JSONDecoder().decode(CheckResponse.self, from: data)
                completion(.success(result.isCoach))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Swap Players
    static func swapPlayers(idAcademie: String, idStarter: String, idSubstitute: String, categorie: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/equipes/toggle-starter-substitute/\(idAcademie)") else { return }
        
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
}
    
