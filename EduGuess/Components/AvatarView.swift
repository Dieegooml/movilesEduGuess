import SwiftUI

struct AvatarView: View {
    let avatar: String
    var size: CGFloat = 40

    var body: some View {
        if avatar.hasPrefix("data:image/"),
           let data = Data(base64Encoded: avatar.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                .replacingOccurrences(of: "data:image/png;base64,", with: "")) {
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
        } else {
            Image(systemName: avatar.isEmpty ? "person.circle.fill" : avatar)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(.accentColor)
        }
    }
}
