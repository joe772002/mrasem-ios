import Foundation
import Combine
internal import CoreLocation

class OfficeViewModel: ObservableObject {
    @Published var offices: [OfficeModel] = []
    @Published var governments: [lookupData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filteredOffices: [OfficeModel] = []
    @Published var selectedGovernment: lookupData?
    @Published var userLocation: CLLocation?
    
    // FIXED: Store current filter state
    private var currentFilterType: FilterType = .nearest
    private var currentSearchText: String = ""
    
    private let locationManager = CLLocationManager()
    
    var governmentStrings: [String] {
        governments.map { $0.desc }
    }
    
    func applyFilters(filterType: FilterType = .nearest, searchText: String = "") {
        // FIXED: Update stored filter state
        currentFilterType = filterType
        currentSearchText = searchText
        
        var result = offices
        
        // Filter by government
        if filterType == .all, let selectedGov = selectedGovernment {
            result = result.filter { $0.govDesc.contains(selectedGov.desc) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.orgUnitName.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText) ||
                $0.govDesc.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply filter type
        switch filterType {
        case .all:
            // Show all results (already filtered by government and search)
            break
            
        case .nearest:
            // Calculate distances and sort by nearest
            if let userLoc = userLocation {
                result = result.filter { $0.hasCoordinates }
                result = calculateDistances(for: result, userLocation: userLoc)
                result = result.sorted { $0.distance < $1.distance }
                
                // Get nearest 10 offices
                result = Array(result.prefix(10))
            }
            
        case .special:
            // Filter special/premium offices only
            result = result.filter { $0.isSpecial }
        }
        
        filteredOffices = result
    }
    
    func calculateDistances(for offices: [OfficeModel], userLocation: CLLocation) -> [OfficeModel] {
        return offices.map { office in
            var updatedOffice = office
            let officeLocation = CLLocation(
                latitude: office.coordinate.latitude,
                longitude: office.coordinate.longitude
            )
            // Distance in meters, convert to kilometers
            let distanceInMeters = userLocation.distance(from: officeLocation)
            updatedOffice.distance = distanceInMeters / 1000.0 // Convert to km as Double
            return updatedOffice
        }
    }
    
    func updateUserLocation(_ location: CLLocation) {
        userLocation = location
        
        // Recalculate distances for all offices
        offices = calculateDistances(for: offices, userLocation: location)
        
        // FIXED: Reapply filters using current filter state
        applyFilters(filterType: currentFilterType, searchText: currentSearchText)
    }
    
    func selectGovernment(_ government: lookupData?) {
        selectedGovernment = government
        // FIXED: Use current filter state
        applyFilters(filterType: currentFilterType, searchText: currentSearchText)
    }
    
    func fetchOffices() async {
//        isLoading = true
        errorMessage = nil
        
        do {
            offices = try await APIClient.shared.getOffices()
            
            // Calculate distances if user location is available
            if let userLoc = userLocation {
                offices = calculateDistances(for: offices, userLocation: userLoc)
            }
            // FIXED: Use current filter state
            applyFilters(filterType: currentFilterType, searchText: currentSearchText)
            Logger.info("Successfully loaded \(offices.count) offices")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            Logger.error("Failed to fetch offices: \(error)")
        } catch {
            Logger.error("Unexpected error: \(error)")
        }
        
//        isLoading = false
    }
    
    func fetchGovs() async {
//        isLoading = true
        errorMessage = nil
        
        do {
            governments = try await APIClient.shared.getGovs()
            Logger.info("Successfully loaded \(governments.count) Govs")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            Logger.error("Failed to fetch offices: \(error)")
        } catch {
            Logger.error("Unexpected error: \(error)")
        }
        
//        isLoading = false
    }
    
    func fetchData() async {
        isLoading = true
        defer {
            isLoading = false
        }
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchGovs()
            }
            
            group.addTask {
                await self.fetchOffices()
            }
        }
        
       
    }
}

extension APIClient {
    func getOffices() async throws -> [OfficeModel] {
        let endpoint = "ReservationMobile/getOrgUnitStatus"
        Logger.info("Fetching offices...")
        let response: OfficeResponse = try await get(endpoint, requiresAuth: false)
        Logger.info("Fetched \(response.orgUnitStatusRes.orgUnitStatusData.count) offices")
        return response.orgUnitStatusRes.orgUnitStatusData
    }
    
    func getGovs() async throws -> [lookupData] {
        let endpoint = "EGovNotarization/getLookups/govTypes/0/1/2/3/4/5"
        Logger.info("Fetching offices...")
        let response: GovernmentModel = try await get(endpoint, requiresAuth: false)
        Logger.info("Fetched \(response.lookupData.count) Governments")
        return response.lookupData
    }
}
