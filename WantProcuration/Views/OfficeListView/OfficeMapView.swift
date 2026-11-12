//
//  OfficeMapView.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 27/10/2025.
//
import SwiftUI
import MapKit
import SwiftfulRouting
// MARK: - Office Map View
struct OfficeMapView: View {
    @ObservedObject var appManager: AppManager
    @StateObject  var viewModel: OfficeViewModel
    @Environment(\.router) private var router
    @State private var region : MKCoordinateRegion
    let category: ServiceCategoryName
   
    init(appManager : AppManager , viewModel: OfficeViewModel , category: ServiceCategoryName){
        self.category = category
        self.appManager = appManager
        _viewModel = .init(wrappedValue: viewModel)
        self.region = MKCoordinateRegion(
            center: viewModel.userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 30.0444, longitude: 31.2357),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
    var body: some View {
        Map(initialPosition: .region(region)) {
            ForEach(viewModel.filteredOffices.filter { $0.hasCoordinates }) { office in
                Annotation(office.orgUnitName, coordinate: office.coordinate) {
                    MapPin(office: office)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let selectedOffice = office
                            router.showScreen(.push) { _ in
                                OfficeDetailView(appManager: appManager, office: selectedOffice, category: category)
                                    .id(selectedOffice.id)
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onMapCameraChange { context in
            region = context.region
        }
    }
}
