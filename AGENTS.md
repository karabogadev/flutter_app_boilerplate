# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains application code. Shared infrastructure lives in `lib/core/`, routing in `lib/config/routes/`, and feature code under `lib/features/<feature>/` split into `data/` (data sources, models, repository implementations), `domain/` (entities, repository interfaces), and `presentation/` (pages, blocs, widgets). `lib/main.dart` and `lib/injection_container.dart` form the composition root; `lib/app.dart` is the root widget. Tests mirror production paths under `test/`, with fakes in `test/fakes/`, helpers in `test/helpers/`, mocks in `test/mocks/`, and JSON fixtures in `test/fixtures/`. Performance integration tests live in `integration_test/` with their driver in `test_driver/`. Assets live in `assets/images/`, `assets/icons/`, `assets/fonts/`, and `assets/translations/`.

## Architecture
The design follows https://docs.flutter.dev/app-architecture with BLoC as the view-model layer. Read these rules before changing code:

- **Layers.** Pages are views; blocs/cubits are their view models; repositories are the single source of truth for their data; data sources are stateless wrappers around one API or store. There are no use cases: blocs call repositories directly. Add a use case only for logic that combines several repositories or is reused across blocs.
- **Errors.** Data sources throw the exceptions in `lib/core/error/exceptions.dart`. Repositories wrap work in `Result.guard` and return `Result<T>` (`Ok` / `Err` with a sealed `Failure`). Callers unwrap it with an exhaustive `switch`. `Error`s (bugs) are never caught.
- **Dependency injection.** `sl` (get_it) is only used in `main.dart` and `injection_container.dart`, which register services and repositories. Blocs are never registered: they are created by `BlocProvider`s (app-wide ones in `app.dart`). Widgets reach repositories through `RepositoryProvider` (`context.read<SettingsRepository>()`), everything else through constructors.
- **Auth session.** `AuthRepository` owns the session (in-memory `currentUser` plus `sessionChanges`). `AuthBloc` mirrors it, and `_AuthNavigationListener` in `app.dart` is the only code that navigates on sign-in or sign-out; pages never navigate on auth state. `AuthGuard` reads `isAuthenticated` synchronously. `TokenRefreshInterceptor` refreshes tokens single-flight and expires the session only when the server rejects the refresh token.
- **Storage.** `CacheManager` (SharedPreferences, synchronous reads) holds non-sensitive data; tokens go to `SecureCacheManager` only. Hive backs the offline sync queue (`OfflineManager`, `SyncQueue`); open feature boxes on demand with `HiveManager.openBox`.
- **UI strings.** Every user-visible string goes through a `LocaleKeys` constant with entries in both `assets/translations/en.json` and `tr.json`. easy_localization persists the selected language itself.
- **Theme.** `AppTheme.light` / `AppTheme.dark` are built once. Colors live in `AppColors` and meet WCAG AA contrast. The Inter font is bundled; do not add `google_fonts` or any runtime font fetching.

## Performance Rules
- Await only what the first frame needs in `main()`, run independent work in parallel (record `.wait`), and never do network I/O before `runApp`.
- Prefer `const`, small private widget classes over helper methods that return widgets, and `BlocSelector` / `buildWhen` to keep rebuilds narrow.
- Build lists lazily with slivers or `.builder` constructors; never nest `shrinkWrap` scrollables. Load remote images with `AppCachedImage`, which decodes at display size.
- Dio decodes JSON bodies of 50 KB or more off the UI isolate. Use `Isolate.run` for other heavy work.

## Build, Test, and Development Commands
- `flutter pub get` after dependency changes; `dart run build_runner build --delete-conflicting-outputs` to regenerate `*.g.dart`, `*.freezed.dart`, and `app_router.gr.dart` (use `watch` while editing models or routes).
- `cp .env.dev.example .env.dev`, then `flutter run --dart-define-from-file=.env.dev` (`BASE_URL` is a compile-time define).
- Validate with `dart format lib test`, `flutter analyze --fatal-infos`, and `flutter test --coverage`. Run one test with `flutter test test/path/to/file_test.dart --plain-name "test name"`.
- Coverage report: `python3 scripts/generate_coverage_html.py` after `flutter test --coverage`.
- Frame timings on a device: `flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/home_scroll_perf_test.dart`.
- Code generators are held at analyzer 12 because `hive_ce_generator` and `auto_route_generator` do not share a newer analyzer version yet; `flutter pub outdated` shows the rest as current.

## Coding Style & Naming Conventions
Follow `analysis_options.yaml` (strict casts, inference, and raw types, `flutter_lints`, plus rules such as `discarded_futures` and `avoid_dynamic_calls`). Keep files formatted with `dart format`. Name files in `snake_case.dart`, classes and enums in `PascalCase`, variables and methods in `camelCase`. Never edit generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`).

## Testing Guidelines
Mirror the source tree and use the `_test.dart` suffix. Prefer the in-memory fakes in `test/fakes/` for repositories; use `mocktail` only for edge collaborators such as storage, network, and the router. Use `bloc_test` for blocs. Widget tests that render text call `setUpAll(setUpLocalization)` and `tester.pumpApp(...)`, and create blocs inside the test body (not in `setUp`) so their events run in the test's fake-async zone. Every new screen gets an `expectMeetsAccessibilityGuidelines` check. Add or update tests with every behavior change.

## Commit & Pull Request Guidelines
History follows Conventional Commits with optional scopes, such as `feat(auth): ...`, `refactor(core): ...`, and `test: ...`. Keep commits focused and use imperative summaries. Pull requests should include a short description, linked issue when applicable, test notes, and screenshots or recordings for UI changes. Confirm code generation, formatting, analysis, and tests pass before requesting review.

## Configuration Tips
Use `.env.dev.example` as the template for local environment values. Never commit secrets, real `.env.*` files, build artifacts, or platform-specific local state.
