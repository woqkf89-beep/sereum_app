# 관령이의 소름사주 (Sereum App)

A premium AI fortune telling app built with Flutter and Node.js backend.

## Features

- AI-powered fortune telling and chat using OpenAI API (via backend)
- Premium UI with black, gold, purple, and navy theme
- Animated magical orb and particle effects
- Bottom tab navigation: Fortune, Chat, Store, Records, Settings
- Heart system for usage and in-app purchases
- Ad integration with Google Mobile Ads (banner, interstitial, rewarded)
- In-app purchase integration with mock and real purchase support
- Local data storage with SharedPreferences
- Error handling and loading states
- Node.js backend with Express, OpenAI SDK, CORS, dotenv

## Project Structure

- `lib/`: Flutter app source code
  - `config/`: App configuration
  - `core/`: Theme, widgets, utilities
  - `models/`: Data models
  - `providers/`: State management providers
  - `services/`: API, ads, payments, storage, fortune, chat services
  - `features/`: Screens for home, fortunes, chat, premium, etc.
- `server/`: Node.js backend server

## Getting Started

### Prerequisites

- Flutter SDK
- Node.js and npm

### Running the Flutter App

```bash
flutter pub get
flutter run
```

### Building Android APK

```bash
flutter build apk --release
```

### Running the Backend Server

```bash
cd server
npm install
npm start
```

## Notes

- Update `lib/config/app_config.dart` with your backend URL and ad unit IDs.
- Backend server handles OpenAI API calls securely.
- Payment and ad services are structured for easy extension.

## License

MIT License