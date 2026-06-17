//
//  ProgressBar.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct ProgressBar: View {

    var progress: CGFloat

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text("Progreso")
                .font(.headline)

            GeometryReader { geometry in

                ZStack(alignment: .leading) {

                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 14)
                        .foregroundColor(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 10)
                        .frame(
                            width: geometry.size.width * progress,
                            height: 14
                        )
                        .foregroundColor(.orange)
                }
            }
            .frame(height: 14)
        }
        .padding(.horizontal)
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {

        ProgressBar(progress: 0.5)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
