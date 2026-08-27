import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/game_provider.dart';
import '../debug/debug_hooks.dart';
import 'theme.dart';
import 'widgets/resource_panel.dart';
import 'widgets/manual_gather_card.dart';
import 'widgets/flame_factory_view.dart';
import 'widgets/buildings_tab.dart';
import 'widgets/crafting_tab.dart';
import 'widgets/research_tab.dart';
import 'widgets/rocket_silo_tab.dart';
import 'widgets/settings_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _hooksRegistered = false;

  final List<Widget Function(dynamic state, dynamic engine)> _tabBuilders = [
    (state, engine) => BuildingsTab(state: state, engine: engine),
    (state, engine) => CraftingTab(state: state, engine: engine),
    (state, engine) => ResearchTab(state: state, engine: engine),
    (state, engine) => RocketSiloTab(state: state, engine: engine),
    (state, engine) => SettingsTab(state: state, engine: engine),
  ];

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(gameEngineProvider);

    if (!_hooksRegistered) {
      _hooksRegistered = true;
      setupDebugHooks(engine);
    }

    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final state = engine.state;
        return Scaffold(
          body: Row(
            children: [
              // Left Navigation Sidebar / Rail
              Container(
                width: 140,
                decoration: const BoxDecoration(
                  color: FactoryTheme.surface,
                  border: Border(
                    right: BorderSide(color: FactoryTheme.border, width: 1.5),
                  ),
                ),
                child: Column(
                  children: [
                    // Brand / Logo area
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Text(
                            '🏭',
                            style: TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'FACTORY\nCLICKER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: FactoryTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: FactoryTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: FactoryTheme.border),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'CLICKS: ${state.totalManualClicks}',
                                  style: const TextStyle(
                                    color: FactoryTheme.textSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'SPEED: ${state.gameSpeedMultiplier.toStringAsFixed(0)}x',
                                  style: const TextStyle(
                                    color: FactoryTheme.accentAmber,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: FactoryTheme.border, height: 1),
                    // Navigation items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _buildNavItem(0, 'MACHINES', Icons.precision_manufacturing),
                          _buildNavItem(1, 'CRAFTING', Icons.handyman),
                          _buildNavItem(2, 'RESEARCH', Icons.science),
                          _buildNavItem(3, 'ROCKET SILO', Icons.rocket_launch),
                          _buildNavItem(4, 'SETTINGS', Icons.settings),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Factory Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top Inventory Dashboard
                    ResourcePanel(state: state, engine: engine),

                    // Factory Floor 2D Animated Canvas
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: FlameFactoryWidget(state: state),
                    ),

                    // Manual Click Extraction Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: ManualGatherCard(engine: engine),
                    ),

                    // Active Tab Content
                    Expanded(
                      child: _tabBuilders[_selectedIndex](state, engine),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Material(
        color: isSelected ? FactoryTheme.accentAmber.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? FactoryTheme.accentAmber : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? FactoryTheme.accentAmber : FactoryTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? FactoryTheme.accentAmber : FactoryTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
