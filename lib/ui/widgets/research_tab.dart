import 'package:flutter/material.dart';

import '../../models/building.dart';
import '../../models/technology.dart';
import '../../models/game_state.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class ResearchTab extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const ResearchTab({super.key, required this.state, required this.engine});

  @override
  Widget build(BuildContext context) {
    final labCount = state.buildings[BuildingType.researchLab]?.count ?? 0;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: Technology.all.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tech = Technology.all[index];
        final isUnlocked = state.isTechUnlocked(tech.id);
        final isActive = state.activeResearchId == tech.id;
        final prereqsMet = tech.prerequisites.every(
          (req) => state.isTechUnlocked(req),
        );
        final canStart = engine.canStartResearch(tech.id);
        final progressRate = labCount == 0
            ? 0.0
            : (1 / tech.researchDurationTicks) *
                  labCount *
                  state.gameSpeedMultiplier *
                  state.prestigeMultiplier;
        final missingResources = tech.cost.entries
            .where(
              (entry) =>
                  (state.inventory[entry.key] ?? 0) <
                  entry.value * progressRate,
            )
            .map((entry) => entry.key.label)
            .toList();
        final isProgressing =
            isActive && labCount > 0 && missingResources.isEmpty;
        final progress = isActive
            ? (state.researchProgressTicks / tech.researchDurationTicks).clamp(
                0.0,
                1.0,
              )
            : (isUnlocked ? 1.0 : 0.0);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tech.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tech.name,
                                style: const TextStyle(
                                  color: FactoryTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isUnlocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FactoryTheme.accentGreen.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: FactoryTheme.accentGreen,
                                    ),
                                  ),
                                  child: const Text(
                                    'COMPLETED',
                                    style: TextStyle(
                                      color: FactoryTheme.accentGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FactoryTheme.accentCyan.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: FactoryTheme.accentCyan,
                                    ),
                                  ),
                                  child: const Text(
                                    'RESEARCHING',
                                    style: TextStyle(
                                      color: FactoryTheme.accentCyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            tech.description,
                            style: const TextStyle(
                              color: FactoryTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isUnlocked && !isActive)
                      Semantics(
                        identifier: 'research-btn-${tech.id}',
                        label: 'Research ${tech.name}',
                        button: true,
                        child: ElevatedButton(
                          key: ValueKey('btn-research-${tech.id}'),
                          onPressed: canStart
                              ? () => engine.startResearch(tech.id)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canStart
                                ? FactoryTheme.accentCyan
                                : FactoryTheme.surfaceLight,
                            foregroundColor: canStart
                                ? Colors.black
                                : FactoryTheme.textSecondary,
                          ),
                          child: Text(
                            labCount == 0
                                ? 'NEEDS LAB'
                                : state.activeResearchId != null
                                ? 'RESEARCH BUSY'
                                : !prereqsMet
                                ? 'LOCKED'
                                : 'RESEARCH',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!isUnlocked) ...[
                  Row(
                    children: [
                      const Text(
                        'Requires: ',
                        style: TextStyle(
                          color: FactoryTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: tech.cost.entries.map((c) {
                          final has =
                              (state.inventory[c.key] ?? 0.0) >= c.value;
                          return Text(
                            '${c.value}x ${c.key.label}',
                            style: TextStyle(
                              color: has
                                  ? FactoryTheme.textPrimary
                                  : FactoryTheme.accentRed,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  if (tech.prerequisites.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Prerequisites: ',
                          style: TextStyle(
                            color: FactoryTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          tech.prerequisites
                              .map((p) => Technology.getById(p)?.name ?? p)
                              .join(', '),
                          style: TextStyle(
                            color: prereqsMet
                                ? FactoryTheme.textSecondary
                                : FactoryTheme.accentRed,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                if (isActive) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        isProgressing
                            ? Icons.play_circle_fill
                            : Icons.pause_circle,
                        size: 16,
                        color: isProgressing
                            ? FactoryTheme.accentGreen
                            : FactoryTheme.accentRed,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isProgressing
                            ? '$labCount lab${labCount == 1 ? '' : 's'} researching'
                            : labCount == 0
                            ? 'Paused — build a Research Lab'
                            : 'Paused — missing ${missingResources.join(' + ')}',
                        style: TextStyle(
                          color: isProgressing
                              ? FactoryTheme.accentGreen
                              : FactoryTheme.accentRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: FactoryTheme.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(
                        FactoryTheme.accentCyan,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
