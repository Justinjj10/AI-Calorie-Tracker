//
//  Ingredient.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation

/// Represents a single ingredient with nutritional information
struct Ingredient: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var calories: Double
    
    init(id: UUID = UUID(), name: String, quantity: Double, unit: String, calories: Double) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
    }
    
    // Custom decoder to handle missing 'id' field from API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Generate UUID if 'id' is not present in JSON
        if let idString = try? container.decode(String.self, forKey: .id),
           let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Double.self, forKey: .quantity)
        unit = try container.decode(String.self, forKey: .unit)
        calories = try container.decode(Double.self, forKey: .calories)
    }
    
    // Coding keys enum
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, calories
    }
    
    /// Calculate calories per unit for this ingredient
    var caloriesPerUnit: Double {
        guard quantity > 0 else { return 0 }
        return calories / quantity
    }
}

