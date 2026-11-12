//
//  ScanNationalIDButton.swift
//  WantProcuration
//
//  "مسح البطاقة ضوئيًا" card shown under the national ID field (with an "أو" divider). Opens the camera scanner.
//

import SwiftUI

struct ScanNationalIDButton: View {
    /// Receives the confirmed 14-digit number.
    let onScanned: (String) -> Void
    @State private var showScanner = false

    var body: some View {
        VStack(spacing: 12) {
            // "أو" divider between typing the number and scanning the card
            HStack(spacing: 10) {
                Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
                Text("أو")
                    .font(Font.setFont(size: 13))
                    .foregroundColor(.theme.themeGray)
                Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
            }

            Button {
                showScanner = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.theme.themeBlue, in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("مسح البطاقة ضوئيًا")
                            .font(Font.setFontSemiBold(size: 15))
                            .foregroundColor(.theme.themeBlue)
                        Text("لإدخال الرقم القومي تلقائيًا من الوجه الأمامي للبطاقة")
                            .font(Font.setFont(size: 12))
                            .foregroundColor(.theme.themeGray)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.forward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.theme.themeBlue)
                }
                .padding(12)
                .background(Color.theme.themeBlue.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.theme.themeBlue.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
            .buttonStyle(.plain)
        }
        .fullScreenCover(isPresented: $showScanner) {
            NationalIDScanSheet(onUse: onScanned)
        }
    }
}
