//
//  NationalIDScanSheet.swift
//  WantProcuration
//
//  "قراءة الرقم القومي من البطاقة": live camera text recognition (VisionKit DataScanner) that reads the national ID
//  from the front of the card. Runs fully on the phone; no image is saved or sent anywhere.
//  The user always confirms the number before it is used.
//

import SwiftUI
import VisionKit
import AVFoundation

// MARK: - Sheet

struct NationalIDScanSheet: View {
    /// Called with the 14-digit number after the user taps "استخدام الرقم".
    let onUse: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cameraState: CameraState = .checking
    @State private var found: NationalIDInfo?

    enum CameraState { case checking, ready, denied, unsupported }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch cameraState {
            case .checking:
                ProgressView().tint(.white)
            case .ready:
                NationalIDScannerView(isPaused: found != nil) { info in
                    if found == nil { found = info }
                }
                .ignoresSafeArea()
            case .denied:
                messageView(
                    icon: "camera.fill",
                    text: "يحتاج التطبيق إلى إذن الوصول إلى الكاميرا لقراءة البطاقة.",
                    buttonTitle: "فتح الإعدادات"
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            case .unsupported:
                messageView(
                    icon: "exclamationmark.triangle.fill",
                    text: "هذا الجهاز لا يدعم قراءة النصوص بالكاميرا. يُرجى إدخال الرقم القومي يدويًا.",
                    buttonTitle: "رجوع"
                ) { dismiss() }
            }

            VStack {
                topBar
                Spacer()
                if cameraState == .ready { bottomCard }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .task { await checkCamera() }
    }

    // MARK: Parts

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.5), in: Circle())
            }
            Spacer()
        }
        .padding()
    }

    private var bottomCard: some View {
        VStack(spacing: 12) {
            if let found {
                Text("الرقم القومي")
                    .font(.setFont(size: 14))
                    .foregroundColor(.theme.themeGray)
                Text(found.number)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.theme.text)
                    .environment(\.layoutDirection, .leftToRight)
                Text("تاريخ الميلاد: \(found.birthDateText) · المحافظة: \(found.governorate)")
                    .font(.setFont(size: 13))
                    .foregroundColor(.theme.themeGray)
                Text("يُرجى التأكد من مطابقة الرقم للبطاقة")
                    .font(.setFont(size: 12))
                    .foregroundColor(.orange)

                HStack(spacing: 10) {
                    Button {
                        onUse(found.number)
                        dismiss()
                    } label: {
                        Text("استخدام الرقم")
                            .font(.setFontSemiBold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.theme.themeBlue, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Button {
                        self.found = nil
                    } label: {
                        Text("إعادة المسح")
                            .font(.setFont())
                            .foregroundColor(.theme.themeBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.theme.themeBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                Image(systemName: "creditcard.viewfinder")
                    .font(.system(size: 28))
                    .foregroundColor(.theme.themeBlue)
                Text("وجّه الكاميرا نحو الوجه الأمامي للبطاقة")
                    .font(.setFont())
                    .foregroundColor(.theme.text)
                Text("احرص على وضوح الرقم القومي وتجنّب انعكاس الضوء")
                    .font(.setFont(size: 13))
                    .foregroundColor(.theme.themeGray)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private func messageView(icon: String, text: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(.white)
            Text(text)
                .font(.setFont())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Button(buttonTitle, action: action)
                .font(.setFont())
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }

    // MARK: Camera permission

    private func checkCamera() async {
        guard DataScannerViewController.isSupported else {
            cameraState = .unsupported
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraState = .ready
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraState = granted ? .ready : .denied
        default:
            cameraState = .denied
        }
        #if DEBUG
        Logger.info("IDScan: languages supported = \(DataScannerViewController.supportedTextRecognitionLanguages)")
        #endif
    }
}

// MARK: - Scanner (VisionKit)

struct NationalIDScannerView: UIViewControllerRepresentable {
    /// Stops reporting while the user is looking at a found number.
    let isPaused: Bool
    let onFound: (NationalIDInfo) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFound: onFound) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Arabic is needed because the number on the card is printed in Arabic-Indic digits (٠-٩).
        let arabic = DataScannerViewController.supportedTextRecognitionLanguages.filter { $0.hasPrefix("ar") }
        let languages = arabic.isEmpty ? [] : arabic + ["en-US"]
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text(languages: languages)],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        context.coordinator.onFound = onFound
        context.coordinator.isPaused = isPaused
        if !scanner.isScanning {
            do {
                try scanner.startScanning()
            } catch {
                Logger.error("IDScan: could not start scanning: \(error)")
            }
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onFound: (NationalIDInfo) -> Void
        var isPaused = false
        /// A number must be read twice in a row before we show it, to avoid one-frame misreads.
        private var lastCandidate: String?

        init(onFound: @escaping (NationalIDInfo) -> Void) {
            self.onFound = onFound
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            check(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            check(allItems)
        }

        private func check(_ items: [RecognizedItem]) {
            guard !isPaused else { return }
            for item in items {
                guard case .text(let text) = item,
                      let info = NationalIDParser.find(in: text.transcript) else { continue }
                if lastCandidate == info.number {
                    Logger.info("IDScan: found \(info.masked)")
                    lastCandidate = nil
                    onFound(info)
                } else {
                    lastCandidate = info.number
                }
                return
            }
        }
    }
}
