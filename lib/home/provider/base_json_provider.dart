import 'dart:convert';
import 'dart:io';

import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:path/path.dart';
import 'package:riverpod/riverpod.dart';

final baseLocaleJsonProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) async {
    final projectPath = ref.watch(projectManagerProvider);
    if (projectPath == null) return null;

    final filePrefix = ref.watch(
        i18nConfigsProvider.select((value) => value.valueOrNull?.filePrefix));
    if (filePrefix == null) {
      return null;
    }

    final baseLocalePath = join(projectPath, '$filePrefix.json');

    ref.listen(filesNotifierProvider, (prev, next) {
      next.whenData((value) {
        final baseLocaleChanged =
            value?.any((element) => element.contains(baseLocalePath)) ?? false;

        if (baseLocaleChanged) ref.invalidateSelf();
      });
    });
    var fileContent = await File(baseLocalePath).readAsString();

    final baseLocaleJson = jsonDecode(fileContent) as Map<String, dynamic>;

    return baseLocaleJson;
  },
  name: 'baseLocaleJson',
);
