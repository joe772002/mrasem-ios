//
//  MrasemStoreTests.swift
//  WantProcurationTests
//
//  Phase 11 — قاعدة البيانات المحلية: الحفظ والقراءة، الملف التالف، الحذف المتسلسل، بيانات العرض.
//

import XCTest
import Combine
@testable import WantProcuration

final class MrasemStoreTests: XCTestCase {

    private func demoStore() -> (MrasemStore, InMemoryMrasemStorage) {
        let storage = InMemoryMrasemStorage()
        let store = MrasemStore(storage: storage)
        store.loadDemo()
        return (store, storage)
    }

    // MARK: - التشغيل والملف

    func testFreshStoreHasOnlyAdminAndAsksHowToStart() {
        let storage = InMemoryMrasemStorage()
        let store = MrasemStore(storage: storage)

        XCTAssertEqual(store.loadResult, .fresh)
        XCTAssertFalse(store.database.didChooseStart)
        XCTAssertTrue(store.database.isEmptyOfContent)
        XCTAssertEqual(store.database.team.map(\.role), [.admin])
        XCTAssertEqual(store.database.currentUser, .team(MrasemSeed.defaultAdmin.id))
        XCTAssertNotNil(storage.data, "أول تشغيل بيكتب الملف")
    }

    func testDatabaseSurvivesRestart() {
        let (store, storage) = demoStore()
        store.update { $0.members[0].room = "999" }

        let reopened = MrasemStore(storage: storage)
        XCTAssertEqual(reopened.loadResult, .loaded)
        XCTAssertEqual(reopened.database, store.database)
        XCTAssertEqual(reopened.database.member("m1")?.room, "999")
    }

    func testCorruptFileIsBackedUpAndStartsBlank() {
        let storage = InMemoryMrasemStorage(data: Data("not json".utf8))
        let store = MrasemStore(storage: storage)

        XCTAssertEqual(store.loadResult, .recoveredFromCorrupt)
        XCTAssertEqual(storage.backupCount, 1)
        XCTAssertTrue(store.database.isEmptyOfContent)
        XCTAssertFalse(store.database.team.isEmpty)
    }

    func testNewerSchemaIsNotOverwrittenSilently() throws {
        var future = MrasemDatabase.blank()
        future.schemaVersion = MrasemDatabase.currentSchemaVersion + 1
        let storage = InMemoryMrasemStorage(data: try MrasemDatabaseCodec.encode(future))

        let store = MrasemStore(storage: storage)
        XCTAssertEqual(store.loadResult, .newerSchema)
        XCTAssertEqual(storage.backupCount, 1)
    }

    func testFileStorageRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("database.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let store = MrasemStore(storage: FileMrasemStorage(url: url))
        store.loadDemo()

        let reopened = MrasemStore(storage: FileMrasemStorage(url: url))
        XCTAssertEqual(reopened.loadResult, .loaded)
        XCTAssertEqual(reopened.database, MrasemSeed.demo())
    }

    func testUpdatePublishesToSubscribers() {
        let (store, _) = demoStore()
        var received: [Int] = []
        let token = store.publisher.sink { received.append($0.members.count) }

        store.update { $0.deleteMember("m3") }
        XCTAssertEqual(received.last, 5)
        token.cancel()
    }

    func testFailedSaveKeepsStateAndReportsError() {
        let (store, storage) = demoStore()
        storage.failWrites = true

        store.update { $0.members[0].room = "1" }
        XCTAssertEqual(store.database.members[0].room, "1")
        XCTAssertNotNil(store.lastSaveError)
    }

    // MARK: - المسح وبيانات العرض

    func testStartEmptyAndWipeAll() {
        let (store, _) = demoStore()

        store.wipeAll()
        XCTAssertTrue(store.database.isEmptyOfContent)
        XCTAssertFalse(store.database.didChooseStart)

        store.startEmpty()
        XCTAssertTrue(store.database.didChooseStart)
        XCTAssertEqual(store.database.team.count, 1)
    }

