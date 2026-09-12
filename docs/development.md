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

## Deploy to GitHub Pages

The public web game is hosted at:

<https://tranquility2.github.io/factory-clicker/>

The repository can remain private; the deployed game and its bundled assets
are public. GitHub Pages for private repositories requires an eligible GitHub
plan.

In repository **Settings > Pages**, select **GitHub Actions** as the build and
deployment source. The workflow in `.github/workflows/deploy-web.yml` then:

1. Runs on pushes to `main`, version tags (`v*`), or manually from **Actions > Build and deploy web**.
2. Installs Flutter 3.47.1 and the dependency versions in `pubspec.lock`.
3. Builds the web release using the Pages base path (`/factory-clicker/`).
4. Uploads only `build/web`, deploying `main` to Pages or publishing a tagged web release.

Deployment is restricted to `main`. Actions are pinned to commit hashes, and
the workflow uses the built-in GitHub token; no personal access token is
needed. Renderer resources are served with the game instead of from a CDN,
and source maps are not published. The build targets JavaScript and skips the
optional WebAssembly compatibility probe. Browser playtesting remains separate.

To reproduce the hosted release locally:

```bash
flutter pub get --enforce-lockfile
flutter build web --release --no-pub --no-web-resources-cdn --no-source-maps --no-wasm-dry-run \
  --base-href /factory-clicker/ --output build/pages/factory-clicker
python3 -m http.server 8080 --directory build/pages
```

Open <http://localhost:8080/factory-clicker/>. Use `make build-web` and
`make serve` for the usual root-path local build.

### Publish a versioned web release

The version in `pubspec.yaml` is the source of truth. After updating and
committing it, push an annotated tag matching the version without the build
suffix. For example, for `version: 1.1.0+2`:

```bash
git push origin main
git tag -a v1.1.0 -m "Factory Clicker v1.1.0 web release"
git push origin v1.1.0
```

The workflow rejects tags that do not match `pubspec.yaml`. A version tag
publishes a GitHub release with a downloadable web ZIP, SHA-256 checksum, and
the play-online link. The ZIP preserves the Pages subdirectory so it can be
served with the same asset paths. Release notes include local serving
instructions.

The README version badge follows the latest published release automatically.
Tagged releases do not replace the live Pages site, which continues to follow
`main`. Use a new version and tag for each release; do not move published tags.

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
