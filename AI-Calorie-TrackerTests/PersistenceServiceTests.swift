//
//  PersistenceServiceTests.swift
//  AI-Calorie-TrackerTests
//
//  Created by Justin Joseph on 12/15/25.
//

import Testing
import Foundation
@testable import AI_Calorie_Tracker

@MainActor
struct PersistenceServiceTests {
    @Test func saveAndFetchRoundTripsAnalysis() async throws {
        let persistence = TestHelper.makeInMemoryPersistence()
        let analysis = TestHelper.makeSampleAnalysis()
        
        let saved = try persistence.saveFoodLog(analysis: analysis, imageData: nil, date: Date())
        let fetched = try persistence.fetchAllFoodLogs()
        let restored = try persistence.foodLogToAnalysis(saved)
        
        #expect(fetched.count == 1)
        #expect(restored.mealType == analysis.mealType)
        #expect(restored.ingredients.count == analysis.ingredients.count)
        #expect(restored.totalCalories == analysis.totalCalories)
    }
    
    @Test func getTotalCaloriesAggregatesByDate() async throws {
        let persistence = TestHelper.makeInMemoryPersistence()
        let now = Date()
        
        var breakfast = TestHelper.makeSampleAnalysis(mealType: "breakfast", description: "Oats")
        breakfast.totalCalories = 300
        var lunch = TestHelper.makeSampleAnalysis(mealType: "lunch", description: "Salad")
        lunch.totalCalories = 500
        
        _ = try persistence.saveFoodLog(analysis: breakfast, imageData: nil, date: now)
        _ = try persistence.saveFoodLog(analysis: lunch, imageData: nil, date: now)
        
        let total = try persistence.getTotalCalories(for: now)
        #expect(total == 800)
    }
}

