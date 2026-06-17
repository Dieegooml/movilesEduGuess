//
//  CategoryButton.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

//
//  CategoryButton.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI

struct CategoryButton: View {
    
    let title: String
    let icon: String
    
    var body: some View {
        
        VStack(spacing: 10) {
            
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(width: 120, height: 120)
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .shadow(radius: 4)
    }
}

struct CategoryButton_Previews: PreviewProvider {
    static var previews: some View {
        
        CategoryButton(
            title: "Swift",
            icon: "swift"
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
