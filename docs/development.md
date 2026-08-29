# Development guide

This guide is for contributors who are already familiar with Flutter.

## Supported targets

The project targets:

- Flutter Web for primary development and integration;
- native Linux desktop; and
- native Windows desktop.

Android and iOS are not currently supported.

## Prerequisites

Install:

- a Flutter SDK compatible with the SDK constraint in `pubspec.yaml`;
- Node.js and npm;
- Chromium for Playwright; and
- platform-specific desktop build tools when building native binaries.

For Linux desktop builds on Ubuntu or Debian:

```bash
sudo apt-get update
sudo apt-get install -y libgtk-3-dev pkg-config ninja-build
```

For Windows desktop builds, install Visual Studio or Visual Studio Build Tools
with the **Desktop development with C++** workload and a Windows SDK. Flutter
Windows builds require MSVC and must run on Windows; MinGW cross-compilation
from Linux is not supported.

## Set up the repository

Install Flutter and Node dependencies:

```bash
flutter pub get
npm ci
npx playwright install chromium
```

The Makefile locates `flutter` on `PATH`, then falls back to
`$HOME/development/flutter/bin/flutter`. Override it when needed:

```bash
make analyze FLUTTER=/path/to/flutter/bin/flutter
```

## Run the web application

Start Flutter's web development server:

```bash
make run-web
```

For a production build served on port 8080:

```bash
make build-web
make serve
```

## Build desktop releases

Build Linux:

```bash
make build-linux
```

The relocatable bundle is written to:

```text
build/linux/x64/release/bundle/
```

Build Windows from Windows PowerShell:

```powershell
.\build-windows.ps1
```

Use `-Clean` to clean first and `-Run` to launch the completed executable:

```powershell
.\build-windows.ps1 -Clean -Run
```

## Run integration coverage

The project uses browser-level Playwright integration instead of Dart unit or
widget tests. Build the web release before running the suite:

```bash
make build-web
make test-e2e
```

Playwright starts a local server for `build/web`, runs Chromium, and exercises
real UI interactions and the simulation debug bridge.

Use a focused Playwright selector while developing:

```bash
npx playwright test e2e/factory_clicker.spec.js -g "Research Lab"
```

## Change game behavior

When adding a resource, recipe, machine, or technology:

1. Update the corresponding model in `lib/models/`.
2. Update processing in `lib/simulation/game_engine.dart`.
3. Add or update controls in `lib/ui/widgets/`.
4. Ensure the factory topology represents the new inputs and outputs.
5. Add a Playwright integration that follows the real player path.
6. Run `make analyze`, `make build-web`, and `make test-e2e`.

Keep the simulation authoritative. Visual effects may read state but must not
change inventory, allocations, progress, or unlocks.

## Troubleshooting

### Port 8080 is already in use

Find the specific listening process and stop it before running Playwright or
`make serve`.

### Linux build cannot find GTK

Install the Linux prerequisites listed above, run `flutter clean`, and rebuild.
The build must remain inside `build/linux`; it must not install into
`/usr/local`.

### Linux reports missing Noto characters

The repository bundles Noto Sans and Noto Color Emoji in `assets/fonts/`.
Run `flutter clean` before rebuilding an older local bundle so the fonts are
copied into the release.

### Windows cannot find Flutter

Run `build-windows.ps1` from Windows PowerShell and ensure the Windows Flutter
SDK is on the Windows `PATH`. A Flutter installation available only inside WSL
cannot build the Windows runner.
