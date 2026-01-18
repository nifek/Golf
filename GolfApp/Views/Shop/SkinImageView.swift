import SwiftUI
import FirebaseStorage

/// A view that loads an image from Firebase Storage using the SDK (which handles auth tokens)
struct SkinImageView: View {
    let storagePath: String
    let skinId: String
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError: Error?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                // Error state - show placeholder
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Image(systemName: "circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard !storagePath.isEmpty else {
            print("⚠️ [SkinImageView '\(skinId)'] Storage path is empty")
            isLoading = false
            return
        }
        
        print("📥 [SkinImageView '\(skinId)'] Loading from path: '\(storagePath)'")
        
        do {
            // Use Firebase SDK to get the download URL with proper token
            let storage = Storage.storage()
            let reference = storage.reference(withPath: storagePath)
            
            print("📥 [SkinImageView '\(skinId)'] Getting download URL from Firebase SDK...")
            let url = try await reference.downloadURL()
            print("✅ [SkinImageView '\(skinId)'] Got URL: \(url.absoluteString)")
            
            // Download the image data
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 [SkinImageView '\(skinId)'] HTTP Status: \(httpResponse.statusCode)")
            }
            
            print("📥 [SkinImageView '\(skinId)'] Downloaded \(data.count) bytes")
            
            if let uiImage = UIImage(data: data) {
                print("✅ [SkinImageView '\(skinId)'] Created UIImage successfully")
                await MainActor.run {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                print("❌ [SkinImageView '\(skinId)'] Failed to create UIImage from data")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            print("❌ [SkinImageView '\(skinId)'] Error: \(error)")
            await MainActor.run {
                self.loadError = error
                self.isLoading = false
            }
        }
    }
}
