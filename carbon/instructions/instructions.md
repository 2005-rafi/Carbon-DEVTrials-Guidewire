# CARBON APPLICATION  
## ADVANCED FRONTEND ARCHITECTURE DOCUMENTATION  
### (CENTRALIZED CONTROL, API MAPPING, NAVIGATION FLOW)

---

# 1. CENTRALIZED COLOR CONTROL ARCHITECTURE

---

## 1.1 PURPOSE

Centralized color control ensures:

- UI consistency across all screens
- Easy theme switching (light/dark)
- Maintainability and scalability
- Elimination of hardcoded styling

---

## 1.2 ARCHITECTURAL APPROACH

All UI styling must be derived from a **single source of truth**:

```text
Theme Layer → ColorScheme → UI Components
````

---

## 1.3 COLOR SYSTEM DESIGN

| Color Type | Responsibility                        |
| ---------- | ------------------------------------- |
| Primary    | Main actions (login, accept, payouts) |
| Secondary  | Alternate actions (filter, edit)      |
| Tertiary   | Helper elements (labels, timestamps)  |
| Surface    | Screen background                     |
| Container  | Cards, grouped UI sections            |

---

## 1.4 USAGE ACROSS SCREENS

| Screen           | Primary Usage                  |
| ---------------- | ------------------------------ |
| Login / Register | Buttons, input highlights      |
| Dashboard        | KPI highlights, action buttons |
| Policy           | Accept button                  |
| Claims           | Status indicators              |
| Payout           | Financial actions              |
| Events           | Severity indicators            |
| Notifications    | Unread indicators              |
| Analytics        | Charts and highlights          |
| Settings         | Toggles and save actions       |

---

## 1.5 KEY PRINCIPLES

* No direct color usage in widgets
* All colors accessed via centralized theme
* Dynamic theme switching supported
* Typography also centralized

---

# 2. CENTRALIZED API ENDPOINT CONTROL

---

## 2.1 PURPOSE

Centralizing API endpoints ensures:

* Clean integration with backend microservices
* Easy environment switching (dev/prod)
* Maintainability and debugging simplicity

---

## 2.2 ARCHITECTURE

```text
API Config Layer
    ↓
Service Layer (API Calls)
    ↓
State Management (Riverpod)
    ↓
UI Screens
```

---

## 2.3 API GATEWAY ENTRY POINT

All frontend requests should ideally pass through:

* **API Gateway** → Port 8001 

This abstracts microservices and provides:

* Unified access
* Security enforcement
* Routing logic

---

## 2.4 CORE MICROSERVICE ENDPOINTS

| Service              | Port | Responsibility    |
| -------------------- | ---- | ----------------- |
| Identity Service     | 8005 | Authentication    |
| Policy Service       | 8004 | Policy management |
| AI Risk Service      | 8003 | Risk scoring      |
| Trigger Service      | 8008 | Event detection   |
| Claims Service       | 8009 | Claims processing |
| Fraud Service        | 8010 | Fraud validation  |
| Payout Service       | 8007 | Payments          |
| Notification Service | 8006 | Notifications     |
| Analytics Service    | 8011 | Insights          |



---

# 3. SCREEN → API ENDPOINT MAPPING

---

## 3.1 AUTHENTICATION SCREENS

### Login / Registration / OTP

**Services Used:**

* Identity Service (8005)

**Endpoints (Conceptual):**

* `/auth/login`
* `/auth/register`
* `/auth/verify-otp`

---

## 3.2 DASHBOARD SCREEN

**Services Used:**

* Analytics Service (8011)
* Policy Service (8004)
* Claims Service (8009)
* Payout Service (8007)

**Data Fetched:**

* User summary
* Claims count
* Earnings overview

---

## 3.3 POLICY SCREEN

**Services Used:**

* Policy Service (8004)

**Endpoints:**

* `/policy/details`
* `/policy/accept`

---

## 3.4 CLAIMS SCREEN

**Services Used:**

* Claims Service (8009)
* Fraud Service (8010)

**Endpoints:**

* `/claims/list`
* `/claims/details`

---

## 3.5 PAYOUT SCREEN

**Services Used:**

* Payout Service (8007)

**Endpoints:**

* `/payout/history`
* `/payout/status`

---

## 3.6 EVENTS / DISRUPTIONS SCREEN

**Services Used:**

* Trigger Service (8008)
* AI Risk Service (8003)

**Endpoints:**

* `/events/list`
* `/events/severity`

---

## 3.7 NOTIFICATIONS SCREEN

**Services Used:**

* Notification Service (8006)

**Endpoints:**

* `/notifications`
* `/notifications/mark-read`

---

## 3.8 ANALYTICS SCREEN

**Services Used:**

* Analytics Service (8011)

**Endpoints:**

* `/analytics/summary`
* `/analytics/trends`

---

## 3.9 SETTINGS SCREEN

**Services Used:**

* Identity Service (8005)
* Notification Service (8006)

**Endpoints:**

* `/user/preferences`
* `/user/update-settings`

---

# 4. COMPLETE NAVIGATION ARCHITECTURE

---

## 4.1 HIGH-LEVEL FLOW

```text
Splash
  ↓
