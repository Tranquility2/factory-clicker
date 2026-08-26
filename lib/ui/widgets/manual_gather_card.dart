import 'package:flutter/material.dart';
import '../../models/resource_type.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class ManualGatherCard extends StatelessWidget {
  final GameEngine engine;

  const ManualGatherCard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    final rawResources = [
      ResourceType.coal,
      ResourceType.ironOre,
      ResourceType.copperOre,
      ResourceType.stone,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app, color: FactoryTheme.accentAmber, size: 20),
                SizedBox(width: 8),
                Text(
                  'MANUAL EXTRACTION',
                  style: TextStyle(
                    color: FactoryTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: rawResources.map((res) {
                return Semantics(
                  identifier: 'gather-btn-${res.name}',
                  label: 'Gather ${res.label}',
                  button: true,
                  child: ElevatedButton.icon(
                    key: ValueKey('btn-gather-${res.name}'),
                    onPressed: () => engine.manualGather(res),
                    icon: Text(res.icon, style: const TextStyle(fontSize: 18)),
                    label: Text('Mine ${res.label}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FactoryTheme.surfaceLight,
                      foregroundColor: FactoryTheme.textPrimary,
                      side: const BorderSide(color: FactoryTheme.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
