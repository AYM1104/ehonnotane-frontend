import SwiftUI
import StoreKit

/// StoreKit動作確認用のテストビュー
struct StoreKitTestView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // ローディング状態
                if storeKitManager.isLoading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("読み込み中...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // エラー表示
                if let error = storeKitManager.lastError {
                    Section("エラー") {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                // プロダクト一覧
                Section("利用可能なプロダクト (\(storeKitManager.products.count))") {
                    if storeKitManager.products.isEmpty {
                        Text("プロダクトが見つかりません")
                            .foregroundColor(.secondary)
                        
                        Button("再読み込み") {
                            Task {
                                await storeKitManager.loadProducts()
                            }
                        }
                    } else {
                        ForEach(storeKitManager.products, id: \.id) { product in
                            ProductRow(product: product)
                        }
                    }
                }
                
                // 購入済みサブスクリプション
                Section("購入済みサブスクリプション (\(storeKitManager.purchasedSubscriptions.count))") {
                    if storeKitManager.purchasedSubscriptions.isEmpty {
                        Text("購入済みサブスクリプションはありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(storeKitManager.purchasedSubscriptions, id: \.id) { product in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.displayName)
                                        .font(.headline)
                                    Text(product.id)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // サブスクリプション状態
                if let status = storeKitManager.subscriptionStatus {
                    Section("サブスクリプション状態") {
                        LabeledContent("状態", value: "\(status.state)")
                        // RenewalInfoは検証結果なので、verified caseを確認
                        switch status.renewalInfo {
                        case .verified(let renewalInfo):
                            LabeledContent("自動更新", value: renewalInfo.willAutoRenew ? "有効" : "無効")
                        case .unverified:
                            LabeledContent("自動更新", value: "検証失敗")
                        }
                    }
                }
                
                // アクション
                Section("アクション") {
                    Button("購入を復元") {
                        Task {
                            do {
                                try await storeKitManager.restorePurchases()
                                alertMessage = "購入の復元が完了しました"
                                showAlert = true
                            } catch {
                                alertMessage = "復元失敗: \(error.localizedDescription)"
                                showAlert = true
                            }
                        }
                    }
                    
                    Button("状態を更新") {
                        Task {
                            await storeKitManager.checkPurchasedSubscriptions()
                        }
                    }
                }
            }
            .navigationTitle("StoreKit テスト")
            .navigationBarTitleDisplayMode(.inline)
            .alert("通知", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
}

// MARK: - Product Row
struct ProductRow: View {
    let product: Product
    @EnvironmentObject var storeKitManager: StoreKitManager
    @State private var isPurchasing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.title3)
                    .bold()
            }
            
            // サブスクリプション期間
            if let subscription = product.subscription {
                Text("期間: \(periodUnitDescription(subscription.subscriptionPeriod.unit)) × \(subscription.subscriptionPeriod.value)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 無料トライアル
                if let introOffer = subscription.introductoryOffer {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.green)
                        Text("無料トライアル: \(periodUnitDescription(introOffer.period.unit)) × \(introOffer.period.value)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // 購入ボタン
            Button(action: {
                Task {
                    isPurchasing = true
                    defer { isPurchasing = false }
                    
                    do {
                        let _ = try await storeKitManager.purchase(product)
                        print("✅ 購入成功: \(product.displayName)")
                    } catch StoreKitError.purchaseCancelled {
                        print("⚠️ 購入キャンセル")
                    } catch {
                        print("❌ 購入エラー: \(error)")
                    }
                }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Text(isPurchasing ? "処理中..." : "購入する")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing || storeKitManager.isLoading)
        }
        .padding(.vertical, 4)
    }
    
    // 期間の単位を日本語で表示
    private func periodUnitDescription(_ unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: return "日"
        case .week: return "週"
        case .month: return "ヶ月"
        case .year: return "年"
        @unknown default: return "不明"
        }
    }
}

#Preview {
    StoreKitTestView()
        .environmentObject(StoreKitManager.shared)
}
