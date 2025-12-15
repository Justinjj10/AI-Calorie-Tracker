//
//  CoreDataErrorHandler.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation
import CoreData

/// Utility for handling Core Data errors consistently
enum CoreDataErrorHandler {
    /// Execute a save operation with consistent error handling
    /// - Parameter context: The managed object context to save
    /// - Throws: NSError wrapped in a more descriptive format
    static func save(_ context: NSManagedObjectContext) throws {
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            #if DEBUG
            fatalError("Unresolved Core Data error \(nsError), \(nsError.userInfo)")
            #else
            throw NSError(
                domain: "CoreDataErrorHandler",
                code: nsError.code,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to save data: \(nsError.localizedDescription)",
                    NSUnderlyingErrorKey: nsError
                ]
            )
            #endif
        }
    }
    
    /// Execute a closure with save operation and error handling
    /// - Parameters:
    ///   - context: The managed object context
    ///   - operation: The operation to perform before saving
    /// - Throws: Core Data save errors
    static func performWithSave<T>(
        context: NSManagedObjectContext,
        operation: () throws -> T
    ) throws -> T {
        let result = try operation()
        try save(context)
        return result
    }
}

