import UIKit
import FirebaseStorage

/// A cache for skin images to avoid repeated downloads from Firebase Storage
actor SkinImageCache {
    static let shared = SkinImageCache()
    
    /// In-memory cache for quick access
    private var memoryCache: [String: UIImage] = [:]
    
    /// File manager for disk cache
    private let fileManager = FileManager.default
    
    /// Directory for cached images
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("SkinImages")
    }
    
    private init() {
        // Create cache directory if needed
        if let cacheDir = cacheDirectory {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Public API
    
    /// Get a skin image, loading from cache or downloading if needed
    /// - Parameter storagePath: The Firebase Storage path (e.g., "skins/fire.png")
    /// - Returns: The UIImage if available
    func getImage(for storagePath: String) async -> UIImage? {
        let cacheKey = cacheKey(for: storagePath)
        
        // 1. Check memory cache first (fastest)
        if let cached = memoryCache[cacheKey] {
            print("💾 [SkinCache] Memory cache HIT for '\(storagePath)'")
            return cached
        }
        
        // 2. Check disk cache
        if let diskCached = loadFromDisk(cacheKey: cacheKey) {
            print("💾 [SkinCache] Disk cache HIT for '\(storagePath)'")
            memoryCache[cacheKey] = diskCached
            return diskCached
        }
        
        // 3. Download from Firebase Storage
        print("📥 [SkinCache] Cache MISS for '\(storagePath)', downloading...")
        if let downloaded = await downloadImage(storagePath: storagePath) {
            // Store in both caches
            memoryCache[cacheKey] = downloaded
            saveToDisk(image: downloaded, cacheKey: cacheKey)
            print("✅ [SkinCache] Downloaded and cached '\(storagePath)'")
            return downloaded
        }
        
        print("❌ [SkinCache] Failed to download '\(storagePath)'")
        return nil
    }
    
    /// Preload multiple skin images into cache
    /// - Parameter storagePaths: Array of Firebase Storage paths
    func preloadImages(for storagePaths: [String]) async {
        print("📦 [SkinCache] Preloading \(storagePaths.count) images...")
        
        await withTaskGroup(of: Void.self) { group in
            for path in storagePaths {
                group.addTask {
                    _ = await self.getImage(for: path)
                }
            }
        }
        
        print("📦 [SkinCache] Preloading complete")
    }
    
    /// Clear the memory cache (disk cache remains)
    func clearMemoryCache() {
        print("🗑️ [SkinCache] Clearing memory cache")
        memoryCache.removeAll()
    }
    
    /// Clear all caches (memory and disk)
    func clearAllCaches() {
        print("🗑️ [SkinCache] Clearing all caches")
        memoryCache.removeAll()
        
        if let cacheDir = cacheDirectory {
            try? fileManager.removeItem(at: cacheDir)
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Private Helpers
    
    private func cacheKey(for storagePath: String) -> String {
        // Create a safe filename from the storage path
        return storagePath
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
    }
    
    private func diskCacheURL(for cacheKey: String) -> URL? {
        cacheDirectory?.appendingPathComponent(cacheKey)
    }
    
    private func loadFromDisk(cacheKey: String) -> UIImage? {
        guard let url = diskCacheURL(for: cacheKey),
              fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    private func saveToDisk(image: UIImage, cacheKey: String) {
        guard let url = diskCacheURL(for: cacheKey),
              let data = image.pngData() else {
            return
        }
        try? data.write(to: url)
    }
    
    private func downloadImage(storagePath: String) async -> UIImage? {
        do {
            // Get download URL from Firebase SDK (includes auth token)
            let storage = Storage.storage()
            let reference = storage.reference(withPath: storagePath)
            let url = try await reference.downloadURL()
            
            // Download the image data
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("❌ [SkinCache] HTTP error \(httpResponse.statusCode) for '\(storagePath)'")
                return nil
            }
            
            return UIImage(data: data)
        } catch {
            print("❌ [SkinCache] Download error for '\(storagePath)': \(error)")
            return nil
        }
    }
}
