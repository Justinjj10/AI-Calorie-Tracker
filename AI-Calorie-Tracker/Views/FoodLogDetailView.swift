//
//  FoodLogDetailView.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData

/// Detail view for a food log
struct FoodLogDetailView: View {
    let foodLog: FoodLog
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var analysisViewModel: FoodAnalysisViewModel
    @State private var showEditView = false
    @State private var appearAnimation = false
    
    init(foodLog: FoodLog, viewModel: HistoryViewModel) {
        self.foodLog = foodLog
        self.viewModel = viewModel
        let persistenceService = PersistenceService(viewContext: PersistenceController.shared.container.viewContext)
        _analysisViewModel = StateObject(wrappedValue: FoodAnalysisViewModel(persistenceService: persistenceService))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Card
                    if let imageData = foodLog.imageData,
                       let image = UIImage(data: imageData) {
                        imageCard(image: image)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                    }
                    
                    // Calories Header Card
                    caloriesHeaderCard
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : -20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                    
                    // Meal Type Card
                    if let mealType = foodLog.mealType {
                        mealTypeCard(mealType: mealType)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appearAnimation)
                    }
                    
                    // Description Card
                    descriptionCard
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : -20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: appearAnimation)
                    
                    // Ingredients Card
                    if let ingredientsJSON = foodLog.ingredientsJSON,
                       let data = ingredientsJSON.data(using: .utf8),
                       let ingredients = try? JSONDecoder().decode([Ingredient].self, from: data) {
                        ingredientsCard(ingredients: ingredients)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: appearAnimation)
                    }
                    
                    // Date Info Card
                    if let createdAt = foodLog.createdAt {
                        dateCard(createdAt: createdAt)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: appearAnimation)
                    }
                }
                .padding()
            }
            .navigationTitle("Food Log Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                appearAnimation = true
                do {
                    try analysisViewModel.loadFromFoodLog(foodLog)
                } catch {
                    // Handle error
                }
            }
            .preferredColorScheme(.light) // Force light mode
        }
    }
    
    // MARK: - View Components
    
    private func imageCard(image: UIImage) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 300)
                .clipped()
                .cornerRadius(20)
        }
    }
    
    private var caloriesHeaderCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Total Calories")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(Int(foodLog.totalCalories))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("kcal")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: min(geometry.size.width * (foodLog.totalCalories / 2000), geometry.size.width),
                            height: 8
                        )
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("Daily Goal: 2000 kcal")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func mealTypeCard(mealType: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: mealTypeIcon(mealType))
                    .foregroundColor(.blue)
                Text("Meal Type")
                    .font(.headline)
            }
            
            HStack {
                Text(mealType.capitalized)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.purple)
                Text("Description")
                    .font(.headline)
            }
            
            Text(foodLog.foodDescription ?? "No description")
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func ingredientsCard(ingredients: [Ingredient]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.green)
                Text("Ingredients")
                    .font(.headline)
                Spacer()
                Text("\(ingredients.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            ForEach(ingredients) { ingredient in
                ingredientRow(ingredient: ingredient)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func ingredientRow(ingredient: Ingredient) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text("\(ingredient.quantity, specifier: "%.1f") \(ingredient.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(Int(ingredient.calories))")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
    
    private func dateCard(createdAt: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.indigo)
                Text("Date & Time")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Created:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(createdAt, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                if let foodLogDate = foodLog.date {
                    HStack {
                        Text("Meal Date:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(foodLogDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func mealTypeIcon(_ mealType: String) -> String {
        switch mealType.lowercased() {
        case "breakfast":
            return "sunrise.fill"
        case "lunch":
            return "sun.max.fill"
        case "dinner":
            return "moon.fill"
        case "snack":
            return "cup.and.saucer.fill"
        default:
            return "fork.knife"
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let foodLog = FoodLog(context: context)
    foodLog.id = UUID()
    foodLog.date = Date()
    foodLog.totalCalories = 525
    foodLog.foodDescription = "Grilled chicken with rice"
    foodLog.mealType = "lunch"
    foodLog.createdAt = Date()
    
    let persistenceService = PersistenceService(viewContext: context)
    let viewModel = HistoryViewModel(persistenceService: persistenceService)
    
    return FoodLogDetailView(foodLog: foodLog, viewModel: viewModel)
        .environment(\.managedObjectContext, context)
}

