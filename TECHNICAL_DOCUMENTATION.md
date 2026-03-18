# Nexora App - Technical Documentation

## 1. Project Overview
**Nexora** is a specialized smartphone application built with Flutter to facilitate snake identification and emergency snake rescue services. The application bridges the gap between the general public and expert snake enthusiasts/rescuers. It integrates real-time location tracking for emergency responders and an AI-powered snake classification model to identify snake species from user-uploaded images.

## 2. Technology Stack & Dependencies
The app is built using the **Flutter Framework** using Dart. 

### Core Dependencies (Pubspec)
*   **Networking**: `dio` (for robust API requests)
*   **Location & Maps**: 
    *   `flutter_map` (for rendering OpenStreetMap tiles)
    *   `geolocator` & `location` (for handling GPS coordinates and device permissions)
    *   `latlong2` (for map coordinates)
    *   `url_launcher` (to launch turn-by-turn Google Maps and phone dialers)
*   **Device Interactions**:
    *   `camera` & `image_picker` (for capturing snake photos for AI identification)
*   **State & Storage**:
    *   `shared_preferences` (for persisting user sessions, JWT tokens, and language preferences locally)
*   **UI & Styling**:
    *   `cupertino_icons`, `font_awesome_flutter`
    *   `flutter_native_splash` (for theming the app boot screen)

## 3. Core Features & Technical Implementation

### A. AI Snake Identification Loop
The app allows users to scan environments or upload photos to identify snake species.
1. **Capture/Upload**: Handled via `camera` and `image_picker` in `scan_screen.dart`.
2. **API Push**: Image is sent as multipart/form-data using `Dio` to a dedicated Python Azure backend (`https://snake-api-eshan123.azurewebsites.net/predict`).
3. **Response Parsing**:
    *   **Rejected Images**: The API returns a `status: "REJECTED"` flag if the image does not contain a snake or is unreadable. Handled by `scan_warning_screen.dart`.
    *   **Low Probability**: If `snake_prob < 0.70`, the app routes to a warning screen.
    *   **Low Confidence**: If a snake is identified but `confidence < 0.80`, `id_result_screen.dart` surfaces a UI warning banner.
    *   **Success**: Displays snake species, characteristics, and venomous status queried from local dataset or backend DB.

### B. Real-time Incident Mapping & Enthusiast Tracking
Crucial for the "Rescue" aspect of the app.
*   **Background Location Sync**: `location_service.dart` handles complex 3-tier fallback logic for fetching coordinates (GPS -> Last Known Location -> Cached Location). 
*   **Enthusiast Pushing**: When an Enthusiast marks themselves "Available" in `enthusiast_dashboard_tab.dart`, their live GPS coordinates are repeatedly pushed to the `/api/experts/location` backend endpoint.
*   **Live Map Polling**: The `map_screen.dart` implements a silent timer (`_silentRefresh`) that polls the backend every 30 seconds to fetch and plot updated JSON arrays of Enthusiast markers and Active Incidents on the `flutter_map`.

### C. Role-Based Access Control (RBAC)
The app dynamically shifts its UI layout and permissions based on user role (`General Public` vs `Enthusiast` vs `Admin`), stored inside `shared_preferences`.
*   **General Public**: Access to AI scanning, reporting incidents, and emergency dialers.
*   **Enthusiasts**: Access to private dashboards allowing them to toggle availability, view active "Help Requests" pinned to the map, and intercept incident reports.

### D. Multi-language Support (Localization)
Implemented via a custom dictionary singleton in `language_service.dart`.
*   Supports **English**, **Sinhala**, and **Tamil**.
*   The entire app's string resources are wrapped in `_t('key')` helper functions that parse translations on the fly without heavy external i18n libraries.

---

## 4. Software Architecture & Directory Structure

```text
lib/
├── main.dart (Global routing, PopScope back-interceptors, Auth gates)
├── screens/
│   ├── login_screen.dart / signup_screen.dart (Authentication)
│   ├── user_home_screen.dart (Public Dashboard UI)
│   ├── enthusiast_home_screen.dart (Rescuer Dashboard UI w/ Drawer)
│   ├── map_screen.dart (flutter_map implementation w/ markers)
│   ├── scan_screen.dart / id_result_screen.dart / scan_warning_screen.dart
│   ├── report_incident_screen.dart (Multipart incident uploading)
│   └── profile_screen.dart / enthusiast_profile_screen.dart
├── services/
│   ├── auth_service.dart (Login API binds, token management)
│   ├── nexora_api_service.dart (Primary Laravel resource abstraction)
│   ├── location_service.dart (GPS lifecycle and permissions)
│   └── language_service.dart (Localization dictionary)
├── widgets/ (Reusable UI components)
└── theme/ (App-wide color palettes and typography)
```

## 5. Backend Integrations

Nexora talks to two primary backends:
1.  **Main Laravel API (`https://nexora.wisegen.lk/api`)**:
    *   JWT-based Authentication (`Bearer {token}`).
    *   `/login`, `/register`, `/auth/profile`
    *   `/incidents` (POST for reporting, GET for nearby mapping)
    *   `/experts/location` (POST hardware GPS arrays)
    *   `/enthusiasts` (GET nearest online rescuers)
2.  **AI Python Backend (`...azurewebsites.net/predict`)**:
    *   Strictly accepts images and returns CNN Softmax probabilities.

## 6. Technical Workarounds & Known Patterns
*   **Navigation Interceptors**: The app actively strips Flutter auto-generated back buttons (`automaticallyImplyLeading: false`) and wraps Scaffolds in `PopScope` to ensure nested bottom-tab navigators (`IndexedStack`) don't accidentally pop the entire app route and mimicking a "logout".
*   **Exception Swallowing on Map UI**: To prevent jarring loader spinners, map polling exceptions are intentionally suppressed and silently retried in the background using asynchronous `Timer.periodic`.
