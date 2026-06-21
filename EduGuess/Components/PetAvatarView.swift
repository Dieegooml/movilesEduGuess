import SwiftUI

enum PetEmotion: String, CaseIterable {
    case welcome
    case like
    case celebration
    case angry
    case surprised
    case thinking
    case idea

    var imageName: String {
        "pet_\(rawValue)"
    }
}

struct PetAvatarView: View {
    let emotion: PetEmotion
    var size: CGFloat = 120
    var animate: Bool = true

    @State private var isBouncing = false
    @State private var isWiggling = false

    var body: some View {
        Image(emotion.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .offset(y: isBouncing ? -size * 0.04 : 0)
            .rotationEffect(.degrees(isWiggling ? 3 : 0))
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isBouncing)
            .animation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true), value: isWiggling)
            .onAppear {
                guard animate else { return }
                isBouncing = emotion == .welcome || emotion == .celebration
                isWiggling = emotion == .angry || emotion == .surprised
            }
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(PetEmotion.allCases, id: \.self) { emotion in
            PetAvatarView(emotion: emotion, size: 60)
        }
    }
}
