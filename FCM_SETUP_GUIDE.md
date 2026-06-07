# FCM Push Notifications — Complete Setup Guide
## Flutter (mobile) + Laravel (backend)

This guide is based on the production implementation in the Quadro Cloud project.
Follow every step in order. Do not skip the manual steps in Part 1.

---

## PART 1 — FIREBASE CONSOLE (Manual, do this first)

### 1.1 Create a Firebase project
1. Go to https://console.firebase.google.com
2. Click **Add project** → enter a project name (e.g. `my-app`)
3. Disable Google Analytics if you don't need it → **Create project**

### 1.2 Register the Android app
1. Project Overview → **Add app** → Android icon
2. **Android package name**: must exactly match `applicationId` in `android/app/build.gradle.kts`
   - Example: `com.example.myapp`
3. Click **Register app**
4. Download `google-services.json`
5. Place it at `mobile/android/app/google-services.json`
6. Add to `mobile/.gitignore`:
   ```
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ```

### 1.3 Register the iOS app (if building for iOS)
1. Project Overview → **Add app** → iOS icon
2. **iOS bundle ID**: must match `CFBundleIdentifier` in `ios/Runner/Info.plist`
3. Download `GoogleService-Info.plist`
4. In Xcode: drag it into the `Runner` target. Check **Copy items if needed** and make sure the `Runner` target is checked.

### 1.4 Generate a service account (for the Laravel backend)
1. Firebase Console → **Project Settings** → **Service accounts** tab
2. Click **Generate new private key** → confirm → download the JSON file
3. Open the JSON. Note these three values:
   - `project_id`
   - `client_email`
   - `private_key` (the full multi-line RSA key)
4. **Never commit this file to git.** Store its values in `.env` only.

### 1.5 Note the Project ID
Firebase Console → Project Settings → General tab → **Project ID**
This goes into `FCM_PROJECT_ID` in `.env`.

---

## PART 2 — LARAVEL BACKEND

### 2.1 Add credentials to `.env`
```env
FCM_PROJECT_ID=your-firebase-project-id
FCM_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"
```
Copy `private_key` from the service account JSON exactly as-is.
In `.env` the newlines must be literal `\n` (not actual line breaks) — keep it all on one line wrapped in double quotes.

### 2.2 Create `config/firebase.php`
```php
<?php

return [
    'project_id'   => env('FCM_PROJECT_ID'),
    'client_email' => env('FCM_CLIENT_EMAIL'),
    'private_key'  => env('FCM_PRIVATE_KEY'),
];
```

### 2.3 Add `fcm_token` to your clients/users table

Create a migration:
```php
Schema::table('clients', function (Blueprint $table) {
    $table->string('fcm_token')->nullable()->after('email');
});
```

Add `fcm_token` to the model's `$fillable` array.

Run `php artisan migrate`.

### 2.4 Create `app/Services/FcmService.php`

