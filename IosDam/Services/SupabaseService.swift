//
// SupabaseService.swift
// IosDam
//
// Service for uploading and managing images in Supabase Storage

import Foundation
import UIKit

class SupabaseService {
    
    // MARK: - Upload Image
    
    /// Upload image to Supabase Storage and return public URL
    static func uploadImage(image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Compress image to JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(SupabaseError.invalidImage))
            return
        }
        
        // Generate unique filename
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(userId)_\(timestamp).jpg"
        
        // Construct upload URL
        let uploadURL = "\(SupabaseConfig.storageURL)/\(SupabaseConfig.bucketName)/\(filename)"
        
        guard let url = URL(string: uploadURL) else {
            completion(.failure(SupabaseError.invalidURL))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        // Perform upload
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(SupabaseError.invalidResponse))
                return
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // Success - return public URL
                let publicURL = SupabaseConfig.publicURL(for: filename)
                completion(.success(publicURL))
            } else {
                // Error - try to parse error message
                if let data = data,
                   let errorMessage = String(data: data, encoding: .utf8) {
                    completion(.failure(SupabaseError.uploadFailed(errorMessage)))
                } else {
                    completion(.failure(SupabaseError.uploadFailed("Status code: \(httpResponse.statusCode)")))
                }
            }
        }.resume()
    }
    
    // MARK: - Delete Image
    
    /// Delete image from Supabase Storage
    static func deleteImage(filename: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let deleteURL = "\(SupabaseConfig.storageURL)/\(SupabaseConfig.bucketName)/\(filename)"
        
        guard let url = URL(string: deleteURL) else {
            completion(.failure(SupabaseError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(SupabaseConfig.apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(SupabaseError.invalidResponse))
                return
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                completion(.success(()))
            } else {
                completion(.failure(SupabaseError.deleteFailed("Status code: \(httpResponse.statusCode)")))
            }
        }.resume()
    }
    
    // MARK: - Load Image from URL
    
    /// Load image from URL (for iOS 14 compatibility)
    static func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            completion(image)
        }.resume()
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case invalidImage
    case invalidURL
    case invalidResponse
    case uploadFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process image"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        }
    }
}

