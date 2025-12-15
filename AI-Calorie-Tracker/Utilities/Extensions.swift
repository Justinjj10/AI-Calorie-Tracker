//
//  Extensions.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation


// MARK: - DateFormatter Extension
extension DateFormatter {
    /// Shared date formatter for food log dates
    static let foodLogDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    /// Shared date formatter for short dates
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Shared date formatter for time only
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Date Extension
extension Date {
    /// Start of day for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of day for this date
    var endOfDay: Date? {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)
    }
}

// MARK: - Encodable Extension
extension Encodable {
    /// Convert to JSON data
    func toJSONData() throws -> Data {
        try JSONEncoder().encode(self)
    }
    
    /// Convert to JSON string
    func toJSONString(encoding: String.Encoding = .utf8) throws -> String {
        let data = try toJSONData()
        guard let string = String(data: data, encoding: encoding) else {
            throw NSError(domain: "EncodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode to string"])
        }
        return string
    }
}

// MARK: - Decodable Extension
extension Decodable {
    /// Initialize from JSON data
    static func fromJSONData(_ data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
    
    /// Initialize from JSON string
    static func fromJSONString(_ string: String, encoding: String.Encoding = .utf8) throws -> Self {
        guard let data = string.data(using: encoding) else {
            throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
        }
        return try fromJSONData(data)
    }
}

// MARK: - Array Extension
extension Array where Element: Numeric {
    /// Sum of all elements
    var sum: Element {
        reduce(0, +)
    }
}

