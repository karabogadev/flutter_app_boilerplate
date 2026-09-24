# Flutter App Boilerplate

Production-ready Flutter starter that follows the official [Flutter app architecture guide](https://docs.flutter.dev/app-architecture) and [performance best practices](https://docs.flutter.dev/perf/best-practices), with BLoC as the state layer.

---

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Architecture](#architecture)
  - [Layers](#layers)
  - [Data Flow: Login](#data-flow-login)
  - [Design Decisions](#design-decisions)
- [Project Structure](#project-structure)
- [Core Modules](#core-modules)
  - [Result & Error Handling](#1-result--error-handling)
  - [Network (Dio)](#2-network-dio)
  - [Storage](#3-storage)
  - [Theme & Fonts](#4-theme--fonts)
  - [Localization](#5-localization)
  - [Navigation & Auth Guard](#6-navigation--auth-guard)
  - [Reusable Widgets](#7-reusable-widgets)
  - [Offline-First Sync](#8-offline-first-sync)
- [Dependency Injection](#dependency-injection)
- [How to Add a New Feature](#how-to-add-a-new-feature)
- [Performance](#performance)
- [Testing](#testing)
- [AI-Assisted Development](#ai-assisted-development)
- [Commands Reference](#commands-reference)
- [Customization Guide](#customization-guide)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

| Component | Technology | Notes |
|-----------|------------|-------|
| Architecture | [Flutter app architecture](https://docs.flutter.dev/app-architecture) | Views + view models (BLoC), repositories, data sources |
| State Management | flutter_bloc | Blocs/cubits act as view models |
| Error Handling | Sealed `Result<T>` + `Failure` | Exhaustive `switch`, no dartz |
| Dependency Injection | get_it | Used only at the composition root |
| Routing | auto_route | Typed routes, `AuthGuard` |
| HTTP Client | Dio | Single-flight token refresh, isolate JSON decoding for big bodies |
| Key-value Storage | shared_preferences | Non-sensitive data, synchronous reads |
| Secure Storage | flutter_secure_storage | Keychain/Keystore for tokens |
| Offline Database | Hive CE | Persistent sync queue |
| Connectivity | connectivity_plus | Non-blocking status monitoring |
| Localization | easy_localization | English and Turkish |
| Fonts | Inter, bundled | No runtime font fetching |
| Code Generation | freezed, json_serializable, auto_route_generator, hive_ce_generator | |
| Testing | flutter_test, bloc_test, mocktail, integration_test | Fakes over mocks, a11y and perf checks |

---

## Getting Started

### Prerequisites

| Tool | Version | Check Command |
|------|---------|---------------|
| Flutter | 3.35+ (developed on 3.47) | `flutter --version` |
| Dart | 3.9+ | `dart --version` |
| Android SDK / Xcode | Current stable | `flutter doctor` |

### Installation

```bash
git clone https://github.com/yourusername/flutter_app_boilerplate.git
cd flutter_app_boilerplate

flutter pub get
dart run build_runner build --delete-conflicting-outputs

cp .env.dev.example .env.dev
```

`android/` and `ios/` are committed. They were generated with `flutter create --platforms=android,ios --org com.example .`; change the bundle identifiers before shipping (see [Customization](#change-app-name-and-bundle-id)).

### Running the App

`BASE_URL` is a compile-time define. Pass it through an env file:

```bash
flutter run --dart-define-from-file=.env.dev
flutter run --release --dart-define-from-file=.env.dev
flutter run -d <device_id> --dart-define-from-file=.env.dev
```

Without the flag, `BASE_URL` falls back to `https://api.example.com`.

---

## Architecture

### Layers

```
┌──────────────────────────────────────────────────────────────────┐
│ UI LAYER                                                         │
│   Pages (views)  ──events──▶  Blocs / Cubits (view models)       │
│        ▲                              │                          │
│        └──────────── states ──────────┘                          │
├──────────────────────────────────────────────────────────────────┤
│ DOMAIN (optional, thin)                                          │
│   Entities · repository interfaces                               │
├──────────────────────────────────────────────────────────────────┤
│ DATA LAYER                                                       │
│   Repositories (single source of truth, return Result<T>)        │
│        │                                                         │
│   Data sources (stateless: Dio, SharedPreferences, Keychain,     │
│   Hive; throw exceptions)                                        │
└──────────────────────────────────────────────────────────────────┘
```

| Layer | Contains | Rules |
|-------|----------|-------|
| **UI** | Pages, widgets, blocs/cubits | Pages hold no business logic. Blocs call repositories directly |
| **Domain** | Entities, repository interfaces | Use cases are *not* added by default (see below) |
| **Data** | Repository implementations, data sources, models | Repositories own their data and are the only place it changes |

### Data Flow: Login

```
LoginPage ──LoginEvent──▶ AuthBloc ──login()──▶ AuthRepository
                                                  │
                                                  ├─ AuthRemoteDataSource ─▶ DioClient ─▶ API
                                                  ├─ saves tokens (SecureCacheManager) and user (CacheManager)
                                                  ├─ DioClient.setAuthToken()
                                                  └─ emits the new user on sessionChanges
                                                          │
AuthBloc ◀── Result<User> / sessionChanges ───────────────┘
   │ emits Authenticated
   ▼
_AuthNavigationListener (app.dart) ──replaceAll([MainNavigationRoute()])
```

Signing out, and a session that expires because the server rejected the refresh token, travel the same path in reverse. The repository emits `null`, the bloc emits `Unauthenticated`, and the listener shows Login. No page navigates on auth state by itself.

### Design Decisions

| Decision | Why |
|----------|-----|
| **No use cases by default** | The docs rate the domain layer as *conditional*: one-line use cases that only forward to a repository are pure overhead. Add one when logic combines several repositories or is reused across blocs. |
| **`Result<T>` instead of `Either`** | The [Result pattern](https://docs.flutter.dev/app-architecture/design-patterns/result) with Dart 3 sealed classes gives exhaustive `switch` checks without a functional-programming dependency. |
| **One source of truth for auth** | The guard, the bloc and the token-refresh interceptor all go through `AuthRepository`. Session state can't diverge. |
| **get_it only at the composition root** | Keeps the benefits of DI (swap implementations, test with fakes) without a global locator inside widgets or blocs. |
| **Blocs created by `BlocProvider`** | The widget tree owns their lifecycle (created lazily, closed automatically), so there are no stray instances in the locator. |

---

## Project Structure

```
lib/
├── main.dart                  # Composition root: init, error reporting, runApp
├── app.dart                   # Root widget: providers, theme, router, auth navigation
├── injection_container.dart   # get_it registrations (services + repositories)
├── config/routes/
│   ├── app_router.dart        # Route tree
│   └── auth_guard.dart        # Blocks signed-out users
├── core/
│   ├── cache/                 # CacheManager (prefs), SecureCacheManager (keychain), keys
│   ├── constants/             # API constants, spacing, durations
│   ├── database/              # HiveManager, box names, type IDs
│   ├── error/                 # Exceptions, sealed Failures, translated failure messages
│   ├── extensions/            # BuildContext, DateTime, String helpers
│   ├── localization/          # LocaleKeys, SupportedLocale
│   ├── logging/               # AppLogger (dart:developer)
│   ├── network/               # DioClient, TokenRefreshInterceptor
│   ├── offline/               # ConnectivityService, SyncQueue, OfflineManager, cubit
│   ├── result/                # Result<T>
│   ├── theme/                 # AppTheme, AppColors, AppTextTheme
│   └── widgets/               # AppButton, AppTextField, AppCachedImage, offline widgets, ...
└── features/
    ├── auth/
    │   ├── data/              # datasources/, models/, repositories/
    │   ├── domain/            # entities/, repositories/ (interfaces)
    │   └── presentation/      # bloc/, pages/, widgets/
    ├── home/                  # presentation only
    ├── main_navigation/       # bottom navigation shell
    ├── onboarding/
    ├── settings/              # data/ (SettingsRepository), presentation/ (ThemeCubit, page)
    └── splash/

test/                          # mirrors lib/
├── fakes/                     # In-memory repository fakes (preferred over mocks)
├── helpers/                   # pumpApp + localization, accessibility checks, test data
├── mocks/                     # mocktail mocks for edge collaborators
└── fixtures/                  # JSON fixtures
integration_test/              # Performance traces (run on a device)
test_driver/                   # Writes timeline summaries
```

---

## Core Modules

### 1. Result & Error Handling

| Type | Thrown / returned by | Purpose |
|------|----------------------|---------|
| `ServerException`, `NetworkException`, `CacheException`, `ParseException` | Data sources | Low-level errors |
| `Result<T>` = `Ok<T>` \| `Err<T>` | Repositories | Success or a user-facing `Failure` |
| `Failure` (sealed): `ServerFailure`, `NetworkFailure`, `CacheFailure`, `ValidationFailure`, `UnexpectedFailure` | Inside `Err` | Message shown to the user |

```dart
// Data source: throws
Future<ProductModel> fetch(String id) async {
  final response = await _dioClient.get<Map<String, dynamic>>('/products/$id');
  return ProductModel.fromJson(response.data!);
}

// Repository: converts exceptions into a Result
Future<Result<Product>> getProduct(String id) =>
    Result.guard(() async => (await _remote.fetch(id)).toEntity());

// Bloc: exhaustive switch
switch (await _repository.getProduct(id)) {
  case Ok(:final value):
    emit(ProductLoaded(value));
  case Err(:final failure):
    emit(ProductError(failure));
}
```

`Result.guard` catches `Exception`s only. `Error`s are programming bugs and are left to surface.

Blocs keep the `Failure` itself in their state (e.g. `AuthError(failure)`); the UI turns it into text with `failure.localizedMessage` (`core/error/failure_message.dart`). Network and unexpected failures get a translated generic message, 5xx responses hide server details, and 4xx/validation messages from the backend are shown as-is.

### 2. Network (Dio)

`DioClient` is injected into data sources. It exposes `get`, `post`, `put`, `patch`, `delete`, `setAuthToken` and `clearAuthToken`, and maps `DioException`s to `ServerException`/`NetworkException`.

| Interceptor | Behavior |
|-------------|----------|
| Logging (debug builds only) | Logs method, URL, status. The `Authorization` header is redacted |
| `TokenRefreshInterceptor` | On a 401 for a request that carried a token: refreshes once and retries |

Token refresh details:

- **Single-flight.** Concurrent 401s wait for one refresh call instead of each starting their own.
- **Stale tokens.** A request sent with an already-replaced token is retried with the current one, without refreshing again.
- **No token, no refresh.** A 401 without an `Authorization` header (e.g. wrong password on login) is passed through untouched.
- **Session expiry.** The session is expired (`AuthRepository.expireSession`) only when the server rejects the refresh token. Network errors keep the session.

JSON bodies of 50 KB or more are decoded off the UI isolate by Dio's default `FusedTransformer`.

### 3. Storage

| Store | Class | Backed by | Use for |
|-------|-------|-----------|---------|
| Key-value | `CacheManager` | SharedPreferences | Theme, onboarding flag, cached profile |
| Secure | `SecureCacheManager` | Keychain / Keystore | Access and refresh tokens |
| Database | `HiveManager` | Hive CE | Sync queue, feature boxes |

`CacheManager` is built from an already loaded `SharedPreferences`, so reads are synchronous and there is no "not initialized" state:

```dart
final cache = CacheManager(await SharedPreferences.getInstance());
await cache.setBool(CacheKeys.onboardingCompleted, value: true);
final user = cache.getObject(CacheKeys.user, UserModel.fromJson); // null if missing or outdated
```

Never put tokens in `CacheManager`: SharedPreferences is plain text on disk.

### 4. Theme & Fonts

- `AppTheme.light` and `AppTheme.dark` are `static final`: built once, never on rebuild.
- `AppColors.light` / `AppColors.dark` hold the palette. Text colors meet WCAG AA contrast (4.5:1).
- `AppTextTheme` is a `const` Material 3 type scale using **Inter**, bundled in `assets/fonts/inter` (subset to Latin + Latin Extended, ~225 KB per weight) and declared in `pubspec.yaml`. Its OFL license is registered in `main.dart`.
- `ThemeCubit` reads the saved `ThemeMode` synchronously, so the first frame already uses it.

```dart
context.read<ThemeCubit>().setThemeMode(ThemeMode.dark);
context.colorScheme.primary;   // context_extensions.dart
context.textTheme.titleLarge;
```

### 5. Localization

All UI strings go through `LocaleKeys` constants, with entries in `assets/translations/en.json` and `tr.json`:

```dart
Text(LocaleKeys.authLogin.tr())
Text(LocaleKeys.homeActivity.tr(namedArgs: {'index': '1'}))
Text(LocaleKeys.homeHoursAgo.plural(3))

await context.setLocale(SupportedLocale.turkish.locale); // persisted by easy_localization
```

**Add a language:**
1. Create `assets/translations/xx.json` with every key.
2. Add a value to the `SupportedLocale` enum. `main.dart` reads `SupportedLocale.locales`, so nothing else changes.

### 6. Navigation & Auth Guard

Routes live in `lib/config/routes/app_router.dart`. `MainNavigationRoute` and its `Home`/`Settings` tabs are guarded by `AuthGuard`, which reads `AuthRepository.isAuthenticated` synchronously and redirects signed-out users to Login.

Navigation on session changes happens in exactly one place, `_AuthNavigationListener` in `app.dart`:

| Auth state becomes | Router |
|--------------------|--------|
| `Authenticated` (login, register, restored session) | `replaceAll([MainNavigationRoute()])` |
| `Unauthenticated` (logout, expired session, no stored session) | `replaceAll([LoginRoute()])` |

Launch flow: `SplashPage` → onboarding (first launch) or session restore → Home or Login. There is no artificial splash delay.

### 7. Reusable Widgets

| Widget | Purpose |
|--------|---------|
| `AppButton` | Primary / secondary / text buttons with a loading state |
| `AppTextField` | Styled input; `.email` and `.password` presets (with an accessible visibility toggle) |
| `AppCachedImage` | Cached network image, decoded at display size (`memCacheWidth` from the device pixel ratio) |
| `LoadingIndicator`, `AppErrorWidget` | Loading and error states (`AppErrorWidget.network/.server/.empty` ship translated texts) |
| `OfflineBanner`, `OfflineIndicatorDot`, `OfflineAwareButton`, `ConnectivityListener` | Connectivity UI |

### 8. Offline-First Sync

`OfflineManager` coordinates `ConnectivityService`, `SyncQueue` and `HiveManager`:

- `ConnectivityService.init()` returns immediately. Its first check, which includes a DNS lookup with up to 5 s timeout, runs in the background, so it never delays app start.
- `SyncQueue` persists operations in Hive, retries with exponential backoff, recovers operations left `inProgress` after a crash, and processes automatically when connectivity returns.
- Pending operations are cleared when the session ends, so they are never sent with another user's token.

```dart
await offlineManager.queueOperation(
  operationType: SyncOperationType.create,
  entityType: 'product',
  entityId: product.id,
  data: product.toJson(),
  endpoint: '/products',
);
```

An offline-first repository, following the [offline-first pattern](https://docs.flutter.dev/app-architecture/design-patterns/offline-first):

```dart
class ProductRepositoryImpl implements ProductRepository {
  // Read: local first, then refresh from the API.
  Stream<List<Product>> watchProducts() async* {
    final local = await _local.getProducts();
    if (local.isNotEmpty) yield local;
    switch (await Result.guard(_remote.getProducts)) {
      case Ok(:final value):
        await _local.saveProducts(value);
        yield value;
      case Err():
        if (local.isEmpty) yield const [];
    }
  }

  // Write: local first, then queue for sync.
  Future<Result<void>> createProduct(Product product) => Result.guard(() async {
        await _local.saveProduct(product);
        await _offlineManager.queueOperation(
          operationType: SyncOperationType.create,
          entityType: 'product',
          entityId: product.id,
          data: ProductModel.fromEntity(product).toJson(),
          endpoint: '/products',
        );
      });
}
```

The `ConnectivityCubit` exposes status to the UI (`state.isOffline`, `state.pendingOperations`, `sync()`, `retryFailed()`).

---

## Dependency Injection

`injection_container.dart` registers **services and repositories** as lazy singletons, then runs the async initialization the first frame needs, in parallel:

```dart
final (prefs, _) = await (
  SharedPreferences.getInstance(),
  sl<OfflineManager>().init(),
).wait;
```

Rules:

| What | How it gets its dependencies |
|------|------------------------------|
| Services, data sources, repositories | Constructor parameters, wired in `injection_container.dart` |
| `App` | Constructor parameters from `main.dart` |
| Blocs / cubits | Created by `BlocProvider`, using `context.read<SomeRepository>()` |
| Widgets | `context.read` / `context.watch` from `RepositoryProvider` / `BlocProvider` |

`sl` is only called in `main.dart` and `injection_container.dart`. Blocs are never registered in get_it.

`registerLazySingleton` factories run on first resolution, so registration order matters only for types resolved eagerly during init (`OfflineManager.init()`, `DioClient.configureTokenRefresh`).

---

## How to Add a New Feature

Example: a "Products" list.

**1. Entity** (`features/products/domain/entities/product.dart`) and **repository interface**:

```dart
abstract interface class ProductRepository {
  Future<Result<List<Product>>> getProducts();
}
```

**2. Model** (`data/models/product_model.dart`): a freezed + json_serializable class with `toEntity()`, as in `user_model.dart`.

**3. Data source** (`data/datasources/product_remote_datasource.dart`): throws exceptions.

```dart
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._dioClient);
  final DioClient _dioClient;

  Future<List<ProductModel>> getProducts() async {
    final response = await _dioClient.get<List<dynamic>>('/products');
    return [
      for (final json in response.data ?? const [])
        ProductModel.fromJson(json as Map<String, dynamic>),
    ];
  }
}
```

**4. Repository** (`data/repositories/product_repository_impl.dart`): returns `Result`.

```dart
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);
  final ProductRemoteDataSource _remote;

  @override
  Future<Result<List<Product>>> getProducts() => Result.guard(
        () async => [for (final m in await _remote.getProducts()) m.toEntity()],
      );
}
```

**5. Bloc** (`presentation/bloc/`): sealed events and states in `part` files, calls the repository directly.

```dart
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repository) : super(const ProductsLoading());
  final ProductRepository _repository;

  Future<void> load() async {
    emit(const ProductsLoading());
    switch (await _repository.getProducts()) {
      case Ok(:final value):
        emit(ProductsLoaded(value));
      case Err(:final failure):
        emit(ProductsError(failure));
    }
  }
}
```

**6. Register** the data source and repository in `injection_container.dart`, and expose the repository in `app.dart`:

```dart
..registerLazySingleton<ProductRemoteDataSource>(() => ProductRemoteDataSource(sl()))
..registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl()))
```

```dart
// app.dart → MultiRepositoryProvider
RepositoryProvider<ProductRepository>.value(value: widget.productRepository),
```

**7. Page** (`presentation/pages/products_page.dart`): creates its cubit and renders lazily.

```dart
@RoutePage()
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsCubit(context.read<ProductRepository>())..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.productsTitle.tr())),
        body: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) => switch (state) {
            ProductsLoading() => const Center(child: LoadingIndicator()),
            ProductsError(:final failure) =>
                AppErrorWidget(message: failure.localizedMessage),
            ProductsLoaded(:final products) => ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) => ProductTile(products[index]),
              ),
          },
        ),
      ),
    );
  }
}
```

**8. Route**: add `AutoRoute(page: ProductsRoute.page)` to `app_router.dart` (nest it under `MainNavigationRoute` to inherit `AuthGuard`), add the strings to both translation files, then run `dart run build_runner build --delete-conflicting-outputs`.

**9. Tests**: a fake repository in `test/fakes/`, a repository test with mocked data sources, a `bloc_test`, and a widget test with `expectMeetsAccessibilityGuidelines`.

---

## Performance

What the boilerplate already does:

| Area | Practice |
|------|----------|
| Startup | Only first-frame work is awaited, in parallel. No network before `runApp`. No artificial splash delay. Theme mode read synchronously |
| Rebuilds | Themes built once. `routerConfig` created once. `BlocSelector` for narrow rebuilds. `ValueListenableBuilder` for page indicators |
| Layout | `CustomScrollView` + slivers instead of nested `shrinkWrap` lists. Private widget classes instead of helper methods |
| Images | `AppCachedImage` decodes at display size |
| Fonts | Bundled Inter, `const` text styles, no runtime fetching |
| Parsing | Large JSON decoded off the UI isolate |
| Rendering | No `Opacity`/clip layers in list items |

**Measure on a real device in profile mode:**

```bash
flutter run --profile --dart-define-from-file=.env.dev          # DevTools → Performance
flutter drive --profile \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/home_scroll_perf_test.dart          # writes build/home_scroll_timeline.timeline_summary.json
flutter build appbundle --analyze-size --dart-define-from-file=.env.prod
```

**Release builds** (obfuscation, smaller binaries, keep the symbols for crash reports):

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=.env.prod
```

---

## Testing

```
test/
├── app_test.dart                     # End-to-end routing: onboarding, login, expiry, logout
├── config/routes/auth_guard_test.dart
├── core/                             # cache, network (DioClient, TokenRefreshInterceptor), result, offline
├── features/
│   ├── auth/data/…                   # AuthRepositoryImpl (mocked data sources)
│   ├── auth/presentation/…           # AuthBloc (fake repository), LoginPage (widget + a11y)
│   └── settings/…                    # SettingsRepository, ThemeCubit
├── fakes/fake_auth_repository.dart
└── helpers/                          # pump_app.dart, accessibility.dart, test_helpers.dart
```

Conventions:

- **Fakes over mocks** for repositories (`FakeAuthRepository`), as the architecture docs recommend. Use `mocktail` for edge collaborators (storage, network, router).
- **Widget tests** call `setUpAll(setUpLocalization)` and `tester.pumpApp(...)`, which loads the real translation files. Create blocs inside the test body so their events run in the test's fake-async zone.
- **Accessibility**: `expectMeetsAccessibilityGuidelines(tester)` checks tap-target sizes, labels and text contrast.

```bash
flutter test
flutter test test/features/auth/presentation/bloc/auth_bloc_test.dart
flutter test --plain-name "concurrent 401s share one refresh"
flutter test --coverage && python3 scripts/generate_coverage_html.py
```

---

## AI-Assisted Development

The repository is set up for AI coding agents, following [docs.flutter.dev/ai](https://docs.flutter.dev/ai/get-started):

| File | Purpose |
|------|---------|
| `AGENTS.md` | Tool-agnostic project rules: architecture, performance and testing conventions, commands |
| `CLAUDE.md` | Imports `AGENTS.md` and adds the Claude Code setup and hot-reload rule |

For Claude Code, install Flutter's agent plugin, which provides the Dart MCP server (analysis, tests, hot reload, pub.dev search) and Flutter/Dart skills:

```bash
claude plugin marketplace add flutter/agent-plugins
claude plugin install dart-flutter@dart-flutter
```

Other tools can run the same MCP server with `dart mcp-server`.

---

## Commands Reference

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `dart run build_runner build --delete-conflicting-outputs` | Generate code once |
| `dart run build_runner watch --delete-conflicting-outputs` | Generate code continuously |
| `flutter run --dart-define-from-file=.env.dev` | Run the app |
| `dart format lib test` | Format |
| `flutter analyze --fatal-infos` | Analyze (strict) |
| `flutter test --coverage` | Run tests with coverage |
| `python3 scripts/generate_coverage_html.py` | HTML coverage report |
| `flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/home_scroll_perf_test.dart` | Frame-timing trace on a device |
| `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=.env.prod` | Release build |
| `flutter pub outdated` | Check dependency versions |

> Code generators are held at analyzer 12: `hive_ce_generator` and `auto_route_generator` don't share a newer analyzer version yet. Runtime dependencies are all on their latest versions.

---

## Customization Guide

### Change App Name and Bundle ID

- Display name: `android/app/src/main/AndroidManifest.xml` (`android:label`) and `ios/Runner/Info.plist` (`CFBundleDisplayName`).
- In-app title: `app_name` in the translation files.
- Bundle ID: `applicationId`/`namespace` in `android/app/build.gradle.kts`, and `PRODUCT_BUNDLE_IDENTIFIER` in the Xcode project (currently `com.example.flutter_app_boilerplate`).

### Change API URL

Set `BASE_URL` in `.env.dev` / `.env.prod` and pass `--dart-define-from-file`. Endpoint paths and timeouts are in `lib/core/constants/api_constants.dart`. Only `.env.*.example` files are committed.

### Change Colors and Font

- Colors: edit `AppColors.light` / `AppColors.dark` in `lib/core/theme/app_colors.dart`. Keep text colors at 4.5:1 contrast; the widget a11y tests check it.
- Font: replace the files in `assets/fonts/`, update the `fonts:` section in `pubspec.yaml` and `AppTextTheme.fontFamily`, and register the new license in `main.dart`.

### Add a Translation Key

1. Add the key to `en.json` **and** `tr.json`.
2. Add a constant to `LocaleKeys`.
3. Use `LocaleKeys.yourKey.tr()`.

---

## FAQ

**Q: Why no use cases?**
> The Flutter architecture guide marks the domain layer as optional. A use case that only forwards to a repository adds a class, a test and a mock without adding logic. Add use cases when logic spans multiple repositories or is shared across blocs.

**Q: Why BLoC if the docs use `ChangeNotifier`?**
> The docs allow any state-management approach in the view-model role and list flutter_bloc explicitly. Blocs here are the view models: pages stay free of logic and state flows one way.

**Q: Where are auth tokens stored, and what happens when they expire?**
> In the Keychain/Keystore via `SecureCacheManager`. On a 401, `TokenRefreshInterceptor` refreshes once (shared by concurrent requests) and retries. If the server rejects the refresh token, the session ends and the app returns to Login.

**Q: How are errors reported?**
> `main.dart` routes `FlutterError.onError` and `PlatformDispatcher.instance.onError` to `AppLogger`. Forward them to Crashlytics or Sentry there.

**Q: Why is the Android `INTERNET` permission in the main manifest?**
> The Flutter template only adds it to the debug and profile manifests; release builds need it to reach the API.

---

## Troubleshooting

**Code generation fails or routes are missing**

```bash
flutter clean && flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**"Could not find the correct Provider"**: the widget is above the `BlocProvider`/`RepositoryProvider` it reads. App-wide providers are in `app.dart`; feature blocs should be provided by their page.

**Widget test renders nothing / translation keys shown**: call `setUpAll(setUpLocalization)` and use `tester.pumpApp`, which loads translations from disk.

**Bloc state doesn't change in a widget test**: create the bloc inside the test body (not in `setUp`), so its events run in the test's fake-async zone.

**Translation key shown instead of text**: the key is missing from one of the JSON files or `LocaleKeys` has a typo.

---

## License

MIT License - see [LICENSE](LICENSE) file.
