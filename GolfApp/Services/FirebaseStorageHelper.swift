import Foundation
import FirebaseStorage
enum FirebaseStorageHelper {
    static let storageBucket = "golf-game-1fcb8.firebasestorage.app"
    
    static func downloadURL(for path: String) -> URL? {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)?
            .replacingOccurrences(of: "/", with: "%2F") ?? path
        let urlString = "https://firebasestorage.googleapis.com/v0/b/\(storageBucket)/o/\(encodedPath)?alt=media"
        
        print("[FirebaseStorageHelper] Path: '\(path)'")
        print("[FirebaseStorageHelper] Encoded path: '\(encodedPath)'")
        print("[FirebaseStorageHelper] Full URL: '\(urlString)'")
        
        let url = URL(string: urlString)
        if url == nil {
            print("[FirebaseStorageHelper] Failed to create URL from string!")
        }
        return url
    }
    
    static func getDownloadURL(for path: String) async throws -> URL {
        print("[FirebaseStorageHelper] Getting download URL via SDK for path: '\(path)'")
        let storage = Storage.storage()
        let reference = storage.reference(withPath: path)
        print("[FirebaseStorageHelper] Reference: \(reference.fullPath)")
        
        do {
            let url = try await reference.downloadURL()
            print("[FirebaseStorageHelper] Got SDK download URL: \(url)")
            return url
        } catch {
            print("[FirebaseStorageHelper] SDK download URL error: \(error)")
            throw error
        }
    }
}
