//
//  VisitDataWriter.swift
//  Mrasem
//
//  Phase 13 — يطبّق نموذج «بيانات الزيارة» (نصوص حرة) على سجلات القاعدة بتاعة رئيس الوفد:
//  المرافق، السيارة، السائق، قاعة الملتقى. اللي مش موجود بيتعمل وبيتربط بأعضاء الوفد اللي ملهمش.
//  التعديل بيتم على السجل نفسه؛ تغيير التعيين لشخص تاني بيتعمل من إدارة الموارد (Phase 15).
//

import Foundation

nonisolated enum VisitDataWriter {

    static func apply(_ data: VisitData, delegationId: String, to db: inout MrasemDatabase) {
        guard let delegation = db.delegation(delegationId),
              let anchor = DelegationService.head(of: delegationId, in: db)
        else { return }

        applyEscort(data, anchor: anchor, delegationId: delegationId, to: &db)
        applyCar(data, anchor: anchor, delegation: delegation, to: &db)
        applyVenue(data, delegation: delegation, to: &db)
    }

    // MARK: - المرافق

    private static func applyEscort(_ data: VisitData, anchor: MemberRecord, delegationId: String, to db: inout MrasemDatabase) {
        let name = data.receiverName.storeTrimmed
        let phone = data.receiverPhone.storeTrimmed

        if let escortId = anchor.escortId, let index = db.escorts.firstIndex(where: { $0.id == escortId }) {
            db.escorts[index].name = name
            db.escorts[index].phone = phone
            return
        }
        guard !name.isEmpty else { return }

        let escort = EscortRecord(id: MrasemDatabase.newId("e"), name: name, title: "", phone: phone, meetingSpot: "")
        db.escorts.append(escort)
        for i in db.members.indices where db.members[i].delegationId == delegationId
            && (db.members[i].escortId == nil || db.escort(db.members[i].escortId) == nil) {
            db.members[i].escortId = escort.id
        }
    }

    // MARK: - السيارة والسائق

    private static func applyCar(_ data: VisitData, anchor: MemberRecord, delegation: DelegationRecord, to db: inout MrasemDatabase) {
        let type = data.carType.storeTrimmed
        let plate = data.carPlate.storeTrimmed
        let driverName = data.driver.storeTrimmed

        var index = db.cars.firstIndex { $0.id == anchor.carId }
        if index == nil {
            guard !(type.isEmpty && plate.isEmpty && driverName.isEmpty) else { return }

            let car = CarRecord(
                id: MrasemDatabase.newId("c"), type: type, plate: plate,
                plateStyle: delegation.mode == .inbound ? .qatar : .unitedKingdom, driverId: nil
            )
            db.cars.append(car)
            for i in db.members.indices where db.members[i].delegationId == delegation.id
                && (db.members[i].carId == nil || db.car(db.members[i].carId) == nil) {
                db.members[i].carId = car.id
            }
            index = db.cars.count - 1
        }
        guard let index else { return }

        db.cars[index].type = type
        db.cars[index].plate = plate

        guard !driverName.isEmpty else { return }
        if let driverId = db.cars[index].driverId, let d = db.drivers.firstIndex(where: { $0.id == driverId }) {
            db.drivers[d].name = driverName
        } else {
            let driver = DriverRecord(id: MrasemDatabase.newId("r"), name: driverName, phone: "", status: .available)
            db.drivers.append(driver)
            db.cars[index].driverId = driver.id
        }
    }

    // MARK: - قاعة الملتقى

    private static func applyVenue(_ data: VisitData, delegation: DelegationRecord, to db: inout MrasemDatabase) {
        let hall = data.hall.storeTrimmed
        let floor = data.floor.storeTrimmed

        if let index = db.places.firstIndex(where: { $0.id == delegation.venueId }) {
            db.places[index].hall = hall
            db.places[index].floor = floor
            return
        }
        guard !(hall.isEmpty && floor.isEmpty), let delegationIndex = db.delegations.firstIndex(where: { $0.id == delegation.id })
        else { return }

        let venue = PlaceRecord(
            id: MrasemDatabase.newId("g"), kind: .entity, mode: delegation.mode, name: delegation.name, description: "",
            minutes: 0, durationHours: 0, tag: "", official: "", building: "", area: "", entrance: "",
            floor: floor, hall: hall, parking: "", latitude: nil, longitude: nil, mapLabel: "", breakfast: "", phone: ""
        )
        db.places.append(venue)
        db.delegations[delegationIndex].venueId = venue.id
    }
}
