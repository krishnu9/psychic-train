# GymApp 🏋️‍♂️

A comprehensive, offline-first workout tracking application built with Flutter, designed specifically for strength training.

## Features

*   **Offline-First Architecture**: Built with [Drift](https://drift.simonbinder.eu/) for robust local database storage. Your workout data is always accessible, even without an internet connection.
*   **Routine Management**: Create and fully customize workout routines. Add exercises, and specify default weights, sets, and repetitions.
*   **Active Workout Tracking**: Start an active workout, record your sets dynamically, and track your progress in real-time. Includes an option to cancel an active workout.
*   **Exercise Selection**: Browse and filter exercises effortlessly (e.g., Legs, Chest, Back) with last-filter memory.
*   **Cloud Synchronization**: Integrated with [Supabase](https://supabase.com/) for secure authentication, user profiles, and seamless data sync across devices.
*   **Web Support**: Deployable to Firebase Hosting as a web application.

## Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`, `riverpod_annotation`)
*   **Local Database**: [Drift](https://drift.simonbinder.eu/) (SQLite)
*   **Backend & Auth**: [Supabase](https://supabase.com/) (`supabase_flutter`)
*   **Code Generation**: `build_runner`, `drift_dev`

## Getting Started

### Prerequisites

*   Flutter SDK (^3.11.1 or higher)
*   A Supabase project (for Authentication & Cloud Sync)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd gymapp
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate data models and providers:**
    Because the app relies heavily on Riverpod and Drift for generated code, you must run `build_runner`.
    ```bash
    dart run build_runner build -d
    ```

4.  **Environment Setup:**
    The project uses `flutter_dotenv` for environment variables. Create a `.env` file in the root directory of the project and add your Supabase credentials:
    ```env
    SUPABASE_URL=your_supabase_url_here
    SUPABASE_ANON_KEY=your_supabase_anon_key_here
    ```
    *Ensure the `.env` file is included in your `pubspec.yaml` assets section (it already is configured).*

5.  **Run the App:**
    ```bash
    # To run on the default connected device/emulator
    flutter run

    # To run specifically on web
    flutter run -d chrome
    ```

## Testing

The project includes unit tests for repositories, providers, widget tests, and drift local database tests.

To manually run the entire test suite:
```bash
flutter test
```

## Code Quality

Make sure to format your code and check for any lint errors before pushing:
```bash
flutter analyze
```