    func testDemoDataHasNoDanglingReferences() {
        let db = MrasemSeed.demo()

        for d in db.delegations {
            if let id = d.hotelId { XCTAssertNotNil(db.place(id), "hotel \(id)") }
            if let id = d.venueId { XCTAssertNotNil(db.place(id), "venue \(id)") }
            if let id = d.destinationId { XCTAssertNotNil(db.destination(id), "destination \(id)") }
            d.coordinatorIds.forEach { XCTAssertNotNil(db.teamUser($0)) }
        }
        for m in db.members {
            XCTAssertNotNil(db.delegation(m.delegationId))
            if let id = m.escortId { XCTAssertNotNil(db.escort(id)) }
            if let id = m.carId { XCTAssertNotNil(db.car(id)) }
        }
        for c in db.cars { if let id = c.driverId { XCTAssertNotNil(db.driver(id)) } }
        for p in db.program {
            XCTAssertNotNil(db.delegation(p.delegationId))
            if let id = p.placeId { XCTAssertNotNil(db.place(id), "place of \(p.id)") }
            if let id = p.carId { XCTAssertNotNil(db.car(id)) }
        }
        for r in db.requests {
            XCTAssertNotNil(db.delegation(r.delegationId))
            if let id = r.memberId { XCTAssertNotNil(db.member(id)) }
            if let id = r.placeId { XCTAssertNotNil(db.place(id)) }
        }
        XCTAssertEqual(db.delegations.filter { $0.mode == .inbound }.count, 2)
        XCTAssertEqual(db.places.filter { $0.kind == .attraction && $0.mode == .inbound }.count, 8)
        XCTAssertTrue(db.team.contains { $0.role == .admin })
    }

    // MARK: - الحذف المتسلسل (F3)

    func testDeleteDelegationCascades() {
        var db = MrasemSeed.demo()
        db.trips = [TripRecord(id: "p1", status: .arrived, updatedAt: Date())]
        db.checklists = [ChecklistRecord(id: "m1", checked: [0])]
        db.currentUser = .member("m1")

        XCTAssertTrue(db.deleteDelegation("d1"))

        XCTAssertNil(db.delegation("d1"))
        XCTAssertFalse(db.members.contains { $0.delegationId == "d1" })
        XCTAssertFalse(db.program.contains { $0.delegationId == "d1" })
        XCTAssertFalse(db.requests.contains { $0.delegationId == "d1" })
        XCTAssertFalse(db.notices.contains { $0.delegationId == "d1" })
        XCTAssertTrue(db.trips.isEmpty)
        XCTAssertTrue(db.checklists.isEmpty)
        XCTAssertNil(db.currentUser)
        XCTAssertNotNil(db.delegation("d2"), "الوفود التانية ما تتأثرش")
    }

    func testDeleteCarClearsAssignments() {
        var db = MrasemSeed.demo()
        XCTAssertTrue(db.deleteCar("c1"))
        XCTAssertFalse(db.members.contains { $0.carId == "c1" })
        XCTAssertFalse(db.program.contains { $0.carId == "c1" })
    }

    func testDeleteDriverAndPlaceAndEscort() {
        var db = MrasemSeed.demo()

        XCTAssertTrue(db.deleteDriver("r1"))
        XCTAssertNil(db.car("c1")?.driverId)

        XCTAssertTrue(db.deletePlace("h1"))
        XCTAssertNil(db.delegation("d1")?.hotelId)
        XCTAssertTrue(db.deletePlace("g1"))
        XCTAssertNil(db.delegation("d1")?.venueId)
        XCTAssertFalse(db.program.contains { $0.placeId == "g1" })

        XCTAssertTrue(db.deleteEscort("e1"))
        XCTAssertFalse(db.members.contains { $0.escortId == "e1" })

        XCTAssertFalse(db.deleteCar("missing"))
    }

    func testDeleteMemberRemovesItFromNotices() {
        var db = MrasemSeed.demo()
        XCTAssertTrue(db.deleteMember("m1"))
        XCTAssertFalse(db.notices.contains { $0.recipients.contains(.member("m1")) })
        XCTAssertFalse(db.requests.contains { $0.memberId == "m1" })
    }

    func testLastAdminCannotBeDeleted() {
        var db = MrasemSeed.demo()
        XCTAssertFalse(db.deleteTeamUser("u1"), "u1 هو الأدمن الوحيد")
        XCTAssertTrue(db.deleteTeamUser("u2"))
        XCTAssertFalse(db.delegations.contains { $0.coordinatorIds.contains("u2") })
    }

    func testStoreRestoresAdminIfTeamCleared() {
        let (store, _) = demoStore()
        store.update { $0.team.removeAll() }
        XCTAssertTrue(store.database.team.contains { $0.role == .admin })
    }
}
