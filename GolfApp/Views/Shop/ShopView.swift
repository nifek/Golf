import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var appState: AppState
    private let grid = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var isProcessing = false
    @State private var purchaseError: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Shop")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.accent)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "creditcard.circle.fill")
                        .foregroundColor(Theme.gold)
                    Text("\(appState.coins)")
                }
                .foregroundColor(.white)
                .padding(8)
                .background(Capsule().fill(Theme.surface.opacity(0.9)))
            }

            if appState.isLoadingShop {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: grid, spacing: 16) {
                        ForEach(appState.shopItems) { item in
                            ShopCard(
                                item: item,
                                userCoins: appState.coins,
                                isProcessing: isProcessing,
                                onBuy: { id in
                                    Task {
                                        await purchaseSkin(id: id)
                                    }
                                },
                                onEquip: { id in
                                    Task {
                                        await equipSkin(id: id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .task {
            await appState.loadShop()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                purchaseError = nil
            }
        } message: {
            Text(purchaseError ?? "An error occurred")
        }
    }
    
    private func purchaseSkin(id: String) async {
        isProcessing = true
        let success = await appState.purchase(itemId: id)
        isProcessing = false
        
        if !success {
            purchaseError = appState.lastError ?? "Failed to purchase skin"
            showError = true
            appState.clearError()
        }
    }
    
    private func equipSkin(id: String) async {
        isProcessing = true
        let success = await appState.equipSkin(skinId: id)
        isProcessing = false
        
        if !success {
            purchaseError = appState.lastError ?? "Failed to equip skin"
            showError = true
            appState.clearError()
        }
    }
}

private struct ShopCard: View {
    let item: ShopItem
    let userCoins: Int
    let isProcessing: Bool
    var onBuy: (String) -> Void
    var onEquip: (String) -> Void
    
    private var canAfford: Bool {
        userCoins >= item.price
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.surface)
                
                // Load skin image from Firebase Storage
                if let url = item.firebaseImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            // Fallback to default ball icon on error
                            Image(systemName: "circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.9))
                        @unknown default:
                            Image(systemName: "circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(20)
                } else {
                    // Default ball for items without image
                    Image(systemName: "circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white.opacity(0.9))
                        .padding(24)
                }
                
                // Equipped badge
                if item.equipped {
                    VStack {
                        HStack {
                            Spacer()
                            Text("IN USE")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(height: 120)

            Text(item.name)
                .font(.headline)
                .foregroundColor(.white)
            
            if !item.description.isEmpty {
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            if item.owned {
                if item.equipped {
                    Text("EQUIPPED")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accent.opacity(0.5)))
                } else {
                    Button(action: { onEquip(item.id) }) {
                        Text("EQUIP")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(FilledButtonStyle(color: Theme.card))
                    .disabled(isProcessing)
                }
            } else {
                Button(action: { onBuy(item.id) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard")
                        Text("\(item.price)")
                    }
                }
                .buttonStyle(FilledButtonStyle(color: canAfford ? Theme.card : Theme.card.opacity(0.5)))
                .disabled(!canAfford || isProcessing)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card.opacity(0.8)))
    }
}
