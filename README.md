# Dosify

A comprehensive medication dosage management application built with Flutter. Dosify helps users track and manage their medication schedules, doses, and supplies with precision and ease.

## Features

- **Medication Management**
  - Support for multiple medication types:
    - Tablets
    - Capsules
    - Injections (includes pre-filled syringes and vials)
  - Detailed medication tracking with strength and inventory management
  - Offline-first functionality for reliable access without internet

- **Modern UI**
  - Dark theme optimized for readability
  - Dashboard-style home screen with statistics
  - Intuitive navigation and medication management

- **Reconstitution Calculator**
  - Calculate precise dosages for reconstitutable medications
  - Visual syringe representation

- **Security**
  - End-to-end encryption for medication data
  - Firebase Authentication
  - Secure local storage

## Project Structure

```
lib/
├── constants/         # Variable definitions and calculations
│   ├── med_variables.dart
│   ├── dose_variables.dart
│   ├── cycles_variables.dart
│   ├── schedules_variables.dart
│   └── supplies_variables.dart
├── models/           # Data models
│   ├── medication.dart
│   ├── dose.dart
│   ├── schedule.dart
│   └── reconstitution_calculator.dart
├── screens/          # UI screens
│   ├── auth/        # Authentication screens
│   ├── home/        # Main app screens
│   └── medications/ # Medication management screens
├── services/        # Business logic and services
│   ├── encryption_service.dart
│   └── firebase_service.dart
├── theme/           # App theming
│   ├── app_colors.dart
│   ├── app_decorations.dart
│   ├── app_text_styles.dart
│   └── app_theme.dart
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Android Studio / VS Code with Flutter extensions
- Firebase project setup
- Android SDK version 23 or higher

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/dosify_cursor.git
```

2. Navigate to the project directory:
```bash
cd dosify_cursor
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

### Firebase Setup

1. Create a new Firebase project
2. Add Android app to Firebase project
3. Download `google-services.json` and place it in `android/app/`
4. Enable Authentication in Firebase Console
5. Configure Firebase options in the app

## Recent Improvements

- **UI Enhancements**: Implemented a modern dark theme with improved readability
- **Medication Model**: Simplified medication types by merging injection categories
- **Dashboard**: Added a statistics dashboard to the home screen
- **Offline Support**: Enhanced offline-first functionality with local storage
- **Security**: Implemented end-to-end encryption for sensitive medication data

## Development Guidelines

- Follow the variables table structure for all calculations
- Maintain consistent naming conventions
- Add comprehensive documentation for new features
- Ensure proper error handling and validation

## Security Features

- End-to-end encryption using AES
- Secure local storage with SharedPreferences
- Firebase Authentication integration
- Offline-first approach with data synchronization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the excellent framework
- Firebase for backend services
- Contributors and testers
