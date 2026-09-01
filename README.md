# GryphMarket

GryphMarket is a mobile marketplace application designed for students at the University of Guelph. The app provides a student-focused platform for buying, selling, and browsing items within the university community.

The project is built with Flutter and uses Firebase for authentication and cloud data storage.

> **Development Status:** GryphMarket is currently under development. Features, functionality, and the user interface are subject to change.

## Features

GryphMarket currently includes or is being developed to support:

* University of Guelph student account registration using `@uoguelph.ca` email addresses
* Email and password authentication
* User profiles
* Marketplace listing creation
* Browsing available listings
* Listing categories and filtering
* Marketplace search
* Personal listing management
* Item detail pages
* Direct messaging between buyers and sellers
* Firebase-backed cloud data storage
* Android support

Additional features and improvements are planned as development continues.

## Technology

GryphMarket is primarily built using:

* **Flutter** - Cross-platform application framework
* **Dart** - Application programming language
* **Firebase Authentication** - User account authentication
* **Cloud Firestore** - Marketplace, user, and messaging data
* **Material Design** - User interface components

## Requirements

To work with the project locally, you will need:

* Flutter SDK
* Dart SDK
* Android Studio and Android SDK
* A supported Android emulator or physical Android device
* A Firebase project
* Git

### Flutter Dependencies

The primary Flutter packages currently used by the project are:

```yaml
firebase_core: ^4.1.0
firebase_auth: ^6.0.2
cloud_firestore: ^6.0.1
intl: ^0.20.2
cupertino_icons: ^1.0.8
```

Development also uses:

```yaml
flutter_lints: ^6.0.0
```

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd gryph_market
```

Install the Flutter dependencies:

```bash
flutter pub get
```

The application requires a Firebase project configured for the target platform. Firebase Authentication with the Email/Password provider and a Cloud Firestore database are required for the application's backend functionality.

Once Firebase and an Android device or emulator are configured, run:

```bash
flutter run
```

## Authentication

GryphMarket is designed specifically for the University of Guelph community. Account registration is restricted by the application to email addresses ending in:

```text
@uoguelph.ca
```

The current project is a proof of concept and does not require access to or verification through a real University of Guelph email inbox.

## Project Status

This project is actively under development and should not currently be considered production-ready.

Current development is focused on completing and improving the core marketplace experience, including authentication, profiles, listings, search and filtering, and buyer/seller messaging.

Bugs, incomplete functionality, placeholder content, and UI changes should be expected during development.

## Disclaimer

GryphMarket is an independent software project and is **not affiliated with, endorsed by, sponsored by, or officially associated with the University of Guelph**.

The University of Guelph name and any associated trademarks belong to their respective owners.