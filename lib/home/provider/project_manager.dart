import 'dart:io';

import 'package:i18n_editor/core/logger/talker.dart';
import 'package:i18n_editor/core/settings/recent_projects.dart';
import 'package:riverpod/riverpod.dart';

typedef Project = String;

class ProjectManagerNotifier extends Notifier<Project?> {
  @override
  Project? build() {
    return null;
  }

  void openProject(String dirPath) async {
    Directory dir = Directory(dirPath);

    if (await dir.exists()) {
      state = dirPath;
      logger.info('Open project: $dirPath');
    }

    ref.read(recentProjectsProvider.notifier).set(
          [...ref.read(recentProjectsProvider).requireValue]
            ..remove(dirPath)
            ..insert(0, dirPath),
        );
  }
}

final projectManagerProvider =
    NotifierProvider<ProjectManagerNotifier, Project?>(() {
  return ProjectManagerNotifier();
});
