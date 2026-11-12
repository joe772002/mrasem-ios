//
//  FormRow.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 08/10/2025.
//

import SwiftUI

struct FormRow<Content: View>: View {
    let title: String
    let required: Bool
    let content: Content
    
    init(title: String, required: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.required = required
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title Section
            HStack(spacing: 4) {
                Text(title)
                    .font(Font.setFontSemiBold(size: 15))
                    .foregroundStyle(Color.theme.text)
                   
                
                if required {
                    Text("*")
                        .font(Font.setFontRegular(size: 20))
                        .foregroundStyle(.red)
                        
                }
            }
            
            // Content Section
            content
        }
    }
}
