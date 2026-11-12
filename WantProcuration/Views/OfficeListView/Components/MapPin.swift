//
//  MapPin.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//

import SwiftUI

// MARK: - Map Pin
struct MapPin: View {
    let office: OfficeModel
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(office.officeColor)
                    .frame(width: 40, height: 40)
                    .shadow(color: (office.officeColor).opacity(0.4), radius: 6, y: 3)
                
                Image(systemName: office.isSpecial ? "star.fill" : "building.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            Text(office.orgUnitName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white)
                .cornerRadius(6)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
    }
}
