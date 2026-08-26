import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;
import '../simulation/game_engine.dart';
import '../models/resource_type.dart';

@JSExport()
class GameDebugExport {
  final GameEngine engine;

  GameDebugExport(this.engine);

  @JSExport()
  String getState() {
    return engine.exportSaveJson();
  }

  @JSExport()
  String setSpeed(double mult) {
    engine.setSpeed(mult);
    return 'Speed set to ${engine.state.gameSpeedMultiplier}x';
  }

  @JSExport()
  String loadState(String jsonStr) {
    final success = engine.importSaveJson(jsonStr);
    return success ? 'State loaded successfully' : 'Failed to load state';
  }

  @JSExport()
  String addResource(String resName, double amount) {
    try {
      final resType = ResourceType.fromName(resName);
      engine.addResourceDebug(resType, amount);
      return 'Added $amount of $resName';
    } catch (e) {
      return 'Error: $e';
    }
  }

  @JSExport()
  String unlockAllTech() {
    engine.unlockAllTechDebug();
    return 'All technologies unlocked';
  }
}

@JS('window')
external JSObject get _window;

void registerWebHooks(GameEngine engine) {
  try {
    final exporter = GameDebugExport(engine);
    final jsObject = createJSInteropWrapper(exporter);
    _window.setProperty('__gameDebug'.toJS, jsObject);
  } catch (e) {
    web.console.log('Error registering web hooks: $e'.toJS);
  }
}
