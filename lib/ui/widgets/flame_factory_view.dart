import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/building.dart';
import '../../models/recipe.dart';

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
    final bgPaint = Paint()..color = const Color(0xFF0E1116);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // Subtle isometric-like floor grid
    final gridPaint = Paint()
      ..color = const Color(0xFF161B23)
      ..strokeWidth = 1.0;

    const gridSize = 24.0;
    for (double x = 0; x < size.x; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    if (_lastState == null) return;

    final burnerCount = _lastState!.buildings[BuildingType.burnerMiner]?.count ?? 0;
    final electricCount = _lastState!.buildings[BuildingType.electricMiner]?.count ?? 0;
    final stoneFurnaceCount = _lastState!.buildings[BuildingType.stoneFurnace]?.count ?? 0;
    final steelFurnaceCount = _lastState!.buildings[BuildingType.steelFurnace]?.count ?? 0;
    final assembler1Count = _lastState!.buildings[BuildingType.assembler1]?.count ?? 0;
    final assembler2Count = _lastState!.buildings[BuildingType.assembler2]?.count ?? 0;
    final labCount = _lastState!.buildings[BuildingType.researchLab]?.count ?? 0;
    final siloCount = _lastState!.buildings[BuildingType.rocketSilo]?.count ?? 0;
    final rocketParts = _lastState!.rocketPartsBuilt;
    final launches = _lastState!.totalRocketLaunches;

    // Determine Factory Tier
    String tierName = 'STAGE 1: MANUAL EXTRACTION';
    Color tierColor = const Color(0xFF9CA3AF);

    if (siloCount > 0 || rocketParts > 0 || launches > 0) {
      tierName = 'STAGE 4: ORBITAL SPACE PROGRAM';
      tierColor = const Color(0xFFA855F7);
    } else if (assembler1Count > 0 || assembler2Count > 0 || labCount > 0) {
      tierName = 'STAGE 3: HIGH-TECH AUTOMATION & LABS';
      tierColor = const Color(0xFF06B6D4);
    } else if (stoneFurnaceCount > 0 || steelFurnaceCount > 0 || burnerCount > 0 || electricCount > 0) {
      tierName = 'STAGE 2: INDUSTRIAL SMELTING';
      tierColor = const Color(0xFFF59E0B);
    }

    // Top Tier Banner
    final tierBannerPaint = Paint()
      ..color = tierColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final tierBorderPaint = Paint()
      ..color = tierColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final bannerRect = Rect.fromLTWH(12, 6, size.x - 24, 20);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(4)), tierBannerPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bannerRect, const Radius.circular(4)), tierBorderPaint);

    final tierTextPainter = TextPainter(
      text: TextSpan(
        text: '🏭 $tierName',
        style: TextStyle(
          color: tierColor,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tierTextPainter.layout();
    tierTextPainter.paint(canvas, Offset(size.x / 2 - tierTextPainter.width / 2, 9));

    // Build specific machine nodes
    final nodes = <_DetailedMachineNode>[];

    // 1. Miners
    if (burnerCount > 0) {
      nodes.add(_DetailedMachineNode(
        name: 'Burner Drill',
        count: burnerCount,
        color: const Color(0xFFD97706),
        icon: '⛏️',
        subtext: 'Coal/Ore',
        speed: 0.5,
        type: _MachineKind.miner,
      ));
    }
    if (electricCount > 0) {
      nodes.add(_DetailedMachineNode(
        name: 'Electric Drill',
        count: electricCount,
        color: const Color(0xFFFBBF24),
        icon: '⚡',
        subtext: 'Fast Ore',
        speed: 1.5,
        type: _MachineKind.miner,
      ));
    }
    if (nodes.isEmpty) {
      nodes.add(_DetailedMachineNode(
        name: 'Manual Mining',
        count: 1,
        color: const Color(0xFF9CA3AF),
        icon: '⛏️',
        subtext: 'Click Ore',
        speed: 1.0,
        type: _MachineKind.miner,
      ));
    }

    // 2. Smelters
    if (stoneFurnaceCount > 0) {
      final recipeId = _lastState!.buildings[BuildingType.stoneFurnace]?.activeRecipeId ?? 'smelt_iron';
      final recipe = Recipe.getById(recipeId);
      nodes.add(_DetailedMachineNode(
        name: 'Stone Furnace',
        count: stoneFurnaceCount,
        color: const Color(0xFFEF4444),
        icon: '🔥',
        subtext: recipe?.name ?? 'Smelting',
        speed: 1.0,
        type: _MachineKind.smelter,
      ));
    }
    if (steelFurnaceCount > 0) {
      final recipeId = _lastState!.buildings[BuildingType.steelFurnace]?.activeRecipeId ?? 'smelt_steel';
      final recipe = Recipe.getById(recipeId);
      nodes.add(_DetailedMachineNode(
        name: 'Steel Furnace',
        count: steelFurnaceCount,
        color: const Color(0xFFDC2626),
        icon: '🏭',
        subtext: recipe?.name ?? 'Steel/Plates',
        speed: 2.0,
        type: _MachineKind.smelter,
      ));
    }

    // 3. Assemblers
    if (assembler1Count > 0) {
      final recipeId = _lastState!.buildings[BuildingType.assembler1]?.activeRecipeId;
      final recipe = recipeId != null ? Recipe.getById(recipeId) : null;
      nodes.add(_DetailedMachineNode(
        name: 'Assembler I',
        count: assembler1Count,
        color: const Color(0xFF3B82F6),
        icon: '🛠️',
        subtext: recipe?.name ?? 'Gears/Wire',
        speed: 0.75,
        type: _MachineKind.assembler,
      ));
    }
    if (assembler2Count > 0) {
      final recipeId = _lastState!.buildings[BuildingType.assembler2]?.activeRecipeId;
      final recipe = recipeId != null ? Recipe.getById(recipeId) : null;
      nodes.add(_DetailedMachineNode(
        name: 'Assembler II',
        count: assembler2Count,
        color: const Color(0xFF2563EB),
        icon: '⚙️',
        subtext: recipe?.name ?? 'Circuits/Packs',
        speed: 1.5,
        type: _MachineKind.assembler,
      ));
    }

    // 4. Research Labs
    if (labCount > 0) {
      final activeTech = _lastState!.activeResearchId;
      nodes.add(_DetailedMachineNode(
        name: 'Research Lab',
        count: labCount,
        color: const Color(0xFF10B981),
        icon: '🔬',
        subtext: activeTech != null ? 'Researching' : 'Idle',
        speed: 1.0,
        hasActivity: activeTech != null,
        type: _MachineKind.lab,
      ));
    }

    // 5. Rocket Silo
    if (siloCount > 0 || rocketParts > 0) {
      nodes.add(_DetailedMachineNode(
        name: 'Rocket Silo',
        count: max(1, siloCount),
        color: const Color(0xFFA855F7),
        icon: '🚀',
        subtext: '$rocketParts% Built',
        speed: 1.0,
        progress: (rocketParts / 100.0).clamp(0.0, 1.0),
        type: _MachineKind.silo,
      ));
    }

    final n = nodes.length;
    if (n == 0) return;

    // Layout configuration
    final padding = 16.0;
    final availableWidth = size.x - (padding * 2);
    final slotWidth = availableWidth / n;
    final boxWidth = min(120.0, slotWidth - 10.0).clamp(68.0, 120.0);
    final boxHeight = 90.0;
    final centerY = size.y / 2 + 10;

    final positions = <Offset>[];
    for (int i = 0; i < n; i++) {
      final cx = padding + (slotWidth * i) + (slotWidth / 2);
      positions.add(Offset(cx, centerY));
    }

    // 1. Draw animated connecting pipes/belts with moving ingredients
    for (int i = 0; i < n - 1; i++) {
      final start = positions[i];
      final end = positions[i + 1];
      _drawPipeline(
        canvas: canvas,
        from: Offset(start.dx + boxWidth / 2, centerY),
        to: Offset(end.dx - boxWidth / 2, centerY),
        fromNode: nodes[i],
        toNode: nodes[i + 1],
        time: _animationTime,
      );
    }

    // 2. Draw each specific machine node
    for (int i = 0; i < n; i++) {
      _drawDetailedMachine(
        canvas: canvas,
        pos: positions[i],
        width: boxWidth,
        height: boxHeight,
        node: nodes[i],
        time: _animationTime,
      );
    }
  }

  void _drawPipeline({
    required Canvas canvas,
    required Offset from,
    required Offset to,
    required _DetailedMachineNode fromNode,
    required _DetailedMachineNode toNode,
    required double time,
  }) {
    if (to.dx <= from.dx) return;

    final beltHeight = 8.0;
    final beltRect = Rect.fromLTRB(from.dx, from.dy - beltHeight / 2, to.dx, to.dy + beltHeight / 2);

    final bgPaint = Paint()..color = const Color(0xFF1E2430);
    final borderPaint = Paint()
      ..color = const Color(0xFF333E52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(RRect.fromRectAndRadius(beltRect, const Radius.circular(2)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(beltRect, const Radius.circular(2)), borderPaint);

    final length = to.dx - from.dx;
    final flowColor = toNode.color.withValues(alpha: 0.8);
    final arrowPaint = Paint()
      ..color = flowColor
      ..strokeWidth = 1.5;

    // Moving directional arrows
    final offset = (time * 30.0) % 14.0;
    for (double x = from.dx + offset; x < to.dx - 2; x += 14.0) {
      if (x > from.dx + 2) {
        canvas.drawLine(Offset(x - 2, from.dy - 2), Offset(x + 1, from.dy), arrowPaint);
        canvas.drawLine(Offset(x + 1, from.dy), Offset(x - 2, from.dy + 2), arrowPaint);
      }
    }

    // Moving resource packet
    final itemProgress = (time * 0.85) % 1.0;
    final itemX = from.dx + (length * itemProgress);
    final itemPaint = Paint()..color = fromNode.color;
    canvas.drawCircle(Offset(itemX, from.dy), 2.5, itemPaint);
  }

  void _drawDetailedMachine({
    required Canvas canvas,
    required Offset pos,
    required double width,
    required double height,
    required _DetailedMachineNode node,
    required double time,
  }) {
    final rect = Rect.fromCenter(center: pos, width: width, height: height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    final pulse = node.hasActivity ? (sin(time * 3.5) * 0.15 + 0.85) : 0.65;

    final fillPaint = Paint()
      ..color = node.color.withValues(alpha: 0.12 * pulse)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = node.color.withValues(alpha: 0.8 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Header badge (Name + Count)
    final titleText = '${node.name} (${node.count})';
    final titlePainter = TextPainter(
      text: TextSpan(
        text: titleText,
        style: TextStyle(
          color: node.color,
          fontSize: (width < 90) ? 8.5 : 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      maxLines: 1,
      ellipsis: '..',
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: width - 8);
    titlePainter.paint(
      canvas,
      Offset(pos.dx - titlePainter.width / 2, pos.dy - height / 2 + 6),
    );

    // Center icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: node.icon,
        style: TextStyle(fontSize: (width < 90) ? 18.0 : 22.0),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(pos.dx - iconPainter.width / 2, pos.dy - 10),
    );

    // Smoke particles for furnaces
    if (node.type == _MachineKind.smelter && node.hasActivity) {
      final smokePaint = Paint()..color = const Color(0x669CA3AF);
      for (int s = 0; s < 2; s++) {
        final st = (time * 1.8 + (s * 0.5)) % 1.0;
        final sx = pos.dx + sin(time * 3 + s) * 4;
        final sy = (pos.dy - height / 2) - (st * 14);
        canvas.drawCircle(Offset(sx, sy), 1.5 + (st * 2.5), smokePaint);
      }
    }

    // Spinning mini-gear for assemblers
    if (node.type == _MachineKind.assembler && node.hasActivity) {
      canvas.save();
      canvas.translate(pos.dx + width / 2 - 12, pos.dy + height / 2 - 14);
      canvas.rotate(time * 3.0 * node.speed);
      final gearPaint = Paint()
        ..color = node.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset.zero, 3.5, gearPaint);
      for (int c = 0; c < 4; c++) {
        final rad = c * (pi / 2);
        canvas.drawLine(Offset(cos(rad) * 3, sin(rad) * 3), Offset(cos(rad) * 5.5, sin(rad) * 5.5), gearPaint);
      }
      canvas.restore();
    }

    // Sublabel (Assigned Recipe / Target)
    final subPainter = TextPainter(
      text: TextSpan(
        text: node.subtext,
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
    subPainter.layout(maxWidth: width - 6);
    subPainter.paint(
      canvas,
      Offset(pos.dx - subPainter.width / 2, pos.dy + height / 2 - 20),
    );

    // Progress bar for Rocket Silo
    if (node.progress != null) {
      final barWidth = width - 14;
      final barBg = Paint()..color = const Color(0xFF222834);
      final barFg = Paint()..color = node.color;
      final barY = pos.dy + height / 2 - 8;
      final barRect = Rect.fromLTWH(pos.dx - barWidth / 2, barY, barWidth, 4);
      canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(2)), barBg);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx - barWidth / 2, barY, barWidth * node.progress!, 4),
          const Radius.circular(2),
        ),
        barFg,
      );
    }
  }
}

enum _MachineKind { miner, smelter, assembler, lab, silo }

class _DetailedMachineNode {
  final String name;
  final int count;
  final Color color;
  final String icon;
  final String subtext;
  final double speed;
  final bool hasActivity;
  final _MachineKind type;
  final double? progress;

  _DetailedMachineNode({
    required this.name,
    required this.count,
    required this.color,
    required this.icon,
    required this.subtext,
    required this.speed,
    this.hasActivity = true,
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
      height: 155,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1116),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF242A38)),
      ),
      clipBehavior: Clip.antiAlias,
      child: GameWidget(game: _game),
    );
  }
}
