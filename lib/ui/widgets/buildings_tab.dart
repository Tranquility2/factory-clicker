import 'package:flutter/material.dart';
import '../../models/building.dart';
import '../../models/recipe.dart';
import '../../models/resource_type.dart';
import '../../models/game_state.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class BuildingsTab extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const BuildingsTab({
    super.key,
    required this.state,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedBuildings = BuildingType.values.where((b) => state.isBuildingUnlocked(b)).toList();

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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: FactoryTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: FactoryTheme.border),
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
                        onPressed: canBuy ? () => engine.purchaseBuilding(bldType) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canBuy ? FactoryTheme.accentAmber : FactoryTheme.surfaceLight,
                          foregroundColor: canBuy ? Colors.black : FactoryTheme.textSecondary,
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
                        final available = (state.inventory[c.key] ?? 0.0) >= c.value;
                        return Text(
                          '${c.value} ${c.key.label}',
                          style: TextStyle(
                            color: available ? FactoryTheme.textPrimary : FactoryTheme.accentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                // Configuration options (Target resource for miners / Recipe for crafters)
                if (bldState.count > 0) ...[
                  const Divider(color: FactoryTheme.border, height: 20),
                  if (bldType.category == BuildingCategory.mining) ...[
                    Row(
                      children: [
                        const Text(
                          'Target Deposit: ',
                          style: TextStyle(
                            color: FactoryTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<ResourceType>(
                          value: bldState.targetResource ?? ResourceType.ironOre,
                          dropdownColor: FactoryTheme.surfaceLight,
                          items: [
                            ResourceType.coal,
                            ResourceType.ironOre,
                            ResourceType.copperOre,
                            ResourceType.stone,
                          ].map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child: Text('${r.icon} ${r.label}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              engine.setMinerTarget(bldType, val);
                            }
                          },
                        ),
                      ],
                    ),
                  ] else if (bldType.category == BuildingCategory.smelting ||
                      bldType.category == BuildingCategory.assembling) ...[
                    Row(
                      children: [
                        const Text(
                          'Active Recipe: ',
                          style: TextStyle(
                            color: FactoryTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: bldState.activeRecipeId ??
                              (bldType.category == BuildingCategory.smelting
                                  ? 'smelt_iron'
                                  : 'craft_copper_wire'),
                          dropdownColor: FactoryTheme.surfaceLight,
                          items: Recipe.all
                              .where((r) =>
                                  state.isRecipeUnlocked(r) &&
                                  ((bldType.category == BuildingCategory.smelting &&
                                          r.category == CraftingCategory.smelting) ||
                                      (bldType.category == BuildingCategory.assembling &&
                                          r.category == CraftingCategory.assembling)))
                              .map((r) {
                            return DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              engine.setBuildingRecipe(bldType, val);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
