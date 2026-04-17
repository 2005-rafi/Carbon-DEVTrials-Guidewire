# CARBON FLUTTER APPLICATION  
## FINAL PRODUCTION-GRADE FOLDER STRUCTURE (OPTIMIZED, CLEAN, SCALABLE)

This structure is **refined for production**, ensuring:

- Strict separation of concerns
- Centralized control (API, Theme, Navigation)
- Feature-first scalability
- Clean Riverpod integration
- Minimal complexity with maximum clarity

---

# 1. FINAL ARCHITECTURE OVERVIEW

```text
lib/
│
├── core/                              # GLOBAL FOUNDATION (STRICTLY SHARED)
│
│   ├── config/                        # Environment & app configuration
│   │   ├── app_config.dart
│   │   └── env.dart
│   │
│   ├── network/                       # CENTRALIZED API LAYER
│   │   ├── api_client.dart            # HTTP client (Dio)
│   │   ├── api_config.dart            # base URL, headers
│   │   ├── api_endpoints.dart         # ALL endpoints (single source)
│   │   ├── interceptors.dart          # auth, logging, retry
│   │   └── api_exception.dart         # error handling
│   │
│   ├── theme/                         # CENTRALIZED THEME SYSTEM
│   │   ├── app_theme.dart
│   │   ├── color_schemes.dart
│   │   ├── text_theme.dart
│   │   └── theme_provider.dart
│   │
│   ├── router/                        # CENTRALIZED NAVIGATION
│   │   ├── app_router.dart            # route configuration
│   │   ├── route_names.dart
│   │   └── navigation_service.dart    # global navigation control
│   │
│   ├── providers/                     # GLOBAL STATE (RIVERPOD)
│   │   ├── app_provider.dart
│   │   ├── auth_provider.dart
│   │   ├── network_provider.dart
│   │   └── connectivity_provider.dart
│   │
│   ├── constants/                     # STATIC VALUES
│   │   └── app_constants.dart
│   │
│   └── utils/                         # PURE HELPERS
│       ├── helpers.dart
│       ├── validators.dart
│       └── formatters.dart
│
├── features/                          # FEATURE-FIRST ARCHITECTURE
│
│   ├── splash/
│   │   └── presentation/
│   │       └── splash_screen.dart
│
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_api.dart
│   │   │   └── auth_models.dart
│   │   │
│   │   ├── provider/
│   │   │   └── auth_feature_provider.dart
│   │   │
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── otp_screen.dart
│
│   ├── dashboard/
│   │   ├── data/
│   │   │   └── dashboard_api.dart
│   │   │
│   │   ├── provider/
│   │   │   └── dashboard_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── dashboard_screen.dart
│
│   ├── policy/
│   │   ├── data/
│   │   │   ├── policy_api.dart
│   │   │   └── policy_models.dart
│   │   │
│   │   ├── provider/
│   │   │   └── policy_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── policy_screen.dart
│
│   ├── claims/
│   │   ├── data/
│   │   │   ├── claims_api.dart
│   │   │   └── claims_models.dart
│   │   │
│   │   ├── provider/
│   │   │   └── claims_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── claims_screen.dart
│
│   ├── payout/
│   │   ├── data/
│   │   │   ├── payout_api.dart
│   │   │   └── payout_models.dart
│   │   │
│   │   ├── provider/
│   │   │   └── payout_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── payout_screen.dart
│
│   ├── events/
│   │   ├── data/
│   │   │   ├── events_api.dart
│   │   │   └── events_models.dart
│   │   │
│   │   ├── provider/
│   │   │   └── events_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── events_screen.dart
│
│   ├── notifications/
│   │   ├── data/
│   │   │   ├── notification_api.dart
│   │   │   └── notification_models.dart
│   │   │
│   │   ├── provider/
│   │   │   └── notification_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── notification_screen.dart
│
│   ├── analytics/
│   │   ├── data/
│   │   │   ├── analytics_api.dart
│   │   │   └── analytics_models.dart
│   │   │
│   │   ├── provider/
│   │   │   └── analytics_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── analytics_screen.dart
│
│   ├── settings/
│   │   ├── data/
│   │   │   └── settings_api.dart
│   │   │
│   │   ├── provider/
│   │   │   └── settings_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── settings_screen.dart
│
│   ├── profile/
│   │   ├── data/
│   │   │   └── profile_api.dart
│   │   │
│   │   ├── provider/
│   │   │   └── profile_provider.dart
│   │   │
│   │   └── presentation/
│   │       └── profile_screen.dart
│
├── shared/                            # PURE REUSABLE LAYER
│
│   ├── widgets/
│   │   ├── app_button.dart
│   │   ├── app_card.dart
│   │   ├── app_loader.dart
│   │   ├── app_textfield.dart
│   │   ├── app_appbar.dart
│   │   ├── app_snackbar.dart
│   │   └── app_dialog.dart
│   │
│   ├── extensions/
│   │   └── context_extensions.dart
│   │
│   └── models/
│       └── common_models.dart
│
├── app.dart                           # App root widget (MaterialApp)
├── main.dart                          # Entry point
````

---

# 2. KEY IMPROVEMENTS OVER PREVIOUS STRUCTURE

---

## 2.1 COMPLETE FEATURE COVERAGE

Added missing production features:

* Splash
* Events (Disruptions)
* Notifications
* Analytics
* Settings

---

## 2.2 STRONG DATA LAYER SEPARATION

Each feature now includes:

* API layer (`*_api.dart`)
* Models (`*_models.dart`)
* Provider (state)
* Presentation (UI)

This ensures:

* Clean architecture
* Testability
* Scalability

---

## 2.3 CENTRALIZED CONTROL (STRICT ENFORCEMENT)

---

### API Control

* `core/network/api_endpoints.dart`
* Single source of truth

---

### Theme Control

* `core/theme/*`
* Fully dynamic theme system

---

### Navigation Control

* `core/router/app_router.dart`
* `navigation_service.dart` added for:

  * Global navigation
  * Decoupled routing

---

### State Management

* Riverpod fully integrated:

  * Global providers (core)
  * Feature providers (isolated)

---

## 2.4 SHARED LAYER IMPROVEMENTS

Added:

* `app_appbar.dart`
* `app_dialog.dart`
* `app_snackbar.dart`
* Extensions for cleaner UI code

---

## 2.5 SCALABILITY DESIGN

---

### Feature Isolation

Each feature is:

* Independent
* Replaceable
* Expandable

---

### Easy Additions

Future features can be added as:

```text
features/new_feature/
  ├── data/
  ├── provider/
  └── presentation/
```

---

# 3. ARCHITECTURAL RULES (STRICT)

---

## 3.1 CORE RULES

* Core layer must NEVER depend on features
* Features can depend on core
* Shared must be UI-only (no business logic)

---

## 3.2 API RULES

* No direct API calls in UI
* All APIs must go through:
  → feature API → core network

---

## 3.3 STATE RULES

* UI → Provider → API
* No direct API calls from UI

---

## 3.4 NAVIGATION RULES

* All routes defined in `app_router.dart`
* No inline navigation logic in widgets
* Use centralized navigation service

---

# 4. FINAL ARCHITECTURAL BENEFITS

---

## 4.1 CLEANNESS

* No duplication
* Clear separation of concerns

---

## 4.2 SCALABILITY

* Easily extendable to:

  * Admin panel
  * New features
  * New services

---

## 4.3 MAINTAINABILITY

* Easy debugging
* Clear structure
* Predictable data flow

---

## 4.4 PRODUCTION READINESS

* Fully modular
* API centralized
* Theme centralized
* Navigation centralized

---

# 5. FINAL SUMMARY

---

This structure ensures:

* Clean Flutter architecture
* Strong microservice alignment
* Centralized control systems
* Scalable feature-first design

---

## Final Insight

> This is a production-grade architecture designed not just to build the app,
> but to **scale, maintain, and evolve it without architectural debt**.

---
