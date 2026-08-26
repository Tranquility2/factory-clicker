# Factory Clicker (Flutter Web) — Architecture & Design Document

## 1. Executive Summary
**Factory Clicker** is a 2D abstract incremental automation game built in Flutter Web, drawing deep inspiration from *Factorio* and *Cookie Clicker*. Players begin with manual resource gathering and progress through multi-tier automated supply chains, refining raw ores into advanced electronics and rocketry components.

Quality assurance and gameplay validation rely entirely on end-to-end integration tests executed by an automated Playwright agent.

---

## 2. Core Game Loop & Systems

### 2.1 Simulation Engine
* **Tick Rate:** 20 Hz (50ms discrete tick cycle).
* **Deterministic Pipelines:** Machines pull exact quantities from a centralized or localized inventory buffer, execute their recipe duration, and deposit outputs upon completion.
* **Offline Catch-Up:** On session resume, the game computes simulated offline progression up to a configurable ceiling (e.g., 8 hours).
* **Prestige Milestone:** Launching a Space Rocket triggers a prestige reset, trading basic machinery for Space Science packs that grant permanent global productivity multipliers.

### 2.2 Tech & Production Tree
1. **Tier 1 — Raw Extraction:** Coal, Iron Ore, Copper Ore, Stone.
2. **Tier 2 — Smelting & Basics:** Stone Furnaces, Iron Plates, Copper Plates, Iron Gears.
3. **Tier 3 — Electronics & Automation:** Copper Wires, Basic Electronic Circuits, Automated Assemblers.
4. **Tier 4 — Advanced Metallurgy & Chemistry:** Steel Plates, Chemical Plants, Advanced Processors.
5. **Tier 5 — Rocketry & Space Science:** Rocket Silo, Rocket Fuel, Satellite, Space Science Packs.

---

## 3. Technology Stack & Architecture

### 3.1 Frontend & State Management
* **Framework:** Flutter (Web target, CanvasKit renderer).
* **State Management:** Flutter Riverpod (`StateNotifierProvider` / `@riverpod` code generation).
  * Decouples the pure Dart simulation state from UI rendering.
* **Rendering Hybrid:**
  * **Flame Engine Canvas:** Handles animated visual machinery, smoke particle effects, and production visualizers.
  * **Flutter / HTML Overlay DOM:** Renders responsive control cards, action buttons, progress bars, and modal sheets with semantic HTML attributes.

### 3.2 Visual Assets & Audio
* **Sprite Assets:** Kenney.nl (CC0 Public Domain) Industrial, Factory, and UI Icon packs.
* **Audio:** Royalty-free CC0 ambient industrial hums and tactile click sound effects.

### 3.3 Persistence
* **Storage:** Browser `window.localStorage` storing serialized JSON save states with automatic 10-second autosave intervals.
* **Data Portability:** In-game Export / Import save string functionality for manual backup and debug test seeding.

---

## 4. Playwright Testing & Agent Automation

### 4.1 Debug & Fast-Forward Hooks (`window.__gameDebug`)
To enable instantaneous, deterministic integration testing without real-time waiting:
* `window.__gameDebug.setSpeed(multiplier)`: Accelerates simulation ticks (e.g., 10x, 100x).
* `window.__gameDebug.loadState(json)`: Injects pre-configured game states, inventories, or unlocked research tiers.
* `window.__gameDebug.getState()`: Dumps current game state for assertion validation.

### 4.2 Locators & Semantic Selectors
* Interactive widgets expose clear HTML `data-testid` and `aria-label` attributes (e.g., `data-testid="mine-iron-btn"`, `data-testid="counter-iron-ore"`).

### 4.3 Test Suite Execution
* **Framework:** Node.js `@playwright/test`.
* **Automation Agent:** Executes end-to-end integration journeys validating manual clicking, automated supply chain balance, research unlocking, and prestige reset triggers.

---

## 5. Project Roadmap & Milestones
* **Phase 1: Foundation:** Project scaffold, pure Dart simulation tick loop, basic resource model, and Riverpod state.
* **Phase 2: UI & Asset Integration:** Kenney.nl sprite integration, responsive dashboard layout, and Flame canvas visualizer.
* **Phase 3: Automation & Recipes:** Crafting pipelines, automated miners/smelters, and balance tuning.
* **Phase 4: Playwright Integration:** `__gameDebug` exposure, test harness setup, and end-to-end agent test suite.
* **Phase 5: Prestige & Audio:** Space Rocket Launch prestige mechanics, audio player, and final polish.
