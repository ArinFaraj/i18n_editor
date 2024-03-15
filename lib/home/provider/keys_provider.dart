import 'dart:convert';
import 'dart:io';

import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:path/path.dart';
import 'package:riverpod/riverpod.dart';

final keysProvider = FutureProvider.autoDispose((ref) async {
  final projectPath = ref.watch(projectManagerProvider);
  if (projectPath == null) return null;

  final i18nConfigs = ref.watch(i18nConfigsProvider);
  if (!i18nConfigs.hasValue) {
    return null;
  }

  final baseLocalePath =
      join(projectPath, '${i18nConfigs.value!.filePrefix}.json');

  ref.listen(filesNotifierProvider, (prev, next) {
    next.whenData((value) {
      final baseLocaleChanged =
          value?.any((element) => element.contains(baseLocalePath)) ?? false;

      if (baseLocaleChanged) ref.invalidateSelf();
    });
  });
  final baseLocaleJson = jsonDecode(await File(baseLocalePath).readAsString())
      as Map<String, dynamic>;
  return baseLocaleJson;
});
