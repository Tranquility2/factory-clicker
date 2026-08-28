import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../models/building.dart';
import '../../models/game_state.dart';
import '../../models/recipe.dart';
import '../../models/resource_type.dart';
import '../../models/technology.dart';
import '../../simulation/game_engine.dart';

class FactoryVisualizerGame extends FlameGame {
  GameState? _state;
  double _time = 0;

  void updateGameState(GameState state) {
    _state = state;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final speed = (_state?.gameSpeedMultiplier ?? 1).clamp(0.5, 8);
    _time += dt * speed;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final viewport = Rect.fromLTWH(0, 0, size.x, size.y);
    _drawShaderFloor(canvas, viewport);

    final state = _state;
    if (state == null) return;

    final nodes = _buildFactoryNodes(state);
    _drawHeader(canvas, nodes, viewport);
    if (nodes.isEmpty) {
      _drawEmptyState(canvas);
    } else {
      final positions = _layoutNodes(nodes);
      _drawBelts(canvas, nodes, positions);
      _drawNodes(canvas, nodes, positions);
      _drawStageLabels(canvas, positions);
    }
    _drawScanlines(canvas, viewport);
  }

  void _drawShaderFloor(Canvas canvas, Rect viewport) {
    final travel = (sin(_time * 0.24) + 1) / 2;
    canvas.drawRect(
      viewport,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.9 + travel * 1.8, -0.8),
          radius: 1.4,
          colors: const [
            Color(0xFF26344D),
            Color(0xFF111824),
            Color(0xFF080B10),
          ],
          stops: const [0, 0.38, 1],
        ).createShader(viewport),
    );

    final gridPaint = Paint()
      ..color = const Color(0x253D4C63)
      ..strokeWidth = 1;
    const spacing = 24.0;
    final drift = (_time * 3) % spacing;
    for (double x = -spacing; x < size.x + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x + drift, 0),
        Offset(x + drift, size.y),
        gridPaint,
      );
    }
    for (double y = 0; y < size.y; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }

  void _drawHeader(Canvas canvas, List<_FactoryNode> nodes, Rect viewport) {
    final running = nodes.where((node) => node.isRunning).length;
    final statusColor = nodes.isNotEmpty && running == nodes.length
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    final rect = Rect.fromLTWH(12, 8, viewport.width - 24, 28);
    final shimmer = (sin(_time * 0.9) + 1) / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + shimmer, 0),
          end: Alignment(1 + shimmer, 0),
          colors: [
            const Color(0xFF121925),
            statusColor.withValues(alpha: 0.24),
            const Color(0xFF121925),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.3),
            statusColor,
            statusColor.withValues(alpha: 0.3),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    _paintText(
      canvas,
      'LIVE FACTORY TOPOLOGY',
      Offset(rect.left + 12, rect.top + 6),
      color: const Color(0xFFF3F4F6),
      fontSize: 10.5,
      weight: FontWeight.bold,
      letterSpacing: 1,
    );
    _paintText(
      canvas,
      nodes.isEmpty
          ? 'NO AUTOMATION'
          : '$running/${nodes.length} GROUPS RUNNING',
      Offset(rect.right - 12, rect.top + 7),
      color: statusColor,
      fontSize: 9,
      weight: FontWeight.bold,
      anchor: _TextAnchor.topRight,
    );
  }

  Map<_FactoryNode, Rect> _layoutNodes(List<_FactoryNode> nodes) {
    const left = 14.0;
    const right = 14.0;
    const top = 61.0;
    const nodeHeight = 70.0;
    const rowGap = 14.0;
    const stageCount = 5;
    final availableWidth = size.x - left - right;
    final stageWidth = availableWidth / stageCount;
    final nodeWidth = min(154.0, max(72.0, stageWidth - 24));
    final positions = <_FactoryNode, Rect>{};

    for (var stage = 0; stage < stageCount; stage++) {
      final stageNodes = nodes.where((node) => node.stage == stage).toList();
      for (var row = 0; row < stageNodes.length; row++) {
        final centerX = left + stageWidth * stage + stageWidth / 2;
        positions[stageNodes[row]] = Rect.fromCenter(
          center: Offset(
            centerX,
            top + nodeHeight / 2 + row * (nodeHeight + rowGap),
          ),
          width: nodeWidth,
          height: nodeHeight,
        );
      }
    }
    return positions;
  }

  void _drawStageLabels(Canvas canvas, Map<_FactoryNode, Rect> positions) {
    const labels = [
      'EXTRACTION',
      'SMELTING',
      'COMPONENTS',
      'SCIENCE',
      'LAUNCH',
    ];
    for (var stage = 0; stage < labels.length; stage++) {
      final stageRects = positions.entries
          .where((entry) => entry.key.stage == stage)
          .map((entry) => entry.value)
          .toList();
      if (stageRects.isEmpty) continue;
      _paintText(
        canvas,
        labels[stage],
        Offset(stageRects.first.center.dx, 43),
        color: const Color(0xFF64748B),
        fontSize: 7.5,
        weight: FontWeight.bold,
        letterSpacing: 0.8,
        anchor: _TextAnchor.topCenter,
      );
    }
  }

  void _drawBelts(
    Canvas canvas,
    List<_FactoryNode> nodes,
    Map<_FactoryNode, Rect> positions,
  ) {
    final edges = <_FactoryEdge>[];
    for (final destination in nodes) {
      for (final resource in destination.inputs) {
        final sources =
            nodes
                .where(
                  (source) =>
                      source.stage < destination.stage &&
                      source.outputs.contains(resource),
                )
                .toList()
              ..sort((a, b) => b.stage.compareTo(a.stage));
        if (sources.isNotEmpty) {
          edges.add(
            _FactoryEdge(
              source: sources.first,
              destination: destination,
              resource: resource,
            ),
          );
        }
      }
    }

    for (var index = 0; index < edges.length; index++) {
      final edge = edges[index];
      final sourceRect = positions[edge.source];
      final destinationRect = positions[edge.destination];
      if (sourceRect == null || destinationRect == null) continue;
      _drawBelt(canvas, sourceRect, destinationRect, edge, index);
    }
  }

  void _drawBelt(
    Canvas canvas,
    Rect source,
    Rect destination,
    _FactoryEdge edge,
    int index,
  ) {
    final start = Offset(source.right - 3, source.center.dy);
    final end = Offset(destination.left + 3, destination.center.dy);
    final horizontalDistance = max(24.0, end.dx - start.dx);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + horizontalDistance * 0.42,
        start.dy,
        end.dx - horizontalDistance * 0.42,
        end.dy,
        end.dx,
        end.dy,
      );
    final resourceColor = _resourceColor(edge.resource);
    final bounds = path.getBounds().inflate(4);
    final active = edge.source.isRunning && edge.destination.isRunning;

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF07090D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            edge.source.color.withValues(alpha: active ? 0.35 : 0.1),
            resourceColor.withValues(alpha: active ? 1 : 0.2),
            edge.destination.color.withValues(alpha: active ? 0.75 : 0.1),
          ],
        ).createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    if (active) {
      canvas.drawPath(
        path,
        Paint()
          ..color = resourceColor.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    if (active) {
      for (var packet = 0; packet < 3; packet++) {
        final progress = (_time * 0.35 + packet / 3 + index * 0.11) % 1;
        final tangent = metric.getTangentForOffset(metric.length * progress);
        if (tangent == null) continue;
        final center = tangent.position;
        canvas.drawCircle(
          center,
          8,
          Paint()
            ..shader = RadialGradient(
              colors: [
                resourceColor.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ).createShader(Rect.fromCircle(center: center, radius: 8)),
        );
        canvas.drawCircle(center, 2.2, Paint()..color = Colors.white);
      }
    }

    final midpoint = metric.getTangentForOffset(metric.length * 0.5);
    if (midpoint != null && horizontalDistance > 54) {
      _drawResourcePill(
        canvas,
        midpoint.position,
        edge.resource,
        resourceColor,
      );
    }
  }

  void _drawResourcePill(
    Canvas canvas,
    Offset center,
    ResourceType resource,
    Color color,
  ) {
    final painter = _textPainter(
      resource.label,
      color: const Color(0xFFF3F4F6),
      fontSize: 7,
      weight: FontWeight.bold,
    );
    final rect = Rect.fromCenter(
      center: center.translate(0, -10),
      width: painter.width + 10,
      height: 14,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()..color = const Color(0xEE111827),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke,
    );
    painter.paint(
      canvas,
      Offset(rect.center.dx - painter.width / 2, rect.top + 2),
    );
  }

  void _drawNodes(
    Canvas canvas,
    List<_FactoryNode> nodes,
    Map<_FactoryNode, Rect> positions,
  ) {
    for (var index = 0; index < nodes.length; index++) {
      final rect = positions[nodes[index]];
      if (rect != null) {
        _drawMachineNode(canvas, rect, nodes[index], index);
      }
    }
  }

  void _drawMachineNode(
    Canvas canvas,
    Rect rect,
    _FactoryNode node,
    int index,
  ) {
    final phase = (_time * 0.2 + index * 0.13) % 1;
    final card = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    final statusColor = node.isComplete
        ? const Color(0xFF06B6D4)
        : node.isRunning
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    canvas.drawRRect(
      card,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.7 + phase * 1.4, -0.6),
          radius: 1.2,
          colors: [
            node.color.withValues(alpha: node.isRunning ? 0.32 : 0.14),
            const Color(0xF2181C24),
            const Color(0xFF0F1319),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + phase * 2, -1),
          end: Alignment(1 + phase * 2, 1),
          colors: [
            node.color.withValues(alpha: 0.35),
            node.color,
            Colors.white.withValues(alpha: 0.8),
            node.color.withValues(alpha: 0.35),
          ],
          stops: const [0, 0.38, 0.52, 1],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    _paintText(
      canvas,
      node.machineIcon,
      Offset(rect.left + 8, rect.top + 8),
      color: Colors.white,
      fontSize: 19,
    );
    canvas.drawCircle(
      Offset(rect.right - 10, rect.top + 10),
      3,
      Paint()..color = statusColor,
    );
    _paintText(
      canvas,
      node.machineName,
      Offset(rect.left + 34, rect.top + 7),
      color: const Color(0xFFF3F4F6),
      fontSize: 8.5,
      weight: FontWeight.bold,
      maxWidth: rect.width - 52,
    );
    _paintText(
      canvas,
      '×${node.count} OWNED',
      Offset(rect.left + 34, rect.top + 20),
      color: node.color,
      fontSize: 7.5,
      weight: FontWeight.bold,
    );
    _paintText(
      canvas,
      node.statusLabel,
      Offset(rect.right - 8, rect.top + 19),
      color: statusColor,
      fontSize: 6,
      weight: FontWeight.bold,
      maxWidth: rect.width * 0.48,
      anchor: _TextAnchor.topRight,
    );

    final assignmentRect = Rect.fromLTWH(
      rect.left + 7,
      rect.top + 35,
      rect.width - 14,
      27,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(assignmentRect, const Radius.circular(5)),
      Paint()..color = const Color(0xB30D1118),
    );
    _paintText(
      canvas,
      node.assignmentVerb,
      Offset(assignmentRect.left + 6, assignmentRect.top + 3),
      color: const Color(0xFF94A3B8),
      fontSize: 6,
      weight: FontWeight.bold,
      letterSpacing: 0.5,
    );
    _paintText(
      canvas,
      node.assignment.toUpperCase(),
      Offset(assignmentRect.left + 6, assignmentRect.top + 12),
      color: node.color,
      fontSize: 8.5,
      weight: FontWeight.bold,
      maxWidth: assignmentRect.width - 12,
    );

    if (node.progress != null) {
      final track = Rect.fromLTWH(
        rect.left + 7,
        rect.bottom - 5,
        rect.width - 14,
        2,
      );
      canvas.drawRect(track, Paint()..color = const Color(0xFF30394A));
      final fill = Rect.fromLTWH(
        track.left,
        track.top,
        track.width * node.progress!,
        track.height,
      );
      canvas.drawRect(
        fill,
        Paint()
          ..shader = LinearGradient(
            colors: [node.color, Colors.white, node.color],
          ).createShader(fill),
      );
    }
  }

  void _drawEmptyState(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2 + 8);
    final pulse = 0.7 + sin(_time * 2) * 0.15;
    canvas.drawCircle(
      center,
      44,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.25 * pulse),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 44)),
    );
    _paintText(
      canvas,
      '⛏️  BUILD A MINER TO START THE FACTORY',
      center,
      color: const Color(0xFFF59E0B),
      fontSize: 10,
      weight: FontWeight.bold,
      anchor: _TextAnchor.topCenter,
    );
  }

  void _drawScanlines(Canvas canvas, Rect viewport) {
    final paint = Paint()..color = const Color(0x0AFFFFFF);
    for (double y = 2; y < viewport.height; y += 5) {
      canvas.drawRect(Rect.fromLTWH(0, y, viewport.width, 1), paint);
    }
  }

  Color _resourceColor(ResourceType resource) {
    return switch (resource) {
      ResourceType.coal => const Color(0xFF94A3B8),
      ResourceType.ironOre => const Color(0xFFC0CAD8),
      ResourceType.copperOre => const Color(0xFFFB923C),
      ResourceType.stone => const Color(0xFFA8A29E),
      ResourceType.ironPlate => const Color(0xFFE2E8F0),
      ResourceType.copperPlate => const Color(0xFFF97316),
      ResourceType.ironGear => const Color(0xFF7DD3FC),
      ResourceType.copperWire => const Color(0xFFF59E0B),
      ResourceType.electronicCircuit => const Color(0xFF22C55E),
      ResourceType.steelPlate => const Color(0xFF60A5FA),
      ResourceType.automationScience => const Color(0xFFEF4444),
      ResourceType.logisticScience => const Color(0xFF10B981),
      ResourceType.rocketPart => const Color(0xFFA855F7),
      ResourceType.spaceScience => const Color(0xFF818CF8),
    };
  }

  TextPainter _textPainter(
    String text, {
    required Color color,
    required double fontSize,
    FontWeight weight = FontWeight.normal,
    double letterSpacing = 0,
    double? maxWidth,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth ?? double.infinity);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset position, {
    required Color color,
    required double fontSize,
    FontWeight weight = FontWeight.normal,
    double? maxWidth,
    double letterSpacing = 0,
    _TextAnchor anchor = _TextAnchor.topLeft,
  }) {
    final painter = _textPainter(
      text,
      color: color,
      fontSize: fontSize,
      weight: weight,
      maxWidth: maxWidth,
      letterSpacing: letterSpacing,
    );
    final offset = switch (anchor) {
      _TextAnchor.topLeft => position,
      _TextAnchor.topCenter => Offset(
        position.dx - painter.width / 2,
        position.dy,
      ),
      _TextAnchor.topRight => Offset(position.dx - painter.width, position.dy),
    };
    painter.paint(canvas, offset);
  }
}

