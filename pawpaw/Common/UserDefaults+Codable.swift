//
//  UserDefaults+Codable.swift
//  pawpaw
//

import Foundation

extension UserDefaults {
    /// `nil` when nothing is stored or it can't be decoded; the latter is logged.
    func decode<Value: Decodable>(
        _ type: Value.Type, forKey key: String, failureMessage: String
    ) -> Value? {
        guard let data = data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            Log.storageFailure(failureMessage, error: error)
            return nil
        }
    }

    func encode<Value: Encodable>(_ value: Value, forKey key: String, failureMessage: String) {
        do {
            set(try JSONEncoder().encode(value), forKey: key)
        } catch {
            Log.storageFailure(failureMessage, error: error)
        }
    }
}
