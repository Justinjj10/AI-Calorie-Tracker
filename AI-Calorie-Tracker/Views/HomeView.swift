//
//  HomeView.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(fetchRequest: {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserProfile.createdAt, ascending: false)]
        request.fetchLimit = 1
        return request
    }()) private var userProfiles: FetchedResults<UserProfile>
    
    @State private var currentTipIndex = 0
    @State private var animatedTip = false
    
    private var safeTipIndex: Int {
        guard !healthTips.isEmpty else { return 0 }
        return min(max(currentTipIndex, 0), healthTips.count - 1)
    }
    
    let healthTips = [
        "💧 Stay hydrated! Aim for 8-10 glasses of water daily.",
        "🍎 Include fruits and vegetables in every meal for balanced nutrition.",
        "🥗 Start your day with a protein-rich breakfast to maintain energy.",
        "🏃 Regular exercise combined with proper nutrition leads to better health.",
        "🧘 Practice mindful eating - chew slowly and enjoy your meals.",
        "🥑 Healthy fats like avocados and nuts are essential for brain health.",
        "🌙 Aim for 7-9 hours of sleep for optimal recovery and metabolism.",
        "🥛 Include calcium-rich foods like dairy or leafy greens daily.",
        "🍽️ Portion control is key - use your hand as a serving size guide.",
        "🌱 Plant-based proteins can be excellent alternatives to meat."
    ]
    
    var userName: String {
        userProfiles.first?.name ?? "User"
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<24:
            return "Good Evening"
        default:
            return "Hello"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Greeting Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(greeting)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("\(userName)! 👋")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.1),
                                        Color.purple.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Daily Health Tip Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            
                            Text("Daily Health Tip")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        
                        Text(healthTips[safeTipIndex])
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .opacity(animatedTip ? 1 : 0)
                            .offset(y: animatedTip ? 0 : 20)
                        
                        HStack {
                            Spacer()
                            
                            Button(action: nextTip) {
                                HStack(spacing: 6) {
                                    Text("Next Tip")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    
                    // Quick Stats (if user has data)
                    if let profile = userProfiles.first {
                        quickStatsView(profile: profile)
                    }
                    
                    // Motivational Quote
                    motivationalQuoteView
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Home")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                // Set initial tip based on day of year for consistency
                let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
                currentTipIndex = dayOfYear % healthTips.count
                animateTip()
            }
            .onChange(of: currentTipIndex) { _, _ in
                animateTip()
            }
        }
    }
    
    private func quickStatsView(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Profile")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "person.fill",
                    title: "Age",
                    value: "\(profile.age)",
                    color: .blue
                )
                
                StatCard(
                    icon: "scalemass.fill",
                    title: "Weight",
                    value: String(format: "%.1f kg", profile.weight),
                    color: .green
                )
                
                StatCard(
                    icon: "ruler.fill",
                    title: "Height",
                    value: String(format: "%.0f cm", profile.height),
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private var motivationalQuoteView: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.largeTitle)
                .foregroundColor(.blue.opacity(0.5))
            
            Text("Every small step towards better nutrition is a victory worth celebrating.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .italic()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.1),
                            Color.pink.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    private func nextTip() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animatedTip = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentTipIndex = (currentTipIndex + 1) % healthTips.count
            animateTip()
        }
    }
    
    private func animateTip() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animatedTip = true
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
