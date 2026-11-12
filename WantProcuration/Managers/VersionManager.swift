//
//  VersionManager.swift
//  WantProcuration
//
//  Created by Ebtehal Elsaid on 02/11/2025.
//

import Combine
import UIKit

class VersionManager: ObservableObject {
    @Published var showUpdateAlert = false
    @Published var isCheckingVersion = true
    @Published var versionCheckCompleted = false
    
    private let appID: String
    
    init(appID: String) {
        self.appID = appID
    }
    
    func checkVersion() {
        guard let currentVersion = getCurrentVersion() else {
            isCheckingVersion = false
            versionCheckCompleted = true
            return
        }
        
        fetchAppStoreVersion { [weak self] appStoreVersion in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isCheckingVersion = false
                
                if let storeVersion = appStoreVersion {
                    if self.isUpdateRequired(current: currentVersion, store: storeVersion) {
                        self.showUpdateAlert = true
                    } else {
                        self.versionCheckCompleted = true
                    }
                } else {
                    // If version check fails, allow app to continue
                    self.versionCheckCompleted = true
                }
            }
        }
    }
    
    private func getCurrentVersion() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    private func fetchAppStoreVersion(completion: @escaping (String?) -> Void) {
        let urlString = "https://itunes.apple.com/lookup?id=\(appID)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let version = firstResult["version"] as? String {
                    completion(version)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
    
    private func isUpdateRequired(current: String, store: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let storeComponents = store.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(currentComponents.count, storeComponents.count)
        
        for i in 0..<maxLength {
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            let storeValue = i < storeComponents.count ? storeComponents[i] : 0
            
            if storeValue > currentValue {
                return true
            } else if storeValue < currentValue {
                return false
            }
        }
        
        return false
    }
    
    func openAppStore() {
        let appStoreURL = "https://apps.apple.com/app/id\(appID)"
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
}
