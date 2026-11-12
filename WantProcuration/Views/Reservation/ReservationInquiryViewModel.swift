//
//  ReservationInquiryViewModel.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 28/10/2025.
//

import Combine
import Foundation

class ReservationInquiryViewModel : ObservableObject {
    @Published var customerId: String = ""
    @Published var inquireReserves: [InquireReserveItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isValidCustomerId: Bool?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupCustomerIdValidation()
    }
    
    private func setupCustomerIdValidation() {
        $customerId
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] id in
                guard let self = self else { return }
                if id.count == 14 {
                    Task {
                        await self.validateCustomerId(id)
                    }
                } else {
                    self.isValidCustomerId = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func validateCustomerId(_ id: String) async {
        do {
            let isValid = try await APIClient.shared.validateCustomerId(id)
            await MainActor.run {
                self.isValidCustomerId = isValid
                if !isValid {
                    self.errorMessage = "invalidCustomerId".localized()
                } else {
                    self.errorMessage = nil
                }
            }
        } catch {
            await MainActor.run {
                self.isValidCustomerId = false
                self.errorMessage = "validationError".localized()
            }
            Logger.error("Customer ID validation error: \(error)")
        }
    }
    
    func fetchInquireData() async -> Bool {
        // Check if customer ID is valid before fetching
        guard isValidCustomerId == true else {
            await MainActor.run {
                errorMessage = "pleaseEnterValidCustomerId".localized()
            }
            return false
        }
        
        isLoading = true
        errorMessage = nil
        var response: InquireReserveResponse
        
        do {
            response = try await APIClient.shared.getInquireMyReserve(customerId: customerId)
            await MainActor.run {
                inquireReserves = response.inquireReserve
                isLoading = false
            }
            Logger.info("Successfully loaded \(response.inquireReserve.count) data")
            return response.statusCode == "200"
        } catch let error as APIError {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            Logger.error("Failed to fetch inquireReserves: \(error)")
        } catch {
            await MainActor.run {
                isLoading = false
            }
            Logger.error("Unexpected error: \(error)")
        }
        
        return false
    }
}

extension APIClient {
    func getInquireMyReserve(customerId: String) async throws -> InquireReserveResponse {
        let endpoint = "ReservationMobile/getInquireMyReserve/\(customerId)"
        Logger.info("Fetching Inquery data...")
        let response: InquireReserveResponse = try await get(endpoint, requiresAuth: false)
        Logger.info("Fetched \(response.inquireReserve.count) responses (statusCode: \(response.statusCode), message: \(response.statusMessage))")
        return response
    }
}
