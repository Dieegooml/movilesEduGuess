//
//  HomeView.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct HomeView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var buttonsAppeared = false

    private let menuItems: [(title: String, color: Color, destination: AnyView)] = [
        ("Desafío Diario", .yellow, AnyView(DailyChallengeView())),
        ("Comenzar", .white, AnyView(CategorySelectView())),
        ("Personajes", .clear, AnyView(CharacterListView())),
        ("Historial", .clear, AnyView(GameHistoryView())),
        ("Administrar", .clear, AnyView(AdminListView())),
        ("Mi Perfil", .clear, AnyView(ProfileView())),
        ("Ranking", .clear, AnyView(LeaderboardView())),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
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
                    ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                        NavigationLink(destination: item.destination) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundColor(index == 0 ? .orange : .white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(index == 0 ? Color.white : (index == 1 ? Color.orange : Color.clear))
                                .cornerRadius(18)
                                .overlay(
                                    index > 1 ?
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white, lineWidth: 2) : nil
                                )
                        }
                        .offset(x: buttonsAppeared ? 0 : (index.isMultiple(of: 2) ? -200 : 200))
                        .opacity(buttonsAppeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                            .delay(Double(index) * 0.08),
                            value: buttonsAppeared
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
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    NavigationLink {
                        HowToPlayView()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.white)
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
            }
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
        .onAppear {
            buttonsAppeared = false
            withAnimation(.easeOut(duration: 0.1)) {
                buttonsAppeared = true
            }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
