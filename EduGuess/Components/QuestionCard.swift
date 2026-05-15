//
//  QuestionCard.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//
import SwiftUI

struct QuestionCard: View {

    let question: String

    var body: some View {

        VStack(spacing: 20) {

            Text(question)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(25)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct QuestionCard_Previews: PreviewProvider {
    static var previews: some View {
        
        QuestionCard(
            question: "¿Qué lenguaje utiliza SwiftUI?"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
