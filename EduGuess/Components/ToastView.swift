import SwiftUI

struct Toast: ViewModifier {
    let message: String
    let icon: String
    @Binding var isShowing: Bool
    let duration: TimeInterval

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isShowing {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .foregroundColor(AppTheme.primaryGold)
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.primaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AppTheme.cardSurfaceSolid.opacity(0.95))
                    )
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation { isShowing = false }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.4), value: isShowing)
    }
}

extension View {
    func toast(message: String, icon: String = "checkmark.circle.fill", isShowing: Binding<Bool>, duration: TimeInterval = 2) -> some View {
        modifier(Toast(message: message, icon: icon, isShowing: isShowing, duration: duration))
    }
}
