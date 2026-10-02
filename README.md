# Budget Tracker (Flutter)

Mobile client for **budget-tracker-spring**, a personal expense/budget
tracker. This app consumes that backend's JWT REST API: email/password and
"Sign in with Google" login, a dashboard with the total spent this month and
a per-category budget progress bar (green/yellow/red), and full CRUD on
expenses.

This is a portfolio project. It is a from-scratch Flutter/Dart app, independent
of the backend's own repo and git history.

## Architecture

```
lib/
  core/            Compile-time configuration (API base URL).
  data/            API client (dio) + repositories + secure token storage.
  models/          Plain Dart model classes (fromJson/toJson), no codegen.
  state/           ChangeNotifier state classes (Provider).
  ui/
    screens/       LoginScreen, DashboardScreen, ExpenseFormScreen.
    widgets/       Shared widgets (CategoryProgressBar).
```

**State management: [Provider]**, chosen over Riverpod/Bloc because the
app's state is small and shallow (three `ChangeNotifier`s: auth, dashboard,
expenses) and Provider lets every screen stay a plain `StatefulWidget` that
reads/watches state via `context.read`/`context.watch`, with no code
generation and a very short learning curve for a project this size. The
three state classes mirror the three concerns a reviewer would look for:

- `AuthState` — session status (`unknown` / `loggedOut` / `loggedIn`),
  login/loginWithGoogle/logout, loading + error state.
- `DashboardState` — `GET /api/dashboard/summary` (total + per-category
  progress).
- `ExpensesState` — the expense list, the category list (for the form's
  dropdown), and create/update/delete. Shared by `DashboardScreen` (recent
  list + delete) and `ExpenseFormScreen` (dropdown + submit) so both stay in
  sync without re-fetching independently.

**Networking: [dio]**, for its interceptor support (attaching
`Authorization: Bearer <token>` to every request in one place) and richer
exception types than `package:http`, which made it straightforward to map
every failure mode (timeout, connection refused, non-2xx, malformed body)
into one normalized, user-readable `ApiException` in `lib/data/api_client.dart`.
No screen ever sees a raw `DioException` or an unhandled exception.

**Token storage: [flutter_secure_storage]**, wrapped in
`lib/data/token_storage.dart` so the JWT lives in the OS keystore/keychain,
never in `SharedPreferences` or a plain file.

### Client-side OK/WARNING/OVER thresholds

The backend's dashboard summary includes a `status` string per category
(`OK`/`WARNING`/`OVER`). Rather than trust that string directly for colouring
the progress bar, `lib/models/budget_status.dart` replicates the backend's own
rule from `percentUsed`:

- `< 50%` → OK (green)
- `50%–99%` → WARNING (yellow)
- `>= 100%` → OVER (red)

`CategoryProgressBar` (in `lib/ui/widgets/category_progress_bar.dart`) always
derives its colour from this client-side computation, so a future wording
change in the backend's `status` string can't silently desync the UI colour
from the real percentage.

## Pointing the app at a backend

The base URL is **never hardcoded**. It's baked in at compile/run time via
`--dart-define`:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

If you omit `--dart-define`, it defaults to `http://10.0.2.2:8080` (see
`lib/core/api_config.dart`).

- **Android emulator → host machine:** `10.0.2.2` is the standard alias the
  Android emulator uses to reach `localhost` on the machine running the
  emulator. If `budget-tracker-spring` is started with `docker compose up`
  (publishing port 8080 on the host), the emulator reaches it at
  `http://10.0.2.2:8080` — this is the compiled-in default.
- **Real device on the same LAN:** `10.0.2.2` does **not** work on a real
  phone. Use the host machine's actual LAN IP instead, e.g.
  `flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080`, and make
  sure the phone and the host are on the same network and the host's firewall
  allows inbound connections on port 8080.
- The Android manifest sets `usesCleartextTraffic="true"` because the backend
  is plain HTTP in local development; remove that flag if the API is ever
  served over HTTPS.

