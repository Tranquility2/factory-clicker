import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../models/game_state.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class CraftingTab extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const CraftingTab({
    super.key,
    required this.state,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final availableRecipes = Recipe.all.where((r) => state.isRecipeUnlocked(r)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Craft Queue Header
          if (state.manualCraftQueue.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.handyman, color: FactoryTheme.accentAmber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'CRAFTING QUEUE (${state.manualCraftQueue.length})',
                          style: const TextStyle(
                            color: FactoryTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...state.manualCraftQueue.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final isCurrent = idx == 0;
                      final progress = (item.progressTicks / item.recipe.durationTicks).clamp(0.0, 1.0);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${idx + 1}. ${item.recipe.name}',
                                  style: TextStyle(
                                    color: isCurrent ? FactoryTheme.textPrimary : FactoryTheme.textSecondary,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: FactoryTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: FactoryTheme.surfaceLight,
                                valueColor: const AlwaysStoppedAnimation(FactoryTheme.accentAmber),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Text(
            'AVAILABLE RECIPES',
            style: TextStyle(
              color: FactoryTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availableRecipes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final recipe = availableRecipes[index];
              final canCraft = engine.canCraftManual(recipe);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: const TextStyle(
                                color: FactoryTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recipe.description,
                              style: const TextStyle(
                                color: FactoryTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: recipe.inputs.entries.map((inEntry) {
                                final has = (state.inventory[inEntry.key] ?? 0.0) >= inEntry.value;
                                return Text(
                                  '${inEntry.value}x ${inEntry.key.label}',
                                  style: TextStyle(
                                    color: has ? FactoryTheme.textSecondary : FactoryTheme.accentRed,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        identifier: 'craft-btn-${recipe.id}',
                        label: 'Craft ${recipe.name}',
                        button: true,
                        child: ElevatedButton(
                          key: ValueKey('btn-craft-${recipe.id}'),
                          onPressed: canCraft ? () => engine.startManualCraft(recipe) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canCraft ? FactoryTheme.accentAmber : FactoryTheme.surfaceLight,
                            foregroundColor: canCraft ? Colors.black : FactoryTheme.textSecondary,
                          ),
                          child: const Text('CRAFT'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
