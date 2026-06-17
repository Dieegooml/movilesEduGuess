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

        Text(question)
            .font(.title2.weight(.bold))
            .multilineTextAlignment(.center)
            .foregroundColor(.primary)
            .minimumScaleFactor(0.6)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
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