## Running

```
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Demo account (once the backend is running): `demo@budgettracker.com` /
`demo1234`.

## Testing

Widget tests (mocked repositories, no network/backend needed):

```
flutter test
```

Covers: `LoginScreen` (shows an error on failed login, validates empty
fields, navigates to the dashboard on success), `DashboardScreen` (renders
the total, colours each category's progress bar correctly per the
OK/WARNING/OVER thresholds above, deletes an expense via swipe), and
`ExpenseFormScreen` (validates required fields/invalid amount, submits the
exact payload to the repository, pre-fills + deletes when editing).

An **optional, best-effort** end-to-end integration test lives in
`integration_test/app_test.dart`: login → dashboard → add an expense → see it
reflected, driven against a **real** running backend. It requires:

1. `budget-tracker-spring` running via `docker compose up` in its own repo.
2. An attached Android emulator or device.

```
flutter test integration_test/app_test.dart --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

This test was **written but not executed** in the environment this app was
built in — no Android emulator/AVD was available there (`flutter emulators`
reported none, and no AVD images were installed), and no backend instance
was running. It's included for documentation/completeness per the project
brief and should work once both prerequisites above are met.

## Building

```
flutter build apk --debug
```

Release signing is out of scope for a portfolio demo (no keystore is
configured; `flutter build apk --release` would currently fall back to the
debug signing config).

**iOS is a known limitation**: it cannot be built or signed on this Windows
development machine (no macOS/Xcode toolchain available). The Dart/Flutter
code itself is cross-platform and makes no platform-specific assumptions, it
has simply never been built or run through the iOS toolchain.

## CI

`.github/workflows/ci.yml` runs on every push/PR to `main` via
[`subosito/flutter-action`](https://github.com/subosito/flutter-action)
(channel `stable`) on `ubuntu-latest`: `flutter pub get` → `flutter analyze`
→ `flutter test` → `flutter build apk --debug`.

## Google Sign-In setup (required manual step)

The code in `lib/data/google_auth_service.dart` + `AuthState.loginWithGoogle`
implements the real integration (`google_sign_in` → ID token →
`POST /api/auth/oauth/google` → app JWT), but it cannot be exercised
end-to-end in this environment because no real Google Cloud project was
created for this task. To make Google Sign-In actually work, you need to, in
[Google Cloud Console](https://console.cloud.google.com/):

1. Create (or reuse) a project and configure the OAuth consent screen.
2. Create an **Android** OAuth client ID (distinct from any web client ID
   the backend might use for its own session-based login) scoped to this
   app's package name (`com.mbeltran.budgettracker.budget_tracker_flutter`)
   and the **SHA-1 fingerprint** of the signing key you'll build with (for a
   debug build: `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore
   -alias androiddebugkey -storepass android -keypass android`).
3. Download the resulting `google-services.json` into `android/app/`, or
   otherwise provide the generated client ID to the app per the
   `google_sign_in` plugin's Android setup docs.
4. The backend's `/api/auth/oauth/google` endpoint must trust ID tokens
   issued for that same client ID (or its associated server client ID).

Without this, `signInAndGetIdToken()` will throw a `GoogleSignInException`
(typically a configuration-related code) — this is expected here.

**Facebook / Twitter sign-in** are not implemented. Next step: both would
follow the exact same exchange pattern already used for Google — get a
provider token/credential from their respective SDK, then
`POST /api/auth/oauth/facebook` (or `/twitter`) with that token to receive
the app's own JWT, exactly like `AuthRepository.loginWithGoogle` does today.

## Known limitations

- iOS cannot be built/signed on this Windows machine (see above).
- The real-backend integration test exists but was not run here (no
  emulator/backend available in this sandbox).
- Google Sign-In cannot be exercised end-to-end without a real Google Cloud
  OAuth client configured (see above).
- Release APK signing is not configured (portfolio demo scope).
