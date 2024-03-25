import 'dart:io';

import 'package:i18n_editor/home/model/i18n_configs.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:i18n_editor/utils.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart';
import 'package:yaml_writer/yaml_writer.dart';

const _i18nFileName = '.i18n_configs.yaml';

final i18nConfigsProvider =
    AsyncNotifierProvider<I18nConfigsNotifier, I18nConfigs?>(
  I18nConfigsNotifier.new,
  name: 'i18nConfigs',
);

class I18nConfigsNotifier extends AsyncNotifier<I18nConfigs?> {
  @override
  Future<I18nConfigs?> build() async {
    final projectPath = ref.watch(projectManagerProvider);
    if (projectPath == null) {
      return null;
    }

    final i18nYaml = File(join(projectPath, _i18nFileName));
    if (!await i18nYaml.exists()) {
      return null;
    }

    final i18nConfigsMap = (loadYaml(await i18nYaml.readAsString()) as YamlMap);
    final i18nConfigs =
        I18nConfigs.fromMap(convertYamlMapToMap(i18nConfigsMap));

    return i18nConfigs;
  }

  Future<void> createFile({
    required String prefix,
    required String defaultLocale,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => _createFile(prefix, defaultLocale),
    );
  }

  Future<void> updateFile({
    required String prefix,
    required String defaultLocale,
  }) async {
    final i18nConfigs = state.value!.copyWith(
      filePrefix: prefix,
      defaultLocale: defaultLocale,
    );
    final projectPath = ref.read(projectManagerProvider);
    if (projectPath == null) {
      throw Exception('No project path');
    }
    final i18nFile = File(join(projectPath, _i18nFileName));
    await i18nFile.writeAsString(YamlWriter().write(i18nConfigs.toMap()));
    state = AsyncValue.data(i18nConfigs);
  }

  Future<I18nConfigs> _createFile(
    String prefix,
    String defaultLocale,
  ) async {
    final projectPath = ref.read(projectManagerProvider);
    if (projectPath == null) {
      throw Exception('No project path');
    }
    final i18nFile = File(join(projectPath, _i18nFileName));
    final i18nConfigs =
        I18nConfigs(filePrefix: prefix, defaultLocale: defaultLocale);

    await i18nFile.writeAsString(YamlWriter().write(i18nConfigs.toMap()));

    return i18nConfigs;
  }
}
