//
//  AI_Calorie_TrackerApp.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData

@main
struct AI_Calorie_TrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
