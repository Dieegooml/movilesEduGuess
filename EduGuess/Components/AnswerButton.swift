//
//  AnswerButton.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct AnswerButton: View {

    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .cornerRadius(18)
        }
    }
}

struct AnswerButton_Previews: PreviewProvider {
    static var previews: some View {
        
        AnswerButton(
            title: "Responder",
            color: .orange,
            action: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
