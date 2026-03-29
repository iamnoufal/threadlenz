# ThreadLenz

AI-powered e-commerce product photography generator. Upload product photos and get professional variations with different lighting, compositions, and backgrounds — ready for Amazon, Instagram, and other platforms.

## Features

- **AI Image Analysis** — Analyzes product images and generates optimized prompts using Gemini 2.5 Flash
- **On-Demand Generation** — Generate one image at a time, up to 6 variations per project
- **Feedback Loop** — Provide feedback after each generation to guide the next variation
- **Multi-Photo Upload** — Select multiple product angles at once
- **Diverse Variations** — Each generation uses a distinct style (natural lighting, studio, minimalist, lifestyle, golden-hour, editorial)
- **Project History** — Browse, view, and delete past projects
- **Cross-Platform** — Runs on Android, iOS, and Web

## Tech Stack

- **Flutter** — Cross-platform UI
- **Firebase AI (Gemini)** — Prompt generation (`gemini-2.5-flash`) and image generation (`gemini-2.5-flash-image`)
- **Firebase Auth** — Anonymous authentication
- **SharedPreferences + File System** — Local project storage

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Firebase project with AI/Gemini enabled
- Firebase Blaze plan (required for AI model access)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/iamnoufal/threadlenz.git
   cd threadlenz
   ```

2. Copy the environment template and fill in your Firebase credentials:
   ```bash
   cp .env.template .env
   ```

3. Add your Firebase config files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

4. Install dependencies and run:
   ```bash
   flutter pub get
   flutter run
   ```

### Environment Variables

| Variable | Description |
|---|---|
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_MESSAGE_SENDER_ID` | FCM sender ID |
| `FIREBASE_STORAGE_BUCKET` | Storage bucket URL |
| `APP_BUNDLE_ID` | App bundle identifier |
| `ANDROID_API_KEY` | Android API key |
| `ANDROID_APP_ID` | Android app ID |
| `IOS_API_KEY` | iOS API key |
| `IOS_APP_ID` | iOS app ID |
| `IOS_CLIENT_ID` | iOS client ID |

## Project Structure

```
lib/
├── main.dart                    # App entry, Firebase init
├── firebase_options.dart        # Firebase credentials
├── theme/
│   └── app_theme.dart           # Color scheme and styling
├── models/
│   └── project_model.dart       # Project data model
├── services/
│   ├── ai_service.dart          # Prompt generation (Gemini)
│   ├── image_generation_service.dart  # Image generation (Gemini)
│   └── storage_service.dart     # Local persistence
├── screens/
│   ├── home_screen.dart         # Dashboard + recent projects
│   ├── image_picker_screen.dart # Upload product photos
│   ├── result_screen.dart       # Generation workflow + results
│   ├── project_detail_screen.dart # View project details
│   └── history_screen.dart      # Browse all projects
└── widgets/
    ├── image_upload_card.dart   # Upload slot widget
    └── full_screen_image_viewer.dart  # Image viewer
```

## How It Works

1. **Upload** — Select 1-4 product photos from different angles
2. **Analyze** — Gemini analyzes the product and creates an optimized prompt
3. **Generate** — First variation is generated automatically
4. **Iterate** — Use "Generate More" with optional feedback to create additional variations
5. **Save** — All variations are saved to project history

## CI/CD

- **PR opened** — Build check runs (Android + iOS) to catch failures early
- **PR merged** — Auto-release based on branch name prefix:
  - `feat_*` — Major version bump (v1.x.x -> v2.0.0)
  - `ptch_*` — Minor version bump (v1.0.x -> v1.1.0)
  - `fix_*` — Patch version bump (v1.0.2 -> v1.0.3)

## License

This project is proprietary. All rights reserved.
