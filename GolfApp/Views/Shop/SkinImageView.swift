import SwiftUI
struct SkinImageView: View {
    let storagePath: String
    let skinId: String
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    
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
            loadFailed = true
            return
        }
        
        print("🖼️ [SkinImageView '\(skinId)'] Loading from path: '\(storagePath)'")
        
        if let cachedImage = await SkinImageCache.shared.getImage(for: storagePath) {
            await MainActor.run {
                self.image = cachedImage
                self.isLoading = false
            }
        } else {
            await MainActor.run {
                self.isLoading = false
                self.loadFailed = true
            }
        }
    }
}
