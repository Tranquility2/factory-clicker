import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/resource_type.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class ManualGatherCard extends StatelessWidget {
  final GameEngine engine;

  const ManualGatherCard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    const rawResources = [
      ResourceType.coal,
      ResourceType.ironOre,
      ResourceType.copperOre,
      ResourceType.stone,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: FactoryTheme.accentAmber,
                  size: 20,
                ),
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
              children: rawResources
                  .map(
                    (resource) =>
                        _GatherButton(resource: resource, engine: engine),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GatherButton extends StatefulWidget {
  final ResourceType resource;
  final GameEngine engine;

  const _GatherButton({required this.resource, required this.engine});

  @override
  State<_GatherButton> createState() => _GatherButtonState();
}

class _GatherButtonState extends State<_GatherButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _impact;

  @override
  void initState() {
    super.initState();
    _impact = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _impact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _resourceColor(widget.resource);
    return Semantics(
      identifier: 'gather-btn-${widget.resource.name}',
      label: 'Gather ${widget.resource.label}',
      button: true,
      child: AnimatedBuilder(
        animation: _impact,
        builder: (context, child) {
          final progress = _impact.value;
          final impactScale = 1 - sin(progress * pi) * 0.08;
          return SizedBox(
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ImpactPainter(progress: progress, color: color),
                  ),
                ),
                Transform.scale(
                  scale: impactScale,
                  child: ElevatedButton.icon(
                    key: ValueKey('btn-gather-${widget.resource.name}'),
                    onPressed: () {
                      widget.engine.manualGather(widget.resource);
                      _impact.forward(from: 0);
                    },
                    icon: Transform.rotate(
                      angle: sin(progress * pi) * -0.18,
                      child: Text(
                        widget.resource.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    label: Text('Mine ${widget.resource.label}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.lerp(
                        FactoryTheme.surfaceLight,
                        color,
                        sin(progress * pi) * 0.22,
                      ),
                      foregroundColor: FactoryTheme.textPrimary,
                      side: BorderSide(
                        color: Color.lerp(
                          FactoryTheme.border,
                          color,
                          sin(progress * pi),
                        )!,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (_impact.isAnimating)
                  Positioned(
                    top: -18 - progress * 16,
                    child: Semantics(
                      liveRegion: true,
                      label: 'Gained 1 ${widget.resource.label}',
                      child: Opacity(
                        opacity: (1 - progress).clamp(0, 1),
                        child: Text(
                          '+1 ${widget.resource.label}',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: color, blurRadius: 8)],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _resourceColor(ResourceType resource) {
    return switch (resource) {
      ResourceType.coal => const Color(0xFF94A3B8),
      ResourceType.ironOre => const Color(0xFFC0CAD8),
      ResourceType.copperOre => const Color(0xFFFB923C),
      ResourceType.stone => const Color(0xFFA8A29E),
      _ => FactoryTheme.accentAmber,
    };
  }
}

class _ImpactPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ImpactPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 10 + progress * size.shortestSide * 0.7;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - progress)
        ..color = color.withValues(alpha: (1 - progress) * 0.7),
    );

    for (var particle = 0; particle < 6; particle++) {
      final angle = particle * pi / 3;
      final distance = 8 + progress * 28;
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * distance,
        2 * (1 - progress),
        Paint()..color = color.withValues(alpha: 1 - progress),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
