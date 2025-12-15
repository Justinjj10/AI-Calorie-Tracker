//
//  PersistenceProtocol.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation
import CoreData

/// Protocol for data persistence operations
protocol PersistenceProtocol {
    /// Save a food log
    func saveFoodLog(analysis: FoodAnalysis, imageData: Data?, date: Date) throws -> FoodLog
    
    /// Fetch all food logs
    func fetchAllFoodLogs() throws -> [FoodLog]
    
    /// Fetch food logs for a specific date
    func fetchFoodLogs(for date: Date) throws -> [FoodLog]
    
    /// Fetch food logs in a date range
    func fetchFoodLogs(from startDate: Date, to endDate: Date) throws -> [FoodLog]
    
    /// Update an existing food log
    func updateFoodLog(_ foodLog: FoodLog, with analysis: FoodAnalysis) throws
    
    /// Delete a food log
    func deleteFoodLog(_ foodLog: FoodLog) throws
    
    /// Get total calories for a specific date
    func getTotalCalories(for date: Date) throws -> Double
    
    /// Convert FoodLog entity to FoodAnalysis
    func foodLogToAnalysis(_ foodLog: FoodLog) throws -> FoodAnalysis
}

