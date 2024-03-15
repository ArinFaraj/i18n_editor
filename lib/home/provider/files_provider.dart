import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:riverpod/riverpod.dart';

typedef I18nFile = (String path, Map<String, dynamic> content);

final filesNotifierProvider =
    AsyncNotifierProvider<FilesNotifier, List<I18nFile>?>(
  FilesNotifier.new,
  name: 'filesNotifier',
);

class FilesNotifier extends AsyncNotifier<List<I18nFile>?> {
  @override
  Future<List<I18nFile>?> build() async {
    final projectPath = ref.watch(projectManagerProvider);
    if (projectPath == null) {
      return null;
    }

    final prefix = (await ref.watch(i18nConfigsProvider.future))?.filePrefix;
    if (prefix == null) {
      return null;
    }
    final files = await _getFiles(projectPath, prefix);

    // ref.listen(projectFolderWatcherProvider, (prev, next) async {
    //   ref.invalidateSelf();
    // });
    return files;
  }

  Future<List<I18nFile>?> _getFiles(String projectPath, String prefix) async {
    final completer = Completer<List<I18nFile>>();

    final dir = Directory(projectPath);
    final files = <String>[];
    final lister = dir.list(recursive: true);
    lister.listen((event) {
      if (event is File &&
          RegExp('.*[\\\\/]$prefix.*\\.json').hasMatch(event.path)) {
        files.add(event.path);
      }
    }, onDone: () async {
      final finalfiles = <(String, Map<String, dynamic>)>[];
      for (final file in files) {
        final fileContent = await File(file).readAsString();
        final fileJson = json.decode(fileContent) as Map<String, dynamic>;
        // final nodes = extractNodes(fileJson);
        finalfiles.add((file, fileJson));
      }
      completer.complete(finalfiles);
    });
    return completer.future;
  }
}
