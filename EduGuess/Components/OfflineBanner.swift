import SwiftUI

/// Banner flotante que indica estado offline. Se muestra automáticamente cuando no hay conexión.
struct OfflineBanner: View {
    @State private var isVisible = false
    @State private var showRetry = false
    var onRetry: (() -> Void)? = nil

    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)

                Text("Sin conexión a internet")
                    .font(.subheadline)
                    .foregroundColor(.white)

                Spacer()

                if let onRetry {
                    Button {
                        withAnimation {
                            showRetry = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onRetry()
                            showRetry = false
                        }
                    } label: {
                        if showRetry {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Text("Reintentar")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color.red.opacity(0.9))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    func monitor() -> some View {
        self
            .onAppear {
                updateVisibility()
                NetworkMonitor.shared.onChange { _ in
                    DispatchQueue.main.async {
                        withAnimation(.spring(duration: 0.3)) {
                            updateVisibility()
                        }
                    }
                }
            }
    }

    private func updateVisibility() {
        isVisible = !NetworkMonitor.shared.isConnected
    }
}

#Preview {
    VStack {
        OfflineBanner()
            .monitor()
        Spacer()
    }
}
