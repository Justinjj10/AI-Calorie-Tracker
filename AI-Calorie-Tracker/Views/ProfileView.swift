//
//  ProfileView.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: false)]
    ) private var userProfiles: FetchedResults<UserProfile>
    
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var userProfile: UserProfile? {
        userProfiles.first
    }
    
    var healthData: [String: String] {
        guard let profile = userProfile,
              let healthJson = profile.healthQuestions,
              let data = healthJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return json
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Text((userProfile?.name?.prefix(1).uppercased() ?? "U"))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        // Name
                        Text(userProfile?.name ?? "User")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Member since
                        if let createdAt = userProfile?.createdAt {
                            Text("Member since \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Personal Information Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Personal Information")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        if let profile = userProfile {
                            InfoRow(icon: "person.fill", title: "Name", value: profile.name ?? "N/A")
                            InfoRow(icon: "calendar", title: "Age", value: "\(profile.age) years")
                            InfoRow(icon: "scalemass.fill", title: "Weight", value: String(format: "%.1f kg", profile.weight))
                            InfoRow(icon: "ruler.fill", title: "Height", value: String(format: "%.0f cm", profile.height))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // Health Information Card
                    if !healthData.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Health Information")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .padding(.horizontal)
                                .padding(.top, 16)
                            
                            if let goal = healthData["goal"] {
                                InfoRow(icon: "target", title: "Goal", value: goal.capitalized)
                            }
                            
                            if let activity = healthData["activityLevel"] {
                                InfoRow(icon: "figure.run", title: "Activity Level", value: activity.capitalized)
                            }
                            
                            if let restrictions = healthData["dietaryRestrictions"], !restrictions.isEmpty {
                                InfoRow(icon: "leaf.fill", title: "Dietary Restrictions", value: restrictions)
                            }
                            
                            if let conditions = healthData["healthConditions"], !conditions.isEmpty {
                                InfoRow(icon: "heart.fill", title: "Health Conditions", value: conditions)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    }
                    
                    // BMI Calculation Card
                    if let profile = userProfile, profile.height > 0 && profile.weight > 0 {
                        bmiCard(profile: profile)
                            .padding(.horizontal)
                    }
                    
                    // Logout Button
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .font(.title3)
                            Text("Logout")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to logout? This will clear your profile data.")
            }
        }
    }
    
    private func bmiCard(profile: UserProfile) -> some View {
        let heightInMeters = profile.height / 100.0
        let bmi = profile.weight / (heightInMeters * heightInMeters)
        let bmiCategory: (String, Color) = {
            switch bmi {
            case ..<18.5:
                return ("Underweight", .blue)
            case 18.5..<25:
                return ("Normal", .green)
            case 25..<30:
                return ("Overweight", .orange)
            default:
                return ("Obese", .red)
            }
        }()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Body Mass Index (BMI)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.horizontal)
                .padding(.top, 16)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", bmi))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(bmiCategory.1)
                    
                    Text(bmiCategory.0)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(progress: min(bmi / 30.0, 1.0), color: bmiCategory.1)
                    .frame(width: 80, height: 80)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
    
    private func logout() {
        // Delete user profile
        if let profile = userProfile {
            viewContext.delete(profile)
            try? viewContext.save()
        }
        
        // Reset onboarding flag and return to onboarding
        hasCompletedOnboarding = false
        appState.showOnboarding = true
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}

