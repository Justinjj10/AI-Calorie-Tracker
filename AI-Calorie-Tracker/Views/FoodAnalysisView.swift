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
    @State private var selectedDate = Date()
    @State private var appearAnimation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let analysis = analysisViewModel.analysis {
                        // Header Card with Calories
                        caloriesHeaderCard(analysis: analysis)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                        
                        // Meal Type Selection
                        mealTypeCard(analysis: analysis)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                        
                        // Description Card
                        descriptionCard(analysis: analysis)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appearAnimation)
                        
                        // Ingredients List
                        ingredientsCard(analysis: analysis)
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: appearAnimation)
                        
                        // Date Picker Card
                        datePickerCard
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: appearAnimation)
                        
                        // Save Button
                        saveButton
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: appearAnimation)
                    } else {
                        Text("No analysis available")
                            .foregroundColor(.secondary)
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
            .onAppear {
                appearAnimation = true
            }
            .preferredColorScheme(.light) // Force light mode
            .alert("Error", isPresented: .constant(analysisViewModel.errorMessage != nil)) {
                Button("OK") {
                    analysisViewModel.errorMessage = nil
                }
            } message: {
                if let error = analysisViewModel.errorMessage {
                    Text(error)
                }
            }
            .alert("Saved!", isPresented: $showSaveConfirmation) {
                Button("OK") {
                    dismiss()
                    cameraViewModel.clearImage()
                }
            } message: {
                Text("Food log saved successfully")
            }
        }
    }
    
    private func addNewIngredient() {
        let newIngredient = Ingredient(
            name: "New Ingredient",
            quantity: 100,
            unit: "g",
            calories: 0
        )
        analysisViewModel.addIngredient(newIngredient)
    }
    
    private func saveFoodLog() {
        let imageData = cameraViewModel.getCompressedImageData()
        
        Task {
            let success = await analysisViewModel.saveFoodLog(
                imageData: imageData,
                date: selectedDate
            )
            
            if success {
                showSaveConfirmation = true
            }
        }
    }
    
    // MARK: - View Components
    
    private func caloriesHeaderCard(analysis: FoodAnalysis) -> some View {
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
                Text("\(Int(analysis.totalCalories))")
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
                            width: min(geometry.size.width * (analysis.totalCalories / 2000), geometry.size.width),
                            height: 8
                        )
                        .cornerRadius(4)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: analysis.totalCalories)
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
    
    private func mealTypeCard(analysis: FoodAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Meal Type")
                    .font(.headline)
            }
            
            Picker("Meal Type", selection: Binding(
                get: { analysis.mealType },
                set: { analysisViewModel.updateMealType($0) }
            )) {
                Label("Breakfast", systemImage: "sunrise.fill").tag("breakfast")
                Label("Lunch", systemImage: "sun.max.fill").tag("lunch")
                Label("Dinner", systemImage: "moon.fill").tag("dinner")
                Label("Snack", systemImage: "cup.and.saucer.fill").tag("snack")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func descriptionCard(analysis: FoodAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.purple)
                Text("Description")
                    .font(.headline)
            }
            
            TextEditor(text: Binding(
                get: { analysis.description },
                set: { analysisViewModel.updateDescription($0) }
            ))
            .frame(minHeight: 100)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func ingredientsCard(analysis: FoodAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.green)
                Text("Ingredients")
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        addNewIngredient()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            
            ForEach(Array(analysis.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                IngredientRowView(
                    ingredient: ingredient,
                    onUpdate: { name, quantity, unit in
                        analysisViewModel.updateIngredient(
                            at: index,
                            name: name,
                            quantity: quantity,
                            unit: unit
                        )
                    },
                    onDelete: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            analysisViewModel.removeIngredient(at: index)
                        }
                    }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var datePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.indigo)
                Text("Date")
                    .font(.headline)
            }
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var saveButton: some View {
        Button(action: {
            saveFoodLog()
        }) {
            HStack(spacing: 12) {
                if analysisViewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
                Text(analysisViewModel.isSaving ? "Saving..." : "Save Food Log")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.green, Color.green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(analysisViewModel.isSaving)
    }
}

/// Row view for editing a single ingredient
struct IngredientRowView: View {
    let ingredient: Ingredient
    let onUpdate: (String, Double, String) -> Void
    let onDelete: () -> Void
    
    @State private var name: String
    @State private var quantity: String
    @State private var unit: String
    
    init(ingredient: Ingredient, onUpdate: @escaping (String, Double, String) -> Void, onDelete: @escaping () -> Void) {
        self.ingredient = ingredient
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _name = State(initialValue: ingredient.name)
        _quantity = State(initialValue: String(ingredient.quantity))
        _unit = State(initialValue: ingredient.unit)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                TextField("Ingredient name", text: $name)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .onChange(of: name) { newValue, _ in
                        if let qty = Double(quantity) {
                            onUpdate(newValue, qty, unit)
                        }
                    }
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    TextField("Qty", text: $quantity)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .frame(width: 70)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: quantity) { newValue, _ in
                            if let qty = Double(newValue) {
                                onUpdate(name, qty, unit)
                            }
                        }
                    
                    TextField("Unit", text: $unit)
                        .textFieldStyle(.plain)
                        .frame(width: 60)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: unit) { newValue, _ in
                            if let qty = Double(quantity) {
                                onUpdate(name, qty, newValue)
                            }
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
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

#Preview {
    let persistenceService = PersistenceService(viewContext: PersistenceController.preview.container.viewContext)
    let analysisViewModel = FoodAnalysisViewModel(persistenceService: persistenceService)
    let cameraViewModel = CameraViewModel()
    
    // Set sample analysis
    analysisViewModel.analysis = FoodAnalysis(
        ingredients: [
            Ingredient(name: "Chicken Breast", quantity: 200, unit: "g", calories: 330),
            Ingredient(name: "Rice", quantity: 150, unit: "g", calories: 195)
        ],
        totalCalories: 525,
        mealType: "lunch",
        description: "Grilled chicken with rice"
    )
    
    return FoodAnalysisView(
        analysisViewModel: analysisViewModel,
        cameraViewModel: cameraViewModel
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


