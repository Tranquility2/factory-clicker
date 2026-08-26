import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../simulation/game_engine.dart';

final gameEngineProvider = Provider<GameEngine>((ref) {
  final engine = GameEngine();
  engine.loadFromStorage().then((_) {
    engine.start();
  });
  ref.onDispose(() {
    engine.stop();
  });
  return engine;
});

