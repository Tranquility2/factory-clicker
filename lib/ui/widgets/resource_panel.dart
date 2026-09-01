import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/resource_type.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class ResourcePanel extends StatefulWidget {
  final GameState state;
  final GameEngine engine;

  const ResourcePanel({super.key, required this.state, required this.engine});

  @override
  State<ResourcePanel> createState() => _ResourcePanelState();
}

class _ResourcePanelState extends State<ResourcePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeResources = ResourceType.values.where((resource) {
      final amount = widget.state.inventory[resource] ?? 0;
      return amount > 0 || resource.isRaw;
    }).toList();

    final maxCap = widget.state.maxStorageCapacity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: FactoryTheme.surface,
        border: Border(bottom: BorderSide(color: FactoryTheme.border)),
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
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: FactoryTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: FactoryTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📦 ', style: TextStyle(fontSize: 11)),
                    Text(
                      'Storage Limit: ${FactoryTheme.formatNumber(maxCap)} / resource',
                      style: const TextStyle(
                        color: FactoryTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (widget.state.spaceScienceCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4C1D95), Color(0xFF7E22CE)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x996B21A8), blurRadius: 9),
                    ],
                  ),
                  child: Text(
                    '🌌 Space Science: ${widget.state.spaceScienceCount} '
                    '(+${((widget.state.prestigeMultiplier - 1) * 100).toStringAsFixed(0)}% Boost)',
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
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final pulse = 0.45 + sin(_pulse.value * pi * 2) * 0.2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeResources
                    .map((resource) => _buildResourceChip(resource, pulse))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChip(ResourceType resource, double pulse) {
    final amount = widget.state.inventory[resource] ?? 0;
    final maxStorage = widget.state.maxStorageFor(resource);
    final isInfinite = maxStorage.isInfinite;
    final fillRatio = isInfinite ? 0.0 : (amount / maxStorage).clamp(0.0, 1.0);
    final isFull = !isInfinite && amount >= maxStorage - 0.001;
    final isNearFull = !isInfinite && fillRatio >= 0.9 && !isFull;

    final rate = widget.engine.ratesPerSecond[resource] ?? 0;
    final isActive = rate.abs() > 0.01;
    final activityColor = isFull
        ? FactoryTheme.accentRed
        : isNearFull
        ? FactoryTheme.accentAmber
        : rate > 0
        ? FactoryTheme.accentGreen
        : rate < 0
        ? FactoryTheme.accentRed
        : FactoryTheme.border;
    final rateSign = rate > 0 ? '+' : '';

    return Semantics(
      identifier: 'counter-${resource.name}',
      label: '${resource.label}: ${amount.toStringAsFixed(1)}${isInfinite ? '' : ' / ${maxStorage.toStringAsFixed(0)}'}',
      child: AnimatedContainer(
        key: ValueKey('res-${resource.name}'),
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: (isActive || isFull)
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      FactoryTheme.surfaceLight,
                      activityColor,
                      pulse * (isFull ? 0.25 : 0.16),
                    )!,
                    FactoryTheme.surfaceLight,
                  ],
                )
              : null,
          color: (isActive || isFull) ? null : FactoryTheme.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isFull
                ? FactoryTheme.accentRed.withValues(alpha: 0.8)
                : isActive
                ? activityColor.withValues(alpha: pulse + 0.2)
                : FactoryTheme.border,
          ),
          boxShadow: (isActive || isFull)
              ? [
                  BoxShadow(
                    color: activityColor.withValues(alpha: pulse * 0.35),
                    blurRadius: 9,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: isActive ? 1 + pulse * 0.04 : 1,
                  child: Text(resource.icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          resource.label,
                          style: const TextStyle(
                            color: FactoryTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isFull) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: FactoryTheme.accentRed.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: FactoryTheme.accentRed, width: 0.8),
                            ),
                            child: const Text(
                              'FULL',
                              style: TextStyle(
                                color: FactoryTheme.accentRed,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          FactoryTheme.formatNumber(amount),
                          style: TextStyle(
                            color: isFull ? FactoryTheme.accentRed : FactoryTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isInfinite)
                          Text(
                            ' / ${FactoryTheme.formatNumber(maxStorage)}',
                            style: const TextStyle(
                              color: FactoryTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (isActive) ...[
                          const SizedBox(width: 4),
                          Icon(
                            rate > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 10,
                            color: activityColor,
                          ),
                          Text(
                            '$rateSign${rate.toStringAsFixed(1)}/s',
                            style: TextStyle(
                              color: activityColor,
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
            if (!isInfinite) ...[
              const SizedBox(height: 4),
              Container(
                width: 90,
                height: 3,
                decoration: BoxDecoration(
                  color: FactoryTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isFull
                          ? FactoryTheme.accentRed
                          : isNearFull
                          ? FactoryTheme.accentAmber
                          : FactoryTheme.accentCyan,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
