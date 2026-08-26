import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_state.dart';
import '../../simulation/game_engine.dart';
import '../theme.dart';

class SettingsTab extends StatefulWidget {
  final GameState state;
  final GameEngine engine;

  const SettingsTab({
    super.key,
    required this.state,
    required this.engine,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _importController = TextEditingController();
  String? _statusMessage;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulation Speed Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SIMULATION SPEED',
                    style: TextStyle(
                      color: FactoryTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [1.0, 2.0, 5.0, 10.0, 50.0].map((speed) {
                      final isSelected = widget.state.gameSpeedMultiplier == speed;
                      return Semantics(
                        identifier: 'speed-btn-${speed.toInt()}x',
                        button: true,
                        child: ElevatedButton(
                          key: ValueKey('btn-speed-${speed.toInt()}x'),
                          onPressed: () => widget.engine.setSpeed(speed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? FactoryTheme.accentAmber : FactoryTheme.surfaceLight,
                            foregroundColor: isSelected ? Colors.black : FactoryTheme.textSecondary,
                          ),
                          child: Text('${speed.toInt()}x'),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Save Management Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SAVE & DATA MANAGEMENT',
                    style: TextStyle(
                      color: FactoryTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        key: const ValueKey('btn-save-now'),
                        onPressed: () async {
                          await widget.engine.saveToStorage();
                          setState(() {
                            _statusMessage = 'Game saved successfully!';
                          });
                        },
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('SAVE GAME'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        key: const ValueKey('btn-export-save'),
                        onPressed: () {
                          final json = widget.engine.exportSaveJson();
                          Clipboard.setData(ClipboardData(text: json));
                          setState(() {
                            _statusMessage = 'Save JSON copied to clipboard!';
                          });
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('COPY SAVE JSON'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FactoryTheme.surfaceLight,
                          foregroundColor: FactoryTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('input-import-json'),
                    controller: _importController,
                    decoration: const InputDecoration(
                      labelText: 'Paste Save JSON to Import',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    key: const ValueKey('btn-import-save'),
                    onPressed: () {
                      final success = widget.engine.importSaveJson(_importController.text);
                      setState(() {
                        _statusMessage = success ? 'Save imported successfully!' : 'Invalid Save JSON';
                      });
                      if (success) _importController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FactoryTheme.accentCyan,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('IMPORT SAVE'),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _statusMessage!,
                      style: const TextStyle(color: FactoryTheme.accentAmber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
