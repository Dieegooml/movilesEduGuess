//
//  WrongGuessView.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct WrongGuessView: View {

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {

                Spacer()

                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .foregroundColor(.white)

                Text("No pude adivinar")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("La IA aprenderá para mejorar")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                NavigationLink {
                    HomeView()
                } label: {
                    Text("Intentar otra vez")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct WrongGuessView_Previews: PreviewProvider {
    static var previews: some View {
        WrongGuessView()
    }
}
