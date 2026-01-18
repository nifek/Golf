import Foundation
import FirebaseStorage

/// Helper for building Firebase Storage URLs from paths
enum FirebaseStorageHelper {
    /// The Firebase Storage bucket from GoogleService-Info.plist
    static let storageBucket = "golf-game-1fcb8.firebasestorage.app"
    
    /// Converts a storage path like "skins/fire.png" to a full download URL
    /// - Parameter path: The path in Firebase Storage (e.g., "skins/fire.png")
    /// - Returns: The full HTTPS URL to download the file
    static func downloadURL(for path: String) -> URL? {
        // Firebase Storage public URL format:
        // https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded-path}?alt=media
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)?
            .replacingOccurrences(of: "/", with: "%2F") ?? path
        let urlString = "https://firebasestorage.googleapis.com/v0/b/\(storageBucket)/o/\(encodedPath)?alt=media"
        
        print("🔗 [FirebaseStorageHelper] Path: '\(path)'")
        print("🔗 [FirebaseStorageHelper] Encoded path: '\(encodedPath)'")
        print("🔗 [FirebaseStorageHelper] Full URL: '\(urlString)'")
        
        let url = URL(string: urlString)
        if url == nil {
            print("❌ [FirebaseStorageHelper] Failed to create URL from string!")
        }
        return url
    }
    
    /// Async method to get download URL using Firebase SDK
    /// - Parameter path: The path in Firebase Storage
    /// - Returns: The download URL
    static func getDownloadURL(for path: String) async throws -> URL {
        print("📥 [FirebaseStorageHelper] Getting download URL via SDK for path: '\(path)'")
        let storage = Storage.storage()
        let reference = storage.reference(withPath: path)
        print("📥 [FirebaseStorageHelper] Reference: \(reference.fullPath)")
        
        do {
            let url = try await reference.downloadURL()
            print("✅ [FirebaseStorageHelper] Got SDK download URL: \(url)")
            return url
        } catch {
            print("❌ [FirebaseStorageHelper] SDK download URL error: \(error)")
            throw error
        }
    }
}
