//
//  AI_Calorie_TrackerApp.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData
import Combine

@main
struct AI_Calorie_TrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .preferredColorScheme(.light) // Force light mode
                .onAppear {
                    checkOnboardingStatus()
                }
        }
    }
    
    private func checkOnboardingStatus() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "hasCompletedOnboarding == YES")
        
        if (try? context.fetch(request).first) != nil {
            hasCompletedOnboarding = true
            appState.showSplash = false
            appState.showOnboarding = false
        } else {
            hasCompletedOnboarding = false
        }
    }
}

// App State to manage navigation flow
class AppState: ObservableObject {
    @Published var showSplash = true
    @Published var showOnboarding = false
}

// Root content view that handles app flow
struct ContentRootView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            if appState.showSplash {
                SplashView()
                    .transition(.opacity)
                    .onAppear {
                        // Show splash for 2 seconds, then check onboarding
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                appState.showSplash = false
                                
                                if !hasCompletedOnboarding {
                                    appState.showOnboarding = true
                                }
                            }
                        }
                    }
            } else if appState.showOnboarding || !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.move(edge: .trailing))
                    .onDisappear {
                        // Check if onboarding was completed
                        if hasCompletedOnboarding {
                            appState.showOnboarding = false
                        }
                    }
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.showSplash)
        .animation(.easeInOut(duration: 0.5), value: appState.showOnboarding)
    }
}