Authentication Layer
  ├── Login
  ├── Register
  └── OTP
  ↓
Dashboard (Home)
  ↓
Drawer Navigation System [No bottom navigation]
  ├── Policy
  ├── Claims
  ├── Payout
  ├── Events
  ├── Analytics
  ├── Notifications
  └── Settings
```

---

## 4.2 NAVIGATION LAYERS

---

### Layer 1: Entry Flow

```text
Splash → Auth Check → Login/Register → Dashboard
```

---

### Layer 2: Core Navigation

* Controlled via **DrawerNavigationBar**
* Index-based switching (no stacking)

---

### Layer 3: Deep Navigation

```text
Claims → Claim Details  
Payout → Transaction Details  
Events → Event Details  
Analytics → Insight Drill-down  
```

---

# 5. NAVIGATION WIRING ARCHITECTURE

---

## 5.1 CENTRALIZED ROUTING

```text
Route Manager
    ↓
Named Routes
    ↓
Navigation Controller
```

---

## 5.2 NAVIGATION PRINCIPLES

* Use **replacement navigation** for core screens
* Avoid push stacking
* Maintain single instance per screen

---

## 5.3 Drawer NAVIGATION BEHAVIOR

* Persistent across core screens
* Index-based navigation
* Stateless switching between screens

---

## 5.4 BACK BUTTON HANDLING

---

### Case 1: Core Screens

```text
Any Screen [except auth and splash screens] → Back → Dashboard
```

---

### Case 2: Dashboard

```text
Dashboard → Back → Exit Confirmation Dialog
```

---

### Case 3: Deep Screens

```text
Details Screen → Back → Parent Screen
```

---

## 5.5 NAVIGATION FLOW EXAMPLE

```text
Login → Dashboard
       ↓
   Claims Tab
       ↓
   Claim Details
       ↓
   Back → Claims
       ↓
   Back → Dashboard
```

---

# 6. STATE + NAVIGATION + API INTEGRATION

---

## 6.1 COMPLETE FLOW

```text
User Action
   ↓
UI Interaction
   ↓
Riverpod State Provider
   ↓
Service Layer (API Call)
   ↓
API Gateway
   ↓
Microservice
   ↓
Response
   ↓
State Update
   ↓
UI Rebuild
```

---

## 6.2 RESPONSIBILITY SEPARATION

| Layer      | Responsibility    |
| ---------- | ----------------- |
| UI         | Rendering         |
| State      | Data management   |
| Service    | API communication |
| API Config | Endpoint control  |

---

# 7. END-TO-END USER FLOW WITH API + NAVIGATION

---

```text
App Launch
  ↓
Splash (Initialization)
  ↓
Login (Identity API)
  ↓
Dashboard (Analytics + Policy + Claims APIs)
  ↓
User taps Claims
  ↓
Claims Screen (Claims API)
  ↓
User taps Claim
  ↓
Claim Details
  ↓
System triggers payout (backend)
  ↓
User views Payout Screen (Payout API)
```

---

# 8. VALIDATION OF ARCHITECTURE

---

## 8.1 USER NEEDS VS SYSTEM DESIGN

| User Need         | Implementation           |
| ----------------- | ------------------------ |
| Easy navigation   | Drawer navigation        |
| No complexity     | Centralized APIs         |
| Transparency      | Events + Claims + Payout |
| Real-time updates | Notification + Analytics |

---

## 8.2 SYSTEM STRENGTHS

* Fully modular frontend
* Clean API abstraction
* Scalable navigation system
* Centralized configuration

---

# 9. FINAL ARCHITECTURAL SUMMARY

---

The Carbon frontend architecture is built on:

---

## Core Pillars

1. **Centralized Theme System**
2. **Centralized API Gateway Integration**
3. **Clean Navigation Architecture**
4. **Modular Screen Design**
5. **Event-Driven Data Flow**

---

## Final Insight

> The frontend is not just a UI layer —
> it is a **structured visualization system** that translates complex backend automation
> into **simple, understandable user experiences**.

---