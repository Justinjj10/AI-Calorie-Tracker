//
//  Config.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation

/// Configuration for API keys and settings
enum Config {
    /// OpenAI API Key - Set via environment variable
    /// WARNING: Never commit API keys to version control!
    /// For production, use Keychain or secure storage
    /// Get your API key from: https://platform.openai.com/api-keys
    /// 
    /// To set the API key:
    /// 1. Edit Scheme > Run > Arguments > Environment Variables
    /// 2. Add OPENAI_API_KEY with your API key value
    /// 3. Or set it in Xcode: Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables
    static var openAIAPIKey: String {
        // Try to get from environment variable first
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty {
            return apiKey
        }
        // Fallback to hardcoded key for development (REMOVE IN PRODUCTION)
        return "your-api-key-here"
    }
    
    /// OpenAI API Base URL
    static let openAIBaseURL = "https://api.openai.com/v1"
    
    /// OpenAI Model to use
    static let openAIModel = "gpt-4o" 
    
    /// Maximum image size for API (in bytes) - 20MB limit
    static let maxImageSize: Int = 20 * 1024 * 1024
    
    /// Target image size for compression (in bytes) - 4MB target
    static let targetImageSize: Int = 4 * 1024 * 1024
}

