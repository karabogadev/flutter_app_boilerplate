# Flutter Clean Architecture Boilerplate

Production-ready Flutter boilerplate with Clean Architecture, BLoC state management, and best practices.

---

## 📑 Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
- [Architecture](#architecture)
  - [What is Clean Architecture?](#what-is-clean-architecture)
  - [Layer Diagram](#layer-diagram)
  - [Data Flow](#data-flow)
  - [Why This Architecture?](#why-this-architecture)
- [Project Structure](#project-structure)
  - [Root Level Files](#root-level-files)
  - [Core Module](#core-module)
  - [Features Module](#features-module)
- [Core Modules Explained](#core-modules-explained)
  - [Error Handling](#1-error-handling)
  - [Network Layer (Dio)](#2-network-layer-dio)
  - [Cache Layer (SharedPreferences + Secure Storage)](#3-cache-layer-sharedpreferences--secure-storage)
  - [Theme System](#4-theme-system)
  - [Localization (Multi-language)](#5-localization-multi-language)
  - [Navigation](#6-navigation)
  - [Widgets](#7-reusable-widgets)
  - [Offline-First Architecture](#8-offline-first-architecture)
- [Features](#features)
  - [Auth Feature (Example)](#auth-feature-example)
  - [Other Features](#other-features)
- [How to Add a New Feature](#how-to-add-a-new-feature)
  - [Step 1: Create Folder Structure](#step-1-create-folder-structure)
  - [Step 2: Create Domain Layer](#step-2-create-domain-layer)
  - [Step 3: Create Data Layer](#step-3-create-data-layer)
  - [Step 4: Create Presentation Layer](#step-4-create-presentation-layer)
  - [Step 5: Register Dependencies](#step-5-register-dependencies)
  - [Step 6: Add Route](#step-6-add-route)
- [State Management (BLoC)](#state-management-bloc)
  - [Events](#events)
  - [States](#states)
  - [BLoC Class](#bloc-class)
  - [Using in UI](#using-in-ui)
- [Dependency Injection (GetIt)](#dependency-injection-getit)
  - [Registration Types](#registration-types)
  - [How to Use](#how-to-use)
- [Testing](#testing)
  - [Test Structure](#test-structure)
  - [Writing Tests](#writing-tests)
  - [Running Tests](#running-tests)
- [Commands Reference](#commands-reference)
- [Customization Guide](#customization-guide)
  - [Change App Name](#change-app-name)
  - [Change API URL](#change-api-url)
  - [Change Colors](#change-colors)
  - [Add New Translation](#add-new-translation)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

| Component | Technology | Purpose |
|-----------|------------|---------|
| Architecture | Clean Architecture | Separation of concerns |
| State Management | BLoC / Cubit | Predictable state changes |
| Dependency Injection | GetIt | Service locator pattern |
| Routing | Auto Route | Type-safe navigation with auth guard |
| HTTP Client | Dio | API requests with token refresh interceptor |
| Local Storage | SharedPreferences | Key-value cache (non-sensitive data) |
| Secure Storage | Flutter Secure Storage | Keychain/Keystore for auth tokens |
| **Offline Database** | **Hive CE** | **Offline-first data persistence** |
| **Connectivity** | **Connectivity Plus** | **Network status monitoring** |
| Localization | Easy Localization | Multi-language support |
| Code Generation | Freezed, JSON Serializable | Immutable models |

---

## Getting Started

### Prerequisites

Make sure you have these installed:

| Tool | Version | Check Command |
|------|---------|---------------|
| Flutter | 3.10+ | `flutter --version` |
| Dart | 3.0+ | `dart --version` |
| IDE | VS Code or Android Studio | - |

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/flutter_app_boilerplate.git

# 2. Navigate to project
cd flutter_app_boilerplate

# 3. Install dependencies
flutter pub get

# 4. Generate code (Freezed, Auto Route, etc.)
dart run build_runner build --delete-conflicting-outputs

# 5. Create your local environment file
cp .env.dev.example .env.dev

# 6. Generate platform folders (android/ and ios/ are not committed)
flutter create --platforms=android,ios .
```

### Running the App

The API base URL is read from the `BASE_URL` compile-time variable. Pass it with `--dart-define-from-file`:

```bash
# Run in debug mode
flutter run --dart-define-from-file=.env.dev

# Run in release mode
flutter run --release --dart-define-from-file=.env.dev

# Run on specific device
flutter run -d <device_id> --dart-define-from-file=.env.dev
```

Without the flag, `BASE_URL` falls back to `https://api.example.com`.

---

## Architecture

### What is Clean Architecture?

Clean Architecture separates your code into **3 layers**, each with a specific responsibility:

| Layer | Responsibility | Contains |
|-------|---------------|----------|
| **Presentation** | UI & State Management | Pages, Widgets, BLoCs |
| **Domain** | Business Logic | Entities, UseCases, Repository Interfaces |
| **Data** | Data Operations | Models, DataSources, Repository Implementations |

### Layer Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION                              │
│                      (UI & State)                                │
│                                                                  │
│   ┌──────────┐      ┌──────────┐      ┌──────────┐              │
│   │  Pages   │      │   BLoC   │      │ Widgets  │              │
│   │  (UI)    │ ───▶ │ (State)  │      │  (UI)    │              │
│   └──────────┘      └────┬─────┘      └──────────┘              │
│                          │                                       │
├──────────────────────────┼───────────────────────────────────────┤
│                     DOMAIN                                       │
│               (Business Logic)                                   │
│                          │                                       │
│                          ▼                                       │
│   ┌──────────┐      ┌──────────┐      ┌──────────┐              │
│   │ Entities │      │ UseCases │      │  Repos   │ (interface)  │
│   │ (Models) │      │ (Logic)  │      │ (Contract)│              │
│   └──────────┘      └────┬─────┘      └────┬─────┘              │
│                          │                 │                     │
├──────────────────────────┼─────────────────┼─────────────────────┤
│                       DATA                 │                     │
│                 (Data Access)              │                     │
│                          │                 │                     │
│                          ▼                 ▼                     │
│   ┌──────────┐      ┌──────────┐      ┌──────────┐              │
│   │  Models  │      │  Repos   │      │DataSources│             │
│   │(Freezed) │      │  (impl)  │      │ (API/DB) │              │
│   └──────────┘      └──────────┘      └──────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

When user taps "Login" button:

```
1. User taps Login
        │
        ▼
┌───────────────┐
│  LoginPage    │  ──▶  Sends LoginEvent
└───────┬───────┘
        │
        ▼
┌───────────────┐
│   AuthBloc    │  ──▶  Calls LoginUser usecase
└───────┬───────┘
        │
        ▼
┌───────────────┐
│  LoginUser    │  ──▶  Calls AuthRepository.login()
│  (UseCase)    │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│AuthRepository │  ──▶  Calls RemoteDataSource
│    (impl)     │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│RemoteDataSrc  │  ──▶  Makes API call via DioClient
└───────┬───────┘
        │
        ▼
     Response flows back up the chain.
     On success the repository saves tokens to secure storage,
     sets the Authorization header, and caches the user.
```

### Why This Architecture?

| Benefit | Explanation |
|---------|-------------|
| **Testable** | Each layer can be tested independently |
| **Maintainable** | Changes in one layer don't affect others |
| **Scalable** | Easy to add new features |
| **Readable** | Clear separation makes code easy to understand |

---

## Project Structure

### Root Level Files

```
lib/
├── main.dart                  # App entry point with error handling
├── app.dart                   # Root widget with providers
├── injection_container.dart   # Dependency injection setup
└── config/
    └── routes/
        ├── app_router.dart    # Route tree (auto_route)
        └── auth_guard.dart    # Protects routes that need a logged-in user
```

### Core Module

Shared code used across all features:

```
lib/core/
│
├── cache/                    # Local storage
│   ├── cache_keys.dart       # Enum of all cache keys
│   ├── cache_manager.dart    # SharedPreferences wrapper
│   ├── secure_cache_manager.dart # Keychain/Keystore wrapper (tokens)
│   └── cacheable_base_model.dart
│
├── constants/                # App-wide constants
│   ├── api_constants.dart    # Base URL, endpoints
│   ├── app_assets.dart       # Asset paths
│   ├── app_durations.dart    # Animation durations
│   └── app_spacing.dart      # Spacing values (4, 8, 16...)
│
├── error/                    # Error handling
│   ├── exceptions.dart       # ServerException, CacheException
│   └── failures.dart         # ServerFailure, CacheFailure
│
├── extensions/               # Dart extensions
│   ├── context_extensions.dart
│   ├── datetime_extensions.dart
│   └── string_extensions.dart
│
├── localization/             # Multi-language
│   ├── locale_keys.dart      # Translation keys
│   ├── localization_manager.dart
│   └── supported_locales.dart
│
├── network/                  # HTTP client
│   └── dio_client.dart       # Dio wrapper with logging + token refresh
│
├── theme/                    # App themes
│   ├── app_theme.dart        # Base theme interface
│   ├── light/                # Light theme files
│   │   ├── light_theme.dart
│   │   ├── color_scheme_light.dart
│   │   └── text_theme_light.dart
│   └── dark/                 # Dark theme files
│       ├── dark_theme.dart
│       ├── color_scheme_dark.dart
│       └── text_theme_dark.dart
│
├── usecases/                 # Base UseCase
│   └── usecase.dart
│
├── database/                 # Local database (Hive)
│   ├── hive_manager.dart     # Hive initialization
│   └── hive_boxes.dart       # Box name constants
│
├── offline/                  # Offline-first infrastructure
│   ├── connectivity_service.dart  # Network monitoring
│   ├── sync_queue.dart       # Pending operations queue
│   ├── sync_operation.dart   # Sync operation model
│   ├── sync_status.dart      # Status enums
│   ├── offline_manager.dart  # Orchestrates offline behavior
│   └── connectivity_cubit.dart # UI state management
│
└── widgets/                  # Reusable widgets
    ├── app_button.dart
    ├── app_text_field.dart
    ├── app_cached_image.dart
    ├── loading_indicator.dart
    ├── error_widget.dart
    └── offline_indicator.dart # Offline status widgets
```

### Features Module

Each feature follows the same structure:

```
lib/features/
│
├── auth/                     # Authentication feature
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── bloc/
│       ├── pages/
│       └── widgets/
│
├── home/                     # Home feature
├── onboarding/               # Onboarding feature
├── settings/                 # Settings feature
├── splash/                   # Splash screen
└── main_navigation/          # Bottom navigation
```

---

## Core Modules Explained

### 1. Error Handling

Two types of errors:

| Type | Used In | Purpose |
|------|---------|---------|
| `Exception` | DataSource | Low-level errors (API errors) |
| `Failure` | BLoC/UI | High-level errors (user-facing) |

**How it works:**

```dart
// 1. DataSource throws Exception
class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password) async {
    final response = await dio.post('/login', data: {...});

    if (response.statusCode != 200) {
      throw ServerException(
        message: 'Login failed',
        statusCode: response.statusCode,
      );
    }

    return UserModel.fromJson(response.data);
  }
}

// 2. Repository catches Exception, returns Failure
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Either<Failure, User>> login(...) async {
    try {
      final user = await remoteDataSource.login(...);
      return Right(user);  // Success
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));  // Failure
    }
  }
}

// 3. BLoC handles Failure
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  Future<void> _onLogin(...) async {
    final result = await loginUser(params);

    result.fold(
      (failure) => emit(AuthError(failure.message)),  // Handle failure
      (user) => emit(Authenticated(user)),            // Handle success
    );
  }
}
```

`DioClient` converts `DioException`s into `ServerException` (bad response, cancel) or `NetworkException` (timeouts, no connection), so data sources only deal with the app's own exception types.

### 2. Network Layer (Dio)

`DioClient` is registered in GetIt. Inject it through constructors instead of reaching for a global:

```dart
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl({required this.dioClient});

  final DioClient dioClient;

  Future<List<ProductModel>> getProducts() async {
    final response = await dioClient.get<List<dynamic>>('/products');
    // ...
  }
}

// Registration (injection_container.dart)
sl.registerLazySingleton<ProductRemoteDataSource>(
  () => ProductRemoteDataSourceImpl(dioClient: sl()),
);
```

Available methods: `get`, `post`, `put`, `patch`, `delete`, `setAuthToken`, `clearAuthToken`.

**Built-in Interceptors:**

| Interceptor | Function |
|-------------|----------|
| Logging | Logs requests/responses (debug builds only) |
| Token Refresh | On a 401, calls `ApiConstants.refreshToken` with the stored refresh token, saves the new tokens and retries the original request once. If the refresh fails, it clears the tokens and the sync queue. |

Token refresh is wired in `injection_container.dart` via `DioClient.configureTokenRefresh(...)`, once the auth data sources are registered. The refresh call uses a separate `Dio` instance so it never passes through the interceptor itself.

### 3. Cache Layer (SharedPreferences + Secure Storage)

There are two stores, split by sensitivity:

| Store | Class | Backed by | Use for |
|-------|-------|-----------|---------|
| Cache | `CacheManager` | SharedPreferences | Theme, locale, onboarding flag, cached user profile |
| Secure | `SecureCacheManager` | Keychain (iOS) / Keystore (Android) | Access & refresh tokens, other secrets |

`CacheManager.init()` is awaited in `main.dart` before `runApp`. Every accessor throws a `StateError` if called before that.

**CacheManager** (keys are the typed `CacheKeys` enum):

```dart
final cache = sl<CacheManager>(); // or inject via constructor

// Boolean
await cache.setBool(CacheKeys.onboardingCompleted, value: true);
final completed = cache.getBool(CacheKeys.onboardingCompleted);

// String
await cache.setString(CacheKeys.themeMode, 'dark');

// Object (must implement CacheableModel)
await cache.setObject(CacheKeys.user, userModel);
final user = cache.getObject(CacheKeys.user, UserModel.fromJson);

// List (add your own key to the CacheKeys enum first)
await cache.setList(CacheKeys.favorites, items);

// Remove / clear
await cache.remove(CacheKeys.user);
await cache.clear();
```

**SecureCacheManager** (async, string keys):

```dart
final secure = sl<SecureCacheManager>();

await secure.write('access_token', token);
final token = await secure.read('access_token');
await secure.delete('access_token');
```

> Never put tokens in `CacheManager`. SharedPreferences is stored as plain text on the device. Auth tokens are handled by `AuthLocalDataSource`, which writes them to `SecureCacheManager`.

### 4. Theme System

**Access theme in widgets:**

```dart
// Using Theme.of
final colors = Theme.of(context).colorScheme;
final text = Theme.of(context).textTheme;

// Using extensions (cleaner)
context.colorScheme.primary
context.textTheme.headlineLarge
```

**Toggle theme:**

```dart
// Toggle between light/dark
context.read<ThemeCubit>().toggleTheme();

// Set specific theme
context.read<ThemeCubit>().setTheme(ThemeMode.dark);
context.read<ThemeCubit>().setTheme(ThemeMode.light);
context.read<ThemeCubit>().setTheme(ThemeMode.system);
```

**Customize colors:**

Edit these files:
- Light: `lib/core/theme/light/color_scheme_light.dart`
- Dark: `lib/core/theme/dark/color_scheme_dark.dart`

### 5. Localization (Multi-language)

**Use translations:**

```dart
// Basic
Text(LocaleKeys.authLogin.tr())

// With named arguments
Text(LocaleKeys.homeWelcome.tr(namedArgs: {'name': 'John'}))
// Translation: "welcome": "Welcome, {name}!"
```

**Change language:**

```dart
context.read<LocaleCubit>().setLocale(context, SupportedLocale.turkish);
context.read<LocaleCubit>().setLocale(context, SupportedLocale.english);
```

**Add new language:**

1. Create translation file: `assets/translations/xx.json`
2. Add to `SupportedLocale` enum in `supported_locales.dart`:

```dart
newLanguage(
  locale: Locale('xx'),
  languageCode: 'xx',
  name: 'Language Name',
  nativeName: 'Native Name',
  flag: '🏳️',
),
```

3. Add to `main.dart` supportedLocales list

### 6. Navigation

Navigation uses auto_route directly. Routes are declared in `lib/config/routes/app_router.dart`, and `AppRouter` is registered in GetIt.

```dart
// Push
context.router.push(const HomeRoute());

// Replace
context.router.replace(const LoginRoute());

// Replace all
context.router.replaceAll([const HomeRoute()]);

// Pop
context.router.pop();
```

**Auth guard:**

`MainNavigationRoute` (and its `Home`/`Settings` children) is protected by `AuthGuard`. The guard reads the access token from `AuthLocalDataSource`. With no token, it pushes `/login` and blocks the original navigation.

```dart
AutoRoute(
  page: MainNavigationRoute.page,
  guards: [_authGuard], // injected into AppRouter's constructor
  children: [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: SettingsRoute.page),
  ],
),
```

### 7. Reusable Widgets

| Widget | Purpose | Location |
|--------|---------|----------|
| `AppButton` | Primary/Secondary buttons | `core/widgets/app_button.dart` |
| `AppTextField` | Styled text input | `core/widgets/app_text_field.dart` |
| `AppCachedImage` | Image with caching | `core/widgets/app_cached_image.dart` |
| `LoadingIndicator` | Loading spinner | `core/widgets/loading_indicator.dart` |
| `AppErrorWidget` | Error display | `core/widgets/error_widget.dart` |
| `OfflineBanner`, `OfflineIndicatorDot`, `OfflineAwareButton`, `ConnectivityListener` | Connectivity UI | `core/widgets/offline_indicator.dart` |

### 8. Offline-First Architecture

The app is designed to work seamlessly offline with automatic sync when back online.

#### Offline-First Principles

| Principle | Description |
|-----------|-------------|
| **Local First** | Hive database is the primary data source |
| **Eventual Consistency** | Changes sync to server when online |
| **Queue Operations** | All writes are queued when offline |
| **Graceful Degradation** | App remains fully functional offline |

#### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     OFFLINE-FIRST FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   User Action                                                    │
│        │                                                         │
│        ▼                                                         │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│   │  Repository │───▶│    Hive     │    │   API       │         │
│   │  (Local 1st)│    │  (Primary)  │    │ (Secondary) │         │
│   └──────┬──────┘    └─────────────┘    └──────▲──────┘         │
│          │                                      │                │
│          ▼                                      │                │
│   ┌─────────────┐    Online?    ┌─────────────┐│                │
│   │  SyncQueue  │──────────────▶│   Process   ├┘                │
│   │  (Pending)  │      Yes      │   Queue     │                 │
│   └─────────────┘               └─────────────┘                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### Core Components

All offline components are plain classes registered as lazy singletons in `injection_container.dart` (`_initOfflineFirst`). There are no static `.instance` accessors. Inject them through constructors, or resolve them with `sl<T>()` at the composition root.

`sl<OfflineManager>().init()` is awaited during `initDependencies()`. It initializes Hive and the connectivity service, recovers operations left `inProgress` by a previous session, and starts listening for connectivity changes.

**1. ConnectivityService** - Network monitoring (connectivity_plus plus a real DNS lookup):

```dart
final connectivity = sl<ConnectivityService>();

if (connectivity.isOnline) {
  // Make API call
}

connectivity.onStatusChanged.listen((status) {
  if (status == ConnectivityStatus.online) {
    debugPrint('Back online!');
  }
});
```

**2. HiveManager** - Database initialization and boxes:

```dart
final hive = sl<HiveManager>();

final syncBox = hive.getSyncQueueBox();
final settingsBox = hive.getSettingsBox();

// Open a feature-specific box
final productsBox = await hive.openBox<Map<dynamic, dynamic>>('products');

// Clear all data
await hive.clearAll();
```

**3. SyncQueue** - Queue offline operations (persisted in Hive, exponential backoff on retry):

```dart
final queue = sl<SyncQueue>();

await queue.addOperation(
  operationType: SyncOperationType.create,
  entityType: 'product',
  entityId: 'product-123',
  data: {'name': 'New Product', 'price': 29.99},
  endpoint: '/api/products',
);

final pending = queue.pendingCount;

final result = await queue.processQueue();
debugPrint('Synced: ${result.succeeded}/${result.processed}');
```

Pending operations are cleared on logout (`AuthRepository.logout` and the token-refresh failure path), so one user's queued writes are never sent with another user's token.

**4. OfflineManager** - Orchestrates everything (auto-syncs when connectivity returns):

```dart
final offline = sl<OfflineManager>();

await offline.queueOperation(
  operationType: SyncOperationType.update,
  entityType: 'user',
  entityId: 'user-1',
  data: {'name': 'John Doe'},
  endpoint: '/api/users/user-1',
);

await offline.processQueue();

offline.onStatusChanged.listen((status) {
  debugPrint('Online: ${status.isOnline}, Pending: ${status.pendingCount}');
});
```

#### UI Widgets

**OfflineBanner** - Shows when offline:

```dart
Scaffold(
  body: Column(
    children: [
      const OfflineBanner(),  // Shows only when offline
      Expanded(child: content),
    ],
  ),
)
```

**OfflineIndicatorDot** - Status dot for app bar:

```dart
AppBar(
  title: Text('My App'),
  actions: [
    const OfflineIndicatorDot(),  // Green/Red/Blue dot
  ],
)
```

**OfflineAwareButton** - Disable actions when offline:

```dart
OfflineAwareButton(
  onPressed: () => submitForm(),
  offlineMessage: 'You must be online to submit',
  child: ElevatedButton(
    child: Text('Submit'),
  ),
)
```

**ConnectivityListener** - Snackbar notifications:

```dart
// Already added in App widget
ConnectivityListener(
  showOnlineMessage: true,
  showOfflineMessage: true,
  child: MaterialApp(...),
)
```

#### Using ConnectivityCubit in UI

```dart
// Check state in widget
BlocBuilder<ConnectivityCubit, ConnectivityState>(
  builder: (context, state) {
    if (state.isOffline) {
      return Text('Working offline');
    }
    if (state.isSyncing) {
      return Text('Syncing ${state.pendingOperations} items...');
    }
    return Text('Online');
  },
)

// Trigger manual sync
context.read<ConnectivityCubit>().sync();

// Retry failed operations
context.read<ConnectivityCubit>().retryFailed();
```

#### Implementing Offline-First in Repository

```dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final HiveManager hiveManager;
  final OfflineManager offlineManager;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    // 1. Try local first
    final localProducts = _getLocalProducts();

    // 2. Return local if offline
    if (offlineManager.isOffline) {
      return Right(localProducts);
    }

    // 3. Fetch from remote if online
    try {
      final remoteProducts = await remoteDataSource.getProducts();
      await _saveToLocal(remoteProducts);  // Update local
      return Right(remoteProducts);
    } catch (e) {
      // Fallback to local on error
      return Right(localProducts);
    }
  }

  @override
  Future<Either<Failure, void>> createProduct(Product product) async {
    // 1. Save locally first
    await _saveToLocal([product]);

    // 2. Queue for sync
    await offlineManager.queueOperation(
      operationType: SyncOperationType.create,
      entityType: 'product',
      entityId: product.id,
      data: product.toJson(),
      endpoint: '/api/products',
    );

    return const Right(null);  // Success (will sync later)
  }
}
```

#### Best Practices

| Practice | Description |
|----------|-------------|
| **Local-first reads** | Always read from Hive first for instant UI |
| **Queue all writes** | Queue writes even when online for resilience |
| **Conflict resolution** | Use timestamps or version numbers |
| **Stale data cleanup** | Remove old pending operations (7+ days) |
| **User feedback** | Always show sync status in UI |

---

## Features

### Auth Feature (Example)

Complete authentication implementation:

```
features/auth/
│
├── data/
│   ├── datasources/
│   │   ├── auth_remote_datasource.dart   # API calls
│   │   └── auth_local_datasource.dart    # Cache operations
│   ├── models/
│   │   └── user_model.dart               # Freezed model
│   └── repositories/
│       └── auth_repository_impl.dart     # Repository implementation
│
├── domain/
│   ├── entities/
│   │   └── user.dart                     # User entity
│   ├── repositories/
│   │   └── auth_repository.dart          # Repository interface
│   └── usecases/
│       ├── login_user.dart               # Login logic
│       ├── register_user.dart            # Register logic
│       ├── logout_user.dart              # Logout logic
│       └── get_current_user.dart         # Get cached user
│
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart                # State management
    │   ├── auth_event.dart               # Events
    │   └── auth_state.dart               # States
    ├── pages/
    │   ├── login_page.dart               # Login UI
    │   └── register_page.dart            # Register UI
    └── widgets/
        └── auth_form.dart                # Shared form widget
```

### Other Features

| Feature | Description |
|---------|-------------|
| `splash` | Splash screen with initialization |
| `onboarding` | First-time user onboarding |
| `home` | Main home screen |
| `settings` | Theme and language settings |
| `main_navigation` | Bottom navigation wrapper |

---

## How to Add a New Feature

Let's add a "Products" feature step by step:

### Step 1: Create Folder Structure

```bash
mkdir -p lib/features/products/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{bloc,pages,widgets}}
```

This creates:

```
lib/features/products/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

### Step 2: Create Domain Layer

**2.1 Entity** (`domain/entities/product.dart`):

```dart
class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });
}
```

**2.2 Repository Interface** (`domain/repositories/product_repository.dart`):

```dart
abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, Product>> getProductById(String id);
}
```

**2.3 UseCase** (`domain/usecases/get_products.dart`):

```dart
class GetProducts implements UseCase<List<Product>, NoParams> {
  final ProductRepository repository;

  GetProducts(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) {
    return repository.getProducts();
  }
}
```

### Step 3: Create Data Layer

**3.1 Model** (`data/models/product_model.dart`):

```dart
@freezed
class ProductModel with _$ProductModel implements CacheableModel {
  const factory ProductModel({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  // Convert to entity
  Product toEntity() => Product(
    id: id,
    name: name,
    price: price,
    imageUrl: imageUrl,
  );
}
```

**3.2 DataSource** (`data/datasources/product_remote_datasource.dart`):

```dart
abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DioClient dioClient;

  ProductRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await dioClient.get('/products');
    return (response.data as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }
}
```

**3.3 Repository Implementation** (`data/repositories/product_repository_impl.dart`):

```dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final models = await remoteDataSource.getProducts();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
```

### Step 4: Create Presentation Layer

**4.1 Events** (`presentation/bloc/product_event.dart`):

```dart
abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {}
```

**4.2 States** (`presentation/bloc/product_state.dart`):

```dart
abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(this.products);
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}
```

**4.3 BLoC** (`presentation/bloc/product_bloc.dart`):

```dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProducts getProducts;

  ProductBloc({required this.getProducts}) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    final result = await getProducts(NoParams());

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }
}
```

**4.4 Page** (`presentation/pages/products_page.dart`):

```dart
@RoutePage()
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductBloc>()..add(LoadProducts()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const LoadingIndicator();
            }
            if (state is ProductError) {
              return AppErrorWidget(message: state.message);
            }
            if (state is ProductLoaded) {
              return ListView.builder(
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('\$${product.price}'),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
```

### Step 5: Register Dependencies

Add to `injection_container.dart`:

```dart
Future<void> _initProducts() async {
  // BLoC
  sl.registerFactory<ProductBloc>(
    () => ProductBloc(getProducts: sl()),
  );

  // UseCases
  sl.registerLazySingleton<GetProducts>(
    () => GetProducts(sl()),
  );

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSource
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(dioClient: sl()),
  );
}
```

Call it in `initDependencies()`:

```dart
Future<void> initDependencies() async {
  // ... existing code
  await _initProducts();
}
```

### Step 6: Add Route

In `lib/config/routes/app_router.dart`, add the page import and the route. If the screen needs a logged-in user, nest it under `MainNavigationRoute` so it inherits `AuthGuard`:

```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter(this._authGuard);

  final AuthGuard _authGuard;

  @override
  List<AutoRoute> get routes => [
        // ... existing routes
        AutoRoute(
          page: MainNavigationRoute.page,
          guards: [_authGuard],
          children: [
            AutoRoute(page: HomeRoute.page, initial: true),
            AutoRoute(page: SettingsRoute.page),
            AutoRoute(page: ProductsRoute.page), // new
          ],
        ),
      ];
}
```

**Don't forget to generate code:**

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## State Management (BLoC)

### Events

Events are **inputs** that trigger state changes:

```dart
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}
```

### States

States are **outputs** that represent UI state:

```dart
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
```

### BLoC Class

BLoC connects events to states (abridged from `auth_bloc.dart`):

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final LogoutUser logoutUser;
  final GetCurrentUser getCurrentUser;

  AuthBloc({
    required this.loginUser,
    required this.registerUser,
    required this.logoutUser,
    required this.getCurrentUser,
  }) : super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await loginUser(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await logoutUser(const NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }
}
```

### Using in UI

**Trigger an event:**

```dart
// On button press
ElevatedButton(
  onPressed: () {
    context.read<AuthBloc>().add(
      LoginEvent(email: email, password: password),
    );
  },
  child: Text('Login'),
)
```

**Listen to state changes:**

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return const LoadingIndicator();
    }
    if (state is AuthError) {
      return Text(state.message);
    }
    if (state is Authenticated) {
      return Text('Welcome, ${state.user.name}');
    }
    return const LoginForm();
  },
)
```

**React to state changes (navigation, snackbar):**

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is Authenticated) {
      context.router.replaceAll([const MainNavigationRoute()]);
    }
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: LoginForm(),
)
```

---

## Dependency Injection (GetIt)

### Registration Types

| Type | Method | When Created | Use Case |
|------|--------|--------------|----------|
| Factory | `registerFactory` | Every time | Screen-scoped BLoCs/Cubits (`AuthBloc`, `ConnectivityCubit`) |
| Lazy Singleton | `registerLazySingleton` | First access | Core services, data sources, repositories, UseCases, router |
| Lazy Singleton | `registerLazySingleton` | First access | App-wide cubits whose state must be shared (`ThemeCubit`, `LocaleCubit`) |
| Singleton | `registerSingleton` | Immediately | Pre-built instances |

> `ThemeCubit` and `LocaleCubit` are lazy singletons on purpose. With `registerFactory`, every `sl<ThemeCubit>()` call would return a new instance that silently drifts from the one owned by the root `BlocProvider`.

### How to Use

**Registering** (everything is wired in `injection_container.dart`):

```dart
// Factory - new instance each time
sl.registerFactory<AuthBloc>(() => AuthBloc(
  loginUser: sl(),
  registerUser: sl(),
  logoutUser: sl(),
  getCurrentUser: sl(),
));

// Lazy Singleton - one instance, created when first needed
sl.registerLazySingleton<LoginUser>(() => LoginUser(sl()));
sl.registerLazySingleton<DioClient>(() => DioClient.instance);
```

The current initialization order in `initDependencies()` is:

1. Core: `CacheManager`, `SecureCacheManager`, `DioClient`, `LocalizationManager`
2. Offline-first: `HiveManager`, `ConnectivityService`, `SyncQueue`, `OfflineManager` (then `await sl<OfflineManager>().init()`)
3. Auth: data sources, repository, use cases, `AuthBloc`, `AuthGuard`, `AppRouter`, then `DioClient.configureTokenRefresh(...)`
4. Settings: `ThemeCubit`, `LocaleCubit`

After `initDependencies()`, `main.dart` awaits `sl<CacheManager>().init()` and `EasyLocalization.ensureInitialized()`, then calls `runApp`.

**Accessing:**

```dart
// Get instance
final authBloc = sl<AuthBloc>();
final loginUser = sl<LoginUser>();

// In BlocProvider
BlocProvider(
  create: (_) => sl<AuthBloc>(),
  child: LoginPage(),
)
```

**Registration Order:**

`registerLazySingleton` and `registerFactory` factories only run when the type is first resolved, so their relative order does not matter. Order *does* matter wherever a type is resolved eagerly during `initDependencies()`. For example, `await sl<OfflineManager>().init()` and `sl<DioClient>().configureTokenRefresh(...)` resolve immediately, so everything they depend on must already be registered:

```dart
// ✅ Works - AuthLocalDataSource is registered before it's resolved
sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(...));
sl<DioClient>().configureTokenRefresh(
  getRefreshToken: () => sl<AuthLocalDataSource>().getRefreshToken(),
  // ...
);

// ❌ Fails - OfflineManager's dependencies are not registered yet
await sl<OfflineManager>().init();
sl.registerLazySingleton<SyncQueue>(() => SyncQueue(sl(), sl()));
```

Resolve dependencies from `sl` only in the composition root (`injection_container.dart`, `app.dart`). Everywhere else, take them as constructor parameters so tests can pass fakes or mocks.

---

## Testing

### Test Structure

```
test/
├── fixtures/                    # Test data (JSON files)
│   ├── fixture_reader.dart      # fixture('user.json') helper
│   ├── user.json
│   └── auth_response.json
│
├── helpers/                     # Test utilities
│   ├── pump_app.dart            # Widget test helper
│   └── test_helpers.dart        # TestData factory (testUser, userJson, ...)
│
├── mocks/                       # Mock classes
│   └── mocks.dart               # Mocktail mocks + registerFallbackValues()
│
├── core/
│   └── offline/
│       ├── connectivity_cubit_test.dart
│       └── sync_queue_test.dart
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   └── repositories/
    │   │       └── auth_repository_impl_test.dart
    │   ├── domain/
    │   │   └── usecases/        # login, register, logout, get_current_user
    │   └── presentation/
    │       └── bloc/
    │           └── auth_bloc_test.dart
    └── settings/
        └── presentation/
            └── bloc/
                └── theme_cubit_test.dart
```

All mocks live in `test/mocks/mocks.dart`. Reuse them instead of declaring new `Mock` classes inside test files.

### Writing Tests

**UseCase Test:**

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mocks.dart';

void main() {
  late LoginUser usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginUser(mockRepository);
  });

  final testUser = TestData.testUser;

  test('should return User when login is successful', () async {
    // Arrange
    when(() => mockRepository.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => Right(testUser));

    // Act
    final result = await usecase(LoginParams(
      email: 'test@test.com',
      password: 'password123',
    ));

    // Assert
    expect(result, Right(testUser));
    verify(() => mockRepository.login(
      email: 'test@test.com',
      password: 'password123',
    )).called(1);
  });

  test('should return Failure when login fails', () async {
    // Arrange
    when(() => mockRepository.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

    // Act
    final result = await usecase(LoginParams(
      email: 'test@test.com',
      password: 'wrong',
    ));

    // Assert
    expect(result, const Left(ServerFailure(message: 'Error')));
  });
}
```

**BLoC Test:**

```dart
import 'package:bloc_test/bloc_test.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mocks.dart';

void main() {
  late AuthBloc bloc;
  late MockLoginUser mockLoginUser;

  setUpAll(registerFallbackValues);

  setUp(() {
    mockLoginUser = MockLoginUser();
    bloc = AuthBloc(
      loginUser: mockLoginUser,
      registerUser: MockRegisterUser(),
      logoutUser: MockLogoutUser(),
      getCurrentUser: MockGetCurrentUser(),
    );
  });

  tearDown(() => bloc.close());

  final testUser = TestData.testUser;

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, Authenticated] when login succeeds',
    build: () {
      when(() => mockLoginUser(any()))
          .thenAnswer((_) async => Right(testUser));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoginEvent(
      email: 'test@test.com',
      password: 'password',
    )),
    expect: () => [
      const AuthLoading(),
      Authenticated(testUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when login fails',
    build: () {
      when(() => mockLoginUser(any()))
          .thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
      return bloc;
    },
    act: (bloc) => bloc.add(const LoginEvent(
      email: 'test@test.com',
      password: 'wrong',
    )),
    expect: () => [
      const AuthLoading(),
      const AuthError('Error'),
    ],
  );
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/domain/usecases/login_user_test.dart

# Run with coverage
flutter test --coverage

# Browse coverage as HTML (needs coverage/lcov.info from the previous command)
python3 scripts/generate_coverage_html.py

# Run with verbose output
flutter test --reporter expanded
```

CI (`.github/workflows/`) runs code generation, `dart format --set-exit-if-changed lib/ test/`, `flutter analyze --fatal-infos` and `flutter test --coverage` on every push and PR to `main` and `develop`.

---

## Commands Reference

### Development

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run --dart-define-from-file=.env.dev` | Run app in debug mode |
| `flutter run --release --dart-define-from-file=.env.dev` | Run app in release mode |
| `flutter run -d <device> --dart-define-from-file=.env.dev` | Run on specific device |

### Code Generation

| Command | Description |
|---------|-------------|
| `dart run build_runner build --delete-conflicting-outputs` | Generate code once |
| `dart run build_runner watch --delete-conflicting-outputs` | Generate code continuously |

### Testing

| Command | Description |
|---------|-------------|
| `flutter test` | Run all tests |
| `flutter test --coverage` | Run tests with coverage |
| `python3 scripts/generate_coverage_html.py` | Generate HTML coverage report from `coverage/lcov.info` |
| `flutter test test/path/to/test.dart` | Run specific test |

### Analysis

| Command | Description |
|---------|-------------|
| `flutter analyze --fatal-infos` | Analyze code (same strictness as CI) |
| `dart format lib test` | Format Dart files |
| `flutter clean` | Clean build artifacts |

### Build

Pass an environment file for each build, e.g. `.env.prod` with `{ "BASE_URL": "https://api.yourapp.com" }`:

| Command | Description |
|---------|-------------|
| `flutter build apk --dart-define-from-file=.env.prod` | Build Android APK |
| `flutter build appbundle --dart-define-from-file=.env.prod` | Build Android App Bundle |
| `flutter build ios --dart-define-from-file=.env.prod` | Build iOS |
| `flutter build web --dart-define-from-file=.env.prod` | Build Web |

Only `.env.*.example` files are committed. Keep real `.env.*` files out of git.

---

## Customization Guide

### Change App Name

1. **pubspec.yaml:**
   ```yaml
   name: your_app_name
   ```

2. **lib/app.dart:**
   ```dart
   MaterialApp(
     title: 'Your App Name',
     ...
   )
   ```

3. **Android** (`android/app/src/main/AndroidManifest.xml`, generated by `flutter create`):
   ```xml
   <application android:label="Your App Name" ...>
   ```

4. **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>CFBundleDisplayName</key>
   <string>Your App Name</string>
   ```

### Change API URL

Don't edit the code. Set `BASE_URL` in your env file and pass it at build or run time:

```json
// .env.dev
{
  "BASE_URL": "https://dev-api.yourapp.com"
}
```

```bash
flutter run --dart-define-from-file=.env.dev
```

`lib/core/constants/api_constants.dart` reads it with `String.fromEnvironment('BASE_URL', defaultValue: 'https://api.example.com')`. Endpoint paths (`/auth/login`, `/auth/refresh`, ...) and timeouts are also defined in that file.

### Change Colors

**Light theme:** `lib/core/theme/light/color_scheme_light.dart`

```dart
class ColorSchemeLight {
  final Color primary = const Color(0xFF6200EE);      // Your primary color
  final Color secondary = const Color(0xFF03DAC6);    // Your secondary color
  final Color background = const Color(0xFFFFFFFF);
  final Color surface = const Color(0xFFFAFAFA);
  final Color error = const Color(0xFFB00020);
  // ... more colors
}
```

**Dark theme:** `lib/core/theme/dark/color_scheme_dark.dart`

### Add New Translation

1. Create translation file: `assets/translations/xx.json`
   ```json
   {
     "auth": {
       "login": "Login",
       "register": "Register"
     },
     "home": {
       "welcome": "Welcome, {name}!"
     }
   }
   ```

2. Add to `lib/core/localization/supported_locales.dart`:
   ```dart
   enum SupportedLocale {
     english(...),
     turkish(...),
     newLanguage(
       locale: Locale('xx'),
       languageCode: 'xx',
       name: 'Language Name',
       nativeName: 'Native Name',
       flag: '🏳️',
     ),
   }
   ```

3. Add to `main.dart` supportedLocales

---

## FAQ

**Q: Why Clean Architecture?**
> It provides clear separation of concerns, making the code testable, maintainable, and scalable. Each layer can be modified independently without affecting others.

**Q: When should I use BLoC vs Cubit?**
> Use **Cubit** for simple state (theme toggle, counter). Use **BLoC** for complex state with event-driven logic (authentication, forms with validation).

**Q: Why GetIt for dependency injection?**
> Simple API, no code generation required, supports all registration types. For larger projects, consider Injectable for code generation.

**Q: Why Freezed for models?**
> Generates immutable data classes with `copyWith`, `==`, `hashCode`, `toString`, and JSON serialization. Reduces boilerplate significantly.

**Q: How do I handle authentication guards?**
> `AuthGuard` (`lib/config/routes/auth_guard.dart`) is registered in GetIt and injected into `AppRouter`. Add it to a route's `guards` list, or nest the route under `MainNavigationRoute`, which is already guarded:
```dart
AutoRoute(
  page: ProductsRoute.page,
  guards: [_authGuard],
)
```

**Q: Where are auth tokens stored? What happens when they expire?**
> Tokens are stored in the Keychain/Keystore via `SecureCacheManager`, never in SharedPreferences. When a request returns 401, `DioClient` refreshes the token automatically and retries the request once. If the refresh fails, the tokens and pending sync operations are cleared.

**Q: How do I add global error handling?**
> `main.dart` sets `FlutterError.onError`, which catches framework errors. Hook your crash reporter (Crashlytics, Sentry, ...) in there; there is a `TODO` at that spot. Errors from async code outside the framework are not captured yet. Add `PlatformDispatcher.instance.onError` if you need them.

---

## Troubleshooting

### Common Issues

**1. Code generation not working**

```bash
# Clean and regenerate
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**2. "Could not find the correct Provider"**

Make sure the BLoC is provided above the widget that uses it:

```dart
BlocProvider(
  create: (_) => sl<AuthBloc>(),
  child: LoginPage(),  // AuthBloc available here
)
```

**3. Dependency not registered**

Check `injection_container.dart` for:
- Correct registration order
- All dependencies registered
- `initDependencies()` called in `main.dart`

**4. Route not found**

After adding new routes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**5. Translation key not found**

Check:
- Key exists in all JSON files
- Key path matches `LocaleKeys` constant
- App restarted after adding new keys

---

## License

MIT License - see [LICENSE](LICENSE) file.

---

Made with ❤️ for Flutter developers
