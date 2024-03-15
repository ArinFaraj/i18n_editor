import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:riverpod/riverpod.dart';
import 'package:watcher/watcher.dart';

final projectFolderWatcherProvider = StreamProvider(
  (ref) async* {
    final projectPath = ref.watch(projectManagerProvider);
    if (projectPath == null) {
      return;
    }
    final watcher = DirectoryWatcher(projectPath);
    yield* watcher.events;
  },
  name: 'projectFolderWatcher',
);
