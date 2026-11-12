//
//  SearchBar.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import SwiftUI

// MARK: -  Search Bar
struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.theme.themeGray)
            
            TextField("ابحث عن خدمة...", text: $searchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .textAlignedToReadingSide()
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.theme.themeGray)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 20, y: 8)
        )
    }
}
