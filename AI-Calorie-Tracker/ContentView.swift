//
//  ContentView.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodLog.date, ascending: true)],
        animation: .default)
    private var items: FetchedResults<FoodLog>

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        VStack(alignment: .leading) {
                            Text(item.foodDescription ?? "No description")
                                .font(.headline)
                            Text(item.date ?? Date(), formatter: DateFormatter.foodLogDateFormatter)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.foodDescription ?? "No description")
                                .font(.headline)
                            Text(item.date ?? Date(), formatter: DateFormatter.foodLogDateFormatter)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select a food log entry")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = FoodLog(context: viewContext)
            newItem.id = UUID()
            newItem.date = Date()
            newItem.createdAt = Date()
            newItem.foodDescription = "New Entry"
            newItem.totalCalories = 0

            do {
                try CoreDataErrorHandler.save(viewContext)
            } catch {
                let nsError = error as NSError
                #if DEBUG
                fatalError("Unresolved Core Data error \(nsError), \(nsError.userInfo)")
                #else
                // In production, log error instead of crashing
                print("Core Data save error: \(nsError.localizedDescription)")
                #endif
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try CoreDataErrorHandler.save(viewContext)
            } catch {
                let nsError = error as NSError
                #if DEBUG
                fatalError("Unresolved Core Data error \(nsError), \(nsError.userInfo)")
                #else
                // In production, log error instead of crashing
                print("Core Data save error: \(nsError.localizedDescription)")
                #endif
            }
        }
    }
}


#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
