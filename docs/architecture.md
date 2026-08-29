# Architecture

Factory Clicker separates authoritative simulation state from Flutter controls
and Flame rendering. This keeps progression deterministic while allowing the
visual layer to animate independently.

## System overview

| Area | Implementation | Responsibility |
| --- | --- | --- |
| Application shell | Flutter | Navigation, controls, cards, dialogs, and accessibility |
| State access | Riverpod `Provider<GameEngine>` | Owns and disposes the engine |
| Simulation | `GameEngine` with `ChangeNotifier` | Advances resources, machines, research, saves, and prestige |
| Factory rendering | Flame `FlameGame` | Draws topology, shaders, belts, particles, and machine effects |
| Persistence | `shared_preferences` | Stores the serialized game state locally |
| Integration | Playwright | Drives the compiled web application through Chromium |

## Runtime flow

`gameEngineProvider` creates one `GameEngine`, loads persisted state, and then
starts the engine timer. The timer calls `tick()` every 50 milliseconds, giving
the simulation a 20 Hz base rate.

Each tick processes systems in this order:

1. manual crafting;
2. mining allocations;
3. smelting allocations;
4. assembler and Rocket Silo allocations;
5. Rocket Part synchronization;
6. research; and
7. periodic persistence.

The engine calls `notifyListeners()` after each tick. `DashboardScreen` uses
`ListenableBuilder` to rebuild Flutter controls from the latest state.

## Domain model

### Resources and recipes

`ResourceType` defines all inventory items. `Recipe` defines input quantities,
output quantities, duration in simulation ticks, category, and optional
technology requirement.

Recipe processing is continuous. Each allocated machine contributes a fraction
of a recipe per tick according to its craft speed, the game-speed setting, and
the Space Science multiplier.

### Buildings and allocations

`BuildingType` defines cost, speed, category, and presentation metadata.
`BuildingState` stores:

- the number of owned machines;
- mining allocations by `ResourceType`;
- recipe allocations by recipe ID; and
- legacy target and recipe fields used when migrating older saves.

Allocation totals are normalized so they cannot exceed the owned count.
Unassigned machines do not produce.

Burner miners share available Coal proportionally. If available fuel is below
the required amount for a tick, production is throttled instead of allowing one
allocation to consume all fuel before another allocation runs.

### Research

Only one technology can be active. Research requires at least one Research Lab
and all prerequisite technologies. Labs consume the technology cost gradually;
missing inputs pause progress without discarding it.

### Rocket progression

Rocket Parts accumulate fractionally in inventory and are synchronized to the
whole-number launch counter. Output is capped at 100 before recipe inputs are
consumed, preventing material loss at the cap.

Launching creates a fresh terrestrial `GameState` while preserving technologies,
lifetime clicks, launch count, and Space Science.

## Rendering

`FactoryVisualizerGame` derives a read-only topology from `GameState`.
Allocations become compact machine nodes arranged across extraction, smelting,
components, science, and launch stages.

An edge is drawn only when an earlier node produces a resource consumed by a
later node. Belt packets and glow animate only when both connected nodes are
actively producing. Starved paths remain visible but static and dim.

The visualizer uses Canvas shaders and particles for:

- moving floor light;
- gradient machine borders;
- resource-colored belt bloom;
- mining dust;
- furnace heat and sparks;
- assembler gears;
- laboratory energy orbits; and
- rocket exhaust.

The renderer never mutates simulation state.

## Persistence

The save key is `factory_clicker_save_v1`. `GameState` serializes inventory,
building allocations, research, crafting, rocket progress, speed, and lifetime
statistics.

Building keys use stable IDs such as `burner_miner`. The loader also accepts
older enum and display-name keys. Legacy single-target buildings migrate all
owned machines into the corresponding allocation.

Offline catch-up is capped at eight hours.

## Web debug bridge

Web builds register `window.__gameDebug` through Dart JavaScript interop.
Playwright uses this bridge to seed deterministic states and inspect results,
while still performing important actions through the rendered UI.

The bridge is conditionally compiled; native desktop builds use a stub.

## Integration boundaries

Playwright coverage should verify behavior at system boundaries:

- UI action to engine mutation;
- allocation to resource flow;
- resource starvation and recovery;
- research start, consumption, and completion;
- save, reload, migration, and reset; and
- Rocket Part production and launch prestige.
