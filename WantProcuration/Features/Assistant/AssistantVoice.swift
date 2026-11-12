//
//  AssistantVoice.swift
//  WantProcuration
//
//  Reads the assistant's replies aloud with the phone's own voice (IOS_PORT_GUIDE.md §4.14).
//  - Every new reply is read by itself, until the user mutes the assistant from the chat header
//    (kept in UserDefaults). «استمع» on a reply reads it even when muted.
//  - The gateway sends `speech`: the whole message for the ear (documents, numbered options, every plan step
//    with its details, the notes). Without it (older gateway, replies made in the app) the reply is cleaned here.
//  - Long messages are read sentence by sentence (one utterance each). Nothing is sent anywhere.
//

import Foundation
import AVFoundation
import Combine

final class AssistantVoice: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = AssistantVoice()

    private static let mutedKey = "assistant_voice_muted"
    private static let partChars = 450

    /// The user muted the assistant (chat header).
    @Published private(set) var isMuted: Bool = UserDefaults.standard.bool(forKey: AssistantVoice.mutedKey)
    /// The chat entry being read now (nil = silent).
    @Published private(set) var speakingId: UUID?
    /// Set when Arabic was asked for and the phone has no Arabic voice; the screen shows a message once.
    @Published var arabicMissing = false

    private let synthesizer = AVSpeechSynthesizer()
    /// The last utterance of the message being read: when it ends, the reading is over.
    private var lastUtterance: AVSpeechUtterance?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Mute

    func toggleMute() { setMuted(!isMuted) }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        UserDefaults.standard.set(muted, forKey: Self.mutedKey)
        if muted { stop() }
    }

    // MARK: - Speaking

    /// A new reply: read it unless muted.
    func speakNew(_ id: UUID, _ text: String, arabic: Bool) {
        guard !isMuted else { return }
        speak(id, text, arabic: arabic)
    }

    /// «استمع» / «إيقاف» on a reply.
    func toggle(_ id: UUID, _ text: String, arabic: Bool) {
        if speakingId == id { stop() } else { speak(id, text, arabic: arabic) }
    }

    func speak(_ id: UUID, _ text: String, arabic: Bool) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        guard let voice = Self.voice(arabic: arabic) else {
            arabicMissing = true
            return
        }
        stop()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        speakingId = id
        let parts = Self.split(clean, maxChars: Self.partChars)
        for (index, part) in parts.enumerated() {
            let utterance = AVSpeechUtterance(string: part)
            utterance.voice = voice
            // a little slower than the default for Arabic
            utterance.rate = arabic ? AVSpeechUtteranceDefaultSpeechRate * 0.92 : AVSpeechUtteranceDefaultSpeechRate
            if index == parts.count - 1 { lastUtterance = utterance }
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        lastUtterance = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        speakingId = nil
    }

    private func finished(_ utterance: ObjectIdentifier) {
        guard let lastUtterance, ObjectIdentifier(lastUtterance) == utterance else { return }
        self.lastUtterance = nil
        speakingId = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let key = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(key) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let key = ObjectIdentifier(utterance)
        Task { @MainActor in self.finished(key) }
    }

    // MARK: - Helpers

    private static func voice(arabic: Bool) -> AVSpeechSynthesisVoice? {
        if !arabic { return AVSpeechSynthesisVoice(language: "en-US") }
        if let voice = AVSpeechSynthesisVoice(language: "ar-SA") { return voice }
        return AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("ar") }
    }

    /// Sentences joined up to `maxChars` per part (a very long sentence is cut at a comma or a space).
    static func split(_ text: String, maxChars: Int) -> [String] {
        var sentences: [String] = []
        var current = ""
        for char in text {
            current.append(char)
            if ".؟?!؛".contains(char) {
                sentences.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            sentences.append(current.trimmingCharacters(in: .whitespaces))
        }
        var parts: [String] = []
        var buffer = ""
        func flush() {
            if !buffer.isEmpty { parts.append(buffer) }
            buffer = ""
        }
        for sentence in sentences where !sentence.isEmpty {
            var rest = sentence
            while rest.count > maxChars {
                let head = String(rest.prefix(maxChars))
                let cut = head.lastIndex(where: { $0 == "،" || $0 == "," || $0 == " " })
                    .map { head.distance(from: head.startIndex, to: $0) } ?? maxChars
                let index = cut > maxChars / 2 ? cut : maxChars
                flush()
                parts.append(String(rest.prefix(index)).trimmingCharacters(in: .whitespaces))
                rest = String(rest.dropFirst(index)).trimmingCharacters(in: CharacterSet(charactersIn: " ،,"))
            }
            if buffer.count + rest.count + 1 > maxChars { flush() }
            buffer = buffer.isEmpty ? rest : buffer + " " + rest
        }
        flush()
        return parts.isEmpty ? [String(text.prefix(maxChars))] : parts
    }

    /// The written reply made speakable (older gateway without `speech`, replies made in the app):
    /// no brackets, «», codes like 5/7, numbering or bullets.
    static func cleanForSpeech(_ reply: String) -> String {
        var text = reply
        var previous = ""
        while previous != text {     // nested brackets
            previous = text
            text = text.replacingOccurrences(of: #"\s*[(\[][^()\[\]]*[)\]]"#, with: "", options: .regularExpression)
        }
        text = text.replacingOccurrences(of: #"\b\d{1,3}\s*/\s*\d{1,3}\b"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"(?m)^\s*\d+\s*[.)-]\s*"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"[«»“”"*_#`~|•●▪◦→←⇢✔✓]+"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: " — ", with: "، ")
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " ،,:")) }
            .filter { !$0.isEmpty }
            .map { line -> String in
                guard let last = line.last, !".؟?!:".contains(last) else { return line }
                return line + "."
            }
        return lines.joined(separator: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
