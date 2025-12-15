//
//  FoodAnalysisViewModelTests.swift
//  AI-Calorie-TrackerTests
//
//  Created by Justin Joseph on 12/15/25.
//

import Testing
import Foundation
@testable import AI_Calorie_Tracker

@MainActor
struct FoodAnalysisViewModelTests {
    @Test func analyzeImageUsesServiceResult() async throws {
        let persistence = TestHelper.makeInMemoryPersistence()
        let expected = TestHelper.makeSampleAnalysis()
        let viewModel = FoodAnalysisViewModel(
            persistenceService: persistence,
            openAIService: MockAPIService(result: expected)
        )
        
        await viewModel.analyzeImage(imageBase64: "stub")
        
        #expect(viewModel.analysis?.mealType == expected.mealType)
        #expect(viewModel.analysis?.ingredients.count == expected.ingredients.count)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func addUpdateAndRemoveIngredientsRecalculatesTotals() async throws {
        let persistence = TestHelper.makeInMemoryPersistence()
        let baseAnalysis = TestHelper.makeSampleAnalysis(
            ingredients: [TestHelper.makeSampleIngredient()]
        )
        let viewModel = FoodAnalysisViewModel(
            persistenceService: persistence,
            openAIService: MockAPIService(result: baseAnalysis)
        )
        
        viewModel.analysis = baseAnalysis
        
        let rice = TestHelper.makeSampleIngredient(name: "Rice", quantity: 50, unit: "g", calories: 65)
        viewModel.addIngredient(rice)
        #expect(viewModel.analysis?.ingredients.count == 2)
        #expect(viewModel.analysis?.totalCalories ?? 0 > 200)
        
        viewModel.updateIngredient(
            at: 0,
            name: "Chicken Breast",
            quantity: 120,
            unit: "g"
        )
        
        #expect(viewModel.analysis?.ingredients.first?.name == "Chicken Breast")
        #expect((viewModel.analysis?.totalCalories ?? 0) > 250)
        
        viewModel.removeIngredient(at: 1)
        #expect(viewModel.analysis?.ingredients.count == 1)
        #expect(viewModel.analysis?.totalCalories ?? 0 > 150)
    }
    
    @Test func saveFoodLogPersistsAnalysis() async throws {
        let persistence = TestHelper.makeInMemoryPersistence()
        let analysis = TestHelper.makeSampleAnalysis()
        let viewModel = FoodAnalysisViewModel(
            persistenceService: persistence,
            openAIService: MockAPIService(result: analysis)
        )
        
        viewModel.analysis = analysis
        
        let success = await viewModel.saveFoodLog(imageData: nil, date: Date())
        let logs = try persistence.fetchAllFoodLogs()
        
        #expect(success == true)
        #expect(logs.count == 1)
        #expect(logs.first?.totalCalories == analysis.totalCalories)
        #expect(viewModel.errorMessage == nil)
    }
}

final class MockAPIService: APIServiceProtocol {
    var result: FoodAnalysis
    
    init(result: FoodAnalysis) {
        self.result = result
    }
    
    func analyzeFoodImage(imageBase64: String) async throws -> FoodAnalysis {
        result
    }
}

