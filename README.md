# Nexora App - Wildlife Identification & Rescue Network

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.0.0-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-green.svg)

> **Nexora** is a specialized smartphone application built with Flutter to facilitate wildlife (specifically snake) identification and emergency rescue services. The application bridges the gap between the general public and expert snake enthusiasts/rescuers by integrating real-time location mapping and an AI-powered snake classification model.

---

## 📖 Table of Contents
1. [Core Features](#1-core-features)
2. [Technology Stack](#2-technology-stack)
3. [Application Architecture](#3-application-architecture)
4. [Backend API Integrations](#4-backend-api-integrations)
5. [Deep Dive: Complex Implementations](#5-deep-dive-complex-implementations)
6. [Installation & Setup](#6-installation--setup)
7. [Environment Requirements](#7-environment-requirements)

---

## 1. Core Features

### 🧍 General Public Dashboard
*   **AI Identification Scanner**: Take a photo of a snake to identify its species, toxicity/venom level, and biological characteristics.
*   **Report Incidents**: Form-based reporting of local snake sightings or bites (includes geo-tagging).
*   **Emergency Services**: Direct dialing to national emergency lines (e.g., `1990`).
*   **Educational Collection**: Browse standard encyclopedic data about local snakes.

### 🐍 Enthusiast / Rescuer Dashboard
*   **Status Toggling**: Rescuers can mark themselves "Online" to be discoverable by the public and admin dispatch grids.
*   **Live Broadcasts**: The app quietly pushes the rescuer's GPS coordinates to the server at regular intervals so they appear on live maps.
*   **Active Requests Map**: Integrates `flutter_map` with real-time location markers showing pending emergency help requests nearby.
*   **Catch Reports**: Submit detailed reports post-rescue to maintain environmental records.

### 🌍 Application-Wide Features
*   **Multi-language Support**: Fully localized in English, Sinhala, and Tamil via a blazing fast singleton dictionary (`lib/services/language_service.dart`).
*   **Role-Based Access Control (RBAC)**: App layout drastically shifts out of the login screen based on the returned JWT Token's defined user role.

---

## 2. Technology Stack
The application is purely developed using the **Flutter Framework** (Dart).

| Category | Primary Packages |
| :--- | :--- |
| **Networking** | `dio` (Robust HTTP client for multipart data & headers) |
| **Maps & Location** | `flutter_map`, `geolocator`, `location`, `latlong2` |
| **Local Storage** | `shared_preferences` (For JWT tokens, Language states) |
| **Device Hardware** | `camera`, `image_picker` (For AI scans) |
| **External Linking** | `url_launcher` (Dial pad & Maps routing) |
| **UI Formatting** | `font_awesome_flutter`, `cupertino_icons` |

---

## 3. Application Architecture

The Flutter lib directory (`lib/`) relies on a robust separation of concerns, dividing reusable UI grids from complex global services.

```text
lib/
├── main.dart                 # Global routing, PopScope back-interceptors, initialization
├── screens/
│   ├── Auth Screens          # login_screen.dart, signup_screen.dart, forgot_password_screen.dart
│   ├── User Flow             # user_home_screen.dart, report_incident_screen.dart
│   ├── Enthusiast Flow       # enthusiast_home_screen.dart, enthusiast_dashboard_tab.dart
│   ├── Maps & Tracking       # map_screen.dart, nearby_rescuers_screen.dart
│   ├── AI Scanners           # scan_screen.dart, scan_warning_screen.dart, id_result_screen.dart
│   └── Profile & Settings    # profile_screen.dart, enthusiast_profile_screen.dart
├── services/
│   ├── auth_service.dart     # Handles token mgmt and login APIs
│   ├── nexora_api_service.dart# Abstracted Laravel interactions (Incidents, Markers, Enthusiasts)
│   ├── location_service.dart # Hardened GPS fetching with 3-tier fallback logic
│   └── language_service.dart # Local dictionary lookup mapping (_t('key'))
├── widgets/                  # Reusable form fields, cards, layout builders
└── theme/                    # Color palettes (Dark/Neon variants)
```

---

## 4. Backend API Integrations

Nexora concurrently relies on two entirely distinct backends:

### A. The Core Application Database (Laravel Web Server)
*   **Base URL**: `https://nexora.wisegen.lk/api`
*   **Role**: Handles user authentication, incident logs, mapping records, and active expert locations.
*   **Authentication**: JSON Web Tokens (`Bearer {token}`).
*   *Key Endpoints*:
    *   `/login`, `/register`, `/auth/profile`
    *   `/incidents` (Handles general reporting)
    *   `/experts/location` (Receives continuous array pulses of Lat/Lng variables from rescuers).
    *   `/enthusiasts` (Spits out online rescuer coordinates for map plotting).

### B. The AI Classification Model (Python / Azure)
*   **Base URL**: `https://snake-api-eshan123.azurewebsites.net/predict`
*   **Role**: A Python CNN Softmax backend dedicated explicitly to image classification. It receives `multipart/form-data` images and returns string labels (`species`) and percentage integers (`snake_prob`, `confidence`).

---

## 5. Deep Dive: Complex Implementations

### AI Filtering & Conditional Routing
The backend AI returns three defining parameters: `status`, `snake_prob` (probability that a snake is actually in the picture), and `confidence` (identification certainty). 

The app strictly handles these to prevent hallucinations:
1.  **Image Rejected**: If the Python wrapper states `status: "REJECTED"`, the user is routed to `ScanWarningScreen` explaining that the image is unreadable.
2.  **No Snake Detected**: If `snake_prob < 0.70`, the user hits `ScanWarningScreen` with a UI alert: *"No snake detected in this image"*.
3.  **Low Confidence ID**: If `confidence < 0.80`, the snake is identified in `IDResultScreen`, but a prominent HTML-red warning banner flags it to the user.

### 3-Tier Location Fallback Architecture
Fetching live coordinates on Android/iOS drops frequently. `LocationService.getCurrentLocation()` uses a rigorous fallback:
1.  Tries to get a fresh lock using `Geolocator.getCurrentPosition`.
2.  If the signal spins out (timeout), fallback to `Geolocator.getLastKnownPosition()`.
3.  If no known position is on cache, fallback to `SharedPreferences` saved coordinates.

### Map Silent Background Polling
Rather than flashing endless loading spinners on the `flutter_map`, `MapScreen` uses deep `dart:async` timers.
`_silentRefresh()` triggers a background API hit to `NexoraApiService` every 30 seconds. If marker counts change, `setState()` gently updates the map pins without clearing the map viewport or dragging the user to the center.

### PopScope Navigation Locking
To mimic sophisticated hardware overrides, `main.dart` and the home screen dashboards implement strictly handled `PopScopes` and `automaticallyImplyLeading: false`. This ensures that native back-swipes correctly cycle *bottom navigation tab indices*, rather than erroneously popping the entire app stack to the `/login` route.

---

## 6. Installation & Setup

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/Ravi0518/nexora_app.git
    cd nexora_app
    ```

2.  **Install Dependencies**
    ```bash
    flutter clean
    flutter pub get
    ```

3.  **Run the Application locally**
    Ensure an emulator is running or a device is attached.
    ```bash
    flutter run
    ```

4.  **Build a Release APK**
    ```bash
    flutter build apk --release
    ```
    Output will be available at: `build/app/outputs/flutter-apk/app-release.apk`

## 7. Environment Requirements
- **Flutter SDK**: `>=3.0.0 <4.0.0`
- **Internet Requirements**: Active cellular data or WiFi is strict for Map Tile loading, Authentication, and POSTing AI queries to the Azure backend.
- **Hardware Profile**: Application requires runtime logic permissions for both **Location** and **Camera**. 

---
_Documentation automatically generated for Nexora App Development v1.0.0_
