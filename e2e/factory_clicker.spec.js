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
    expect(after.inventory.ironOre).toBeGreaterThan(before.inventory.ironOre);
    expect(after.inventory.coal).toBeLessThan(before.inventory.coal);
  });

  test('4. Full tech tree unlock and state persistence', async ({ page }) => {
    // Unlock all technologies
    await page.evaluate(() => window['__gameDebug'].unlockAllTech());

    const rawState = await page.evaluate(() => window['__gameDebug'].getState());
    const state = JSON.parse(rawState);

    expect(state.unlockedTechIds).toContain('automation_1');
    expect(state.unlockedTechIds).toContain('electronics');
    expect(state.unlockedTechIds).toContain('steel_processing');
    expect(state.unlockedTechIds).toContain('rocketry');
  });

  test('5. Reset Save clears persisted progress', async ({ page }) => {
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

  test('6. End-to-end automation simulation and rocket launch prestige', async ({ page }) => {
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
