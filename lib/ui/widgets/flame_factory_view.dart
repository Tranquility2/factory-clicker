import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../models/building.dart';
import '../../models/game_state.dart';
import '../../models/recipe.dart';
import '../../models/resource_type.dart';
import '../../models/technology.dart';

class FactoryVisualizerGame extends FlameGame {
  GameState? _state;
  double _animationTime = 0;

  void updateGameState(GameState state) {
    _state = state;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final speed = (_state?.gameSpeedMultiplier ?? 1).clamp(0.5, 12);
    _animationTime += dt * speed;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF0E1116),
    );
    _drawGrid(canvas);

    final state = _state;
    if (state == null) return;

    final chains = _buildResourceChains(state);
    _drawHeader(canvas, chains);
    _drawChains(canvas, chains);
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF171C25)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x < size.x; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }
    for (double y = 0; y < size.y; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  void _drawHeader(Canvas canvas, List<_ResourceChain> chains) {
    final activeCount = chains.where((chain) => chain.isRunning).length;
    final label = chains.isEmpty
        ? 'FACTORY FLOW · NO AUTOMATION'
        : 'FACTORY FLOW · $activeCount/${chains.length} CHAINS RUNNING';
    final color = activeCount == chains.length && chains.isNotEmpty
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    final rect = Rect.fromLTWH(12, 7, size.x - 24, 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke,
    );
    _paintText(
      canvas,
      label,
      Offset(size.x / 2, 13),
      color: color,
      fontSize: 10,
      weight: FontWeight.bold,
      anchor: _TextAnchor.topCenter,
    );
  }

  void _drawChains(Canvas canvas, List<_ResourceChain> chains) {
    if (chains.isEmpty) {
      _paintText(
        canvas,
        'Build a miner to start your first resource chain',
        Offset(size.x / 2, size.y / 2),
        color: const Color(0xFF9CA3AF),
        fontSize: 12,
        anchor: _TextAnchor.center,
      );
      return;
    }

    final columns = columnsForWidth(size.x);
    const gap = 10.0;
    const horizontalPadding = 12.0;
    const top = 39.0;
    const cardHeight = 84.0;
    final cardWidth =
        (size.x - horizontalPadding * 2 - gap * (columns - 1)) / columns;

    for (var index = 0; index < chains.length; index++) {
      final row = index ~/ columns;
      final column = index % columns;
      final rect = Rect.fromLTWH(
        horizontalPadding + column * (cardWidth + gap),
        top + row * (cardHeight + gap),
        cardWidth,
        cardHeight,
      );
      _drawChainCard(canvas, rect, chains[index], index);
    }
  }

  void _drawChainCard(
    Canvas canvas,
    Rect rect,
    _ResourceChain chain,
    int index,
  ) {
    final statusColor = chain.isRunning
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final card = RRect.fromRectAndRadius(rect, const Radius.circular(7));

    canvas.drawRRect(card, Paint()..color = const Color(0xEE181C24));
    canvas.drawRRect(
      card,
      Paint()
        ..color = chain.color.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawCircle(
      Offset(rect.left + 10, rect.top + 11),
      3,
      Paint()..color = statusColor,
    );
    _paintText(
      canvas,
      '${chain.machineName} ×${chain.count}',
      Offset(rect.left + 18, rect.top + 5),
      color: chain.color,
      fontSize: 9.5,
      weight: FontWeight.bold,
      maxWidth: rect.width - 28,
    );

    final flowY = rect.top + 42;
    canvas.drawLine(
      Offset(rect.left + 10, flowY),
      Offset(rect.right - 10, flowY),
      Paint()
        ..color = const Color(0xFF30394A)
        ..strokeWidth = 2,
    );

    if (chain.isRunning) {
      final progress = (_animationTime * 0.55 + index * 0.17) % 1;
      canvas.drawCircle(
        Offset(rect.left + 12 + (rect.width - 24) * progress, flowY),
        3,
        Paint()..color = chain.color,
      );
    }

    final inputText = chain.inputs.isEmpty
        ? '∞'
        : chain.inputs.map((resource) => resource.icon).join('+');
    final outputText = chain.outputs.isEmpty
        ? chain.outputLabel
        : chain.outputs.map((resource) => resource.icon).join('+');
    final flowText = '$inputText  →  ${chain.machineIcon}  →  $outputText';
    _paintText(
      canvas,
      flowText,
      Offset(rect.center.dx, flowY - 12),
      color: const Color(0xFFF3F4F6),
      fontSize: rect.width < 180 ? 13 : 15,
      weight: FontWeight.bold,
      maxWidth: rect.width - 16,
      anchor: _TextAnchor.topCenter,
    );

    final status = chain.isRunning ? 'RUNNING' : chain.blockedReason;
    _paintText(
      canvas,
      '${chain.detail} · $status',
      Offset(rect.left + 9, rect.bottom - 18),
      color: chain.isRunning
          ? const Color(0xFF9CA3AF)
          : const Color(0xFFF87171),
      fontSize: 8.5,
      maxWidth: rect.width - 18,
    );

    if (chain.progress != null) {
      final progressRect = Rect.fromLTWH(
        rect.left + 9,
        rect.bottom - 7,
        rect.width - 18,
        3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(progressRect, const Radius.circular(2)),
        Paint()..color = const Color(0xFF30394A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            progressRect.left,
            progressRect.top,
            progressRect.width * chain.progress!,
            progressRect.height,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = chain.color,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset position, {
    required Color color,
    required double fontSize,
    FontWeight weight = FontWeight.normal,
    double? maxWidth,
    _TextAnchor anchor = _TextAnchor.topLeft,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth ?? double.infinity);

    final offset = switch (anchor) {
      _TextAnchor.topLeft => position,
      _TextAnchor.topCenter => Offset(
        position.dx - painter.width / 2,
        position.dy,
      ),
      _TextAnchor.center => Offset(
        position.dx - painter.width / 2,
        position.dy - painter.height / 2,
      ),
    };
    painter.paint(canvas, offset);
  }
}

enum _TextAnchor { topLeft, topCenter, center }

class _ResourceChain {
  final String machineName;
  final String machineIcon;
  final int count;
  final List<ResourceType> inputs;
  final List<ResourceType> outputs;
  final String outputLabel;
  final String detail;
  final Color color;
  final bool isRunning;
  final String blockedReason;
  final double? progress;

  const _ResourceChain({
    required this.machineName,
    required this.machineIcon,
    required this.count,
    required this.inputs,
    required this.outputs,
    this.outputLabel = '',
    required this.detail,
    required this.color,
    required this.isRunning,
    this.blockedReason = 'STARVED',
    this.progress,
  });
}

List<_ResourceChain> _buildResourceChains(GameState state) {
  final chains = <_ResourceChain>[];

  void addMiner(BuildingType type, Color color) {
    final building = state.buildings[type];
    if (building == null || building.count == 0) return;
    final target = building.targetResource ?? ResourceType.ironOre;
    final needsFuel = type == BuildingType.burnerMiner;
    final hasFuel = !needsFuel || (state.inventory[ResourceType.coal] ?? 0) > 0;
    chains.add(
      _ResourceChain(
        machineName: type.name,
        machineIcon: type.icon,
        count: building.count,
        inputs: needsFuel ? const [ResourceType.coal] : const [],
        outputs: [target],
        detail: 'Mining ${target.label}',
        color: color,
        isRunning: hasFuel,
        blockedReason: 'NO COAL',
      ),
    );
  }

  void addRecipeMachine(BuildingType type, Color color) {
    final building = state.buildings[type];
    if (building == null || building.count == 0) return;
    final recipe = building.activeRecipeId == null
        ? null
        : Recipe.getById(building.activeRecipeId!);
    final hasInputs =
        recipe != null &&
        recipe.inputs.entries.every(
          (entry) => (state.inventory[entry.key] ?? 0) > 0,
        );
    chains.add(
      _ResourceChain(
        machineName: type.name,
        machineIcon: type.icon,
        count: building.count,
        inputs: recipe?.inputs.keys.toList() ?? const [],
        outputs: recipe?.outputs.keys.toList() ?? const [],
        outputLabel: '?',
        detail: recipe?.name ?? 'No recipe selected',
        color: color,
        isRunning: hasInputs,
        blockedReason: recipe == null ? 'NO RECIPE' : 'MISSING INPUT',
        progress: type == BuildingType.rocketSilo
            ? (state.rocketPartsBuilt / 100).clamp(0, 1)
            : null,
      ),
    );
  }

  addMiner(BuildingType.burnerMiner, const Color(0xFFD97706));
  addMiner(BuildingType.electricMiner, const Color(0xFFFBBF24));
  addRecipeMachine(BuildingType.stoneFurnace, const Color(0xFFEF4444));
  addRecipeMachine(BuildingType.steelFurnace, const Color(0xFFDC2626));
  addRecipeMachine(BuildingType.assembler1, const Color(0xFF3B82F6));
  addRecipeMachine(BuildingType.assembler2, const Color(0xFF2563EB));

  final lab = state.buildings[BuildingType.researchLab];
  if (lab != null && lab.count > 0) {
    final technology = state.activeResearchId == null
        ? null
        : Technology.getById(state.activeResearchId!);
    final hasInputs =
        technology != null &&
        technology.cost.entries.every(
          (entry) => (state.inventory[entry.key] ?? 0) > 0,
        );
    chains.add(
      _ResourceChain(
        machineName: BuildingType.researchLab.name,
        machineIcon: BuildingType.researchLab.icon,
        count: lab.count,
        inputs: technology?.cost.keys.toList() ?? const [],
        outputs: const [],
        outputLabel: 'TECH',
        detail: technology?.name ?? 'No active research',
        color: const Color(0xFF10B981),
        isRunning: hasInputs,
        blockedReason: technology == null ? 'IDLE' : 'MISSING PACKS',
      ),
    );
  }

  addRecipeMachine(BuildingType.rocketSilo, const Color(0xFFA855F7));
  return chains;
}

int columnsForWidth(double width) {
  if (width >= 1050) return 4;
  if (width >= 720) return 3;
  if (width >= 460) return 2;
  return 1;
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
    _game = FactoryVisualizerGame()..updateGameState(widget.state);
  }

  @override
  void didUpdateWidget(FlameFactoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updateGameState(widget.state);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chainCount = max(1, _buildResourceChains(widget.state).length);
        final columns = columnsForWidth(constraints.maxWidth);
        final rows = (chainCount / columns).ceil();
        final height = 39 + rows * 94 + 6;

        return Container(
          height: height.toDouble(),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1116),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF242A38)),
          ),
          clipBehavior: Clip.antiAlias,
          child: GameWidget(game: _game),
        );
      },
    );
  }
}
