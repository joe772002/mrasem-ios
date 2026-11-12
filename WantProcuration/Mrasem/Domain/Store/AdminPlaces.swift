//
//  AdminPlaces.swift
//  Mrasem
//
//  Phase 15 — تاب «الأماكن» (دليل الفنادق والمطاعم والمزارات والجهات): فلتر حسب النوع وصفوف القائمة.
//

import Foundation

enum PlaceFilter: String, CaseIterable, Hashable {
    case all
    case hotel
    case restaurant
    case attraction
    case entity

    var kind: PlaceKind? { PlaceKind(rawValue: rawValue) }

    var titleKey: String { kind?.adminLabelKey ?? "mrasem_admin_place_all" }
}

struct AdminPlaceRow: Equatable, Identifiable {
    let id: String
    let name: String
    let kind: PlaceKind
    let mode: MissionMode
    let description: String
    /// عدد الفقرات والوفود اللي بتستخدم المكان (للتحذير قبل الحذف).
    let usage: Int
}

struct AdminPlacesState: Equatable {
    let filter: PlaceFilter
    let rows: [AdminPlaceRow]
    let counts: [PlaceFilter: Int]

    static func make(_ db: MrasemDatabase, filter: PlaceFilter) -> AdminPlacesState {
        AdminPlacesState(
            filter: filter,
            rows: AdminPlacesBuilder.rows(db, filter: filter),
            counts: AdminPlacesBuilder.counts(db)
        )
    }
}

nonisolated enum AdminPlacesBuilder {

    static func rows(_ db: MrasemDatabase, filter: PlaceFilter) -> [AdminPlaceRow] {
        db.places
            .filter { filter.kind == nil || $0.kind == filter.kind }
            .map { place in
                AdminPlaceRow(
                    id: place.id, name: place.name, kind: place.kind, mode: place.mode,
                    description: place.description, usage: usage(of: place.id, in: db)
                )
            }
    }

    static func counts(_ db: MrasemDatabase) -> [PlaceFilter: Int] {
        Dictionary(uniqueKeysWithValues: PlaceFilter.allCases.map { filter in
            (filter, db.places.count { filter.kind == nil || $0.kind == filter.kind })
        })
    }

    static func usage(of placeId: String, in db: MrasemDatabase) -> Int {
        db.program.count { $0.placeId == placeId }
            + db.delegations.count { $0.hotelId == placeId || $0.venueId == placeId }
            + db.requests.count { $0.placeId == placeId }
    }
}
