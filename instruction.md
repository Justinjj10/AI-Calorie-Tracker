# AI-Calorie-Tracker: Product Requirements Document (PRD)

## Overview
AI-Calorie-Tracker is an iOS application that uses OpenAI's Vision API to analyze food photos and extract nutritional information including ingredients and calorie counts. Users can capture food photos, review and edit the AI-generated analysis, and maintain a calendar history of their food logs.

## Features

### 1. Camera Capture
- **Description**: Capture food photos using device camera or photo library
- **Requirements**:
  - Support both camera and photo library selection
  - Image compression before API upload (optimize for API limits)
  - Preview captured image before analysis
  - Handle camera permissions gracefully

### 2. OpenAI Vision API Integration
- **Description**: Analyze food photos to extract ingredients and nutritional information
- **API Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Model**: `gpt-4o` or `gpt-4o-mini` (with vision capabilities)
- **Request Format**:
  ```json
  {
    "model": "gpt-4o",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "Analyze this food image and return a JSON object with: ingredients (array of {name, quantity, unit, calories}), totalCalories (number), mealType (string: breakfast/lunch/dinner/snack), and description (string)."
          },
          {
            "type": "image_url",
            "image_url": {
              "url": "data:image/jpeg;base64,..."
            }
          }
        ]
      }
    ],
    "response_format": {
      "type": "json_object"
    }
  }
  ```
- **Response Format**:
  ```json
  {
    "ingredients": [
      {
        "name": "Chicken Breast",
        "quantity": 200,
        "unit": "g",
        "calories": 330
      }
    ],
    "totalCalories": 330,
    "mealType": "lunch",
    "description": "Grilled chicken breast with vegetables"
  }
  ```
- **Error Handling**: Network errors, API errors, invalid responses
- **API Key**: Store in environment variable or secure keychain (use test key for development)

### 3. Editable Ingredient View
- **Description**: Display and allow editing of analyzed ingredients with real-time calorie calculation
- **Requirements**:
  - List all ingredients with name, quantity, unit, calories
  - Editable fields: name, quantity, unit
  - Real-time total calorie calculation as user edits
  - Add/remove ingredients
  - Save edited analysis

### 4. Calendar History View
- **Description**: Display food logs in a calendar format with daily summaries
- **Requirements**:
  - Calendar view showing dates with food logs
  - Daily view showing all meals for selected date
  - Total calories per day
  - Ability to view/edit/delete past logs
  - Filter by meal type (breakfast/lunch/dinner/snack)

## Data Models

### FoodLog (Core Data Entity)
```swift
- id: UUID
- date: Date
- mealType: String (breakfast/lunch/dinner/snack)
- totalCalories: Double
- description: String
- imageData: Data? (optional, for thumbnail)
- ingredientsJSON: String (JSON string of ingredients array)
- createdAt: Date
- updatedAt: Date
```

### Ingredient (Codable)
```swift
struct Ingredient: Codable, Identifiable {
    let id: UUID
    var name: String
    var quantity: Double
    var unit: String
    var calories: Double
}
```

### FoodAnalysis (Codable)
```swift
struct FoodAnalysis: Codable {
    var ingredients: [Ingredient]
    var totalCalories: Double
    var mealType: String
    var description: String
}
```

## Architecture

### MVVM Pattern
- **Models**: Data structures (FoodLog, Ingredient, FoodAnalysis)
- **Views**: SwiftUI views (CameraView, FoodAnalysisView, HistoryView)
- **ViewModels**: Business logic and state management
  - `CameraViewModel`: Camera/image picker logic
  - `FoodAnalysisViewModel`: OpenAI API integration, ingredient editing
  - `HistoryViewModel`: Calendar and food log management
- **Services**: 
  - `OpenAIService`: API communication
  - `ImageService`: Image compression and processing
  - `PersistenceService`: Core Data operations

## Technical Requirements

### Dependencies
- SwiftUI (iOS 16.0+)
- Core Data
- UIKit (for camera/image picker)
- Foundation (for networking)

### Permissions
- Camera: `NSCameraUsageDescription`
- Photo Library: `NSPhotoLibraryUsageDescription`

### API Configuration
- OpenAI API Key: Store securely (Keychain recommended for production)
- Base URL: `https://api.openai.com/v1`
- Timeout: 30 seconds
- Retry logic: 2 retries on network failure

## User Flow

1. **Capture Photo**
   - User opens app → Main tab view
   - Taps camera button
   - Takes photo or selects from library
   - Image preview shown

2. **Analyze Food**
   - User taps "Analyze" button
   - Loading indicator shown
   - API call made with compressed image
   - Results displayed in FoodAnalysisView

3. **Edit Analysis**
   - User reviews ingredients
   - Edits quantity, name, or unit
   - Total calories update in real-time
   - User can add/remove ingredients

4. **Save Log**
   - User taps "Save" button
   - Food log saved to Core Data
   - Returns to history view
   - New entry appears in calendar

5. **View History**
   - User navigates to history tab
   - Calendar view shows dates with logs
   - Tapping date shows daily meals
   - Can edit or delete past logs

## Error Handling

- **Network Errors**: Show user-friendly message, allow retry
- **API Errors**: Display error message, log for debugging
- **Image Errors**: Handle invalid/corrupted images
- **Core Data Errors**: Graceful degradation, error logging

## Testing Considerations

- Mock OpenAI API responses for testing
- Test image compression
- Test Core Data persistence
- Test real-time calorie calculations
- Test calendar navigation

## Development Tools

### Cursor AI
- Use `.cursor-rules` for AI-assisted development
- Leverage Cursor's code completion and refactoring
- Debug using structured logging with prefixes

### SweetPad
- Build and deploy directly from VS Code
- Connect to iOS Simulator or physical device
- Real-time debugging and hot reload support

### GitHub
- Use conventional commit messages (feat:, fix:, etc.)
- Each feature should have separate commits
- Maintain clear commit history for evaluation

## Future Enhancements (Bonus)

- Image compression optimization
- Enhanced UI/UX
- TestFlight deployment
- Export data functionality
- Nutritional breakdown (protein, carbs, fats)
- Barcode scanning for packaged foods

