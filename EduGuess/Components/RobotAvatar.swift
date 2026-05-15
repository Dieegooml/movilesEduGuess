//
//  RobotAvatar.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct RobotAvatar: View {

    var body: some View {

        ZStack {

            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 150, height: 150)

            Image(systemName: "brain.head.profile")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.orange)
        }
    }
}

struct RobotAvatar_Previews: PreviewProvider {
    static var previews: some View {
        RobotAvatar()
    }
}
