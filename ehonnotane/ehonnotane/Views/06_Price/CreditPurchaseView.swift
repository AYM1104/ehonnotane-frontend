import SwiftUI
import StoreKit

/// クレジットパック購入画面（シート表示）
struct CreditPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isPurchasing = false
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.15, blue: 0.4),
                        Color(red: 0.15, green: 0.1, blue: 0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // タイトル
                    Text(String(localized: "credit.purchase_title"))
                        .font(.custom("YuseiMagic-Regular", size: 24))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text(String(localized: "credit.purchase_subtitle"))
                        .font(.custom("YuseiMagic-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer().frame(height: 20)
                    
                    // クレジットパック一覧
                    if !storeKitManager.availableCreditPacks.isEmpty {
                        ForEach(storeKitManager.availableCreditPacks, id: \.id) { product in
                            CreditPackCard(
                                product: product,
                                isPurchasing: isPurchasing,
                                onPurchase: { purchasePack(product) }
                            )
                        }
                    } else if isLoading {
                        // ローディング中の表示
                        ProgressView()
                            .tint(.white)
                        Text(String(localized: "common.loading"))
                            .font(.custom("YuseiMagic-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        // 読み込み失敗時
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                            Text(String(localized: "credit.load_failed"))
                                .font(.custom("YuseiMagic-Regular", size: 16))
                                .foregroundColor(.white)
                            Text(String(localized: "credit.check_storekit"))
                                .font(.custom("YuseiMagic-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.6))
                            Button(action: { loadCreditPacks() }) {
                                Text(String(localized: "common.reload"))
                                    .font(.custom("YuseiMagic-Regular", size: 14))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // ローディングオーバーレイ
                if isPurchasing {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView(String(localized: "common.purchasing"))
                        .padding(20)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.title2)
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadCreditPacks()
        }
    }
    
    private func loadCreditPacks() {
        isLoading = true
        loadError = false
        Task {
            await storeKitManager.loadCreditPacks()
            
            // 少し待ってから結果を確認
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
            
            await MainActor.run {
                isLoading = false
                if storeKitManager.availableCreditPacks.isEmpty {
                    loadError = true
                    print("⚠️ クレジットパックの読み込みに失敗しました")
                }
            }
        }
    }
    
    /// クレジットパックを購入
    private func purchasePack(_ product: Product) {
        guard !isPurchasing else { return }
        
        isPurchasing = true
        
        Task {
            do {
                let result = try await storeKitManager.purchaseCreditPack(product)
                
                alertTitle = String(localized: "credit.purchase_complete")
                alertMessage = String(localized: "credit.purchase_success \(result.creditsAmount)")
                showingAlert = true
                
            } catch StoreKitError.purchaseCancelled {
                // キャンセル時は何もしない
            } catch {
                alertTitle = String(localized: "common.error")
                alertMessage = String(localized: "credit.purchase_failed \(error.localizedDescription)")
                showingAlert = true
            }
            
            isPurchasing = false
        }
    }
}

/// クレジットパックカード
struct CreditPackCard: View {
    let product: Product
    let isPurchasing: Bool
    let onPurchase: () -> Void
    
    private var creditsAmount: Int {
        StoreKitManager.shared.creditsForProduct(product.id)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // クレジットアイコン
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // クレジット量
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "credit.credits_amount \(creditsAmount)"))
                    .font(.custom("YuseiMagic-Regular", size: 20))
                    .foregroundColor(.white)
                
                if creditsAmount >= 500 {
                    Text(creditsAmount >= 1000 ? String(localized: "credit.best_deal") : String(localized: "credit.good_deal"))
                        .font(.custom("YuseiMagic-Regular", size: 12))
                        .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            // 価格ボタン
            Button(action: onPurchase) {
                Text(product.displayPrice)
                    .font(.custom("YuseiMagic-Regular", size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.8, blue: 0.7), Color(red: 0.1, green: 0.6, blue: 0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
            .disabled(isPurchasing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CreditPurchaseView()
}
