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
    _drawShaderBackground(canvas, viewport);

    final state = _state;
    if (state == null) return;

    final modules = _buildTelemetry(state);
    _drawHeader(canvas, modules, viewport);
    _drawModules(canvas, modules);
    _drawScanlines(canvas, viewport);
  }

  void _drawShaderBackground(Canvas canvas, Rect viewport) {
    final travel = (sin(_time * 0.22) + 1) / 2;
    final shader = RadialGradient(
      center: Alignment(-0.9 + travel * 1.8, -0.8),
      radius: 1.35,
      colors: const [Color(0xFF26344D), Color(0xFF121925), Color(0xFF090C11)],
      stops: const [0, 0.42, 1],
    ).createShader(viewport);
    canvas.drawRect(viewport, Paint()..shader = shader);

    final gridPaint = Paint()
      ..color = const Color(0x243D4C63)
      ..strokeWidth = 1;
    const spacing = 26.0;
    for (double x = -spacing; x < size.x + spacing; x += spacing) {
      final drift = (_time * 3) % spacing;
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

  void _drawHeader(
    Canvas canvas,
    List<_MachineTelemetry> modules,
    Rect viewport,
  ) {
    final running = modules.where((module) => module.isRunning).length;
    final health = modules.isEmpty ? 0.0 : running / modules.length;
    final statusColor = health == 1
        ? const Color(0xFF10B981)
        : health >= 0.5
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    final rect = Rect.fromLTWH(12, 8, viewport.width - 24, 30);
    final shimmer = (sin(_time * 0.8) + 1) / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + shimmer, 0),
          end: Alignment(1 + shimmer, 0),
          colors: [
            const Color(0xFF121925),
            statusColor.withValues(alpha: 0.23),
            const Color(0xFF121925),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.25),
            statusColor,
            statusColor.withValues(alpha: 0.25),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    _paintText(
      canvas,
      'LIVE FACTORY TELEMETRY',
      Offset(rect.left + 12, rect.top + 7),
      color: const Color(0xFFF3F4F6),
      fontSize: 11,
      weight: FontWeight.bold,
      letterSpacing: 1.1,
    );
    _paintText(
      canvas,
      modules.isEmpty
          ? 'NO AUTOMATION ONLINE'
          : '$running / ${modules.length} MACHINE GROUPS RUNNING',
      Offset(rect.right - 12, rect.top + 8),
      color: statusColor,
      fontSize: 9.5,
      weight: FontWeight.bold,
      anchor: _TextAnchor.topRight,
    );
  }

  void _drawModules(Canvas canvas, List<_MachineTelemetry> modules) {
    if (modules.isEmpty) {
      _drawEmptyState(canvas);
      return;
    }

    final columns = telemetryColumnsForWidth(size.x);
    const horizontalPadding = 12.0;
    const gap = 10.0;
    const top = 48.0;
    const cardHeight = 120.0;
    final cardWidth =
        (size.x - horizontalPadding * 2 - gap * (columns - 1)) / columns;

    for (var index = 0; index < modules.length; index++) {
      final row = index ~/ columns;
      final column = index % columns;
      final rect = Rect.fromLTWH(
        horizontalPadding + column * (cardWidth + gap),
        top + row * (cardHeight + gap),
        cardWidth,
        cardHeight,
      );
      _drawTelemetryModule(canvas, rect, modules[index], index);
    }
  }

  void _drawEmptyState(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2 + 10);
    final pulse = 0.65 + sin(_time * 2) * 0.15;
    canvas.drawCircle(
      center,
      46,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.2 * pulse),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 46)),
    );
    _paintText(
      canvas,
      '⛏️',
      Offset(center.dx, center.dy - 27),
      color: Colors.white,
      fontSize: 28,
      anchor: _TextAnchor.topCenter,
    );
    _paintText(
      canvas,
      'BUILD A MINER TO START THE FACTORY',
      Offset(center.dx, center.dy + 10),
      color: const Color(0xFFF59E0B),
      fontSize: 11,
      weight: FontWeight.bold,
      anchor: _TextAnchor.topCenter,
    );
  }

  void _drawTelemetryModule(
    Canvas canvas,
    Rect rect,
    _MachineTelemetry module,
    int index,
  ) {
    final card = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    final phase = (_time * 0.18 + index * 0.14) % 1;
    final statusColor = module.isRunning
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    canvas.drawRRect(
      card,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawRRect(
      card,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.8 + phase * 1.6, -0.4),
          radius: 1.2,
          colors: [
            module.color.withValues(alpha: module.isRunning ? 0.28 : 0.12),
            const Color(0xF2181C24),
            const Color(0xFF10141B),
          ],
          stops: const [0, 0.52, 1],
        ).createShader(rect),
    );

    final borderGlow = LinearGradient(
      begin: Alignment(-1 + phase * 2, -1),
      end: Alignment(1 + phase * 2, 1),
      colors: [
        module.color.withValues(alpha: 0.25),
        module.color,
        Colors.white.withValues(alpha: 0.75),
        module.color.withValues(alpha: 0.25),
      ],
      stops: const [0, 0.38, 0.52, 1],
    ).createShader(rect);
    canvas.drawRRect(
      card,
      Paint()
        ..shader = borderGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = module.isRunning ? 1.5 : 1,
    );

    _drawMachineIdentity(canvas, rect, module, statusColor);
    _drawAssignment(canvas, rect, module);
    _drawMaterialFlow(canvas, rect, module, index);

    if (module.progress != null) {
      _drawProgress(canvas, rect, module);
    }
  }

  void _drawMachineIdentity(
    Canvas canvas,
    Rect rect,
    _MachineTelemetry module,
    Color statusColor,
  ) {
    _paintText(
      canvas,
      module.machineIcon,
      Offset(rect.left + 11, rect.top + 9),
      color: Colors.white,
      fontSize: 21,
    );
    _paintText(
      canvas,
      module.machineName.toUpperCase(),
      Offset(rect.left + 40, rect.top + 8),
      color: const Color(0xFFF3F4F6),
      fontSize: 10,
      weight: FontWeight.bold,
      maxWidth: rect.width - 145,
    );
    _paintText(
      canvas,
      'OWNED ×${module.count}',
      Offset(rect.left + 40, rect.top + 22),
      color: module.color,
      fontSize: 9,
      weight: FontWeight.bold,
    );

    final statusRect = Rect.fromLTWH(rect.right - 89, rect.top + 9, 77, 21);
    canvas.drawRRect(
      RRect.fromRectAndRadius(statusRect, const Radius.circular(11)),
      Paint()..color = statusColor.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      Offset(statusRect.left + 10, statusRect.center.dy),
      3,
      Paint()..color = statusColor,
    );
    _paintText(
      canvas,
      module.isRunning ? 'RUNNING' : module.blockedReason,
      Offset(statusRect.left + 18, statusRect.top + 6),
      color: statusColor,
      fontSize: 8,
      weight: FontWeight.bold,
      maxWidth: statusRect.width - 22,
    );
  }

  void _drawAssignment(Canvas canvas, Rect rect, _MachineTelemetry module) {
    final assignmentRect = Rect.fromLTWH(
      rect.left + 10,
      rect.top + 38,
      rect.width - 20,
      37,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(assignmentRect, const Radius.circular(6)),
      Paint()..color = const Color(0x9910141B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(assignmentRect, const Radius.circular(6)),
      Paint()
        ..color = module.color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke,
    );
    _paintText(
      canvas,
      module.assignmentVerb,
      Offset(assignmentRect.left + 9, assignmentRect.top + 4),
      color: const Color(0xFF9CA3AF),
      fontSize: 7.5,
      weight: FontWeight.bold,
      letterSpacing: 0.8,
    );
    _paintText(
      canvas,
      module.assignment.toUpperCase(),
      Offset(assignmentRect.left + 9, assignmentRect.top + 15),
      color: module.color,
      fontSize: 12,
      weight: FontWeight.bold,
      maxWidth: assignmentRect.width - 18,
    );
  }

  void _drawMaterialFlow(
    Canvas canvas,
    Rect rect,
    _MachineTelemetry module,
    int index,
  ) {
    final flowY = rect.top + 88;
    final start = Offset(rect.left + 12, flowY);
    final end = Offset(rect.right - 12, flowY);
    final trackRect = Rect.fromLTRB(start.dx, flowY - 2, end.dx, flowY + 2);
    final flowShader = LinearGradient(
      colors: [
        module.color.withValues(alpha: 0.1),
        module.color.withValues(alpha: 0.85),
        module.color.withValues(alpha: 0.1),
      ],
    ).createShader(trackRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, const Radius.circular(2)),
      Paint()..shader = flowShader,
    );

    if (module.isRunning) {
      for (var packet = 0; packet < 3; packet++) {
        final progress =
            (_time * (0.28 + module.activitySpeed * 0.05) +
                packet / 3 +
                index * 0.09) %
            1;
        final center = Offset(start.dx + (end.dx - start.dx) * progress, flowY);
        canvas.drawCircle(
          center,
          8,
          Paint()
            ..shader = RadialGradient(
              colors: [
                module.color.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ).createShader(Rect.fromCircle(center: center, radius: 8)),
        );
        canvas.drawCircle(center, 2.4, Paint()..color = Colors.white);
      }
    }

    final flowLabel = '${module.inputLabel}  →  ${module.outputLabel}';
    _paintText(
      canvas,
      flowLabel,
      Offset(rect.center.dx, rect.top + 96),
      color: const Color(0xFFD1D5DB),
      fontSize: 8.5,
      weight: FontWeight.w600,
      maxWidth: rect.width - 20,
      anchor: _TextAnchor.topCenter,
    );
  }

  void _drawProgress(Canvas canvas, Rect rect, _MachineTelemetry module) {
    final track = Rect.fromLTWH(
      rect.left + 11,
      rect.bottom - 7,
      rect.width - 22,
      3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, const Radius.circular(2)),
      Paint()..color = const Color(0xFF30394A),
    );
    final fill = Rect.fromLTWH(
      track.left,
      track.top,
      track.width * module.progress!,
      track.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(fill, const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          colors: [module.color, Colors.white, module.color],
        ).createShader(fill),
    );
  }

  void _drawScanlines(Canvas canvas, Rect viewport) {
    canvas.drawRect(
      viewport,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0x0CFFFFFF), Colors.transparent],
          stops: [0, 0.5, 1],
          tileMode: TileMode.repeated,
          transform: GradientRotation(pi / 2),
        ).createShader(Rect.fromLTWH(0, 0, 5, 5)),
    );
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
    final painter = TextPainter(
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

class _MachineTelemetry {
  final String machineName;
  final String machineIcon;
  final int count;
  final String assignmentVerb;
  final String assignment;
  final String inputLabel;
  final String outputLabel;
  final Color color;
  final bool isRunning;
  final String blockedReason;
  final double activitySpeed;
  final double? progress;

  const _MachineTelemetry({
    required this.machineName,
    required this.machineIcon,
    required this.count,
    required this.assignmentVerb,
    required this.assignment,
    required this.inputLabel,
    required this.outputLabel,
    required this.color,
    required this.isRunning,
    required this.blockedReason,
    required this.activitySpeed,
    this.progress,
  });
}

List<_MachineTelemetry> _buildTelemetry(GameState state) {
  final modules = <_MachineTelemetry>[];

  void addMiner(BuildingType type, Color color) {
    final building = state.buildings[type];
    if (building == null || building.count == 0) return;
    final target = building.targetResource;
    final needsFuel = type == BuildingType.burnerMiner;
    final hasFuel = !needsFuel || (state.inventory[ResourceType.coal] ?? 0) > 0;
    modules.add(
      _MachineTelemetry(
        machineName: type.name,
        machineIcon: type.icon,
        count: building.count,
        assignmentVerb: 'ASSIGNED DEPOSIT',
        assignment: target?.label ?? 'Iron Ore',
        inputLabel: needsFuel ? 'Coal fuel' : 'Grid power',
        outputLabel: target?.label ?? 'Iron Ore',
        color: color,
        isRunning: hasFuel,
        blockedReason: 'NO FUEL',
        activitySpeed: type.craftSpeed,
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
    modules.add(
      _MachineTelemetry(
        machineName: type.name,
        machineIcon: type.icon,
        count: building.count,
        assignmentVerb: type == BuildingType.rocketSilo
            ? 'CURRENT PROJECT'
            : 'ACTIVE RECIPE',
        assignment: recipe?.name ?? 'Unassigned',
        inputLabel:
            recipe?.inputs.keys.map((item) => item.label).join(' + ') ??
            'No inputs',
        outputLabel:
            recipe?.outputs.keys.map((item) => item.label).join(' + ') ??
            'No output',
        color: color,
        isRunning: hasInputs,
        blockedReason: recipe == null ? 'NO RECIPE' : 'STARVED',
        activitySpeed: type.craftSpeed,
        progress: type == BuildingType.rocketSilo
            ? (state.rocketPartsBuilt / 100).clamp(0, 1)
            : null,
      ),
    );
  }

  addMiner(BuildingType.burnerMiner, const Color(0xFFF59E0B));
  addMiner(BuildingType.electricMiner, const Color(0xFFEAB308));
  addRecipeMachine(BuildingType.stoneFurnace, const Color(0xFFF97316));
  addRecipeMachine(BuildingType.steelFurnace, const Color(0xFFEF4444));
  addRecipeMachine(BuildingType.assembler1, const Color(0xFF38BDF8));
  addRecipeMachine(BuildingType.assembler2, const Color(0xFF3B82F6));

  final lab = state.buildings[BuildingType.researchLab];
  if (lab != null && lab.count > 0) {
    final technology = state.activeResearchId == null
        ? null
        : Technology.getById(state.activeResearchId!);
    final hasPacks =
        technology != null &&
        technology.cost.entries.every(
          (entry) => (state.inventory[entry.key] ?? 0) > 0,
        );
    modules.add(
      _MachineTelemetry(
        machineName: BuildingType.researchLab.name,
        machineIcon: BuildingType.researchLab.icon,
        count: lab.count,
        assignmentVerb: 'RESEARCHING',
        assignment: technology?.name ?? 'Nothing selected',
        inputLabel:
            technology?.cost.keys.map((item) => item.label).join(' + ') ??
            'Science packs',
        outputLabel: technology?.name ?? 'Technology',
        color: const Color(0xFF10B981),
        isRunning: hasPacks,
        blockedReason: technology == null ? 'IDLE' : 'NO PACKS',
        activitySpeed: 1,
      ),
    );
  }

  addRecipeMachine(BuildingType.rocketSilo, const Color(0xFFA855F7));
  return modules;
}

int telemetryColumnsForWidth(double width) {
  if (width >= 980) return 3;
  if (width >= 620) return 2;
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
        final moduleCount = max(1, _buildTelemetry(widget.state).length);
        final columns = telemetryColumnsForWidth(constraints.maxWidth);
        final rows = (moduleCount / columns).ceil();
        final height = 48 + rows * 130 + 8;

        return Container(
          height: height.toDouble(),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1116),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2D3545)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5506B6D4),
                blurRadius: 12,
                spreadRadius: -7,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: GameWidget(game: _game),
        );
      },
    );
  }
}
