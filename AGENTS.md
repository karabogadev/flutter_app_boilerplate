# Repository Guidelines

## Project Structure & Module Organization
`lib/` contains application code. Keep shared infrastructure in `lib/core/`, app-wide wiring in `lib/config/` and `lib/injection_container.dart`, and feature code under `lib/features/<feature>/` split into `data/`, `domain/`, and `presentation/`. Entry points live in `lib/main.dart` and `lib/app.dart`. Tests mirror production paths under `test/`, with helpers in `test/helpers/`, mocks in `test/mocks/`, and JSON fixtures in `test/fixtures/`. Static assets live in `assets/images/`, `assets/icons/`, and `assets/translations/`.

## Build, Test, and Development Commands
Run `flutter pub get` after pulling dependency changes. Use `dart run build_runner build --delete-conflicting-outputs` to regenerate `*.g.dart`, `*.freezed.dart`, and router files; use `watch` during active model or route work. Start the app with `flutter run`. Validate changes with `dart format lib test`, `flutter analyze --fatal-infos`, and `flutter test --coverage`. To inspect coverage in a browser, generate `coverage/lcov.info` first, then run `python3 scripts/generate_coverage_html.py`.

## Coding Style & Naming Conventions
Follow `analysis_options.yaml`, which enables strict casts, inference, and raw types plus `flutter_lints`. Use 2-space indentation and keep files formatted with `dart format`. Name files in `snake_case.dart`, classes and enums in `PascalCase`, variables and methods in `camelCase`, and constants in `lowerCamelCase` unless Dart requires otherwise. Do not manually edit generated files such as `*.g.dart`, `*.freezed.dart`, or `*.gr.dart`.

## Testing Guidelines
Use `flutter_test` for widget tests, `mocktail` for mocks, and `bloc_test` for bloc/cubit behavior. Name tests with the `_test.dart` suffix and mirror the source tree, for example `test/features/auth/domain/usecases/login_user_test.dart`. Add or update tests with every behavior change, especially around repositories, use cases, and blocs. CI currently runs `flutter test --coverage`; keep coverage from regressing on touched code.

## Commit & Pull Request Guidelines
Recent history follows Conventional Commits with optional scopes, such as `feat(auth): ...`, `refactor(core): ...`, and `test: ...`. Keep commits focused and use imperative summaries. Pull requests should include a short description, linked issue when applicable, test notes, and screenshots or recordings for UI changes. Confirm code generation, formatting, analysis, and tests pass before requesting review.

## Configuration Tips
Use `.env.dev.example` as the template for local environment values. Never commit secrets, build artifacts, or platform-specific local state.
