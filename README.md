# AI-Calorie-Tracker

An iOS app that analyzes food calories from photos using OpenAI's Vision API.

## Features

- 📸 **Camera Capture**: Take photos of food or select from photo library
- 🤖 **AI Analysis**: Uses OpenAI Vision API to identify ingredients and calculate calories
- ✏️ **Editable Analysis**: Edit ingredients with real-time calorie updates
- 📅 **Calendar History**: View and manage food logs in a calendar format

## Requirements

- iOS 16.0+
- Xcode 15.0+
- OpenAI API key
- Swift 5.9+

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd AI-Calorie-Tracker
```

### 2. Open in Xcode

```bash
open AI-Calorie-Tracker.xcodeproj
```

### 3. Configure OpenAI API Key

Create a file `Config.swift` in the `AI-Calorie-Tracker/Models` folder (or add to existing configuration):

```swift
enum Config {
    static let openAIAPIKey = "your-api-key-here"
}
```

**Note**: For production, use Keychain or environment variables instead of hardcoding the API key.

Alternatively, you can set it as an environment variable:
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add `OPENAI_API_KEY` with your API key value

### 4. Build and Run

1. Select your target device (Simulator or physical device)
2. Press `Cmd + R` to build and run
3. Grant camera and photo library permissions when prompted

## Project Structure

```
AI-Calorie-Tracker/
├── AI-Calorie-Tracker/
│   ├── Models/
│   │   ├── Config.swift
│   │   ├── Ingredient.swift
│   │   └── FoodAnalysis.swift
│   ├── ViewModels/
│   │   ├── CameraViewModel.swift
│   │   ├── FoodAnalysisViewModel.swift
│   │   └── HistoryViewModel.swift
│   ├── Views/
│   │   ├── CameraView.swift
│   │   ├── FoodAnalysisView.swift
│   │   ├── HistoryView.swift
│   │   └── MainTabView.swift
│   ├── Services/
│   │   ├── OpenAIService.swift
│   │   └── ImageService.swift
│   ├── AI_Calorie_TrackerApp.swift
│   └── Persistence.swift
├── instruction.md
├── .cursor-rules
└── README.md
```

## Architecture

The app follows **MVVM (Model-View-ViewModel)** architecture:

- **Models**: Data structures and Core Data entities
- **Views**: SwiftUI views for UI
- **ViewModels**: Business logic and state management
- **Services**: API communication and image processing

## Usage

### Taking a Photo

1. Open the app
2. Tap the camera button in the main tab
3. Take a photo or select from photo library
4. Tap "Analyze" to process the image

### Editing Analysis

1. Review the AI-generated ingredients
2. Edit quantity, name, or unit as needed
3. Total calories update automatically
4. Add or remove ingredients if needed
5. Tap "Save" to add to your food log

### Viewing History

1. Navigate to the History tab
2. Browse calendar to see dates with food logs
3. Tap a date to view all meals for that day
4. Edit or delete past logs as needed

## Development with SweetPad

This project is designed to work with SweetPad for iOS development in VS Code:

1. Install SweetPad extension in VS Code
2. Connect to your iOS device or simulator
3. Use SweetPad to build and deploy directly from VS Code

## Development with Cursor

This project uses Cursor AI for development:

- `.cursor-rules` contains project-specific AI rules
- `instruction.md` contains the PRD and technical specifications
- Use Cursor's AI features for code generation and debugging
- Debug via Cursor AI logs: Check console output with prefixed logs like `[OpenAI]`, `[ImageService]`, `[ViewModel]`

## Development with Cline

This project is designed to work with Cline (VS Code AI extension):

- Use Cline for AI-assisted code generation and refactoring
- Leverage Cline's context awareness for better code suggestions
- Use Cline for debugging assistance and error resolution

## API Configuration

The app uses OpenAI's Vision API. Make sure you have:

1. An OpenAI API account
2. API key with sufficient credits
3. Access to `gpt-4o` or `gpt-4o-mini` models

## Troubleshooting

### Camera Not Working
- Check Info.plist has camera permissions
- Verify permissions are granted in Settings

### API Errors
- Verify API key is correct
- Check internet connection
- Ensure API key has sufficient credits

### Build Errors
- Clean build folder: `Cmd + Shift + K`
- Delete derived data
- Rebuild: `Cmd + B`

## License

[Add your license here]

## Git Commit Conventions

This project follows conventional commit messages for clear history:

- `feat: implement camera` - New features
- `fix: calorie update bug` - Bug fixes
- `refactor: improve image compression` - Code refactoring
- `docs: update README` - Documentation changes
- `chore: update dependencies` - Maintenance tasks

Example commits:
```
feat: implement camera capture functionality
feat: add OpenAI Vision API integration
feat: create editable ingredient view
feat: implement calendar history view
fix: resolve calorie calculation bug
fix: handle API timeout errors
```

## Contributing

[Add contribution guidelines if applicable]

