# Dosify

A comprehensive medication dosage management application built with Flutter. Dosify helps users track and manage their medication schedules, doses, and supplies with precision and ease.

## Features

- **Medication Management**
  - Support for multiple medication types:
    - Tablets
    - Capsules
    - Liquid Vials
    - Reconstitutable Vials
    - Pre-filled Syringes
  - Detailed medication tracking with strength and volume calculations

- **Dosage Scheduling**
  - Flexible scheduling options:
    - Multiple times per day
    - Daily doses
    - Specific days scheduling
    - Days On/Off patterns
    - Weekly and monthly patterns
  - Custom time selection for each dose

- **Treatment Cycles**
  - Various cycle types:
    - Never-ending treatments
    - Date-based end points
    - Days/Weeks/Months On/Off patterns
  - Dose switching support
  - Break period management

- **Supply Management**
  - Track medical supplies
  - Monitor unit quantities
  - Volume tracking per unit

## Project Structure

```
lib/
├── constants/          # Variable definitions and calculations
│   ├── med_variables.dart
│   ├── dose_variables.dart
│   ├── cycles_variables.dart
│   ├── schedules_variables.dart
│   └── supplies_variables.dart
├── models/            # Data models
│   ├── medication.dart
│   ├── dose.dart
│   └── schedule.dart
├── screens/           # UI screens
│   ├── auth/         # Authentication screens
│   └── home/         # Main app screens
├── services/         # Business logic and services
└── main.dart         # App entry point
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
git clone [repository-url]
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

## Development Guidelines

- Follow the variables table structure for all calculations
- Maintain consistent naming conventions
- Add comprehensive documentation for new features
- Ensure proper error handling and validation

## Security Features

- Secure storage for sensitive data
- Firebase Authentication integration
- Encrypted data transmission

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

## Contact

For support or queries, please contact [project-contact-email]
