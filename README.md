# Fadeu – Offline German Vocabulary Learning App

Fadeu is a cross-platform language learning app designed to help users — especially Persian speakers — learn German vocabulary through an interactive, flashcard-based experience. It features offline access, bilingual dictionary data, and synchronized learning progress via a Django backend.

---

## ✨ Key Features

- **Cross-Platform**: Works on Android and Web (Chrome).
- **Offline Mode (Android)**: Loads an embedded SQLite database for fast, offline lookups.
- **German Dictionary**: Translations to both Persian and English with examples.
- **Flashcards**: Practice vocabulary based on Goethe levels (A1–B1).
- **Saved Words**: Mark and review key words later.
- **User Tracking**: Tracks user activity, daily streaks, and study progress.
- **Notifications (Android)**: Optional daily word reminders.
- **Authentication**: Email-based login system with password reset support.
- **Data Sync**: User data syncs with backend when logged in.
- **Multi-language UI**: Persian and English interfaces supported.
- **Dark & Light Mode**: Theme toggle for comfortable studying.

---

## 🛠️ Technology Stack

| Layer        | Stack                                |
|--------------|---------------------------------------|
| Frontend     | Flutter 3.32.4, Dart 3.8.1            |
| Backend      | Django + Django REST Framework        |
| Local DB     | SQLite (via `sqflite`)                |
| Authentication | JWT (`djangorestframework-simplejwt`) |
| State Mgmt   | Provider + SharedPreferences (basic)  |
| Platform     | Android + Web (Chrome)                |

---

## 📦 Installation & Running

### Prerequisites:
- Flutter SDK installed
- Dart SDK (included in Flutter)
- For backend: Python 3.x, pip, virtualenv

