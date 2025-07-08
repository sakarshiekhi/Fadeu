# Fadeu Django Backend

## Overview

This Django project serves as the backend for the Fadeu language learning application. It provides a RESTful API for user authentication, dictionary data management, and storage of user-specific information such as learning activity and saved words.

## Key Features & API Functionalities

*   **User Authentication & Management:**
    *   User registration (`/api/auth/register/`)
    *   Email-based login with JWT token generation (`/api/auth/token/`)
    *   JWT token refresh (`/api/token/refresh/`)
    *   Password reset functionality:
        *   Request password reset (`/api/accounts/password-reset/`)
        *   Verify reset code (`/api/accounts/password-reset/verify/`)
        *   Set new password (`/api/accounts/reset-password/`)
    *   User profile retrieval and updates (`/api/auth/profile/`)
*   **User Activity Synchronization:**
    *   Endpoint to sync user learning activity (`/api/accounts/sync-activity/`) including study time, words searched/saved, flashcards completed, and streaks.
*   **Dictionary Data:**
    *   Serves dictionary data (German words with Persian and English translations, examples, levels, etc.).
    *   Endpoints for searching words (`/api/words/search/`), fetching word lists (e.g., for flashcards `/api/words/words/`), and retrieving individual word details (`/api/words/words/<id>/`).
*   **Saved Words Management:**
    *   Endpoints to manage user-saved words (e.g., `/api/words/saved-words/`). *(Exact implementation details for adding/removing saved words for a specific user would be within the `words` app's views and require user authentication.)*

## Technology Stack

*   **Framework:** Django & Django REST Framework
*   **Programming Language:** Python
*   **Database:**
    *   SQLite for the main dictionary data (`dictionary.db`) - accessed via a separate database connection.
    *   Default SQLite database (`db.sqlite3`) for user accounts and user-specific data (like `UserActivity`).
*   **Authentication:** JWT (JSON Web Tokens) via `djangorestframework-simplejwt`.
*   **User Model:** Custom user model (`users.User`) using email as the unique identifier.

## Project Structure (Key Directories in `fadeuBackend/fadeu/`)

*   **`accounts/`**: Django app primarily handling password reset, user activity models, and related views/serializers. Also contains legacy authentication views that have been mostly superseded by the `users` app for primary auth.
*   **`users/`**: Django app managing the primary custom `User` model, user registration, login (token generation), and profile views/serializers.
*   **`words/`**: Django app responsible for managing and serving dictionary word data and user-saved words. (Contains models, views, serializers for word data).
*   **`fadeu/`**: Main Django project directory containing settings (`settings.py`), main URL configuration (`urls.py`), and WSGI/ASGI configurations.
    *   `database_routers.py`: Contains logic for routing database queries to the appropriate database (default or dictionary).

## Setup and Run

1.  **Prerequisites:**
    *   Python 3.x installed.
    *   `pip` (Python package installer).
2.  **Clone the Repository:**
    ```bash
    git clone <repository_url>
    cd fadeuBackend
    ```
3.  **Create a Virtual Environment (Recommended):**
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```
4.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    # Note: A requirements.txt file would need to be generated: pip freeze > requirements.txt
    # Common dependencies would include: Django, djangorestframework, djangorestframework-simplejwt, PyMySQL (if using MySQL), psycopg2-binary (if using PostgreSQL)
    ```
5.  **Database Setup:**
    *   The project is configured to use SQLite by default for both the main application data and the dictionary.
    *   The `dictionary.db` file should be present in the `fadeuBackend/fadeu/` directory.
    *   Apply migrations:
        ```bash
        python manage.py makemigrations
        python manage.py migrate
        python manage.py migrate --database=dictionary # If dictionary app has its own migrations
        ```
6.  **Create Superuser (Optional):**
    ```bash
    python manage.py createsuperuser
    ```
7.  **Run the Development Server:**
    ```bash
    python manage.py runserver
    ```
    The backend API will typically be available at `http://127.0.0.1:8000/`.

## Important Notes

*   Ensure the `dictionary.db` file is correctly placed for the dictionary functionality.
*   The `SECRET_KEY` in `settings.py` should be kept secret in a production environment.
*   `DEBUG` mode should be turned off in production.
*   CORS (Cross-Origin Resource Sharing) is currently set to allow all origins (`CORS_ALLOW_ALL_ORIGINS = True`), which is suitable for development but should be configured more restrictively for production.
