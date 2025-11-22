import SwiftUI

/// 16進カラーコードから Color を生成するための拡張
extension Color {
    /// 16進カラーコード（#RRGGBB, #RGB, #AARRGGBB）から Color を生成する初期化メソッド
    /// 例:
    ///   Color(hex: "#FFC31C")
    ///   Color(hex: "77C7E3")
    ///   Color(hex: "#F3A")        → #FF33AA に展開
    ///   Color(hex: "AAFFC31C")   → 透明度付き
    init(hex: String) {
        // 1. 文字列から # やスペースを取り除いて英数字だけにする
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        // 2. 16進文字列を整数（UInt64）に変換
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        // 3. a(透明度), r, g, b を分割して格納する変数（0〜255）
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 3:
            // --- 3桁 (#RGB) の場合 ---
            // 例: "F3A" → F, 3, A → FF, 33, AA に拡張
            // 各桁を16進1桁 → 2桁にするために *17 している
            (a, r, g, b) = (
                255,                       // Aなし → 透明度は最大(255)
                (int >> 8) * 17,          // R
                (int >> 4 & 0xF) * 17,    // G
                (int & 0xF) * 17          // B
            )
            
        case 6:
            // --- 6桁 (#RRGGBB) の場合 ---
            // 例: "FFC31C" → FF, C3, 1C
            (a, r, g, b) = (
                255,                      // 不透明
                int >> 16,                // R
                int >> 8 & 0xFF,          // G
                int & 0xFF                // B
            )
            
        case 8:
            // --- 8桁 (#AARRGGBB) の場合 ---
            // 例: "AAFFC31C" → AA, FF, C3, 1C
            (a, r, g, b) = (
                int >> 24,                // A
                int >> 16 & 0xFF,         // R
                int >> 8 & 0xFF,          // G
                int & 0xFF                // B
            )
            
        default:
            // --- 不正な形式 → 黒 (不透明) を返す ---
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        // 4. 0〜255 の値を 0.0〜1.0 の範囲に変換して Color を初期化
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}