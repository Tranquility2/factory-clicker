import 'package:flutter_test/flutter_test.dart';
import 'package:factory_clicker/models/building.dart';
import 'package:factory_clicker/models/game_state.dart';
import 'package:factory_clicker/models/resource_type.dart';
import 'package:factory_clicker/simulation/game_engine.dart';

void main() {
  group('Storage Limits & Chests Tests', () {
    test('Initial base storage limit is 100 per resource', () {
      final state = GameState();
      expect(state.maxStorageCapacity, 100.0);
      expect(state.maxStorageFor(ResourceType.ironOre), 100.0);
      expect(state.maxStorageFor(ResourceType.copperPlate), 100.0);
      expect(state.maxStorageFor(ResourceType.rocketPart), 100.0);
      expect(state.maxStorageFor(ResourceType.spaceScience), double.infinity);
    });

    test('Wooden Chest is unlocked by default and increases capacity by 100 each', () {
      final state = GameState();
      expect(state.isBuildingUnlocked(BuildingType.woodenChest), isTrue);

      state.buildings[BuildingType.woodenChest]!.count = 2;
      expect(state.maxStorageCapacity, 300.0); // 100 base + 2 * 100
      expect(state.maxStorageFor(ResourceType.ironOre), 300.0);
    });

    test('Iron and Steel Chests unlock through technology and provide higher capacity', () {
      final state = GameState();
      expect(state.isBuildingUnlocked(BuildingType.ironChest), isFalse);
      expect(state.isBuildingUnlocked(BuildingType.steelChest), isFalse);

      state.unlockedTechIds.add('automation_1');
      expect(state.isBuildingUnlocked(BuildingType.ironChest), isTrue);

      state.unlockedTechIds.add('steel_processing');
      expect(state.isBuildingUnlocked(BuildingType.steelChest), isTrue);

      state.buildings[BuildingType.woodenChest]!.count = 1; // +100
      state.buildings[BuildingType.ironChest]!.count = 2;   // +1000
      state.buildings[BuildingType.steelChest]!.count = 1;  // +2500

      // 100 base + 100 + 1000 + 2500 = 3700
      expect(state.maxStorageCapacity, 3700.0);
      expect(state.maxStorageFor(ResourceType.steelPlate), 3700.0);
    });

    test('Resource addition clamps to maximum storage capacity', () {
      final engine = GameEngine();
      expect(engine.state.maxStorageFor(ResourceType.ironOre), 100.0);

      // Add resource beyond cap
      engine.addResourceDebug(ResourceType.ironOre, 200.0);
      expect(engine.state.inventory[ResourceType.ironOre], 100.0);

      // Purchase a wooden chest
      engine.state.inventory[ResourceType.stone] = 50.0;
      engine.state.inventory[ResourceType.coal] = 50.0;
      final bought = engine.purchaseBuilding(BuildingType.woodenChest);
      expect(bought, isTrue);
      expect(engine.state.maxStorageCapacity, 200.0);

      // Now adding more reaches the new 200.0 cap
      engine.addResourceDebug(ResourceType.ironOre, 50.0);
      expect(engine.state.inventory[ResourceType.ironOre], 150.0);

      engine.addResourceDebug(ResourceType.ironOre, 100.0);
      expect(engine.state.inventory[ResourceType.ironOre], 200.0);
    });

    test('Manual gathering respects storage limit', () {
      final engine = GameEngine();
      engine.state.inventory[ResourceType.ironOre] = 99.0;
      engine.manualGather(ResourceType.ironOre);
      expect(engine.state.inventory[ResourceType.ironOre], 100.0);

      // Next gather does nothing
      final clicksBefore = engine.state.totalManualClicks;
      engine.manualGather(ResourceType.ironOre);
      expect(engine.state.inventory[ResourceType.ironOre], 100.0);
      expect(engine.state.totalManualClicks, clicksBefore);
    });

    test('Miners pause and do not waste fuel when target storage is full', () {
      final engine = GameEngine();
      final burnerMiner = engine.state.buildings[BuildingType.burnerMiner]!;
      burnerMiner.count = 1;
      burnerMiner.miningAllocations[ResourceType.ironOre] = 1;

      engine.state.inventory[ResourceType.coal] = 20.0;
      engine.state.inventory[ResourceType.ironOre] = 100.0; // Already full

      final initialCoal = engine.state.inventory[ResourceType.coal]!;

      // Simulate 1 second (20 ticks)
      for (int i = 0; i < 20; i++) {
        engine.tick();
      }

      // Iron Ore should stay at 100 and Coal should NOT have been consumed
      expect(engine.state.inventory[ResourceType.ironOre], 100.0);
      expect(engine.state.inventory[ResourceType.coal], initialCoal);
    });

    test('Smelters pause and do not consume ingredients when output storage is full', () {
      final engine = GameEngine();
      final furnace = engine.state.buildings[BuildingType.stoneFurnace]!;
      furnace.count = 1;
      furnace.recipeAllocations['smelt_iron'] = 1;

      engine.state.inventory[ResourceType.ironOre] = 50.0;
      engine.state.inventory[ResourceType.coal] = 50.0;
      engine.state.inventory[ResourceType.ironPlate] = 100.0; // Full iron plate storage

      final initialOre = engine.state.inventory[ResourceType.ironOre]!;
      final initialCoal = engine.state.inventory[ResourceType.coal]!;

      // Simulate 1 second (20 ticks)
      for (int i = 0; i < 20; i++) {
        engine.tick();
      }

      // Outputs full -> ingredients preserved
      expect(engine.state.inventory[ResourceType.ironPlate], 100.0);
      expect(engine.state.inventory[ResourceType.ironOre], initialOre);
      expect(engine.state.inventory[ResourceType.coal], initialCoal);
    });

    test('State serialization preserves storage chests', () {
      final state = GameState();
      state.buildings[BuildingType.woodenChest]!.count = 3;
      state.buildings[BuildingType.ironChest]!.count = 2;
      state.buildings[BuildingType.steelChest]!.count = 1;

      final json = state.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.buildings[BuildingType.woodenChest]!.count, 3);
      expect(restored.buildings[BuildingType.ironChest]!.count, 2);
      expect(restored.buildings[BuildingType.steelChest]!.count, 1);
      expect(restored.maxStorageCapacity, state.maxStorageCapacity);
    });
  });
}
