# Upgrade Plan — Digital Products Mobile

## Current state

Score: 7.5/10 — persisted integer-cent cart with edge-case-tested maths, limit feedback, a11y guideline tests and fail-closed signing; no product detail screen, icon or E2E flow yet.

## Backlog

### P0
- None open. (Release signing now fails closed without `android/key.properties`.)

### P1
- Product detail screen with description and preview images.
- If checkout is ever added, use a hosted payment page; never collect card data in the app.
- Replace the template launcher icon with a real app icon (the application ID `com.bookchaowalit.*` is already set).
- Add a Maestro smoke flow for the main journey.
- Add a CI job that builds a signed release bundle from repository secrets (keystore decoded at runtime, never committed).

### P2
- Tablet layout (NavigationRail).
- Localisation (Thai/English) for UI strings.

## Done in this pass (pass 3)

- Error state: the add button stayed enabled at the 99-per-product limit and taps were silently ignored; it is now disabled with a "Maximum 99 per product" tooltip.
- Accessibility: quantities are announced as "N of <product> in cart" instead of a bare number; the total is a live region.
- Edge-case unit tests (no logic bugs found — cart maths held up): `formatCents` boundaries, half-cent discount rounding, a full 99×catalog cart staying exact and non-negative, no-op add/remove at limits, code whitespace/case, line order, `CartState` JSON with non-integer quantities.
- Widget tests: disabled add at the limit, quantity semantics, a11y guidelines (tap target, labels, contrast), 200% text scale.

## Done in pass 2

- Release builds no longer sign with the debug key: `android/app/build.gradle.kts` reads the ignored `android/key.properties` and a Gradle guard fails any release assemble/bundle without it (pattern from `bookchaowalit-goal-tracker-mobile`). Root `.gitignore` also ignores `key.properties`, `*.jks`, `*.keystore`; README documents the setup. Not build-verified here (no Android SDK/Gradle in this environment).
- The cart (product ids, quantities, discount code) now persists on device via `lib/data/cart_repository.dart` (`CartRepository` interface, `shared_preferences` JSON store, in-memory store for tests). `Cart.restore` resolves ids against the catalog, drops unknown products/codes and clamps quantities; the home screen shows an error line when storage fails.
- Added repository and restore tests plus widget tests for restore/save and load failure.

## Done in pass 1

- Replaced the Expo/npm CI (which could never fail) with fail-closed Flutter CI: `dart format` check, `flutter analyze`, `flutter test`, debug APK on `main`.
- Implemented the core feature (browse a small catalog of digital products and build a cart with an accurate total) with pure-Dart logic in `lib/logic/`.
- Replaced placeholder Explore/Profile tabs with an About screen describing features and privacy.
- Added unit tests for the logic and widget tests for the main journey.
- Removed unused `go_router` / `flutter_riverpod` dependencies; README now matches the code.
