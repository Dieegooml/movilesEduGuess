import SwiftUI

/// Empty state reutilizable con icono animado, título, descripción y CTA opcional.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    @State private var animate = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryText.opacity(0.6))
                .symbolEffect(.bounce, options: .nonRepeating, value: animate)
                .onAppear {
                    animate.toggle()
                }

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText.opacity(0.9))
                .multilineTextAlignment(.center)

            Text(description)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let buttonTitle, let buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.backgroundTop)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppTheme.buttonGradient)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ZStack {
        AppTheme.mainGradient.ignoresSafeArea()
        EmptyStateView(
            icon: "trophy.fill",
            title: "Aún no hay ranking",
            description: "Sé el primero en jugar y aparecer en la tabla de líderes.",
            buttonTitle: "Jugar ahora",
            buttonAction: {}
        )
    }
}
