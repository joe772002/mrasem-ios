//
//  MrasemStorage.swift
//  Mrasem
//
//  Phase 11 — مكان حفظ ملف قاعدة البيانات. على الجهاز بس (F1).
//

import Foundation

protocol MrasemStorage: AnyObject {
    /// `nil` لو مفيش ملف لسه.
    func read() throws -> Data?
    func write(_ data: Data) throws
    /// يحفظ الملف الحالي باسم تاني (تالف أو من إصدار أحدث) بدل ما يتكتب فوقه.
    func backupCorrupt()
}

/// `Application Support/Mrasem/database.json` بكتابة ذرّية.
nonisolated final class FileMrasemStorage: MrasemStorage {
    let url: URL

    init(url: URL = FileMrasemStorage.defaultURL) {
        self.url = url
    }

    static var defaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Mrasem", isDirectory: true)
            .appendingPathComponent("database.json")
    }

    func read() throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    func write(_ data: Data) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: [.atomic])
    }

    func backupCorrupt() {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = url.deletingLastPathComponent()
            .appendingPathComponent("database.corrupt-\(stamp).json")
        try? FileManager.default.moveItem(at: url, to: backup)
    }
}

/// للاختبارات والـ Previews.
nonisolated final class InMemoryMrasemStorage: MrasemStorage {
    var data: Data?
    private(set) var writeCount = 0
    private(set) var backupCount = 0
    var failWrites = false

    init(data: Data? = nil) {
        self.data = data
    }

    func read() throws -> Data? { data }

    func write(_ data: Data) throws {
        if failWrites {
            throw CocoaError(.fileWriteUnknown)
        }
        self.data = data
        writeCount += 1
    }

    func backupCorrupt() {
        backupCount += 1
        data = nil
    }
}
