//
//  URL.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 01/10/2025.
//
import Foundation
import UniformTypeIdentifiers
// MARK: - URL Extensions
extension URL {
    func mimeType() -> String {
        if let uti = try? self.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let mimeType = UTType(uti)?.preferredMIMEType {
            return mimeType
        }
        
        // Fallback based on file extension
        switch self.pathExtension.lowercased() {
        case "pdf":
            return "application/pdf"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default:
            return "application/octet-stream"
        }
    }
}
