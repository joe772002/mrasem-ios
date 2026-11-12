//
//  MissionRepository.swift
//  Mrasem
//
//  Mirrors Android: data/repository/MissionRepository.kt + MissionRepositoryImpl.kt
//

import Foundation
import Combine

/// مصدر الحالة الوحيد لعرض الضيف وعرض الفريق (قاعدة A5).
/// عمليات بسيطة فقط — المنطق في Domain (قاعدة A3).
protocol MissionRepository: AnyObject {
    /// البث المباشر للحالة (قاعدة A5: `CurrentValueSubject`).
    var statePublisher: AnyPublisher<MrasemState, Never> { get }
    /// الحالة الحالية.
    var state: MrasemState { get }

    /// يغيّر الوضع، يضبط اليوم المختار، ويمسح المحادثة.
    func setMode(_ mode: MissionMode, dayIndex: Int)
    func setRole(_ role: UserRole)
    func setGuestTab(_ tab: GuestTab)
    func setTeamTab(_ tab: TeamTab)
    func setDay(_ index: Int)
    func setFilter(_ filter: ExploreFilter)

    func setArrival(mode: MissionMode, stage: Int)

    @discardableResult
    func addRequest(mode: MissionMode, kind: RequestKind, place: String?, text: String?) -> GuestRequest
    func setRequestStatus(id: Int64, status: RequestStatus)

    @discardableResult
    func addNotice(mode: MissionMode, content: NoticeContent) -> Notice
    func markChanged(_ keys: Set<ChangeKey>)

    func updateVisitData(mode: MissionMode, data: VisitData)
    func setDress(_ dress: DressCode)
    func setItemTime(mode: MissionMode, dayIndex: Int, itemIndex: Int, time: String)

    func setCheck(mode: MissionMode, index: Int, checked: Bool)
    func appendChat(_ messages: [ChatMessage])
}

/// تنفيذ في الذاكرة فوق `MrasemDemoData` (قرار #3).
/// بيتبدّل بـ API لاحقاً من غير ما الطبقات اللي فوقه تتغير.
nonisolated final class InMemoryMissionRepository: MissionRepository {
    private let subject: CurrentValueSubject<MrasemState, Never>
    private var nextId: Int64 = 0

    init(missions: [MissionMode: Mission] = MrasemDemoData.missions) {
        subject = CurrentValueSubject(MrasemState(missions: missions))
    }

    var statePublisher: AnyPublisher<MrasemState, Never> {
        subject.eraseToAnyPublisher()
    }

    var state: MrasemState {
        subject.value
    }

    // MARK: - التنقل

    func setMode(_ mode: MissionMode, dayIndex: Int) {
        update { state in
            state.mode = mode
            state.dayIndex = dayIndex
            state.chat = []
        }
    }

    func setRole(_ role: UserRole) {
        update { $0.role = role }
    }

    func setGuestTab(_ tab: GuestTab) {
        update { $0.guestTab = tab }
    }

    func setTeamTab(_ tab: TeamTab) {
        update { $0.teamTab = tab }
    }

    func setDay(_ index: Int) {
        update { $0.dayIndex = index }
    }

    func setFilter(_ filter: ExploreFilter) {
        update { $0.filter = filter }
    }

    // MARK: - الوصول والطلبات والتنبيهات

    func setArrival(mode: MissionMode, stage: Int) {
        update { $0.arrived[mode] = stage }
    }

    @discardableResult
    func addRequest(mode: MissionMode, kind: RequestKind, place: String?, text: String?) -> GuestRequest {
        let request = GuestRequest(
            id: incrementId(),
            mode: mode,
            kind: kind,
            place: place,
            text: text,
            status: .new
        )
        update { $0.requests.append(request) }
        return request
    }

    func setRequestStatus(id: Int64, status: RequestStatus) {
        update { state in
            state.requests = state.requests.map { $0.id == id ? $0.withStatus(status) : $0 }
        }
    }

    @discardableResult
    func addNotice(mode: MissionMode, content: NoticeContent) -> Notice {
        let notice = Notice(id: incrementId(), mode: mode, content: content)
        update { $0.notices.append(notice) }
        return notice
    }

    func markChanged(_ keys: Set<ChangeKey>) {
        update { $0.changed.formUnion(keys) }
    }

    // MARK: - بيانات الزيارة

    func updateVisitData(mode: MissionMode, data: VisitData) {
        updateMission(mode) { mission in
            mission.with(
                receiver: mission.receiver.with(name: data.receiverName, phone: data.receiverPhone),
                car: mission.car.with(type: data.carType, plate: data.carPlate, driver: data.driver),
                venue: mission.venue.with(hall: data.hall, floor: data.floor)
            )
        }
    }

    func setDress(_ dress: DressCode) {
        update { $0.dress = dress }
    }

    func setItemTime(mode: MissionMode, dayIndex: Int, itemIndex: Int, time: String) {
        updateMission(mode) { mission in
            let days = mission.days.enumerated().map { index, day -> ProgramDay in
                guard index == dayIndex else { return day }
                let items = day.items.enumerated().map { position, item -> ProgramItem in
                    guard position == itemIndex else { return item }
                    return item.official.map { .official($0.with(time: time)) } ?? item
                }
                return day.with(items: items)
            }
            return mission.with(days: days)
        }
    }

    // MARK: - الفحص والمحادثة

    func setCheck(mode: MissionMode, index: Int, checked: Bool) {
        update { state in
            let current = state.checks(for: mode)
            state.checks[mode] = checked ? current.union([index]) : current.subtracting([index])
        }
    }

    func appendChat(_ messages: [ChatMessage]) {
        update { $0.chat.append(contentsOf: messages) }
    }

    // MARK: - Helpers

    private func incrementId() -> Int64 {
        nextId += 1
        return nextId
    }

    private func update(_ transform: (inout MrasemState) -> Void) {
        var state = subject.value
        transform(&state)
        subject.send(state)
    }

    private func updateMission(_ mode: MissionMode, transform: (Mission) -> Mission) {
        update { state in
            state.missions[mode] = transform(state.missions[mode] ?? MissionStateBuilder.emptyMission(mode))
        }
    }
}

