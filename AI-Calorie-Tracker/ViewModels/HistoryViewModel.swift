//
//  HistoryViewModel.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData
import Combine

/// ViewModel for calendar history and food log management
@MainActor
class HistoryViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var foodLogs: [FoodLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalCaloriesForSelectedDate: Double = 0
    @Published var selectedMealType: String? = nil
    
    private let persistenceService: PersistenceProtocol
    
    init(persistenceService: PersistenceProtocol) {
        self.persistenceService = persistenceService
    }
    
    /// Load food logs for selected date
    func loadFoodLogsForSelectedDate() {
        isLoading = true
        errorMessage = nil
        
        do {
            foodLogs = try persistenceService.fetchFoodLogs(for: selectedDate)
            totalCaloriesForSelectedDate = try persistenceService.getTotalCalories(for: selectedDate)
        } catch {
            errorMessage = "Failed to load food logs: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load all food logs
    func loadAllFoodLogs() {
        isLoading = true
        errorMessage = nil
        
        do {
            foodLogs = try persistenceService.fetchAllFoodLogs()
        } catch {
            errorMessage = "Failed to load food logs: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Get food logs for a specific date
    /// - Parameter date: Date to fetch logs for
    /// - Returns: Array of FoodLog entities
    func getFoodLogs(for date: Date) -> [FoodLog] {
        do {
            return try persistenceService.fetchFoodLogs(for: date)
        } catch {
            errorMessage = "Failed to load food logs: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Get total calories for a date
    /// - Parameter date: Date to calculate for
    /// - Returns: Total calories
    func getTotalCalories(for date: Date) -> Double {
        do {
            return try persistenceService.getTotalCalories(for: date)
        } catch {
            return 0
        }
    }
    
    /// Check if a date has food logs
    /// - Parameter date: Date to check
    /// - Returns: True if date has logs
    func hasFoodLogs(for date: Date) -> Bool {
        return !getFoodLogs(for: date).isEmpty
    }
    
    /// Delete a food log
    /// - Parameter foodLog: FoodLog to delete
    func deleteFoodLog(_ foodLog: FoodLog) {
        do {
            try persistenceService.deleteFoodLog(foodLog)
            loadFoodLogsForSelectedDate()
        } catch {
            errorMessage = "Failed to delete food log: \(error.localizedDescription)"
        }
    }
    
    /// Filter food logs by meal type
    /// - Parameter mealType: Meal type to filter by (nil for all)
    /// - Returns: Filtered food logs
    func filteredFoodLogs() -> [FoodLog] {
        guard let mealType = selectedMealType else {
            return foodLogs
        }
        return foodLogs.filter { $0.mealType == mealType }
    }
    
    /// Get dates with food logs in a month
    /// - Parameter month: Month to check
    /// - Returns: Set of dates with logs
    func getDatesWithLogs(in month: Date) -> Set<Date> {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return Set<Date>()
        }
        
        do {
            let logs = try persistenceService.fetchFoodLogs(from: startOfMonth, to: endOfMonth)
            let dates = Set(logs.compactMap { log -> Date? in
                guard let date = log.date else { return nil }
                return calendar.startOfDay(for: date)
            })
            return dates
        } catch {
            return []
        }
    }
}
