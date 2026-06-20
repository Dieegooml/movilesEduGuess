//
//  SplashView.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct SplashView: View {

    @State private var showHome = false
    @State private var animateLogo = false
    @State private var animateText = false
    @State private var showProgress = false
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo con animación de pulso
                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, options: .repeat(1), value: animateLogo)
                    .scaleEffect(animateLogo ? 1.0 : 0.5)
                    .opacity(animateLogo ? 1.0 : 0.0)

                // Texto con fade-in escalonado
                VStack(spacing: 12) {
                    Text("EduGuess")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 20)

                    Text("La IA que adivina personajes")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 10)
                }

                Spacer()

                // Barra de progreso sutil
                if showProgress {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)

                        Text("Cargando...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .opacity(showProgress ? 1.0 : 0.0)
                }

                Spacer()
                    .frame(height: 40)
            }
            .opacity(showHome ? 0 : 1)
            .animation(.easeOut(duration: 0.4), value: showHome)
        }
        .navigationDestination(isPresented: $showHome) {
            HomeView()
        }
        .onAppear {
            // Animación escalonada
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateLogo = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateText = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showProgress = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                showHome = true
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
