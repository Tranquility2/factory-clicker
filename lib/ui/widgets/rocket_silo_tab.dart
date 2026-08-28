import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class RocketSiloTab extends StatefulWidget {
  final GameState state;
  final GameEngine engine;

  const RocketSiloTab({super.key, required this.state, required this.engine});

  @override
  State<RocketSiloTab> createState() => _RocketSiloTabState();
}

class _RocketSiloTabState extends State<RocketSiloTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _launch;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _launch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partsBuilt = widget.state.rocketPartsBuilt;
    final isReady = partsBuilt >= 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _launch,
            builder: (context, child) {
              final progress = _launch.value;
              final ignition = ((progress - 0.45) / 0.25).clamp(0.0, 1.0);
              final shake = sin(progress * pi * 42) * ignition * 4;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RocketLaunchPainter(progress: progress),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(
                                0,
                                progress > 0.72 ? -(progress - 0.72) * 250 : 0,
                              ),
                              child: Text(
                                progress > 0.72 ? '🚀' : '🚀',
                                style: TextStyle(
                                  fontSize: 48,
                                  shadows: ignition > 0
                                      ? [
                                          Shadow(
                                            color: Colors.orange.withValues(
                                              alpha: ignition,
                                            ),
                                            blurRadius: 18 * ignition,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLaunching
                                  ? _countdownLabel(progress)
                                  : 'ORBITAL ROCKET SILO',
                              style: TextStyle(
                                color: _isLaunching
                                    ? FactoryTheme.accentAmber
                                    : FactoryTheme.textPrimary,
                                fontSize: _isLaunching ? 24 : 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Construct 100 Rocket Parts to launch a satellite '
                              'into orbit, resetting terrestrial infrastructure '
                              'for permanent Space Science artifacts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: FactoryTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                value: (partsBuilt / 100).clamp(0, 1),
                                backgroundColor: FactoryTheme.surfaceLight,
                                valueColor: AlwaysStoppedAnimation(
                                  Color.lerp(
                                    FactoryTheme.accentAmber,
                                    Colors.white,
                                    ignition * 0.6,
                                  )!,
                                ),
                                minHeight: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Semantics(
                              identifier: 'launch-rocket-btn',
                              label: 'Launch Rocket Prestige',
                              button: true,
                              child: ElevatedButton.icon(
                                key: const ValueKey('btn-launch-rocket'),
                                onPressed: isReady && !_isLaunching
                                    ? _startLaunch
                                    : null,
                                icon: const Icon(Icons.rocket_launch, size: 20),
                                label: Text(
                                  _isLaunching
                                      ? _countdownLabel(progress)
                                      : isReady
                                      ? 'LAUNCH ROCKET (+50 SPACE SCIENCE)'
                                      : 'CONSTRUCTING ($partsBuilt%)',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isReady
                                      ? FactoryTheme.accentAmber
                                      : FactoryTheme.surfaceLight,
                                  foregroundColor: isReady
                                      ? Colors.black
                                      : FactoryTheme.textSecondary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
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
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Total Rocket Launches:',
                    '${widget.state.totalRocketLaunches}',
                  ),
                  _buildStatRow(
                    'Space Science Artifacts:',
                    '${widget.state.spaceScienceCount}',
                  ),
                  _buildStatRow(
                    'Global Production Boost:',
                    '+${((widget.state.prestigeMultiplier - 1) * 100).toStringAsFixed(0)}%',
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

  Future<void> _startLaunch() async {
    if (_isLaunching || widget.state.rocketPartsBuilt < 100) return;
    setState(() {
      _isLaunching = true;
    });
    await _launch.forward(from: 0);
    widget.engine.launchRocket();
    if (!mounted) return;
    setState(() {
      _isLaunching = false;
    });
    _launch.reset();
  }

  String _countdownLabel(double progress) {
    if (progress < 0.22) return 'IGNITION IN 3';
    if (progress < 0.44) return 'IGNITION IN 2';
    if (progress < 0.66) return 'IGNITION IN 1';
    if (progress < 0.82) return 'LIFTOFF';
    return 'ORBIT ACHIEVED';
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FactoryTheme.textSecondary,
              fontSize: 13,
            ),
          ),
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

class _RocketLaunchPainter extends CustomPainter {
  final double progress;

  const _RocketLaunchPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final ignition = ((progress - 0.45) / 0.25).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, 62);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 1.1,
          colors: [
            Colors.orange.withValues(alpha: ignition * 0.34),
            Colors.deepOrange.withValues(alpha: ignition * 0.12),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );

    if (ignition == 0) return;
    final random = Random(7);
    for (var particle = 0; particle < 28; particle++) {
      final seed = random.nextDouble();
      final fall = (progress * (1.2 + seed) + seed) % 1;
      final spread = (random.nextDouble() - 0.5) * 90 * fall;
      final position = Offset(center.dx + spread, center.dy + 28 + fall * 95);
      canvas.drawCircle(
        position,
        1 + (1 - fall) * 2,
        Paint()
          ..color = Color.lerp(
            Colors.white,
            Colors.deepOrange,
            fall,
          )!.withValues(alpha: ignition * (1 - fall)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RocketLaunchPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
