import SwiftUI
import FirebaseFirestore

struct Comment: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let text: String
    let timestamp: Date
}

struct CommentsView: View {
    let profileUserId: String

    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoading = true
    @State private var isSending = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comentarios")
                .font(.headline)
                .foregroundColor(.white)

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Escribe un comentario...", text: $newCommentText)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isSending)

                        Button {
                            Task { await sendComment() }
                        } label: {
                            if isSending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                    }

                    if comments.isEmpty {
                        Text("Sin comentarios. ¡Sé el primero!")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.caption)
                            .padding(.top, 4)
                    } else {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.userName)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(comment.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Text(comment.text)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .task { await loadComments() }
    }

    private func loadComments() async {
        let db = Firestore.firestore()
        let snapshot = try? await db.collection("users")
            .document(profileUserId)
            .collection("comments")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments()
        comments = snapshot?.documents.compactMap { try? $0.data(as: Comment.self) } ?? []
        isLoading = false
    }

    private func sendComment() async {
        let text = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isSending = true

        let authVM = AuthViewModel.shared
        let comment = Comment(
            userId: authVM.userUID ?? "",
            userName: authVM.userName,
            text: text,
            timestamp: Date()
        )

        let db = Firestore.firestore()
        try? await db.collection("users")
            .document(profileUserId)
            .collection("comments")
            .addDocument(from: comment)

        newCommentText = ""
        isSending = false
        await loadComments()
    }
}