// MARK: - نسخ القيم (قاعدة C5: الـ Models بـ let والتعديل بنسخة جديدة)

extension GuestRequest {
    func withStatus(_ status: RequestStatus) -> GuestRequest {
        GuestRequest(
            id: id,
            mode: mode,
            kind: kind,
            place: place,
            text: text,
            status: status
        )
    }
}

extension Receiver {
    func with(name: String, phone: String) -> Receiver {
        Receiver(name: name, title: title, phone: phone, spot: spot)
    }
}

extension Car {
    func with(type: String, plate: String, driver: String) -> Car {
        Car(type: type, plate: plate, driver: driver, country: country, plateStyle: plateStyle)
    }
}

extension Venue {
    func with(hall: String, floor: String) -> Venue {
        Venue(
            building: building,
            area: area,
            entrance: entrance,
            floor: floor,
            hall: hall,
            parking: parking,
            lat: lat,
            lng: lng,
            mapLabel: mapLabel
        )
    }
}

extension ProgramItem.Official {
    func with(time: String) -> ProgramItem.Official {
        ProgramItem.Official(
            time: time,
            title: title,
            place: place,
            note: note,
            isKey: isKey
        )
    }
}

extension ProgramDay {
    func with(items: [ProgramItem]) -> ProgramDay {
        ProgramDay(label: label, items: items)
    }
}

extension Mission {
    func with(
        receiver: Receiver? = nil,
        car: Car? = nil,
        venue: Venue? = nil,
        days: [ProgramDay]? = nil
    ) -> Mission {
        Mission(
            mode: mode,
            guest: guest,
            country: country,
            dest: dest,
            host: host,
            start: start,
            end: end,
            timeZone: timeZone,
            currency: currency,
            weather: weather,
            receiver: receiver ?? self.receiver,
            car: car ?? self.car,
            coordinator: coordinator,
            venue: venue ?? self.venue,
            hotel: hotel,
            emergency: emergency,
            days: days ?? self.days,
            services: services,
            quickInfo: quickInfo,
            places: places,
            customs: customs,
            nextMeeting: nextMeeting
        )
    }
}
