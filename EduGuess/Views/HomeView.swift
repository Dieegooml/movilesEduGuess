//
//  HomeView.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct HomeView: View {
    @State private var authVM = AuthViewModel.shared

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color.orange.opacity(0.9),
                    Color.red.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {

                Spacer()

                VStack(spacing: 20) {

                    Image(systemName: "brain")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)

                    Text("EduGuess")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.white)

                    Text("Piensa en un personaje y la IA intentará adivinarlo")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal)
                }

                if authVM.isAuthenticated {
                    Text("Bienvenido, \(authVM.userName)")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.subheadline)
                }

                VStack(spacing: 16) {

                    NavigationLink {
                        QuestionView()
                    } label: {
                        Text("Comenzar")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(18)
                    }

                    NavigationLink {
                        ProfileView()
                    } label: {
                        Text("Mi Perfil")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }

                    NavigationLink {
                        LeaderboardView()
                    } label: {
                        Text("Ranking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                Text("Powered by AI")
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 25)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if authVM.isAuthenticated {
                    Button {
                        authVM.signOut()
                    } label: {
                        Text("Salir")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
