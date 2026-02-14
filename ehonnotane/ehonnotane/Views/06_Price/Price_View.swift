import SwiftUI
import StoreKit

struct PriceView: View {
    // StoreKit管理
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    // 現在表示中のカードインデックス
    @State private var currentIndex: Int = 0
    // 横スクロールの現在位置（スナップ用）
    @State private var scrollOffset: CGFloat = 0
    // ドラッグ中の一時オフセット
    @State private var dragOffset: CGFloat = 0
    
    // エラーアラート
    @State private var showingAlert = false
    @State private var alertTitle = String(localized: "common.error")
    @State private var alertMessage = ""
    
    // クレジット購入シート
    @State private var showCreditPurchaseSheet = false
    
    // 利用規約・プライバシーポリシー表示フラグ
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false

    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {}
            
            // ローディング表示
            if storeKitManager.isLoading {
                ProgressView(String(localized: "common.processing"))
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
        
            // メインカード（画面下部に配置）
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト
                MainText(text: String(localized: "price.header_line1"))
                MainText(text: String(localized: "price.header_line2"))
                Spacer().frame(height: 28)
                MainText(text: String(localized: "price.header_subtitle"), fontSize: 20)
                Spacer().frame(height: 40)

                // メインカード（カルーセル）
                Carousel()
                
                // クレジット個別購入ボタン
                Spacer()
                Button(action: { showCreditPurchaseSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text(String(localized: "price.buy_credits_individually"))
                            .font(.custom("YuseiMagic-Regular", size: 16))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .sheet(isPresented: $showCreditPurchaseSheet) {
                    CreditPurchaseView()
                }
                
                // 購入を復元 | 利用規約 | プライバシーポリシー
                Spacer().frame(height: 16)
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            do {
                                try await storeKitManager.restorePurchases()
                                alertTitle = String(localized: "common.complete")
                                alertMessage = String(localized: "price.restore_success")
                                showingAlert = true
                            } catch {
                                alertTitle = String(localized: "common.error")
                                alertMessage = String(localized: "price.restore_failed")
                                showingAlert = true
                            }
                        }
                    }) {
                        Text(String(localized: "price.restore_purchases"))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                    Text("|")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Button(action: { showTermsOfService = true }) {
                        Text(String(localized: "settings.terms"))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                    Text("|")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Button(action: { showPrivacyPolicy = true }) {
                        Text(String(localized: "settings.privacy"))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                }
                .sheet(isPresented: $showTermsOfService) {
                    LegalDocumentView(documentType: .termsOfService)
                }
                .sheet(isPresented: $showPrivacyPolicy) {
                    LegalDocumentView(documentType: .privacyPolicy)
                }
                
                Spacer().frame(height: 4)
            }
            // ヘッダー
            Header()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // プロダクト読み込み
            Task {
                await storeKitManager.loadProducts()
            }
        }
        // .ignoresSafeArea()
    }
}


