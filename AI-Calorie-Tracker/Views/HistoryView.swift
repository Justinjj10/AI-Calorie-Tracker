//
//  HistoryView.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import UIKit
import CoreData

/// View for displaying calendar history of food logs
struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedFoodLog: FoodLog?
    
    init() {
        // Initialize with shared context, will be updated with environment context
        let persistenceService = PersistenceService(viewContext: PersistenceController.shared.container.viewContext)
        _viewModel = StateObject(wrappedValue: HistoryViewModel(persistenceService: persistenceService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Header
                VStack(spacing: 16) {
                    // Date Navigation
                    HStack {
                        Button(action: {
                            viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                            viewModel.loadFoodLogsForSelectedDate()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.selectedDate = Date()
                            viewModel.loadFoodLogsForSelectedDate()
                        }) {
                            Text(viewModel.selectedDate, style: .date)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                            viewModel.loadFoodLogsForSelectedDate()
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Total Calories for Selected Date
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Calories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(Int(viewModel.totalCaloriesForSelectedDate))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                // Meal Type Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterButton(
                            title: "All",
                            isSelected: viewModel.selectedMealType == nil,
                            action: {
                                viewModel.selectedMealType = nil
                            }
                        )
                        
                        FilterButton(
                            title: "Breakfast",
                            isSelected: viewModel.selectedMealType == "breakfast",
                            action: {
                                viewModel.selectedMealType = viewModel.selectedMealType == "breakfast" ? nil : "breakfast"
                            }
                        )
                        
                        FilterButton(
                            title: "Lunch",
                            isSelected: viewModel.selectedMealType == "lunch",
                            action: {
                                viewModel.selectedMealType = viewModel.selectedMealType == "lunch" ? nil : "lunch"
                            }
                        )
                        
                        FilterButton(
                            title: "Dinner",
                            isSelected: viewModel.selectedMealType == "dinner",
                            action: {
                                viewModel.selectedMealType = viewModel.selectedMealType == "dinner" ? nil : "dinner"
                            }
                        )
                        
                        FilterButton(
                            title: "Snack",
                            isSelected: viewModel.selectedMealType == "snack",
                            action: {
                                viewModel.selectedMealType = viewModel.selectedMealType == "snack" ? nil : "snack"
                            }
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Food Logs List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    let filteredLogs = viewModel.filteredFoodLogs()
                    
                    if filteredLogs.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("No food logs for this date")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredLogs, id: \.id) { foodLog in
                                FoodLogRowView(foodLog: foodLog)
                                    .onTapGesture {
                                        selectedFoodLog = foodLog
                                    }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    viewModel.deleteFoodLog(filteredLogs[index])
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("History")
            .onAppear {
                viewModel.loadFoodLogsForSelectedDate()
            }
            .sheet(item: $selectedFoodLog) { foodLog in
                FoodLogDetailView(
                    foodLog: foodLog,
                    viewModel: viewModel
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

/// Filter button for meal types
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

/// Row view for displaying a food log in the list
struct FoodLogRowView: View {
    let foodLog: FoodLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageData = foodLog.imageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray4))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(foodLog.foodDescription ?? "No description")
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    if let mealType = foodLog.mealType {
                        Text(mealType.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    if let date = foodLog.date {
                        Text(date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Calories
            VStack(alignment: .trailing) {
                Text("\(Int(foodLog.totalCalories))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

