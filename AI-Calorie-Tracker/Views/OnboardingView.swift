//
//  OnboardingView.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var goal: String = "maintain"
    @State private var activityLevel: String = "moderate"
    @State private var dietaryRestrictions: String = ""
    @State private var healthConditions: String = ""
    
    @State private var currentStep: Int = 0
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    let goals = ["lose weight", "maintain", "gain weight"]
    let activityLevels = ["sedentary", "light", "moderate", "active", "very active"]
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, age, weight, height, restrictions, conditions
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: 2)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.horizontal)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 8) {
                            Text(getTitle())
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(getSubtitle())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Content based on step
                        if currentStep == 0 {
                            personalInfoSection
                        } else if currentStep == 1 {
                            healthInfoSection
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: previousStep) {
                            Text("Back")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(16)
                        }
                    }
                    
                    Button(action: nextStep) {
                        Text(currentStep < 1 ? "Continue" : "Complete")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var personalInfoSection: some View {
        VStack(spacing: 20) {
            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your name", text: $name)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .focused($focusedField, equals: .name)
            }
            
            // Age
            VStack(alignment: .leading, spacing: 8) {
                Text("Age")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("Enter your age", text: $age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .focused($focusedField, equals: .age)
            }
            
            // Weight and Height in a row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("0", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .focused($focusedField, equals: .weight)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (cm)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("0", text: $height)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .focused($focusedField, equals: .height)
                }
            }
        }
    }
    
    private var healthInfoSection: some View {
        VStack(spacing: 20) {
            // Goal
            VStack(alignment: .leading, spacing: 8) {
                Text("Fitness Goal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("Goal", selection: $goal) {
                    ForEach(goals, id: \.self) { goalOption in
                        Text(goalOption.capitalized).tag(goalOption)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 8)
            }
            
            // Activity Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Activity Level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Menu {
                    ForEach(activityLevels, id: \.self) { level in
                        Button(action: {
                            activityLevel = level
                        }) {
                            Text(level.capitalized)
                        }
                    }
                } label: {
                    HStack {
                        Text(activityLevel.capitalized)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            // Dietary Restrictions
            VStack(alignment: .leading, spacing: 8) {
                Text("Dietary Restrictions (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("e.g., vegetarian, vegan, gluten-free", text: $dietaryRestrictions, axis: .vertical)
                    .lineLimit(3...5)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .focused($focusedField, equals: .restrictions)
            }
            
            // Health Conditions
            VStack(alignment: .leading, spacing: 8) {
                Text("Health Conditions (Optional)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                TextField("e.g., diabetes, hypertension", text: $healthConditions, axis: .vertical)
                    .lineLimit(3...5)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .focused($focusedField, equals: .conditions)
            }
        }
    }
    
    private func getTitle() -> String {
        switch currentStep {
        case 0:
            return "Welcome! 👋"
        case 1:
            return "Health Information"
        default:
            return "Get Started"
        }
    }
    
    private func getSubtitle() -> String {
        switch currentStep {
        case 0:
            return "Let's set up your profile to personalize your calorie tracking experience"
        case 1:
            return "Help us understand your health goals and preferences"
        default:
            return ""
        }
    }
    
    private func previousStep() {
        withAnimation(.spring(response: 0.3)) {
            currentStep -= 1
        }
    }
    
    private func nextStep() {
        if currentStep == 0 {
            // Validate personal info
            guard !name.isEmpty,
                  !age.isEmpty,
                  Int(age) != nil,
                  !weight.isEmpty,
                  Double(weight) != nil,
                  !height.isEmpty,
                  Double(height) != nil else {
                errorMessage = "Please fill in all fields with valid values"
                showError = true
                return
            }
            
            withAnimation(.spring(response: 0.3)) {
                currentStep += 1
            }
        } else {
            // Save to Core Data
            saveUserProfile()
        }
    }
    
    private func saveUserProfile() {
        // Delete existing profile if any
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = UserProfile.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
            
            // Create new profile
            let profile = UserProfile(context: viewContext)
            profile.id = UUID()
            profile.name = name
            profile.age = Int32(age) ?? 0
            profile.weight = Double(weight) ?? 0.0
            profile.height = Double(height) ?? 0.0
            profile.hasCompletedOnboarding = true
            profile.createdAt = Date()
            profile.updatedAt = Date()
            
            // Save health questions as JSON
            let healthData: [String: String] = [
                "goal": goal,
                "activityLevel": activityLevel,
                "dietaryRestrictions": dietaryRestrictions,
                "healthConditions": healthConditions
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: healthData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                profile.healthQuestions = jsonString
            }
            
            try viewContext.save()
            
            // Set onboarding complete flag
            hasCompletedOnboarding = true
            appState.showOnboarding = false
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            showError = true
        }
    }
}

// Custom TextField Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    OnboardingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}

