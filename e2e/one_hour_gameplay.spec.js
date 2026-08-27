// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('1-Hour Full Progression Simulation Playthrough', () => {

  test('Simulate complete 1-hour gameplay journey across all factory tiers with tab tours', async ({ page }) => {
    // Set viewport size for clean high-res inspection
    await page.setViewportSize({ width: 1280, height: 800 });

    await page.goto('/');
    await page.waitForFunction(() => typeof window['__gameDebug'] !== 'undefined', { timeout: 15000 });

    // Enable Flutter semantics for Playwright
    await page.evaluate(() => {
      const btn = document.querySelector('flt-semantics-placeholder');
      if (btn) btn.click();
    });

    // -------------------------------------------------------------
    // STAGE 1: Early Game - Manual Mining & Gathering (Mins 0 - 10)
    // -------------------------------------------------------------
    await page.evaluate(() => window['__gameDebug'].setSpeed(50));
    await page.evaluate(() => {
      window['__gameDebug'].addResource('coal', 40);
      window['__gameDebug'].addResource('ironOre', 35);
      window['__gameDebug'].addResource('copperOre', 25);
      window['__gameDebug'].addResource('stone', 50);
    });

    // Ensure we are on CRAFTING tab
    await page.getByText('CRAFTING').first().click();
    await page.waitForTimeout(600);
    await page.screenshot({ path: './play-stage1-early-game.png' });

    // -------------------------------------------------------------
    // STAGE 2: Smelting & Machines Tab (Mins 10 - 25)
    // -------------------------------------------------------------
    const stage2State = {
      inventory: {
        coal: 180,
        ironOre: 150,
        copperOre: 120,
        stone: 90,
        ironPlate: 85,
        copperPlate: 60,
        ironGear: 30,
        copperWire: 60,
        electronicCircuit: 15,
        steelPlate: 0,
        automationScience: 20,
        logisticScience: 0,
        rocketPart: 0,
        spaceScience: 0
      },
      buildings: {
        burnerMiner: { type: 'burnerMiner', count: 6, targetResource: 'ironOre' },
        stoneFurnace: { type: 'stoneFurnace', count: 4, activeRecipeId: 'smelt_iron' },
        assembler1: { type: 'assembler1', count: 3, activeRecipeId: 'craft_iron_gear' },
        researchLab: { type: 'researchLab', count: 2 }
      },
      unlockedTechIds: ['automation_1', 'electronics'],
      activeResearchId: 'steel_processing',
      researchProgressTicks: 150.0,
      totalManualClicks: 65,
      gameSpeedMultiplier: 50.0,
      lastSaveTimestamp: Date.now()
    };

    await page.evaluate((s) => window['__gameDebug'].loadState(JSON.stringify(s)), stage2State);

    // Switch to MACHINES tab to see all purchased drills and furnaces
    await page.getByText('MACHINES').first().click();
    await page.waitForTimeout(600);
    await page.screenshot({ path: './play-stage2-smelting-automation.png' });

    // -------------------------------------------------------------
    // STAGE 3: Advanced Research & Tech Tree (Mins 25 - 45)
    // -------------------------------------------------------------
    const stage3State = {
      inventory: {
        coal: 1200,
        ironOre: 1800,
        copperOre: 1500,
        stone: 800,
        ironPlate: 1200,
        copperPlate: 900,
        ironGear: 450,
        copperWire: 1200,
        electronicCircuit: 600,
        steelPlate: 350,
        automationScience: 150,
        logisticScience: 120,
        rocketPart: 25,
        spaceScience: 0
      },
      buildings: {
        burnerMiner: { type: 'burnerMiner', count: 10, targetResource: 'ironOre' },
        electricMiner: { type: 'electricMiner', count: 8, targetResource: 'copperOre' },
        steelFurnace: { type: 'steelFurnace', count: 8, activeRecipeId: 'smelt_iron' },
        assembler1: { type: 'assembler1', count: 6, activeRecipeId: 'craft_electronic_circuit' },
        assembler2: { type: 'assembler2', count: 6, activeRecipeId: 'craft_logistic_science' },
        researchLab: { type: 'researchLab', count: 4 }
      },
      unlockedTechIds: ['automation_1', 'electronics', 'steel_processing', 'logistic_science_tech'],
      activeResearchId: 'rocketry',
      researchProgressTicks: 450.0,
      totalManualClicks: 110,
      gameSpeedMultiplier: 50.0,
      lastSaveTimestamp: Date.now()
    };

    await page.evaluate((s) => window['__gameDebug'].loadState(JSON.stringify(s)), stage3State);

    // Switch to RESEARCH tab to see research progression
    await page.getByText('RESEARCH').first().click();
    await page.waitForTimeout(600);
    await page.screenshot({ path: './play-stage3-advanced-assembly.png' });

    // -------------------------------------------------------------
    // STAGE 4: Rocket Silo & Launch Prestige (Mins 45 - 60+)
    // -------------------------------------------------------------
    const stage4State = {
      inventory: {
        coal: 4000,
        ironPlate: 3500,
        copperPlate: 3000,
        steelPlate: 2000,
        electronicCircuit: 2500,
        ironGear: 1800,
        automationScience: 500,
        logisticScience: 500,
        rocketPart: 100,
        spaceScience: 0
      },
      buildings: {
        electricMiner: { type: 'electricMiner', count: 16, targetResource: 'ironOre' },
        steelFurnace: { type: 'steelFurnace', count: 12, activeRecipeId: 'smelt_steel' },
        assembler2: { type: 'assembler2', count: 10, activeRecipeId: 'craft_electronic_circuit' },
        researchLab: { type: 'researchLab', count: 8 },
        rocketSilo: { type: 'rocketSilo', count: 1, activeRecipeId: 'craft_rocket_part' }
      },
      unlockedTechIds: ['automation_1', 'electronics', 'steel_processing', 'logistic_science_tech', 'rocketry'],
      rocketPartsBuilt: 100,
      totalRocketLaunches: 0,
      spaceScienceCount: 0,
      totalManualClicks: 210,
      gameSpeedMultiplier: 50.0,
      lastSaveTimestamp: Date.now()
    };

    await page.evaluate((s) => window['__gameDebug'].loadState(JSON.stringify(s)), stage4State);

    // Switch to ROCKET SILO tab
    await page.getByText('ROCKET SILO').first().click();
    await page.waitForTimeout(800);
    await page.screenshot({ path: './play-stage4-rocket-silo-ready.png' });

    // -------------------------------------------------------------
    // STAGE 5: Launch Rocket & Verify Prestige
    // -------------------------------------------------------------
    await page.getByRole('button', { name: 'Launch Rocket Prestige' }).click();
    await page.waitForTimeout(1000);
    await page.screenshot({ path: './play-stage5-rocket-prestige-launched.png' });

    // Verify Space Science was awarded
    const postPrestigeRaw = await page.evaluate(() => window['__gameDebug'].getState());
    const postPrestigeState = JSON.parse(postPrestigeRaw);

    expect(postPrestigeState.spaceScienceCount).toBe(50);
    expect(postPrestigeState.totalRocketLaunches).toBe(1);
  });
});
