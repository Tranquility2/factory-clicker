import 'package:flutter/foundation.dart';
import '../simulation/game_engine.dart';
import 'debug_hooks_stub.dart' if (dart.library.js_interop) 'debug_hooks_web.dart';

void setupDebugHooks(GameEngine engine) {
  if (kIsWeb) {
    try {
      registerWebHooks(engine);
    } catch (e) {
      debugPrint('Debug hook registration error: $e');
    }
  }
}

