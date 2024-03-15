import 'dart:io';

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

    final newRecentProjects =
        List<String>.from(ref.read(recentProjectsProvider).requireValue)
          ..remove(dirPath)
          ..insert(0, dirPath);

    if (await dir.exists()) {
      state = dirPath;
    } else {
      newRecentProjects.remove(dirPath);
    }

    ref.read(recentProjectsProvider.notifier).set(newRecentProjects);
  }

  void closeProject() {
    state = null;
  }
}

final projectManagerProvider =
    NotifierProvider<ProjectManagerNotifier, Project?>(
  () {
    return ProjectManagerNotifier();
  },
  name: 'projectManager',
);