// MARK: - カルーセル本体
private extension PriceView {
    @ViewBuilder
    func Carousel() -> some View {
        // カードを3枚に固定
        let cards = Array(0..<3)
        let cardSpacing: CGFloat = 12
        
        GeometryReader { proxy in
            // 画面幅ベースでレイアウト計算（UIKit 不要）
            let screenWidth = proxy.size.width
            let cardWidth = screenWidth * 0.78
            // 中央に1枚分を配置しつつ、次カードが少し見えるように左右余白を調整
            let sidePadding = (screenWidth - cardWidth) / 2
            // HStack をオフセットさせてページングのように見せる
            let pageWidth = cardWidth + cardSpacing

            HStack(spacing: cardSpacing) {
                ForEach(cards, id: \.self) { index in
                    mainCard(width: .screen95, height: 420) {
                        // 上下にSpacerを入れて中央配置
                        Spacer()
                        // カード内容（例）：プラン名・価格など
                        VStack(spacing: 12) {
                            // ロゴ
                            Image(planLogo(for: index))
                                .resizable()
                                .scaledToFit()
                                .frame(height: 10)
                            
                            HStack(alignment: .lastTextBaseline) {
                                Text(planTitle(for: index))
                                    .font(.custom("YuseiMagic-Regular", size: 28))
                                    .foregroundColor(.white)
                                Text(String(localized: "price.plan_label"))
                                    .font(.custom("YuseiMagic-Regular", size: 18))
                                    .foregroundColor(.white)
                            }
                            Spacer().frame(height: 8)
                            Text(planSubtitle(for: index))
                                .font(.custom("YuseiMagic-Regular", size: 18))
                                .foregroundColor(.white)
                            Spacer().frame(height: 8)
                            HStack(alignment: .lastTextBaseline) {
                                Text(planPrice(for: index))
                                    .font(.custom("YuseiMagic-Regular", size: 42))
                                    .foregroundColor(.white)
                                Text(String(localized: "price.per_month"))
                                    .font(.custom("YuseiMagic-Regular", size: 28))
                                    .foregroundColor(.white)
                            }
                            // プラン毎のクレジット数（先頭にチェックアイコン）
                            Spacer().frame(height: 6)
                            HStack(alignment: .center, spacing: 8) {
                                Image(systemName: "checkmark.app")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundStyle(Color.white)
                                Text(String(localized: "price.monthly_credits \(planMonthlyCredits(for: index))"))
                                    .font(.custom("YuseiMagic-Regular", size: 18))
                                    .foregroundColor(.white)
                            }
                            
                            // ボタン
                            Spacer().frame(height: 12)
                            PrimaryButton(
                                title: String(localized: "price.select_plan"),
                                width: cardWidth * 0.8,
                                action: {
                                    // プラン選択のアクション
                                    handlePlanSelection(index: index)
                                }
                            )
                        }
                        .padding(.vertical, 12)
                        Spacer()
                    }
                    .frame(width: cardWidth)
                    .scaleEffect(index == currentIndex ? 1.0 : 0.9)
                    .animation(.spring(response: 0.28, dampingFraction: 0.86), value: currentIndex)
                }
            }
            .padding(.horizontal, sidePadding)
            .offset(x: -scrollOffset + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        // 予測終了位置を使ってスナップ先を決定
                        let predicted = scrollOffset - value.predictedEndTranslation.width
                        let rawIndex = predicted / pageWidth
                        let snapped = (rawIndex).rounded()
                        let newIndex = max(0, min(cards.count - 1, Int(snapped)))

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            currentIndex = newIndex
                            scrollOffset = CGFloat(newIndex) * pageWidth
                            dragOffset = 0
                        }
                    }
            )
            .onChange(of: currentIndex) { _, newValue in
                // インデックス変更時はスナップ位置も同期
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    scrollOffset = CGFloat(newValue) * pageWidth
                }
            }
            .onAppear {
                // 初期位置は 0（1枚目）
                scrollOffset = 0
            }
        }
        .frame(height: 360)
    }

    // プラン名などのダミー文言をインデックスで切り替え
    func planTitle(for index: Int) -> String {
        switch index {
        case 0: return String(localized: "price.plan_starter")
        case 1: return String(localized: "price.plan_plus")
        default: return String(localized: "price.plan_premium")
        }
    }

    // プランごとのロゴ名
    func planLogo(for index: Int) -> String {
        switch index {
        case 0: return "Price_Logo_Basic"
        case 1: return "Price_logo_Standard"
        default: return "Price_logo_Premium"
        }
    }

    func planSubtitle(for index: Int) -> String {
        switch index {
        case 0: return String(localized: "price.plan_starter_subtitle")
        case 1: return String(localized: "price.plan_plus_subtitle")
        default: return String(localized: "price.plan_premium_subtitle")
        }
    }

    func planPrice(for index: Int) -> String {
        let productId: String
        switch index {
        case 0: productId = "com.ehonnotane.subscription.starter"
        case 1: productId = "com.ehonnotane.subscription.plus"
        default: productId = "com.ehonnotane.subscription.premium"
        }
        
        // StoreKitから動的に価格を取得
        if let product = storeKitManager.availableProducts.first(where: { $0.id == productId }) {
            return product.displayPrice
        }
        
        // フォールバック（ローディング中など）
        return "..."
    }

    
    // プランごとの毎月付与クレジット数
    // 数値は仮値。必要に応じて調整してください
    func planMonthlyCredits(for index: Int) -> Int {
        switch index {
        case 0: return 600
        case 1: return 1000
        default: return 1500
        }
    }
    
    // 文頭にチェック入り四角アイコンを付けた行
    @ViewBuilder
    func featureRow(_ text: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            CheckSquareIcon()
            MainText(text: text, fontSize: 18)
        }
    }
    
    // チェック入りの角丸スクエアアイコン（デザインに近い表現）
    struct CheckSquareIcon: View {
        var body: some View {
            Image(systemName: "checkmark.app")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.white)
        }
    }
    
    // プラン選択時の処理
    func handlePlanSelection(index: Int) {
        let planName = planTitle(for: index)
        let price = planPrice(for: index)
        
        print("選択されたプラン: \(planName) (\(price))")
        
        // プロダクトIDを取得
        let productId: String
        switch index {
        case 0:
            productId = "com.ehonnotane.subscription.starter"
        case 1:
            productId = "com.ehonnotane.subscription.plus"
        default:
            productId = "com.ehonnotane.subscription.premium"
        }
        
        // StoreKitManagerから該当プロダクトを検索
        guard let product = storeKitManager.availableProducts.first(where: { $0.id == productId }) else {
            alertTitle = String(localized: "common.error")
            alertMessage = String(localized: "price.error_product_not_found")
            showingAlert = true
            return
        }
        
        // 購入開始
        Task {
            do {
                let transaction = try await storeKitManager.purchase(product)
                print("✅ 購入完了: \(transaction.productID)")
                
                // 成功メッセージ
                alertTitle = String(localized: "common.complete")
                alertMessage = String(localized: "price.purchase_success \(planName)")
                showingAlert = true
                
            } catch StoreKitError.purchaseCancelled {
                print("ℹ️ ユーザーが購入をキャンセルしました")
                // キャンセル時はアラート表示しない
                
            } catch {
                print("❌ 購入エラー: \(error)")
                alertTitle = String(localized: "common.error")
                alertMessage = String(localized: "price.purchase_failed \(error.localizedDescription)")
                showingAlert = true
            }
        }
    }
}


#Preview {
    PriceView()
        // .environmentObject(AppCoordinator())
        // .environmentObject(AuthService())
}
