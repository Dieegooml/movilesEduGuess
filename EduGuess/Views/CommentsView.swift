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
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comentarios")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
                .onTapGesture { UIApplication.shared.endEditing() }

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Escribe un comentario...", text: $newCommentText)
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor(AppTheme.primaryText)
                            .disabled(isSending)

                        Button {
                            Task { await sendComment() }
                        } label: {
                            if isSending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(AppTheme.primaryGold)
                            }
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                    }

                    if comments.isEmpty {
                        Text("Sin comentarios. ¡Sé el primero!")
                            .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                            .font(.caption)
                            .padding(.top, 4)
                    } else {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.userName)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.primaryText)
                                    Spacer()
                                    Text(comment.timestamp, style: .relative)
                                        .font(.caption2)
                                        .foregroundColor(AppTheme.mutedText)
                                }
                                Text(comment.text)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(10)
                            .background(AppTheme.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            )
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .task { await loadComments() }
        .toast(message: errorText, icon: "exclamationmark.circle.fill", isShowing: $showError)
    }

    private func loadComments() async {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("users")
                .document(profileUserId)
                .collection("comments")
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .getDocuments()
            comments = snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
        } catch {
            errorText = "Error al cargar comentarios"
            showError = true
        }
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
        do {
            try await db.collection("users")
                .document(profileUserId)
                .collection("comments")
                .addDocument(from: comment)
        } catch {
            errorText = "Error al enviar comentario"
            showError = true
        }

        newCommentText = ""
        isSending = false
        await loadComments()
    }
}
