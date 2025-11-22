import SwiftUI
import Combine

// テーマ選択ビュー
struct Theme_Select_View: View {
    @StateObject private var viewModel = ThemeSelectViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var authManager: AuthManager
    
    @State private var currentPageIndex = 0
    
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

                // メインテキストを表示
                MainText(text: "どんな えほんを")
                MainText(text: "つくろうかな？")
                Spacer()
            
                // メインカード
                mainCard(width: .screen95) {
                    VStack {
                        if viewModel.isLoading {
                            // 読み込み中
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("テーマをかんがえているよ...")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.themePages.isEmpty {
                            // データなしまたはエラー
                            VStack(spacing: 20) {
                                if let error = viewModel.errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                } else {
                                    Text("テーマが見つかりませんでした")
                                        .foregroundColor(.gray)
                                }
                                
                                Button("再読み込み") {
                                    Task {
                                        await viewModel.loadThemeData(coordinator: coordinator)
                                    }
                                }
                                .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // テーマデータがある場合
                            VStack(spacing: 16) {
                                // PageSliderでスライド機能を実装
                                PageSlider(viewModel.themePages, currentIndex: $currentPageIndex) { page in
                                    // インナーカードを表示
                                    ThemeDetailCard(
                                        page: page,
                                        isGeneratingImages: viewModel.isGeneratingImages,
                                        onSelect: {
                                            Task {
                                                await viewModel.selectTheme(page: page, coordinator: coordinator)
                                            }
                                        }
                                    )
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                // プログレスバーを表示
                                if viewModel.isGeneratingImages {
                                    // 画像生成中の進捗表示
                                    VStack(spacing: 12) {
                                        ProgressBar(
                                            totalSteps: viewModel.totalSteps,
                                            currentStep: viewModel.currentStep
                                        )
                                        .padding(.horizontal, 20)
                                        
                                        // 進捗メッセージ
                                        SubText(
                                            text: viewModel.stepMessage,
                                            fontSize: 14
                                        )
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                    }
                                } else {
                                    // 通常のテーマ選択進捗
                                    ProgressBar(
                                        totalSteps: viewModel.themePages.count,
                                        currentStep: currentPageIndex + 1
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(.bottom, -11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            // ヘッダー
            Header()
        }
        .onAppear {
            Task {
                await viewModel.loadThemeData(coordinator: coordinator)
            }
        }
    }
}

struct Theme_Select_View_Previews: PreviewProvider {
    static var previews: some View {
        Theme_Select_View()
            .environmentObject(AppCoordinator())
        
    }
}
