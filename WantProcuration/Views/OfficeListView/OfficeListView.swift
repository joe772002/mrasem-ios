import SwiftUI
import SwiftfulRouting
internal import CoreLocation

// MARK: - Office List View
struct OfficeListView: View {
    @State private var selectedFilter: FilterType = .nearest
    @State private var searchText = ""
    @State private var showMap = false
    @State private var showGovernmentPicker = false
    @Environment(\.router) private var router
    @ObservedObject var appManager: AppManager
    @StateObject private var viewModel: OfficeViewModel = OfficeViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showOrgTypeAlert = false
    @State private var selectedOffice: OfficeModel?
    let category: ServiceCategoryName
    var body: some View {
        ZStack {
            //            Color(Color.theme.background)
            //                .edgesIgnoringSafeArea(.all)
            
           HomeBackground()
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Location permission banner
                if let errorMsg = locationManager.errorMessage {
                    locationErrorBanner(message: errorMsg)
                }
                
                headerSection
                contentSection
            }
        }
        .task {
            if viewModel.offices.isEmpty {
                await viewModel.fetchData()
            }
           
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                viewModel.updateUserLocation(location)
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            viewModel.applyFilters(filterType: selectedFilter, searchText: searchText)
        }
        .onChange(of: searchText) { _, _ in
            viewModel.applyFilters(filterType: selectedFilter, searchText: searchText)
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .overlay {
            if showOrgTypeAlert {
                CustomAlertView(
                    type: .information, // or .warning depending on your needs
                    title: "notice".localized(),
                    message: "specialMessage".localized(),
                    primaryButton: CustomAlertButton(
                        title: "continue".localized(),
                        action: {
                            openOfficeDetails()
                        },
                        style: .primary
                    ),
                    secondaryButton: CustomAlertButton(
                        title: "cancel".localized(),
                        action: {
                            // Alert will auto-dismiss
                        },
                        style: .secondary
                    ),
                    isPresented: $showOrgTypeAlert
                )
            }
        }
        .environment(\.locale, appManager.locale)
        .environment(\.layoutDirection, appManager.layoutDirection)
    }
    
    // MARK: - Sections
    private var headerSection: some View {
        
        
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("findOffice".localized())
                        .font(.setFontBold(size: 26))
                        .foregroundColor(.theme.text)
                    Text("officesCount".localized() + " \(viewModel.filteredOffices.count)")
                        .font(.setFontRegular(size: 14))
                        .foregroundColor(.theme.themeGray)
                }

                Spacer()

                // Map / list switch, on the title row (opposite side of the title).
                Button(action: { showMap.toggle() }) {
                    // Icon only, no circle behind it.
                    Image(systemName: showMap ? "list.bullet" : "map")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.theme.themeBlue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(showMap ? "عرض القائمة" : "عرض الخريطة")
            }
            // Government Dropdown
            if selectedFilter == .all {
                Button(action: { showGovernmentPicker.toggle() }) {
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.theme.themeBlue)
                        
                        Text(viewModel.selectedGovernment?.desc ?? "All Governorates".localized())
                            .font(.setFontRegular(size: 15))
                            .foregroundColor(.theme.secondaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.theme.themeGray)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
                    }
                }
                .sheet(isPresented: $showGovernmentPicker) {
                    GovernmentPickerSheet(
                        isPresented: $showGovernmentPicker,
                        viewModel: viewModel,
                        appManager: appManager)
                    
                    
                    
                }
            }
            // Search Bar
            searchBar
            
            // Filter Pills
            //            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.title,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                    .frame(maxWidth: .infinity) // This makes each pill take equal space
                }
            }
            .frame(maxWidth: .infinity) // This makes the HStack fill the screen width
            
            //            }
        }
        
        // Small top padding: the title sits right under the Back / Map buttons row.
        .padding(.horizontal)
        // Negative: pulls the title and map icon up, right under the Back button (Cairo's tall line height
        // left a visible gap).
        .padding(.top, -12)
        .padding(.bottom, 12)
        // .background(Color.theme.background)
        .animation(.easeInOut(duration: 0.2), value: showGovernmentPicker)
        
    }
    
    private var contentSection: some View {
        Group {
            if showMap {
                OfficeMapView(appManager: appManager,viewModel: viewModel,category: category)
            } else {
                officesList
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.theme.themeGray)
            
            TextField("searchOffices".localized(), text: $searchText)
                .font(.setFontRegular(size: 15))
                .textAlignedToReadingSide(isRTL: appManager.isRTL)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.theme.themeGray)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.theme.white1, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 1)
        }
    }
    
    
    
    private var officesList: some View {
        ScrollView {
            if viewModel.isLoading {
                // Show loading indicator while fetching data
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.theme.themeBlue)
                    
                    Text("loadingOffices".localized())
                        .font(.setFontRegular(size: 15))
                        .foregroundColor(.theme.themeGray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if viewModel.filteredOffices.isEmpty {
                // Show empty state only after loading is complete
                VStack(spacing: 16) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.theme.themeGray.opacity(0.5))
                    
                    Text("noOfficesFound".localized())
                        .font(.setFontRegular(size: 15))
                        .foregroundColor(.theme.themeGray)
                    
                    if selectedFilter == .nearest && locationManager.location == nil {
                        Text("enableLocationToSeeNearestOffices".localized())
                            .font(.setFontRegular(size: 14))
                            .foregroundColor(.theme.themeGray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else {
                // Show offices list
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredOffices) { office in
                        OfficeCard(office: office, appManager: appManager)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedOffice = office
                                navigateToDetail()
                            }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Views
    private func locationErrorBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.setFontRegular(size: 14))
                .foregroundColor(.black)
            
            Spacer()
            
            if locationManager.authorizationStatus == .denied {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.setFontSemiBold(size: 14))
                .foregroundColor(.theme.themeBlue)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func navigateToDetail() {
        guard let office = selectedOffice else { return}
        if office.orgType == 1 && category == .reserve {
                showOrgTypeAlert = true
            } else {
                openOfficeDetails()
            }
        }
    
    private func openOfficeDetails(){
        guard let office = selectedOffice else { return}
        router.showScreen(.push) { _ in
            OfficeDetailView(appManager: appManager, office: office, category: category)
                .id(office.id)
        }
    }
}

// MARK: - Filter Type
enum FilterType: CaseIterable {
    case nearest ,all, special
    
    var title: String {
        switch self {
        case .nearest: return "Nearest".localized()
        case .all: return "All".localized()
        case .special: return "premuim".localized()
        }
    }
    
    var icon: String {
        switch self {
        case .nearest: return "location.fill"
        case .all: return "building.2.fill"
        case .special: return "star.fill"
        }
    }
}


// MARK: - Preview
struct OfficeListView_Previews: PreviewProvider {
    static var previews: some View {
        let appManager = AppManager()
        OfficeListView(appManager: appManager, category: .reserve)
            .environment(\.locale, appManager.locale)
            .environment(\.layoutDirection, appManager.layoutDirection)
        
    }
}
