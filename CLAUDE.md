# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## Claude Code Setup
Install Flutter's official agent plugin, which bundles the Dart MCP server and the Flutter/Dart skills (https://docs.flutter.dev/ai/get-started):

```bash
claude plugin marketplace add flutter/agent-plugins
claude plugin install dart-flutter@dart-flutter
```

Prefer its MCP tools (`analyze_files`, `run_tests`, `dart_format`, `pub_dev_search`, `pub`) over ad-hoc shell commands. The plugin's skills (e.g. `flutter-add-widget-test`, `flutter-fix-layout-issues`) apply, but this repository's architecture overrides their defaults: BLoC instead of `ChangeNotifier`, get_it at the composition root instead of `provider`, auto_route instead of go_router, and easy_localization instead of gen-l10n.

## Hot Reload
Adapted from the official `flutter-hot-reload` rule:
- When an app is running (find it with the MCP `dtd` tool) and you edit files under `lib/`, call `hot_reload` afterwards.
- Call `hot_restart` instead after changes to `main()`, `initState`, global or static state, or `injection_container.dart` registrations.
- Skip reloading for edits under `test/`, `integration_test/`, or that only touch comments or whitespace.
