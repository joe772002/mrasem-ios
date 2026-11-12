//
//  MrasemStore.swift
//  Mrasem
//
//  Phase 11 — مصدر الحقيقة الوحيد لكل المستخدمين (08 §2). محلي بالكامل (F1).
//  أي تعديل: يتطبق على نسخة ← يتحفظ في الملف ← يتبعت لكل المشتركين.
//

import Foundation
import Combine

/// نتيجة قراءة الملف عند التشغيل.
enum StoreLoadResult: Equatable {
    /// مفيش ملف: أول تشغيل.
    case fresh
    case loaded
    /// الملف كان تالف: اتحفظ نسخة منه وبدأنا قاعدة فاضية.
    case recoveredFromCorrupt
    /// الملف من إصدار أحدث من التطبيق: اتحفظ نسخة منه وبدأنا قاعدة فاضية.
    case newerSchema
}

nonisolated final class MrasemStore {
    private let storage: MrasemStorage
    private let subject: CurrentValueSubject<MrasemDatabase, Never>
    private let lock = NSLock()

    let loadResult: StoreLoadResult
    /// آخر خطأ حفظ (الحالة في الذاكرة بتفضل صح حتى لو الحفظ فشل).
    private(set) var lastSaveError: String?

    init(storage: MrasemStorage) {
        self.storage = storage

        let (database, result) = Self.load(from: storage)
        self.loadResult = result
        self.subject = CurrentValueSubject(database)

        if result != .loaded {
            persist(database)
        }
    }

    var database: MrasemDatabase { subject.value }

    var publisher: AnyPublisher<MrasemDatabase, Never> { subject.eraseToAnyPublisher() }

    /// التعديل الوحيد المسموح على البيانات. بيضمن وجود أدمن بعد أي تعديل.
    func update(_ change: (inout MrasemDatabase) -> Void) {
        lock.lock()
        var database = subject.value
        change(&database)
        database.normalize()
        let changed = database != subject.value
        if changed {
            persist(database)
        }
        lock.unlock()

        if changed {
            subject.send(database)
        }
    }

    /// «ابدأ فارغ».
    func startEmpty() {
        replace(with: { var db = MrasemDatabase.blank(); db.didChooseStart = true; return db }())
    }

    /// «حمّل بيانات العرض» / «إعادة تحميل بيانات العرض».
    func loadDemo() {
        replace(with: MrasemSeed.demo())
    }

    /// «مسح كل البيانات»: يرجع لأول تشغيل (أدمن بس، وسؤال البداية يظهر تاني).
    func wipeAll() {
        replace(with: .blank())
    }

    private func replace(with database: MrasemDatabase) {
        update { $0 = database }
    }

    // MARK: - الملف

    private static func load(from storage: MrasemStorage) -> (MrasemDatabase, StoreLoadResult) {
        let data: Data?
        do {
            data = try storage.read()
        } catch {
            storage.backupCorrupt()
            return (.blank(), .recoveredFromCorrupt)
        }

        guard let data else { return (.blank(), .fresh) }

        if let version = MrasemDatabaseCodec.schemaVersion(of: data),
           version > MrasemDatabase.currentSchemaVersion {
            storage.backupCorrupt()
            return (.blank(), .newerSchema)
        }

        do {
            var database = try MrasemDatabaseCodec.decode(data)
            database.normalize()
            return (database, .loaded)
        } catch {
            storage.backupCorrupt()
            return (.blank(), .recoveredFromCorrupt)
        }
    }

    private func persist(_ database: MrasemDatabase) {
        do {
            try storage.write(MrasemDatabaseCodec.encode(database))
            lastSaveError = nil
        } catch {
            lastSaveError = String(describing: error)
        }
    }
}
