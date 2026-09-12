import 'dart:math';

import 'resource_type.dart';
import 'building.dart';
import 'recipe.dart';
import 'technology.dart';

class ManualCraftItem {
  final Recipe recipe;
  double progressTicks;

  ManualCraftItem({required this.recipe, this.progressTicks = 0.0});

  Map<String, dynamic> toJson() => {
    'recipeId': recipe.id,
    'progressTicks': progressTicks,
  };

  factory ManualCraftItem.fromJson(Map<String, dynamic> json) {
    final recipe =
        Recipe.getById(json['recipeId'] as String) ?? Recipe.all.first;
    return ManualCraftItem(
      recipe: recipe,
      progressTicks: (json['progressTicks'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GameState {
  final Map<ResourceType, double> inventory;
  final Map<BuildingType, BuildingState> buildings;
  final Set<String> unlockedTechIds;
  String? activeResearchId;
  double researchProgressTicks;
  final List<ManualCraftItem> manualCraftQueue;
  int rocketPartsBuilt;
  int totalRocketLaunches;
  int spaceScienceCount;
  int totalManualClicks;
  double gameSpeedMultiplier;
  int lastSaveTimestamp;

  GameState({
    Map<ResourceType, double>? inventory,
    Map<BuildingType, BuildingState>? buildings,
    Set<String>? unlockedTechIds,
    this.activeResearchId,
    this.researchProgressTicks = 0.0,
    List<ManualCraftItem>? manualCraftQueue,
    this.rocketPartsBuilt = 0,
    this.totalRocketLaunches = 0,
    this.spaceScienceCount = 0,
    this.totalManualClicks = 0,
    this.gameSpeedMultiplier = 1.0,
    int? lastSaveTimestamp,
  }) : inventory = inventory ?? _initialInventory(),
       buildings = buildings ?? _initialBuildings(),
       unlockedTechIds = unlockedTechIds ?? <String>{},
       manualCraftQueue = manualCraftQueue ?? <ManualCraftItem>[],
       lastSaveTimestamp =
           lastSaveTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  static Map<ResourceType, double> _initialInventory() {
    final map = <ResourceType, double>{};
    for (final type in ResourceType.values) {
      map[type] = 0.0;
    }
    // Starting starter resources
    map[ResourceType.coal] = 10.0;
    map[ResourceType.ironOre] = 10.0;
    map[ResourceType.stone] = 10.0;
    return map;
  }

  static Map<BuildingType, BuildingState> _initialBuildings() {
    final map = <BuildingType, BuildingState>{};
    for (final type in BuildingType.values) {
      map[type] = BuildingState(type: type, count: 0);
    }
    return map;
  }

  static const double baseStorageCapacity = 100.0;

  double get prestigeMultiplier => 1.0 + (spaceScienceCount * 0.1);

  double get maxStorageCapacity {
    double total = baseStorageCapacity;
    for (final entry in buildings.entries) {
      if (entry.key.category == BuildingCategory.storage) {
        total += entry.key.storageCapacity * entry.value.count;
      }
    }
    return total;
  }

  double maxStorageFor(ResourceType type) {
    if (type == ResourceType.spaceScience) {
      return double.infinity;
    }
    if (type == ResourceType.rocketPart) {
      return 100.0;
    }
    return maxStorageCapacity;
  }

  double researchTicksForStep(Technology technology) {
    final labCount = buildings[BuildingType.researchLab]?.count ?? 0;
    final progress = activeResearchId == technology.id
        ? researchProgressTicks
        : 0.0;
    final remaining = max(0.0, technology.researchDurationTicks - progress);
    return min(remaining, labCount * gameSpeedMultiplier * prestigeMultiplier);
  }

  Map<ResourceType, double> researchCostsForStep(Technology technology) {
    final progressRate =
        researchTicksForStep(technology) / technology.researchDurationTicks;
    return technology.cost.map((resource, totalCost) {
      final required = totalCost * progressRate;
      final available = inventory[resource] ?? 0.0;
      // Snap fractional spending round-off to the actual remaining inventory.
      final amount = (available - required).abs() <= 1e-9
          ? max(0.0, available)
          : required;
      return MapEntry(resource, amount);
    });
  }

  List<ResourceType> missingResearchResources(Technology technology) {
    return researchCostsForStep(technology).entries
        .where((entry) => (inventory[entry.key] ?? 0.0) < entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  bool isTechUnlocked(String techId) => unlockedTechIds.contains(techId);

  bool isRecipeUnlocked(Recipe recipe) {
    if (recipe.requiredTechId == null) return true;
    return unlockedTechIds.contains(recipe.requiredTechId);
  }

  bool isBuildingUnlocked(BuildingType type) {
    if (type == BuildingType.burnerMiner ||
        type == BuildingType.stoneFurnace ||
        type == BuildingType.researchLab ||
        type == BuildingType.woodenChest) {
      return true;
    }
    for (final tech in Technology.all) {
      if (tech.unlockedBuildingIds.contains(type.id)) {
        return unlockedTechIds.contains(tech.id);
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'inventory': inventory.map((k, v) => MapEntry(k.name, v)),
    'buildings': buildings.map((k, v) => MapEntry(k.id, v.toJson())),
    'unlockedTechIds': unlockedTechIds.toList(),
    'activeResearchId': activeResearchId,
    'researchProgressTicks': researchProgressTicks,
    'manualCraftQueue': manualCraftQueue.map((item) => item.toJson()).toList(),
    'rocketPartsBuilt': rocketPartsBuilt,
    'totalRocketLaunches': totalRocketLaunches,
    'spaceScienceCount': spaceScienceCount,
    'totalManualClicks': totalManualClicks,
    'gameSpeedMultiplier': gameSpeedMultiplier,
    'lastSaveTimestamp': lastSaveTimestamp,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final inv = <ResourceType, double>{};
    if (json['inventory'] != null) {
      final rawInv = json['inventory'] as Map<String, dynamic>;
      for (final type in ResourceType.values) {
        inv[type] = (rawInv[type.name] as num?)?.toDouble() ?? 0.0;
      }
    } else {
      inv.addAll(_initialInventory());
    }

    final blds = <BuildingType, BuildingState>{};
    if (json['buildings'] != null) {
      final rawBlds = json['buildings'] as Map<String, dynamic>;
      for (final type in BuildingType.values) {
        final rawBuilding =
            rawBlds[type.id] ?? rawBlds[type.key] ?? rawBlds[type.name];
        if (rawBuilding is Map<String, dynamic>) {
          blds[type] = BuildingState.fromJson(rawBuilding);
        } else {
          blds[type] = BuildingState(type: type, count: 0);
        }
      }
    } else {
      blds.addAll(_initialBuildings());
    }

    final unlocked =
        (json['unlockedTechIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};

    final queue =
        (json['manualCraftQueue'] as List<dynamic>?)
            ?.map((e) => ManualCraftItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <ManualCraftItem>[];
    final savedRocketParts = json['rocketPartsBuilt'] as int? ?? 0;
    final inventoryRocketParts = inv[ResourceType.rocketPart] ?? 0;
    final rocketPartsBuilt = min(
      100,
      max(savedRocketParts, inventoryRocketParts.floor()),
    );
    inv[ResourceType.rocketPart] = max(
      inventoryRocketParts,
      rocketPartsBuilt.toDouble(),
    ).clamp(0, 100);

    return GameState(
      inventory: inv,
      buildings: blds,
      unlockedTechIds: unlocked,
      activeResearchId: json['activeResearchId'] as String?,
      researchProgressTicks:
          (json['researchProgressTicks'] as num?)?.toDouble() ?? 0.0,
      manualCraftQueue: queue,
      rocketPartsBuilt: rocketPartsBuilt,
      totalRocketLaunches: json['totalRocketLaunches'] as int? ?? 0,
      spaceScienceCount: json['spaceScienceCount'] as int? ?? 0,
      totalManualClicks: json['totalManualClicks'] as int? ?? 0,
      gameSpeedMultiplier:
          (json['gameSpeedMultiplier'] as num?)?.toDouble() ?? 1.0,
      lastSaveTimestamp:
          json['lastSaveTimestamp'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}
