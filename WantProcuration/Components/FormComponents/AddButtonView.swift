//
//  AddButtonView.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 12/10/2025.
//

import SwiftUI
import SwiftfulUI
struct AddButtonView: View {
    var title : String
    var backgroundColor : Color = Color.theme.lightBlue
    var foregroundColor : Color = Color.white
    var action : () -> Void
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18))
            Text(title)
                .font(Font.setFontRegular())
        }
        .foregroundColor(foregroundColor)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(backgroundColor)
        .clipShape(Capsule())
        .shadow(radius: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .asButton {
            action()
        }
    }
}

#Preview {
    AddButtonView(title: "Add Button", action: {})
}
