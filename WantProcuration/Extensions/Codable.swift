//
//  Codable.swift
//  MTCIT
//
//  Created by Ebtehal Elsaid on 01/10/2025.
//
import Foundation
// MARK: - Encodable Extensions
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: 0, userInfo: nil)
        }
        return dictionary
    }
}

// MARK: - Lossy array decoding

extension KeyedDecodingContainer {
    /// Decodes an array, skipping (and logging) elements that fail to decode.
    /// A missing or null key returns an empty array.
    func decodeLossyArray<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> [T] {
        guard contains(key), try !decodeNil(forKey: key) else { return [] }
        var container = try nestedUnkeyedContainer(forKey: key)
        var result: [T] = []
        var index = 0
        while !container.isAtEnd {
            do {
                result.append(try container.decode(T.self))
            } catch {
                Logger.error("Skipped invalid \(T.self) at index \(index): \(error)")
                // Advance past the bad element.
                _ = try? container.decode(SkippedElement.self)
            }
            index += 1
        }
        return result
    }
}

/// Decodes anything without reading it; used only to move past a bad array element.
private struct SkippedElement: Decodable {
    init(from decoder: Decoder) throws {}
}
