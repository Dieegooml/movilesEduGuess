//
//  CorrectGuessView.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//


import SwiftUI

struct CorrectGuessView: View {

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [Color.green, Color.teal],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .foregroundColor(.white)

                Text("¡Lo adiviné!")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)

                Text("Tu personaje es Harry Potter")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.95))
                    .padding(.horizontal)

                Spacer()

                Button {

                } label: {
                    Text("Jugar otra vez")
                        .font(.headline)
                        .foregroundColor(.green)
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


struct CorrectGuessView_Previews: PreviewProvider {
    static var previews: some View {
        CorrectGuessView()
    }
}
