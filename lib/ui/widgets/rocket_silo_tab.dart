import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class RocketSiloTab extends StatelessWidget {
  final GameState state;
  final GameEngine engine;

  const RocketSiloTab({
    super.key,
    required this.state,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final partsBuilt = state.rocketPartsBuilt;
    final isReady = partsBuilt >= 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Silo Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  const Text(
                    'ORBITAL ROCKET SILO',
                    style: TextStyle(
                      color: FactoryTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Construct 100 Rocket Parts to launch a satellite into orbit, resetting terrestrial infrastructure for permanent Space Science artifacts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FactoryTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rocket Construction Progress',
                        style: TextStyle(
                          color: FactoryTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$partsBuilt / 100 Parts',
                        style: const TextStyle(
                          color: FactoryTheme.accentAmber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (partsBuilt / 100.0).clamp(0.0, 1.0),
                      backgroundColor: FactoryTheme.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(FactoryTheme.accentAmber),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Launch Button
                  Semantics(
                    identifier: 'launch-rocket-btn',
                    label: 'Launch Rocket Prestige',
                    button: true,
                    child: ElevatedButton.icon(
                      key: const ValueKey('btn-launch-rocket'),
                      onPressed: isReady ? () => engine.launchRocket() : null,
                      icon: const Icon(Icons.rocket_launch, size: 20),
                      label: Text(
                        isReady ? 'LAUNCH ROCKET (+50 SPACE SCIENCE)' : 'CONSTRUCTING ($partsBuilt%)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReady ? FactoryTheme.accentAmber : FactoryTheme.surfaceLight,
                        foregroundColor: isReady ? Colors.black : FactoryTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Prestige Statistics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRESTIGE MILESTONES',
                    style: TextStyle(
                      color: FactoryTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Total Rocket Launches:', '${state.totalRocketLaunches}'),
                  _buildStatRow('Space Science Artifacts:', '${state.spaceScienceCount}'),
                  _buildStatRow(
                    'Global Production Boost:',
                    '+${((state.prestigeMultiplier - 1.0) * 100).toStringAsFixed(0)}%',
                    color: FactoryTheme.accentGreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FactoryTheme.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: color ?? FactoryTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
