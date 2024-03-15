import 'dart:async';
import 'dart:io';

import 'package:i18n_editor/home/provider/directory_watcher.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:riverpod/riverpod.dart';

typedef Files = List<String>;

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

    final files = await _getFiles(projectPath);

    ref.listen(projectFolderWatcherProvider, (prev, next) async {
      ref.invalidateSelf();
    });
    return files;
  }

  Future<Files> _getFiles(String projectPath) async {
    final completer = Completer<Files>();
    final dir = Directory(projectPath);
    final files = <String>[];
    final lister = dir.list(recursive: true);
    lister.listen((event) {
      if (event is File && event.path.endsWith('.json')) {
        files.add(event.path);
      }
    }, onDone: () {
      completer.complete(files);
    });
    return completer.future;
  }
}
