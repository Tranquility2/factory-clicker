import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resource_type.dart';
import '../models/building.dart';
import '../models/recipe.dart';
import '../models/technology.dart';
import '../models/game_state.dart';

class GameEngine extends ChangeNotifier {
  static const String saveKey = 'factory_clicker_save_v1';
  static const int ticksPerSecond = 20;

  GameState state;
  Timer? _timer;
  final Map<ResourceType, double> ratesPerSecond = {};
  final Map<ResourceType, double> _tickDeltas = {};
  int _ticksSinceLastSave = 0;
  int _ticksSinceLastRateCalculation = 0;

  GameEngine({GameState? initialState}) : state = initialState ?? GameState() {
    _initRates();
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      tick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _initRates() {
    for (final r in ResourceType.values) {
      ratesPerSecond[r] = 0.0;
      _tickDeltas[r] = 0.0;
    }
  }

  void tick() {
    final speed = state.gameSpeedMultiplier;
    final prestige = state.prestigeMultiplier;
    final tickMultiplier = speed * prestige;

    // Reset delta trackers periodically to calculate rates/sec
    _ticksSinceLastRateCalculation++;
    if (_ticksSinceLastRateCalculation >= ticksPerSecond) {
      for (final r in ResourceType.values) {
        ratesPerSecond[r] = _tickDeltas[r] ?? 0.0;
        _tickDeltas[r] = 0.0;
      }
      _ticksSinceLastRateCalculation = 0;
    }

    _processManualCraftQueue(tickMultiplier);
    _processMiners(tickMultiplier);
    _processSmelters(tickMultiplier);
    _processAssemblers(tickMultiplier);
    _syncRocketParts();
    _processResearch(tickMultiplier);

    _ticksSinceLastSave++;
    if (_ticksSinceLastSave >= ticksPerSecond * 10) {
      // Autosave every 10 seconds
      _ticksSinceLastSave = 0;
      saveToStorage();
    }

    notifyListeners();
  }

  double _addResource(ResourceType type, double amount) {
    if (amount <= 0) return 0.0;
    final current = state.inventory[type] ?? 0.0;
    final maxCap = state.maxStorageFor(type);
    final allowed = max(0.0, maxCap - current);
    final added = min(amount, allowed);
    if (added > 0) {
      state.inventory[type] = current + added;
      _tickDeltas[type] = (_tickDeltas[type] ?? 0.0) + added;
    }
    return added;
  }

  bool _consumeResource(ResourceType type, double amount) {
    final current = state.inventory[type] ?? 0.0;
    if (current >= amount) {
      state.inventory[type] = current - amount;
      _tickDeltas[type] = (_tickDeltas[type] ?? 0.0) - amount;
      return true;
    }
    return false;
  }

  void manualGather(ResourceType type) {
    final current = state.inventory[type] ?? 0.0;
    if (current >= state.maxStorageFor(type)) {
      return;
    }
    state.totalManualClicks++;
    _addResource(type, 1.0);
    notifyListeners();
  }

  bool canCraftManual(Recipe recipe) {
    if (!state.isRecipeUnlocked(recipe)) return false;
    for (final entry in recipe.inputs.entries) {
      if ((state.inventory[entry.key] ?? 0.0) < entry.value) {
        return false;
      }
    }
    final hasOutputRoom = recipe.outputs.keys.any((outRes) {
      final current = state.inventory[outRes] ?? 0.0;
      return current < state.maxStorageFor(outRes);
    });
    if (!hasOutputRoom) return false;
    return true;
  }

  bool startManualCraft(Recipe recipe) {
    if (!canCraftManual(recipe)) return false;

    // Deduct inputs immediately
    for (final entry in recipe.inputs.entries) {
      _consumeResource(entry.key, entry.value.toDouble());
    }

    state.manualCraftQueue.add(ManualCraftItem(recipe: recipe));
    notifyListeners();
    return true;
  }

  void _processManualCraftQueue(double multiplier) {
    if (state.manualCraftQueue.isEmpty) return;

    final current = state.manualCraftQueue.first;
    current.progressTicks += 1.0 * multiplier;

    if (current.progressTicks >= current.recipe.durationTicks) {
      for (final entry in current.recipe.outputs.entries) {
        _addResource(entry.key, entry.value.toDouble());
      }
      state.manualCraftQueue.removeAt(0);
    }
  }

  void _processMiners(double multiplier) {
    for (final type in [BuildingType.burnerMiner, BuildingType.electricMiner]) {
      final building = state.buildings[type];
      if (building == null || building.count == 0) continue;
      final allocations = building.miningAllocations.entries
          .where((entry) => entry.value > 0)
          .toList();
      if (allocations.isEmpty) continue;

      final activeAllocations = allocations.where((allocation) {
        final current = state.inventory[allocation.key] ?? 0.0;
        final maxCap = state.maxStorageFor(allocation.key);
        return current < maxCap;
      }).toList();

      if (activeAllocations.isEmpty) continue;

      var activityRatio = 1.0;
      if (type == BuildingType.burnerMiner) {
        final allocatedMiners = activeAllocations.fold<int>(
          0,
          (total, entry) => total + entry.value,
        );
        final fuelNeeded = 0.1 * allocatedMiners * multiplier / ticksPerSecond;
        final availableFuel = state.inventory[ResourceType.coal] ?? 0.0;
        if (fuelNeeded <= 0 || availableFuel <= 0) continue;
        activityRatio = min(1.0, availableFuel / fuelNeeded);
        _consumeResource(ResourceType.coal, fuelNeeded * activityRatio);
      }

      for (final allocation in activeAllocations) {
        final current = state.inventory[allocation.key] ?? 0.0;
        final maxCap = state.maxStorageFor(allocation.key);
        final headroom = max(0.0, maxCap - current);
        if (headroom <= 0) continue;

        final desiredProduction =
            type.craftSpeed *
            allocation.value *
            multiplier *
            activityRatio /
            ticksPerSecond;
        final produced = min(desiredProduction, headroom);
        _addResource(allocation.key, produced);
      }
    }
  }

  void _processSmelters(double multiplier) {
    for (final type in [BuildingType.stoneFurnace, BuildingType.steelFurnace]) {
      final building = state.buildings[type];
      if (building == null || building.count == 0) continue;
      for (final allocation in building.recipeAllocations.entries) {
        if (allocation.value <= 0) continue;
        final recipe = Recipe.getById(allocation.key);
        if (recipe != null) {
          _processRecipe(
            recipe: recipe,
            type: type,
            machineCount: allocation.value,
            multiplier: multiplier,
          );
        }
      }
    }
  }

  void _processAssemblers(double multiplier) {
    for (final type in [
      BuildingType.assembler1,
      BuildingType.assembler2,
      BuildingType.rocketSilo,
    ]) {
      final building = state.buildings[type];
      if (building == null || building.count == 0) continue;
      if (type == BuildingType.rocketSilo && state.rocketPartsBuilt >= 100) {
        continue;
      }
      for (final allocation in building.recipeAllocations.entries) {
        if (allocation.value <= 0) continue;
        final recipe = Recipe.getById(allocation.key);
        if (recipe != null) {
          _processRecipe(
            recipe: recipe,
            type: type,
            machineCount: allocation.value,
            multiplier: multiplier,
          );
        }
      }
    }
  }

  void _processRecipe({
    required Recipe recipe,
    required BuildingType type,
    required int machineCount,
    required double multiplier,
  }) {
    var stepFactor =
        (1.0 / recipe.durationTicks) *
        type.craftSpeed *
        machineCount *
        multiplier;

    for (final entry in recipe.outputs.entries) {
      final current = state.inventory[entry.key] ?? 0.0;
      final maxCap = state.maxStorageFor(entry.key);
      final headroom = max(0.0, maxCap - current);
      if (headroom <= 0) return;
      stepFactor = min(stepFactor, headroom / entry.value);
    }
    if (stepFactor <= 0) return;

    final hasIngredients = recipe.inputs.entries.every(
      (entry) =>
          (state.inventory[entry.key] ?? 0.0) >= entry.value * stepFactor,
    );
    if (!hasIngredients) return;

    for (final entry in recipe.inputs.entries) {
      _consumeResource(entry.key, entry.value * stepFactor);
    }
    for (final entry in recipe.outputs.entries) {
      _addResource(entry.key, entry.value * stepFactor);
    }
  }

  void _syncRocketParts() {
    final parts = (state.inventory[ResourceType.rocketPart] ?? 0).clamp(
      0.0,
      100.0,
    );
    state.inventory[ResourceType.rocketPart] = parts;
    state.rocketPartsBuilt = parts.floor();
  }

  void _processResearch(double multiplier) {
    final lab = state.buildings[BuildingType.researchLab];
    if (lab == null || lab.count == 0 || state.activeResearchId == null) return;

    final tech = Technology.getById(state.activeResearchId!);
    if (tech == null) return;

    final progressRate =
        (1.0 / tech.researchDurationTicks) * lab.count * multiplier;

    bool hasPacks = true;
    for (final entry in tech.cost.entries) {
      if ((state.inventory[entry.key] ?? 0.0) < entry.value * progressRate) {
        hasPacks = false;
        break;
      }
    }

    if (hasPacks) {
      for (final entry in tech.cost.entries) {
        _consumeResource(entry.key, entry.value * progressRate);
      }
      state.researchProgressTicks += 1.0 * lab.count * multiplier;

      if (state.researchProgressTicks >= tech.researchDurationTicks) {
        state.unlockedTechIds.add(tech.id);
        state.activeResearchId = null;
        state.researchProgressTicks = 0.0;
      }
    }
  }

  bool canPurchaseBuilding(BuildingType type) {
    if (!state.isBuildingUnlocked(type)) return false;
    final currentCount = state.buildings[type]?.count ?? 0;
    final cost = type.costForCount(currentCount);
    for (final entry in cost.entries) {
      if ((state.inventory[entry.key] ?? 0.0) < entry.value) {
        return false;
      }
    }
    return true;
  }

  bool purchaseBuilding(BuildingType type) {
    if (!canPurchaseBuilding(type)) return false;
    final currentCount = state.buildings[type]?.count ?? 0;
    final cost = type.costForCount(currentCount);

    for (final entry in cost.entries) {
      _consumeResource(entry.key, entry.value.toDouble());
    }

    final building = state.buildings[type]!;
    building.count++;
    _allocatePurchasedBuilding(building);

    notifyListeners();
    return true;
  }

  void _allocatePurchasedBuilding(BuildingState building) {
    final type = building.type;
    if (type.category == BuildingCategory.storage) {
      return;
    }
    if (type.category == BuildingCategory.mining) {
      final target = building.targetResource ?? ResourceType.ironOre;
      building.targetResource = target;
      building.miningAllocations.update(
        target,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      return;
    }

    String? recipeId = building.activeRecipeId;
    if (type.category == BuildingCategory.smelting) {
      recipeId ??= 'smelt_iron';
    } else if (type.category == BuildingCategory.assembling) {
      recipeId ??= 'craft_copper_wire';
    } else if (type == BuildingType.rocketSilo) {
      recipeId = 'craft_rocket_part';
    }
    if (recipeId != null) {
      building.activeRecipeId = recipeId;
      building.recipeAllocations.update(
        recipeId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  bool adjustMinerAllocation(
    BuildingType type,
    ResourceType resource,
    int delta,
  ) {
    final building = state.buildings[type];
    if (building == null || type.category != BuildingCategory.mining) {
      return false;
    }
    final current = building.miningAllocations[resource] ?? 0;
    if (delta > 0 && building.allocatedCount >= building.count) return false;
    if (delta < 0 && current <= 0) return false;

    final updated = current + delta;
    if (updated <= 0) {
      building.miningAllocations.remove(resource);
    } else {
      building.miningAllocations[resource] = updated;
      building.targetResource = resource;
    }
    notifyListeners();
    return true;
  }

  bool adjustRecipeAllocation(BuildingType type, String recipeId, int delta) {
    final building = state.buildings[type];
    final recipe = Recipe.getById(recipeId);
    if (building == null || recipe == null) return false;
    if (!state.isRecipeUnlocked(recipe) ||
        !_buildingSupportsRecipe(type, recipe)) {
      return false;
    }
    if (delta > 0 && building.allocatedCount >= building.count) return false;
    final current = building.recipeAllocations[recipeId] ?? 0;
    if (delta < 0 && current <= 0) return false;

    final updated = current + delta;
    if (updated <= 0) {
      building.recipeAllocations.remove(recipeId);
    } else {
      building.recipeAllocations[recipeId] = updated;
      building.activeRecipeId = recipeId;
    }
    notifyListeners();
    return true;
  }

  bool _buildingSupportsRecipe(BuildingType type, Recipe recipe) {
    return switch (type.category) {
      BuildingCategory.smelting => recipe.category == CraftingCategory.smelting,
      BuildingCategory.assembling =>
        recipe.category == CraftingCategory.assembling,
      BuildingCategory.rocketSilo => recipe.category == CraftingCategory.silo,
      _ => false,
    };
  }

  bool canStartResearch(String techId) {
    final tech = Technology.getById(techId);
    if (tech == null) return false;
    if (state.unlockedTechIds.contains(techId)) return false;
    if (state.activeResearchId != null) return false;
    final lab = state.buildings[BuildingType.researchLab];
    if (lab == null || lab.count == 0) return false;

    for (final req in tech.prerequisites) {
      if (!state.unlockedTechIds.contains(req)) return false;
    }
    return true;
  }

  bool startResearch(String techId) {
    if (!canStartResearch(techId)) return false;
    state.activeResearchId = techId;
    state.researchProgressTicks = 0.0;
    notifyListeners();
    return true;
  }

  bool launchRocket() {
    if (state.rocketPartsBuilt < 100) return false;

    // Prestige launch!
    state.totalRocketLaunches++;
    state.spaceScienceCount += 50;
    state.rocketPartsBuilt = 0;

    // Reset inventory and buildings
    final spacePacks = state.spaceScienceCount;
    final launches = state.totalRocketLaunches;
    final clicks = state.totalManualClicks;
    final unlocked = Set<String>.from(state.unlockedTechIds);

    state = GameState(
      unlockedTechIds: unlocked,
      totalRocketLaunches: launches,
      spaceScienceCount: spacePacks,
      totalManualClicks: clicks,
    );

    notifyListeners();
    saveToStorage();
    return true;
  }

  void setSpeed(double multiplier) {
    state.gameSpeedMultiplier = multiplier > 0 ? multiplier : 1.0;
    notifyListeners();
  }

  Future<void> saveToStorage() async {
    try {
      state.lastSaveTimestamp = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(saveKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  Future<bool> resetSave() async {
    final wasRunning = _timer?.isActive ?? false;
    stop();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(saveKey);
      state = GameState();
      _ticksSinceLastSave = 0;
      _ticksSinceLastRateCalculation = 0;
      _initRates();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Reset error: $e');
      return false;
    } finally {
      if (wasRunning) start();
    }
  }

  Future<bool> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(saveKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = GameState.fromJson(json);

        // Offline catchup (capped to 8 hours = 28800 seconds)
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedSeconds = ((now - state.lastSaveTimestamp) / 1000).clamp(
          0,
          28800,
        );
        if (elapsedSeconds > 5) {
          final catchupTicks = (elapsedSeconds * ticksPerSecond).toInt();
          // Simulate in large chunks
          final chunkMultiplier = catchupTicks / ticksPerSecond;
          _processMiners(chunkMultiplier);
          _processSmelters(chunkMultiplier);
          _processAssemblers(chunkMultiplier);
          _syncRocketParts();
        }

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }
    return false;
  }

  String exportSaveJson() => jsonEncode(state.toJson());

  bool importSaveJson(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      state = GameState.fromJson(json);
      notifyListeners();
      saveToStorage();
      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }

  void addResourceDebug(ResourceType type, double amount) {
    _addResource(type, amount);
    notifyListeners();
  }

  void unlockAllTechDebug() {
    for (final t in Technology.all) {
      state.unlockedTechIds.add(t.id);
    }
    notifyListeners();
  }

  void notifyUpdate() {
    notifyListeners();
  }
}