This is the exact production service used in Quadro Cloud.
It uses Google's OAuth2 JWT flow (no third-party packages needed).

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    private string $projectId;
    private string $clientEmail;
    private string $privateKey;

    public function __construct()
    {
        $this->projectId   = config('firebase.project_id', '');
        $this->clientEmail = config('firebase.client_email', '');
        // str_replace converts \n literals from .env to real newlines
        $this->privateKey  = str_replace('\\n', "\n", config('firebase.private_key', ''));
    }

    /**
     * Send a push notification to a single device token.
     *
     * $data values must all be strings (FCM requirement).
     * Pass action/action_id in $data for deep-link navigation in the app.
     */
    public function send(string $fcmToken, string $title, string $body, array $data = []): bool
    {
        if (! $fcmToken || ! $this->projectId) {
            return false;
        }

        $token = $this->getAccessToken();
        if (! $token) {
            return false;
        }

        $response = Http::withToken($token)
            ->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", [
                'message' => [
                    'token'        => $fcmToken,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'android' => [
                        'notification' => [
                            'channel_id' => 'high_importance_channel', // must match Flutter channel ID
                            'sound'      => 'default',
                        ],
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'sound' => 'default',
                                'badge' => 1,
                            ],
                        ],
                    ],
                    // All data values must be strings
                    'data' => empty($data) ? new \stdClass() : array_map('strval', $data),
                ],
            ]);

        if (! $response->successful()) {
            Log::error('FCM send failed', ['token' => substr($fcmToken, 0, 20), 'response' => $response->body()]);
            return false;
        }

        return true;
    }

    // ─── Internal: OAuth2 access token cached for 55 min ─────────────────────

    private function getAccessToken(): ?string
    {
        return Cache::remember('fcm_access_token', 3300, function () {
            return $this->fetchNewAccessToken();
        });
    }

    private function fetchNewAccessToken(): ?string
    {
        if (! $this->clientEmail || ! $this->privateKey) {
            Log::warning('FCM: missing service account credentials in .env');
            return null;
        }

        $now = time();
        $jwt = $this->buildJwt([
            'iss'   => $this->clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud'   => 'https://oauth2.googleapis.com/token',
            'iat'   => $now,
            'exp'   => $now + 3600,
        ]);

        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $jwt,
        ]);

        if (! $response->successful() || ! isset($response['access_token'])) {
            Log::error('FCM: failed to fetch OAuth2 token', ['body' => $response->body()]);
            return null;
        }

        return $response['access_token'];
    }

    private function buildJwt(array $claims): string
    {
        $header  = $this->base64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = $this->base64url(json_encode($claims));
        $input   = "{$header}.{$payload}";

        openssl_sign($input, $signature, $this->privateKey, OPENSSL_ALGO_SHA256);

        return "{$input}." . $this->base64url($signature);
    }

    private function base64url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
```

### 2.5 Add the FCM token API endpoint

In `routes/api.php` (inside the auth middleware group):
```php
Route::put('auth/fcm-token', [AuthController::class, 'updateFcmToken']);
```

In `AuthController.php`:
```php
public function updateFcmToken(Request $request)
{
    $request->validate(['fcm_token' => 'required|string']);
    $request->user()->update(['fcm_token' => $request->fcm_token]);
    return response()->json(['message' => 'FCM token updated']);
}
```

### 2.6 Send a notification from your code

Example — after a payment is confirmed in a webhook controller:
```php
use App\Services\FcmService;

$client = $invoice->client;
if ($client->fcm_token) {
    app(FcmService::class)->send(
        $client->fcm_token,
        'تم تأكيد الدفع',
        'تم استلام دفعتك بنجاح للفاتورة ' . $invoice->invoice_number,
        [
            'action'    => 'invoice_detail',           // Flutter reads this
            'action_id' => (string) $invoice->id,      // All values must be strings
        ]
    );
}
```

### 2.7 (Optional) Notification log table

If you want to keep a history of all sent notifications, create a migration:
```php
Schema::create('notification_logs', function (Blueprint $table) {
    $table->id();
    $table->foreignId('client_id')->constrained()->cascadeOnDelete();
    $table->string('type');
    $table->enum('channel', ['push', 'email', 'both']);
    $table->string('title');
    $table->text('body');
    $table->nullableMorphs('reference'); // polymorphic: invoice, contract, etc.
    $table->boolean('sent')->default(true);
    $table->timestamp('sent_at')->nullable();
    $table->timestamps();
});
```

Then add a `notifyAndLog()` wrapper to `FcmService` that calls `send()` and then creates a `NotificationLog` record.

---

## PART 3 — FLUTTER MOBILE

### 3.1 Add dependencies to `pubspec.yaml`
```yaml
dependencies:
  firebase_core: ^3.10.0
  firebase_messaging: ^15.1.6
  flutter_local_notifications: ^18.0.0
```

Run: `flutter pub get`

### 3.2 Configure Android

**`android/settings.gradle.kts`** — add the GMS plugin to the `plugins {}` block:
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false  // ADD THIS
}
```

**`android/app/build.gradle.kts`** — apply the plugin and add dependencies:
```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ADD THIS
}

android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true  // Required for flutter_local_notifications
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        // ...
        multiDexEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")  // Required
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
    implementation("com.google.firebase:firebase-messaging")
}
```

**`android/app/src/main/AndroidManifest.xml`** — inside `<application>`:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

**`android/app/proguard-rules.pro`** (if using minification in release builds):
```
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn io.flutter.embedding.**
```

**`android/gradle.properties`** — add if you get incremental compilation errors (common on Windows when project and Flutter SDK are on different drives):
```
kotlin.incremental=false
```

