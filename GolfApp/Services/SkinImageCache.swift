import UIKit
import FirebaseStorage
actor SkinImageCache {
    static let shared = SkinImageCache()
    
    private var memoryCache: [String: UIImage] = [:]
    
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("SkinImages")
    }
    
    private init() {
        if let cacheDir = cacheDirectory {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }
    
    func getImage(for storagePath: String) async -> UIImage? {
        let cacheKey = cacheKey(for: storagePath)
        
        if let cached = memoryCache[cacheKey] {
            print("💾 [SkinCache] Memory cache HIT for '\(storagePath)'")
            return cached
        }
        
        if let diskCached = loadFromDisk(cacheKey: cacheKey) {
            print("💾 [SkinCache] Disk cache HIT for '\(storagePath)'")
            memoryCache[cacheKey] = diskCached
            return diskCached
        }
        
        print("📥 [SkinCache] Cache MISS for '\(storagePath)', downloading...")
        if let downloaded = await downloadImage(storagePath: storagePath) {
            memoryCache[cacheKey] = downloaded
            saveToDisk(image: downloaded, cacheKey: cacheKey)
            print("✅ [SkinCache] Downloaded and cached '\(storagePath)'")
            return downloaded
        }
        
        print("❌ [SkinCache] Failed to download '\(storagePath)'")
        return nil
    }
    
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
    
    func clearMemoryCache() {
        print("🗑️ [SkinCache] Clearing memory cache")
        memoryCache.removeAll()
    }
    
    func clearAllCaches() {
        print("🗑️ [SkinCache] Clearing all caches")
        memoryCache.removeAll()
        
        if let cacheDir = cacheDirectory {
            try? fileManager.removeItem(at: cacheDir)
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }
    
    private func cacheKey(for storagePath: String) -> String {
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
            let storage = Storage.storage()
            let reference = storage.reference(withPath: storagePath)
            let url = try await reference.downloadURL()
            
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
