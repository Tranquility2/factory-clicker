import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/building.dart';

class FactoryVisualizerGame extends FlameGame {
  GameState? _lastState;
  double _animationTime = 0.0;

  void updateGameState(GameState state) {
    _lastState = state;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final mult = (_lastState?.gameSpeedMultiplier ?? 1.0).clamp(0.5, 50.0);
    _animationTime += dt * mult;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Deep factory floor background
    final bgPaint = Paint()..color = const Color(0xFF11141A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // Subtle isometric-like floor grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1B202A)
      ..strokeWidth = 1.0;

    const gridSize = 32.0;
    for (double x = 0; x < size.x; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    if (_lastState == null) return;

    // Determine Factory Tier
    final burnerCount = _lastState!.buildings[BuildingType.burnerMiner]?.count ?? 0;
    final electricCount = _lastState!.buildings[BuildingType.electricMiner]?.count ?? 0;
    final totalMiners = burnerCount + electricCount;

    final furnaceCount = (_lastState!.buildings[BuildingType.stoneFurnace]?.count ?? 0) +
        (_lastState!.buildings[BuildingType.steelFurnace]?.count ?? 0);

    final assemblerCount = (_lastState!.buildings[BuildingType.assembler1]?.count ?? 0) +
        (_lastState!.buildings[BuildingType.assembler2]?.count ?? 0);

    final labCount = _lastState!.buildings[BuildingType.researchLab]?.count ?? 0;
    final siloCount = _lastState!.buildings[BuildingType.rocketSilo]?.count ?? 0;
    final rocketParts = _lastState!.rocketPartsBuilt;
    final launches = _lastState!.totalRocketLaunches;

    String tierName = 'TIER 1: RAW EXTRACTION ⛏️';
    Color tierColor = const Color(0xFF9CA3AF);

    if (siloCount > 0 || rocketParts > 0 || launches > 0) {
      tierName = 'TIER 4: ORBITAL SPACE PROGRAM 🚀';
      tierColor = const Color(0xFFA855F7);
    } else if (assemblerCount > 0 || labCount > 0 || _lastState!.unlockedTechIds.length >= 2) {
      tierName = 'TIER 3: HIGH-TECH AUTOMATION ⚡';
      tierColor = const Color(0xFF06B6D4);
    } else if (furnaceCount > 0 || totalMiners > 0) {
      tierName = 'TIER 2: INDUSTRIAL REVOLUTION 🔥';
      tierColor = const Color(0xFFF59E0B);
    }

    // Draw Tier Header Banner
    final tierBannerPaint = Paint()
      ..color = tierColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final tierBorderPaint = Paint()
      ..color = tierColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final bannerRect = Rect.fromLTWH(12, 8, size.x - 24, 22);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(4)), tierBannerPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(4)), tierBorderPaint);

