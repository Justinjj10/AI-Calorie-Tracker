//
//  APIServiceProtocol.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation

/// Protocol for API service operations
protocol APIServiceProtocol {
    /// Analyze food image and return structured nutritional information
    func analyzeFoodImage(imageBase64: String) async throws -> FoodAnalysis
}

