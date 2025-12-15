//
//  FoodAnalysisViewModel.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import Combine

//// ViewModel for food analysis and ingredient editing
@MainActor
class FoodAnalysisViewModel: ObservableObject {
    @Published var analysis: FoodAnalysis?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaving = false
    
    private let openAIService: APIServiceProtocol
    private let persistenceService: PersistenceProtocol
    
    init(
        persistenceService: PersistenceProtocol,
        openAIService: APIServiceProtocol = OpenAIService.shared
    ) {
        self.persistenceService = persistenceService
        self.openAIService = openAIService
    }
    
    /// Analyze image using OpenAI Vision API
    /// - Parameter imageBase64: Base64 encoded image string
    func analyzeImage(imageBase64: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await openAIService.analyzeFoodImage(imageBase64: imageBase64)
            analysis = result
        } catch let error as OpenAIError {
            errorMessage = error.errorDescription ?? "Failed to analyze image"
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    /// Clear analysis results
    func clearAnalysis() {
        analysis = nil
        errorMessage = nil
        isLoading = false
    }
    
    /// Update ingredient at index
    /// - Parameters:
    ///   - index: Index of ingredient
    ///   - name: Updated name
    ///   - quantity: Updated quantity
    ///   - unit: Updated unit
    func updateIngredient(at index: Int, name: String, quantity: Double, unit: String) {
        mutateAnalysis { currentAnalysis in
            guard index < currentAnalysis.ingredients.count else {
                return false
            }
            
            let ingredient = currentAnalysis.ingredients[index]
            let caloriesPerUnit = ingredient.caloriesPerUnit
            
            // Update ingredient
            currentAnalysis.ingredients[index].name = name
            currentAnalysis.ingredients[index].quantity = quantity
            currentAnalysis.ingredients[index].unit = unit
            currentAnalysis.ingredients[index].calories = caloriesPerUnit * quantity
            
            // Recalculate total calories
            currentAnalysis.updateTotalCalories()
            return true
        }
    }
    
    /// Add new ingredient
    /// - Parameter ingredient: Ingredient to add
    func addIngredient(_ ingredient: Ingredient) {
        if analysis == nil {
            // Create new analysis if none exists
            analysis = FoodAnalysis(
                ingredients: [ingredient],
                totalCalories: ingredient.calories,
                mealType: "snack",
                description: ""
            )
            return
        }
        
        mutateAnalysis { currentAnalysis in
            currentAnalysis.ingredients.append(ingredient)
            currentAnalysis.updateTotalCalories()
            return true
        }
    }
    
    /// Remove ingredient at index
    /// - Parameter index: Index of ingredient to remove
    func removeIngredient(at index: Int) {
        mutateAnalysis { currentAnalysis in
            guard index < currentAnalysis.ingredients.count else {
                return false
            }
            currentAnalysis.ingredients.remove(at: index)
            currentAnalysis.updateTotalCalories()
            return true
        }
    }
    
    /// Update meal type
    /// - Parameter mealType: New meal type
    func updateMealType(_ mealType: String) {
        mutateAnalysis { currentAnalysis in
            currentAnalysis.mealType = mealType
            return true
        }
    }
    
    /// Update description
    /// - Parameter description: New description
    func updateDescription(_ description: String) {
        mutateAnalysis { currentAnalysis in
            currentAnalysis.description = description
            return true
        }
    }
    
    /// Save food log to Core Data
    /// - Parameters:
    ///   - imageData: Optional image data for thumbnail
    ///   - date: Date for the food log
    /// - Returns: Success status
    func saveFoodLog(imageData: Data?, date: Date = Date()) async -> Bool {
        guard let currentAnalysis = analysis else {
            errorMessage = "No analysis to save"
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            _ = try persistenceService.saveFoodLog(
                analysis: currentAnalysis,
                imageData: imageData,
                date: date
            )
            isSaving = false
            return true
        } catch {
            errorMessage = "Failed to save food log: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    /// Load analysis from FoodLog entity
    /// - Parameter foodLog: FoodLog entity to load
    func loadFromFoodLog(_ foodLog: FoodLog) throws {
        analysis = try persistenceService.foodLogToAnalysis(foodLog)
    }
    
    // MARK: - Private Helpers
    
    /// Mutate the current analysis if it exists
    /// - Parameter mutation: Closure that mutates the analysis and returns true if successful
    private func mutateAnalysis(_ mutation: (inout FoodAnalysis) -> Bool) {
        guard var currentAnalysis = analysis else {
            return
        }
        
        if mutation(&currentAnalysis) {
            analysis = currentAnalysis
        }
    }
}
