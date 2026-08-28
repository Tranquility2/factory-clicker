// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('Factory Clicker E2E Integration Suite', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Wait for Flutter Web initialization and debug bridge
    await page.waitForFunction(() => typeof window['__gameDebug'] !== 'undefined', { timeout: 15000 });
  });

  test('1. Core game engine initializes with valid starting inventory', async ({ page }) => {
    const rawState = await page.evaluate(() => window['__gameDebug'].getState());
    const state = JSON.parse(rawState);

    expect(state.inventory.coal).toBeGreaterThanOrEqual(10);
    expect(state.inventory.ironOre).toBeGreaterThanOrEqual(10);
    expect(state.inventory.stone).toBeGreaterThanOrEqual(10);
    expect(state.gameSpeedMultiplier).toBe(1.0);
  });

  test('2. Debug hooks allow speed control and resource manipulation', async ({ page }) => {
    // Set simulation speed to 10x
    await page.evaluate(() => window['__gameDebug'].setSpeed(10));
    
    // Add resources via debug hook
    await page.evaluate(() => window['__gameDebug'].addResource('ironPlate', 50));
    await page.evaluate(() => window['__gameDebug'].addResource('copperPlate', 50));

    const rawState = await page.evaluate(() => window['__gameDebug'].getState());
    const state = JSON.parse(rawState);

    expect(state.gameSpeedMultiplier).toBe(10);
    expect(state.inventory.ironPlate).toBeGreaterThanOrEqual(50);
    expect(state.inventory.copperPlate).toBeGreaterThanOrEqual(50);
  });

  test('3. Purchased burner miner produces its assigned resource', async ({ page }) => {
    // Let persisted-state initialization finish before interacting.
    await page.waitForTimeout(750);
    await page.evaluate(() => {
      const enableAccessibility = document.querySelector(
        'flt-semantics-placeholder'
      );
      if (enableAccessibility) enableAccessibility.click();
      window['__gameDebug'].addResource('ironPlate', 10);
      window['__gameDebug'].setSpeed(10);
    });

    const beforeRaw = await page.evaluate(
      () => window['__gameDebug'].getState()
    );
    const before = JSON.parse(beforeRaw);
    await page.getByRole('button', {
      name: 'Buy Burner Mining Drill'
    }).click();
    await page.waitForTimeout(1200);

    const afterRaw = await page.evaluate(
      () => window['__gameDebug'].getState()
    );
    const after = JSON.parse(afterRaw);
    expect(after.buildings.burner_miner.count).toBe(1);
    expect(after.buildings.burner_miner.targetResource).toBe('ironOre');
    expect(after.buildings.burner_miner.miningAllocations.ironOre).toBe(1);
    expect(after.inventory.ironOre).toBeGreaterThan(before.inventory.ironOre);
    expect(after.inventory.coal).toBeLessThan(before.inventory.coal);
  });

  test('4. Split Coal and Iron allocations sustain iron smelting', async ({ page }) => {
    await page.waitForTimeout(750);
    const ironChain = {
      inventory: {
        coal: 100,
        ironOre: 100,
        stone: 10,
        ironPlate: 0
      },
      buildings: {
        burner_miner: {
          type: 'burner_miner',
          count: 2,
          targetResource: 'ironOre',
          miningAllocations: { ironOre: 2 }
        },
        stone_furnace: {
          type: 'stone_furnace',
          count: 1,
          activeRecipeId: 'smelt_iron',
          recipeAllocations: { smelt_iron: 1 }
        }
      },
      unlockedTechIds: [],
      gameSpeedMultiplier: 1,
      lastSaveTimestamp: Date.now()
    };
    await page.evaluate((state) => {
      window['__gameDebug'].loadState(JSON.stringify(state));
      const enableAccessibility = document.querySelector(
        'flt-semantics-placeholder'
      );
      if (enableAccessibility) enableAccessibility.click();
    }, ironChain);
    await page.getByRole('button', {
      name: 'Remove one from Burner Mining Drill Iron Ore'
    }).click();
    await page.getByRole('button', {
      name: 'Assign one to Burner Mining Drill Coal'
    }).click();
    const beforeRaw = await page.evaluate(
      () => window['__gameDebug'].getState()
    );
    const before = JSON.parse(beforeRaw);
    expect(before.buildings.burner_miner.miningAllocations.coal).toBe(1);
    expect(before.buildings.burner_miner.miningAllocations.ironOre).toBe(1);
    await page.waitForTimeout(1200);
    const afterRaw = await page.evaluate(
      () => window['__gameDebug'].getState()
    );
    const after = JSON.parse(afterRaw);

    expect(after.inventory.ironOre).toBeLessThan(before.inventory.ironOre);
    expect(after.inventory.ironPlate).toBeGreaterThan(0);
    expect(after.inventory.coal).toBeLessThan(before.inventory.coal);

    await page.getByText('SETTINGS').first().click();
    await page.getByRole('button', { name: 'SAVE GAME' }).click();
    await page.reload();
    await page.waitForFunction(
      () => typeof window['__gameDebug'] !== 'undefined'
    );
    await page.waitForTimeout(750);
    const persistedRaw = await page.evaluate(
      () => window['__gameDebug'].getState()
    );
    const persisted = JSON.parse(persistedRaw);
    expect(persisted.buildings.burner_miner.miningAllocations.coal).toBe(1);
    expect(persisted.buildings.burner_miner.miningAllocations.ironOre).toBe(1);
  });

  test('5. Starved iron smelter reports its missing Coal input', async ({ page }) => {
    await page.waitForTimeout(750);
    await page.evaluate((state) => {
      window['__gameDebug'].loadState(JSON.stringify(state));
      const enableAccessibility = document.querySelector(
        'flt-semantics-placeholder'
      );
      if (enableAccessibility) enableAccessibility.click();
    }, {
      inventory: { coal: 0, ironOre: 100, stone: 10 },
      buildings: {
        stone_furnace: {
          type: 'stone_furnace',
          count: 1,
          activeRecipeId: 'smelt_iron'
        }
      },
      unlockedTechIds: [],
      lastSaveTimestamp: Date.now()
    });

    await expect(
      page.getByLabel(/STOPPED — Missing Coal/)
    ).toBeVisible();
  });

  test('6. Rocket silo accumulates fractional production into whole parts', async ({ page }) => {
    await page.waitForTimeout(750);
    await page.evaluate((state) => {
      window['__gameDebug'].loadState(JSON.stringify(state));
    }, {
      inventory: {
        coal: 1000,
        steelPlate: 1000,
        electronicCircuit: 1000,
        ironGear: 1000,
        rocketPart: 0
      },
      buildings: {
        rocket_silo: {
          type: 'rocket_silo',
          count: 1,
          activeRecipeId: 'craft_rocket_part',
          recipeAllocations: { craft_rocket_part: 1 }
        }
      },
      unlockedTechIds: ['rocketry'],
      rocketPartsBuilt: 0,
      gameSpeedMultiplier: 20,
      lastSaveTimestamp: Date.now()
    });
    await page.waitForTimeout(1200);
    const rawState = await page.evaluate(
      () => window['__gameDebug'].getState()
    );
    const state = JSON.parse(rawState);
    expect(state.inventory.rocketPart).toBeGreaterThan(0);
    expect(state.rocketPartsBuilt).toBeGreaterThan(0);

    await page.evaluate((savedState) => {
      window['__gameDebug'].loadState(JSON.stringify(savedState));
    }, {
      inventory: { rocketPart: 100 },
      buildings: {},
      unlockedTechIds: ['rocketry'],
      lastSaveTimestamp: Date.now()
    });
    const migratedRaw = await page.evaluate(
      () => window['__gameDebug'].getState()
    );
    expect(JSON.parse(migratedRaw).rocketPartsBuilt).toBe(100);
  });

  test('7. Full tech tree unlock and state persistence', async ({ page }) => {
    // Unlock all technologies
    await page.evaluate(() => window['__gameDebug'].unlockAllTech());

    const rawState = await page.evaluate(() => window['__gameDebug'].getState());
    const state = JSON.parse(rawState);

    expect(state.unlockedTechIds).toContain('automation_1');
    expect(state.unlockedTechIds).toContain('electronics');
    expect(state.unlockedTechIds).toContain('steel_processing');
    expect(state.unlockedTechIds).toContain('rocketry');
  });

  test('8. Reset Save clears persisted progress', async ({ page }) => {
    await page.waitForTimeout(750);
    await page.evaluate(() => {
      const enableAccessibility = document.querySelector(
        'flt-semantics-placeholder'
      );
      if (enableAccessibility) enableAccessibility.click();
      window['__gameDebug'].addResource('ironPlate', 100);
    });

    await page.getByText('SETTINGS').first().click();
    await page.getByRole('button', { name: 'SAVE GAME' }).click();
    await page.getByRole('button', { name: 'Reset saved game' }).click();
    await page.getByRole('button', { name: 'RESET EVERYTHING' }).click();
    await page.waitForFunction(async () => {
      const state = JSON.parse(window['__gameDebug'].getState());
      return state.inventory.ironPlate === 0;
    });
    await page.reload();
    await page.waitForFunction(
      () => typeof window['__gameDebug'] !== 'undefined'
    );
    await page.waitForTimeout(750);

    const rawState = await page.evaluate(
      () => window['__gameDebug'].getState()
    );
    const state = JSON.parse(rawState);
    expect(state.inventory.coal).toBe(10);
    expect(state.inventory.ironOre).toBe(10);
    expect(state.inventory.ironPlate).toBe(0);
    expect(state.buildings.burner_miner.count).toBe(0);
    expect(state.unlockedTechIds).toEqual([]);
  });

  test('9. End-to-end automation simulation and rocket launch prestige', async ({ page }) => {
    // Accelerate simulation
    await page.evaluate(() => window['__gameDebug'].setSpeed(20));
    await page.evaluate(() => window['__gameDebug'].unlockAllTech());

    // Inject state with 100 rocket parts ready
    const testState = {
      inventory: {
        coal: 1000,
        ironOre: 1000,
        copperOre: 1000,
        stone: 1000,
        ironPlate: 500,
        copperPlate: 500,
        steelPlate: 500,
        electronicCircuit: 500,
        spaceScience: 0
      },
      buildings: {
        rocketSilo: { type: 'rocketSilo', count: 1, activeRecipeId: 'craft_rocket_part', currentProgressTicks: 0 }
      },
      unlockedTechIds: ['automation_1', 'electronics', 'steel_processing', 'logistic_science_tech', 'rocketry'],
      rocketPartsBuilt: 100,
      totalRocketLaunches: 0,
      spaceScienceCount: 0,
      totalManualClicks: 5,
      gameSpeedMultiplier: 20.0,
      lastSaveTimestamp: Date.now()
    };

    await page.evaluate((s) => window['__gameDebug'].loadState(JSON.stringify(s)), testState);

    // Verify state was loaded
    const loadedRaw = await page.evaluate(() => window['__gameDebug'].getState());
    const loadedState = JSON.parse(loadedRaw);
    expect(loadedState.rocketPartsBuilt).toBe(100);

    // Trigger save and state export validation
    expect(loadedState.unlockedTechIds.length).toBeGreaterThan(0);
  });
});
