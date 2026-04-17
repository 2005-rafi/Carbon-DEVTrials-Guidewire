ṇ# Carbon Mobile Knowledge Dump (Updated: 2026-04-05)

## Scope of this knowledge dump
This document captures implementation details discovered while auditing:

- AppBar
- Drawer
- Bottom Navigation bar
- Reusable patterns vs repeated implementation across screens

It also records architecture observations and concrete refactor opportunities.

---

## 1) Navigation and layout architecture (current state)

### 1.1 Central routing
- All app routes are declared in `lib/core/router/app_router.dart`.
- Route string constants are in `lib/core/router/route_names.dart`.
- Global navigation is done through `NavigationService` (`lib/core/router/navigation_service.dart`) using:
	- `pushNamed`
	- `pushReplacementNamed`
	- `pushNamedAndRemoveUntil`

### 1.2 Shell pattern used in most core feature screens
- `CoreScaffold` (`lib/shared/widgets/core_scaffold.dart`) wraps common structure:
	- `AppAppBar`
	- `AppDrawer`
	- `SafeArea(body)`
	- optional `bottomNavigationBar`
	- back-button handling via `PopScope`

### 1.3 Screen groups by scaffold strategy

CoreScaffold screens:
- Dashboard
- Policy
- Claims
- Payout
- Events
- Analytics
- Notifications
- Profile
- Settings

Standalone Scaffold screens:
- Splash
- Login
- Register
- OTP

Implication:
- Core product area uses a shared shell.
- Auth and splash flows are isolated and intentionally do not share drawer/nav shell.

---

## 2) AppBar implementation details

### 2.1 Reusable AppBar wrapper
- `AppAppBar` (`lib/shared/widgets/app_appbar.dart`) is a thin wrapper around Flutter `AppBar`.
- Inputs:
	- `title`
	- optional `actions`
- Used directly by `CoreScaffold`, so all CoreScaffold screens inherit it.

### 2.2 How AppBar is used by screen category

CoreScaffold screens:
- Automatically get `AppAppBar(title, actions)` from CoreScaffold.
- Each screen supplies screen-specific `appBarActions`.

OTP screen:
- Uses `AppAppBar` directly with title `Verify OTP`.

Register screen:
- Uses a custom inline `AppBar` (not AppAppBar) to implement special auth back behavior while loading.

Login and Splash:
- No app bar.

### 2.3 Reuse assessment for AppBar
- Good reuse at shell level (CoreScaffold + AppAppBar).
- Partial divergence in auth screens (intentional UX differences).
- AppAppBar itself is minimal; styling mostly comes from global theme and per-screen actions.

---

## 3) Drawer implementation details

### 3.1 Single reusable drawer component
- `AppDrawer` is defined in `lib/shared/widgets/app_drawer.dart`.
- It is injected only once by `CoreScaffold` using `drawer: AppDrawer(currentRoute: currentRoute)`.

### 3.2 Drawer menu model
- Drawer uses an internal static list `_items` of `_DrawerItem(label, routeName, icon)`.
- Includes routes:
	- Dashboard, Policy, Claims, Payout, Events, Analytics, Notifications, Profile, Settings
- Active item highlighting is based on route equality with `currentRoute`.

### 3.3 Drawer navigation behavior
- On item tap:
	- closes drawer
	- if same route, no-op
	- otherwise `pushReplacementNamed(item.routeName)`
- Logout tile:
	- navigates to login with `pushNamedAndRemoveUntil(..., (route) => false)`

### 3.4 Reuse assessment for Drawer
- Excellent reuse.
- No duplicated drawer code in feature screens.
- Route list is centralized in one location and easy to maintain.

---

## 4) Bottom Navigation bar implementation details

### 4.1 Where bottom nav appears
Bottom nav is passed into CoreScaffold manually per screen. It appears in:

- Dashboard
- Claims
- Payout
- Events
- Analytics
- Notifications
- Settings

No bottom nav in:
- Policy
- Profile
- Splash
- Login
- Register
- OTP

### 4.2 Implementation pattern per bottom-nav screen
Each screen independently defines:

- `int _selectedNavIndex = 1;`
- `_openCoreRoute(String routeName)` helper
- `_onBottomNavTap(int index)` switch mapping
- inline `NavigationBar` widget with const `NavigationDestination` list

### 4.3 Observed bottom-nav design pattern
- The currently active feature is usually the second tab (index 1).
- Tab 0 is labeled `Home` and often routes to Dashboard.
- Remaining tabs are feature shortcuts and vary by screen context.

### 4.4 Reuse assessment for BottomNavigationBar
- Functionally consistent, but implementation is duplicated.
- The same structure and control flow are re-authored in each screen.
- Destination lists are similar but not centralized.

---

## 5) Reusable code vs repeated code (direct answer)

### 5.1 Reusable code that is already in place
- Reusable shell scaffold: `CoreScaffold`
- Reusable app bar wrapper: `AppAppBar`
- Reusable drawer: `AppDrawer`
- Reusable global route constants: `RouteNames`
- Reusable global navigation API: `NavigationService`

### 5.2 Repeated development currently present
- Bottom nav state and tap-routing logic repeated across multiple feature screens.
- Bottom nav destination declarations repeated across screens.
- Similar `_openCoreRoute` helper repeated per screen.

### 5.3 Additional architectural signal found
- `CoreRoutes` in `route_names.dart` defines an ordered list + `indexOf(...)`, but it is currently unused.
- This looks like groundwork for centralized nav indexing that was not completed.

---

## 6) Screen-by-screen quick matrix

| Screen | AppBar source | Drawer | Bottom Nav |
|---|---|---|---|
| Splash | none | no | no |
| Login | none | no | no |
| Register | inline custom AppBar | no | no |
| OTP | AppAppBar direct | no | no |
| Dashboard | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | yes (local implementation) |
| Policy | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | no |
| Claims | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | yes (local implementation) |
| Payout | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | yes (local implementation) |
| Events | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | yes (local implementation) |
| Analytics | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | yes (local implementation) |
| Notifications | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | yes (local implementation) |
| Profile | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | no |
| Settings | CoreScaffold -> AppAppBar | AppDrawer via CoreScaffold | yes (local implementation) |

---

## 7) Practical conclusion

Answer to "Did we use reusable code or repeated development?"

- Yes, reusable code is used effectively for AppBar + Drawer through CoreScaffold.
- Yes, repeated development exists primarily in BottomNavigationBar logic and destination definitions across multiple screens.

So the architecture is mixed:
- Strong reuse for shell-level structure.
- Medium to high duplication for screen-level bottom navigation.

---

## 8) Refactor opportunities (high-value, low-risk)

1. Introduce a shared `AppBottomNav` widget in `lib/shared/widgets/`:
	 - Inputs: `currentRoute`
	 - Emits: destination tapped route
	 - Owns destination definitions centrally

2. Replace per-screen `_selectedNavIndex` with derived index from route:
	 - Reuse `CoreRoutes.indexOf(...)` or replace it with a focused bottom-nav route map

3. Create one route-mapping function for bottom nav taps:
	 - Avoid repeated screen-local switches

4. Keep per-screen action icons in place:
	 - AppBar actions are correctly context-specific and should remain screen-owned

---

## 9) Side note from latest auth update

- OTP screen now includes a global bypass action for Twilio outage handling.
- Bypass route moves user to Dashboard and is available from OTP screen UI.
- Registration payload submission still happens before OTP screen transition.