enum _TextAnchor { topLeft, topCenter, topRight }

class _FactoryNode {
  final BuildingType type;
  final int stage;
  final int count;
  final String assignmentVerb;
  final String assignment;
  final Set<ResourceType> inputs;
  final Set<ResourceType> outputs;
  final Color color;
  final bool isRunning;
  final String statusLabel;
  final bool isComplete;
  final double? progress;

  const _FactoryNode({
    required this.type,
    required this.stage,
    required this.count,
    required this.assignmentVerb,
    required this.assignment,
    required this.inputs,
    required this.outputs,
    required this.color,
    required this.isRunning,
    required this.statusLabel,
    this.isComplete = false,
    this.progress,
  });

  String get machineName => type.name;
  String get machineIcon => type.icon;
}

class _FactoryEdge {
  final _FactoryNode source;
  final _FactoryNode destination;
  final ResourceType resource;

  const _FactoryEdge({
    required this.source,
    required this.destination,
    required this.resource,
  });
}

List<_FactoryNode> _buildFactoryNodes(GameState state) {
  final nodes = <_FactoryNode>[];

  void addMiner(BuildingType type, Color color) {
    final building = state.buildings[type];
    if (building == null || building.count == 0) return;
    final needsFuel = type == BuildingType.burnerMiner;
    final fuelNeeded =
        0.1 *
        building.allocatedCount *
        state.gameSpeedMultiplier *
        state.prestigeMultiplier /
        GameEngine.ticksPerSecond;
    final availableFuel = state.inventory[ResourceType.coal] ?? 0;
    final activityRatio = needsFuel && fuelNeeded > 0
        ? min(1.0, availableFuel / fuelNeeded)
        : 1.0;
    final hasFuel = !needsFuel || activityRatio > 0;
    for (final allocation in building.miningAllocations.entries) {
      if (allocation.value <= 0) continue;
      nodes.add(
        _FactoryNode(
          type: type,
          stage: 0,
          count: allocation.value,
          assignmentVerb: 'MINING TARGET',
          assignment: allocation.key.label,
          inputs: needsFuel ? {ResourceType.coal} : const {},
          outputs: {allocation.key},
          color: color,
          isRunning: hasFuel,
          statusLabel: !hasFuel
              ? 'NEEDS COAL'
              : activityRatio < 1
              ? 'THROTTLED'
              : 'RUNNING',
        ),
      );
    }
  }

  void addRecipeMachine(BuildingType type, int stage, Color color) {
    final building = state.buildings[type];
    if (building == null || building.count == 0) return;
    for (final allocation in building.recipeAllocations.entries) {
      if (allocation.value <= 0) continue;
      final recipe = Recipe.getById(allocation.key);
      if (recipe == null) continue;
      final isComplete =
          type == BuildingType.rocketSilo && state.rocketPartsBuilt >= 100;
      final stepFactor =
          (1 / recipe.durationTicks) *
          type.craftSpeed *
          allocation.value *
          state.gameSpeedMultiplier *
          state.prestigeMultiplier;
      final missingInputs = recipe.inputs.entries
          .where(
            (entry) =>
                (state.inventory[entry.key] ?? 0) < entry.value * stepFactor,
          )
          .map((entry) => entry.key.label.toUpperCase())
          .toList();
      final hasInputs = !isComplete && missingInputs.isEmpty;
      nodes.add(
        _FactoryNode(
          type: type,
          stage: stage,
          count: allocation.value,
          assignmentVerb: type == BuildingType.rocketSilo
              ? 'BUILDING'
              : 'ACTIVE RECIPE',
          assignment: recipe.name,
          inputs: recipe.inputs.keys.toSet(),
          outputs: recipe.outputs.keys.toSet(),
          color: color,
          isRunning: hasInputs,
          statusLabel: isComplete
              ? 'READY'
              : hasInputs
              ? 'RUNNING'
              : 'NEEDS ${missingInputs.join(' + ')}',
          isComplete: isComplete,
          progress: type == BuildingType.rocketSilo
              ? (state.rocketPartsBuilt / 100).clamp(0, 1)
              : null,
        ),
      );
    }
  }

  addMiner(BuildingType.burnerMiner, const Color(0xFFF59E0B));
  addMiner(BuildingType.electricMiner, const Color(0xFFEAB308));
  addRecipeMachine(BuildingType.stoneFurnace, 1, const Color(0xFFF97316));
  addRecipeMachine(BuildingType.steelFurnace, 1, const Color(0xFFEF4444));
  addRecipeMachine(BuildingType.assembler1, 2, const Color(0xFF38BDF8));
  addRecipeMachine(BuildingType.assembler2, 3, const Color(0xFF3B82F6));

  final lab = state.buildings[BuildingType.researchLab];
  if (lab != null && lab.count > 0) {
    final technology = state.activeResearchId == null
        ? null
        : Technology.getById(state.activeResearchId!);
    final progressRate = technology == null
        ? 0.0
        : (1 / technology.researchDurationTicks) *
              lab.count *
              state.gameSpeedMultiplier *
              state.prestigeMultiplier;
    final hasPacks =
        technology != null &&
        technology.cost.entries.every(
          (entry) =>
              (state.inventory[entry.key] ?? 0) >= entry.value * progressRate,
        );
    final missingPacks =
        technology?.cost.entries
            .where(
              (entry) =>
                  (state.inventory[entry.key] ?? 0) <
                  entry.value * progressRate,
            )
            .map((entry) => entry.key.label.toUpperCase())
            .join(' + ') ??
        '';
    nodes.add(
      _FactoryNode(
        type: BuildingType.researchLab,
        stage: 3,
        count: lab.count,
        assignmentVerb: 'RESEARCHING',
        assignment: technology?.name ?? 'Nothing selected',
        inputs: technology?.cost.keys.toSet() ?? const {},
        outputs: const {},
        color: const Color(0xFF10B981),
        isRunning: hasPacks,
        statusLabel: hasPacks
            ? 'RUNNING'
            : technology == null
            ? 'IDLE'
            : 'NEEDS $missingPacks',
      ),
    );
  }

  addRecipeMachine(BuildingType.rocketSilo, 4, const Color(0xFFA855F7));
  return nodes;
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
    final nodes = _buildFactoryNodes(widget.state);
    final maxRows = nodes.isEmpty
        ? 1
        : List.generate(
            5,
            (stage) => nodes.where((node) => node.stage == stage).length,
          ).reduce(max);
    final height = nodes.isEmpty ? 168.0 : (61 + maxRows * 84 + 10).toDouble();

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1116),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D3545)),
        boxShadow: const [
          BoxShadow(color: Color(0x5506B6D4), blurRadius: 12, spreadRadius: -7),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GameWidget(game: _game),
    );
  }
}
