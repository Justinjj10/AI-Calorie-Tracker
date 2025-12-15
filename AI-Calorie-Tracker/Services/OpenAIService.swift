//
//  OpenAIService.swift
//  AI-Calorie-Tracker
//
//  Created by Justin Joseph on 12/15/25.
//

import Foundation

/// Service for communicating with OpenAI Vision API
@MainActor
class OpenAIService: APIServiceProtocol {
    static let shared = OpenAIService()
    
    // MARK: - Constants
    private enum Constants {
        static let timeoutInterval: TimeInterval = 30.0
        static let maxTokens = 1000
        static let maxRetries = 3
        static let defaultRetryDelay: UInt64 = 1_000_000_000 // 1 second
    }
    
    private let baseURL = Config.openAIBaseURL
    private let model = Config.openAIModel
    private let apiKey: String
    
    private init() {
        self.apiKey = Config.openAIAPIKey
    }
    
    /// Analyze food image and return structured nutritional information
    /// - Parameter imageBase64: Base64 encoded image string
    /// - Returns: FoodAnalysis with ingredients and calories
    /// - Throws: OpenAIError for various API failures
    func analyzeFoodImage(imageBase64: String) async throws -> FoodAnalysis {
        guard !apiKey.isEmpty else {
            throw OpenAIError.invalidAPIKey
        }
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = Constants.timeoutInterval
        
        // Construct the prompt for structured JSON response
        let prompt = """
        Analyze this food image and return a JSON object with the following structure:
        {
            "ingredients": [
                {
                    "name": "string",
                    "quantity": number,
                    "unit": "string (g, ml, oz, etc.)",
                    "calories": number
                }
            ],
            "totalCalories": number,
            "mealType": "string (breakfast/lunch/dinner/snack)",
            "description": "string (brief description of the meal)"
        }
        
        Be accurate with calorie estimates based on the visible ingredients and quantities.
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(imageBase64)"
                            ]
                        ]
                    ]
                ]
            ],
            "response_format": [
                "type": "json_object"
            ],
            "max_tokens": Constants.maxTokens
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Perform request with retry logic
        var lastError: Error?
        for attempt in 0..<Constants.maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OpenAIError.networkError
                }
                
                // Handle different HTTP status codes
                switch httpResponse.statusCode {
                case 200:
                    // Log response for debugging
                    #if DEBUG
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📥 OpenAI API Response:")
                        print(jsonObject)
                    }
                    #endif
                    
                    let decoder = JSONDecoder()
                    let openAIResponse = try decoder.decode(OpenAIResponse.self, from: data)
                    return try openAIResponse.extractFoodAnalysis()
                    
                case 400, 401, 403:
                    // Client errors - don't retry
                    if let errorMessage = parseErrorResponse(data: data) {
                        throw OpenAIError.apiError(errorMessage)
                    }
                    throw OpenAIError.invalidAPIKey
                    
                case 429:
                    // Rate limit - retry with backoff if not last attempt
                    if attempt < Constants.maxRetries - 1 {
                        let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                        let delay = (retryAfter.flatMap { UInt64($0) } ?? 2) * 1_000_000_000
                        try await Task.sleep(nanoseconds: delay)
                        continue
                    }
                    if let errorMessage = parseErrorResponse(data: data) {
                        throw OpenAIError.apiError(errorMessage)
                    }
                    throw OpenAIError.rateLimitExceeded
                    
                case 500...599:
                    // Server error - retry if not last attempt
                    if attempt < Constants.maxRetries - 1 {
                        try await Task.sleep(nanoseconds: Constants.defaultRetryDelay * UInt64(1 << attempt))
                        continue
                    }
                    if let errorMessage = parseErrorResponse(data: data) {
                        throw OpenAIError.apiError(errorMessage)
                    }
                    throw OpenAIError.serverError
                    
                default:
                    if let errorMessage = parseErrorResponse(data: data) {
                        throw OpenAIError.apiError(errorMessage)
                    }
                    throw OpenAIError.invalidResponse
                }
            } catch let error as OpenAIError {
                // Don't retry OpenAI-specific errors (they're already handled above)
                throw error
            } catch {
                lastError = error
                // Network error - retry if not last attempt
                if attempt < Constants.maxRetries - 1 {
                    try await Task.sleep(nanoseconds: Constants.defaultRetryDelay * UInt64(1 << attempt))
                    continue
                }
            }
        }
        
        // If we get here, all retries failed
        throw lastError ?? OpenAIError.networkError
    }
    
    /// Parse error response from OpenAI API
    private func parseErrorResponse(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            // Try to get raw error message
            if let jsonString = String(data: data, encoding: .utf8) {
                return "API Error: \(jsonString)"
            }
            return nil
        }
        
        // Provide more user-friendly messages for common errors
        if message.contains("quota") || message.contains("billing") {
            return "OpenAI API Quota Exceeded\n\nYou've exceeded your current OpenAI API quota. Please:\n1. Check your billing at https://platform.openai.com/account/billing\n2. Add payment method or increase your quota\n3. Wait for your quota to reset\n\nOriginal error: \(message)"
        }
        
        return message
    }
}
