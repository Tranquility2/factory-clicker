# Technical reference

## Repository layout

| Path | Purpose |
| --- | --- |
| `lib/models/` | Resources, recipes, buildings, technologies, and serialized game state |
| `lib/simulation/game_engine.dart` | Authoritative 20 Hz simulation |
| `lib/state/game_provider.dart` | Riverpod engine lifecycle |
| `lib/ui/` | Theme, dashboard, controls, and status panels |
| `lib/ui/widgets/flame_factory_view.dart` | Shader-based factory topology |
| `lib/debug/` | Conditional web debug bridge |
| `e2e/` | Playwright integration journeys |
| `web/` | Web runner and manifest |
| `linux/` | Native Linux runner |
| `windows/` | Native Windows runner |
| `assets/fonts/` | Bundled Noto fonts and licenses |

## Make targets

| Command | Result |
| --- | --- |
| `make` or `make help` | List project commands |
| `make all` | Analyze and build web |
| `make analyze` | Run Flutter static analysis |
| `make build-web` | Build the web release |
| `make build-linux` | Build the Linux release bundle |
| `make run-web` | Start Flutter's Chrome development target |
| `make serve` | Serve `build/web` on port 8080 |
| `make test-e2e` | Run the Playwright integration suite |
| `make clean` | Remove Flutter and integration artifacts |

## Build outputs

| Target | Output |
| --- | --- |
| Web | `build/web/` |
| Linux | `build/linux/x64/release/bundle/` |
| Windows | `build/windows/x64/runner/Release/` |

## Windows build script

```powershell
.\build-windows.ps1 [-Clean] [-Run]
```

`-Clean` runs `flutter clean`. `-Run` starts the executable after a successful
build.

## Web debug API

After initialization, web builds expose `window.__gameDebug`.

| Method | Arguments | Result |
| --- | --- | --- |
| `getState()` | None | Current save as a JSON string |
| `setSpeed(multiplier)` | Positive number | Updates simulation speed |
| `loadState(json)` | Save JSON string | Replaces state and persists it |
| `addResource(name, amount)` | Resource enum name and number | Adds inventory for integration setup |
| `unlockAllTech()` | None | Unlocks all technologies |

Example:

```js
const state = JSON.parse(window.__gameDebug.getState());
window.__gameDebug.setSpeed(10);
window.__gameDebug.addResource('ironPlate', 50);
```

Resource names use Dart enum identifiers such as `ironOre`, `ironPlate`, and
`electronicCircuit`.

## Persistence reference

| Setting | Value |
| --- | --- |
| Save key | `factory_clicker_save_v1` |
| Autosave interval | 10 seconds |
| Offline catch-up cap | 8 hours |
| Rocket requirement | 100 Rocket Parts |
| Launch reward | 50 Space Science |
| Bonus per Space Science | 10% global production |

On web, `shared_preferences` stores data in browser local storage. On native
desktop targets, the plugin uses platform-local application storage.