    final tierTextPainter = TextPainter(
      text: TextSpan(
        text: tierName,
        style: TextStyle(
          color: tierColor,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tierTextPainter.layout();
    tierTextPainter.paint(canvas, Offset(size.x / 2 - tierTextPainter.width / 2, 12));

    final activeNodes = <_MachineNode>[];

    // Always show mining if no buildings yet to welcome player
    if (totalMiners > 0 || furnaceCount == 0) {
      activeNodes.add(_MachineNode(
        label: totalMiners > 0 ? 'MINING ($totalMiners)' : 'MANUAL MINING',
        sublabel: totalMiners > 0 ? 'Active Drills' : 'Click to Mine',
        color: const Color(0xFFF59E0B),
        icon: '⛏️',
        hasActivity: true,
        type: _NodeType.miner,
      ));
    }

    if (furnaceCount > 0) {
      activeNodes.add(_MachineNode(
        label: 'SMELTING ($furnaceCount)',
        sublabel: 'Plates & Steel',
        color: const Color(0xFFEF4444),
        icon: '🔥',
        hasActivity: true,
        type: _NodeType.smelter,
      ));
    }

    if (assemblerCount > 0) {
      activeNodes.add(_MachineNode(
        label: 'ASSEMBLY ($assemblerCount)',
        sublabel: 'Circuits & Packs',
        color: const Color(0xFF3B82F6),
        icon: '⚙️',
        hasActivity: true,
        type: _NodeType.assembler,
      ));
    }

    if (labCount > 0) {
      activeNodes.add(_MachineNode(
        label: 'LABS ($labCount)',
        sublabel: _lastState!.activeResearchId != null ? 'Researching' : 'Idle',
        color: const Color(0xFF10B981),
        icon: '🔬',
        hasActivity: _lastState!.activeResearchId != null,
        type: _NodeType.lab,
      ));
    }

    if (siloCount > 0 || rocketParts > 0) {
      activeNodes.add(_MachineNode(
        label: 'ROCKET SILO',
        sublabel: '$rocketParts% Built',
        color: const Color(0xFFA855F7),
        icon: '🚀',
        hasActivity: true,
        type: _NodeType.silo,
        progress: (rocketParts / 100.0).clamp(0.0, 1.0),
      ));
    }

    final n = activeNodes.length;
    if (n == 0) return;

    // Compute dynamic, collision-safe positions
    final padding = 16.0;
    final availableWidth = size.x - (padding * 2);
    final slotWidth = availableWidth / n;
    final boxWidth = min(115.0, slotWidth - 12.0).clamp(65.0, 115.0);
    final boxHeight = 88.0;
    final centerY = size.y / 2 + 10;

    final nodePositions = <Offset>[];
    for (int i = 0; i < n; i++) {
      final cx = padding + (slotWidth * i) + (slotWidth / 2);
      nodePositions.add(Offset(cx, centerY));
    }

    // 1. Draw animated conveyor belts between nodes
    for (int i = 0; i < n - 1; i++) {
      final start = nodePositions[i];
      final end = nodePositions[i + 1];
      _drawConveyorBelt(
        canvas: canvas,
        from: Offset(start.dx + boxWidth / 2, centerY),
        to: Offset(end.dx - boxWidth / 2, centerY),
        time: _animationTime,
      );
    }

    // 2. Draw machines
    for (int i = 0; i < n; i++) {
      final node = activeNodes[i];
      final pos = nodePositions[i];
      _drawMachineBox(
        canvas: canvas,
        pos: pos,
        width: boxWidth,
        height: boxHeight,
        node: node,
        time: _animationTime,
      );
    }
  }

  void _drawConveyorBelt({
    required Canvas canvas,
    required Offset from,
    required Offset to,
    required double time,
  }) {
    if (to.dx <= from.dx) return;

    final beltHeight = 10.0;
    final beltRect = Rect.fromLTRB(from.dx, from.dy - beltHeight / 2, to.dx, to.dy + beltHeight / 2);

    // Belt casing
    final beltBg = Paint()..color = const Color(0xFF262D3D);
    final beltBorder = Paint()
      ..color = const Color(0xFF3F495E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(RRect.fromRectAndRadius(beltRect, const Radius.circular(2)), beltBg);
    canvas.drawRRect(RRect.fromRectAndRadius(beltRect, const Radius.circular(2)), beltBorder);

    // Moving conveyor chevrons
    final chevronPaint = Paint()
      ..color = const Color(0xFF53627E)
      ..strokeWidth = 1.5;

    final length = to.dx - from.dx;
    final offset = (time * 35.0) % 16.0;

    for (double x = from.dx + offset; x < to.dx - 2; x += 16.0) {
      if (x > from.dx + 2) {
        canvas.drawLine(Offset(x - 3, from.dy - 3), Offset(x + 1, from.dy), chevronPaint);
        canvas.drawLine(Offset(x + 1, from.dy), Offset(x - 3, from.dy + 3), chevronPaint);
      }
    }

    // Moving item on belt
    final itemProgress = (time * 0.8) % 1.0;
    final itemX = from.dx + (length * itemProgress);
    final itemPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(itemX, from.dy), 3.0, itemPaint);
  }

  void _drawMachineBox({
    required Canvas canvas,
    required Offset pos,
    required double width,
    required double height,
    required _MachineNode node,
    required double time,
  }) {
    final rect = Rect.fromCenter(center: pos, width: width, height: height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Glow pulse for active machines
    final pulse = node.hasActivity ? (sin(time * 4.0) * 0.15 + 0.85) : 0.6;

    final fillPaint = Paint()
      ..color = node.color.withValues(alpha: 0.12 * pulse)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = node.color.withValues(alpha: 0.7 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Header label
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          color: node.color,
          fontSize: (width < 85) ? 8.5 : 10.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      maxLines: 1,
      ellipsis: '..',
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width - 8);
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy - height / 2 + 6),
    );

    // Center icon & specialized animation
    final iconPainter = TextPainter(
      text: TextSpan(
        text: node.icon,
        style: TextStyle(fontSize: (width < 85) ? 20.0 : 24.0),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();

    final iconY = pos.dy - 8;
    iconPainter.paint(
      canvas,
      Offset(pos.dx - iconPainter.width / 2, iconY),
    );

    // Sublabel
    final subPainter = TextPainter(
      text: TextSpan(
        text: node.sublabel,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 8.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 1,
      ellipsis: '..',
      textDirection: TextDirection.ltr,
    );
    subPainter.layout(maxWidth: width - 8);
    subPainter.paint(
      canvas,
      Offset(pos.dx - subPainter.width / 2, pos.dy + height / 2 - 20),
    );

    // Smoke particles for smelter
    if (node.type == _NodeType.smelter && node.hasActivity) {
      final smokePaint = Paint()..color = const Color(0x669CA3AF);
      for (int s = 0; s < 3; s++) {
        final st = (time * 1.5 + (s * 0.4)) % 1.0;
        final sx = pos.dx + sin(time * 3 + s) * 6;
        final sy = (pos.dy - height / 2) - (st * 16);
        final sRadius = 2.0 + (st * 3.5);
        canvas.drawCircle(Offset(sx, sy), sRadius, smokePaint);
      }
    }

    // Rotating mini-cog for assemblers
    if (node.type == _NodeType.assembler && node.hasActivity) {
      canvas.save();
      canvas.translate(pos.dx + width / 2 - 14, pos.dy + height / 2 - 14);
      canvas.rotate(time * 3.0);
      final cogPaint = Paint()
        ..color = node.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset.zero, 5.0, cogPaint);
      for (int c = 0; c < 4; c++) {
        final rad = c * (pi / 2);
        canvas.drawLine(Offset(cos(rad) * 4, sin(rad) * 4), Offset(cos(rad) * 7, sin(rad) * 7), cogPaint);
      }
      canvas.restore();
    }

    // Progress bar for Rocket Silo or Crafting
    if (node.progress != null) {
      final barWidth = width - 16;
      final barBg = Paint()..color = const Color(0xFF222834);
      final barFg = Paint()..color = node.color;
      final barY = pos.dy + height / 2 - 14;
      final barRect = Rect.fromLTWH(pos.dx - barWidth / 2, barY, barWidth, 6);
      canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(3)), barBg);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx - barWidth / 2, barY, barWidth * node.progress!, 6),
          const Radius.circular(3),
        ),
        barFg,
      );
    }
  }
}

enum _NodeType { miner, smelter, assembler, lab, silo }

class _MachineNode {
  final String label;
  final String sublabel;
  final Color color;
  final String icon;
  final bool hasActivity;
  final _NodeType type;
  final double? progress;

  _MachineNode({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.hasActivity,
    required this.type,
    this.progress,
  });
}

class FlameFactoryWidget extends StatefulWidget {
  final GameState state;

  const FlameFactoryWidget({super.key, required this.state});

  @override
  State<FlameFactoryWidget> createState() => _FlameFactoryWidgetState();
}

class _FlameFactoryWidgetState extends State<FlameFactoryWidget> {
  late final FactoryVisualizerGame _game;

  @override
  void initState() {
    super.initState();
    _game = FactoryVisualizerGame();
    _game.updateGameState(widget.state);
  }

  @override
  void didUpdateWidget(FlameFactoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updateGameState(widget.state);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF13171F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D3545)),
      ),
      clipBehavior: Clip.antiAlias,
      child: GameWidget(game: _game),
    );
  }
}
