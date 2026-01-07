//
//  GeminiService.swift
//  IosDam
//
//  Service for interacting with Groq AI API

import Foundation

class GrokAIService {
    
    static let shared = GrokAIService()
    
    private init() {}
    
    // MARK: - Send Message to AI
    
    func sendMessage(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Build URL
        let urlString = "\(AIConfig.baseURL)/chat/completions"
        guard let url = URL(string: urlString) else {
            completion(.failure(GrokAIError.invalidURL))
            return
        }
        
        // Build request body (OpenAI-compatible format)
        let requestBody: [String: Any] = [
            "model": AIConfig.textModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": AIConfig.temperature,
            "max_tokens": AIConfig.maxTokens,
            "top_p": AIConfig.topP
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(GrokAIError.encodingError))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(AIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(GrokAIError.noData))
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    // Try to parse error
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        completion(.failure(GrokAIError.apiError(message)))
                    } else {
                        completion(.failure(GrokAIError.parsingError))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Grok AI Errors

enum GrokAIError: LocalizedError {
    case invalidURL
    case encodingError
    case noData
    case parsingError
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request"
        case .noData:
            return "No data received from API"
        case .parsingError:
            return "Failed to parse API response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

