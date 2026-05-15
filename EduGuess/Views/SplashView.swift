//
//  SplashView.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct SplashView: View {

    @State private var navigate = false

    var body: some View {

        NavigationStack {

            ZStack {

                LinearGradient(
                    colors: [
                        Color.orange,
                        Color.red
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 25) {

                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.white)

                    Text("EduGuess")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Text("La IA que adivina personajes")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    navigate = true
                }
            }
            .navigationDestination(isPresented: $navigate) {
                HomeView()
            }
        }
    }
}


struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
