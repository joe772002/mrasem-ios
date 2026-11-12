//
//  MissionCards.swift
//  Mrasem
//
//  Mirrors Android: ui/screens/mission/MissionScreen.kt (ReceiverCard … EmergencyCard)
//

import SwiftUI

/// كارت مع محتوى اختياري (مثلاً pill «محدَّث») بجانب العنوان.
struct MissionCard<Content: View>: View {
    let title: String
    let headerEnd: AnyView?
    let content: () -> Content

    init(title: String, headerEnd: AnyView? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.headerEnd = headerEnd
        self.content = content
    }

    var body: some View {
        if let headerEnd {
            MrasemCard(title: title, headerEnd: headerEnd, content: content)
        } else {
            MrasemCard(title: title, content: content)
        }
    }
}

/// pill «محدَّث» بجانب عنوان الكارت لو القسم اتعدّل من فريق المراسم.
func missionUpdatedSlot(_ visible: Bool) -> AnyView? {
    visible ? AnyView(MrasemPill(mrasemString("mrasem_pill_updated"), kind: .warn)) : nil
}

struct ReceiverCard: View {
    @Environment(\.mrasem) private var theme

    let mission: Mission
    let updated: Bool
    let onCall: (String) -> Void
    let onWhatsApp: (String) -> Void

    var body: some View {
        let r = mission.receiver

        MissionCard(title: mrasemString("mrasem_receiver_title"), headerEnd: missionUpdatedSlot(updated)) {
            HStack(alignment: .center, spacing: 12) {
                MrasemAvatarInitial(r.name)
                VStack(alignment: .leading, spacing: 0) {
                    Text(r.name).mrasemText(theme.type.strong).foregroundColor(theme.colors.ink)
                    Text(r.title).mrasemText(theme.type.label).foregroundColor(theme.colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            MrasemKeyValueList([
                KeyValue(mrasemString("mrasem_receiver_kv_phone"), r.phone, ltr: true),
                KeyValue(mrasemString("mrasem_receiver_kv_spot"), r.spot),
            ])
            HStack(spacing: 8) {
                MrasemButton(mrasemString("mrasem_action_call")) { onCall(r.phone) }
                MrasemButton(mrasemString("mrasem_action_whatsapp")) { onWhatsApp(r.phone) }
            }
        }
    }
}

struct CarCard: View {
    @Environment(\.mrasem) private var theme

    let mission: Mission
    let updated: Bool

    var body: some View {
        let car = mission.car

        MissionCard(title: mrasemString("mrasem_car_title"), headerEnd: missionUpdatedSlot(updated)) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(car.type).mrasemText(theme.type.strong).foregroundColor(theme.colors.ink)
                    Text(mrasemString("mrasem_car_driver", [car.driver]))
                        .mrasemText(theme.type.label)
                        .foregroundColor(theme.colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                MrasemPlateBadge(plate: car.plate, country: car.country, style: car.plateStyle)
            }
        }
    }
}

struct VenueCard: View {
    @Environment(\.mrasem) private var theme

    let mission: Mission
    let updated: Bool
    let onOpenMaps: (Double, Double) -> Void

    var body: some View {
        let v = mission.venue

        MissionCard(title: mrasemString("mrasem_venue_title"), headerEnd: missionUpdatedSlot(updated)) {
            Text(v.building).mrasemText(theme.type.cardTitle).foregroundColor(theme.colors.ink)
            MrasemMapPreview(venueLabel: v.mapLabel, hotelLabel: mrasemString("mrasem_map_hotel"))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(mrasemString("mrasem_map_description", [v.building]))
            MrasemKeyValueList([
                KeyValue(mrasemString("mrasem_venue_kv_area"), v.area),
                KeyValue(mrasemString("mrasem_venue_kv_entrance"), v.entrance),
                KeyValue(mrasemString("mrasem_venue_kv_floor"), v.floor),
                KeyValue(mrasemString("mrasem_venue_kv_hall"), v.hall),
                KeyValue(mrasemString("mrasem_venue_kv_parking"), v.parking),
            ])
            MrasemButton(mrasemString("mrasem_venue_open_maps")) { onOpenMaps(v.lat, v.lng) }
        }
    }
}

struct StayCard: View {
    let mission: Mission

    var body: some View {
        let h = mission.hotel

        MrasemCard(title: mrasemString("mrasem_stay_title")) {
            MrasemKeyValueList([
                KeyValue(mrasemString("mrasem_stay_kv_hotel"), mrasemString("mrasem_stay_hotel_value", [h.name, h.area])),
                KeyValue(mrasemString("mrasem_stay_kv_room"), h.room.toArabicDigits()),
                KeyValue(mrasemString("mrasem_stay_kv_breakfast"), h.breakfast),
                KeyValue(mrasemString("mrasem_stay_kv_distance"), h.drive),
            ])
        }
    }
}

struct PassCard: View {
    @Environment(\.mrasem) private var theme

    let mission: Mission

    var body: some View {
        MrasemCard(title: mrasemString("mrasem_pass_title")) {
            HStack(alignment: .center, spacing: 12) {
                MrasemQrPlaceholder()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(mrasemString("mrasem_pass_qr_description"))
                VStack(alignment: .leading, spacing: 0) {
                    Text(mission.guest).mrasemText(theme.type.strong).foregroundColor(theme.colors.ink)
                    Text(mrasemString("mrasem_pass_hint", [mission.venue.building]))
                        .mrasemText(theme.type.label)
                        .foregroundColor(theme.colors.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct EmergencyCard: View {
    @Environment(\.mrasem) private var theme

    let mission: Mission

    var body: some View {
        MrasemCard(title: mrasemString("mrasem_emergency_title")) {
            MrasemKeyValueList(mission.emergency.map { KeyValue($0.label, $0.value, ltr: true) })
            Text(mrasemString("mrasem_emergency_coordinator", [mission.coordinator.name]))
                .mrasemText(theme.type.label)
                .foregroundColor(theme.colors.muted)
        }
    }
}
