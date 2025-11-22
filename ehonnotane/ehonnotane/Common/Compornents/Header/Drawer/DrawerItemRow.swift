import SwiftUI

// ドロワー内の共通行コンポーネント
struct DrawerItemRow: View {
    let title: String
    let icon: Image
    let action: () -> Void
    
    private var subTextColor: Color {
        Color(hex: "362D30")
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(subTextColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(subTextColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(subTextColor.opacity(0.6))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 12) {
            DrawerItemRow(title: "アカウント", icon: Image(systemName: "person"), action: {})
            DrawerItemRow(title: "アプリ情報", icon: Image(systemName: "info.circle"), action: {})
        }
        .padding()
    }
}


