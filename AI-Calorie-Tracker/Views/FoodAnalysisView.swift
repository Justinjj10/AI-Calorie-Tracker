//
//  FoodAnalysisView.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData

/// View for displaying and editing food analysis results
struct FoodAnalysisView: View {
    @ObservedObject var analysisViewModel: FoodAnalysisViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showSaveConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let analysis = analysisViewModel.analysis {
                        // Header with Calories
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Calories")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("\(Int(analysis.totalCalories))")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )
                        
                        // Meal Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Type")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(analysis.mealType.capitalized)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                        )
                        
                        // Description
                        if !analysis.description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text(analysis.description)
                                    .font(.body)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        
                        // Ingredients List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ingredients")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ForEach(analysis.ingredients) { ingredient in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ingredient.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text("\(ingredient.quantity, specifier: "%.1f") \(ingredient.unit)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(Int(ingredient.calories)) cal")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.05))
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                        )
                        
                        // Save Button
                        Button(action: {
                            saveFoodLog()
                        }) {
                            HStack {
                                if analysisViewModel.isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(analysisViewModel.isSaving ? "Saving..." : "Save Food Log")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: analysisViewModel.isSaving ? [Color.gray, Color.gray.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(analysisViewModel.isSaving)
                        .padding(.horizontal)
                    } else {
                        Text("No analysis available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Food Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .alert("Saved!", isPresented: $showSaveConfirmation) {
                Button("OK") {
                    dismiss()
                    cameraViewModel.clearImage()
                    analysisViewModel.clearAnalysis()
                }
            } message: {
                Text("Food log saved successfully")
            }
        }
    }
    
    private func saveFoodLog() {
        let imageData = cameraViewModel.getCompressedImageData()
        Task {
            let success = await analysisViewModel.saveFoodLog(imageData: imageData, date: Date())
            if success {
                showSaveConfirmation = true
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let persistenceService = PersistenceService(viewContext: context)
    let viewModel = FoodAnalysisViewModel(persistenceService: persistenceService)
    let cameraViewModel = CameraViewModel()
    
    // Set sample analysis
    viewModel.analysis = FoodAnalysis(
        ingredients: [
            Ingredient(name: "Chicken Breast", quantity: 200, unit: "g", calories: 330),
            Ingredient(name: "Rice", quantity: 150, unit: "g", calories: 195)
        ],
        totalCalories: 525,
        mealType: "lunch",
        description: "Grilled chicken with rice"
    )
    
    return FoodAnalysisView(
        analysisViewModel: viewModel,
        cameraViewModel: cameraViewModel
    )
    .environment(\.managedObjectContext, context)
}

