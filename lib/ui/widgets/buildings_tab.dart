import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/building.dart';
import '../../models/recipe.dart';
import '../../models/resource_type.dart';
import '../../models/game_state.dart';
import '../../models/technology.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class BuildingsTab extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const BuildingsTab({super.key, required this.state, required this.engine});

  @override
  Widget build(BuildContext context) {
    final unlockedBuildings = BuildingType.values
        .where((b) => state.isBuildingUnlocked(b))
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: unlockedBuildings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bldType = unlockedBuildings[index];
        final bldState = state.buildings[bldType]!;
        final canBuy = engine.canPurchaseBuilding(bldType);
        final cost = bldType.costForCount(bldState.count);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bldType.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                bldType.name,
                                style: const TextStyle(
                                  color: FactoryTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: FactoryTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: FactoryTheme.border,
                                  ),
                                ),
                                child: Text(
                                  'Count: ${bldState.count}',
                                  style: const TextStyle(
                                    color: FactoryTheme.accentAmber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            bldType.description,
                            style: const TextStyle(
                              color: FactoryTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      identifier: 'buy-btn-${bldType.id}',
                      label: 'Buy ${bldType.name}',
                      button: true,
                      child: ElevatedButton(
                        key: ValueKey('btn-buy-${bldType.id}'),
                        onPressed: canBuy
                            ? () => engine.purchaseBuilding(bldType)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canBuy
                              ? FactoryTheme.accentAmber
                              : FactoryTheme.surfaceLight,
                          foregroundColor: canBuy
                              ? Colors.black
                              : FactoryTheme.textSecondary,
                        ),
                        child: const Text('BUY +1'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Cost display
                Row(
                  children: [
                    const Text(
                      'Cost: ',
                      style: TextStyle(
                        color: FactoryTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: cost.entries.map((c) {
                        final available =
                            (state.inventory[c.key] ?? 0.0) >= c.value;
                        return Text(
                          '${c.value} ${c.key.label}',
                          style: TextStyle(
                            color: available
                                ? FactoryTheme.textPrimary
                                : FactoryTheme.accentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Allocate owned machines across targets or recipes, or show storage status.
                if (bldState.count > 0) ...[
                  const Divider(color: FactoryTheme.border, height: 20),
                  if (bldType.category == BuildingCategory.storage) ...[
                    Row(
                      children: [
                        const Text(
                          'STORAGE VAULT',
                          style: TextStyle(
                            color: FactoryTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${bldType.storageCapacity} / chest',
                          style: const TextStyle(
                            color: FactoryTheme.accentCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: FactoryTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: FactoryTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, color: FactoryTheme.accentCyan, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vault holds +${FactoryTheme.formatNumber((bldType.storageCapacity * bldState.count).toDouble())} max capacity per resource type.',
                              style: const TextStyle(
                                color: FactoryTheme.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Text(
                          'MACHINE ALLOCATIONS',
                          style: TextStyle(
                            color: FactoryTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${bldState.unassignedCount} unassigned',
                          style: TextStyle(
                            color: bldState.unassignedCount > 0
                                ? FactoryTheme.accentAmber
                                : FactoryTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (bldType.category == BuildingCategory.mining)
                      _buildMinerAllocations(bldType, bldState)
                    else if (bldType.category == BuildingCategory.smelting ||
                        bldType.category == BuildingCategory.assembling ||
                        bldType.category == BuildingCategory.rocketSilo)
                      _buildRecipeAllocations(bldType, bldState)
                    else
                      const Text(
                        'All labs work on the technology selected in Research.',
                        style: TextStyle(
                          color: FactoryTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                  const SizedBox(height: 10),
                  _buildOperationalStatus(bldType, bldState),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinerAllocations(BuildingType type, BuildingState building) {
    const resources = [
      ResourceType.coal,
      ResourceType.ironOre,
      ResourceType.copperOre,
      ResourceType.stone,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: resources
          .map(
            (resource) => _buildAllocationControl(
              label: '${resource.icon} ${resource.label}',
              count: building.miningAllocations[resource] ?? 0,
              canAdd: building.unassignedCount > 0,
              onRemove: () => engine.adjustMinerAllocation(type, resource, -1),
              onAdd: () => engine.adjustMinerAllocation(type, resource, 1),
              semanticName: '${type.name} ${resource.label}',
            ),
          )
          .toList(),
    );
  }

  Widget _buildRecipeAllocations(BuildingType type, BuildingState building) {
    final recipes = Recipe.all.where((recipe) {
      if (!state.isRecipeUnlocked(recipe)) return false;
      if (type.category == BuildingCategory.smelting) {
        return recipe.category == CraftingCategory.smelting;
      }
      if (type.category == BuildingCategory.assembling) {
        return recipe.category == CraftingCategory.assembling;
      }
      return type == BuildingType.rocketSilo &&
          recipe.category == CraftingCategory.silo;
    });
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recipes
          .map(
            (recipe) => _buildAllocationControl(
              label: recipe.name,
              count: building.recipeAllocations[recipe.id] ?? 0,
              canAdd: building.unassignedCount > 0,
              onRemove: () =>
                  engine.adjustRecipeAllocation(type, recipe.id, -1),
              onAdd: () => engine.adjustRecipeAllocation(type, recipe.id, 1),
              semanticName: '${type.name} ${recipe.name}',
            ),
          )
          .toList(),
    );
  }

  Widget _buildAllocationControl({
    required String label,
    required int count,
    required bool canAdd,
    required VoidCallback onRemove,
    required VoidCallback onAdd,
    required String semanticName,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: FactoryTheme.surfaceLight,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: count > 0
              ? FactoryTheme.accentCyan.withValues(alpha: 0.7)
              : FactoryTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: count > 0
                  ? FactoryTheme.textPrimary
                  : FactoryTheme.textSecondary,
              fontSize: 11,
              fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Remove one from $semanticName',
            button: true,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: count > 0 ? onRemove : null,
              icon: const Icon(Icons.remove, size: 16),
            ),
          ),
          Container(
            width: 26,
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: const TextStyle(
                color: FactoryTheme.accentAmber,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Semantics(
            label: 'Assign one to $semanticName',
            button: true,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              onPressed: canAdd ? onAdd : null,
              icon: const Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalStatus(BuildingType type, BuildingState building) {
    final multiplier = state.gameSpeedMultiplier * state.prestigeMultiplier;
    late final bool isRunning;
    late final String summary;
    late final String detail;
    var isComplete = false;

    if (type.category == BuildingCategory.storage) {
      isRunning = true;
      summary = 'ACTIVE — Expanding Storage Capacity';
      final totalCapacity = type.storageCapacity * building.count;
      detail = '+${FactoryTheme.formatNumber(totalCapacity.toDouble())} capacity to all resources';
    } else if (type.category == BuildingCategory.mining) {
      final allocations = building.miningAllocations.entries
          .where((entry) => entry.value > 0)
          .toList();
      final fullResources = allocations
          .where((entry) => (state.inventory[entry.key] ?? 0) >= state.maxStorageFor(entry.key))
          .map((entry) => entry.key.label)
          .toList();
      final activeAllocations = allocations
          .where((entry) => (state.inventory[entry.key] ?? 0) < state.maxStorageFor(entry.key))
          .toList();
      final activeCount = activeAllocations.fold<int>(0, (sum, e) => sum + e.value);

      final fullOutputRate =
          type.craftSpeed * activeCount * multiplier;
      final fuelRate = type == BuildingType.burnerMiner
          ? 0.1 * activeCount * multiplier
          : 0.0;
      final fuelNeededPerTick = fuelRate / GameEngine.ticksPerSecond;
      final availableFuel = state.inventory[ResourceType.coal] ?? 0;
      final activityRatio = fuelNeededPerTick > 0
          ? min(1.0, availableFuel / fuelNeededPerTick)
          : 1.0;

      if (allocations.isEmpty) {
        isRunning = false;
        summary = 'STOPPED — No machines assigned';
        detail = '${building.count} machines are idle';
      } else if (activeAllocations.isEmpty) {
        isRunning = false;
        summary = 'PAUSED — Storage Full (${fullResources.join(', ')})';
        detail = 'Build chests to expand storage capacity';
      } else if (type == BuildingType.burnerMiner && activityRatio == 0) {
        isRunning = false;
        summary = 'STOPPED — Missing Coal fuel';
        detail = '$activeCount assigned machines are idle';
      } else {
        isRunning = true;
        summary = activityRatio < 1
            ? 'THROTTLED — ${(activityRatio * 100).toStringAsFixed(0)}% fuel supply'
            : fullResources.isNotEmpty
            ? 'PARTIAL — $activeCount/${building.count} miners active (${fullResources.join(', ')} full)'
            : 'RUNNING — ${building.allocatedCount}/${building.count} miners active';
        detail =
            '${(fullOutputRate * activityRatio).toStringAsFixed(1)}/s total output'
            '${fuelRate > 0 ? ' · ${(fuelRate * activityRatio).toStringAsFixed(1)}/s Coal fuel' : ''}';
      }
    } else if (type == BuildingType.researchLab) {
      final technology = state.activeResearchId == null
          ? null
          : Technology.getById(state.activeResearchId!);
      final progressRate = technology == null
          ? 0.0
          : (1 / technology.researchDurationTicks) *
                building.count *
                multiplier;
      final missing =
          technology?.cost.entries
              .where(
                (entry) =>
                    (state.inventory[entry.key] ?? 0) <
                    entry.value * progressRate,
              )
              .map((entry) => entry.key.label)
              .toList() ??
          const <String>[];
      isRunning = technology != null && missing.isEmpty;
      summary = technology == null
          ? 'IDLE — Select a technology in Research'
          : isRunning
          ? 'RUNNING — Researching ${technology.name}'
          : 'STOPPED — Missing ${missing.join(' + ')}';
      detail = '${building.count} labs available';
    } else {
      final allocations = building.recipeAllocations.entries
          .where((entry) => entry.value > 0)
          .toList();
      if (type == BuildingType.rocketSilo && state.rocketPartsBuilt >= 100) {
        isRunning = false;
        isComplete = true;
        summary = 'COMPLETE — Rocket ready to launch';
        detail = 'No more materials will be consumed';
      } else {
        final missing = <String>{};
        final fullOutputs = <String>{};
        var runningAllocations = 0;
        for (final allocation in allocations) {
          final recipe = Recipe.getById(allocation.key);
          if (recipe == null) continue;
          final isFull = recipe.outputs.keys.every(
            (outRes) => (state.inventory[outRes] ?? 0) >= state.maxStorageFor(outRes),
          );
          if (isFull) {
            fullOutputs.addAll(recipe.outputs.keys.map((r) => r.label));
            continue;
          }
          final cyclesPerSecond =
              GameEngine.ticksPerSecond /
              recipe.durationTicks *
              type.craftSpeed *
              allocation.value *
              multiplier;
          final missingForRecipe = recipe.inputs.entries.where(
            (entry) =>
                (state.inventory[entry.key] ?? 0) <
                entry.value * cyclesPerSecond / GameEngine.ticksPerSecond,
          );
          if (missingForRecipe.isEmpty) {
            runningAllocations++;
          } else {
            missing.addAll(missingForRecipe.map((entry) => entry.key.label));
          }
        }
        isRunning = runningAllocations > 0;
        summary = allocations.isEmpty
            ? 'STOPPED — No machines assigned'
            : runningAllocations == allocations.length
            ? 'RUNNING — $runningAllocations production lines active'
            : runningAllocations > 0
            ? 'PARTIAL — $runningAllocations/${allocations.length} lines running'
            : fullOutputs.isNotEmpty
            ? 'PAUSED — Storage Full (${fullOutputs.join(', ')})'
            : 'STOPPED — Missing ${missing.join(' + ')}';
        detail =
            '${building.allocatedCount}/${building.count} machines assigned';
      }
    }

    final color = isComplete
        ? FactoryTheme.accentCyan
        : isRunning
        ? FactoryTheme.accentGreen
        : FactoryTheme.accentRed;
    return Semantics(
      label: '$summary. $detail',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(
              isComplete
                  ? Icons.check_circle
                  : isRunning
                  ? Icons.play_circle_fill
                  : Icons.error,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: FactoryTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
