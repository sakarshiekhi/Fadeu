# Fadeu Flutter App

## Overview

Fadeu is a language learning application designed to help users learn German, primarily targeting Persian speakers but also supporting English speakers. The app provides a dictionary, flashcards, and user activity tracking to enhance the learning experience. It supports both Android and Web platforms, with offline capabilities on Android.

## Key Features

*   **Cross-Platform:** Available on Android and Web.
*   **Offline Mode (Android):** Allows users to access dictionary data and save activity locally on Android.
*   **Bilingual Dictionary:** Provides German words with translations in Persian and English.
*   **Flashcards:** Helps users memorize vocabulary through interactive flashcards, filterable by difficulty level (A1, A2, B1).
*   **Saved Words:** Users can save words they want to focus on for later review.
*   **User Authentication:** Secure user registration and login.
*   **User Activity Tracking:** Monitors user progress, including study time, words searched, words saved, flashcards completed, and daily streaks.
*   **Data Synchronization:** Syncs user-specific data (saved words, activity) with the backend when authenticated, allowing data to persist across devices.
*   **Multi-Language UI:** Supports English and Persian interface languages.
*   **Light/Dark Theme:** Offers both light and dark mode themes for user preference.
*   **Password Reset:** Allows users to reset their password via email verification.
*   **Notifications (Android):** Provides word reminders (configurable).

## Technology Stack

*   **Framework:** Flutter
*   **Programming Language:** Dart
*   **Local Database (Android):** SQLite (for dictionary and offline user data)
*   **State Management:** (The project appears to use a combination of `setState` for local widget state and `SharedPreferences` for simple persistent data. More complex global state management isn't immediately obvious from the reviewed files but could be present.)
*   **Localization:** Uses Flutter's built-in localization capabilities (`arb` files).

## Backend Communication

The app communicates with a Django REST Framework backend to:
*   Authenticate users.
*   Fetch dictionary data (primarily for the web version or when local data is unavailable).
*   Synchronize user activity and saved words.

## Setup and Run

1.  Ensure you have Flutter SDK installed.
2.  Clone the repository.
3.  Navigate to the `fadeu` directory.
4.  Run `flutter pub get` to install dependencies.
5.  Run `flutter run` to launch the application on a connected device or emulator.
    *   For web, use `flutter run -d chrome`.

## Project Structure (Key Directories in `fadeu/lib/`)

*   `l10n/`: Contains localization files (`.arb`).
*   `main.dart`: Main application entry point.
*   `models/`: Data models (e.g., `Word`).
*   `pages/`: UI screens/pages for different features (auth, dictionary, flashcards, settings, etc.).
*   `services/`: Business logic and utility classes (e.g., `ApiService`, `AuthService`, `DatabaseHelper`).
*   `widgets/`: Reusable custom UI widgets (if any).
