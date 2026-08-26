import 'package:flutter/material.dart';
import '../../models/resource_type.dart';
import '../../models/game_state.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class ResourcePanel extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const ResourcePanel({
    super.key,
    required this.state,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    // Show unlocked or non-zero resources
    final activeResources = ResourceType.values.where((r) {
      final amt = state.inventory[r] ?? 0.0;
      return amt > 0 || r.isRaw;
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: FactoryTheme.surface,
        border: const Border(bottom: BorderSide(color: FactoryTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'FACTORY INVENTORY',
                style: TextStyle(
                  color: FactoryTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (state.spaceScienceCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B21A8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🌌 Space Science: ${state.spaceScienceCount} (+${((state.prestigeMultiplier - 1.0) * 100).toStringAsFixed(0)}% Boost)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeResources.map((res) {
              final amount = state.inventory[res] ?? 0.0;
              final rate = engine.ratesPerSecond[res] ?? 0.0;
              final rateSign = rate > 0 ? '+' : '';

              return Semantics(
                identifier: 'counter-${res.name}',
                label: '${res.label}: ${amount.toStringAsFixed(1)}',
                child: Container(
                  key: ValueKey('res-${res.name}'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: FactoryTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: FactoryTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(res.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            res.label,
                            style: const TextStyle(
                              color: FactoryTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                FactoryTheme.formatNumber(amount),
                                style: const TextStyle(
                                  color: FactoryTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (rate.abs() > 0.01) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '($rateSign${rate.toStringAsFixed(1)}/s)',
                                  style: TextStyle(
                                    color: rate > 0 ? FactoryTheme.accentGreen : FactoryTheme.accentRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
