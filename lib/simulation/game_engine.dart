import 'dart:async';
import 'dart:convert';
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
    _processResearch(tickMultiplier);

    _ticksSinceLastSave++;
    if (_ticksSinceLastSave >= ticksPerSecond * 10) {
      // Autosave every 10 seconds
      _ticksSinceLastSave = 0;
      saveToStorage();
    }

    notifyListeners();
  }

  void _addResource(ResourceType type, double amount) {
    final current = state.inventory[type] ?? 0.0;
    state.inventory[type] = (current + amount);
    _tickDeltas[type] = (_tickDeltas[type] ?? 0.0) + amount;
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
    // Burner Miner
    final burner = state.buildings[BuildingType.burnerMiner];
    if (burner != null && burner.count > 0 && burner.targetResource != null) {
      final coalAvailable = (state.inventory[ResourceType.coal] ?? 0.0) > 0.01;
      if (coalAvailable) {
        // Burner consumes 0.005 coal per tick per miner
        final coalConsumed = 0.005 * burner.count * multiplier;
        if (_consumeResource(ResourceType.coal, coalConsumed)) {
          final produced = 0.02 * burner.count * multiplier * burner.type.craftSpeed;
          _addResource(burner.targetResource!, produced);
        }
      }
    }

    // Electric Miner
    final electric = state.buildings[BuildingType.electricMiner];
    if (electric != null && electric.count > 0 && electric.targetResource != null) {
      final produced = 0.05 * electric.count * multiplier * electric.type.craftSpeed;
      _addResource(electric.targetResource!, produced);
    }
  }

  void _processSmelters(double multiplier) {
    for (final type in [BuildingType.stoneFurnace, BuildingType.steelFurnace]) {
      final bld = state.buildings[type];
      if (bld == null || bld.count == 0 || bld.activeRecipeId == null) continue;

      final recipe = Recipe.getById(bld.activeRecipeId!);
      if (recipe == null) continue;

      // Check fuel and recipe inputs
      final baseProgressRate = (1.0 / recipe.durationTicks) * bld.type.craftSpeed * multiplier;
      final stepFactor = baseProgressRate * bld.count;

      bool hasIngredients = true;
      for (final entry in recipe.inputs.entries) {
        if ((state.inventory[entry.key] ?? 0.0) < entry.value * stepFactor) {
          hasIngredients = false;
          break;
        }
      }

      if (hasIngredients) {
        for (final entry in recipe.inputs.entries) {
          _consumeResource(entry.key, entry.value * stepFactor);
        }
        for (final entry in recipe.outputs.entries) {
          _addResource(entry.key, entry.value * stepFactor);
        }
      }
    }
  }

  void _processAssemblers(double multiplier) {
    for (final type in [BuildingType.assembler1, BuildingType.assembler2, BuildingType.rocketSilo]) {
      final bld = state.buildings[type];
      if (bld == null || bld.count == 0 || bld.activeRecipeId == null) continue;

      final recipe = Recipe.getById(bld.activeRecipeId!);
      if (recipe == null) continue;

      final baseProgressRate = (1.0 / recipe.durationTicks) * bld.type.craftSpeed * multiplier;
      final stepFactor = baseProgressRate * bld.count;

      bool hasIngredients = true;
      for (final entry in recipe.inputs.entries) {
        if ((state.inventory[entry.key] ?? 0.0) < entry.value * stepFactor) {
          hasIngredients = false;
          break;
        }
      }

      if (hasIngredients) {
        for (final entry in recipe.inputs.entries) {
          _consumeResource(entry.key, entry.value * stepFactor);
        }
        for (final entry in recipe.outputs.entries) {
          if (entry.key == ResourceType.rocketPart) {
            state.rocketPartsBuilt += (entry.value * stepFactor).round();
            if (state.rocketPartsBuilt > 100) state.rocketPartsBuilt = 100;
          } else {
            _addResource(entry.key, entry.value * stepFactor);
          }
        }
      }
    }
  }

  void _processResearch(double multiplier) {
    final lab = state.buildings[BuildingType.researchLab];
    if (lab == null || lab.count == 0 || state.activeResearchId == null) return;

    final tech = Technology.getById(state.activeResearchId!);
    if (tech == null) return;

    final progressRate = (1.0 / tech.researchDurationTicks) * lab.count * multiplier;

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

    state.buildings[type]?.count++;
    // Default assignment if unset
    if (type.category == BuildingCategory.mining && state.buildings[type]?.targetResource == null) {
      state.buildings[type]?.targetResource = ResourceType.ironOre;
    } else if (type.category == BuildingCategory.smelting && state.buildings[type]?.activeRecipeId == null) {
      state.buildings[type]?.activeRecipeId = 'smelt_iron';
    } else if (type.category == BuildingCategory.assembling && state.buildings[type]?.activeRecipeId == null) {
      state.buildings[type]?.activeRecipeId = 'craft_copper_wire';
    } else if (type == BuildingType.rocketSilo) {
      state.buildings[type]?.activeRecipeId = 'craft_rocket_part';
    }

    notifyListeners();
    return true;
  }

  void setBuildingRecipe(BuildingType type, String recipeId) {
    state.buildings[type]?.activeRecipeId = recipeId;
    notifyListeners();
  }

  void setMinerTarget(BuildingType type, ResourceType resource) {
    state.buildings[type]?.targetResource = resource;
    notifyListeners();
  }

  bool startResearch(String techId) {
    final tech = Technology.getById(techId);
    if (tech == null) return false;
    if (state.unlockedTechIds.contains(techId)) return false;

    // Check prerequisites
    for (final req in tech.prerequisites) {
      if (!state.unlockedTechIds.contains(req)) return false;
    }

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

  Future<bool> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(saveKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = GameState.fromJson(json);

        // Offline catchup (capped to 8 hours = 28800 seconds)
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedSeconds = ((now - state.lastSaveTimestamp) / 1000).clamp(0, 28800);
        if (elapsedSeconds > 5) {
          final catchupTicks = (elapsedSeconds * ticksPerSecond).toInt();
          // Simulate in large chunks
          final chunkMultiplier = catchupTicks / ticksPerSecond;
          _processMiners(chunkMultiplier);
          _processSmelters(chunkMultiplier);
          _processAssemblers(chunkMultiplier);
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
