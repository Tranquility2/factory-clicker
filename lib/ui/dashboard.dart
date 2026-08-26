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

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _hooksRegistered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          appBar: AppBar(
            title: Row(
              children: [
                const Text('🏭 FACTORY CLICKER'),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: FactoryTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: FactoryTheme.border),
                  ),
                  child: Text(
                    'Clicks: ${state.totalManualClicks} | Speed: ${state.gameSpeedMultiplier.toStringAsFixed(0)}x',
                    style: const TextStyle(
                      color: FactoryTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: FactoryTheme.accentAmber,
              labelColor: FactoryTheme.accentAmber,
              unselectedLabelColor: FactoryTheme.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.precision_manufacturing), text: 'MACHINES'),
                Tab(icon: Icon(Icons.handyman), text: 'CRAFTING'),
                Tab(icon: Icon(Icons.science), text: 'RESEARCH'),
                Tab(icon: Icon(Icons.rocket_launch), text: 'ROCKET SILO'),
                Tab(icon: Icon(Icons.settings), text: 'SETTINGS'),
              ],
            ),
          ),
          body: Column(
            children: [
              ResourcePanel(state: state, engine: engine),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FlameFactoryWidget(state: state),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ManualGatherCard(engine: engine),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    BuildingsTab(state: state, engine: engine),
                    CraftingTab(state: state, engine: engine),
                    ResearchTab(state: state, engine: engine),
                    RocketSiloTab(state: state, engine: engine),
                    SettingsTab(state: state, engine: engine),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
