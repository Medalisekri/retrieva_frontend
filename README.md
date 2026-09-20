# 📱 Retrieva — Frontend

> The Flutter mobile app for Retrieva, a lost-and-found platform. Browse, post, and chat about lost and found items — with maps, push notifications, and offline support.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Riverpod](https://img.shields.io/badge/Riverpod-00BCD4?style=for-the-badge&logo=flutter&logoColor=white)

---

## Screenshots


| Browse | Map | Detail |
|---|---|---|
| *<img width="400" height="600" alt="Screenshot_20260919-214432" src="https://github.com/user-attachments/assets/fc00c1c5-7d95-43af-8801-e1fbb2e2c59f" />* | *<img width="400" height="600" alt="Screenshot_20260919-212059" src="https://github.com/user-attachments/assets/01738736-b062-433e-9c48-cd389adfcabb" />* | *<img width="400" height="600" alt="Screenshot_20260919-214432" src="https://github.com/user-attachments/assets/44ebb801-b13d-419d-85b9-0e7343b60e57" />* |

---

## Architecture

The app follows a clean three-layer architecture — screens never touch Dio or API logic directly.

```
lib/
├── core/
│   ├── helper/         # GeocodingService, AuthInterceptor
│   ├── router/         # GoRouter setup and route constants
│   ├── services/       # CloudinaryService, OneSignalService     
│   ├── theme/          # Colors, typography, button styles
│   ├── utils/          # ErrorMapper, ItemsCache  
│   └── widgets/        # Reusable components
├── models/             # Item, Conversation, Message, ProfileModel
├── repositories/       # AuthRepository, ItemRepository, ChatRepository, ContactRepository
├── providers/          # Riverpod notifiers and providers
├── screens/            # All UI screens
└── main.dart
```

Screens call **Providers**, Providers call **Repositories**, Repositories call **Dio**. Each layer has one job.

---

## Features

| Feature | Description |
|---|---|
| Authentication | Email/password, Google Sign-In, password reset, email verification |
| Post items | Photo, location, category, date — lost or found |
| Browse | Infinite scroll with type and category filters |
| Map view | Geolocated pins filtered by visible map bounds |
| Chat | Real-time messaging with image sharing and block/unblock |
| Push notifications | New messages and fuzzy match alerts via OneSignal |
| Deep linking | Notification tap navigates directly to chat or item detail |
| Offline support | Cached items load from SharedPreferences when offline |
| My listings | Edit, resolve, and delete own items |
| Report items | Flag inappropriate listings |


---

## State Management

All providers use Riverpod `AsyncNotifier` with `AsyncValue.guard()` for safe error handling.

| Provider | Manages | Key methods |
|---|---|---|
| `AuthNotifier` | Auth state | `signUp`, `signIn`, `signInWithGoogle`, `resetPassword`, `signOut` |
| `ItemNotifier` | Public items list | `loadItems`, `addItem` |
| `MyItemsNotifier` | Current user's items | `loadMyItems`, `editMyItem`, `deleteMyItem`, `markAsResolved` |
| `ConversationNotifier` | Conversations | `getConversations`, `createConversation`, `blockOtherUser` |
| `MessageNotifier` | Messages for a conversation | `getMessages`, `sendMessage` |
| `profileProvider` | Current user profile | FutureProvider — refetched on login |

On login, all providers are invalidated to clear any stale data. On logout, the same happens to wipe user-specific state.

---

## Key Logic

| Feature | How it works |
|---|---|
| **Token auto-refresh** | `AuthInterceptor` attaches the Firebase ID token to every request and retries on `401` with a fresh token — prevents session breaks after 1 hour |
| **Offline cache** | `ItemsCache` saves the last fetch to SharedPreferences. If the network fails, cached items are shown instead of an error |
| **Deep linking** | `OneSignalService` parses notification `additionalData` and waits up to 8 seconds for Firebase to restore session on cold start before navigating |
| **Map performance** | `MapScreen` filters markers by `visibleBounds` client-side, so only pins in the current viewport are rendered |
| **Geocoding** | `GeocodingService` uses Nominatim to reverse geocode coordinates to a readable address, with coordinate fallback on failure |
| **Image uploads** | `CloudinaryService` accepts a `File` or `Uint8List`, POSTs to Cloudinary, and returns the `secure_url` |
| **Error messages** | `ErrorMapper` converts `FirebaseAuthException` and `DioException` errors to friendly strings shown via SnackBar |

---

## Navigation

GoRouter handles all navigation with automatic auth redirects.

- Logged-in users on login/signup are redirected to home
- Non-logged-in users on protected routes are redirected to login
- Public routes (browse, map, item detail) are accessible without login
- Route data is passed via `state.extra`
- Onboarding is shown once, controlled by a `SharedPreferences` flag checked in `main()`

---

## Getting Started

**Prerequisites:** Flutter SDK, a Firebase project, a Cloudinary account, OneSignal account

**1. Clone the repo**
```bash
git clone https://github.com/yourusername/retrieva-app.git
cd retrieva-app
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Firebase setup**
- Create a project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable **Email/Password** and **Google** authentication
- Run `flutterfire configure` to generate `firebase_options.dart`
- Add your **SHA-1 fingerprint** for Google Sign-In

**4. Set environment variables**

Create a `.env` file at the project root:
```
API_BASE_URL=https://your-backend.onrender.com
ONESIGNAL_APP_ID=your-onesignal-app-id
```

**5. Run the app**
```bash
flutter run
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation and auth redirects |
| `dio` | HTTP client with interceptors |
| `firebase_core` / `firebase_auth` | Authentication |
| `google_sign_in` | Google Sign-In |
| `flutter_map` / `latlong2` | Map view |
| `geolocator` | Device location |
| `onesignal_flutter` | Push notifications |
| `image_picker` | Photo selection |
| `shared_preferences` | Onboarding flag, offline cache |
| `infinite_scroll_pagination` | Browse screen pagination |
| `flutter_dotenv` | Environment variables |
| `intl` | Date formatting |

---

## Deployment

The app is built as a release APK and distributed via GitHub Releases.

```bash
flutter build apk --release
```

The APK is signed with a keystore. Users download and install it by enabling "Install from unknown sources".

---

## What I Learned

- Riverpod `AsyncNotifier` — clean async state with `AsyncValue.guard()` and `ref.invalidate()`
- Dio interceptors — auto-attaching tokens and silently retrying on `401` without touching screen code
- GoRouter redirects — declarative auth guards and deep link handling
- OneSignal deep linking — cold-start session restoration before navigating from a notification tap
- Offline-first patterns — cache-on-success, serve-cache-on-failure with SharedPreferences
- Map performance — client-side bounds filtering to avoid rendering thousands of markers
- Safe JSON parsing — `tryParse` with fallbacks everywhere to prevent crashes on unexpected API data
