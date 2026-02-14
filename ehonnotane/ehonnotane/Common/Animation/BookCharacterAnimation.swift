import SwiftUI

/// キャラクターの本のページが左にめくれるアニメーション
///
/// レイヤー構成（奥→手前）:
/// 1. CharacterBody: キャラクターの体（黒目なし）
/// 2. CharacterEyes: 黒目（左右にアニメーション）
/// 3. CharacterRightPage A/B: 右ページ2枚を交互に使用
/// 4. BookStatic: 本の表紙・背表紙・左ページ
/// 5. CharacterHands: キャラクターの手
///
/// アニメーション:
/// ページがめくれた後そのまま残り、新しいページがふわっと浮き出て再びめくれる
/// 黒目はページの移動に合わせて左右に動く
struct BookCharacterAnimation: View {
    // --- ページ A ---
    @State private var flipAngleA: Double = 0
    @State private var opacityA: Double = 1.0

    // --- ページ B ---
    @State private var flipAngleB: Double = 0
    @State private var opacityB: Double = 0.0

    /// 現在めくるのがページAならtrue、Bならfalse
    @State private var isPageATurn: Bool = true

    /// 黒目の水平オフセット（ページめくりに連動）
    @State private var eyeOffsetX: CGFloat = 0

    /// ページの回転軸（背表紙の位置）
    private let spineAnchorX: CGFloat = 163.0 / 385.0

    /// めくりアニメーションの時間（秒）
    private let flipDuration: Double = 1.5

    /// 次ページ出現アニメーションの時間（秒）
    private let appearDuration: Double = 0.5

    /// めくり後の待機時間（秒）
    private let pauseDuration: Double = 0.3

    /// 黒目の最大移動量（画像幅に対する比率）
    private let eyeMaxOffset: CGFloat = 4.0

    var body: some View {
        GeometryReader { geometry in
            let pageSize = CGSize(width: geometry.size.width, height: geometry.size.height)

            ZStack {
                // 1. 体（一番奥・黒目なし）
                Image("CharacterBody")
                    .resizable()
                    .aspectRatio(385.0 / 464.0, contentMode: .fit)
                    .frame(width: pageSize.width, height: pageSize.height)

                // 2. 黒目（ページめくりに合わせて左右に移動）
                Image("CharacterEyes")
                    .resizable()
                    .aspectRatio(385.0 / 464.0, contentMode: .fit)
                    .frame(width: pageSize.width, height: pageSize.height)
                    .offset(x: eyeOffsetX)

                // 3. ページ A
                pageLayer(angle: flipAngleA, opacity: opacityA, size: pageSize)

                // 4. ページ B（Aの上に重なる）
                pageLayer(angle: flipAngleB, opacity: opacityB, size: pageSize)

                // 5. 本の表紙・背表紙（ページの上）
                Image("BookStatic")
                    .resizable()
                    .aspectRatio(385.0 / 464.0, contentMode: .fit)
                    .frame(width: pageSize.width, height: pageSize.height)

                // 6. 手（一番手前）
                Image("CharacterHands")
                    .resizable()
                    .aspectRatio(385.0 / 464.0, contentMode: .fit)
                    .frame(width: pageSize.width, height: pageSize.height)
            }
            .clipped()
        }
        .aspectRatio(385.0 / 464.0, contentMode: .fit)
        .clipped()
        .onAppear {
            flipCurrentPage()
        }
    }

    /// ページレイヤーを生成
    private func pageLayer(angle: Double, opacity: Double, size: CGSize) -> some View {
        Image("CharacterRightPage")
            .resizable()
            .aspectRatio(385.0 / 464.0, contentMode: .fit)
            .frame(width: size.width, height: size.height)
            .opacity(opacity)
            .rotation3DEffect(
                .degrees(angle),
                axis: (x: 0, y: 1, z: 0),
                anchor: UnitPoint(x: spineAnchorX, y: 0.5),
                perspective: 0.4
            )
    }

    /// 現在のページをめくり、次のページを浮き出させるサイクル
    private func flipCurrentPage() {
        // 現在のページをめくる（0° → -180°）＋ 黒目を左に移動
        withAnimation(.easeInOut(duration: flipDuration)) {
            if isPageATurn {
                flipAngleA = -180
            } else {
                flipAngleB = -180
            }
            eyeOffsetX = -eyeMaxOffset
        }

        // めくり完了後、次のページを準備して浮き出させる
        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration + pauseDuration) {
            // 次のページの角度をリセット（アニメーションなし）
            if isPageATurn {
                // Aがめくれた → Bを準備
                flipAngleB = 0
            } else {
                // Bがめくれた → Aを準備
                flipAngleA = 0
            }

            // 次のページをふわっと表示 ＋ 黒目を右に戻す
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: appearDuration)) {
                    if isPageATurn {
                        opacityB = 1.0
                    } else {
                        opacityA = 1.0
                    }
                    eyeOffsetX = 0
                }

                // 出現完了後、ターンを切り替えて次のめくりへ
                DispatchQueue.main.asyncAfter(deadline: .now() + appearDuration + pauseDuration) {
                    isPageATurn.toggle()
                    flipCurrentPage()
                }
            }
        }
    }
}

#Preview {
    BookCharacterAnimation()
        .frame(width: 300, height: 360)
        .padding()
        .background(Color.white)
}