### 3.3 Configure iOS (manual Xcode steps)

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)
2. Select the **Runner** target → **Signing & Capabilities** tab
3. Click **+ Capability** → add **Push Notifications**
4. Click **+ Capability** → add **Background Modes** → check:
   - Background fetch
   - Remote notifications
5. Run `cd ios && pod install`

**`ios/Runner/AppDelegate.swift`**:
```swift
import UIKit
import Flutter
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

For iOS APNs: Firebase Console → Project Settings → Cloud Messaging → your iOS app → upload APNs Auth Key (`.p8` from Apple Developer account). Without this, push will not work on iOS.

### 3.4 Create `lib/core/services/notification_service.dart`

This is the exact production file from Quadro Cloud, adapted for a generic project.
Replace the channel ID and action mappings with your own.

```dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart'; // adjust import path

// ─── Providers ────────────────────────────────────────────────────────────────

/// Set to a route string when a notification tap should navigate.
final notificationPendingRouteProvider = StateProvider<String?>((ref) => null);

// Add more providers here if a notification needs to pass extra data
// (e.g., which tab to open, which item to highlight).

// ─── Background handler (must be top-level) ───────────────────────────────────

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // No navigation here — the app may not be running.
  // Firebase requires this to be registered; leave it empty unless you need
  // to do background data processing.
}

// ─── Service ──────────────────────────────────────────────────────────────────

class NotificationService {
  static final _fln = FlutterLocalNotificationsPlugin();
  static const _channelId   = 'high_importance_channel'; // must match AndroidManifest.xml
  static const _channelName = 'My App Notifications';    // display name in system settings

  static ProviderContainer? _container;

  /// Call once in main() before runApp(), after Firebase.initializeApp().
  static Future<void> init({ProviderContainer? container}) async {
    _container = container;

    // Register background handler first
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ));
    }

    // Initialize flutter_local_notifications
    await _fln.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    // Request permission (Android 13+ and iOS)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Show notification banner even when app is in foreground (iOS)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
      // Show local notification when app is in foreground (Android)
      FirebaseMessaging.onMessage.listen(_showLocal);
    }

    // Handle tap when app was in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  /// Call after the first frame (e.g., in initState of your root widget or
  /// in a post-frame callback) to handle the case where the app was terminated.
  static Future<void> checkInitialMessage() async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) _handleTap(msg);
  }

  /// Call after login to register the device token with your backend.
  static Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiClient().dio.put('/auth/fcm-token', data: {'fcm_token': token});
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        try {
          await ApiClient().dio.put('/auth/fcm-token', data: {'fcm_token': t});
        } catch (_) {}
      });
    } catch (_) {}
  }

  // ─── Internal ───────────────────────────────────────────────────────────────

  static void _handleTap(RemoteMessage message) {
    final action   = message.data['action']    as String?;
    final actionId = message.data['action_id'] as String?;
    final id       = actionId != null ? int.tryParse(actionId) : null;

    // MAP YOUR ACTIONS TO APP ROUTES HERE
    switch (action) {
      case 'invoice_detail':
      case 'payment_confirmed':
        _container?.read(notificationPendingRouteProvider.notifier).state =
            id != null ? '/invoices/$id' : '/invoices';
      // Add more cases:
      // case 'ticket_reply':
      //   _container?.read(notificationPendingRouteProvider.notifier).state = '/tickets/$id';
      default:
        break;
    }
  }

  static void _showLocal(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _fln.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
        ),
      ),
    );
  }
}
```

### 3.5 Initialize in `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();            // must be before NotificationService.init
  await ApiClient().init();                  // your auth/HTTP client setup

  final container = ProviderContainer();
  await NotificationService.init(container: container);

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}
```

### 3.6 Wire navigation in the root widget

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for notification taps and navigate
    ref.listen(notificationPendingRouteProvider, (_, route) {
      if (route != null) {
        router.go(route);  // your GoRouter instance
        ref.read(notificationPendingRouteProvider.notifier).state = null;
      }
    });

    return MaterialApp.router(routerConfig: router, ...);
  }
}
```

### 3.7 Sync token after login

