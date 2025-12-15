//
//  FoodAnalysis.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation

/// Response structure from OpenAI Vision API
struct FoodAnalysis: Codable {
    var ingredients: [Ingredient]
    var totalCalories: Double
    var mealType: String
    var description: String
    
    /// Calculate total calories from ingredients
    mutating func updateTotalCalories() {
        totalCalories = ingredients.map { $0.calories }.sum
    }
}

/// OpenAI API response wrapper
struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
    
    /// Extract FoodAnalysis from response
    func extractFoodAnalysis() throws -> FoodAnalysis {
        guard let firstChoice = choices.first else {
            throw OpenAIError.invalidResponse
        }
        
        let content = firstChoice.message.content
        guard let data = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(FoodAnalysis.self, from: data)
        } catch let decodingError as DecodingError {
            // Provide more detailed error information
            let errorMessage: String
            switch decodingError {
            case .keyNotFound(let key, let context):
                errorMessage = "Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                errorMessage = "Type mismatch for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorMessage = "Value not found for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorMessage = "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
            @unknown default:
                errorMessage = "Decoding error: \(decodingError.localizedDescription)"
            }
            throw OpenAIError.apiError("Failed to parse API response: \(errorMessage). Raw content: \(content.prefix(200))")
        } catch {
            throw OpenAIError.apiError("Failed to parse API response: \(error.localizedDescription). Raw content: \(content.prefix(200))")
        }
    }
}

/// OpenAI API errors
enum OpenAIError: LocalizedError {
    case invalidAPIKey
    case networkError
    case invalidResponse
    case rateLimitExceeded
    case serverError
    case apiError(String) // Custom error message from API
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidResponse:
            return "Invalid response from API. Please try again."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        case .apiError(let message):
            return message
        }
    }
}

/// Extension to sum array of doubles
extension Sequence where Element == Double {
    func sum() -> Double {
        return reduce(0, +)
    }
}

