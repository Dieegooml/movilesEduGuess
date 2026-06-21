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
    @State private var rotation: Double = 0
    @State private var floatOffset: CGFloat = 20

    var body: some View {
        ZStack {
            AppTheme.mainGradient
                .ignoresSafeArea()

            // Soft ambient glow behind mascot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.primaryYellow.opacity(0.20),
                            AppTheme.primaryYellow.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(y: floatOffset)

            VStack(spacing: 28) {
                Spacer()

                PetAvatarView(emotion: .welcome, size: 160, animate: false)
                    .rotationEffect(.degrees(rotation))
                    .offset(y: floatOffset)
                    .scaleEffect(animateLogo ? 1.0 : 0.5)
                    .opacity(animateLogo ? 1.0 : 0.0)

                VStack(spacing: 12) {
                    Text("EduGuess")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, AppTheme.primaryYellow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 20)

                    Text("La IA que adivina personajes")
                        .font(.headline)
                        .foregroundColor(AppTheme.secondaryText)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 10)
                }

                Spacer()

                if showProgress {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(AppTheme.primaryYellow)
                            .scaleEffect(1.3)

                        Text("Cargando...")
                            .font(.caption)
                            .foregroundColor(AppTheme.mutedText)
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
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                animateLogo = true
            }

            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = -20
            }

            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                rotation = 8
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
