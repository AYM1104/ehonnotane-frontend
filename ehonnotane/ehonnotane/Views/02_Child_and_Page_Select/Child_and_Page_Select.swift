import SwiftUI

struct Child_and_Page_Selection_View: View {
    
    /// アップロード結果（前の画面から渡される）
    var uploadResult: UploadResult?

    // ViewModelを使用
    @StateObject private var viewModel = ChildAndPageSelectViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    
    @State private var showingCreditAlert: Bool = false
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()  // 背景に大きなキャラクターを表示
            }

            // メインコンテンツ        
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)

                // メインテキスト
                MainText(text: "どんな えほんを")
                MainText(text: "つくろうかな？")
                Spacer()          
            
                // メインカード
                mainCard(width: .screen95) {

                    // インナーカード
                    SelectInputBoxCard(
                        title: "ページ数をえらんでね",
                        options: viewModel.availablePageCountOptions,
                        selection: $viewModel.selectedPageCount,
                        subTitle: "消費クレジット: \(viewModel.requiredCredits)"
                    ) {
                        // お子さまを選択 (2人以上の場合のみ表示)
                        if viewModel.childrenCount >= 2 {
                            VStack(spacing: 12) {
                                SubText(text: "お子さまをえらんでね")
                                Select_Input_Box(
                                    options: viewModel.childOptions,
                                    answer: $viewModel.selectedChild
                                )
                                .frame(maxWidth: 360)
                            }
                        }
                    } footer: {
                        // ボタン
                        PrimaryButton(
                            title: "これにけってい",
                            style: .primary,
                            isLoading: viewModel.isLoading
                        ) {
                            if viewModel.hasInsufficientCredits {
                                showingCreditAlert = true
                            } else {
                                // 次の画面への遷移処理
                                Task {
                                    do {
                                        if let storySettingId = uploadResult?.storySettingId {
                                            try await viewModel.confirmSelection(storySettingId: storySettingId)
                                            
                                            // 画面遷移（子供が0人の場合はchildIdを0として扱う）
                                            if let storyPages = Int(viewModel.selectedPageCount) {
                                                let childId = Int(viewModel.selectedChild) ?? 0
                                                coordinator.navigateToQuestion(
                                                    storySettingId: storySettingId,
                                                    childId: childId,
                                                    storyPages: storyPages
                                                )
                                            }
                                        } else {
                                            print("❌ Upload result is missing")
                                            errorMessage = "アップロード情報が見つかりません"
                                            showingErrorAlert = true
                                        }
                                    } catch {
                                        print("❌ Confirmation failed: \(error)")
                                        errorMessage = "設定の保存に失敗しました: \(error.localizedDescription)"
                                        showingErrorAlert = true
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, -11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            // ヘッダー
            Header()
            
            // モーダル表示
            if showingCreditAlert {
                CreditInsufficientModal(
                    isPresented: $showingCreditAlert,
                    requiredCredits: viewModel.requiredCredits,
                    currentCredits: viewModel.currentCredits
                ) {
                    // TODO: クレジット追加画面への遷移
                    print("クレジットを追加 tapped")
                }
                .zIndex(100) // 最前面に表示
            }
        }
        // View表示時に起動する機能
        .onAppear {
            Task {
                // 子供の情報を取得
                await viewModel.loadChildren()
            }
        }
        // エラーアラート
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

// プレビュー専用のラッパービュー（モックViewModelを使用）
struct Child_and_Page_Selection_View_Preview: View {
    @StateObject private var viewModel = ChildAndPageSelectViewModel(
        mockMode: true,
        mockChildrenCount: 2,
        mockCredits: 200
    )
    @StateObject private var coordinator = AppCoordinator()
    
    @State private var showingCreditAlert: Bool = false
    @State private var showingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }

            // メインコンテンツ        
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)

                // メインテキスト
                MainText(text: "どんな えほんを")
                MainText(text: "つくろうかな？")
                Spacer()          
            
                // メインカード
                mainCard(width: .screen95) {

                    // インナーカード
                    SelectInputBoxCard(
                        title: "ページ数をえらんでね",
                        options: viewModel.availablePageCountOptions,
                        selection: $viewModel.selectedPageCount,
                        subTitle: "消費クレジット: \(viewModel.requiredCredits)"
                    ) {
                        // お子さまを選択 (2人以上の場合のみ表示)
                        if viewModel.childrenCount >= 2 {
                            VStack(spacing: 12) {
                                SubText(text: "お子さまをえらんでね")
                                Select_Input_Box(
                                    options: viewModel.childOptions,
                                    answer: $viewModel.selectedChild
                                )
                                .frame(maxWidth: 360)
                            }
                        }
                    } footer: {
                        // ボタン
                        PrimaryButton(
                            title: "これにけってい",
                            style: .primary,
                            isLoading: viewModel.isLoading
                        ) {
                            // プレビューでは何もしない
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, -11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            // ヘッダー
            Header()
            
            // モーダル表示
            if showingCreditAlert {
                CreditInsufficientModal(
                    isPresented: $showingCreditAlert,
                    requiredCredits: viewModel.requiredCredits,
                    currentCredits: viewModel.currentCredits
                ) {
                    print("クレジットを追加 tapped")
                }
                .zIndex(100)
            }
        }
        // エラーアラート
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    Child_and_Page_Selection_View_Preview()
}
