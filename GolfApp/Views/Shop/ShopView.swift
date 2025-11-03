import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var appState: AppState
    private let grid = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Shop")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.accent)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "creditcard.circle.fill")
                    Text("\(appState.coins)")
                }
                .foregroundColor(.white)
                .padding(8)
                .background(Capsule().fill(Theme.surface.opacity(0.9)))
            }

            ScrollView {
                LazyVGrid(columns: grid, spacing: 16) {
                    ForEach(appState.shopItems) { item in
                        ShopCard(item: item) { id in
                            _ = appState.purchase(itemId: id)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}

private struct ShopCard: View {
    let item: ShopItem
    var onBuy: (String) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.surface)
                Image(systemName: "circle.fill").resizable().scaledToFit()
                    .foregroundColor(.white.opacity(0.9))
                    .padding(24)
            }
            .frame(height: 120)

            Text(item.name)
                .font(.headline)
                .foregroundColor(.white)

            if item.owned {
                Text("OWNED")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.card.opacity(0.5)))
            } else {
                Button(action: { onBuy(item.id) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard")
                        Text("\(item.price)")
                    }
                }
                .buttonStyle(FilledButtonStyle(color: Theme.card))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card.opacity(0.8)))
    }
}