In your auth repository's login method, after saving the token and setting the auth header:
```dart
Future<void> login(String email, String password) async {
  final response = await _api.dio.post('/auth/login', data: {...});
  final token = response.data['token'] as String;
  await _storage.write(key: 'token', value: token);
  _api.dio.options.headers['Authorization'] = 'Bearer $token';

  await NotificationService.syncToken();  // ADD THIS
}
```

---

## PART 4 — ADDING NEW NOTIFICATION TYPES

### Backend — send with a new action key:
```php
app(FcmService::class)->send(
    $client->fcm_token,
    'رد جديد على تذكرتك',
    $replyText,
    ['action' => 'ticket_reply', 'action_id' => (string) $ticket->id]
);
```

### Flutter — add a case in `NotificationService._handleTap()`:
```dart
case 'ticket_reply':
  _container?.read(notificationPendingRouteProvider.notifier).state =
      id != null ? '/tickets/$id' : '/tickets';
```

---

## PART 5 — TESTING

### Test from Firebase Console (no backend needed):
1. Firebase Console → **Cloud Messaging** → **Send your first message**
2. Enter a notification title and body
3. Target: **Single device**
4. Get your test device token: temporarily add this to `main()`:
   ```dart
   FirebaseMessaging.instance.getToken().then(print);
   ```
5. Paste the token → **Test on device**

### Test from Laravel Tinker:
```php
php artisan tinker

$client = App\Models\Client::find(1);  // a client with a real fcm_token
app(App\Services\FcmService::class)->send(
    $client->fcm_token,
    'Test Title',
    'Test body',
    ['action' => 'invoice_detail', 'action_id' => '1']
);
```

---

## PART 6 — COMMON ERRORS

| Error | Cause | Fix |
|---|---|---|
| `FirebaseApp not initialized` | `Firebase.initializeApp()` not called before `NotificationService.init()` | Call it first in `main()` |
| `No matching client for package name` | `google-services.json` package name ≠ `applicationId` in `build.gradle.kts` | Fix `applicationId` and `namespace` to match the JSON |
| `UNREGISTERED` from FCM API | Token is stale (app reinstalled, token rotated) | Delete old token from DB; re-sync on next login |
| Foreground notifications not shown on Android | `flutter_local_notifications` not set up, or channel not created | Make sure `createNotificationChannel` is called and `onMessage` listener calls `_showLocal` |
| `authentication_error` from FCM v1 API | Bad JWT — wrong `private_key` format (missing real newlines) | Verify `str_replace('\\n', "\n", ...)` is applied; check `FCM_CLIENT_EMAIL` matches the service account |
| `isCoreLibraryDesugaringEnabled` build error | Missing `coreLibraryDesugaring` dependency | Add `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` to `dependencies {}` |
| Kotlin incremental compilation error on Windows | Project on D: drive, Flutter pub cache on C: drive (cross-drive cache) | Add `kotlin.incremental=false` to `android/gradle.properties` |
| iOS notifications not arriving | APNs key not uploaded to Firebase | Firebase Console → Project Settings → Cloud Messaging → iOS app → upload APNs Auth Key |
| Token not updating after app reinstall | `onTokenRefresh` listener not registered | It is registered inside `syncToken()` — call `syncToken()` after every login, not just first login |

---

## PART 7 — GITIGNORE RULES

**`mobile/.gitignore`** — already covered in Flutter's default `.gitignore`, but verify these are present:
```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
ios/Runner/GoogleService-Info*.plist
```

**`backend/.gitignore`**:
```
firebase-service-account.json
```

The service account JSON content goes directly in `.env` as `FCM_PRIVATE_KEY` — never commit the file.

---

## PART 8 — PRODUCTION CHECKLIST

- [ ] `google-services.json` placed at `android/app/google-services.json` on every dev machine (not committed)
- [ ] `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY` set in production `.env`
- [ ] APNs Auth Key uploaded in Firebase Console (iOS only)
- [ ] `php artisan config:cache` run after adding FCM keys to production `.env`
- [ ] `fcm_token` column exists and is nullable in the DB
- [ ] `updateFcmToken` API route is inside auth middleware (authenticated route)
- [ ] `NotificationService.syncToken()` called after every login (not just registration)
- [ ] Android notification channel ID in `FcmService.php` matches the one in `NotificationService.dart` and `AndroidManifest.xml`
