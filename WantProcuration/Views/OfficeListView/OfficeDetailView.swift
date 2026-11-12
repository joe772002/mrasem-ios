import SwiftUI
import MapKit
import SwiftfulRouting
import SwiftfulUI


// MARK: - Office Detail View
struct OfficeDetailView: View {
    @ObservedObject var appManager: AppManager
    @Environment(\.router) private var router
    let office: OfficeModel
    let category: ServiceCategoryName
    @State private var mapRegion: MKCoordinateRegion
    
    init(appManager: AppManager, office: OfficeModel , category: ServiceCategoryName) {
            self.category = category
            self.appManager = appManager
            self.office = office
            // Offset the center to position pin in visible area above card
            let offsetCoordinate = CLLocationCoordinate2D(
                latitude: office.coordinate.latitude + -0.003, // Shift north
                longitude: office.coordinate.longitude
            )
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: offsetCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    
    var body: some View {
        ZStack {
            // Map fills entire background
            Map(initialPosition: .region(mapRegion)) {
                Annotation(office.orgUnitName, coordinate: office.coordinate) {
                    LocationPin(color: office.officeColor, isSpecial: office.isSpecial)
                }
            }
            .ignoresSafeArea()
            .id(office.id)
            .onMapCameraChange { context in
                mapRegion = context.region
            }
            
            // Content at bottom
            VStack {
                Spacer()
                
                contentCard
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Back button at top
            VStack {
                // Same place and arrow as the system back button on the other screens (top-left, "<").
                HStack {
                    backButton
                    Spacer()
                }
                .environment(\.layoutDirection, .leftToRight)
                .padding(.horizontal, 20)
//                .padding(.top, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
        .onChange(of: office.id) { oldValue, newValue in
            mapRegion = MKCoordinateRegion(
                center: office.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private var backButton: some View {
        Button(action: { router.dismissScreen() }) {
            Circle()
                .fill(Color.theme.background)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.theme.text)
                )
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        }
    }
    
    // MARK: - Content Card
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection
            Divider()
            infoSection
            
            if category == .reserve {
                bookingButton
            }
        }
        .padding(24)
        .padding(.bottom, 20)
        .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(appManager.isDarkMode ? Color.theme.background : Color.theme.white1)
            .shadow(color: .black.opacity(0.08), radius: 20, y: -5)
            .ignoresSafeArea(edges: .bottom)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // The distance box spans exactly the name + tags block: top with the name, bottom with the tags.
            HStack(alignment: .center, spacing: 12) {
                officeInfo
                Spacer(minLength: 0)
                distanceBadge
                    .frame(maxHeight: .infinity)
                    // Cairo leaves empty space above the name's letters: start the box at the letters, not the line.
                    .padding(.top, 7)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var officeInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(office.orgUnitName)
                .font(.setFontBold(size: 19))
                .foregroundStyle(Color.theme.text)
            
            tagsRow
        }
    }
    
    private var tagsRow: some View {
        HStack(spacing: 8) {
            governmentTag
            officeTypeTag
        }
    }
    
    private var governmentTag: some View {
        HStack(spacing: 6) {
            Image(systemName: "building.columns.fill")
                .font(.setFontRegular(size: 13))
                .foregroundColor(.theme.themeBlue)
            Text(office.govDesc)
                .font(.setFontRegular(size: 13))
                .foregroundStyle(Color.theme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.theme.themeBlue.opacity(0.1))
        )
    }
    
    private var officeTypeTag: some View {
        HStack(spacing: 6) {
            Image(systemName: "building.2.fill")
                .font(.setFontRegular(size: 13))
                .foregroundColor(office.isSpecial ? Color.theme.gold : Color.theme.darkBlue)
            Text(office.orgTypeDesc)
                .font(.setFontRegular(size: 13))
                .foregroundColor(office.isSpecial ? Color.theme.gold : Color.theme.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(office.isSpecial ? Color.theme.gold.opacity(0.1) : Color.theme.darkBlue.opacity(0.1))
        )
    }
    
    /// "2.4", "38", "1,250": one decimal only for short distances.
    private var distanceText: String {
        let km = office.distance
        if km < 10 { return String(format: "%.1f", km) }
        return Int(km.rounded()).formatted()
    }

    private var distanceBadge: some View {
        // «على بُعد» + «2.4 كم» (same number format as the office list).
        VStack(spacing: 0) {
            Text("distance_away".localized())
                .font(.setFontRegular(size: 10))
                .foregroundColor(.theme.secondaryText2)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(distanceText)
                    .font(.setFontBold(size: 16))
                    .foregroundColor(.theme.themeBlue)
                Text("km_unit".localized())
                    .font(.setFontRegular(size: 11))
                    .foregroundColor(.theme.themeBlue)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.theme.themeBlue.opacity(0.1))
        )
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 16) {
            InfoRow(
                icon: "mappin.circle.fill",
                title: "Address".localized(),
                value: office.address,
                color: .theme.themeBlue
            )
            
            InfoRow(
                icon: "clock.fill",
                title: "workinHours".localized(),
                value: workingHoursText,
                color: .theme.themeBlue
            )
            
            InfoRow(
                icon: "map.fill",
                title: "directions".localized(),
                value: "directions_hint".localized(),
                color: .theme.themeBlue,
                isLink: true
            )
            .asButton {
                openInMaps()
            }
        }
    }
    
    private var workingHoursText: String {
        "from".localized() + " \(TimeDisplay.twelveHour(office.fromTime)) " + "to".localized() + " \(TimeDisplay.twelveHour(office.toTime))"
    }
    
    // MARK: - Booking Button
    private var bookingButton: some View {
        Button(action: openReservationForm) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                Text("bookAppointment".localized())
                    .font(.setFontSemiBold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.theme.themeBlue)
            .cornerRadius(16)
            .shadow(color: .theme.themeBlue.opacity(0.3), radius: 3, y: 3)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Actions
    
    private func openReservationForm() {
        router.showScreen(.push) { _ in
            ReservationFormView(appManager: appManager, office: office)
        }
    }
    
    private func openInMaps() {
        let coordinate = office.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = office.orgUnitName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

#Preview {
    let appManager = AppManager()
    OfficeDetailView(appManager: appManager, office: OfficeModel.preview, category: .reserve)
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
}
