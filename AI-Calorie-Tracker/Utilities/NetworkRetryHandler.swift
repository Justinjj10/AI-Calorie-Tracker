//
//  NetworkRetryHandler.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation

/// Generic network retry handler with exponential backoff
enum NetworkRetryHandler {
    /// Execute a network operation with retry logic
    /// - Parameters:
    ///   - maxAttempts: Maximum number of retry attempts (default: 3)
    ///   - baseDelay: Base delay in seconds for exponential backoff (default: 1)
    ///   - operation: The async throwing operation to execute
    /// - Returns: The result of the operation
    /// - Throws: The error from the final attempt
    static func retry<T>(
        maxAttempts: Int = 3,
        baseDelay: UInt64 = 1_000_000_000,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on the last attempt
                guard attempt < maxAttempts - 1 else {
                    break
                }
                
                // Calculate exponential backoff delay
                let delay = baseDelay * UInt64(1 << attempt) // 1s, 2s, 4s, etc.
                try await Task.sleep(nanoseconds: delay)
            }
        }
        
        throw lastError ?? NSError(domain: "NetworkRetryHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
    }
    
    /// Execute a network operation with custom retry logic based on HTTP status codes
    /// - Parameters:
    ///   - maxAttempts: Maximum number of retry attempts (default: 3)
    ///   - operation: The async throwing operation that returns both result and HTTP response
    ///   - shouldRetry: Closure to determine if should retry based on error/response
    /// - Returns: The result of the operation
    /// - Throws: The error from the final attempt
    static func retryWithCondition<T>(
        maxAttempts: Int = 3,
        operation: @escaping () async throws -> (result: T, shouldRetry: Bool, delay: UInt64?),
        shouldRetry: ((Error?) -> Bool)? = nil
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxAttempts {
            do {
                let (result, needsRetry, delay) = try await operation()
                
                guard needsRetry && attempt < maxAttempts - 1 else {
                    return result
                }
                
                let retryDelay = delay ?? (1_000_000_000 * UInt64(1 << attempt))
                try await Task.sleep(nanoseconds: retryDelay)
                continue
                
            } catch {
                lastError = error
                
                // Check if we should retry based on error type
                if let shouldRetry = shouldRetry, shouldRetry(error) && attempt < maxAttempts - 1 {
                    let delay = 1_000_000_000 * UInt64(1 << attempt)
                    try await Task.sleep(nanoseconds: delay)
                    continue
                }
                
                guard attempt < maxAttempts - 1 else {
                    break
                }
            }
        }
        
        throw lastError ?? NSError(domain: "NetworkRetryHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
    }
}


