//
//  StorageService.swift
//  FitAi
//
//  Created by Shazni Shiraz on 1/30/26.
//

import Foundation
import UIKit
import Supabase

// MARK: - Storage Error

enum StorageError: Error, LocalizedError {
    case imageConversionFailed
    case uploadFailed(message: String)
    case urlGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to data."
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .urlGenerationFailed:
            return "Failed to generate public URL."
        }
    }
}

// MARK: - Storage Service Protocol

/// Protocol for storage operations.
protocol StorageService {
    /// Uploads an image to storage and returns the public URL.
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - path: Optional custom path (default generates unique filename)
    /// - Returns: Public URL of the uploaded image
    func uploadImage(_ image: UIImage, path: String?) async throws -> String
}

// MARK: - Supabase Storage Service

/// Concrete implementation using Supabase Storage.
final class SupabaseStorageService: StorageService {
    
    // MARK: - Properties
    
    private let client: SupabaseClient
    private let bucketName = "food-images"
    
    // MARK: - Initialization
    
    init(clientProvider: SupabaseClientProviding) {
        self.client = clientProvider.client
    }
    
    // MARK: - StorageService Implementation
    
    func uploadImage(_ image: UIImage, path: String? = nil) async throws -> String {
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.imageConversionFailed
        }
        
        // Generate unique filename if not provided
        let fileName = path ?? "\(UUID().uuidString).jpg"
        let filePath = "uploads/\(fileName)"
        
        print("📸 [Storage] Uploading image to: \(filePath)")
        
        do {
            // Upload to Supabase Storage
            try await client.storage
                .from(bucketName)
                .upload(
                    filePath,
                    data: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )
            
            // Get public URL
            let publicURL = try client.storage
                .from(bucketName)
                .getPublicURL(path: filePath)
            
            let urlString = publicURL.absoluteString
            print("✅ [Storage] Upload successful! Public URL: \(urlString)")
            
            return urlString
            
        } catch {
            print("❌ [Storage] Upload failed: \(error.localizedDescription)")
            throw StorageError.uploadFailed(message: error.localizedDescription)
        }
    }
}

// MARK: - Mock Storage Service (for testing)

#if DEBUG
final class MockStorageService: StorageService {
    func uploadImage(_ image: UIImage, path: String?) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let mockURL = "https://example.com/mock-food-image-\(UUID().uuidString).jpg"
        print("🧪 [MockStorage] Returning mock URL: \(mockURL)")
        return mockURL
    }
}
#endif
