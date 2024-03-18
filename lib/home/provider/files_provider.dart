import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:riverpod/riverpod.dart';

typedef FileData = MapEntry<String, Map<String, dynamic>>;
typedef Files = Map<String, Map<String, dynamic>>;

final filesNotifierProvider = AsyncNotifierProvider<FilesNotifier, Files?>(
  FilesNotifier.new,
  name: 'filesNotifier',
);

class FilesNotifier extends AsyncNotifier<Files?> {
  @override
  Future<Files?> build() async {
    final projectPath = ref.watch(projectManagerProvider);
    if (projectPath == null) {
      return null;
    }

    final prefix = (await ref.watch(i18nConfigsProvider.future))?.filePrefix;
    if (prefix == null) {
      return null;
    }
    final files = await _getFiles(projectPath, prefix);

    return files;
  }

  Future<Files?> _getFiles(String projectPath, String prefix) async {
    final completer = Completer<Files>();

    final dir = Directory(projectPath);
    final files = <String>[];
    final lister = dir.list(recursive: true);

    lister.listen((event) {
      if (event is File &&
          RegExp('.*[\\\\/]$prefix.*\\.json').hasMatch(event.path)) {
        files.add(event.path);
      }
    }, onDone: () async {
      final contentOfFiles = <String, Map<String, dynamic>>{};

      for (final file in files) {
        final fileContent = await File(file).readAsString();
        final fileJson = json.decode(fileContent) as Map<String, dynamic>;
        // final nodes = extractNodes(fileJson);
        contentOfFiles[basename(file)] = fileJson;
      }

      completer.complete(contentOfFiles);
    });

    return completer.future;
  }
}
