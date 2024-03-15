import 'package:i18n_editor/core/logger/talker.dart';
import 'package:i18n_editor/home/provider/base_json_provider.dart';
import 'package:riverpod/riverpod.dart';

typedef JsonKey = List<dynamic>;

final baseLocaleKeysProvider = FutureProvider<List<JsonKey>?>(
  (ref) async {
    final baseJson = await ref.watch(baseLocaleJsonProvider.future);
    logger.info('baseJson: $baseJson');
    return extractKeyPaths(baseJson);
  },
  name: 'baseLocaleKeys',
);

List<JsonKey> extractKeyPaths(dynamic json, [List<dynamic> path = const []]) {
  final keyPaths = <List<dynamic>>[];

  if (json is Map) {
    json.forEach((key, value) {
      final newPath = [...path, key];
      keyPaths.addAll(extractKeyPaths(value, newPath));
    });
  } else if (json is List) {
    for (int i = 0; i < json.length; i++) {
      final newPath = [...path, i];
      keyPaths.addAll(extractKeyPaths(json[i], newPath));
    }
  } else {
    keyPaths.add(path);
  }

  return keyPaths;
}
