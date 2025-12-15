//
//  PersistenceService.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import CoreData
import Foundation
import UIKit

/// Service for Core Data operations related to FoodLog
@MainActor
class PersistenceService: PersistenceProtocol {
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    /// Save a food log to Core Data
    /// - Parameters:
    ///   - analysis: FoodAnalysis to save
    ///   - imageData: Optional image data for thumbnail
    ///   - date: Date for the food log (defaults to now)
    /// - Returns: Saved FoodLog entity
    /// - Throws: Core Data save errors
    func saveFoodLog(analysis: FoodAnalysis, imageData: Data?, date: Date = Date()) throws -> FoodLog {
        let foodLog = FoodLog(context: viewContext)
        foodLog.id = UUID()
        foodLog.date = date
        foodLog.mealType = analysis.mealType
        foodLog.totalCalories = analysis.totalCalories
        foodLog.foodDescription = analysis.description
        foodLog.createdAt = Date()
        foodLog.updatedAt = Date()
        
        // Store ingredients as JSON
        foodLog.ingredientsJSON = try analysis.ingredients.toJSONString()
        
        // Store thumbnail if provided
        if let imageData = imageData,
           let thumbnail = ImageService.shared.createThumbnail(from: imageData) {
            foodLog.imageData = thumbnail.jpegData(compressionQuality: 0.7)
        }
        
        try CoreDataErrorHandler.save(viewContext)
        return foodLog
    }
    
    /// Fetch all food logs
    /// - Returns: Array of FoodLog entities
    func fetchAllFoodLogs() throws -> [FoodLog] {
        let request: NSFetchRequest<FoodLog> = FoodLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodLog.date, ascending: false)]
        return try viewContext.fetch(request)
    }
    
    /// Fetch food logs for a specific date
    /// - Parameter date: Date to filter by
    /// - Returns: Array of FoodLog entities for that date
    func fetchFoodLogs(for date: Date) throws -> [FoodLog] {
        guard let endOfDay = date.endOfDay else {
            throw NSError(domain: "PersistenceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate end of day"])
        }
        
        return try fetchFoodLogs(from: date.startOfDay, to: endOfDay)
    }
    
    /// Fetch food logs in a date range
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Array of FoodLog entities in the range
    func fetchFoodLogs(from startDate: Date, to endDate: Date) throws -> [FoodLog] {
        let request: NSFetchRequest<FoodLog> = FoodLog.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodLog.date, ascending: false)]
        return try viewContext.fetch(request)
    }
    
    /// Update an existing food log
    /// - Parameters:
    ///   - foodLog: FoodLog to update
    ///   - analysis: Updated FoodAnalysis
    /// - Throws: Core Data save errors
    func updateFoodLog(_ foodLog: FoodLog, with analysis: FoodAnalysis) throws {
        foodLog.mealType = analysis.mealType
        foodLog.totalCalories = analysis.totalCalories
        foodLog.foodDescription = analysis.description
        foodLog.updatedAt = Date()
        
        foodLog.ingredientsJSON = try analysis.ingredients.toJSONString()
        
        try CoreDataErrorHandler.save(viewContext)
    }
    
    /// Delete a food log
    /// - Parameter foodLog: FoodLog to delete
    /// - Throws: Core Data save errors
    func deleteFoodLog(_ foodLog: FoodLog) throws {
        viewContext.delete(foodLog)
        try CoreDataErrorHandler.save(viewContext)
    }
    
    /// Get total calories for a specific date
    /// - Parameter date: Date to calculate for
    /// - Returns: Total calories for that date
    func getTotalCalories(for date: Date) throws -> Double {
        let logs = try fetchFoodLogs(for: date)
        return logs.map { $0.totalCalories }.sum
    }
    
    /// Convert FoodLog entity to FoodAnalysis
    /// - Parameter foodLog: FoodLog entity
    /// - Returns: FoodAnalysis model
    func foodLogToAnalysis(_ foodLog: FoodLog) throws -> FoodAnalysis {
        let ingredients: [Ingredient]
        
        if let ingredientsJSON = foodLog.ingredientsJSON, !ingredientsJSON.isEmpty {
            ingredients = try [Ingredient].fromJSONString(ingredientsJSON)
        } else {
            ingredients = []
        }
        
        return FoodAnalysis(
            ingredients: ingredients,
            totalCalories: foodLog.totalCalories,
            mealType: foodLog.mealType ?? "snack",
            description: foodLog.foodDescription ?? ""
        )
    }
}
