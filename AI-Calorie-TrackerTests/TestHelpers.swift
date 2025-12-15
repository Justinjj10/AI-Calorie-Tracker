//
//  TestHelpers.swift
//  AI-Calorie-TrackerTests
//
//  Created by Justin Joseph on 12/15/25.
//

import CoreData
import UIKit
@testable import AI_Calorie_Tracker

enum TestHelper {
    @MainActor static func makeInMemoryPersistence() -> PersistenceService {
        let controller = PersistenceController(inMemory: true)
        return PersistenceService(viewContext: controller.container.viewContext)
    }
    
    static func makeSampleIngredient(
        name: String = "Chicken",
        quantity: Double = 100,
        unit: String = "g",
        calories: Double = 165
    ) -> Ingredient {
        Ingredient(name: name, quantity: quantity, unit: unit, calories: calories)
    }
    
    static func makeSampleAnalysis(
        ingredients: [Ingredient]? = nil,
        mealType: String = "lunch",
        description: String = "Grilled chicken with rice"
    ) -> FoodAnalysis {
        let ingredients = ingredients ?? [
            makeSampleIngredient(),
            makeSampleIngredient(name: "Rice", quantity: 50, unit: "g", calories: 65)
        ]
        var analysis = FoodAnalysis(
            ingredients: ingredients,
            totalCalories: ingredients.map { $0.calories }.sum,
            mealType: mealType,
            description: description
        )
        analysis.updateTotalCalories()
        return analysis
    }
    
    static func makeSolidImage(color: UIColor = .red, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}

