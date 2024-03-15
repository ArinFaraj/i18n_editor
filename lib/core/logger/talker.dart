import 'package:simple_logger/simple_logger.dart';
// import 'package:talker/talker.dart';
// final logger = Talker(
//   settings: TalkerSettings(),
// );

final logger = SimpleLogger()
  ..setLevel(
    Level.FINEST,
    includeCallerInfo: false,
  )
  ..formatter = (info) => '${_levelInfo(info.level)}'
      '${info.message}';

String _levelInfo(Level level) {
  return '${levelPrefixes[level] ?? ''}$level ';
}

Map<Level, String> levelPrefixes = {
  Level.FINEST: '👾 ',
  Level.FINER: '👀 ',
  Level.FINE: '🎾 ',
  Level.CONFIG: '🐶 ',
  Level.INFO: '👻 ',
  Level.WARNING: '⚠️ ',
  Level.SEVERE: '‼️ ',
  Level.SHOUT: '😡 ',
};

extension ExLogger on SimpleLogger {
  void verbose(String message) {
    finest(message);
  }
}
