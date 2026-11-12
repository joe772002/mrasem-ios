//
//  VoiceInput.swift
//  WantProcuration
//
//  Voice input for the assistant (IOS_PORT_GUIDE.md §4.7).
//  iOS has no ready system screen like Android's RecognizerIntent, so this is a small sheet
//  (speak → stop) using SFSpeechRecognizer + AVAudioEngine. Needs microphone + speech permissions.
//

import SwiftUI
import Speech
import AVFoundation
import Combine

final class SpeechInput: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false
    @Published private(set) var unavailable = false

    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// ar-EG, or en-US when the app is in English.
    static var localeIdentifier: String { GatewayConfig.lang == "en" ? "en-US" : "ar-EG" }

    func start() async {
        guard !isRecording else { return }
        transcript = ""
        guard await Self.requestPermissions(),
              let recognizer = SFSpeechRecognizer(locale: Locale(identifier: Self.localeIdentifier)),
              recognizer.isAvailable else {
            unavailable = true
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.request = request

            Self.installTap(on: engine.inputNode, request: request)
            engine.prepare()
            try engine.start()
            isRecording = true

            task = Self.recognize(with: recognizer, request: request) { [weak self] text, finished in
                Task { @MainActor in
                    guard let self else { return }
                    if let text { self.transcript = text }
                    if finished { self.stop() }
                }
            }
        } catch {
            Logger.error("Voice input failed to start: \(error)")
            stop()
            unavailable = true
        }
    }

    func stop() {
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
        task?.finish()
        task = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // These run off the main thread, so they are kept out of the main-actor class body.

    nonisolated private static func installTap(on node: AVAudioInputNode, request: SFSpeechAudioBufferRecognitionRequest) {
        let format = node.outputFormat(forBus: 0)
        node.removeTap(onBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    nonisolated private static func recognize(
        with recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        onUpdate: @escaping @Sendable (String?, Bool) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            onUpdate(result?.bestTranscription.formattedString, error != nil || (result?.isFinal ?? false))
        }
    }

    nonisolated private static func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speech else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }
}

/// Sheet: listens right away, shows the text live; "Stop" returns the text.
struct VoiceInputSheet: View {
    let onResult: (String) -> Void
    @StateObject private var speech = SpeechInput()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            if speech.unavailable {
                Image(systemName: "mic.slash")
                    .font(.system(size: 36))
                    .foregroundColor(.theme.themeGray)
                Text("assistant_voice_unavailable".localized())
                    .font(.setFont(size: 15))
                    .foregroundColor(.theme.text)
                    .multilineTextAlignment(.center)
                Button("assistant_voice_close".localized()) { dismiss() }
                    .font(.setFont(size: 15))
                    .buttonStyle(.bordered)
            } else {
                Text("assistant_voice_input".localized())
                    .font(.setFontSemiBold(size: 17))
                    .foregroundColor(.theme.text)

                Image(systemName: "waveform")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.theme.themeBlue)
                    .symbolEffect(.variableColor.iterative, isActive: speech.isRecording)
                    .frame(width: 84, height: 84)
                    .background(Color.theme.themeBlue.opacity(0.1), in: Circle())

                Text(speech.transcript.isEmpty ? "…" : speech.transcript)
                    .font(.setFont(size: 15))
                    .foregroundColor(.theme.text)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 44)

                HStack(spacing: 12) {
                    Button("assistant_voice_cancel".localized()) {
                        speech.stop()
                        dismiss()
                    }
                    .font(.setFont(size: 15))
                    .buttonStyle(.bordered)

                    Button {
                        speech.stop()
                        let text = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                        if !text.isEmpty { onResult(text) }
                    } label: {
                        Text("assistant_voice_stop".localized())
                            .font(.setFontSemiBold(size: 15))
                            .frame(minWidth: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.theme.themeBlue)
                }
            }
        }
        .padding(24)
        .presentationDetents([.height(320)])
        .task { await speech.start() }
        .onDisappear { speech.stop() }
    }
}
